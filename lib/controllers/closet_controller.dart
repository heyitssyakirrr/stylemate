import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clothing_item.dart';

class ClosetController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<ClothingItem> _items = [];
  bool _isLoading = false;

  List<ClothingItem> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('clothing_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _items = (response as List)
          .map((item) => ClothingItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error fetching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _supabase.from('clothing_items').delete().eq('id', id);
      _items.removeWhere((item) => item.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }
}