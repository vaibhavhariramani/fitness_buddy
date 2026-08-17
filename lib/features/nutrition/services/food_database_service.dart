import '../models/food.dart';

/// Abstraction over any food-data backend, so a different/additional
/// database can be plugged in later without touching call sites.
abstract class FoodDatabaseService {
  Future<List<Food>> searchFoods(String query);
  Future<Food?> getFoodByBarcode(String barcode);
  Future<Food?> getFood(String id);
}
