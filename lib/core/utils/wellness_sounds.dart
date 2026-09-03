/// The selectable reminder sounds — deliberately a small, explicit list
/// (not a folder scan) so every entry is something we've actually bundled
/// and verified, never a silently-broken selection.
///
/// [androidRawResource] must match a file (any extension) placed at
/// `android/app/src/main/res/raw/<name>.*`, referenced without the
/// extension — used for real Android notification/alarm sounds via
/// flutter_local_notifications. [iosSoundFile] must match a sound file
/// (with extension) added as a bundled resource in the iOS Xcode project,
/// same purpose on iOS. [flutterAssetPath] is a normal Flutter asset (see
/// pubspec.yaml's assets: list) played back with the audioplayers package —
/// the only mechanism that works on Web, since
/// flutter_local_notifications has no Web implementation at all and
/// browsers can't be scheduled to wake up and play a platform notification
/// sound the way a native OS can. Leaving a field null means "no sound
/// available for that mechanism"; leaving all three null means "use the
/// platform's own default sound" (or, on Web, no sound — see
/// NotificationService's web reminder polling).
class WellnessSound {
  final String id;
  final String label;
  final String? androidRawResource;
  final String? iosSoundFile;
  final String? flutterAssetPath;

  const WellnessSound({
    required this.id,
    required this.label,
    this.androidRawResource,
    this.iosSoundFile,
    this.flutterAssetPath,
  });
}

const wellnessSounds = [
  WellnessSound(id: 'default', label: 'Default'),
  // Android: bundled at android/app/src/main/res/raw/gayatri_mantra.mp3 —
  // MP3 is natively supported there, no conversion needed.
  // iOS: bundled at ios/Runner/gayatri_mantra.caf (converted from the mp3
  // via `afconvert -f caff -d ima4`, added to the Runner target's Copy
  // Bundle Resources) — iOS only accepts aiff/wav/caf for notification
  // sounds, not mp3, and rejects (silently falls back to default) anything
  // over 30s; this track is ~14s so no trimming was needed.
  // flutterAssetPath: also bundled at assets/sounds/gayatri_mantra.mp3 (a
  // second copy, registered in pubspec.yaml) for the Web playback path.
  WellnessSound(
    id: 'gayatri_mantra',
    label: 'Gayatri Mantra',
    androidRawResource: 'gayatri_mantra',
    iosSoundFile: 'gayatri_mantra.caf',
    flutterAssetPath: 'sounds/gayatri_mantra.mp3',
  ),
];

WellnessSound wellnessSoundById(String id) => wellnessSounds.firstWhere(
  (s) => s.id == id,
  orElse: () => wellnessSounds.first,
);
