import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../services/repositories/chat_repo.dart';
import '../services/repositories/custom_food_repo.dart';
import '../services/repositories/expense_repo.dart';
import '../services/repositories/favorite_food_repo.dart';
import '../services/repositories/friend_repo.dart';
import '../services/repositories/meal_repo.dart';
import '../services/repositories/notification_repo.dart';
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

/// A single, long-lived instance so scheduled reminders and the tap stream
/// survive across widget rebuilds — created once and disposed with the app.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    localNotifications: ref.watch(notificationServiceProvider),
    userRepo: ref.watch(userRepoProvider),
  );
});

final notificationRepoProvider = Provider<NotificationRepo>(
  (ref) => NotificationRepo(),
);

/// The signed-in user's notification feed — empty stream when signed out
/// rather than an error, so the bell can watch it unconditionally.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepoProvider).watchAll(uid);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(notificationRepoProvider).watchUnreadCount(uid);
});

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
