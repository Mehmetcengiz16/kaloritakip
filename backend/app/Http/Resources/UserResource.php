<?php

namespace App\Http\Resources;

use App\Services\NutritionCalculator;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $p = $this->profile;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'avatar' => $this->avatar,
            'locale' => $this->locale,
            'is_premium' => $this->isPremium(),
            'premium_until' => $this->premium_until?->toIso8601String(),
            'onboarding_completed' => (bool) $p?->birth_date,
            'profile' => $p ? [
                'gender' => $p->gender,
                'birth_date' => $p->birth_date?->toDateString(),
                'height_cm' => $p->height_cm,
                'weight_kg' => $p->weight_kg !== null ? (float) $p->weight_kg : null,
                'target_weight_kg' => $p->target_weight_kg !== null ? (float) $p->target_weight_kg : null,
                'goal' => $p->goal,
                'activity_level' => $p->activity_level,
                'daily_kcal_target' => $p->daily_kcal_target,
                'protein_g' => $p->protein_g,
                'carb_g' => $p->carb_g,
                'fat_g' => $p->fat_g,
                'water_ml_target' => $p->water_ml_target,
                'notifications_enabled' => (bool) $p->notifications_enabled,
                'bmi' => NutritionCalculator::bmi($p->weight_kg !== null ? (float) $p->weight_kg : null, $p->height_cm),
            ] : null,
        ];
    }
}
