<p align="center">
  <img src="assets/branding/logo.svg" alt="Fitness Buddy logo" width="96" height="96">
</p>

<h1 align="center">Fitness Buddy</h1>

<p align="center">
  A Flutter (web-first, also Android/iOS) app for tracking body transformation and fitness
  progress — workouts, nutrition, weight, and expenses — backed by Firebase.
</p>

<p align="center">
  <a href="https://github.com/vaibhavhariramani/fitness_buddy/actions/workflows/ci-cd.yml">
    <img src="https://github.com/vaibhavhariramani/fitness_buddy/actions/workflows/ci-cd.yml/badge.svg" alt="CI/CD status">
  </a>
  <a href="https://fitness-buddy.web.app">
    <img src="https://img.shields.io/badge/demo-fitness--buddy.web.app-2E7D32" alt="Live demo">
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.fitnessbuddy.fitness_buddy">
    <img src="https://img.shields.io/badge/Play%20Store-live-3DDC84?logo=google-play&logoColor=white" alt="On Google Play">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
  </a>
</p>

**Live web app:** [fitness-buddy.web.app](https://fitness-buddy.web.app) · **Android:**
[Google Play](https://play.google.com/store/apps/details?id=com.fitnessbuddy.fitness_buddy)

## Screenshots

<div align="center">
<table>
<tr>
<td align="center"><img src="docs/screenshots/dashboard.png" alt="Dashboard" width="200"><br><sub><b>Dashboard</b> — streak, weight trend, today's nutrition</sub></td>
<td align="center"><img src="docs/screenshots/exercises.png" alt="Exercise library" width="200"><br><sub><b>Exercise library</b> — searchable catalog with photos</sub></td>
<td align="center"><img src="docs/screenshots/nutrition.png" alt="Nutrition tracker" width="200"><br><sub><b>Nutrition</b> — macro targets & meal log</sub></td>
<td align="center"><img src="docs/screenshots/wellness.png" alt="Wellness reminders" width="200"><br><sub><b>Wellness reminders</b> — medicine/yoga/meditation alarms</sub></td>
</tr>
</table>
</div>

The app is also responsive down to phone width and up to tablet — see
[docs/screenshots/](docs/screenshots/) for the tablet layout and more.

## Features

### Onboarding & Auth
- Email/password and Google sign-in, forgot-password flow
- Onboarding collects weight, height, target weight, age, gender, and activity level, then computes BMI, TDEE, and calorie/macro targets (Mifflin-St Jeor)

### Dashboard
- Day streak, current/target weight, and personal-record stat cards (responsive grid)
- Weight trend chart and all-time muscle-group volume chart
- Weekly summary (average weight, trend direction)

### Exercise Library & Workout Coach
- 70-exercise offline catalog — category, primary/secondary muscles, equipment, difficulty, preparation/execution instructions, form tips, common mistakes, safety notes, and substitute suggestions
- Real exercise photos (wger.de, CC BY-SA 4.0) for the most common exercises, with a hand-drawn pose illustration fallback for the rest — cached on-device for offline use
- Muscle-group anatomy diagrams
- Workout Plans — build, reorder, duplicate, and start guided sessions from a plan
- Muscle Reports — weekly/monthly training volume per muscle group with recovery status
- "Replace exercise" substitution sheet, "Add to workout" quick action

### Workout Logging
- Ad-hoc logging with an exercise-name autocomplete backed by the catalog (auto-fills muscle group)
- Guided "Start Workout" session: rest timer, previous-performance display, RIR tracking, warm-up/failure set flags, automatic PR detection (Epley estimated 1RM)
- Date picker on every logging entry point (defaults to today, supports backdating)

### Nutrition Tracker
- Food search backed by Open Food Facts, plus barcode scanning
- A small bundled "Common foods" list (plain oats, oats + whey protein, chicken curry, boiled rice) that's always available even when Open Food Facts has no generic match or is unreachable, with quick gram/serving-size presets
- Quick Add (manual macros), Saved Meals (batch logging), user-created Recipes with live per-serving macro calculation, Custom Foods, Favorites, and a Recent-foods list derived from history
- Editable macros on the logging screen — override calculated values with exact figures from a label
- Daily targets ring + macro progress bars, 6 meal types, date picker for backdating

### Expenses, Diet Plan & Recipes
- Expense tracker with category-wise totals, bar charts, and date picker
- Rule-based diet suggestion (calorie/macro plan derived from TDEE)
- "Cook This" — ingredient-overlap recipe matching against a seeded recipe set

### Social
- Friend requests, privacy-gated shared progress, 1:1 and group chat

### Platform polish
- Light/dark theme, mobile-first responsive layout (curated bottom nav + "More" sheet on phones), pill buttons, hairline-bordered cards, and the Inter typeface — see `lib/app/theme.dart`

## Tech stack

- **Flutter** (Web, Android, iOS) with **Riverpod** (hand-written `StateNotifier`s) for state management
- **go_router** for navigation
- **Firebase**: Authentication, Firestore, Storage, Hosting (no Cloud Functions)
- **fl_chart** for charts, **mobile_scanner** for barcode scanning, **cached_network_image** for offline-friendly image caching, **Hive** for local favorites/recents

## Architecture

Feature-first structure under `lib/features/<feature>/`. Two model/data conventions coexist by design:

- **Flat**: `lib/models/` + `lib/services/repositories/` for cross-feature, persisted data (expenses, workouts, weight, meals, workout plans, custom foods, etc.)
- **Nested**: `lib/features/<feature>/{models,repository,providers,pages,widgets}` for feature-internal types (the exercise catalog, food search models)

Firestore is organized as per-user subcollections under `users/{uid}/...`, gated by security rules in `firestore.rules`.

## Getting started (local development)

`lib/firebase_options.dart` and `android/app/google-services.json` are gitignored and not
included in this repo — generate your own against your own Firebase project:

```bash
flutter pub get
flutterfire configure   # generates lib/firebase_options.dart + android/app/google-services.json
flutter run -d chrome
```

`lib/firebase_options.dart.example` shows the shape FlutterFire CLI produces, for reference.

**New to Firebase, or want the full walkthrough** (creating the project, enabling
Auth/Firestore/Storage, deploying security rules, Android release signing)?
See **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)** — step by step, ~15 minutes.

## Testing

```bash
flutter analyze          # static analysis
dart format --output=none --set-exit-if-changed .   # format check
flutter test              # unit tests (calculations, streaks, PR detection)
```

## Deployment

**Web:** [fitness-buddy.web.app](https://fitness-buddy.web.app) — deploys to a dedicated
Firebase Hosting site (target `fitness-buddy`) inside the `expense-tracker-71917` Firebase
project:

```bash
flutter build web --no-web-resources-cdn
firebase deploy --only hosting:fitness-buddy --project expense-tracker-71917
```

**Android:** [Google Play](https://play.google.com/store/apps/details?id=com.fitnessbuddy.fitness_buddy) —
published as a signed release build (`flutter build appbundle --release`); see
[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md#android-release-builds-signing) for the signing
setup.

A fork deploys to *your own* Firebase project and (if you choose to publish one) your own Play
Store listing — nothing here points at the original app's infrastructure. See
[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## CI/CD

`.github/workflows/ci-cd.yml` runs on every push/PR to `main` with four stages:

1. **Scan code** — `flutter analyze`, `dart format --set-exit-if-changed`, and a secret scan ([gitleaks](https://github.com/gitleaks/gitleaks-action))
2. **Build app** — `flutter build web --release`, uploaded as a build artifact
3. **Smoke test** — `flutter test` (unit tests covering BMI/TDEE calculations, streak logic, and PR detection)
4. **Deploy** — deploys the built artifact to Firebase Hosting (`fitness-buddy` site), **only on pushes to `main`**, after scan/build/test all pass

Since `lib/firebase_options.dart` isn't in the repo, each of the first three jobs reconstructs it
from a repo secret before running any `flutter` command.

### One-time setup: repo secrets

| Secret | Used for | How to get it |
|---|---|---|
| `FIREBASE_OPTIONS_DART` | Reconstructing `lib/firebase_options.dart` in CI (scan/build/smoke-test) | Run `flutterfire configure` locally, then paste the full contents of the generated file |
| `FIREBASE_SERVICE_ACCOUNT` | Deploying to Firebase Hosting | Firebase Console → Project Settings → Service Accounts → **Generate new private key** (for project `expense-tracker-71917`) |

Add both under GitHub repo → Settings → Secrets and variables → Actions → **New repository secret**.
Until `FIREBASE_SERVICE_ACCOUNT` is added, `scan`/`build`/`smoke-test` still pass — only `deploy` fails.

**Forks and external PRs can't deploy to the live app.** The `deploy` job only runs on a direct
push to `main` on this repository — never on a `pull_request` event — and needs a repo secret
that doesn't exist anywhere else. See [CONTRIBUTING.md](CONTRIBUTING.md#cicd-and-your-fork) for
the full explanation.

## Security note

`lib/firebase_options.dart` and `android/app/google-services.json` are intentionally excluded
from this repo and from git history — see `.gitignore`. Firebase's own docs note that these
client-side identifiers aren't secret in the traditional sense (access is enforced by
`firestore.rules`/`storage.rules`, not by hiding the API key), but they're kept out of version
control here anyway. Generate your own via `flutterfire configure`.

See **[SECURITY.md](SECURITY.md)** for the full security model — what `firestore.rules` and
`storage.rules` actually guarantee, what they don't, and how to report a vulnerability.

## Contributing

Issues and PRs are welcome — see **[CONTRIBUTING.md](CONTRIBUTING.md)** for the project layout,
dev setup, and guidelines. Good first issues: more entries in the food database, additional
exercise photos/instructions, accessibility passes.

## License

[MIT](LICENSE) — free and open source. Use it, fork it, modify it, ship your own version — just
keep the copyright notice and this license file, and credit the original project if you build
on it. There's no requirement to share your changes back, unlike a copyleft license.

## Acknowledgments

- Built by [Vaibhav Hariramani](https://github.com/vaibhavhariramani).
- Exercise photos from [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (public
  domain) and muscle-diagram anatomy from [MuscleMap](https://github.com/melihcolpan/MuscleMap)
  (MIT) — see the license headers in `lib/shared/widgets/body_diagram_paths.dart`.
- Nutrition data from [Open Food Facts](https://world.openfoodfacts.org/).
- Some of this app's product direction was inspired by
  [openGym](https://github.com/arvids-unavailable/openGym), a self-hosted workout tracker —
  no code or UI was copied, only feature ideas adapted to this app's own Flutter/Firebase stack.
