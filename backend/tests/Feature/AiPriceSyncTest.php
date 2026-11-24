<?php

namespace Tests\Feature;

use App\Models\AiModel;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiPriceSyncTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutVite();
        Cache::flush();
        $this->admin = User::factory()->create();
        $this->admin->forceFill(['is_admin' => true])->save();

    }

    private function fakeCatalog(): void
    {
        Http::fake(['openrouter.ai/api/v1/models' => Http::response(['data' => [
            [
                'id' => 'google/gemini-2.5-flash', 'name' => 'Google: Gemini 2.5 Flash',
                'pricing' => ['prompt' => '0.0000003', 'completion' => '0.0000025'],
                'architecture' => ['input_modalities' => ['text', 'image']], 'context_length' => 1048576,
            ],
            [
                'id' => 'openai/gpt-4o-mini', 'name' => 'OpenAI: GPT-4o-mini',
                'pricing' => ['prompt' => '0.00000015', 'completion' => '0.0000006'],
                'architecture' => ['input_modalities' => ['text', 'image']],
            ],
            [
                'id' => 'meta/text-only', 'name' => 'Text Only',
                'pricing' => ['prompt' => '0.0000001', 'completion' => '0.0000001'],
                'architecture' => ['input_modalities' => ['text']],
            ],
            [
                'id' => 'openrouter/auto', 'name' => 'Auto Router',
                'pricing' => ['prompt' => '-1', 'completion' => '-1'],
            ],
        ]])]);
    }

    public function test_sync_command_updates_prices_and_reports_missing_models(): void
    {
        $this->fakeCatalog();
        AiModel::create(['slug' => 'google/gemini-2.5-flash', 'label' => 'Ana', 'purpose' => 'vision', 'input_price_per_mtok' => 9, 'output_price_per_mtok' => 9]);
        AiModel::create(['slug' => 'google/gemini-2.5-flash', 'label' => 'Metin', 'purpose' => 'text', 'input_price_per_mtok' => 9, 'output_price_per_mtok' => 9]);
        AiModel::create(['slug' => 'removed/model', 'label' => 'Eski', 'purpose' => 'vision', 'priority' => 2]);

        $this->artisan('ai:sync-prices')
            ->expectsOutputToContain('removed/model')
            ->expectsOutputToContain('2 model güncellendi')
            ->assertSuccessful();

        $m = AiModel::where('purpose', 'vision')->where('slug', 'google/gemini-2.5-flash')->first();
        $this->assertEquals(0.3, (float) $m->input_price_per_mtok);
        $this->assertEquals(2.5, (float) $m->output_price_per_mtok);
        $this->assertNotNull(Setting::get('ai_prices_synced_at'));
    }

    public function test_admin_sync_button_and_catalog_search(): void
    {
        $this->fakeCatalog();
        AiModel::create(['slug' => 'openai/gpt-4o-mini', 'label' => 'Yedek', 'purpose' => 'vision', 'input_price_per_mtok' => 1, 'output_price_per_mtok' => 1]);
        $this->actingAs($this->admin);

        $this->post('/admin/ai-models/sync-prices')->assertSessionHas('success', '1 modelin fiyatı güncellendi.');
        $this->assertEquals(0.15, (float) AiModel::first()->input_price_per_mtok);

        // Sadece görsel destekleyenler, ucuzdan pahalıya; değişken fiyatlı "auto" yok.
        $slugs = collect($this->getJson('/admin/ai-catalog?purpose=vision')->assertOk()->json('data'))->pluck('slug')->all();
        $this->assertSame(['openai/gpt-4o-mini', 'google/gemini-2.5-flash'], $slugs);

        $this->getJson('/admin/ai-catalog?purpose=text&q=text')->assertJsonPath('data.0.slug', 'meta/text-only');
    }

    public function test_new_model_takes_prices_from_catalog(): void
    {
        $this->fakeCatalog();
        $this->actingAs($this->admin)->post('/admin/ai-models', [
            'slug' => 'google/gemini-2.5-flash', 'label' => 'Gemini', 'purpose' => 'vision', 'priority' => 1,
            'is_active' => true, 'input_price_per_mtok' => 0, 'output_price_per_mtok' => 0,
        ])->assertSessionHasNoErrors();

        $this->assertEquals(2.5, (float) AiModel::first()->output_price_per_mtok);
    }

    public function test_catalog_failure_is_handled(): void
    {
        Http::fake(['openrouter.ai/*' => Http::response('down', 500)]);
        Cache::flush();
        $this->actingAs($this->admin);

        $this->getJson('/admin/ai-catalog')->assertStatus(502);
        $this->post('/admin/ai-models/sync-prices')->assertSessionHas('error');
        $this->artisan('ai:sync-prices')->assertFailed();
    }
}
