import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/meal_entry.dart';
import '../../../models/story.dart';

/// The original manual-numbers meal form, relocated here as the "Quick Add"
/// option — for when the exact food isn't available in search.
class QuickAddSheet extends ConsumerStatefulWidget {
  final MealType mealType;
  final DateTime? initialDate;

  const QuickAddSheet({super.key, required this.mealType, this.initialDate});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbController = TextEditingController();
  final _fatController = TextEditingController();
  Uint8List? _photoBytes;
  late DateTime _date = widget.initialDate ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _save() async {
    final calories = double.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid calorie amount')),
      );
      return;
    }
    setState(() => _saving = true);

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    try {
      final mealId = await ref
          .read(mealRepoProvider)
          .add(
            uid,
            MealEntry(
              id: '',
              date: _date,
              mealType: widget.mealType,
              calories: calories,
              proteinG: double.tryParse(_proteinController.text) ?? 0,
              carbG: double.tryParse(_carbController.text) ?? 0,
              fatG: double.tryParse(_fatController.text) ?? 0,
              source: MealEntrySource.manualQuickAdd,
              manualEntry: _photoBytes == null,
              createdAt: DateTime.now(),
            ),
          );

      if (_photoBytes != null) {
        final url = await ref
            .read(storageServiceProvider)
            .uploadMealPhoto(uid: uid, mealId: mealId, bytes: _photoBytes!);
        await ref.read(mealRepoProvider).update(uid, mealId, {'photoUrl': url});

        final now = DateTime.now();
        final proteinG = double.tryParse(_proteinController.text) ?? 0;
        final carbG = double.tryParse(_carbController.text) ?? 0;
        final fatG = double.tryParse(_fatController.text) ?? 0;
        await ref
            .read(storyRepoProvider)
            .add(
              uid,
              Story(
                id: '',
                type: StoryType.meal,
                photoUrl: url,
                mealTypeLabel: widget.mealType.label,
                calories: calories,
                proteinG: proteinG,
                carbG: carbG,
                fatG: fatG,
                createdAt: now,
                expiresAt: now.add(const Duration(hours: 24)),
              ),
            );
      }

      await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick add · ${widget.mealType.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
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
                    controller: _carbController,
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
                    controller: _fatController,
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
            const SizedBox(height: 4),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                _photoBytes == null ? 'Add photo (optional)' : 'Photo selected',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child:
                  _saving
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
