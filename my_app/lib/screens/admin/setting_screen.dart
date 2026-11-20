import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/models/mart_models.dart';
import 'package:my_app/services/mart_service.dart';

import 'package:my_app/config/app_language.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final MartService _martService = MartService();
  late MartSettingModel _settings;

  final TextEditingController _nameKhCtrl = TextEditingController();
  final TextEditingController _nameEnCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _bakongCtrl = TextEditingController();
  final TextEditingController _apiCtrl = TextEditingController();

  String _selectedLanguage = 'km';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _settings = _martService.getSettings();
    _selectedLanguage = AppLanguage.current;
    _nameKhCtrl.text = _settings.martNameKh;
    _nameEnCtrl.text = _settings.martNameEn;
    _branchCtrl.text = _settings.branchName;
    _phoneCtrl.text = _settings.phone;
    _rateCtrl.text = _settings.exchangeRate.toStringAsFixed(0);
    _bakongCtrl.text = _settings.bakongAccountId;
    _apiCtrl.text = _martService.baseUrl;
  }

  Future<void> _changeLanguage(String lang) async {
    if (_selectedLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
      _settings.language = lang;
    });
    await AppLanguage.setLanguage(lang);
    EasyLoading.showSuccess(
      lang == 'km' ? 'បានប្តូរភាសាទៅជា៖ ភាសាខ្មែរ 🇰🇭' : 'Language switched to: English 🇺🇸',
    );
  }

  Future<void> _testApiConnection() async {
    setState(() => _isTesting = true);
    await _martService.setBaseUrl(_apiCtrl.text.trim());
    final ok = await _martService.testConnection();
    setState(() => _isTesting = false);

    if (ok) {
      EasyLoading.showSuccess(
        _selectedLanguage == 'km' ? 'ភ្ជាប់ទៅកាន់ Laravel API បានជោគជ័យ!' : 'Connected to Laravel API successfully!',
      );
    } else {
      EasyLoading.showInfo(
        _selectedLanguage == 'km'
            ? 'មិនអាចភ្ជាប់បានទេ - ប្រព័ន្ធដំណើរការរបៀប Offline Local Mode យ៉ាងរលូន!'
            : 'Could not connect - Running smoothly in Offline Local Mode!',
      );
    }
  }

  void _saveSettings() {
    _settings.language = _selectedLanguage;
    _settings.martNameKh = _nameKhCtrl.text.trim();
    _settings.martNameEn = _nameEnCtrl.text.trim();
    _settings.branchName = _branchCtrl.text.trim();
    _settings.phone = _phoneCtrl.text.trim();
    _settings.exchangeRate = double.tryParse(_rateCtrl.text) ?? 4100.0;
    _settings.bakongAccountId = _bakongCtrl.text.trim();

    _martService.updateSettings(_settings);
    _martService.setBaseUrl(_apiCtrl.text.trim());
    EasyLoading.showSuccess(
      _selectedLanguage == 'km' ? 'បានរក្សាទុកការកំណត់ជោគជ័យ!' : 'Settings saved successfully!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKh = _selectedLanguage == 'km';

    return Scaffold(
      backgroundColor: AppColors.bgmain,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isKh ? 'ការកំណត់ប្រព័ន្ធម៉ាត ' : 'Mart Settings',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── LANGUAGE SELECTION SECTION ──
            Row(
              children: [
                const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  isKh ? 'ជ្រើសរើសភាសា' 
                        : 'System Language',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildLanguageTile(
                      langCode: 'km',
                      flagEmoji: '🇰🇭',
                      title: 'ភាសាខ្មែរ (Khmer)',
                      subtitle: isKh ? 'ភាសាខ្មែរជាភាសាចម្បង' : 'Khmer as primary language',
                      isSelected: isKh,
                      onTap: () => _changeLanguage('km'),
                    ),
                    const SizedBox(height: 8),
                    _buildLanguageTile(
                      langCode: 'en',
                      flagEmoji: '🇺🇸',
                      title: 'English',
                      subtitle: isKh ? 'ភាសាអង់គ្លេសសម្រាប់ប្រតិបត្តិការ' : 'English for global operation',
                      isSelected: !isKh,
                      onTap: () => _changeLanguage('en'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mart Info Section
            Text(
              isKh ? 'ព័ត៌មានម៉ាត' : 'Store Profile',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameKhCtrl,
                      decoration: InputDecoration(
                        labelText: isKh ? 'ឈ្មោះម៉ាត' : 'Mart Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: isKh ? 'ឈ្មោះម៉ាត' : 'Mart Name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _branchCtrl,
                      decoration: InputDecoration(
                        labelText: isKh ? 'សាខា និងអាសយដ្ឋាន' : 'Branch & Address',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: isKh ? 'លេខទូរស័ព្ទទាក់ទង' : 'Phone Number',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Currency & Payment Section
            Text(
              isKh ? 'រូបិយប័ណ្ណ & ការទូទាត់' : 'Currency & Payment (KHQR)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isKh ? 'អត្រាប្តូរប្រាក់ (\$1 = ? ៛)' : 'Exchange Rate (\$1 = ? KHR)',
                        helperText: isKh ? 'អត្រាស្តង់ដារទូទៅនៅកម្ពុជា: 4,100 ៛ ឬ 4,120 ៛' : 'Standard rate: 4,100 KHR or 4,120 KHR',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.currency_exchange),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _bakongCtrl,
                      decoration: InputDecoration(
                        labelText: isKh ? 'គណនីបាគង KHQR Account ID' : 'Bakong KHQR Account ID',
                        helperText: 'e.g. lucky_express@aclb',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.qr_code, color: AppColors.khqrBakongRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Backend API Server connection
            Text(
              isKh ? 'តភ្ជាប់ Backend Server' : 'Laravel REST API Connection',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _apiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'API Base URL',
                        helperText: 'Android Emulator: http://10.0.2.2:8000/api\nWeb / Local: http://localhost:8000/api',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: _isTesting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.network_check),
                      label: Text(isKh ? 'តេស្តការតភ្ជាប់' : 'Test Connection'),
                      onPressed: _isTesting ? null : _testApiConnection,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSettings,
              child: Text(
                isKh ? 'រក្សាទុកការកំណត់' : 'Save Settings',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String langCode,
    required String flagEmoji,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Text(
                flagEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}