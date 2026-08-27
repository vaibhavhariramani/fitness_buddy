import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/providers.dart';
import '../../core/utils/calculations.dart';
import '../../models/user_profile.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/section_header.dart';

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
                  const SizedBox(height: AppSpacing.xxl),
                  const _NorthIndianDietGuide(),
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

class _FoodGroup {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String note;

  const _FoodGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.note,
  });
}

const _northIndianFoodGroups = [
  _FoodGroup(
    title: 'Protein',
    icon: Icons.egg_alt_outlined,
    color: AppColors.workout,
    items: [
      'Paneer',
      'Dal (moong, masoor, toor)',
      'Rajma',
      'Chole / chana',
      'Curd (dahi)',
      'Eggs',
      'Chicken or fish',
      'Sprouts',
      'Soybean / tofu',
    ],
    note:
        'Aim for a protein source at every meal — pair dals with rice or '
        'roti for a complete amino acid profile.',
  ),
  _FoodGroup(
    title: 'Whole grains',
    icon: Icons.grain_outlined,
    color: AppColors.nutrition,
    items: [
      'Whole wheat roti / chapati',
      'Millets (bajra, jowar, ragi)',
      'Brown rice',
      'Dalia (broken wheat)',
      'Oats',
    ],
    note:
        'Favor whole-grain atta and millets over maida (refined flour) '
        'for more fiber and steadier energy.',
  ),
  _FoodGroup(
    title: 'Vegetables',
    icon: Icons.eco_outlined,
    color: AppColors.recovery,
    items: [
      'Palak (spinach)',
      'Methi (fenugreek)',
      'Lauki (bottle gourd)',
      'Bhindi (okra)',
      'Gobi (cauliflower)',
      'Seasonal mixed sabzi',
    ],
    note:
        'Half the plate as vegetables is a simple, reliable target most '
        'dietitians reach for first.',
  ),
  _FoodGroup(
    title: 'Fruits & dairy',
    icon: Icons.local_florist_outlined,
    color: AppColors.achievement,
    items: [
      'Guava',
      'Papaya',
      'Apple',
      'Amla',
      'Buttermilk (chaas)',
      'Low-fat milk',
    ],
    note:
        'A piece of seasonal fruit and a glass of chaas make an easy, '
        'light snack between meals.',
  ),
  _FoodGroup(
    title: 'Healthy fats',
    icon: Icons.spa_outlined,
    color: AppColors.workout,
    items: [
      'Ghee (in moderation)',
      'Mustard or groundnut oil',
      'Almonds & walnuts',
      'Flax or chia seeds',
    ],
    note:
        'A teaspoon of ghee on dal or roti is fine daily — the goal is '
        'moderation, not elimination.',
  ),
  _FoodGroup(
    title: 'Limit / moderate',
    icon: Icons.info_outline,
    color: Colors.redAccent,
    items: [
      'Fried snacks (samosa, pakora)',
      'Mithai / sweets',
      'Excess ghee or butter',
      'Sugary drinks',
    ],
    note:
        'These are fine occasionally — the aim is a mostly-whole-food '
        'plate, not strict avoidance.',
  ),
];

/// A general reference list of North Indian foods commonly recommended by
/// dietitians, organized the way a nutritionist would frame a plate —
/// protein, whole grains, vegetables, fruit/dairy, healthy fats, and what to
/// keep occasional. General guidance, not a personalized medical plan.
class _NorthIndianDietGuide extends StatelessWidget {
  const _NorthIndianDietGuide();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'North Indian Diet Guide'),
        Text(
          "A general reference — the kind of everyday food list a dietitian "
          "would suggest for a North Indian diet, organized by what each "
          "food group is for.",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final group in _northIndianFoodGroups)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              accentColor: group.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(group.icon, size: 18, color: group.color),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        group.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final item in group.items)
                        Chip(
                          label: Text(item),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    group.note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
