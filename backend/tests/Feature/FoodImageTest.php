<?php

namespace Tests\Feature;

use App\Models\Food;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class FoodImageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        $this->withoutVite();
    }

    public function test_admin_uploads_image_which_is_cropped_to_webp_and_served_in_api(): void
    {
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        $food = Food::create(['name' => 'Haşlanmış yumurta', 'kcal_per_100g' => 155, 'verified' => true]);

        $this->actingAs($admin)->post("/admin/foods/{$food->id}", [
            'name' => 'Haşlanmış yumurta', 'kcal_per_100g' => 155, 'protein_per_100g' => 13,
            'carb_per_100g' => 1.1, 'fat_per_100g' => 11, 'default_portion_g' => 50,
            'image' => UploadedFile::fake()->image('yumurta.jpg', 1200, 800),
        ])->assertSessionHasNoErrors();

        $path = $food->fresh()->image_path;
        $this->assertStringEndsWith('.webp', $path);
        Storage::disk('public')->assertExists($path);
        [$w, $h] = getimagesizefromstring(Storage::disk('public')->get($path));
        $this->assertSame([600, 600], [$w, $h]);

        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/v1/foods/search?q=yumurta')
            ->assertJsonPath('data.0.image_url', fn ($url) => str_contains($url, '/storage/foods/') && str_ends_with($url, '.webp'));

        // Görseli kaldır: dosya da silinir.
        $this->actingAs($admin)->post("/admin/foods/{$food->id}", [
            'name' => 'Haşlanmış yumurta', 'kcal_per_100g' => 155, 'protein_per_100g' => 13,
            'carb_per_100g' => 1.1, 'fat_per_100g' => 11, 'default_portion_g' => 50, 'remove_image' => true,
        ]);
        Storage::disk('public')->assertMissing($path);
        $this->assertNull($food->fresh()->imageUrl());
    }

    public function test_barcode_product_keeps_open_food_facts_image_only_from_its_domain(): void
    {
        Sanctum::actingAs(User::factory()->create());
        Http::fake([
            'world.openfoodfacts.org/api/v2/product/8690000000011.json*' => Http::response(['status' => 1, 'product' => [
                'product_name' => 'Gofret', 'nutriments' => ['energy-kcal_100g' => 520],
                'image_front_small_url' => 'https://images.openfoodfacts.org/images/products/869/front.200.jpg',
            ]]),
            'world.openfoodfacts.org/api/v2/product/8690000000028.json*' => Http::response(['status' => 1, 'product' => [
                'product_name' => 'Bisküvi', 'nutriments' => ['energy-kcal_100g' => 450],
                'image_front_small_url' => 'http://evil.example.com/x.jpg',
            ]]),
        ]);

        $this->getJson('/api/v1/foods/barcode/8690000000011')
            ->assertJsonPath('data.image_url', 'https://images.openfoodfacts.org/images/products/869/front.200.jpg');
        $this->getJson('/api/v1/foods/barcode/8690000000028')->assertJsonPath('data.image_url', null);
    }

    public function test_meal_items_in_dashboard_carry_food_image(): void
    {
        $user = User::factory()->create();
        $user->profile()->create();
        Sanctum::actingAs($user);
        $food = Food::create(['name' => 'Gofret', 'kcal_per_100g' => 500, 'image_url' => 'https://images.openfoodfacts.org/a.jpg']);

        $this->postJson('/api/v1/meals/snack1/items', ['items' => [['food_id' => $food->id, 'grams' => 40]]])->assertCreated();
        $this->getJson('/api/v1/dashboard')->assertJsonPath('data.meals.1.items.0.image_url', 'https://images.openfoodfacts.org/a.jpg');
    }
}
