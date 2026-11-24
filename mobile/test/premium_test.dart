import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/config/app_links.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/home/dashboard_repository.dart';
import 'package:kaloritakip/features/premium/premium_repository.dart';
import 'package:kaloritakip/features/premium/premium_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  test('Abonelik durumu API yanıtından okunur', () {
    final s = SubscriptionStatus.fromJson({
      'is_premium': false,
      'premium_until': null,
      'quota': {'used': 2, 'limit': 2, 'remaining': 0, 'is_premium': false},
      'limits': {'free_daily': 2, 'premium_daily': 30},
    });
    expect(s.quota.remaining, 0);
    expect(s.premiumDaily, 30);
  });

  test(
    'Ana Sayfa verisi AI hakkını içerir (eski yanıtlarda alan yoksa null)',
    () {
      Map<String, dynamic> json({Map<String, dynamic>? quota}) => {
        'user': {'first_name': 'A', 'goal': 'lose'},
        'calories': {
          'target': 2000,
          'consumed': 0,
          'burned': 0,
          'remaining': 2000,
        },
        'macros': {
          for (final m in ['protein', 'carb', 'fat'])
            m: {'consumed': 0, 'target': 1},
        },
        'meals': <dynamic>[],
        'ai_quota': ?quota,
      };
      expect(Dashboard.fromJson(json()).aiQuota, isNull);
      final d = Dashboard.fromJson(
        json(
          quota: {'used': 1, 'limit': 2, 'remaining': 1, 'is_premium': false},
        ),
      );
      expect(d.aiQuota!.remaining, 1);
    },
  );

  test(
    'Mağaza anahtarı yokken satın alma kapalı, önizleme paketleri hazır',
    () {
      expect(PurchaseService.previewPlans.map((p) => p.id), [
        'annual',
        'monthly',
      ]);
      expect(
        PurchaseService.previewPlans.every((p) => p.package == null),
        isTrue,
      );
    },
  );

  testWidgets('Paket kartı fiyat, deneme ve tasarruf rozetini gösterir', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: PlanCard(
              plan: PurchaseService.previewPlans.first,
              selected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Yıllık'), findsOneWidget);
    expect(find.text('%43 tasarruf'), findsOneWidget);
    expect(find.textContaining('7 gün ücretsiz'), findsOneWidget);
    expect(find.textContaining('949,99 ₺', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Yıllık'));
    expect(tapped, isTrue);
  });

  testWidgets('Abonelik açıklaması mağaza kurallarındaki bilgileri içerir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              SubscriptionDisclosure(plan: PurchaseService.previewPlans.first),
              LegalLinksRow(onRestore: () {}),
            ],
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text).first).data!;
    expect(text, contains('1 yıl süreli'));
    expect(text, contains('949,99 ₺/yıl'));
    expect(text, contains('İlk 7 gün ücretsiz'));
    expect(text, contains('en az 24 saat önce iptal edilmezse'));
    expect(text, contains('otomatik yenilenir'));
    expect(find.text('Geri yükle'), findsOneWidget);
    expect(find.text('Kullanım Koşulları'), findsOneWidget);
    expect(find.text('Gizlilik'), findsOneWidget);
  });

  test('Web linkleri API adresinden türetilir', () {
    expect(AppLinks.privacy, endsWith('/gizlilik'));
    expect(AppLinks.terms, isNot(contains('/api/')));
    expect(AppLinks.manageSubscription, contains('subscriptions'));
  });
}
