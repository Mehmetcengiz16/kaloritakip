<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiModel;
use App\Models\Setting;
use App\Services\Ai\AiCredentials;
use App\Services\Ai\OpenRouterCatalog;
use App\Services\Ai\OpenRouterClient;
use App\Services\ExchangeRateService;
use Throwable;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

/** AI modelleri (ana/yedek, fiyatlar) ve kota/bütçe ayarları. */
class SettingsController extends Controller
{
    public const KEYS = [
        'ai_free_daily_photo_limit' => ['required', 'integer', 'between:0,50'],
        'ai_premium_daily_photo_limit' => ['required', 'integer', 'between:1,200'],
        'ai_daily_budget_usd' => ['required', 'numeric', 'between:0,10000'],
        'ai_cost_ratio_alert_pct' => ['required', 'numeric', 'between:1,100'],
        'store_fee_pct' => ['required', 'numeric', 'between:0,50'],
        'usd_try_rate' => ['required', 'numeric', 'between:1,1000'],
    ];

    public function index()
    {
        return Inertia::render('Settings/Index', [
            'models' => AiModel::orderBy('purpose')->orderBy('priority')->get()->map(fn (AiModel $m) => [
                'id' => $m->id,
                'slug' => $m->slug,
                'label' => $m->label,
                'purpose' => $m->purpose,
                'priority' => $m->priority,
                'is_active' => $m->is_active,
                'input_price_per_mtok' => (float) $m->input_price_per_mtok,
                'output_price_per_mtok' => (float) $m->output_price_per_mtok,
            ]),
            'settings' => collect(array_keys(self::KEYS))
                ->mapWithKeys(fn ($k) => [$k => (float) Setting::get($k, config('ai.'.str_replace('ai_', '', $k), 0))]),
            'pricesSyncedAt' => Setting::get('ai_prices_synced_at'),
            'fx' => [
                'auto' => (bool) (int) Setting::get('usd_try_auto', 1),
                'source' => Setting::get('usd_try_source'),
                'synced_at' => Setting::get('usd_try_synced_at'),
            ],
            'apiKey' => [
                'configured' => AiCredentials::key() !== null,
                'masked' => AiCredentials::masked(),
                'source' => AiCredentials::source(),
            ],
        ]);
    }

    public function updateSettings(Request $request, ExchangeRateService $fx)
    {
        $data = $request->validate(self::KEYS + ['usd_try_auto' => ['required', 'boolean']]);
        $auto = (bool) $data['usd_try_auto'];
        $wasAuto = $fx->autoEnabled();
        unset($data['usd_try_auto']);

        // Otomatik kur açıkken formdaki (eski) kur yazılmaz; kur kaynaktan gelir.
        if ($auto) {
            unset($data['usd_try_rate']);
        }
        foreach ($data as $key => $value) {
            Setting::put($key, $value);
        }
        Setting::put('usd_try_auto', $auto ? 1 : 0);
        if (! $auto) {
            Setting::put('usd_try_source', 'Manuel');
        }

        // Otomatik yeni açıldıysa kuru hemen güncelle.
        if ($auto && ! $wasAuto) {
            try {
                $r = $fx->sync();

                return back()->with('success', 'Ayarlar kaydedildi. Güncel kur: '.number_format($r['rate'], 4, ',', '.').' ₺ ('.$r['source'].')');
            } catch (Throwable $e) {
                report($e);

                return back()->with('error', 'Ayarlar kaydedildi ama kur alınamadı; bir sonraki otomatik denemede güncellenecek.');
            }
        }

        return back()->with('success', 'Ayarlar kaydedildi.');
    }

    /** "Şimdi güncelle": kuru hemen kaynaktan çeker. */
    public function syncFx(ExchangeRateService $fx)
    {
        try {
            $r = $fx->sync();
        } catch (Throwable $e) {
            report($e);

            return back()->with('error', 'Kur alınamadı. Mevcut kur korunuyor.');
        }

        return back()->with('success', 'USD/TL: '.number_format($r['rate'], 4, ',', '.').' ₺ ('.$r['source'].')');
    }

    /** Anahtarı kaydetmeden önce OpenRouter'da doğrular; geçersizse kaydetmez. */
    public function updateApiKey(Request $request, OpenRouterClient $client)
    {
        $key = trim($request->validate([
            'api_key' => ['required', 'string', 'min:20', 'max:200', 'regex:/^\S+$/'],
        ], ['api_key.regex' => 'Anahtar boşluk içeremez.'])['api_key']);

        $check = $client->checkKey($key);
        if (! $check['ok']) {
            return back()->withErrors(['api_key' => $check['message']]);
        }

        AiCredentials::store($key);

        return back()->with('success', 'OpenRouter anahtarı doğrulandı ve kaydedildi.');
    }

