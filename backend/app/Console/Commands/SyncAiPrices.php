<?php

namespace App\Console\Commands;

use App\Services\Ai\OpenRouterCatalog;
use Illuminate\Console\Command;
use Throwable;

class SyncAiPrices extends Command
{
    protected $signature = 'ai:sync-prices';

    protected $description = 'Kayıtlı AI modellerinin fiyatlarını OpenRouter\'dan günceller';

    public function handle(OpenRouterCatalog $catalog): int
    {
        try {
            $result = $catalog->syncPrices();
        } catch (Throwable $e) {
            $this->error($e->getMessage());
            report($e);

            return self::FAILURE;
        }

        foreach ($result['updated'] as $u) {
            $this->line(sprintf('%s: $%s/$%s → $%s/$%s', $u['slug'], $u['old'][0], $u['old'][1], $u['new'][0], $u['new'][1]));
        }
        foreach ($result['missing'] as $slug) {
            $this->warn("{$slug}: OpenRouter'da bulunamadı (model kaldırılmış veya adı değişmiş olabilir).");
        }
        $this->info(count($result['updated']).' model güncellendi.');

        return self::SUCCESS;
    }
}
