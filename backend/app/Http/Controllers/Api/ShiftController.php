<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Shift;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function current(Request $request)
    {
        $cashierId = $request->get('cashier_id', 1);
        $shift = Shift::where('cashier_id', $cashierId)
            ->where('status', 'open')
            ->latest('id')
            ->first();

        return response()->json([
            'success' => true,
            'has_active_shift' => !is_null($shift),
            'data' => $shift
        ]);
    }

    public function open(Request $request)
    {
        $request->validate([
            'opening_cash_usd' => 'required|numeric|min:0',
            'opening_cash_khr' => 'required|numeric|min:0',
            'cashier_id' => 'nullable|integer',
        ]);

        $cashierId = $request->cashier_id ?? 1;

        // Check if there is already an open shift
        $existing = Shift::where('cashier_id', $cashierId)->where('status', 'open')->first();
        if ($existing) {
            return response()->json([
                'success' => false,
                'message' => 'អ្នកមានវេនការងារដែលកំពុងដំណើរការរួចហើយ',
                'data' => $existing
            ], 400);
        }

        $shift = Shift::create([
            'cashier_id' => $cashierId,
            'opening_cash_usd' => $request->opening_cash_usd,
            'opening_cash_khr' => $request->opening_cash_khr,
            'status' => 'open',
            'opened_at' => now(),
            'note' => $request->note,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'បានបើកវេនការងារថ្មីដោយជោគជ័យ!',
            'data' => $shift
        ], 201);
    }

    public function close(Request $request)
    {
        $request->validate([
            'shift_id' => 'required|exists:shifts,id',
            'closing_cash_usd' => 'required|numeric|min:0',
            'closing_cash_khr' => 'required|numeric|min:0',
            'note' => 'nullable|string',
        ]);

        $shift = Shift::find($request->shift_id);
        if ($shift->status === 'closed') {
            return response()->json(['success' => false, 'message' => 'វេននេះត្រូវបានបិទរួចរាល់ហើយ'], 400);
        }

        $shift->update([
            'closing_cash_usd' => $request->closing_cash_usd,
            'closing_cash_khr' => $request->closing_cash_khr,
            'status' => 'closed',
            'closed_at' => now(),
            'note' => $request->note,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'បានបិទវេនការងារ និងផ្ទៀងផ្ទាត់សាច់ប្រាក់ជោគជ័យ!',
            'data' => $shift
        ]);
    }
}
