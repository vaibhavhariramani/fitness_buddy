import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../../../models/saved_meal.dart';
import '../models/food.dart';
import '../providers/nutrition_providers.dart';
import '../utils/nutrient_scaling.dart';
import '../widgets/add_food_sheet.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/macro_progress_bar.dart';
import '../widgets/meal_section_card.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _diaryDateLabel(DateTime date) {
  final now = DateTime.now();
  if (_isSameDay(date, now)) return 'Today';
  if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return DateFormat.yMMMd().format(date);
}

class NutritionDiaryPage extends ConsumerStatefulWidget {
  const NutritionDiaryPage({super.key});

  @override
  ConsumerState<NutritionDiaryPage> createState() => _NutritionDiaryPageState();
}

class _NutritionDiaryPageState extends ConsumerState<NutritionDiaryPage> {
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  MealType _defaultMealType(DateTime selectedDate) {
    if (!_isSameDay(selectedDate, DateTime.now())) return MealType.breakfast;
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 12) return MealType.morningSnack;
    if (hour < 15) return MealType.lunch;
    if (hour < 17) return MealType.afternoonSnack;
    if (hour < 20) return MealType.dinner;
    return MealType.eveningSnack;
  }

  void _openAddFoodSheet(
    BuildContext context,
    MealType mealType,
    DateTime date,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddFoodSheet(mealType: mealType, initialDate: date),
    );
  }

  Future<void> _pickDiaryDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDiaryDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDiaryDateProvider.notifier).state = picked;
    }
  }

  void _toggleSelect(MealEntry entry) {
    setState(() {
      if (!_selectedIds.remove(entry.id)) _selectedIds.add(entry.id);
    });
  }

  Future<void> _saveAsMeal(List<MealEntry> allMeals) async {
    final selected =
        allMeals.where((m) => _selectedIds.contains(m.id)).toList();
    if (selected.isEmpty) return;

    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save as meal'),
            content: TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Meal name',
                hintText: 'e.g. My Breakfast',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, nameCtrl.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (name == null || name.isEmpty) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final items =
        selected.map((m) {
          final n = per100gFromEntry(m);
          return SavedMealItem(
            foodId: m.sourceFoodId ?? m.id,
            foodName: m.foodName ?? 'Quick add',
            brand: m.brand,
            source:
                m.source == MealEntrySource.customFood
                    ? FoodSource.custom
                    : FoodSource.openFoodFacts,
            grams: m.quantity * 100,
            caloriesPer100g: n.calories,
            proteinPer100g: n.protein,
            carbPer100g: n.carb,
            fatPer100g: n.fat,
            fiberPer100g: n.fiber,
            sugarPer100g: n.sugar,
            satFatPer100g: n.satFat,
            sodiumPer100gMg: n.sodium,
          );
        }).toList();

    await ref
        .read(savedMealRepoProvider)
        .add(
          uid,
          SavedMeal(
            id: '',
            name: name,
            items: items,
            createdAt: DateTime.now(),
          ),
        );

    if (mounted) {
      setState(() {
        _selecting = false;
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved "$name"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDiaryDateProvider);
    final mealsAsync = ref.watch(mealsForDateProvider(selectedDate));
    final totals = ref.watch(nutritionTotalsForDateProvider(selectedDate));
    final targets = ref.watch(activeNutritionTargetsProvider);
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title:
            _selecting
                ? Text('${_selectedIds.length} selected')
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous day',
                      onPressed:
                          () =>
                              ref
                                  .read(selectedDiaryDateProvider.notifier)
                                  .state = selectedDate.subtract(
                                const Duration(days: 1),
                              ),
                    ),
                    InkWell(
                      onTap: () => _pickDiaryDate(context, ref),
                      child: Text(_diaryDateLabel(selectedDate)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next day',
                      onPressed:
                          isToday
                              ? null
                              : () =>
                                  ref
                                      .read(selectedDiaryDateProvider.notifier)
                                      .state = selectedDate.add(
                                    const Duration(days: 1),
                                  ),
                    ),
                  ],
                ),
        actions: [
          if (_selecting)
            TextButton(
              onPressed:
                  () => setState(() {
                    _selecting = false;
                    _selectedIds.clear();
                  }),
              child: const Text('Cancel'),
            )
          else
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Save entries as a meal',
              onPressed: () => setState(() => _selecting = true),
            ),
        ],
      ),
      floatingActionButton:
          _selecting
              ? null
              : FloatingActionButton.extended(
                onPressed:
                    () => _openAddFoodSheet(
                      context,
                      _defaultMealType(selectedDate),
                      selectedDate,
                    ),
                icon: const Icon(Icons.add),
                label: const Text('Add food'),
              ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (meals) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!_selecting)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                isToday
                                    ? "Today's Nutrition"
                                    : '${_diaryDateLabel(selectedDate)}\'s Nutrition',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              CalorieRing(
                                consumed: totals.calories,
                                target: targets?.calories,
                              ),
                              const SizedBox(height: 16),
                              MacroProgressBar(
                                label: 'Protein',
                                consumedG: totals.proteinG,
                                targetG: targets?.proteinG,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 8),
                              MacroProgressBar(
                                label: 'Carbs',
                                consumedG: totals.carbG,
                                targetG: targets?.carbG,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(height: 8),
                              MacroProgressBar(
                                label: 'Fat',
                                consumedG: totals.fatG,
                                targetG: targets?.fatG,
                                color: Colors.blueAccent,
                              ),
                              if (targets == null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Set a daily target on the Diet Plan screen to track progress.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (!_selecting) const SizedBox(height: 16),
                    for (final type in MealType.values)
                      MealSectionCard(
                        type: type,
                        entries:
                            meals.where((m) => m.mealType == type).toList(),
                        onAddFood:
                            () =>
                                _openAddFoodSheet(context, type, selectedDate),
                        onDelete: (entry) {
                          final uid =
                              ref.read(authStateProvider).valueOrNull?.uid;
                          if (uid != null) {
                            ref.read(mealRepoProvider).delete(uid, entry.id);
                          }
                        },
                        selectionMode: _selecting,
                        selectedIds: _selectedIds,
                        onToggleSelect: _toggleSelect,
                      ),
                  ],
                ),
              ),
              if (_selecting)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed:
                          _selectedIds.isEmpty
                              ? null
                              : () => _saveAsMeal(meals),
                      child: Text(
                        'Save ${_selectedIds.length} item(s) as meal',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
