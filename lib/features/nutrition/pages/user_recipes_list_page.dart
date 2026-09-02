import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../../../models/user_recipe.dart';
import 'recipe_builder_page.dart';

class UserRecipesListPage extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime? initialDate;

  const UserRecipesListPage({
    super.key,
    required this.mealType,
    this.initialDate,
  });

  @override
  ConsumerState<UserRecipesListPage> createState() =>
      _UserRecipesListPageState();
}

class _UserRecipesListPageState extends ConsumerState<UserRecipesListPage> {
  late DateTime _date = widget.initialDate ?? DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _logServing(UserRecipe recipe) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final entry = MealEntry(
      id: '',
      date: _date,
      mealType: widget.mealType,
      calories: recipe.caloriesPerServing,
      proteinG: recipe.proteinPerServing,
      carbG: recipe.carbPerServing,
      fatG: recipe.fatPerServing,
      foodName: recipe.name,
      quantity: 1.0,
      servingDescription: '1 serving',
      source: MealEntrySource.recipe,
      sourceFoodId: recipe.id,
      createdAt: now,
    );

    await ref.read(mealRepoProvider).add(uid, entry);
    await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);

    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _deleteRecipe(UserRecipe recipe) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(userRecipeRepoProvider).delete(uid, recipe.id);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final recipesAsync =
        uid == null
            ? const AsyncValue.data(<UserRecipe>[])
            : ref.watch(_userRecipesProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New recipe',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecipeBuilderPage(),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Log to date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const Divider(height: 1),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'No recipes yet.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const RecipeBuilderPage(),
                                  ),
                                ),
                            child: const Text('New recipe'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, i) {
                    final recipe = recipes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(recipe.name),
                        subtitle: Text(
                          '${recipe.servings} servings · '
                          '${recipe.caloriesPerServing.toStringAsFixed(0)} kcal/serving',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteRecipe(recipe),
                        ),
                        onTap: () => _logServing(recipe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _userRecipesProvider = StreamProvider.autoDispose
    .family<List<UserRecipe>, String>(
      (ref, uid) => ref.watch(userRecipeRepoProvider).watchAll(uid),
    );
