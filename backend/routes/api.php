<?php

use App\Http\Controllers\Api\V1\AiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\DietPlanController;
use App\Http\Controllers\Api\V1\FoodController;
use App\Http\Controllers\Api\V1\MealController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ProgressController;
use App\Http\Controllers\Api\V1\SubscriptionController;
use App\Http\Controllers\Api\V1\WaterActivityController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('webhooks/revenuecat', [SubscriptionController::class, 'webhook'])->middleware('throttle:120,1');

    Route::middleware('throttle:10,1')->group(function () {
        Route::post('auth/register', [AuthController::class, 'register']);
        Route::post('auth/login', [AuthController::class, 'login']);
    });

    Route::middleware(['auth:sanctum', 'not.blocked'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);

        Route::get('me', [ProfileController::class, 'show']);
        Route::put('me', [ProfileController::class, 'update']);
        Route::delete('me', [ProfileController::class, 'destroy']);
        Route::post('onboarding', [ProfileController::class, 'onboarding']);

        Route::get('dashboard', DashboardController::class);

        Route::get('water-activity', [WaterActivityController::class, 'show']);
        Route::post('water', [WaterActivityController::class, 'addWater']);
        Route::delete('water/last', [WaterActivityController::class, 'undoWater']);
        Route::post('activities', [WaterActivityController::class, 'addActivity']);
        Route::delete('activity-logs/{log}', [WaterActivityController::class, 'deleteActivity']);

        Route::get('diet-plans', [DietPlanController::class, 'index']);

        Route::get('progress', [ProgressController::class, 'index']);
        Route::post('weight-logs', [ProgressController::class, 'storeWeight']);

        Route::get('foods/search', [FoodController::class, 'search'])->middleware('throttle:60,1');
        Route::get('foods/barcode/{code}', [FoodController::class, 'barcode'])->middleware('throttle:30,1');

        Route::post('meals/{type}/items', [MealController::class, 'addItems']);
        Route::delete('meal-items/{item}', [MealController::class, 'deleteItem']);

        Route::get('subscription', [SubscriptionController::class, 'status']);
        Route::post('subscription/sync', [SubscriptionController::class, 'sync'])->middleware('throttle:10,1');

        Route::get('ai/quota', [AiController::class, 'quota']);
        // Günlük kota ayrıca uygulanır; bu sınır kısa sürede çok istek atılmasını engeller.
        Route::post('ai/analyze-photo', [AiController::class, 'analyzePhoto'])->middleware('throttle:6,1');
    });
});
