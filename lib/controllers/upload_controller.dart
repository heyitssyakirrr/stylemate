// lib/controllers/upload_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
// Note: In a real app, you would import a DataService here (e.g., FirestoreService)

class UploadController {
  // State Notifiers: Used to manage state changes observed by the UI
  final ValueNotifier<XFile?> selectedImage = ValueNotifier(null);
  final ValueNotifier<bool> isProcessing = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<ClothingItem> _itemNotifier;

  // Public getter to get the current item being edited.
  ClothingItem get currentItem => _itemNotifier.value;
  ValueNotifier<ClothingItem> get itemNotifier => _itemNotifier;


  UploadController() : _itemNotifier = ValueNotifier(ClothingItem(imageUrl: 'assets/logo.png')) {
    // Initialize the item with a blank state
  }
  
  void _resetItem() {
    // We use a mock URL here for development until a real image is selected/uploaded
    _itemNotifier.value = ClothingItem(imageUrl: 'assets/logo.png'); 
  }


  /// Simulates picking an image from the gallery or camera.
  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);

      if (image != null) {
        selectedImage.value = image;
        
        // Update the item with the temporary local path and trigger UI rebuild
        final newItem = _itemNotifier.value;
        newItem.imageUrl = image.path; // <--- FIX APPLIED: imageUrl is now mutable
        _itemNotifier.value = newItem; // Notify listeners with the updated item

        await _fetchTags(image);
      }
    } catch (e) {
      errorMessage.value = "Failed to pick image: $e";
      selectedImage.value = null;
    }
  }

  /// Simulates calling the AI/ML service to get tags.
  Future<void> _fetchTags(XFile imageFile) async {
    isProcessing.value = true;
    errorMessage.value = null;

    // Simulate AI model latency
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // MOCK AI RESULTS
    final updatedItem = _itemNotifier.value;
    updatedItem.category = 'T-Shirt';
    updatedItem.color = 'Soft Blue';
    updatedItem.pattern = 'Solid';
    updatedItem.season = 'Summer';
    updatedItem.usage = 'Active Wear';
    
    _itemNotifier.value = updatedItem; // Update and notify listeners
    
    isProcessing.value = false;
  }

  /// Updates a specific tag field in the current item.
  void updateTag(String field, String value) {
    final updatedItem = _itemNotifier.value;
    
    switch (field) {
      case "Category": updatedItem.category = value; break;
      case "Color": updatedItem.color = value; break;
      case "Season": updatedItem.season = value; break;
      case "Brand": updatedItem.brand = value; break;
      case "Custom Note": updatedItem.customNote = value; break;
      default: return; // Ignore unknown fields
    }
    
    _itemNotifier.value = updatedItem; // Update and notify listeners
  }


  /// Saves the final, tagged item to the virtual closet (database).
  Future<bool> saveItem() async {
    if (selectedImage.value == null) {
      errorMessage.value = "Please select an image first.";
      return false;
    }

    isProcessing.value = true;
    errorMessage.value = null;

    // MOCK SAVE OPERATION to DB
    debugPrint("Saving item: ${_itemNotifier.value.toMap()}");
    await Future.delayed(const Duration(seconds: 2));
    
    // Assume success
    isProcessing.value = false;
    
    // Reset controller state after successful save
    selectedImage.value = null;
    _resetItem();

    return true;
  }

  void dispose() {
    selectedImage.dispose();
    isProcessing.dispose();
    errorMessage.dispose();
    _itemNotifier.dispose();
  }
}