<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AiAnalysis;
use App\Models\Food;
use App\Models\Meal;
use App\Models\MealItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MealController extends Controller
{
    /**
     * Bir öğüne bir veya birden çok yemek ekler (arama, barkod veya AI sonucundan).
     * food_id verilirse besin değerleri sunucuda gramajdan hesaplanır.
     */
    public function addItems(Request $request, string $type)
    {
        abort_unless(in_array($type, Meal::TYPES, true), 404);
        $user = $request->user();

        $data = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
            'ai_analysis_id' => ['nullable', 'integer', Rule::exists('ai_analyses', 'id')->where('user_id', $user->id)],
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.food_id' => ['nullable', 'integer', 'exists:foods,id'],
            'items.*.name' => ['required_without:items.*.food_id', 'nullable', 'string', 'max:190'],
            'items.*.grams' => ['required', 'integer', 'between:1,3000'],
            'items.*.kcal' => ['required_without:items.*.food_id', 'nullable', 'integer', 'between:0,5000'],
            'items.*.protein' => ['nullable', 'numeric', 'between:0,500'],
            'items.*.carb' => ['nullable', 'numeric', 'between:0,500'],
            'items.*.fat' => ['nullable', 'numeric', 'between:0,500'],
        ]);

        $meal = DB::transaction(function () use ($user, $type, $data) {
            $meal = Meal::firstOrCreate([
                'user_id' => $user->id,
                'date' => $data['date'] ?? now()->toDateString(),
                'type' => $type,
            ]);

            foreach ($data['items'] as $item) {
                $meal->items()->create($this->buildItem($item, $data['ai_analysis_id'] ?? null));
            }

            return $meal;
        });

        if (! empty($data['ai_analysis_id'])) {
            $this->learnFromAnalysis(AiAnalysis::find($data['ai_analysis_id']), $data['items']);
        }

        $meal->load('items');

        return response()->json(['data' => [
            'type' => $meal->type,
            'kcal' => (int) $meal->items->sum('kcal'),
            'items' => $meal->items->map->only(['id', 'name', 'grams', 'kcal', 'protein', 'carb', 'fat']),
        ]], 201);
    }

    public function deleteItem(Request $request, MealItem $item)
    {
        abort_unless($item->meal->user_id === $request->user()->id, 404);
        $item->delete();

        return response()->noContent();
    }

    private function buildItem(array $item, ?int $analysisId): array
    {
        $grams = (int) $item['grams'];

        if (! empty($item['food_id'])) {
            $f = Food::findOrFail($item['food_id']);
            $k = $grams / 100;

            return [
                'food_id' => $f->id,
                'name' => $f->name,
                'grams' => $grams,
                'kcal' => (int) round($f->kcal_per_100g * $k),
                'protein' => round($f->protein_per_100g * $k, 1),
                'carb' => round($f->carb_per_100g * $k, 1),
                'fat' => round($f->fat_per_100g * $k, 1),
            ];
        }

        return [
            'ai_analysis_id' => $analysisId,
            'name' => $item['name'],
            'grams' => $grams,
            'kcal' => (int) $item['kcal'],
            'protein' => round($item['protein'] ?? 0, 1),
            'carb' => round($item['carb'] ?? 0, 1),
            'fat' => round($item['fat'] ?? 0, 1),
        ];
    }

    /**
     * AI'ın bulduğu yemekleri doğrulanmamış (verified=false) olarak yemek veritabanına ekler.
     * Admin onaylayınca aramada çıkar; zamanla AI'a daha az ihtiyaç duyulur (maliyet düşer).
     */
    private function learnFromAnalysis(?AiAnalysis $analysis, array $items): void
    {
        if (! $analysis) {
            return;
        }
        foreach ($items as $item) {
            if (empty($item['name']) || empty($item['grams']) || ! isset($item['kcal'])) {
                continue;
            }
            $k = 100 / max(1, (int) $item['grams']);
            Food::firstOrCreate(
                ['name' => mb_substr($item['name'], 0, 190), 'source' => 'ai'],
                [
                    'kcal_per_100g' => round($item['kcal'] * $k, 2),
                    'protein_per_100g' => round(($item['protein'] ?? 0) * $k, 2),
                    'carb_per_100g' => round(($item['carb'] ?? 0) * $k, 2),
                    'fat_per_100g' => round(($item['fat'] ?? 0) * $k, 2),
                    'default_portion_g' => (int) $item['grams'],
                    'verified' => false,
                ],
            );
        }
    }
}
