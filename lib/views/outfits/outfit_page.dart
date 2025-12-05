// lib/views/outfit/outfit_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/outfit_controller.dart';
import 'outfit_result_page.dart';

class OutfitPage extends StatefulWidget {
  const OutfitPage({super.key});

  @override
  State<OutfitPage> createState() => _OutfitPageState();
}

class _OutfitPageState extends State<OutfitPage> {
  final OutfitController _controller = OutfitController();
  
  // Local state to hold form data
  final Map<String, dynamic> _criteria = {
    'Usage': null,
    'Occasion': null,
    'ColorPreference': null,
    'StylePreference': null,
  };

  void _generateOutfit() async {
    // 1. Generate outfit (updates controller state)
    await _controller.generateOutfit(criteria: _criteria);

    // 2. Navigate to results page
    if (mounted && _controller.currentOutfit.value != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutfitResultPage(controller: _controller),
        ),
      );
    }
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
            Text("Select filters below to tailor the recommendation. Leave blank for a random AI pick.",
                style: GoogleFonts.poppins(color: Colors.black54)),
            const SizedBox(height: 32),

            _buildFormCard(),
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
          // Dropdown: Usage
          _buildDropdownField('Usage', 'Usage', _controller.options['Usage']!),
          const SizedBox(height: 16),
          
          // Dropdown: Occasion
          _buildDropdownField('Occasion', 'Occasion', _controller.options['Occasion']!),
          const SizedBox(height: 16),
          
          // Dropdown: Color Preference
          _buildDropdownField('ColorPreference', 'Color Palette', _controller.options['ColorPreference']!),
          const SizedBox(height: 16),

          // Dropdown: Style Preference
          _buildDropdownField('StylePreference', 'Style Preference', _controller.options['StylePreference']!),
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
      hint: Text("Select $label (Optional)"),
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

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, child) {
          return ElevatedButton(
            onPressed: isLoading ? null : _generateOutfit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryAccent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
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