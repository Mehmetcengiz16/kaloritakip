import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Yemek görseli; görsel yoksa ya da yüklenemezse ada göre emoji (renkli zemin üzerinde).
class FoodThumb extends StatelessWidget {
  const FoodThumb({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.radius = 12,
  });

  final String name;
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = _EmojiTile(name: name, size: size, radius: radius);
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).round(),
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) =>
            Container(width: size, height: size, color: AppColors.surfaceMuted),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.name,
    required this.size,
    required this.radius,
  });

  final String name;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = foodEmoji(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// Ada göre emoji ve yumuşak zemin rengi (admin panel: resources/js/lib/format.js ile aynı kurallar).
(String, Color) foodEmoji(String name) {
  final n = ' ${name.toLowerCase()} ';
  for (final (keys, emoji, color) in _rules) {
    if (keys.any(n.contains)) return (emoji, color);
  }
  return ('🍽️', AppColors.surfaceMuted);
}

const _orange = Color(0xFFFFF1E0);
const _green = Color(0xFFEAF7EC);
const _red = Color(0xFFFDECEC);
const _yellow = Color(0xFFFFF8DB);
const _blue = Color(0xFFE8F1FE);
const _purple = AppColors.primarySoft;

const _rules = <(List<String>, String, Color)>[
  (['yumurta', 'omlet', 'menemen'], '🥚', _yellow),
  (['tavuk', 'piliç', 'kanat', 'döner'], '🍗', _orange),
  (['köfte', 'et ', 'kıyma', 'biftek', 'iskender', 'kebap'], '🍖', _red),
  (['balık', 'somon', 'ton balığı', 'hamsi', 'levrek'], '🐟', _blue),
  (['çorba'], '🍲', _orange),
  (['pilav', 'pirinç'], '🍚', _yellow),
  (['bulgur'], '🌾', _yellow),
  (['makarna', 'spagetti', 'mantı'], '🍝', _orange),
  (['salata'], '🥗', _green),
  (['ekmek', 'simit', 'poğaça', 'börek'], '🥐', _yellow),
  (['peynir', 'kaşar'], '🧀', _yellow),
  (['süt', 'ayran', 'yoğurt', 'kefir'], '🥛', _blue),
  (['zeytin'], '🫒', _green),
  (['fasulye', 'nohut', 'mercimek'], '🫘', _orange),
  (['sarma', 'dolma'], '🍃', _green),
  (['lahmacun', 'pide', 'pizza'], '🍕', _red),
  (['patates'], '🍟', _yellow),
  (['muz'], '🍌', _yellow),
  (['elma'], '🍎', _red),
  (['portakal', 'mandalina'], '🍊', _orange),
  (['çilek'], '🍓', _red),
  (['üzüm'], '🍇', _purple),
  (['karpuz'], '🍉', _red),
  (['avokado'], '🥑', _green),
  (['ceviz', 'badem', 'fındık', 'fıstık'], '🥜', _orange),
  (
    [
      'baklava',
      'tatlı',
      'pasta',
      'kek',
      'sütlaç',
      'kurabiye',
      'bisküvi',
      'gofret',
      'çikolata',
    ],
    '🍰',
    _purple,
  ),
  (['kahve'], '☕', _orange),
  (['çay'], '🍵', _green),
  (['yulaf', 'müsli', 'granola'], '🥣', _yellow),
  (['sebze', 'brokoli', 'kabak', 'ıspanak'], '🥦', _green),
];
