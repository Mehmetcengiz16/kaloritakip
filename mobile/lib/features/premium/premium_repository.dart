import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/network/api_client.dart';
import '../add_food/add_food_repository.dart';
import '../auth/auth_repository.dart';
import '../home/dashboard_repository.dart';

/// RevenueCat public SDK anahtarları derlemede verilir:
/// --dart-define=RC_ANDROID_KEY=goog_xxx --dart-define=RC_IOS_KEY=appl_xxx
const _rcAndroidKey = String.fromEnvironment('RC_ANDROID_KEY');
const _rcIosKey = String.fromEnvironment('RC_IOS_KEY');

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPremium,
    this.premiumUntil,
    required this.quota,
    required this.freeDaily,
    required this.premiumDaily,
  });

  final bool isPremium;
  final DateTime? premiumUntil;
  final AiQuota quota;
  final int freeDaily;
  final int premiumDaily;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> j) =>
      SubscriptionStatus(
        isPremium: j['is_premium'] as bool,
        premiumUntil: j['premium_until'] == null
            ? null
            : DateTime.parse(j['premium_until'] as String).toLocal(),
        quota: AiQuota.fromJson(j['quota'] as Map<String, dynamic>),
        freeDaily: (j['limits'] as Map)['free_daily'] as int,
        premiumDaily: (j['limits'] as Map)['premium_daily'] as int,
      );
}

/// Paywall'da gösterilecek paket (mağazadan gelen fiyatla).
class PlanOption {
  const PlanOption({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.monthlyEquivalent,
    this.badge,
    this.trialDays,
    this.package,
  });

  final String id;
  final String title;
  final String price;
  final String period;
  final String? monthlyEquivalent;
  final String? badge;
  final int? trialDays;

  /// null: mağaza bağlantısı yok (yalnızca önizleme).
  final Package? package;
}

class PurchaseCancelled implements Exception {}

/// RevenueCat ile satın alma. Anahtar verilmemişse [isAvailable] false olur ve paywall önizleme modunda çalışır.
class PurchaseService {
  PurchaseService(this._ref);

  final Ref _ref;
  String? _configuredFor;

  static String get _apiKey =>
      kIsWeb ? '' : (Platform.isIOS ? _rcIosKey : _rcAndroidKey);

  bool get isAvailable => _apiKey.isNotEmpty;

  /// Kullanıcıyı RevenueCat'te bizim id'mizle tanıtır (webhook'lar bu id ile gelir).
  Future<void> ensureReady() async {
    if (!isAvailable) return;
    final user = await _ref.read(authRepositoryProvider).me();
    final id = user.id.toString();
    if (_configuredFor == id) return;
    if (await Purchases.isConfigured) {
      await Purchases.logIn(id);
    } else {
      await Purchases.configure(
        PurchasesConfiguration(_apiKey)..appUserID = id,
      );
    }
    _configuredFor = id;
  }

  Future<List<PlanOption>> plans() async {
    if (!isAvailable) return previewPlans;
    await ensureReady();
    final offering = (await Purchases.getOfferings()).current;
    if (offering == null) return previewPlans;

    final monthly = offering.monthly;
    final annual = offering.annual;
    return [
      if (annual != null)
        PlanOption(
          id: 'annual',
          title: 'Yıllık',
          price: annual.storeProduct.priceString,
          period: '/yıl',
          monthlyEquivalent: _perMonth(annual.storeProduct),
          badge: _savingBadge(annual.storeProduct, monthly?.storeProduct),
          trialDays: _trialDays(annual.storeProduct),
          package: annual,
        ),
      if (monthly != null)
        PlanOption(
          id: 'monthly',
          title: 'Aylık',
          price: monthly.storeProduct.priceString,
          period: '/ay',
          trialDays: _trialDays(monthly.storeProduct),
          package: monthly,
        ),
    ];
  }

  /// Satın alır; sonra backend'den doğrulatıp güncel durumu döndürür.
  Future<SubscriptionStatus> buy(PlanOption plan) async {
    if (plan.package == null)
      throw StateError('Mağaza bağlantısı yapılandırılmadı.');
    await ensureReady();
    try {
      await Purchases.purchase(PurchaseParams.package(plan.package!));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw PurchaseCancelled();
      }
      rethrow;
    }
    return _ref.read(subscriptionProvider.notifier).sync();
  }

  Future<SubscriptionStatus> restore() async {
    if (isAvailable) {
      await ensureReady();
      await Purchases.restorePurchases();
    }
    return _ref.read(subscriptionProvider.notifier).sync();
  }

  static String? _perMonth(StoreProduct p) {
    final perMonth = p.price / 12;
    final symbol = p.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '${perMonth.toStringAsFixed(2).replaceAll('.', ',')} $symbol/ay';
  }

  static String? _savingBadge(StoreProduct annual, StoreProduct? monthly) {
    if (monthly == null || monthly.price <= 0) return null;
    final saving = (1 - annual.price / (monthly.price * 12)) * 100;
    return saving >= 5 ? '%${saving.round()} tasarruf' : null;
  }

  static int? _trialDays(StoreProduct p) {
    final intro = p.introductoryPrice;
    if (intro == null || intro.price > 0) return null;
    return switch (intro.periodUnit) {
      PeriodUnit.day => intro.periodNumberOfUnits,
      PeriodUnit.week => intro.periodNumberOfUnits * 7,
      PeriodUnit.month => intro.periodNumberOfUnits * 30,
      _ => null,
    };
  }

  /// Mağaza bağlantısı olmadan ekranın nasıl görüneceğini göstermek için (satın alınamaz).
  static const previewPlans = [
    PlanOption(
      id: 'annual',
      title: 'Yıllık',
      price: '949,99 ₺',
      period: '/yıl',
      monthlyEquivalent: '79,17 ₺/ay',
      badge: '%43 tasarruf',
      trialDays: 7,
    ),
    PlanOption(id: 'monthly', title: 'Aylık', price: '139,99 ₺', period: '/ay'),
  ];
}

final purchaseServiceProvider = Provider((ref) => PurchaseService(ref));

class SubscriptionNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    final res = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>('/subscription');
    return SubscriptionStatus.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    );
  }

  /// Satın alma/geri yükleme sonrası backend'in RevenueCat'ten doğrulamasını ister.
  Future<SubscriptionStatus> sync() async {
    final res = await ref
        .read(dioProvider)
        .post<Map<String, dynamic>>('/subscription/sync');
    final status = SubscriptionStatus.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    );
    state = AsyncData(status);
    // Premium değişince kota, planlar ve profil de değişir.
    ref
      ..invalidate(dashboardProvider)
      ..invalidate(meProvider);
    return status;
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
      SubscriptionNotifier.new,
    );
