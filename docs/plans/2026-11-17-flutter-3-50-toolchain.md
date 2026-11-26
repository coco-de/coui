# Flutter 3.50.0 — what the bump took

Status on 2026-11-17: **applied in one commit, the second of the two in the pull request that carries this note; no CI run has seen it yet.** Flutter 3.50.0 (Dart 3.14.0,
released 2026-11-11) was installed and the repository was taken to green on it in a throwaway worktree. The owner then
approved option 1 below — adopt the Jaspr 0.24 beta line for the workspace — and the change set was applied to the
working tree and measured there, across every package the CI test commands cover. Library code needed one change, a
shader (see [the upstream audit](2026-11-17-liquid-glass-widgets-1-17-delta.md)); everything else is workspace
tooling. CI cannot follow yet: see "What the bump costs outside the repository".

## Why a plain bump fails

`flutter pub get` under 3.50.0 cannot solve the workspace:

1. `flutter_test` pins `test_api 0.7.14`. The only `test` release that accepts it is `1.32.0`, which needs
   `analyzer >=13 <15`.
2. `jaspr_builder 0.23.5` — the latest stable — needs `analyzer ^12.1.0`. `coui_core` (`^12.1.0`) and `coui_lints`
   (`>=10 <13`) also exclude 13 and later.

Forcing the analyzer with a `dependency_overrides` entry does not rescue it: `jaspr_builder 0.23.5` does not compile
against analyzer 13 (`FormalParameterElement.isInitializingFormal` no longer exists), so `build_runner` for the docs
site cannot run, and `mockito 5.6.4` breaks too. The other direction fails the same way: with the change set applied,
`flutter pub get` under 3.47.9 reports `flutter_test from sdk depends on test_api 0.7.12` against `test >=1.31.0` and
stops (`--dry-run`; 3.48 and 3.49 were not tried).

## The path that works

The Jaspr 0.24 line — **pre-releases as of today** — moves `jaspr_builder` to analyzer 13/14:

| Package | Was | Now |
| --- | --- | --- |
| `jaspr`, `jaspr_test` | `^0.23.5` | `^0.24.0-beta.1` — except `coui_web`'s runtime `jaspr`, which becomes `>=0.23.5 <0.25.0` (see Consumers) |
| `jaspr_builder` | `^0.23.5` | `^0.24.0-beta.1` |
| `jaspr_lints` | `^0.7.2` | `^0.8.0-beta.0` |
| `jaspr_content` | `^0.5.3` | `^0.6.0-beta.0` |
| `jaspr_router` | `^0.8.3` | `^0.10.0-beta.1` |
| `jaspr_flutter_embed` | `^0.4.10` | `^0.5.0-beta.0` |
| `jaspr_cli` (deploy, nightly sweep, contributing guide) | `0.23.5` | `0.24.0-beta.1` — the 0.23 CLI stops at `[CRITICAL] Incompatible jaspr dependency with version ^0.24.0-beta.1` |
| `analyzer` in `coui_core` (dev), `coui_lints` | `^12.1.0`, `>=10 <13` | `>=13.3.0 <15.0.0` |
| `flutter` floor in the root `pubspec.yaml` | `>=3.47.0` | `>=3.50.0` — the workspace does not resolve below it |

The lock moves 26 packages (analyzer 12.1.0 → 14.7.0, test 1.31.1 → 1.32.0, test_api 0.7.12 → 0.7.14, build_runner
2.15.1 → 2.16.2, source_gen 4.2.3 → 4.3.1, mockito 5.6.4 → 5.8.1, …), adds `listen` and `sse`, and drops
`hotreloader`; its `sdks` block records the new Flutter floor. The seven Jaspr packages are the only new pre-releases
(`widgetbook` and `super_editor` already were).

## What the change set is

