<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiModel extends Model
{
    protected $guarded = ['id'];
    protected $casts = ['is_active' => 'boolean'];

    public function scopeFor($q, string $purpose) { return $q->where('purpose', $purpose)->where('is_active', true)->orderBy('priority'); }

    public function costFor(int $in, int $out): float
    {
        return ($in * $this->input_price_per_mtok + $out * $this->output_price_per_mtok) / 1_000_000;
    }
}
