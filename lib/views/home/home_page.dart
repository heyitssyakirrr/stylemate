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
  
  // We keep the scroll controller for versatility, though standard list view manages well
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

      // Fetch items marked as worn today
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
    _outfitScrollController.dispose(); 
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
    return Scaffold(
      backgroundColor: AppConstants.background,
      // Removed the standard AppBar to create a custom, more spacious header
      body: RefreshIndicator(
        color: AppConstants.primaryAccent,
        backgroundColor: Colors.white,
        onRefresh: () async {
          _weatherController.fetchWeather();
          await _fetchTodaysLook(); 
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: AppConstants.kPadding,
            right: AppConstants.kPadding,
            bottom: 100, // Space for BottomNav
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(),
              const SizedBox(height: 32),
              
              _buildWeatherCard(), 
              const SizedBox(height: 32),

              _buildSectionTitle("Quick Actions"),
              const SizedBox(height: 16),
              _buildQuickActionsModern(),
              
              const SizedBox(height: 36),

              _buildSectionTitle("Today's Look"),
              const SizedBox(height: 16),
              _buildDailyRecommendationCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: selectedIndex,
        onTap: onNavTap,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18, 
        fontWeight: FontWeight.w700, 
        color: AppConstants.textDark,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernHeader() {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final User? user = snapshot.data?.session?.user ?? _authController.currentUser;
        final String displayName = user?.userMetadata?['full_name'] ?? 
                                   user?.email?.split('@')[0] ?? 
                                   "User";
        
        // Initial for Avatar
        final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Good Morning,",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppConstants.textGrey,
                    fontWeight: FontWeight.w500,
                  )),
                Text(displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                  )),
              ],
            ),
            // Profile / Avatar Action
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.profile),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.poppins(
                      fontSize: 20, 
                      fontWeight: FontWeight.w700, 
                      color: AppConstants.primaryAccent
                    ),
                  ),
                ),
              ),
            )
          ],
        );
      }
    );
  }

  Widget _buildQuickActionsModern() {
    return Row(
      children: [
        // Main Action: Generate Outfit (Big Card)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.outfit),
            child: Container(
              height: 140,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryAccent,
                borderRadius: BorderRadius.circular(AppConstants.kRadius),
                boxShadow: const [AppConstants.activeShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("AI Stylist",
                        style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text("Generate Outfit",
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Secondary Actions (Vertical Stack)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _secondaryActionButton(
                icon: Icons.add_a_photo, 
                label: "Upload", 
                color: Colors.orange.shade800,
                onTap: () => Navigator.pushNamed(context, Routes.upload),
              ),
              const SizedBox(height: 12),
              _secondaryActionButton(
                icon: Icons.checkroom, 
                label: "Closet", 
                color: Colors.teal.shade700,
                onTap: () => Navigator.pushNamed(context, Routes.closet),
              ),
            ],
          ),
        )
      ],
    );
  }
  
  Widget _secondaryActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [AppConstants.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, 
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600, color: AppConstants.textDark
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _weatherController.isLoading,
      builder: (context, isLoading, child) {
        if (isLoading) {
          return const Center(child: LinearProgressIndicator(color: AppConstants.primaryAccent));
        }

        final weather = _weatherController.weather.value;
        // Fallback or Empty state
        if (weather == null) return const SizedBox.shrink(); 

        return Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)], // Blue Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.kRadius),
                boxShadow: const [AppConstants.activeShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(weather.cityName,
                        style: GoogleFonts.poppins(
                          fontSize: 14, 
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        )),
                      const SizedBox(height: 4),
                      Text("${weather.temperature.round()}°", 
                        style: GoogleFonts.poppins(
                          fontSize: 48, 
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                        )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          weather.description.toUpperCase(), 
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.0
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Weather Icon with glow
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: -10,
                        )
                      ]
                    ),
                    child: Image.network(
                      WeatherService().getWeatherIconUrl(weather.iconCode),
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            // Decorative Circle 1
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Decorative Circle 2
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildDailyRecommendationCard() {
    if (_isLoadingOutfit) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppConstants.primaryAccent)
      );
    }

    // 1. STATE: NO OUTFIT LOGGED
    if (_todaysOutfitItems == null || _todaysOutfitItems!.isEmpty) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, Routes.outfit),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [AppConstants.cardShadow],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.style, size: 32, color: AppConstants.textGrey),
              ),
              const SizedBox(height: 16),
              Text("No Outfit Logged Yet",
                style: GoogleFonts.poppins(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                )),
              const SizedBox(height: 8),
              Text("Tap here to let AuraFit generate your perfect look for today.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13, 
                  color: AppConstants.textGrey,
                )),
            ],
          ),
        ),
      );
    }

    // 2. STATE: OUTFIT LOGGED (Horizontal Carousel)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text("Selected for Today", 
                  style: GoogleFonts.poppins(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600, 
                    color: Colors.green
                  )),
              ],
            ),
          ),
          
          // Horizontal List of Items
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _todaysOutfitItems!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _todaysOutfitItems![index];
                return Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: AppConstants.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          item.subCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textDark
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}