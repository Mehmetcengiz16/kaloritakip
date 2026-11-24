<?php

namespace App\Services;

use App\Models\ActivityLog;
use App\Models\MealItem;
use App\Models\User;
use App\Models\UserProfile;
use App\Models\WaterLog;
use App\Models\WeightLog;
use Carbon\CarbonImmutable;
use Carbon\CarbonPeriod;
use Illuminate\Support\Collection;

/**
 * İlerleme ekranının ek bölümleri: hedefe ilerleme, kalori grafiği, makro ortalaması, seri ve alışkanlıklar.
 */
class ProgressInsights
{
    /** Hedefte sayılma toleransı (hedefin ±%10'u; kilo verirken hedefin altı da hedefte sayılır) */
    private const TOLERANCE = 0.10;

    public function goal(User $user, UserProfile $p, ?float $current): ?array
    {
        $target = $p->target_weight_kg !== null ? (float) $p->target_weight_kg : null;
        $first = WeightLog::where('user_id', $user->id)->orderBy('date')->first();
        if ($target === null || $current === null || ! $first || ! in_array($p->goal, ['lose', 'gain'], true)) {
            return null;
        }

        $start = (float) $first->weight_kg;
        $total = $target - $start;
        $done = $current - $start;
        $pct = abs($total) < 0.05 ? 100 : max(0, min(100, $done / $total * 100));
        $remaining = round(abs($target - $current), 1);
        $reached = $p->goal === 'lose' ? $current <= $target : $current >= $target;

        return [
            'start_kg' => $start,
            'current_kg' => $current,
            'target_kg' => $target,
            'progress_pct' => round($pct),
            'remaining_kg' => $reached ? 0 : $remaining,
            'reached' => $reached,
            'eta_date' => $reached ? null : $this->eta($user, $current, $target),
        ];
    }

    /** Son 30 günün eğimine (doğrusal regresyon) göre hedefe tahmini varış; yanlış yöndeyse null. */
    private function eta(User $user, float $current, float $target): ?string
    {
        $logs = WeightLog::where('user_id', $user->id)->whereDate('date', '>=', now()->subDays(30))->orderBy('date')->get();
        if ($logs->count() < 3) {
            return null;
        }

        $t0 = $logs->first()->date;
        $xs = $logs->map(fn ($l) => (float) $t0->diffInDays($l->date));
        $ys = $logs->map(fn ($l) => (float) $l->weight_kg);
        $n = $logs->count();
        $mx = $xs->avg();
        $my = $ys->avg();
        $den = $xs->reduce(fn ($c, $x) => $c + ($x - $mx) ** 2, 0.0);
        if ($den == 0) {
            return null;
        }
        $slope = $xs->zip($ys)->reduce(fn ($c, $xy) => $c + ($xy[0] - $mx) * ($xy[1] - $my), 0.0) / $den; // kg/gün

        $days = ($target - $current) / $slope;
        if ($slope == 0 || $days <= 0 || $days > 3 * 365) {
            return null;
        }

        return now()->addDays((int) ceil($days))->toDateString();
    }

    /** Günlük (yıllıkta aylık ortalama) kalori; sadece kayıt girilen günler ortalamaya katılır. */
    public function calories(User $user, UserProfile $p, CarbonImmutable $from, string $range): array
    {
        $daily = $this->dailyTotals($user, $from);
        $target = (int) $p->daily_kcal_target;

        $bars = $range === 'year'
            ? $daily->groupBy(fn ($kcal, $d) => substr($d, 0, 7))
                ->map(fn ($g, $m) => ['date' => $m.'-01', 'kcal' => (int) round($g->avg())])->values()
            : collect(CarbonPeriod::create($from, now()->startOfDay()))
                ->map(fn ($d) => ['date' => $d->toDateString(), 'kcal' => (int) ($daily[$d->toDateString()] ?? 0)]);

        $onTarget = $daily->filter(fn ($kcal) => $this->isOnTarget($kcal, $target, $p->goal))->count();

        return [
            'target' => $target,
            'avg' => $daily->isEmpty() ? 0 : (int) round($daily->avg()),
            'logged_days' => $daily->count(),
            'on_target_days' => $onTarget,
            'bars' => $bars,
        ];
    }

