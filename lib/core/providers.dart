import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/repositories/chat_repo.dart';
import '../services/repositories/custom_food_repo.dart';
import '../services/repositories/expense_repo.dart';
import '../services/repositories/favorite_food_repo.dart';
import '../services/repositories/friend_repo.dart';
import '../services/repositories/meal_repo.dart';
import '../services/repositories/recipe_repo.dart';
import '../services/repositories/saved_meal_repo.dart';
import '../services/repositories/user_recipe_repo.dart';
import '../services/repositories/user_repo.dart';
import '../services/repositories/weight_repo.dart';
import '../services/repositories/workout_repo.dart';
import '../services/repositories/workout_plan_repo.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final userRepoProvider = Provider<UserRepo>((ref) => UserRepo());
final weightRepoProvider = Provider<WeightRepo>((ref) => WeightRepo());
final mealRepoProvider = Provider<MealRepo>((ref) => MealRepo());
final workoutRepoProvider = Provider<WorkoutRepo>((ref) => WorkoutRepo());
final workoutPlanRepoProvider = Provider<WorkoutPlanRepo>(
  (ref) => WorkoutPlanRepo(),
);
final expenseRepoProvider = Provider<ExpenseRepo>((ref) => ExpenseRepo());
final customFoodRepoProvider = Provider<CustomFoodRepo>(
  (ref) => CustomFoodRepo(),
);
final favoriteFoodRepoProvider = Provider<FavoriteFoodRepo>(
  (ref) => FavoriteFoodRepo(),
);
final savedMealRepoProvider = Provider<SavedMealRepo>((ref) => SavedMealRepo());
final userRecipeRepoProvider = Provider<UserRecipeRepo>(
  (ref) => UserRecipeRepo(),
);
final recipeRepoProvider = Provider<RecipeRepo>((ref) => RecipeRepo());
final friendRepoProvider = Provider<FriendRepo>((ref) => FriendRepo());
final chatRepoProvider = Provider<ChatRepo>((ref) => ChatRepo());

/// Emits the current Firebase user, or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Emits the signed-in user's Firestore profile, or null before onboarding
/// is complete / while signed out.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepoProvider).watchProfile(user.uid);
});
