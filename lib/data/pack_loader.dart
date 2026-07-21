import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quiz_pack.dart';

class PackLoader {
  static const _assetPaths = [
    'assets/packs/bible_basics.json',
    'assets/packs/gospels_jesus.json',
    'assets/packs/adventist_distinctives.json',
  ];

  Future<List<QuizPack>> loadAll() async {
    final packs = <QuizPack>[];
    for (final path in _assetPaths) {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      packs.add(QuizPack.fromJson(json));
    }
    return packs;
  }
}
