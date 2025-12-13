import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stylemate/views/home/home_page.dart';
import 'package:stylemate/views/closet/closet_page.dart';
import 'package:stylemate/views/outfits/outfit_page.dart'; // Corrected import
import 'package:stylemate/views/profile/profile_page.dart';
import 'package:stylemate/views/upload/upload_page.dart';
import 'package:stylemate/views/analytics/analytics_page.dart';
import 'utils/app_theme.dart';
import 'utils/routes.dart';
import 'views/splash/splash_page.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once here
  try {
    await Supabase.initialize(
      url: 'https://ozvwxveyxyxxwpxtoesi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96dnd4dmV5eHl4eHdweHRvZXNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzQ0NzgsImV4cCI6MjA3Nzg1MDQ3OH0.e4FjpGU8jw3tO0mqb47CYAAiZgp5NP-fPgsZol96o64',
    ).timeout(const Duration(seconds: 5)); // Lower timeout to 5s to fail faster
  } catch (e) {
    debugPrint("Supabase init failed (Offline mode?): $e");
  }

  // ✅ ADD THIS LINE: Initialize Notifications
  await NotificationService().init();

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
        Routes.closet: (context) => const ClosetPage(),
        Routes.outfit: (context) => const OutfitPage(),
        Routes.upload: (context) => const UploadClothingPage(),
        Routes.profile: (context) => const ProfilePage(),
        Routes.analytics: (context) => const AnalyticsPage(),
      },
    );
  }
}