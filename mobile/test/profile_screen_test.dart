import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kaloritakip/core/theme/app_theme.dart';
import 'package:kaloritakip/features/auth/auth_repository.dart';
import 'package:kaloritakip/features/profile/profile_screen.dart';

AppUser _user({bool premium = false, bool notifications = true}) =>
    AppUser.fromJson({
      'id': 1,
      'name': 'Mehmet Cengiz',
      'email': 'test@example.com',
      'is_premium': premium,
      'onboarding_completed': true,
      'profile': {'goal': 'lose', 'notifications_enabled': notifications},
    });

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('tr_TR');
  });

  testWidgets('Tasarımdaki profil kartı ve menü', (tester) async {
    bool? toggled;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProfileContent(
            user: _user(),
            onNotificationsChanged: (v) => toggled = v,
          ),
        ),
      ),
    );

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Mehmet Cengiz'), findsOneWidget);
    expect(find.text('Hedef: Kilo Vermek'), findsOneWidget);
    for (final label in [
      'Hedef ve Bilgilerim',
      'Bildirimler',
      'Verilerim',
      'Diyet Planım',
      'Uygulama Ayarları',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Premium'), findsNothing);

    await tester.tap(find.byType(Switch));
    expect(toggled, isFalse);
  });

  testWidgets('Premium rozeti', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProfileContent(
            user: _user(premium: true),
            onNotificationsChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Premium'), findsOneWidget);
  });
}
