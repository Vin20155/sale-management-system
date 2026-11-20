<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductBatch extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'batch_no',
        'received_date',
        'expiry_date',
        'quantity_received',
        'quantity_remaining',
        'cost_price_usd',
        'cost_price_khr',
        'supplier_name',
        'note',
    ];

    protected $casts = [
        'received_date' => 'date',
        'expiry_date' => 'date',
        'quantity_received' => 'integer',
        'quantity_remaining' => 'integer',
        'cost_price_usd' => 'float',
        'cost_price_khr' => 'float',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function scopeAvailable($query)
    {
        return $query->where('quantity_remaining', '>', 0);
    }

    public function scopeFefo($query)
    {
        // First Expired, First Out (batches with null expiry go last)
        return $query->orderByRaw('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date ASC, id ASC');
    }
}

