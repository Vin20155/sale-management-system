<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name_en',
        'name_kh',
        'code',
        'icon',
        'color_hex',
        'description',
    ];

    public function products()
    {
        return $this->hasMany(Product::class);
    }
}
