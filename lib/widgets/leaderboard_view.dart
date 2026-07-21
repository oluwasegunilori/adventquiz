import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.players,
    this.highlightUid,
    this.title = 'Leaderboard',
    this.podium = false,
  });

  final List<RoomPlayer> players;
  final String? highlightUid;
  final String title;
  final bool podium;

  @override
  Widget build(BuildContext context) {
    final ranked = [...players]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.joinedAt.compareTo(b.joinedAt);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 20),
        if (podium && ranked.isNotEmpty) ...[
          PopIn(
            delay: const Duration(milliseconds: 120),
            child: _Podium(players: ranked.take(3).toList()),
          ),
          const SizedBox(height: 28),
        ],
        ...ranked.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final mine = p.uid == highlightUid;
          return FadeSlideIn(
            delay: Duration(milliseconds: 80 + (i * 70)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: mine
                    ? AppColors.forest.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: mine
                      ? AppColors.forest
                      : AppColors.mist.withValues(alpha: 0.25),
                  width: mine ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: i < 3 ? AppColors.clay : AppColors.mist,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.nickname,
                      style: TextStyle(
                        fontWeight: mine ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${p.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.forestDeep,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Podium extends StatefulWidget {
  const _Podium({required this.players});

  final List<RoomPlayer> players;

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RoomPlayer? first =
        widget.players.isNotEmpty ? widget.players[0] : null;
    RoomPlayer? second =
        widget.players.length > 1 ? widget.players[1] : null;
    RoomPlayer? third =
        widget.players.length > 2 ? widget.players[2] : null;

    Widget block(
      RoomPlayer? p,
      String place,
      double height,
      Color color,
      double delay,
    ) {
      return Expanded(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeOutBack.transform(
              (((_controller.value - delay) / (1 - delay)).clamp(0.0, 1.0)),
            );
            return Column(
              children: [
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(
                    p?.nickname ?? '—',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: height * t,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: t > 0.55
                      ? Text(
                          place,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(
                    p == null ? '' : '${p.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestDeep,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        block(second, '2', 90, AppColors.mist, 0.1),
        const SizedBox(width: 10),
        block(first, '1', 130, AppColors.clay, 0.0),
        const SizedBox(width: 10),
        block(third, '3', 70, AppColors.forest, 0.18),
      ],
    );
  }
}
