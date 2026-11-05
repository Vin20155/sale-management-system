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
              p.barcode.toLowerCase().contains(s))
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
      imageUrl: product.imageUrl,
      isActive: product.isActive,
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
      imageUrl: product.imageUrl,
      isActive: product.isActive,
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
}
