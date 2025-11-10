import 'dart:async';

class SplashController {
  // Simple controller that handles splash timing and navigation decision
  Future<void> initializeApp() async {
    // Insert initialization tasks here (load config, check auth, preload images)
    // We'll simulate a short startup task
    await Future.delayed(const Duration(milliseconds: 10500));
  }
}
