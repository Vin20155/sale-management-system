part of 'mart_service.dart';

extension SettingsService on MartService {
  // ==========================================
  // SETTINGS
  // ==========================================
  MartSettingModel getSettings() => _settings;

  Future<void> updateSettings(MartSettingModel settings) async {
    _settings = settings;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('APP_LANGUAGE', settings.language);
      await sp.setString('MART_NAME_KH', settings.martNameKh);
      await sp.setString('MART_NAME_EN', settings.martNameEn);
      await sp.setString('MART_BRANCH', settings.branchName);
      await sp.setString('BAKONG_ACCOUNT', settings.bakongAccountId);
      await sp.setDouble('EXCHANGE_RATE', settings.exchangeRate);
    } catch (_) {}
  }
}
