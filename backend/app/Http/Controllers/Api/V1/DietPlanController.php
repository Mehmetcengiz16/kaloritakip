<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\DietPlan;
use App\Models\DietPlanMeal;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DietPlanController extends Controller
{
    /**
     * Hedefe göre örnek planlar. goal verilmezse kullanıcının hedefi kullanılır
     * ("healthy" hedefi için koruma planları gösterilir).
     * Premium planların öğünleri premium olmayan kullanıcıya gönderilmez.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        $p = $user->profile()->firstOrCreate();
        $userGoal = $p->goal === 'healthy' ? 'maintain' : $p->goal;

        $goal = $request->validate(['goal' => ['nullable', Rule::in(['lose', 'gain', 'maintain'])]])['goal'] ?? $userGoal;
        $premium = $user->isPremium();

        $plans = DietPlan::where('goal', $goal)->where('is_active', true)
            ->with('meals')->orderBy('is_premium')->orderBy('id')->get();

        return ['data' => [
            'goal' => $goal,
            'user_goal' => $userGoal,
            'daily_kcal_target' => $p->daily_kcal_target,
            'plans' => $plans->map(fn (DietPlan $plan) => [
                'id' => $plan->id,
                'title' => $plan->title,
                'daily_kcal' => $plan->daily_kcal,
                'is_premium' => $plan->is_premium,
                'locked' => $plan->is_premium && ! $premium,
                'meals' => $plan->is_premium && ! $premium ? [] : $plan->meals->map(fn (DietPlanMeal $m) => [
                    'meal_type' => $m->meal_type,
                    'title' => $m->title,
                    'description' => $m->description,
                    'kcal' => $m->kcal,
                ])->values(),
            ])->values(),
        ]];
    }
}
