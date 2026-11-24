import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_state.dart';
import 'widgets/onboarding_scaffold.dart';

/// 3/4 – Boy, kilo ve hedef kilo.
class OnboardingBodyScreen extends ConsumerWidget {
  const OnboardingBodyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(onboardingProvider);
    final n = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      step: 3,
      title: 'Vücut Ölçülerin',
      subtitle: 'Boyunu ve kilonu gir, hedefini\nbirlikte belirleyelim.',
      scrollable: true,
      onNext: () => context.push('/onboarding/activity'),
      child: Column(
        children: [
          MeasureCard(
            label: 'Boy',
            unit: 'cm',
            value: s.heightCm.toDouble(),
            min: 120,
            max: 230,
            step: 1,
            decimals: 0,
            onChanged: (v) => n.setHeight(v.round()),
          ),
          const SizedBox(height: 12),
          MeasureCard(
            label: 'Kilo',
            unit: 'kg',
            value: s.weightKg,
            min: 35,
            max: 250,
            step: 0.5,
            decimals: 1,
            onChanged: n.setWeight,
          ),
          if (s.needsTargetWeight) ...[
            const SizedBox(height: 12),
            MeasureCard(
              label: 'Hedef Kilo',
              unit: 'kg',
              value: s.targetWeightKg,
              min: 35,
              max: 250,
              step: 0.5,
              decimals: 1,
              onChanged: n.setTargetWeight,
              footer: _TargetHint(
                current: s.weightKg,
                target: s.targetWeightKg,
                goal: s.goal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiket, büyük değer, -/+ butonları ve kaydırıcıdan oluşan ölçü kartı.
class MeasureCard extends StatelessWidget {
  const MeasureCard({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.decimals,
    required this.onChanged,
    this.footer,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final double step;
  final int decimals;
  final ValueChanged<double> onChanged;
  final Widget? footer;

  void _emit(double v) {
    final snapped = (v / step).round() * step;
    onChanged(snapped.clamp(min, max).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final text = value.toStringAsFixed(decimals).replaceAll('.', ',');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onTap: () => _emit(value - step),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: text,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onTap: () => _emit(value + step),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.track,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: _emit,
            ),
          ),
          if (footer != null)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: footer),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _TargetHint extends StatelessWidget {
  const _TargetHint({
    required this.current,
    required this.target,
    required this.goal,
  });

  final double current;
  final double target;
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final diff = target - current;
    final wrongDirection =
        (goal == Goal.lose && diff >= 0) || (goal == Goal.gain && diff <= 0);
    final text = wrongDirection
        ? (goal == Goal.lose
              ? 'Kilo vermek için hedef kilon mevcut kilondan düşük olmalı.'
              : 'Kilo almak için hedef kilon mevcut kilondan yüksek olmalı.')
        : '${diff.abs().toStringAsFixed(1).replaceAll('.', ',')} kg ${diff < 0 ? 'vermeyi' : 'almayı'} hedefliyorsun.';

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: wrongDirection ? AppColors.danger : AppColors.success,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
