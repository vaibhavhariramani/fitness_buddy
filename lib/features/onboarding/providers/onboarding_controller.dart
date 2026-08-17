import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/calculations.dart';
import '../../../models/user_profile.dart';
import '../../../models/weight_entry.dart';

class OnboardingInput {
  final double currentWeightKg;
  final double heightCm;
  final double targetWeightKg;
  final int age;
  final Gender gender;
  final ActivityLevel activityLevel;

  const OnboardingInput({
    required this.currentWeightKg,
    required this.heightCm,
    required this.targetWeightKg,
    required this.age,
    required this.gender,
    required this.activityLevel,
  });
}

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, void>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> submit(OnboardingInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw StateError('Cannot complete onboarding while signed out.');
      }

      final bmi = FitnessCalculations.bmi(
        weightKg: input.currentWeightKg,
        heightCm: input.heightCm,
      );
      final bmiCategory = FitnessCalculations.bmiCategory(bmi);
      final tdee = FitnessCalculations.tdee(
        weightKg: input.currentWeightKg,
        heightCm: input.heightCm,
        age: input.age,
        gender: input.gender,
        activityLevel: input.activityLevel,
      );
      final calorieTargets = FitnessCalculations.calorieTargets(tdee);
      final macros = FitnessCalculations.macros(
        calorieTarget: calorieTargets.maintenance,
        weightKg: input.currentWeightKg,
      );

      final profile = UserProfile(
        uid: user.uid,
        displayName: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        age: input.age,
        gender: input.gender,
        heightCm: input.heightCm,
        currentWeightKg: input.currentWeightKg,
        targetWeightKg: input.targetWeightKg,
        activityLevel: input.activityLevel,
        bmi: bmi,
        bmiCategory: bmiCategory,
        tdee: tdee,
        calorieTargets: calorieTargets,
        macros: macros,
        createdAt: DateTime.now(),
      );

      await ref.read(userRepoProvider).createProfile(profile);
      // Seed day-one weight log so the weight chart has a starting point.
      await ref
          .read(weightRepoProvider)
          .add(
            user.uid,
            WeightEntry(
              id: '',
              date: DateTime.now(),
              weightKg: input.currentWeightKg,
            ),
          );
    });
  }
}
