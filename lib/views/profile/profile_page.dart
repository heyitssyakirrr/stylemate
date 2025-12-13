// lib/views/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stylemate/services/notification_service.dart';
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
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // ✅ New
  
  bool _isEditingProfile = false;
  bool _dailyReminderEnabled = false; // ✅ Toggle state

  @override
  void initState() {
    super.initState();
    final user = _authController.currentUser;
    // Pre-fill fields. Check metadata for name, fallback to email part
    final metaName = user?.userMetadata?['full_name'];
    _nameController.text = metaName ?? user?.email?.split('@')[0] ?? "Guest User";
    _emailController.text = user?.email ?? "N/A";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleEdit() async {
    if (_isEditingProfile) {
      // If we were editing and just clicked save:
      await _saveProfile(); 
    }
    
    setState(() {
      _isEditingProfile = !_isEditingProfile;
    });
  }

  Future<void> _saveProfile() async {
    final error = await _authController.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      // Only send password if user typed something new
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
    );

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        _passwordController.clear(); // Clear password field after save
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ UPDATED: Connects to Notification Service
  void _toggleNotification(bool value) async {
    final notificationService = NotificationService();

    if (value) {
      // 1. Request Permission first
      bool granted = await notificationService.requestPermissions();
      
      if (granted) {
        // 2. Schedule the alarm
        await notificationService.scheduleDailyNotification();
        
        setState(() {
          _dailyReminderEnabled = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily Reminder scheduled for 8:00 AM!')),
          );
        }
      } else {
        // Permission denied logic
        setState(() {
          _dailyReminderEnabled = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied. Please enable notifications in settings.')),
          );
        }
      }
    } else {
      // 3. Cancel the alarm if toggled off
      await notificationService.cancelDailyNotification();
      
      setState(() {
        _dailyReminderEnabled = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Reminder turned off.')),
        );
      }
    }
  }

  void _logout() async {
    await _authController.signOut();
    if (mounted) {
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
            backgroundColor: Color(0xFFF0EAE4), 
            child: Icon(Icons.person_rounded, size: 48, color: Color(0xFF7D5A50)),
          ),
          const SizedBox(height: 20),
          
          // Name Field
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
          
          // Email Field
          TextField(
            controller: _emailController,
            enabled: _isEditingProfile, // Now Editable
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              labelText: "Email",
              border: _isEditingProfile ? const OutlineInputBorder() : InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            ),
          ),

          // ✅ NEW: Password Change Field (Only visible in Edit Mode)
          if (_isEditingProfile) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password (Leave empty to keep)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ UPDATED: Only Daily Outfit Reminder
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
            Switch(
              value: _dailyReminderEnabled, 
              onChanged: _toggleNotification, // ✅ Connected logic
              activeColor: AppConstants.primaryAccent,
            ),
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