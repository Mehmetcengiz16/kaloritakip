import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../add_food/add_food_repository.dart' show AiQuota;

class MacroProgress {
  const MacroProgress(this.consumed, this.target);

  final int consumed;
  final int target;

  double get ratio =>
      target <= 0 ? 0 : (consumed / target).clamp(0, 1).toDouble();

  factory MacroProgress.fromJson(Map<String, dynamic> j) =>
      MacroProgress(j['consumed'] as int, j['target'] as int);
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.grams,
    required this.kcal,
    this.imageUrl,
  });

  final int id;
  final String name;
  final int grams;
  final int kcal;
  final String? imageUrl;

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    id: j['id'] as int,
    name: j['name'] as String,
    grams: j['grams'] as int,
    kcal: j['kcal'] as int,
    imageUrl: j['image_url'] as String?,
  );
}

class MealSummary {
  const MealSummary({
    required this.type,
    required this.kcal,
    required this.items,
  });

  final String type;
  final int kcal;
  final List<MealEntry> items;

  int get itemCount => items.length;
  List<String> get itemNames => [for (final i in items) i.name];

  factory MealSummary.fromJson(Map<String, dynamic> j) => MealSummary(
    type: j['type'] as String,
    kcal: j['kcal'] as int,
    items: [
      for (final i in j['items'] as List)
        MealEntry.fromJson(i as Map<String, dynamic>),
    ],
  );
}

class Dashboard {
  const Dashboard({
    required this.firstName,
    required this.goal,
    required this.targetKcal,
    required this.consumedKcal,
    required this.burnedKcal,
    required this.remainingKcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.meals,
    this.aiQuota,
  });

  final String firstName;
  final String goal;
  final int targetKcal;
  final int consumedKcal;
  final int burnedKcal;
  final int remainingKcal;
  final MacroProgress protein;
  final MacroProgress carb;
  final MacroProgress fat;
  final List<MealSummary> meals;
  final AiQuota? aiQuota;

  /// Halkada gösterilecek doluluk: tüketilen / (hedef + yakılan).
  double get ringProgress {
    final budget = targetKcal + burnedKcal;
    return budget <= 0 ? 0 : (consumedKcal / budget).clamp(0, 1).toDouble();
  }

  factory Dashboard.fromJson(Map<String, dynamic> j) {
    final cal = j['calories'] as Map<String, dynamic>;
    final macros = j['macros'] as Map<String, dynamic>;
    final user = j['user'] as Map<String, dynamic>;
    return Dashboard(
      firstName: user['first_name'] as String,
      goal: user['goal'] as String,
      targetKcal: cal['target'] as int,
      consumedKcal: cal['consumed'] as int,
      burnedKcal: cal['burned'] as int,
      remainingKcal: cal['remaining'] as int,
      protein: MacroProgress.fromJson(
        macros['protein'] as Map<String, dynamic>,
      ),
      carb: MacroProgress.fromJson(macros['carb'] as Map<String, dynamic>),
      fat: MacroProgress.fromJson(macros['fat'] as Map<String, dynamic>),
      meals: [
        for (final m in j['meals'] as List)
          MealSummary.fromJson(m as Map<String, dynamic>),
      ],
      aiQuota: j['ai_quota'] == null
          ? null
          : AiQuota.fromJson(j['ai_quota'] as Map<String, dynamic>),
    );
  }
}

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<Dashboard> fetch({DateTime? date}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/dashboard',
      queryParameters: {if (date != null) 'date': apiDate(date)},
    );
    return Dashboard.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> deleteItem(int id) => _dio.delete<void>('/meal-items/$id');
}

final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

final dashboardProvider = FutureProvider.autoDispose<Dashboard>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetch(),
);

/// Beslenme ekranı: seçilen günün öğünleri (aynı /dashboard uç noktası, tarih parametresiyle).
final dayMealsProvider = FutureProvider.autoDispose.family<Dashboard, DateTime>(
  (ref, date) => ref.watch(dashboardRepositoryProvider).fetch(date: date),
);

/// 2026-11-22 biçimi.
String apiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
