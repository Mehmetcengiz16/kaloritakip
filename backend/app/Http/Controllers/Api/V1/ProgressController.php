<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\WeightLog;
use App\Services\NutritionCalculator;
use App\Services\ProgressInsights;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class ProgressController extends Controller
{
    private const DAYS = ['week' => 7, 'month' => 30, 'year' => 365];

    /**
     * Kilo grafiği ve özet kartları. Haftalık/aylık günlük noktalar, yıllık aylık ortalamalar döner.
     * Değişim: aralığın başındaki (veya aralıktan önceki son) ölçüme göre.
     */
    public function index(Request $request, ProgressInsights $insights)
    {
        $range = $request->validate(['range' => ['nullable', Rule::in(array_keys(self::DAYS))]])['range'] ?? 'week';
        $user = $request->user();
        $p = $user->profile()->firstOrCreate();

        $from = now()->startOfDay()->subDays(self::DAYS[$range] - 1);
        $logs = WeightLog::where('user_id', $user->id)->whereDate('date', '>=', $from)->orderBy('date')->get();
        $baseline = WeightLog::where('user_id', $user->id)->whereDate('date', '<', $from)->orderByDesc('date')->first()
            ?? $logs->first();
        $latest = WeightLog::where('user_id', $user->id)->orderByDesc('date')->first();

        $points = $range === 'year'
            ? $logs->groupBy(fn ($l) => $l->date->format('Y-m'))->map(fn ($g, $month) => [
                'date' => $month.'-01',
                'weight_kg' => round($g->avg('weight_kg'), 1),
            ])->values()
            : $logs->map(fn ($l) => ['date' => $l->date->toDateString(), 'weight_kg' => (float) $l->weight_kg])->values();

        $fatLogs = $logs->whereNotNull('body_fat_pct');
        $currentWeight = $latest ? (float) $latest->weight_kg : ($p->weight_kg !== null ? (float) $p->weight_kg : null);

        return ['data' => [
            'range' => $range,
            'from' => $from->toDateString(),
            'to' => now()->toDateString(),
            'current_weight_kg' => $currentWeight,
            'target_weight_kg' => $p->target_weight_kg !== null ? (float) $p->target_weight_kg : null,
            'weight_change_kg' => $latest && $baseline ? round($latest->weight_kg - $baseline->weight_kg, 1) : null,
            'body_fat_pct' => $fatLogs->last()?->body_fat_pct !== null ? (float) $fatLogs->last()->body_fat_pct : null,
            'body_fat_change_pct' => $fatLogs->count() >= 2
                ? round($fatLogs->last()->body_fat_pct - $fatLogs->first()->body_fat_pct, 1)
                : null,
            'bmi' => NutritionCalculator::bmi($currentWeight, $p->height_cm),
            'points' => $points,
            'goal' => $insights->goal($user, $p, $currentWeight),
            'calories' => $insights->calories($user, $p, $from->toImmutable(), $range),
            'macros' => $insights->macros($user, $p, $from->toImmutable()),
            'habits' => $insights->habits($user, $from->toImmutable()),
        ]];
    }

    /** Kilo kaydı: aynı güne ikinci kayıt öncekini günceller. Bugünün kaydıysa hedefler yeniden hesaplanır. */
    public function storeWeight(Request $request, NutritionCalculator $calc)
    {
        $data = $request->validate([
            'weight_kg' => ['required', 'numeric', 'between:30,350'],
            'body_fat_pct' => ['nullable', 'numeric', 'between:2,70'],
            'date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ]);
        $user = $request->user();
        $date = $data['date'] ?? now()->toDateString();

        $log = WeightLog::updateOrCreate(
            ['user_id' => $user->id, 'date' => $date],
            ['weight_kg' => $data['weight_kg'], 'body_fat_pct' => $data['body_fat_pct'] ?? null],
        );

        $isLatest = ! WeightLog::where('user_id', $user->id)->whereDate('date', '>', $date)->exists();
        if ($isLatest) {
            $p = $user->profile()->firstOrCreate();
            $p->weight_kg = $data['weight_kg'];
            $p->fill($calc->targets($p))->save();
        }

        return response()->json(['data' => [
            'date' => Carbon::parse($log->date)->toDateString(),
            'weight_kg' => (float) $log->weight_kg,
            'body_fat_pct' => $log->body_fat_pct !== null ? (float) $log->body_fat_pct : null,
        ]], 201);
    }
}
