part of 'mart_service.dart';

extension CustomerService on MartService {
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
}
