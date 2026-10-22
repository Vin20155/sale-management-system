import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/menu/navigation_menu.dart';
import 'package:my_app/screens/cards/category_screen.dart';
import 'package:my_app/screens/cards/customer_screen.dart';
import 'package:my_app/screens/cards/invoice_screen.dart';
import 'package:my_app/screens/cards/pos_screen.dart';
import 'package:my_app/screens/cards/product_screen.dart';
import 'package:my_app/screens/cards/report_screen.dart';
import 'package:my_app/screens/cards/setting_screen.dart';
import 'package:my_app/screens/cards/shift_screen.dart';
import 'package:my_app/screens/cards/user_management_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/screens/cards/stock_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final MartService _martService = MartService();
  String? fullname;
  String _role = 'cashier';
  Map<String, dynamic> _todayStats = {};

  @override
  void initState() {
    super.initState();
    AppLanguage.languageNotifier.addListener(_onLanguageChanged);
    _loadData();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadData() async {
    final sp = await SharedPreferences.getInstance();
    await _martService.init();
    if (mounted) {
      setState(() {
        _role = sp.getString("ROLE") ?? 'cashier';
        if (_role == 'admin') {
          fullname = sp.getString("FULLNAME") ?? 'ង៉ាម វីន (Admin)';
        } else if (_role == 'stock_controller') {
          fullname = sp.getString("FULLNAME") ?? 'វីន (Stock Controller)';
        } else {
          fullname = sp.getString("FULLNAME") ?? 'តារា ចាន់ (Cashier)';
        }
        _todayStats = _martService.getTodayReport();
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final isSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('ចាកចេញពីប្រព័ន្ធ (Logout)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('តើអ្នកពិតជាចង់ចាកចេញពីគណនីនេះមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ចាកចេញ'),
          ),
        ],
      ),
    );

    if (isSignOut == true) {
      EasyLoading.show(status: 'កំពុងចាកចេញ...');
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.clear();
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      EasyLoading.dismiss();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      EasyLoading.showSuccess('បានចាកចេញដោយជោគជ័យ!');
    }
  }

  Future<void> _promptPasswordAndSwitchRole({
    required String targetRole,
    required String targetFullName,
    required String targetEmail,
    required String targetLabelKh,
    required Color roleColor,
    required IconData roleIcon,
  }) async {
    if (_role == targetRole) {
      EasyLoading.showInfo('អ្នកកំពុងស្ថិតនៅក្នុងតួនាទីនេះរួចហើយ');
      return;
    }

    final txtSwitchPassword = TextEditingController();
    bool isObscured = true;
    String? errorMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withOpacity(0.15),
                child: Icon(roleIcon, color: roleColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'សូមបញ្ចូលពាក្យសម្ងាត់ដើម្បីប្តូរទៅកាន់៖\n$targetLabelKh ($targetEmail)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: txtSwitchPassword,
                obscureText: isObscured,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password (ពាក្យសម្ងាត់)',
                  hintText: '123456',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        isObscured = !isObscured;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  errorText: errorMessage,
                ),
                onSubmitted: (_) {
                  final entered = txtSwitchPassword.text.trim();
                  if (entered == '123456' || entered == 'password' || entered.length >= 6) {
                    Navigator.pop(dialogCtx, true);
                  } else {
                    setDialogState(() {
                      errorMessage = 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ! (Default: 123456)';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final entered = txtSwitchPassword.text.trim();
                if (entered == '123456' || entered == 'password' || entered.length >= 6) {
                  Navigator.pop(dialogCtx, true);
                } else {
                  setDialogState(() {
                    errorMessage = 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ! (Default: 123456)';
                  });
                }
              },
              child: const Text('បញ្ជាក់ & ប្តូរ'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString("ROLE", targetRole);
      await sp.setString("FULLNAME", targetFullName);
      await sp.setString("EMAIL", targetEmail);
      await sp.setString("UID", "${targetRole}_uid");
      EasyLoading.showSuccess('បានប្តូរទៅកាន់ $targetLabelKh');
      _loadData();
    }
  }

  void _switchRoleDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ជ្រើសរើសតួនាទី (Switch Role)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'សូមជ្រើសរើសតួនាទី និងបញ្ចូលពាក្យសម្ងាត់ដើម្បីផ្ទៀងផ្ទាត់៖',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              // Cashier Role Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _role == 'cashier' ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'cashier'
                    ? AppColors.primary.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.06),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.point_of_sale, color: Colors.white),
                ),
                title: const Text('បេឡាករ (Cashier)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('cashier@gmail.com • គិតប្រាក់ POS, KHQR, បើក/បិទវេន', style: TextStyle(fontSize: 11)),
                trailing: _role == 'cashier' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _promptPasswordAndSwitchRole(
                    targetRole: 'cashier',
                    targetFullName: 'អ្នកគិតលុយ (Cashier)',
                    targetEmail: 'cashier@gmail.com',
                    targetLabelKh: 'បេឡាករ (Cashier)',
                    roleColor: AppColors.primary,
                    roleIcon: Icons.point_of_sale,
                  );
                },
              ),
              const SizedBox(height: 8),
              // Stock Controller Role Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _role == 'stock_controller' ? AppColors.secondary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'stock_controller'
                    ? AppColors.secondary.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.06),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.warehouse, color: Colors.white),
                ),
                title: const Text('អ្នកគ្រប់គ្រងស្តុក (Stock Controller)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('stock@gmail.com • ពិនិត្យស្តុក, ផុតកំណត់, បញ្ចូលទំនិញ', style: TextStyle(fontSize: 11)),
                trailing: _role == 'stock_controller' ? const Icon(Icons.check_circle, color: AppColors.secondary) : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _promptPasswordAndSwitchRole(
                    targetRole: 'stock_controller',
                    targetFullName: 'Vin (Stock Controller)',
                    targetEmail: 'stock@gmail.com',
                    targetLabelKh: 'អ្នកគ្រប់គ្រងស្តុក (Stock Controller)',
                    roleColor: AppColors.secondary,
                    roleIcon: Icons.warehouse,
                  );
                },
              ),
              const SizedBox(height: 8),
              // Admin Role Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _role == 'admin' ? Colors.indigo : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'admin'
                    ? Colors.indigo.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.06),
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: const Text('អ្នកគ្រប់គ្រងទូទៅ (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('admin@gmail.com • របាយការណ៍ហិរញ្ញវត្ថុ, គ្រប់គ្រងម៉ាត', style: TextStyle(fontSize: 11)),
                trailing: _role == 'admin' ? const Icon(Icons.check_circle, color: Colors.indigo) : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  _promptPasswordAndSwitchRole(
                    targetRole: 'admin',
                    targetFullName: 'Ngam Vin (Admin)',
                    targetEmail: 'admin@gmail.com',
                    targetLabelKh: 'អ្នកគ្រប់គ្រងទូទៅ (Admin)',
                    roleColor: Colors.indigo,
                    roleIcon: Icons.admin_panel_settings,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String greetingMessage() {
    return AppLanguage.greeting();
  }

  @override
  Widget build(BuildContext context) {
    final setting = _martService.getSettings();
    final shift = _martService.getCurrentShift();
    final bool hasShift = shift != null && shift.isOpen;
    final bool isEn = AppLanguage.isEnglish;

    double todayUsd = (_todayStats['total_sales_usd'] ?? 0.0).toDouble();
    double todayKhr = (_todayStats['total_sales_khr'] ?? 0.0).toDouble();
    int lowStock = _todayStats['low_stock_count'] ?? 0;
    int expiring = _todayStats['expiring_count'] ?? 0;
    final bool isStockController = _role == 'stock_controller';
    final bool isAdmin = _role == 'admin';

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? setting.martNameEn : setting.martNameKh,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              setting.branchName,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isEn ? 'Settings' : 'ការកំណត់',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()))
                  .then((_) => _loadData());
            },
          ),
          IconButton(
            tooltip: isEn ? 'Logout' : 'ចាកចេញ (Logout)',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      drawer: const NavigationMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Top Gradient Curve with User Greeting & Role Badge
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isAdmin
                            ? Colors.indigo
                            : (isStockController ? AppColors.secondary : Colors.white24),
                        child: Icon(
                          isAdmin
                              ? Icons.admin_panel_settings
                              : (isStockController ? Icons.warehouse : Icons.person),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingMessage(),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              fullname ?? (isEn ? (isAdmin ? 'Ngam Vin' : (isStockController ? 'Vin' : 'Dara Chan')) : (isAdmin ? 'ង៉ាម វីន' : (isStockController ? 'វីន' : 'តារា ចាន់'))),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.currency_exchange, color: AppColors.secondary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '\$1 = ${_martService.formatKhr(_martService.exchangeRate)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PRIMARY ACTION BANNER (Tailored to Cashier vs Stock Controller vs Admin)
                  if (isAdmin)
                    // ADMIN PRIMARY BANNER: DASHBOARD & ANALYTICS
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.35),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.analytics, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'ផ្ទាំងគ្រប់គ្រង & វិភាគទិន្នន័យ (Admin Dashboard)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ចំណូលលក់សរុប • របាយការណ៍ហិរញ្ញវត្ថុ • គ្រប់គ្រងម៉ាត',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    )
                  else if (!isStockController)
                    // CASHIER PRIMARY BANNER: POS TERMINAL
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withOpacity(0.35),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'កន្លែងគិតលុយ (POS Terminal)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ស្កេនបាកូដ • គិតប្រាក់ \$/៛ • បាគង KHQR',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    )
                  else
                    // STOCK CONTROLLER PRIMARY BANNER: INVENTORY & RESTOCK
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706).withOpacity(0.35),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.warehouse, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'គ្រប់គ្រងស្តុក & ចូលទំនិញ (Inventory & Stock)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ជិតអស់: $lowStock | ជិតផុតកំណត់: $expiring • បញ្ចូលស្តុក',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // SECONDARY SUMMARY CARD (Tailored to Cashier vs Stock Controller)
                  if (!isStockController)
                    // CASHIER: TODAY'S SALES & SHIFT DRAWER
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'ចំណូលលក់ថ្ងៃនេះ (Today Sales)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftScreen()))
                                        .then((_) => _loadData());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: hasShift ? AppColors.success.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hasShift ? 'វេនបើក ●' : 'វេនបិទ ○',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: hasShift ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _martService.formatUsd(todayUsd),
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    Text(
                                      _martService.formatKhr(todayKhr),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.surface,
                                        foregroundColor: AppColors.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.account_balance_wallet, size: 16),
                                      label: const Text('វេនការងារ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftScreen()))
                                            .then((_) => _loadData());
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // STOCK CONTROLLER: INVENTORY HEALTH & ALERTS
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'ស្ថានភាពស្តុក (Inventory Health)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (lowStock + expiring) > 0
                                        ? AppColors.warning.withOpacity(0.15)
                                        : AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (lowStock + expiring) > 0 ? 'ត្រូវការបញ្ចូលស្តុក ⚠' : 'ស្តុកពេញលេញ ✓',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (lowStock + expiring) > 0 ? AppColors.warning : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                          .then((_) => _loadData());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.warning_amber, size: 16, color: AppColors.danger),
                                              SizedBox(width: 4),
                                              Text('ជិតអស់ស្តុក', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('$lowStock មុខទំនិញ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.danger)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                          .then((_) => _loadData());
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.alarm, size: 16, color: AppColors.warning),
                                              SizedBox(width: 4),
                                              Text('ជិតផុតកំណត់', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('$expiring មុខទំនិញ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'ទំនិញសរុប: ${_martService.products.length} មុខ',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.add_shopping_cart, size: 15),
                                  label: const Text('បញ្ចូលស្តុកភ្លាមៗ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // ROLE-SPECIFIC MODULES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isAdmin
                              ? 'មុខងារគ្រប់គ្រងទូទៅ (Admin Modules)'
                              : (isStockController
                                  ? 'មុខងារគ្រប់គ្រងស្តុក (Stock Modules)'
                                  : 'មុខងារបេឡាករ (Cashier Modules)'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.primary),
                        label: const Text('ប្តូរតួនាទី', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        onPressed: _switchRoleDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: isAdmin
                        ? [
                            // ── Admin modules (Full System Control) ──
                            _buildMenuCard(
                              titleKh: 'គ្រប់គ្រងអ្នកប្រើប្រាស់',
                              titleEn: 'User Management',
                              icon: Icons.manage_accounts,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'របាយការណ៍លក់ & វិភាគ',
                              titleEn: 'Reports & Analytics',
                              icon: Icons.bar_chart,
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ការកំណត់ប្រព័ន្ធ',
                              titleEn: 'Mart Settings',
                              icon: Icons.tune,
                              color: const Color(0xFF64748B),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'កន្លែងគិតលុយ (POS)',
                              titleEn: 'POS Checkout',
                              icon: Icons.point_of_sale,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'វេនការងារ & ប្រអប់លុយ',
                              titleEn: 'Shift Drawer',
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFFE11D48),
                              badge: hasShift ? 'វេនបើក' : 'វេនបិទ',
                              badgeColor: hasShift ? AppColors.success : AppColors.danger,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ស្តុក & ផុតកំណត់',
                              titleEn: 'Stock & Expiry',
                              icon: Icons.warehouse,
                              color: AppColors.warning,
                              badge: (lowStock + expiring) > 0 ? '${lowStock + expiring}' : null,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ទំនិញទាំងអស់ & បាកូដ',
                              titleEn: 'Products & Barcode',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រភេទទំនិញ',
                              titleEn: 'Categories',
                              icon: Icons.category,
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រវត្តិវិក្កយបត្រ',
                              titleEn: 'Sales Invoices',
                              icon: Icons.receipt_long,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceScreen()));
                              },
                            ),
                          ]
                        : isStockController
                        ? [
                            // ── Stock Controller modules ──
                            _buildMenuCard(
                              titleKh: 'ស្តុក & ផុតកំណត់',
                              titleEn: 'Stock & Expiry',
                              icon: Icons.warehouse,
                              color: AppColors.warning,
                              badge: (lowStock + expiring) > 0 ? '${lowStock + expiring}' : null,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ទំនិញទាំងអស់ & បាកូដ',
                              titleEn: 'Products & Barcode',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រភេទទំនិញ',
                              titleEn: 'Categories',
                              icon: Icons.category,
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'របាយការណ៍លក់ & ស្តុក',
                              titleEn: 'Reports & Analytics',
                              icon: Icons.bar_chart,
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'កន្លែងគិតលុយ (POS)',
                              titleEn: 'POS Checkout',
                              icon: Icons.point_of_sale,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ការកំណត់ប្រព័ន្ធ',
                              titleEn: 'Mart Settings',
                              icon: Icons.tune,
                              color: const Color(0xFF64748B),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                          ]
                        : [
                            // ── Cashier modules ──
                            _buildMenuCard(
                              titleKh: 'លក់ទំនិញ (POS)',
                              titleEn: 'POS Checkout',
                              icon: Icons.point_of_sale,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'វេនការងារ & ប្រអប់លុយ',
                              titleEn: 'Shift Drawer',
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFFE11D48),
                              badge: hasShift ? 'វេនបើក' : 'វេនបិទ',
                              badgeColor: hasShift ? AppColors.success : AppColors.danger,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រវត្តិវិក្កយបត្រ',
                              titleEn: 'Sales Invoices',
                              icon: Icons.receipt_long,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'អតិថិជន & ពិន្ទុ',
                              titleEn: 'Customer Loyalty',
                              icon: Icons.people_alt,
                              color: const Color(0xFFEC4899),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ទំនិញទាំងអស់',
                              titleEn: 'Products & Barcode',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ស្តុក & ផុតកំណត់',
                              titleEn: 'Stock & Expiry',
                              icon: Icons.warehouse,
                              color: AppColors.warning,
                              badge: (lowStock + expiring) > 0 ? '${lowStock + expiring}' : null,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                          ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String titleKh,
    required String titleEn,
    required IconData icon,
    required Color color,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                AppLanguage.isEnglish ? titleEn : titleKh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              Text(
                AppLanguage.isEnglish ? titleKh : titleEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}