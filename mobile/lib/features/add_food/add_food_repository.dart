import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/network/api_client.dart';

/// Arama/barkod sonucu: 100 g başına değerler.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbPer100g,
    required this.fatPer100g,
    required this.defaultPortionG,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String? brand;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbPer100g;
  final double fatPer100g;
  final int defaultPortionG;
  final String? imageUrl;

  int kcalFor(int grams) => (kcalPer100g * grams / 100).round();

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id'] as int,
    name: j['name'] as String,
    brand: j['brand'] as String?,
    kcalPer100g: (j['kcal_per_100g'] as num).toDouble(),
    proteinPer100g: (j['protein_per_100g'] as num).toDouble(),
    carbPer100g: (j['carb_per_100g'] as num).toDouble(),
    fatPer100g: (j['fat_per_100g'] as num).toDouble(),
    defaultPortionG: j['default_portion_g'] as int,
    imageUrl: j['image_url'] as String?,
  );
}

/// AI'ın bulduğu, kullanıcının gramajını düzenleyebildiği yemek.
class AnalyzedItem {
  const AnalyzedItem({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.confidence,
  });

  final String name;
  final int grams;
  final int kcal;
  final double protein;
  final double carb;
  final double fat;
  final double confidence;

  /// Gramaj değişince besin değerleri orantılı ölçeklenir.
  AnalyzedItem withGrams(int newGrams) {
    final k = grams <= 0 ? 1.0 : newGrams / grams;
    double r(double v) => (v * k * 10).roundToDouble() / 10;
    return AnalyzedItem(
      name: name,
      grams: newGrams,
      kcal: (kcal * k).round(),
      protein: r(protein),
      carb: r(carb),
      fat: r(fat),
      confidence: confidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'grams': grams,
    'kcal': kcal,
    'protein': protein,
    'carb': carb,
    'fat': fat,
  };

  factory AnalyzedItem.fromJson(Map<String, dynamic> j) => AnalyzedItem(
    name: j['name'] as String,
    grams: j['grams'] as int,
    kcal: j['kcal'] as int,
    protein: (j['protein'] as num).toDouble(),
    carb: (j['carb'] as num).toDouble(),
    fat: (j['fat'] as num).toDouble(),
    confidence: (j['confidence'] as num? ?? 0.5).toDouble(),
  );
}

class AiQuota {
  const AiQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.isPremium,
  });

  final int used;
  final int limit;
  final int remaining;
  final bool isPremium;

  factory AiQuota.fromJson(Map<String, dynamic> j) => AiQuota(
    used: j['used'] as int,
    limit: j['limit'] as int,
    remaining: j['remaining'] as int,
    isPremium: j['is_premium'] as bool,
  );
}

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.id,
    required this.isFood,
    required this.items,
    required this.quota,
  });

  final int id;
  final bool isFood;
  final List<AnalyzedItem> items;
  final AiQuota quota;

  factory AiAnalysisResult.fromJson(Map<String, dynamic> j) => AiAnalysisResult(
    id: j['id'] as int,
    isFood: j['is_food'] as bool,
    items: [
      for (final i in j['items'] as List)
        AnalyzedItem.fromJson(i as Map<String, dynamic>),
    ],
    quota: AiQuota.fromJson(j['quota'] as Map<String, dynamic>),
  );
}

/// API'nin döndürdüğü hata kodu (quota_exceeded, budget_exceeded ...).
class AiException implements Exception {
  const AiException(this.message, {this.code});

  final String message;
  final String? code;

  bool get isQuota => code == 'quota_exceeded';

  @override
  String toString() => message;
}

class AddFoodRepository {
  AddFoodRepository(this._dio);

  final Dio _dio;

  Future<List<FoodItem>> search(String q) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/foods/search',
      queryParameters: {'q': q},
    );
    return [
      for (final f in res.data!['data'] as List)
        FoodItem.fromJson(f as Map<String, dynamic>),
    ];
  }

  /// Barkod bulunamazsa null döner.
  Future<FoodItem?> barcode(String code) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/foods/barcode/$code');
      return FoodItem.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<AiQuota> quota() async {
    final res = await _dio.get<Map<String, dynamic>>('/ai/quota');
    return AiQuota.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AiAnalysisResult> analyzePhoto(Uint8List jpeg) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/ai/analyze-photo',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(
            jpeg,
            filename: 'yemek.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        }),
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      return AiAnalysisResult.fromJson(
        res.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw AiException(
          data['message'] as String,
          code: data['code'] as String?,
        );
      }
      throw AiException(apiErrorMessage(e));
    }
  }

  Future<void> addFood({
    required String mealType,
    required int foodId,
    required int grams,
    String? date,
  }) => _addItems(mealType, {
    'date': ?date,
    'items': [
      {'food_id': foodId, 'grams': grams},
    ],
  });

  Future<void> addAnalyzed({
    required String mealType,
    required int analysisId,
    required List<AnalyzedItem> items,
    String? date,
  }) => _addItems(mealType, {
    'date': ?date,
    'ai_analysis_id': analysisId,
    'items': [for (final i in items) i.toJson()],
  });

  Future<void> _addItems(String mealType, Map<String, dynamic> body) =>
      _dio.post<void>('/meals/$mealType/items', data: body);
}

final addFoodRepositoryProvider = Provider(
  (ref) => AddFoodRepository(ref.watch(dioProvider)),
);

/// Saate göre varsayılan öğün.
String defaultMealType([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'breakfast';
  if (h < 12) return 'snack1';
  if (h < 15) return 'lunch';
  if (h < 18) return 'snack2';
  return 'dinner';
}
