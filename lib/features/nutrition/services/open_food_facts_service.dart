import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food.dart';
import '../models/open_food_facts_food.dart';
import 'food_database_service.dart';

class FoodSearchException implements Exception {
  final String message;

  FoodSearchException(this.message);

  @override
  String toString() => message;
}

/// Open Food Facts (openfoodfacts.org) — free, open, no API key required.
/// Data is licensed ODbL; see the attribution caption shown alongside
/// results in the UI.
class OpenFoodFactsService implements FoodDatabaseService {
  static const _base = 'https://world.openfoodfacts.org';
  static const _fields = 'code,product_name,brands,nutriments,serving_size';

  final http.Client _client;

  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  @override
  Future<List<Food>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse('$_base/api/v2/search').replace(
      queryParameters: {
        'search_terms': q,
        'fields': _fields,
        'page_size': '20',
      },
    );
    final res = await _get(uri);
    final products = (jsonDecode(res.body)['products'] as List? ?? const []);

    return products
        .map(
          (p) =>
              OpenFoodFactsFood.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .where((f) => f.caloriesPer100g != null)
        .map(Food.fromOpenFoodFacts)
        .toList();
  }

  @override
  Future<Food?> getFoodByBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_base/api/v2/product/$barcode.json',
    ).replace(queryParameters: {'fields': _fields});
    final res = await _get(uri);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 1 || body['product'] == null) return null;

    final off = OpenFoodFactsFood.fromJson(
      Map<String, dynamic>.from(body['product'] as Map),
    );
    if (off.caloriesPer100g == null) return null;
    return Food.fromOpenFoodFacts(off);
  }

  @override
  Future<Food?> getFood(String id) => getFoodByBarcode(id);

  Future<http.Response> _get(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw FoodSearchException(
          'Open Food Facts returned an error (${res.statusCode}).',
        );
      }
      return res;
    } on TimeoutException {
      throw FoodSearchException(
        'Food search timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw FoodSearchException("Couldn't reach the food database.");
    }
  }
}
