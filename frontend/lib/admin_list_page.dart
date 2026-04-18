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
import 'admin_details_page.dart';

/// Model class for admin member data
class AdminMember {
  final String id;
  final String fullName;
  final String position;
  final String email;
  final String contact;
  final String username;

  AdminMember({
    required this.id,
    required this.fullName,
    required this.position,
    required this.email,
    required this.contact,
    required this.username,
  });

  factory AdminMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminMember(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      position: data['position'] ?? '',
      email: data['email'] ?? '',
      contact: data['contactNo'] ?? '',
      username: data['username'] ?? '',
    );
  }
}

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AdminMember> _adminMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    try {
      final snapshot = await _firestore.collection('admins').get();
      setState(() {
        _adminMembers = snapshot.docs
            .map((doc) => AdminMember.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading admins: $e')),
        );
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
                      title: 'Admin Members',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Admin List
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accentGreen,
                            ),
                          )
                        : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'All Admins',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${_adminMembers.length} members',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_adminMembers.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'No admin members found',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _adminMembers.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final admin = _adminMembers[index];
                                return _buildAdminCard(admin);
                              },
                            ),
                          ],
                        ),
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
                        builder: (_) => ProfilePage(
                          userId: 'admin', // Replace with actual userId if available
                          role: 'admin',   // Replace with actual role if needed
                        ),
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

  Widget _buildAdminCard(AdminMember admin) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminDetailsPage(admin: admin)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.highlightGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with admin badge
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      admin.fullName.split(' ').map((e) => e[0]).take(2).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Name and Position
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    admin.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.position,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
