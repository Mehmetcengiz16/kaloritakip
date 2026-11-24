<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Throwable;

/**
 * USD/TL kuru: önce TCMB (resmî, döviz satış), ulaşılamazsa open.er-api.com.
 * İkisi de anahtar istemez ve ücretsizdir.
 */
class ExchangeRateService
{
    public const TCMB_URL = 'https://www.tcmb.gov.tr/kurlar/today.xml';
    public const FALLBACK_URL = 'https://open.er-api.com/v6/latest/USD';

    public function autoEnabled(): bool
    {
        return (bool) (int) Setting::get('usd_try_auto', 1);
    }

    /** @return array{rate: float, source: string} */
    public function fetch(): array
    {
        try {
            return ['rate' => $this->fromTcmb(), 'source' => 'TCMB'];
        } catch (Throwable $e) {
            report($e);
        }

        return ['rate' => $this->fromFallback(), 'source' => 'ExchangeRate-API'];
    }

    /** Kuru çekip ayarlara yazar. @return array{rate: float, source: string, previous: float} */
    public function sync(): array
    {
        $result = $this->fetch();
        $previous = (float) Setting::get('usd_try_rate', 0);

        Setting::put('usd_try_rate', $result['rate']);
        Setting::put('usd_try_source', $result['source']);
        Setting::put('usd_try_synced_at', now()->toIso8601String());

        return $result + ['previous' => $previous];
    }

    private function fromTcmb(): float
    {
        $res = Http::timeout(10)->get(self::TCMB_URL);
        if ($res->failed()) {
            throw new RuntimeException('TCMB kuru alınamadı ('.$res->status().').');
        }

        $previous = libxml_use_internal_errors(true);
        $xml = simplexml_load_string($res->body(), options: LIBXML_NONET);
        libxml_use_internal_errors($previous);

        $usd = $xml ? $xml->xpath('//Currency[@CurrencyCode="USD"]/ForexSelling') : null;

        return $this->validate((float) str_replace(',', '.', (string) ($usd[0] ?? '')), 'TCMB');
    }

    private function fromFallback(): float
    {
        $res = Http::timeout(10)->acceptJson()->get(self::FALLBACK_URL);
        if ($res->failed() || $res->json('result') !== 'success') {
            throw new RuntimeException('Yedek kur kaynağı da yanıt vermedi ('.$res->status().').');
        }

        return $this->validate((float) $res->json('rates.TRY'), 'ExchangeRate-API');
    }

    /** Bozuk/saçma veriyi kaydetmemek için makul aralık kontrolü. */
    private function validate(float $rate, string $source): float
    {
        if ($rate < 1 || $rate > 1000) {
            throw new RuntimeException("{$source} geçersiz kur döndürdü: {$rate}");
        }

        return round($rate, 4);
    }
}
