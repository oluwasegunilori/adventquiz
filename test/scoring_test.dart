import 'package:adventquiz/data/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wrong answers score zero', () {
    expect(
      Scoring.pointsFor(correct: false, responseMs: 100, timeLimitSec: 20),
      0,
    );
  });

  test('fast correct answers earn near max', () {
    final points = Scoring.pointsFor(
      correct: true,
      responseMs: 0,
      timeLimitSec: 20,
    );
    expect(points, Scoring.basePoints + Scoring.maxBonus);
  });

  test('slow correct answers earn base only', () {
    final points = Scoring.pointsFor(
      correct: true,
      responseMs: 20000,
      timeLimitSec: 20,
    );
    expect(points, Scoring.basePoints);
  });
}
