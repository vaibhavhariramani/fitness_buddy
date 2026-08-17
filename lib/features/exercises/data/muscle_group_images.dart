/// Real body-diagram illustrations from wger.de (a highlighted-muscle
/// silhouette per muscle group), used for the "muscle worked" visual on the
/// exercise detail page and the Muscle Reports cards. One representative
/// muscle per broad category — e.g. "Legs" shows the quadriceps diagram.
/// "Cardio"/"Full body" have no single representative muscle and are
/// intentionally omitted (callers should fall back to the category icon).
const Map<String, String> muscleGroupImageUrls = {
  'Chest':
      'https://wger.de/static/images/muscles/main/muscle-4.c9fa9a228bc8.svg',
  'Back':
      'https://wger.de/static/images/muscles/main/muscle-12.6a5de7a0e373.svg',
  'Shoulders':
      'https://wger.de/static/images/muscles/main/muscle-2.e1e1205a3202.svg',
  'Legs':
      'https://wger.de/static/images/muscles/main/muscle-10.b1445ea1acf6.svg',
  'Arms':
      'https://wger.de/static/images/muscles/main/muscle-1.8790f8a0b3b9.svg',
  'Core':
      'https://wger.de/static/images/muscles/main/muscle-6.592f938fa8c7.svg',
};
