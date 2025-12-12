import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';
import '../services/ml_service.dart';

class UploadController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _mlService = MLService();

  // State Notifiers
  final ValueNotifier<File?> selectedImage = ValueNotifier<File?>(null);
  final ValueNotifier<bool> isProcessing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  
  // Holds the actual item data (This is what gets saved)
  final ValueNotifier<ClothingItem> itemNotifier = ValueNotifier<ClothingItem>(
    ClothingItem(
      id: '', userId: '', imageUrl: '', 
      subCategory: '', articleType: '', baseColour: '', 
      usage: '', gender: '', season: '', embedding: []
    )
  );

  // Getter for Dropdown options
  Map<String, List<String>> get labelOptions => _mlService.labelMaps;

  UploadController() {
    _init();
  }

  Future<void> _init() async {
    await _mlService.loadModel();
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;
      
      selectedImage.value = File(picked.path);
      await _classifyAndExtract();
    } catch (e) {
      errorMessage.value = "Error picking image: $e";
    }
  }

  Future<void> _classifyAndExtract() async {
    if (selectedImage.value == null) return;
    
    isProcessing.value = true;
    errorMessage.value = null;

    try {
      final result = _mlService.classifyAndExtract(selectedImage.value!);
      final tags = result['tags'] as Map<String, String>;
      final embedding = result['embedding'] as List<double>;

      // 2. Update the item with AI results
      // Notice: No 'brand' or 'customNote' here, matching your Model
      itemNotifier.value = ClothingItem(
        id: '', 
        userId: _supabase.auth.currentUser?.id ?? '', 
        imageUrl: '', // Will be set after upload
        subCategory: tags['subCategory'] ?? 'Topwear',
        articleType: tags['articleType'] ?? 'Tshirts',
        baseColour: tags['baseColour'] ?? 'Black',
        usage: tags['usage'] ?? 'Casual',
        gender: tags['gender'] ?? 'Unisex',
        season: tags['season'] ?? 'Summer',
        embedding: embedding,
      );
      
    } catch (e) {
      errorMessage.value = "AI Analysis failed: $e";
      debugPrint("ML Error: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  // 3. Called when Dropdown value changes
  void updateTag(String field, String value) {
    final current = itemNotifier.value;
    
    // We create a new object because ClothingItem is immutable (final fields)
    // This assumes you haven't added copyWith to your model yet. 
    // If you did add copyWith, use that. If not, we construct it manually:
    
    itemNotifier.value = ClothingItem(
      id: current.id,
      userId: current.userId,
      imageUrl: current.imageUrl,
      embedding: current.embedding,
      wearCount: current.wearCount,
      lastWornDate: current.lastWornDate,
      // Update only the field that changed, keep others:
      subCategory: field == 'subCategory' ? value : current.subCategory,
      articleType: field == 'articleType' ? value : current.articleType,
      baseColour: field == 'baseColour' ? value : current.baseColour,
      usage: field == 'usage' ? value : current.usage,
      gender: field == 'gender' ? value : current.gender,
      season: field == 'season' ? value : current.season,
    );
  }

  // 4. FIX: The Save Logic
  Future<bool> saveItem() async {
    if (selectedImage.value == null) {
      errorMessage.value = "Please select an image first.";
      return false;
    }

    isProcessing.value = true;
    errorMessage.value = null;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';
      
      // A. Upload Image
      await _supabase.storage.from('clothing_items').upload(path, selectedImage.value!);
      final imageUrl = _supabase.storage.from('clothing_items').getPublicUrl(path);

      // B. Create Final Object using the current Dropdown values
      final current = itemNotifier.value;
      final finalItem = ClothingItem(
        id: '', // DB generates this
        userId: userId,
        imageUrl: imageUrl,
        subCategory: current.subCategory,
        articleType: current.articleType,
        baseColour: current.baseColour,
        usage: current.usage,
        gender: current.gender,
        season: current.season,
        embedding: current.embedding,
      );

      var data = finalItem.toJson();
      data.remove('id'); // Remove empty ID so DB generates it
      
      // C. Insert
      await _supabase.from('clothing_items').insert(data);
      
      return true;
    } catch (e) {
      errorMessage.value = "Failed to save: $e";
      debugPrint("Upload Error: $e");
      return false;
    } finally {
      isProcessing.value = false;
    }
  }
  
  @override
  void dispose() {
    selectedImage.dispose();
    isProcessing.dispose();
    errorMessage.dispose();
    itemNotifier.dispose();
    super.dispose();
  }
}