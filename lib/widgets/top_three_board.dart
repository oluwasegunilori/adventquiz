import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

/// Compact Kahoot-style top-three board for the reveal sidebar.
class TopThreeBoard extends StatelessWidget {
  const TopThreeBoard({
    super.key,
    required this.players,
    this.highlightUid,
    this.roundPoints = const {},
  });

  final List<RoomPlayer> players;
  final String? highlightUid;

  /// Optional points earned this round, keyed by uid.
  final Map<String, int> roundPoints;

  @override
  Widget build(BuildContext context) {
    final ranked = [...players]..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.joinedAt.compareTo(b.joinedAt);
      });
    final top = ranked.take(3).toList();

    return PopIn(
      delay: const Duration(milliseconds: 220),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top 3',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scoreboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mist,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            if (top.isEmpty)
              Text(
                'No players yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mist),
              )
            else
              ...top.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final mine = p.uid == highlightUid;
                final gained = roundPoints[p.uid] ?? 0;
                final medal = switch (i) {
                  0 => AppColors.clay,
                  1 => AppColors.mist,
                  _ => AppColors.forest,
                };
                final placeLabel = switch (i) {
                  0 => '1st',
                  1 => '2nd',
                  _ => '3rd',
                };

                return FadeSlideIn(
                  delay: Duration(milliseconds: 120 + i * 90),
                  offset: const Offset(0.12, 0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? AppColors.forest.withValues(alpha: 0.12)
                          : AppColors.parchment.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: mine ? AppColors.forest : medal.withValues(alpha: 0.35),
                        width: mine || i == 0 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: medal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            placeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (gained > 0)
                                Text(
                                  '+$gained this round',
                                  style: TextStyle(
                                    color: AppColors.correct,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${p.score}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }
}
