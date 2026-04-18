import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final List<Color> gradientColors;
  final int particleCount;
  final Color particleColor;

  const AnimatedBackground({
    super.key,
    this.child,
    this.gradientColors = AppColors.backgroundGradient,
    this.particleCount = 20,
    this.particleColor = AppColors.particleColor,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;
  late final List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => Particle());
    _particleController = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) => CustomPaint(
              painter: ParticlePainter(
                _particles,
                _particleController.value,
                widget.particleColor,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class Particle {
  final math.Random _random = math.Random();
  late double x = _random.nextDouble();
  late double y = _random.nextDouble();
  late double phase = _random.nextDouble() * math.pi * 2;
  late double size = _random.nextDouble() * 3.5 + 1.5;
  late double speedX = (_random.nextDouble() - 0.5) * 0.00045;
  late double speedY = (_random.nextDouble() - 0.5) * 0.00045;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter(this.particles, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      p.x = (p.x + p.speedX) % 1.0;
      p.y = (p.y + p.speedY) % 1.0;
      final twinkle = (math.sin((progress * math.pi * 2) + p.phase) + 1) / 2;
      paint.color = color.withValues(alpha: 0.10 + (twinkle * 0.16));
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
