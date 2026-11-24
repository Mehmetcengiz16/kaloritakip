<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivityLog extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['date' => 'date'];

    public function activity() { return $this->belongsTo(Activity::class); }
}
