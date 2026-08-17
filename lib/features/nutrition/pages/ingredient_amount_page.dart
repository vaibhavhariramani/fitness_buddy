import 'package:flutter/material.dart';

import '../../../models/user_recipe.dart';
import '../models/food.dart';

/// A trimmed copy of ServingConfirmPage's grams-entry + live-nutrient-preview
/// UI, but returns a [RecipeIngredient] via pop instead of writing a
/// MealEntry — kept as its own page so ServingConfirmPage's single
/// responsibility (logging a diary entry) stays intact.
class IngredientAmountPage extends StatefulWidget {
  final Food food;

  const IngredientAmountPage({super.key, required this.food});

  @override
  State<IngredientAmountPage> createState() => _IngredientAmountPageState();
}

class _IngredientAmountPageState extends State<IngredientAmountPage> {
  late final _gramsController = TextEditingController(
    text: (widget.food.servingSizeG ?? 100).toStringAsFixed(0),
  );

  double get _grams => double.tryParse(_gramsController.text) ?? 0;

  double _scaled(double? per100g) =>
      per100g == null ? 0 : per100g * _grams / 100;

  void _add() {
    if (_grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    Navigator.pop(
      context,
      RecipeIngredient.fromFood(widget.food, grams: _grams),
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;

    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (food.brand != null)
            Text(food.brand!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _gramsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (grams)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For ${_grams.toStringAsFixed(0)}g',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_scaled(food.caloriesPer100g).toStringAsFixed(0)} kcal',
                  ),
                  Text(
                    'P ${_scaled(food.proteinPer100g).toStringAsFixed(1)}g · '
                    'C ${_scaled(food.carbPer100g).toStringAsFixed(1)}g · '
                    'F ${_scaled(food.fatPer100g).toStringAsFixed(1)}g',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _add,
            child: const Text('Add ingredient'),
          ),
        ),
      ),
    );
  }
}
