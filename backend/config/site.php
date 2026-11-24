<?php

/*
| Tanıtım ve politika sayfalarındaki şirket bilgileri.
| DEMO değerlerdir: yayından önce gerçek bilgilerle .env üzerinden doldurun ve
| metinleri bir hukuk danışmanına kontrol ettirin.
*/
return [
    'app_name' => env('APP_NAME', 'KaloriTakip'),
    'company' => env('SITE_COMPANY', 'KaloriTakip Yazılım (Demo Şirket)'),
    'address' => env('SITE_ADDRESS', 'Örnek Mah. Demo Sok. No:1, İstanbul, Türkiye'),
    'email' => env('SITE_EMAIL', 'destek@kaloritakip.app'),
    'kvkk_email' => env('SITE_KVKK_EMAIL', 'kvkk@kaloritakip.app'),
    'effective_date' => env('SITE_POLICY_DATE', '24 Kasım 2026'),

    'app_store_url' => env('SITE_APP_STORE_URL', '#'),
    'play_store_url' => env('SITE_PLAY_STORE_URL', '#'),
    'android_package' => env('SITE_ANDROID_PACKAGE', 'com.kaloritakip.kaloritakip'),

    // Gösterim amaçlı fiyatlar; gerçek fiyat mağazada belirlenir ve uygulamada mağazadan okunur.
    'price_monthly' => env('SITE_PRICE_MONTHLY', '139,99 ₺'),
    'price_yearly' => env('SITE_PRICE_YEARLY', '949,99 ₺'),
    'trial_days' => (int) env('SITE_TRIAL_DAYS', 7),

    'demo' => (bool) env('SITE_DEMO', true),
];
