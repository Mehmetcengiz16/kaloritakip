<?php

namespace Tests\Feature;

use App\Models\ActivityLog;
use App\Models\Meal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_sums_meals_activity_and_remaining(): void
    {
        $user = User::factory()->create(['name' => 'Mehmet Cengiz']);
        $user->profile()->create(['daily_kcal_target' => 2200, 'protein_g' => 150, 'goal' => 'lose']);
        Sanctum::actingAs($user);

        $today = now()->toDateString();
        $breakfast = Meal::create(['user_id' => $user->id, 'date' => $today, 'type' => 'breakfast']);
        $breakfast->items()->createMany([
            ['name' => 'Yulaf', 'grams' => 80, 'kcal' => 300, 'protein' => 10, 'carb' => 50, 'fat' => 5],
            ['name' => 'Muz', 'grams' => 120, 'kcal' => 220, 'protein' => 2, 'carb' => 27, 'fat' => 0.4],
        ]);
        // Başka günün öğünü sayılmamalı.
        Meal::create(['user_id' => $user->id, 'date' => now()->subDay()->toDateString(), 'type' => 'lunch'])
            ->items()->create(['name' => 'Dün', 'grams' => 100, 'kcal' => 999]);
        ActivityLog::create(['user_id' => $user->id, 'name' => 'Yürüyüş', 'date' => $today, 'minutes' => 30, 'kcal' => 120]);

        $this->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.user.first_name', 'Mehmet')
            ->assertJsonPath('data.calories.consumed', 520)
            ->assertJsonPath('data.calories.burned', 120)
            ->assertJsonPath('data.calories.remaining', 1800)
            ->assertJsonPath('data.macros.protein.consumed', 12)
            ->assertJsonPath('data.meals.0.type', 'breakfast')
            ->assertJsonPath('data.meals.0.kcal', 520)
            ->assertJsonPath('data.meals.2.kcal', 0)
            ->assertJsonCount(5, 'data.meals');
    }
}
