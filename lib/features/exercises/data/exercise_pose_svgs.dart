/// Original, hand-drawn stick-figure pictograms representing exercise
/// movement patterns. Rendered in-memory via SvgPicture.string — no network
/// calls, no bundled asset files, no third-party art or licensing concerns.
/// Each shares a 100x100 viewBox and a consistent stroke style so they tint
/// cleanly to any category color via a ColorFilter.
const _headR = 7;

String _svg(String body) =>
    '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">'
    '<g fill="none" stroke="currentColor" stroke-width="6" stroke-linecap="round" stroke-linejoin="round">'
    '$body'
    '</g></svg>';

String _head(double cx, double cy) =>
    '<circle cx="$cx" cy="$cy" r="$_headR" fill="currentColor"/>';

final Map<String, String> exercisePoseSvgs = {
  'bench_press': _svg(
    '${_head(15, 68)}'
    '<path d="M22,68 L60,68"/>'
    '<path d="M60,68 L68,85 L80,80"/>'
    '<path d="M35,68 L35,40"/>'
    '<path d="M50,68 L50,40"/>'
    '<path d="M25,40 L60,40"/>',
  ),
  'incline_press': _svg(
    '${_head(18, 55)}'
    '<path d="M25,60 L58,75"/>'
    '<path d="M58,75 L66,90 L78,86"/>'
    '<path d="M35,66 L38,35"/>'
    '<path d="M45,70 L48,35"/>'
    '<path d="M28,35 L58,35"/>',
  ),
  'fly': _svg(
    '${_head(15, 68)}'
    '<path d="M22,68 L58,68"/>'
    '<path d="M35,68 L20,45"/>'
    '<path d="M45,68 L60,45"/>'
    '<path d="M58,68 L66,85 L78,80"/>',
  ),
  'pushup': _svg(
    '${_head(15, 45)}'
    '<path d="M22,45 L85,60"/>'
    '<path d="M35,50 L35,75"/>',
  ),
  'dip': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,55"/>'
    '<path d="M38,30 L38,70"/>'
    '<path d="M62,30 L62,70"/>'
    '<path d="M40,35 L40,60"/>'
    '<path d="M60,35 L60,60"/>'
    '<path d="M50,55 L45,75 L40,85"/>',
  ),
  'deadlift': _svg(
    '${_head(35, 25)}'
    '<path d="M35,32 L55,55"/>'
    '<path d="M45,45 L45,75"/>'
    '<path d="M35,75 L60,75"/>'
    '<path d="M55,55 L58,80 L58,95"/>',
  ),
  'pullup': _svg(
    '<path d="M30,10 L70,10"/>'
    '<path d="M35,10 L45,30"/>'
    '<path d="M65,10 L55,30"/>'
    '${_head(50, 35)}'
    '<path d="M50,42 L50,65"/>'
    '<path d="M50,65 L45,85 L45,95"/>',
  ),
  'row': _svg(
    '${_head(30, 25)}'
    '<path d="M30,32 L50,55"/>'
    '<path d="M50,55 L55,80 L55,95"/>'
    '<path d="M40,45 L60,40"/>'
    '<circle cx="62" cy="40" r="3" fill="currentColor"/>',
  ),
  'lat_pulldown': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,55"/>'
    '<path d="M25,10 L75,10"/>'
    '<path d="M50,30 L25,10"/>'
    '<path d="M50,30 L75,10"/>'
    '<path d="M50,55 L40,70 L40,85"/>'
    '<path d="M50,55 L60,70 L60,85"/>',
  ),
  'face_pull': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,35 L25,30"/>'
    '<path d="M50,35 L75,30"/>'
    '<path d="M50,60 L45,85"/>'
    '<path d="M50,60 L55,85"/>',
  ),
  'overhead_press': _svg(
    '${_head(50, 30)}'
    '<path d="M50,37 L50,65"/>'
    '<path d="M35,10 L65,10"/>'
    '<path d="M50,40 L35,10"/>'
    '<path d="M50,40 L65,10"/>'
    '<path d="M50,65 L45,90"/>'
    '<path d="M50,65 L55,90"/>',
  ),
  'raise_arms': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,35 L25,35"/>'
    '<path d="M50,35 L75,35"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
  'upright_row': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,40 L46,15"/>'
    '<path d="M50,40 L54,15"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
  'band_pull_apart': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,32 L20,32"/>'
    '<path d="M50,32 L80,32"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
  'squat': _svg(
    '${_head(50, 15)}'
    '<path d="M30,22 L70,22"/>'
    '<path d="M50,25 L50,45"/>'
    '<path d="M50,45 L35,60 L35,85"/>'
    '<path d="M50,45 L65,60 L65,85"/>',
  ),
  'leg_press': _svg(
    '${_head(20, 55)}'
    '<path d="M27,55 L50,65"/>'
    '<path d="M50,65 L75,55 L90,55"/>'
    '<path d="M85,40 L85,70"/>',
  ),
  'lunge': _svg(
    '${_head(45, 20)}'
    '<path d="M45,27 L48,55"/>'
    '<path d="M48,55 L60,65 L60,85"/>'
    '<path d="M48,55 L35,75 L30,90"/>',
  ),
  'step_up': _svg(
    '<path d="M60,70 L85,70 L85,90 L60,90"/>'
    '${_head(35, 30)}'
    '<path d="M35,37 L45,55"/>'
    '<path d="M45,55 L65,60 L65,70"/>'
    '<path d="M45,55 L35,75 L30,90"/>',
  ),
  'leg_extension': _svg(
    '${_head(20, 25)}'
    '<path d="M25,25 L45,55"/>'
    '<path d="M45,55 L65,55"/>'
    '<path d="M65,55 L85,45"/>',
  ),
  'leg_curl': _svg(
    '${_head(15, 30)}'
    '<path d="M22,32 L60,32"/>'
    '<path d="M60,32 L75,32"/>'
    '<path d="M75,32 L80,15"/>',
  ),
  'calf_raise': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,55"/>'
    '<path d="M50,55 L45,80 L48,88"/>'
    '<path d="M50,55 L55,80 L52,88"/>',
  ),
  'hip_thrust': _svg(
    '${_head(20, 50)}'
    '<path d="M25,50 L45,50"/>'
    '<path d="M45,50 L60,35 L75,50"/>'
    '<path d="M75,50 L75,70"/>',
  ),
  'kettlebell_swing': _svg(
    '${_head(45, 25)}'
    '<path d="M45,32 L55,55"/>'
    '<path d="M50,45 L50,70"/>'
    '<circle cx="50" cy="76" r="6"/>'
    '<path d="M55,55 L58,80 L58,95"/>',
  ),
  'curl': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,35 L35,40"/>'
    '<path d="M35,40 L30,20"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
  'triceps_extension': _svg(
    '${_head(50, 25)}'
    '<path d="M50,32 L50,60"/>'
    '<path d="M50,35 L60,15"/>'
    '<path d="M60,15 L50,25"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
  'plank': _svg(
    '${_head(15, 45)}'
    '<path d="M22,45 L85,50"/>'
    '<path d="M30,50 L30,65"/>',
  ),
  'ab_wheel': _svg(
    '${_head(30, 30)}'
    '<path d="M30,37 L40,55"/>'
    '<path d="M40,55 L42,85"/>'
    '<path d="M35,45 L75,55"/>'
    '<circle cx="78" cy="58" r="6"/>',
  ),
  'crunch': _svg(
    '${_head(25, 45)}'
    '<path d="M32,48 L55,60"/>'
    '<path d="M55,60 L70,50"/>'
    '<path d="M70,50 L75,65"/>',
  ),
  'leg_raise': _svg(
    '<path d="M35,10 L65,10"/>'
    '<path d="M40,10 L50,25"/>'
    '<path d="M60,10 L50,25"/>'
    '${_head(50, 30)}'
    '<path d="M50,37 L50,55"/>'
    '<path d="M50,55 L70,45 L85,45"/>',
  ),
  'dead_bug': _svg(
    '${_head(20, 50)}'
    '<path d="M27,50 L50,50"/>'
    '<path d="M35,50 L35,25"/>'
    '<path d="M45,50 L60,35"/>'
    '<path d="M50,50 L55,35 L65,35"/>'
    '<path d="M50,50 L60,65"/>',
  ),
  'twist': _svg(
    '${_head(45, 25)}'
    '<path d="M45,32 L48,55"/>'
    '<path d="M35,45 L65,40"/>'
    '<path d="M48,55 L40,70 L40,85"/>'
    '<path d="M48,55 L58,70 L58,85"/>',
  ),
  'woodchopper': _svg(
    '${_head(35, 20)}'
    '<path d="M35,27 L45,55"/>'
    '<path d="M20,15 L70,60"/>'
    '<path d="M45,55 L40,75 L40,90"/>'
    '<path d="M45,55 L55,75 L55,90"/>',
  ),
  'mountain_climber': _svg(
    '${_head(15, 45)}'
    '<path d="M22,45 L70,55"/>'
    '<path d="M70,55 L85,60"/>'
    '<path d="M45,50 L50,35"/>',
  ),
  'jumping_jack': _svg(
    '${_head(50, 15)}'
    '<path d="M50,22 L50,50"/>'
    '<path d="M50,28 L25,10"/>'
    '<path d="M50,28 L75,10"/>'
    '<path d="M50,50 L30,85"/>'
    '<path d="M50,50 L70,85"/>',
  ),
  'burpee': _svg(
    '${_head(35, 55)}'
    '<path d="M40,58 L60,65"/>'
    '<path d="M45,60 L45,80"/>'
    '<path d="M60,65 L70,80 L75,88"/>',
  ),
  'running': _svg(
    '${_head(45, 20)}'
    '<path d="M45,27 L52,50"/>'
    '<path d="M48,32 L35,40"/>'
    '<path d="M52,32 L68,25"/>'
    '<path d="M52,50 L65,55 L70,45"/>'
    '<path d="M52,50 L40,65 L35,80"/>',
  ),
  'rowing_machine': _svg(
    '${_head(60, 25)}'
    '<path d="M60,32 L45,45"/>'
    '<path d="M45,45 L25,40"/>'
    '<path d="M45,45 L60,60 L75,55"/>'
    '<path d="M20,60 L80,60"/>',
  ),
  'battle_ropes': _svg(
    '${_head(50, 20)}'
    '<path d="M50,27 L50,60"/>'
    '<path d="M50,32 L35,15"/>'
    '<path d="M50,32 L65,50"/>'
    '<path d="M30,15 Q40,25 30,35 Q40,45 30,55"/>'
    '<path d="M70,50 Q60,40 70,30 Q60,20 70,10"/>'
    '<path d="M50,60 L45,90"/>'
    '<path d="M50,60 L55,90"/>',
  ),
};
