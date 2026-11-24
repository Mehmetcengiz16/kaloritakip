import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/formatters.dart';
import '../home/dashboard_repository.dart';
import 'add_food_repository.dart';
import 'tabs/barcode_tab.dart';
import 'tabs/photo_ai_tab.dart';
import 'tabs/search_tab.dart';
import 'widgets/portion_sheet.dart';

enum AddFoodTab { search, barcode, photo }

/// Yemek Ekle: Ara · Barkod · Fotoğraf (AI)
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({
    super.key,
    this.initialTab = AddFoodTab.photo,
    this.mealType,
    this.date,
  });

  final AddFoodTab initialTab;
  final String? mealType;

  /// Geçmiş bir güne ekleme (yyyy-MM-dd); boşsa bugün.
  final String? date;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  late AddFoodTab _tab = widget.initialTab;
  late String _mealType = widget.mealType ?? defaultMealType();

  /// Arama veya barkoddan seçilen yemek için porsiyon seçtirip öğüne ekler.
  Future<void> _addFood(FoodItem food) async {
    final grams = await showPortionSheet(
      context,
      food: food,
      mealLabel: mealLabels[_mealType]!,
    );
    if (grams == null || !mounted) return;
    try {
      await ref
          .read(addFoodRepositoryProvider)
          .addFood(
            mealType: _mealType,
            foodId: food.id,
            grams: grams,
            date: widget.date,
          );
      _done('${food.name} eklendi (${formatNumber(food.kcalFor(grams))} kcal)');
    } catch (e) {
      _error(apiErrorMessage(e));
    }
  }

  Future<void> _addAnalyzed(int analysisId, List<AnalyzedItem> items) async {
    await ref
        .read(addFoodRepositoryProvider)
        .addAnalyzed(
          mealType: _mealType,
          analysisId: analysisId,
          items: items,
          date: widget.date,
        );
    final total = items.fold<int>(0, (s, i) => s + i.kcal);
    _done(
      '${mealLabels[_mealType]} öğününe ${formatNumber(total)} kcal eklendi',
    );
  }

  void _done(String message) {
    ref.invalidate(dashboardProvider);
    ref.invalidate(dayMealsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.canPop() ? context.pop() : context.go('/home');
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yemek Ekle',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _TabSelector(
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _MealTypeSelector(
                value: _mealType,
                onChanged: (v) => setState(() => _mealType = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_tab) {
                AddFoodTab.search => SearchTab(onSelect: _addFood),
                AddFoodTab.barcode => BarcodeTab(onFound: _addFood),
                AddFoodTab.photo => PhotoAiTab(onAdd: _addAnalyzed),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tasarımdaki üç sekmeli seçici: ikon + etiket, seçili olan açık mor arka planlı.
class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selected, required this.onChanged});

  final AddFoodTab selected;
  final ValueChanged<AddFoodTab> onChanged;

  static const _tabs = [
    (AddFoodTab.search, Icons.search_rounded, 'Ara'),
    (AddFoodTab.barcode, Icons.qr_code_scanner_rounded, 'Barkod'),
    (AddFoodTab.photo, Icons.photo_camera_outlined, 'Fotoğraf (AI)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final (tab, icon, label) in _tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: tab == selected
                        ? AppColors.primarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.button - 2),
                    border: Border.all(
                      color: tab == selected
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: tab == selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: tab == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: tab == selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final type in mealLabels.keys)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mealLabels[type]!),
                selected: value == type,
                onSelected: (_) => onChanged(type),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value == type ? Colors.white : AppColors.textSecondary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: value == type ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
