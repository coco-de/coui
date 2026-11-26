# DotIndicator verification checklist — integrated source d63205414

This is a work-in-progress evidence ledger, not component approval. The source
is the local integration of #5737, #5739, #5741 and #5743 plus the RTL fix.
Each item states what was actually run. “Partial” and “Not run” are not pass.
Commands use Flutter 3.47.6 on PATH; browser work uses Ego Lite. Numbers
correspond to `.claude/skills/unify-component/verify.md`.

## 7-1 Analyze — partial

Command: `dart analyze` separately on the core contract, Flutter and Web
DotIndicator directories, and both docs preview example directories. Expected:
zero errors/warnings and info-level findings compared with baseline. Evidence:
core 0/0/0, Flutter 0/0/3, Web 0/0/10, docs 0/0/0 (error/warning/info).
The 13 infos have not all been rechecked against the integration base.

## 7-2 Format — pass

Command: `dart format --set-exit-if-changed --output=none` on the three
DotIndicator source directories. Expected zero changed. Evidence:
`Formatted 8 files (0 changed) in 0.02 seconds.`

## 7-3 Example/code parity — pass

Command: `rg -n '(class |extends (Stateless|Stateful)(Widget|Component))' docs_core/lib/previews/examples/{flutter,web}/dot_indicator/*`.
Evidence: default and chain examples and their code strings use StatefulWidget
on Flutter and StatefulComponent on Web. Source from each example class matched its corresponding snippet after whitespace normalization for default and chain on both platforms (4/4).

## 7-4 SSR tokens — pass

Command: `jaspr serve --release --port 20530 --web-port 20531 --proxy-port 20532`, then curl the DotIndicator page. Evidence: HTTP 200,
341425 bytes; `activeLength` present; invalid inline `background-color` token
names 0 and `bg-rgba(...)` classes 0. Token class examples include `text-on-surface`, `bg-surface-container` and `border` classes; the two forbidden patterns had zero matches. The generated client options were altered by the local builder and
are restored after the server stops.

## 7-5 Visual parity — fail

