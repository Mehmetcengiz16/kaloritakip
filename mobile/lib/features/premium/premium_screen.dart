import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_links.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_buttons.dart';
import 'premium_repository.dart';

/// Premium (paywall). [reason]: 'quota' | 'plan' | null — üstteki bağlam mesajını belirler.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key, this.reason});

  final String? reason;

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  late final Future<List<PlanOption>> _plans = ref
      .read(purchaseServiceProvider)
      .plans();
  String _selected = 'annual';
  bool _busy = false;

  Future<void> _buy(PlanOption plan) async {
    setState(() => _busy = true);
    try {
      final status = await ref.read(purchaseServiceProvider).buy(plan);
      if (!mounted) return;
      if (status.isPremium) {
        _toast(
          'Premium aktif! Günde ${status.premiumDaily} AI analiz hakkın var.',
          AppColors.success,
        );
        context.pop(true);
      } else {
        _toast(
          'Satın alma alındı, onay bekleniyor. Birkaç dakika içinde aktif olur.',
          AppColors.carb,
        );
      }
    } on PurchaseCancelled {
      // kullanıcı vazgeçti
    } catch (e) {
      _toast(
        e is StateError ? e.message : apiErrorMessage(e),
        AppColors.danger,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final status = await ref.read(purchaseServiceProvider).restore();
      if (!mounted) return;
      _toast(
        status.isPremium
            ? 'Premium üyeliğin geri yüklendi.'
            : 'Bu hesapta aktif bir abonelik bulunamadı.',
        status.isPremium ? AppColors.success : AppColors.textSecondary,
      );
      if (status.isPremium) context.pop(true);
    } catch (e) {
      _toast(apiErrorMessage(e), AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(subscriptionProvider).value;
    final service = ref.watch(purchaseServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<PlanOption>>(
          future: _plans,
          builder: (context, snap) {
            final plans = snap.data ?? const <PlanOption>[];
            final plan =
                plans.where((p) => p.id == _selected).firstOrNull ??
                plans.firstOrNull;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/home'),
                        ),
                      ),
                      const _Hero(),
                      const SizedBox(height: 16),
                      if (status != null && !status.isPremium)
                        _ContextBanner(reason: widget.reason, status: status),
                      if (status?.isPremium == true)
                        _AlreadyPremium(until: status!.premiumUntil)
                      else ...[
                        _Benefits(
                          free: status?.freeDaily ?? 2,
                          premium: status?.premiumDaily ?? 30,
                        ),
                        const SizedBox(height: 20),
                        if (!service.isAvailable) const _PreviewNotice(),
                        if (snap.connectionState != ConnectionState.done)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (snap.hasError)
                          Text(
                            'Paketler yüklenemedi: ${apiErrorMessage(snap.error!)}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                            ),
                          )
                        else ...[
                          for (final p in plans) ...[
                            PlanCard(
                              plan: p,
                              selected: p.id == plan?.id,
                              onTap: () => setState(() => _selected = p.id),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (plan != null) ...[
                            const SizedBox(height: 6),
                            SubscriptionDisclosure(plan: plan),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
                if (status?.isPremium != true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: plan?.trialDays != null
                              ? '${plan!.trialDays} Gün Ücretsiz Dene'
                              : "Premium'a Geç",
                          icon: Icons.workspace_premium_rounded,
                          loading: _busy,
                          onPressed: plan?.package == null
                              ? null
                              : () => _buy(plan!),
                        ),
                        const SizedBox(height: 6),
                        if (plan != null)
                          Text(
                            plan.trialDays != null
                                ? '${plan.trialDays} gün ücretsiz, ardından ${plan.price}${plan.period}. Otomatik yenilenir, istediğin zaman iptal edebilirsin.'
                                : '${plan.price}${plan.period}. Otomatik yenilenir, istediğin zaman iptal edebilirsin.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 2),
                        LegalLinksRow(onRestore: _busy ? null : _restore),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'KaloriTakip Premium',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Yapay zekâyla sınırsıza yakın analiz,\nkişisel öneriler ve tüm diyet planları.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ContextBanner extends StatelessWidget {
  const _ContextBanner({required this.reason, required this.status});

  final String? reason;
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final q = status.quota;
    final text = switch (reason) {
      'quota' =>
        'Bugünkü ${q.limit} ücretsiz AI analiz hakkını kullandın. Hakların yarın yenilenir.',
      'plan' => 'Bu diyet planı Premium üyelere özel.',
      _ =>
        q.remaining > 0
            ? 'Bugün ${q.remaining}/${q.limit} ücretsiz AI analiz hakkın kaldı.'
            : 'Bugünkü ücretsiz AI analiz hakların bitti.',
    };
    final exhausted = reason == 'quota' || q.remaining == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: exhausted ? const Color(0xFFFFF4E5) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            exhausted ? Icons.lock_clock_outlined : Icons.auto_awesome_rounded,
            color: exhausted ? AppColors.carb : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.free, required this.premium});

  final int free;
  final int premium;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.photo_camera_rounded,
        'Günde $premium AI fotoğraf analizi',
        'Ücretsiz planda günde $free',
      ),
      (
        Icons.lightbulb_outline_rounded,
        'Kişisel AI beslenme önerileri',
        'Her gün öğünlerine göre',
      ),
      (
        Icons.menu_book_rounded,
        'Tüm diyet planları',
        'Kilo verme, alma ve koruma',
      ),
      (
        Icons.insights_rounded,
        'Yıllık ilerleme grafikleri',
        'Uzun vadeli değişimini gör',
      ),
      (Icons.block_rounded, 'Reklamsız deneyim', ''),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (icon, title, sub) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Seçilebilir paket kartı (onboarding kartlarıyla aynı stil).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySoft.withValues(alpha: 0.5)
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (plan.trialDays != null ||
                              plan.monthlyEquivalent != null)
                            Text(
                              [
                                if (plan.trialDays != null)
                                  '${plan.trialDays} gün ücretsiz',
                                if (plan.monthlyEquivalent != null)
                                  plan.monthlyEquivalent!,
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: plan.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: plan.period,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (plan.badge != null)
          Positioned(
            top: -10,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'Önizleme: mağaza bağlantısı henüz yapılandırılmadı. Fiyatlar örnektir, satın alma yapılamaz.',
      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
    ),
  );
}

class _AlreadyPremium extends StatelessWidget {
  const _AlreadyPremium({required this.until});

  final DateTime? until;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Column(
      children: [
        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 36),
        const SizedBox(height: 8),
        const Text(
          'Premium üyesin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (until != null)
          Text(
            '${DateFormat('d MMMM y', 'tr_TR').format(until!)} tarihine kadar',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              openLink(AppLinks.manageSubscription, external: true),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Aboneliği Yönet'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'İptal, plan değişikliği ve fatura bilgileri ${AppLinks.storeName} hesabından yönetilir.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// App Store (Guideline 3.1.2) ve Google Play abonelik politikası için zorunlu açıklama:
/// abonelik adı, süresi, fiyatı, deneme, ödemenin alındığı hesap, otomatik yenileme ve iptal.
class SubscriptionDisclosure extends StatelessWidget {
  const SubscriptionDisclosure({super.key, required this.plan});

  final PlanOption plan;

  @override
  Widget build(BuildContext context) {
    final period = plan.period == '/yıl' ? '1 yıl' : '1 ay';
    final trial = plan.trialDays != null
        ? 'İlk ${plan.trialDays} gün ücretsizdir; deneme bitmeden en az 24 saat önce iptal etmezsen '
              'deneme sonunda ${plan.price} tahsil edilir. Denemenin kullanılmayan kısmı, abonelik satın alındığında geçersiz olur. '
        : '';
    return Text(
      '${plan.title} Premium: $period süreli, ${plan.price}${plan.period}. $trial'
      'Ödeme, satın almayı onayladığında ${AppLinks.accountName} hesabından alınır. '
      'Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmezse aynı fiyat ve süreyle otomatik yenilenir; '
      'yenileme ücreti dönem bitimine 24 saat kala tahsil edilir. '
      'Aboneliğini ${AppLinks.storeName} hesap ayarlarından yönetebilir ve otomatik yenilemeyi kapatabilirsin.',
      style: const TextStyle(
        fontSize: 10.5,
        height: 1.45,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// Satın alma ekranının altındaki zorunlu linkler: geri yükle · Kullanım Koşulları (EULA) · Gizlilik.
class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({super.key, required this.onRestore});

  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600);
    Widget link(String label, VoidCallback? onTap) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.textSecondary,
      ),
      child: Text(label, style: style),
    );
    const dot = Text('·', style: TextStyle(color: AppColors.textMuted));

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link('Geri yükle', onRestore),
        dot,
        link('Kullanım Koşulları', () => openLink(AppLinks.terms)),
        dot,
        link('Gizlilik', () => openLink(AppLinks.privacy)),
      ],
    );
  }
}
