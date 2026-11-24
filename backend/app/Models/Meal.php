<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Meal extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['date' => 'date'];

    public const TYPES = ['breakfast', 'snack1', 'lunch', 'snack2', 'dinner'];

    public function items() { return $this->hasMany(MealItem::class); }
}
