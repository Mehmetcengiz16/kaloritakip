<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiAnalysis;
use App\Models\Meal;
use App\Models\Setting;
use App\Models\Subscription;
use App\Models\User;
use App\Services\Ai\AiQuota;
use App\Services\ProfitabilityService;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

class DashboardController extends Controller
{
    public function __invoke(Request $request, ProfitabilityService $profit, AiQuota $quota)
    {
        $days = (int) ($request->validate(['days' => ['nullable', Rule::in([7, 30, 90])]])['days'] ?? 30);
        $to = CarbonImmutable::today();
        $from = $to->subDays($days - 1);
        $prevTo = $from->subDay();
        $prevFrom = $prevTo->subDays($days - 1);

        $summary = $profit->summary($from, $to);
        $previous = $profit->summary($prevFrom, $prevTo);

        $totalUsers = User::where('is_admin', false)->count();
        $premiumUsers = User::where('is_admin', false)->where('premium_until', '>', now())->count();
        $activeToday = Meal::whereDate('date', today())->distinct('user_id')->count('user_id');

        $analyses = AiAnalysis::whereBetween('created_at', [$from->startOfDay(), $to->endOfDay()]);
        $analysisCount = (clone $analyses)->count();
        $cacheHits = (clone $analyses)->where('from_cache', true)->count();

        $budget = (float) Setting::get('ai_daily_budget_usd', config('ai.daily_budget_usd'));
        $spentToday = $quota->spentTodayUsd();

        return Inertia::render('Dashboard', [
            'days' => $days,
            'summary' => $summary,
            'previous' => $previous,
            'series' => $profit->dailySeries($from, $to),
            'aiRatioAlert' => (float) Setting::get('ai_cost_ratio_alert_pct', 15),
            'users' => [
                'total' => $totalUsers,
                'premium' => $premiumUsers,
                'conversion_pct' => $totalUsers ? round($premiumUsers / $totalUsers * 100, 1) : 0,
                'new' => User::where('is_admin', false)->where('created_at', '>=', $from->startOfDay())->count(),
                'active_today' => $activeToday,
            ],
            'ai' => [
                'analyses' => $analysisCount,
                'cache_hit_pct' => $analysisCount ? round($cacheHits / $analysisCount * 100, 1) : 0,
                'failed' => (clone $analyses)->where('status', 'failed')->count(),
                'avg_cost_usd' => $analysisCount ? round($summary['ai_cost_usd'] / max(1, $analysisCount - $cacheHits), 5) : 0,
                'budget_usd' => $budget,
                'spent_today_usd' => round($spentToday, 4),
            ],
            'subscriptions' => [
                'active' => Subscription::whereIn('status', ['active', 'trial'])->where(fn ($q) => $q->whereNull('expires_at')->orWhere('expires_at', '>', now()))->count(),
            ],
        ]);
    }
}
