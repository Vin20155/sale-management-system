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
}
