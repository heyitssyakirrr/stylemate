import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Ensure provider is imported
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
  final ClosetController _controller = ClosetController();
  late ClothingItem _editableItem; // Local state copy for editing

  @override
  void initState() {
    super.initState();
    // Create a copy of the item for local, client-side edits
    _editableItem = ClothingItem.fromMap(widget.item.toMap());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markAsWorn() async {
    await _controller.markAsWorn(_editableItem);
    setState(() {}); // Refresh UI after update
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_editableItem.category} marked as worn!')),
      );
    }
  }

  void _saveEdits() async {
    await _controller.saveItemEdits(_editableItem);
    setState(() {
      _controller.isEditing.value = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item successfully updated.')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item"),
        content: Text("Are you sure you want to permanently delete your ${_editableItem.category}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              // Pass ID to controller for deletion, which will update the list
              await _controller.deleteItem(_editableItem.id!); 
              if (mounted) {
                // Return to the previous screen (the ClosetPage) after deletion
                Navigator.pop(context); 
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
    // If you want to allow deleting, access controller here
    final closetController = context.read<ClosetController>();

    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text(_editableItem.category,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppConstants.background,
        elevation: 0,
        // Removed Actions: Edit button removed as we simplify flow
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _controller.isEditing,
            builder: (context, isEditing, child) {
              if (isEditing) {
                return IconButton(
                  icon: const Icon(Icons.save_rounded, color: Colors.green),
                  onPressed: _saveEdits,
                );
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _controller.isEditing.value = true,
              );
            },
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
        child: Image.asset(
          _editableItem.imageUrl, 
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildWearStatsCard() {
    final lastWorn = _editableItem.lastWornDate;
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
              'Wear Count', _editableItem.wearCount.toString(), Icons.checkroom),
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
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isEditing,
      builder: (context, isEditing, child) {
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
              Text('Item Tags & Info',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
              const Divider(height: 24),
              // Dynamic fields: Tags
              ..._editableItem.primaryTags.entries.map((entry) {
                return _buildTagRow(entry.key, entry.value, isEditing);
              }),
              // Static fields: Brand/Notes
              _buildInfoRow('Brand', _editableItem.brand ?? 'N/A', isEditing),
              _buildInfoRow(
                  'Notes', _editableItem.customNote ?? 'N/A', isEditing),
            ],
          ),
        );
      },
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
  
  Widget _buildEditableDropdown(String label, String currentValue) {
    List<String> options;
    Function(String) onUpdate;

    switch (label) {
      case 'Category':
        options = ['T-Shirt', 'Pants', 'Jacket', 'Dress', 'Footwear', 'Accessory'];
        onUpdate = (v) => _editableItem.category = v;
        break;
      case 'Color':
        options = ['Soft Blue', 'White', 'Black', 'Red', 'Gray'];
        onUpdate = (v) => _editableItem.color = v;
        break;
      case 'Season':
        options = ['Summer', 'Winter', 'Spring', 'Fall', 'All-Season'];
        onUpdate = (v) => _editableItem.season = v;
        break;
      case 'Usage':
        options = ['Active Wear', 'Casual', 'Formal', 'Business Casual'];
        onUpdate = (v) => _editableItem.usage = v;
        break;
      default:
        options = [currentValue];
        onUpdate = (v) {};
    }
    
    String? selectedValue = options.contains(currentValue) ? currentValue : options.first;

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: selectedValue,
      items: options.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onUpdate(newValue);
          setState(() {}); 
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isEditing) {
    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TextField(
          controller: TextEditingController(text: value == 'N/A' ? '' : value),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (newValue) {
            if (label == 'Brand') {
              _editableItem.brand = newValue;
            } else if (label == 'Notes') {
              _editableItem.customNote = newValue;
            }
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.black54)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
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
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ),
      ],
    );
  }
}