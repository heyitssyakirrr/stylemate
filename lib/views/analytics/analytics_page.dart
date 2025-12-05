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
      body: RefreshIndicator(
        onRefresh: _controller.refreshAnalytics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sustainability Dashboard",
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text("Track your environmental impact and wardrobe usage.",
                  style: GoogleFonts.poppins(color: Colors.black54)),
              const SizedBox(height: 32),

              // --- Sustainability Metrics ---
              _buildSustainabilityMetrics(),
              const SizedBox(height: 32),

              // --- Wear Frequency Chart ---
              _buildSectionHeader("Wear Frequency by Category"),
              _buildChartCard(
                child: _buildBarChartPlaceholder(_controller.wearFrequencyData),
              ),
              const SizedBox(height: 32),

              // --- Most Worn Items ---
              _buildSectionHeader("Most Worn Items (Total Count)"),
              _buildChartCard(
                height: 200,
                child: _buildListChartPlaceholder(_controller.mostWornItems),
              ),
              const SizedBox(height: 32),
              
              // --- Encourage Message ---
              _buildEncourageMessage(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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

  // Placeholder for a Bar Chart (simulated with Text)
  Widget _buildBarChartPlaceholder(List<ChartDataPoint> data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Placeholder: Bar Chart (e.g., fl_chart)",
              style: GoogleFonts.poppins(color: Colors.black38)),
          const SizedBox(height: 10),
          ...data.map((p) => Text("${p.label}: ${p.value} uses", 
              style: GoogleFonts.poppins(fontSize: 12))),
        ],
      ),
    );
  }
  
  // Placeholder for a List Chart / Ranking
  Widget _buildListChartPlaceholder(List<ChartDataPoint> data) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: item.color,
            child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white)),
          ),
          title: Text(item.label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          trailing: Text("${item.value.round()} wears", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        );
      },
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
      width: (MediaQuery.of(context).size.width - (AppConstants.kPadding * 4.5)) / 2, // Half width minus padding
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
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: metric.color)),
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