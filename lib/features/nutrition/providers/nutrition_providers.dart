import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/nutrition_targets.dart';
import '../../../models/custom_food.dart';
import '../../../models/meal_entry.dart';
import '../data/common_foods.dart';
import '../models/food.dart';
import '../services/food_database_service.dart';
import '../services/open_food_facts_service.dart';
import '../utils/nutrient_scaling.dart';

/// The day currently shown in the nutrition diary — defaults to today, but
/// lets the diary page browse/log any other date without threading a date
/// argument through every widget that only ever wants "today".
final selectedDiaryDateProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime.now(),
);

final mealsForDateProvider = StreamProvider.autoDispose
    .family<List<MealEntry>, DateTime>((ref, date) {
      final uid = ref.watch(authStateProvider).valueOrNull?.uid;
      if (uid == null) return Stream.value(const []);
      return ref.watch(mealRepoProvider).watchForDate(uid, date);
    });

final foodDatabaseServiceProvider = Provider<FoodDatabaseService>(
  (ref) => OpenFoodFactsService(),
);

final activeNutritionTargetsProvider = Provider<DailyNutritionTargets?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile == null ? null : dailyNutritionTargets(profile);
});

class NutritionTotals {
  final double calories;
  final double proteinG;
  final double carbG;
  final double fatG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  const NutritionTotals({
    this.calories = 0,
    this.proteinG = 0,
    this.carbG = 0,
    this.fatG = 0,
    this.fiberG = 0,
    this.sugarG = 0,
    this.sodiumMg = 0,
  });

  factory NutritionTotals.fromMeals(List<MealEntry> meals) {
    var calories = 0.0, proteinG = 0.0, carbG = 0.0, fatG = 0.0;
    var fiberG = 0.0, sugarG = 0.0, sodiumMg = 0.0;
    for (final m in meals) {
      calories += m.calories;
      proteinG += m.proteinG;
      carbG += m.carbG;
      fatG += m.fatG;
      fiberG += m.fiberG ?? 0;
      sugarG += m.sugarG ?? 0;
      sodiumMg += m.sodiumMg ?? 0;
    }
    return NutritionTotals(
      calories: calories,
      proteinG: proteinG,
      carbG: carbG,
      fatG: fatG,
      fiberG: fiberG,
      sugarG: sugarG,
      sodiumMg: sodiumMg,
    );
  }
}

final nutritionTotalsForDateProvider = Provider.autoDispose
    .family<NutritionTotals, DateTime>((ref, date) {
      final meals =
          ref.watch(mealsForDateProvider(date)).valueOrNull ?? const [];
      return NutritionTotals.fromMeals(meals);
    });

/// Convenience alias for dashboard/analytics widgets that only ever care
/// about today, so they don't need to know about date-scoped diary browsing.
///
/// Must be `autoDispose`: a plain (cached-forever) provider would call
/// `DateTime.now()` exactly once, the first time anything reads it, and then
/// keep watching that one frozen day for the rest of the app's process
/// lifetime — silently going stale (or even watching the wrong calendar day
/// after a midnight rollover) on platforms like iOS where the app can sit
/// backgrounded for a long time without being relaunched. `autoDispose`
/// makes it re-evaluate "today" fresh every time a screen (re)subscribes to
/// it, e.g. navigating back to the dashboard.
final todaysNutritionTotalsProvider = Provider.autoDispose<NutritionTotals>((
  ref,
) {
  final now = DateTime.now();
  return ref.watch(
    nutritionTotalsForDateProvider(DateTime(now.year, now.month, now.day)),
  );
});

