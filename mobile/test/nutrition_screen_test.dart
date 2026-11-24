import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/home/dashboard_repository.dart';
import 'package:kaloritakip/features/nutrition/nutrition_screen.dart';

Dashboard _data() => Dashboard.fromJson({
  'user': {'first_name': 'Mehmet', 'goal': 'lose'},
  'calories': {'target': 2200, 'consumed': 700, 'burned': 0, 'remaining': 1500},
  'macros': {
    for (final m in ['protein', 'carb', 'fat'])
      m: {'consumed': 0, 'target': 100},
  },
  'meals': [
    {
      'type': 'breakfast',
      'kcal': 520,
      'item_count': 1,
      'items': [
        {'id': 11, 'name': 'Yulaf', 'grams': 80, 'kcal': 520},
      ],
    },
    {
      'type': 'snack1',
      'kcal': 180,
      'item_count': 1,
      'items': [
        {'id': 12, 'name': 'Elma', 'grams': 180, 'kcal': 180},
      ],
    },
    for (final t in ['lunch', 'snack2', 'dinner'])
      {'type': t, 'kcal': 0, 'item_count': 0, 'items': []},
  ],
});

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  testWidgets('Öğün listesi açılır, silme ve ekleme çağrılır', (tester) async {
    final expanded = <String>{};
    MealEntry? deleted;
    String? addedTo;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MealList(
              data: _data(),
              expanded: expanded,
              onToggle: (t) => setState(
                () =>
                    expanded.contains(t) ? expanded.remove(t) : expanded.add(t),
              ),
              onAdd: (t) => addedTo = t,
              onDelete: (e) => deleted = e,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Kahvaltı'), findsOneWidget);
    expect(find.text('Ara Öğün'), findsNWidgets(2));
    expect(find.text('Akşam Yemeği'), findsOneWidget);
    expect(find.text('520 kcal'), findsOneWidget);
    expect(find.text('700 / 2.200 kcal'), findsOneWidget);
    expect(find.text('Yulaf'), findsNothing);

    await tester.tap(find.text('Kahvaltı'));
    await tester.pumpAndSettle();
    expect(find.text('Yulaf'), findsOneWidget);

    await tester.tap(find.byTooltip('Sil'));
    expect(deleted?.id, 11);

    await tester.tap(find.text('Kahvaltı ekle'));
    expect(addedTo, 'breakfast');
  });

  testWidgets('Tarih çubuğu bugünü gösterir ve ileri gün kapalıdır', (
    tester,
  ) async {
    final today = dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DateBar(
            date: today,
            isToday: true,
            onTap: () {},
            onPrev: () {},
            onNext: null,
          ),
        ),
      ),
    );
    expect(find.textContaining('Bugün, '), findsOneWidget);
  });
}
