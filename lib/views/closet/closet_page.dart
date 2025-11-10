// lib/views/closet/closet_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../models/clothing_item.dart';
import '../../controllers/closet_controller.dart';
import 'item_details_page.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  final ClosetController _controller = ClosetController();
  String _selectedFilter = 'All Items';
  String _searchQuery = '';
  
  late List<ClothingItem> _items;

  final List<String> _filters = [
    'All Items',
    'T-Shirt',
    'Jeans',
    'Jacket',
    'Dress',
    'Footwear',
    'Accessories'
  ];

  @override
  void initState() {
    super.initState();
    _items = _controller.mockItems; 
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Virtual Closet",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            )),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding * 1.5, vertical: 12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(_filters[index]),
                      selected: _selectedFilter == _filters[index],
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? _filters[index] : 'All Items';
                        });
                      },
                      selectedColor: AppConstants.primaryAccent.withOpacity(0.8),
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.poppins(
                        color: _selectedFilter == _filters[index] ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _selectedFilter == _filters[index] ? AppConstants.primaryAccent : Colors.black26,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Item Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding),
              child: GridView.builder(
                itemCount: _items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildClosetItem(context, item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for a single clothing item in the grid
  Widget _buildClosetItem(BuildContext context, ClothingItem item) {
    return GestureDetector(
      onTap: () {
        // Navigate to the Item Details Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailsPage(item: item),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Item Thumbnail/Image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [AppConstants.cardShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Item Label
          Text(
            item.category,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Item Sub-label
          Text(
            'Worn ${item.wearCount} times',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}