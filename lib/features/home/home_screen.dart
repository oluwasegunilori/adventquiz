import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/bounce_buttons.dart';
import '../../widgets/motion.dart';
import '../../widgets/mute_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.usingFirebase = false});

  final bool usingFirebase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: MuteButton(),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  child: Text(
                    'AdventQuiz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Live Bible trivia for your Sabbath class, youth group, or living room.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.mist,
                          height: 1.4,
                        ),
                  ),
                ),
                const Spacer(),
                PopIn(
                  delay: const Duration(milliseconds: 180),
                  child: BounceFilledButton(
                    onPressed: () => context.go('/host'),
                    child: const Text('Host a game'),
                  ),
                ),
                const SizedBox(height: 14),
                PopIn(
                  delay: const Duration(milliseconds: 260),
                  child: BounceOutlinedButton(
                    onPressed: () => context.go('/join'),
                    child: const Text('Join with PIN'),
                  ),
                ),
                const Spacer(),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  child: Text(
                    usingFirebase
                        ? 'Online rooms ready'
                        : 'Local demo mode — same browser works across tabs. Add Firebase for devices worldwide.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mist,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
