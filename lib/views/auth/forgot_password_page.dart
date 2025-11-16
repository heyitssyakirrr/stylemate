// lib/views/auth/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/auth_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthController _controller = AuthController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message; // Used for success or error message

  Future<void> _sendLink() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final error = await _controller.sendPasswordResetLink(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        // Success message is displayed even if the email doesn't exist (for security)
        setState(() => _message = "If the account exists, a password reset link has been sent to your email.");
      } else {
        setState(() => _message = "Error sending link: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Forgot Password",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Heading ---
              Text(
                "Reset Your Password",
                style: GoogleFonts.poppins(
                    fontSize: 24, 
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryAccent,
                  ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Enter your email address to receive a password reset link.",
                style: GoogleFonts.poppins(
                    fontSize: 16, 
                    color: Colors.black54,
                  ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- Card Container ---
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
                    const SizedBox(height: 20),

                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          _message!,
                          style: GoogleFonts.poppins(
                            color: _message!.startsWith("Error") ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Send Link Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendLink,
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
                                "Send Reset Link",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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