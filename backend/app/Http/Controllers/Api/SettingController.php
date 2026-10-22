<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class SettingController extends Controller
{
    public function index()
    {
        $setting = Setting::first();
        if (!$setting) {
            $setting = Setting::create([
                'mart_name_en' => 'Lucky Express Mart',
                'mart_name_kh' => 'ឡាក់គី អិចប្រេស ម៉ាត',
                'branch_name' => 'សាខាទួលគោក, ភ្នំពេញ',
                'phone' => '012 345 678',
                'address_kh' => 'រាជធានីភ្នំពេញ',
                'exchange_rate' => 4100.00,
                'tax_percentage' => 0.00,
                'bakong_account_id' => 'lucky_express@aclb',
                'bakong_merchant_name' => 'LUCKY EXPRESS MART',
                'receipt_footer_kh' => 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => $setting
        ]);
    }

    public function update(Request $request)
    {
        $setting = Setting::first();
        if (!$setting) {
            $setting = new Setting();
        }

        $setting->fill($request->all());
        $setting->save();

        return response()->json([
            'success' => true,
            'message' => 'បានកែប្រែការកំណត់ម៉ាតដោយជោគជ័យ',
            'data' => $setting
        ]);
    }
}
