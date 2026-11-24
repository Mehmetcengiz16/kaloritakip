<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\Meal;
use App\Models\User;
use App\Models\WaterLog;
use App\Models\WeightLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProgressInsightsTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->user->profile()->create([
            'goal' => 'lose', 'height_cm' => 180, 'weight_kg' => 86, 'target_weight_kg' => 80,
            'daily_kcal_target' => 2000, 'protein_g' => 150, 'carb_g' => 200, 'fat_g' => 60,
        ]);
        Sanctum::actingAs($this->user);
    }

    private function eat(int $daysAgo, int $kcal, float $p = 0, float $c = 0, float $f = 0): void
    {
        $meal = Meal::firstOrCreate(['user_id' => $this->user->id, 'date' => now()->subDays($daysAgo)->toDateString(), 'type' => 'lunch']);
        $meal->items()->create(['name' => 'X', 'grams' => 100, 'kcal' => $kcal, 'protein' => $p, 'carb' => $c, 'fat' => $f]);
    }

    private function weigh(int $daysAgo, float $kg): void
    {
        WeightLog::create(['user_id' => $this->user->id, 'date' => now()->subDays($daysAgo)->toDateString(), 'weight_kg' => $kg]);
    }

    public function test_goal_progress_and_eta(): void
    {
        // 90 -> 86 kg, hedef 80: 4/10 = %40; 20 günde 4 kg (0,2 kg/gün) -> kalan 6 kg ≈ 30 gün
        foreach ([[20, 90], [15, 89], [10, 88], [5, 87], [0, 86]] as [$d, $kg]) {
            $this->weigh($d, $kg);
        }

        $goal = $this->getJson('/api/v1/progress')->assertOk()->json('data.goal');

        $this->assertEquals(90, $goal['start_kg']);
        $this->assertSame(40, $goal['progress_pct']);
        $this->assertEquals(6, $goal['remaining_kg']);
        $this->assertFalse($goal['reached']);
        $this->assertSame(now()->addDays(30)->toDateString(), $goal['eta_date']);
    }

    public function test_goal_is_null_without_target_or_for_maintain(): void
    {
        $this->weigh(0, 86);
        $this->user->profile->update(['goal' => 'maintain']);
        $this->getJson('/api/v1/progress')->assertJsonPath('data.goal', null);
    }

    public function test_calories_bars_average_and_on_target_days(): void
    {
        $this->eat(0, 1900);
        $this->eat(1, 2150); // %10 tolerans içinde -> hedefte
        $this->eat(2, 2600); // hedef aşıldı
        $this->eat(10, 1500); // haftalık aralık dışı

        $cal = $this->getJson('/api/v1/progress?range=week')->json('data.calories');

        $this->assertCount(7, $cal['bars']);
        $this->assertSame(1900, end($cal['bars'])['kcal']);
        $this->assertSame(0, $cal['bars'][0]['kcal']); // kayıt olmayan gün 0
        $this->assertSame(2217, $cal['avg']);           // (1900+2150+2600)/3
        $this->assertSame(3, $cal['logged_days']);
        $this->assertSame(2, $cal['on_target_days']);
        $this->assertSame(2000, $cal['target']);
    }

    public function test_macros_average_and_share(): void
    {
        $this->eat(0, 1000, 100, 100, 22.2);
        $this->eat(1, 1000, 50, 100, 22.2);

        $m = $this->getJson('/api/v1/progress')->json('data.macros');

        $this->assertSame(75, $m['protein']['avg']);
        $this->assertSame(150, $m['protein']['target']);
        // 75*4=300, 100*4=400, 22*9=198 -> toplam 898
        $this->assertSame(33, $m['protein']['pct']);
        $this->assertSame(45, $m['carb']['pct']);
        $this->assertSame(22, $m['fat']['pct']);
    }

    public function test_habits_streak_water_activity(): void
    {
        // Bugün kayıt yok; dün, önceki gün ve ondan önceki gün var; 5 gün önce kopuk.
        foreach ([1, 2, 3, 5] as $d) {
            $this->eat($d, 1800);
        }
        WaterLog::create(['user_id' => $this->user->id, 'date' => now()->toDateString(), 'amount_ml' => 2000]);
        WaterLog::create(['user_id' => $this->user->id, 'date' => now()->subDay()->toDateString(), 'amount_ml' => 1000]);
        ActivityLog::create(['user_id' => $this->user->id, 'name' => 'Yürüyüş', 'date' => now()->toDateString(), 'minutes' => 30, 'kcal' => 140]);

        $h = $this->getJson('/api/v1/progress?range=week')->json('data.habits');

        $this->assertSame(3, $h['streak_days']);
        $this->assertSame(4, $h['logged_days']);
        $this->assertSame(7, $h['period_days']);
        $this->assertSame(1500, $h['avg_water_ml']);
        $this->assertSame(140, $h['activity_kcal']);
    }

    public function test_yearly_calories_are_monthly_averages(): void
    {
        $this->eat(0, 2000);
        $this->eat(40, 1000);

        $bars = $this->getJson('/api/v1/progress?range=year')->json('data.calories.bars');
        $this->assertCount(2, $bars);
        $this->assertStringEndsWith('-01', $bars[0]['date']);
    }
}
