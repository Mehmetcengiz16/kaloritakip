<?php

namespace Tests\Feature;

use App\Models\Setting;
use App\Models\User;
use App\Services\ExchangeRateService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ExchangeRateTest extends TestCase
{
    use RefreshDatabase;

    private const TCMB_XML = '<?xml version="1.0" encoding="UTF-8"?><Tarih_Date><Currency CrossOrder="0" Kod="USD" CurrencyCode="USD"><Unit>1</Unit><ForexBuying>50.5376</ForexBuying><ForexSelling>50.6286</ForexSelling></Currency><Currency Kod="EUR" CurrencyCode="EUR"><ForexSelling>58.1</ForexSelling></Currency></Tarih_Date>';

    private function settingsPayload(array $over = []): array
    {
        return $over + [
            'ai_free_daily_photo_limit' => 2, 'ai_premium_daily_photo_limit' => 30, 'ai_daily_budget_usd' => 5,
            'ai_cost_ratio_alert_pct' => 15, 'store_fee_pct' => 15, 'usd_try_rate' => 34, 'usd_try_auto' => true,
        ];
    }

    public function test_command_reads_tcmb_forex_selling(): void
    {
        Http::fake([ExchangeRateService::TCMB_URL => Http::response(self::TCMB_XML)]);

        $this->artisan('fx:sync')->expectsOutputToContain('50.6286')->assertSuccessful();

        $this->assertEquals(50.6286, (float) Setting::get('usd_try_rate'));
        $this->assertSame('TCMB', Setting::get('usd_try_source'));
    }

    public function test_falls_back_when_tcmb_is_down_and_keeps_rate_when_all_fail(): void
    {
        Http::fake([
            ExchangeRateService::TCMB_URL => Http::response('', 503),
            ExchangeRateService::FALLBACK_URL => Http::response(['result' => 'success', 'rates' => ['TRY' => 50.71]]),
        ]);
        $this->artisan('fx:sync')->assertSuccessful();
        $this->assertSame('ExchangeRate-API', Setting::get('usd_try_source'));
        $this->assertEquals(50.71, (float) Setting::get('usd_try_rate'));
    }

    public function test_invalid_data_does_not_overwrite_rate(): void
    {
        Setting::put('usd_try_rate', 50);
        Http::fake([
            ExchangeRateService::TCMB_URL => Http::response('<bozuk'),
            ExchangeRateService::FALLBACK_URL => Http::response(['result' => 'success', 'rates' => ['TRY' => 0]]),
        ]);

        $this->artisan('fx:sync')->assertFailed();
        $this->assertEquals(50, (float) Setting::get('usd_try_rate'));
    }

    public function test_command_skips_when_auto_disabled(): void
    {
        Setting::put('usd_try_auto', 0);
        Http::fake();

        $this->artisan('fx:sync')->expectsOutputToContain('kapalı')->assertSuccessful();
        Http::assertNothingSent();
    }

    public function test_admin_toggle_and_manual_rate(): void
    {
        Http::fake([ExchangeRateService::TCMB_URL => Http::response(self::TCMB_XML)]);
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        $this->actingAs($admin);

        // Elle kur: girilen değer kaydedilir.
        $this->put('/admin/settings', $this->settingsPayload(['usd_try_auto' => false, 'usd_try_rate' => 42]))->assertSessionHasNoErrors();
        $this->assertEquals(42, (float) Setting::get('usd_try_rate'));
        $this->assertSame('Manuel', Setting::get('usd_try_source'));

        // Otomatiğe geçince formdaki eski kur yok sayılır ve kur hemen çekilir.
        $this->put('/admin/settings', $this->settingsPayload(['usd_try_rate' => 34]))->assertSessionHas('success');
        $this->assertEquals(50.6286, (float) Setting::get('usd_try_rate'));

        // "Şimdi güncelle"
        $this->post('/admin/settings/fx-sync')->assertSessionHas('success', fn ($m) => str_contains($m, '50,6286'));
    }
}
