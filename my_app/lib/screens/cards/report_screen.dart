import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/services/mart_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final MartService _martService = MartService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = _martService.getTodayReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalUsd = (_stats['total_sales_usd'] ?? 0.0).toDouble();
    double totalKhr = (_stats['total_sales_khr'] ?? 0.0).toDouble();
    int ordersCount = _stats['total_orders'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'របាយការណ៍លក់ប្រចាំថ្ងៃ (Daily Report)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Revenue Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ចំណូលលក់ថ្ងៃនេះ (Today Revenue)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(_martService.formatUsd(totalUsd), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(_martService.formatKhr(totalKhr), style: const TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ចំនួនវិក្កយបត្រ: $ordersCount', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('អត្រា: \$1 = ${_martService.formatKhr(_martService.exchangeRate)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2 Stats Boxes
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, color: AppColors.danger, size: 26),
                          const SizedBox(height: 8),
                          Text('${_stats['low_stock_count'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.danger)),
                          const Text('ជិតអស់ស្តុក', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.alarm_on, color: AppColors.warning, size: 26),
                          const SizedBox(height: 8),
                          Text('${_stats['expiring_count'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.warning)),
                          const Text('ជិតផុតកំណត់', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Selling Mart Items
            const Text(
              'មុខទំនិញលក់ដាច់បំផុត (Top Selling Products)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildTopItem('ស្រាបៀរ អង្គរ កំប៉ុង 330ml', '3 កំប៉ុង', '\$2.25', '9,300 ៛'),
                  const Divider(height: 1),
                  _buildTopItem('ទឹកបរិសុទ្ធ វីតាល់ 500ml', '2 ដប', '\$0.70', '2,800 ៛'),
                  const Divider(height: 1),
                  _buildTopItem('ដំឡូងបារាំងបំពង Lays 50g', '1 កញ្ចប់', '\$1.00', '4,100 ៛'),
                  const Divider(height: 1),
                  _buildTopItem('មីម៉ាម៉ា រសជាតិសាច់ជ្រូក', '2 កញ្ចប់', '\$0.70', '2,800 ៛'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItem(String name, String qty, String usd, String khr) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.surface,
        child: Icon(Icons.star, color: AppColors.secondary, size: 20),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text('បានលក់: $qty', style: const TextStyle(fontSize: 11)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(usd, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          Text(khr, style: const TextStyle(fontSize: 10, color: AppColors.secondary)),
        ],
      ),
    );
  }
}
