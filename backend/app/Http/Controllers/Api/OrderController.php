<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\ProductBatch;
use App\Models\Setting;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with(['items', 'cashier', 'customer'])
            ->orderBy('id', 'desc')
            ->paginate($request->get('limit', 20));

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function show($id)
    {
        $order = Order::with(['items.product', 'cashier', 'customer'])->find($id);

        if (!$order) {
            return response()->json(['success' => false, 'message' => 'រកមិនឃើញវិក្កយបត្រ'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $order
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|exists:products,id',
            'items.*.quantity' => 'required|integer|min:1',
            'payment_method' => 'required|in:cash_usd,cash_khr,mixed_cash,khqr_bakong',
            'received_usd' => 'nullable|numeric|min:0',
            'received_khr' => 'nullable|numeric|min:0',
            'customer_phone' => 'nullable|string',
            'cashier_id' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'ទិន្នន័យនៃការលក់មិនត្រឹមត្រូវ',
                'errors' => $validator->errors()
            ], 422);
        }

        $setting = Setting::first();
        $exchangeRate = $setting ? (float)$setting->exchange_rate : 4100.00;

        return DB::transaction(function () use ($request, $exchangeRate) {
            $subtotalUsd = 0.0;
            $itemsData = [];

            // 1. Process items and verify stock
            foreach ($request->items as $item) {
                $product = Product::lockForUpdate()->find($item['product_id']);
                
                if ($product->stock_quantity < $item['quantity']) {
                    return response()->json([
                        'success' => false,
                        'message' => "ទំនិញ '{$product->name_kh}' មិនគ្រប់គ្រាន់ក្នុងស្តុកទេ (នៅសល់តែ {$product->stock_quantity} {$product->unit})",
                    ], 400);
                }

                $qty = (int)$item['quantity'];
                $unitPriceUsd = (float)$product->selling_price_usd;
                $unitPriceKhr = (float)$product->selling_price_khr;
                $lineSubtotalUsd = $unitPriceUsd * $qty;
                $lineSubtotalKhr = $lineSubtotalUsd * $exchangeRate;

                // Deduct stock from product table
                $product->decrement('stock_quantity', $qty);

                // FEFO: Deduct stock from product batches (earliest expiry first)
                $batches = ProductBatch::where('product_id', $product->id)
                    ->where('quantity_remaining', '>', 0)
                    ->orderByRaw('CASE WHEN expiry_date IS NULL THEN 1 ELSE 0 END, expiry_date ASC, id ASC')
                    ->lockForUpdate()
                    ->get();

                $needed = $qty;
                foreach ($batches as $b) {
                    if ($needed <= 0) break;
                    $deduct = min($needed, $b->quantity_remaining);
                    $b->decrement('quantity_remaining', $deduct);
                    $needed -= $deduct;
                }

                // Update product table's primary expiry_date to match next available batch
                $nextBatch = ProductBatch::where('product_id', $product->id)
                    ->where('quantity_remaining', '>', 0)
                    ->whereNotNull('expiry_date')
                    ->orderBy('expiry_date', 'asc')
                    ->first();
                if ($nextBatch) {
                    $product->update(['expiry_date' => $nextBatch->expiry_date]);
                }

                $subtotalUsd += $lineSubtotalUsd;

                $itemsData[] = [
                    'product_id' => $product->id,
                    'product_name' => $product->name_kh,
                    'barcode' => $product->barcode,
                    'unit_price_usd' => $unitPriceUsd,
                    'unit_price_khr' => $unitPriceKhr,
                    'quantity' => $qty,
                    'discount_usd' => 0.0,
                    'subtotal_usd' => $lineSubtotalUsd,
                    'subtotal_khr' => $lineSubtotalKhr,
                ];
            }

            $discountUsd = (float)($request->discount_usd ?? 0.0);
            $taxUsd = (float)($request->tax_usd ?? 0.0);
            $totalUsd = max(0, $subtotalUsd - $discountUsd + $taxUsd);
            $totalKhr = round($totalUsd * $exchangeRate, -2); // Round to nearest 100 Riel

            // 2. Customer & Loyalty Points
            $customer = null;
            $pointsEarned = 0;
            if (!empty($request->customer_phone)) {
                $customer = Customer::firstOrCreate(
                    ['phone' => $request->customer_phone],
                    ['name' => $request->customer_name ?? 'Mart Customer']
                );
                $pointsEarned = (int)floor($totalUsd);
                $customer->increment('points', $pointsEarned);
                $customer->increment('total_spent_usd', $totalUsd);
            }

            // 3. Payment & Change calculation
            $receivedUsd = (float)($request->received_usd ?? 0.0);
            $receivedKhr = (float)($request->received_khr ?? 0.0);
            $paymentMethod = $request->payment_method;

            if ($paymentMethod === 'khqr_bakong') {
                $receivedUsd = $totalUsd;
                $receivedKhr = $totalKhr;
                $changeUsd = 0.0;
                $changeKhr = 0.0;
            } else {
                $totalPaidUsdEquivalent = $receivedUsd + ($receivedKhr / $exchangeRate);
                $changeEquivalentUsd = max(0, $totalPaidUsdEquivalent - $totalUsd);
                $changeUsd = floor($changeEquivalentUsd);
                $changeKhr = round(($changeEquivalentUsd - $changeUsd) * $exchangeRate, -2);
            }

            // 4. Current active shift
            $cashierId = $request->cashier_id ?? 1;
            $activeShift = Shift::where('cashier_id', $cashierId)->where('status', 'open')->first();

            // 5. Generate Invoice Number (e.g. INV-20261020-0042)
            $datePrefix = date('Ymd');
            $dailyCount = Order::whereDate('created_at', today())->count() + 1;
            $invoiceNo = 'INV-' . $datePrefix . '-' . str_pad($dailyCount, 4, '0', STR_PAD_LEFT);

            // 6. Create Order
            $order = Order::create([
                'invoice_no' => $invoiceNo,
                'shift_id' => $activeShift ? $activeShift->id : null,
                'cashier_id' => $cashierId,
                'customer_id' => $customer ? $customer->id : null,
                'subtotal_usd' => $subtotalUsd,
                'discount_usd' => $discountUsd,
                'tax_usd' => $taxUsd,
                'total_usd' => $totalUsd,
                'total_khr' => $totalKhr,
                'exchange_rate' => $exchangeRate,
                'payment_method' => $paymentMethod,
                'received_usd' => $receivedUsd,
                'received_khr' => $receivedKhr,
                'change_usd' => $changeUsd,
                'change_khr' => $changeKhr,
                'points_earned' => $pointsEarned,
                'status' => 'completed',
            ]);

            // Save order items
            foreach ($itemsData as $itemData) {
                $itemData['order_id'] = $order->id;
                OrderItem::create($itemData);
            }

            // Update shift summary if active
            if ($activeShift) {
                $activeShift->increment('total_sales_usd', $totalUsd);
                $activeShift->increment('total_sales_khr', $totalKhr);
                $activeShift->increment('total_orders_count', 1);
            }

            return response()->json([
                'success' => true,
                'message' => 'ការលក់ទទួលបានជោគជ័យ!',
                'data' => $order->load(['items', 'customer', 'cashier'])
            ], 201);
        });
    }

    public function voidOrder($id)
    {
        $order = Order::with('items')->find($id);

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'រកមិនឃើញវិក្កយបត្រ'
            ], 404);
        }

        if ($order->status === 'voided') {
            return response()->json([
                'success' => false,
                'message' => 'វិក្កយបត្រនេះត្រូវបានបោះបង់រួចហើយ'
            ], 400);
        }

        return DB::transaction(function () use ($order) {
            foreach ($order->items as $item) {
                if ($item->product_id) {
                    Product::where('id', $item->product_id)
                        ->increment('stock_quantity', (int) $item->quantity);
                }
            }

            if ($order->shift_id) {
                $shift = Shift::find($order->shift_id);
                if ($shift && $shift->status === 'open') {
                    $shift->decrement('total_sales_usd', (float) $order->total_usd);
                    $shift->decrement('total_sales_khr', (float) $order->total_khr);
                    $shift->decrement('total_orders_count', 1);
                }
            }

            $order->status = 'voided';
            $order->save();

            return response()->json([
                'success' => true,
                'message' => 'បានបោះបង់វិក្កយបត្រ និងបង្វិលស្តុកទំនិញវិញរួចរាល់',
                'data' => $order->load(['items', 'customer', 'cashier'])
            ]);
        });
    }
}
