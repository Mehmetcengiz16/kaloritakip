<?php

namespace Database\Seeders;

use App\Models\ActivityLog;
use App\Models\AiAnalysis;
use App\Models\Expense;
use App\Models\Food;
use App\Models\Meal;
use App\Models\Setting;
use App\Models\Subscription;
use App\Models\User;
use App\Models\WaterLog;
use App\Models\WeightLog;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

/**
 * Admin paneli ve uygulamayı denemek için örnek veri.
 * YALNIZCA geliştirme/demo veritabanında çalıştırın:  php artisan db:seed --class=DemoSeeder
 *
 * - 60 demo kullanıcı (…@demo.kaloritakip.test), bir kısmı Premium
 * - Son 60 günün abonelik gelirleri, AI analiz maliyetleri ve giderler
 * - demo@kaloritakip.test / demo12345 : öğün, kilo, su ve aktivite geçmişi dolu mobil test hesabı
 */
class DemoSeeder extends Seeder
{
    public function run(): void
    {
        abort_if(app()->environment('production'), 403, 'DemoSeeder canlı ortamda çalıştırılamaz.');

        $this->call(DatabaseSeeder::class);
        mt_srand(42); // her çalıştırmada aynı veri

        $names = ['Ayşe', 'Mehmet', 'Zeynep', 'Ali', 'Elif', 'Can', 'Selin', 'Burak', 'Deniz', 'Ece', 'Emre', 'Merve', 'Kerem', 'İrem', 'Onur'];
        $surnames = ['Yılmaz', 'Kaya', 'Demir', 'Şahin', 'Çelik', 'Arslan', 'Doğan', 'Kılıç', 'Aydın', 'Öztürk'];
        $goals = ['lose', 'lose', 'lose', 'gain', 'maintain', 'healthy'];
        $rate = (float) Setting::get('usd_try_rate', 50);

        for ($i = 1; $i <= 60; $i++) {
            $created = now()->subDays(mt_rand(0, 75))->subMinutes(mt_rand(0, 1440));
            $user = User::firstOrCreate(
                ['email' => "kullanici{$i}@demo.kaloritakip.test"],
                ['name' => $names[array_rand($names)].' '.$surnames[array_rand($surnames)], 'password' => 'demo12345'],
            );
            $user->forceFill(['created_at' => $created])->save();
            $weight = mt_rand(55, 110);
            $user->profile()->updateOrCreate([], [
                'goal' => $goals[array_rand($goals)], 'gender' => mt_rand(0, 1) ? 'female' : 'male',
                'birth_date' => now()->subYears(mt_rand(19, 55)), 'height_cm' => mt_rand(155, 192),
                'weight_kg' => $weight, 'target_weight_kg' => $weight - mt_rand(3, 15), 'activity_level' => 'light',
                'daily_kcal_target' => mt_rand(16, 27) * 100,
            ]);

            // ~%33 premium: yıllık veya aylık abonelik
            if ($i % 3 === 0) {
                $yearly = $i % 2 === 0;
                $started = $created->copy()->addDays(mt_rand(0, 7));
                if ($started->isFuture()) {
                    $started = now();
                }
                $price = $yearly ? 949.99 : 139.99;
                Subscription::updateOrCreate(
                    ['user_id' => $user->id, 'original_transaction_id' => "DEMO-{$i}"],
                    [
                        'store' => $i % 5 < 2 ? 'app_store' : 'play_store',
                        'product_id' => $yearly ? 'premium_annual' : 'premium_monthly',
                        'status' => 'active', 'started_at' => $started,
                        'expires_at' => $started->copy()->add($yearly ? '1 year' : '1 month'),
                        'price' => $price, 'store_fee' => round($price * 0.15, 2), 'currency' => 'TRY',
                    ],
                );
                $user->forceFill(['premium_until' => $started->copy()->add($yearly ? '1 year' : '1 month')])->save();
            }

            // AI analizleri ve maliyetleri (son 30 gün)
            $count = mt_rand(2, $i % 3 === 0 ? 40 : 12);
            for ($a = 0; $a < $count; $a++) {
                $cached = mt_rand(1, 100) <= 18;
                $at = now()->subDays(mt_rand(0, 29))->setTime(mt_rand(7, 22), mt_rand(0, 59));
                AiAnalysis::create([
                    'user_id' => $user->id,
                    'image_hash' => hash('sha256', "demo-{$i}-{$a}"),
                    'model' => 'google/gemini-2.5-flash',
                    'prompt_tokens' => $cached ? 0 : mt_rand(1050, 1300),
                    'completion_tokens' => $cached ? 0 : mt_rand(120, 420),
                    'cost_usd' => $cached ? 0 : mt_rand(25, 90) / 100000,
                    'from_cache' => $cached,
                    'status' => mt_rand(1, 100) <= 4 ? 'not_food' : 'done',
                    'result_json' => ['is_food' => true, 'total_kcal' => mt_rand(250, 900), 'items' => [
                        ['name' => 'Tavuk ızgara', 'grams' => 120, 'kcal' => 198, 'protein' => 37, 'carb' => 0, 'fat' => 4, 'confidence' => 0.9],
                        ['name' => 'Bulgur pilavı', 'grams' => 150, 'kcal' => 225, 'protein' => 6, 'carb' => 39, 'fat' => 5, 'confidence' => 0.8],
                    ]],
                    'latency_ms' => mt_rand(2200, 7400),
                    'created_at' => $at, 'updated_at' => $at,
                ]);
            }
        }

        // Aylık sabit giderler
        foreach ([[2, 'server', 'Sunucu (VPS)', 1450], [3, 'storage', 'Depolama / CDN', 260], [10, 'marketing', 'Sosyal medya reklamı', 1200], [32, 'server', 'Sunucu (VPS)', 1450], [40, 'marketing', 'Sosyal medya reklamı', 1000]] as [$d, $c, $desc, $amt]) {
            Expense::firstOrCreate(['category' => $c, 'description' => $desc, 'date' => now()->subDays($d)->toDateString()], ['amount' => $amt, 'currency' => 'TRY']);
        }

        // AI'dan öğrenilmiş, onay bekleyen yemekler
        foreach ([['Etli kuru fasulye', 135], ['Fırın sütlaç', 145], ['Tavuk döner dürüm', 230]] as [$n, $k]) {
            Food::firstOrCreate(['name' => $n, 'source' => 'ai'], ['kcal_per_100g' => $k, 'protein_per_100g' => 8, 'carb_per_100g' => 15, 'fat_per_100g' => 6, 'default_portion_g' => 200, 'verified' => false]);
        }

        $this->demoAppUser();
        $this->command?->info('Demo veri hazır. Mobil test hesabı: demo@kaloritakip.test / demo12345 (kur: '.$rate.' ₺)');
    }

