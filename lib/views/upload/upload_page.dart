// lib/views/upload/upload_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// Removed unused provider import
import '../../utils/constants.dart';
import '../../controllers/upload_controller.dart';

class UploadClothingPage extends StatefulWidget {
  const UploadClothingPage({super.key});

  @override
  State<UploadClothingPage> createState() => _UploadClothingPageState();
}

class _UploadClothingPageState extends State<UploadClothingPage> {
  // Using the controller directly.
  final UploadController _controller = UploadController();

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
    // Controller handles the upload and navigation pop
    await _controller.uploadItem(context);
    
    if (mounted && _controller.selectedImage != null) {
       // Optional: Show success message if not handled in controller
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Item uploaded!')),
       );
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
      // Use ListenableBuilder to rebuild when controller notifies changes
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageUploadCard(),
                const SizedBox(height: 30),
                
                // Only show form if image is selected
                if (_controller.selectedImage != null) ...[
                  _buildAutoTaggingResults(),
                  const SizedBox(height: 30),
                  _buildManualEditSection(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget to handle image upload/preview
  Widget _buildImageUploadCard() {
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
          Text("1. Upload Image for AI Tagging",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
            child: _controller.selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          _controller.selectedImage!,
                          fit: BoxFit.contain,
                        ),
                        if (_controller.isLoading)
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
            onPressed: _controller.isLoading ? null : _showImageSourceDialog,
            icon: Icon(Icons.add_a_photo_outlined, 
                color: _controller.selectedImage != null ? Colors.white : Colors.black87),
            label: Text(
                _controller.selectedImage != null ? "Change Image" : "Select from Gallery/Camera",
                style: TextStyle(color: _controller.selectedImage != null ? Colors.white : Colors.black87)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.selectedImage != null 
                  ? AppConstants.primaryAccent 
                  : AppConstants.background,
              side: _controller.selectedImage != null ? BorderSide.none : const BorderSide(color: Colors.black26),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display AI-powered tags (Using the controllers directly)
  Widget _buildAutoTaggingResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("2. AI Prediction & Manual Edit",
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
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
            children: [
              // We map your specific fields here instead of a generic map
              _buildTagField("Sub Category", _controller.subCategoryCtrl),
              const SizedBox(height: 12),
              _buildTagField("Article Type", _controller.articleTypeCtrl),
              const SizedBox(height: 12),
              _buildTagField("Base Colour", _controller.baseColourCtrl),
              const SizedBox(height: 12),
              _buildTagField("Usage", _controller.usageCtrl),
              const SizedBox(height: 12),
              _buildTagField("Season", _controller.seasonCtrl),
              const SizedBox(height: 12),
              _buildTagField("Gender", _controller.genderCtrl),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for text fields
  Widget _buildTagField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  // Removed separate ManualEditSection since we merged editing into the AI results display
  Widget _buildManualEditSection() {
    return const SizedBox.shrink(); // Placeholder if you want to add extra fields later
  }

  // Final save button
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_controller.selectedImage != null && !_controller.isLoading) ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryAccent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.kRadius / 2),
          ),
        ),
        child: _controller.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                "Save to Virtual Closet",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
      ),
    );
  }
}