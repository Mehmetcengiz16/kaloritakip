import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../formatters.dart';

/// Ana Sayfa'daki "Kalan Kalori" halkası: gri iz + mor gradient ilerleme yayı.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    required this.remaining,
    required this.target,
    this.size = 196,
  });

  final double progress;
  final int remaining;
  final int target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final over = remaining < 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(progress: value, over: over),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  over ? 'Hedefi Aştın' : 'Kalan Kalori',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatNumber(remaining.abs()),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: over
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: ' kcal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hedef: ${formatNumber(target)} kcal',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.over});

  final double progress;
  final bool over;

  static const _stroke = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(_stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.track,
    );

    if (progress <= 0) return;

    final sweep = math.pi * 2 * progress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: const GradientRotation(-math.pi / 2),
        colors: over
            ? const [AppColors.danger, AppColors.danger]
            : const [AppColors.primaryLight, AppColors.primaryDark],
      ).createShader(arcRect);

    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.over != over;
}
