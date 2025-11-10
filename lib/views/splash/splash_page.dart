import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splash_view.dart';
import '../../utils/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Ensure Flutter binding initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Supabase safely
      await Supabase.initialize(
        url: 'https://zthhqhxdxgodzoczfxej.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0aGhxaHhkeGdvZHpvY3pmeGVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNzQyNjksImV4cCI6MjA3Nzg1MDI2OX0.zuilqdxkNXzhGNBwZqg9C_hvBmcQcVgL4PgdP8vRu58',
      );

      // Simulate any other initialization (controllers, settings, etc.)
      await Future.delayed(const Duration(milliseconds: 800));

      // Mark ready for SplashView animation
      if (!mounted) return;
      setState(() {
        _ready = true;
      });

      // Wait a bit to show animation
      await Future.delayed(const Duration(milliseconds: 600));

      // Navigate to login or home depending on session
      final user = Supabase.instance.client.auth.currentUser;
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        Navigator.pushReplacementNamed(context, Routes.auth);
      }
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
      // In case of error, still go to auth
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashView(isReady: _ready);
  }
}
