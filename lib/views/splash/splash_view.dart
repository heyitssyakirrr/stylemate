import 'package:flutter/material.dart';
import '../../utils/constants.dart';
//import 'package:flutter_svg/flutter_svg.dart';

class SplashView extends StatelessWidget {
  final bool isReady;
  const SplashView({super.key, this.isReady = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo card
                Container(
                  width: size.width * 0.52,
                  height: size.width * 0.52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                // App name
                Text(
                  'Aura Fit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Smart Fashion Assistant',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 30),
                // Loading / progress indicator with subtle message
                AnimatedOpacity(
                  duration: Duration(milliseconds: 400),
                  opacity: isReady ? 1 : 0.9,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(AppConstants.primaryAccent),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              isReady ? 'Almost ready...' : 'Loading style AI',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Minimal, sustainable wardrobe suggestions.',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                // Small hint / accessibility: show skip button for dev fast navigation
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
                  child: Text('Skip (dev)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
