// lib/views/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stylemate/utils/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/routes.dart';
import '../../widgets/bottom_nav.dart';
// --- NEW IMPORTS ---
import '../../controllers/weather_controller.dart'; 
import '../../services/weather_service.dart'; // Used for icon URL
import '../../models/weather.dart';
// -------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  final WeatherController _weatherController = WeatherController(); // Initialize controller
  int selectedIndex = 0;

  // Placeholder for the generated outfit.
  // In a real app with Provider, this would update automatically when you generate an outfit.
  // For now, it stays null to trigger the "Call to Action" state.
  final Map<String, dynamic>? _todaysOutfit = null;

  @override
  void dispose() {
    _weatherController.dispose(); // Dispose controller to prevent memory leaks
    super.dispose();
  }

  void onNavTap(int index) {
    setState(() => selectedIndex = index);

    switch (index) {
      case 0: break;
      case 1: Navigator.pushNamed(context, Routes.closet); break;
      case 2: Navigator.pushNamed(context, Routes.outfit); break;
      case 3: Navigator.pushNamed(context, Routes.analytics); break;
      case 4: Navigator.pushNamed(context, Routes.profile); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser;
    final username = user?.email?.split('@')[0] ?? "User";

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        elevation: 0,
        backgroundColor: AppConstants.background,
        title: Text("AURA FIT", 
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppConstants.primaryAccent,
          )),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: selectedIndex,
        onTap: onNavTap,
      ),
      body: RefreshIndicator(
        onRefresh: _weatherController.fetchWeather, // Pull-to-refresh weather
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(username),
              const SizedBox(height: 28),

              _buildQuickActionsGrid(),
              const SizedBox(height: 32),
              
              // --- WEATHER WIDGET (Your existing code preserved) ---
              _buildWeatherCard(), 
              const SizedBox(height: 32),

              Text("Today’s Featured Outfit",
                  style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              // --- NEW: Dynamic Recommendation Card ---
              _buildDailyRecommendationCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ... (unchanged _buildWelcomeHeader and _buildQuickActionsGrid methods)

  Widget _buildWelcomeHeader(String username) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hi, $username 👋",
          style: GoogleFonts.poppins(
            fontSize: 30, // Larger, more stylish greeting
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          )),
        const SizedBox(height: 4),
        Text("Your style journey starts now.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          )),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Access",
            style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _quickActionButton(
              icon: Icons.add_a_photo_outlined, 
              label: "Upload Item", 
              onTap: () => Navigator.pushNamed(context, Routes.upload),
            ),
            _quickActionButton(
              icon: Icons.style_outlined, 
              label: "Get Outfit", 
              onTap: () => Navigator.pushNamed(context, Routes.outfit),
            ),
            _quickActionButton(
              icon: Icons.checkroom_outlined, 
              label: "View Closet", 
              onTap: () => Navigator.pushNamed(context, Routes.closet),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _quickActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppConstants.cardShadow],
            ),
            child: Icon(icon, size: 32, color: AppConstants.primaryAccent),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }


  // --- WEATHER CARD (Unchanged logic) ---
  Widget _buildWeatherCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _weatherController.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return Center(
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.kRadius),
                boxShadow: [AppConstants.cardShadow],
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final error = _weatherController.errorMessage.value;
        if (error != null) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.kRadius),
              border: Border.all(color: Colors.red),
            ),
            child: Text("Error: $error", style: GoogleFonts.poppins(color: Colors.red)),
          );
        }

        final Weather? weatherData = _weatherController.weather.value;
        if (weatherData == null) {
          return const SizedBox.shrink(); 
        }
        
        final temp = weatherData.temperature.round();
        final description = weatherData.description;
        final iconUrl = WeatherService().getWeatherIconUrl(weatherData.iconCode);

        return Container(
          padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryAccent, AppConstants.primaryAccent.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
            boxShadow: [AppConstants.cardShadow],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Weather",
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    )),
                  const SizedBox(height: 8),
                  Text("$temp°C", 
                    style: GoogleFonts.poppins(
                      fontSize: 56, 
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    )),
                  const SizedBox(height: 4),
                  Text(description.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '), 
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    )),
                ],
              ),
              Image.network(
                iconUrl,
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.cloud_queue, size: 60, color: Colors.white);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // --- NEW: Dynamic Recommendation Card ---
  // Replaces the old static image/text with the "Call to Action" design
  Widget _buildDailyRecommendationCard() {
    // STATE 1: No Outfit Generated Yet (Call To Action)
    if (_todaysOutfit == null) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, Routes.outfit),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryAccent, AppConstants.primaryAccent.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Discover Your Look",
                      style: GoogleFonts.poppins(
                        fontSize: 18, 
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                    const SizedBox(height: 6),
                    Text("Tap to let AI style you based on your closet.",
                      style: GoogleFonts.poppins(
                        fontSize: 13, 
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      )),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
            ],
          ),
        ),
      );
    }

    // STATE 2: Outfit Generated (Featured Display)
    // This layout is ready for when you connect the real data
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Preview Section
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.checkroom, size: 64, color: Colors.black12),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text("92% Match", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Casual Summer Fit", // Placeholder
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text("Blue T-Shirt • Beige Chinos • White Sneakers", // Placeholder
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}