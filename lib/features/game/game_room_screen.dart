import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/room_repository.dart';
import '../../models/room.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../utils/share_room.dart';
import '../../widgets/answer_button.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/bounce_buttons.dart';
import '../../widgets/bounce_tap.dart';
import '../../widgets/leaderboard_view.dart';
import '../../widgets/motion.dart';
import '../../widgets/mute_button.dart';
import '../../widgets/top_three_board.dart';
import 'game_controller.dart';

class GameRoomScreen extends StatelessWidget {
  const GameRoomScreen({
    super.key,
    required this.roomId,
    required this.isHost,
  });

  final String roomId;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = GameController(
          repository: context.read<RoomRepository>(),
          roomId: roomId,
          isHost: isHost,
          sounds: context.read<SoundService>(),
        );
        controller.start();
        return controller;
      },
      child: const _GameRoomView(),
    );
  }
}

class _GameRoomView extends StatelessWidget {
  const _GameRoomView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final room = controller.room;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: room == null
              ? Center(
                  child: controller.error == null
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(controller.error!),
                            TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Home'),
                            ),
                          ],
                        ),
                )
              : MaxWidth(
                  width: room.status == RoomStatus.reveal ||
                          room.status == RoomStatus.leaderboard
                      ? 980
                      : 720,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.04, 0.06),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: switch (room.status) {
                      RoomStatus.lobby =>
                        const _LobbyView(key: ValueKey('lobby')),
                      RoomStatus.question =>
                        const _QuestionView(key: ValueKey('question')),
                      RoomStatus.reveal =>
                        const _RevealView(key: ValueKey('reveal')),
                      RoomStatus.leaderboard =>
                        const _LeaderboardPhase(key: ValueKey('board')),
                      RoomStatus.finished =>
                        const _FinishedView(key: ValueKey('done')),
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _LobbyView extends StatelessWidget {
  const _LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final room = c.room!;
    final host = c.isHost || c.isMeHost;
    final compact = context.isCompact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('← Leave'),
            ),
            const Spacer(),
            const MuteButton(),
          ],
        ),
        FadeSlideIn(
          child: Text(
            room.packTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.mist,
                  fontSize: compact ? 14 : null,
                ),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Join at AdventQuiz',
            textAlign: TextAlign.center,
            style: compact
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        PopIn(
          delay: const Duration(milliseconds: 120),
          child: Pulse(
            active: room.players.length < 2,
            child: BounceTap(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: room.pin));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN copied')),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: compact ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'GAME PIN',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mist,
                        fontSize: compact ? 12 : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          room.pin,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                letterSpacing: compact ? 4 : 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestDeep,
                                fontSize: compact ? 36 : null,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap PIN to copy',
                      style: TextStyle(color: AppColors.mist, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        BounceOutlinedButton(
          onPressed: () async {
            try {
              final outcome = await shareRoom(
                pin: room.pin,
                packTitle: room.packTitle,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    outcome == ShareRoomOutcome.shared
                        ? 'Invite shared'
                        : 'Invite copied — paste to send the PIN + link',
                  ),
                ),
              );
            } catch (_) {
              await Clipboard.setData(
                ClipboardData(
                  text: roomShareText(
                    pin: room.pin,
                    packTitle: room.packTitle,
                  ),
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite copied — paste to send the PIN + link'),
                ),
              );
            }
          },
          child: const Text('Share room'),
        ),
        SizedBox(height: compact ? 14 : 20),
        Text(
          'Players (${room.players.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: room.players.isEmpty
              ? const Center(child: Text('Waiting for players…'))
              : ListView.builder(
                  itemCount: room.players.length,
                  itemBuilder: (context, index) {
                    final p = room.players[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 40 * index),
                      offset: const Offset(-0.08, 0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.forest.withValues(alpha: 0.15),
                              foregroundColor: AppColors.forestDeep,
                              child: Text(
                                p.nickname.isNotEmpty
                                    ? p.nickname[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (p.isHost)
                              const Text(
                                'HOST',
                                style: TextStyle(
                                  color: AppColors.clay,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (c.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              c.error!,
              style: const TextStyle(color: AppColors.wrong),
            ),
          ),
        if (host)
          PopIn(
            child: BounceFilledButton(
              onPressed: room.players.isEmpty || c.busy ? null : c.startGame,
              child: const Text('Start game'),
            ),
          )
        else
          Text(
            'Waiting for host to start…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mist),
          ),
      ],
    );
  }
}

const _choiceColors = [
  Color(0xFFE07A3D),
  Color(0xFF3B7EA1),
  Color(0xFFD4A017),
  Color(0xFF3F8F6B),
];
const _choiceSymbols = ['▲', '◆', '●', '■'];

class _QuestionView extends StatelessWidget {
  const _QuestionView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final room = c.room!;
    final q = room.currentQuestion!;
    final totalMs = q.timeLimitSec * 1000;
    final progress = totalMs == 0 ? 0.0 : c.remainingMs / totalMs;
    final host = c.isHost || c.isMeHost;
    final answered = c.selectedChoiceId != null;
    final locked = c.answersLocked;
    final urgent = progress < 0.25;
    final compact = context.isCompact;
    final width = MediaQuery.sizeOf(context).width;
    final answerAspect = width < 380
        ? 1.05
        : width < 600
            ? 1.2
            : 1.55;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FadeSlideIn(
              child: Text(
                'Q${room.currentIndex + 1}/${room.questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestDeep,
                ),
              ),
            ),
            const Spacer(),
            const MuteButton(),
            const SizedBox(width: 4),
            Pulse(
              active: urgent,
              minScale: 0.96,
              maxScale: 1.08,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: urgent ? 22 : 18,
                  color: urgent ? AppColors.wrong : AppColors.ink,
                ),
                child: Text('${(c.remainingMs / 1000).ceil()}s'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 120),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.sand,
                color: urgent ? AppColors.wrong : AppColors.forest,
              );
            },
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        FadeSlideIn(
          key: ValueKey('q-${room.currentIndex}'),
          child: Text(
            q.text,
            style: (compact
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(height: 1.25),
          ),
        ),
        SizedBox(height: compact ? 12 : 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: compact ? 8 : 12,
              crossAxisSpacing: compact ? 8 : 12,
              childAspectRatio: answerAspect,
            ),
            itemCount: q.choices.length,
            itemBuilder: (context, index) {
              final choice = q.choices[index];
              final selected = c.selectedChoiceId == choice.id;
              return AnswerButton(
                key: ValueKey('choice-${room.currentIndex}-$index'),
                label: choice.text,
                color: _choiceColors[index % _choiceColors.length],
                symbol: _choiceSymbols[index % _choiceSymbols.length],
                selected: selected,
                dimmed: answered && !selected,
                enabled: !locked,
                entranceDelay: Duration(milliseconds: 70 * index),
                onTap: () => c.submitAnswer(choice.id),
              );
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: answered
              ? Padding(
                  key: const ValueKey('locked'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PopIn(
                      child: Text(
                      'Your answer is highlighted — hang tight!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.forestDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : c.remainingMs <= 0
                  ? Padding(
                      key: const ValueKey('times-up'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Time’s up — waiting for reveal…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mist,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('open')),
        ),
        if (host)
          BounceOutlinedButton(
            onPressed: c.busy ? null : c.reveal,
            child: const Text('Reveal answers'),
          ),
      ],
    );
  }
}

class _RevealView extends StatelessWidget {
  const _RevealView({super.key});

  Map<String, int> _roundPoints(GameRoom room) {
    final map = <String, int>{};
    for (final a in room.answers) {
      if (a.questionIndex == room.currentIndex && a.points > 0) {
        map[a.uid] = a.points;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final room = c.room!;
    final q = room.currentQuestion!;
    final host = c.isHost || c.isMeHost;
    final mine =
        c.uid == null ? null : room.answerFor(c.uid!, room.currentIndex);
    final isLast = room.currentIndex >= room.questions.length - 1;
    final topThree = TopThreeBoard(
      players: room.players,
      highlightUid: c.uid,
      roundPoints: _roundPoints(room),
    );

    final revealColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: Text(
            'Question complete',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(
            'Q${room.currentIndex + 1} · ${q.text}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.3,
                ),
          ),
        ),
        const SizedBox(height: 14),
        ...q.choices.asMap().entries.map((entry) {
          final i = entry.key;
          final choice = entry.value;
          final isCorrect = choice.id == q.correctId;
          final selected = mine?.choiceId == choice.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnswerButton(
              label: choice.text,
              color: _choiceColors[i % _choiceColors.length],
              symbol: _choiceSymbols[i % _choiceSymbols.length],
              selected: selected,
              enabled: false,
              entranceDelay: Duration(milliseconds: 90 * i),
              revealCorrect: isCorrect ? true : (selected ? false : null),
              onTap: null,
            ),
          );
        }),
        if (q.verseRef != null) ...[
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: Text(
              q.verseRef!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mist,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (mine != null)
          PopIn(
            delay: const Duration(milliseconds: 320),
            child: Text(
              mine.correct ? '+${mine.points} points!' : 'No points this round',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: mine.correct ? AppColors.correct : AppColors.wrong,
              ),
            ),
          )
        else if (c.answerTooLate || c.selectedChoiceId != null)
          Text(
            'Too late — that answer didn’t count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.clay,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Text(
            'You did not answer',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mist),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerRight, child: MuteButton()),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 700;
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(child: revealColumn),
                    ),
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 280,
                      child: SingleChildScrollView(child: topThree),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    revealColumn,
                    const SizedBox(height: 18),
                    topThree,
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (host)
          PopIn(
            delay: const Duration(milliseconds: 450),
            child: BounceFilledButton(
              onPressed: c.busy ? null : c.continueAfterReveal,
              child: Text(isLast ? 'Final podium' : 'Next question'),
            ),
          )
        else
          Text(
            isLast
                ? 'Waiting for final podium…'
                : 'Waiting for next question…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mist),
          ),
      ],
    );
  }
}

class _LeaderboardPhase extends StatelessWidget {
  const _LeaderboardPhase({super.key});

  Map<String, int> _roundPoints(GameRoom room) {
    final map = <String, int>{};
    for (final a in room.answers) {
      if (a.questionIndex == room.currentIndex && a.points > 0) {
        map[a.uid] = a.points;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final room = c.room!;
    final host = c.isHost || c.isMeHost;

    return Column(
      children: [
        const Align(alignment: Alignment.centerRight, child: MuteButton()),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                FadeSlideIn(
                  child: Text(
                    'Scoreboard',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TopThreeBoard(
                    players: room.players,
                    highlightUid: c.uid,
                    roundPoints: _roundPoints(room),
                  ),
                ),
                const SizedBox(height: 20),
                LeaderboardView(
                  players: room.players,
                  highlightUid: c.uid,
                  title: 'Everyone',
                ),
              ],
            ),
          ),
        ),
        if (host) ...[
          const SizedBox(height: 12),
          BounceFilledButton(
            onPressed: c.busy ? null : c.nextQuestion,
            child: const Text('Next question'),
          ),
          TextButton(
            onPressed: c.busy ? null : c.endGame,
            child: const Text('End game'),
          ),
        ],
      ],
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final room = c.room!;

    return Stack(
      children: [
        const Positioned.fill(child: ConfettiBurst()),
        Column(
          children: [
            const Align(alignment: Alignment.centerRight, child: MuteButton()),
            Expanded(
              child: SingleChildScrollView(
                child: LeaderboardView(
                  players: room.players,
                  highlightUid: c.uid,
                  title: 'Final podium',
                  podium: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            PopIn(
              delay: const Duration(milliseconds: 500),
              child: BounceFilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back home'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