    public function destroyApiKey()
    {
        AiCredentials::forget();

        return back()->with('success', AiCredentials::source() === 'env'
            ? 'Paneldeki anahtar silindi; .env dosyasındaki anahtar kullanılacak.'
            : 'OpenRouter anahtarı silindi. Fotoğraf analizi anahtar girilene kadar çalışmaz.');
    }

    /** Kayıtlı anahtarı test eder; kullanım ve kredi limitini döndürür. */
    public function testApiKey(OpenRouterClient $client)
    {
        $key = AiCredentials::key();
        if (! $key) {
            return back()->with('error', 'Kayıtlı bir anahtar yok.');
        }

        $check = $client->checkKey($key);
        if (! $check['ok']) {
            return back()->with('error', $check['message']);
        }

        $usage = $check['usage'] !== null ? ' Kullanım: $'.number_format($check['usage'], 2) : '';
        $limit = $check['limit'] !== null ? ' / limit: $'.number_format($check['limit'], 2) : '';

        return back()->with('success', 'Bağlantı başarılı.'.$usage.$limit);
    }

    /** "Fiyatları güncelle" butonu: kayıtlı modellerin fiyatlarını OpenRouter'dan çeker. */
    public function syncPrices(OpenRouterCatalog $catalog)
    {
        try {
            $result = $catalog->syncPrices();
        } catch (Throwable $e) {
            report($e);

            return back()->with('error', "OpenRouter'dan fiyatlar alınamadı. Biraz sonra tekrar dene.");
        }

        $msg = count($result['updated'])
            ? count($result['updated']).' modelin fiyatı güncellendi.'
            : 'Fiyatlar zaten güncel.';
        if ($result['missing']) {
            return back()->with('error', $msg." OpenRouter'da bulunamayan: ".implode(', ', $result['missing']));
        }

        return back()->with('success', $msg);
    }

    /** Model ekleme penceresindeki arama: OpenRouter kataloğundan, fiyatlarıyla. */
    public function catalog(Request $request, OpenRouterCatalog $catalog)
    {
        $data = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'purpose' => ['nullable', Rule::in(['vision', 'text'])],
        ]);

        try {
            return response()->json(['data' => $catalog->search($data['q'] ?? null, ($data['purpose'] ?? null) === 'vision')]);
        } catch (Throwable $e) {
            report($e);

            return response()->json(['message' => "OpenRouter model listesi alınamadı."], 502);
        }
    }

    public function storeModel(Request $request, OpenRouterCatalog $catalog)
    {
        $data = $this->validated($request);
        try {
            if ($remote = $catalog->find($data['slug'])) {
                $data['input_price_per_mtok'] = $remote['input_price_per_mtok'];
                $data['output_price_per_mtok'] = $remote['output_price_per_mtok'];
            }
        } catch (Throwable) {
            // Katalog alınamazsa formdaki fiyatlar kullanılır.
        }
        AiModel::create($data);

        return back()->with('success', 'Model eklendi.');
    }

    public function updateModel(Request $request, AiModel $model)
    {
        $model->update($this->validated($request, $model));

        return back()->with('success', "{$model->slug} güncellendi.");
    }

    public function destroyModel(AiModel $model)
    {
        $model->delete();

        return back()->with('success', "{$model->slug} silindi.");
    }

    private function validated(Request $request, ?AiModel $model = null): array
    {
        return $request->validate([
            'slug' => [
                'required', 'string', 'max:150', 'regex:/^[a-z0-9._\-]+\/[a-zA-Z0-9._:\-]+$/',
                Rule::unique('ai_models')->where('purpose', $request->input('purpose'))->ignore($model?->id),
            ],
            'label' => ['required', 'string', 'max:100'],
            'purpose' => ['required', Rule::in(['vision', 'text'])],
            'priority' => ['required', 'integer', 'between:1,9'],
            'is_active' => ['required', 'boolean'],
            'input_price_per_mtok' => ['required', 'numeric', 'between:0,1000'],
            'output_price_per_mtok' => ['required', 'numeric', 'between:0,1000'],
        ], ['slug.regex' => 'OpenRouter model kimliği "saglayici/model" biçiminde olmalı.']);
    }
}
