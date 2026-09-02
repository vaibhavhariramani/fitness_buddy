/// The selectable reminder sounds — deliberately a small, explicit list
/// (not a folder scan) so every entry is something we've actually bundled
/// and verified, never a silently-broken selection.
///
/// [androidRawResource] must match a file (any extension) placed at
/// `android/app/src/main/res/raw/<name>.*`, referenced without the
/// extension. [iosSoundFile] must match a sound file (with extension)
/// added as a bundled resource in the iOS Xcode project. Leaving both null
/// means "use the platform's own default alarm/notification sound."
class WellnessSound {
  final String id;
  final String label;
  final String? androidRawResource;
  final String? iosSoundFile;

  const WellnessSound({
    required this.id,
    required this.label,
    this.androidRawResource,
    this.iosSoundFile,
  });
}

const wellnessSounds = [
  WellnessSound(id: 'default', label: 'Default'),
  // Android: bundled at android/app/src/main/res/raw/gayatri_mantra.mp3 —
  // MP3 is natively supported there, no conversion needed.
  // iOS: left unset (falls back to the platform default sound) — iOS only
  // accepts aiff/wav/caf for notification sounds, not mp3, so the source
  // file needs converting and adding as an Xcode bundle resource on a Mac
  // before this can point at one there too.
  WellnessSound(
    id: 'gayatri_mantra',
    label: 'Gayatri Mantra',
    androidRawResource: 'gayatri_mantra',
  ),
];

WellnessSound wellnessSoundById(String id) => wellnessSounds.firstWhere(
  (s) => s.id == id,
  orElse: () => wellnessSounds.first,
);
