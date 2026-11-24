import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_buttons.dart';
import '../home/dashboard_repository.dart';
import 'progress_repository.dart';
import 'progress_sections.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressRange _range = ProgressRange.week;

  Future<void> _addWeight(double? current) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WeightSheet(initial: current ?? 70),
    );
    if (saved == true) {
      ref.invalidate(progressProvider);
      ref.invalidate(
        dashboardProvider,
      ); // kilo değişince kalori hedefi de değişir
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(progressProvider(_range));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'İlerleme',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addWeight(async.value?.currentWeightKg),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Kilo Gir'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RangeSegments(
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 14),
            async.when(
              data: (p) => ProgressContent(progress: p),
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
                    onPressed: () => ref.invalidate(progressProvider(_range)),
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
    );
  }
}

/// Haftalık · Aylık · Yıllık
class RangeSegments extends StatelessWidget {
  const RangeSegments({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ProgressRange value;
  final ValueChanged<ProgressRange> onChanged;

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
          for (final r in ProgressRange.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: r == value
                        ? AppColors.primarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.button - 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    r.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: r == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: r == value
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

class ProgressContent extends StatelessWidget {
  const ProgressContent({super.key, required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final change = p.weightChangeKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p.goal != null) ...[
          GoalProgressCard(goal: p.goal!),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kilo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    p.currentWeightKg == null
                        ? '—'
                        : decimal(p.currentWeightKg!),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    ' kg',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  if (change != null)
                    Text(
                      '${signed(change)} kg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _changeColor(change),
                      ),
                    ),
                ],
              ),
              Text(
                '(${p.range.periodLabel})',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: WeightChart(points: p.points, range: p.range),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Kilo',
                value: change == null ? '—' : '${signed(change)} kg',
                color: change == null ? null : _changeColor(change),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Yağ Oranı',
                value: p.bodyFatChangePct == null
                    ? '—'
                    : '${signed(p.bodyFatChangePct!)} %',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'BMI',
                value: p.bmi == null ? '—' : decimal(p.bmi!),
              ),
            ),
          ],
        ),
        if (p.calories != null) ...[
          const SizedBox(height: 12),
          CalorieChartCard(stats: p.calories!, range: p.range),
        ],
        if (p.macros != null) ...[
          const SizedBox(height: 12),
          MacroAverageCard(stats: p.macros!),
        ],
        if (p.habits != null) ...[
          const SizedBox(height: 12),
          HabitsCard(stats: p.habits!),
        ],
      ],
    );
  }

  /// Kilo kaybı yeşil (tasarımdaki gibi), artış turuncu.
  static Color _changeColor(double v) =>
      v <= 0 ? AppColors.success : AppColors.carb;
}

class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.points, required this.range});

  final List<WeightPoint> points;
  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text(
          'Bu dönemde kilo kaydı yok.\n"Kilo Gir" ile ilk ölçümünü ekle.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final first = points.first.date;
    double x(DateTime d) => range == ProgressRange.year
        ? ((d.year - first.year) * 12 + d.month - first.month).toDouble()
        : d.difference(first).inDays.toDouble();

    final spots = [for (final p in points) FlSpot(x(p.date), p.weightKg)];
    final ys = points.map((p) => p.weightKg);
    final minY = (ys.reduce(math.min) - 1).floorToDouble();
    final maxY = (ys.reduce(math.max) + 1).ceilToDouble();
    final maxX = math.max(spots.last.x, 1.0);
    final labelFmt = DateFormat(
      range == ProgressRange.year ? 'MMM' : 'd MMM',
      'tr_TR',
    );
    final step = range == ProgressRange.week
        ? 1.0
        : (range == ProgressRange.month ? 5.0 : 2.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: math.max(1, ((maxY - minY) / 3).roundToDouble()),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                if (v != v.roundToDouble()) return const SizedBox.shrink();
                final d = range == ProgressRange.year
                    ? DateTime(first.year, first.month + v.toInt())
                    : first.add(Duration(days: v.toInt()));
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    labelFmt.format(d),
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${decimal(s.y)} kg',
                  const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.primary,
            barWidth: 2.5,
            isCurved: false,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card - 4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightSheet extends ConsumerStatefulWidget {
  const _WeightSheet({required this.initial});

  final double initial;

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  late final _weight = TextEditingController(text: decimal(widget.initial));
  final _fat = TextEditingController();
  bool _saving = false;
  String? _error;

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final kg = _parse(_weight.text);
    final fat = _fat.text.trim().isEmpty ? null : _parse(_fat.text);
    if (kg == null || kg < 30 || kg > 350) {
      setState(() => _error = 'Geçerli bir kilo gir (30-350).');
      return;
    }
    if (_fat.text.trim().isNotEmpty && (fat == null || fat < 2 || fat > 70)) {
      setState(() => _error = 'Yağ oranı 2 ile 70 arasında olmalı.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(progressRepositoryProvider).addWeight(kg, bodyFatPct: fat);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
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
              'Bugünkü Ölçümün',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: input,
              decoration: const InputDecoration(
                labelText: 'Kilo',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: input,
              decoration: const InputDecoration(
                labelText: 'Yağ oranı (isteğe bağlı)',
                suffixText: '%',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Kaydet', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
