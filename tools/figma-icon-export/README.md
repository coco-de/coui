# CoUI Icon Export (Figma plugin)

Generates a full **App Icon + Splash Screen** variant matrix — every platform
(iOS Light/Dark/Tinted, Android Adaptive layers, Android legacy, macOS/
Windows/Linux, Android 12+ splash) × every flavor (Production/Development/
Staging) — from **one selected logo component**, then exports each variant as
a PNG under its real shipped filename. No manual safe-zone math, no manual
renaming.

This was extracted from a manual build (Figma Plugin API scripting) done
against a real app's icon pipeline (`icons_launcher` + `flutter_native_splash`
— see the source project's `.claude/rules/app-icon-splash-guidelines.md` for
the safe-zone numbers this plugin encodes). It follows the same architecture
as `tools/figma-token-sync` in this repo (generate/export command pair,
`figma.ui.postMessage` → browser download) — read that plugin's README first
if you're unfamiliar with the pattern.

## Usage

1. Select your logo **component** on the canvas (not an instance — the
   plugin needs the actual master so it can reuse it across all 36 variant
   slots via Instance Swap).
2. Pick a background color (used for every opaque platform except the three
   iOS variants, which each have their own fixed treatment — see below).
3. Click **Generate Icon System**. This builds/replaces an "App Icon Export"
   page with two component sets:
   - `App Icon` — 9 platforms × 3 flavors = 27 variants
   - `Splash Screen` — 2 platforms × 3 flavors = 6 variants
4. Click **Export All PNGs**. Every variant downloads as a correctly-named
   PNG (e.g. `ic_foreground_dev.png`, `splash_logo_android12.png`) — drop
   them straight into your project's `assets/icons/` (or wherever your
   `icons_launcher.yaml` / `flutter_native_splash.yaml` point).

Re-running **Generate** is idempotent — it removes and rebuilds the two
component sets by name, so you can safely re-run after editing the logo
master or changing the background color.

## Safe-zone rules encoded (see `src/spec.ts` for the single source of truth)

| Platform | Background | Logo treatment | Safe-zone guide |
|---|---|---|---|
| iOS Light | fixed `#FFFFFF` | full-bleed | squircle keyline (decorative) |
| iOS Dark | fixed `#1C1C1E` (flat approximation — real assets often use a subtle gradient) | full-bleed | squircle keyline |
| iOS Tinted | fixed `#000000` | **every fill overridden to a single gray tone** (iOS 18+ tinted icon requirement) | squircle keyline |
| Desktop (macOS/Windows/Linux) | your background color | full-bleed | squircle keyline |
| Android Background | your background color | none (pure background layer) | 61.1% circle |
| Android Foreground | transparent | 0.8× scale (~54-57% content) | 61.1% circle |
| Android Monochrome | transparent | 0.8× scale | 61.1% circle |
| Android Legacy (square/round) | your background color | full-bleed | full canvas |
| Splash — Normal (iOS/Android/Web) | your background color | full-bleed | none (no masking) |
| Splash — Android 12+ | your background color | **0.84× scale** (lands at ~57-60% content) | 66.7% circle |

The `Show Safe Zone Guide` component property defaults to `false` so a naive
export never bakes the guide into a shipped asset — **Export All PNGs** also
force-hides it regardless of the toggle state, as a second line of defense.

## Known limitations / not in scope (v1)

- Only one `Logo` component is supported per run — there's no per-platform
  logo override in the UI (use the `Logo` Instance Swap property on an
  individual placed instance if you need to preview a different mark).
- The "Branding Wordmark" (bottom-right splash badge, often empty in
  production and a small DEV/STG tag otherwise) isn't generated — its
  behavior differs categorically from the rest of the matrix (presence/
  absence per flavor, not a rescale), so it's left as a manual follow-up.
- `windows`/`linux` share the same treatment as `macOS` (`Desktop` platform)
  since most `icons_launcher.yaml` setups point all three at the same source
  image; if your project ever needs a genuinely different Windows/Linux icon,
  split that platform entry in `src/spec.ts`.
- Export downloads files individually (matching `figma-token-sync`'s
  `export-dart` pattern) rather than bundling a ZIP — 36 browser downloads.
  Worth revisiting with a bundled zip library if that proves annoying in
  practice.

## Development

```bash
npm install
npm run typecheck   # tsc --noEmit
npm run build        # esbuild → code.js
npm run watch         # rebuild on change, for local plugin dev in Figma
```

Load `manifest.json` via Figma Desktop → Plugins → Development → Import
plugin from manifest.
