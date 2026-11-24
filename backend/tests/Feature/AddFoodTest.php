<?php

namespace Tests\Feature;

use App\Models\AiAnalysis;
use App\Models\AiModel;
use App\Models\Food;
use App\Models\Setting;
use App\Models\User;
use Database\Seeders\FoodSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AddFoodTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        config(['ai.openrouter.key' => 'test-key', 'ai.free_daily_photo_limit' => 2, 'ai.daily_budget_usd' => 5]);
        AiModel::create(['slug' => 'test/vision', 'label' => 'Test', 'purpose' => 'vision', 'input_price_per_mtok' => 1, 'output_price_per_mtok' => 2]);
        $this->user = User::factory()->create();
        $this->user->profile()->create();
        Sanctum::actingAs($this->user);
    }

    private function fakeOpenRouter(string $content, ?float $cost = 0.0012): void
    {
        Http::fake(['openrouter.ai/*' => Http::response([
            'model' => 'test/vision',
            'choices' => [['message' => ['content' => $content]]],
            'usage' => array_filter(['prompt_tokens' => 1200, 'completion_tokens' => 150, 'cost' => $cost], fn ($v) => $v !== null),
        ])]);
    }

    private function photo(string $name = 'yemek.jpg', int $w = 2000, int $h = 1500): UploadedFile
    {
        return UploadedFile::fake()->image($name, $w, $h);
    }

    public function test_search_returns_seeded_foods_and_hides_unverified_ai_foods(): void
    {
        $this->seed(FoodSeeder::class);
        Food::create(['name' => 'Tavuk AI', 'kcal_per_100g' => 100, 'source' => 'ai', 'verified' => false]);

        $res = $this->getJson('/api/v1/foods/search?q=tavuk')->assertOk();
        $names = collect($res->json('data'))->pluck('name');

        $this->assertContains('Tavuk göğsü ızgara', $names);
        $this->assertNotContains('Tavuk AI', $names);
    }

    public function test_add_food_from_database_calculates_nutrients_by_grams(): void
    {
        $food = Food::create(['name' => 'Pilav', 'kcal_per_100g' => 175, 'protein_per_100g' => 3, 'carb_per_100g' => 30, 'fat_per_100g' => 4.5]);

        $this->postJson('/api/v1/meals/lunch/items', ['items' => [['food_id' => $food->id, 'grams' => 200]]])
            ->assertCreated()
            ->assertJsonPath('data.kcal', 350)
            ->assertJsonPath('data.items.0.name', 'Pilav');

        $this->getJson('/api/v1/dashboard')->assertJsonPath('data.calories.consumed', 350);
    }

    public function test_barcode_falls_back_to_open_food_facts_and_caches(): void
    {
        Http::fake(['world.openfoodfacts.org/*' => Http::response([
            'status' => 1,
            'product' => ['product_name' => 'Çikolatalı Gofret', 'brands' => 'Marka', 'nutriments' => ['energy-kcal_100g' => 520, 'proteins_100g' => 6, 'carbohydrates_100g' => 60, 'fat_100g' => 28], 'serving_quantity' => 35],
        ])]);

        $this->getJson('/api/v1/foods/barcode/8690000000001')->assertOk()
            ->assertJsonPath('data.name', 'Çikolatalı Gofret')
            ->assertJsonPath('data.default_portion_g', 35);
        $this->getJson('/api/v1/foods/barcode/8690000000001')->assertOk();

        Http::assertSentCount(1); // ikinci istek yerel veritabanından
    }

    public function test_photo_analysis_logs_cost_consumes_quota_and_uses_cache(): void
    {
        $this->fakeOpenRouter('```json
{"is_food": true, "items": [
 {"name": "Tavuk ızgara", "grams": 100, "kcal": 180, "protein": 31, "carb": 0, "fat": 5, "confidence": 0.9},
 {"name": "Pirinç pilavı", "grams": 150, "kcal": 260, "protein": 4, "carb": 45, "fat": 6, "confidence": 0.8},
 {"name": "Salata", "grams": 100, "kcal": 40, "protein": 1, "carb": 6, "fat": 2}
]}
```');

        $photo = $this->photo();
        $res = $this->post('/api/v1/ai/analyze-photo', ['image' => $photo], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.is_food', true)
            ->assertJsonPath('data.total_kcal', 480)
            ->assertJsonPath('data.items.2.confidence', 0.5)
            ->assertJsonPath('data.quota.remaining', 1);

        $analysis = AiAnalysis::find($res->json('data.id'));
        $this->assertEquals(0.0012, (float) $analysis->cost_usd);
        $this->assertSame(1200, $analysis->prompt_tokens);
        Storage::disk('local')->assertExists($analysis->image_path);

        // Gönderilen görsel 1024 px'e küçültülmüş olmalı.
        Http::assertSent(function ($req) {
            $url = $req['messages'][0]['content'][1]['image_url']['url'];
            [$w] = getimagesizefromstring(base64_decode(substr($url, strlen('data:image/jpeg;base64,'))));

            return $req['model'] === 'test/vision' && $w === 1024;
        });

        // Aynı fotoğraf: önbellekten, maliyetsiz, hak düşmez.
        $this->post('/api/v1/ai/analyze-photo', ['image' => $photo], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.from_cache', true)
            ->assertJsonPath('data.quota.remaining', 1);
        Http::assertSentCount(1);

        // AI sonucunu öğüne ekle -> yemekler onaysız olarak veritabanına öğrenilir.
        $this->postJson('/api/v1/meals/dinner/items', [
            'ai_analysis_id' => $analysis->id,
            'items' => $res->json('data.items'),
        ])->assertCreated()->assertJsonPath('data.kcal', 480);
        $this->assertDatabaseHas('foods', ['name' => 'Tavuk ızgara', 'source' => 'ai', 'verified' => false, 'kcal_per_100g' => 180]);
    }

    public function test_cost_is_computed_from_model_prices_when_openrouter_omits_it(): void
    {
        $this->fakeOpenRouter('{"is_food": true, "items": [{"name": "Elma", "grams": 180, "kcal": 94}]}', null);

        $res = $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo()], ['Accept' => 'application/json'])->assertOk();

        // 1200 * $1/M + 150 * $2/M = 0.0015
        $this->assertEquals(0.0015, (float) AiAnalysis::find($res->json('data.id'))->cost_usd);
    }

    public function test_quota_endpoint_returns_integers_for_new_user(): void
    {
        $this->getJson('/api/v1/ai/quota')->assertOk()->assertExactJson(['data' => [
            'used' => 0, 'limit' => 2, 'remaining' => 2, 'is_premium' => false,
        ]]);
    }

    public function test_free_user_quota_is_enforced(): void
    {
        $this->fakeOpenRouter('{"is_food": false, "items": []}');

        $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo('a.jpg', 300, 300)], ['Accept' => 'application/json'])
            ->assertOk()->assertJsonPath('data.is_food', false);
        $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo('b.jpg', 310, 300)], ['Accept' => 'application/json'])->assertOk();
        $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo('c.jpg', 320, 300)], ['Accept' => 'application/json'])
            ->assertStatus(429)->assertJsonPath('code', 'quota_exceeded');
    }

    public function test_daily_budget_blocks_free_users_but_not_premium(): void
    {
        Setting::put('ai_daily_budget_usd', 0.001);
        AiAnalysis::create(['user_id' => $this->user->id, 'image_hash' => 'x', 'status' => 'done', 'cost_usd' => 0.002]);
        $this->fakeOpenRouter('{"is_food": true, "items": [{"name": "Elma", "grams": 180, "kcal": 94}]}');

        $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo()], ['Accept' => 'application/json'])
            ->assertStatus(503)->assertJsonPath('code', 'budget_exceeded');

        $this->user->forceFill(['premium_until' => now()->addMonth()])->save();
        $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo()], ['Accept' => 'application/json'])->assertOk();
    }

    public function test_falls_back_to_second_model_when_first_fails(): void
    {
        AiModel::create(['slug' => 'test/backup', 'label' => 'Yedek', 'purpose' => 'vision', 'priority' => 2]);
        Http::fake(['openrouter.ai/*' => Http::sequence()
            ->push(['error' => ['message' => 'down']], 500)
            ->push(['model' => 'test/backup', 'choices' => [['message' => ['content' => '{"is_food": true, "items": [{"name": "Muz", "grams": 120, "kcal": 107}]}']]], 'usage' => ['prompt_tokens' => 10, 'completion_tokens' => 10]]),
        ]);

        $res = $this->post('/api/v1/ai/analyze-photo', ['image' => $this->photo()], ['Accept' => 'application/json'])->assertOk();
        $this->assertSame('test/backup', AiAnalysis::find($res->json('data.id'))->model);
    }

    public function test_cannot_delete_other_users_meal_item(): void
    {
        $other = User::factory()->create();
        $meal = \App\Models\Meal::create(['user_id' => $other->id, 'date' => now()->toDateString(), 'type' => 'lunch']);
        $item = $meal->items()->create(['name' => 'X', 'grams' => 100, 'kcal' => 100]);

        $this->deleteJson("/api/v1/meal-items/{$item->id}")->assertNotFound();
    }
}
