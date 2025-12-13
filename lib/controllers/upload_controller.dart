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

  // ✅ NEW: Master Map to group Article Types into Parent Categories
  final Map<String, String> _categoryGrouping = {
    // Topwear
    'Tshirts': 'Topwear', 'Shirts': 'Topwear', 'Tops': 'Topwear', 
    'Sweatshirts': 'Topwear', 'Sweaters': 'Topwear', 'Kurtas': 'Topwear', 
    'Tunics': 'Topwear', 'Waistcoat': 'Topwear', 'Camisoles': 'Topwear', 
    'Vest': 'Topwear', 'Innerwear Vests': 'Topwear', 'Blouses': 'Topwear',
    
    // Bottomwear
    'Jeans': 'Bottomwear', 'Trousers': 'Bottomwear', 'Shorts': 'Bottomwear', 
    'Track Pants': 'Bottomwear', 'Skirts': 'Bottomwear', 'Leggings': 'Bottomwear', 
    'Capris': 'Bottomwear', 'Salwar': 'Bottomwear', 'Churidar': 'Bottomwear', 
    'Patiala': 'Bottomwear', 'Palazzos': 'Bottomwear', 'Stockings': 'Bottomwear', 
    'Swimwear': 'Bottomwear',
    
    // Outerwear
    'Jackets': 'Outerwear', 'Blazers': 'Outerwear', 'Rain Jacket': 'Outerwear', 
    'Coats': 'Outerwear', 'Cardigans': 'Outerwear', 'Shrug': 'Outerwear',
    
    // Dress
    'Dresses': 'Dress', 'Sarees': 'Dress', 'Lehenga Choli': 'Dress', 
    'Kurtis': 'Dress', 
    
    // Jumpsuit
    'Jumpsuit': 'Jumpsuit', 'Rompers': 'Jumpsuit', 'Dungarees': 'Jumpsuit',
    
    // Set
    'Tracksuits': 'Set', 'Suits': 'Set', 'Apparel Set': 'Set', 
    'Night suits': 'Set', 'Lounge Wear': 'Set',
    
    // Footwear
    'Casual Shoes': 'Footwear', 'Flats': 'Footwear', 'Heels': 'Footwear', 
    'Formal Shoes': 'Footwear', 'Sports Shoes': 'Footwear', 'Sandals': 'Footwear', 
    'Flip Flops': 'Footwear', 'Boots': 'Footwear', 'Sneakers': 'Footwear',
    
    // Accessory
    'Watches': 'Accessory', 'Belts': 'Accessory', 'Handbags': 'Accessory', 
    'Wallets': 'Accessory', 'Sunglasses': 'Accessory', 'Jewellery': 'Accessory', 
    'Gloves': 'Accessory', 'Caps': 'Accessory', 'Scarves': 'Accessory', 
    'Ties': 'Accessory', 'Cufflinks': 'Accessory', 'Socks': 'Accessory', 
    'Mufflers': 'Accessory', 'Stoles': 'Accessory', 'Perfume': 'Accessory', 
    'Deodorant': 'Accessory', 'Water Bottle': 'Accessory', 'Bags': 'Accessory',
    'Headwear': 'Accessory', 'Eyewear': 'Accessory'
  };

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

      String predictedArticle = tags['articleType'] ?? 'Tshirts';
      
      // ✅ FIX: Auto-assign Parent Category based on the map
      // This ensures 'Gloves' becomes 'Accessory' automatically
      String groupedCategory = _categoryGrouping[predictedArticle] ?? 'Accessory'; 

      // 2. Update the item with AI results
      itemNotifier.value = ClothingItem(
        id: '', 
        userId: _supabase.auth.currentUser?.id ?? '', 
        imageUrl: '', // Will be set after upload
        subCategory: groupedCategory, // ✅ Using the Parent Group here
        articleType: predictedArticle,
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