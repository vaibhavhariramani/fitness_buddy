import 'package:cloud_firestore/cloud_firestore.dart';

enum StoryType { weight, meal, dailySummary }

StoryType _parseStoryType(String? raw) => StoryType.values.firstWhere(
  (t) => t.name == raw,
  orElse: () => StoryType.dailySummary,
);

/// A 24-hour, WhatsApp/Instagram-style status update — created whenever a
/// weight or meal log gets a photo attached, or generated server-side once a
/// day as a [StoryType.dailySummary] recap. Expiry is enforced both by the
/// client (`StoryRepo.watchActive` filters on [expiresAt]) and by a
/// scheduled Cloud Function that physically deletes the doc afterwards.
class Story {
  final String id;
  final StoryType type;

  /// The uploaded photo — null only for [StoryType.dailySummary], which
  /// renders as a text/stat card instead of a photo. For weight/meal
  /// stories this is the *same* download URL already stored on the
  /// underlying weightLog/meal doc, not a separate upload.
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  // StoryType.weight
  final double? weightKg;

  // StoryType.meal
  final String? mealName;
  final String? mealTypeLabel;
  final double? calories;
  final double? proteinG;
  final double? carbG;
  final double? fatG;

  // StoryType.dailySummary
  final String? displayName;
  final int? streakCount;
  final double? summaryWeightKg;
  final int? summaryMealsCount;
  final double? summaryCaloriesTotal;

  /// Set only on dailySummary docs — the user's local calendar day
  /// ("YYYY-MM-DD" in their own timezone) this summary covers, used by the
  /// Cloud Function to avoid posting a duplicate for the same local day.
  final String? summaryDateKey;

  const Story({
    required this.id,
    required this.type,
    this.photoUrl,
    required this.createdAt,
    required this.expiresAt,
    this.weightKg,
    this.mealName,
    this.mealTypeLabel,
    this.calories,
    this.proteinG,
    this.carbG,
    this.fatG,
    this.displayName,
    this.streakCount,
    this.summaryWeightKg,
    this.summaryMealsCount,
    this.summaryCaloriesTotal,
    this.summaryDateKey,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': Timestamp.fromDate(expiresAt),
    'weightKg': weightKg,
    'mealName': mealName,
    'mealTypeLabel': mealTypeLabel,
    'calories': calories,
    'proteinG': proteinG,
    'carbG': carbG,
    'fatG': fatG,
    'displayName': displayName,
    'streakCount': streakCount,
    'summaryWeightKg': summaryWeightKg,
    'summaryMealsCount': summaryMealsCount,
    'summaryCaloriesTotal': summaryCaloriesTotal,
    'summaryDateKey': summaryDateKey,
  };

  factory Story.fromJson(String id, Map<String, dynamic> json) => Story(
    id: id,
    type: _parseStoryType(json['type'] as String?),
    photoUrl: json['photoUrl'] as String?,
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt: (json['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    mealName: json['mealName'] as String?,
    mealTypeLabel: json['mealTypeLabel'] as String?,
    calories: (json['calories'] as num?)?.toDouble(),
    proteinG: (json['proteinG'] as num?)?.toDouble(),
    carbG: (json['carbG'] as num?)?.toDouble(),
    fatG: (json['fatG'] as num?)?.toDouble(),
    displayName: json['displayName'] as String?,
    streakCount: (json['streakCount'] as num?)?.toInt(),
    summaryWeightKg: (json['summaryWeightKg'] as num?)?.toDouble(),
    summaryMealsCount: (json['summaryMealsCount'] as num?)?.toInt(),
    summaryCaloriesTotal: (json['summaryCaloriesTotal'] as num?)?.toDouble(),
    summaryDateKey: json['summaryDateKey'] as String?,
  );
}
