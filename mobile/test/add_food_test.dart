import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/add_food/add_food_repository.dart';
import 'package:kaloritakip/features/add_food/tabs/photo_ai_tab.dart';

const _tavuk = AnalyzedItem(
  name: 'Tavuk ızgara',
  grams: 100,
  kcal: 180,
  protein: 31,
  carb: 0,
  fat: 5,
  confidence: 0.9,
);
const _pilav = AnalyzedItem(
  name: 'Pirinç Pilavı',
  grams: 150,
  kcal: 260,
  protein: 4,
  carb: 45,
  fat: 6,
  confidence: 0.4,
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  test('Gramaj değişince besin değerleri orantılı ölçeklenir', () {
    final double = _pilav.withGrams(300);
    expect(double.kcal, 520);
    expect(double.carb, 90);
    expect(_tavuk.withGrams(50).protein, 15.5);
  });

  test('Saate göre varsayılan öğün', () {
    expect(defaultMealType(DateTime(2026, 1, 1, 8)), 'breakfast');
    expect(defaultMealType(DateTime(2026, 1, 1, 13)), 'lunch');
    expect(defaultMealType(DateTime(2026, 1, 1, 20)), 'dinner');
  });

  test('API yanıtı modele çevrilir', () {
    final r = AiAnalysisResult.fromJson({
      'id': 7,
      'is_food': true,
      'items': [
        {
          'name': 'Salata',
          'grams': 100,
          'kcal': 40,
          'protein': 1,
          'carb': 6,
          'fat': 2,
          'confidence': 0.5,
        },
      ],
      'quota': {'used': 1, 'limit': 2, 'remaining': 1, 'is_premium': false},
    });
    expect(r.items.single.name, 'Salata');
    expect(r.quota.remaining, 1);
  });

  testWidgets('AI sonuç kartı yemekleri ve düşük güven işaretini gösterir', (
    tester,
  ) async {
    int? removed;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AiResultCard(
            items: const [_tavuk, _pilav],
            onEdit: (_) {},
            onRemove: (i) => removed = i,
          ),
        ),
      ),
    );

    expect(find.text('Yapay Zeka Analizi'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('180 kcal • 100 g'), findsOneWidget);
    expect(find.text('260 kcal • 150 g'), findsOneWidget);
    expect(
      find.byIcon(Icons.help_outline_rounded),
      findsOneWidget,
    ); // sadece pilav (0.4)

    await tester.tap(find.byTooltip('Kaldır').first);
    expect(removed, 0);
  });
}
