<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WeightLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProgressTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->user->profile()->create([
            'gender' => 'male', 'birth_date' => now()->subYears(30), 'height_cm' => 180,
            'weight_kg' => 90, 'goal' => 'lose', 'activity_level' => 'light', 'daily_kcal_target' => 2100,
        ]);
        Sanctum::actingAs($this->user);
    }

    private function log(int $daysAgo, float $kg, ?float $fat = null): void
    {
        WeightLog::create(['user_id' => $this->user->id, 'date' => now()->subDays($daysAgo)->toDateString(), 'weight_kg' => $kg, 'body_fat_pct' => $fat]);
    }

    public function test_weekly_progress_uses_last_measurement_before_range_as_baseline(): void
    {
        $this->log(10, 92.0);         // aralık dışı -> başlangıç
        $this->log(6, 91.0, 25.0);
        $this->log(3, 90.4);
        $this->log(0, 89.2, 23.6);

        $this->getJson('/api/v1/progress?range=week')
            ->assertOk()
            ->assertJsonPath('data.current_weight_kg', 89.2)
            ->assertJsonPath('data.weight_change_kg', -2.8)
            ->assertJsonPath('data.body_fat_pct', 23.6)
            ->assertJsonPath('data.body_fat_change_pct', -1.4)
            ->assertJsonPath('data.bmi', 27.5)
            ->assertJsonCount(3, 'data.points');
    }

    public function test_yearly_progress_returns_monthly_averages(): void
    {
        $this->log(0, 90.0);
        $this->log(1, 91.0);
        $this->log(70, 95.0);

        $points = $this->getJson('/api/v1/progress?range=year')->assertOk()->json('data.points');
        $this->assertGreaterThanOrEqual(2, count($points));
        $this->assertStringEndsWith('-01', $points[0]['date']);
    }

    public function test_store_weight_updates_profile_and_recalculates_targets(): void
    {
        $this->postJson('/api/v1/weight-logs', ['weight_kg' => 80])->assertCreated();
        $this->postJson('/api/v1/weight-logs', ['weight_kg' => 79.5])->assertCreated(); // aynı gün güncellenir

        $this->assertSame(1, WeightLog::count());
        $profile = $this->user->profile()->first();
        $this->assertEquals(79.5, (float) $profile->weight_kg);
        $this->assertNotEquals(2100, $profile->daily_kcal_target);
    }

    public function test_past_weight_does_not_overwrite_profile(): void
    {
        $this->log(0, 88.0);
        $this->postJson('/api/v1/weight-logs', ['weight_kg' => 95, 'date' => now()->subDays(5)->toDateString()])->assertCreated();

        $this->assertEquals(90, (float) $this->user->profile()->first()->weight_kg);
        $this->postJson('/api/v1/weight-logs', ['weight_kg' => 80, 'date' => now()->addDay()->toDateString()])->assertStatus(422);
    }

    public function test_empty_progress(): void
    {
        $this->getJson('/api/v1/progress')->assertOk()
            ->assertJsonPath('data.weight_change_kg', null)
            ->assertJsonPath('data.current_weight_kg', 90)
            ->assertJsonCount(0, 'data.points');
    }
}
