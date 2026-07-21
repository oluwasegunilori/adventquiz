import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class AnswerButton extends StatefulWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
    this.revealCorrect,
    this.symbol,
    this.entranceDelay = Duration.zero,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;
  final bool? revealCorrect;
  final String? symbol;
  final Duration entranceDelay;

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton>
    with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _bounceScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 0.9), weight: 35),
    TweenSequenceItem(
      tween: Tween(begin: 0.9, end: 1.08)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 65,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 30),
  ]).animate(_bounce);

  @override
  void didUpdateWidget(covariant AnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealCorrect == false &&
        widget.selected &&
        oldWidget.revealCorrect != false) {
      _shake.forward(from: 0);
    }
    if (widget.revealCorrect == true && oldWidget.revealCorrect != true) {
      _bounce.forward(from: 0);
    }
  }

  Future<void> _onTap() async {
    if (!widget.enabled || widget.onTap == null) return;
    final sounds = context.read<SoundService>();
    await sounds.unlock();
    await sounds.play(GameSound.select);
    _bounce.forward(from: 0);
    widget.onTap!();
  }

  @override
  void dispose() {
    _shake.dispose();
    _bounce.dispose();
    super.dispose();
  }

  Color get _bg {
    if (widget.revealCorrect == true) return AppColors.correct;
    if (widget.revealCorrect == false && widget.selected) {
      return AppColors.wrong;
    }
    return widget.color;
  }

  @override
  Widget build(BuildContext context) {
    final revealPop = widget.revealCorrect == true;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          Duration(milliseconds: 380 + widget.entranceDelay.inMilliseconds),
      curve: Interval(
        widget.entranceDelay.inMilliseconds /
            (380 + widget.entranceDelay.inMilliseconds).clamp(1, 9999),
        1,
        curve: Curves.easeOutBack,
      ),
      builder: (context, value, child) {
        final v = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.scale(scale: 0.9 + 0.1 * v, child: child),
        );
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_shake, _bounce]),
        builder: (context, child) {
          final t = _shake.value;
          final dx = (t < 1 ? (1 - t) : 0.0) *
              8 *
              ((t * 18).floor().isEven ? 1.0 : -1.0);
          final scale = _bounceScale.value *
              (widget.selected && !revealPop ? 1.03 : (revealPop ? 1.04 : 1));
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (revealPop || widget.selected)
                BoxShadow(
                  color: _bg.withValues(alpha: 0.35),
                  blurRadius: revealPop ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Material(
            color: _bg,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.enabled ? _onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 72),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: widget.selected || revealPop
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
                child: Row(
                  children: [
                    if (widget.symbol != null) ...[
                      Text(
                        widget.symbol!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (revealPop)
                      const Icon(Icons.check_circle, color: Colors.white)
                    else if (widget.revealCorrect == false && widget.selected)
                      const Icon(Icons.cancel, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
