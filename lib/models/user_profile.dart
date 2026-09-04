import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/calculations.dart';

class PrivacySettings {
  final bool shareWeight;
  final bool shareWorkouts;
  final bool shareStreak;

  /// Whether today's meal photos are visible to accepted friends. Unlike the
  /// other flags (which default on for backward compatibility), this
  /// defaults OFF — food photos are more personal than a weight number or a
  /// workout count, so sharing them is opt-in.
  final bool shareMeals;

  /// Whether friends can see this user's 24h stories (weight/meal photos
  /// posted while logging, plus the auto-generated daily summary). On by
  /// default — unlike [shareMeals], stories are ephemeral (24h) and are the
  /// main way friends stay engaged with each other, so it's opt-out.
  final bool shareStories;

  const PrivacySettings({
    this.shareWeight = true,
    this.shareWorkouts = true,
    this.shareStreak = true,
    this.shareMeals = false,
    this.shareStories = true,
  });

  Map<String, dynamic> toJson() => {
    'shareWeight': shareWeight,
    'shareWorkouts': shareWorkouts,
    'shareStreak': shareStreak,
    'shareMeals': shareMeals,
    'shareStories': shareStories,
  };

  factory PrivacySettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrivacySettings();
    return PrivacySettings(
      shareWeight: json['shareWeight'] as bool? ?? true,
      shareWorkouts: json['shareWorkouts'] as bool? ?? true,
      shareStreak: json['shareStreak'] as bool? ?? true,
      shareMeals: json['shareMeals'] as bool? ?? false,
      shareStories: json['shareStories'] as bool? ?? true,
    );
  }
}

/// When each daily reminder should fire, stored as minutes since midnight
/// (local time) so it round-trips through Firestore as a plain int and
/// survives DST shifts the same way a wall-clock time would.
class ReminderSettings {
  final bool enabled;
  final int breakfastMinutes;
  final int lunchMinutes;
  final int workoutMinutes;
  final int dinnerMinutes;
  final bool junkFoodNudgesEnabled;

  const ReminderSettings({
    this.enabled = true,
    this.breakfastMinutes = 11 * 60,
    this.lunchMinutes = 14 * 60,
    this.workoutMinutes = 17 * 60,
    this.dinnerMinutes = 20 * 60,
    this.junkFoodNudgesEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'breakfastMinutes': breakfastMinutes,
    'lunchMinutes': lunchMinutes,
    'workoutMinutes': workoutMinutes,
    'dinnerMinutes': dinnerMinutes,
    'junkFoodNudgesEnabled': junkFoodNudgesEnabled,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReminderSettings();
    const defaults = ReminderSettings();
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? defaults.enabled,
      breakfastMinutes:
          (json['breakfastMinutes'] as num?)?.toInt() ??
          defaults.breakfastMinutes,
      lunchMinutes:
          (json['lunchMinutes'] as num?)?.toInt() ?? defaults.lunchMinutes,
      workoutMinutes:
          (json['workoutMinutes'] as num?)?.toInt() ?? defaults.workoutMinutes,
      dinnerMinutes:
          (json['dinnerMinutes'] as num?)?.toInt() ?? defaults.dinnerMinutes,
      junkFoodNudgesEnabled:
          json['junkFoodNudgesEnabled'] as bool? ??
          defaults.junkFoodNudgesEnabled,
    );
  }

  ReminderSettings copyWith({
    bool? enabled,
    int? breakfastMinutes,
    int? lunchMinutes,
    int? workoutMinutes,
    int? dinnerMinutes,
    bool? junkFoodNudgesEnabled,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      breakfastMinutes: breakfastMinutes ?? this.breakfastMinutes,
      lunchMinutes: lunchMinutes ?? this.lunchMinutes,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      dinnerMinutes: dinnerMinutes ?? this.dinnerMinutes,
      junkFoodNudgesEnabled:
          junkFoodNudgesEnabled ?? this.junkFoodNudgesEnabled,
    );
  }
}

/// A minimal, broadly-readable record used only for "find a friend by
/// email" lookups. Kept separate from the full [UserProfile] because
/// Firestore security rules can't scope a collection query field-by-field —
/// letting anyone query `users` directly to find an email match would force
/// the entire profile (weight, macros, streak, privacy...) to be world
/// readable. This directory doc exposes just uid/displayName/email instead.
class UserDirectoryEntry {
  final String uid;
  final String displayName;
  final String email;

