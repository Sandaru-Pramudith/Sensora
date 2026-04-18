// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';
import 'models/notification_model.dart';
import 'services/sensora_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _api = SensoraApi();
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;

  final List<String> _filters = ['All', 'Alerts', 'Devices', 'System'];

  String get _selectedFilter => _filters[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await _api.getNotifications(limit: 100);
      setState(() {
        _notifications = raw.map(NotificationModel.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    try {
      await _api.markNotificationRead(n.id);
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx != -1) _notifications[idx] = n.copyWith(isRead: true);
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel n) async {
    try {
      await _api.deleteNotification(n.id);
      setState(() => _notifications.removeWhere((x) => x.id == n.id));
    } catch (_) {}
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  List<NotificationModel> get _filtered {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((n) => n.tabCategory == _selectedFilter).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: const [
          Color(0xFF143C28), Color(0xFF1A532F), Color(0xFF2B7A48),
        ],
        particleCount: 20,
        particleColor: AppColors.particleColor,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
            Positioned(
              bottom: 18, left: 12, right: 12,
              child: GlassBottomNavBar(
                activeIndex: -1,
                onTap: (i) => _handleNav(context, i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.headerGreen,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          _glassBack(context),
          const Expanded(
            child: Text('Notifications',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          // Mark-all-read button + unread badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_unreadCount > 0)
                GestureDetector(
                  onTap: _markAllRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Mark all read',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                const SizedBox(width: 8),
              const SizedBox(width: 6),
              if (_unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text('$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(24)),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: _filters.map((f) => Tab(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(f),
          ))).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGreen));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_outlined, size: 56, color: Colors.white.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('Could not reach backend', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh, color: AppColors.accentGreen),
            label: const Text('Retry', style: TextStyle(color: AppColors.accentGreen)),
          ),
        ]),
      );
    }
    if (_filtered.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppColors.accentGreen,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('No notifications', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6))),
      ]),
    );
  }

  Widget _buildCard(NotificationModel n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => _deleteNotification(n),
        child: GestureDetector(
          onTap: () {
            _markRead(n);
            _showDetail(n);
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            color: n.isRead
                ? Colors.black.withOpacity(0.1)
                : Colors.white.withOpacity(0.12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: n.severityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n.icon, color: n.severityColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.white,
                              )),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF6BCB5B), shape: BoxShape.circle),
                          ),
                      ]),
                      const SizedBox(height: 6),
                      Text(n.message,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), height: 1.3),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: n.severityColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(n.tabCategory,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: n.severityColor)),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(n.timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(NotificationModel n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.modalBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 50, height: 50,
                decoration: BoxDecoration(color: n.severityColor.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                child: Icon(n.icon, color: n.severityColor, size: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(n.tabCategory, style: TextStyle(fontSize: 12, color: n.severityColor)),
              ])),
            ]),
            const SizedBox(height: 20),
            Text(n.message, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(n.timeAgo, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _glassBack(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppColors.glassBlur, sigmaY: AppColors.glassBlur),
        child: Container(
          width: AppColors.headerActionSize, height: AppColors.headerActionSize,
          decoration: BoxDecoration(
            color: AppColors.textWhite.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textWhite.withOpacity(AppColors.glassBorderOpacity), width: AppColors.glassBorderWidth),
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite, size: AppColors.iconMd),
          ),
        ),
      ),
    );
  }

  void _handleNav(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const DashboardPage()), (r) => false);
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage()));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProfilePage(userId: '', role: '')));
    }
  }
}
