import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/exercise.dart';

/// Loads the curated, locally-bundled exercise catalog (see
/// assets/data/exercises.json). No network calls — fully offline.
class ExerciseRepository {
  static const _assetPath = 'assets/data/exercises.json';

  List<Exercise>? _cache;

  Future<List<Exercise>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List;
    final exercises =
        decoded
            .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
            .toList();
    _cache = exercises;
    return exercises;
  }
}
