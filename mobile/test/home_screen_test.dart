import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/home/dashboard_repository.dart';
import 'package:kaloritakip/features/home/home_screen.dart';

Map<String, dynamic> _json({
  List<Map<String, dynamic>> breakfastItems = const [],
}) => {
  'user': {'first_name': 'Mehmet', 'goal': 'lose'},
  'calories': {'target': 2200, 'consumed': 950, 'burned': 0, 'remaining': 1250},
  'macros': {
    'protein': {'consumed': 75, 'target': 150},
    'carb': {'consumed': 160, 'target': 275},
    'fat': {'consumed': 40, 'target': 73},
  },
  'meals': [
    {
      'type': 'breakfast',
      'kcal': breakfastItems.isEmpty ? 0 : 520,
      'item_count': breakfastItems.length,
      'items': breakfastItems,
    },
    for (final t in ['snack1', 'lunch', 'snack2', 'dinner'])
      {'type': t, 'kcal': 0, 'item_count': 0, 'items': []},
  ],
};

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  Future<void> pump(WidgetTester tester, Dashboard d) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: HomeContent(data: d)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Ana Sayfa tasarımdaki bilgileri gösterir', (tester) async {
    await pump(
      tester,
      Dashboard.fromJson(
        _json(
          breakfastItems: [
            {'id': 1, 'name': 'Yulaf', 'grams': 80, 'kcal': 520},
          ],
        ),
      ),
    );

    expect(find.text('Merhaba Mehmet 👋'), findsOneWidget);
    expect(find.text('Hedef: Kilo Vermek'), findsOneWidget);
    expect(find.text('Kalan Kalori'), findsOneWidget);
    expect(find.textContaining('1.250'), findsOneWidget);
    expect(find.text('Hedef: 2.200 kcal'), findsOneWidget);
    expect(find.text('Karbonhidrat'), findsOneWidget);
    expect(find.text('AI ile Analiz'), findsOneWidget);
    expect(find.text('Kahvaltı'), findsOneWidget);
    expect(find.text('Bugün henüz bir şey eklemedin.'), findsNothing);
  });

  testWidgets('Öğün yoksa boş durum gösterilir', (tester) async {
    await pump(tester, Dashboard.fromJson(_json()));
    expect(find.text('Bugün henüz bir şey eklemedin.'), findsOneWidget);
  });

  test('Halka doluluğu yakılan kaloriyi bütçeye ekler', () {
    final j = _json();
    (j['calories'] as Map)['burned'] = 200;
    expect(Dashboard.fromJson(j).ringProgress, closeTo(950 / 2400, 0.0001));
  });
}
