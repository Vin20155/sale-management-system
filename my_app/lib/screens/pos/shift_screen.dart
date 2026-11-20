import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
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
    final bool isEn = AppLanguage.isEnglish;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isEn
              ? 'Shift & Cash Drawer'
              : 'វេនការងារ & ប្រអប់លុយ',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEn ? 'Current Shift Status:' : 'ស្ថានភាពវេនបច្ចុប្បន្ន:',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasOpenShift
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasOpenShift
                                ? (isEn
                                    ? '● Active (Open)'
                                    : '● កំពុងដំណើរការ')
                                : (isEn
                                    ? '○ Closed'
                                    : '○ បានបិទវេន'),
                            style: TextStyle(
                              color: hasOpenShift
                                  ? AppColors.success
                                  : AppColors.danger,
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
                          Text(
                            isEn ? 'Opened At:' : 'ម៉ោងបើកវេន:',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(_shift!.openedAt,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Opening Cash (\$):' : 'លុយដើមគ្រា (\$):',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                              _martService.formatUsd(_shift!.openingCashUsd),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Opening Cash (៛):' : 'លុយដើមគ្រា (៛):',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                              _martService.formatKhr(_shift!.openingCashKhr),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Total Invoices:' : 'ចំនួនវិក្កយបត្រលក់:',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            isEn
                                ? '${_shift!.totalOrdersCount} invoices'
                                : '${_shift!.totalOrdersCount} វិក្កយបត្រ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Total Sales (\$):' : 'ចំណូលសរុប (\$):',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                              _martService.formatUsd(_shift!.totalSalesUsd),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Total Sales (៛):' : 'ចំណូលសរុប (៛):',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                              _martService.formatKhr(_shift!.totalSalesKhr),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.secondary)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: Text(
                  isEn
                      ? 'Open New Shift'
                      : 'បើកវេនការងារថ្មី',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                onPressed: _showOpenShiftDialog,
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.lock, color: Colors.white),
                label: Text(
                  isEn
                      ? 'Close Shift & Count Cash'
                      : 'បិទវេនការងារ & រាប់លុយ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                onPressed: _showCloseShiftDialog,
              ),
          ],
        ),
      ),
    );
  }

  void _showOpenShiftDialog() {
    final bool isEn = AppLanguage.isEnglish;
    final usdCtrl = TextEditingController(text: '50.00');
    final khrCtrl = TextEditingController(text: '200000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEn ? 'Open Shift' : 'បើកវេនការងារ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn
                  ? 'Enter the opening cash in the drawer:'
                  : 'សូមបញ្ចូលចំនួនប្រាក់អាប់ដើមគ្រាក្នុងកេះលុយ:',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usdCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isEn ? 'Opening Cash (\$)' : 'ប្រាក់ដើមគ្រា (\$)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: khrCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isEn ? 'Opening Cash (៛)' : 'ប្រាក់ដើមគ្រា (៛)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final usd = double.tryParse(usdCtrl.text) ?? 0.0;
              final khr = double.tryParse(khrCtrl.text) ?? 0.0;
              _martService.openShift(usd, khr);
              Navigator.pop(context);
              _loadShift();
              EasyLoading.showSuccess(
                isEn ? 'Shift opened successfully!' : 'បានបើកវេនការងារជោគជ័យ!',
              );
            },
            child: Text(
              isEn ? 'Open Shift' : 'បើកវេន',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseShiftDialog() {
    final bool isEn = AppLanguage.isEnglish;
    final usdCloseCtrl = TextEditingController();
    final khrCloseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEn
              ? 'Close Shift & Verify Cash'
              : 'បិទវេនការងារ & ផ្ទៀងផ្ទាត់សាច់ប្រាក់',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEn
                  ? 'Count the actual cash remaining in the drawer:'
                  : 'សូមរាប់សាច់ប្រាក់ជាក់ស្តែងក្នុងកេះលុយ:',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usdCloseCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    isEn ? 'Actual Cash (\$)' : 'សាច់ប្រាក់ជាក់ស្តែង (\$)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: khrCloseCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    isEn ? 'Actual Cash (៛)' : 'សាច់ប្រាក់ជាក់ស្តែង (៛)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final usd = double.tryParse(usdCloseCtrl.text) ?? 0.0;
              final khr = double.tryParse(khrCloseCtrl.text) ?? 0.0;
              _martService.closeShift(usd, khr);
              Navigator.pop(context);
              _loadShift();
              EasyLoading.showSuccess(
                isEn
                    ? 'Shift closed and cash verified!'
                    : 'បានបិទវេនការងារ និងផ្ទៀងផ្ទាត់សាច់ប្រាក់រួចរាល់!',
              );
            },
            child: Text(
              isEn ? 'Close Shift' : 'បិទវេន',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
