import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class MuteButton extends StatelessWidget {
  const MuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = context.watch<SoundService>();
    return IconButton(
      tooltip: sounds.muted ? 'Unmute' : 'Mute',
      onPressed: () {
        sounds.toggleMute();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          sounds.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          key: ValueKey(sounds.muted),
          color: AppColors.forestDeep,
        ),
      ),
    );
  }
}