  const UserDirectoryEntry({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  Map<String, dynamic> toJson() => {'displayName': displayName, 'email': email};

  factory UserDirectoryEntry.fromJson(String uid, Map<String, dynamic> json) =>
      UserDirectoryEntry(
        uid: uid,
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );
}

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final int age;
  final Gender gender;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
  final double bmi;
  final BmiCategory bmiCategory;
  final double tdee;
  final CalorieTargets calorieTargets;
  final Macros macros;
  final NutritionGoal nutritionGoal;
  final double? customCalorieTarget;
  final double? customProteinG;
  final double? customCarbG;
  final double? customFatG;
  final int streakCount;
  final DateTime? lastLogDate;
  final PrivacySettings privacy;
  final ReminderSettings reminders;

  /// IANA timezone name (e.g. "Asia/Kolkata"), captured from the device on
  /// sign-in — used server-side to post the daily-summary story at this
  /// user's own local 11pm rather than a fixed reference time.
  final String? timezone;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.bmi,
    required this.bmiCategory,
    required this.tdee,
    required this.calorieTargets,
    required this.macros,
    this.nutritionGoal = NutritionGoal.maintain,
    this.customCalorieTarget,
    this.customProteinG,
    this.customCarbG,
    this.customFatG,
    this.streakCount = 0,
    this.lastLogDate,
    this.privacy = const PrivacySettings(),
    this.reminders = const ReminderSettings(),
    this.timezone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'age': age,
    'gender': gender.name,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'activityLevel': activityLevel.name,
    'bmi': bmi,
    'bmiCategory': bmiCategory.name,
    'tdee': tdee,
    'calorieTargets': calorieTargets.toJson(),
    'macros': macros.toJson(),
    'nutritionGoal': nutritionGoal.name,
    'customCalorieTarget': customCalorieTarget,
    'customProteinG': customProteinG,
    'customCarbG': customCarbG,
    'customFatG': customFatG,
    'streakCount': streakCount,
    'lastLogDate':
        lastLogDate == null ? null : Timestamp.fromDate(lastLogDate!),
    'privacy': privacy.toJson(),
    'reminders': reminders.toJson(),
    'timezone': timezone,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory UserProfile.fromJson(String uid, Map<String, dynamic> json) {
    return UserProfile(
      uid: uid,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: Gender.values.firstWhere(
        (g) => g.name == json['gender'],
        orElse: () => Gender.male,
      ),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 0,
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
      activityLevel: ActivityLevel.values.firstWhere(
        (a) => a.name == json['activityLevel'],
        orElse: () => ActivityLevel.sedentary,
      ),
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0,
      bmiCategory: BmiCategory.values.firstWhere(
        (c) => c.name == json['bmiCategory'],
        orElse: () => BmiCategory.normal,
      ),
      tdee: (json['tdee'] as num?)?.toDouble() ?? 0,
      calorieTargets: CalorieTargets.fromJson(
        Map<String, dynamic>.from(json['calorieTargets'] as Map? ?? {}),
      ),
      macros: Macros.fromJson(
        Map<String, dynamic>.from(json['macros'] as Map? ?? {}),
      ),
      nutritionGoal: NutritionGoal.values.firstWhere(
        (g) => g.name == json['nutritionGoal'],
        orElse: () => NutritionGoal.maintain,
      ),
      customCalorieTarget: (json['customCalorieTarget'] as num?)?.toDouble(),
      customProteinG: (json['customProteinG'] as num?)?.toDouble(),
      customCarbG: (json['customCarbG'] as num?)?.toDouble(),
      customFatG: (json['customFatG'] as num?)?.toDouble(),
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      lastLogDate: (json['lastLogDate'] as Timestamp?)?.toDate(),
      privacy: PrivacySettings.fromJson(
        json['privacy'] == null
            ? null
            : Map<String, dynamic>.from(json['privacy'] as Map),
      ),
      reminders: ReminderSettings.fromJson(
        json['reminders'] == null
            ? null
            : Map<String, dynamic>.from(json['reminders'] as Map),
      ),
      timezone: json['timezone'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    double? bmi,
    BmiCategory? bmiCategory,
    double? tdee,
    CalorieTargets? calorieTargets,
    Macros? macros,
    NutritionGoal? nutritionGoal,
    double? customCalorieTarget,
    double? customProteinG,
    double? customCarbG,
    double? customFatG,
    int? streakCount,
    DateTime? lastLogDate,
    PrivacySettings? privacy,
    ReminderSettings? reminders,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      bmi: bmi ?? this.bmi,
      bmiCategory: bmiCategory ?? this.bmiCategory,
      tdee: tdee ?? this.tdee,
      calorieTargets: calorieTargets ?? this.calorieTargets,
      macros: macros ?? this.macros,
      nutritionGoal: nutritionGoal ?? this.nutritionGoal,
      customCalorieTarget: customCalorieTarget ?? this.customCalorieTarget,
      customProteinG: customProteinG ?? this.customProteinG,
      customCarbG: customCarbG ?? this.customCarbG,
      customFatG: customFatG ?? this.customFatG,
      streakCount: streakCount ?? this.streakCount,
      lastLogDate: lastLogDate ?? this.lastLogDate,
      privacy: privacy ?? this.privacy,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt,
    );
  }
}
