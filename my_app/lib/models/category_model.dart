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
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
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
