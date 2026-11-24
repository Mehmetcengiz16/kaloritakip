<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiInsight extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['content_json' => 'array', 'date' => 'date'];
}
