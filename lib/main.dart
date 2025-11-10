// lib/main.dart

import 'package:flutter/material.dart';
import 'package:stylemate/views/home/home_page.dart';
import 'utils/app_theme.dart';
import 'utils/routes.dart';
import 'views/splash/splash_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'views/upload/upload_page.dart'; // <--- NEW IMPORT
import 'views/closet/closet_page.dart'; // <--- NEW IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StyleMateApp());
}

class StyleMateApp extends StatelessWidget {
  const StyleMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashPage(),
        Routes.auth: (context) => const LoginPage(),
        Routes.register: (context) => const RegisterPage(),
        Routes.home: (context) => const HomeScreen(),
        Routes.upload: (context) => const UploadClothingPage(), // <--- MAPPED
        Routes.closet: (context) => const ClosetPage(), // <--- MAPPED
        // Outfit, Analytics, Profile will be mapped later
      },
      // Note: ItemDetailsPage is navigated to using MaterialPageRoute since it requires an argument.
    );
  }
}