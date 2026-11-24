import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/calorie_ring.dart';
import '../../shared/widgets/food_thumb.dart';
import 'dashboard_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: async.when(
          data: (d) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(dashboardProvider.future),
            child: HomeContent(data: d),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorView(
            message: apiErrorMessage(e),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
        ),
      ),
    );
  }
}

/// Veriden bağımsız olarak test edilebilmesi için ayrı tutulan içerik.
class HomeContent extends StatelessWidget {
  const HomeContent({super.key, required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final eaten = data.meals.where((m) => m.itemCount > 0).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(firstName: data.firstName, goal: data.goal),
        const SizedBox(height: 20),
        Center(
          child: CalorieRing(
            progress: data.ringProgress,
            remaining: data.remainingKcal,
            target: data.targetKcal,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MacroCard(
                label: 'Protein',
                icon: Icons.egg_alt_outlined,
                color: AppColors.protein,
                progress: data.protein,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Karbonhidrat',
                icon: Icons.bakery_dining_outlined,
                color: AppColors.carb,
                progress: data.carb,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroCard(
                label: 'Yağ',
                icon: Icons.water_drop_outlined,
                color: AppColors.fat,
                progress: data.fat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShortcutCard(
                icon: Icons.restaurant_menu_rounded,
                label: 'Yemek Ekle',
                onTap: () => context.push('/add-food?tab=search'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.photo_camera_outlined,
                label: 'AI ile Analiz',
                badge: data.aiQuota == null
                    ? null
                    : '${data.aiQuota!.remaining}/${data.aiQuota!.limit}',
                badgeEmpty: data.aiQuota?.remaining == 0,
                onTap: () => context.push('/add-food?tab=photo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ShortcutCard(
                icon: Icons.event_note_outlined,
                label: 'Planım',
                onTap: () => context.go('/plan'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bugün Tükettiklerim',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${formatNumber(data.consumedKcal)} kcal',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.aiQuota != null &&
            !data.aiQuota!.isPremium &&
            data.aiQuota!.remaining == 0) ...[
          const SizedBox(height: 0),
          _PremiumStrip(onTap: () => context.push('/premium?reason=quota')),
          const SizedBox(height: 12),
        ],
        if (eaten.isEmpty)
          const _EmptyMeals()
        else
          for (final m in eaten) ...[
            _MealTile(meal: m),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.goal});

  final String firstName;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Merhaba $firstName 👋',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hedef: ${goalLabels[goal] ?? goal}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/water-activity'),
          icon: const Icon(
            Icons.water_drop_outlined,
            size: 24,
            color: AppColors.water,
          ),
          tooltip: 'Su ve Aktivite',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, size: 26),
          tooltip: 'Bildirimler',
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String label;
  final IconData icon;
  final Color color;
  final MacroProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 5,
              backgroundColor: AppColors.track,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${progress.consumed}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' / ${progress.target} g',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeEmpty = false,
  });

  final String? badge;
  final bool badgeEmpty;

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  if (badge != null)
                    Positioned(
                      right: -26,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeEmpty
                              ? AppColors.carb
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final MealSummary meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          FoodThumb(
            name:
                (meal.items.where((i) => i.imageUrl != null).firstOrNull ??
                        meal.items.firstOrNull)
                    ?.name ??
                '',
            imageUrl: meal.items
                .where((i) => i.imageUrl != null)
                .firstOrNull
                ?.imageUrl,
            size: 44,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealLabels[meal.type] ?? meal.type,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (meal.itemNames.isNotEmpty)
                  Text(
                    meal.itemNames.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${formatNumber(meal.kcal)} kcal',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
      ),
      child: const Column(
        children: [
          Text('🍽️', style: TextStyle(fontSize: 28)),
          SizedBox(height: 8),
          Text(
            'Bugün henüz bir şey eklemedin.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Yemek Ekle veya AI ile Analiz ile başla.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}

/// Ücretsiz AI hakkı bitince Ana Sayfa'da çıkan ince premium şeridi.
class _PremiumStrip extends StatelessWidget {
  const _PremiumStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.card - 4),
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.card - 4),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card - 4),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Bugünkü ücretsiz AI hakların bitti. Premium ile günde daha fazla analiz yap.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
