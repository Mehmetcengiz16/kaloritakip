<?php

namespace Database\Seeders;

use App\Models\Activity;
use App\Models\AiModel;
use App\Models\DietPlan;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Yönetici: bilgiler .env'deki ADMIN_EMAIL / ADMIN_PASSWORD'den gelir.
        if (env('ADMIN_EMAIL') && env('ADMIN_PASSWORD')) {
            $admin = User::updateOrCreate(
                ['email' => env('ADMIN_EMAIL')],
                ['name' => 'Yönetici', 'password' => env('ADMIN_PASSWORD')],
            );
            $admin->forceFill(['is_admin' => true])->save();
            $admin->profile()->firstOrCreate();
        }

        // Fiyatlar örnek değerdir: admin panelden OpenRouter'ın güncel fiyatlarıyla güncellenmeli.
        foreach ([
            ['slug' => env('OPENROUTER_VISION_MODEL', 'google/gemini-2.5-flash'), 'label' => 'Ana görsel modeli', 'purpose' => 'vision', 'priority' => 1, 'input_price_per_mtok' => 0.30, 'output_price_per_mtok' => 2.50],
            ['slug' => 'openai/gpt-4o-mini', 'label' => 'Yedek görsel modeli', 'purpose' => 'vision', 'priority' => 2, 'input_price_per_mtok' => 0.15, 'output_price_per_mtok' => 0.60],
            ['slug' => env('OPENROUTER_TEXT_MODEL', 'google/gemini-2.5-flash'), 'label' => 'Günlük öneri modeli', 'purpose' => 'text', 'priority' => 1, 'input_price_per_mtok' => 0.30, 'output_price_per_mtok' => 2.50],
        ] as $m) {
            AiModel::updateOrCreate(['slug' => $m['slug'], 'purpose' => $m['purpose']], $m);
        }

        foreach ([
            ['name' => 'Yürüyüş', 'icon' => 'footprints', 'met' => 3.5],
            ['name' => 'Bisiklet', 'icon' => 'bike', 'met' => 7.5],
            ['name' => 'Koşu', 'icon' => 'activity', 'met' => 9.8],
            ['name' => 'Yüzme', 'icon' => 'waves', 'met' => 7.0],
            ['name' => 'Fitness', 'icon' => 'dumbbell', 'met' => 5.0],
            ['name' => 'Yoga', 'icon' => 'flower', 'met' => 2.5],
        ] as $a) {
            Activity::updateOrCreate(['name' => $a['name']], $a);
        }

        $plans = [
            'lose' => ['Kilo Verme Planı', 2200, [
                ['breakfast', 'Kahvaltı', 'Yulaf, süt, muz, ceviz', 520],
                ['lunch', 'Öğle', 'Izgara tavuk, bulgur, salata', 620],
                ['snack2', 'Ara Öğün', 'Yoğurt, çilek', 150],
                ['dinner', 'Akşam', 'Zeytinyağlı sebze, yoğurt', 480],
            ]],
            'gain' => ['Kilo Alma Planı', 3000, [
                ['breakfast', 'Kahvaltı', 'Yumurta, peynir, tam buğday ekmek, avokado', 750],
                ['snack1', 'Ara Öğün', 'Fıstık ezmeli muz, süt', 400],
                ['lunch', 'Öğle', 'Kıymalı makarna, ayran', 850],
                ['dinner', 'Akşam', 'Somon, pilav, salata', 800],
            ]],
            'maintain' => ['Koruma Planı', 2500, [
                ['breakfast', 'Kahvaltı', 'Menemen, peynir, zeytin', 600],
                ['lunch', 'Öğle', 'Mercimek çorbası, tavuk sote', 700],
                ['snack2', 'Ara Öğün', 'Meyve, badem', 250],
                ['dinner', 'Akşam', 'Köfte, sebze, yoğurt', 700],
            ]],
        ];
        foreach ($plans as $goal => [$title, $kcal, $meals]) {
            $plan = DietPlan::updateOrCreate(['goal' => $goal, 'title' => $title], ['daily_kcal' => $kcal]);
            $plan->meals()->delete();
            foreach ($meals as $i => [$type, $mTitle, $desc, $mKcal]) {
                $plan->meals()->create(['meal_type' => $type, 'title' => $mTitle, 'description' => $desc, 'kcal' => $mKcal, 'sort' => $i]);
            }
        }

        $this->call(FoodSeeder::class);

        foreach ([
            'ai_free_daily_photo_limit' => env('AI_FREE_DAILY_PHOTO_LIMIT', 2),
            'ai_premium_daily_photo_limit' => env('AI_PREMIUM_DAILY_PHOTO_LIMIT', 30),
            'ai_daily_budget_usd' => env('AI_DAILY_BUDGET_USD', 5),
            'ai_cost_ratio_alert_pct' => 15,
            'store_fee_pct' => 15,
            'usd_try_rate' => 34,
        ] as $key => $value) {
            Setting::updateOrCreate(['key' => $key], ['value' => $value]);
        }
    }
}
