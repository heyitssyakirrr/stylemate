import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';
import '../services/ml_service.dart';

class UploadController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _mlService = MLService();

  File? _selectedImage;
  bool _isLoading = false;
  
  // Controllers for editing the tags
  final subCategoryCtrl = TextEditingController();
  final articleTypeCtrl = TextEditingController();
  final baseColourCtrl = TextEditingController();
  final usageCtrl = TextEditingController();
  final genderCtrl = TextEditingController();
  final seasonCtrl = TextEditingController();
  
  List<double> _currentEmbedding = [];

  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;

  UploadController() {
    _mlService.loadModel();
  }

  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    
    _selectedImage = File(picked.path);
    notifyListeners();
    await _classifyAndExtract();
  }

  Future<void> _classifyAndExtract() async {
    if (_selectedImage == null) return;
    try {
      _isLoading = true; notifyListeners();
      
      final result = _mlService.classifyAndExtract(_selectedImage!);
      final tags = result['tags'] as Map<String, String>;
      _currentEmbedding = result['embedding'] as List<double>;

      // Auto-fill form
      subCategoryCtrl.text = tags['subCategory'] ?? '';
      articleTypeCtrl.text = tags['articleType'] ?? '';
      baseColourCtrl.text = tags['baseColour'] ?? '';
      usageCtrl.text = tags['usage'] ?? '';
      genderCtrl.text = tags['gender'] ?? '';
      seasonCtrl.text = tags['season'] ?? '';

    } catch (e) {
      debugPrint("ML Error: $e");
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> uploadItem(BuildContext context) async {
    if (_selectedImage == null) return;
    try {
      _isLoading = true; notifyListeners();
      final userId = _supabase.auth.currentUser!.id;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 1. Upload Image
      await _supabase.storage.from('clothing_items').upload(path, _selectedImage!);
      final url = _supabase.storage.from('clothing_items').getPublicUrl(path);

      // 2. Save Metadata + Embedding
      final item = ClothingItem(
        id: '', userId: userId, imageUrl: url,
        subCategory: subCategoryCtrl.text,
        articleType: articleTypeCtrl.text,
        baseColour: baseColourCtrl.text,
        usage: usageCtrl.text,
        gender: genderCtrl.text,
        season: seasonCtrl.text,
        embedding: _currentEmbedding,
      );

      var data = item.toJson();
      data.remove('id'); // let DB generate it
      await _supabase.from('clothing_items').insert(data);

      if(context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}