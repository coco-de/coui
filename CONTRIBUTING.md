# Contributing to CoUI

Welcome! This guide is for people improving **CoUI itself**: its shared Dart
design system, Flutter and Web implementations, documentation, and Figma plugin.
You do not need to understand every package before making your first change.

**한국어로 처음부터 따라 하기 → [CoUI 기여자 안내](docs/contributing/README.md)**

## Choose your starting point

| Your goal | Start here |
|---|---|
| Set up a checkout and see a component | [First run](docs/contributing/getting-started.md) |
| Understand Core, Flutter, Web, and Figma | [Architecture and terminology](docs/contributing/architecture.md) |
| Make a small, end-to-end improvement | [First change: an outlined Badge](docs/contributing/first-change.md) |
| Decide which checks to run | [Verification and troubleshooting](docs/contributing/verification.md) |
| Build the plugin and update a Figma canvas | [Figma workflow](docs/contributing/figma.md) |
| Change an API or upgrade a consuming project | [Compatibility and upgrades](docs/contributing/upgrading.md) |

For a first-day checklist, use [ONBOARDING.md](ONBOARDING.md). To **use** CoUI in
an application, see the [installation guide](docs_core/content/guides/installation.md).

## How a change travels

```text
coui_core: tokens + Contract + Style + Theme
    ├── coui_flutter: resolver → Flutter widget
    ├── coui_web:     resolver → Jaspr component / DOM
    └── Dart exporters → JSON → TypeScript Figma builders → Figma canvas

docs_core: shared prose + examples + code snippets
    ├── docs_site: Jaspr documentation website
    └── app/docs_app: native Flutter documentation app
app/coui_widgetbook: Flutter component playground
```

Core describes the shared API and appearance. Each platform's **resolver** turns
those descriptions into values it can draw; the widget renders those values.
The Figma plugin generates a design representation from exported data. A Dart
change does not automatically rebuild the plugin or redraw a Figma file.

The [architecture guide](docs/contributing/architecture.md) maps these roles to
real files and explains the separate Figma-to-code review/export paths.

## Set up your environment

- Repository access and Git. If cloning the private repository fails, request
  access from a maintainer.
- Flutter with its bundled Dart SDK. The current root
  [pubspec.yaml](pubspec.yaml) requires **Flutter ≥3.50.1** and **Dart ≥3.11.0,
  <4.0.0**; [CI](.github/workflows/public-ci.yml) pins the tested Flutter version.
- Melos for workspace commands; CI currently uses **7.1.1**.
- For Web previews: the matching Jaspr CLI; see [first run](docs/contributing/getting-started.md).
- For plugin work: Node.js/npm, Figma Desktop, and the static Pretendard fonts.
  See [Figma prerequisites](docs/contributing/figma.md).

From the directory where you want the checkout, clone and enter it:

```bash
git clone https://github.com/coco-de/coui.git
cd coui
```

Then, **from the repository root**, with Flutter's `bin` and Dart's global
executables on `PATH`:

```bash
flutter --version
flutter doctor
dart pub global activate melos 7.1.1
flutter pub get
melos bootstrap
```

Expected: dependency resolution and bootstrap finish without errors. Bootstrap
also runs the configured hooks, including locale generation. Inspect
`git status --short` afterward. The [first-run guide](docs/contributing/getting-started.md)
explains what to generate next and how to launch each preview.

## Make one focused change

1. Find or create an issue describing the current behavior, desired behavior,
   affected platforms, and how you will verify the result.
2. Create an issue-linked branch from the appropriate base. Independent work
   targets `main`; a child issue targets its existing parent branch. Follow the
   [pull request workflow](#pull-requests).
3. Locate the shared source and both platform implementations using the
   [change map](docs/contributing/architecture.md). For example, a shared Badge
   border default belongs in `CoreBadgeStyle`, not in two platform-local constants.
4. Implement and test the behavior. New shared fields need a complete path through
   both platforms; an existing default may already be consumed by both resolvers.
5. Update affected examples, their copyable code snippets, and component docs.
   Add or update the Figma builder/export when its representation is affected.
6. Run [checks for your change](docs/contributing/verification.md), inspect the
   diff, and open a PR with the evidence.

The [Badge walkthrough](docs/contributing/first-change.md) demonstrates this
sequence and also lists the registration work for a new component.

## Engineering rules and naming

| Topic | Contributor guide |
|---|---|
| Shared tokens, contracts, styles, and platform resolvers | [Architecture and change map](docs/contributing/architecture.md) |
| Examples and documentation registration | [Adding a component](docs/contributing/first-change.md#새-컴포넌트를-추가한다면) |
| Scoped formatting, lint, and visual or behavioral evidence | [Verification](docs/contributing/verification.md) |
| Receiving design changes and confirming adoption | [Design and development collaboration](docs/contributing/design-collaboration.md) |

Current component names are bare names such as `Button` and `Badge`; shared types
use `Core`, such as `CoreButtonVariant` and `CoreBadgeStyle`. Files use snake_case,
such as `badge_style.dart`. Look at the current implementation before copying an
older example or a migration document.

Format and analyze the files you changed. Broad automatic-fix commands are not a
substitute for reviewing the diff. Use the [scoped check recipes](docs/contributing/verification.md).

## Pull requests

Use [Conventional Commits](https://www.conventionalcommits.org/) for the PR title
and commits, for example `docs(contributing): explain the Figma update path` or
`fix(badge): preserve the outline style override`.

A useful PR includes:

- What changed, why, and `Closes #<issue-number>` for the issue it completes.
- Affected Core/Flutter/Web/Figma/docs surfaces and any migration instructions.
- Commands run, their results, and a clear distinction between executed checks
  and manual/source review.
- Before/after evidence for visible changes, including overrides and relevant
  states. Figma selftests do not replace inspection in Figma's real layout engine.

CI and review must pass before merge. Use the repository's
[PR template](.github/PULL_REQUEST_TEMPLATE.md) to record the change and its verification.

[Package checks](.github/workflows/public-ci.yml) run representative Core,
Flutter, and Jaspr tests on GitHub-hosted runners. Run the focused checks for
your change and record any required visual evidence in the PR.

## Compatibility and releases

Public API removals follow the [deprecation policy](docs/contributing/upgrading.md#deprecation).
Introduce a working replacement, identify it and the starting version in the
deprecation message, and follow the policy's minimum retention window. Include
old-to-new examples when migration is necessary.

**Release Please owns package versions, tags, and changelogs.** Do not manually
run `melos version` or follow the legacy release-preparation script's versioning
instructions. A source PR, package release, plugin publication, and Figma library
publication are separate steps. See [upgrades](docs/contributing/upgrading.md)
and [pub.dev publishing](docs/contributing/publishing.md).

## Reporting issues and license

- [Bug report](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature request](.github/ISSUE_TEMPLATE/feature_request.md)
- [Component request](.github/ISSUE_TEMPLATE/component_request.md)

Include the relevant version/commit, reproduction steps, platform, and expected
result. For Figma, include the plugin build identity and the affected component.

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