/// Distinct foods logged in the last 30 days, most recent first — derived
/// entirely from existing meal history, no separate storage.
final recentFoodsProvider = StreamProvider.autoDispose<List<Food>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);

  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 30));
  return ref.watch(mealRepoProvider).watchRange(uid, start, end).map((meals) {
    final seen = <String>{};
    final result = <Food>[];
    for (final m in meals.reversed) {
      // watchRange orders ascending by date; walk backwards for most-recent-first.
      if (m.foodName == null) {
        continue; // manual quick-adds aren't reconstructable foods
      }
      final key = m.sourceFoodId ?? m.foodName!;
      if (!seen.add(key)) continue;

      final n = per100gFromEntry(m);
      result.add(
        Food(
          source:
              m.source == MealEntrySource.customFood
                  ? FoodSource.custom
                  : FoodSource.openFoodFacts,
          id: key,
          name: m.foodName!,
          brand: m.brand,
          caloriesPer100g: n.calories,
          proteinPer100g: n.protein,
          carbPer100g: n.carb,
          fatPer100g: n.fat,
          fiberPer100g: n.fiber,
          sugarPer100g: n.sugar,
          satFatPer100g: n.satFat,
          sodiumPer100gMg: n.sodium,
          servingSizeG: m.quantity * 100,
        ),
      );
      if (result.length >= 20) break;
    }
    return result;
  });
});

final favoriteFoodsProvider = StreamProvider.autoDispose<List<Food>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(favoriteFoodRepoProvider).watchAll(uid);
});

final favoriteFoodIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final favorites = ref.watch(favoriteFoodsProvider).valueOrNull ?? const [];
  return favorites.map((f) => f.id).toSet();
});

class FoodSearchState {
  final String query;
  final bool loading;
  final String? error;
  final List<Food> commonResults;
  final List<Food> customResults;
  final List<Food> offResults;

  const FoodSearchState({
    this.query = '',
    this.loading = false,
    this.error,
    this.commonResults = const [],
    this.customResults = const [],
    this.offResults = const [],
  });

  FoodSearchState copyWith({
    String? query,
    bool? loading,
    String? error,
    bool clearError = false,
    List<Food>? commonResults,
    List<Food>? customResults,
    List<Food>? offResults,
  }) => FoodSearchState(
    query: query ?? this.query,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    commonResults: commonResults ?? this.commonResults,
    customResults: customResults ?? this.customResults,
    offResults: offResults ?? this.offResults,
  );
}

class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  FoodSearchNotifier(this._ref) : super(const FoodSearchState());

  final Ref _ref;
  Timer? _debounce;

  void setQuery(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (query.trim().isEmpty) {
      state = const FoodSearchState();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    state = state.copyWith(loading: true, clearError: true);

    final uid = _ref.read(authStateProvider).valueOrNull?.uid;
    final customFuture =
        uid == null
            ? Future.value(<CustomFood>[])
            : _ref.read(customFoodRepoProvider).watchAll(uid).first;
    final offFuture = _ref.read(foodDatabaseServiceProvider).searchFoods(query);

    List<CustomFood> customFoods = const [];
    List<Food> offResults = const [];
    String? error;
    try {
      final results = await Future.wait([customFuture, offFuture]);
      customFoods = results[0] as List<CustomFood>;
      offResults = results[1] as List<Food>;
    } on FoodSearchException catch (e) {
      error = e.message;
      // Custom foods may still have loaded even if OFF failed — retry just
      // the custom half so a network error doesn't hide the user's own foods.
      if (uid != null) {
        try {
          customFoods =
              await _ref.read(customFoodRepoProvider).watchAll(uid).first;
        } catch (_) {
          // Leave customFoods empty; the OFF error message is still shown.
        }
      }
    }

    if (state.query != query) return; // a newer query has since started

    final matchingCustom =
        customFoods
            .where(
              (f) => f.name.toLowerCase().contains(query.trim().toLowerCase()),
            )
            .map(Food.fromCustomFood)
            .toList();
    final matchingCommon =
        commonFoods
            .where(
              (f) => f.name.toLowerCase().contains(query.trim().toLowerCase()),
            )
            .toList();

    state = state.copyWith(
      loading: false,
      error: error,
      clearError: error == null,
      commonResults: matchingCommon,
      customResults: matchingCustom,
      offResults: offResults,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final foodSearchProvider =
    StateNotifierProvider.autoDispose<FoodSearchNotifier, FoodSearchState>(
      (ref) => FoodSearchNotifier(ref),
    );
