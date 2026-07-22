import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/pack_loader.dart';
import '../../data/question_sheet_parser.dart';
import '../../data/room_repository.dart';
import '../../models/quiz_pack.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/download_helper.dart';
import '../../utils/pick_sheet_file.dart';
import '../../utils/responsive.dart';
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

  QuizPack? get _activePack => _uploaded ?? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SoundService>().setMusic(MusicBed.lounge));
    });
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
        content: Text('Template ready — open it in Excel or Sheets'),
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
      final file = await pickSheetFile();
      if (file == null) {
        setState(() => _importing = false);
        return;
      }
      final imported = _parser.parseBytes(
        bytes: file.bytes,
        filename: file.name,
      );
      setState(() {
        _uploaded = imported.pack;
        _selected = imported.pack;
        _warnings = imported.warnings;
        _importing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded ${imported.pack.questions.length} questions',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Bad state: ', '');
        _importing = false;
      });
    }
  }

  Future<void> _create() async {
    final pack = _activePack;
    if (pack == null) return;
    setState(() {
      _creating = true;
      _error = null;
      _selected = pack;
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

  void _selectStarter(QuizPack pack) {
    setState(() {
      _uploaded = null;
      _selected = pack;
      _warnings = [];
      _error = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _activePack;
    final compact = context.isCompact;
    final packCardWidth = compact ? 168.0 : 210.0;
    final packRowHeight = compact ? 172.0 : 188.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AtmosphereBackground(
        child: SafeArea(
          child: MaxWidth(
            width: 880,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
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
                              Text(
                                'Host a game',
                                style: compact
                                    ? Theme.of(context).textTheme.headlineSmall
                                    : Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pick a starter pack or upload your own, then create a room.',
                                style: TextStyle(
                                  color: AppColors.mist,
                                  height: 1.35,
                                  fontSize: compact ? 14 : null,
                                ),
                              ),
                              SizedBox(height: compact ? 16 : 20),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Your display name',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: compact ? 18 : 22),
                              Row(
                                children: [
                                  Text(
                                    'Starter packs',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Swipe',
                                    style: TextStyle(
                                      color: AppColors.mist
                                          .withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: packRowHeight,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _packs.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final pack = _packs[index];
                                    return _StarterPackCard(
                                      pack: pack,
                                      width: packCardWidth,
                                      accent: _packAccent(index),
                                      icon: _packIcon(index),
                                      selected: _uploaded == null &&
                                          _selected?.id == pack.id,
                                      onTap: () => _selectStarter(pack),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: compact ? 18 : 22),
                              Text(
                                'Custom questions',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              _UploadStrip(
                                importing: _importing,
                                uploaded: _uploaded,
                                onUpload: _uploadSheet,
                                onTemplate: _downloadTemplate,
                                onClearUpload: _uploaded == null
                                    ? null
                                    : () => setState(() {
                                          _uploaded = null;
                                          _selected = _packs.isNotEmpty
                                              ? _packs.first
                                              : null;
                                          _warnings = [];
                                        }),
                              ),
                              if (_warnings.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _warnings.take(2).join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.clay,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.wrong),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (active != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Ready with “${active.title}” · ${active.questions.length} questions',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.forestDeep,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      BounceFilledButton(
                        onPressed:
                            _creating || active == null ? null : _create,
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

  static Color _packAccent(int index) {
    const accents = [
      AppColors.forest,
      AppColors.clay,
      Color(0xFF3B7EA1),
    ];
    return accents[index % accents.length];
  }

  static IconData _packIcon(int index) {
    const icons = [
      Icons.menu_book_rounded,
      Icons.auto_stories_rounded,
      Icons.wb_sunny_rounded,
    ];
    return icons[index % icons.length];
  }
}

class _StarterPackCard extends StatelessWidget {
  const _StarterPackCard({
    required this.pack,
    required this.width,
    required this.accent,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final QuizPack pack;
  final double width;
  final Color accent;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [
                    accent.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.92),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.88),
                    Colors.white.withValues(alpha: 0.72),
                  ],
          ),
          border: Border.all(
            color: selected ? accent : Colors.white.withValues(alpha: 0.7),
            width: selected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: selected ? 0.22 : 0.08),
              blurRadius: selected ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Icon(Icons.check_circle_rounded, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pack.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                pack.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.mist,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
            Text(
              '${pack.questions.length} questions',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadStrip extends StatelessWidget {
  const _UploadStrip({
    required this.importing,
    required this.uploaded,
    required this.onUpload,
    required this.onTemplate,
    required this.onClearUpload,
  });

  final bool importing;
  final QuizPack? uploaded;
  final VoidCallback onUpload;
  final VoidCallback onTemplate;
  final VoidCallback? onClearUpload;

  @override
  Widget build(BuildContext context) {
    final hasUpload = uploaded != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: hasUpload
            ? AppColors.forest.withValues(alpha: 0.1)
            : AppColors.forest.withValues(alpha: 0.05),
        border: Border.all(
          color: hasUpload
              ? AppColors.forest.withValues(alpha: 0.45)
              : AppColors.forest.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasUpload) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.forest,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${uploaded!.title} · ${uploaded!.questions.length} questions',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestDeep,
                    ),
                  ),
                ),
                if (onClearUpload != null)
                  TextButton(
                    onPressed: onClearUpload,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: BounceTap(
                  enabled: !importing,
                  onTap: importing ? null : onUpload,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: importing ? 0.5 : 1,
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.forest,
                          width: 1.8,
                        ),
                      ),
                      child: Text(
                        importing
                            ? 'Reading…'
                            : hasUpload
                                ? 'Replace file'
                                : 'Upload CSV / Excel',
                        style: const TextStyle(
                          color: AppColors.forestDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onTemplate,
                child: const Text('Template'),
              ),
            ],
          ),
          if (!hasUpload) ...[
            const SizedBox(height: 8),
            Text(
              'CSV or Excel · Template includes the columns you need',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mist,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
