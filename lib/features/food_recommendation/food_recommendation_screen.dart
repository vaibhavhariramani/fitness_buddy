import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/recipe.dart';

class FoodRecommendationScreen extends ConsumerStatefulWidget {
  const FoodRecommendationScreen({super.key});

  @override
  ConsumerState<FoodRecommendationScreen> createState() =>
      _FoodRecommendationScreenState();
}

class _FoodRecommendationScreenState
    extends ConsumerState<FoodRecommendationScreen> {
  final _ingredientController = TextEditingController();
  final Set<String> _ingredients = {};
  List<Recipe>? _results;
  bool _loading = false;

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _ingredients.add(trimmed);
      _ingredientController.clear();
    });
  }

  Future<void> _findRecipes() async {
    if (_ingredients.isEmpty) return;
    setState(() => _loading = true);
    try {
      final results = await ref
          .read(recipeRepoProvider)
          .recommend(_ingredients);
      setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What can I cook?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List the ingredients you have available, then find matching recipes.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ingredientController,
              decoration: InputDecoration(
                labelText: 'Add ingredient',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addIngredient(_ingredientController.text),
                ),
              ),
              onSubmitted: _addIngredient,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children:
                  _ingredients
                      .map(
                        (i) => Chip(
                          label: Text(i),
                          onDeleted:
                              () => setState(() => _ingredients.remove(i)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _ingredients.isEmpty || _loading ? null : _findRecipes,
              icon: const Icon(Icons.search),
              label: Text(_loading ? 'Searching…' : 'Find recipes'),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null) {
      return const Center(
        child: Text('Your matching recipes will show up here.'),
      );
    }
    if (_results!.isEmpty) {
      return const Center(
        child: Text('No recipes matched — try adding more ingredients.'),
      );
    }
    return ListView.builder(
      itemCount: _results!.length,
      itemBuilder: (context, i) {
        final recipe = _results![i];
        final matchPercent = (recipe.matchScore(_ingredients) * 100).round();
        return Card(
          child: ListTile(
            title: Text(recipe.name),
            subtitle: Text(
              '${recipe.calories.toStringAsFixed(0)} kcal · Uses: ${recipe.ingredients.join(', ')}',
            ),
            trailing: Chip(label: Text('$matchPercent%')),
            onTap:
                () => showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(recipe.name),
                        content: SingleChildScrollView(
                          child: Text(recipe.instructions),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                ),
          ),
        );
      },
    );
  }
}
