part of 'mart_service.dart';

extension OrderService on MartService {
  // ==========================================
  // POS ORDERS & CHECKOUT
  // ==========================================
  Future<OrderModel> checkout({
    required List<CartItemModel> items,
    required String paymentMethod,
    double discountUsd = 0.0,
    double receivedUsd = 0.0,
    double receivedKhr = 0.0,
    String? customerPhone,
    String? customerName,
  }) async {
    if (_isOnline) {
      try {
        final sp = await SharedPreferences.getInstance();
        final cashierId = int.tryParse(sp.getString('UID') ?? '');
        final res = await http
            .post(
              Uri.parse('$_baseUrl/orders'),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'items': items
                    .map((ci) => {
                          'product_id': ci.product.id,
                          'quantity': ci.quantity,
                        })
                    .toList(),
                'payment_method': paymentMethod,
                'discount_usd': discountUsd,
                'received_usd': receivedUsd,
                'received_khr': receivedKhr,
                if (customerPhone != null && customerPhone.isNotEmpty)
                  'customer_phone': customerPhone,
                if (customerName != null && customerName.isNotEmpty)
                  'customer_name': customerName,
                if (cashierId != null) 'cashier_id': cashierId,
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 201 || res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is Map<String, dynamic>) {
            final serverOrder =
                OrderModel.fromJson(body['data'] as Map<String, dynamic>);
            _orders.removeWhere((o) => o.id == serverOrder.id);
            _orders.insert(0, serverOrder);
            await getProducts();
            return serverOrder;
          }
        }
      } catch (e) {
        debugPrint('Online checkout fallback to local: $e');
      }
    }

    double subtotalUsd = items.fold(0.0, (sum, item) => sum + item.subtotalUsd);
    double totalUsd = (subtotalUsd - discountUsd).clamp(0.0, 9999999.0);
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

    // Deduct stock (FEFO: First Expired, First Out)
    for (var cartItem in items) {
      final p = _products.firstWhere((prod) => prod.id == cartItem.product.id,
          orElse: () => cartItem.product);
      p.stockQuantity = (p.stockQuantity - cartItem.quantity).clamp(0, 999999);

      int needed = cartItem.quantity;
      for (var batch in p.batches) {
        if (needed <= 0) break;
        if (batch.quantityRemaining <= 0) continue;
        int deduct = batch.quantityRemaining >= needed ? needed : batch.quantityRemaining;
        batch.quantityRemaining -= deduct;
        needed -= deduct;
      }
    }
    _notifyProductsChanged();

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
      discountUsd: discountUsd,
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
    if (_isOnline) {
      try {
        final res = await http
            .get(Uri.parse('$_baseUrl/orders?limit=100'))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final rawData = body['data'];
          final List? list = rawData is Map<String, dynamic>
              ? rawData['data'] as List?
              : (rawData is List ? rawData : null);
          if (list != null) {
            final fetched = list
                .whereType<Map<String, dynamic>>()
                .map(OrderModel.fromJson)
                .toList();
            _orders
              ..clear()
              ..addAll(fetched);
          }
        }
      } catch (e) {
        debugPrint('getOrders online fetch failed: $e');
      }
    }
    return _orders;
  }

  Future<bool> voidOrder(OrderModel order) async {
    if (order.isVoided) return false;

    if (_isOnline) {
      try {
        final res = await http.post(
          Uri.parse('$_baseUrl/orders/${order.id}/void'),
          headers: const {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          order.status = 'voided';
          await getProducts();
          return true;
        }
      } catch (e) {
        debugPrint('voidOrder online request failed: $e');
      }
    }

    // Local fallback: mark voided & restore stock
    order.status = 'voided';
    for (final item in order.items) {
      try {
        final prod = _products.firstWhere((p) => p.id == item.productId);
        prod.stockQuantity += item.quantity;
      } catch (_) {}
    }
    if (_currentShift != null && _currentShift!.isOpen) {
      _currentShift!.totalSalesUsd =
          (_currentShift!.totalSalesUsd - order.totalUsd).clamp(0.0, 999999999.0);
      _currentShift!.totalSalesKhr =
          (_currentShift!.totalSalesKhr - order.totalKhr).clamp(0.0, 999999999.0);
      if (_currentShift!.totalOrdersCount > 0) {
        _currentShift!.totalOrdersCount -= 1;
      }
    }
    _notifyProductsChanged();
    return true;
  }
}
