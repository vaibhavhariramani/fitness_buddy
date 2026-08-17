import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/user_recipe.dart';
import '../models/food.dart';
import 'food_search_page.dart';
import 'ingredient_amount_page.dart';

class RecipeBuilderPage extends ConsumerStatefulWidget {
  const RecipeBuilderPage({super.key});

  @override
  ConsumerState<RecipeBuilderPage> createState() => _RecipeBuilderPageState();
}

class _RecipeBuilderPageState extends ConsumerState<RecipeBuilderPage> {
  final _nameCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController(text: '4');
  final List<RecipeIngredient> _ingredients = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    super.dispose();
  }

  int get _servings => int.tryParse(_servingsCtrl.text) ?? 1;

  double get _totalCalories =>
      _ingredients.fold(0, (s, i) => s + i.caloriesPer100g * i.grams / 100);
  double get _totalProtein =>
      _ingredients.fold(0, (s, i) => s + i.proteinPer100g * i.grams / 100);
  double get _totalCarb =>
      _ingredients.fold(0, (s, i) => s + i.carbPer100g * i.grams / 100);
  double get _totalFat =>
      _ingredients.fold(0, (s, i) => s + i.fatPer100g * i.grams / 100);

  Future<void> _addIngredient() async {
    Food? picked;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FoodSearchPage(onFoodPicked: (food) => picked = food),
      ),
    );
    if (picked == null || !mounted) return;

    final ingredient = await Navigator.push<RecipeIngredient>(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientAmountPage(food: picked!),
      ),
    );
    if (ingredient != null) setState(() => _ingredients.add(ingredient));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a name and at least one ingredient')),
      );
      return;
    }
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(userRecipeRepoProvider)
          .add(
            uid,
            UserRecipe(
              id: '',
              name: name,
              servings: _servings,
              ingredients: _ingredients,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servings = _servings <= 0 ? 1 : _servings;
    final perServingCalories = _totalCalories / servings;

    return Scaffold(
      appBar: AppBar(title: const Text('New recipe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Recipe name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _servingsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Servings',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < _ingredients.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(_ingredients[i].foodName),
                subtitle: Text(
                  '${_ingredients[i].grams.toStringAsFixed(0)}g · '
                  '${(_ingredients[i].caloriesPer100g * _ingredients[i].grams / 100).toStringAsFixed(0)} kcal',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _ingredients.removeAt(i)),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addIngredient,
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
          ),
          const SizedBox(height: 20),
          if (_ingredients.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serves $servings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1 serving = ${perServingCalories.toStringAsFixed(0)} kcal',
                    ),
                    Text(
                      'P ${(_totalProtein / servings).toStringAsFixed(1)}g · '
                      'C ${(_totalCarb / servings).toStringAsFixed(1)}g · '
                      'F ${(_totalFat / servings).toStringAsFixed(1)}g per serving',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save recipe'),
          ),
        ],
      ),
    );
  }
}
