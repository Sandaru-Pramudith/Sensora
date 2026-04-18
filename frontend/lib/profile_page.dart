// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'logout_pages.dart';

/// Profile page showing user info with Edit Profile and Logout options
class ProfilePage extends StatefulWidget {
  final String userId;
  final String role;

  const ProfilePage({super.key, this.userId = '', this.role = ''});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  late String _effectiveUserId;
  late String _effectiveRole;

  @override
  void initState() {
    super.initState();
    _resolveIdentity();
    _loadUserData();
  }

  bool _isPlaceholderUserId(String value) {
    final v = value.trim().toLowerCase();
    return v.isEmpty || v == 'youruserid' || v == 'null';
  }

  String _normalizeRole(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'admin' || v == 'staff') return v;
    return 'staff';
  }

  void _resolveIdentity() {
    final incomingUserId = widget.userId.trim();
    final incomingRole = widget.role.trim();

    final sessionUserId = (UserSession.userId ?? '').trim();
    final sessionRole = (UserSession.role ?? '').trim();

    if (sessionUserId.isNotEmpty) {
      _effectiveUserId = sessionUserId;
      _effectiveRole = _normalizeRole(
        sessionRole.isNotEmpty ? sessionRole : incomingRole,
      );
    } else {
      _effectiveUserId = _isPlaceholderUserId(incomingUserId)
          ? ''
          : incomingUserId;
      _effectiveRole = _normalizeRole(incomingRole);

      if (_effectiveUserId.isNotEmpty) {
        UserSession.setCurrentUser(
          userId: _effectiveUserId,
          role: _effectiveRole,
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_effectiveUserId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userData = null;
        });
      }
      return;
    }

    try {
      final collection = _effectiveRole == 'admin' ? 'admins' : 'staff';
      final doc = await _firestore
          .collection(collection)
          .doc(_effectiveUserId)
          .get();
      if (doc.exists) {
        setState(() {
          _userData = {'id': doc.id, ...doc.data()!};
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
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
                      title: 'Profile',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profile Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGreen,
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            child: Column(
                              children: [
                                // Profile Picture
                                _buildProfilePicture(),
                                const SizedBox(height: 16),
                                // Name and Role Badge
                                Text(
                                  _userData != null &&
                                          _userData!['fullName'] != null &&
                                          _userData!['fullName']
                                              .toString()
                                              .trim()
                                              .isNotEmpty
                                      ? _userData!['fullName']
                                      : (_userData != null &&
                                                _userData!['username'] !=
                                                    null &&
                                                _userData!['username']
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty
                                            ? _userData!['username']
                                            : 'Unknown User'),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _effectiveRole == 'admin'
                                        ? const Color(
                                            0xFF4CAF50,
                                          ).withValues(alpha: 0.2)
                                        : AppColors.accentGreen.withValues(alpha: 
                                            0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _effectiveRole == 'admin'
                                          ? const Color(
                                              0xFF4CAF50,
                                            ).withValues(alpha: 0.5)
                                          : AppColors.accentGreen.withValues(alpha: 
                                              0.5,
                                            ),
                                    ),
                                  ),
                                  child: Text(
                                    _effectiveRole.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _effectiveRole == 'admin'
                                          ? const Color(0xFF4CAF50)
                                          : AppColors.accentGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userData != null &&
                                          _userData!['position'] != null
                                      ? _userData!['position']
                                      : '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // User Info Card
                                GlassContainer(
                                  padding: const EdgeInsets.all(20),
                                  borderRadius: 24,
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child: Column(
                                    children: [
                                      _buildInfoRow(
                                        Icons.email_outlined,
                                        'Email',
                                        _userData != null &&
                                                _userData!['email'] != null
                                            ? _userData!['email']
                                            : '',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        Icons.phone_outlined,
                                        'Contact',
                                        _userData != null &&
                                                _userData!['contactNo'] != null
                                            ? _userData!['contactNo']
                                            : '',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        Icons.person_outline,
                                        'Username',
                                        _userData != null &&
                                                _userData!['username'] != null
                                            ? _userData!['username']
                                            : '',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Actions Card
                                GlassContainer(
                                  padding: const EdgeInsets.all(20),
                                  borderRadius: 24,
                                  color: Colors.black.withValues(alpha: 0.15),
                                  child: Column(
                                    children: [
                                      _buildActionItem(
                                        context,
                                        icon: Icons.person_outline,
                                        label: 'Edit Profile',
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditProfilePage(
                                                userId: _effectiveUserId,
                                                role: _effectiveRole,
                                                userData: _userData!,
                                              ),
                                            ),
                                          );
                                          // Reload user data after editing
                                          _loadUserData();
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildActionItem(
                                        context,
                                        icon: Icons.logout,
                                        label: 'Logout',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LogoutConfirmationPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              left: 12,
              right: 12,
              child: GlassBottomNavBar(
                activeIndex: 3,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardPage(
                          userId: _effectiveUserId,
                          role: _effectiveRole,
                        ),
                      ),
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
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.highlightGreen, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.highlightGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey[300],
          child: const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 14,
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.highlightGreen, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Edit Profile page with account settings form
class EditProfilePage extends StatefulWidget {
  final String userId;
  final String role;
  final Map<String, dynamic> userData;

  const EditProfilePage({
    super.key,
    required this.userId,
    required this.role,
    required this.userData,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _positionController;
  bool _pushNotifications = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.userData['fullName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['contactNo'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _positionController = TextEditingController(
      text: widget.userData['position'] ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final collection = widget.role == 'admin' ? 'admins' : 'staff';
      await _firestore.collection(collection).doc(widget.userId).update({
        'fullName': _fullNameController.text.trim(),
        'contactNo': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'position': _positionController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: AppColors.backgroundGradient,
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
                      title: 'Edit My Profile',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture with Camera
                          Center(child: _buildProfilePictureWithCamera()),
                          const SizedBox(height: 16),
                          // Name and ID
                          Center(
                            child: Text(
                              widget.userData['fullName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              '@${widget.userData['username'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Account Settings
                          const Text(
                            'Account Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Form Fields
                          GlassContainer(
                            padding: const EdgeInsets.all(20),
                            borderRadius: 24,
                            color: Colors.black.withValues(alpha: 0.15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputField(
                                  label: 'Full Name',
                                  controller: _fullNameController,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Position',
                                  controller: _positionController,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Phone',
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                // Push Notifications Toggle
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Push Notifications',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    Switch(
                                      value: _pushNotifications,
                                      onChanged: (value) {
                                        setState(() {
                                          _pushNotifications = value;
                                        });
                                      },
                                      activeColor: AppColors.highlightGreen,
                                      activeTrackColor: const Color(
                                        0xFF00FFA3,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Update Profile Button
                                Center(
                                  child: GestureDetector(
                                    onTap: _isSaving ? null : _saveChanges,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isSaving
                                            ? AppColors.accentGreen.withValues(alpha: 
                                                0.5,
                                              )
                                            : AppColors.accentGreen,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6BCB5B,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Update Profile',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              left: 12,
              right: 12,
              child: GlassBottomNavBar(
                activeIndex: 3,
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
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureWithCamera() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.highlightGreen, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.highlightGreen.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              // Open camera/gallery picker
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }
}
