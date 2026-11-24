<?php

namespace App\Console\Commands;

use App\Services\ExchangeRateService;
use Illuminate\Console\Command;
use Throwable;

class SyncExchangeRate extends Command
{
    protected $signature = 'fx:sync {--force : Otomatik güncelleme kapalı olsa da çalıştır}';

    protected $description = 'USD/TL kurunu TCMB\'den (yoksa yedek kaynaktan) günceller';

    public function handle(ExchangeRateService $fx): int
    {
        if (! $fx->autoEnabled() && ! $this->option('force')) {
            $this->info('Otomatik kur güncellemesi kapalı; atlandı.');

            return self::SUCCESS;
        }

        try {
            $r = $fx->sync();
        } catch (Throwable $e) {
            $this->error('Kur alınamadı: '.$e->getMessage().' Mevcut kur korunuyor.');
            report($e);

            return self::FAILURE;
        }

        $this->info("USD/TL: {$r['previous']} → {$r['rate']} ({$r['source']})");

        return self::SUCCESS;
    }
}
