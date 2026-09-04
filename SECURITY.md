# Security policy

Fitness Buddy stores real personal data — health metrics, nutrition logs, expenses, photos,
and messages between friends — in a Firebase backend. This file explains what's supported,
how to report a vulnerability privately, and — the part most useful to anyone auditing this
code before self-hosting a fork — exactly what the security model does and doesn't cover.

## Supported versions

Only the latest deployed web app ([fitness-buddy.web.app](https://fitness-buddy.web.app)) and
the latest Play Store release get fixes. There's no maintenance branch for older versions —
this is a single, continuously-deployed app, not a versioned library.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting rather than a public issue:

<https://github.com/vaibhavhariramani/fitness_buddy/security/advisories/new>

Include: what you did, what data/access it exposed, and steps to reproduce. If it involves a
specific account's data, you don't need to include that data itself — describing the mechanism
is enough.

**On response times:** this is a personal project maintained by one person. There's no SLA or
bounty. Expect days rather than hours. If it's actively exploitable against real user data on
the live app, say so explicitly in the report — that gets prioritized over anything theoretical.

## In scope

- **`firestore.rules` / `storage.rules`** — reading or writing another user's data without a
  valid `isOwner`/`isAcceptedFriend` grant, bypassing a privacy toggle (`shareWeight`,
  `shareMeals`, `shareWorkouts`, `shareStories`), or forging a friendship's `accepted` status
  without both parties' consent.
- **The Flutter app** — anything that lets one user's session read or act on another user's
  data through the app itself, not just the rules directly.
- **`.github/workflows/ci-cd.yml`** — any path by which a fork or an external pull request
  could trigger a deploy to the real `fitness-buddy.web.app`, or exfiltrate a repository secret.
- **The live deployment** — `fitness-buddy.web.app` and the published Play Store build.

## Out of scope

- Anything that already requires access to a Firebase project's own console/service account —
  whoever owns the Firebase project is trusted by design, same as any backend operator.
- The Firebase `apiKey` in `firebase_options.dart`/`google-services.json` being visible. This is
  a public client identifier by Firebase's own design, not a secret — see
  [Firebase's docs on API keys](https://firebase.google.com/docs/projects/api-keys) and the note
  in [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
- Reports against a fork you're self-hosting with your own Firebase project, unless the same
  issue also affects the live app or a default configuration this repo ships.
- Missing rate limiting on Firebase Auth sign-in/sign-up — that's enforced by Firebase Auth
  itself, not application code.
- `npm audit`/`flutter pub outdated` findings in build-time tooling with no reachable exploit
  path in the running app.

## Security model

Read this before self-hosting a fork for anyone other than yourself.

### What it does

- **Authentication is entirely Firebase Auth's** — email/password and Google Sign-In, session
  tokens, password storage/hashing, and account recovery are all handled by Firebase, not custom
  code in this app.
- **Every collection is gated by `firestore.rules`**, keyed off the signed-in user's uid — see
  `isOwner()`/`isAcceptedFriend()` near the top of that file. Personal data (expenses, workout
  plans, wellness reminders, custom foods) is owner-only, full stop. Shareable data (weight,
  meals, workouts, personal records, stories) additionally requires an *accepted* friendship
  **and** the owner's own per-type privacy toggle (`PrivacySettings` in
  `lib/models/user_profile.dart`) to be on — friendship alone is not sufcient to read
  someone's weight log or stories, matching the toggle they actually see in Settings.
- **Friendships require mutual consent.** A `friendships/{id}` doc can only be created with
  `status: 'pending'` by the requester, and can only move to `'accepted'` by a signed-in user
  who is one of the two parties on the document — one side can't silently friend the other.
- **The CI/CD deploy job cannot be triggered by a fork or an external PR** — see
  [CONTRIBUTING.md](CONTRIBUTING.md#cicd-and-your-fork) for the specific mechanism
  (`push`-to-`main`-only trigger, plus a repository secret that doesn't exist outside this repo).

### What it does not do

- **Storage security rules (`storage.rules`) don't gate the actual photo URLs friends see.**
  `storage.rules` restricts direct SDK access to owner-only, but photos are shown to friends via
  Firebase Storage's tokenized public download URL (`…?alt=media&token=…`), stored on the
  Firestore document. That URL format is fetchable by *anyone who has the exact string*,
  regardless of `storage.rules` — this is inherent to how Firebase Storage download tokens work,
  not a bug in this app's rules. The actual privacy boundary is "can this person's Firestore
  read see the URL in the first place" (governed by `firestore.rules` as described above), not
  the storage layer. Treat any photo URL that reaches a client as effectively public to anyone
  who obtains it, e.g. via a browser's network inspector.
- **No per-field validation on most writes.** Rules check *who* can write to a document, not
  that its contents are well-formed (e.g. a client could write an implausible calorie value to
  its own meal log). This only affects the writer's own data — see the friend-read gates above
  for what's actually cross-user-visible — but it means the app trusts its own client code to
  send sane data, not a server-side schema.
- **No rate limiting in application code.** Firebase Auth applies its own throttling to
  sign-in attempts; nothing else in this app limits request volume.
- **Deleted data isn't cryptographically wiped.** Firestore/Storage deletes remove the document
  or object; nothing here implements secure erasure beyond what Google Cloud provides.
- **No end-to-end encryption.** Chat messages, photos, and every other field are stored in
  Firestore/Storage as plaintext, accessible to anyone with the Firebase project's admin
  credentials (i.e., whoever owns the Firebase project a given deployment points at).
