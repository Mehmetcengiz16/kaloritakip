<?php

namespace App\Services;

use App\Models\AiAnalysis;
use App\Models\AiInsight;
use App\Models\Expense;
use App\Models\Setting;
use App\Models\Subscription;
use Carbon\CarbonImmutable;
use Carbon\CarbonPeriod;

/**
 * Gelir – gider – net kâr hesabı (TL).
 * Gelir: abonelik satışları · Gider: mağaza komisyonu + AI (USD→TL) + girilen giderler.
 */
class ProfitabilityService
{
    public function usdTry(): float
    {
        return (float) Setting::get('usd_try_rate', 34);
    }

    /** @return array{revenue: float, store_fee: float, ai_cost: float, ai_cost_usd: float, expenses: float, net: float, margin_pct: float|null, ai_ratio_pct: float|null} */
    public function summary(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $subs = Subscription::whereBetween('started_at', [$from->startOfDay(), $to->endOfDay()])
            ->where('status', '!=', 'refunded');
        $revenue = (float) (clone $subs)->sum('price');
        $storeFee = $this->storeFee($subs->get(['price', 'store_fee']));

        $aiUsd = $this->aiCostUsd($from, $to);
        $aiCost = round($aiUsd * $this->usdTry(), 2);

        $expenses = (float) Expense::whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->where('category', '!=', 'openrouter') // OpenRouter maliyeti zaten otomatik hesaplanıyor
            ->sum('amount');

        $net = $revenue - $storeFee - $aiCost - $expenses;

        return [
            'revenue' => round($revenue, 2),
            'store_fee' => round($storeFee, 2),
            'ai_cost' => $aiCost,
            'ai_cost_usd' => round($aiUsd, 4),
            'expenses' => round($expenses, 2),
            'net' => round($net, 2),
            'margin_pct' => $revenue > 0 ? round($net / $revenue * 100, 1) : null,
            'ai_ratio_pct' => $revenue > 0 ? round($aiCost / $revenue * 100, 1) : null,
        ];
    }

    /** Grafik için günlük gelir, toplam gider ve AI maliyeti (TL). */
    public function dailySeries(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $rate = $this->usdTry();
        $feePct = (float) Setting::get('store_fee_pct', 15) / 100;

        $revenue = Subscription::whereBetween('started_at', [$from->startOfDay(), $to->endOfDay()])
            ->where('status', '!=', 'refunded')
            ->selectRaw('DATE(started_at) d, SUM(price) total, SUM(CASE WHEN store_fee > 0 THEN store_fee ELSE price * ? END) fee', [$feePct])
            ->groupBy('d')->get()->keyBy('d');

        $ai = AiAnalysis::whereBetween('created_at', [$from->startOfDay(), $to->endOfDay()])
            ->selectRaw('DATE(created_at) d, SUM(cost_usd) usd')->groupBy('d')->pluck('usd', 'd');
        $aiInsight = AiInsight::whereBetween('created_at', [$from->startOfDay(), $to->endOfDay()])
            ->selectRaw('DATE(created_at) d, SUM(cost_usd) usd')->groupBy('d')->pluck('usd', 'd');

        $expenses = Expense::whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->where('category', '!=', 'openrouter')
            ->selectRaw('DATE(date) d, SUM(amount) total')->groupBy('d')->pluck('total', 'd');

        $rows = [];
        foreach (CarbonPeriod::create($from, $to) as $day) {
            $d = $day->toDateString();
            $aiTl = ((float) ($ai[$d] ?? 0) + (float) ($aiInsight[$d] ?? 0)) * $rate;
            $rev = (float) ($revenue[$d]->total ?? 0);
            $cost = (float) ($revenue[$d]->fee ?? 0) + $aiTl + (float) ($expenses[$d] ?? 0);
            $rows[] = [
                'date' => $d,
                'revenue' => round($rev, 2),
                'cost' => round($cost, 2),
                'ai_cost' => round($aiTl, 2),
                'net' => round($rev - $cost, 2),
            ];
        }

        return $rows;
    }

    public function aiCostUsd(CarbonImmutable $from, CarbonImmutable $to): float
    {
        $range = [$from->startOfDay(), $to->endOfDay()];

        return (float) AiAnalysis::whereBetween('created_at', $range)->sum('cost_usd')
            + (float) AiInsight::whereBetween('created_at', $range)->sum('cost_usd');
    }

    /** Mağaza komisyonu: kayıtta varsa o, yoksa ayardaki oran (varsayılan %15). */
    private function storeFee($subs): float
    {
        $pct = (float) Setting::get('store_fee_pct', 15) / 100;

        return (float) $subs->sum(fn ($s) => (float) $s->store_fee > 0 ? (float) $s->store_fee : (float) $s->price * $pct);
    }
}
