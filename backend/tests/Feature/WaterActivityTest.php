<?php

namespace Tests\Feature;

use App\Models\Activity;
use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class WaterActivityTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        $this->user->profile()->create(['weight_kg' => 80, 'water_ml_target' => 3000, 'daily_kcal_target' => 2000]);
        Sanctum::actingAs($this->user);
    }

    public function test_water_add_and_undo(): void
    {
        $this->postJson('/api/v1/water', ['amount_ml' => 500])->assertCreated();
        $this->postJson('/api/v1/water', ['amount_ml' => 1000])->assertCreated()
            ->assertJsonPath('data.water.consumed_ml', 1500)
            ->assertJsonPath('data.water.target_ml', 3000);

        $this->deleteJson('/api/v1/water/last')->assertOk()->assertJsonPath('data.water.consumed_ml', 500);
        $this->postJson('/api/v1/water', ['amount_ml' => 10])->assertStatus(422);
    }

    public function test_catalog_activity_uses_met_formula_and_reduces_dashboard_budget(): void
    {
        $walk = Activity::create(['name' => 'Yürüyüş', 'icon' => 'footprints', 'met' => 3.5]);

        // 3.5 MET × 80 kg × 0.5 saat = 140 kcal
        $this->postJson('/api/v1/activities', ['activity_id' => $walk->id, 'minutes' => 30])
            ->assertCreated()
            ->assertJsonPath('data.activity.burned_kcal', 140)
            ->assertJsonPath('data.activity.logs.0.name', 'Yürüyüş')
            ->assertJsonPath('data.activity.logs.0.icon', 'footprints')
            ->assertJsonPath('data.catalog.0.kcal_per_minute', 4.67);

        $this->getJson('/api/v1/dashboard')->assertJsonPath('data.calories.remaining', 2140);
    }

    public function test_custom_activity_and_delete(): void
    {
        $res = $this->postJson('/api/v1/activities', ['name' => 'Tenis', 'minutes' => 45, 'kcal' => 350])
            ->assertCreated()->assertJsonPath('data.activity.burned_kcal', 350);

        $id = $res->json('data.activity.logs.0.id');
        $this->deleteJson("/api/v1/activity-logs/{$id}")->assertOk()->assertJsonPath('data.activity.burned_kcal', 0);

        $this->postJson('/api/v1/activities', ['name' => 'Tenis', 'minutes' => 45])->assertStatus(422);
    }

    public function test_cannot_delete_other_users_activity(): void
    {
        $other = User::factory()->create();
        $log = ActivityLog::create(['user_id' => $other->id, 'name' => 'X', 'date' => now()->toDateString(), 'minutes' => 10, 'kcal' => 50]);

        $this->deleteJson("/api/v1/activity-logs/{$log->id}")->assertNotFound();
    }
}
