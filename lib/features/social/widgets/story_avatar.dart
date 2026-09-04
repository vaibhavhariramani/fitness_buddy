import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/providers.dart';
import '../../../models/story.dart';
import '../stories/story_viewer_page.dart';

/// URLs already handed to [precacheImage] this session — a plain top-level
/// set (not per-widget state) so re-mounting the avatar (e.g. scrolling the
/// stories bar off-screen and back) doesn't re-trigger a fetch Flutter's own
/// image cache has already satisfied.
final _precachedStoryUrls = <String>{};

/// Kicks off (fire-and-forget) downloading every story photo in [stories]
/// as soon as their existence is known — typically while the stories bar is
/// just sitting on screen, well before the user taps an avatar — so the
/// full-screen viewer has the image ready instead of showing a black
/// background while it downloads.
void _precacheStoryPhotos(List<Story> stories, BuildContext context) {
  for (final story in stories) {
    final url = story.photoUrl;
    if (url == null || !_precachedStoryUrls.add(url)) continue;
    precacheImage(CachedNetworkImageProvider(url), context);
  }
}

/// Active (unexpired) stories for a given uid — shared by [StoryAvatar] and
/// anything else that needs to know whether someone currently has a story.
final activeStoriesProvider = StreamProvider.autoDispose
    .family<List<Story>, String>(
      (ref, uid) => ref.watch(storyRepoProvider).watchActive(uid),
    );

/// A circle avatar that grows a gradient "story ring" (WhatsApp/Instagram
/// style) whenever [uid] has an active story, and opens the full-screen
/// viewer on tap.
class StoryAvatar extends ConsumerWidget {
  final String uid;
  final String displayName;
  final double radius;

  const StoryAvatar({
    super.key,
    required this.uid,
    required this.displayName,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stories =
        ref.watch(activeStoriesProvider(uid)).valueOrNull ?? const [];
    final hasActive = stories.isNotEmpty;
    if (hasActive) _precacheStoryPhotos(stories, context);

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        (displayName.isNotEmpty ? displayName[0] : '?').toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return GestureDetector(
      onTap:
          hasActive
              ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => StoryViewerPage(
                        stories: stories,
                        ownerName: displayName,
                      ),
                ),
              )
              : null,
      child: Container(
        padding: EdgeInsets.all(hasActive ? 2.5 : 0),
        decoration:
            hasActive
                ? const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.nutrition,
                      AppColors.achievement,
                      AppColors.recovery,
                    ],
                  ),
                )
                : null,
        child: Container(
          padding: EdgeInsets.all(hasActive ? 2 : 0),
          decoration:
              hasActive
                  ? BoxDecoration(shape: BoxShape.circle, color: scheme.surface)
                  : null,
          child: avatar,
        ),
      ),
    );
  }
}
