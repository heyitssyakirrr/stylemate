import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  // ✅ NEW: Fixed list of Parent Categories
  final List<String> _parentCategories = [
    'Topwear', 'Bottomwear', 'Dress', 'Jumpsuit', 
    'Set', 'Outerwear', 'Footwear', 'Accessory'
  ];

  @override
  void dispose() {
    _controller.dispose();
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
    final success = await _controller.saveItem();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item successfully saved to your Closet!')),
      );
      Navigator.pop(context, true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Upload New Item",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black87)),
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
                // Error Display
                ValueListenableBuilder<String?>(
                  valueListenable: _controller.errorMessage,
                  builder: (context, errorMessage, child) {
                    if (errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.red)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                _buildImageUploadCard(isProcessing),
                const SizedBox(height: 30),
                
                // CHANGE: Show form based on Image Selection, not Embedding
                ValueListenableBuilder<File?>(
                  valueListenable: _controller.selectedImage,
                  builder: (context, imageFile, child) {
                    // Hide only if no image is selected yet
                    if (imageFile == null) return const SizedBox.shrink();

                    return ValueListenableBuilder<ClothingItem>(
                      valueListenable: _controller.itemNotifier,
                      builder: (context, item, child) {
                        return Column(
                          children: [
                            _buildEditSection(item, isProcessing),
                          ],
                        );
                      },
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

  Widget _buildImageUploadCard(bool isProcessing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: ValueListenableBuilder<File?>(
        valueListenable: _controller.selectedImage,
        builder: (context, imageFile, child) {
          return Column(
            children: [
              Text("1. Upload Image for AI Tagging", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppConstants.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12, width: 1),
                ),
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.file(imageFile, fit: BoxFit.contain),
                            if (isProcessing)
                              Container(
                                color: Colors.black45.withOpacity(0.8),
                                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                          ],
                        ),
                      )
                    : Center(child: Text("No Image Selected", style: GoogleFonts.poppins(color: Colors.black45))),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isProcessing ? null : _showImageSourceDialog,
                icon: Icon(Icons.add_a_photo_outlined, color: imageFile != null ? Colors.white : Colors.black87),
                label: Text(imageFile != null ? "Change Image" : "Select from Gallery/Camera", style: TextStyle(color: imageFile != null ? Colors.white : Colors.black87)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: imageFile != null ? AppConstants.primaryAccent : AppConstants.background,
                  side: imageFile != null ? BorderSide.none : const BorderSide(color: Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditSection(ClothingItem item, bool isProcessing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("2. Verify & Edit Details", style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
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
              // ✅ MODIFIED: Pass isFixed: true for Sub Category
              _buildDropdown("Sub Category", 'subCategory', item.subCategory, isProcessing, isFixed: true),
              const SizedBox(height: 12),
              _buildDropdown("Article Type", 'articleType', item.articleType, isProcessing),
              const SizedBox(height: 12),
              _buildDropdown("Base Colour", 'baseColour', item.baseColour, isProcessing),
              const SizedBox(height: 12),
              _buildDropdown("Season", 'season', item.season, isProcessing),
              const SizedBox(height: 12),
              _buildDropdown("Usage", 'usage', item.usage, isProcessing),
              const SizedBox(height: 12),
              _buildDropdown("Gender", 'gender', item.gender, isProcessing),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Updated _buildDropdown to handle fixed lists
  Widget _buildDropdown(String label, String mapKey, String currentValue, bool isDisabled, {bool isFixed = false}) {
    List<String> options = [];
    
    if (isFixed) {
      options = _parentCategories; // Use hardcoded list
    } else {
      options = _controller.labelOptions[mapKey] ?? []; // Use dynamic list
      if (options.isEmpty) options = ["Other"];
    }
    
    if (currentValue.isNotEmpty && !options.contains(currentValue)) {
      options = [...options, currentValue];
    }
    if (currentValue.isEmpty && options.isNotEmpty) {
      currentValue = options.first;
      Future.microtask(() => _controller.updateTag(mapKey, currentValue));
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      value: currentValue.isNotEmpty ? currentValue : null,
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: isDisabled ? null : (newValue) {
        if (newValue != null) _controller.updateTag(mapKey, newValue);
      },
      isExpanded: true,
    );
  }

  Widget _buildSaveButton(bool isProcessing) {
    return ValueListenableBuilder<File?>(
      valueListenable: _controller.selectedImage,
      builder: (context, imageFile, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (imageFile != null && !isProcessing) ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.kRadius / 2)),
            ),
            child: isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Save to Virtual Closet", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        );
      },
    );
  }
}