| Area | Change |
| --- | --- |
| Pubspecs, `pubspec.lock` | The table above; `pub_semver` becomes a dev dependency of `coui_core`. The comments that explained the old analyzer pin (root floor, `coui_lints`) say what holds now |
| `coui_lints` (7 rule files) | analyzer 13's renamed syntax API: `NamedExpression` → `NamedArgument`, `argument.name.label.name` → `argument.name.lexeme`, `argument.expression` → `argument.argumentExpression`; `SimpleFormalParameter` visitor → `RegularFormalParameter` (skipping function-typed ones); one rule also accepts a bare `Expression` argument. 80 rule tests pass |
| `coui_core/bin/figma_reader` | One helper, `parseSource`, pins the parse to language 3.11 — the language the kit's sources are written in. Analyzer 14's `parseString` reads the latest language (3.14), which rejects a `final` parameter on a function that 3.11 allows, so a fixture failed |
| `coui_web` tests | `AttachDocument` is private in Jaspr 0.24 (and component tests no longer register the document adapter). A shared helper reads the `Document.html` declarations off the tree by name; two tests use it |
| `docs_site` generated files | `main.client.options.dart` factories become `p.get<T>(…)`; `_web.dart` gets the corrected relative path. **The generator drops the Flutter web plugin block** (imports and the `initialize:` registrations) when it cannot find `.flutter-plugins-dependencies` in its working directory, which a clean checkout does not have — the change set keeps the committed block and changes only the factories. A `jaspr build` run after `flutter pub get` in `docs_site` (the order the deploy workflow uses) regenerates all four tracked files byte-identically |
| CI, editor, docs | `FLUTTER_VERSION` in eight workflows and the comment that explains it, `JASPR_CLI_VERSION` in `deploy.yaml` and `parity-nightly.yml` with the comments that cite the CLI's source (`FlutterRunner.build()` in 0.24; it was `buildFlutter()` in 0.23), `DOCS_DEPLOYMENT.md`, `.vscode/settings.json`, and the Flutter and Jaspr CLI versions in the contributing guide and the runner-routing page |
| Dead ignores | 19 `// ignore: avoid_positional_boolean_parameters` comments (and the lines that only justified them) in 15 files — seven contracts, both `swiper.dart`, six widgetbook stories. 3.50's analyzer reports them `unnecessary_ignore`; on 3.47.9 they were needed |

The Jaspr CLI pin was missing from the first version of this change set. Nothing in analysis or the test suites runs the
CLI; only `jaspr build` does, and the deploy and nightly workflows would have failed there.

## Measured on 3.50.0 with the change set (and the audit's changes)

Commands are the CI ones (`melos run test:flutter`, `test:dart`, `test:tool` expand to these), run directly in each
package on one macOS ARM64 machine:

