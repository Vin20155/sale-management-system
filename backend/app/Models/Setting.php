<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    use HasFactory;

    protected $fillable = [
        'mart_name_en',
        'mart_name_kh',
        'branch_name',
        'phone',
        'address_kh',
        'exchange_rate',
        'tax_percentage',
        'bakong_account_id',
        'bakong_merchant_name',
        'receipt_footer_kh',
    ];

    protected $casts = [
        'exchange_rate' => 'float',
        'tax_percentage' => 'float',
    ];
}
