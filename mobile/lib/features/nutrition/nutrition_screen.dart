import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/food_thumb.dart';
import '../home/dashboard_repository.dart';

/// Beslenme: tarih seçici + günün öğünleri. Öğüne dokununca içindekiler açılır.
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _date = dateOnly(DateTime.now());
  final Set<String> _expanded = {};

  bool get _isToday => _date == dateOnly(DateTime.now());

  void _shiftDay(int days) => setState(() {
    _date = _date.add(Duration(days: days));
    _expanded.clear();
  });

  Future<void> _pickDate() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _openAddFood([String? mealType]) async {
    final meal = mealType ?? '';
    await context.push(
      '/add-food?tab=search${meal.isEmpty ? '' : '&meal=$meal'}${_isToday ? '' : '&date=${apiDate(_date)}'}',
    );
    ref.invalidate(dayMealsProvider(_date));
  }

  Future<void> _delete(MealEntry entry) async {
    try {
      await ref.read(dashboardRepositoryProvider).deleteItem(entry.id);
      ref.invalidate(dayMealsProvider(_date));
      ref.invalidate(dashboardProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(apiErrorMessage(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dayMealsProvider(_date));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Text(
                'Beslenme',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DateBar(
                date: _date,
                isToday: _isToday,
                onTap: _pickDate,
                onPrev: () => _shiftDay(-1),
                onNext: _isToday ? null : () => _shiftDay(1),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                data: (d) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.refresh(dayMealsProvider(_date).future),
                  child: MealList(
                    data: d,
                    expanded: _expanded,
                    onToggle: (type) => setState(
                      () => _expanded.contains(type)
                          ? _expanded.remove(type)
                          : _expanded.add(type),
                    ),
                    onAdd: _openAddFood,
                    onDelete: _delete,
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(dayMealsProvider(_date)),
                    child: Text(
                      '${apiErrorMessage(e)}\nTekrar dene',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: PrimaryButton(
                label: 'Yemek Ekle',
                icon: Icons.add_rounded,
                onPressed: _openAddFood,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Bugün, 22 Kasım" tarih kartı.
class DateBar extends StatelessWidget {
  const DateBar({
    super.key,
    required this.date,
    required this.isToday,
    required this.onTap,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final yesterday = dateOnly(
      DateTime.now(),
    ).subtract(const Duration(days: 1));
    final prefix = isToday ? 'Bugün, ' : (date == yesterday ? 'Dün, ' : '');
    final label =
        '$prefix${DateFormat(isToday || date == yesterday ? 'd MMMM' : 'd MMMM EEEE', 'tr_TR').format(date)}';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            tooltip: 'Önceki gün',
            icon: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'Sonraki gün',
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext == null ? AppColors.border : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class MealList extends StatelessWidget {
  const MealList({
    super.key,
    required this.data,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onDelete,
  });

  final Dashboard data;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onAdd;
  final ValueChanged<MealEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        for (final meal in data.meals) ...[
          _MealCard(
            meal: meal,
            expanded: expanded.contains(meal.type),
            onToggle: () => onToggle(meal.type),
            onAdd: () => onAdd(meal.type),
            onDelete: onDelete,
          ),
          const SizedBox(height: 10),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '${formatNumber(data.consumedKcal)} / ${formatNumber(data.targetKcal)} kcal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.expanded,
    required this.onToggle,
    required this.onAdd,
    required this.onDelete,
  });

  final MealSummary meal;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAdd;
  final ValueChanged<MealEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      mealEmojis[meal.type] ?? '🍽️',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mealLabels[meal.type] ?? meal.type,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${formatNumber(meal.kcal)} kcal',
                    style: TextStyle(
                      fontSize: 13,
                      color: meal.kcal == 0
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            if (meal.items.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Bu öğüne henüz bir şey eklenmedi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            for (final item in meal.items)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                child: Row(
                  children: [
                    FoodThumb(
                      name: item.name,
                      imageUrl: item.imageUrl,
                      size: 40,
                      radius: 10,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${item.grams} g',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatNumber(item.kcal)} kcal',
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => onDelete(item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('${mealLabels[meal.type]} ekle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
