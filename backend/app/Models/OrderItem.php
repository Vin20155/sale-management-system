<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'order_id',
        'product_id',
        'product_name',
        'barcode',
        'unit_price_usd',
        'unit_price_khr',
        'quantity',
        'discount_usd',
        'subtotal_usd',
        'subtotal_khr',
    ];

    protected $casts = [
        'unit_price_usd' => 'float',
        'unit_price_khr' => 'float',
        'quantity' => 'integer',
        'discount_usd' => 'float',
        'subtotal_usd' => 'float',
        'subtotal_khr' => 'float',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
