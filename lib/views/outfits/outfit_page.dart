// lib/views/outfits/outfit_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/outfit_controller.dart';
import '../../controllers/closet_controller.dart';
import '../../controllers/weather_controller.dart'; // ✅ Import Weather Controller
import '../../models/clothing_item.dart';
import 'outfit_result_page.dart';

class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  final OutfitController _controller = OutfitController();
  final ClosetController _closetController = ClosetController();
  final WeatherController _weatherController = WeatherController(); // ✅ Initialize Weather Controller

  final Map<String, List<String>> _options = {
    'Usage': [
      'Casual', 'Ethnic', 'Formal', 'Party', 'Smart Casual', 'Sports', 'Travel'
    ],
    'Season': [
      'Fall', 'Spring', 'Summer', 'Winter', 'All Seasons'
    ],
    'ColorPreference': [
      'Beige', 'Black', 'Blue', 'Brown', 'Burgundy', 'Charcoal', 'Cream', 'Gold', 
      'Green', 'Grey', 'Khaki', 'Lavender', 'Magenta', 'Maroon', 'Multi', 'Mustard', 
      'Navy Blue', 'Olive', 'Orange', 'Peach', 'Pink', 'Purple', 'Red', 'Silver', 
      'Tan', 'Teal', 'Turquoise', 'White', 'Yellow'
    ],
  };

  final Map<String, String?> _criteria = {
    'Usage': null,
    'Season': null,
    'ColorPreference': null,
  };

  bool _useAnchorItem = false;
  List<ClothingItem> _selectedAnchorItems = [];

  final List<String> _requiredSlots = ['Top', 'Bottom', 'Footwear'];

  @override
  void initState() {
    super.initState();
    _closetController.fetchItems();
    _weatherController.fetchWeather(); // ✅ Fetch weather when page loads
  }

  void _generateOutfit() async {
    List<String>? anchorIds;
    if (_useAnchorItem && _selectedAnchorItems.isNotEmpty) {
      anchorIds = _selectedAnchorItems.map((e) => e.id).toList();
    }

    // ✅ Get Current Temperature
    double? currentTemp = _weatherController.weather.value?.temperature;

    await _controller.generateOutfit(
      usage: _criteria['Usage'], 
      season: _criteria['Season'],
      color: _criteria['ColorPreference'],
      anchorItemIds: anchorIds,
      slots: _requiredSlots,
      temperature: currentTemp, // ✅ Pass to Controller
    );

    if (mounted && _controller.currentOutfit != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutfitResultPage(controller: _controller),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate outfit. Try different filters.')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _closetController.dispose();
    _weatherController.dispose();
    super.dispose();
  }

  void _toggleSlot(String slot, bool isSelected) {
    setState(() {
      if (['Dress', 'Jumpsuit', 'Set'].contains(slot)) {
        if (isSelected) {
          _requiredSlots.remove('Top');
          _requiredSlots.remove('Bottom');
          _requiredSlots.remove('Dress');
          _requiredSlots.remove('Jumpsuit');
          _requiredSlots.remove('Set');
          _requiredSlots.add(slot);
        } else {
          _requiredSlots.remove(slot);
        }
      } 
      else if (['Top', 'Bottom'].contains(slot)) {
        if (isSelected) {
          _requiredSlots.remove('Dress');
          _requiredSlots.remove('Jumpsuit');
          _requiredSlots.remove('Set');
          if (!_requiredSlots.contains('Top')) _requiredSlots.add('Top');
          if (!_requiredSlots.contains('Bottom')) _requiredSlots.add('Bottom');
        } else {
          _requiredSlots.remove('Top');
          _requiredSlots.remove('Bottom');
        }
      } 
      else {
        if (isSelected) {
          _requiredSlots.add(slot);
        } else {
          _requiredSlots.remove(slot);
        }
      }
    });
  }

  void _onAnchorTap(ClothingItem item) {
    setState(() {
      final isAlreadySelected = _selectedAnchorItems.any((i) => i.id == item.id);

      if (isAlreadySelected) {
        _selectedAnchorItems.removeWhere((i) => i.id == item.id);
      } else {
        _selectedAnchorItems.removeWhere((i) => i.subCategory == item.subCategory);
        _selectedAnchorItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Generate Outfit",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Define Your Look",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Set constraints or leave empty for AI selection.",
                style: GoogleFonts.poppins(color: Colors.black54)),
            const SizedBox(height: 32),

            _buildFormCard(),
            const SizedBox(height: 32),

            _buildSlotRequirements(),
            const SizedBox(height: 32),

            _buildAnchorSelection(),
            const SizedBox(height: 40),

            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        children: [
          _buildDropdownField('Usage', 'Usage / Occasion', _options['Usage']!),
          const SizedBox(height: 16),
          _buildDropdownField('Season', 'Season', _options['Season']!),
          const SizedBox(height: 16),
          _buildDropdownField('ColorPreference', 'Preferred Color', _options['ColorPreference']!),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String key, String label, List<String> options) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: _criteria[key],
      hint: const Text("Any (Optional)"),
      isExpanded: true,
      items: options
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (newValue) {
        setState(() {
          _criteria[key] = newValue;
        });
      },
    );
  }

  Widget _buildSlotRequirements() {
    List<String> allSlots = ['Top', 'Bottom', 'Dress', 'Jumpsuit', 'Set', 'Outerwear', 'Footwear', 'Accessory'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Required Items:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: allSlots.map((slot) => FilterChip(
            label: Text(slot),
            selected: _requiredSlots.contains(slot),
            onSelected: (selected) => _toggleSlot(slot, selected),
            selectedColor: AppConstants.primaryAccent.withOpacity(0.8),
            backgroundColor: Colors.white,
            labelStyle: GoogleFonts.poppins(
              color: _requiredSlots.contains(slot) ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAnchorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Select Anchor Items", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Switch(
              value: _useAnchorItem, 
              onChanged: (val) {
                setState(() {
                  _useAnchorItem = val;
                  if (!val) _selectedAnchorItems.clear(); 
                });
              },
              activeColor: AppConstants.primaryAccent,
            )
          ],
        ),
        if (_useAnchorItem)
          ListenableBuilder(
            listenable: _closetController,
            builder: (context, child) {
              if (_closetController.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (_closetController.items.isEmpty) {
                return const Text("No items in closet to select.");
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedAnchorItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Selected: ${_selectedAnchorItems.map((e) => e.subCategory).join(", ")}",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _closetController.items.length,
                      itemBuilder: (context, index) {
                        final item = _closetController.items[index];
                        final isSelected = _selectedAnchorItems.any((i) => i.id == item.id);
                        
                        return GestureDetector(
                          onTap: () => _onAnchorTap(item),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0, bottom: 8.0, top: 8.0),
                            child: Container(
                              width: 90,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppConstants.primaryAccent : Colors.transparent, 
                                  width: 3
                                ),
                                boxShadow: [AppConstants.cardShadow],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                      child: item.imageUrl.isNotEmpty ? Image.network(item.imageUrl, fit: BoxFit.cover) : const Icon(Icons.image),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0), 
                                    child: Text(
                                      item.subCategory, 
                                      style: GoogleFonts.poppins(fontSize: 10), 
                                      textAlign: TextAlign.center,
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          )
      ],
    );
  }

  Widget _buildGenerateButton() {
    bool canGenerate = !_useAnchorItem || (_useAnchorItem && _selectedAnchorItems.isNotEmpty);

    return SizedBox(
      width: double.infinity,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return ElevatedButton(
            onPressed: (_controller.isLoading || !canGenerate) ? null : _generateOutfit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Text(
                    "Generate Outfit",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          );
        }
      ),
    );
  }
}