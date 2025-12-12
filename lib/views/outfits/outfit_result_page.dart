// lib/views/outfit/outfit_result_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/outfit_controller.dart';
import '../../models/outfit.dart';
import '../../models/clothing_item.dart';

class OutfitResultPage extends StatelessWidget {
  final OutfitController controller;
  
  const OutfitResultPage({super.key, required this.controller});

  void _markAsWorn(BuildContext context) async {
    await controller.markAsWorn();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit marked as worn! Analytics updated.')),
      );
    }
  }

  void _regenerateOutfit(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Outfit? outfit = controller.currentOutfit;

    if (outfit == null) {
      return Scaffold(
        body: Center(
          child: Text("No outfit found. Please try generating again.",
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Your Recommendation",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Recommended Look",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Here is a personalized combination based on your style and constraints.",
                style: GoogleFonts.poppins(color: Colors.black54)),
            const SizedBox(height: 32),

            // --- Outfit Display (Visual Grid Updated) ---
            _buildOutfitDisplay(outfit.items),
            const SizedBox(height: 32),

            _buildActionButtons(context),
            const SizedBox(height: 32),

            _buildWhyThisOutfit(outfit.suggestionLogic),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOutfitDisplay(List<ClothingItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        children: [
          Text("Composed Items", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: items.map((item) => _buildItemPill(item)).toList(),
          ),
          const SizedBox(height: 24),

          // --- VISUAL GRID (Shows ALL items now) ---
          // ✅ FIX: Removed fixed height so it expands to show all items
          Container(
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12, width: 1),
            ),
            child: _buildVisualGrid(items),
          )
        ],
      ),
    );
  }

  Widget _buildVisualGrid(List<ClothingItem> items) {
    if (items.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No items to display")));

    // Dynamic grid layout based on item count
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true, // ✅ FIX: Allows grid to expand vertically to fit all items
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: items.length <= 1 ? 1 : 2, 
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          // Adjust aspect ratio so images aren't squashed
          childAspectRatio: items.length >= 3 ? 0.8 : 1.0, 
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => 
                          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
                // Label at bottom of image
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: AppConstants.primaryAccent.withOpacity(0.05),
                  child: Text(
                    // ✅ FIX: Use 'articleType' (T-shirt) instead of 'subCategory' (Topwear)
                    item.articleType, 
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemPill(ClothingItem item) {
    return Chip(
      // Using 'articleType' and 'baseColour' from your new model
      label: Text("${item.articleType} - ${item.baseColour}", style: const TextStyle(fontSize: 11)),
      backgroundColor: AppConstants.primaryAccent.withOpacity(0.1),
      labelStyle: GoogleFonts.poppins(color: AppConstants.primaryAccent),
      avatar: Icon(Icons.checkroom_outlined, size: 16, color: AppConstants.primaryAccent),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Regenerate"),
            onPressed: () => _regenerateOutfit(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryAccent,
              side: BorderSide(color: AppConstants.primaryAccent, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text("Mark as Worn", style: TextStyle(color: Colors.white)),
            onPressed: () => _markAsWorn(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWhyThisOutfit(String logic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Why This Outfit? (Transparency UX)",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppConstants.kPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
            boxShadow: const [AppConstants.cardShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, color: AppConstants.primaryAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  logic,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}