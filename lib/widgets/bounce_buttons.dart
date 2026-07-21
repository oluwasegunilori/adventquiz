import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'bounce_tap.dart';

/// Bouncy primary / outline buttons matching AdventQuiz theme.
class BounceFilledButton extends StatelessWidget {
  const BounceFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.sound = GameSound.click,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final GameSound sound;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return BounceTap(
      enabled: enabled,
      sound: sound,
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class BounceOutlinedButton extends StatelessWidget {
  const BounceOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.sound = GameSound.click,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final GameSound sound;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return BounceTap(
      enabled: enabled,
      sound: sound,
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          constraints: const BoxConstraints(minWidth: 220, minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forest, width: 2),
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.forestDeep,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: AppColors.forestDeep),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
