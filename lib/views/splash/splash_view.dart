// lib/views/splash/splash_view.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';

class SplashView extends StatelessWidget {
  final bool isReady;
  const SplashView({super.key, this.isReady = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo card
              Container(
                width: size.width * 0.52,
                height: size.width * 0.52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.kRadius * 1.5), // Larger radius for flair
                  boxShadow: [AppConstants.cardShadow],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.kPadding * 2), // More space around logo
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              
              // App name
              Text(
                'Aura Fit',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Fashion Assistant',
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              
              // Loading / progress indicator with subtle message
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isReady ? 1 : 0.7,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppConstants.primaryAccent),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            isReady ? 'Almost ready...' : 'Initializing style AI',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Minimal, sustainable wardrobe suggestions.',
                      style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Small hint / accessibility: show skip button for dev fast navigation
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
                child: Text('Skip (dev)', style: TextStyle(color: Colors.black38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}