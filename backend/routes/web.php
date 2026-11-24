<?php

use App\Http\Controllers\Admin;
use Illuminate\Support\Facades\Route;

// Tanıtım ve politika sayfaları (mağaza kayıtları ve uygulama içi linkler bu adresleri kullanır)
Route::controller(App\Http\Controllers\SiteController::class)->group(function () {
    Route::get('/', 'home')->name('site.home');
    Route::get('gizlilik', 'privacy')->name('site.privacy');
    Route::get('kullanim-kosullari', 'terms')->name('site.terms');
    Route::get('abonelik-kosullari', 'subscription')->name('site.subscription');
    Route::get('kvkk', 'kvkk')->name('site.kvkk');
    Route::get('hesap-silme', 'deletion')->name('site.deletion');
    Route::get('destek', 'support')->name('site.support');
});

Route::prefix('admin')->group(function () {
    Route::get('login', [Admin\AuthController::class, 'show'])->name('login');
    Route::post('login', [Admin\AuthController::class, 'login'])->middleware('throttle:5,1');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::post('logout', [Admin\AuthController::class, 'logout']);

        Route::get('/', Admin\DashboardController::class);

        Route::get('users', [Admin\UserController::class, 'index']);
        Route::get('users/{user}', [Admin\UserController::class, 'show']);
        Route::post('users/{user}/premium', [Admin\UserController::class, 'premium']);
        Route::post('users/{user}/block', [Admin\UserController::class, 'block']);
        Route::post('users/{user}/reset-quota', [Admin\UserController::class, 'resetQuota']);

        Route::get('foods', [Admin\FoodController::class, 'index']);
        Route::post('foods', [Admin\FoodController::class, 'store']);
        Route::put('foods/{food}', [Admin\FoodController::class, 'update']);
        Route::post('foods/{food}', [Admin\FoodController::class, 'update']);
        Route::post('foods/{food}/verify', [Admin\FoodController::class, 'verify']);
        Route::delete('foods/{food}', [Admin\FoodController::class, 'destroy']);

        Route::get('ai-analyses', [Admin\AiAnalysisController::class, 'index']);
        Route::get('ai-analyses/{analysis}/image', [Admin\AiAnalysisController::class, 'image']);

        Route::get('settings', [Admin\SettingsController::class, 'index']);
        Route::put('settings', [Admin\SettingsController::class, 'updateSettings']);
        Route::post('settings/fx-sync', [Admin\SettingsController::class, 'syncFx'])->middleware('throttle:6,1');
        Route::put('settings/api-key', [Admin\SettingsController::class, 'updateApiKey'])->middleware('throttle:10,1');
        Route::delete('settings/api-key', [Admin\SettingsController::class, 'destroyApiKey']);
        Route::post('settings/api-key/test', [Admin\SettingsController::class, 'testApiKey'])->middleware('throttle:10,1');
        Route::post('ai-models/sync-prices', [Admin\SettingsController::class, 'syncPrices'])->middleware('throttle:6,1');
        Route::get('ai-catalog', [Admin\SettingsController::class, 'catalog'])->middleware('throttle:60,1');
        Route::post('ai-models', [Admin\SettingsController::class, 'storeModel']);
        Route::put('ai-models/{model}', [Admin\SettingsController::class, 'updateModel']);
        Route::delete('ai-models/{model}', [Admin\SettingsController::class, 'destroyModel']);

        Route::get('expenses', [Admin\ExpenseController::class, 'index']);
        Route::post('expenses', [Admin\ExpenseController::class, 'store']);
        Route::delete('expenses/{expense}', [Admin\ExpenseController::class, 'destroy']);
    });
});
