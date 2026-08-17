import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/utils/calculations.dart';
import '../../models/user_profile.dart';

class DietSuggestionScreen extends ConsumerStatefulWidget {
  const DietSuggestionScreen({super.key});

  @override
  ConsumerState<DietSuggestionScreen> createState() =>
      _DietSuggestionScreenState();
}

class _DietSuggestionScreenState extends ConsumerState<DietSuggestionScreen> {
  NutritionGoal _goal = NutritionGoal.maintain;
  bool _seeded = false;
  bool _saving = false;

  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  void dispose() {
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _seedFromProfile(UserProfile profile) {
    _goal = profile.nutritionGoal;
    _calCtrl.text = profile.customCalorieTarget?.toStringAsFixed(0) ?? '';
    _proteinCtrl.text = profile.customProteinG?.toStringAsFixed(0) ?? '';
    _carbCtrl.text = profile.customCarbG?.toStringAsFixed(0) ?? '';
    _fatCtrl.text = profile.customFatG?.toStringAsFixed(0) ?? '';
    _seeded = true;
  }

  Future<void> _saveGoal(String uid) async {
    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{'nutritionGoal': _goal.name};
      if (_goal == NutritionGoal.custom) {
        patch['customCalorieTarget'] = double.tryParse(_calCtrl.text);
        patch['customProteinG'] = double.tryParse(_proteinCtrl.text);
        patch['customCarbG'] = double.tryParse(_carbCtrl.text);
        patch['customFatG'] = double.tryParse(_fatCtrl.text);
      }
      await ref.read(userRepoProvider).updateProfile(uid, patch);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Daily target updated')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    if (profile != null && !_seeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _seedFromProfile(profile));
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plan')),
      body:
          profile == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Derived from your onboarding TDEE — pick a goal to see the '
                    'suggested daily calories and macro split, then set it as your '
                    'active target for the nutrition diary.',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        NutritionGoal.values
                            .map(
                              (g) => ChoiceChip(
                                label: Text(g.label),
                                selected: _goal == g,
                                onSelected: (_) => setState(() => _goal = g),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_goal == NutritionGoal.custom)
                    _buildCustomForm(context)
                  else
                    _buildPlanCard(context, profile),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed:
                        (_saving || uid == null) ? null : () => _saveGoal(uid),
                    child:
                        _saving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Set as my daily target'),
                  ),
                ],
              ),
    );
  }

  Widget _buildCustomForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave a field blank to have it calculated automatically from your calories.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _calCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _proteinCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Protein (g)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _carbCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Carbs (g)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fatCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fat (g)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, UserProfile profile) {
    final calorieTarget = _goal.calorieTarget(profile.calorieTargets);
    final macros = FitnessCalculations.macros(
      calorieTarget: calorieTarget,
      weightKg: profile.currentWeightKg,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_goal.label} plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${calorieTarget.toStringAsFixed(0)} kcal / day',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _MacroRow(
              label: 'Protein',
              grams: macros.proteinG,
              color: Colors.redAccent,
            ),
            _MacroRow(
              label: 'Carbs',
              grams: macros.carbG,
              color: Colors.orangeAccent,
            ),
            _MacroRow(
              label: 'Fat',
              grams: macros.fatG,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Protein is set at 1.8 g/kg bodyweight, fat at 25% of calories, '
              'and the remainder comes from carbs.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('${grams.toStringAsFixed(0)} g'),
        ],
      ),
    );
  }
}
