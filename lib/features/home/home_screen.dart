import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/bounce_buttons.dart';
import '../../widgets/motion.dart';
import '../../widgets/mute_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.usingFirebase = false});

  final bool usingFirebase;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SoundService>().setMusic(MusicBed.lounge));
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

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
                SizedBox(height: compact ? 12 : 8),
                FadeSlideIn(
                  child: Text(
                    'AdventQuiz',
                    textAlign: TextAlign.center,
                    style: (compact
                            ? Theme.of(context).textTheme.headlineLarge
                            : Theme.of(context).textTheme.displaySmall)
                        ?.copyWith(letterSpacing: -0.5),
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
                          fontSize: compact ? 15 : null,
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
                const SizedBox(height: 12),
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
                    widget.usingFirebase
                        ? 'Online rooms ready'
                        : 'Local demo mode — same browser works across tabs.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mist,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
