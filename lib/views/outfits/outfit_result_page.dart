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

  void _markAsWorn(BuildContext context, Outfit outfit) async {
    await controller.markOutfitAsWorn(outfit);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit marked as worn! Analytics updated.')),
    );
  }

  void _regenerateOutfit(BuildContext context) {
    // Navigates back to the OutfitPage (Form) where the user can regenerate.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Outfit? outfit = controller.currentOutfit.value;

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
            // --- Recommendation Header ---
            Text(outfit.title,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(outfit.description,
                style: GoogleFonts.poppins(color: Colors.black54)),
            const SizedBox(height: 32),

            // --- Outfit Display (Mockup) ---
            _buildOutfitDisplay(outfit.items),
            const SizedBox(height: 32),

            // --- Action Buttons ---
            _buildActionButtons(context, outfit),
            const SizedBox(height: 32),

            // --- Why This Outfit? Section ---
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
          
          // List of Items (Pills)
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: items.map((item) => _buildItemPill(item)).toList(),
          ),
          const SizedBox(height: 24),

          // --- MOCK STYLED OUTFIT IMAGE (CENTERPIECE) ---
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppConstants.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12, width: 1),
            ),
            child: const Center(
              child: Text("Styled Outfit Image Placeholder", style: TextStyle(color: Colors.black54)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemPill(ClothingItem item) {
    return Chip(
      label: Text("${item.category} - ${item.color}"),
      backgroundColor: AppConstants.primaryAccent.withOpacity(0.1),
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppConstants.primaryAccent),
      avatar: Icon(Icons.checkroom_outlined, size: 18, color: AppConstants.primaryAccent),
    );
  }

  Widget _buildActionButtons(BuildContext context, Outfit outfit) {
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
            label: const Text("Mark as Worn"),
            onPressed: () => _markAsWorn(context, outfit),
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