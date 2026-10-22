<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class KhqrController extends Controller
{
    /**
     * Generate KHQR EMV payload for Bakong payment
     */
    public function generate(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0.01',
            'currency' => 'required|in:USD,KHR',
            'order_id' => 'nullable|string',
        ]);

        $setting = Setting::first();
        $bakongId = $setting->bakong_account_id ?? 'lucky_express@aclb';
        $merchantName = $setting->bakong_merchant_name ?? 'LUCKY EXPRESS MART';
        $amount = (float)$request->amount;
        $currency = strtoupper($request->currency);
        $currencyCode = ($currency === 'USD') ? '840' : '116';

        // KHQR dynamic standard format simulation
        $billNumber = $request->order_id ?? ('BILL' . time());
        $qrString = "00020101021229370016bakong@aclb29370109{$bakongId}520459995303{$currencyCode}54" . 
                    str_pad(strlen((string)$amount), 2, '0', STR_PAD_LEFT) . $amount . 
                    "5802KH59" . str_pad(strlen($merchantName), 2, '0', STR_PAD_LEFT) . $merchantName . 
                    "6010Phnom Penh62" . str_pad(strlen($billNumber) + 4, 2, '0', STR_PAD_LEFT) . "01" . str_pad(strlen($billNumber), 2, '0', STR_PAD_LEFT) . $billNumber . "6304ABCD";

        return response()->json([
            'success' => true,
            'data' => [
                'bakong_account_id' => $bakongId,
                'merchant_name' => $merchantName,
                'amount' => $amount,
                'currency' => $currency,
                'bill_number' => $billNumber,
                'qr_string' => $qrString,
                'instructions' => 'ស្កេនជាមួយកម្មវិធីបាគង (Bakong) ឬ Mobile Banking ណាមួយនៅកម្ពុជា'
            ]
        ]);
    }
}
