<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiAnalysis;
use App\Services\ProfitabilityService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

class AiAnalysisController extends Controller
{
    public function index(Request $request, ProfitabilityService $profit)
    {
        $rate = $profit->usdTry();

        $filters = $request->validate([
            'status' => ['nullable', Rule::in(['done', 'failed', 'not_food', 'pending'])],
            'cache' => ['nullable', Rule::in(['yes', 'no'])],
        ]);

        $analyses = AiAnalysis::query()
            ->with('user:id,name,email')
            ->when($filters['status'] ?? null, fn ($q, $s) => $q->where('status', $s))
            ->when(($filters['cache'] ?? null) === 'yes', fn ($q) => $q->where('from_cache', true))
            ->when(($filters['cache'] ?? null) === 'no', fn ($q) => $q->where('from_cache', false))
            ->latest()
            ->paginate(20)->withQueryString()
            ->through(fn (AiAnalysis $a) => [
                'id' => $a->id,
                'user' => $a->user?->only(['id', 'name', 'email']),
                'status' => $a->status,
                'model' => $a->model,
                'from_cache' => $a->from_cache,
                'prompt_tokens' => $a->prompt_tokens,
                'completion_tokens' => $a->completion_tokens,
                'cost_usd' => (float) $a->cost_usd,
                'cost_try' => round((float) $a->cost_usd * $rate, 4),
                'latency_ms' => $a->latency_ms,
                'items' => $a->result_json['items'] ?? [],
                'total_kcal' => $a->result_json['total_kcal'] ?? null,
                'error' => $a->error,
                'has_image' => (bool) $a->image_path,
                'created_at' => $a->created_at->format('d.m.Y H:i'),
            ]);

        $page = AiAnalysis::query()
            ->when($filters['status'] ?? null, fn ($q, $s) => $q->where('status', $s));
        $paidCount = (clone $page)->where('from_cache', false)->where('cost_usd', '>', 0)->count();
        $totalUsd = (float) (clone $page)->sum('cost_usd');

        return Inertia::render('AiAnalyses/Index', [
            'analyses' => $analyses,
            'filters' => $filters,
            'usdTry' => $rate,
            'totals' => [
                'count' => (clone $page)->count(),
                'cost_usd' => round($totalUsd, 4),
                'cost_try' => round($totalUsd * $rate, 4),
                'avg_try' => $paidCount ? round($totalUsd * $rate / $paidCount, 4) : 0,
            ],
        ]);
    }

    /** Analiz görselini sadece adminlere gösterir (dosyalar herkese açık diskte değil). */
    public function image(AiAnalysis $analysis)
    {
        abort_unless($analysis->image_path && Storage::disk('local')->exists($analysis->image_path), 404);

        return Storage::disk('local')->response($analysis->image_path, headers: ['Cache-Control' => 'private, max-age=86400']);
    }
}
