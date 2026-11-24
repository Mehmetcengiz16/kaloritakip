<?php

namespace App\Services\Ai;

use App\Models\Setting;
use Illuminate\Contracts\Encryption\DecryptException;
use Illuminate\Support\Facades\Crypt;

/**
 * OpenRouter API anahtarı: admin panelden girilen (veritabanında APP_KEY ile şifreli) önceliklidir,
 * yoksa .env'deki OPENROUTER_API_KEY kullanılır.
 */
class AiCredentials
{
    private const SETTING = 'openrouter_api_key';

    public static function key(): ?string
    {
        return self::panelKey() ?? (config('ai.openrouter.key') ?: null);
    }

    /** 'panel' | 'env' | null */
    public static function source(): ?string
    {
        if (self::panelKey()) {
            return 'panel';
        }

        return config('ai.openrouter.key') ? 'env' : null;
    }

    /** Ekranda gösterilecek maskeli hali: sk-or-v1-••••••••a1b2 */
    public static function masked(): ?string
    {
        $key = self::key();
        if (! $key) {
            return null;
        }

        return substr($key, 0, min(9, (int) (strlen($key) / 3))).'••••••••'.substr($key, -4);
    }

    public static function store(string $key): void
    {
        Setting::put(self::SETTING, Crypt::encryptString(trim($key)));
    }

    public static function forget(): void
    {
        Setting::where('key', self::SETTING)->delete();
        cache()->forget('setting.'.self::SETTING);
    }

    private static function panelKey(): ?string
    {
        $encrypted = Setting::get(self::SETTING);
        if (! $encrypted) {
            return null;
        }

        try {
            return Crypt::decryptString($encrypted) ?: null;
        } catch (DecryptException) {
            return null; // APP_KEY değiştiyse eski anahtar okunamaz; yeniden girilmeli
        }
    }
}
