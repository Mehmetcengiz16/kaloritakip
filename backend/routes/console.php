<?php

use Illuminate\Support\Facades\Schedule;

// Sunucuda cron gerekir: * * * * * php artisan schedule:run

// OpenRouter fiyatları her gün güncellenir.
Schedule::command('ai:sync-prices')->dailyAt('04:00')->withoutOverlapping();

// USD/TL kuru: TCMB kurları hafta içi ~15:30'da yayınlar; gün içinde birkaç kez kontrol edilir.
Schedule::command('fx:sync')->cron('5 9,12,16,20 * * *')->withoutOverlapping();
