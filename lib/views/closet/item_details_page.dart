import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Ensure provider is imported
import '../../utils/constants.dart';
import '../../models/clothing_item.dart';
import '../../controllers/closet_controller.dart';

class ItemDetailsPage extends StatefulWidget {
  final ClothingItem item;
  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  // Use context.read/watch for controller in build, or keep local reference if needed for specific logic
  // Typically better to get controller from context if it's provided higher up
  // Assuming ClosetController is provided at a higher level (e.g. in main or ClosetPage)
  
  // Local editable item is tricky if we want to save back to DB.
  // For now, let's assume we are just viewing. 
  // If editing is required, we need a way to update the item in the controller.
  
  // Since the previous code had local editing state, we'll keep a simplified version
  // that just displays data for now, or we can re-implement editing if your 
  // ClosetController supports updating specific fields.
  
  @override
  Widget build(BuildContext context) {
    // If you want to allow deleting, access controller here
    final closetController = context.read<ClosetController>();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text(widget.item.articleType, // Use articleType as title
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppConstants.background,
        elevation: 0,
        actions: [
          // Removed Edit button for now as logic for updating specific fields needs 
          // to be defined in controller. Can add back if needed.
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, closetController),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCard(),
            const SizedBox(height: 24),
            _buildWearStatsCard(),
            const SizedBox(height: 30),
            _buildTagsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClosetController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Are you sure you want to permanently delete your ${widget.item.articleType}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await controller.deleteItem(widget.item.id);
              if (context.mounted) {
                Navigator.pop(context); // Return to ClosetPage
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item successfully deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        child: Image.network( // Changed to NetworkImage for Supabase URLs
          widget.item.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => 
              const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildWearStatsCard() {
    final lastWorn = widget.item.lastWornDate;
    final lastWornText = lastWorn != null
        ? DateFormat('MMM dd, yyyy').format(lastWorn.toLocal())
        : 'Never worn';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: AppConstants.primaryAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        border: Border.all(color: AppConstants.primaryAccent.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
              'Wear Count', widget.item.wearCount.toString(), Icons.checkroom),
          _buildStatColumn('Last Worn', lastWornText, Icons.calendar_month),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryAccent, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Classification Tags',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          
          // Display the 6 specific AI-classified tags
          _buildTagRow('Sub Category', widget.item.subCategory),
          _buildTagRow('Article Type', widget.item.articleType),
          _buildTagRow('Base Colour', widget.item.baseColour),
          _buildTagRow('Usage', widget.item.usage),
          _buildTagRow('Gender', widget.item.gender),
          _buildTagRow('Season', widget.item.season),
        ],
      ),
    );
  }

  Widget _buildTagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.black54)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}