import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/screens/inventory/stock_in_dialog.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen>
    with SingleTickerProviderStateMixin {
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
    final bool isEn = AppLanguage.isEnglish;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEn
              ? 'Inventory & Expiry Tracking'
              : 'គ្រប់គ្រងស្តុក & ផុតកំណត់',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
              text: isEn
                  ? 'Low Stock (${_lowStockList.length})'
                  : 'ជិតអស់ស្តុក (${_lowStockList.length})',
            ),
            Tab(
              icon: const Icon(Icons.event_busy),
              text: isEn
                  ? 'Expiring (${_expiringList.length})'
                  : 'ជិតផុតកំណត់ (${_expiringList.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Low stock
          _buildLowStockTab(isEn),
          // Tab 2: Expiring
          _buildExpiringTab(isEn),
        ],
      ),
    );
  }

  Widget _buildLowStockTab(bool isEn) {
    if (_lowStockList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 54, color: AppColors.success),
            const SizedBox(height: 10),
            Text(
              isEn
                  ? 'All products are well stocked!'
                  : 'ស្តុកគ្រប់គ្រាន់ទាំងអស់ គ្មានទំនិញខ្វះខាតទេ!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.danger.withValues(alpha: 0.12),
              child: const Icon(Icons.production_quantity_limits,
                  color: AppColors.danger),
            ),
            title: Text(
                isEn
                    ? (p.nameEn.isNotEmpty ? p.nameEn : p.nameKh)
                    : p.nameKh,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEn
                      ? 'Barcode: ${p.barcode} • Reorder Level: ${p.reorderLevel} ${p.unit}'
                      : 'បាកូដ: ${p.barcode} • កម្រិតប្រកាសអាសន្ន: ${p.reorderLevel} ${p.unit}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Remaining: ${p.stockQuantity} ${p.unit}'
                      : 'នៅសល់ត្រឹម: ${p.stockQuantity} ${p.unit}',
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => _restockDialog(p),
              child: Text(
                isEn ? 'Restock' : 'បញ្ចូលស្តុក',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiringTab(bool isEn) {
    if (_expiringList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, size: 54, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              isEn
                  ? 'No products are expiring soon!'
                  : 'គ្មានទំនិញដែលជិតផុតកំណត់កាលបរិច្ឆេទទេ!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              child: const Icon(Icons.alarm_on, color: AppColors.warning),
            ),
            title: Text(
                isEn
                    ? (p.nameEn.isNotEmpty ? p.nameEn : p.nameKh)
                    : p.nameKh,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              isEn
                  ? 'Expiry Date: ${p.expiryDate}\nCurrent Stock: ${p.stockQuantity} ${p.unit}'
                  : 'ថ្ងៃផុតកំណត់: ${p.expiryDate}\nស្តុកបច្ចុប្បន្ន: ${p.stockQuantity} ${p.unit}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isEn ? 'Expiring Soon' : 'ជិតដល់កាលបរិច្ឆេទ',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 10),
              ),
            ),
          ),
        );
      },
    );
  }

  void _restockDialog(ProductModel product) {
    StockInDialog.show(
      context,
      product: product,
      onStockUpdated: () {
        _loadAlerts();
      },
    );
  }
}
