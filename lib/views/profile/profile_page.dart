// lib/views/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/constants.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  
  // --- Local State for Profile Editing (MOCK) ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingProfile = false;
  String _preferredStyle = 'Minimalist';

  @override
  void initState() {
    super.initState();
    final user = _authController.currentUser;
    // Pre-fill fields with current user data
    _nameController.text = user?.email?.split('@')[0] ?? "Guest User";
    _emailController.text = user?.email ?? "N/A";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (!_isEditingProfile) {
        _saveProfile(); // Auto-save when exiting edit mode
      }
    });
  }

  void _saveProfile() {
    // In a real app, this would update Supabase metadata or a profile table.
    debugPrint("Profile saved: Name: ${_nameController.text}, Style: $_preferredStyle");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile settings updated successfully!')),
      );
    }
  }

  void _logout() async {
    await _authController.signOut();
    if (mounted) {
      // Navigate user back to the login page and clear the navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.auth, 
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      appBar: AppBar(
        title: Text("Profile & Settings",
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
            icon: Icon(_isEditingProfile ? Icons.save_rounded : Icons.edit_outlined),
            onPressed: _toggleEdit,
            color: _isEditingProfile ? Colors.green : AppConstants.primaryAccent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.kPadding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Card ---
            _buildProfileCard(),
            const SizedBox(height: 32),

            // --- Style Preferences ---
            _buildSectionHeader("Style Preferences"),
            _buildStylePreferencesCard(),
            const SizedBox(height: 32),

            // --- App Settings ---
            _buildSectionHeader("App Settings"),
            _buildNotificationSettings(),
            const SizedBox(height: 40),

            // --- Logout Button ---
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFF0EAE4), // Lighter accent color
            child: Icon(Icons.person_rounded, size: 48, color: Color(0xFF7D5A50)),
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _nameController,
            enabled: _isEditingProfile,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              labelText: "Name",
              border: _isEditingProfile ? const OutlineInputBorder() : InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
          const Divider(),
          TextField(
            controller: _emailController,
            enabled: false, // Email is typically not editable
            style: GoogleFonts.poppins(color: Colors.black54),
            decoration: InputDecoration(
              labelText: "Email",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreferencesCard() {
    List<String> styleOptions = ['Minimalist', 'Bohemian', 'Sporty', 'Classic', 'Edgy'];
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: "Preferred Style Look",
          border: OutlineInputBorder(),
        ),
        value: _preferredStyle,
        items: styleOptions
            .map((style) => DropdownMenuItem(value: style, child: Text(style)))
            .toList(),
        onChanged: _isEditingProfile 
            ? (newValue) {
                setState(() {
                  _preferredStyle = newValue!;
                });
              }
            : null,
        style: GoogleFonts.poppins(color: Colors.black87),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.kPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kRadius),
        boxShadow: const [AppConstants.cardShadow],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            'Daily Outfit Reminders',
            Icons.notifications_active_outlined,
            const Switch(value: true, onChanged: null), // Mocked for UI
          ),
          const Divider(),
          _buildSettingsTile(
            'Sustainability Insights',
            Icons.eco_outlined,
            const Switch(value: true, onChanged: null), // Mocked for UI
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Widget trailing) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryAccent),
      title: Text(title, style: GoogleFonts.poppins()),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded),
        label: Text("Log Out", 
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.kRadius / 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}