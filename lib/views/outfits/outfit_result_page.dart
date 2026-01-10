import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/outfit_controller.dart';
import '../../utils/constants.dart';
import '../../models/clothing_item.dart';

class OutfitResultPage extends StatelessWidget {
  final OutfitController controller;

  const OutfitResultPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // ✅ WRAP WITH LISTENABLE BUILDER
    // This ensures the page rebuilds instantly when regenerate finishes
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final outfit = controller.currentOutfit;

        return Scaffold(
          backgroundColor: AppConstants.background,
          appBar: AppBar(
            title: Text("Your Style Match",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppConstants.background,
            foregroundColor: Colors.black87,
          ),
          body: controller.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppConstants.primaryAccent),
                      SizedBox(height: 16),
                      Text("Styling the next best look...", style: TextStyle(color: Colors.grey))
                    ],
                  ),
                )
              : (outfit == null || outfit.items.isEmpty)
                  ? _buildErrorView(context)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.kPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildScoreCard(outfit.harmonyScore),
                          const SizedBox(height: 24),
                          
                          if (outfit.suggestionLogic.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                outfit.suggestionLogic,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, 
                                    color: Colors.grey[700], 
                                    fontStyle: FontStyle.italic
                                ),
                              ),
                            ),

                          Text("Items in this look:",
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          
                          ...outfit.items.map((item) => _buildItemCard(item)),
                          
                          const SizedBox(height: 32),
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildScoreCard(int score) {
    Color scoreColor = score > 85
        ? Colors.green
        : score > 70
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        children: [
          Text("Harmony Score",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text("$score%",
              style: GoogleFonts.poppins(
                  fontSize: 48, fontWeight: FontWeight.bold, color: scoreColor)),
          const SizedBox(height: 8),
          Text(
            score > 85
                ? "Excellent Match!"
                : score > 70
                    ? "Good Combination"
                    : "Bold Choice",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ClothingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(width: 80, height: 80, color: Colors.grey[200]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.subCategory,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text("${item.baseColour} • ${item.season}",
                    style: GoogleFonts.poppins(
                        color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.usage,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppConstants.primaryAccent)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await controller.markAsWorn();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Outfit marked as worn!')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text("Mark as Worn Today",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            // ✅ FIXED: REGENERATE LOGIC
            // Does NOT pop navigation. Calls controller to fetch next option.
            onPressed: () async {
              await controller.regenerateOutfit();
            },
            icon: const Icon(Icons.refresh, color: AppConstants.primaryAccent),
            label: Text("Regenerate (Next Option)",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryAccent)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppConstants.primaryAccent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text("No outfits found.",
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Adjust Filters"),
          )
        ],
      ),
    );
  }
}