<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = ['name', 'email', 'password', 'provider', 'provider_id', 'avatar', 'locale'];

    protected $hidden = ['password', 'remember_token', 'provider_id'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'premium_until' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'is_blocked' => 'boolean',
        ];
    }

    public function isPremium(): bool
    {
        return $this->premium_until !== null && $this->premium_until->isFuture();
    }

    public function profile() { return $this->hasOne(UserProfile::class); }
    public function meals() { return $this->hasMany(Meal::class); }
    public function weightLogs() { return $this->hasMany(WeightLog::class); }
    public function waterLogs() { return $this->hasMany(WaterLog::class); }
    public function activityLogs() { return $this->hasMany(ActivityLog::class); }
    public function aiAnalyses() { return $this->hasMany(AiAnalysis::class); }
    public function subscriptions() { return $this->hasMany(Subscription::class); }
}
