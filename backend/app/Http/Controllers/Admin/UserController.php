<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiAnalysis;
use App\Models\Subscription;
use App\Models\UsageQuota;
use App\Models\User;
use App\Services\ProfitabilityService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', Rule::in(['premium', 'free', 'blocked'])],
        ]);

        $users = User::query()
            ->where('is_admin', false)
            ->with('profile:id,user_id,goal,weight_kg,daily_kcal_target')
            ->withCount('aiAnalyses')
            ->withSum('aiAnalyses', 'cost_usd')
            ->when($filters['q'] ?? null, fn ($q, $s) => $q->where(fn ($w) => $w
                ->where('name', 'like', '%'.addcslashes($s, '%_\\').'%')
                ->orWhere('email', 'like', '%'.addcslashes($s, '%_\\').'%')))
            ->when(($filters['status'] ?? null) === 'premium', fn ($q) => $q->where('premium_until', '>', now()))
            ->when(($filters['status'] ?? null) === 'free', fn ($q) => $q->where(fn ($w) => $w->whereNull('premium_until')->orWhere('premium_until', '<=', now())))
            ->when(($filters['status'] ?? null) === 'blocked', fn ($q) => $q->where('is_blocked', true))
            ->latest()
            ->paginate(20)
            ->withQueryString()
            ->through(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'goal' => $u->profile?->goal,
                'weight_kg' => $u->profile?->weight_kg !== null ? (float) $u->profile->weight_kg : null,
                'kcal_target' => $u->profile?->daily_kcal_target,
                'is_premium' => $u->isPremium(),
                'premium_until' => $u->premium_until?->toDateString(),
                'is_blocked' => $u->is_blocked,
                'ai_count' => $u->ai_analyses_count,
                'ai_cost_usd' => round((float) $u->ai_analyses_sum_cost_usd, 4),
                'created_at' => $u->created_at->toDateString(),
            ]);

        return Inertia::render('Users/Index', ['users' => $users, 'filters' => $filters]);
    }

    /** Elle premium ver (destek/kampanya) veya premium'u kaldır. */
    public function premium(Request $request, User $user)
    {
        abort_if($user->is_admin, 404);
        $days = (int) $request->validate(['days' => ['required', 'integer', 'between:0,366']])['days'];

        if ($days === 0) {
            $user->forceFill(['premium_until' => null])->save();
            $user->subscriptions()->where('store', 'manual')->whereIn('status', ['active', 'trial'])->update(['status' => 'cancelled']);

            return back()->with('success', "{$user->name} için premium kaldırıldı.");
        }

        $until = ($user->isPremium() ? $user->premium_until : now())->copy()->addDays($days);
        $user->forceFill(['premium_until' => $until])->save();
        Subscription::create([
            'user_id' => $user->id, 'store' => 'manual', 'product_id' => "manual_{$days}d",
            'status' => 'active', 'started_at' => now(), 'expires_at' => $until, 'price' => 0,
        ]);

        return back()->with('success', "{$user->name} {$until->format('d.m.Y')} tarihine kadar premium.");
    }

    public function block(User $user)
    {
        abort_if($user->is_admin, 404);
        $user->forceFill(['is_blocked' => ! $user->is_blocked])->save();
        if ($user->is_blocked) {
            $user->tokens()->delete(); // açık oturumları kapat
        }

        return back()->with('success', $user->is_blocked ? "{$user->name} engellendi." : "{$user->name} engeli kaldırıldı.");
    }

    public function resetQuota(User $user)
    {
        UsageQuota::where('user_id', $user->id)->whereDate('date', today())->update(['ai_photo_count' => 0]);

        return back()->with('success', "{$user->name} için bugünkü AI hakkı sıfırlandı.");
    }

    public function show(User $user, ProfitabilityService $profit)
    {
        $rate = $profit->usdTry();
        abort_if($user->is_admin, 404);
        $user->load('profile');

        return Inertia::render('Users/Show', [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'is_premium' => $user->isPremium(),
                'premium_until' => $user->premium_until?->toDateString(),
                'is_blocked' => $user->is_blocked,
                'created_at' => $user->created_at->toDateString(),
                'profile' => $user->profile?->only([
                    'gender', 'height_cm', 'weight_kg', 'target_weight_kg', 'goal', 'activity_level',
                    'daily_kcal_target', 'protein_g', 'carb_g', 'fat_g',
                ]),
            ],
            'analyses' => AiAnalysis::where('user_id', $user->id)->latest()->limit(12)->get()
                ->map(fn ($a) => [
                    'id' => $a->id, 'status' => $a->status, 'cost_usd' => (float) $a->cost_usd,
                    'cost_try' => round((float) $a->cost_usd * $rate, 4),
                    'total_kcal' => $a->result_json['total_kcal'] ?? null, 'created_at' => $a->created_at->format('d.m.Y H:i'),
                    'has_image' => (bool) $a->image_path,
                ]),
            'subscriptions' => $user->subscriptions()->latest('started_at')->get()
                ->map(fn ($s) => $s->only(['store', 'product_id', 'status', 'price', 'currency']) + [
                    'started_at' => $s->started_at->toDateString(), 'expires_at' => $s->expires_at?->toDateString(),
                ]),
            'quotaToday' => UsageQuota::where('user_id', $user->id)->whereDate('date', today())->value('ai_photo_count') ?? 0,
        ]);
    }
}
