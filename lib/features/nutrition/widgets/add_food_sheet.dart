import 'package:flutter/material.dart';

import '../../../models/meal_entry.dart';
import '../pages/barcode_scan_page.dart';
import '../pages/custom_food_form_page.dart';
import '../pages/food_search_page.dart';
import '../pages/saved_meals_list_page.dart';
import '../pages/user_recipes_list_page.dart';
import 'quick_add_sheet.dart';

class AddFoodSheet extends StatelessWidget {
  final MealType mealType;
  final DateTime initialDate;

  const AddFoodSheet({
    super.key,
    required this.mealType,
    required this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add food · ${mealType.label}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search food'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FoodSearchPage(
                        mealType: mealType,
                        initialDate: initialDate,
                      ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan barcode'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BarcodeScanPage(
                        mealType: mealType,
                        initialDate: initialDate,
                      ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.flash_on),
            title: const Text('Quick add calories'),
            subtitle: const Text('When the exact food isn\'t available'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder:
                    (context) => QuickAddSheet(
                      mealType: mealType,
                      initialDate: initialDate,
                    ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('My saved meals'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SavedMealsListPage(
                        mealType: mealType,
                        initialDate: initialDate,
                      ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Recipes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => UserRecipesListPage(
                        mealType: mealType,
                        initialDate: initialDate,
                      ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Create custom food'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomFoodFormPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
