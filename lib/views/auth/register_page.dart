// lib/views/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/auth_controller.dart';
import '../../utils/constants.dart'; // <--- NEW IMPORT
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authController.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Verification Email Sent", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: const Text(
            "Please check your inbox and verify your email before logging in."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              ),
              child: Text("OK", style: TextStyle(color: AppConstants.primaryAccent)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.kPadding * 1.5), // 24.0
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Logo/Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  "assets/logo.png",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // --- Heading ---
              Text(
                "Create your Aura Fit account",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 28, 
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryAccent,
                  ),
              ),
              const SizedBox(height: 32),

              // --- Card Container (Stylized) ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.kRadius),
                  boxShadow: [AppConstants.cardShadow],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : Text(
                                "Create Account",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      ),
                      child: Text(
                        "Already have an account? Login",
                        style: GoogleFonts.poppins(
                          color: AppConstants.primaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}