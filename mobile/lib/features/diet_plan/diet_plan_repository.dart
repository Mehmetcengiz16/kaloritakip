import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

enum PlanGoal {
  lose('lose', 'Kilo Verme'),
  gain('gain', 'Kilo Alma'),
  maintain('maintain', 'Koruma');

  const PlanGoal(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PlanGoal fromApi(String v) =>
      values.firstWhere((g) => g.apiValue == v, orElse: () => maintain);
}

class PlanMeal {
  const PlanMeal({
    required this.mealType,
    required this.title,
    this.description,
    required this.kcal,
  });

  final String mealType;
  final String title;
  final String? description;
  final int kcal;

  factory PlanMeal.fromJson(Map<String, dynamic> j) => PlanMeal(
    mealType: j['meal_type'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    kcal: j['kcal'] as int,
  );
}

class DietPlan {
  const DietPlan({
    required this.id,
    required this.title,
    required this.dailyKcal,
    required this.locked,
    required this.meals,
  });

  final int id;
  final String title;
  final int dailyKcal;
  final bool locked;
  final List<PlanMeal> meals;

  factory DietPlan.fromJson(Map<String, dynamic> j) => DietPlan(
    id: j['id'] as int,
    title: j['title'] as String,
    dailyKcal: j['daily_kcal'] as int,
    locked: j['locked'] as bool,
    meals: [
      for (final m in j['meals'] as List)
        PlanMeal.fromJson(m as Map<String, dynamic>),
    ],
  );
}

class DietPlans {
  const DietPlans({
    required this.goal,
    required this.userGoal,
    required this.userTargetKcal,
    required this.plans,
  });

  final PlanGoal goal;
  final PlanGoal userGoal;
  final int userTargetKcal;
  final List<DietPlan> plans;

  bool get isOwnGoal => goal == userGoal;

  factory DietPlans.fromJson(Map<String, dynamic> j) => DietPlans(
    goal: PlanGoal.fromApi(j['goal'] as String),
    userGoal: PlanGoal.fromApi(j['user_goal'] as String),
    userTargetKcal: j['daily_kcal_target'] as int,
    plans: [
      for (final p in j['plans'] as List)
        DietPlan.fromJson(p as Map<String, dynamic>),
    ],
  );
}

class DietPlanRepository {
  DietPlanRepository(this._dio);

  final Dio _dio;

  Future<DietPlans> fetch(PlanGoal? goal) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/diet-plans',
      queryParameters: {if (goal != null) 'goal': goal.apiValue},
    );
    return DietPlans.fromJson(res.data!['data'] as Map<String, dynamic>);
  }
}

final dietPlanRepositoryProvider = Provider(
  (ref) => DietPlanRepository(ref.watch(dioProvider)),
);

/// null = kullanıcının kendi hedefi (sunucu belirler).
final dietPlansProvider = FutureProvider.autoDispose
    .family<DietPlans, PlanGoal?>(
      (ref, goal) => ref.watch(dietPlanRepositoryProvider).fetch(goal),
    );
