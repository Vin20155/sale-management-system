<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'barcode',
        'item_code',
        'name_en',
        'name_kh',
        'category_id',
        'unit',
        'cost_price_usd',
        'cost_price_khr',
        'selling_price_usd',
        'selling_price_khr',
        'stock_quantity',
        'reorder_level',
        'expiry_date',
        'received_date',
        'image_url',
        'is_active',
    ];

    protected $casts = [
        'cost_price_usd' => 'float',
        'cost_price_khr' => 'float',
        'selling_price_usd' => 'float',
        'selling_price_khr' => 'float',
        'stock_quantity' => 'integer',
        'reorder_level' => 'integer',
        'is_active' => 'boolean',
        'expiry_date' => 'date',
        'received_date' => 'date',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function batches()
    {
        return $this->hasMany(ProductBatch::class);
    }

    public function activeBatches()
    {
        return $this->hasMany(ProductBatch::class)
            ->where('quantity_remaining', '>', 0)
            ->orderByRaw('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date ASC, id ASC');
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', 1);
    }

    public function scopeLowStock($query)
    {
        return $query->whereRaw('stock_quantity <= reorder_level');
    }

    public function scopeExpiringSoon($query, $days = 30)
    {
        return $query->whereNotNull('expiry_date')
            ->whereDate('expiry_date', '<=', now()->addDays($days));
    }
}
