// lib/views/analytics/analytics_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/analytics_controller.dart';
import '../../models/analytics_data.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final AnalyticsController _controller = AnalyticsController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Wear Analytics",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.background,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // ✅ Wrap body in ListenableBuilder to rebuild when data loads
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _controller.refreshAnalytics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sustainability Dashboard",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text("Track your real wardrobe usage statistics.",
                      style: GoogleFonts.poppins(color: Colors.black54)),
                  const SizedBox(height: 32),

                  // --- Sustainability Metrics ---
                  _buildSustainabilityMetrics(),
                  const SizedBox(height: 32),

                  // --- Wear Frequency Chart ---
                  _buildSectionHeader("Wear Count by Category"),
                  _buildChartCard(
                    child: _controller.wearFrequencyData.isEmpty 
                      ? _buildEmptyState("Start marking outfits as worn to see data.")
                      : _buildBarChartPlaceholder(_controller.wearFrequencyData),
                  ),
                  const SizedBox(height: 32),

                  // --- Most Worn Items (Scrollable) ---
                  _buildSectionHeader("Your Top Worn Items"),
                  _buildChartCard(
                    height: 300, // Fixed height to allow scrolling inside
                    child: _controller.mostWornItems.isEmpty
                      ? _buildEmptyState("No wear data yet.")
                      : _buildListChartPlaceholder(_controller.mostWornItems),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- Encourage Message ---
                  _buildEncourageMessage(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(message, style: GoogleFonts.poppins(color: Colors.black45)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildChartCard({required Widget child, double height = 250}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: child,
    );
  }

  // ✅ UPDATED: Bar Chart fills the width and fits labels properly
  Widget _buildBarChartPlaceholder(List<ChartDataPoint> data) {
    // Find max value to normalize bar height
    double maxVal = 0;
    for(var p in data) { if (p.value > maxVal) maxVal = p.value; }
    if (maxVal == 0) maxVal = 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      // Removed MainAxisAlignment.start/spaceEvenly - Explained below
      children: data.map((point) {
        return Expanded( // ✅ 1. Expanded forces items to fill all available space equally
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0), // Small padding between bars
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Value Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("${point.value.toInt()}", 
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                // The Bar
                Container(
                  width: double.infinity, // Fill the width of the Expanded column (minus padding)
                  height: (point.value / maxVal) * 150, // Scale height relative to max
                  decoration: BoxDecoration(
                    color: point.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                // Category Label
                // ✅ 2. FittedBox ensures "Bottomwear" scales down to fit horizontally without wrapping/rotating
                SizedBox(
                  height: 20, // Constrain height so alignment stays consistent
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      point.label, 
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // Scrollable List with Scrollbar
  Widget _buildListChartPlaceholder(List<ChartDataPoint> data) {
    return Scrollbar(
      thumbVisibility: true, 
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 12.0), 
        itemCount: data.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = data[index];
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AppConstants.primaryAccent,
              child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            title: Text(item.label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("${item.value.toInt()}x", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSustainabilityMetrics() {
    return Wrap(
      spacing: AppConstants.kPadding,
      runSpacing: AppConstants.kPadding,
      children: _controller.metrics.map((metric) => 
        _buildMetricCard(metric)
      ).toList(),
    );
  }

  Widget _buildMetricCard(SustainabilityMetric metric) {
    return Container(
      width: (MediaQuery.of(context).size.width - (AppConstants.kPadding * 4.5)) / 2, 
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 32),
          const SizedBox(height: 8),
          Text(metric.value, 
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: metric.color)),
          const SizedBox(height: 4),
          Text(metric.title, 
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text(metric.insight, 
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEncourageMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: AppConstants.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        border: Border.all(color: AppConstants.primaryAccent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: AppConstants.primaryAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sustainability Tip", 
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppConstants.primaryAccent)),
                const SizedBox(height: 4),
                Text("Challenge: Wear an item from your 'Underused' list once this week to boost your reuse score!",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}