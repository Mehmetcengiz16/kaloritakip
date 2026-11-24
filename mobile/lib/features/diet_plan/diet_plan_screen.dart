import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import 'diet_plan_repository.dart';

class DietPlanScreen extends ConsumerStatefulWidget {
  const DietPlanScreen({super.key});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  /// null: ilk açılışta kullanıcının kendi hedefi gösterilir.
  PlanGoal? _goal;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dietPlansProvider(_goal));
    final selected = _goal ?? async.value?.goal;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(dietPlansProvider(_goal).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Diyet Planım',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              GoalSegments(
                value: selected,
                onChanged: (g) => setState(() => _goal = g),
              ),
              const SizedBox(height: 14),
              async.when(
                data: (d) => DietPlanContent(data: d),
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(dietPlansProvider(_goal)),
                      child: Text(
                        '${apiErrorMessage(e)}\nTekrar dene',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kilo Verme · Kilo Alma · Koruma
class GoalSegments extends StatelessWidget {
  const GoalSegments({super.key, required this.value, required this.onChanged});

  final PlanGoal? value;
  final ValueChanged<PlanGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final g in PlanGoal.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: g == value
                        ? AppColors.background
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.button - 4),
                    border: Border.all(
                      color: g == value
                          ? AppColors.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    g.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: g == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: g == value
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DietPlanContent extends StatelessWidget {
  const DietPlanContent({super.key, required this.data});

  final DietPlans data;

  @override
  Widget build(BuildContext context) {
    final first = data.plans.isEmpty ? null : data.plans.first;
    final kcal = data.isOwnGoal ? data.userTargetKcal : (first?.dailyKcal ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TargetCard(
          label: data.isOwnGoal ? 'Günlük Hedefin' : 'Plan Kalorisi',
          kcal: kcal,
        ),
        const SizedBox(height: 22),
        if (data.plans.isEmpty)
          const Text(
            'Bu hedef için henüz bir plan yok.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          for (final plan in data.plans) ...[
            Text(
              data.plans.length > 1 ? plan.title : 'Örnek Günlük Plan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (plan.locked)
              _LockedPlan(onTap: () => context.push('/premium?reason=plan'))
            else
              for (final m in plan.meals) ...[
                _PlanMealTile(meal: m),
                const SizedBox(height: 8),
              ],
            if (data.isOwnGoal &&
                !plan.locked &&
                (plan.dailyKcal - data.userTargetKcal).abs() > 150)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  'Bu örnek plan ${formatNumber(plan.dailyKcal)} kcal. Porsiyonları hedefine göre ayarlayabilirsin.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// "Günlük Hedefin 2.200 kcal" kartı; sağda yemek görseli.
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.label, required this.kcal});

  final String label;
  final int kcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          const Icon(
            Icons.track_changes_rounded,
            color: AppColors.primary,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatNumber(kcal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' kcal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tasarımdaki somon & avokado görseli gelene kadar: assets/images/plan_food.png
          SizedBox(
            width: 110,
            child: Image.asset(
              'assets/images/plan_food.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Text('🥑🍣', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMealTile extends StatelessWidget {
  const _PlanMealTile({required this.meal});

  final PlanMeal meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Text(
              mealEmojis[meal.mealType] ?? '🍽️',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meal.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meal.description!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatNumber(meal.kcal)} kcal',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LockedPlan extends StatelessWidget {
  const _LockedPlan({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu plan Premium üyelere özel. Açmak için dokun.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
