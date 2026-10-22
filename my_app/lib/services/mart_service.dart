import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/mart_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MartService {
  static final MartService _instance = MartService._internal();
  factory MartService() => _instance;
  MartService._internal() {
    _initLocalData();
  }

  // Base API URL (supports Flutter Web localhost and Android Emulator 10.0.2.2)
  String _baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
  bool _isOnline = false;

  String get baseUrl => _baseUrl;
  bool get isOnline => _isOnline;

  // Local fallback storage
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<OrderModel> _orders = [];
  List<CustomerModel> _customers = [];
  List<UserModel> _users = [];
  ShiftModel? _currentShift;
  MartSettingModel _settings = MartSettingModel();

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<OrderModel> get orders => _orders;
  List<CustomerModel> get customers => _customers;
  List<UserModel> get users => _users;

  // Exchange rate
  double get exchangeRate => _settings.exchangeRate;

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final savedLang = sp.getString('APP_LANGUAGE');
      if (savedLang != null && savedLang.isNotEmpty) {
        _settings.language = savedLang;
      }
      final savedUrl = sp.getString('MART_API_URL');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
      } else {
        _baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
      }
    } catch (_) {}
    await testConnection();
    if (_isOnline) {
      await getCategories();
      await getProducts();
    }
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('MART_API_URL', url);
    await testConnection();
    if (_isOnline) {
      await getCategories();
      await getProducts();
    }
  }

  Future<bool> testConnection() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/categories')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _isOnline = true;
        return true;
      }
    } catch (e) {
      debugPrint('MartService testConnection failed: $e');
      _isOnline = false;
    }
    return _isOnline;
  }

  // ==========================================
  // CURRENCY HELPERS
  // ==========================================
  String formatUsd(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String formatKhr(double amount) {
    int val = amount.round();
    String str = val.toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formatted ៛';
  }

  double usdToKhr(double usd) => usd * _settings.exchangeRate;
  double khrToUsd(double khr) => khr / _settings.exchangeRate;

  // ==========================================
  // CATEGORIES
  // ==========================================
  Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final list = (json['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
          _categories = list;
          _isOnline = true;
          return list;
        }
      }
    } catch (e) {
      debugPrint('getCategories error: $e');
    }
    return _categories;
  }

  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(category.toJson()),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final newCat = CategoryModel.fromJson(json['data']);
          _categories.add(newCat);
          _isOnline = true;
          return newCat;
        }
      } else {
        debugPrint('addCategory server response ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('addCategory HTTP error: $e');
    }
    _categories.add(category);
    return category;
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/categories/${category.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(category.toJson()),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('updateCategory error: $e');
    }
    int idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _categories[idx] = category;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/categories/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('deleteCategory error: $e');
    }
    _categories.removeWhere((c) => c.id == id);
  }

  // ==========================================
  // PRODUCTS
  // ==========================================
  Future<List<ProductModel>> getProducts({int? categoryId, String? search}) async {
    try {
      String url = '$_baseUrl/products?';
      if (categoryId != null && categoryId > 0) url += 'category_id=$categoryId&';
      if (search != null && search.isNotEmpty) url += 'search=${Uri.encodeComponent(search)}&';

      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final list = (json['data'] as List).map((e) => ProductModel.fromJson(e)).toList();
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
      result = result.where((p) =>
        p.nameKh.toLowerCase().contains(s) ||
        p.nameEn.toLowerCase().contains(s) ||
        p.barcode.toLowerCase().contains(s)
      ).toList();
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

  Future<ProductModel> addProduct(ProductModel product) async {
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

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(productWithCat.toJson()),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final saved = ProductModel.fromJson(json['data']);
          _products.insert(0, saved);
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
    return productWithCat;
  }

  Future<void> updateProduct(ProductModel product) async {
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

    try {
      await http.put(
        Uri.parse('$_baseUrl/products/${product.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(productWithCat.toJson()),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('updateProduct error: $e');
    }

    int idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = productWithCat;
    }
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
      double totalPaidUsd = receivedUsd + (receivedKhr / _settings.exchangeRate);
      double changeEquivalentUsd = (totalPaidUsd - totalUsd) > 0 ? (totalPaidUsd - totalUsd) : 0.0;
      changeUsd = changeEquivalentUsd.floorToDouble();
      changeKhr = ((changeEquivalentUsd - changeUsd) * _settings.exchangeRate).roundToDouble();
    }

    // Deduct stock
    for (var cartItem in items) {
      final p = _products.firstWhere((prod) => prod.id == cartItem.product.id, orElse: () => cartItem.product);
      p.stockQuantity = (p.stockQuantity - cartItem.quantity).clamp(0, 999999);
    }

    // Invoice No
    String dateStr = DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String invoiceNo = 'INV-$dateStr-${(_orders.length + 1).toString().padLeft(4, '0')}';

    List<OrderItemModel> orderItems = items.map((ci) => OrderItemModel(
      productId: ci.product.id,
      productName: ci.product.nameKh,
      barcode: ci.product.barcode,
      unitPriceUsd: ci.product.sellingPriceUsd,
      unitPriceKhr: ci.product.sellingPriceKhr,
      quantity: ci.quantity,
      subtotalUsd: ci.subtotalUsd,
      subtotalKhr: ci.subtotalKhr,
    )).toList();

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
      customerName: customerName ?? (customerPhone != null ? 'អតិថិជន ($customerPhone)' : null),
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

  // ==========================================
  // SHIFTS & CASH DRAWER
  // ==========================================
  ShiftModel? getCurrentShift() => _currentShift;

  Future<ShiftModel> openShift(double openingUsd, double openingKhr) async {
    final shift = ShiftModel(
      id: DateTime.now().millisecondsSinceEpoch,
      cashierId: 1,
      openingCashUsd: openingUsd,
      openingCashKhr: openingKhr,
      status: 'open',
      openedAt: DateTime.now().toString().substring(0, 16),
    );
    _currentShift = shift;
    return shift;
  }

  Future<ShiftModel> closeShift(double closingUsd, double closingKhr) async {
    if (_currentShift != null) {
      _currentShift!.closingCashUsd = closingUsd;
      _currentShift!.closingCashKhr = closingKhr;
      _currentShift!.status = 'closed';
      _currentShift!.closedAt = DateTime.now().toString().substring(0, 16);
    }
    final s = _currentShift!;
    _currentShift = null;
    return s;
  }

  // ==========================================
  // CUSTOMERS
  // ==========================================
  Future<List<CustomerModel>> getCustomers() async => _customers;

  CustomerModel? findCustomerByPhone(String phone) {
    try {
      return _customers.firstWhere((c) => c.phone == phone);
    } catch (_) {
      return null;
    }
  }

  Future<CustomerModel> addCustomer(String name, String phone) async {
    final c = CustomerModel(
      id: _customers.length + 1,
      name: name,
      phone: phone,
      points: 10,
    );
    _customers.add(c);
    return c;
  }

  // ==========================================
  // SETTINGS
  // ==========================================
  MartSettingModel getSettings() => _settings;

  Future<void> updateSettings(MartSettingModel settings) async {
    _settings = settings;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('APP_LANGUAGE', settings.language);
      await sp.setString('MART_NAME_KH', settings.martNameKh);
      await sp.setString('MART_NAME_EN', settings.martNameEn);
      await sp.setString('MART_BRANCH', settings.branchName);
      await sp.setString('BAKONG_ACCOUNT', settings.bakongAccountId);
      await sp.setDouble('EXCHANGE_RATE', settings.exchangeRate);
    } catch (_) {}
  }

  // ==========================================
  // REPORTS
  // ==========================================
  Map<String, dynamic> getTodayReport() {
    double totalUsd = _orders.fold(0.0, (sum, o) => sum + o.totalUsd);
    double totalKhr = _orders.fold(0.0, (sum, o) => sum + o.totalKhr);
    int ordersCount = _orders.length;

    return {
      'total_sales_usd': totalUsd,
      'total_sales_khr': totalKhr,
      'total_orders': ordersCount,
      'low_stock_count': getLowStockProducts().length,
      'expiring_count': getExpiringProducts().length,
    };
  }

  // ==========================================
  // USERS MANAGEMENT (ADMIN ONLY)
  // ==========================================
  List<UserModel> getUsers({String? search, String? roleFilter}) {
    List<UserModel> list = List.from(_users);
    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
      list = list.where((u) => u.role == roleFilter).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Future<bool> addUser({
    required String name,
    required String email,
    required String role,
    required String phone,
    String password = '',
  }) async {
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return false;
    }
    final int nextId = _users.isEmpty ? 1 : (_users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1);
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    _users.insert(0, UserModel(
      id: nextId,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: role,
      phone: phone.trim(),
      isActive: true,
      createdAt: dateStr,
    ));
    return true;
  }

  Future<bool> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    required String phone,
    required bool isActive,
  }) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return false;
    
    if (_users.any((u) => u.id != id && u.email.toLowerCase() == email.trim().toLowerCase())) {
      return false;
    }

    _users[idx].name = name.trim();
    _users[idx].email = email.trim().toLowerCase();
    _users[idx].role = role;
    _users[idx].phone = phone.trim();
    _users[idx].isActive = isActive;
    return true;
  }

  Future<bool> deleteUser(int id) async {
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return false;
    _users.removeAt(idx);
    return true;
  }

  // ==========================================
  // INITIAL SAMPLE DATA (REALISTIC CAMBODIAN MART)
  // ==========================================
  void _initLocalData() {
    _users = [
      UserModel(
        id: 1,
        name: 'Ngam Vin (Admin)',
        email: 'admin@gmail.com',
        role: 'admin',
        phone: '012 345 678',
        isActive: true,
        createdAt: '2026-01-01',
      ),
      UserModel(
        id: 2,
        name: 'Vin (Stock Controller)',
        email: 'stock@gmail.com',
        role: 'stock_controller',
        phone: '098 765 432',
        isActive: true,
        createdAt: '2026-01-15',
      ),
      UserModel(
        id: 3,
        name: 'តារា ចាន់ (Cashier)',
        email: 'cashier@gmail.com',
        role: 'cashier',
        phone: '077 888 999',
        isActive: true,
        createdAt: '2026-02-01',
      ),
      UserModel(
        id: 4,
        name: 'សុខ គន្ធា (Sok Kunthea)',
        email: 'cashier2@gmail.com',
        role: 'cashier',
        phone: '088 123 456',
        isActive: true,
        createdAt: '2026-02-20',
      ),
    ];
    _categories = [
      CategoryModel(id: 1, nameEn: 'Beverages', nameKh: 'ភេសជ្ជៈ & ទឹក', code: 'BEV', icon: 'local_drink', colorHex: '#0284C7', productCount: 4),
      CategoryModel(id: 2, nameEn: 'Snacks & Chips', nameKh: 'នំចំណី & ស្ករគ្រាប់', code: 'SNK', icon: 'fastfood', colorHex: '#F59E0B', productCount: 2),
      CategoryModel(id: 3, nameEn: 'Dairy & Ice Cream', nameKh: 'ទឹកដោះគោ & ការ៉េម', code: 'DRY', icon: 'icecream', colorHex: '#10B981', productCount: 1),
      CategoryModel(id: 4, nameEn: 'Instant Food', nameKh: 'អាហារកំប៉ុង & មីកញ្ចប់', code: 'CND', icon: 'lunch_dining', colorHex: '#EF4444', productCount: 2),
      CategoryModel(id: 5, nameEn: 'Bakery', nameKh: 'នំប៉័ង & អាហារស្រស់', code: 'BKR', icon: 'bakery_dining', colorHex: '#8B5CF6', productCount: 1),
      CategoryModel(id: 6, nameEn: 'Personal Care', nameKh: 'សម្ភារៈថែរក្សាខ្លួន', code: 'PRS', icon: 'clean_hands', colorHex: '#EC4899', productCount: 1),
      CategoryModel(id: 7, nameEn: 'Household', nameKh: 'របស់របរប្រើប្រាស់', code: 'HSH', icon: 'home', colorHex: '#64748B', productCount: 1),
    ];

    _products = [
      ProductModel(
        id: 1,
        barcode: '8850124001111',
        nameEn: 'Vital Mineral Water 500ml',
        nameKh: 'ទឹកបរិសុទ្ធ វីតាល់ 500ml',
        categoryId: 1,
        categoryName: 'ភេសជ្ជៈ & ទឹក',
        unit: 'ដប',
        costPriceUsd: 0.20,
        costPriceKhr: 820.0,
        sellingPriceUsd: 0.35,
        sellingPriceKhr: 1400.0,
        stockQuantity: 120,
        reorderLevel: 20,
        expiryDate: '2027-05-15',
      ),
      ProductModel(
        id: 2,
        barcode: '8850124002222',
        nameEn: 'Angkor Beer Can 330ml',
        nameKh: 'ស្រាបៀរ អង្គរ កំប៉ុង 330ml',
        categoryId: 1,
        categoryName: 'ភេសជ្ជៈ & ទឹក',
        unit: 'កំប៉ុង',
        costPriceUsd: 0.55,
        costPriceKhr: 2250.0,
        sellingPriceUsd: 0.75,
        sellingPriceKhr: 3100.0,
        stockQuantity: 8, // Low stock demo!
        reorderLevel: 24,
        expiryDate: '2026-12-30',
      ),
      ProductModel(
        id: 3,
        barcode: '8850124003333',
        nameEn: 'Carabao Energy Drink 250ml',
        nameKh: 'ភេសជ្ជៈ ខារ៉ាបាវ 250ml',
        categoryId: 1,
        categoryName: 'ភេសជ្ជៈ & ទឹក',
        unit: 'កំប៉ុង',
        costPriceUsd: 0.40,
        costPriceKhr: 1640.0,
        sellingPriceUsd: 0.60,
        sellingPriceKhr: 2500.0,
        stockQuantity: 65,
        reorderLevel: 15,
        expiryDate: '2027-01-20',
      ),
      ProductModel(
        id: 4,
        barcode: '8850124004444',
        nameEn: 'Sting Strawberry 330ml',
        nameKh: 'ស្ទីង រសជាតិស្ត្របឺរី 330ml',
        categoryId: 1,
        categoryName: 'ភេសជ្ជៈ & ទឹក',
        unit: 'ដប',
        costPriceUsd: 0.45,
        costPriceKhr: 1845.0,
        sellingPriceUsd: 0.65,
        sellingPriceKhr: 2700.0,
        stockQuantity: 90,
        reorderLevel: 20,
        expiryDate: '2026-11-10',
      ),
      ProductModel(
        id: 5,
        barcode: '8850124005555',
        nameEn: 'Lays Potato Chips Classic 50g',
        nameKh: 'ដំឡូងបារាំងបំពង Lays 50g',
        categoryId: 2,
        categoryName: 'នំចំណី & ស្ករគ្រាប់',
        unit: 'កញ្ចប់',
        costPriceUsd: 0.70,
        costPriceKhr: 2870.0,
        sellingPriceUsd: 1.00,
        sellingPriceKhr: 4100.0,
        stockQuantity: 42,
        reorderLevel: 10,
        expiryDate: '2026-08-30',
      ),
      ProductModel(
        id: 6,
        barcode: '8850124006666',
        nameEn: 'Kirirom Dried Mango 100g',
        nameKh: 'ដំណាប់ស្វាយ គិរីរម្យ 100g',
        categoryId: 2,
        categoryName: 'នំចំណី & ស្ករគ្រាប់',
        unit: 'កញ្ចប់',
        costPriceUsd: 1.20,
        costPriceKhr: 4920.0,
        sellingPriceUsd: 1.75,
        sellingPriceKhr: 7200.0,
        stockQuantity: 30,
        reorderLevel: 10,
        expiryDate: '2026-10-15',
      ),
      ProductModel(
        id: 7,
        barcode: '8850124007777',
        nameEn: 'Dutch Mill Fresh Milk 180ml',
        nameKh: 'ទឹកដោះគោស្រស់ Dutch Mill',
        categoryId: 3,
        categoryName: 'ទឹកដោះគោ & ការ៉េម',
        unit: 'ប្រអប់',
        costPriceUsd: 0.40,
        costPriceKhr: 1640.0,
        sellingPriceUsd: 0.60,
        sellingPriceKhr: 2500.0,
        stockQuantity: 4, // Low stock demo!
        reorderLevel: 12,
        expiryDate: '2026-05-15', // Expiring demo!
      ),
      ProductModel(
        id: 8,
        barcode: '8850124008888',
        nameEn: 'Mama Instant Noodle Pork 60g',
        nameKh: 'មីម៉ាម៉ា រសជាតិសាច់ជ្រូក',
        categoryId: 4,
        categoryName: 'អាហារកំប៉ុង & មីកញ្ចប់',
        unit: 'កញ្ចប់',
        costPriceUsd: 0.22,
        costPriceKhr: 900.0,
        sellingPriceUsd: 0.35,
        sellingPriceKhr: 1400.0,
        stockQuantity: 180,
        reorderLevel: 30,
        expiryDate: '2027-03-01',
      ),
      ProductModel(
        id: 9,
        barcode: '8850124009999',
        nameEn: 'Three Lady Canned Sardines',
        nameKh: 'ត្រីខកំប៉ុង ស្រីបីនាក់ 155g',
        categoryId: 4,
        categoryName: 'អាហារកំប៉ុង & មីកញ្ចប់',
        unit: 'កំប៉ុង',
        costPriceUsd: 0.75,
        costPriceKhr: 3075.0,
        sellingPriceUsd: 1.10,
        sellingPriceKhr: 4500.0,
        stockQuantity: 60,
        reorderLevel: 15,
        expiryDate: '2027-09-10',
      ),
      ProductModel(
        id: 10,
        barcode: '8850124010101',
        nameEn: 'Sandwich Bread Special',
        nameKh: 'នំប៉័ងសាំងវិចទន់ ពិសេស',
        categoryId: 5,
        categoryName: 'នំប៉័ង & អាហារស្រស់',
        unit: 'កញ្ចប់',
        costPriceUsd: 1.00,
        costPriceKhr: 4100.0,
        sellingPriceUsd: 1.50,
        sellingPriceKhr: 6150.0,
        stockQuantity: 15,
        reorderLevel: 5,
        expiryDate: '2026-05-02', // Expiring very soon!
      ),
      ProductModel(
        id: 11,
        barcode: '8850124011112',
        nameEn: 'Colgate Total Toothpaste 150g',
        nameKh: 'ថ្នាំដុសធ្មេញ កូលហ្គេត 150g',
        categoryId: 6,
        categoryName: 'សម្ភារៈថែរក្សាខ្លួន',
        unit: 'ប្រអប់',
        costPriceUsd: 1.30,
        costPriceKhr: 5330.0,
        sellingPriceUsd: 1.85,
        sellingPriceKhr: 7600.0,
        stockQuantity: 25,
        reorderLevel: 8,
        expiryDate: '2028-01-01',
      ),
      ProductModel(
        id: 12,
        barcode: '8850124012123',
        nameEn: 'Sunlight Dishwashing 750ml',
        nameKh: 'ទឹកលាងចាន សាន់ឡាយ 750ml',
        categoryId: 7,
        categoryName: 'របស់របរប្រើប្រាស់',
        unit: 'ដប',
        costPriceUsd: 1.10,
        costPriceKhr: 4510.0,
        sellingPriceUsd: 1.60,
        sellingPriceKhr: 6500.0,
        stockQuantity: 32,
        reorderLevel: 10,
        expiryDate: '2028-06-01',
      ),
    ];

    _customers = [
      CustomerModel(id: 1, name: 'ជា វិជ្ជា (Chea Vichea)', phone: '012987654', points: 125, totalSpentUsd: 125.0),
      CustomerModel(id: 2, name: 'កែវ ស្រីរ័ត្ន (Sreyroth Keo)', phone: '098456123', points: 68, totalSpentUsd: 68.5),
      CustomerModel(id: 3, name: 'ហេង បូរ៉ា (Bora Heng)', phone: '088776655', points: 210, totalSpentUsd: 210.0),
    ];

    // Seed initial orders
    _orders = [
      OrderModel(
        id: 1,
        invoiceNo: 'INV-20261020-0001',
        subtotalUsd: 4.85,
        totalUsd: 4.85,
        totalKhr: 19900.0,
        exchangeRate: 4100.0,
        paymentMethod: 'khqr_bakong',
        receivedUsd: 4.85,
        receivedKhr: 19900.0,
        changeUsd: 0.0,
        changeKhr: 0.0,
        pointsEarned: 4,
        createdAt: '2026-10-20 10:15:22',
        cashierName: 'តារា ចាន់ (Cashier)',
        customerName: 'ជា វិជ្ជា',
        items: [
          OrderItemModel(productId: 1, productName: 'ទឹកបរិសុទ្ធ វីតាល់ 500ml', unitPriceUsd: 0.35, unitPriceKhr: 1400.0, quantity: 2, subtotalUsd: 0.70, subtotalKhr: 2800.0),
          OrderItemModel(productId: 2, productName: 'ស្រាបៀរ អង្គរ កំប៉ុង 330ml', unitPriceUsd: 0.75, unitPriceKhr: 3100.0, quantity: 3, subtotalUsd: 2.25, subtotalKhr: 9300.0),
          OrderItemModel(productId: 5, productName: 'ដំឡូងបារាំងបំពង Lays 50g', unitPriceUsd: 1.00, unitPriceKhr: 4100.0, quantity: 1, subtotalUsd: 1.00, subtotalKhr: 4100.0),
          OrderItemModel(productId: 8, productName: 'មីម៉ាម៉ា រសជាតិសាច់ជ្រូក', unitPriceUsd: 0.35, unitPriceKhr: 1400.0, quantity: 2, subtotalUsd: 0.70, subtotalKhr: 2800.0),
        ],
      )
    ];

    // Initial shift
    _currentShift = ShiftModel(
      id: 101,
      cashierId: 1,
      openingCashUsd: 50.0,
      openingCashKhr: 200000.0,
      totalSalesUsd: 4.85,
      totalSalesKhr: 19900.0,
      totalOrdersCount: 1,
      status: 'open',
      openedAt: '2026-10-20 08:00',
    );
  }
}
