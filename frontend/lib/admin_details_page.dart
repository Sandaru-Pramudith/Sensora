// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';
import 'admin_list_page.dart';

class AdminDetailsPage extends StatefulWidget {
  final AdminMember admin;

  const AdminDetailsPage({super.key, required this.admin});

  @override
  State<AdminDetailsPage> createState() => _AdminDetailsPageState();
}

class _AdminDetailsPageState extends State<AdminDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _positionController;
  late TextEditingController _contactController;
  late TextEditingController _usernameController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.admin.fullName);
    _emailController = TextEditingController(text: widget.admin.email);
    _positionController = TextEditingController(text: widget.admin.position);
    _contactController = TextEditingController(text: widget.admin.contact);
    _usernameController = TextEditingController(text: widget.admin.username);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    try {
      await _firestore.collection('admins').doc(widget.admin.id).update({
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'position': _positionController.text.trim(),
        'contactNo': _contactController.text.trim(),
        'username': _usernameController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin details updated successfully'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  void _cancelEdit() {
    // Reset to original values
    _fullNameController.text = widget.admin.fullName;
    _emailController.text = widget.admin.email;
    _positionController.text = widget.admin.position;
    _contactController.text = widget.admin.contact;
    _usernameController.text = widget.admin.username;
    setState(() {
      _isEditing = false;
    });
  }

  void _deleteAdmin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A532F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Admin',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.admin.fullName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              try {
                await _firestore
                    .collection('admins')
                    .doc(widget.admin.id)
                    .delete();
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Admin deleted'),
                    backgroundColor: Color(0xFFE57373),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error deleting: $e')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE57373)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: const [
          Color(0xFF143C28),
          Color(0xFF1A532F),
          Color(0xFF2B7A48),
        ],
        particleCount: 20,
        particleColor: AppColors.particleColor,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.headerGreen,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: GlassNavBar(
                      title: 'Admin Details',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Admin Details
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        children: [
                          // Profile Header
                          GlassContainer(
                            padding: const EdgeInsets.all(24),
                            borderRadius: 24,
                            color: Colors.black.withValues(alpha: 0.15),
                            child: Column(
                              children: [
                                // Avatar with admin badge
                                Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(
                                            0xFF4CAF50,
                                          ).withValues(alpha: 0.7),
                                          width: 3,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          widget.admin.fullName
                                              .split(' ')
                                              .map((e) => e[0])
                                              .take(2)
                                              .join(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Admin Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Name
                                Text(
                                  _fullNameController.text,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Position
                                Text(
                                  _positionController.text,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Edit Button
                                if (!_isEditing)
                                  _buildButton(
                                    label: 'Edit Details',
                                    color: AppColors.accentGreen,
                                    icon: Icons.edit_outlined,
                                    onTap: _toggleEdit,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Details Form
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            borderRadius: 24,
                            color: Colors.black.withValues(alpha: 0.15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailField(
                                  controller: _fullNameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  enabled: _isEditing,
                                ),
                                const SizedBox(height: 14),
                                _buildDetailField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _buildDetailField(
                                  controller: _positionController,
                                  label: 'Position',
                                  icon: Icons.badge_outlined,
                                  enabled: _isEditing,
                                ),
                                const SizedBox(height: 14),
                                _buildDetailField(
                                  controller: _contactController,
                                  label: 'Contact No',
                                  icon: Icons.phone_outlined,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _buildDetailField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.account_circle_outlined,
                                  enabled: _isEditing,
                                ),
                                if (_isEditing) ...[
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildButton(
                                          label: 'Save',
                                          color: const Color(0xFF4CAF50),
                                          onTap: _saveChanges,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildButton(
                                          label: 'Cancel',
                                          color: const Color(0xFFE57373),
                                          onTap: _cancelEdit,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Delete Button
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            borderRadius: 24,
                            color: Colors.black.withValues(alpha: 0.15),
                            child: _buildButton(
                              label: 'Delete Admin',
                              color: const Color(0xFFE57373),
                              icon: Icons.delete_outline,
                              onTap: _deleteAdmin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Navigation Bar
            Positioned(
              bottom: 18,
              left: 12,
              right: 12,
              child: GlassBottomNavBar(
                activeIndex: -1,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                      (route) => false,
                    );
                  } else if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MenuPage()),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfilePage(userId: widget.admin.id, role: 'admin'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.dropdownColor
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? AppColors.highlightGreen.withValues(alpha: 0.5)
                  : AppColors.highlightGreen.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: Icon(
                icon,
                color: enabled
                    ? AppColors.highlightGreen
                    : AppColors.highlightGreen.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
