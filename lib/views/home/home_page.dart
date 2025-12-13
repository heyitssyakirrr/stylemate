// lib/views/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stylemate/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../controllers/auth_controller.dart';
import '../../utils/routes.dart';
import '../../widgets/bottom_nav.dart';
import '../../controllers/weather_controller.dart'; 
import '../../services/weather_service.dart'; 
import '../../models/weather.dart';
import '../../models/clothing_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = AuthController();
  final WeatherController _weatherController = WeatherController();
  
  // ✅ NEW: Controller specifically for the outfit grid scrollbar
  final ScrollController _outfitScrollController = ScrollController();

  int selectedIndex = 0;
  List<ClothingItem>? _todaysOutfitItems;
  bool _isLoadingOutfit = true;

  @override
  void initState() {
    super.initState();
    _fetchTodaysLook(); 
  }

  Future<void> _fetchTodaysLook() async {
    final userId = _authController.currentUser?.id;
    if (userId == null) return;

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final response = await Supabase.instance.client
          .from('clothing_items')
          .select()
          .eq('user_id', userId)
          .gte('last_worn_date', todayStart);

      if (mounted) {
        setState(() {
          if ((response as List).isNotEmpty) {
            _todaysOutfitItems = (response as List)
                .map((data) => ClothingItem.fromJson(data))
                .toList();
          } else {
            _todaysOutfitItems = null;
          }
          _isLoadingOutfit = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching featured outfit: $e");
      if (mounted) setState(() => _isLoadingOutfit = false);
    }
  }

  @override
  void dispose() {
    _weatherController.dispose();
    _outfitScrollController.dispose(); // ✅ Dispose the scroll controller
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
        onRefresh: () async {
          _weatherController.fetchWeather();
          await _fetchTodaysLook(); 
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(username),
              const SizedBox(height: 28),

              _buildQuickActionsGrid(),
              const SizedBox(height: 32),
              
              _buildWeatherCard(), 
              const SizedBox(height: 32),

              Text("Today’s Featured Outfit",
                  style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),

              _buildDailyRecommendationCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String username) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hi, $username 👋",
          style: GoogleFonts.poppins(
            fontSize: 30,
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
  
  Widget _buildDailyRecommendationCard() {
    if (_isLoadingOutfit) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todaysOutfitItems == null || _todaysOutfitItems!.isEmpty) {
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

    // FEATURED DISPLAY
    final int itemCount = _todaysOutfitItems!.length;
    final double aspectRatio = itemCount > 2 ? 1.3 : 0.9; 

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
          Container(
            height: 250, 
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // ✅ FIXED: Added controller to Scrollbar and GridView to fix the error
              child: Scrollbar(
                thumbVisibility: true,
                controller: _outfitScrollController, // Linked here
                child: GridView.builder(
                  controller: _outfitScrollController, // Linked here
                  padding: const EdgeInsets.only(right: 6), 
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: itemCount <= 1 ? 1 : 2, 
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        _todaysOutfitItems![index].imageUrl,
                        fit: BoxFit.contain, 
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 6),
                    Text("Logged for Today", 
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Your Style Selection", 
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_todaysOutfitItems!.map((i) => i.articleType).join(' • '), 
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}