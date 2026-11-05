class CustomerModel {
  final int id;
  final String name;
  final String phone;
  final int points;
  final double totalSpentUsd;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.points = 0,
    this.totalSpentUsd = 0.0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      points: json['points'] ?? 0,
      totalSpentUsd: (json['total_spent_usd'] ?? 0).toDouble(),
    );
  }
}
