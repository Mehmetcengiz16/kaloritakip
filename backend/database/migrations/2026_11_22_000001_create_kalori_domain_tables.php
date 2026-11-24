<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->string('provider')->nullable()->after('password');
            $t->string('provider_id')->nullable()->after('provider');
            $t->string('avatar')->nullable();
            $t->string('locale', 5)->default('tr');
            $t->boolean('is_admin')->default(false);
            $t->boolean('is_blocked')->default(false);
            $t->timestamp('premium_until')->nullable();
            $t->string('password')->nullable()->change();
        });

        Schema::create('user_profiles', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $t->enum('gender', ['male', 'female'])->nullable();
            $t->date('birth_date')->nullable();
            $t->unsignedSmallInteger('height_cm')->nullable();
            $t->decimal('weight_kg', 5, 1)->nullable();
            $t->decimal('target_weight_kg', 5, 1)->nullable();
            $t->enum('goal', ['lose', 'gain', 'maintain', 'healthy'])->default('lose');
            $t->enum('activity_level', ['sedentary', 'light', 'moderate', 'active', 'very_active'])->default('light');
            $t->unsignedSmallInteger('daily_kcal_target')->default(2000);
            $t->unsignedSmallInteger('protein_g')->default(150);
            $t->unsignedSmallInteger('carb_g')->default(250);
            $t->unsignedSmallInteger('fat_g')->default(70);
            $t->unsignedSmallInteger('water_ml_target')->default(3000);
            $t->boolean('notifications_enabled')->default(true);
            $t->timestamps();
        });

        Schema::create('foods', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('brand')->nullable();
            $t->string('barcode')->nullable()->unique();
            $t->decimal('kcal_per_100g', 7, 2);
            $t->decimal('protein_per_100g', 6, 2)->default(0);
            $t->decimal('carb_per_100g', 6, 2)->default(0);
            $t->decimal('fat_per_100g', 6, 2)->default(0);
            $t->unsignedSmallInteger('default_portion_g')->default(100);
            $t->enum('source', ['manual', 'openfoodfacts', 'ai'])->default('manual');
            $t->boolean('verified')->default(false);
            $t->timestamps();
            $t->index('name');
        });

        Schema::create('ai_models', function (Blueprint $t) {
            $t->id();
            $t->string('slug');                     // openrouter model id
            $t->string('label');
            $t->enum('purpose', ['vision', 'text']);
            $t->decimal('input_price_per_mtok', 10, 4)->default(0);
            $t->decimal('output_price_per_mtok', 10, 4)->default(0);
            $t->unsignedTinyInteger('priority')->default(1); // 1 = ana model, 2+ = yedek
            $t->unique(['slug', 'purpose']);
            $t->boolean('is_active')->default(true);
            $t->timestamps();
        });

        Schema::create('ai_analyses', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('image_path')->nullable();
            $t->string('image_hash', 64)->index();
            $t->string('model')->nullable();
            $t->unsignedInteger('prompt_tokens')->default(0);
            $t->unsignedInteger('completion_tokens')->default(0);
            $t->decimal('cost_usd', 10, 6)->default(0);
            $t->boolean('from_cache')->default(false);
            $t->enum('status', ['pending', 'done', 'failed', 'not_food'])->default('pending');
            $t->json('result_json')->nullable();
            $t->text('error')->nullable();
            $t->unsignedInteger('latency_ms')->nullable();
            $t->timestamps();
            $t->index(['created_at', 'status']);
        });

        Schema::create('ai_insights', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->date('date');
            $t->json('content_json');
            $t->string('model')->nullable();
            $t->decimal('cost_usd', 10, 6)->default(0);
            $t->timestamps();
            $t->unique(['user_id', 'date']);
        });

        Schema::create('meals', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->date('date');
            $t->enum('type', ['breakfast', 'snack1', 'lunch', 'snack2', 'dinner']);
            $t->timestamps();
            $t->unique(['user_id', 'date', 'type']);
        });

        Schema::create('meal_items', function (Blueprint $t) {
            $t->id();
            $t->foreignId('meal_id')->constrained()->cascadeOnDelete();
            $t->foreignId('food_id')->nullable()->constrained('foods')->nullOnDelete();
            $t->foreignId('ai_analysis_id')->nullable()->constrained()->nullOnDelete();
            $t->string('name');
            $t->unsignedSmallInteger('grams');
            $t->unsignedSmallInteger('kcal');
            $t->decimal('protein', 6, 1)->default(0);
            $t->decimal('carb', 6, 1)->default(0);
            $t->decimal('fat', 6, 1)->default(0);
            $t->timestamps();
        });

        Schema::create('weight_logs', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->date('date');
            $t->decimal('weight_kg', 5, 1);
            $t->decimal('body_fat_pct', 4, 1)->nullable();
            $t->timestamps();
            $t->unique(['user_id', 'date']);
        });

        Schema::create('water_logs', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->date('date');
            $t->unsignedSmallInteger('amount_ml');
            $t->timestamps();
            $t->index(['user_id', 'date']);
        });

        Schema::create('activities', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('icon')->default('activity');
            $t->decimal('met', 4, 1);
            $t->boolean('is_active')->default(true);
            $t->timestamps();
        });

        Schema::create('activity_logs', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('activity_id')->nullable()->constrained()->nullOnDelete();
            $t->string('name');
            $t->date('date');
            $t->unsignedSmallInteger('minutes');
            $t->unsignedSmallInteger('kcal');
            $t->timestamps();
            $t->index(['user_id', 'date']);
        });

        Schema::create('diet_plans', function (Blueprint $t) {
            $t->id();
            $t->enum('goal', ['lose', 'gain', 'maintain']);
            $t->string('title');
            $t->unsignedSmallInteger('daily_kcal');
            $t->boolean('is_premium')->default(false);
            $t->boolean('is_active')->default(true);
            $t->timestamps();
        });

        Schema::create('diet_plan_meals', function (Blueprint $t) {
            $t->id();
            $t->foreignId('diet_plan_id')->constrained()->cascadeOnDelete();
            $t->enum('meal_type', ['breakfast', 'snack1', 'lunch', 'snack2', 'dinner']);
            $t->string('title');
            $t->string('description')->nullable();
            $t->unsignedSmallInteger('kcal');
            $t->unsignedTinyInteger('sort')->default(0);
            $t->timestamps();
        });

        Schema::create('subscriptions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->enum('store', ['app_store', 'play_store', 'manual']);
            $t->string('product_id');
            $t->string('original_transaction_id')->nullable()->index();
            $t->enum('status', ['trial', 'active', 'cancelled', 'expired', 'refunded']);
            $t->timestamp('started_at');
            $t->timestamp('expires_at')->nullable();
            $t->decimal('price', 10, 2)->default(0);
            $t->decimal('store_fee', 10, 2)->default(0);
            $t->string('currency', 3)->default('TRY');
            $t->timestamps();
        });

        Schema::create('usage_quotas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->date('date');
            $t->unsignedSmallInteger('ai_photo_count')->default(0);
            $t->unsignedSmallInteger('ai_bonus_count')->default(0); // ödüllü reklamdan
            $t->unsignedSmallInteger('ai_insight_count')->default(0);
            $t->timestamps();
            $t->unique(['user_id', 'date']);
        });

        Schema::create('expenses', function (Blueprint $t) {
            $t->id();
            $t->enum('category', ['server', 'storage', 'openrouter', 'store_fee', 'marketing', 'other']);
            $t->string('description')->nullable();
            $t->decimal('amount', 12, 2);
            $t->string('currency', 3)->default('TRY');
            $t->date('date');
            $t->timestamps();
        });

        Schema::create('settings', function (Blueprint $t) {
            $t->string('key')->primary();
            $t->text('value')->nullable();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        foreach ([
            'settings', 'expenses', 'usage_quotas', 'subscriptions', 'diet_plan_meals', 'diet_plans',
            'activity_logs', 'activities', 'water_logs', 'weight_logs', 'meal_items', 'meals',
            'ai_insights', 'ai_analyses', 'ai_models', 'foods', 'user_profiles',
        ] as $table) {
            Schema::dropIfExists($table);
        }
        Schema::table('users', function (Blueprint $t) {
            $t->dropColumn(['provider', 'provider_id', 'avatar', 'locale', 'is_admin', 'is_blocked', 'premium_until']);
        });
    }
};
