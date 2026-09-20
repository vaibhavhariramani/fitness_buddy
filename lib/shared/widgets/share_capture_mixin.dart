import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures whatever's wrapped in a [RepaintBoundary] keyed with
/// [boundaryKey] as a PNG and hands it to the OS share sheet — the shared
/// flow behind every "Share ___" screen in the app (workouts, stories, ...).
///
/// [shareButtonKey] must be attached to the button that triggers the share:
/// iOS (even on iPhone, on some OS versions) requires a non-empty
/// sharePositionOrigin popover anchor, or share_plus's platform channel
/// throws before ever presenting anything.
mixin ShareCaptureMixin<T extends StatefulWidget> on State<T> {
  final boundaryKey = GlobalKey();
  final shareButtonKey = GlobalKey();
  bool sharing = false;

  Future<void> shareCapturedImage({
    required String fileNamePrefix,
    required String text,
  }) async {
    setState(() => sharing = true);
    try {
      // A frame to let any just-added content (e.g. a picked photo) paint
      // before capture.
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final buttonBox =
          shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          buttonBox != null
              ? buttonBox.localToGlobal(Offset.zero) & buttonBox.size
              : null;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
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
      if (mounted) setState(() => sharing = false);
    }
  }
}
