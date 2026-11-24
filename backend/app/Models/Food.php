<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

class Food extends Model
{
    protected $table = 'foods';
    protected $guarded = ['id'];
    protected $casts = ['verified' => 'boolean'];

    /** Yüklenen görsel önceliklidir, yoksa dış kaynak (Open Food Facts). */
    public function imageUrl(): ?string
    {
        if ($this->image_path) {
            return Storage::disk('public')->url($this->image_path);
        }

        return $this->image_url ?: null;
    }
}
