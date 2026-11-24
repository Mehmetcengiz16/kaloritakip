<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UsageQuota extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['date' => 'date'];
}
