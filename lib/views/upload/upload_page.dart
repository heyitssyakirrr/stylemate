// lib/views/upload/upload_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import '../../controllers/upload_controller.dart';
import '../../models/clothing_item.dart';

class UploadClothingPage extends StatefulWidget {
  const UploadClothingPage({super.key});

  @override
  State<UploadClothingPage> createState() => _UploadClothingPageState();
}

class _UploadClothingPageState extends State<UploadClothingPage> {
  final UploadController _controller = UploadController();
  
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize text fields with current item data or empty string on load
    _brandController.text = _controller.currentItem.brand ?? '';
    _noteController.text = _controller.currentItem.customNote ?? '';
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _brandController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _controller.pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _save() async {
    if (await _controller.saveItem()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item successfully saved to your Closet!')),
        );
        // Clear text fields after successful save
        _brandController.clear();
        _noteController.clear();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Upload New Item",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            )),
        backgroundColor: AppConstants.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isProcessing,
        builder: (context, isProcessing, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: _controller.errorMessage,
                  builder: (context, errorMessage, child) {
                    if (errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(errorMessage,
                            style: GoogleFonts.poppins(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                _buildImageUploadCard(isProcessing),
                const SizedBox(height: 30),
                
                ValueListenableBuilder<ClothingItem>(
                  valueListenable: _controller.itemNotifier,
                  builder: (context, item, child) {
                    return Column(
                      children: [
                        _buildAutoTaggingResults(item),
                        const SizedBox(height: 30),
                        _buildManualEditSection(item, isProcessing),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                _buildSaveButton(isProcessing),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget to handle image upload/preview
  Widget _buildImageUploadCard(bool isProcessing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: ValueListenableBuilder<XFile?>(
        valueListenable: _controller.selectedImage,
        builder: (context, imageFile, child) {
          final bool imageSelected = imageFile != null;
          
          return Column(
            children: [
              Text("1. Upload Image for AI Tagging",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              // Image Preview Area
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: imageSelected
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Placeholder for the uploaded image (replace with FileImage/NetworkImage in a real app)
                            Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                            ),
                            if (isProcessing)
                              Container(
                                color: Colors.black45.withOpacity(0.8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(color: Colors.white),
                                      const SizedBox(height: 10),
                                      Text("AI Tagging in Progress...", 
                                          style: GoogleFonts.poppins(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text("No Image Selected",
                            style: GoogleFonts.poppins(color: Colors.black45)),
                      ),
              ),
              const SizedBox(height: 16),
              // Image Picker Button
              ElevatedButton.icon(
                onPressed: isProcessing ? null : _showImageSourceDialog,
                icon: Icon(Icons.add_a_photo_outlined, color: imageSelected ? Colors.white : Colors.black87),
                label: Text(imageSelected ? "Change Image" : "Select from Gallery/Camera",
                    style: TextStyle(color: imageSelected ? Colors.white : Colors.black87)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: imageSelected ? AppConstants.primaryAccent : AppConstants.background,
                  side: imageSelected ? BorderSide.none : const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget to display AI-powered tags
  Widget _buildAutoTaggingResults(ClothingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("2. AI Auto-Tagging Results",
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.kPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
            boxShadow: const [AppConstants.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.primaryTags.entries
                .map((entry) => _buildTagRow(entry.key, entry.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  // Widget for displaying a single tag
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

  // Widget for manual editing/refining tags
  Widget _buildManualEditSection(ClothingItem item, bool isProcessing) {
    
    // Update controllers to reflect the current item state
    if (_brandController.text != (item.brand ?? '')) {
      _brandController.text = item.brand ?? '';
    }
    if (_noteController.text != (item.customNote ?? '')) {
      _noteController.text = item.customNote ?? '';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("3. Manual Tag Refinement",
            style: GoogleFonts.poppins(
                fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.kPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.kRadius),
            boxShadow: const [AppConstants.cardShadow],
          ),
          child: Column(
            children: [
              // Category Dropdown
              _buildDropdownField(
                  "Category",
                  item.category,
                  ['T-Shirt', 'Pants', 'Jacket', 'Dress', 'Footwear'],
                  isProcessing
              ),
              const SizedBox(height: 16),
              // Season Dropdown
              _buildDropdownField(
                  "Season",
                  item.season,
                  ['Summer', 'Winter', 'Spring', 'Fall', 'All-Season'],
                  isProcessing
              ),
              const SizedBox(height: 16),
              // Brand Text Field
              TextField(
                controller: _brandController,
                enabled: !isProcessing,
                onChanged: (value) => _controller.updateTag("Brand", value),
                decoration: const InputDecoration(
                  labelText: "Brand (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Note Text Field
              TextField(
                controller: _noteController,
                enabled: !isProcessing,
                onChanged: (value) => _controller.updateTag("Custom Note", value),
                decoration: const InputDecoration(
                  labelText: "Custom Note (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable dropdown widget
  Widget _buildDropdownField(
      String label,
      String currentValue,
      List<String> options,
      bool isDisabled
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: options.contains(currentValue) ? currentValue : options.first,
      items: options
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: isDisabled ? null : (newValue) {
        if (newValue != null) {
          _controller.updateTag(label, newValue);
        }
      },
      disabledHint: Text(currentValue),
    );
  }


  // Final save button
  Widget _buildSaveButton(bool isProcessing) {
    return ValueListenableBuilder<XFile?>(
      valueListenable: _controller.selectedImage,
      builder: (context, imageFile, child) {
        final bool imageSelected = imageFile != null;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: imageSelected && !isProcessing ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.kRadius / 2),
              ),
            ),
            child: isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(
                    "Save to Virtual Closet",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
          ),
        );
      },
    );
  }
}