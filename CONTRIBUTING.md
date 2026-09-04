# Contributing to Fitness Buddy

Thanks for taking a look! This is a solo-maintained personal project, but issues and PRs are
genuinely welcome.

## Project layout

```
lib/
  app/                    theme, router, app-level widgets
  core/                   design system, shared providers, utilities
  models/                 cross-feature data models (expenses, weight, meals, workouts…)
  services/repositories/  Firestore access for the models above
  features/<feature>/     feature-first UI — each has its own pages/, widgets/, providers/,
                           and (where the data is feature-internal) models/ and repository/
test/                     unit tests
firestore.rules           Firestore security rules (per-user subcollections, friend-gated reads)
storage.rules             Storage security rules
docs/FIREBASE_SETUP.md    step-by-step Firebase backend setup
```

See the [README](README.md#architecture) for more on the flat-vs-nested model convention.

## Running for development

You'll need your own Firebase project — see **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)**
for the full walkthrough. Once that's done:

```bash
flutter pub get
flutter run -d chrome     # or any connected device/emulator
```

## Before opening a PR

```bash
flutter analyze                                            # static analysis — must be clean
dart format --output=none --set-exit-if-changed $(git ls-files '*.dart')   # format check
flutter test                                                # unit tests
```

All three run in CI on every PR (see `.github/workflows/ci-cd.yml`) — a red check means one of
these failed.

## Guidelines

- **Match the existing style.** Feature-first structure, Riverpod (`StateNotifier` /
  `StreamProvider`) for state, `go_router` for navigation. No new state-management or routing
  libraries without discussion first.
- **Comments explain *why*, not *what*.** A hidden constraint, a workaround for a specific bug,
  a non-obvious invariant — yes. A restatement of the code — no.
- **Security rules changes need care.** `firestore.rules`/`storage.rules` gate everything —
  if your PR touches data access patterns, update the rules in the same PR and explain the
  reasoning (see the existing rules for the pattern: friend-gated reads keyed off an
  `isAcceptedFriend()` helper, per-type privacy toggles for social data).
- **New dependencies are a real cost.** This app already carries the ones its 60+ feature areas
  actually need; before adding one, check whether an existing dependency already covers it.
- **Don't commit secrets.** `lib/firebase_options.dart`, `android/app/google-services.json`,
  `ios/Runner/GoogleService-Info.plist`, and `android/key.properties` are gitignored — a
  [gitleaks](https://github.com/gitleaks/gitleaks-action) scan also runs in CI on every PR.

## CI/CD and your fork

`.github/workflows/ci-cd.yml` is the exact pipeline used to build and deploy the live app, and
it's public so you can see (and reuse) the whole thing. It cannot be used to push changes to the
live app from a fork or an external PR:

- The **deploy** job only ever runs on a direct push to `main` on this repository
  (`if: github.event_name == 'push' && github.ref == 'refs/heads/main'`) — it never runs for
  `pull_request` events, so opening a PR (from a fork or otherwise) cannot trigger it.
- It also requires a repository secret (`FIREBASE_SERVICE_ACCOUNT`) that only exists on this
  repository. A fork's copy of the workflow has no way to obtain it.
- GitHub doesn't expose repository secrets to workflow runs triggered by pull requests from
  forks at all, by default — so even the non-deploy jobs (`scan`/`build`/`smoke-test`) will show
  as failing on an external contributor's fork PR until they add their own
  `FIREBASE_OPTIONS_DART` secret pointing at their own Firebase project (see
  [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)). That's expected — it means your fork can't
  accidentally (or otherwise) affect the real deployment.

## Reporting bugs

Please use the **bug report** issue template — it asks for the platform (web/Android/iOS),
browser if relevant, steps to reproduce, and what you expected instead. A screenshot or screen
recording helps a lot for UI issues.

## Reporting security issues

See **[SECURITY.md](SECURITY.md)** — please don't open a public issue for anything that could
be used against another user's data.

## License

By contributing, you agree your contribution is licensed under this project's
[MIT License](LICENSE).
