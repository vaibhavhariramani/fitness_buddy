import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../../../models/saved_meal.dart';

class SavedMealsListPage extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime? initialDate;

  const SavedMealsListPage({
    super.key,
    required this.mealType,
    this.initialDate,
  });

  @override
  ConsumerState<SavedMealsListPage> createState() => _SavedMealsListPageState();
}

class _SavedMealsListPageState extends ConsumerState<SavedMealsListPage> {
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

  Future<void> _addWholeMeal(SavedMeal meal) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final entries =
        meal.items
            .map(
              (i) => MealEntry(
                id: '',
                date: _date,
                mealType: widget.mealType,
                calories: i.caloriesPer100g * i.grams / 100,
                proteinG: i.proteinPer100g * i.grams / 100,
                carbG: i.carbPer100g * i.grams / 100,
                fatG: i.fatPer100g * i.grams / 100,
                fiberG:
                    i.fiberPer100g == null
                        ? null
                        : i.fiberPer100g! * i.grams / 100,
                sugarG:
                    i.sugarPer100g == null
                        ? null
                        : i.sugarPer100g! * i.grams / 100,
                satFatG:
                    i.satFatPer100g == null
                        ? null
                        : i.satFatPer100g! * i.grams / 100,
                sodiumMg:
                    i.sodiumPer100gMg == null
                        ? null
                        : i.sodiumPer100gMg! * i.grams / 100,
                foodName: i.foodName,
                brand: i.brand,
                quantity: i.grams / 100,
                servingDescription: '${i.grams.toStringAsFixed(0)} g',
                source: MealEntrySource.savedMeal,
                sourceFoodId: i.foodId,
                createdAt: now,
              ),
            )
            .toList();

    await ref.read(mealRepoProvider).addBatch(uid, entries);
    await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);

    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _deleteMeal(SavedMeal meal) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(savedMealRepoProvider).delete(uid, meal.id);
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final mealsAsync =
        uid == null
            ? const AsyncValue.data(<SavedMeal>[])
            : ref.watch(_savedMealsProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My saved meals')),
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
            child: mealsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (meals) {
                if (meals.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No saved meals yet. Select entries from your diary and save them as a meal to reuse here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, i) {
                    final meal = meals[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(meal.name),
                        subtitle: Text(
                          '${meal.items.length} items · ${meal.totalCalories.toStringAsFixed(0)} kcal',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteMeal(meal),
                        ),
                        onTap: () => _addWholeMeal(meal),
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

final _savedMealsProvider = StreamProvider.autoDispose
    .family<List<SavedMeal>, String>(
      (ref, uid) => ref.watch(savedMealRepoProvider).watchAll(uid),
    );
