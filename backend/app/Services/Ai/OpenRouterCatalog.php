<?php

namespace App\Services\Ai;

use App\Models\AiModel;
use App\Models\Setting;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * OpenRouter model listesi ve fiyatları (GET /models, anahtar gerektirmez).
 * OpenRouter fiyatları token başına USD verir; burada 1M token başına çevrilir.
 */
class OpenRouterCatalog
{
    private const CACHE_KEY = 'openrouter.catalog';

    /**
     * @return Collection<int, array{slug: string, name: string, input_price_per_mtok: float, output_price_per_mtok: float, vision: bool, context: int|null}>
     */
    public function all(bool $fresh = false): Collection
    {
        if ($fresh) {
            Cache::forget(self::CACHE_KEY);
        }

        return collect(Cache::remember(self::CACHE_KEY, now()->addHour(), function () {
            $res = Http::timeout(20)->acceptJson()->get(rtrim(config('ai.openrouter.base_url'), '/').'/models');
            if ($res->failed() || ! is_array($res->json('data'))) {
                throw new RuntimeException('OpenRouter model listesi alınamadı ('.$res->status().').');
            }

            return collect($res->json('data'))
                ->filter(fn ($m) => isset($m['id'], $m['pricing']['prompt'], $m['pricing']['completion']))
                ->map(fn ($m) => [
                    'slug' => $m['id'],
                    'name' => $m['name'] ?? $m['id'],
                    'input_price_per_mtok' => $this->perMillion($m['pricing']['prompt']),
                    'output_price_per_mtok' => $this->perMillion($m['pricing']['completion']),
                    'vision' => in_array('image', $m['architecture']['input_modalities'] ?? [], true)
                        || str_contains((string) ($m['architecture']['modality'] ?? ''), 'image'),
                    'context' => $m['context_length'] ?? null,
                ])
                // Negatif fiyat = değişken fiyatlı yönlendirici modeller (ör. openrouter/auto); listeden çıkar.
                ->filter(fn ($m) => $m['input_price_per_mtok'] >= 0 && $m['output_price_per_mtok'] >= 0)
                ->values()
                ->all();
        }));
    }

    public function find(string $slug): ?array
    {
        return $this->all()->firstWhere('slug', $slug);
    }

    /** Arama: ad veya kimlikte geçen, istenirse sadece görsel destekleyen modeller; ucuzdan pahalıya. */
    public function search(?string $q, bool $visionOnly = false, int $limit = 30): Collection
    {
        $q = mb_strtolower(trim((string) $q));

        return $this->all()
            ->when($visionOnly, fn ($c) => $c->where('vision', true))
            ->when($q !== '', fn ($c) => $c->filter(fn ($m) => str_contains(mb_strtolower($m['slug'].' '.$m['name']), $q)))
            ->sortBy(fn ($m) => $m['input_price_per_mtok'] + $m['output_price_per_mtok'] * 0.125)
            ->take($limit)
            ->values();
    }

    /**
     * Kayıtlı modellerin fiyatlarını OpenRouter'daki güncel fiyatlarla günceller.
     *
     * @return array{updated: array<int, array{slug: string, old: array, new: array}>, missing: array<int, string>}
     */
    public function syncPrices(): array
    {
        $catalog = $this->all(fresh: true)->keyBy('slug');
        $updated = [];
        $missing = [];

        foreach (AiModel::all() as $model) {
            $remote = $catalog->get($model->slug);
            if (! $remote) {
                $missing[] = $model->slug;

                continue;
            }

            $old = [(float) $model->input_price_per_mtok, (float) $model->output_price_per_mtok];
            $new = [$remote['input_price_per_mtok'], $remote['output_price_per_mtok']];
            if (abs($old[0] - $new[0]) > 1e-6 || abs($old[1] - $new[1]) > 1e-6) {
                $model->update(['input_price_per_mtok' => $new[0], 'output_price_per_mtok' => $new[1]]);
                $updated[] = ['slug' => $model->slug, 'old' => $old, 'new' => $new];
            }
        }

        Setting::put('ai_prices_synced_at', now()->toIso8601String());

        return ['updated' => $updated, 'missing' => array_values(array_unique($missing))];
    }

    private function perMillion(mixed $perToken): float
    {
        return round((float) $perToken * 1_000_000, 4);
    }
}
