import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// Soft decorative wanderers behind the UI (never blocks taps).
class WanderingAmbience extends StatefulWidget {
  const WanderingAmbience({super.key});

  @override
  State<WanderingAmbience> createState() => _WanderingAmbienceState();
}

class _WanderingAmbienceState extends State<WanderingAmbience>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  final _rng = math.Random(42);
  late final List<_Wanderer> _sprites;
  int _spriteCount = 9;

  @override
  void initState() {
    super.initState();
    _sprites = List.generate(_spriteCount, (i) => _Wanderer.spawn(_rng, i));
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_size == Size.zero || dt <= 0 || dt > 0.1) {
      if (mounted) setState(() {});
      return;
    }
    final desired = _size.width < 600 ? 5 : 9;
    if (desired != _spriteCount) {
      _spriteCount = desired;
      if (_sprites.length > desired) {
        _sprites.removeRange(desired, _sprites.length);
      } else {
        while (_sprites.length < desired) {
          _sprites.add(_Wanderer.spawn(_rng, _sprites.length));
        }
      }
    }
    for (final s in _sprites) {
      s.step(dt, _size, _rng);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = constraints.maxWidth < 600;
        return IgnorePointer(
          child: Stack(
            children: [
              for (final s in _sprites)
                Positioned(
                  left: s.pos.dx - s.size / 2,
                  top: s.pos.dy - s.size / 2,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scaleByDouble(
                        s.facingRight ? 1.0 : -1.0,
                        1.0,
                        1.0,
                        1.0,
                      )
                      ..rotateZ(s.tilt),
                    child: Opacity(
                      opacity: compact ? s.opacity * 0.85 : s.opacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: s.color.withValues(alpha: 0.35),
                              blurRadius: compact ? 12 : 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: Size(
                            compact ? s.size * 0.85 : s.size,
                            compact ? s.size * 0.85 : s.size,
                          ),
                          painter:
                              _SpritePainter(kind: s.kind, color: s.color),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _SpriteKind { book, star, fish, leaf, dove, note }

class _Wanderer {
  _Wanderer({
    required this.pos,
    required this.vel,
    required this.size,
    required this.kind,
    required this.color,
    required this.opacity,
    required this.bobPhase,
  });

  Offset pos;
  Offset vel;
  final double size;
  final _SpriteKind kind;
  final Color color;
  final double opacity;
  double bobPhase;
  double tilt = 0;
  bool facingRight = true;

  factory _Wanderer.spawn(math.Random rng, int index) {
    const kinds = _SpriteKind.values;
    final palette = [
      AppColors.forest.withValues(alpha: 0.92),
      AppColors.clay.withValues(alpha: 0.9),
      AppColors.forestDeep.withValues(alpha: 0.88),
      AppColors.claySoft.withValues(alpha: 0.9),
      const Color(0xFF3B7EA1).withValues(alpha: 0.9),
      AppColors.mist.withValues(alpha: 0.85),
    ];
    // Prefer edges so the center UI stays clear.
    final alongEdge = index % 2 == 0;
    final pos = alongEdge
        ? Offset(
            rng.nextBool()
                ? rng.nextDouble() * 0.2
                : 0.8 + rng.nextDouble() * 0.18,
            0.08 + rng.nextDouble() * 0.84,
          )
        : Offset(
            0.08 + rng.nextDouble() * 0.84,
            rng.nextBool()
                ? rng.nextDouble() * 0.18
                : 0.82 + rng.nextDouble() * 0.16,
          );
    final speed = 32 + rng.nextDouble() * 40;
    final angle = rng.nextDouble() * math.pi * 2;
    return _Wanderer(
      pos: pos, // normalized until first layout; step converts
      vel: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      size: 40 + rng.nextDouble() * 28,
      kind: kinds[index % kinds.length],
      color: palette[index % palette.length],
      opacity: 0.38 + rng.nextDouble() * 0.18,
      bobPhase: rng.nextDouble() * math.pi * 2,
    );
  }

  bool _normalized = true;

  void step(double dt, Size bounds, math.Random rng) {
    if (_normalized) {
      pos = Offset(pos.dx * bounds.width, pos.dy * bounds.height);
      _normalized = false;
    }

    bobPhase += dt * 3.2;
    final bob = math.sin(bobPhase) * 16;
    tilt = math.sin(bobPhase * 0.85) * 0.18;

    pos += vel * dt + Offset(0, bob * dt);

    final margin = bounds.width * 0.02;
    final half = size / 2;
    final minX = margin + half;
    final maxX = bounds.width - margin - half;
    final minY = margin + half;
    final maxY = bounds.height - margin - half;

    // Soft bounce; nudge toward edges if drifting mid-screen too long.
    if (pos.dx < minX) {
      pos = Offset(minX, pos.dy);
      vel = Offset(vel.dx.abs(), vel.dy);
    } else if (pos.dx > maxX) {
      pos = Offset(maxX, pos.dy);
      vel = Offset(-vel.dx.abs(), vel.dy);
    }
    if (pos.dy < minY) {
      pos = Offset(pos.dx, minY);
      vel = Offset(vel.dx, vel.dy.abs());
    } else if (pos.dy > maxY) {
      pos = Offset(pos.dx, maxY);
      vel = Offset(vel.dx, -vel.dy.abs());
    }

    // Gentle steering away from dead-center so UI stays readable.
    final cx = bounds.width / 2;
    final cy = bounds.height / 2;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final clearRadius = math.min(bounds.width, bounds.height) * 0.14;
    if (dist < clearRadius && dist > 1) {
      vel += Offset(dx / dist, dy / dist) * (55 * dt);
    }

    // Occasional gentle turn so paths feel alive.
    if (rng.nextDouble() < dt * 0.55) {
      final turn = (rng.nextDouble() - 0.5) * 1.1;
      final cos = math.cos(turn);
      final sin = math.sin(turn);
      vel = Offset(vel.dx * cos - vel.dy * sin, vel.dx * sin + vel.dy * cos);
    }

    // Cap speed
    final spd = vel.distance;
    final target = 28.0 + (kind.index % 3) * 12;
    if (spd > 1) {
      vel = vel / spd * (spd * 0.97 + target * 0.03);
    }

    facingRight = vel.dx >= 0;
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter({required this.kind, required this.color});

  final _SpriteKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    switch (kind) {
      case _SpriteKind.book:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: r * 1.6, height: r * 1.3),
          Radius.circular(r * 0.15),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
          Offset(c.dx, c.dy - r * 0.55),
          Offset(c.dx, c.dy + r * 0.55),
          stroke..color = Colors.white.withValues(alpha: 0.55),
        );
      case _SpriteKind.star:
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 4 * math.pi / 5;
          final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      case _SpriteKind.fish:
        final body = Path()
          ..moveTo(c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy - r * 0.9, c.dx + r * 0.55, c.dy)
          ..quadraticBezierTo(c.dx, c.dy + r * 0.9, c.dx - r, c.dy)
          ..close();
        canvas.drawPath(body, paint);
        final tail = Path()
          ..moveTo(c.dx + r * 0.45, c.dy)
          ..lineTo(c.dx + r * 1.15, c.dy - r * 0.55)
          ..lineTo(c.dx + r * 1.15, c.dy + r * 0.55)
          ..close();
        canvas.drawPath(tail, paint);
        canvas.drawCircle(
          Offset(c.dx - r * 0.35, c.dy - r * 0.12),
          r * 0.12,
          Paint()..color = Colors.white.withValues(alpha: 0.7),
        );
      case _SpriteKind.leaf:
        final leaf = Path()
          ..moveTo(c.dx, c.dy + r)
          ..quadraticBezierTo(c.dx + r, c.dy, c.dx, c.dy - r)
          ..quadraticBezierTo(c.dx - r, c.dy, c.dx, c.dy + r)
          ..close();
        canvas.drawPath(leaf, paint);
        canvas.drawLine(
          Offset(c.dx, c.dy + r * 0.85),
          Offset(c.dx, c.dy - r * 0.7),
          stroke..color = Colors.white.withValues(alpha: 0.45),
        );
      case _SpriteKind.dove:
        final wing = Path()
          ..moveTo(c.dx - r * 0.2, c.dy)
          ..quadraticBezierTo(c.dx - r, c.dy - r * 0.9, c.dx + r * 0.2, c.dy - r * 0.2)
          ..quadraticBezierTo(c.dx + r * 0.9, c.dy - r * 0.1, c.dx + r, c.dy + r * 0.2)
          ..quadraticBezierTo(c.dx + r * 0.2, c.dy + r * 0.35, c.dx - r * 0.2, c.dy)
          ..close();
        canvas.drawPath(wing, paint);
        canvas.drawCircle(Offset(c.dx + r * 0.55, c.dy - r * 0.05), r * 0.22, paint);
      case _SpriteKind.note:
        canvas.drawCircle(Offset(c.dx - r * 0.25, c.dy + r * 0.35), r * 0.32, paint);
        canvas.drawCircle(Offset(c.dx + r * 0.35, c.dy + r * 0.15), r * 0.28, paint);
        canvas.drawLine(
          Offset(c.dx - r * 0.25 + r * 0.28, c.dy + r * 0.35),
          Offset(c.dx - r * 0.25 + r * 0.28, c.dy - r * 0.7),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx + r * 0.35 + r * 0.24, c.dy + r * 0.15),
          Offset(c.dx + r * 0.35 + r * 0.24, c.dy - r * 0.85),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx - r * 0.25 + r * 0.28, c.dy - r * 0.7),
          Offset(c.dx + r * 0.35 + r * 0.24, c.dy - r * 0.85),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
