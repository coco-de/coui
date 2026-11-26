# Documentation discovery verification — 2026-11-06

Base: `1dd36c7b3` (`origin/main`). Scope: docs_site, docs_core search/catalog and preview composition, docs_app search adapter.

## Implemented behavior

- The shared Command index searches Korean aliases, descriptions, components, blocks, getting started, tokens, accessibility and all guide pages. Both Web and Flutter adapters consume the same keywords.
- Component pages show basic usage before Live Preview while retaining the original fragment IDs. A variant selector mounts one paired Web/Flutter example; code starts collapsed. Delegated platform switching and copy also work on newly mounted examples.
- Theme tools expose Flutter/Web setup snippets and a share URL retaining surface style and light/dark mode.
- The component catalog filters by query and category, announces counts, handles empty results/reset, and clears filters when following category fragments.
- The mobile landing header exposes all guides and categories before hydration, supports Escape/outside dismissal, and keeps the existing sidebar menu on manual pages. Landing content has its own stacking context so preview/hero layers cannot cover the menu.

## Automated checks

- `dart test` in docs_site: **154 passed, 1 failed** (existing gallery gzip budget).
- `flutter test` in app/docs_app: **60 passed**. The existing narrow Markdown sweep prints contained preview overflow diagnostics, but its assertions pass.
- `flutter test` in docs_core: **1610 passed, 14 failed**. The exact same 14 failures reproduce after restoring all three changed docs_core sources to the base commit; task sources were restored in a `finally` block. They cover Figma mapping/snapshot, existing chain snippet conventions, and file-input/item-picker Flutter preview overflow. See [baseline-failures.txt](baseline-failures.txt).
- Catalog gzip before/after: **73.4 → 77.4 KiB**, existing gate **<64 KiB**. The added search and filter controls account for the increase; the gate was not relaxed.
- Targeted SSR coverage verifies a single gallery client boundary, one paired preview, collapsed code, platform configuration templates, mobile destinations, and retained reading anchors.

Known baseline failures remain explicit exceptions to the broad preflight result. This change does not claim a fully green repository test suite. No tests were removed, disabled, or weakened to hide these failures.

## Browser evidence

Local browser checks use Ego Browser task space 21. Clipboard APIs are mocked on the task page, so checks compare produced text without reading the system clipboard.

- `버튼` returns Button and FAB; selecting Button reaches `/components/button`.
- Button basic usage starts at **594px**, versus **13,008px** in the preceding production audit (1200px desktop viewport). Paired preview count falls from 10 to 1.
- Selecting secondary updates both preview IDs and both code snippets. Selecting chain and shuffling changes the permutation, Web view, Flutter view and URL.
- Catalog `버튼` yields 2 cards; combining Form yields 0 and shows the empty message; reset and `#form` restore the full catalog.
- Style/mode changes update the exported APIs; share URLs retain both values.
- Mobile menu at 390×844: panel x=16, y=74, width=358, max height=754; document scroll width=390. Escape closes it and returns focus. A guide link reaches `/guides/theming`.

[Mobile menu, light mode](mobile-menu-light.png)

## Release build and final checks

- `jaspr build`: completed, **355 generated routes**, 357 HTML files including static entries, **49 client split parts**. Flutter `main.dart.js` and `flutter.js` were merged exactly as the deployment workflow does. All workflow sanity checks pass. CNAME is added later by the deploy job.
- `dart analyze --fatal-infos` on the changed libraries and new/changed tests: **No issues found!**
- `dart format --set-exit-if-changed --output=none`: **24 files, 0 changed**.
- `node --check docs_site/web/docs-shell.js` and `git diff --check`: exit 0.
- Release browser: secondary mounts Web/Flutter secondary IDs and the secondary snippet; **1** paired panel and **1** Flutter view. Chain shuffle copies the active Flutter snippet exactly. Reloading the generated chain URL restores both the chain selection and its permutation; code starts collapsed again.
- Release theme export text preserves its original indentation. The copied Web/Flutter snippets retain liquidGlass/dark; toggling light retains liquidGlass and updates code. `테마` returns the theming guide and ThemeController.

[Theme export, dark mode](theme-tools-dark.png) · [Chain preview, light mode](preview-chain-light.png) · [Catalog filter, light mode](catalog-filter-light.png)
