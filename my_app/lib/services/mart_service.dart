import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config/app_url.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'category_service.dart';
part 'product_service.dart';
part 'order_service.dart';
part 'shift_service.dart';
part 'customer_service.dart';
part 'settings_service.dart';
part 'report_service.dart';
part 'user_service.dart';

class MartService {
  static final MartService _instance = MartService._internal();
  factory MartService() => _instance;
  MartService._internal();

  static const String _apiBaseUrlKey = 'API_BASE_URL';
  static const String _authTokenKey = 'AUTH_TOKEN';

  String _baseUrl = '${AppUrl.baseUrl}api';
  bool _isOnline = false;

  String get baseUrl => _baseUrl;
  bool get isOnline => _isOnline;

  final ValueNotifier<int> productsRevision = ValueNotifier<int>(0);

  void _notifyProductsChanged() {
    productsRevision.value++;
  }

  // Local fallback storage
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  final List<OrderModel> _orders = [];
  final List<CustomerModel> _customers = [];
  List<UserModel> _users = [];
  ShiftModel? _currentShift;
  MartSettingModel _settings = MartSettingModel();

  List<ProductModel> get products => _products;
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
      _baseUrl = await _loadBaseUrl(sp);
    } catch (_) {}
    await testConnection();
    if (_isOnline) {
      await getCategories();
      await getProducts();
    }
  }

  Future<String?> authenticate({
    required String username,
    required String password,
    String? requiredRole,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      _baseUrl = await _loadBaseUrl(sp);
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
              if (requiredRole != null) 'role': requiredRole,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        return body['message']?.toString() ?? 'Login failed.';
      }

      final user = body['user'] as Map<String, dynamic>?;
      final token = body['token']?.toString();
      if (user == null || token == null || token.isEmpty) {
        debugPrint('Login response is missing user or token.');
        return 'The server returned an invalid login response.';
      }

      await sp.setString(_authTokenKey, token);
      await _saveAuthenticatedUser(sp, user);
      return null;
    } catch (e) {
      debugPrint('Authentication request failed: $e');
      return 'Unable to connect to the server. Check your connection and try again.';
    }
  }

  Future<String?> resetPassword({
    required String username,
    required String newPassword,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      _baseUrl = await _loadBaseUrl(sp);
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/forgot-password'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username.trim(),
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200 || body['success'] != true) {
        return body['message']?.toString() ?? 'Failed to reset password.';
      }
      return null;
    } catch (e) {
      debugPrint('Reset password request failed: $e');
      return 'Unable to connect to the server. Check your connection and try again.';
    }
  }

  Future<bool> restoreSession() async {
    SharedPreferences? sp;
    try {
      sp = await SharedPreferences.getInstance();
      final token = sp.getString(_authTokenKey);
      if (token == null || token.isEmpty) return false;

      _baseUrl = await _loadBaseUrl(sp);
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await _clearAuthSession(sp);
          return false;
        }
        final hasCachedUser = sp.getString('FULLNAME')?.isNotEmpty == true;
        return hasCachedUser;
      }

      final body = jsonDecode(response.body);
      final user = body['user'] as Map<String, dynamic>?;
      if (body['success'] != true || user == null) {
        await _clearAuthSession(sp);
        return false;
      }

      await _saveAuthenticatedUser(sp, user);
      return true;
    } catch (e) {
      debugPrint('Session restore failed: $e');
      if (sp != null) {
        final hasCachedUser = sp.getString('FULLNAME')?.isNotEmpty == true ||
            sp.getString('ROLE')?.isNotEmpty == true;
        if (hasCachedUser) {
          debugPrint(
              'Server offline or timed out - continuing with cached local session.');
          return true;
        }
      }
      return false;
    }
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(_authTokenKey);
    try {
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('Logout request failed: $e');
    } finally {
      await _clearAuthSession(sp);
    }
  }

  Future<Map<String, String>> get userAuthHeaders async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(_authTokenKey);
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _saveAuthenticatedUser(
    SharedPreferences preferences,
    Map<String, dynamic> user,
  ) async {
    await preferences.setString('FULLNAME', user['name']?.toString() ?? '');
    await preferences.setString('EMAIL', user['email']?.toString() ?? '');
    await preferences.setString('ROLE', user['role']?.toString() ?? 'cashier');
    await preferences.setString('UID', user['id']?.toString() ?? '');
  }

  Future<void> _clearAuthSession(SharedPreferences preferences) async {
    await preferences.remove(_authTokenKey);
    await preferences.remove('FULLNAME');
    await preferences.remove('EMAIL');
    await preferences.remove('ROLE');
    await preferences.remove('UID');
  }

  Future<String> _loadBaseUrl(SharedPreferences preferences) async {
    final savedUrl = preferences.getString(_apiBaseUrlKey);
    return savedUrl == null || savedUrl.isEmpty
        ? '${AppUrl.baseUrl}api'
        : savedUrl;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_apiBaseUrlKey, url);
    await testConnection();
    if (_isOnline) {
      await getCategories();
      await getProducts();
      await getUsers();
    }
  }

  Future<bool> testConnection() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/categories'))
          .timeout(const Duration(seconds: 4));
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
}