Command: Ego Lite screenshots of the integrated Web before and after; Pillow
compares the 400×650 top-left preview region. Evidence: 0 changed pixels; full
screens have different viewport dimensions. Earlier Flutter/Web light preview
inspection and screenshots are in the adjacent report. Release docs light/dark screenshots were inspected in Ego Lite: dots and selection align, but in dark mode Web preview background is RGB (33,41,58) and the Flutter canvas background is RGB (21,23,27). The embedding `preview_app.dart:201` intentionally paints an opaque surface to avoid a CanvasKit transparency problem; it remains an unresolved docs surface mismatch. The original CoUI Figma md/selected 3 reference (88×24) was compared to latest-main default preview crops: exact RGB difference Web 184/2112 pixels (8.712%), Flutter 380/2112 pixels (17.992%); see the [reference and crops](README.md#original-coui-figma-component-comparison). These include anti-aliasing and are not whole-screen rates. Full theme/surface matrix remains unverified. [Light](docs-light.png) and [dark](docs-dark.png).

## 7-6 Contract/style/theme/resolver — partial

Command: `./scripts/guards/resolver/verify_contracts.sh` and
`./scripts/guards/tokens/check_design_tokens.sh --phase 7`. Evidence: both
passed on the integrated branch; resolver reported seven non-enforced Web
migration-backlog warnings in unrelated components. Full 7-6 subchecks and
field-by-field table not completed.

## 7-7 Contract completeness — pass

Command: `rg -n 'implements CoreDotIndicatorContract|final .* (index|length|onChanged|direction|size|dotIndicatorStyle)'` on both widgets.
Evidence: Flutter and Web implement `CoreDotIndicatorContract` and each expose
all six contract fields: index, length, onChanged, direction, size, dotIndicatorStyle. Both implement the platform-specific generic contract.

## 7-8 Parameter naming — pass

Command: inspect both `DotIndicator` constructors. Evidence: index, length,
onChanged, direction, size and dotIndicatorStyle match; Web additionally
inherits id/classes/css/attributes/eventHandlers and both inherit key. The Web-only inherited attributes are platform infrastructure; the six component contract parameters agree.

## 7-9 Colors/tokens — pass

Command: release docs SSR inspection. Evidence: zero invalid inline color token
names and zero bg-rgba classes. Source regex checks for literal inline token names, bg-rgba classes, and `var(--color-` each returned 0 matches. See [static audit](static-audit.json).

## 7-10 Disabled state — N/A

Source regex scans on both component directories found 0 `Opacity(` and 0 `opacity-50` uses ([static audit](static-audit.json)). The contract has no disabled state; null `onChanged` makes the indicator passive. Passive semantics tests pass; dedicated disabled tokens are not applicable.

## 7-11 Unified internal components — pass

Source scans for GhostButton, PrimaryButton, SecondaryButton, OutlineButton, DestructiveButton, LinkButton and CalendarItem found 0 matches ([static audit](static-audit.json)). DotIndicator itself is the component under audit, not a legacy nested instance. The widget uses shared Clickable/TouchTarget.

## 7-12 Exports — pass

Command: inspect exports and component files. Evidence: all four core contract
files and the Flutter/Web widget and style files are exported. The core contract directory has four files and all four are exported; both platform widget/style files are exported. Deprecation is considered separately in 7-13.

## 7-13 Legacy deprecation — N/A

The DotIndicator component directories contain the public DotIndicator implementation and resolver, with no separate legacy widget class or `@Deprecated` entry. There is no legacy class in these directories to deprecate; no migration/removal is part of these PRs.

## 7-14 Web structure — pass

Command: `ls packages/coui_web/lib/src/components/display/dot_indicator`.
Evidence: `dot_indicator.dart` and `dot_indicator_style.dart` exist. The widget imports `dot_indicator_style.dart` and source search found no prohibited `classes:` token assembly; the resolver owns classes/inline styles.

## 7-15 Docs registration — pass

Command: search four preview registries, `component_catalog.dart` and the
component markdown. Evidence: all four registries contain `dot-indicator`;
catalog contains one mention; docs API test suite: 11 passed. `component_catalog.dart:456` contains one slug entry. The markdown refers to the current DotIndicator name; no separate legacy component was identified.

## 7-16 Preview constraints — pass

Command: `rg -n dot-indicator docs_core/lib/shared/preview_{constraints,layout}.dart`.
Evidence: `preview_constraints.dart:494` registers `kDocsCompactConstraints`;
no `preview_layout.dart` match. The widget is an intrinsic-width row of markers with no expanding text or wide child; screenshots show it centered in the compact preview. The wide set is not applicable.

## 7-17 Typography hierarchy — N/A

Inspection of both DotIndicator widgets shows visual markers with no text/title/subtitle slots. Accessible labels are semantics, not painted typography.

## 7-18 Pointer affordance — pass

Command: Ego Lite click/keyboard checks and 2,180 Web / 2,239 Flutter targeted
tests. Evidence: Flutter uses shared `TouchTarget`/`Clickable` plus `MouseRegion`; Web uses `Clickable` and the touch-target marker. Source search found zero InkWell/TextButton/IconButton uses; actual LTR/RTL pointer and keyboard checks passed.

## 7-19 Flex safeguards — N/A

Source inspection: the root uses `WebLayout.flex` plus `flexRow`/`flexCol` and `itemsCenter`; it contains marker boxes, no text or width-filling flex child. `w-full`, `min-w-0` and break-words are not applicable to this intrinsic-width component. Light/dark screenshots show the markers within the preview pane.

## 7-20 Animation parity — pass

Command: inspect Flutter AnimatedContainer/AnimatedScale and hydrated Web style.
Evidence: Flutter uses `resolved.transitionDuration`; Web computed duration
`0.2s` and visual-only transition properties. Both platform resolvers fall back to `CoreDotIndicatorStyle.defaultTransitionDuration`; Flutter applies it to AnimatedContainer/AnimatedScale, and Web computed duration was 0.2s. RTL spacing is deliberately immediate to avoid overlapping targets. A frame-by-frame animation comparison and every theme are not claimed.

## 7-21 Variants — pass in supplemental draft #5749

The original registry only had default and chain. Supplemental draft #5749 adds vertical and passive examples and snippets to both platforms and declares them in the gallery. Widget tests exercise vertical selection and passive configuration; the overflow test passes 1024/1440 viewports and all densities at an 88px stage. Ego Lite release docs on latest main showed default, vertical, passive and chain, and both platforms changed the vertical selection on click. The supplemental PR is not merged; the original branch alone does not satisfy this check.

## 7-22 Markdown API — pass

Command: `dart run tool/generate_style_tables.dart --check dot-indicator` and
`dart test test/registry/docs_api_sync_test.dart` from docs_core. Evidence:
1 slug, 0 drift; 11 tests passed; generated table includes `activeLength`.
The Props table lists index, length, onChanged, direction, size and dotIndicatorStyle, matching the six shared constructor parameters; Web infrastructure parameters and key are inherited.

## 7-23 Hardcoded tokens — pass

Command: design-token guard phases 1–7. Evidence: guard passed. The required duration, EdgeInsets, BorderRadius, Web px and Tailwind scale literal patterns found no matches in either component directory ([static audit](static-audit.json)).

## 7-24 Computed Web styles — partial

Command: Ego Lite on release docs hydrated DOM, `getComputedStyle` of dot
markers. Evidence: default 8×8px, `rgb(207, 209, 212)`, outline none,
transition duration 0.2s and explicit visual/size/transform transition list;
margin is absent. Ego Lite keyboard focus exposed a selected-dot solid 3px ring in RGB (244,245,246), offset 0px and no box shadow; unfocused was transparent 2px outline, offset 2px and no shadow. All states and surfaces are not fully inspected. The standard CDP script was not used because browser use is limited
to Ego Lite.

## 7-25 Reverification loop — incomplete

Targeted Core 6, Flutter 2,239, Web 2,180, localization generator and token
guard passed after the RTL change. Full checklist rerun is incomplete and the
PRs remain draft; no merge approval follows.

## 7-26 Token resolution — pass

Flutter resolver inspection shows all four color paths (`activeColor`, `inactiveColor`, `inactiveBorderColor`, `hoverBorderColor`) use `colorScheme.resolve(...).toValue()`. The required direct-color, raw argb, transparent sentinel and typography regex checks each returned 0 matches ([static audit](static-audit.json)).

## 7-27 Six-layer field mapping — not run

The required complete field table and common-token audit are not completed.

## 7-28 Web resolved chrome — pass

Command: `rg 'class ResolvedDotIndicator|WebElementChrome|WebResolvedChrome'`
in the Web resolver. Evidence: root and per-dot resolved types implement
`WebResolvedChrome` and hold `WebElementChrome` slots. The required flat `String/Styles` chrome fields and inline Tailwind widget assembly checks returned zero matches ([static audit](static-audit.json)); root and per-dot each expose `WebElementChrome`.

## 7-29 Enum conversions — pass

The four required pattern scans for file-local mappings, Core extensions, mapping helper classes and Tailwind extension getters returned zero matches ([static audit](static-audit.json)). The Core DotIndicator size enum selects shared `defaultsBySize`; no component-specific Core-to-Core conversion is present. The repository resolver contract guard additionally passed its enum-mapping phase.

## Latest main integration recheck — 2026-10-28

The integration was merged without conflicts onto CoUI main `deb49b5fe`. Its
source with the preview-stage fix and density test correction was `6eb1d2ccb`;
subsequent visual transition and generated metadata commits were included in
`1b595c9d4`. Full tests started before the last two commits, so they are not
presented as a full-suite pass for `1b595c9d4`.

- Flutter `flutter test --no-pub --coverage --exclude-tags parity,golden
  --concurrency=2`: **9,161 passed** at `6eb1d2ccb`.
- Web `dart test --coverage=coverage --exclude-tags perf --concurrency 2`:
  **6,959 passed, 4 failed** at the initial latest-main integration
  `41dbcc889`. One stale physical-margin density expectation was corrected;
  its 37 cases and the combined style/density set of **56 cases** pass at
  `1b595c9d4`. The remaining three Badge preview failures (each expects one
  span and finds two) also reproduce against clean `deb49b5fe`.
- Core `dart test --coverage=coverage --exclude-tags perf --concurrency 2`:
  **5,728 passed, 2 failed** at `6eb1d2ccb`. The census gate reports deficit
  228 against 227 even on clean `deb49b5fe`. The other failure was stale
  `components.json`; after official regeneration, all **14 exporter tests**
  pass at `1b595c9d4`. The export nevertheless classifies `activeLength`
  as `absent`, while its fallback is resolved `dotSize`, not an absent
  marker. A semantic reader/schema remedy is required before trusting the
  Figma fidelity result; this has not been marked passed.
- The last visual-property change preserved `box-shadow` in the transition
  list. Ego Lite retest of `1b595c9d4` rebuilt Web preview: 3/3 immediate
  RTL first selections reached item 2, and computed transition includes
  `box-shadow` while excluding margins. The prior broader test covered 30/30
  centres, axes, directions and marker sizes, but predates this last change.
- `dart analyze . --fatal-warnings` on `41dbcc889`: 0 errors and warnings,
  2,755 infos. Workspace format: 4,936 files, 0 changes. Token/resolver
  guards and generated docs table check passed. No physical screen reader
  was available. This is not a full-platform or full-theme approval.

### 7-27 supplemental inspection — partial

All 12 declared style fields (`spacing`, `padding`, `dotSize`, `activeLength`,
`borderRadius`, `activeColor`, `inactiveColor`, `inactiveBorderColor`,
`inactiveBorderWidth`, `hoverBorderColor`, `transitionDuration`,
`focusOutlineStyle`) occur in Core and both resolvers. Flutter consumes the
resolved fields; Web consumes the emitted per-dot/root chrome. `dotSize` and
`spacing` use size-keyed defaults rather than a single static default, and
`activeLength` uses `defaultActiveLength(resolvedDotSize)`, a dynamic default.
The two platform resolver files contain no direct common-token static access
for the checklist's six token classes. This source inspection is **not** a
completed six-layer field-by-field mapping and does not solve the derived
Figma export issue. 7-27 remains partial.
