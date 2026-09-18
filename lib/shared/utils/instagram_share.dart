import 'package:flutter/services.dart';

const _channel = MethodChannel('fitness_buddy/instagram_share');

/// Hands [imageBytes] (a PNG) straight to Instagram's Stories composer via
/// the pasteboard handoff Instagram documents for third-party "share to
/// Stories" buttons — no Instagram API/auth involved. iOS only; returns
/// `false` on every other platform, and on iOS whenever Instagram isn't
/// installed or the handoff otherwise fails, so callers can fall back to
/// the plain OS share sheet.
Future<bool> shareImageToInstagramStories(Uint8List imageBytes) async {
  try {
    final result = await _channel.invokeMethod<bool>('shareToInstagramStories', {
      'image': imageBytes,
    });
    return result ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
