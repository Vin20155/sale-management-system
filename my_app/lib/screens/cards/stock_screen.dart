import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  final MartService _martService = MartService();
  late TabController _tabController;

  List<ProductModel> _lowStockList = [];
  List<ProductModel> _expiringList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  void _loadAlerts() {
    setState(() {
      _lowStockList = _martService.getLowStockProducts();
      _expiringList = _martService.getExpiringProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'គ្រប់គ្រងស្តុក & ផុតកំណត់ (Inventory)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.warning_amber),
              text: 'ជិតអស់ស្តុក (${_lowStockList.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_busy),
              text: 'ជិតផុតកំណត់ (${_expiringList.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Low stock
          _buildLowStockTab(),
          // Tab 2: Expiring
          _buildExpiringTab(),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    if (_lowStockList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 54, color: AppColors.success),
            SizedBox(height: 10),
            Text('ស្តុកគ្រប់គ្រាន់ទាំងអស់ គ្មានទំនិញខ្វះខាតទេ!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _lowStockList.length,
      itemBuilder: (context, index) {
        final p = _lowStockList[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.danger.withOpacity(0.12),
              child: const Icon(Icons.production_quantity_limits, color: AppColors.danger),
            ),
            title: Text(p.nameKh, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('បាកូដ: ${p.barcode} • កម្រិតប្រកាសអាសន្ន: ${p.reorderLevel} ${p.unit}', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  'នៅសល់ត្រឹម: ${p.stockQuantity} ${p.unit}',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _restockDialog(p),
              child: const Text('បញ្ចូលស្តុក', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiringTab() {
    if (_expiringList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, size: 54, color: AppColors.primary),
            SizedBox(height: 10),
            Text('គ្មានទំនិញដែលជិតផុតកំណត់កាលបរិច្ឆេទទេ!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _expiringList.length,
      itemBuilder: (context, index) {
        final p = _expiringList[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.15),
              child: const Icon(Icons.alarm_on, color: AppColors.warning),
            ),
            title: Text(p.nameKh, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('ថ្ងៃផុតកំណត់: ${p.expiryDate}\nស្តុកបច្ចុប្បន្ន: ${p.stockQuantity} ${p.unit}', style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('ជិតដល់កាលបរិច្ឆេទ', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ),
        );
      },
    );
  }

  void _restockDialog(ProductModel product) {
    final qtyCtrl = TextEditingController(text: '24');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('បញ្ចូលស្តុក: ${product.nameKh}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'ចំនួនបន្ថែម (${product.unit})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              int add = int.tryParse(qtyCtrl.text) ?? 0;
              if (add > 0) {
                product.stockQuantity += add;
                _martService.updateProduct(product);
                _loadAlerts();
                EasyLoading.showSuccess('បានបញ្ចូលស្តុកជោគជ័យ!');
              }
              Navigator.pop(context);
            },
            child: const Text('រក្សាទុក', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
