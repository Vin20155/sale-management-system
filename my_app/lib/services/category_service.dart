part of 'mart_service.dart';

extension CategoryService on MartService {
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
          final list = (json['data'] as List)
              .map((e) => CategoryModel.fromJson(e))
              .toList();
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
      final res = await http
          .post(
            Uri.parse('$_baseUrl/categories'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(category.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          final newCat = CategoryModel.fromJson(json['data']);
          _categories.add(newCat);
          _isOnline = true;
          return newCat;
        }
      } else {
        debugPrint(
            'addCategory server response ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('addCategory HTTP error: $e');
    }
    _categories.add(category);
    return category;
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await http
          .put(
            Uri.parse('$_baseUrl/categories/${category.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(category.toJson()),
          )
          .timeout(const Duration(seconds: 5));
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
}
