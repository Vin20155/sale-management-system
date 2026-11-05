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
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      barcode: json['barcode'],
      unitPriceUsd: (json['unit_price_usd'] ?? 0).toDouble(),
      unitPriceKhr: (json['unit_price_khr'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      subtotalUsd: (json['subtotal_usd'] ?? 0).toDouble(),
      subtotalKhr: (json['subtotal_khr'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'barcode': barcode,
        'unit_price_usd': unitPriceUsd,
        'unit_price_khr': unitPriceKhr,
        'quantity': quantity,
        'subtotal_usd': subtotalUsd,
        'subtotal_khr': subtotalKhr,
      };
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
  final String status;
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItemModel> itemsList =
        rawItems.map((e) => OrderItemModel.fromJson(e)).toList();

    return OrderModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      invoiceNo: json['invoice_no'] ?? '',
      subtotalUsd: (json['subtotal_usd'] ?? 0).toDouble(),
      discountUsd: (json['discount_usd'] ?? 0).toDouble(),
      taxUsd: (json['tax_usd'] ?? 0).toDouble(),
      totalUsd: (json['total_usd'] ?? 0).toDouble(),
      totalKhr: (json['total_khr'] ?? 0).toDouble(),
      exchangeRate: (json['exchange_rate'] ?? 4100.0).toDouble(),
      paymentMethod: json['payment_method'] ?? 'cash_usd',
      receivedUsd: (json['received_usd'] ?? 0).toDouble(),
      receivedKhr: (json['received_khr'] ?? 0).toDouble(),
      changeUsd: (json['change_usd'] ?? 0).toDouble(),
      changeKhr: (json['change_khr'] ?? 0).toDouble(),
      pointsEarned: json['points_earned'] ?? 0,
      status: json['status'] ?? 'completed',
      createdAt: json['created_at'] ?? '',
      cashierName: json['cashier'] != null
          ? json['cashier']['name_kh'] ?? json['cashier']['name']
          : 'បេឡាករ',
      customerName: json['customer'] != null ? json['customer']['name'] : null,
      items: itemsList,
    );
  }
}
