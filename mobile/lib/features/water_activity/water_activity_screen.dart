import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_buttons.dart';
import 'water_activity_repository.dart';

class WaterActivityScreen extends ConsumerWidget {
  const WaterActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(waterActivityProvider);
    final notifier = ref.read(waterActivityProvider.notifier);

    Future<void> run(Future<void> Function() action, {String? success}) async {
      try {
        await action();
        if (success != null && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(success),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Geri al',
                  onPressed: () => run(notifier.undoWater),
                ),
              ),
            );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiErrorMessage(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }

    return Scaffold(
      appBar: context.canPop()
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: SafeArea(
        top: !context.canPop(),
        child: async.when(
          data: (d) => WaterActivityContent(
            data: d,
            onWater: (ml) =>
                run(() => notifier.addWater(ml), success: '+$ml ml su eklendi'),
            onAddActivity: () async {
              final result = await showModalBottomSheet<_NewActivity>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.background,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => _AddActivitySheet(catalog: d.catalog),
              );
              if (result == null) return;
              await run(
                () => result.type != null
                    ? notifier.addActivity(
                        activityId: result.type!.id,
                        minutes: result.minutes,
                      )
                    : notifier.addCustomActivity(
                        name: result.name!,
                        minutes: result.minutes,
                        kcal: result.kcal!,
                      ),
              );
            },
            onTapLog: (log) async {
              final delete = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(log.name),
                  content: Text(
                    '${log.minutes} dk • ${log.kcal} kcal\nBu aktiviteyi silmek istiyor musun?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sil',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (delete == true)
                await run(() => notifier.deleteActivity(log.id));
            },
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(waterActivityProvider),
              child: Text(
                '${apiErrorMessage(e)}\nTekrar dene',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaterActivityContent extends StatelessWidget {
  const WaterActivityContent({
    super.key,
    required this.data,
    required this.onWater,
    required this.onAddActivity,
    required this.onTapLog,
  });

  final WaterActivity data;
  final ValueChanged<int> onWater;
  final VoidCallback onAddActivity;
  final ValueChanged<ActivityLogEntry> onTapLog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const Text(
          'Su ve Aktivite',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _WaterCard(data: data, onWater: onWater),
        const SizedBox(height: 14),
        _ActivityCard(data: data, onAdd: onAddActivity, onTapLog: onTapLog),
      ],
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.data, required this.onWater});

  final WaterActivity data;
  final ValueChanged<int> onWater;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: AppColors.water,
                size: 38,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Su Tüketimi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: liters(data.waterMl),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${liters(data.waterTargetMl)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: data.waterRatio),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: AppColors.track,
                      color: AppColors.water,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(data.waterRatio * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (ml, label) in const [
                (250, '+250 ml'),
                (500, '+500 ml'),
                (1000, '+1 L'),
              ]) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onWater(ml),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.water,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.button - 2,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(label),
                  ),
                ),
                if (ml != 1000) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.data,
    required this.onAdd,
    required this.onTapLog,
  });

  final WaterActivity data;
  final VoidCallback onAdd;
  final ValueChanged<ActivityLogEntry> onTapLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_run_rounded,
                  color: AppColors.success,
                  size: 34,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivite',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Bugünkü hareketin',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${formatNumber(data.burnedKcal)} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          for (final log in data.logs) ...[
            const Divider(height: 1, color: AppColors.border),
            _Row(
              icon: activityIcon(log.icon),
              title: log.name,
              subtitle: '${log.minutes} dk • ${formatNumber(log.kcal)} kcal',
              onTap: () => onTapLog(log),
            ),
          ],
          const Divider(height: 1, color: AppColors.border),
          _Row(
            icon: Icons.add_rounded,
            title: 'Diğer Aktivite',
            subtitle: 'Ekle',
            subtitleColor: AppColors.primary,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(width: 14),
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
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor ?? AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewActivity {
  const _NewActivity.catalog(ActivityType this.type, this.minutes)
    : name = null,
      kcal = null;
  const _NewActivity.custom(String this.name, this.minutes, int this.kcal)
    : type = null;

  final ActivityType? type;
  final String? name;
  final int minutes;
  final int? kcal;
}

class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet({required this.catalog});

  final List<ActivityType> catalog;

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  ActivityType? _type;
  bool _custom = false;
  double _minutes = 30;
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.catalog.firstOrNull;
    _custom = widget.catalog.isEmpty;
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  void _submit() {
    final minutes = _minutes.round();
    if (!_custom) {
      Navigator.pop(context, _NewActivity.catalog(_type!, minutes));
      return;
    }
    final kcal = int.tryParse(_kcal.text.trim());
    if (_name.text.trim().isEmpty || kcal == null || kcal <= 0) {
      setState(() => _error = 'Aktivite adını ve yakılan kaloriyi gir.');
      return;
    }
    Navigator.pop(
      context,
      _NewActivity.custom(_name.text.trim(), minutes, kcal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _minutes.round();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Aktivite Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in widget.catalog)
                  ChoiceChip(
                    avatar: Icon(
                      activityIcon(a.icon),
                      size: 18,
                      color: !_custom && _type == a
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    label: Text(a.name),
                    selected: !_custom && _type == a,
                    onSelected: (_) => setState(() {
                      _type = a;
                      _custom = false;
                    }),
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: !_custom && _type == a
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ChoiceChip(
                  label: const Text('Diğer'),
                  selected: _custom,
                  onSelected: (_) => setState(() => _custom = true),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _custom ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (_custom) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Aktivite adı'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _kcal,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Yakılan kalori',
                  suffixText: 'kcal',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minutes dk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_custom && _type != null)
                  Text(
                    '≈ ${formatNumber(_type!.kcalFor(minutes))} kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
            Slider(
              value: _minutes,
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _minutes = v),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Ekle', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
