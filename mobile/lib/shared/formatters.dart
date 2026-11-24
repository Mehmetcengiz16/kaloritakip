import 'package:intl/intl.dart';

final _thousands = NumberFormat('#,##0', 'tr_TR');

/// 1250 -> "1.250"
String formatNumber(num value) => _thousands.format(value);

const goalLabels = {
  'lose': 'Kilo Vermek',
  'gain': 'Kilo Almak',
  'maintain': 'Kilo Korumak',
  'healthy': 'Sağlıklı Beslenmek',
};

const mealLabels = {
  'breakfast': 'Kahvaltı',
  'snack1': 'Ara Öğün',
  'lunch': 'Öğle Yemeği',
  'snack2': 'Ara Öğün',
  'dinner': 'Akşam Yemeği',
};

/// Tasarımdaki yemek görselleri gelene kadar öğün başına emoji.
const mealEmojis = {
  'breakfast': '🥣',
  'snack1': '🍎',
  'lunch': '🥗',
  'snack2': '🍌',
  'dinner': '🍲',
};
