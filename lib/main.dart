import 'package:flutter/material.dart';
import 'package:stylemate/views/home/home_page.dart';
import 'utils/app_theme.dart';
import 'utils/routes.dart';
import 'views/splash/splash_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';

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
        // Add other routes like home, closet, etc.
      },
    );
  }
}
