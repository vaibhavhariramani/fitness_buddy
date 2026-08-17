import 'package:flutter/foundation.dart' show kIsWeb;

/// wger.de serves its exercise photos and muscle diagrams without CORS
/// headers, which blocks them on Flutter Web (canvaskit fetches image bytes
/// via XHR, unlike a plain <img> tag — it needs Access-Control-Allow-Origin
/// to read the response). images.weserv.nl is a free public image proxy
/// that re-serves any public image URL with CORS enabled (and rasterizes
/// SVGs to PNG along the way). Only used on web — native platforms hit wger
/// directly, which also lets cached_network_image's disk cache give real
/// offline access after the first view.
String wgerImageProxyUrl(String originalUrl) {
  if (!kIsWeb) return originalUrl;
  final withoutScheme = originalUrl.replaceFirst(RegExp(r'^https?://'), '');
  return 'https://images.weserv.nl/?url=${Uri.encodeComponent(withoutScheme)}';
}
