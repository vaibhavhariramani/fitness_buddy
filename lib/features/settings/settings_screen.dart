import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_mode_controller.dart';
import '../../core/providers.dart';
import '../../core/utils/calculations.dart';
import '../../models/user_profile.dart';
import '../auth/providers/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _displayNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _prefilledForUid;

  @override
  void dispose() {
    _displayNameController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(UserProfile profile) {
    if (_prefilledForUid == profile.uid) return;
    _prefilledForUid = profile.uid;
    _displayNameController.text = profile.displayName;
    _weightController.text = profile.currentWeightKg.toStringAsFixed(1);
    _targetWeightController.text = profile.targetWeightKg.toStringAsFixed(1);
    _heightController.text = profile.heightCm.toStringAsFixed(1);
  }

  Future<void> _saveDisplayName(UserProfile profile) async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty || displayName == profile.displayName) return;

    await ref
        .read(userRepoProvider)
        .updateDisplayName(profile.uid, displayName);
    await ref.read(authServiceProvider).updateDisplayName(displayName);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name updated')));
    }
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final weight =
        double.tryParse(_weightController.text) ?? profile.currentWeightKg;
    final target =
        double.tryParse(_targetWeightController.text) ?? profile.targetWeightKg;
    final height = double.tryParse(_heightController.text) ?? profile.heightCm;

    final bmi = FitnessCalculations.bmi(weightKg: weight, heightCm: height);
    final tdee = FitnessCalculations.tdee(
      weightKg: weight,
      heightCm: height,
      age: profile.age,
      gender: profile.gender,
      activityLevel: profile.activityLevel,
    );
    final calorieTargets = FitnessCalculations.calorieTargets(tdee);
    final macros = FitnessCalculations.macros(
      calorieTarget: calorieTargets.maintenance,
      weightKg: weight,
    );

    await ref.read(userRepoProvider).updateProfile(profile.uid, {
      'currentWeightKg': weight,
      'targetWeightKg': target,
      'heightCm': height,
      'bmi': bmi,
      'bmiCategory': FitnessCalculations.bmiCategory(bmi).name,
      'tdee': tdee,
      'calorieTargets': calorieTargets.toJson(),
      'macros': macros.toJson(),
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _updatePrivacy(UserProfile profile, PrivacySettings privacy) {
    return ref.read(userRepoProvider).updateProfile(profile.uid, {
      'privacy': privacy.toJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _prefillIfNeeded(profile);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: 'Display name',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _saveDisplayName(profile),
              ),
            ),
            onSubmitted: (_) => _saveDisplayName(profile),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Current weight (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target weight (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _saveProfile(profile),
            child: const Text('Save profile'),
          ),
          const SizedBox(height: 32),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {ref.watch(themeModeProvider)},
            onSelectionChanged:
                (selection) => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first),
          ),
          const SizedBox(height: 32),
          Text(
            'Privacy — what friends can see',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            title: const Text('Share weight trend'),
            value: profile.privacy.shareWeight,
            onChanged:
                (v) => _updatePrivacy(
                  profile,
                  PrivacySettings(
                    shareWeight: v,
                    shareWorkouts: profile.privacy.shareWorkouts,
                    shareStreak: profile.privacy.shareStreak,
                  ),
                ),
          ),
          SwitchListTile(
            title: const Text('Share workouts'),
            value: profile.privacy.shareWorkouts,
            onChanged:
                (v) => _updatePrivacy(
                  profile,
                  PrivacySettings(
                    shareWeight: profile.privacy.shareWeight,
                    shareWorkouts: v,
                    shareStreak: profile.privacy.shareStreak,
                  ),
                ),
          ),
          SwitchListTile(
            title: const Text('Share streak'),
            value: profile.privacy.shareStreak,
            onChanged:
                (v) => _updatePrivacy(
                  profile,
                  PrivacySettings(
                    shareWeight: profile.privacy.shareWeight,
                    shareWorkouts: profile.privacy.shareWorkouts,
                    shareStreak: v,
                  ),
                ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed:
                () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
