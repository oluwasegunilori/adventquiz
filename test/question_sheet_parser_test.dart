import 'dart:convert';
import 'dart:typed_data';

import 'package:adventquiz/data/question_sheet_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = QuestionSheetParser();

  test('parses template CSV into a pack', () {
    final result = parser.parseCsv(QuestionSheetParser.templateCsv);
    expect(result.pack.questions.length, 4);
    expect(result.pack.questions.first.correctId, 'b');
    expect(result.pack.questions[1].verseRef, contains('Genesis'));
  });

  test('rejects missing columns', () {
    expect(
      () => parser.parseCsv('q,a\nHello,World\n'),
      throwsA(isA<PackParseException>()),
    );
  });

  test('accepts quoted commas in CSV', () {
    final csv = '''question,choice_a,choice_b,choice_c,choice_d,correct
"Who said, Follow me?",Peter,Andrew,Jesus,John,C
''';
    final result = parser.parseCsv(csv);
    expect(result.pack.questions.single.text, 'Who said, Follow me?');
    expect(result.pack.questions.single.correctId, 'c');
  });

  test('parseBytes routes csv by extension', () {
    final bytes = Uint8List.fromList(utf8.encode(QuestionSheetParser.templateCsv));
    final result = parser.parseBytes(bytes: bytes, filename: 'my_quiz.csv');
    expect(result.pack.title, 'My quiz');
    expect(result.pack.questions, isNotEmpty);
  });
}
