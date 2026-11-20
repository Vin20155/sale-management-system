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
}
