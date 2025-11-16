// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Lazy getter ensures Supabase is initialized before accessing
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // --- FIX APPLIED ---
  Future<void> resetPasswordForEmail(String email) async {
    // This calls the Supabase API to send the reset link to the provided email.
    await _supabase.auth.resetPasswordForEmail(email);
  }
  // -------------------

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}