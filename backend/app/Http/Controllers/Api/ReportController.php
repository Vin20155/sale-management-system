<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function todaySummary()
    {
        $today = today();

        $totalSalesUsd = Order::whereDate('created_at', $today)->where('status', 'completed')->sum('total_usd');
        $totalSalesKhr = Order::whereDate('created_at', $today)->where('status', 'completed')->sum('total_khr');
        $ordersCount = Order::whereDate('created_at', $today)->where('status', 'completed')->count();

        $lowStockCount = Product::lowStock()->active()->count();
        $expiringCount = Product::expiringSoon(30)->active()->count();

        // Top 5 selling items today or all-time
        $topProducts = OrderItem::select('product_name', DB::raw('SUM(quantity) as total_qty'), DB::raw('SUM(subtotal_usd) as total_revenue'))
            ->groupBy('product_name')
            ->orderBy('total_qty', 'desc')
            ->limit(5)
            ->get();

        // Payment breakdown
        $paymentBreakdown = Order::whereDate('created_at', $today)
            ->where('status', 'completed')
            ->select('payment_method', DB::raw('COUNT(*) as count'), DB::raw('SUM(total_usd) as total_usd'))
            ->groupBy('payment_method')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $today->format('Y-m-d'),
                'total_sales_usd' => (float)$totalSalesUsd,
                'total_sales_khr' => (float)$totalSalesKhr,
                'total_transactions' => $ordersCount,
                'low_stock_alerts' => $lowStockCount,
                'expiring_alerts' => $expiringCount,
                'top_products' => $topProducts,
                'payment_breakdown' => $paymentBreakdown,
            ]
        ]);
    }
}
