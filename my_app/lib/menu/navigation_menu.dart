import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/screens/cards/category_screen.dart';
import 'package:my_app/screens/cards/customer_screen.dart';
import 'package:my_app/screens/cards/invoice_screen.dart';
import 'package:my_app/screens/cards/pos_screen.dart';
import 'package:my_app/screens/cards/product_screen.dart';
import 'package:my_app/screens/cards/report_screen.dart';
import 'package:my_app/screens/cards/setting_screen.dart';
import 'package:my_app/screens/cards/shift_screen.dart';
import 'package:my_app/screens/cards/stock_screen.dart';
import 'package:my_app/screens/cards/user_management_screen.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  final MartService _martService = MartService();
  String? fullname;
  String? email;
  String _role = 'cashier';

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
    setState(() {
      _role = sp.getString("ROLE") ?? 'cashier';
      if (_role == 'admin') {
        fullname = sp.getString("FULLNAME") ?? 'Ngam Vin (Admin)';
        email = sp.getString("EMAIL") ?? 'admin@gmail.com';
      } else if (_role == 'stock_controller') {
        fullname = sp.getString("FULLNAME") ?? 'Vin (Stock Controller)';
        email = sp.getString("EMAIL") ?? 'stock@gmail.com';
      } else {
        fullname = sp.getString("FULLNAME") ?? 'អ្នកគិតលុយ (Cashier)';
        email = sp.getString("EMAIL") ?? 'cashier@gmail.com';
      }
    });
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
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
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

  Future<void> _signOut() async {
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
      await _signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final setting = _martService.getSettings();
    final bool isStockController = _role == 'stock_controller';
    final bool isAdmin = _role == 'admin';
    final bool isEn = AppLanguage.isEnglish;

    String roleLabel = isEn ? 'Cashier' : 'បេឡាករ (Cashier)';
    IconData roleIcon = Icons.point_of_sale;
    Color roleColor = AppColors.primary;
    List<Color> headerGradient = [const Color(0xFF0F766E), const Color(0xFF115E59)];

    if (isAdmin) {
      roleLabel = isEn ? 'Administrator' : 'អ្នកគ្រប់គ្រងទូទៅ (Admin)';
      roleIcon = Icons.admin_panel_settings;
      roleColor = Colors.indigo;
      headerGradient = [const Color(0xFF4F46E5), const Color(0xFF312E81)];
    } else if (isStockController) {
      roleLabel = isEn ? 'Stock Controller' : 'អ្នកគ្រប់គ្រងស្តុក (Stock)';
      roleIcon = Icons.warehouse;
      roleColor = AppColors.secondary;
      headerGradient = [const Color(0xFFD97706), const Color(0xFF92400E)];
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── PREMIUM CUSTOM HEADER ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGradient.first.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Icon(roleIcon, color: roleColor, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullname ?? (isEn ? 'Dara Chan' : 'តារា ចាន់'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${isEn ? setting.martNameEn : setting.martNameKh} • $email',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _switchRoleDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isEn ? 'Switch Role Demo' : 'ប្តូរតួនាទី (Switch Role)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── MENU ITEMS LIST ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // SECTION 1: CASHIER OPERATIONS
                _buildSectionHeader(isEn ? 'Cashier Operations' : 'ផ្នែកគិតប្រាក់ (Cashier)', icon: Icons.point_of_sale_rounded),
                _buildMenuItem(
                  icon: Icons.point_of_sale_rounded,
                  iconColor: AppColors.primary,
                  title: 'POS Terminal',
                  subtitle: isEn ? 'Scan barcode, Pay, KHQR' : 'ស្កេនបាកូដ, គិតប្រាក់, KHQR',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.khqrBakongRed,
                  title: isEn ? 'Shift Drawer' : 'វេនការងារ (Shift Drawer)',
                  subtitle: isEn ? 'Open/Close shift, cash count' : 'បើក/បិទវេន, រាប់សាច់ប្រាក់',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.success,
                  title: isEn ? 'Sales Invoices' : 'វិក្កយបត្រលក់ (Invoices)',
                  subtitle: isEn ? 'View & reprint receipts' : 'មើលវិក្កយបត្រ & បោះពុម្ពឡើងវិញ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InvoiceScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.pink,
                  title: isEn ? 'Customer Loyalty' : 'អតិថិជន (Customer Loyalty)',
                  subtitle: isEn ? 'Phone search & earn points' : 'ស្វែងរកតាមលេខទូរស័ព្ទ & សន្សំពិន្ទុ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerScreen()));
                  },
                ),

                const SizedBox(height: 6),

                // SECTION 2: STOCK CONTROLLER OPERATIONS
                _buildSectionHeader(isEn ? 'Stock & Inventory' : 'ផ្នែកគ្រប់គ្រងស្តុក (Stock & Inventory)', icon: Icons.warehouse_rounded),
                _buildMenuItem(
                  icon: Icons.warehouse_outlined,
                  iconColor: AppColors.warning,
                  title: isEn ? 'Stock & Expiry' : 'ស្តុក & ផុតកំណត់ (Stock & Expiry)',
                  subtitle: isEn ? 'Low stock alert & restock' : 'ប្រកាសអាសន្នជិតអស់ & បញ្ចូលស្តុក',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StockScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.info,
                  title: isEn ? 'Products & Barcode' : 'ទំនិញ (Products & Barcode)',
                  subtitle: isEn ? 'Create products, barcodes & prices' : 'បង្កើតទំនិញថ្មី, កំណត់បាកូដ & តម្លៃ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.category_outlined,
                  iconColor: Colors.purple,
                  title: isEn ? 'Categories' : 'ប្រភេទទំនិញ (Categories)',
                  subtitle: isEn ? 'Beverages, snacks, grocery...' : 'ភេសជ្ជៈ, នំចំណី, អាហារកំប៉ុង...',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                  },
                ),

                const SizedBox(height: 6),

                // SECTION 3: MANAGEMENT & SETTINGS
                _buildSectionHeader(isEn ? 'Management & Settings' : 'គ្រប់គ្រង & ប្រព័ន្ធ (Management & Settings)', icon: Icons.tune_rounded),
                if (isAdmin)
                  _buildMenuItem(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: isEn ? 'User Management' : 'គ្រប់គ្រងអ្នកប្រើប្រាស់ (Users)',
                    subtitle: isEn ? 'Add, edit, delete staff & roles' : 'បន្ថែម, កែប្រែ, លុបគណនីបុគ្គលិក',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
                    },
                  ),
                _buildMenuItem(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Colors.indigo,
                  title: isEn ? 'Analytics & Reports' : 'របាយការណ៍ (Analytics)',
                  subtitle: isEn ? 'Revenue, expense & profit' : 'ចំណូល, ចំណាយ, និងប្រាក់ចំណេញ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.textSecondary,
                  title: isEn ? 'Mart Settings' : 'ការកំណត់ (Settings)',
                  subtitle: isEn ? 'Exchange rate, store info, KHQR' : 'អត្រាប្តូរប្រាក់, ឈ្មោះម៉ាត, KHQR',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()));
                  },
                ),
              ],
            ),
          ),

          // ── FOOTER: LOGOUT & VERSION ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.bgmain,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => _confirmSignOut(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEn ? 'Logout System' : 'ចាកចេញពីប្រព័ន្ធ (Logout)',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.danger, size: 13),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'SuperMart POS • Version 1.0.0',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}