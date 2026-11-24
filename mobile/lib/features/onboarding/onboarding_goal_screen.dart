import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/selectable_option_card.dart';
import 'onboarding_state.dart';
import 'widgets/onboarding_scaffold.dart';

/// 1/4 – Hedefin Nedir?
class OnboardingGoalScreen extends ConsumerWidget {
  const OnboardingGoalScreen({super.key});

  static const _options = [
    (Goal.lose, Icons.local_fire_department_outlined, 'Kilo Vermek'),
    (Goal.gain, Icons.arrow_upward_rounded, 'Kilo Almak'),
    (Goal.maintain, Icons.monitor_weight_outlined, 'Kilo Korumak'),
    (Goal.healthy, Icons.favorite_border_rounded, 'Daha Sağlıklı Beslenmek'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return OnboardingScaffold(
      step: 1,
      title: 'Hedefin Nedir?',
      subtitle: 'Sana özel bir plan oluşturabilmemiz\niçin hedefini seç.',
      onNext: () => context.push('/onboarding/details'),
      child: Column(
        children: [
          for (final (goal, icon, label) in _options) ...[
            SelectableOptionCard(
              icon: icon,
              label: label,
              selected: state.goal == goal,
              onTap: () => ref.read(onboardingProvider.notifier).setGoal(goal),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
