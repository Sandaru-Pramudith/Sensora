import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

const Color _headerGreen = Color(0xB31B3F2B);

class AlertThresholdSettingsPage extends StatefulWidget {
  const AlertThresholdSettingsPage({super.key});

  @override
  State<AlertThresholdSettingsPage> createState() =>
      _AlertThresholdSettingsPageState();
}

class _AlertThresholdSettingsPageState extends State<AlertThresholdSettingsPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _particleController;
  late final List<Particle> _particles;

  final math.Random _rand = math.Random();

  int _freshToRipe = 0; // 0: Low, 1: Medium, 2: High
  int _ripeToSpoil = 0; // 0: Low, 1: Medium, 2: High

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _particles = List.generate(36, (i) => _randomParticle());
  }

  Particle _randomParticle() {
    return Particle(
      position: Offset(_rand.nextDouble(), _rand.nextDouble()),
      radius: 2 + _rand.nextDouble() * 6,
      color: Colors.greenAccent.withOpacity(0.25 + _rand.nextDouble() * 0.6),
      velocity: Offset(
        (_rand.nextDouble() - 0.5) * 0.002,
        (_rand.nextDouble() - 0.5) * 0.002,
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          _animatedBackground(),
          _buildParticles(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ).copyWith(bottom: 120),
                    children: [const SizedBox(height: 8), _buildCard()],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: const BoxDecoration(
        color: _headerGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: _backButton(context)),
            Center(
              child: Text(
                'Alert Threshold\nSettings',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlur,
          sigmaY: AppColors.glassBlur,
        ),
        child: Container(
          width: AppColors.headerActionSize,
          height: AppColors.headerActionSize,
          decoration: BoxDecoration(
            color: AppColors.textWhite.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textWhite.withOpacity(
                AppColors.glassBorderOpacity,
              ),
              width: AppColors.glassBorderWidth,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textWhite,
              size: AppColors.iconMd,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      color: Colors.white.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fresh To Ripe Threshold',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _radioRow('Low', 0, forFresh: true),
          const SizedBox(height: 8),
          _radioRow('Medium', 1, forFresh: true),
          const SizedBox(height: 8),
          _radioRow('High', 2, forFresh: true),
          const SizedBox(height: 12),
          Divider(color: Colors.green.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'Ripe To Spoil Threshold',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _radioRow('Low Sensitivity', 0, forFresh: false),
          const SizedBox(height: 8),
          _radioRow('Medium Sensitivity', 1, forFresh: false),
          const SizedBox(height: 8),
          _radioRow('High Sensitivity', 2, forFresh: false),
        ],
      ),
    );
  }

  Widget _radioRow(String label, int value, {required bool forFresh}) {
    final group = forFresh ? _freshToRipe : _ripeToSpoil;
    return InkWell(
      onTap: () {
        setState(() {
          if (forFresh) {
            _freshToRipe = value;
          } else {
            _ripeToSpoil = value;
          }
        });
      },
      child: Row(
        children: [
          Radio<int>(
            value: value,
            groupValue: group,
            onChanged: (v) {
              setState(() {
                if (forFresh) {
                  _freshToRipe = v ?? 0;
                } else {
                  _ripeToSpoil = v ?? 0;
                }
              });
            },
            activeColor: Colors.greenAccent[200],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: SizedBox(
          height: 64,
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
                      userId: (UserSession.userId ?? '').trim(),
                      role: (UserSession.role ?? '').trim(),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// ANIMATED BACKGROUND
  Widget _animatedBackground() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final v = _floatingController.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 15, 47, 30),
                Color.lerp(
                  const Color.fromARGB(255, 16, 44, 18),
                  const Color.fromARGB(255, 23, 68, 34),
                  (math.sin(v) + 1) / 2,
                )!,
                const Color.fromARGB(255, 27, 94, 58),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: MeshGradientPainter(_floatingController.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  /// FLOATING PARTICLES
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _particleController.value),
          size: Size.infinite,
        );
      },
    );
  }
}

// Simple particle classes used by the page's painter.
class Particle {
  Offset position;
  double radius;
  Color color;
  Offset velocity;

  Particle({
    required this.position,
    required this.radius,
    required this.color,
    required this.velocity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;
    for (var p in particles) {
      final pos = Offset(
        (p.position.dx + p.velocity.dx * progress * 60) * size.width,
        (p.position.dy + p.velocity.dy * progress * 60) * size.height,
      );
      paint.color = p.color;
      canvas.drawCircle(pos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Placeholder mesh painter used by the header animation (keeps file self-contained).
class MeshGradientPainter extends CustomPainter {
  final double progress;
  MeshGradientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
