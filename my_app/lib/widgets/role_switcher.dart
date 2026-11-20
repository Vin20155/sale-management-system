import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/screens/auth/login_screen.dart';
import 'package:my_app/services/mart_service.dart';

class RoleSwitcher {
  static final MartService _martService = MartService();

  static Future<void> confirmSignOut(BuildContext context) async {
    final isEn = AppLanguage.isEnglish;
    final isSignOut = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(
              isEn ? 'Sign Out' : 'ចាកចេញពីប្រព័ន្ធ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Are you sure you want to sign out of this account?'
              : 'តើអ្នកពិតជាចង់ចាកចេញពីគណនីនេះមែនទេ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(isEn ? 'Cancel' : 'បោះបង់'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(isEn ? 'Sign Out' : 'ចាកចេញ'),
          ),
        ],
      ),
    );

    if (isSignOut == true) {
      EasyLoading.show(status: isEn ? 'Signing out...' : 'កំពុងចាកចេញ...');
      await _martService.logout();
      EasyLoading.dismiss();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      EasyLoading.showSuccess(isEn ? 'Signed out successfully!' : 'បានចាកចេញដោយជោគជ័យ!');
    }
  }

  static void showSwitchRoleSheet(
    BuildContext context, {
    required String currentRole,
    required VoidCallback onRoleChanged,
  }) {
    final isEn = AppLanguage.isEnglish;
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
                  Text(
                    isEn ? 'Switch Role' : 'ជ្រើសរើសតួនាទី',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isEn
                    ? 'Select a role and enter account credentials:'
                    : 'សូមជ្រើសរើសតួនាទី ហើយបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់៖',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _buildRoleTile(
                context: context,
                bottomSheetCtx: bottomSheetCtx,
                currentRole: currentRole,
                targetRole: 'cashier',
                title: isEn ? 'Cashier' : 'បេឡាករ',
                subtitle: isEn
                    ? 'POS checkout, KHQR, open/close shifts'
                    : 'គិតប្រាក់ POS, KHQR, បើក/បិទវេន',
                color: AppColors.primary,
                icon: Icons.point_of_sale,
                onRoleChanged: onRoleChanged,
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                context: context,
                bottomSheetCtx: bottomSheetCtx,
                currentRole: currentRole,
                targetRole: 'stock_controller',
                title: isEn ? 'Stock Controller' : 'អ្នកគ្រប់គ្រងស្តុក',
                subtitle: isEn
                    ? 'Stock count, batches, expiry tracking'
                    : 'ពិនិត្យស្តុក, ផុតកំណត់, បញ្ចូលទំនិញ',
                color: AppColors.secondary,
                icon: Icons.warehouse,
                onRoleChanged: onRoleChanged,
              ),
              const SizedBox(height: 8),
              _buildRoleTile(
                context: context,
                bottomSheetCtx: bottomSheetCtx,
                currentRole: currentRole,
                targetRole: 'admin',
                title: isEn ? 'Admin' : 'អ្នកគ្រប់គ្រងទូទៅ',
                subtitle: isEn
                    ? 'Financial reports, settings & management'
                    : 'របាយការណ៍ហិរញ្ញវត្ថុ, គ្រប់គ្រងម៉ាត',
                color: Colors.indigo,
                icon: Icons.admin_panel_settings,
                onRoleChanged: onRoleChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRoleTile({
    required BuildContext context,
    required BuildContext bottomSheetCtx,
    required String currentRole,
    required String targetRole,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onRoleChanged,
  }) {
    final isSelected = currentRole == targetRole;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      tileColor: isSelected
          ? color.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.06),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () {
        Navigator.pop(bottomSheetCtx);
        final matched = _martService.users.cast<UserModel?>().firstWhere(
              (u) => u?.role == targetRole,
              orElse: () => null,
            );
        _promptPasswordAndSwitchRole(
          context,
          currentRole: currentRole,
          targetRole: targetRole,
          targetEmail: matched?.email ?? '',
          targetLabelKh: title,
          roleColor: color,
          roleIcon: icon,
          onRoleChanged: onRoleChanged,
        );
      },
    );
  }

  static Future<void> _promptPasswordAndSwitchRole(
    BuildContext context, {
    required String currentRole,
    required String targetRole,
    required String targetEmail,
    required String targetLabelKh,
    required Color roleColor,
    required IconData roleIcon,
    required VoidCallback onRoleChanged,
  }) async {
    final isEn = AppLanguage.isEnglish;
    if (currentRole == targetRole) {
      EasyLoading.showInfo(isEn ? 'You are already in this role' : 'អ្នកកំពុងស្ថិតនៅក្នុងតួនាទីនេះរួចហើយ');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Icon(roleIcon, color: roleColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEn ? 'Verify Password' : 'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn
                    ? 'Enter username or email and password to switch to:\n$targetLabelKh'
                    : 'សូមបញ្ចូលឈ្មោះគណនី ឬអ៊ីមែល និងពាក្យសម្ងាត់ដើម្បីប្តូរទៅកាន់៖\n$targetLabelKh',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: txtSwitchUsername,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isEn ? 'Username / Email' : 'ឈ្មោះគណនី ឬអ៊ីមែល',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txtSwitchPassword,
                obscureText: isObscured,
                decoration: InputDecoration(
                  labelText: isEn ? 'Password' : 'ពាក្យសម្ងាត់',
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
                      errorMessage = isEn ? 'Please enter username and password' : 'សូមបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់';
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(isEn ? 'Cancel' : 'បោះបង់'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final entered = txtSwitchPassword.text.trim();
                if (txtSwitchUsername.text.trim().isNotEmpty &&
                    entered.isNotEmpty) {
                  Navigator.pop(dialogCtx, true);
                } else {
                  setDialogState(() {
                    errorMessage = isEn ? 'Please enter username and password' : 'សូមបញ្ចូលឈ្មោះគណនី និងពាក្យសម្ងាត់';
                  });
                }
              },
              child: Text(isEn ? 'Confirm & Switch' : 'បញ្ជាក់ & ប្តូរ'),
            ),
          ],
        ),
      ),
    );

    final username = txtSwitchUsername.text;
    final password = txtSwitchPassword.text;
    txtSwitchUsername.dispose();
    txtSwitchPassword.dispose();

    if (confirmed == true) {
      final error = await _martService.authenticate(
        username: username,
        password: password,
        requiredRole: targetRole,
      );
      if (error != null) {
        EasyLoading.showError(error);
        return;
      }
      EasyLoading.showSuccess(isEn ? 'Switched to $targetLabelKh successfully' : 'បានចូលគណនី $targetLabelKh');
      onRoleChanged();
    }
  }
}

