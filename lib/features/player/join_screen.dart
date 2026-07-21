import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/room_repository.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/mute_button.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  bool _joining = false;
  String? _error;

  Future<void> _join() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'Enter the 6-digit PIN');
      return;
    }
    context.read<SoundService>().play(GameSound.click);
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final repo = context.read<RoomRepository>();
      final room = await repo.joinRoom(
        pin: pin,
        nickname: _nameController.text,
      );
      if (!mounted) return;
      context.read<SoundService>().play(GameSound.join);
      context.go('/room/${room.id}');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _joining = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: MaxWidth(
            width: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('← Home'),
                    ),
                    const Spacer(),
                    const MuteButton(),
                  ],
                ),
                const Spacer(),
                Text(
                  'Join game',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the PIN shown on the host screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mist),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'Game PIN',
                    hintText: '123456',
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _join(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'Your name',
                  ),
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _join(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.wrong),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _joining ? null : _join,
                  child: Text(_joining ? 'Joining…' : 'Join'),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
