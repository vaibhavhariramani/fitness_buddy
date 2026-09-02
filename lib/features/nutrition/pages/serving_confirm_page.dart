import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../models/food.dart';
import '../providers/nutrition_providers.dart';

class ServingConfirmPage extends ConsumerStatefulWidget {
  final Food food;
  final MealType mealType;
  final MealEntrySource? sourceOverride;
  final DateTime? initialDate;

  const ServingConfirmPage({
    super.key,
    required this.food,
    required this.mealType,
    this.sourceOverride,
    this.initialDate,
  });

  @override
  ConsumerState<ServingConfirmPage> createState() => _ServingConfirmPageState();
}

class _ServingConfirmPageState extends ConsumerState<ServingConfirmPage> {
  late final _gramsController = TextEditingController(
    text: (widget.food.servingSizeG ?? 100).toStringAsFixed(0),
  );
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _satFatController = TextEditingController();
  final _sodiumController = TextEditingController();

  late DateTime _date = widget.initialDate ?? DateTime.now();
  bool _saving = false;
  bool _editingMacros = false;

  double get _grams => double.tryParse(_gramsController.text) ?? 0;

  double _scaled(double? per100g) =>
      per100g == null ? 0 : per100g * _grams / 100;

  double _finalValue(TextEditingController controller, double? per100g) {
    if (_editingMacros) return double.tryParse(controller.text) ?? 0;
    return _scaled(per100g);
  }

  double? _finalValueOrNull(TextEditingController controller, double? per100g) {
    if (per100g == null) return null;
    return _finalValue(controller, per100g);
  }

  void _setServings(double servings) {
    final base = widget.food.servingSizeG ?? 100;
    _setGrams(base * servings);
  }

  void _setGrams(double grams) {
    setState(() {
      _gramsController.text = grams.toStringAsFixed(0);
      if (_editingMacros) _syncMacroControllersFromGrams();
    });
  }

  void _syncMacroControllersFromGrams() {
    final food = widget.food;
    _caloriesController.text = _scaled(food.caloriesPer100g).toStringAsFixed(1);
    _proteinController.text = _scaled(food.proteinPer100g).toStringAsFixed(1);
    _carbController.text = _scaled(food.carbPer100g).toStringAsFixed(1);
    _fatController.text = _scaled(food.fatPer100g).toStringAsFixed(1);
    if (food.fiberPer100g != null) {
      _fiberController.text = _scaled(food.fiberPer100g).toStringAsFixed(1);
    }
    if (food.sugarPer100g != null) {
      _sugarController.text = _scaled(food.sugarPer100g).toStringAsFixed(1);
    }
    if (food.satFatPer100g != null) {
      _satFatController.text = _scaled(food.satFatPer100g).toStringAsFixed(1);
    }
    if (food.sodiumPer100gMg != null) {
      _sodiumController.text = _scaled(food.sodiumPer100gMg).toStringAsFixed(1);
    }
  }

  void _toggleEditingMacros() {
    setState(() {
      _editingMacros = !_editingMacros;
      if (_editingMacros) _syncMacroControllersFromGrams();
    });
  }

  Future<void> _save() async {
    if (_grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    final calories = _finalValue(
      _caloriesController,
      widget.food.caloriesPer100g,
    );
    if (calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid calorie amount')),
      );
      return;
    }
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final food = widget.food;
      final entry = MealEntry(
        id: '',
        date: _date,
        mealType: widget.mealType,
        calories: calories,
        proteinG: _finalValue(_proteinController, food.proteinPer100g),
        carbG: _finalValue(_carbController, food.carbPer100g),
        fatG: _finalValue(_fatController, food.fatPer100g),
        fiberG: _finalValueOrNull(_fiberController, food.fiberPer100g),
        sugarG: _finalValueOrNull(_sugarController, food.sugarPer100g),
        sodiumMg: _finalValueOrNull(_sodiumController, food.sodiumPer100gMg),
        satFatG: _finalValueOrNull(_satFatController, food.satFatPer100g),
        foodName: food.name,
        brand: food.brand,
        quantity: _grams / 100,
        servingDescription: '${_grams.toStringAsFixed(0)} g',
        source:
            widget.sourceOverride ??
            (food.source == FoodSource.custom
                ? MealEntrySource.customFood
                : MealEntrySource.foodSearch),
        sourceFoodId: food.id,
        manualEntry: false,
        createdAt: DateTime.now(),
      );

      await ref.read(mealRepoProvider).add(uid, entry);
      await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);

      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _satFatController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final isFavorite = ref.watch(favoriteFoodIdsProvider).contains(food.id);
    final baseServing = food.servingSizeG;

