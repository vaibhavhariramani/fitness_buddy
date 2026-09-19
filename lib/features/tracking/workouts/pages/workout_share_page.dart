import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../models/workout_entry.dart';
import '../../../../shared/utils/photo_picker.dart';
import '../../../../shared/widgets/muscle_body_diagram.dart';
import '../../../exercises/providers/exercise_providers.dart';
import '../../../exercises/widgets/add_to_workout_dialog.dart'
    show resolveMuscleGroup;

/// Renders a finished workout as a shareable card — a muscle-group body
/// diagram, exercises, PR callout, and an app banner inviting whoever sees
/// it to sign up — then hands it to the OS share sheet, which is what
/// actually gets it into Instagram/WhatsApp: neither platform has a public
/// API this app can call directly, but both register themselves in the
/// share sheet for an image + text payload, same as Strava's own share
/// button relies on.
class WorkoutSharePage extends ConsumerStatefulWidget {
  final WorkoutEntry entry;

  const WorkoutSharePage({super.key, required this.entry});

  @override
  ConsumerState<WorkoutSharePage> createState() => _WorkoutSharePageState();
}

class _WorkoutSharePageState extends ConsumerState<WorkoutSharePage> {
  final _boundaryKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  Uint8List? _photoBytes;
  bool _sharing = false;

  Future<void> _pickPhoto() async {
    final bytes = await pickPhotoFromCameraOrGallery(context);
    if (bytes == null) return;
    setState(() => _photoBytes = bytes);
  }

  Future<Uint8List> _captureImage() async {
    // A frame to let the just-added photo actually paint before capture.
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _captureImage();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/fitness_buddy_workout_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      // iOS (even on iPhone, on some OS versions) requires a non-empty
      // sharePositionOrigin — the share sheet's popover anchor — or
      // share_plus's platform channel throws before ever presenting
      // anything. Anchor it to the Share button itself.
      final buttonBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          buttonBox != null
              ? buttonBox.localToGlobal(Offset.zero) & buttonBox.size
              : null;

      final hasPr = widget.entry.exercises.any((e) => e.isPr);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            hasPr
                ? 'New PR on Fitness Buddy 🏆'
                : 'Just finished a workout on Fitness Buddy 💪',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      // Surface failures instead of letting them vanish silently — an
      // unawaited/uncaught error here otherwise just resets the button with
      // no visible sign anything went wrong.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Couldn\'t share: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final prExercises = entry.exercises.where((e) => e.isPr).toList();
    final totalSets = entry.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.length,
    );

    final setsByGroup = <String, int>{};
    for (final e in entry.exercises) {
      final catalogExercise =
          e.exerciseId == null
              ? null
              : ref.watch(exerciseByIdProvider(e.exerciseId!));
      final group = resolveMuscleGroup(catalogExercise, e.muscleGroup);
      setsByGroup[group] = (setsByGroup[group] ?? 0) + e.sets.length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Share workout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: _ShareCard(
                      entry: entry,
                      prExercises: prExercises,
                      totalSets: totalSets,
                      setsByGroup: setsByGroup,
                      photoBytes: _photoBytes,
                    ),
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
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _sharing ? null : _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _photoBytes == null
                          ? 'Add photo from gallery'
                          : 'Change photo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: _shareButtonKey,
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.ios_share),
                    label: Text(_sharing ? 'Preparing…' : 'Share'),
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

class _ShareCard extends StatelessWidget {
  final WorkoutEntry entry;
  final List<ExerciseLog> prExercises;
  final int totalSets;
  final Map<String, int> setsByGroup;
  final Uint8List? photoBytes;

  const _ShareCard({
    required this.entry,
    required this.prExercises,
    required this.totalSets,
    required this.setsByGroup,
    this.photoBytes,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 360,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16321A), Color(0xFF2E7D32)],
          ),
        ),
        child: Stack(
          children: [
            // A faint, oversized logo mark bleeding off the bottom-right
            // corner — a subtle watermark so the card still reads as
            // "Fitness Buddy" even if it gets re-shared or screenshotted
            // without the app banner below.
            Positioned(
              right: -40,
              bottom: -40,
              child: Opacity(
                opacity: 0.08,
                child: SvgPicture.asset(
                  'assets/branding/logo_mark.svg',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        photoBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (prExercises.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '🏆 NEW PR',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Workout Complete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.exercises.length} exercises · $totalSets sets',
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    // Scoped color overrides so the body diagram reads
                    // clearly on a dark gradient regardless of the app's own
                    // light/dark theme — MuscleBodyDiagram always paints
                    // from the ambient ColorScheme.
                    child: Theme(
                      data: ThemeData(
                        colorScheme: const ColorScheme.dark(
                          surfaceContainerHighest: Color(0x33FFFFFF),
                          outlineVariant: Color(0x66FFFFFF),
                          primary: Color(0xFFFFC107),
                        ),
                      ),
                      child: MuscleBodyDiagram(
                        trainedSets: setsByGroup,
                        height: 220,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in entry.exercises.take(6))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            e.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SvgPicture.asset(
                          'assets/branding/logo.svg',
                          width: 28,
                          height: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Fitness Buddy — join me and become workout buddies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search "Fitness Buddy" to download',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      _StoreBadge(icon: Icons.apple, label: 'App Store'),
                      SizedBox(width: 8),
                      _StoreBadge(
                        icon: Icons.shop_outlined,
                        label: 'Google Play',
                      ),
                    ],
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

/// A minimal, non-trademarked stand-in for an app-store badge — an icon plus
/// the store's name in a pill — since we don't ship Apple's/Google's actual
/// badge artwork (those come with their own usage/branding guidelines) but
/// still want to tell whoever sees the share card which stores to search.
class _StoreBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StoreBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF16321A)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF16321A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
