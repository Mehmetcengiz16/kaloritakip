import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_food/add_food_screen.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/diet_plan/diet_plan_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/onboarding/onboarding_activity_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/onboarding/onboarding_body_screen.dart';
import '../../features/onboarding/onboarding_details_screen.dart';
import '../../features/onboarding/onboarding_goal_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/profile/account_screens.dart';
import '../../features/profile/goals_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/water_activity/water_activity_screen.dart';
import '../../features/welcome/welcome_screen.dart';

/// Açılışta kayıtlı token varsa /home, yoksa /welcome (main.dart'ta belirlenir).
final initialLocationProvider = Provider<String>((_) => '/welcome');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: ref.watch(initialLocationProvider),
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingGoalScreen(),
      ),
      GoRoute(
        path: '/onboarding/details',
        builder: (_, _) => const OnboardingDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/body',
        builder: (_, _) => const OnboardingBodyScreen(),
      ),
      GoRoute(
        path: '/onboarding/activity',
        builder: (_, _) => const OnboardingActivityScreen(),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/profile/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(path: '/profile/data', builder: (_, _) => const MyDataScreen()),
      GoRoute(
        path: '/profile/settings',
        builder: (_, _) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (_, state) =>
            PremiumScreen(reason: state.uri.queryParameters['reason']),
      ),
      GoRoute(
        path: '/water-activity',
        builder: (_, _) => const WaterActivityScreen(),
      ),
      // /add-food?tab=search|barcode|photo&meal=lunch
      GoRoute(
        path: '/add-food',
        builder: (_, state) => AddFoodScreen(
          initialTab:
              AddFoodTab.values.asNameMap()[state.uri.queryParameters['tab']] ??
              AddFoodTab.photo,
          mealType: state.uri.queryParameters['meal'],
          date: state.uri.queryParameters['date'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (_, _) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const DietPlanScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
