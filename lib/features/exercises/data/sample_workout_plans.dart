import '../models/workout_plan_template.dart';

const sampleWorkoutPlans = <WorkoutPlanTemplate>[
  WorkoutPlanTemplate(
    id: 'push-day',
    name: 'Push Day',
    focus: 'Chest, Shoulders, Triceps',
    exercises: [
      PlannedExerciseTemplate(
        exerciseId: 'barbell-bench-press',
        sets: 4,
        targetReps: 8,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'incline-dumbbell-press',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'overhead-barbell-press',
        sets: 3,
        targetReps: 8,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'lateral-raise',
        sets: 3,
        targetReps: 15,
      ),
      PlannedExerciseTemplate(exerciseId: 'chest-dip', sets: 3, targetReps: 10),
      PlannedExerciseTemplate(
        exerciseId: 'triceps-pushdown',
        sets: 3,
        targetReps: 12,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'pull-day',
    name: 'Pull Day',
    focus: 'Back, Biceps',
    exercises: [
      PlannedExerciseTemplate(exerciseId: 'deadlift', sets: 3, targetReps: 5),
      PlannedExerciseTemplate(exerciseId: 'pull-up', sets: 4, targetReps: 8),
      PlannedExerciseTemplate(
        exerciseId: 'seated-cable-row',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'barbell-bent-over-row',
        sets: 3,
        targetReps: 8,
      ),
      PlannedExerciseTemplate(exerciseId: 'face-pull', sets: 3, targetReps: 15),
      PlannedExerciseTemplate(
        exerciseId: 'dumbbell-bicep-curl',
        sets: 3,
        targetReps: 12,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'leg-day',
    name: 'Leg Day',
    focus: 'Quads, Hamstrings, Glutes, Calves',
    exercises: [
      PlannedExerciseTemplate(
        exerciseId: 'barbell-back-squat',
        sets: 4,
        targetReps: 6,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'romanian-deadlift',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(exerciseId: 'leg-press', sets: 3, targetReps: 12),
      PlannedExerciseTemplate(
        exerciseId: 'leg-extension',
        sets: 3,
        targetReps: 15,
      ),
      PlannedExerciseTemplate(exerciseId: 'leg-curl', sets: 3, targetReps: 12),
      PlannedExerciseTemplate(
        exerciseId: 'standing-calf-raise',
        sets: 4,
        targetReps: 15,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'upper-body',
    name: 'Upper Body',
    focus: 'Chest, Back, Shoulders, Arms',
    exercises: [
      PlannedExerciseTemplate(
        exerciseId: 'dumbbell-bench-press',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'seated-cable-row',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'dumbbell-shoulder-press',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'lat-pulldown',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'dumbbell-bicep-curl',
        sets: 2,
        targetReps: 12,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'triceps-pushdown',
        sets: 2,
        targetReps: 12,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'lower-body',
    name: 'Lower Body',
    focus: 'Legs, Glutes, Core',
    exercises: [
      PlannedExerciseTemplate(
        exerciseId: 'goblet-squat',
        sets: 3,
        targetReps: 12,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'romanian-deadlift',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'walking-lunge',
        sets: 3,
        targetReps: 12,
      ),
      PlannedExerciseTemplate(exerciseId: 'leg-curl', sets: 3, targetReps: 12),
      PlannedExerciseTemplate(
        exerciseId: 'hip-thrust',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'standing-calf-raise',
        sets: 3,
        targetReps: 15,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'beginner-full-body',
    name: 'Beginner Full Body',
    focus: 'Full Body',
    exercises: [
      PlannedExerciseTemplate(exerciseId: 'push-up', sets: 3, targetReps: 10),
      PlannedExerciseTemplate(
        exerciseId: 'dumbbell-row',
        sets: 3,
        targetReps: 10,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'goblet-squat',
        sets: 3,
        targetReps: 12,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'plank',
        sets: 3,
        targetReps: 30,
        isTimed: true,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'band-pull-apart',
        sets: 2,
        targetReps: 15,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'jumping-jacks',
        sets: 3,
        targetReps: 30,
        isTimed: true,
      ),
    ],
  ),
  WorkoutPlanTemplate(
    id: 'core-cardio-finisher',
    name: 'Core & Cardio Finisher',
    focus: 'Core, Conditioning',
    exercises: [
      PlannedExerciseTemplate(
        exerciseId: 'plank',
        sets: 3,
        targetReps: 45,
        isTimed: true,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'russian-twist',
        sets: 3,
        targetReps: 20,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'mountain-climber',
        sets: 3,
        targetReps: 30,
        isTimed: true,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'bicycle-crunch',
        sets: 3,
        targetReps: 20,
      ),
      PlannedExerciseTemplate(
        exerciseId: 'high-knees',
        sets: 3,
        targetReps: 30,
        isTimed: true,
      ),
    ],
  ),
];
