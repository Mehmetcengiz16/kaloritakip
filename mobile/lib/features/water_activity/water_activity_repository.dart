import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../home/dashboard_repository.dart';

class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.name,
    required this.icon,
    required this.minutes,
    required this.kcal,
  });

  final int id;
  final String name;
  final String icon;
  final int minutes;
  final int kcal;

  factory ActivityLogEntry.fromJson(Map<String, dynamic> j) => ActivityLogEntry(
    id: j['id'] as int,
    name: j['name'] as String,
    icon: j['icon'] as String,
    minutes: j['minutes'] as int,
    kcal: j['kcal'] as int,
  );
}

class ActivityType {
  const ActivityType({
    required this.id,
    required this.name,
    required this.icon,
    required this.kcalPerMinute,
  });

  final int id;
  final String name;
  final String icon;
  final double kcalPerMinute;

  int kcalFor(int minutes) => (kcalPerMinute * minutes).round();

  factory ActivityType.fromJson(Map<String, dynamic> j) => ActivityType(
    id: j['id'] as int,
    name: j['name'] as String,
    icon: j['icon'] as String,
    kcalPerMinute: (j['kcal_per_minute'] as num).toDouble(),
  );
}

class WaterActivity {
  const WaterActivity({
    required this.waterMl,
    required this.waterTargetMl,
    required this.burnedKcal,
    required this.logs,
    required this.catalog,
  });

  final int waterMl;
  final int waterTargetMl;
  final int burnedKcal;
  final List<ActivityLogEntry> logs;
  final List<ActivityType> catalog;

  double get waterRatio =>
      waterTargetMl <= 0 ? 0 : (waterMl / waterTargetMl).clamp(0, 1).toDouble();

  factory WaterActivity.fromJson(Map<String, dynamic> j) {
    final water = j['water'] as Map<String, dynamic>;
    final act = j['activity'] as Map<String, dynamic>;
    return WaterActivity(
      waterMl: water['consumed_ml'] as int,
      waterTargetMl: water['target_ml'] as int,
      burnedKcal: act['burned_kcal'] as int,
      logs: [
        for (final l in act['logs'] as List)
          ActivityLogEntry.fromJson(l as Map<String, dynamic>),
      ],
      catalog: [
        for (final c in j['catalog'] as List)
          ActivityType.fromJson(c as Map<String, dynamic>),
      ],
    );
  }
}

/// Sunucudaki ikon adlarının karşılığı (admin panelden aktivite eklenirken seçilen ad).
IconData activityIcon(String name) => switch (name) {
  'footprints' => Icons.directions_walk_rounded,
  'bike' => Icons.directions_bike_rounded,
  'waves' => Icons.pool_rounded,
  'dumbbell' => Icons.fitness_center_rounded,
  'flower' => Icons.self_improvement_rounded,
  _ => Icons.directions_run_rounded,
};

/// 1500 -> "1,5 L"
String liters(int ml) {
  final l = ml / 1000;
  return '${l.toStringAsFixed(1).replaceAll('.', ',')} L';
}

/// Her işlem sunucudan güncel özeti döndürür; ekran ek istek atmadan yenilenir.
class WaterActivityNotifier extends AsyncNotifier<WaterActivity> {
  Dio get _dio => ref.read(dioProvider);

  @override
  Future<WaterActivity> build() async {
    final res = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>('/water-activity');
    return WaterActivity.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> addWater(int ml) =>
      _apply(() => _dio.post('/water', data: {'amount_ml': ml}));

  Future<void> undoWater() => _apply(() => _dio.delete('/water/last'));

  Future<void> addActivity({required int activityId, required int minutes}) =>
      _apply(
        () => _dio.post(
          '/activities',
          data: {'activity_id': activityId, 'minutes': minutes},
        ),
        affectsCalories: true,
      );

  Future<void> addCustomActivity({
    required String name,
    required int minutes,
    required int kcal,
  }) => _apply(
    () => _dio.post(
      '/activities',
      data: {'name': name, 'minutes': minutes, 'kcal': kcal},
    ),
    affectsCalories: true,
  );

  Future<void> deleteActivity(int id) =>
      _apply(() => _dio.delete('/activity-logs/$id'), affectsCalories: true);

  Future<void> _apply(
    Future<Response<dynamic>> Function() call, {
    bool affectsCalories = false,
  }) async {
    final res = await call();
    state = AsyncData(
      WaterActivity.fromJson((res.data as Map)['data'] as Map<String, dynamic>),
    );
    // Yakılan kalori Ana Sayfa'daki kalan kaloriyi değiştirir.
    if (affectsCalories) ref.invalidate(dashboardProvider);
  }
}

final waterActivityProvider =
    AsyncNotifierProvider.autoDispose<WaterActivityNotifier, WaterActivity>(
      WaterActivityNotifier.new,
    );