| Command | Result |
| --- | --- |
| `dart analyze . --fatal-warnings` (repository root, after the last edit) | 0 errors; 3 warnings, all `prefer_k_prefixed_global_constant` in `tool/parity` — identical at the pre-change `HEAD` on 3.47.9, so `main`'s own gate is red on them |
| `dart analyze --fatal-warnings` in each of the 11 workspace packages | 0 errors, 0 warnings (these runs do not look at `tool/`) |
| `dart format --set-exit-if-changed --output=none .` | no drift (5,631 files) |
| `dart test --exclude-tags perf` — `coui_core` · `coui_web` · `coui_lints` · `coui_mcp` · `docs_site` | 7,775 · 8,964 · 80 · 17 · 297 pass |
| `flutter test --exclude-tags parity,golden` — `coui_flutter` | 11,855 pass, 4 skipped |
| the same — `coui_i10n` · `docs_core` · `docs_app` · `coui_widgetbook` | 5 · 1,730 · 64 · 1,903 pass |
| `flutter test --tags "parity \|\| golden"` — `coui_flutter` | 47 pass, 1 skipped, against the committed baselines |
| `dart test tool/parity/test tool/test` (repository root) | 1,232 pass, 3 skipped |
| `flutter test --platform chrome test/web/` — `coui_flutter` | 21 pass |
| `dart test --timeout 5m tool/parity/test/web/flutter_glass_refraction_test.dart` | 6 pass — a release web build, pixels and gestures, with the single-exit shader |
| `dart run tool/api_sync_check.dart --ci` | passes |
| every `scripts/guards/**` guard, no arguments, one at a time | 100 of 101 pass; `figma_axis_collapse_judge` needs the environment variable `A1_DATA`, as on a clean `main` |
| `jaspr build` in `docs_site`, `jaspr_cli 0.24.0-beta.1` | succeeds (357 pages); the deploy workflow's merge step and sanity check find nothing missing (41 split parts, 3,200 files) |
| the same with `jaspr_cli 0.23.5` | refuses at once: `[CRITICAL] Incompatible jaspr dependency with version ^0.24.0-beta.1` |
| `flutter build web --release --base-href /` in `app/coui_widgetbook` (the deploy workflow's first job) | succeeds |

Library code needed one change for 3.50.0: the refraction shader (`main()` with one exit). The new compiler warns about
a shader that samples a texture and returns early; the shader and a guard that compiles every shader for the five
target sets are in the audit's change set and are neutral on 3.47.9. The 0.24 CLI was run from the pub cache through a
throwaway package, not through `dart pub global activate`, so the machine's own `jaspr` stayed at 0.23.5.

### What 3.50.0 adds to the analyzer's output

All infos; none fail CI (`--fatal-warnings`). `unnecessary_ignore` is gone after the removal above.

- **Material and Cupertino are being split out.** `package:flutter/material.dart` and `package:flutter/cupertino.dart`
  are deprecated in favour of the `material_ui` and `cupertino_ui` packages ("deprecated after v3.47.0"). Findings:
  `coui_flutter` 21 (15 in `lib`, 6 in test helpers and probes — `coui_app.dart` alone has four, including
  `GlobalMaterialLocalizations` / `GlobalCupertinoLocalizations`), `coui_widgetbook` 21, `docs_app` 1, `docs_site` 1,
  and 11 in the sample files under `docs/verification/`.
  The old imports still work. Moving off them is its own piece of work: new dependencies, and CoUI's rule that
  components do not import Material. `text_field.dart` and `text_area.dart` carry one each, from
  `import 'package:flutter/material.dart' show TextMagnifier;`.
- **The pre-commit hook judges files, not lines** (`lefthook.yml`: `dart analyze --fatal-infos {staged_files}`). This
  checkout has no lefthook installed, so its commands were run by hand on each commit's staged Dart files. The
  toolchain commit (32 files) reports nothing. The audit's commit (23 files) reports 31 infos in 11 files on 3.50.0.
  Twenty-nine sit on lines the commit did not touch: five are the Material import above (`text_field.dart`,
  `text_area.dart` and three tests) and twenty-four are older lints in files that already carried them
  (`text_area.dart` has ten besides the import, `obscured_field_services_test.dart` nine). Two are the same Material
  import in the two dialog tests the commit adds, written like their neighbours. The hook's own header prescribes
  `LEFTHOOK=0 git commit` for debt the commit does not pay, with the reason in the PR body; `pre-push` judges the
  same files (`--fatal-infos {push_files}`), so a checkout with lefthook meets the same findings there.

## What the bump costs outside the repository

- **Runners.** The fleet's shared SDK pin should move to 3.50.0 before the workflows are switched
  (`ci.yaml`'s comment: CI installs the fleet pin, not the package floor). Without it each runner downloads its own
  copy on first use — `deploy.yaml` budgets about 25 minutes for a cold download.
- **Baselines.** `golden-baseline.yml`, `preset-baseline.yml` and `parity-baseline.yml` re-capture on the CI renderer
  and are the owner's to dispatch. Here the 47 parity and golden tests passed unchanged against the committed
  baselines on this Mac, which suggests a re-capture may not be needed, but the CI renderer is the authority — the
  first PR on 3.50.0 will show it.
- **Consumers.** Two constraints changed.
  - `coui_web`'s runtime `jaspr` is the range `>=0.23.5 <0.25.0`: the workspace resolves to `0.24.0-beta.1` because the
    docs site and the dev dependencies ask for it, but an app can stay on stable Jaspr. `coui_web`'s source is the same
    on both ends — it passes on 0.23.5 (before this change) and on 0.24.0-beta.1 with it. What a range does not cover
    is a 0.24 API change that compiles but behaves differently; the suites would not see it.
  - `coui_lints` now requires `analyzer >=13.3.0 <15.0.0` (resolved 14.7.0). A consumer that resolves that package
    on an SDK whose solver is held below analyzer 13 needs the previous tag for it. `coui_core`'s analyzer is a dev
    dependency and is not visible to consumers.
- **Package floors.** `coui_flutter` and `docs_app` keep `flutter: >=3.47.0`, which is what a consumer needs and is
  unchanged. Nothing in CI exercises that floor any more: the audit's changes ran on 3.47.9 before the bump and the
  final tree runs on 3.50.0 only. Raising the floor is a consumer-visible decision and a breaking release.
- **Version snapshots.** `tool/build_version_snapshot.sh` builds an older tag with the pinned CLI. A tag whose
  `docs_site` is on Jaspr 0.23 is refused by the 0.24 CLI the same way the 0.23 CLI refuses 0.24 (the 0.24 CLI against a
  0.23 project was not run). The script already says old tags may not reproduce with a modern toolchain.
- **Jaspr 0.24 is a beta with breaking changes.** The ones this repository hit are above; others
  (`ClientAppBinding` as a singleton, `Component.wrapElement` → `apply`, CSS nesting rules) were not exercised by the
  test suites.

### Not verified

- CI itself: every run above is on this Mac. The hosted `build-docs` job (Linux) and the self-hosted runners have not
  run the change set, and `melos bootstrap` / `melos run …` were replaced by the commands they expand to.
- The desktop builds (`deploy-desktop.yaml`) and `publish.yaml`.
- A browser's rendering of the built docs site; the sanity check proves the files exist, not that the pages work.

## Decision

Option 1 was approved on 2026-11-17 and is applied above. What stays with the owner:

1. Move the runner fleet to 3.50.0 and dispatch the three baseline workflows if the first CI run shows a pixel
   difference.
2. Decide the package floors (above).
3. When Jaspr 0.24 ships stable, replace the beta constraints and the CLI pin with the stable line; the
   `coui_web` range can then be tightened or kept.
