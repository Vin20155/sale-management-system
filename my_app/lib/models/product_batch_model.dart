class ProductBatchModel {
  final int id;
  final int productId;
  final String batchNo;
  final String receivedDate;
  final String? expiryDate;
  final int quantityReceived;
  int quantityRemaining;
  final double costPriceUsd;
  final double costPriceKhr;
  final String? supplierName;
  final String? note;

  ProductBatchModel({
    required this.id,
    required this.productId,
    required this.batchNo,
    required this.receivedDate,
    this.expiryDate,
    required this.quantityReceived,
    required this.quantityRemaining,
    this.costPriceUsd = 0.0,
    this.costPriceKhr = 0.0,
    this.supplierName,
    this.note,
  });

  bool get isExpired {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiryDate!);
      return exp.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool get isExpiringSoon {
    if (expiryDate == null || expiryDate!.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiryDate!);
      final diff = exp.difference(DateTime.now()).inDays;
      return diff <= 60 && diff >= 0;
    } catch (_) {
      return false;
    }
  }

  int get daysUntilExpiry {
    if (expiryDate == null || expiryDate!.isEmpty) return 99999;
    try {
      final exp = DateTime.parse(expiryDate!);
      return exp.difference(DateTime.now()).inDays;
    } catch (_) {
      return 99999;
    }
  }

  factory ProductBatchModel.fromJson(Map<String, dynamic> json) {
    return ProductBatchModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString()) ?? 0,
      batchNo: json['batch_no']?.toString() ?? '',
      receivedDate: json['received_date']?.toString() ?? '',
      expiryDate: json['expiry_date']?.toString(),
      quantityReceived: json['quantity_received'] is int
          ? json['quantity_received']
          : int.tryParse(json['quantity_received'].toString()) ?? 0,
      quantityRemaining: json['quantity_remaining'] is int
          ? json['quantity_remaining']
          : int.tryParse(json['quantity_remaining'].toString()) ?? 0,
      costPriceUsd: (json['cost_price_usd'] ?? 0).toDouble(),
      costPriceKhr: (json['cost_price_khr'] ?? 0).toDouble(),
      supplierName: json['supplier_name']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'batch_no': batchNo,
      'received_date': receivedDate,
      'expiry_date': expiryDate,
      'quantity_received': quantityReceived,
      'quantity_remaining': quantityRemaining,
      'cost_price_usd': costPriceUsd,
      'cost_price_khr': costPriceKhr,
      'supplier_name': supplierName,
      'note': note,
    };
  }
}

