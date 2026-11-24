<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Ai\AiQuota;
use App\Services\SubscriptionService;
use Illuminate\Http\Request;
use Throwable;

class SubscriptionController extends Controller
{
    /** Uygulama: premium durumu ve bugünkü AI hakkı (ücretsiz ve premium limitleriyle, paywall'da gösterilir). */
    public function status(Request $request, AiQuota $quota)
    {
        $user = $request->user();

        return ['data' => [
            'is_premium' => $user->isPremium(),
            'premium_until' => $user->premium_until?->toIso8601String(),
            'quota' => $quota->status($user),
            'limits' => [
                'free_daily' => (int) \App\Models\Setting::get('ai_free_daily_photo_limit', config('ai.free_daily_photo_limit')),
                'premium_daily' => (int) \App\Models\Setting::get('ai_premium_daily_photo_limit', config('ai.premium_daily_photo_limit')),
            ],
        ]];
    }

    /** Satın alma/geri yükleme sonrası: RevenueCat'ten doğrulayıp premium'u hemen aç. */
    public function sync(Request $request, SubscriptionService $subs, AiQuota $quota)
    {
        try {
            $subs->syncFromRevenueCat($request->user());
        } catch (Throwable $e) {
            report($e);
            // Webhook yine de birkaç saniye içinde günceller; uygulamaya mevcut durumu döndür.
        }

        return $this->status($request, $quota);
    }

    /** RevenueCat webhook: Authorization başlığı panelde tanımlanan gizli değerle eşleşmeli. */
    public function webhook(Request $request, SubscriptionService $subs)
    {
        $secret = config('revenuecat.webhook_secret');
        abort_unless($secret && hash_equals($secret, (string) $request->header('Authorization')), 401);

        $event = $request->input('event');
        abort_unless(is_array($event), 422);

        return ['result' => $subs->handleEvent($event)];
    }
}
