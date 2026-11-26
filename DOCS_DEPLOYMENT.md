# CoUI Documentation Deployment Guide

This document explains how the CoUI documentation site is deployed to GitHub Pages
and Widgetbook is deployed to Firebase Hosting.

> ⚠️ This file previously described a two-site architecture
> (`packages/coui_web/docs/` + `packages/coui_flutter/docs/`,
> `.github/workflows/deploy-docs.yml`) that no longer exists. The current
> architecture is the single unified `docs_site` (Jaspr, embedding Flutter
> previews) plus a separate Widgetbook app, both orchestrated by
> `.github/workflows/deploy.yaml`.

## 📚 What gets deployed

### 🌐 `docs_site` (unified component docs)
- **Framework**: Jaspr (Dart for web), `mode: static`, `flutter: embedded` — component preview panes embed real Flutter widgets side-by-side with the Web rendering via `jaspr_flutter_embed`.
- **Live Site**: [https://coui.cocode.im/](https://coui.cocode.im/)
- **Source**: `docs_site/` (content in `docs_core/content/components/`)
- **Build**: `jaspr build` (working directory `docs_site/`) — see the `build-docs` job in `deploy.yaml`.
- **Output**: `docs_site/build/jaspr/`

### 📱 Widgetbook
- **Framework**: Flutter
- **Live Site**: [https://coui.cocode.studio/](https://coui.cocode.studio/)
- **Source**: `app/coui_widgetbook/`
- **Build**: `flutter build web --release --base-href /` — see the `build-widgetbook` job in `deploy.yaml`.
- **Output**: `app/coui_widgetbook/build/web/`
- **Hosting**: Firebase project/site `im-cocode-coui`, live channel. The custom
  domain already points to `im-cocode-coui.web.app`.

### 🖥️ Widgetbook desktop (macOS, team-internal)
- **Framework**: Flutter (macOS) — the same source as the web Widgetbook above.
- **Distribution**: not a public site. A GitHub Actions artifact that teammates
  install with `install_macos.sh` (the repository is private).
- **Source**: `app/coui_widgetbook/` (`macos/` runner project).
- **Build**: `app/coui_widgetbook/scripts/build_macos.sh` — see `deploy-desktop.yaml`.
- **Output**: `app/coui_widgetbook/build/desktop/` (zip, sha256, info).

## 🚀 Deployment

**Workflow File**: `.github/workflows/deploy.yaml` (manual-only — `workflow_dispatch`; hosted GitHub Actions runners are billed, so this is not wired to run on every merge).

### Deployment process (`deploy.yaml`)

1. **`build-widgetbook`** (self-hosted) — Flutter SDK setup, `melos bootstrap`,
   `flutter build web --release --base-href /`. Build failures fail the workflow.
2. **`build-docs`** (hosted `ubuntu-latest` — see "Why hosted" below) — Flutter SDK setup, Jaspr CLI install, `dart pub get`/`flutter pub get` in `docs_site/`, `jaspr build`, merge the Flutter embed's own `main.dart.js`/`flutter.js` into the Jaspr output, then a sanity check that fails the job if essential files/split parts are missing (see the job's own inline comments for the exact failure mode this catches).
3. **`deploy-widgetbook`** — downloads the Widgetbook artifact into
   `app/coui_widgetbook/build/web`, checks essential files and the root base href,
   then deploys through `FirebaseExtended/action-hosting-deploy` using that app's
   `firebase.json` and the existing `FIREBASE_SERVICE_ACCOUNT_IM_COCODE_COUI` secret.
4. **`deploy`** — after both the docs build and Firebase publication succeed,
   publishes the `docs` artifact with `.nojekyll` + the `coui.cocode.im` CNAME to
   GitHub Pages. Its `/widgetbook/` page redirects to the new host, preserving
   query parameters and the story hash. A failed Firebase publication does not
   publish the redirect.

The two builds run in parallel. Both domains are shown separately in GitHub
deployment environments (`github-pages` and `widgetbook-production`).

### Why `build-docs` runs on hosted (`ubuntu-latest`), not self-hosted

The self-hosted runner has reproducibly produced incomplete Jaspr output (missing `main.client.dart.js` split parts / DDC packages / images) **while still reporting success**. A fresh `ubuntu-latest` environment has been reliable. `build-widgetbook` (plain `flutter build web`, no Jaspr build daemon) doesn't have this failure mode and stays self-hosted.

### Renderer determinism (#3378)

Both Flutter web builds (`build-widgetbook`'s direct `flutter build web`, `build-docs`'s `jaspr build`-driven Flutter embed) are pinned to **CanvasKit** — neither passes `--wasm`/`--experimental-wasm`. This is intentional, not an oversight: Skwasm falls back to JS on unsupported browsers, meaning a single build could ship two different rasterizers depending on the visiting browser — the opposite of the determinism the parity pipeline (Project #3593) depends on. See the inline comments at each `flutter build web`/`jaspr build` call site (`deploy.yaml`, `parity-nightly.yml`, `app/coui_widgetbook/scripts/deploy_web.sh`) for the same note kept next to the actual invocation.

### CanvasKit is served from Google's CDN, by decision (#3655)

Neither build passes `--no-web-resources-cdn`, so both fetch CanvasKit from Google's CDN rather than serving a copy of their own. That is a decision, not a gap left open.

**Why not self-host.** Only one of the two builds *can* take the flag: `build-widgetbook` is a plain `flutter build web`, while `build-docs` goes through `jaspr_cli`, whose `FlutterRunner.build()` hard-codes the `flutter build web` argument list and offers no pass-through (read from its source, not assumed). Wiring it on one side only would split the two artifacts under different rules, which the call-site comments exist to prevent; wiring it on both means either an upstream change to `jaspr_cli` or rewriting the CDN URL out of the emitted bootstrap JS after the build — and that rewrite breaks silently the next time Flutter changes the URL shape, unless it comes with a guard that fails the build when the substitution matches nothing.

**Why that trade is acceptable today.** No outage, flake, or parity failure has been attributed to the CDN. The pipeline's determinism requirement is about *which rasterizer* ships, and that is already pinned above; where the pinned rasterizer's binary is fetched from does not change what gets rasterized.

**What would reopen this.** Either of these, as an actual case rather than a hypothetical: an offline/air-gapped CI requirement, or a parity failure traced to CanvasKit version drift between builds. Then self-hosting becomes option 1 (upstream pass-through) or option 2 (post-build URL rewrite) — and option 2 only together with a guard that detects a failed substitution.

### Desktop build (`deploy-desktop.yaml`)

**Workflow File**: `.github/workflows/deploy-desktop.yaml` (manual-only —
`workflow_dispatch`). It is independent of `deploy.yaml`: a different concurrency
group, so neither cancels the other, and a failure here never blocks the web deploy.

1. **`build-macos`** (self-hosted macOS ARM64) — the same environment preparation as
   `build-widgetbook` (Flutter pin, per-runner `PUB_CACHE`, `melos bootstrap`), then
   `scripts/build_macos.sh` runs `flutter build macos --release`.
2. The script **fails hard** unless the bundle id, version, build number
   (`github.run_number`), both architectures (arm64 + x86_64), `codesign --verify
   --deep --strict`, the entitlements in the signature, and the signature after a
   zip round-trip all check out. A green build of a broken app is the failure it
   exists to prevent.
3. The zip, its sha256 and an info file (commit, run, versions) are uploaded as the
   `coui-widgetbook-macos` artifact, kept for 30 days. Re-run the workflow when it
   expires.

Signing is **ad-hoc and the app is not notarized** — it is team-internal. A file
downloaded with `gh` carries no quarantine attribute, so Gatekeeper does not block it;
a file downloaded in a browser is blocked. Widening this to external users means
adding a Developer ID certificate and notarization credentials as secrets and a
sign + notarize step in `build_macos.sh`. Windows and Linux have no pipeline: Flutter
desktop builds only on the target OS and every self-hosted runner is macOS, so they
would need hosted runners.

Install and update instructions for teammates:
[Widgetbook README](app/coui_widgetbook/README.md#macos-데스크톱-앱-팀-내부용).

## 🛠️ Local development

### docs_site

```bash
cd docs_site
dart pub get
flutter pub get   # resolves the embedded Flutter previews
jaspr serve
# Visit http://localhost:8080
```

### Widgetbook

```bash
cd app/coui_widgetbook
flutter pub get
flutter run -d chrome
```

## 🔧 Configuration

### GitHub Pages settings

1. Repository Settings → Pages → Source: GitHub Actions.
2. `deploy.yaml` handles the rest.

### Base URL / path configuration

- docs_site: deployed to `/` (root of the Jaspr build).
- Widgetbook: deployed to `/` on `coui.cocode.studio` (`--base-href /`).
- Legacy links: `docs_site/web/widgetbook/index.html` redirects
  `coui.cocode.im/widgetbook/` to the new root host. Keep its script when changing
  the destination so bookmarked `#/?path=...` links continue to work. Without
  JavaScript, the page provides a normal link.

### Firebase Hosting settings

- Project and default Hosting site: `im-cocode-coui`.
- Custom domain: `coui.cocode.studio` → `im-cocode-coui.web.app` (CNAME).
- App configuration: `app/coui_widgetbook/firebase.json`; `build/web` is public,
  and SPA requests rewrite to `/index.html`.
- Authentication: repository secret `FIREBASE_SERVICE_ACCOUNT_IM_COCODE_COUI`
  contains the service-account JSON used by the Hosting action. Local Firebase
  login is not required for the GitHub Actions path.
- The service account must retain permission to publish Hosting releases in this
  project. Authentication/upload failures must remain failures, not skipped steps.

## 📝 Adding new components

1. Implement the component in `packages/coui_flutter/lib/src/components/` and `packages/coui_web/lib/src/components/`. Follow the [contributor guide for adding components](docs/contributing/first-change.md#새-컴포넌트를-추가한다면).
2. Export from `packages/coui_flutter/lib/coui_flutter.dart` / `packages/coui_web/lib/coui_web.dart`.
3. Register the component with `docs_site` by adding example files, registry entries, and `docs_core/content/components/<slug>.md`.
4. It becomes visible on the next `docs_site` deploy.

## 🐛 Troubleshooting

### Build failures

1. Check the `build-docs`/`build-widgetbook` job logs in the Actions tab — `build-docs` has an explicit "Verify build output" step that names exactly which files/split parts are missing rather than silently publishing a broken site.
2. Reproduce locally: `cd docs_site && jaspr build` (or `flutter build web --release --base-href /` in `app/coui_widgetbook`).

### New domain still shows an old Widgetbook

1. Check **Deploy Widgetbook to Firebase Hosting**, not only the Pages job or a
   successful artifact upload. The Hosting action must publish the live channel.
2. Confirm `projectId: im-cocode-coui`, `entryPoint: app/coui_widgetbook`, and the
   root base href. Check the custom domain's DNS and certificate if HTTPS fails.
3. Reload the app, then check real stories, language/theme controls and font
   requests. HTTP 200 for `index.html` alone is not runtime verification.

### Components not showing

1. Verify the component is exported from both platform barrel files.
2. Verify the `docs_site` registration (`process/docs-site.md`) is complete — a missing registry entry is the most common cause.

## 🔐 Permissions

`deploy.yaml` requests `contents: read`, `pages: write`, `id-token: write` — configured in the workflow file itself.
The Firebase job narrows its GitHub token to `contents: read` and authenticates
to Firebase with the separate Hosting service-account secret.

## 📚 Resources

- [Jaspr Documentation](https://docs.page/schultek/jaspr)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Firebase Hosting GitHub integration](https://firebase.google.com/docs/hosting/github-integration)
