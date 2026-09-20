import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The dark-green brand color behind every shareable card's chrome (badges,
/// gradient start).
const kShareBrandDark = Color(0xFF16321A);

/// A faint, oversized app logo mark bleeding off the bottom-right corner —
/// a subtle watermark so a shared card still reads as "Fitness Buddy" even
/// if it gets re-shared or screenshotted standalone. A direct child of a
/// [Stack] (it positions itself).
class AppWatermark extends StatelessWidget {
  const AppWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
    );
  }
}

/// The app-icon-and-download-CTA footer shown at the bottom of every
/// shareable card (workout, story, ...) — tells whoever sees the shared
/// image what to search for to join, since neither Instagram nor WhatsApp
/// carry a link back to the app automatically.
class AppShareBanner extends StatelessWidget {
  const AppShareBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
            StoreBadge(icon: Icons.apple, label: 'App Store'),
            SizedBox(width: 8),
            StoreBadge(icon: Icons.shop_outlined, label: 'Google Play'),
          ],
        ),
      ],
    );
  }
}

/// A minimal, non-trademarked stand-in for an app-store badge — an icon plus
/// the store's name in a pill — since we don't ship Apple's/Google's actual
/// badge artwork (those come with their own usage/branding guidelines) but
/// still want to tell whoever sees the share card which stores to search.
class StoreBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const StoreBadge({super.key, required this.icon, required this.label});

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
          Icon(icon, size: 14, color: kShareBrandDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: kShareBrandDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
