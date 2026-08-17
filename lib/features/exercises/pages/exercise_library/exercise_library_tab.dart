import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/exercise_providers.dart';
import '../../widgets/category_chip_row.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/equipment_filter_sheet.dart';
import '../../widgets/exercise_card.dart';
import '../../widgets/shimmer_card.dart';

class ExerciseLibraryTab extends ConsumerStatefulWidget {
  const ExerciseLibraryTab({super.key});

  @override
  ConsumerState<ExerciseLibraryTab> createState() => _ExerciseLibraryTabState();
}

class _ExerciseLibraryTabState extends ConsumerState<ExerciseLibraryTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  int _visibleCount = 30;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      setState(() => _visibleCount += 30);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(exerciseLibraryFilterProvider.notifier).setSearch(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(exerciseLibraryFilterProvider, (previous, next) {
      if (previous != next) setState(() => _visibleCount = 30);
    });

    final filteredAsync = ref.watch(filteredExercisesProvider);
    final favorites = ref.watch(favoritesProvider);
    final filter = ref.watch(exerciseLibraryFilterProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search exercises',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Filter by equipment',
                icon: const Icon(Icons.tune),
                onPressed:
                    () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const EquipmentFilterSheet(),
                    ),
              ),
              IconButton(
                tooltip:
                    filter.favoritesOnly
                        ? 'Show all exercises'
                        : 'Show favorites only',
                icon: Icon(
                  filter.favoritesOnly ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed:
                    () => ref
                        .read(exerciseLibraryFilterProvider.notifier)
                        .setFavoritesOnly(!filter.favoritesOnly),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: CategoryChipRow(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredAsync.when(
            loading: () => ShimmerGrid(crossAxisCount: isWide ? 4 : 2),
            error:
                (e, _) => Center(child: Text('Failed to load exercises: $e')),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'No exercises found',
                  message: 'Try a different search term or clear your filters.',
                );
              }
              final visible = list.take(_visibleCount).toList();
              return GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final exercise = visible[i];
                  return ExerciseCard(
                    exercise: exercise,
                    isFavorite: favorites.contains(exercise.id),
                    onToggleFavorite:
                        () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(exercise.id),
                    onTap: () => context.push('/exercises/${exercise.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
