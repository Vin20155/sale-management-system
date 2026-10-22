import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final MartService _martService = MartService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _users = [];
  String _selectedRoleFilter = 'all';
  String? _currentUserEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppLanguage.languageNotifier.addListener(_onLanguageChanged);
    _loadCurrentUserInfo();
    _loadUsers();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppLanguage.languageNotifier.removeListener(_onLanguageChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserInfo() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = sp.getString('EMAIL') ?? 'admin@gmail.com';
    });
  }

  void _loadUsers() {
    setState(() => _isLoading = true);
    final list = _martService.getUsers(
      search: _searchController.text.trim(),
      roleFilter: _selectedRoleFilter == 'all' ? null : _selectedRoleFilter,
    );
    setState(() {
      _users = list;
      _isLoading = false;
    });
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.indigo;
      case 'stock_controller':
        return AppColors.secondary;
      case 'cashier':
      default:
        return AppColors.primary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'stock_controller':
        return Icons.warehouse_rounded;
      case 'cashier':
      default:
        return Icons.point_of_sale_rounded;
    }
  }

  String _getRoleLabel(String role) {
    final bool isEn = AppLanguage.isEnglish;
    switch (role) {
      case 'admin':
        return isEn ? 'Admin' : 'អ្នកគ្រប់គ្រង (Admin)';
      case 'stock_controller':
        return isEn ? 'Stock Controller' : 'គ្រប់គ្រងស្តុក (Stock)';
      case 'cashier':
      default:
        return isEn ? 'Cashier' : 'បេឡាករ (Cashier)';
    }
  }

  Future<void> _showAddEditUserDialog({UserModel? user}) async {
    final bool isEdit = user != null;
    final bool isEn = AppLanguage.isEnglish;

    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final passCtrl = TextEditingController(text: '123456');

    String selectedRole = user?.role ?? 'cashier';
    bool isActive = user?.isActive ?? true;
    bool isPasswordVisible = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getRoleColor(selectedRole).withOpacity(0.15),
                child: Icon(_getRoleIcon(selectedRole), color: _getRoleColor(selectedRole), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEdit
                      ? (isEn ? 'Edit User Account' : 'កែប្រែព័ត៌មានអ្នកប្រើប្រាស់')
                      : (isEn ? 'Add New User' : 'បង្កើតគណនីអ្នកប្រើប្រាស់ថ្មី'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full name
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Full Name *' : 'ឈ្មោះពេញ (Full Name) *',
                      hintText: 'e.g. John Doe / សុខ ចាន់',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Email Address *' : 'អ៊ីមែល (Email) *',
                      hintText: 'username@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Phone Number' : 'លេខទូរស័ព្ទ (Phone Number)',
                      hintText: '012 345 678',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role selector
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: isEn ? 'Assign Role *' : 'តួនាទី (Role) *',
                      prefixIcon: Icon(
                        _getRoleIcon(selectedRole),
                        color: _getRoleColor(selectedRole),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.point_of_sale_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEn ? 'Cashier' : 'បេឡាករ (Cashier)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'stock_controller',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warehouse_rounded, color: AppColors.secondary, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEn ? 'Stock Controller' : 'គ្រប់គ្រងស្តុក (Stock)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: Colors.indigo, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isEn ? 'Administrator' : 'អ្នកគ្រប់គ្រង (Admin)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password field (only for new user or optional reset)
                  if (!isEdit) ...[
                    TextField(
                      controller: passCtrl,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: isEn ? 'Default Password' : 'ពាក្យសម្ងាត់ដំបូង',
                        hintText: '123456',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                          ),
                          onPressed: () {
                            setDialogState(() => isPasswordVisible = !isPasswordVisible);
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Status switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Account Status:' : 'ស្ថានភាពគណនី:',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            isActive ? (isEn ? 'Active' : 'សកម្ម') : (isEn ? 'Inactive' : 'អសកម្ម'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeColor: AppColors.success,
                            onChanged: (val) {
                              setDialogState(() => isActive = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(isEn ? 'Cancel' : 'បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getRoleColor(selectedRole),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final pass = passCtrl.text.trim();

                if (name.isEmpty) {
                  EasyLoading.showToast(isEn ? 'Please enter user name' : 'សូមបញ្ចូលឈ្មោះអ្នកប្រើប្រាស់');
                  return;
                }
                if (email.isEmpty || !email.contains('@')) {
                  EasyLoading.showToast(isEn ? 'Please enter a valid email' : 'សូមបញ្ចូលអ៊ីមែលឱ្យបានត្រឹមត្រូវ');
                  return;
                }

                Navigator.pop(dialogCtx);

                if (isEdit) {
                  final ok = await _martService.updateUser(
                    id: user.id,
                    name: name,
                    email: email,
                    role: selectedRole,
                    phone: phone,
                    isActive: isActive,
                  );
                  if (ok) {
                    EasyLoading.showSuccess(isEn ? 'User updated successfully!' : 'បានកែប្រែអ្នកប្រើប្រាស់ជោគជ័យ!');
                    _loadUsers();
                  } else {
                    EasyLoading.showError(isEn ? 'Email already used by another user' : 'អ៊ីមែលនេះមានរួចហើយ!');
                  }
                } else {
                  final ok = await _martService.addUser(
                    name: name,
                    email: email,
                    role: selectedRole,
                    phone: phone,
                    password: pass,
                  );
                  if (ok) {
                    EasyLoading.showSuccess(isEn ? 'User created successfully!' : 'បានបង្កើតអ្នកប្រើប្រាស់ជោគជ័យ!');
                    _loadUsers();
                  } else {
                    EasyLoading.showError(isEn ? 'Email already exists' : 'អ៊ីមែលនេះមានក្នុងប្រព័ន្ធរួចហើយ!');
                  }
                }
              },
              child: Text(isEdit ? (isEn ? 'Save Changes' : 'រក្សាទុក') : (isEn ? 'Create User' : 'បង្កើត')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final bool isEn = AppLanguage.isEnglish;

    // Safety: Prevent deleting self
    if (_currentUserEmail != null && user.email.toLowerCase() == _currentUserEmail!.toLowerCase()) {
      EasyLoading.showInfo(
        isEn
            ? 'Cannot delete your own active Admin account!'
            : 'មិនអាចលុបគណនី Admin ដែលកំពុង Login ប្រើប្រាស់បានទេ!',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEn ? 'Delete User' : 'បញ្ជាក់ការលុប (Delete User)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Are you sure you want to delete user "${user.name}" (${user.email})? This action cannot be undone.'
              : 'តើអ្នកពិតជាចង់លុបអ្នកប្រើប្រាស់ "${user.name}" (${user.email}) មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់ក្រោយបានទេ។',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEn ? 'Delete' : 'លុបចេញ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _martService.deleteUser(user.id);
      if (ok) {
        EasyLoading.showSuccess(isEn ? 'User deleted successfully!' : 'បានលុបអ្នកប្រើប្រាស់ជោគជ័យ!');
        _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLanguage.isEnglish;

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'User & Staff Management' : 'គ្រប់គ្រងអ្នកប្រើប្រាស់ (Users)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              isEn ? 'Administrator Access Only' : 'សិទ្ធិ: អ្នកគ្រប់គ្រងទូទៅ (Admin Only)',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isEn ? 'Add User' : 'បន្ថែមអ្នកប្រើប្រាស់ថ្មី',
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            onPressed: () => _showAddEditUserDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          isEn ? 'Add User' : 'បន្ថែមអ្នកប្រើប្រាស់',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddEditUserDialog(),
      ),
      body: Column(
        children: [
          // ── SEARCH & FILTER HEADER ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search box
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadUsers(),
                  decoration: InputDecoration(
                    hintText: isEn ? 'Search by name, email, or phone...' : 'ស្វែងរកតាមឈ្មោះ, អ៊ីមែល, ឬលេខទូរស័ព្ទ...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.indigo),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: isEn ? 'All Users (${_martService.users.length})' : 'ទាំងអស់ (${_martService.users.length})',
                        filterKey: 'all',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isEn ? 'Admin' : 'អ្នកគ្រប់គ្រង (Admin)',
                        filterKey: 'admin',
                        accentColor: Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isEn ? 'Stock' : 'ស្តុក (Stock)',
                        filterKey: 'stock_controller',
                        accentColor: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: isEn ? 'Cashier' : 'បេឡាករ (Cashier)',
                        filterKey: 'cashier',
                        accentColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── USER LIST ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              isEn ? 'No users found matching query' : 'មិនមានអ្នកប្រើប្រាស់ដែលត្រូវនឹងលក្ខខណ្ឌទេ',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final roleColor = _getRoleColor(user.role);
                          final roleIcon = _getRoleIcon(user.role);
                          final isSelf = _currentUserEmail != null &&
                              user.email.toLowerCase() == _currentUserEmail!.toLowerCase();

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: roleColor.withOpacity(0.5), width: 1.5),
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: roleColor.withOpacity(0.12),
                                      child: Icon(roleIcon, color: roleColor, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // User Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                  color: AppColors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelf) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.indigo.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isEn ? 'YOU' : 'អ្នក',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.indigo,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.email_outlined, size: 12, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                user.email,
                                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (user.phone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.phone,
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // Role Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(roleIcon, size: 10, color: roleColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getRoleLabel(user.role),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: roleColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Status Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: user.isActive
                                                    ? AppColors.success.withOpacity(0.12)
                                                    : Colors.grey.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                user.isActive
                                                    ? (isEn ? 'Active' : 'សកម្ម')
                                                    : (isEn ? 'Inactive' : 'អសកម្ម'),
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: user.isActive ? AppColors.success : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 19, color: Colors.blueGrey),
                                        tooltip: isEn ? 'Edit User' : 'កែប្រែ',
                                        onPressed: () => _showAddEditUserDialog(user: user),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 19,
                                          color: isSelf ? Colors.grey.shade300 : AppColors.danger,
                                        ),
                                        tooltip: isEn ? 'Delete User' : 'លុប',
                                        onPressed: isSelf ? null : () => _confirmDeleteUser(user),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    Color? accentColor,
  }) {
    final bool isSelected = _selectedRoleFilter == filterKey;
    final color = accentColor ?? Colors.indigo;

    return InkWell(
      onTap: () {
        setState(() => _selectedRoleFilter = filterKey);
        _loadUsers();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
