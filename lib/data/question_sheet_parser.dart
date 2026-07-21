import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';

import '../models/quiz_pack.dart';

class PackParseException implements Exception {
  PackParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PackImportResult {
  const PackImportResult({
    required this.pack,
    this.warnings = const [],
  });

  final QuizPack pack;
  final List<String> warnings;
}

/// Parses AdventQuiz question sheets (CSV or XLSX).
///
/// Expected headers (case-insensitive):
/// question, choice_a, choice_b, choice_c, choice_d, correct [, verse] [, seconds]
class QuestionSheetParser {
  static const templateCsv = '''question,choice_a,choice_b,choice_c,choice_d,correct,verse,seconds
How many books are in the Protestant Bible?,39,66,73,27,B,,20
Who built the ark?,Abraham,Moses,Noah,David,C,Genesis 6:13-22,20
Jesus said I am the way the truth and the…,Light,Life,Door,Word,B,John 14:6,20
According to Exodus 20 which day is the Sabbath?,First,Sixth,Seventh,Any day,C,Exodus 20:8-11,20
''';

  PackImportResult parseBytes({
    required Uint8List bytes,
    required String filename,
    String? title,
  }) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return parseExcel(bytes, title: title, filename: filename);
    }
    return parseCsv(utf8.decode(bytes, allowMalformed: true),
        title: title, filename: filename);
  }

  PackImportResult parseCsv(
    String raw, {
    String? title,
    String? filename,
  }) {
    final rows = _parseCsvRows(raw);
    if (rows.isEmpty) {
      throw PackParseException('The file is empty.');
    }
    return _fromRows(rows, title: title, filename: filename);
  }

  PackImportResult parseExcel(
    Uint8List bytes, {
    String? title,
    String? filename,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw PackParseException('No sheets found in the Excel file.');
    }
    final sheet = excel.tables.values.first;
    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      rows.add(row.map(_excelCellText).toList());
    }
    // Drop trailing fully-empty rows.
    while (rows.isNotEmpty && rows.last.every((c) => c.trim().isEmpty)) {
      rows.removeLast();
    }
    return _fromRows(rows, title: title, filename: filename);
  }

  PackImportResult _fromRows(
    List<List<String>> rows, {
    String? title,
    String? filename,
  }) {
    if (rows.isEmpty) {
      throw PackParseException('No rows found.');
    }

    final header = rows.first.map(_normalizeHeader).toList();
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      if (header[i].isNotEmpty) map[header[i]] = i;
    }

    String? col(List<String> aliases) {
      for (final a in aliases) {
        if (map.containsKey(a)) return a;
      }
      return null;
    }

    final qCol = col(['question', 'prompt', 'q']);
    final aCol = col(['choice_a', 'a', 'option_a', 'answer_a']);
    final bCol = col(['choice_b', 'b', 'option_b', 'answer_b']);
    final cCol = col(['choice_c', 'c', 'option_c', 'answer_c']);
    final dCol = col(['choice_d', 'd', 'option_d', 'answer_d']);
    final correctCol = col(['correct', 'answer', 'correct_answer', 'key']);
    final verseCol = col(['verse', 'verseref', 'reference', 'scripture']);
    final secondsCol = col(['seconds', 'timelimit', 'time', 'timelimitsec']);

    final missing = <String>[];
    if (qCol == null) missing.add('question');
    if (aCol == null) missing.add('choice_a');
    if (bCol == null) missing.add('choice_b');
    if (cCol == null) missing.add('choice_c');
    if (dCol == null) missing.add('choice_d');
    if (correctCol == null) missing.add('correct');
    if (missing.isNotEmpty) {
      throw PackParseException(
        'Missing required column(s): ${missing.join(', ')}. '
        'Use the AdventQuiz template (question, choice_a–d, correct).',
      );
    }

    String cell(List<String> row, String key) {
      final i = map[key]!;
      if (i >= row.length) return '';
      return row[i].trim();
    }

    final questions = <QuizQuestion>[];
    final warnings = <String>[];

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.every((c) => c.trim().isEmpty)) continue;

      final text = cell(row, qCol!);
      final ca = cell(row, aCol!);
      final cb = cell(row, bCol!);
      final cc = cell(row, cCol!);
      final cd = cell(row, dCol!);
      final correctRaw = cell(row, correctCol!);

      if (text.isEmpty) {
        warnings.add('Row ${r + 1}: skipped (empty question).');
        continue;
      }
      if ([ca, cb, cc, cd].any((c) => c.isEmpty)) {
        warnings.add('Row ${r + 1}: skipped (need four choices).');
        continue;
      }

      final correctId = _parseCorrect(correctRaw);
      if (correctId == null) {
        warnings.add(
          'Row ${r + 1}: skipped (correct must be A, B, C, or D).',
        );
        continue;
      }

      var seconds = 20;
      if (verseCol != null && secondsCol != null) {
        // parsed below
      }
      if (secondsCol != null) {
        final s = cell(row, secondsCol);
        if (s.isNotEmpty) {
          seconds = int.tryParse(s) ?? 20;
          seconds = seconds.clamp(5, 120);
        }
      }

      final verse = verseCol == null ? null : cell(row, verseCol);
      questions.add(
        QuizQuestion(
          id: 'up_${r}_${const Uuid().v4().substring(0, 8)}',
          text: text,
          choices: [
            QuizChoice(id: 'a', text: ca),
            QuizChoice(id: 'b', text: cb),
            QuizChoice(id: 'c', text: cc),
            QuizChoice(id: 'd', text: cd),
          ],
          correctId: correctId,
          verseRef: (verse == null || verse.isEmpty) ? null : verse,
          timeLimitSec: seconds,
        ),
      );
    }

    if (questions.isEmpty) {
      throw PackParseException(
        'No valid questions found. Check columns and that correct is A–D.',
      );
    }
    if (questions.length > 50) {
      warnings.add('Only the first 50 questions will be used.');
    }

    final limited = questions.take(50).toList();
    final packTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : _titleFromFilename(filename);
    final pack = QuizPack(
      id: 'upload_${const Uuid().v4()}',
      title: packTitle,
      description: 'Uploaded by host (${limited.length} questions)',
      questions: limited,
    );
    return PackImportResult(pack: pack, warnings: warnings);
  }

  String _excelCellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) {
      // excel.TextSpan — use toString() which returns visible text.
      return value.toString().trim();
    }
    if (value is IntCellValue) return '${value.value}';
    if (value is DoubleCellValue) {
      final n = value.value;
      return (n == n.roundToDouble()) ? '${n.toInt()}' : '$n';
    }
    if (value is BoolCellValue) return value.value ? 'TRUE' : 'FALSE';
    return value.toString().trim();
  }

  String _titleFromFilename(String? filename) {
    if (filename == null || filename.trim().isEmpty) return 'Custom pack';
    var name = filename.trim();
    final slash = name.replaceAll('\\', '/').split('/').last;
    name = slash;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (name.isEmpty) return 'Custom pack';
    return name[0].toUpperCase() + name.substring(1);
  }

  String _normalizeHeader(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String? _parseCorrect(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == 'a' || v == '1') return 'a';
    if (v == 'b' || v == '2') return 'b';
    if (v == 'c' || v == '3') return 'c';
    if (v == 'd' || v == '4') return 'd';
    // Accept "choice_a" style
    if (v.endsWith('a') && v.length <= 8) return 'a';
    if (v.endsWith('b') && v.length <= 8) return 'b';
    if (v.endsWith('c') && v.length <= 8) return 'c';
    if (v.endsWith('d') && v.length <= 8) return 'd';
    return null;
  }

  /// Minimal CSV parser supporting quoted fields and commas.
  List<List<String>> _parseCsvRows(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      if (row.any((c) => c.trim().isNotEmpty)) {
        rows.add(row);
      }
      row = <String>[];
    }

    for (var i = 0; i < normalized.length; i++) {
      final ch = normalized[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < normalized.length && normalized[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          endField();
        } else if (ch == '\n') {
          endRow();
        } else {
          field.write(ch);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      endRow();
    }
    return rows;
  }
}
