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
  
  Future<String?> sendPasswordResetLink(String email) async {
    try {
      await _authService.resetPasswordForEmail(email);
      return null; // success
    } on AuthException catch (e) {
      return e.message; 
    } catch (e) {
      return "An unknown error occurred. Please try again.";
    }
  }

  // ✅ NEW: Update Profile Logic
  Future<String?> updateProfile({String? email, String? password, String? name}) async {
    try {
      // Only pass fields that actually have text
      await _authService.updateUser(
        email: (email != null && email.isNotEmpty) ? email : null,
        password: (password != null && password.isNotEmpty) ? password : null,
        name: (name != null && name.isNotEmpty) ? name : null,
      );
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Failed to update profile: $e";
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  User? get currentUser => _authService.currentUser;
}