# Firebase backend setup

Fitness Buddy has no backend of its own — everything (accounts, data, file storage, hosting)
runs on **your own Firebase project**. Nothing in this repo points at the original author's
project; `lib/firebase_options.dart` and `android/app/google-services.json` are gitignored
specifically so every fork wires up its own backend. This guide walks through that setup from
an empty Google account to a running app, step by step.

Total time: **15–20 minutes**, free tier (Firebase's Spark plan covers this app comfortably at
low usage — nothing here requires billing to be enabled).

## What you'll need

- A Google account
- [Flutter](https://docs.flutter.dev/get-started/install) installed (`flutter --version` to check)
- [Node.js](https://nodejs.org/) (only needed for the Firebase CLI)
- 15 minutes

## 1. Create the Firebase project

1. Go to the [Firebase Console](https://console.firebase.google.com/) and sign in.
2. Click **Add project**.
3. Name it anything (e.g. `my-fitness-buddy`) → **Continue**.
4. Google Analytics is optional — this app doesn't use it. You can disable it.
5. Click **Create project** and wait for it to finish provisioning.

## 2. Enable Authentication

1. In the left sidebar: **Build → Authentication → Get started**.
2. Under **Sign-in method**, enable:
   - **Email/Password** — toggle on, save.
   - **Google** — toggle on, pick a support email, save.
3. Under **Settings → Authorized domains**, your project's own domains (`<project-id>.web.app`,
   `<project-id>.firebaseapp.com`) are already listed — you don't need to add anything unless
   you later host on a custom domain.

## 3. Create the Firestore database

1. **Build → Firestore Database → Create database**.
2. Choose a location close to your users (this can't be changed later).
3. Start in **production mode** — this repo ships its own `firestore.rules`, deployed in step 7,
   so the default "locked" starting rules don't matter.

## 4. Create the Storage bucket

1. **Build → Storage → Get started**.
2. Same location as Firestore is fine. Start in production mode (same reasoning as above —
   `storage.rules` in this repo replaces the default).

## 5. Register your apps

Still in the Firebase Console, **Project settings** (gear icon, top left) → **Your apps** →
add each platform you want to build for:

- **Web**: click the `</>` icon, give it a nickname, **do not** check "Also set up Firebase
  Hosting" here (step 8 covers that with more control) → Register app.
- **Android**: package name must be `com.fitnessbuddy.fitness_buddy` to match this repo's
  `android/app/build.gradle.kts`, *or* change `applicationId` there to your own package name
  first — either works, they just need to match.
- **iOS** (optional, only if you're building for iOS): bundle ID must likewise match
  `ios/Runner.xcodeproj`'s bundle identifier, or you change that to match.

You don't need to download the config files by hand — the next step generates all of them
together.

## 6. Wire the Flutter app to your project (FlutterFire CLI)

```bash
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure
```

`flutterfire configure` will:
- Ask you to log in to Firebase (opens a browser)
- List your Firebase projects — pick the one you just created
- Ask which platforms to generate config for — select web (and android/ios if you registered them)
- Generate `lib/firebase_options.dart`, `android/app/google-services.json`, and
  `ios/Runner/GoogleService-Info.plist` — all three are gitignored, so this step is required on
  every fresh clone/fork.

## 7. Deploy Firestore & Storage security rules and indexes

The repo already contains the rules and composite indexes this app needs — you're deploying
them to *your* project, not writing new ones.

```bash
npm install -g firebase-tools    # if you don't already have it
firebase login
firebase use --add               # pick your project, give it an alias (e.g. "default")
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Without this step, every read/write from the app will fail with `PERMISSION_DENIED` — the
default Firestore/Storage rules from step 3–4 deny everything.

## 8. (Optional) Set up Hosting for the web build

Only needed if you want to deploy the web app somewhere, not just run it locally.

```bash
firebase target:apply hosting fitness-buddy <project-id>   # or your own target name
```

`firebase.json` in this repo already targets a site named `fitness-buddy` — either create a
Hosting site with that exact name in the Firebase Console (**Build → Hosting → Add another
site**), or edit the `target` value in `firebase.json` and this repo's
`.github/workflows/ci-cd.yml` to match a name of your choosing.

```bash
flutter build web --no-web-resources-cdn
firebase deploy --only hosting:fitness-buddy   # replace with your target name if you changed it
```

## 9. Run it

```bash
flutter run -d chrome     # web
flutter run                # whatever device/emulator is connected
```

On first run, sign up, complete onboarding (weight/height/goals), and you should land on a
fully working, empty dashboard — your own backend, your own data.

## Android release builds (signing)

Only needed if you're building a release APK/AAB to publish somewhere yourself. Debug builds
(`flutter run`) don't need any of this.

1. Generate an upload keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Keep this file **outside the repo** and back it up somewhere safe — losing it means you can
   never publish an update to the same app listing again.
2. Create `android/key.properties` (already gitignored):
   ```properties
   storePassword=<your keystore password>
   keyPassword=<your key password>
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. `flutter build appbundle --release` — `android/app/build.gradle.kts` picks up
   `key.properties` automatically when present, and falls back to the debug key when it's
   absent (so a fresh clone without a keystore still builds fine for local testing).

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Blank white page on web, no errors visible | Open the browser console. If you see `MissingPluginException`, run `flutter clean && flutter pub get` and rebuild — a stale plugin-registrant cache is the usual culprit. |
| `PERMISSION_DENIED` on every read/write | Step 7 (deploying rules) was skipped, or you deployed to the wrong project — check `firebase use`. |
| Photos/story images don't load on web (but load fine on mobile) | Flutter Web's renderer fetches images via XHR, which needs CORS headers Firebase Storage doesn't set by default. Run:<br>`gsutil cors set storage_cors.json gs://<project-id>.firebasestorage.app` |
| Google sign-in fails with "unauthorized domain" | Add the domain you're running on (e.g. `localhost`, or your custom Hosting domain) under Authentication → Settings → Authorized domains. |
| `flutterfire configure` can't find your project | Make sure you're logged into the same Google account in `firebase login` that owns the Firebase project. |

## Notes on the Firebase config values

`lib/firebase_options.dart` contains an `apiKey` — this **is not a secret**. Firebase's own
documentation is explicit about this: the API key only identifies your project to Google's
servers, and access to your data is governed entirely by `firestore.rules`/`storage.rules`, not
by keeping this value private. It's still kept out of version control here (see `.gitignore`)
so every fork cleanly points at its own project rather than accidentally sharing one — not
because leaking it would be a security incident.
