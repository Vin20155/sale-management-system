class CategoryModel {
  final int id;
  final String nameEn;
  final String nameKh;
  final String code;
  final String icon;
  final String colorHex;
  final String? description;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameKh,
    required this.code,
    this.icon = 'category',
    this.colorHex = '#0F766E',
    this.description,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nameEn: json['name_en'] ?? '',
      nameKh: json['name_kh'] ?? '',
      code: json['code'] ?? '',
      icon: json['icon'] ?? 'category',
      colorHex: json['color_hex'] ?? '#0F766E',
      description: json['description'],
      productCount: json['products_count'] ?? json['product_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_en': nameEn,
    'name_kh': nameKh,
    'code': code,
    'icon': icon,
    'color_hex': colorHex,
    'description': description,
  };
}

class ProductModel {
  final int id;
  final String barcode;
  final String nameEn;
  final String nameKh;
  final int categoryId;
  final String? categoryName;
  final String unit;
  final double costPriceUsd;
  final double costPriceKhr;
  final double sellingPriceUsd;
  final double sellingPriceKhr;
  int stockQuantity;
  final int reorderLevel;
  final String? expiryDate;
  final String? imageUrl;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.barcode,
    required this.nameEn,
    required this.nameKh,
    required this.categoryId,
    this.categoryName,
    this.unit = 'កំប៉ុង',
    this.costPriceUsd = 0.0,
    this.costPriceKhr = 0.0,
    required this.sellingPriceUsd,
    required this.sellingPriceKhr,
    required this.stockQuantity,
    this.reorderLevel = 10,
    this.expiryDate,
    this.imageUrl,
    this.isActive = true,
  });

  bool get isLowStock => stockQuantity <= reorderLevel;

  bool get isExpiringSoon {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final diff = expiry.difference(DateTime.now()).inDays;
      return diff <= 60 && diff >= 0;
    } catch (_) {
      return false;
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      barcode: json['barcode'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameKh: json['name_kh'] ?? '',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString()) ?? 1,
      categoryName: json['category'] != null ? (json['category']['name_kh'] ?? json['category']['name_en']) : null,
      unit: json['unit'] ?? 'កំប៉ុង',
      costPriceUsd: (json['cost_price_usd'] ?? 0).toDouble(),
      costPriceKhr: (json['cost_price_khr'] ?? 0).toDouble(),
      sellingPriceUsd: (json['selling_price_usd'] ?? 0).toDouble(),
      sellingPriceKhr: (json['selling_price_khr'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] is int ? json['stock_quantity'] : int.tryParse(json['stock_quantity'].toString()) ?? 0,
      reorderLevel: json['reorder_level'] is int ? json['reorder_level'] : 10,
      expiryDate: json['expiry_date'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'name_en': nameEn,
    'name_kh': nameKh,
    'category_id': categoryId,
    'unit': unit,
    'cost_price_usd': costPriceUsd,
    'cost_price_khr': costPriceKhr,
    'selling_price_usd': sellingPriceUsd,
    'selling_price_khr': sellingPriceKhr,
    'stock_quantity': stockQuantity,
    'reorder_level': reorderLevel,
    'expiry_date': expiryDate,
    'image_url': imageUrl,
  };
}

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  double get subtotalUsd => product.sellingPriceUsd * quantity;
  double get subtotalKhr => product.sellingPriceKhr * quantity;
}

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
    List<OrderItemModel> itemsList = rawItems.map((e) => OrderItemModel.fromJson(e)).toList();

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
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
      cashierName: json['cashier'] != null ? json['cashier']['name_kh'] ?? json['cashier']['name'] : 'បេឡាករ',
      customerName: json['customer'] != null ? json['customer']['name'] : null,
      items: itemsList,
    );
  }
}

