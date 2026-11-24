<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Food;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Throwable;

class FoodController extends Controller
{
    public function search(Request $request)
    {
        $q = trim((string) $request->validate(['q' => ['required', 'string', 'min:2', 'max:60']])['q']);
        $escaped = addcslashes($q, '%_\\');

        $foods = Food::query()
            ->where('name', 'like', "%{$escaped}%")
            // AI'dan öğrenilen yemekler admin onaylayana kadar aramada çıkmaz.
            ->where(fn ($w) => $w->where('source', '!=', 'ai')->orWhere('verified', true))
            ->orderByRaw('name LIKE ? DESC', ["{$escaped}%"]) // başında eşleşenler önce
            ->orderByDesc('verified')
            ->orderBy('name')
            ->limit(30)
            ->get();

        return ['data' => $foods->map(fn (Food $f) => $this->present($f))];
    }

    /** Önce yerel veritabanı, yoksa Open Food Facts; bulunan ürün yerelde saklanır. */
    public function barcode(string $code)
    {
        abort_unless(preg_match('/^\d{8,14}$/', $code), 422, 'Geçersiz barkod.');

        $food = Food::where('barcode', $code)->first() ?? $this->fetchOpenFoodFacts($code);
        abort_unless($food, 404, 'Bu barkoda ait ürün bulunamadı.');

        return ['data' => $this->present($food)];
    }

    private function fetchOpenFoodFacts(string $code): ?Food
    {
        try {
            $res = Http::timeout(8)
                ->withUserAgent('KaloriTakip/1.0')
                ->get("https://world.openfoodfacts.org/api/v2/product/{$code}.json", [
                    'fields' => 'product_name,product_name_tr,brands,nutriments,serving_quantity,image_front_small_url,image_front_url',
                ]);
        } catch (Throwable) {
            return null;
        }

        $p = $res->json('product');
        $n = $p['nutriments'] ?? [];
        $kcal = $n['energy-kcal_100g'] ?? (isset($n['energy_100g']) ? $n['energy_100g'] / 4.184 : null);
        $name = $p['product_name_tr'] ?? $p['product_name'] ?? null;
        if (! $res->ok() || $res->json('status') !== 1 || $kcal === null || ! $name) {
            return null;
        }

        return Food::create([
            'name' => mb_substr($name, 0, 190),
            'brand' => isset($p['brands']) ? mb_substr(explode(',', $p['brands'])[0], 0, 190) : null,
            'barcode' => $code,
            'kcal_per_100g' => round($kcal, 2),
            'protein_per_100g' => round($n['proteins_100g'] ?? 0, 2),
            'carb_per_100g' => round($n['carbohydrates_100g'] ?? 0, 2),
            'fat_per_100g' => round($n['fat_100g'] ?? 0, 2),
            'default_portion_g' => (int) round($p['serving_quantity'] ?? 100) ?: 100,
            'image_url' => $this->safeImageUrl($p['image_front_small_url'] ?? $p['image_front_url'] ?? null),
            'source' => 'openfoodfacts',
        ]);
    }

    /** Sadece Open Food Facts'in kendi görsel sunucusundan https adreslerini kabul et. */
    private function safeImageUrl(?string $url): ?string
    {
        if (! $url || ! str_starts_with($url, 'https://') || strlen($url) > 500) {
            return null;
        }
        $host = parse_url($url, PHP_URL_HOST);

        return $host && str_ends_with($host, 'openfoodfacts.org') ? $url : null;
    }

    private function present(Food $f): array
    {
        return [
            'id' => $f->id,
            'name' => $f->name,
            'brand' => $f->brand,
            'kcal_per_100g' => (float) $f->kcal_per_100g,
            'protein_per_100g' => (float) $f->protein_per_100g,
            'carb_per_100g' => (float) $f->carb_per_100g,
            'fat_per_100g' => (float) $f->fat_per_100g,
            'default_portion_g' => $f->default_portion_g,
            'image_url' => $f->imageUrl(),
        ];
    }
}
