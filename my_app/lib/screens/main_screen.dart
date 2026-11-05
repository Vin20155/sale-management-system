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
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/screens/cards/stock_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/models/mart_models.dart';
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
        fullname = sp.getString("FULLNAME");
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
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.danger),
            SizedBox(width: 8),
            Text('ចាកចេញពីប្រព័ន្ធ (Logout)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('ចាកចេញ'),
          ),
        ],
      ),
    );

    if (isSignOut == true) {
      EasyLoading.show(status: 'កំពុងចាកចេញ...');
      await _martService.logout();
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
    required String targetEmail,
    required String targetLabelKh,
    required Color roleColor,
    required IconData roleIcon,
  }) async {
    if (_role == targetRole) {
      EasyLoading.showInfo('អ្នកកំពុងស្ថិតនៅក្នុងតួនាទីនេះរួចហើយ');
      return;
    }

    final txtSwitchUsername = TextEditingController(text: targetEmail);
    final txtSwitchPassword = TextEditingController();
    bool isObscured = true;
    String? errorMessage;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
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
                'សូមបញ្ចូលឈ្មោះគណនី ឬអ៊ីមែល និងពាក្យសម្ងាត់ដើម្បីប្តូរទៅកាន់៖\n$targetLabelKh',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: txtSwitchUsername,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username / Email (ឈ្មោះគណនី / អ៊ីមែល)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txtSwitchPassword,
                obscureText: isObscured,
                decoration: InputDecoration(
                  labelText: 'Password (ពាក្យសម្ងាត់)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
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
                  if (txtSwitchUsername.text.trim().isNotEmpty &&
                      entered.isNotEmpty) {
                    Navigator.pop(dialogCtx, true);
                  } else {
                    setDialogState(() {
                      errorMessage = 'សូមបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់';
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final entered = txtSwitchPassword.text.trim();
                if (txtSwitchUsername.text.trim().isNotEmpty &&
                    entered.isNotEmpty) {
                  Navigator.pop(dialogCtx, true);
                } else {
                  setDialogState(() {
                    errorMessage = 'សូមបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់';
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
      final username = txtSwitchUsername.text;
      final password = txtSwitchPassword.text;
      txtSwitchUsername.dispose();
      txtSwitchPassword.dispose();
      final error = await _martService.authenticate(
        username: username,
        password: password,
        requiredRole: targetRole,
      );
      if (error != null) {
        EasyLoading.showError(error);
        return;
      }
      EasyLoading.showSuccess('បានចូលគណនី $targetLabelKh');
      _loadData();
    } else {
      txtSwitchUsername.dispose();
      txtSwitchPassword.dispose();
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
                'សូមជ្រើសរើសតួនាទី ហើយបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់៖',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              // Cashier Role Tile
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _role == 'cashier'
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'cashier'
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.06),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.point_of_sale, color: Colors.white),
                ),
                title: const Text('បេឡាករ (Cashier)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('គិតប្រាក់ POS, KHQR, បើក/បិទវេន',
                    style: TextStyle(fontSize: 11)),
                trailing: _role == 'cashier'
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  final matched =
                      _martService.users.cast<UserModel?>().firstWhere(
                            (u) => u?.role == 'cashier',
                            orElse: () => null,
                          );
                  _promptPasswordAndSwitchRole(
                    targetRole: 'cashier',
                    targetEmail: matched?.email ?? '',
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
                    color: _role == 'stock_controller'
                        ? AppColors.secondary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'stock_controller'
                    ? AppColors.secondary.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.06),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.warehouse, color: Colors.white),
                ),
                title: const Text('អ្នកគ្រប់គ្រងស្តុក (Stock Controller)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('ពិនិត្យស្តុក, ផុតកំណត់, បញ្ចូលទំនិញ',
                    style: TextStyle(fontSize: 11)),
                trailing: _role == 'stock_controller'
                    ? const Icon(Icons.check_circle, color: AppColors.secondary)
                    : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  final matched =
                      _martService.users.cast<UserModel?>().firstWhere(
                            (u) => u?.role == 'stock_controller',
                            orElse: () => null,
                          );
                  _promptPasswordAndSwitchRole(
                    targetRole: 'stock_controller',
                    targetEmail: matched?.email ?? '',
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
                    color:
                        _role == 'admin' ? Colors.indigo : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                tileColor: _role == 'admin'
                    ? Colors.indigo.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.06),
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: const Text('អ្នកគ្រប់គ្រងទូទៅ (Admin)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('របាយការណ៍ហិរញ្ញវត្ថុ, គ្រប់គ្រងម៉ាត',
                    style: TextStyle(fontSize: 11)),
                trailing: _role == 'admin'
                    ? const Icon(Icons.check_circle, color: Colors.indigo)
                    : null,
                onTap: () {
                  Navigator.pop(bottomSheetCtx);
                  final matched =
                      _martService.users.cast<UserModel?>().firstWhere(
                            (u) => u?.role == 'admin',
                            orElse: () => null,
                          );
                  _promptPasswordAndSwitchRole(
                    targetRole: 'admin',
                    targetEmail: matched?.email ?? '',
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

    final List<Color> headerGradient = isAdmin
        ? [const Color(0xFF4338CA), const Color(0xFF312E81)]
        : (isStockController
            ? [const Color(0xFFD97706), const Color(0xFF92400E)]
            : [const Color(0xFF0F766E), const Color(0xFF0D5E56)]);

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: headerGradient.first,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? setting.martNameEn : setting.martNameKh,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.white,
                  letterSpacing: 0.2),
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                const Icon(Icons.location_on, size: 11, color: Colors.white70),
                const SizedBox(width: 3),
                Text(
                  setting.branchName,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: isEn ? 'Settings' : 'ការកំណត់',
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 19),
                onPressed: () {
                  Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingScreen()))
                      .then((_) => _loadData());
                },
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: isEn ? 'Logout' : 'ចាកចេញ (Logout)',
                icon: const Icon(Icons.logout_rounded,
                    color: Colors.white, size: 18),
                onPressed: _confirmSignOut,
              ),
            ),
          ),
        ],
      ),
      drawer: const NavigationMenu(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Top Gradient Curve with User Greeting & Role Badge
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: headerGradient.first.withValues(alpha: 0.25),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings
                            : (isStockController
                                ? Icons.warehouse
                                : Icons.person),
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greetingMessage(),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullname ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isAdmin
                                    ? (isEn
                                        ? 'Administrator'
                                        : 'អ្នកគ្រប់គ្រង (Admin)')
                                    : (isStockController
                                        ? (isEn
                                            ? 'Stock Controller'
                                            : 'អ្នកគ្រប់គ្រងស្តុក (Stock)')
                                        : (isEn
                                            ? 'Cashier'
                                            : 'បេឡាករ (Cashier)')),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_exchange,
                            color: Color(0xFFFDE047), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '\$1 = ${_martService.formatKhr(_martService.exchangeRate)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ReportScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.28),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.analytics_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ផ្ទាំងគ្រប់គ្រង & វិភាគទិន្នន័យ (Admin Dashboard)',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'ចំណូលលក់សរុប • របាយការណ៍ហិរញ្ញវត្ថុ • គ្រប់គ្រងម៉ាត',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    )
                  else if (!isStockController)
                    // CASHIER PRIMARY BANNER: POS TERMINAL
                    InkWell(
                      onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PosScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E)
                                  .withValues(alpha: 0.28),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                  Icons.shopping_cart_checkout_rounded,
                                  color: Colors.white,
                                  size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'កន្លែងគិតលុយ (POS Terminal)',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'ស្កេនបាកូដ • គិតប្រាក់ \$/៛ • បាគង KHQR',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    )
                  else
                    // STOCK CONTROLLER PRIMARY BANNER: INVENTORY & RESTOCK
                    InkWell(
                      onTap: () {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const StockScreen()))
                            .then((_) => _loadData());
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFB45309)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.28),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.warehouse_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'គ្រប់គ្រងស្តុក & ចូលទំនិញ (Inventory & Stock)',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'ជិតអស់: $lowStock | ជិតផុតកំណត់: $expiring • បញ្ចូលស្តុក',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // SECONDARY SUMMARY CARD (Tailored to Cashier vs Stock Controller)
                  if (!isStockController)
                    // CASHIER: TODAY'S SALES & SHIFT DRAWER
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.trending_up,
                                        size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ចំណូលលក់ថ្ងៃនេះ (Today Sales)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ShiftScreen()))
                                      .then((_) => _loadData());
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hasShift
                                        ? AppColors.success
                                            .withValues(alpha: 0.1)
                                        : AppColors.danger
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: hasShift
                                          ? AppColors.success
                                              .withValues(alpha: 0.3)
                                          : AppColors.danger
                                              .withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: hasShift
                                              ? AppColors.success
                                              : AppColors.danger,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        hasShift ? 'វេនបើក' : 'វេនបិទ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: hasShift
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _martService.formatUsd(todayUsd),
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _martService.formatKhr(todayKhr),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondary),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.08),
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.account_balance_wallet,
                                    size: 16),
                                label: const Text('វេនការងារ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const ShiftScreen()))
                                      .then((_) => _loadData());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // STOCK CONTROLLER: INVENTORY HEALTH & ALERTS
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final hasStockAlerts = lowStock + expiring > 0;
                              final title = Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.inventory_rounded,
                                        size: 16, color: Color(0xFFD97706)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'ស្ថានភាពស្តុក (Inventory Health)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              );
                              final status = Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasStockAlerts
                                      ? AppColors.warning
                                          .withValues(alpha: 0.12)
                                      : AppColors.success
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: hasStockAlerts
                                        ? AppColors.warning
                                            .withValues(alpha: 0.3)
                                        : AppColors.success
                                            .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  hasStockAlerts
                                      ? 'ត្រូវការបញ្ចូលស្តុក ⚠'
                                      : 'ស្តុកពេញលេញ ✓',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: hasStockAlerts
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                              );

                              if (constraints.maxWidth < 380) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    title,
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: status,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: title),
                                  const SizedBox(width: 8),
                                  status,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const StockScreen()))
                                        .then((_) => _loadData());
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFFECACA),
                                          width: 0.8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded,
                                                size: 16,
                                                color: AppColors.danger),
                                            SizedBox(width: 4),
                                            Text('ជិតអស់ស្តុក',
                                                style: TextStyle(
                                                    color: AppColors.danger,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('$lowStock មុខ',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.danger)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const StockScreen()))
                                        .then((_) => _loadData());
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFFDE68A),
                                          width: 0.8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.alarm_rounded,
                                                size: 16,
                                                color: Color(0xFFB45309)),
                                            SizedBox(width: 4),
                                            Text('ជិតផុតកំណត់',
                                                style: TextStyle(
                                                    color: Color(0xFFB45309),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text('$expiring មុខ',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFB45309))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ទំនិញសរុប: ${_martService.products.length} មុខ',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B)),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add_shopping_cart,
                                    size: 15),
                                label: const Text('បញ្ចូលស្តុកភ្លាមៗ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const StockScreen()))
                                      .then((_) => _loadData());
                                },
                              ),
                            ],
                          ),
                        ],
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
                              ? (isEn
                                  ? 'Admin Modules'
                                  : 'មុខងារគ្រប់គ្រងទូទៅ (Admin)')
                              : (isStockController
                                  ? (isEn
                                      ? 'Stock Modules'
                                      : 'មុខងារគ្រប់គ្រងស្តុក (Stock)')
                                  : (isEn
                                      ? 'Cashier Modules'
                                      : 'មុខងារបេឡាករ (Cashier)')),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: _switchRoleDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_horiz_rounded,
                                  size: 15, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                isEn ? 'Switch' : 'ប្តូរតួនាទី',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const UserManagementScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'របាយការណ៍លក់ & វិភាគ',
                              titleEn: 'Reports & Analytics',
                              icon: Icons.bar_chart,
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ReportScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ការកំណត់ប្រព័ន្ធ',
                              titleEn: 'Mart Settings',
                              icon: Icons.tune,
                              color: const Color(0xFF64748B),
                              onTap: () {
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'កន្លែងគិតលុយ (POS)',
                              titleEn: 'POS Checkout',
                              icon: Icons.point_of_sale,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PosScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'វេនការងារ & ប្រអប់លុយ',
                              titleEn: 'Shift Drawer',
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFFE11D48),
                              badge: hasShift ? 'វេនបើក' : 'វេនបិទ',
                              badgeColor: hasShift
                                  ? AppColors.success
                                  : AppColors.danger,
                              onTap: () {
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ShiftScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ស្តុក & ផុតកំណត់',
                              titleEn: 'Stock & Expiry',
                              icon: Icons.warehouse,
                              color: AppColors.warning,
                              badge: (lowStock + expiring) > 0
                                  ? '${lowStock + expiring}'
                                  : null,
                              onTap: () {
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const StockScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ទំនិញទាំងអស់ & បាកូដ',
                              titleEn: 'Products & Barcode',
                              icon: Icons.inventory_2,
                              color: const Color(0xFF0284C7),
                              onTap: () {
                                Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ProductScreen()))
                                    .then((_) => _loadData());
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រភេទទំនិញ',
                              titleEn: 'Categories',
                              icon: Icons.category,
                              color: const Color(0xFF8B5CF6),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const CategoryScreen()));
                              },
                            ),
                            _buildMenuCard(
                              titleKh: 'ប្រវត្តិវិក្កយបត្រ',
                              titleEn: 'Sales Invoices',
                              icon: Icons.receipt_long,
                              color: const Color(0xFF10B981),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const InvoiceScreen()));
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
                                  badge: (lowStock + expiring) > 0
                                      ? '${lowStock + expiring}'
                                      : null,
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const StockScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ទំនិញទាំងអស់ & បាកូដ',
                                  titleEn: 'Products & Barcode',
                                  icon: Icons.inventory_2,
                                  color: const Color(0xFF0284C7),
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ProductScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ប្រភេទទំនិញ',
                                  titleEn: 'Categories',
                                  icon: Icons.category,
                                  color: const Color(0xFF8B5CF6),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CategoryScreen()));
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'របាយការណ៍លក់ & ស្តុក',
                                  titleEn: 'Reports & Analytics',
                                  icon: Icons.bar_chart,
                                  color: Colors.indigo,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ReportScreen()));
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'កន្លែងគិតលុយ (POS)',
                                  titleEn: 'POS Checkout',
                                  icon: Icons.point_of_sale,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const PosScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ការកំណត់ប្រព័ន្ធ',
                                  titleEn: 'Mart Settings',
                                  icon: Icons.tune,
                                  color: const Color(0xFF64748B),
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const SettingScreen()))
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
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const PosScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'វេនការងារ & ប្រអប់លុយ',
                                  titleEn: 'Shift Drawer',
                                  icon: Icons.account_balance_wallet,
                                  color: const Color(0xFFE11D48),
                                  badge: hasShift ? 'វេនបើក' : 'វេនបិទ',
                                  badgeColor: hasShift
                                      ? AppColors.success
                                      : AppColors.danger,
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ShiftScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ប្រវត្តិវិក្កយបត្រ',
                                  titleEn: 'Sales Invoices',
                                  icon: Icons.receipt_long,
                                  color: const Color(0xFF10B981),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const InvoiceScreen()));
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'អតិថិជន & ពិន្ទុ',
                                  titleEn: 'Customer Loyalty',
                                  icon: Icons.people_alt,
                                  color: const Color(0xFFEC4899),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CustomerScreen()));
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ទំនិញទាំងអស់',
                                  titleEn: 'Products & Barcode',
                                  icon: Icons.inventory_2,
                                  color: const Color(0xFF0284C7),
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ProductScreen()))
                                        .then((_) => _loadData());
                                  },
                                ),
                                _buildMenuCard(
                                  titleKh: 'ស្តុក & ផុតកំណត់',
                                  titleEn: 'Stock & Expiry',
                                  icon: Icons.warehouse,
                                  color: AppColors.warning,
                                  badge: (lowStock + expiring) > 0
                                      ? '${lowStock + expiring}'
                                      : null,
                                  onTap: () {
                                    Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const StockScreen()))
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.danger,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (badgeColor ?? AppColors.danger)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  AppLanguage.isEnglish ? titleEn : titleKh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  AppLanguage.isEnglish ? titleKh : titleEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
