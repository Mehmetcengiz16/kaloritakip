import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'progress_insights.dart';

enum ProgressRange {
  week('week', 'Haftalık', 'son 7 gün'),
  month('month', 'Aylık', 'son 30 gün'),
  year('year', 'Yıllık', 'son 1 yıl');

  const ProgressRange(this.apiValue, this.label, this.periodLabel);
  final String apiValue;
  final String label;
  final String periodLabel;
}

class WeightPoint {
  const WeightPoint(this.date, this.weightKg);

  final DateTime date;
  final double weightKg;
}

class Progress {
  const Progress({
    required this.range,
    required this.currentWeightKg,
    required this.weightChangeKg,
    required this.bodyFatChangePct,
    required this.bmi,
    required this.points,
    this.goal,
    this.calories,
    this.macros,
    this.habits,
  });

  final ProgressRange range;
  final double? currentWeightKg;
  final double? weightChangeKg;
  final double? bodyFatChangePct;
  final double? bmi;
  final List<WeightPoint> points;
  final GoalProgress? goal;
  final CalorieStats? calories;
  final MacroStats? macros;
  final HabitStats? habits;

  static double? _d(Object? v) => (v as num?)?.toDouble();

  factory Progress.fromJson(Map<String, dynamic> j) => Progress(
    range: ProgressRange.values.firstWhere((r) => r.apiValue == j['range']),
    currentWeightKg: _d(j['current_weight_kg']),
    weightChangeKg: _d(j['weight_change_kg']),
    bodyFatChangePct: _d(j['body_fat_change_pct']),
    bmi: _d(j['bmi']),
    points: [
      for (final p in j['points'] as List)
        WeightPoint(
          DateTime.parse((p as Map)['date'] as String),
          (p['weight_kg'] as num).toDouble(),
        ),
    ],
    goal: GoalProgress.fromJson(j['goal']),
    calories: CalorieStats.fromJson(j['calories']),
    macros: MacroStats.fromJson(j['macros']),
    habits: HabitStats.fromJson(j['habits']),
  );
}

class ProgressRepository {
  ProgressRepository(this._dio);

  final Dio _dio;

  Future<Progress> fetch(ProgressRange range) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/progress',
      queryParameters: {'range': range.apiValue},
    );
    return Progress.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> addWeight(double kg, {double? bodyFatPct}) => _dio.post<void>(
    '/weight-logs',
    data: {'weight_kg': kg, 'body_fat_pct': ?bodyFatPct},
  );
}

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(dioProvider)),
);

final progressProvider = FutureProvider.autoDispose
    .family<Progress, ProgressRange>(
      (ref, range) => ref.watch(progressRepositoryProvider).fetch(range),
    );

/// -2.8 -> "−2,8"  /  1.4 -> "+1,4"
String signed(double v) {
  final s = v.abs().toStringAsFixed(1).replaceAll('.', ',');
  if (v < 0) return '−$s';
  if (v > 0) return '+$s';
  return s;
}

String decimal(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
