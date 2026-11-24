<?php

namespace Tests\Feature;

use App\Models\DietPlan;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DietPlanTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(DatabaseSeeder::class);
        $this->user = User::factory()->create();
        $this->user->profile()->create(['goal' => 'lose', 'daily_kcal_target' => 2200]);
        Sanctum::actingAs($this->user);
    }

    public function test_defaults_to_user_goal_and_returns_meals(): void
    {
        $this->getJson('/api/v1/diet-plans')->assertOk()
            ->assertJsonPath('data.goal', 'lose')
            ->assertJsonPath('data.daily_kcal_target', 2200)
            ->assertJsonPath('data.plans.0.meals.0.title', 'Kahvaltı')
            ->assertJsonPath('data.plans.0.meals.0.description', 'Yulaf, süt, muz, ceviz')
            ->assertJsonPath('data.plans.0.meals.0.kcal', 520);
    }

    public function test_other_goal_and_premium_lock(): void
    {
        $plan = DietPlan::create(['goal' => 'gain', 'title' => 'Premium Kas', 'daily_kcal' => 3200, 'is_premium' => true]);
        $plan->meals()->create(['meal_type' => 'lunch', 'title' => 'Öğle', 'kcal' => 900]);

        $res = $this->getJson('/api/v1/diet-plans?goal=gain')->assertOk()->assertJsonPath('data.user_goal', 'lose');
        $premium = collect($res->json('data.plans'))->firstWhere('title', 'Premium Kas');
        $this->assertTrue($premium['locked']);
        $this->assertSame([], $premium['meals']);

        $this->user->forceFill(['premium_until' => now()->addMonth()])->save();
        $premium = collect($this->getJson('/api/v1/diet-plans?goal=gain')->json('data.plans'))->firstWhere('title', 'Premium Kas');
        $this->assertFalse($premium['locked']);
        $this->assertCount(1, $premium['meals']);
    }

    public function test_healthy_goal_maps_to_maintain(): void
    {
        $this->user->profile->update(['goal' => 'healthy']);
        $this->getJson('/api/v1/diet-plans')->assertJsonPath('data.goal', 'maintain');
    }
}
