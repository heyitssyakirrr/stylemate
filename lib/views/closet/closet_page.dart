import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Make sure you have this if using Provider, or just keep local state if not
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
  
  // UPDATED: Filters matching your SubCategory options
  final List<String> _filters = [
    'All Items',
    'Topwear',
    'Bottomwear',
    'Shoes',
    'Bags',
    'Jewellery',
    'Accessories',
    'Dress',
    'Innerwear',
    'Headwear',
    'Eyewear',
    'Watches',
    'Wallets'
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.fetchItems();
            },
          )
        ],
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
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.items.isEmpty) {
                  return Center(
                    child: Text('Your closet is empty.',
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

  Widget _buildClosetItem(BuildContext context, ClothingItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailsPage(item: item),
          ),
        ).then((_) {
          _controller.fetchItems();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [AppConstants.cardShadow],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // Use subCategory for display as requested
            item.subCategory, 
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Kept Wear Count display
          Text(
            'Worn ${item.wearCount} times',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
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