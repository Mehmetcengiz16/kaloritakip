<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiAnalysis extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['result_json' => 'array', 'from_cache' => 'boolean'];

    public function user() { return $this->belongsTo(User::class); }
}
