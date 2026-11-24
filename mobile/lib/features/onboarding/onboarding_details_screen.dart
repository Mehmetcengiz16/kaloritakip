import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/selectable_option_card.dart';
import 'onboarding_state.dart';
import 'widgets/onboarding_scaffold.dart';

/// 2/4 – Cinsiyet ve doğum tarihi.
class OnboardingDetailsScreen extends ConsumerWidget {
  const OnboardingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return OnboardingScaffold(
      step: 2,
      title: 'Seni Tanıyalım',
      subtitle:
          'Günlük kalori ihtiyacını doğru\nhesaplayabilmemiz için gerekli.',
      onNext: state.detailsValid
          ? () => context.push('/onboarding/body')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Cinsiyet'),
          SelectableOptionCard(
            icon: Icons.female_rounded,
            label: Gender.female.label,
            selected: state.gender == Gender.female,
            onTap: () => notifier.setGender(Gender.female),
          ),
          const SizedBox(height: 12),
          SelectableOptionCard(
            icon: Icons.male_rounded,
            label: Gender.male.label,
            selected: state.gender == Gender.male,
            onTap: () => notifier.setGender(Gender.male),
          ),
          const SizedBox(height: 24),
          const _Label('Doğum Tarihi'),
          _DateField(
            value: state.birthDate,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.birthDate ?? DateTime(now.year - 25, 1, 1),
                firstDate: DateTime(now.year - 100),
                lastDate: DateTime(now.year - 13, now.month, now.day),
                helpText: 'Doğum tarihini seç',
                initialEntryMode: DatePickerEntryMode.calendarOnly,
              );
              if (picked != null) notifier.setBirthDate(picked);
            },
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null
                    ? 'Tarih seç'
                    : DateFormat('d MMMM y', 'tr_TR').format(value!),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: value == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
