import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../models/story.dart';
import 'widgets/macro_pie_chart.dart';

/// Full-screen WhatsApp/Instagram-style viewer for one person's active
/// stories — segmented progress bars up top, auto-advance, tap left/right
/// to navigate, long-press to pause, swipe down or tap the X to dismiss.
class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final String ownerName;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.ownerName,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController();
  late AnimationController _progress;
  int _index = 0;

  Duration _durationFor(int i) {
    final story = widget.stories[i];
    return story.type == StoryType.dailySummary
        ? const Duration(seconds: 7)
        : const Duration(seconds: 5);
  }

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _durationFor(0))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _advance();
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_index >= widget.stories.length - 1) {
      Navigator.pop(context);
      return;
    }
    _goTo(_index + 1);
  }

  void _goBack() {
    if (_index == 0) return;
    _goTo(_index - 1);
  }

  void _goTo(int i) {
    setState(() => _index = i);
    _pageController.jumpToPage(i);
    _progress
      ..duration = _durationFor(i)
      ..reset()
      ..forward();
  }

  void _setPaused(bool paused) {
    if (paused) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _goBack();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _advance();
          }
        },
        onLongPressStart: (_) => _setPaused(true),
        onLongPressEnd: (_) => _setPaused(false),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) Navigator.pop(context);
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder:
                  (context, i) => _StorySlide(story: widget.stories[i]),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.stories.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: AnimatedBuilder(
                                animation: _progress,
                                builder: (context, _) {
                                  final value =
                                      i < _index
                                          ? 1.0
                                          : i > _index
                                          ? 0.0
                                          : _progress.value;
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: value,
                                      minHeight: 3,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.ownerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorySlide extends StatelessWidget {
  final Story story;

  const _StorySlide({required this.story});

  @override
  Widget build(BuildContext context) {
    if (story.type == StoryType.dailySummary) {
      return _DailySummarySlide(story: story);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (story.photoUrl != null)
          CachedNetworkImage(imageUrl: story.photoUrl!, fit: BoxFit.cover)
        else
          const ColoredBox(color: Colors.black),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
              ),
            ),
            child:
                story.type == StoryType.weight
                    ? _WeightOverlay(story: story)
                    : _MealOverlay(story: story),
          ),
        ),
      ],
    );
  }
}

class _WeightOverlay extends StatelessWidget {
  final Story story;

  const _WeightOverlay({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            '${story.weightKg?.toStringAsFixed(1) ?? '—'} kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealOverlay extends StatelessWidget {
  final Story story;

  const _MealOverlay({required this.story});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          story.mealTypeLabel ?? 'Meal',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${story.calories?.toStringAsFixed(0) ?? '—'} kcal',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 10),
        MacroPieChart(
          proteinG: story.proteinG ?? 0,
          carbG: story.carbG ?? 0,
          fatG: story.fatG ?? 0,
        ),
      ],
    );
  }
}

class _DailySummarySlide extends StatelessWidget {
  final Story story;

  const _DailySummarySlide({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.achievement, AppColors.recovery],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.displayName ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                story.summaryDateKey ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (story.streakCount != null)
                _SummaryRow(
                  icon: Icons.local_fire_department_rounded,
                  label:
                      '${story.streakCount} day${story.streakCount == 1 ? '' : 's'} streak',
                ),
              if (story.summaryWeightKg != null)
                _SummaryRow(
                  icon: Icons.monitor_weight_outlined,
                  label: '${story.summaryWeightKg!.toStringAsFixed(1)} kg',
                ),
              if (story.summaryMealsCount != null &&
                  story.summaryMealsCount! > 0)
                _SummaryRow(
                  icon: Icons.restaurant_menu,
                  label:
                      '${story.summaryMealsCount} meal'
                      '${story.summaryMealsCount == 1 ? '' : 's'} logged'
                      '${story.summaryCaloriesTotal != null ? ' · ${story.summaryCaloriesTotal!.toStringAsFixed(0)} kcal' : ''}',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
