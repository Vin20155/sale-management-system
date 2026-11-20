part of 'mart_service.dart';

extension ProductService on MartService {
  // ==========================================
  // PRODUCTS
  // ==========================================
  Future<List<ProductModel>> getProducts(
      {int? categoryId, String? search}) async {
    try {
      String url = '$_baseUrl/products?';
      if (categoryId != null && categoryId > 0) {
        url += 'category_id=$categoryId&';
      }
      if (search != null && search.isNotEmpty) {
        url += 'search=${Uri.encodeComponent(search)}&';
      }

      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final list = (json['data'] as List)
              .map((e) => ProductModel.fromJson(e))
              .toList();
          _products = list;
          _isOnline = true;
          return list;
        }
      }
    } catch (e) {
      debugPrint('getProducts error: $e');
    }

    // Local filter fallback
    var result = _products.where((p) => p.isActive).toList();
    if (categoryId != null && categoryId > 0) {
      result = result.where((p) => p.categoryId == categoryId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      result = result
          .where((p) =>
              p.nameKh.toLowerCase().contains(s) ||
              p.nameEn.toLowerCase().contains(s) ||
              p.barcode.toLowerCase().contains(s) ||
              p.itemCode.toLowerCase().contains(s))
          .toList();
    }
    return result;
  }

  ProductModel? findProductByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode && p.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<ProductModel> addProduct(
    ProductModel product, {
    XFile? image,
  }) async {
    // Lookup category name
    String catName = '';
    try {
      final cat = _categories.firstWhere((c) => c.id == product.categoryId);
      catName = cat.nameKh;
    } catch (_) {}

    final productWithCat = ProductModel(
      id: product.id,
      barcode: product.barcode,
      itemCode: product.itemCode,
      nameEn: product.nameEn,
      nameKh: product.nameKh,
      categoryId: product.categoryId,
      categoryName: catName.isNotEmpty ? catName : product.categoryName,
      unit: product.unit,
      costPriceUsd: product.costPriceUsd,
      costPriceKhr: product.costPriceKhr,
      sellingPriceUsd: product.sellingPriceUsd,
      sellingPriceKhr: product.sellingPriceKhr,
      stockQuantity: product.stockQuantity,
      reorderLevel: product.reorderLevel,
      expiryDate: product.expiryDate,
      receivedDate: product.receivedDate,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      batches: product.batches,
    );

    if (image != null) {
      final saved = await _sendProductImageRequest(
        productWithCat,
        image: image,
      );
      _products.insert(0, saved);
      _notifyProductsChanged();
      _isOnline = true;
      return saved;
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/products'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(productWithCat.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final saved = ProductModel.fromJson(json['data']);
          _products.insert(0, saved);
          _notifyProductsChanged();
          _isOnline = true;
          return saved;
        }
      } else {
        debugPrint('addProduct server response ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('addProduct HTTP error: $e');
    }

    _products.insert(0, productWithCat);
    _notifyProductsChanged();
    return productWithCat;
  }

  Future<void> updateProduct(
    ProductModel product, {
    XFile? image,
    bool removeImage = false,
  }) async {
    // Lookup category name
    String catName = '';
    try {
      final cat = _categories.firstWhere((c) => c.id == product.categoryId);
      catName = cat.nameKh;
    } catch (_) {}

    final productWithCat = ProductModel(
      id: product.id,
      barcode: product.barcode,
      itemCode: product.itemCode,
      nameEn: product.nameEn,
      nameKh: product.nameKh,
      categoryId: product.categoryId,
      categoryName: catName.isNotEmpty ? catName : product.categoryName,
      unit: product.unit,
      costPriceUsd: product.costPriceUsd,
      costPriceKhr: product.costPriceKhr,
      sellingPriceUsd: product.sellingPriceUsd,
      sellingPriceKhr: product.sellingPriceKhr,
      stockQuantity: product.stockQuantity,
      reorderLevel: product.reorderLevel,
      expiryDate: product.expiryDate,
      receivedDate: product.receivedDate,
      imageUrl: product.imageUrl,
      isActive: product.isActive,
      batches: product.batches,
    );

    if (image != null || removeImage) {
      final saved = await _sendProductImageRequest(
        productWithCat,
        image: image,
        update: true,
        removeImage: removeImage,
      );
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = saved;
      } else {
        _products.insert(0, saved);
      }
      _notifyProductsChanged();
      _isOnline = true;
      return;
    }

    try {
      await http
          .put(
            Uri.parse('$_baseUrl/products/${product.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(productWithCat.toJson()),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('updateProduct error: $e');
    }

    int idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = productWithCat;
    }
    _notifyProductsChanged();
  }

  Future<ProductModel> _sendProductImageRequest(
    ProductModel product, {
    XFile? image,
    bool update = false,
    bool removeImage = false,
  }) async {
    final uri = Uri.parse(
      update ? '$_baseUrl/products/${product.id}' : '$_baseUrl/products',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json';
    if (update) {
      request.fields['_method'] = 'PUT';
    }
    if (removeImage) {
      request.fields['remove_image'] = '1';
    }

    product.toJson().forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );
    final response = await http.Response.fromStream(streamedResponse);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw StateError(
        'The server returned an invalid response while saving the product image.',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      final errors = body['errors'];
      final details = errors is Map
          ? errors.values
              .map((error) =>
                  error is List ? error.join(', ') : error.toString())
              .join('; ')
          : null;
      final message = body['message']?.toString();
      throw StateError(
        details != null && details.isNotEmpty
            ? details
            : message == null || message.isEmpty
                ? 'Product image upload failed (HTTP ${response.statusCode}).'
                : message,
      );
    }

    return ProductModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/products/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('deleteProduct error: $e');
    }
    _products.removeWhere((p) => p.id == id);
  }

  List<ProductModel> getLowStockProducts() {
    return _products.where((p) => p.isLowStock && p.isActive).toList();
  }

  List<ProductModel> getExpiringProducts() {
    return _products.where((p) => p.isExpiringSoon && p.isActive).toList();
  }

  // ==========================================
  // PRODUCT BATCHES / STOCK IN
  // ==========================================
  Future<List<ProductBatchModel>> getProductBatches(int productId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/products/$productId/batches'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return (json['data'] as List)
              .map((b) => ProductBatchModel.fromJson(b))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('getProductBatches error: $e');
    }

    final p = _products.firstWhere((prod) => prod.id == productId,
        orElse: () => _products.first);
    return p.batches;
  }

  Future<bool> addStockBatch({
    required int productId,
    required int quantity,
    required String receivedDate,
    String? expiryDate,
    String? batchNo,
    double? costPriceUsd,
    String? supplierName,
    String? note,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/products/$productId/batches'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'quantity': quantity,
              'received_date': receivedDate,
              'expiry_date': expiryDate,
              'batch_no': batchNo,
              'cost_price_usd': costPriceUsd,
              'supplier_name': supplierName,
              'note': note,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          // Update product in local memory
          if (json['data'] != null && json['data']['product'] != null) {
            final updated = ProductModel.fromJson(json['data']['product']);
            final idx = _products.indexWhere((p) => p.id == productId);
            if (idx != -1) {
              _products[idx] = updated;
            }
            _notifyProductsChanged();
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint('addStockBatch HTTP error: $e');
    }

    // Offline fallback: Update product stock and local batches list
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final p = _products[idx];
      final newBatch = ProductBatchModel(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: productId,
        batchNo: batchNo ?? 'B-${DateTime.now().millisecondsSinceEpoch}',
        receivedDate: receivedDate,
        expiryDate: expiryDate,
        quantityReceived: quantity,
        quantityRemaining: quantity,
        costPriceUsd: costPriceUsd ?? p.costPriceUsd,
        costPriceKhr: (costPriceUsd ?? p.costPriceUsd) * exchangeRate,
        supplierName: supplierName,
        note: note,
      );

      final updatedBatches = List<ProductBatchModel>.from(p.batches)
        ..add(newBatch);
      // Sort FEFO
      updatedBatches.sort((a, b) {
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });

      // Update nearest expiry date
      final nearest = updatedBatches.firstWhere(
        (b) => b.quantityRemaining > 0 && b.expiryDate != null,
        orElse: () => updatedBatches.first,
      );

      _products[idx] = ProductModel(
        id: p.id,
        barcode: p.barcode,
        itemCode: p.itemCode,
        nameEn: p.nameEn,
        nameKh: p.nameKh,
        categoryId: p.categoryId,
        categoryName: p.categoryName,
        unit: p.unit,
        costPriceUsd: costPriceUsd ?? p.costPriceUsd,
        costPriceKhr: (costPriceUsd ?? p.costPriceUsd) * exchangeRate,
        sellingPriceUsd: p.sellingPriceUsd,
        sellingPriceKhr: p.sellingPriceKhr,
        stockQuantity: p.stockQuantity + quantity,
        reorderLevel: p.reorderLevel,
        expiryDate: nearest.expiryDate ?? p.expiryDate,
        receivedDate: p.receivedDate,
        imageUrl: p.imageUrl,
        isActive: p.isActive,
        batches: updatedBatches,
      );
      _notifyProductsChanged();
      return true;
    }

    return false;
  }
}
