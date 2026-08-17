import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/custom_food.dart';

class CustomFoodFormPage extends ConsumerStatefulWidget {
  const CustomFoodFormPage({super.key});

  @override
  ConsumerState<CustomFoodFormPage> createState() => _CustomFoodFormPageState();
}

class _CustomFoodFormPageState extends ConsumerState<CustomFoodFormPage> {
  NutritionBasis _basis = NutritionBasis.per100g;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController();
  final _servingDescCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _satFatCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _servingSizeCtrl.dispose();
    _servingDescCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    _fiberCtrl.dispose();
    _sugarCtrl.dispose();
    _sodiumCtrl.dispose();
    _satFatCtrl.dispose();
    super.dispose();
  }

  String get _basisSuffix {
    switch (_basis) {
      case NutritionBasis.per100g:
        return 'per 100g';
      case NutritionBasis.per100ml:
        return 'per 100ml';
      case NutritionBasis.perServing:
        return 'per serving';
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final calories = double.tryParse(_caloriesCtrl.text);
    if (name.isEmpty || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and calories')),
      );
      return;
    }
    if (_basis == NutritionBasis.perServing &&
        double.tryParse(_servingSizeCtrl.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the serving size in grams')),
      );
      return;
    }

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(customFoodRepoProvider)
          .add(
            uid,
            CustomFood(
              id: '',
              name: name,
              brand:
                  _brandCtrl.text.trim().isEmpty
                      ? null
                      : _brandCtrl.text.trim(),
              basis: _basis,
              servingSizeG: double.tryParse(_servingSizeCtrl.text),
              servingDescription:
                  _servingDescCtrl.text.trim().isEmpty
                      ? null
                      : _servingDescCtrl.text.trim(),
              calories: calories,
              proteinG: double.tryParse(_proteinCtrl.text) ?? 0,
              carbG: double.tryParse(_carbCtrl.text) ?? 0,
              fatG: double.tryParse(_fatCtrl.text) ?? 0,
              fiberG: double.tryParse(_fiberCtrl.text),
              sugarG: double.tryParse(_sugarCtrl.text),
              sodiumMg: double.tryParse(_sodiumCtrl.text),
              satFatG: double.tryParse(_satFatCtrl.text),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create custom food')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Food name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _brandCtrl,
            decoration: const InputDecoration(
              labelText: 'Brand (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<NutritionBasis>(
            segments: const [
              ButtonSegment(
                value: NutritionBasis.per100g,
                label: Text('Per 100g'),
              ),
              ButtonSegment(
                value: NutritionBasis.per100ml,
                label: Text('Per 100ml'),
              ),
              ButtonSegment(
                value: NutritionBasis.perServing,
                label: Text('Per serving'),
              ),
            ],
            selected: {_basis},
            onSelectionChanged: (s) => setState(() => _basis = s.first),
          ),
          if (_basis == NutritionBasis.perServing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _servingSizeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Serving size (grams)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servingDescCtrl,
              decoration: const InputDecoration(
                labelText: 'Serving description (e.g. "1 bar")',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Nutrition $_basisSuffix',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caloriesCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Calories (kcal)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proteinCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Carbs (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Optional', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fiberCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fiber (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _sugarCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sugar (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sodiumCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Sodium (mg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _satFatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Saturated fat (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Save food'),
          ),
        ],
      ),
    );
  }
}
