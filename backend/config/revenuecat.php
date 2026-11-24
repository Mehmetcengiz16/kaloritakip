<?php

return [
    // RevenueCat > Project > Integrations > Webhooks: "Authorization header value"
    'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),

    // RevenueCat > Project > API keys > Secret API key (sk_...). Satın alma sonrası anında doğrulama için.
    'secret_key' => env('REVENUECAT_SECRET_KEY'),

    // Premium erişim veren entitlement kimliği
    'entitlement' => env('REVENUECAT_ENTITLEMENT', 'premium'),

    'api_url' => 'https://api.revenuecat.com/v1',
];
