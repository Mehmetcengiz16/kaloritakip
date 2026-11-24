<?php

namespace App\Services;

use App\Models\Setting;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * RevenueCat abonelik olaylarını uygular: subscriptions tablosu (gelir hesabı) ve users.premium_until (erişim).
 * Kullanıcı RevenueCat'te kendi id'mizle tanımlanır (Purchases.logIn(userId)).
 */
class SubscriptionService
{
    /** Erişimi açan olaylar */
    private const ACTIVE = ['INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'NON_RENEWING_PURCHASE'];

    public function __construct(private ProfitabilityService $profit) {}

    /** @return string işlenen sonucun kısa açıklaması (log/test için) */
    public function handleEvent(array $event): string
    {
        $user = $this->resolveUser($event);
        if (! $user) {
            return 'ignored:unknown_user';
        }

        $type = $event['type'] ?? '';
        $expiresAt = isset($event['expiration_at_ms']) ? Carbon::createFromTimestampMs($event['expiration_at_ms']) : null;
        $txId = $event['transaction_id'] ?? $event['original_transaction_id'] ?? $event['id'] ?? null;

        if (in_array($type, self::ACTIVE, true)) {
            $trial = ($event['period_type'] ?? null) === 'TRIAL';
            [$price, $currency] = $this->priceTry($event, $trial);

            Subscription::updateOrCreate(
                ['user_id' => $user->id, 'original_transaction_id' => $txId],
                [
                    'store' => $this->store($event['store'] ?? ''),
                    'product_id' => $event['product_id'] ?? 'unknown',
                    'status' => $trial ? 'trial' : 'active',
                    'started_at' => isset($event['purchased_at_ms']) ? Carbon::createFromTimestampMs($event['purchased_at_ms']) : now(),
                    'expires_at' => $expiresAt,
                    'price' => $price,
                    'store_fee' => round($price * (float) Setting::get('store_fee_pct', 15) / 100, 2),
                    'currency' => $currency,
                ],
            );
            $this->extendPremium($user, $expiresAt);

            return 'active';
        }

        if ($type === 'CANCELLATION') {
            // İade: erişim hemen kapanır, gelir sayılmaz. Normal iptal: süre sonuna kadar premium kalır.
            $refund = ($event['cancel_reason'] ?? null) === 'CUSTOMER_SUPPORT';
            $this->latest($user)?->update(['status' => $refund ? 'refunded' : 'cancelled']);
            if ($refund) {
                $user->forceFill(['premium_until' => now()])->save();
            }

            return $refund ? 'refunded' : 'cancelled';
        }

        if ($type === 'EXPIRATION') {
            $this->latest($user)?->update(['status' => 'expired']);
            $user->forceFill(['premium_until' => $expiresAt && $expiresAt->isPast() ? $expiresAt : now()])->save();

            return 'expired';
        }

        return 'ignored:'.$type; // BILLING_ISSUE, TRANSFER, TEST vb.
    }

    /**
     * Satın almadan hemen sonra uygulama çağırır: RevenueCat REST API'den güncel durumu okuyup premium'u ayarlar
     * (webhook birkaç saniye gecikebilir).
     */
    public function syncFromRevenueCat(User $user): bool
    {
        $key = config('revenuecat.secret_key');
        if (! $key) {
            throw new RuntimeException('REVENUECAT_SECRET_KEY tanımlı değil.');
        }

        $res = Http::withToken($key)->timeout(10)->get(config('revenuecat.api_url').'/subscribers/'.$user->id);
        if ($res->failed()) {
            throw new RuntimeException('RevenueCat yanıt vermedi ('.$res->status().').');
        }

        $ent = $res->json('subscriber.entitlements.'.config('revenuecat.entitlement'));
        $expires = isset($ent['expires_date']) ? Carbon::parse($ent['expires_date']) : null;

        if ($ent && (! $expires || $expires->isFuture())) {
            // Ömür boyu (expires_date null) erişim için uzak bir tarih.
            $this->extendPremium($user, $expires ?? now()->addYears(50));

            return true;
        }

        return $user->isPremium();
    }

    private function extendPremium(User $user, ?Carbon $until): void
    {
        $until ??= now()->addMonth();
        if (! $user->premium_until || $user->premium_until->lt($until)) {
            $user->forceFill(['premium_until' => $until])->save();
        }
    }

    private function resolveUser(array $event): ?User
    {
        $ids = array_filter([$event['app_user_id'] ?? null, $event['original_app_user_id'] ?? null, ...($event['aliases'] ?? [])]);
        foreach ($ids as $id) {
            if (ctype_digit((string) $id) && $user = User::find((int) $id)) {
                return $user;
            }
        }

        return null;
    }

    private function latest(User $user): ?Subscription
    {
        return Subscription::where('user_id', $user->id)->where('store', '!=', 'manual')->latest('started_at')->first();
    }

    /** Geliri TL olarak sakla: TL ödemede ödenen tutar, diğerlerinde USD fiyat × güncel kur. */
    private function priceTry(array $event, bool $trial): array
    {
        if ($trial) {
            return [0, 'TRY'];
        }
        if (($event['currency'] ?? null) === 'TRY' && isset($event['price_in_purchased_currency'])) {
            return [round((float) $event['price_in_purchased_currency'], 2), 'TRY'];
        }

        return [round((float) ($event['price'] ?? 0) * $this->profit->usdTry(), 2), 'TRY'];
    }

    private function store(string $store): string
    {
        return match ($store) {
            'APP_STORE', 'MAC_APP_STORE' => 'app_store',
            'PLAY_STORE' => 'play_store',
            default => 'manual',
        };
    }
}
