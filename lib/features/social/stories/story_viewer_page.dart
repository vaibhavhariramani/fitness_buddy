import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../models/story.dart';
import '../../../shared/widgets/app_share_branding.dart';
import '../../../shared/widgets/share_capture_mixin.dart';
import 'widgets/macro_pie_chart.dart';

/// Full-screen WhatsApp/Instagram-style viewer for one person's active
/// stories — segmented progress bars up top, auto-advance, tap left/right
/// to navigate, long-press to pause, swipe down or tap the X to dismiss.
class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final String ownerName;

  /// Whether these are the signed-in user's own stories — only then do we
  /// show a share button, since sharing someone else's story outside the
  /// app isn't ours to offer.
  final bool isOwnStory;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.ownerName,
    this.isOwnStory = false,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController();
  late AnimationController _progress;
  int _index = 0;
  bool _didPrecache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Backstop for StoryAvatar's proactive precache — fetches every photo
    // in this person's story set (not just the first slide) up front, so
    // swiping through them is instant even if the avatar-level precache
    // hadn't finished yet (e.g. tapped right as the story bar loaded).
    if (_didPrecache) return;
    _didPrecache = true;
    for (final story in widget.stories) {
      final url = story.photoUrl;
      if (url != null) precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  Duration _durationFor(int i) {
    final story = widget.stories[i];
    return story.type == StoryType.dailySummary
        ? const Duration(seconds: 7)
        : const Duration(seconds: 5);
  }

  @override
  void initState() {
    super.initState();
    _progress =
        AnimationController(vsync: this, duration: _durationFor(0))
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
                                      valueColor: const AlwaysStoppedAnimation(
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
                        if (widget.isOwnStory)
                          IconButton(
                            icon: const Icon(
                              Icons.ios_share,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _setPaused(true);
                              Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => StorySharePage(
                                            story: widget.stories[_index],
                                          ),
                                    ),
                                  )
                                  .then((_) => _setPaused(false));
                            },
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
          CachedNetworkImage(
            imageUrl: story.photoUrl!,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder:
                (context, url) => const ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                ),
          )
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
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: switch (story.type) {
              StoryType.weight => _WeightOverlay(story: story),
              StoryType.workout => _WorkoutOverlay(story: story),
              _ => _MealOverlay(story: story),
            },
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

class _WorkoutOverlay extends StatelessWidget {
  final Story story;

  const _WorkoutOverlay({required this.story});

  @override
  Widget build(BuildContext context) {
    final exerciseCount = story.workoutExerciseCount;
    final setCount = story.workoutSetCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💪', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                exerciseCount == null
                    ? 'Workout'
                    : '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}'
                        '${setCount != null ? ' · $setCount sets' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (story.workoutHasPr == true)
                const Text(
                  '🏆 New PR',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
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
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (story.mealName != null)
          Text(
            story.mealName!,
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

/// Lets a user share one of their own stories outside the app — same
/// pattern as [WorkoutSharePage]: preview the card (the story's own visual,
/// plus an app banner asking whoever sees it to join), then hand it to the
/// OS share sheet so it can go to Instagram/WhatsApp/etc.
class StorySharePage extends ConsumerStatefulWidget {
  final Story story;

  const StorySharePage({super.key, required this.story});

  @override
  ConsumerState<StorySharePage> createState() => _StorySharePageState();
}

class _StorySharePageState extends ConsumerState<StorySharePage>
    with ShareCaptureMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share story')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: _StoryShareCard(story: widget.story),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: FilledButton.icon(
                key: shareButtonKey,
                onPressed:
                    sharing
                        ? null
                        : () => shareCapturedImage(
                          fileNamePrefix: 'fitness_buddy_story',
                          text: 'Check out my update on Fitness Buddy 💪',
                        ),
                icon: const Icon(Icons.ios_share),
                label: Text(sharing ? 'Preparing…' : 'Share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryShareCard extends StatelessWidget {
  final Story story;

  const _StoryShareCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 320,
              height: 480,
              child: Stack(
                fit: StackFit.expand,
                children: [_StorySlide(story: story), const AppWatermark()],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: kShareBrandDark,
              child: const AppShareBanner(),
            ),
          ],
        ),
      ),
    );
  }
}
