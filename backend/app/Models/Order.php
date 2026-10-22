<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'invoice_no',
        'shift_id',
        'cashier_id',
        'customer_id',
        'subtotal_usd',
        'discount_usd',
        'tax_usd',
        'total_usd',
        'total_khr',
        'exchange_rate',
        'payment_method',
        'received_usd',
        'received_khr',
        'change_usd',
        'change_khr',
        'points_earned',
        'status',
    ];

    protected $casts = [
        'subtotal_usd' => 'float',
        'discount_usd' => 'float',
        'tax_usd' => 'float',
        'total_usd' => 'float',
        'total_khr' => 'float',
        'exchange_rate' => 'float',
        'received_usd' => 'float',
        'received_khr' => 'float',
        'change_usd' => 'float',
        'change_khr' => 'float',
        'points_earned' => 'integer',
    ];

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
