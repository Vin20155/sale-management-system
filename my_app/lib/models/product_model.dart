import 'product_batch_model.dart';

class ProductModel {
  final int id;
  final String barcode;
  final String itemCode;
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
  final String? receivedDate;
  final String? imageUrl;
  final bool isActive;
  final List<ProductBatchModel> batches;

  ProductModel({
    required this.id,
    required this.barcode,
    this.itemCode = '',
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
    this.receivedDate,
    this.imageUrl,
    this.isActive = true,
    this.batches = const [],
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

  String get formattedExpiryDate {
    if (expiryDate == null || expiryDate!.isEmpty) return '';
    try {
      final dt = DateTime.parse(expiryDate!);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      // If contains 'T', take the first part
      if (expiryDate!.contains('T')) {
        return expiryDate!.split('T').first;
      }
      return expiryDate!;
    }
  }

  String get formattedReceivedDate {
    if (receivedDate == null || receivedDate!.isEmpty) return '';
    try {
      final dt = DateTime.parse(receivedDate!);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      if (receivedDate!.contains('T')) {
        return receivedDate!.split('T').first;
      }
      return receivedDate!;
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      barcode: json['barcode'] ?? '',
      itemCode: json['item_code']?.toString() ?? '',
      nameEn: json['name_en'] ?? '',
      nameKh: json['name_kh'] ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id'].toString()) ?? 1,
      categoryName: json['category'] != null
          ? (json['category']['name_kh'] ?? json['category']['name_en'])
          : null,
      unit: json['unit'] ?? 'កំប៉ុង',
      costPriceUsd: (json['cost_price_usd'] ?? 0).toDouble(),
      costPriceKhr: (json['cost_price_khr'] ?? 0).toDouble(),
      sellingPriceUsd: (json['selling_price_usd'] ?? 0).toDouble(),
      sellingPriceKhr: (json['selling_price_khr'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] is int
          ? json['stock_quantity']
          : int.tryParse(json['stock_quantity'].toString()) ?? 0,
      reorderLevel: json['reorder_level'] is int ? json['reorder_level'] : 10,
      expiryDate: json['expiry_date'],
      receivedDate: json['received_date'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      batches: json['active_batches'] is List
          ? (json['active_batches'] as List)
              .map((b) => ProductBatchModel.fromJson(b))
              .toList()
          : (json['batches'] is List
              ? (json['batches'] as List)
                  .map((b) => ProductBatchModel.fromJson(b))
                  .toList()
              : const []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'item_code': itemCode,
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
        'received_date': receivedDate,
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
