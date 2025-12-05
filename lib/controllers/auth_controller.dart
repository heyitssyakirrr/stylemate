// lib/controllers/auth_controller.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<String?> signUp(String email, String password) async {
    try {
      final response = await _authService.signUp(email, password);
      if (response.user == null) {
        return "Registration failed. Try again.";
      }
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _authService.signIn(email, password);
      if (response.session == null) {
        return "Invalid email or password.";
      }
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
  
  // --- NEW: Forgot Password Logic ---
  Future<String?> sendPasswordResetLink(String email) async {
    try {
      await _authService.resetPasswordForEmail(email);
      return null; // success
    } on AuthException catch (e) {
      // Catch specific Supabase errors, though often it returns a generic message for security
      return e.message; 
    } catch (e) {
      return "An unknown error occurred. Please try again.";
    }
  }
  // ------------------------------------

  Future<void> signOut() async {
    await _authService.signOut();
  }

  User? get currentUser => _authService.currentUser;
}