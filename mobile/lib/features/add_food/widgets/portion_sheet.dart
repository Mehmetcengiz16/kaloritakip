import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/food_thumb.dart';
import '../add_food_repository.dart';

/// Porsiyon (gram) seçtirir; iptalde null döner.
Future<int?> showPortionSheet(
  BuildContext context, {
  required FoodItem food,
  required String mealLabel,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PortionSheet(food: food, mealLabel: mealLabel),
  );
}

/// Sadece gramaj seçtirir (AI sonucu düzenlerken kullanılır).
Future<int?> showGramsSheet(
  BuildContext context, {
  required String title,
  required int grams,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _GramsSheet(title: title, initial: grams),
  );
}

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({required this.food, required this.mealLabel});

  final FoodItem food;
  final String mealLabel;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  late int _grams = widget.food.defaultPortionG;

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final k = _grams / 100;
    String g(double v) => (v * k).toStringAsFixed(1).replaceAll('.', ',');

    return _SheetFrame(
      children: [
        Row(
          children: [
            FoodThumb(name: f.name, imageUrl: f.imageUrl, size: 72, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (f.brand != null)
                    Text(
                      f.brand!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _GramStepper(
          value: _grams,
          onChanged: (v) => setState(() => _grams = v),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Nutrient(
              'Kalori',
              '${formatNumber(f.kcalFor(_grams))} kcal',
              AppColors.primary,
            ),
            _Nutrient('Protein', '${g(f.proteinPer100g)} g', AppColors.protein),
            _Nutrient('Karb.', '${g(f.carbPer100g)} g', AppColors.carb),
            _Nutrient('Yağ', '${g(f.fatPer100g)} g', AppColors.fat),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: '${widget.mealLabel} öğününe ekle',
          onPressed: () => Navigator.pop(context, _grams),
        ),
      ],
    );
  }
}

class _GramsSheet extends StatefulWidget {
  const _GramsSheet({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_GramsSheet> createState() => _GramsSheetState();
}

class _GramsSheetState extends State<_GramsSheet> {
  late int _grams = widget.initial;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Porsiyonu düzelt; kalori buna göre yeniden hesaplanır.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        _GramStepper(
          value: _grams,
          onChanged: (v) => setState(() => _grams = v),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Kaydet',
          onPressed: () => Navigator.pop(context, _grams),
        ),
      ],
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GramStepper extends StatelessWidget {
  const _GramStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  void _set(int v) => onChanged(v.clamp(5, 3000));

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: () => _set(value - (value > 50 ? 10 : 5)),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text: ' g',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: () => _set(value + (value >= 50 ? 10 : 5)),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primarySoft,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: AppColors.primary),
      ),
    ),
  );
}

class _Nutrient extends StatelessWidget {
  const _Nutrient(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );
}
