import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stylemate/utils/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  int selectedIndex = 0;

  void onNavTap(int index) {
    setState(() => selectedIndex = index);

    switch (index) {
      case 0: break; // already home
      case 1: Navigator.pushNamed(context, "/closet"); break;
      case 2: Navigator.pushNamed(context, "/outfit"); break;
      case 3: Navigator.pushNamed(context, "/analytics"); break;
      case 4: Navigator.pushNamed(context, "/profile"); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final username = user?.email?.split('@')[0] ?? "User";

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("AURA FIT",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: selectedIndex,
        onTap: onNavTap,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi, $username 👋",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              )),
            const SizedBox(height: 8),
            Text("What will you wear today?",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black54,
              )),
            const SizedBox(height: 24),

            // Weather Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 38, color: AppConstants.primaryAccent),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Weather Today",
                        style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                      Text("28°C · Mostly Sunny",
                        style: GoogleFonts.poppins(color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickActionButton(icon: Icons.add_a_photo_outlined, label: "Upload", onTap: () {}),
                _quickActionButton(icon: Icons.style_outlined, label: "Get Outfit", onTap: () {}),
                _quickActionButton(icon: Icons.checkroom_outlined, label: "Closet", onTap: () {}),
              ],
            ),

            const SizedBox(height: 32),

            Text("Today’s Recommendation",
                style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Recommendation Card
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text("AI outfit suggestion\nwill appear here",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14,
                  )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Icon(icon, size: 28, color: AppConstants.primaryAccent),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }
}
