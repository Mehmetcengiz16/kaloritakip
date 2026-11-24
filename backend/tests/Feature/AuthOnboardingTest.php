<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthOnboardingTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_onboarding_and_profile_flow(): void
    {
        $res = $this->postJson('/api/v1/auth/register', [
            'name' => 'Test Kullanıcı',
            'email' => 'test@example.com',
            'password' => 'gizlisifre123',
        ])->assertCreated()->assertJsonPath('user.onboarding_completed', false);

        $auth = ['Authorization' => 'Bearer '.$res->json('token')];

        $this->postJson('/api/v1/onboarding', [
            'goal' => 'lose',
            'gender' => 'male',
            'birth_date' => now()->subYears(30)->toDateString(),
            'height_cm' => 180,
            'weight_kg' => 90,
            'activity_level' => 'light',
        ], $auth)
            ->assertOk()
            ->assertJsonPath('data.onboarding_completed', true)
            ->assertJsonPath('data.profile.bmi', 27.8)
            // BMR = 900 + 1125 - 150 + 5 = 1880; *1.375 = 2585; -500 = 2085 -> 2100
            ->assertJsonPath('data.profile.daily_kcal_target', 2100)
            ->assertJsonPath('data.profile.protein_g', 180);

        $this->putJson('/api/v1/me', ['notifications_enabled' => false], $auth)
            ->assertOk()->assertJsonPath('data.profile.notifications_enabled', false);

        $this->postJson('/api/v1/auth/login', ['email' => 'test@example.com', 'password' => 'yanlis'])
            ->assertStatus(422);
    }

    public function test_me_requires_auth(): void
    {
        $this->getJson('/api/v1/me')->assertUnauthorized();
    }
}
