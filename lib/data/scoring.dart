/// Kahoot-style points: correct answers earn a base + speed bonus.
class Scoring {
  static const int basePoints = 500;
  static const int maxBonus = 500;

  static int pointsFor({
    required bool correct,
    required int responseMs,
    required int timeLimitSec,
  }) {
    if (!correct) return 0;
    final limitMs = timeLimitSec * 1000;
    final clamped = responseMs.clamp(0, limitMs);
    final remainingRatio = 1 - (clamped / limitMs);
    final bonus = (maxBonus * remainingRatio).round();
    return basePoints + bonus;
  }
}
