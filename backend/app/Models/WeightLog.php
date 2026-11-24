<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WeightLog extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['date' => 'date'];
}
