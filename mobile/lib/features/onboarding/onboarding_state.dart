import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Goal {
  lose('lose'),
  gain('gain'),
  maintain('maintain'),
  healthy('healthy');

  const Goal(this.apiValue);
  final String apiValue;
}

enum Gender {
  female('female', 'Kadın'),
  male('male', 'Erkek');

  const Gender(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum ActivityLevel {
  sedentary('sedentary', 'Hareketsiz', 'Masa başı iş, çok az egzersiz'),
  light('light', 'Az Hareketli', 'Haftada 1-3 gün hafif egzersiz'),
  moderate('moderate', 'Orta Hareketli', 'Haftada 3-5 gün egzersiz'),
  active('active', 'Çok Hareketli', 'Haftada 6-7 gün egzersiz'),
  veryActive('very_active', 'Sporcu', 'Günde 2 antrenman veya fiziksel iş');

  const ActivityLevel(this.apiValue, this.label, this.description);
  final String apiValue;
  final String label;
  final String description;
}

/// Onboarding adımlarında toplanan veriler; kayıttan sonra POST /onboarding'e gönderilir.
class OnboardingData {
  const OnboardingData({
    this.goal = Goal.lose,
    this.gender,
    this.birthDate,
    this.heightCm = 170,
    this.weightKg = 70,
    this.targetWeightKg = 65,
    this.activityLevel = ActivityLevel.light,
  });

  final Goal goal;
  final Gender? gender;
  final DateTime? birthDate;
  final int heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;

  bool get detailsValid => gender != null && birthDate != null;

  /// Kilo korumak/sağlıklı beslenmek hedeflerinde hedef kilo sorulmaz.
  bool get needsTargetWeight => goal == Goal.lose || goal == Goal.gain;

  OnboardingData copyWith({
    Goal? goal,
    Gender? gender,
    DateTime? birthDate,
    int? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
  }) => OnboardingData(
    goal: goal ?? this.goal,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    activityLevel: activityLevel ?? this.activityLevel,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal.apiValue,
    'gender': gender?.apiValue,
    'birth_date': birthDate?.toIso8601String().substring(0, 10),
    'height_cm': heightCm,
    'weight_kg': weightKg,
    if (needsTargetWeight) 'target_weight_kg': targetWeightKg,
    'activity_level': activityLevel.apiValue,
  };
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void setGoal(Goal goal) {
    // Hedef kilo, hedefle uyumlu bir başlangıç değeri alsın.
    final target = switch (goal) {
      Goal.lose => state.weightKg - 5,
      Goal.gain => state.weightKg + 5,
      _ => state.weightKg,
    };
    state = state.copyWith(goal: goal, targetWeightKg: target);
  }

  void setGender(Gender g) => state = state.copyWith(gender: g);
  void setBirthDate(DateTime d) => state = state.copyWith(birthDate: d);
  void setHeight(int cm) => state = state.copyWith(heightCm: cm);
  void setWeight(double kg) => state = state.copyWith(weightKg: kg);
  void setTargetWeight(double kg) => state = state.copyWith(targetWeightKg: kg);
  void setActivity(ActivityLevel a) => state = state.copyWith(activityLevel: a);

  void reset() => state = const OnboardingData();
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);
