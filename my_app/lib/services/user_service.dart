part of 'mart_service.dart';

extension UserService on MartService {
  // ==========================================
  // USERS MANAGEMENT (ADMIN ONLY)
  // ==========================================
  Future<List<UserModel>> getUsers({String? search, String? roleFilter}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
        queryParams['role'] = roleFilter;
      }

      final uri = Uri.parse('$_baseUrl/users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final res = await http.get(
        uri,
        headers: await userAuthHeaders,
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final list = (json['data'] as List)
              .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList();

          if ((search == null || search.isEmpty) &&
              (roleFilter == null || roleFilter == 'all')) {
            _users = list;
          }
          _isOnline = true;
          return list;
        }
      }
    } catch (e) {
      debugPrint('getUsers API error: $e');
    }

    // Fallback to local _users if offline
    List<UserModel> list = List.from(_users);
    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
      list = list.where((u) => u.role == roleFilter).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where((u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.phone.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<bool> addUser({
    required String name,
    required String email,
    required String role,
    required String phone,
    required String password,
  }) async {
    try {
      final headers = await userAuthHeaders;
      final res = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'role': role,
              'phone': phone.trim(),
              if (password.isNotEmpty) 'password': password,
              'is_active': true,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final newUser = UserModel.fromJson(json['data']);
          _users.removeWhere((u) => u.id == newUser.id);
          _users.insert(0, newUser);
          _isOnline = true;
          return true;
        }
      } else {
        debugPrint('addUser API response: ${res.statusCode} ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('addUser HTTP error: $e');
      return false;
    }

    return false;
  }

  Future<bool> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
    required String phone,
    required bool isActive,
    String? password,
  }) async {
    try {
      final headers = await userAuthHeaders;
      final res = await http
          .put(
            Uri.parse('$_baseUrl/users/$id'),
            headers: {
              ...headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'role': role,
              'phone': phone.trim(),
              'is_active': isActive,
              if (password != null && password.isNotEmpty) 'password': password,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final updated = UserModel.fromJson(json['data']);
          final idx = _users.indexWhere((u) => u.id == id);
          if (idx != -1) {
            _users[idx] = updated;
          } else {
            _users.insert(0, updated);
          }
          _isOnline = true;
          return true;
        }
      } else {
        debugPrint('updateUser API response: ${res.statusCode} ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('updateUser HTTP error: $e');
      return false;
    }

    return false;
  }

  Future<bool> deleteUser(int id) async {
    try {
      final headers = await userAuthHeaders;
      final res = await http.delete(
        Uri.parse('$_baseUrl/users/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        _users.removeWhere((u) => u.id == id);
        return true;
      }
    } catch (e) {
      debugPrint('deleteUser HTTP error: $e');
      return false;
    }
    return false;
  }
}
