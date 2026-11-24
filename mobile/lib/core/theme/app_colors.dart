import 'package:flutter/material.dart';

/// Tasarımdaki renk token'ları. Admin panel Tailwind teması da aynı değerleri kullanır.
abstract final class AppColors {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF6D28D9);
  static const primarySoft = Color(0xFFF3EEFF);

  static const background = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFFAFAFC);
  static const border = Color(0xFFECEBF2);
  static const track = Color(0xFFEFEDF5);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const protein = primary;
  static const carb = Color(0xFFF59E0B);
  static const fat = Color(0xFFFACC15);
  static const success = Color(0xFF22C55E);
  static const water = Color(0xFF3B82F6);
  static const danger = Color(0xFFEF4444);

  static const primaryGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
