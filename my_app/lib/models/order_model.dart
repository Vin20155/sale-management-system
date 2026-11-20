class OrderItemModel {
  final int productId;
  final String productName;
  final String? barcode;
  final double unitPriceUsd;
  final double unitPriceKhr;
  final int quantity;
  final double subtotalUsd;
  final double subtotalKhr;

  OrderItemModel({
    required this.productId,
    required this.productName,
    this.barcode,
    required this.unitPriceUsd,
    required this.unitPriceKhr,
    required this.quantity,
    required this.subtotalUsd,
    required this.subtotalKhr,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      unitPriceUsd:
          double.tryParse(json['unit_price_usd']?.toString() ?? '0') ?? 0.0,
      unitPriceKhr:
          double.tryParse(json['unit_price_khr']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      subtotalUsd:
          double.tryParse(json['subtotal_usd']?.toString() ?? '0') ?? 0.0,
      subtotalKhr:
          double.tryParse(json['subtotal_khr']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String invoiceNo;
  final double subtotalUsd;
  final double discountUsd;
  final double taxUsd;
  final double totalUsd;
  final double totalKhr;
  final double exchangeRate;
  final String paymentMethod; // cash_usd, cash_khr, mixed_cash, khqr_bakong
  final double receivedUsd;
  final double receivedKhr;
  final double changeUsd;
  final double changeKhr;
  final int pointsEarned;
  String status;
  final String createdAt;
  final String? cashierName;
  final String? customerName;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.invoiceNo,
    required this.subtotalUsd,
    this.discountUsd = 0.0,
    this.taxUsd = 0.0,
    required this.totalUsd,
    required this.totalKhr,
    this.exchangeRate = 4100.0,
    required this.paymentMethod,
    required this.receivedUsd,
    required this.receivedKhr,
    required this.changeUsd,
    required this.changeKhr,
    this.pointsEarned = 0,
    this.status = 'completed',
    required this.createdAt,
    this.cashierName = 'បេឡាករ',
    this.customerName,
    required this.items,
  });

  bool get isVoided => status.toLowerCase() == 'voided';
  bool get isKhqr => paymentMethod == 'khqr_bakong';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final cashierObj = json['cashier'] as Map<String, dynamic>?;
    final customerObj = json['customer'] as Map<String, dynamic>?;
    String rawDate = json['created_at']?.toString() ?? '';
    if (rawDate.length >= 19) {
      rawDate = rawDate.substring(0, 19).replaceAll('T', ' ');
    }

    return OrderModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNo: json['invoice_no']?.toString() ?? '',
      subtotalUsd:
          double.tryParse(json['subtotal_usd']?.toString() ?? '0') ?? 0.0,
      discountUsd:
          double.tryParse(json['discount_usd']?.toString() ?? '0') ?? 0.0,
      taxUsd: double.tryParse(json['tax_usd']?.toString() ?? '0') ?? 0.0,
      totalUsd: double.tryParse(json['total_usd']?.toString() ?? '0') ?? 0.0,
      totalKhr: double.tryParse(json['total_khr']?.toString() ?? '0') ?? 0.0,
      exchangeRate:
          double.tryParse(json['exchange_rate']?.toString() ?? '4100') ??
              4100.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash_usd',
      receivedUsd:
          double.tryParse(json['received_usd']?.toString() ?? '0') ?? 0.0,
      receivedKhr:
          double.tryParse(json['received_khr']?.toString() ?? '0') ?? 0.0,
      changeUsd: double.tryParse(json['change_usd']?.toString() ?? '0') ?? 0.0,
      changeKhr: double.tryParse(json['change_khr']?.toString() ?? '0') ?? 0.0,
      pointsEarned: int.tryParse(json['points_earned']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'completed',
      createdAt: rawDate,
      cashierName: cashierObj?['name']?.toString() ??
          json['cashier_name']?.toString() ??
          'បេឡាករ',
      customerName: customerObj != null
          ? '${customerObj['name'] ?? ''} (${customerObj['phone'] ?? ''})'
              .trim()
          : json['customer_name']?.toString(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItemModel.fromJson)
          .toList(),
    );
  }
}
