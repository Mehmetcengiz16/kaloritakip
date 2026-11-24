import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import 'progress_insights.dart';
import 'progress_repository.dart';

/// Ortak kart çerçevesi: başlık + içerik (diğer ekranlardaki kartlarla aynı stil).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Hedefe ilerleme ────────────────────────────────────────────────

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    return SectionCard(
      title: 'Hedefe İlerleme',
      trailing: Text(
        '%${g.progressPct}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: g.progressPct / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: AppColors.track,
                color: g.reached ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Kg('Başlangıç', g.startKg)),
              Expanded(
                child: _Kg(
                  'Şimdi',
                  g.currentKg,
                  bold: true,
                  align: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _Kg('Hedef', g.targetKg, align: CrossAxisAlignment.end),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: g.reached
                  ? const Color(0xFFEAF7EC)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  g.reached ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  size: 18,
                  color: g.reached ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    g.reached
                        ? 'Tebrikler, hedef kilona ulaştın!'
                        : '${decimal(g.remainingKg)} kg kaldı'
                              '${g.etaDate != null ? ' · Bu hızla tahmini varış: ${DateFormat('d MMMM', 'tr_TR').format(g.etaDate!)}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

class _Kg extends StatelessWidget {
  const _Kg(
    this.label,
    this.kg, {
    this.bold = false,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final double kg;
  final bool bold;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: align,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${decimal(kg)} kg',
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

// ── Kalori grafiği ─────────────────────────────────────────────────

class CalorieChartCard extends StatelessWidget {
  const CalorieChartCard({super.key, required this.stats, required this.range});

  final CalorieStats stats;
  final ProgressRange range;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return SectionCard(
      title: 'Kalori',
      trailing: Text(
        'Hedef ${formatNumber(s.target)} kcal',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: s.loggedDays == 0
                ? const _Empty('Bu dönemde öğün kaydı yok.')
                : _bars(s),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat('Ortalama', '${formatNumber(s.avg)} kcal'),
              ),
              Expanded(
                child: _MiniStat(
                  'Hedefte kalınan',
                  '${s.onTargetDays}/${s.loggedDays} gün',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  'Fark',
                  s.loggedDays == 0
                      ? '—'
                      : '${s.avg - s.target > 0 ? '+' : ''}${formatNumber(s.avg - s.target)} kcal',
                  color: s.loggedDays == 0
                      ? null
                      : (s.avg <= s.target * 1.1
                            ? AppColors.success
                            : AppColors.carb),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bars(CalorieStats s) {
    final maxKcal = s.bars.fold<int>(s.target, (m, b) => math.max(m, b.kcal));
    final maxY = (maxKcal * 1.15 / 500).ceil() * 500.0;
    final fmt = DateFormat(
      range == ProgressRange.week
          ? 'E'
          : (range == ProgressRange.month ? 'd' : 'MMM'),
      'tr_TR',
    );
    final labelEvery = range == ProgressRange.month ? 5 : 1;
    final barWidth = switch (range) {
      ProgressRange.week => 18.0,
      ProgressRange.month => 5.0,
      ProgressRange.year => 14.0,
    };

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: s.target.toDouble(),
              color: AppColors.primary.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= s.bars.length || i % labelEvery != 0)
                  return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    fmt.format(s.bars[i].date),
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${formatNumber(rod.toY)} kcal',
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < s.bars.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: s.bars[i].kcal.toDouble(),
                  width: barWidth,
                  borderRadius: BorderRadius.circular(barWidth > 8 ? 6 : 2),
                  color: s.bars[i].kcal > s.target * 1.1
                      ? AppColors.carb
                      : AppColors.primary,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Makro ortalaması ───────────────────────────────────────────────

class MacroAverageCard extends StatelessWidget {
  const MacroAverageCard({super.key, required this.stats});

  final MacroStats stats;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Protein', stats.protein, AppColors.protein),
      ('Karbonhidrat', stats.carb, AppColors.carb),
      ('Yağ', stats.fat, AppColors.fat),
    ];

    return SectionCard(
      title: 'Makro Ortalaması',
      trailing: const Text(
        'günlük',
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      child: stats.isEmpty
          ? const SizedBox(
              height: 60,
              child: _Empty('Bu dönemde öğün kaydı yok.'),
            )
          : Column(
              children: [
                // Kalorinin makrolara dağılımı: tek şerit
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        for (final (_, m, color) in rows)
                          if (m.pct > 0)
                            Expanded(
                              flex: m.pct,
                              child: ColoredBox(color: color),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (final (label, m, color) in rows) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${m.avg} / ${m.target} g',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '%${m.pct}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: m.ratio,
                      minHeight: 5,
                      backgroundColor: AppColors.track,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

// ── Seri ve alışkanlıklar ──────────────────────────────────────────

class HabitsCard extends StatelessWidget {
  const HabitsCard({super.key, required this.stats});

  final HabitStats stats;

  @override
  Widget build(BuildContext context) {
    final h = stats;
    final tiles = [
      ('🔥', '${h.streakDays} gün', 'Seri'),
      ('📅', '${h.loggedDays}/${h.periodDays}', 'Kayıtlı gün'),
      (
        '💧',
        '${(h.avgWaterMl / 1000).toStringAsFixed(1).replaceAll('.', ',')} L',
        'Ort. su',
      ),
      ('🏃', '${formatNumber(h.activityKcal)} kcal', 'Aktivite'),
    ];

    return SectionCard(
      title: 'Seri ve Alışkanlıklar',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              for (final (emoji, value, label) in tiles)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (h.streakDays >= 3) ...[
            const SizedBox(height: 10),
            Text(
              '${h.streakDays} gündür kayıt tutuyorsun, böyle devam! 💪',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );
}
