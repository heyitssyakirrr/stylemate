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
  
  // Ensure these match valid 'articleType' or 'subCategory' in your DB
  final List<String> _filters = [
    'All Items',
    'Tshirts', // Example: Ensure this matches DB value exactly (e.g. 'Tshirts' vs 'T-Shirt')
    'Jeans',
    'Jackets',
    'Dresses',
    'Footwear', // Matches subCategory
    'Accessories' // Matches subCategory
  ];
  
  @override
  void initState() {
    super.initState();
    // Fetch data and then apply initial filter
    _controller.fetchItems().then((_) {
      _controller.filterItems(_searchQuery, _selectedFilter);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose(); 
    super.dispose();
  }
  
  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _controller.filterItems(_searchQuery, _selectedFilter);
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      _controller.filterItems(_searchQuery, _selectedFilter);
    });
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
              onChanged: _updateSearch,
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
                        _updateFilter(selected ? _filters[index] : 'All Items');
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
          // UPDATED: Using ListenableBuilder because ClosetController is a ChangeNotifier
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.items.isEmpty) {
                  return Center(
                    child: Text('No items found.',
                        style: GoogleFonts.poppins(color: Colors.black54)),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.kPadding),
                  child: GridView.builder(
                    itemCount: _controller.items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final item = _controller.items[index];
                      return _buildClosetItem(context, item);
                    },
                  ),
                );
              },
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
        ).then((_) {
          // Refresh list when returning (in case item was deleted/edited)
          _controller.fetchItems();
        });
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
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Item Label
          Text(
            // UPDATED: 'category' doesn't exist in model, using 'articleType'
            item.subCategory, 
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