<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\ActivityLog;
use App\Models\WaterLog;
use Illuminate\Http\Request;

class WaterActivityController extends Controller
{
    /** Su ve Aktivite ekranı: günün su toplamı, aktiviteleri ve seçilebilir aktivite listesi. */
    public function show(Request $request)
    {
        $date = $request->validate(['date' => ['nullable', 'date_format:Y-m-d']])['date'] ?? now()->toDateString();

        return ['data' => $this->summary($request, $date)];
    }

    public function addWater(Request $request)
    {
        $data = $request->validate([
            'amount_ml' => ['required', 'integer', 'between:50,2000'],
            'date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ]);
        $date = $data['date'] ?? now()->toDateString();

        WaterLog::create(['user_id' => $request->user()->id, 'date' => $date, 'amount_ml' => $data['amount_ml']]);

        return response()->json(['data' => $this->summary($request, $date)], 201);
    }

    /** Son su eklemesini geri al (yanlışlıkla basıldığında). */
    public function undoWater(Request $request)
    {
        $date = $request->validate(['date' => ['nullable', 'date_format:Y-m-d']])['date'] ?? now()->toDateString();

        WaterLog::where('user_id', $request->user()->id)->whereDate('date', $date)->latest('id')->first()?->delete();

        return ['data' => $this->summary($request, $date)];
    }

    /**
     * Aktivite ekle: katalogdan (activity_id + dakika -> MET formülü) veya serbest (ad + dakika + kcal).
     * kcal = MET × kilo (kg) × saat
     */
    public function addActivity(Request $request)
    {
        $data = $request->validate([
            'activity_id' => ['required_without:name', 'nullable', 'integer', 'exists:activities,id'],
            'name' => ['required_without:activity_id', 'nullable', 'string', 'max:100'],
            'minutes' => ['required', 'integer', 'between:1,600'],
            'kcal' => ['required_without:activity_id', 'nullable', 'integer', 'between:1,5000'],
            'date' => ['nullable', 'date_format:Y-m-d', 'before_or_equal:today'],
        ]);
        $user = $request->user();
        $date = $data['date'] ?? now()->toDateString();

        if (! empty($data['activity_id'])) {
            $activity = Activity::findOrFail($data['activity_id']);
            $weight = (float) ($user->profile?->weight_kg ?: 70);
            $name = $activity->name;
            $kcal = (int) round($activity->met * $weight * $data['minutes'] / 60);
        } else {
            $name = $data['name'];
            $kcal = (int) $data['kcal'];
        }

        ActivityLog::create([
            'user_id' => $user->id,
            'activity_id' => $data['activity_id'] ?? null,
            'name' => $name,
            'date' => $date,
            'minutes' => $data['minutes'],
            'kcal' => $kcal,
        ]);

        return response()->json(['data' => $this->summary($request, $date)], 201);
    }

    public function deleteActivity(Request $request, ActivityLog $log)
    {
        abort_unless($log->user_id === $request->user()->id, 404);
        $date = $log->date->toDateString();
        $log->delete();

        return ['data' => $this->summary($request, $date)];
    }

    private function summary(Request $request, string $date): array
    {
        $user = $request->user();
        $p = $user->profile()->firstOrCreate();
        $logs = ActivityLog::where('user_id', $user->id)->whereDate('date', $date)->with('activity')->orderBy('id')->get();
        $weight = (float) ($p->weight_kg ?: 70);

        return [
            'date' => $date,
            'water' => [
                'consumed_ml' => (int) WaterLog::where('user_id', $user->id)->whereDate('date', $date)->sum('amount_ml'),
                'target_ml' => $p->water_ml_target,
            ],
            'activity' => [
                'burned_kcal' => (int) $logs->sum('kcal'),
                'logs' => $logs->map(fn (ActivityLog $l) => [
                    'id' => $l->id,
                    'name' => $l->name,
                    'icon' => $l->activity?->icon ?? 'activity',
                    'minutes' => $l->minutes,
                    'kcal' => $l->kcal,
                ])->values(),
            ],
            'catalog' => Activity::where('is_active', true)->orderBy('id')->get()->map(fn (Activity $a) => [
                'id' => $a->id,
                'name' => $a->name,
                'icon' => $a->icon,
                // 1 dakikada yaklaşık yakılan kalori (uygulamada canlı önizleme için)
                'kcal_per_minute' => round($a->met * $weight / 60, 2),
            ])->values(),
        ];
    }
}
