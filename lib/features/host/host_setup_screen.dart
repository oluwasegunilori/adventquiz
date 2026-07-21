import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/pack_loader.dart';
import '../../data/room_repository.dart';
import '../../models/quiz_pack.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/mute_button.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final _nameController = TextEditingController(text: 'Host');
  List<QuizPack> _packs = [];
  QuizPack? _selected;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final packs = await PackLoader().loadAll();
      setState(() {
        _packs = packs;
        _selected = packs.isNotEmpty ? packs.first : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final pack = _selected;
    if (pack == null) return;
    context.read<SoundService>().play(GameSound.click);
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final repo = context.read<RoomRepository>();
      final room = await repo.createRoom(
        pack: pack,
        hostNickname: _nameController.text,
      );
      if (!mounted) return;
      context.go('/room/${room.id}?host=1');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _creating = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: MaxWidth(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
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
                      Text(
                        'Host a game',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick a pack, share the PIN, and lead the room.',
                        style: TextStyle(color: AppColors.mist),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your display name',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Question pack',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _packs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pack = _packs[index];
                            final selected = _selected?.id == pack.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context
                                    .read<SoundService>()
                                    .play(GameSound.click);
                                setState(() => _selected = pack);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.forest.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.forest
                                        : AppColors.mist.withValues(alpha: 0.3),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pack.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pack.description,
                                      style: TextStyle(
                                        color: AppColors.mist,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${pack.questions.length} questions',
                                      style: const TextStyle(
                                        color: AppColors.forestDeep,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.wrong),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _creating ? null : _create,
                        child: Text(_creating ? 'Creating…' : 'Create room'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
