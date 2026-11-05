part of 'mart_service.dart';

extension OrderService on MartService {
  // ==========================================
  // POS ORDERS & CHECKOUT
  // ==========================================
  Future<OrderModel> checkout({
    required List<CartItemModel> items,
    required String paymentMethod,
    double receivedUsd = 0.0,
    double receivedKhr = 0.0,
    String? customerPhone,
    String? customerName,
  }) async {
    double subtotalUsd = items.fold(0.0, (sum, item) => sum + item.subtotalUsd);
    double totalUsd = subtotalUsd;
    double totalKhr = (totalUsd * _settings.exchangeRate).roundToDouble();

    // Change calculation
    double changeUsd = 0.0;
    double changeKhr = 0.0;

    if (paymentMethod == 'khqr_bakong') {
      receivedUsd = totalUsd;
      receivedKhr = totalKhr;
      changeUsd = 0.0;
      changeKhr = 0.0;
    } else {
      double totalPaidUsd =
          receivedUsd + (receivedKhr / _settings.exchangeRate);
      double changeEquivalentUsd =
          (totalPaidUsd - totalUsd) > 0 ? (totalPaidUsd - totalUsd) : 0.0;
      changeUsd = changeEquivalentUsd.floorToDouble();
      changeKhr = ((changeEquivalentUsd - changeUsd) * _settings.exchangeRate)
          .roundToDouble();
    }

    // Deduct stock
    for (var cartItem in items) {
      final p = _products.firstWhere((prod) => prod.id == cartItem.product.id,
          orElse: () => cartItem.product);
      p.stockQuantity = (p.stockQuantity - cartItem.quantity).clamp(0, 999999);
    }

    // Invoice No
    String dateStr =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String invoiceNo =
        'INV-$dateStr-${(_orders.length + 1).toString().padLeft(4, '0')}';

    List<OrderItemModel> orderItems = items
        .map((ci) => OrderItemModel(
              productId: ci.product.id,
              productName: ci.product.nameKh,
              barcode: ci.product.barcode,
              unitPriceUsd: ci.product.sellingPriceUsd,
              unitPriceKhr: ci.product.sellingPriceKhr,
              quantity: ci.quantity,
              subtotalUsd: ci.subtotalUsd,
              subtotalKhr: ci.subtotalKhr,
            ))
        .toList();

    int pointsEarned = totalUsd.floor();

    final order = OrderModel(
      id: _orders.length + 1,
      invoiceNo: invoiceNo,
      subtotalUsd: subtotalUsd,
      totalUsd: totalUsd,
      totalKhr: totalKhr,
      exchangeRate: _settings.exchangeRate,
      paymentMethod: paymentMethod,
      receivedUsd: receivedUsd,
      receivedKhr: receivedKhr,
      changeUsd: changeUsd,
      changeKhr: changeKhr,
      pointsEarned: pointsEarned,
      createdAt: DateTime.now().toString().substring(0, 19),
      cashierName: 'តារា ចាន់ (Cashier)',
      customerName: customerName ??
          (customerPhone != null ? 'អតិថិជន ($customerPhone)' : null),
      items: orderItems,
    );

    _orders.insert(0, order);

    // Update active shift if any
    if (_currentShift != null && _currentShift!.isOpen) {
      _currentShift!.totalSalesUsd += totalUsd;
      _currentShift!.totalSalesKhr += totalKhr;
      _currentShift!.totalOrdersCount += 1;
    }

    return order;
  }

  Future<List<OrderModel>> getOrders() async {
    return _orders;
  }
}
