/// Maps each exercise id (assets/data/exercises.json) to a pose key in
/// exercise_pose_svgs.dart. Exercises sharing a movement pattern share a
/// pictogram — kept as a code-level presentation mapping, separate from the
/// factual exercise data.
const Map<String, String> exercisePoseByExerciseId = {
  // Chest
  'barbell-bench-press': 'bench_press',
  'dumbbell-bench-press': 'bench_press',
  'incline-barbell-bench-press': 'incline_press',
  'incline-dumbbell-press': 'incline_press',
  'push-up': 'pushup',
  'chest-dip': 'dip',
  'cable-chest-fly': 'fly',
  'dumbbell-fly': 'fly',
  'machine-chest-press': 'bench_press',
  'pec-deck-fly': 'fly',

  // Back
  'deadlift': 'deadlift',
  'pull-up': 'pullup',
  'lat-pulldown': 'lat_pulldown',
  'barbell-bent-over-row': 'row',
  'dumbbell-row': 'row',
  'seated-cable-row': 'row',
  't-bar-row': 'row',
  'chin-up': 'pullup',
  'face-pull': 'face_pull',
  'straight-arm-pulldown': 'lat_pulldown',

  // Shoulders
  'overhead-barbell-press': 'overhead_press',
  'dumbbell-shoulder-press': 'overhead_press',
  'arnold-press': 'overhead_press',
  'lateral-raise': 'raise_arms',
  'front-raise': 'raise_arms',
  'rear-delt-fly': 'raise_arms',
  'cable-lateral-raise': 'raise_arms',
  'upright-row': 'upright_row',
  'machine-shoulder-press': 'overhead_press',
  'band-pull-apart': 'band_pull_apart',

  // Legs
  'barbell-back-squat': 'squat',
  'front-squat': 'squat',
  'leg-press': 'leg_press',
  'romanian-deadlift': 'deadlift',
  'walking-lunge': 'lunge',
  'bulgarian-split-squat': 'lunge',
  'leg-extension': 'leg_extension',
  'leg-curl': 'leg_curl',
  'goblet-squat': 'squat',
  'standing-calf-raise': 'calf_raise',
  'hip-thrust': 'hip_thrust',
  'kettlebell-swing': 'kettlebell_swing',

  // Arms
  'barbell-bicep-curl': 'curl',
  'dumbbell-bicep-curl': 'curl',
  'hammer-curl': 'curl',
  'cable-bicep-curl': 'curl',
  'concentration-curl': 'curl',
  'triceps-pushdown': 'triceps_extension',
  'skull-crusher': 'triceps_extension',
  'overhead-triceps-extension': 'triceps_extension',
  'close-grip-bench-press': 'bench_press',
  'bench-dip': 'dip',

  // Core
  'plank': 'plank',
  'side-plank': 'plank',
  'crunch': 'crunch',
  'bicycle-crunch': 'crunch',
  'hanging-leg-raise': 'leg_raise',
  'russian-twist': 'twist',
  'cable-woodchopper': 'woodchopper',
  'ab-wheel-rollout': 'ab_wheel',
  'mountain-climber': 'mountain_climber',
  'dead-bug': 'dead_bug',

  // Cardio
  'jumping-jacks': 'jumping_jack',
  'burpees': 'burpee',
  'jump-rope': 'jumping_jack',
  'high-knees': 'running',
  'box-jump': 'squat',
  'rowing-machine': 'rowing_machine',
  'battle-ropes': 'battle_ropes',
  'step-up': 'step_up',
};
