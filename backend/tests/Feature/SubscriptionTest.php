<?php

namespace Tests\Feature;

use App\Models\Setting;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SubscriptionTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        config(['revenuecat.webhook_secret' => 'Bearer gizli-webhook', 'revenuecat.secret_key' => 'sk_test']);
        Setting::put('usd_try_rate', 50);
        Setting::put('store_fee_pct', 15);
        $this->user = User::factory()->create();
        $this->user->profile()->create();
    }

    private function event(string $type, array $over = []): array
    {
        return ['event' => $over + [
            'type' => $type,
            'app_user_id' => (string) $this->user->id,
            'product_id' => 'premium_monthly',
            'store' => 'PLAY_STORE',
            'period_type' => 'NORMAL',
            'transaction_id' => 'GPA.1',
            'purchased_at_ms' => now()->getTimestampMs(),
            'expiration_at_ms' => now()->addMonth()->getTimestampMs(),
            'currency' => 'TRY',
            'price_in_purchased_currency' => 139.99,
            'price' => 2.8,
        ]];
    }

    private function hook(array $payload, string $auth = 'Bearer gizli-webhook')
    {
        return $this->postJson('/api/v1/webhooks/revenuecat', $payload, ['Authorization' => $auth]);
    }

    public function test_webhook_requires_secret(): void
    {
        $this->hook($this->event('INITIAL_PURCHASE'), 'Bearer yanlis')->assertUnauthorized();
        config(['revenuecat.webhook_secret' => null]);
        $this->hook($this->event('INITIAL_PURCHASE'))->assertUnauthorized();
        $this->assertFalse($this->user->fresh()->isPremium());
    }

    public function test_purchase_renewal_cancel_and_expiration(): void
    {
        $this->hook($this->event('INITIAL_PURCHASE'))->assertOk()->assertJson(['result' => 'active']);
        $this->assertTrue($this->user->fresh()->isPremium());
        $this->assertDatabaseHas('subscriptions', ['user_id' => $this->user->id, 'store' => 'play_store', 'price' => 139.99, 'store_fee' => 21.0, 'status' => 'active']);

        // Yenileme: yeni işlem kaydı, süre uzar.
        $this->hook($this->event('RENEWAL', ['transaction_id' => 'GPA.2', 'expiration_at_ms' => now()->addMonths(2)->getTimestampMs()]));
        $this->assertSame(2, Subscription::count());
        $this->assertTrue($this->user->fresh()->premium_until->gt(now()->addMonth()->addDays(20)));

        // İptal: süre sonuna kadar premium devam eder.
        $this->hook($this->event('CANCELLATION', ['cancel_reason' => 'UNSUBSCRIBE']))->assertJson(['result' => 'cancelled']);
        $this->assertTrue($this->user->fresh()->isPremium());

        // Süre doldu.
        $this->hook($this->event('EXPIRATION', ['expiration_at_ms' => now()->subMinute()->getTimestampMs()]))->assertJson(['result' => 'expired']);
        $this->assertFalse($this->user->fresh()->isPremium());
    }

    public function test_trial_is_free_and_usd_price_is_converted(): void
    {
        $this->hook($this->event('INITIAL_PURCHASE', ['period_type' => 'TRIAL', 'transaction_id' => 'T1']));
        $this->assertDatabaseHas('subscriptions', ['original_transaction_id' => 'T1', 'status' => 'trial', 'price' => 0]);

        $this->hook($this->event('RENEWAL', ['transaction_id' => 'T2', 'currency' => 'USD', 'price_in_purchased_currency' => 2.99, 'price' => 2.99]));
        $this->assertDatabaseHas('subscriptions', ['original_transaction_id' => 'T2', 'price' => 149.5]);
    }

    public function test_refund_closes_access_immediately(): void
    {
        $this->hook($this->event('INITIAL_PURCHASE'));
        $this->hook($this->event('CANCELLATION', ['cancel_reason' => 'CUSTOMER_SUPPORT']))->assertJson(['result' => 'refunded']);

        $this->assertFalse($this->user->fresh()->isPremium());
        $this->assertDatabaseHas('subscriptions', ['user_id' => $this->user->id, 'status' => 'refunded']);
    }

    public function test_unknown_user_is_ignored(): void
    {
        $this->hook($this->event('INITIAL_PURCHASE', ['app_user_id' => '$RCAnonymousID:abc']))->assertJson(['result' => 'ignored:unknown_user']);
    }

    public function test_status_and_sync_after_purchase(): void
    {
        Sanctum::actingAs($this->user);
        Http::fake(['api.revenuecat.com/*' => Http::response(['subscriber' => ['entitlements' => [
            'premium' => ['expires_date' => now()->addYear()->toIso8601String()],
        ]]])]);

        $this->getJson('/api/v1/subscription')->assertOk()
            ->assertJsonPath('data.is_premium', false)
            ->assertJsonPath('data.quota.remaining', 2)
            ->assertJsonPath('data.limits.premium_daily', 30);

        $this->postJson('/api/v1/subscription/sync')->assertOk()
            ->assertJsonPath('data.is_premium', true)
            ->assertJsonPath('data.quota.limit', 30);

        Http::assertSent(fn ($r) => str_ends_with($r->url(), '/subscribers/'.$this->user->id) && $r->hasHeader('Authorization', 'Bearer sk_test'));
        $this->getJson('/api/v1/dashboard')->assertJsonPath('data.ai_quota.limit', 30);
    }
}
