import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_buttons.dart';

/// Tüm onboarding adımlarının ortak iskeleti: geri oku, "n/4", ilerleme çubuğu,
/// başlık, açıklama, içerik ve altta "Devam Et" butonu.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Devam Et',
    this.loading = false,
    this.total = 4,
    this.scrollable = false,
  });

  final int step;
  final int total;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool loading;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 36),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        child,
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _StepHeader(step: step, total: total),
              Expanded(
                child: scrollable ? SingleChildScrollView(child: body) : body,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: nextLabel,
                onPressed: onNext,
                loading: loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/welcome'),
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            const Spacer(),
            Text(
              '$step/$total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: step / total),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.track,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
