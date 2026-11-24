<?php

namespace Tests\Feature;

use App\Models\AiAnalysis;
use App\Models\AiModel;
use App\Models\Expense;
use App\Models\Food;
use App\Models\Setting;
use App\Models\Subscription;
use App\Models\UsageQuota;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use App\Services\Ai\AiCredentials;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class AdminPanelTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
        $this->admin = User::factory()->create(['email' => 'admin@test.local', 'password' => 'gizli-sifre']);
        $this->admin->forceFill(['is_admin' => true])->save();
    }

    public function test_guest_is_redirected_and_non_admin_cannot_log_in(): void
    {
        $this->get('/admin')->assertRedirect('/admin/login');

        $user = User::factory()->create(['email' => 'user@test.local', 'password' => 'gizli-sifre']);
        $this->post('/admin/login', ['email' => 'user@test.local', 'password' => 'gizli-sifre'])->assertSessionHasErrors('email');
        $this->assertGuest();

        // Oturumu olsa bile admin olmayan içeri giremez.
        $this->actingAs($user)->get('/admin')->assertRedirect('/admin/login');
    }

    public function test_admin_logs_in(): void
    {
        $this->post('/admin/login', ['email' => 'admin@test.local', 'password' => 'gizli-sifre'])->assertRedirect('/admin');
        $this->assertAuthenticatedAs($this->admin);
    }

    public function test_dashboard_computes_profitability(): void
    {
        Setting::put('usd_try_rate', 40);
        Setting::put('store_fee_pct', 15);
        $user = User::factory()->create();
        Subscription::create(['user_id' => $user->id, 'store' => 'play_store', 'product_id' => 'monthly', 'status' => 'active', 'started_at' => now(), 'price' => 1000]);
        AiAnalysis::create(['user_id' => $user->id, 'image_hash' => 'a', 'status' => 'done', 'cost_usd' => 1.5]); // 60 TL
        Expense::create(['category' => 'server', 'amount' => 200, 'date' => today()]);
        Expense::create(['category' => 'openrouter', 'amount' => 999, 'date' => today()]); // çift sayılmamalı

        $this->actingAs($this->admin)->get('/admin')->assertOk()->assertInertia(fn (Assert $page) => $page
            ->component('Dashboard')
            ->where('summary.revenue', 1000)
            ->where('summary.store_fee', 150)
            ->where('summary.ai_cost', 60)
            ->where('summary.expenses', 200)
            ->where('summary.net', 590)
            ->where('summary.margin_pct', 59)
            ->where('summary.ai_ratio_pct', 6)
            ->where('users.total', 1)
            ->has('series', 30)
        );
    }

    public function test_user_management_actions(): void
    {
        $user = User::factory()->create(['name' => 'Ayşe']);
        $token = $user->createToken('mobile');
        UsageQuota::create(['user_id' => $user->id, 'date' => today(), 'ai_photo_count' => 2]);
        $this->actingAs($this->admin);

        $this->get('/admin/users?q=Ayş')->assertInertia(fn (Assert $p) => $p->component('Users/Index')->has('users.data', 1));

        $this->post("/admin/users/{$user->id}/premium", ['days' => 30])->assertRedirect();
        $this->assertTrue($user->fresh()->isPremium());
        $this->assertDatabaseHas('subscriptions', ['user_id' => $user->id, 'store' => 'manual', 'status' => 'active']);

        $this->post("/admin/users/{$user->id}/premium", ['days' => 0]);
        $this->assertFalse($user->fresh()->isPremium());

        $this->post("/admin/users/{$user->id}/reset-quota");
        $this->assertSame(0, UsageQuota::where('user_id', $user->id)->value('ai_photo_count'));

        $this->post("/admin/users/{$user->id}/block");
        $this->assertTrue($user->fresh()->is_blocked);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $token->accessToken->id]);

        $this->get("/admin/users/{$user->id}")->assertInertia(fn (Assert $p) => $p->component('Users/Show')->where('user.name', 'Ayşe'));
    }

    public function test_food_crud_and_verify(): void
    {
        $this->actingAs($this->admin);
        $this->post('/admin/foods', [
            'name' => 'Karnıyarık', 'kcal_per_100g' => 140, 'protein_per_100g' => 5,
            'carb_per_100g' => 9, 'fat_per_100g' => 9.5, 'default_portion_g' => 250,
        ])->assertSessionHasNoErrors();
        $this->assertDatabaseHas('foods', ['name' => 'Karnıyarık', 'verified' => true, 'source' => 'manual']);

        $ai = Food::create(['name' => 'AI Yemek', 'kcal_per_100g' => 100, 'source' => 'ai', 'verified' => false]);
        $this->get('/admin/foods?pending=1')->assertInertia(fn (Assert $p) => $p->has('foods.data', 1)->where('pendingCount', 1));
        $this->post("/admin/foods/{$ai->id}/verify");
        $this->assertTrue($ai->fresh()->verified);

        $this->delete("/admin/foods/{$ai->id}");
        $this->assertModelMissing($ai);
    }

    public function test_settings_and_models(): void
    {
        $this->actingAs($this->admin);

        $this->put('/admin/settings', [
            'ai_free_daily_photo_limit' => 1, 'ai_premium_daily_photo_limit' => 20, 'ai_daily_budget_usd' => 3,
            'ai_cost_ratio_alert_pct' => 12, 'store_fee_pct' => 15, 'usd_try_rate' => 41, 'usd_try_auto' => false,
        ])->assertSessionHasNoErrors();
        $this->assertSame('1', (string) Setting::get('ai_free_daily_photo_limit'));

        $this->post('/admin/ai-models', [
            'slug' => 'openai/gpt-4o-mini', 'label' => 'Yedek', 'purpose' => 'vision', 'priority' => 2,
            'is_active' => true, 'input_price_per_mtok' => 0.15, 'output_price_per_mtok' => 0.6,
        ])->assertSessionHasNoErrors();
        $this->post('/admin/ai-models', [
            'slug' => 'gecersiz model', 'label' => 'X', 'purpose' => 'vision', 'priority' => 1,
            'is_active' => true, 'input_price_per_mtok' => 0, 'output_price_per_mtok' => 0,
        ])->assertSessionHasErrors('slug');

        $this->assertSame(1, AiModel::count());
        $this->get('/admin/settings')->assertInertia(fn (Assert $p) => $p->component('Settings/Index')->has('models', 1)->where('settings.usd_try_rate', 41));
    }

    public function test_expenses_and_pages_render(): void
    {
        $this->actingAs($this->admin);
        $this->post('/admin/expenses', ['category' => 'server', 'amount' => 750, 'date' => today()->toDateString()])->assertSessionHasNoErrors();
        $this->get('/admin/expenses')->assertInertia(fn (Assert $p) => $p->component('Expenses/Index')->where('thisMonth', 750));

        Setting::put('usd_try_rate', 50);
        AiAnalysis::create(['user_id' => $this->admin->id, 'image_hash' => 'x', 'status' => 'done', 'cost_usd' => 0.00034]);
        AiAnalysis::create(['user_id' => $this->admin->id, 'image_hash' => 'x', 'status' => 'done', 'from_cache' => true]);
        $this->get('/admin/ai-analyses')->assertInertia(fn (Assert $p) => $p
            ->component('AiAnalyses/Index')
            ->where('usdTry', 50)
            ->where('analyses.data', fn ($rows) => collect($rows)->pluck('cost_try')->sort()->values()->all() === [0, 0.017])
            ->where('totals.count', 2)
            ->where('totals.cost_try', 0.017)
            ->where('totals.avg_try', 0.017)
        );
    }

    public function test_openrouter_key_is_validated_encrypted_and_used(): void
    {
        config(['ai.openrouter.key' => null]);
        $key = 'sk-or-v1-'.str_repeat('a', 40).'WXYZ';
        Http::fake([
            'openrouter.ai/api/v1/key' => fn ($req) => $req->header('Authorization')[0] === "Bearer {$key}"
                ? Http::response(['data' => ['label' => 'test', 'usage' => 1.25, 'limit' => 10]])
                : Http::response(['error' => ['message' => 'invalid']], 401),
        ]);
        $this->actingAs($this->admin);

        // Geçersiz anahtar kaydedilmez.
        $this->put('/admin/settings/api-key', ['api_key' => 'sk-or-v1-'.str_repeat('b', 40)])->assertSessionHasErrors('api_key');
        $this->assertNull(AiCredentials::key());

        // Geçerli anahtar şifreli kaydedilir, panele sadece maskeli hali gider.
        $this->put('/admin/settings/api-key', ['api_key' => $key])->assertSessionHasNoErrors();
        $this->assertSame($key, AiCredentials::key());
        $this->assertStringNotContainsString($key, (string) Setting::find('openrouter_api_key')->value);

        $this->get('/admin/settings')->assertInertia(fn (Assert $p) => $p
            ->where('apiKey.configured', true)
            ->where('apiKey.source', 'panel')
            ->where('apiKey.masked', fn ($m) => str_ends_with($m, 'WXYZ') && ! str_contains($m, str_repeat('a', 20)))
        );

        $this->post('/admin/settings/api-key/test')->assertSessionHas('success', fn ($m) => str_contains($m, '1.25'));

        // Panel anahtarı .env'dekinden önceliklidir; silinince .env'e düşer.
        config(['ai.openrouter.key' => 'env-key-123']);
        $this->assertSame($key, AiCredentials::key());
        $this->delete('/admin/settings/api-key');
        $this->assertSame('env-key-123', AiCredentials::key());
        $this->assertSame('env', AiCredentials::source());
    }
}