class CustomerModel {
  final int id;
  final String name;
  final String phone;
  final int points;
  final double totalSpentUsd;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.points = 0,
    this.totalSpentUsd = 0.0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      points: json['points'] ?? 0,
      totalSpentUsd: (json['total_spent_usd'] ?? 0).toDouble(),
    );
  }
}

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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      cashierId: json['cashier_id'] ?? 1,
      openingCashUsd: (json['opening_cash_usd'] ?? 0).toDouble(),
      openingCashKhr: (json['opening_cash_khr'] ?? 0).toDouble(),
      closingCashUsd: json['closing_cash_usd'] != null ? (json['closing_cash_usd']).toDouble() : null,
      closingCashKhr: json['closing_cash_khr'] != null ? (json['closing_cash_khr']).toDouble() : null,
      totalSalesUsd: (json['total_sales_usd'] ?? 0).toDouble(),
      totalSalesKhr: (json['total_sales_khr'] ?? 0).toDouble(),
      totalOrdersCount: json['total_orders_count'] ?? 0,
      status: json['status'] ?? 'open',
      openedAt: json['opened_at'] ?? '',
      closedAt: json['closed_at'],
    );
  }
}

class MartSettingModel {
  String martNameEn;
  String martNameKh;
  String branchName;
  String phone;
  String addressKh;
  double exchangeRate;
  double taxPercentage;
  String bakongAccountId;
  String bakongMerchantName;
  String receiptFooterKh;
  String language;

  MartSettingModel({
    this.martNameEn = 'Lucky Express Mart',
    this.martNameKh = 'ឡាក់គី អិចប្រេស ម៉ាត',
    this.branchName = 'សាខាទួលគោក, ភ្នំពេញ',
    this.phone = '012 345 678',
    this.addressKh = 'ផ្ទះលេខ 45A, ផ្លូវ 315, ទួលគោក, ភ្នំពេញ',
    this.exchangeRate = 4100.0,
    this.taxPercentage = 0.0,
    this.bakongAccountId = 'lucky_express@aclb',
    this.bakongMerchantName = 'LUCKY EXPRESS MART',
    this.receiptFooterKh = 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
    this.language = 'km',
  });

  factory MartSettingModel.fromJson(Map<String, dynamic> json) {
    return MartSettingModel(
      martNameEn: json['mart_name_en'] ?? 'Lucky Express Mart',
      martNameKh: json['mart_name_kh'] ?? 'ឡាក់គី អិចប្រេស ម៉ាត',
      branchName: json['branch_name'] ?? 'សាខាទួលគោក, ភ្នំពេញ',
      phone: json['phone'] ?? '012 345 678',
      addressKh: json['address_kh'] ?? 'រាជធានីភ្នំពេញ',
      exchangeRate: (json['exchange_rate'] ?? 4100.0).toDouble(),
      taxPercentage: (json['tax_percentage'] ?? 0.0).toDouble(),
      bakongAccountId: json['bakong_account_id'] ?? 'lucky_express@aclb',
      bakongMerchantName: json['bakong_merchant_name'] ?? 'LUCKY EXPRESS MART',
      receiptFooterKh: json['receipt_footer_kh'] ?? 'សូមអរគុណ! សូមអញ្ជើញមកម្តងទៀត',
      language: json['language'] ?? 'km',
    );
  }

  Map<String, dynamic> toJson() => {
    'mart_name_en': martNameEn,
    'mart_name_kh': martNameKh,
    'branch_name': branchName,
    'phone': phone,
    'address_kh': addressKh,
    'exchange_rate': exchangeRate,
    'tax_percentage': taxPercentage,
    'bakong_account_id': bakongAccountId,
    'bakong_merchant_name': bakongMerchantName,
    'receipt_footer_kh': receiptFooterKh,
    'language': language,
  };
}

class UserModel {
  final int id;
  String name;
  String email;
  String role; // 'admin', 'stock_controller', 'cashier'
  String phone;
  bool isActive;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.isActive = true,
    this.createdAt = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'cashier',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] == null ? true : (json['is_active'] == 1 || json['is_active'] == true),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
  };
}
