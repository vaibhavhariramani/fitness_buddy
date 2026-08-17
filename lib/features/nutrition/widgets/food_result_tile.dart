import 'package:flutter/material.dart';

import '../models/food.dart';

/// Deliberately uses a generic local icon rather than a network product
/// photo — Open Food Facts images live on a path not verified for CORS on
/// Flutter Web (the same class of problem that broke wger.de images).
class FoodResultTile extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const FoodResultTile({
    super.key,
    required this.food,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          food.source == FoodSource.custom
              ? Icons.restaurant_menu
              : Icons.fastfood_outlined,
        ),
      ),
      title: Text(food.name),
      subtitle: Text(
        [
          if (food.brand != null && food.brand!.isNotEmpty) food.brand!,
          '${food.caloriesPer100g.toStringAsFixed(0)} kcal / 100g',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Theme.of(context).colorScheme.error : null,
            ),
            onPressed: onToggleFavorite,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
