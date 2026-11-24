<?php

return [
    'openrouter' => [
        'key' => env('OPENROUTER_API_KEY'),
        'base_url' => env('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1'),
        'timeout' => (int) env('OPENROUTER_TIMEOUT', 45),
        'app_name' => env('APP_NAME', 'KaloriTakip'),
        'app_url' => env('APP_URL'),
    ],

    // Varsayılanlar; çalışırken settings tablosundaki değerler (admin panel) önceliklidir.
    'free_daily_photo_limit' => (int) env('AI_FREE_DAILY_PHOTO_LIMIT', 2),
    'premium_daily_photo_limit' => (int) env('AI_PREMIUM_DAILY_PHOTO_LIMIT', 30),
    'daily_budget_usd' => (float) env('AI_DAILY_BUDGET_USD', 5),

    'image_max_side' => 1024,
    'image_quality' => 75,
];
