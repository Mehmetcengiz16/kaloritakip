import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_state.dart';
import 'widgets/onboarding_scaffold.dart';

/// 4/4 – Aktivite seviyesi. Sonrasında hesap oluşturma ekranına geçilir.
class OnboardingActivityScreen extends ConsumerWidget {
  const OnboardingActivityScreen({super.key});

  static const _icons = {
    ActivityLevel.sedentary: Icons.weekend_outlined,
    ActivityLevel.light: Icons.directions_walk_rounded,
    ActivityLevel.moderate: Icons.directions_run_rounded,
    ActivityLevel.active: Icons.fitness_center_rounded,
    ActivityLevel.veryActive: Icons.sports_gymnastics_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingProvider);
    final n = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      step: 4,
      title: 'Ne Kadar Hareketlisin?',
      subtitle: 'Günlük aktivite seviyeni seç.',
      scrollable: true,
      onNext: () => context.push('/register'),
      child: Column(
        children: [
          for (final level in ActivityLevel.values) ...[
            _ActivityCard(
              icon: _icons[level]!,
              level: level,
              selected: s.activityLevel == level,
              onTap: () => n.setActivity(level),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
