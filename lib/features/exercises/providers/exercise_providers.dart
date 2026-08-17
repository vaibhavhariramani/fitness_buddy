import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/exercise.dart';
import '../repository/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(),
);

final exerciseListProvider = FutureProvider<List<Exercise>>(
  (ref) => ref.watch(exerciseRepositoryProvider).loadAll(),
);

final categoriesProvider = Provider<List<String>>((ref) {
  final exercises =
      ref.watch(exerciseListProvider).valueOrNull ?? const <Exercise>[];
  final categories = exercises.map((e) => e.category).toSet().toList()..sort();
  return categories;
});

final equipmentListProvider = Provider<List<String>>((ref) {
  final exercises =
      ref.watch(exerciseListProvider).valueOrNull ?? const <Exercise>[];
  final equipment =
      exercises.expand((e) => e.equipment).toSet().toList()..sort();
  return equipment;
});

final exerciseByIdProvider = Provider.family<Exercise?, String>((ref, id) {
  final list =
      ref.watch(exerciseListProvider).valueOrNull ?? const <Exercise>[];
  for (final e in list) {
    if (e.id == id) return e;
  }
  return null;
});

class ExerciseLibraryFilter {
  final String search;
  final String? category;
  final String? equipment;
  final bool favoritesOnly;

  const ExerciseLibraryFilter({
    this.search = '',
    this.category,
    this.equipment,
    this.favoritesOnly = false,
  });

  ExerciseLibraryFilter copyWith({
    String? search,
    String? category,
    bool clearCategory = false,
    String? equipment,
    bool clearEquipment = false,
    bool? favoritesOnly,
  }) => ExerciseLibraryFilter(
    search: search ?? this.search,
    category: clearCategory ? null : (category ?? this.category),
    equipment: clearEquipment ? null : (equipment ?? this.equipment),
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );
}

class ExerciseLibraryFilterNotifier
    extends StateNotifier<ExerciseLibraryFilter> {
  ExerciseLibraryFilterNotifier() : super(const ExerciseLibraryFilter());

  void setSearch(String value) => state = state.copyWith(search: value);

  void setCategory(String? category) =>
      state = state.copyWith(
        category: category,
        clearCategory: category == null,
      );

  void setEquipment(String? equipment) =>
      state = state.copyWith(
        equipment: equipment,
        clearEquipment: equipment == null,
      );

  void setFavoritesOnly(bool value) =>
      state = state.copyWith(favoritesOnly: value);
}

final exerciseLibraryFilterProvider =
    StateNotifierProvider<ExerciseLibraryFilterNotifier, ExerciseLibraryFilter>(
      (ref) => ExerciseLibraryFilterNotifier(),
    );

final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final listAsync = ref.watch(exerciseListProvider);
  final filter = ref.watch(exerciseLibraryFilterProvider);
  final favorites = ref.watch(favoritesProvider);

  return listAsync.whenData((all) {
    final query = filter.search.trim().toLowerCase();
    return all.where((e) {
      if (filter.favoritesOnly && !favorites.contains(e.id)) return false;
      if (filter.category != null && e.category != filter.category) {
        return false;
      }
      if (filter.equipment != null && !e.equipment.contains(filter.equipment)) {
        return false;
      }
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  });
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier()
    : super(
        Hive.box('exercise_favorites').keys.map((k) => k.toString()).toSet(),
      );

  void toggle(String exerciseId) {
    final box = Hive.box('exercise_favorites');
    if (box.containsKey(exerciseId)) {
      box.delete(exerciseId);
      state = {...state}..remove(exerciseId);
    } else {
      box.put(exerciseId, true);
      state = {...state, exerciseId};
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

class RecentlyViewedNotifier extends StateNotifier<List<String>> {
  RecentlyViewedNotifier()
    : super(
        List<String>.from(
          Hive.box(
                'exercises_meta',
              ).get('recentlyViewed', defaultValue: <String>[])
              as List,
        ),
      );

  static const _maxItems = 20;

  void recordView(String exerciseId) {
    final capped =
        [
          exerciseId,
          ...state.where((id) => id != exerciseId),
        ].take(_maxItems).toList();
    Hive.box('exercises_meta').put('recentlyViewed', capped);
    state = capped;
  }
}

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<String>>(
      (ref) => RecentlyViewedNotifier(),
    );
