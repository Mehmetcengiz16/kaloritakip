<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use App\Models\Meal;
use App\Models\MealItem;
use App\Models\WaterLog;
use App\Services\Ai\AiQuota;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Ana Sayfa: kalan kalori halkası, makrolar ve bugünkü öğünler tek istekte.
 */
class DashboardController extends Controller
{
    public function __invoke(Request $request, AiQuota $quota)
    {
        $request->validate(['date' => ['nullable', 'date_format:Y-m-d']]);
        $date = Carbon::parse($request->query('date', now()->toDateString()))->toDateString();
        $user = $request->user();
        $p = $user->profile()->firstOrCreate();

        $meals = Meal::where('user_id', $user->id)->whereDate('date', $date)->with('items.food')->get()->keyBy('type');

        $items = $meals->flatMap->items;
        $consumed = [
            'kcal' => (int) $items->sum('kcal'),
            'protein' => (int) round($items->sum('protein')),
            'carb' => (int) round($items->sum('carb')),
            'fat' => (int) round($items->sum('fat')),
        ];
        $burned = (int) ActivityLog::where('user_id', $user->id)->whereDate('date', $date)->sum('kcal');
        $water = (int) WaterLog::where('user_id', $user->id)->whereDate('date', $date)->sum('amount_ml');

        return response()->json(['data' => [
            'date' => $date,
            'user' => ['name' => $user->name, 'first_name' => explode(' ', trim($user->name))[0], 'goal' => $p->goal],
            'calories' => [
                'target' => $p->daily_kcal_target,
                'consumed' => $consumed['kcal'],
                'burned' => $burned,
                // Yakılan kalori, günlük bütçeye geri eklenir.
                'remaining' => $p->daily_kcal_target + $burned - $consumed['kcal'],
            ],
            'macros' => [
                'protein' => ['consumed' => $consumed['protein'], 'target' => $p->protein_g],
                'carb' => ['consumed' => $consumed['carb'], 'target' => $p->carb_g],
                'fat' => ['consumed' => $consumed['fat'], 'target' => $p->fat_g],
            ],
            'water' => ['consumed_ml' => $water, 'target_ml' => $p->water_ml_target],
            'ai_quota' => $quota->status($user),
            'meals' => collect(Meal::TYPES)->map(function (string $type) use ($meals) {
                $mealItems = $meals->get($type)?->items ?? collect();

                return [
                    'type' => $type,
                    'kcal' => (int) $mealItems->sum('kcal'),
                    'item_count' => $mealItems->count(),
                    'items' => $mealItems->map(fn (MealItem $i) => [
                        'id' => $i->id, 'name' => $i->name, 'grams' => $i->grams, 'kcal' => $i->kcal,
                        'image_url' => $i->food?->imageUrl(),
                    ])->values(),
                ];
            })->values(),
        ]]);
    }
}
