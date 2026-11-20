import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/config/app_language.dart';
import 'package:my_app/screens/auth/app_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage.init();

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
  loadingConfig();
}

void loadingConfig() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = AppColors.white
    ..backgroundColor = Colors.green
    ..indicatorColor = AppColors.white
    ..textColor = AppColors.white
    ..maskColor = AppColors.primary
    ..userInteractions = true
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.languageNotifier,
      builder: (context, currentLang, _) {
        final bool isKh = currentLang == 'km';
        return MaterialApp(
          locale: Locale(currentLang),
          title: isKh
              ? 'ប្រព័ន្ធគ្រប់គ្រងការលក់នៅម៉ាត'
              : 'Mart Sales Management System',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
            scaffoldBackgroundColor: AppColors.bgmain,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            useMaterial3: true,
            fontFamilyFallback: const [
              'KhmerOS',
              'KhmerOSbattambang',
              'LeelawUI',
              'sans-serif',
            ],
          ),
          home: const AppAuth(),
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
