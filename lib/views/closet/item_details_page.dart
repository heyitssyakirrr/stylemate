import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../models/clothing_item.dart';
import '../../controllers/closet_controller.dart';
import 'package:provider/provider.dart';

class ItemDetailsPage extends StatefulWidget {
  final ClothingItem item;
  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  late ClothingItem _displayItem;

  @override
  void initState() {
    super.initState();
    _displayItem = widget.item;
  }

  void _markAsWorn() async {
    final controller = context.read<ClosetController>();
    await controller.markAsWorn(_displayItem);
    
    // Optimistic update for UI
    setState(() {
       _displayItem = ClothingItem(
         id: _displayItem.id,
         userId: _displayItem.userId,
         imageUrl: _displayItem.imageUrl,
         subCategory: _displayItem.subCategory,
         articleType: _displayItem.articleType,
         baseColour: _displayItem.baseColour,
         usage: _displayItem.usage,
         gender: _displayItem.gender,
         season: _displayItem.season,
         wearCount: _displayItem.wearCount + 1,
         lastWornDate: DateTime.now(),
         embedding: _displayItem.embedding
       );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_displayItem.articleType} marked as worn!')),
      );
    }
  }

  void _confirmDelete() {
    final controller = context.read<ClosetController>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Are you sure you want to permanently delete your ${_displayItem.articleType}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await controller.deleteItem(_displayItem.id);
              if (mounted) {
                Navigator.pop(context); // Go back to Closet
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text(_displayItem.articleType, // Updated from category
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppConstants.background,
        elevation: 0,
        // Removed Actions: Edit button removed as we simplify flow
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          )
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
            const SizedBox(height: 30),
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
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
        // Use NetworkImage for Supabase URLs
        child: Image.network(
          _displayItem.imageUrl, 
          fit: BoxFit.contain,
          errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported, size: 50),
        ),
      ),
    );
  }

  Widget _buildWearStatsCard() {
    final lastWorn = _displayItem.lastWornDate;
    final lastWornText = lastWorn != null
        ? DateFormat('MMM dd, yyyy').format(lastWorn)
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
              'Wear Count', _displayItem.wearCount.toString(), Icons.checkroom),
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

  // Updated to show the 6 new fields
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
          Text('Item Classification',
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          // Static display of tags
          _buildTagRow("Subcategory", _displayItem.subCategory),
          _buildTagRow("Article Type", _displayItem.articleType),
          _buildTagRow("Base Colour", _displayItem.baseColour),
          _buildTagRow("Usage", _displayItem.usage),
          _buildTagRow("Gender", _displayItem.gender),
          _buildTagRow("Season", _displayItem.season),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _markAsWorn,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: Text("Mark as Worn",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}