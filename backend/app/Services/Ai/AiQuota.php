<?php

namespace App\Services\Ai;

use App\Models\AiAnalysis;
use App\Models\AiInsight;
use App\Models\Setting;
use App\Models\UsageQuota;
use App\Models\User;

/**
 * Kullanıcı başı günlük AI foto hakkı ve tüm uygulama için günlük AI bütçe tavanı.
 */
class AiQuota
{
    public function limitFor(User $user): int
    {
        return $user->isPremium()
            ? (int) Setting::get('ai_premium_daily_photo_limit', config('ai.premium_daily_photo_limit'))
            : (int) Setting::get('ai_free_daily_photo_limit', config('ai.free_daily_photo_limit'));
    }

    public function today(User $user): UsageQuota
    {
        return UsageQuota::firstOrCreate(['user_id' => $user->id, 'date' => now()->toDateString()]);
    }

    /** @return array{used: int, limit: int, remaining: int, is_premium: bool} */
    public function status(User $user): array
    {
        // Yeni oluşan satırda veritabanı varsayılanları (0) modele yansımaz; int'e çevir.
        $q = $this->today($user);
        $used = (int) $q->ai_photo_count;
        $limit = $this->limitFor($user) + (int) $q->ai_bonus_count;

        return [
            'used' => $used,
            'limit' => $limit,
            'remaining' => max(0, $limit - $used),
            'is_premium' => $user->isPremium(),
        ];
    }

    public function hasPhotoQuota(User $user): bool
    {
        return $this->status($user)['remaining'] > 0;
    }

    public function consumePhoto(User $user): void
    {
        $this->today($user)->increment('ai_photo_count');
    }

    /** Bugün harcanan toplam AI maliyeti (USD). */
    public function spentTodayUsd(): float
    {
        $today = now()->toDateString();

        return (float) AiAnalysis::whereDate('created_at', $today)->sum('cost_usd')
            + (float) AiInsight::whereDate('created_at', $today)->sum('cost_usd');
    }

    /** Günlük bütçe aşıldıysa ücretsiz kullanıcılar için AI geçici kapanır; premium devam eder. */
    public function budgetExceededFor(User $user): bool
    {
        if ($user->isPremium()) {
            return false;
        }
        $budget = (float) Setting::get('ai_daily_budget_usd', config('ai.daily_budget_usd'));

        return $budget > 0 && $this->spentTodayUsd() >= $budget;
    }
}
