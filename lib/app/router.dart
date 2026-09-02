import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation_key.dart';
import '../core/providers.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/home/home_shell.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/tracking/tracking_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/exercises/pages/exercises_screen.dart';
import '../features/exercises/pages/exercise_details/exercise_details_screen.dart';
import '../features/diet_suggestion/diet_suggestion_screen.dart';
import '../features/food_recommendation/food_recommendation_screen.dart';
import '../features/social/social_screen.dart';
import '../features/social/chat/chat_thread_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/wellness_reminders_screen.dart';

/// Notifies go_router whenever auth or profile state changes, so its
/// [redirect] callback is re-evaluated (e.g. right after sign-in or once
/// onboarding finishes writing the profile document).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;

      const loggingInRoutes = ['/login', '/signup', '/forgot-password'];
      final goingToAuthRoute = loggingInRoutes.contains(state.matchedLocation);

      if (!isLoggedIn) {
        return goingToAuthRoute ? null : '/login';
      }

      if (goingToAuthRoute) return '/dashboard';

      // Gate everything except /onboarding behind a completed profile.
      final profileState = ref.read(userProfileProvider);
      final hasProfile = profileState.valueOrNull != null;
      final profileLoaded = !profileState.isLoading;

      if (profileLoaded &&
          !hasProfile &&
          state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      if (hasProfile && state.matchedLocation == '/onboarding') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/tracking',
            builder: (context, state) => const TrackingScreen(),
          ),
          GoRoute(
            path: '/exercises',
            builder: (context, state) => const ExercisesScreen(),
          ),
          GoRoute(
            path: '/exercises/:id',
            builder:
                (context, state) => ExerciseDetailsScreen(
                  exerciseId: state.pathParameters['id']!,
                ),
          ),
          GoRoute(
            path: '/wellness-reminders',
            builder: (context, state) => const WellnessRemindersScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/diet-suggestion',
            builder: (context, state) => const DietSuggestionScreen(),
          ),
          GoRoute(
            path: '/food-recommendation',
            builder: (context, state) => const FoodRecommendationScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialScreen(),
          ),
          GoRoute(
            path: '/social/chat/:chatId',
            builder:
                (context, state) =>
                    ChatThreadScreen(chatId: state.pathParameters['chatId']!),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
