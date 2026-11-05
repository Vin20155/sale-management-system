part of 'mart_service.dart';

extension ReportService on MartService {
  // ==========================================
  // REPORTS
  // ==========================================
  Map<String, dynamic> getTodayReport() {
    double totalUsd = _orders.fold(0.0, (sum, o) => sum + o.totalUsd);
    double totalKhr = _orders.fold(0.0, (sum, o) => sum + o.totalKhr);
    int ordersCount = _orders.length;

    return {
      'total_sales_usd': totalUsd,
      'total_sales_khr': totalKhr,
      'total_orders': ordersCount,
      'low_stock_count': getLowStockProducts().length,
      'expiring_count': getExpiringProducts().length,
    };
  }
}
