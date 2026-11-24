/// İlerleme ekranının ek bölümleri için veri modelleri (GET /progress → goal, calories, macros, habits).
library;

class GoalProgress {
  const GoalProgress({
    required this.startKg,
    required this.currentKg,
    required this.targetKg,
    required this.progressPct,
    required this.remainingKg,
    required this.reached,
    this.etaDate,
  });

  final double startKg;
  final double currentKg;
  final double targetKg;
  final int progressPct;
  final double remainingKg;
  final bool reached;
  final DateTime? etaDate;

  static GoalProgress? fromJson(Object? j) {
    if (j is! Map) return null;
    return GoalProgress(
      startKg: (j['start_kg'] as num).toDouble(),
      currentKg: (j['current_kg'] as num).toDouble(),
      targetKg: (j['target_kg'] as num).toDouble(),
      progressPct: (j['progress_pct'] as num).round(),
      remainingKg: (j['remaining_kg'] as num).toDouble(),
      reached: j['reached'] as bool,
      etaDate: j['eta_date'] == null
          ? null
          : DateTime.parse(j['eta_date'] as String),
    );
  }
}

class CalorieBar {
  const CalorieBar(this.date, this.kcal);

  final DateTime date;
  final int kcal;
}

class CalorieStats {
  const CalorieStats({
    required this.target,
    required this.avg,
    required this.loggedDays,
    required this.onTargetDays,
    required this.bars,
  });

  final int target;
  final int avg;
  final int loggedDays;
  final int onTargetDays;
  final List<CalorieBar> bars;

  static CalorieStats? fromJson(Object? j) {
    if (j is! Map) return null;
    return CalorieStats(
      target: j['target'] as int,
      avg: j['avg'] as int,
      loggedDays: j['logged_days'] as int,
      onTargetDays: j['on_target_days'] as int,
      bars: [
        for (final b in j['bars'] as List)
          CalorieBar(
            DateTime.parse((b as Map)['date'] as String),
            b['kcal'] as int,
          ),
      ],
    );
  }
}

class MacroAvg {
  const MacroAvg(this.avg, this.target, this.pct);

  final int avg;
  final int target;
  final int pct;

  double get ratio => target <= 0 ? 0 : (avg / target).clamp(0, 1).toDouble();

  factory MacroAvg.fromJson(Map j) =>
      MacroAvg(j['avg'] as int, j['target'] as int, j['pct'] as int);
}

class MacroStats {
  const MacroStats(this.protein, this.carb, this.fat);

  final MacroAvg protein;
  final MacroAvg carb;
  final MacroAvg fat;

  bool get isEmpty => protein.avg == 0 && carb.avg == 0 && fat.avg == 0;

  static MacroStats? fromJson(Object? j) {
    if (j is! Map) return null;
    return MacroStats(
      MacroAvg.fromJson(j['protein'] as Map),
      MacroAvg.fromJson(j['carb'] as Map),
      MacroAvg.fromJson(j['fat'] as Map),
    );
  }
}

class HabitStats {
  const HabitStats({
    required this.streakDays,
    required this.loggedDays,
    required this.periodDays,
    required this.avgWaterMl,
    required this.activityKcal,
  });

  final int streakDays;
  final int loggedDays;
  final int periodDays;
  final int avgWaterMl;
  final int activityKcal;

  static HabitStats? fromJson(Object? j) {
    if (j is! Map) return null;
    return HabitStats(
      streakDays: j['streak_days'] as int,
      loggedDays: j['logged_days'] as int,
      periodDays: j['period_days'] as int,
      avgWaterMl: j['avg_water_ml'] as int,
      activityKcal: j['activity_kcal'] as int,
    );
  }
}
