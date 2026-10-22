<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'phone',
        'points',
        'total_spent_usd',
    ];

    protected $casts = [
        'points' => 'integer',
        'total_spent_usd' => 'float',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
