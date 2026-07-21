import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sound_service.dart';

/// Bouncy tap target that unlocks web audio + plays a UI click.
class BounceTap extends StatefulWidget {
  const BounceTap({
    super.key,
    required this.child,
    required this.onTap,
    this.enabled = true,
    this.sound = GameSound.click,
    this.playSound = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final GameSound sound;
  final bool playSound;

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 0.9)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.9, end: 1.08)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.08, end: 1)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
  ]).animate(_controller);

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onTap == null) return;
    final sounds = context.read<SoundService>();
    await sounds.unlock();
    if (widget.playSound) {
      await sounds.play(widget.sound);
    }
    _controller.forward(from: 0);
    widget.onTap!();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.enabled ? _handleTap : null,
          borderRadius: BorderRadius.circular(16),
          child: widget.child,
        ),
      ),
    );
  }
}
