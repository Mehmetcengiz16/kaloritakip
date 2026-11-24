import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/progress/progress_repository.dart';
import 'package:kaloritakip/features/progress/progress_screen.dart';
import 'package:kaloritakip/features/progress/progress_sections.dart';

Map<String, dynamic> _json({List<Map<String, dynamic>> points = const []}) => {
  'range': 'week',
  'current_weight_kg': 155.0,
  'weight_change_kg': -2.8,
  'body_fat_change_pct': -1.4,
  'bmi': 40.7,
  'points': points,
};

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: ListView(children: [child])),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('İşaretli sayı biçimi', () {
    expect(signed(-2.8), '−2,8');
    expect(signed(1.4), '+1,4');
    expect(decimal(155), '155,0');
  });

  testWidgets('Tasarımdaki kilo kartı ve özet kartları', (tester) async {
    await pump(
      tester,
      ProgressContent(
        progress: Progress.fromJson(
          _json(
            points: [
              {'date': '2026-11-15', 'weight_kg': 157.8},
              {'date': '2026-11-18', 'weight_kg': 156.5},
              {'date': '2026-11-21', 'weight_kg': 155.0},
            ],
          ),
        ),
      ),
    );

    expect(find.text('155,0'), findsOneWidget);
    expect(find.text('−2,8 kg'), findsNWidgets(2)); // başlık + Kilo kartı
    expect(find.text('(son 7 gün)'), findsOneWidget);
    expect(find.text('−1,4 %'), findsOneWidget);
    expect(find.text('40,7'), findsOneWidget);
    expect(find.text('Yağ Oranı'), findsOneWidget);
  });

  testWidgets('Kayıt yoksa grafik yerine yönlendirme', (tester) async {
    await pump(tester, ProgressContent(progress: Progress.fromJson(_json())));
    expect(find.textContaining('Bu dönemde kilo kaydı yok.'), findsOneWidget);
  });

  testWidgets('Segment seçimi değişir', (tester) async {
    var selected = ProgressRange.week;
    await pump(
      tester,
      RangeSegments(value: selected, onChanged: (r) => selected = r),
    );
    await tester.tap(find.text('Yıllık'));
    expect(selected, ProgressRange.year);
  });

  testWidgets('Yeni bölümler: hedef, kalori, makro, seri', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 3000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final json =
        _json(
            points: [
              {'date': '2026-11-15', 'weight_kg': 157.8},
              {'date': '2026-11-21', 'weight_kg': 155.0},
            ],
          )
          ..['goal'] = {
            'start_kg': 160,
            'current_kg': 155,
            'target_kg': 140,
            'progress_pct': 25,
            'remaining_kg': 15,
            'reached': false,
            'eta_date': '2027-03-01',
          }
          ..['calories'] = {
            'target': 2200,
            'avg': 2050,
            'logged_days': 3,
            'on_target_days': 2,
            'bars': [
              for (var d = 15; d <= 21; d++)
                {'date': '2026-11-$d', 'kcal': d.isOdd ? 2600 : 1900},
            ],
          }
          ..['macros'] = {
            'protein': {'avg': 120, 'target': 150, 'pct': 30},
            'carb': {'avg': 200, 'target': 250, 'pct': 50},
            'fat': {'avg': 35, 'target': 70, 'pct': 20},
          }
          ..['habits'] = {
            'streak_days': 4,
            'logged_days': 5,
            'period_days': 7,
            'avg_water_ml': 1500,
            'activity_kcal': 320,
          };

    await pump(tester, ProgressContent(progress: Progress.fromJson(json)));

    expect(find.byType(GoalProgressCard), findsOneWidget);
    expect(find.text('%25'), findsOneWidget);
    expect(find.textContaining('15,0 kg kaldı'), findsOneWidget);
    expect(find.textContaining('1 Mart'), findsOneWidget);
    expect(find.text('2/3 gün'), findsOneWidget);
    expect(find.text('-150 kcal'), findsOneWidget);
    expect(find.text('120 / 150 g'), findsOneWidget);
    expect(find.text('4 gün'), findsOneWidget);
    expect(find.text('1,5 L'), findsOneWidget);
    expect(find.textContaining('böyle devam'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Eski yanıt (yeni alanlar yok) sorunsuz açılır', (tester) async {
    await pump(tester, ProgressContent(progress: Progress.fromJson(_json())));
    expect(find.byType(GoalProgressCard), findsNothing);
    expect(find.byType(CalorieChartCard), findsNothing);
  });
}
