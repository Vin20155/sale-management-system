import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final MartService _martService = MartService();
  ShiftModel? _shift;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  void _loadShift() {
    setState(() {
      _shift = _martService.getCurrentShift();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOpenShift = _shift != null && _shift!.isOpen;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'វេនការងារ & ប្រអប់លុយ (Shift Drawer)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ស្ថានភាពវេនបច្ចុប្បន្ន:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasOpenShift ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasOpenShift ? '● កំពុងដំណើរការ (Open)' : '○ បានបិទវេន (Closed)',
                            style: TextStyle(
                              color: hasOpenShift ? AppColors.success : AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasOpenShift) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ម៉ោងបើកវេន:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(_shift!.openedAt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('លុយដើមគ្រា (\$):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(_martService.formatUsd(_shift!.openingCashUsd), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('លុយដើមគ្រា (៛):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(_martService.formatKhr(_shift!.openingCashKhr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ចំនួនវិក្កយបត្រលក់:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('${_shift!.totalOrdersCount} វិក្កយបត្រ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ចំណូលសរុប (\$):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(_martService.formatUsd(_shift!.totalSalesUsd), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ចំណូលសរុប (៛):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(_martService.formatKhr(_shift!.totalSalesKhr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Open or Close Button
            if (!hasOpenShift)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('បើកវេនការងារថ្មី (Open Shift)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _showOpenShiftDialog,
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock, color: Colors.white),
                label: const Text('បិទវេនការងារ & រាប់លុយ (Close Shift)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _showCloseShiftDialog,
              ),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog() {
    final usdCtrl = TextEditingController(text: '50.00');
    final khrCtrl = TextEditingController(text: '200000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('បើកវេនការងារ (Open Shift)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('សូមបញ្ចូលចំនួនប្រាក់អាប់ដើមគ្រាក្នុងកេះលុយ:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: usdCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'ប្រាក់ដើមគ្រា (\$)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: khrCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ប្រាក់ដើមគ្រា (៛)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final usd = double.tryParse(usdCtrl.text) ?? 0.0;
              final khr = double.tryParse(khrCtrl.text) ?? 0.0;
              _martService.openShift(usd, khr);
              Navigator.pop(context);
              _loadShift();
              EasyLoading.showSuccess('បានបើកវេនការងារជោគជ័យ!');
            },
            child: const Text('បើកវេន', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog() {
    final usdCloseCtrl = TextEditingController();
    final khrCloseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('បិទវេនការងារ & ផ្ទៀងផ្ទាត់សាច់ប្រាក់', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('សូមរាប់សាច់ប្រាក់ជាក់ស្តែងក្នុងកេះលុយ:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: usdCloseCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'សាច់ប្រាក់ជាក់ស្តែង (\$)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: khrCloseCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'សាច់ប្រាក់ជាក់ស្តែង (៛)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('បោះបង់')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final usd = double.tryParse(usdCloseCtrl.text) ?? 0.0;
              final khr = double.tryParse(khrCloseCtrl.text) ?? 0.0;
              _martService.closeShift(usd, khr);
              Navigator.pop(context);
              _loadShift();
              EasyLoading.showSuccess('បានបិទវេនការងារ និងផ្ទៀងផ្ទាត់សាច់ប្រាក់រួចរាល់!');
            },
            child: const Text('បិទវេន', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
