// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

/// Help & FAQs page with FAQ and Contact Us tabs
class HelpFaqsPage extends StatefulWidget {
  const HelpFaqsPage({super.key});

  @override
  State<HelpFaqsPage> createState() => _HelpFaqsPageState();
}

class _HelpFaqsPageState extends State<HelpFaqsPage> {
    int _selectedTab = 0; // 0 = FAQ, 1 = Contact Us
  int _selectedCategory = 0; // 0 = General, 1 = Account, 2 = Services
  final TextEditingController _searchController = TextEditingController();

  // FAQ Data
  final Map<int, List<Map<String, String>>> _faqData = {
    0: [
      // General
      {
        'question': 'How to use this app?',
        'answer':
            'Download the app, create an account, and connect your sensors. The dashboard will display real-time data from all connected devices. Navigate using the bottom menu to access reports, alerts, and settings.',
      },
      {
        'question': 'How often is data updated?',
        'answer':
            'Sensor data is updated every 5 seconds for real-time monitoring. Historical reports are generated daily at midnight. You can also manually refresh data by pulling down on any data screen.',
      },
      {
        'question': 'How to contact support?',
        'answer':
            'You can reach our support team via email at sensora2026@gmail.com, call us at +94 XX XXX XXXX (Mon-Fri, 9 AM - 6 PM), or use the in-app chat feature for instant assistance.',
      },
      {
        'question': 'Can I use the app offline?',
        'answer':
            'Yes, you can view previously cached data offline. However, real-time sensor updates and report generation require an active internet connection. Data will sync automatically when you reconnect.',
      },
    ],
    1: [
      // Account
      {
        'question': 'How can I reset my password if I forget it?',
        'answer':
            'Tap "Forgot Password" on the login screen, enter your registered email, and we\'ll send you a password reset link. The link expires in 24 hours for security purposes.',
      },
      {
        'question': 'How can I delete my account?',
        'answer':
            'Go to Settings > Account > Delete Account. You\'ll need to confirm your password. Note that this action is irreversible and all your data will be permanently deleted after 30 days.',
      },
      {
        'question': 'Can I change my username?',
        'answer':
            'Yes, go to Profile > Edit Profile > Username. You can change your username once every 30 days. Your user ID will remain the same.',
      },
    ],
    2: [
      // Services
      {
        'question': 'Are there any privacy or data security measures in place?',
        'answer':
            'Yes, we use end-to-end encryption for all data transmission. Your sensor data is stored on secure cloud servers with AES-256 encryption. We never share your data with third parties without consent.',
      },
      {
        'question': 'Can I customize settings within the application?',
        'answer':
            'Absolutely! Go to Settings to customize alert thresholds, notification preferences, display units (Celsius/Fahrenheit, etc.), and dashboard layout. You can also create custom reports.',
      },
      {
        'question': 'Can I turn alerts off?',
        'answer':
            'Yes, you can manage alerts in Settings > Notifications. You can disable all alerts, mute specific sensor alerts, or set quiet hours. Critical system alerts cannot be fully disabled for safety.',
      },
    ],
  };

  final List<int> _expandedItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      title: 'Help & FAQS',
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
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Column(
                          children: [
                            // "How Can We Help You?" title
                            Text(
                              'How Can We Help You?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // FAQ / Contact Us tabs
                            _buildMainTabs(),
                            const SizedBox(height: 16),
                            // Category tabs (General, Account, Services)
                            _buildCategoryTabs(),
                            const SizedBox(height: 16),
                            // Search bar
                            _buildSearchBar(),
                            const SizedBox(height: 20),
                            // Content based on selected tab
                            _selectedTab == 0
                                ? _buildFaqList()
                                : _buildContactList(),
                          ],
                        ),
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
                      MaterialPageRoute(builder: (_) => ProfilePage(userId: 'yourUserId', role: 'yourRole')),
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

  Widget _buildMainTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? AppColors.accentGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'FAQ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedTab == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? AppColors.accentGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _selectedTab == 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['General', 'Account', 'Services'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(categories.length, (index) {
        final isSelected = _selectedCategory == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = index;
              _expandedItems.clear();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFaqList() {
    final faqs = _faqData[_selectedCategory] ?? [];
    final searchQuery = _searchController.text.toLowerCase();

    final filteredFaqs = faqs.where((faq) {
      if (searchQuery.isEmpty) return true;
      return faq['question']!.toLowerCase().contains(searchQuery) ||
          faq['answer']!.toLowerCase().contains(searchQuery);
    }).toList();

    return Column(
      children: List.generate(filteredFaqs.length, (index) {
        final faq = filteredFaqs[index];
        final isExpanded = _expandedItems.contains(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq['question']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      faq['answer']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContactList() {
    final contacts = [
      {
        'icon': Icons.support_agent,
        'label': 'Customer Service',
        'action': 'navigate',
      },
      {
        'icon': Icons.language,
        'label': 'Website',
        'url': 'https://www.sensora.com',
      },
      {
        'icon': Icons.facebook,
        'label': 'Facebook',
        'url': 'https://www.facebook.com/sensora',
      },
      {
        'icon': Icons.chat,
        'label': 'Whatsapp',
        'url': 'https://wa.me/94771234567',
      },
      {
        'icon': Icons.camera_alt,
        'label': 'Instagram',
        'url': 'https://www.instagram.com/sensora_official',
      },
    ];

    return Column(
      children: contacts.map((contact) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              if (contact['action'] == 'navigate') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerServicePage(),
                  ),
                );
              } else if (contact['url'] != null) {
                _launchUrl(contact['url'] as String);
              }
            },
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
                    child: Icon(
                      contact['icon'] as IconData,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      contact['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Customer Service detail page
class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});

  
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
                      title: 'Customer Service',
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
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              "We're Here To Help!",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Get support for app usage, sensors, alerts and data issues.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Contact Support label
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Email card
                            _buildContactCard(
                              context,
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: 'sensora2026@gmail.com',
                              info: 'Responses within 24 hours.',
                              onTap: () => _launchEmail(),
                            ),
                            const SizedBox(height: 12),
                            // Phone card
                            _buildContactCard(
                              context,
                              icon: Icons.phone_outlined,
                              title: 'Phone',
                              subtitle: '+94 XX XXX XXXX',
                              info: 'Mon-Fri | 9:00 AM - 6:00 PM',
                              onTap: () => _launchPhone(),
                            ),
                            const SizedBox(height: 12),
                            // In-App Chat card
                            _buildChatCard(context),
                          ],
                        ),
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
                      MaterialPageRoute(builder: (_) => ProfilePage(userId: 'yourUserId', role: 'yourRole')),
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

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String info,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 14,
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    info,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 14,
      color: Colors.white.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In-App Chat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fast help from our support team',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Start chat action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting chat...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Start chat',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:sensora2026@gmail.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+94771234567');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}


