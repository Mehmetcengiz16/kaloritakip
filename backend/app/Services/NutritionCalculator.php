<?php

namespace App\Services;

use App\Models\UserProfile;

/**
 * Mifflin-St Jeor formülü ile günlük kalori ve makro hedeflerini hesaplar.
 */
class NutritionCalculator
{
    private const ACTIVITY = [
        'sedentary' => 1.2, 'light' => 1.375, 'moderate' => 1.55, 'active' => 1.725, 'very_active' => 1.9,
    ];

    private const GOAL_ADJUST = ['lose' => -500, 'gain' => 400, 'maintain' => 0, 'healthy' => 0];

    public function targets(UserProfile $p): array
    {
        if (! $p->weight_kg || ! $p->height_cm || ! $p->birth_date || ! $p->gender) {
            return [];
        }

        $age = $p->birth_date->age;
        $bmr = 10 * $p->weight_kg + 6.25 * $p->height_cm - 5 * $age + ($p->gender === 'male' ? 5 : -161);
        $tdee = $bmr * self::ACTIVITY[$p->activity_level];
        $minKcal = $p->gender === 'male' ? 1500 : 1200;
        $kcal = (int) (round(max($minKcal, $tdee + self::GOAL_ADJUST[$p->goal]) / 50) * 50);

        $proteinPerKg = match ($p->goal) { 'lose' => 2.0, 'gain' => 1.8, default => 1.6 };
        $protein = (int) round($p->weight_kg * $proteinPerKg);
        $fat = (int) round($kcal * 0.25 / 9);
        $carb = (int) max(0, round(($kcal - $protein * 4 - $fat * 9) / 4));

        return [
            'daily_kcal_target' => $kcal,
            'protein_g' => $protein,
            'carb_g' => $carb,
            'fat_g' => $fat,
            'water_ml_target' => (int) (round($p->weight_kg * 35 / 250) * 250),
        ];
    }

    public static function bmi(?float $weight, ?int $height): ?float
    {
        return $weight && $height ? round($weight / (($height / 100) ** 2), 1) : null;
    }
}
