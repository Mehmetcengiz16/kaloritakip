<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DietPlan extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['is_premium' => 'boolean', 'is_active' => 'boolean'];

    public function meals() { return $this->hasMany(DietPlanMeal::class)->orderBy('sort'); }
}
