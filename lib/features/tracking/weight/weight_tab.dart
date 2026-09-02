import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../models/story.dart';
import '../../../models/weight_entry.dart';
import '../../../shared/utils/photo_picker.dart';

final weightLogsProvider = StreamProvider.autoDispose<List<WeightEntry>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(weightRepoProvider).watchAll(uid);
});

class WeightTab extends ConsumerWidget {
  const WeightTab({super.key});

  Future<void> _logWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    DateTime date = DateTime.now();
    Uint8List? photoBytes;

    final result = await showDialog<(double, Uint8List?)>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Log weight'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date'),
                        subtitle: Text(DateFormat.yMMMd().format(date)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) setState(() => date = picked);
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final bytes = await pickPhotoFromCameraOrGallery(
                            context,
                          );
                          if (bytes == null) return;
                          setState(() => photoBytes = bytes);
                        },
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          photoBytes == null
                              ? 'Add progress photo (optional)'
                              : 'Photo selected',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final weight = double.tryParse(controller.text);
                        if (weight == null) return;
                        Navigator.pop(context, (weight, photoBytes));
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
    if (result == null || result.$1 <= 0) return;
    final weight = result.$1;
    final pickedPhoto = result.$2;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final entryId = await ref
        .read(weightRepoProvider)
        .add(uid, WeightEntry(id: '', date: date, weightKg: weight));

    if (pickedPhoto != null) {
      final url = await ref
          .read(storageServiceProvider)
          .uploadWeightPhoto(uid: uid, logId: entryId, bytes: pickedPhoto);
      await ref
          .read(weightRepoProvider)
          .update(uid, entryId, {'photoUrl': url});

      final now = DateTime.now();
      await ref
          .read(storyRepoProvider)
          .add(
            uid,
            Story(
              id: '',
              type: StoryType.weight,
              photoUrl: url,
              weightKg: weight,
              createdAt: now,
              expiresAt: now.add(const Duration(hours: 24)),
            ),
          );
    }

    // Only overwrite the profile's "current" weight if this entry isn't
    // backdated — an old log shouldn't override today's actual current weight.
    if (!date.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    )) {
      await ref.read(userRepoProvider).updateProfile(uid, {
        'currentWeightKg': weight,
      });
    }
    await ref.read(userRepoProvider).registerActivityAndGetStreak(uid);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(weightLogsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _logWeight(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No weight logs yet. Tap "Log weight" to start.'),
            );
          }
          final chronological = logs.reversed.toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (profile != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: ${profile.currentWeightKg.toStringAsFixed(1)} kg',
                        ),
                        Text(
                          'Target: ${profile.targetWeightKg.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _WeightChart(entries: chronological),
              ),
              const SizedBox(height: 16),
              ...logs.map(
                (entry) => ListTile(
                  leading:
                      entry.photoUrl == null
                          ? const Icon(Icons.monitor_weight_outlined)
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: entry.photoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                  title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(
                    DateFormat.yMMMd().add_jm().format(entry.date),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final uid = ref.read(authStateProvider).valueOrNull?.uid;
                      if (uid != null) {
                        ref.read(weightRepoProvider).delete(uid, entry.id);
                      }
                    },
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

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(
        child: Text('Log a few more days to see your trend.'),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].weightKg),
    ];
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
