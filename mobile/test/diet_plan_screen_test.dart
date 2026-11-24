import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/diet_plan/diet_plan_repository.dart';
import 'package:kaloritakip/features/diet_plan/diet_plan_screen.dart';

DietPlans _data({String goal = 'lose', bool locked = false}) =>
    DietPlans.fromJson({
      'goal': goal,
      'user_goal': 'lose',
      'daily_kcal_target': 2200,
      'plans': [
        {
          'id': 1,
          'title': 'Kilo Verme Planı',
          'daily_kcal': 1770,
          'is_premium': locked,
          'locked': locked,
          'meals': locked
              ? []
              : [
                  {
                    'meal_type': 'breakfast',
                    'title': 'Kahvaltı',
                    'description': 'Yulaf, süt, muz, ceviz',
                    'kcal': 520,
                  },
                  {
                    'meal_type': 'lunch',
                    'title': 'Öğle',
                    'description': 'Izgara tavuk, bulgur, salata',
                    'kcal': 620,
                  },
                ],
        },
      ],
    });

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: ListView(children: [child])),
    ),
  );

  testWidgets('Kendi hedefinde günlük hedef ve örnek plan gösterilir', (
    tester,
  ) async {
    await pump(tester, DietPlanContent(data: _data()));
    expect(find.text('Günlük Hedefin'), findsOneWidget);
    expect(find.textContaining('2.200', findRichText: true), findsOneWidget);
    expect(find.text('Örnek Günlük Plan'), findsOneWidget);
    expect(find.text('Yulaf, süt, muz, ceviz'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);
  });

  testWidgets('Başka hedefte plan kalorisi, kilitli planda premium uyarısı', (
    tester,
  ) async {
    await pump(
      tester,
      DietPlanContent(data: _data(goal: 'gain', locked: true)),
    );
    expect(find.text('Plan Kalorisi'), findsOneWidget);
    expect(find.textContaining('1.770', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('Hedef sekmesi seçilir', (tester) async {
    PlanGoal? picked;
    await pump(
      tester,
      GoalSegments(value: PlanGoal.lose, onChanged: (g) => picked = g),
    );
    await tester.tap(find.text('Koruma'));
    expect(picked, PlanGoal.maintain);
  });
}
