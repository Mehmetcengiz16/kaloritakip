import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/onboarding/onboarding_body_screen.dart';
import 'package:kaloritakip/features/onboarding/onboarding_details_screen.dart';
import 'package:kaloritakip/features/onboarding/onboarding_goal_screen.dart';
import 'package:kaloritakip/features/onboarding/onboarding_state.dart';
import 'package:kaloritakip/features/welcome/welcome_screen.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );

  testWidgets('Karşılama ekranı metinleri ve butonları gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('KaloriTakip'), findsOneWidget);
    expect(find.text('Hemen Başla'), findsOneWidget);
    expect(find.text('Hesabın Var mı? Giriş Yap'), findsOneWidget);
  });

  testWidgets('Hedef ekranında seçim değişir', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingGoalScreen()));
    expect(find.text('Hedefin Nedir?'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget); // varsayılan: Kilo Vermek
    await tester.tap(find.text('Kilo Almak'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('Kişisel bilgiler seçilmeden Devam Et pasif', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingDetailsScreen(),
        ),
      ),
    );
    expect(container.read(onboardingProvider).detailsValid, isFalse);
    await tester.tap(find.text('Kadın'));
    container
        .read(onboardingProvider.notifier)
        .setBirthDate(DateTime(1995, 5, 10));
    await tester.pump();
    expect(container.read(onboardingProvider).detailsValid, isTrue);
  });

  test('Onboarding verisi API formatına çevrilir', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(onboardingProvider.notifier)
      ..setGoal(Goal.maintain)
      ..setGender(Gender.male)
      ..setBirthDate(DateTime(1990, 1, 2))
      ..setWeight(80)
      ..setActivity(ActivityLevel.veryActive);
    expect(n, isNotNull);
    final json = c.read(onboardingProvider).toJson();
    expect(json['goal'], 'maintain');
    expect(json['birth_date'], '1990-01-02');
    expect(json['activity_level'], 'very_active');
    expect(
      json.containsKey('target_weight_kg'),
      isFalse,
    ); // korumada hedef kilo yok
  });

  testWidgets('Vücut ölçüleri ekranında + butonu kiloyu artırır', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OnboardingBodyScreen(),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add_rounded).at(1)); // Kilo kartı
    await tester.pump();
    expect(container.read(onboardingProvider).weightKg, 70.5);
  });
}
