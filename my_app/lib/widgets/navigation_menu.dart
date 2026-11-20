import 'package:flutter/material.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/screens/admin/report_screen.dart';
import 'package:my_app/screens/admin/setting_screen.dart';
import 'package:my_app/screens/admin/user_management_screen.dart';
import 'package:my_app/screens/dashboard/main_screen.dart';
import 'package:my_app/screens/inventory/category_screen.dart';
import 'package:my_app/screens/inventory/inventory_report_screen.dart';
import 'package:my_app/screens/inventory/product_screen.dart';
import 'package:my_app/screens/inventory/stock_screen.dart';
import 'package:my_app/screens/pos/customer_screen.dart';
import 'package:my_app/screens/pos/invoice_screen.dart';
import 'package:my_app/screens/pos/pos_screen.dart';
import 'package:my_app/screens/pos/shift_screen.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:my_app/widgets/role_switcher.dart';
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
    await _martService.init();

    if (mounted) {
      setState(() {
        _role = sp.getString("ROLE") ?? 'cashier';
        fullname = sp.getString("FULLNAME");
        email = sp.getString("EMAIL");
      });
    }
  }

  void _switchRoleDialog() {
    RoleSwitcher.showSwitchRoleSheet(
      context,
      currentRole: _role,
      onRoleChanged: () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      },
    );
  }

  Future<void> _confirmSignOut() => RoleSwitcher.confirmSignOut(context);

  @override
  Widget build(BuildContext context) {
    final setting = _martService.getSettings();
    final bool isStockController = _role == 'stock_controller';
    final bool isAdmin = _role == 'admin';
    final bool isEn = AppLanguage.isEnglish;

    String roleLabel = isEn ? 'Cashier' : 'បេឡាករ';
    IconData roleIcon = Icons.point_of_sale;
    Color roleColor = AppColors.primary;
    List<Color> headerGradient = [
      const Color(0xFF0F766E),
      const Color(0xFF115E59)
    ];

    if (isAdmin) {
      roleLabel = isEn ? 'Administrator' : 'អ្នកគ្រប់គ្រងទូទៅ';
      roleIcon = Icons.admin_panel_settings;
      roleColor = Colors.indigo;
      headerGradient = [const Color(0xFF4F46E5), const Color(0xFF312E81)];
    } else if (isStockController) {
      roleLabel = isEn ? 'Stock Controller' : 'អ្នកគ្រប់គ្រងស្តុក';
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
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 14, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGradient.first.withValues(alpha: 0.25),
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
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 2),
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
                            fullname ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${isEn ? setting.martNameEn : setting.martNameKh} • $email',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
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
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isEn ? 'Switch Role' : 'ប្តូរតួនាទី',
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
                _buildSectionHeader(
                    isEn ? 'Cashier Operations' : 'ផ្នែកគិតប្រាក់',
                    icon: Icons.point_of_sale_rounded),
                _buildMenuItem(
                  icon: Icons.point_of_sale_rounded,
                  iconColor: AppColors.primary,
                  title: 'POS Terminal',
                  subtitle: isEn
                      ? 'Scan barcode, Pay, KHQR'
                      : 'ស្កេនបាកូដ, គិតប្រាក់, KHQR',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PosScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.khqrBakongRed,
                  title: isEn ? 'Shift Drawer' : 'វេនការងារ',
                  subtitle: isEn
                      ? 'Open/Close shift, cash count'
                      : 'បើក/បិទវេន, រាប់សាច់ប្រាក់',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ShiftScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.success,
                  title: isEn ? 'Sales Invoices' : 'វិក្កយបត្រលក់',
                  subtitle: isEn
                      ? 'View & reprint receipts'
                      : 'មើលវិក្កយបត្រ & បោះពុម្ពឡើងវិញ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const InvoiceScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.people_alt_outlined,
                  iconColor: Colors.pink,
                  title:
                      isEn ? 'Customer Loyalty' : 'អតិថិជន',
                  subtitle: isEn
                      ? 'Phone search & earn points'
                      : 'ស្វែងរកតាមលេខទូរស័ព្ទ & សន្សំពិន្ទុ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomerScreen()));
                  },
                ),

                const SizedBox(height: 6),

                // SECTION 2: STOCK CONTROLLER OPERATIONS
                _buildSectionHeader(
                    isEn
                        ? 'Stock & Inventory'
                        : 'ផ្នែកគ្រប់គ្រងស្តុក',
                    icon: Icons.warehouse_rounded),
                _buildMenuItem(
                  icon: Icons.warehouse_outlined,
                  iconColor: AppColors.warning,
                  title: isEn
                      ? 'Stock & Expiry'
                      : 'ស្តុក & ផុតកំណត់',
                  subtitle: isEn
                      ? 'Low stock alert & restock'
                      : 'ប្រកាសអាសន្នជិតអស់ & បញ្ចូលស្តុក',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StockScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.assessment_outlined,
                  iconColor: const Color(0xFF0F766E),
                  title: isEn
                      ? 'Inventory Report'
                      : 'របាយការណ៍ស្តុកទំនិញ',
                  subtitle: isEn
                      ? 'Valuation, low stock, print & export'
                      : 'តម្លៃស្តុកសរុប, ជិតអស់, បោះពុម្ព & CSV',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const InventoryReportScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  iconColor: AppColors.info,
                  title: isEn
                      ? 'Products & Barcode'
                      : 'ទំនិញ',
                  subtitle: isEn
                      ? 'Create products, barcodes & prices'
                      : 'បង្កើតទំនិញថ្មី, កំណត់បាកូដ & តម្លៃ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProductScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.category_outlined,
                  iconColor: Colors.purple,
                  title: isEn ? 'Categories' : 'ប្រភេទទំនិញ',
                  subtitle: isEn
                      ? 'Beverages, snacks, grocery...'
                      : 'ភេសជ្ជៈ, នំចំណី, អាហារកំប៉ុង...',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CategoryScreen()));
                  },
                ),

                const SizedBox(height: 6),

                // SECTION 3: MANAGEMENT & SETTINGS
                _buildSectionHeader(
                    isEn
                        ? 'Management & Settings'
                        : 'គ្រប់គ្រង & ប្រព័ន្ធ',
                    icon: Icons.tune_rounded),
                if (isAdmin)
                  _buildMenuItem(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: isEn
                        ? 'User Management'
                        : 'គ្រប់គ្រងអ្នកប្រើប្រាស់',
                    subtitle: isEn
                        ? 'Add, edit, delete staff & roles'
                        : 'បន្ថែម, កែប្រែ, លុបគណនីបុគ្គលិក',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const UserManagementScreen()));
                    },
                  ),
                _buildMenuItem(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Colors.indigo,
                  title: isEn ? 'Analytics & Reports' : 'របាយការណ៍',
                  subtitle: isEn
                      ? 'Revenue, expense & profit'
                      : 'ចំណូល, ចំណាយ, និងប្រាក់ចំណេញ',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportScreen()));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.textSecondary,
                  title: isEn ? 'Mart Settings' : 'ការកំណត់',
                  subtitle: isEn
                      ? 'Exchange rate, store info, KHQR'
                      : 'អត្រាប្តូរប្រាក់, ឈ្មោះម៉ាត, KHQR',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingScreen()));
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.danger, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'Logout System'
                                : 'ចាកចេញពីប្រព័ន្ធ',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.danger, size: 13),
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
            color: iconColor.withValues(alpha: 0.12),
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
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: Colors.grey.shade400),
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
