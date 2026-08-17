import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../models/food.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/food_result_tile.dart';
import 'serving_confirm_page.dart';

class FoodSearchPage extends ConsumerStatefulWidget {
  /// Required when picking a food to log directly into a meal. Omit (and
  /// supply [onFoodPicked] instead) when this page is reused as a plain
  /// ingredient picker, e.g. from the recipe builder.
  final MealType? mealType;
  final void Function(Food food)? onFoodPicked;

  const FoodSearchPage({super.key, this.mealType, this.onFoodPicked})
    : assert(mealType != null || onFoodPicked != null);

  @override
  ConsumerState<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends ConsumerState<FoodSearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectFood(Food food) {
    final onPicked = widget.onFoodPicked;
    if (onPicked != null) {
      onPicked(food);
      Navigator.pop(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ServingConfirmPage(food: food, mealType: widget.mealType!),
      ),
    );
  }

  void _toggleFavorite(Food food, bool isFavorite) {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final repo = ref.read(favoriteFoodRepoProvider);
    if (isFavorite) {
      repo.remove(uid, food.id);
    } else {
      repo.add(uid, food);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodSearchProvider);
    final favoriteIds = ref.watch(favoriteFoodIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'What did you eat?',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (v) => ref.read(foodSearchProvider.notifier).setQuery(v),
            ),
          ),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => ref
                            .read(foodSearchProvider.notifier)
                            .setQuery(state.query),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                state.query.trim().isEmpty
                    ? _BrowseView(
                      favoriteIds: favoriteIds,
                      onSelect: _selectFood,
                      onToggleFavorite: _toggleFavorite,
                    )
                    : ListView(
                      children: [
                        if (state.commonResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              'Common foods',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          for (final food in state.commonResults)
                            FoodResultTile(
                              food: food,
                              isFavorite: favoriteIds.contains(food.id),
                              onToggleFavorite:
                                  () => _toggleFavorite(
                                    food,
                                    favoriteIds.contains(food.id),
                                  ),
                              onTap: () => _selectFood(food),
                            ),
                        ],
                        if (state.customResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              'Your foods',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          for (final food in state.customResults)
                            FoodResultTile(
                              food: food,
                              isFavorite: favoriteIds.contains(food.id),
                              onToggleFavorite:
                                  () => _toggleFavorite(
                                    food,
                                    favoriteIds.contains(food.id),
                                  ),
                              onTap: () => _selectFood(food),
                            ),
                        ],
                        if (state.offResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text(
                              'Open Food Facts',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          for (final food in state.offResults)
                            FoodResultTile(
                              food: food,
                              isFavorite: favoriteIds.contains(food.id),
                              onToggleFavorite:
                                  () => _toggleFavorite(
                                    food,
                                    favoriteIds.contains(food.id),
                                  ),
                              onTap: () => _selectFood(food),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Text(
                              'Food data © Open Food Facts contributors, licensed under ODbL',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                        if (!state.loading &&
                            state.error == null &&
                            state.commonResults.isEmpty &&
                            state.customResults.isEmpty &&
                            state.offResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No foods found. Try a different search term.',
                              ),
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _BrowseView extends ConsumerWidget {
  final Set<String> favoriteIds;
  final void Function(Food food) onSelect;
  final void Function(Food food, bool isFavorite) onToggleFavorite;

  const _BrowseView({
    required this.favoriteIds,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteFoodsProvider);
    final recentAsync = ref.watch(recentFoodsProvider);
    final favorites = favoritesAsync.valueOrNull ?? const [];
    final recent = recentAsync.valueOrNull ?? const [];

    if (favorites.isEmpty && recent.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Search for a food to get started.'),
        ),
      );
    }

    return ListView(
      children: [
        if (favorites.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Favorites',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final food in favorites)
            FoodResultTile(
              food: food,
              isFavorite: true,
              onToggleFavorite: () => onToggleFavorite(food, true),
              onTap: () => onSelect(food),
            ),
        ],
        if (recent.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Recent',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final food in recent)
            FoodResultTile(
              food: food,
              isFavorite: favoriteIds.contains(food.id),
              onToggleFavorite:
                  () => onToggleFavorite(food, favoriteIds.contains(food.id)),
              onTap: () => onSelect(food),
            ),
        ],
      ],
    );
  }
}
