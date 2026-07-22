import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/room_repository.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/bounce_buttons.dart';
import '../../widgets/mute_button.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.initialPin});

  final String? initialPin;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final TextEditingController _pinController;
  final _nameController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final pin = (widget.initialPin ?? '').replaceAll(RegExp(r'\D'), '');
    _pinController = TextEditingController(
      text: pin.length > 6 ? pin.substring(0, 6) : pin,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SoundService>().setMusic(MusicBed.lounge));
    });
  }

  Future<void> _join() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      setState(() => _error = 'Enter the 6-digit PIN');
      return;
    }
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
    final compact = context.isCompact;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 12 : 0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(),
                                Text(
                                  'Join game',
                                  textAlign: TextAlign.center,
                                  style: compact
                                      ? Theme.of(context).textTheme.headlineSmall
                                      : Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter the PIN shown on the host screen.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.mist,
                                    fontSize: compact ? 14 : null,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _pinController,
                                  decoration: InputDecoration(
                                    labelText: 'Game PIN',
                                    hintText: '6-digit code',
                                    hintStyle: TextStyle(
                                      color: AppColors.mist.withValues(alpha: 0.45),
                                      fontSize: compact ? 22 : 24,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: compact ? 2 : 3,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 28 : 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: compact ? 6 : 8,
                                    color: AppColors.ink,
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
                                  autofocus:
                                      (widget.initialPin ?? '').isNotEmpty,
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
                                BounceFilledButton(
                                  onPressed: _joining ? null : _join,
                                  child: Text(_joining ? 'Joining…' : 'Join'),
                                ),
                                const Spacer(flex: 2),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