    public function macros(User $user, UserProfile $p, CarbonImmutable $from): array
    {
        $rows = MealItem::query()
            ->join('meals', 'meals.id', '=', 'meal_items.meal_id')
            ->where('meals.user_id', $user->id)
            ->whereDate('meals.date', '>=', $from)
            ->selectRaw('meals.date d, SUM(protein) p, SUM(carb) c, SUM(fat) f')
            ->groupBy('d')->get();

        $days = max(1, $rows->count());
        $avg = fn ($k) => $rows->isEmpty() ? 0 : (int) round($rows->sum($k) / $days);
        [$prot, $carb, $fat] = [$avg('p'), $avg('c'), $avg('f')];
        $kcal = $prot * 4 + $carb * 4 + $fat * 9;
        $share = fn ($g, $f) => $kcal > 0 ? (int) round($g * $f / $kcal * 100) : 0;

        return [
            'protein' => ['avg' => $prot, 'target' => $p->protein_g, 'pct' => $share($prot, 4)],
            'carb' => ['avg' => $carb, 'target' => $p->carb_g, 'pct' => $share($carb, 4)],
            'fat' => ['avg' => $fat, 'target' => $p->fat_g, 'pct' => $share($fat, 9)],
        ];
    }

    public function habits(User $user, CarbonImmutable $from): array
    {
        $loggedDates = $this->dailyTotals($user, now()->subDays(400)->toImmutable())->keys()->flip();

        // Seri: bugünden (bugün henüz kayıt yoksa dünden) geriye kesintisiz kayıt günleri.
        $streak = 0;
        $day = now()->startOfDay();
        if (! isset($loggedDates[$day->toDateString()])) {
            $day = $day->subDay();
        }
        while (isset($loggedDates[$day->toDateString()])) {
            $streak++;
            $day = $day->subDay();
        }

        $water = WaterLog::where('user_id', $user->id)->whereDate('date', '>=', $from)
            ->selectRaw('date, SUM(amount_ml) ml')->groupBy('date')->pluck('ml');

        $periodDays = (int) $from->diffInDays(now()->startOfDay()) + 1;

        return [
            'streak_days' => $streak,
            'logged_days' => $loggedDates->keys()->filter(fn ($d) => $d >= $from->toDateString())->count(),
            'period_days' => $periodDays,
            'avg_water_ml' => $water->isEmpty() ? 0 : (int) round($water->avg()),
            'activity_kcal' => (int) ActivityLog::where('user_id', $user->id)->whereDate('date', '>=', $from)->sum('kcal'),
        ];
    }

    /** @return Collection<string, int> tarih => toplam kcal (sadece kayıt girilen günler) */
    private function dailyTotals(User $user, CarbonImmutable $from): Collection
    {
        return MealItem::query()
            ->join('meals', 'meals.id', '=', 'meal_items.meal_id')
            ->where('meals.user_id', $user->id)
            ->whereDate('meals.date', '>=', $from)
            ->selectRaw('DATE(meals.date) d, SUM(kcal) total')
            ->groupBy('d')->orderBy('d')
            ->pluck('total', 'd')
            ->map(fn ($v) => (int) $v);
    }

    private function isOnTarget(int $kcal, int $target, ?string $goal): bool
    {
        if ($target <= 0) {
            return false;
        }
        $low = $target * (1 - self::TOLERANCE);
        $high = $target * (1 + self::TOLERANCE);

        return match ($goal) {
            'lose' => $kcal <= $high,
            'gain' => $kcal >= $low,
            default => $kcal >= $low && $kcal <= $high,
        };
    }
}