    /** Mobil uygulamada dolu ekranlar için: 21 günlük öğün, kilo, su ve aktivite geçmişi. */
    private function demoAppUser(): void
    {
        $user = User::firstOrCreate(['email' => 'demo@kaloritakip.test'], ['name' => 'Ayşe Demir', 'password' => 'demo12345']);
        $user->profile()->updateOrCreate([], [
            'goal' => 'lose', 'gender' => 'female', 'birth_date' => now()->subYears(29), 'height_cm' => 168,
            'weight_kg' => 71.4, 'target_weight_kg' => 64, 'activity_level' => 'moderate',
            'daily_kcal_target' => 1850, 'protein_g' => 140, 'carb_g' => 190, 'fat_g' => 55, 'water_ml_target' => 2500,
        ]);

        $menu = [
            'breakfast' => [['Yulaf ezmesi', 50], ['Muz', 120], ['Ceviz', 15]],
            'lunch' => [['Tavuk göğsü ızgara', 150], ['Bulgur pilavı', 120], ['Çoban salata', 150]],
            'snack2' => [['Yoğurt (tam yağlı)', 150], ['Çilek', 120]],
            'dinner' => [['Mercimek çorbası', 250], ['Zeytinyağlı taze fasulye', 200]],
        ];

        for ($d = 20; $d >= 0; $d--) {
            $date = now()->subDays($d)->toDateString();
            WeightLog::updateOrCreate(['user_id' => $user->id, 'date' => $date], ['weight_kg' => round(74.6 - (20 - $d) * 0.16 + mt_rand(-2, 2) / 10, 1)]);
            WaterLog::where('user_id', $user->id)->whereDate('date', $date)->delete();
            WaterLog::create(['user_id' => $user->id, 'date' => $date, 'amount_ml' => mt_rand(7, 11) * 250]);
            if ($d % 2 === 0) {
                ActivityLog::updateOrCreate(['user_id' => $user->id, 'date' => $date, 'name' => 'Yürüyüş'], ['minutes' => 40, 'kcal' => 170]);
            }

            foreach ($menu as $type => $items) {
                if ($d === 0 && $type === 'dinner') {
                    continue; // bugün akşam yemeği henüz yenmedi: kalan kalori görünür
                }
                $meal = Meal::firstOrCreate(['user_id' => $user->id, 'date' => $date, 'type' => $type]);
                $meal->items()->delete();
                foreach ($items as [$name, $grams]) {
                    $food = Food::where('name', $name)->first();
                    if (! $food) {
                        continue;
                    }
                    $g = (int) round($grams * mt_rand(85, 120) / 100);
                    $k = $g / 100;
                    $meal->items()->create([
                        'food_id' => $food->id, 'name' => $food->name, 'grams' => $g,
                        'kcal' => (int) round($food->kcal_per_100g * $k),
                        'protein' => round($food->protein_per_100g * $k, 1),
                        'carb' => round($food->carb_per_100g * $k, 1),
                        'fat' => round($food->fat_per_100g * $k, 1),
                    ]);
                }
            }
        }
    }
}
