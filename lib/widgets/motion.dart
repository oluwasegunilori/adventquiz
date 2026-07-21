import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offset = const Offset(0, 0.12),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds / (duration + delay).inMilliseconds,
        1,
        curve: curve,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              offset.dx * 40 * (1 - value),
              offset.dy * 40 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Interval(
        delay.inMilliseconds /
            math.max(1, (duration + delay).inMilliseconds),
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, value, child) {
        final v = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.86 + (0.14 * v), child: child),
        );
      },
      child: child,
    );
  }
}

class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.active = true,
    this.minScale = 0.97,
    this.maxScale = 1.03,
  });

  final Widget child;
  final bool active;
  final double minScale;
  final double maxScale;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale =
            widget.minScale + (widget.maxScale - widget.minScale) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.particleCount = 42});

  final int particleCount;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final List<_Particle> _particles = List.generate(
    widget.particleCount,
    (i) {
      final rng = math.Random(i * 17 + 3);
      return _Particle(
        color: [
          AppColors.clay,
          AppColors.forest,
          AppColors.claySoft,
          const Color(0xFFD4A017),
          const Color(0xFF3B7EA1),
        ][i % 5],
        x: rng.nextDouble(),
        speed: 0.35 + rng.nextDouble() * 0.9,
        drift: (rng.nextDouble() - 0.5) * 0.35,
        size: 5 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 6,
      );
    },
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: Curves.easeOut.transform(_controller.value),
              particles: _particles,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.color,
    required this.x,
    required this.speed,
    required this.drift,
    required this.size,
    required this.spin,
  });

  final Color color;
  final double x;
  final double speed;
  final double drift;
  final double size;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final y = -20 + (size.height + 40) * progress * p.speed;
      final x = size.width * p.x + p.drift * size.width * progress;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * progress * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
