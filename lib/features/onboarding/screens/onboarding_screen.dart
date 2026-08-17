import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/calculations.dart';
import '../providers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _ageController = TextEditingController();
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;

  // Non-null once calculated, so the results card can be shown before saving.
  double? _previewBmi;
  double? _previewTdee;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _preview() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.parse(_weightController.text);
    final height = double.parse(_heightController.text);
    final age = int.parse(_ageController.text);
    setState(() {
      _previewBmi = FitnessCalculations.bmi(weightKg: weight, heightCm: height);
      _previewTdee = FitnessCalculations.tdee(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: _gender,
        activityLevel: _activityLevel,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final input = OnboardingInput(
      currentWeightKg: double.parse(_weightController.text),
      heightCm: double.parse(_heightController.text),
      targetWeightKg: double.parse(_targetWeightController.text),
      age: int.parse(_ageController.text),
      gender: _gender,
      activityLevel: _activityLevel,
    );
    await ref.read(onboardingControllerProvider.notifier).submit(input);
    final state = ref.read(onboardingControllerProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: ${state.error}')),
      );
    }
    // On success, the router redirect (profile now exists) sends the user
    // to the dashboard automatically.
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about yourself')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              onChanged: _preview,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Current weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _targetWeightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Target weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            border: OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Gender>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        Gender.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.name),
                              ),
                            )
                            .toList(),
                    onChanged: (g) {
                      setState(() => _gender = g ?? _gender);
                      _preview();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ActivityLevel>(
                    value: _activityLevel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Activity level',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ActivityLevel.values
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.label),
                              ),
                            )
                            .toList(),
                    onChanged: (a) {
                      setState(() => _activityLevel = a ?? _activityLevel);
                      _preview();
                    },
                  ),
                  if (_previewBmi != null && _previewTdee != null) ...[
                    const SizedBox(height: 24),
                    _ResultsPreviewCard(bmi: _previewBmi!, tdee: _previewTdee!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child:
                        isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save and continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }
}

class _ResultsPreviewCard extends StatelessWidget {
  final double bmi;
  final double tdee;

  const _ResultsPreviewCard({required this.bmi, required this.tdee});

  @override
  Widget build(BuildContext context) {
    final category = FitnessCalculations.bmiCategory(bmi);
    final targets = FitnessCalculations.calorieTargets(tdee);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your numbers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('BMI: ${bmi.toStringAsFixed(1)} (${category.label})'),
            Text(
              'Maintenance calories (TDEE): ${tdee.toStringAsFixed(0)} kcal/day',
            ),
            const SizedBox(height: 8),
            Text(
              'Mild deficit: ${targets.mildDeficit.toStringAsFixed(0)} kcal',
            ),
            Text(
              'Moderate deficit: ${targets.moderateDeficit.toStringAsFixed(0)} kcal',
            ),
            Text(
              'Aggressive deficit: ${targets.aggressiveDeficit.toStringAsFixed(0)} kcal',
            ),
            Text(
              'Surplus (bulking): ${targets.surplus.toStringAsFixed(0)} kcal',
            ),
          ],
        ),
      ),
    );
  }
}
