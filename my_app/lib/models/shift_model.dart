class ShiftModel {
  final int id;
  final int cashierId;
  final double openingCashUsd;
  final double openingCashKhr;
  double? closingCashUsd;
  double? closingCashKhr;
  double totalSalesUsd;
  double totalSalesKhr;
  int totalOrdersCount;
  String status; // open, closed
  final String openedAt;
  String? closedAt;

  ShiftModel({
    required this.id,
    required this.cashierId,
    required this.openingCashUsd,
    required this.openingCashKhr,
    this.closingCashUsd,
    this.closingCashKhr,
    this.totalSalesUsd = 0.0,
    this.totalSalesKhr = 0.0,
    this.totalOrdersCount = 0,
    this.status = 'open',
    required this.openedAt,
    this.closedAt,
  });

  bool get isOpen => status == 'open';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      cashierId: json['cashier_id'] ?? 1,
      openingCashUsd: (json['opening_cash_usd'] ?? 0).toDouble(),
      openingCashKhr: (json['opening_cash_khr'] ?? 0).toDouble(),
      closingCashUsd: json['closing_cash_usd'] != null
          ? (json['closing_cash_usd']).toDouble()
          : null,
      closingCashKhr: json['closing_cash_khr'] != null
          ? (json['closing_cash_khr']).toDouble()
          : null,
      totalSalesUsd: (json['total_sales_usd'] ?? 0).toDouble(),
      totalSalesKhr: (json['total_sales_khr'] ?? 0).toDouble(),
      totalOrdersCount: json['total_orders_count'] ?? 0,
      status: json['status'] ?? 'open',
      openedAt: json['opened_at'] ?? '',
      closedAt: json['closed_at'],
    );
  }
}
