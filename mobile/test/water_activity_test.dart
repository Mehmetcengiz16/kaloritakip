import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/water_activity/water_activity_repository.dart';
import 'package:kaloritakip/features/water_activity/water_activity_screen.dart';

WaterActivity _data() => WaterActivity.fromJson({
  'water': {'consumed_ml': 1500, 'target_ml': 3000},
  'activity': {
    'burned_kcal': 280,
    'logs': [
      {
        'id': 1,
        'name': 'Yürüyüş',
        'icon': 'footprints',
        'minutes': 30,
        'kcal': 120,
      },
      {'id': 2, 'name': 'Bisiklet', 'icon': 'bike', 'minutes': 20, 'kcal': 160},
    ],
  },
  'catalog': [
    {'id': 1, 'name': 'Yürüyüş', 'icon': 'footprints', 'kcal_per_minute': 4.0},
  ],
});

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  test('Litre biçimi ve oran', () {
    expect(liters(1500), '1,5 L');
    expect(liters(3000), '3,0 L');
    expect(_data().waterRatio, 0.5);
  });

  testWidgets('Tasarımdaki su ve aktivite kartları', (tester) async {
    int? water;
    ActivityLogEntry? tapped;
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: WaterActivityContent(
            data: _data(),
            onWater: (ml) => water = ml,
            onAddActivity: () => added = true,
            onTapLog: (l) => tapped = l,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Su ve Aktivite'), findsOneWidget);
    expect(find.textContaining('1,5 L', findRichText: true), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('280 kcal'), findsOneWidget);
    expect(find.text('30 dk • 120 kcal'), findsOneWidget);
    expect(find.text('20 dk • 160 kcal'), findsOneWidget);

    await tester.tap(find.text('+500 ml'));
    expect(water, 500);
    await tester.tap(find.text('+1 L'));
    expect(water, 1000);
    await tester.tap(find.text('Bisiklet'));
    expect(tapped?.id, 2);
    await tester.tap(find.text('Diğer Aktivite'));
    expect(added, isTrue);
  });
}