    return Scaffold(
      appBar: AppBar(
        title: Text(food.name),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () {
              final uid = ref.read(authStateProvider).valueOrNull?.uid;
              if (uid == null) return;
              final repo = ref.read(favoriteFoodRepoProvider);
              if (isFavorite) {
                repo.remove(uid, food.id);
              } else {
                repo.add(uid, food);
              }
            },
          ),
        ],
      ),
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
            onChanged:
                (_) => setState(() {
                  if (_editingMacros) _syncMacroControllersFromGrams();
                }),
          ),
          if (food.servingDescription != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reference serving: ${food.servingDescription}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (food.quantityPresetsG != null &&
              food.quantityPresetsG!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Quantity', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final g in food.quantityPresetsG!)
                  OutlinedButton(
                    onPressed: () => _setGrams(g),
                    child: Text('${g.toStringAsFixed(0)}g'),
                  ),
              ],
            ),
          ] else if (baseServing != null && baseServing > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Had more than one serving?',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final n in [1, 2, 3, 4])
                  OutlinedButton(
                    onPressed: () => _setServings(n.toDouble()),
                    child: Text(
                      '${n}x (${(baseServing * n).toStringAsFixed(0)}g)',
                    ),
                  ),
              ],
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingMacros
                            ? 'Nutrition (edit exact values)'
                            : 'Nutrition for ${_grams.toStringAsFixed(0)}g',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: _toggleEditingMacros,
                        icon: Icon(
                          _editingMacros ? Icons.check : Icons.edit_outlined,
                          size: 18,
                        ),
                        label: Text(_editingMacros ? 'Done' : 'Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _NutrientField(
                    label: 'Calories',
                    unit: 'kcal',
                    controller: _caloriesController,
                    editing: _editingMacros,
                    value: _scaled(food.caloriesPer100g),
                  ),
                  _NutrientField(
                    label: 'Protein',
                    unit: 'g',
                    controller: _proteinController,
                    editing: _editingMacros,
                    value: _scaled(food.proteinPer100g),
                  ),
                  _NutrientField(
                    label: 'Carbs',
                    unit: 'g',
                    controller: _carbController,
                    editing: _editingMacros,
                    value: _scaled(food.carbPer100g),
                  ),
                  _NutrientField(
                    label: 'Fat',
                    unit: 'g',
                    controller: _fatController,
                    editing: _editingMacros,
                    value: _scaled(food.fatPer100g),
                  ),
                  if (food.fiberPer100g != null)
                    _NutrientField(
                      label: 'Fiber',
                      unit: 'g',
                      controller: _fiberController,
                      editing: _editingMacros,
                      value: _scaled(food.fiberPer100g),
                    ),
                  if (food.sugarPer100g != null)
                    _NutrientField(
                      label: 'Sugar',
                      unit: 'g',
                      controller: _sugarController,
                      editing: _editingMacros,
                      value: _scaled(food.sugarPer100g),
                    ),
                  if (food.satFatPer100g != null)
                    _NutrientField(
                      label: 'Saturated fat',
                      unit: 'g',
                      controller: _satFatController,
                      editing: _editingMacros,
                      value: _scaled(food.satFatPer100g),
                    ),
                  if (food.sodiumPer100gMg != null)
                    _NutrientField(
                      label: 'Sodium',
                      unit: 'mg',
                      controller: _sodiumController,
                      editing: _editingMacros,
                      value: _scaled(food.sodiumPer100gMg),
                    ),
                ],
              ),
            ),
          ),
          if (food.source == FoodSource.openFoodFacts) ...[
            const SizedBox(height: 12),
            Text(
              'Food data © Open Food Facts contributors, licensed under ODbL',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text('Add to ${widget.mealType.label}'),
          ),
        ),
      ),
    );
  }
}

/// A nutrient row that's either a plain read-out (scaled live from grams) or,
/// once "Edit" is tapped, a directly-editable field — so exact consumption
/// (a different scoop count, a label that doesn't match the generic
/// estimate, etc.) can always be logged precisely.
class _NutrientField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool editing;
  final double value;

  const _NutrientField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.editing,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${value.toStringAsFixed(1)} $unit')],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(isDense: true, suffixText: unit),
            ),
          ),
        ],
      ),
    );
  }
}
