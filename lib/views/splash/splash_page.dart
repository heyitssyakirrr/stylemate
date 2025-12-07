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
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. Wait a moment for the animation to show (UI experience)
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // 2. Mark UI as ready (stops loading spinner if used)
    setState(() {
      _ready = true;
    });

    try {
      // 3. Check if a user session exists
      // We assume Supabase was initialized in main.dart
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        Navigator.pushReplacementNamed(context, Routes.auth);
      }
    } catch (e) {
      debugPrint("Session check error: $e");
      // If something is wrong (e.g. initialization failed in main.dart), 
      // fallback to the Login page so the user isn't stuck.
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplashView(isReady: _ready);
  }
}