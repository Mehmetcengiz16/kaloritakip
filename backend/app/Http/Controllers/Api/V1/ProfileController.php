<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\WeightLog;
use App\Services\NutritionCalculator;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    private const GOALS = ['lose', 'gain', 'maintain', 'healthy'];
    private const LEVELS = ['sedentary', 'light', 'moderate', 'active', 'very_active'];

    public function __construct(private NutritionCalculator $calc) {}

    public function show(Request $request)
    {
        return new UserResource($request->user()->load('profile'));
    }

    /** Onboarding: hedef + kişisel bilgiler -> kalori/makro hedefleri hesaplanır. */
    public function onboarding(Request $request)
    {
        $data = $request->validate([
            'goal' => ['required', Rule::in(self::GOALS)],
            'gender' => ['required', Rule::in(['male', 'female'])],
            'birth_date' => ['required', 'date', 'before:-13 years', 'after:-100 years'],
            'height_cm' => ['required', 'integer', 'between:100,250'],
            'weight_kg' => ['required', 'numeric', 'between:30,350'],
            'target_weight_kg' => ['nullable', 'numeric', 'between:30,350'],
            'activity_level' => ['required', Rule::in(self::LEVELS)],
        ]);

        $user = $request->user();
        $profile = $user->profile()->firstOrCreate();
        $profile->fill($data);
        $profile->fill($this->calc->targets($profile))->save();

        WeightLog::updateOrCreate(
            ['user_id' => $user->id, 'date' => now()->toDateString()],
            ['weight_kg' => $data['weight_kg']],
        );

        return new UserResource($user->load('profile'));
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'locale' => ['sometimes', Rule::in(['tr', 'en'])],
            'goal' => ['sometimes', Rule::in(self::GOALS)],
            'height_cm' => ['sometimes', 'integer', 'between:100,250'],
            'weight_kg' => ['sometimes', 'numeric', 'between:30,350'],
            'target_weight_kg' => ['sometimes', 'nullable', 'numeric', 'between:30,350'],
            'activity_level' => ['sometimes', Rule::in(self::LEVELS)],
            'notifications_enabled' => ['sometimes', 'boolean'],
            'daily_kcal_target' => ['sometimes', 'integer', 'between:1000,6000'],
        ]);

        $user = $request->user();
        $user->fill(collect($data)->only(['name', 'locale'])->all())->save();

        $profile = $user->profile()->firstOrCreate();
        $profile->fill(collect($data)->except(['name', 'locale', 'daily_kcal_target'])->all());
        if ($profile->isDirty(['goal', 'height_cm', 'weight_kg', 'activity_level'])) {
            $profile->fill($this->calc->targets($profile));
        }
        if (isset($data['daily_kcal_target'])) {
            $profile->daily_kcal_target = $data['daily_kcal_target'];
        }
        $profile->save();

        return new UserResource($user->load('profile'));
    }

    /** KVKK / App Store zorunluluğu: hesabı ve tüm verileri sil. */
    public function destroy(Request $request)
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete();

        return response()->noContent();
    }
}
