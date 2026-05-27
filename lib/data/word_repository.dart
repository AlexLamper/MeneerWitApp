import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/game_models.dart';

/// Loads and holds the bundled word list (extracted from meneerwit.com).
class WordRepository {
  WordRepository._();
  static final WordRepository instance = WordRepository._();

  final Map<String, List<WordPair>> _byCategory = {};
  bool _loaded = false;

  List<String> get categories => _byCategory.keys.toList();
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/words.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    data.forEach((category, pairs) {
      _byCategory[category] = (pairs as List)
          .map((e) => WordPair.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    _loaded = true;
  }

  List<WordPair> pairsFor(String category) =>
      _byCategory[category] ?? const [];

  int get totalPairs =>
      _byCategory.values.fold(0, (sum, list) => sum + list.length);
}
