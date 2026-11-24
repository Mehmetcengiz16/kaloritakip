<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Food;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

class FoodController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'source' => ['nullable', Rule::in(['manual', 'openfoodfacts', 'ai'])],
            'pending' => ['nullable', 'boolean'],
        ]);

        $foods = Food::query()
            ->when($filters['q'] ?? null, fn ($q, $s) => $q->where('name', 'like', '%'.addcslashes($s, '%_\\').'%'))
            ->when($filters['source'] ?? null, fn ($q, $s) => $q->where('source', $s))
            ->when($filters['pending'] ?? false, fn ($q) => $q->where('verified', false))
            ->orderBy('verified')->latest()
            ->paginate(25)->withQueryString()
            ->through(fn (Food $f) => $f->toArray() + ['image' => $f->imageUrl()]);

        return Inertia::render('Foods/Index', [
            'foods' => $foods,
            'filters' => $filters,
            'pendingCount' => Food::where('verified', false)->count(),
        ]);
    }

    public function store(Request $request)
    {
        $food = Food::create($this->validated($request) + ['source' => 'manual', 'verified' => true]);
        $this->storeImage($request, $food);

        return back()->with('success', 'Yemek eklendi.');
    }

    public function update(Request $request, Food $food)
    {
        $food->update($this->validated($request, $food));
        $this->storeImage($request, $food);
        if ($request->boolean('remove_image')) {
            $this->deleteImage($food);
            $food->update(['image_url' => null]);
        }

        return back()->with('success', "{$food->name} güncellendi.");
    }

    /** AI'dan öğrenilen yemeği onayla: aramada görünür olur. */
    public function verify(Food $food)
    {
        $food->update(['verified' => ! $food->verified]);

        return back()->with('success', $food->verified ? "{$food->name} onaylandı." : "{$food->name} onayı kaldırıldı.");
    }

    public function destroy(Food $food)
    {
        $this->deleteImage($food);
        $food->delete(); // öğün kayıtlarındaki food_id null olur, kayıtlar korunur

        return back()->with('success', "{$food->name} silindi.");
    }

    /** Görsel 600x600'e kırpılıp WebP olarak public diske kaydedilir (mobilde hızlı yüklenir). */
    private function storeImage(Request $request, Food $food): void
    {
        $request->validate(['image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096']]);
        if (! $request->hasFile('image')) {
            return;
        }

        $src = @imagecreatefromstring((string) file_get_contents($request->file('image')->getRealPath()));
        abort_unless($src, 422, 'Görsel okunamadı.');
        $w = imagesx($src);
        $h = imagesy($src);
        $side = min($w, $h);
        $dst = imagecreatetruecolor(600, 600);
        imagefill($dst, 0, 0, imagecolorallocate($dst, 255, 255, 255));
        imagecopyresampled($dst, $src, 0, 0, (int) (($w - $side) / 2), (int) (($h - $side) / 2), 600, 600, $side, $side);
        ob_start();
        imagewebp($dst, null, 80);
        $bytes = (string) ob_get_clean();

        $this->deleteImage($food);
        $path = 'foods/'.$food->id.'-'.substr(md5($bytes), 0, 8).'.webp';
        Storage::disk('public')->put($path, $bytes);
        $food->update(['image_path' => $path]);
    }

    private function deleteImage(Food $food): void
    {
        if ($food->image_path) {
            Storage::disk('public')->delete($food->image_path);
            $food->update(['image_path' => null]);
        }
    }

    private function validated(Request $request, ?Food $food = null): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:190'],
            'brand' => ['nullable', 'string', 'max:190'],
            'barcode' => ['nullable', 'regex:/^\d{8,14}$/', Rule::unique('foods', 'barcode')->ignore($food?->id)],
            'kcal_per_100g' => ['required', 'numeric', 'between:0,1000'],
            'protein_per_100g' => ['required', 'numeric', 'between:0,100'],
            'carb_per_100g' => ['required', 'numeric', 'between:0,100'],
            'fat_per_100g' => ['required', 'numeric', 'between:0,100'],
            'default_portion_g' => ['required', 'integer', 'between:1,2000'],
            'verified' => ['sometimes', 'boolean'],
        ]);
    }
}
