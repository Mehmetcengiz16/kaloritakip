<?php

namespace App\Services\Ai;

use App\Models\AiModel;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

/**
 * OpenRouter chat/completions istemcisi. Aktif modelleri öncelik sırasıyla dener (ana model -> yedek).
 */
class OpenRouterClient
{
    /**
     * @return array{content: string, model: string, prompt_tokens: int, completion_tokens: int, cost_usd: float}
     */
    public function chat(string $purpose, array $messages, int $maxTokens = 600): array
    {
        $key = AiCredentials::key();
        if (! $key) {
            throw new AiUnavailableException('Yapay zekâ servisi yapılandırılmamış (OpenRouter API anahtarı girilmemiş).');
        }

        $models = AiModel::for($purpose)->get();
        if ($models->isEmpty()) {
            throw new AiUnavailableException("'{$purpose}' için aktif yapay zekâ modeli yok.");
        }

        $lastError = null;
        foreach ($models as $model) {
            try {
                return $this->call($key, $model, $messages, $maxTokens);
            } catch (Throwable $e) {
                $lastError = $e;
                report($e);
            }
        }

        throw new AiUnavailableException('Yapay zekâ servisine şu an ulaşılamıyor.', previous: $lastError);
    }

    /**
     * Anahtarı doğrular (OpenRouter /key uç noktası; model çağrısı yapmaz, ücretsizdir).
     *
     * @return array{ok: bool, message: string, label?: string|null, usage?: float|null, limit?: float|null}
     */
    public function checkKey(string $key): array
    {
        try {
            $res = Http::withToken($key)->timeout(10)->get(rtrim(config('ai.openrouter.base_url'), '/').'/key');
        } catch (Throwable) {
            return ['ok' => false, 'message' => "OpenRouter'a ulaşılamadı. Sunucunun internet bağlantısını kontrol et."];
        }

        if ($res->status() === 401 || $res->status() === 403) {
            return ['ok' => false, 'message' => 'Anahtar geçersiz veya iptal edilmiş.'];
        }
        if ($res->failed()) {
            return ['ok' => false, 'message' => 'OpenRouter hata döndürdü ('.$res->status().').'];
        }

        $limit = $res->json('data.limit');

        return [
            'ok' => true,
            'message' => 'Anahtar geçerli.',
            'label' => $res->json('data.label'),
            'usage' => $res->json('data.usage') !== null ? (float) $res->json('data.usage') : null,
            'limit' => $limit !== null ? (float) $limit : null,
        ];
    }

    private function call(string $key, AiModel $model, array $messages, int $maxTokens): array
    {
        $res = Http::withToken($key)
            ->withHeaders([
                'HTTP-Referer' => config('ai.openrouter.app_url') ?? '',
                'X-Title' => config('ai.openrouter.app_name'),
            ])
            ->timeout(config('ai.openrouter.timeout'))
            ->post(rtrim(config('ai.openrouter.base_url'), '/').'/chat/completions', [
                'model' => $model->slug,
                'messages' => $messages,
                'max_tokens' => $maxTokens,
                'temperature' => 0.2,
                'response_format' => ['type' => 'json_object'],
                'usage' => ['include' => true], // OpenRouter gerçek maliyeti döndürür
            ]);

        if ($res->failed() || $res->json('error')) {
            throw new RuntimeException("OpenRouter {$model->slug} hata: ".$res->status().' '.mb_substr($res->body(), 0, 300));
        }

        $in = (int) $res->json('usage.prompt_tokens', 0);
        $out = (int) $res->json('usage.completion_tokens', 0);
        $cost = $res->json('usage.cost');

        return [
            'content' => (string) $res->json('choices.0.message.content', ''),
            'model' => (string) $res->json('model', $model->slug),
            'prompt_tokens' => $in,
            'completion_tokens' => $out,
            // OpenRouter maliyet döndürmezse tablodaki fiyatlardan hesapla.
            'cost_usd' => $cost !== null ? (float) $cost : $model->costFor($in, $out),
        ];
    }
}
