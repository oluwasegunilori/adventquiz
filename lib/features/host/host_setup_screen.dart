import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/pack_loader.dart';
import '../../data/question_sheet_parser.dart';
import '../../data/room_repository.dart';
import '../../models/quiz_pack.dart';
import '../../theme/app_theme.dart';
import '../../utils/download_helper.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/bounce_buttons.dart';
import '../../widgets/bounce_tap.dart';
import '../../widgets/mute_button.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final _nameController = TextEditingController(text: 'Host');
  final _parser = QuestionSheetParser();
  List<QuizPack> _packs = [];
  QuizPack? _selected;
  QuizPack? _uploaded;
  bool _loading = true;
  bool _creating = false;
  bool _importing = false;
  String? _error;
  List<String> _warnings = [];

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

  Future<void> _downloadTemplate() async {
    downloadTextFile(
      'adventquiz_questions_template.csv',
      QuestionSheetParser.templateCsv,
    );
    await Clipboard.setData(
      ClipboardData(text: QuestionSheetParser.templateCsv),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template downloaded (and copied to clipboard)'),
      ),
    );
  }

  Future<void> _uploadSheet() async {
    setState(() {
      _importing = true;
      _error = null;
      _warnings = [];
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _importing = false);
        return;
      }
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw PackParseException(
          'Could not read that file. Try CSV export from Excel/Sheets.',
        );
      }
      final imported = _parser.parseBytes(
        bytes: bytes,
        filename: file.name,
      );
      setState(() {
        _uploaded = imported.pack;
        _selected = imported.pack;
        _warnings = imported.warnings;
        _importing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _importing = false;
      });
    }
  }

  Future<void> _create() async {
    final pack = _selected;
    if (pack == null) return;
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
                        'Pick a pack or upload your own spreadsheet, then share the PIN.',
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
                        'Your questions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          BounceOutlinedButton(
                            onPressed: _importing ? null : _uploadSheet,
                            child: Text(
                              _importing
                                  ? 'Reading…'
                                  : 'Upload CSV / Excel',
                            ),
                          ),
                          TextButton(
                            onPressed: _downloadTemplate,
                            child: const Text('Download template'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Columns: question, choice_a–d, correct (A–D), optional verse & seconds',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.mist,
                            ),
                      ),
                      if (_uploaded != null) ...[
                        const SizedBox(height: 10),
                        _PackTile(
                          pack: _uploaded!,
                          selected: _selected?.id == _uploaded!.id,
                          badge: 'UPLOADED',
                          onTap: () => setState(() => _selected = _uploaded),
                        ),
                      ],
                      if (_warnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _warnings.take(3).join('\n'),
                          style: const TextStyle(
                            color: AppColors.clay,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Starter packs',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _packs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final pack = _packs[index];
                            return _PackTile(
                              pack: pack,
                              selected: _selected?.id == pack.id,
                              onTap: () => setState(() => _selected = pack),
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
                      BounceFilledButton(
                        onPressed: _creating || _selected == null
                            ? null
                            : _create,
                        child: Text(
                          _creating ? 'Creating…' : 'Create room',
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

class _PackTile extends StatelessWidget {
  const _PackTile({
    required this.pack,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final QuizPack pack;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    pack.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (badge != null)
                  Text(
                    badge!,
                    style: const TextStyle(
                      color: AppColors.clay,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
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
  }
}
