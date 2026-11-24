import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/selectable_option_card.dart';
import '../auth/auth_repository.dart';
import '../diet_plan/diet_plan_repository.dart';
import '../home/dashboard_repository.dart';
import '../onboarding/onboarding_body_screen.dart';
import '../onboarding/onboarding_state.dart';

/// Hedef ve Bilgilerim: hedef, boy, kilo, hedef kilo, aktivite. Kaydedince kalori hedefi yeniden hesaplanır.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  Goal? _goal;
  int? _height;
  double? _weight;
  double? _target;
  ActivityLevel? _activity;
  bool _saving = false;

  static const _goalIcons = {
    Goal.lose: Icons.local_fire_department_outlined,
    Goal.gain: Icons.arrow_upward_rounded,
    Goal.maintain: Icons.monitor_weight_outlined,
    Goal.healthy: Icons.favorite_border_rounded,
  };

  void _initFrom(Map<String, dynamic> p) {
    _goal ??= Goal.values.firstWhere(
      (g) => g.apiValue == p['goal'],
      orElse: () => Goal.lose,
    );
    _height ??= p['height_cm'] as int? ?? 170;
    _weight ??= (p['weight_kg'] as num?)?.toDouble() ?? 70;
    _target ??= (p['target_weight_kg'] as num?)?.toDouble() ?? _weight;
    _activity ??= ActivityLevel.values.firstWhere(
      (a) => a.apiValue == p['activity_level'],
      orElse: () => ActivityLevel.light,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(meProvider.notifier).save({
        'goal': _goal!.apiValue,
        'height_cm': _height,
        'weight_kg': _weight,
        'target_weight_kg': (_goal == Goal.lose || _goal == Goal.gain)
            ? _target
            : null,
        'activity_level': _activity!.apiValue,
      });
      ref
        ..invalidate(dashboardProvider)
        ..invalidate(dietPlansProvider);
      if (!mounted) return;
      final kcal =
          ref.read(meProvider).value?.profile?['daily_kcal_target'] as int?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kcal == null
                ? 'Kaydedildi'
                : 'Kaydedildi. Yeni günlük hedefin ${formatNumber(kcal)} kcal.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hedef ve Bilgilerim',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: me.when(
        data: (user) {
          _initFrom(user.profile ?? const {});
          final kcal = user.profile?['daily_kcal_target'] as int?;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      if (kcal != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Şu anki günlük hedefin: ${formatNumber(kcal)} kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const _Section('Hedefin'),
                      for (final g in Goal.values) ...[
                        SelectableOptionCard(
                          icon: _goalIcons[g]!,
                          label: goalLabels[g.apiValue]!,
                          selected: _goal == g,
                          onTap: () => setState(() => _goal = g),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 8),
                      const _Section('Vücut Ölçülerin'),
                      MeasureCard(
                        label: 'Boy',
                        unit: 'cm',
                        value: _height!.toDouble(),
                        min: 120,
                        max: 230,
                        step: 1,
                        decimals: 0,
                        onChanged: (v) => setState(() => _height = v.round()),
                      ),
                      const SizedBox(height: 10),
                      MeasureCard(
                        label: 'Kilo',
                        unit: 'kg',
                        value: _weight!,
                        min: 35,
                        max: 250,
                        step: 0.5,
                        decimals: 1,
                        onChanged: (v) => setState(() => _weight = v),
                      ),
                      if (_goal == Goal.lose || _goal == Goal.gain) ...[
                        const SizedBox(height: 10),
                        MeasureCard(
                          label: 'Hedef Kilo',
                          unit: 'kg',
                          value: _target!,
                          min: 35,
                          max: 250,
                          step: 0.5,
                          decimals: 1,
                          onChanged: (v) => setState(() => _target = v),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const _Section('Aktivite Seviyen'),
                      DropdownButtonFormField<ActivityLevel>(
                        initialValue: _activity,
                        isExpanded: true,
                        items: [
                          for (final a in ActivityLevel.values)
                            DropdownMenuItem(
                              value: a,
                              child: Text('${a.label} – ${a.description}'),
                            ),
                        ],
                        onChanged: (a) => setState(() => _activity = a),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: PrimaryButton(
                    label: 'Kaydet',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}
