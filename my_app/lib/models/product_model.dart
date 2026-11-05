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
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      barcode: json['barcode'] ?? '',
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
