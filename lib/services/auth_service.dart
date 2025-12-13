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

  Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ✅ NEW: Update User Details
  Future<UserResponse> updateUser({String? email, String? password, String? name}) async {
    final attributes = UserAttributes(
      email: email,
      password: password,
      // We store 'name' in user_metadata since Supabase auth doesn't have a 'name' column
      data: name != null ? {'full_name': name} : null,
    );
    return await _supabase.auth.updateUser(attributes);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}