<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'cashier_id',
        'opening_cash_usd',
        'opening_cash_khr',
        'closing_cash_usd',
        'closing_cash_khr',
        'total_sales_usd',
        'total_sales_khr',
        'total_orders_count',
        'status',
        'opened_at',
        'closed_at',
        'note',
    ];

    protected $casts = [
        'opening_cash_usd' => 'float',
        'opening_cash_khr' => 'float',
        'closing_cash_usd' => 'float',
        'closing_cash_khr' => 'float',
        'total_sales_usd' => 'float',
        'total_sales_khr' => 'float',
        'total_orders_count' => 'integer',
        'opened_at' => 'datetime',
        'closed_at' => 'datetime',
    ];

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}
