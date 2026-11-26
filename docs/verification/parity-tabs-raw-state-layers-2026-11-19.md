# Tabs raw state-layer verification — 2026-11-19

Issue: #6440, Part of #6131. Product/test commit `bb3bb59669f571f15e5cff50ecbe4bdb3c5cca40` on base `f27dc733a85fb1af499112a4ebf8affab58674f9`. The only production changes are the Web Tabs widget and its internal resolver. No push or PR was performed by this worker.

The existing `CoreTabsStyle.hoverStateLayerColor`/`pressedStateLayerColor` accept raw ARGB, but Web previously omitted them whenever `token == null`. Native resolves them and uses `Color.alphaBlend` over the current tab fill. Replacing Web `background-color` would erase a selected pill's indicator, so a raw instance now uses the repository's existing state-layer representation: a flat gradient over its existing background colour, as ThemeConfig/ToggleGroup already do. Colour conversion remains the existing `CoreColor.toValue()`.

When either state is raw, both hover and pressed use the same Element-owned private scope; the later pressed declaration wins. Disabled faces carry no scope. The all-token branch retains its previous classes and emits no new style. The private scope ignores caller IDs and survives the owning Element's rebuild/remount rules. A reused const configuration at two tree locations gets separate scopes. No new exported API, constructor parameter, Core field/token/default, JSON schema, dependency, comparison criterion, baseline or skip is introduced.

## Local verification

| Evidence | Result |
|---|---:|
| Initial new regression tests against old production | 7 tests: 5 fail, 2 pass |
| Final new regressions plus existing Tabs/close/scroll suites | 61 pass (10 new) |
| Touched fatal-infos / final format drift | 0 / 0 |
| Complete contract guard | exit0, seven existing non-enforced WARNs |
| Final actual Native controls with canonical fonts | 132 rows, each rest/hover/pressed |
| Actual Web before / after SSR / optimized hydration | 132 / 132 / 132 rows |
| Browser errors / external requests | 0 / 0 in every phase |
| Default/custom-token rows changed before/after | 0 of24 |
| Disabled rows changed before/after | 0 of44 |
| Rest rows changed before/after | 0 of132 |
| SSR versus hydration state/paint/geometry changes | 0 of132 |
| All-token/default serialized HTML subtrees | 4/4 byte-equal |
| Raw instance scope ownership, per theme/phase | 18 instances /18 unique scopes |
| Actual raw-colour paint samples before | 8/24 exact, max channel delta237 |
| Actual raw-colour paint samples after / hydrated | 20/24 exact, max channel delta1 |
| Standard docs build (`jaspr build --optimize=2`) | 359 routes, exit0, 103.72s |
| Build tracked source delta | 0 of22,550 paths |

The state controls cover both variants, opaque/alpha/transparent washes, mixed raw/token fallbacks, selected and disabled-selected faces, closable faces, a raw selected indicator, and caller root CSS gradients/classes. The field/state/geometry comparisons are exact; the paint sample numbers are observations without relaxed thresholds. The four remaining one-channel sample differences follow the existing shared Web conversion's two-decimal raw alpha (`128/255 → 0.50`, `64/255 → 0.25`) versus Native blending. They are not labelled unavoidable AA or exact pixel parity. Whole images are not claimed equal: the declared fixture includes a common opaque grey underlay and each platform retains its existing intrinsic layout. Original PNGs are never edited or promoted to baselines.

The final Native images register the same13 static Pretendard/Geist Mono OTF masters used by the Web capture harness, through the unchanged repository `loadParityFonts()` helper. Earlier unregistered-font controls remain under `native/` and `native-records.json`; they are not used for the final UI comparison. `canonical-font-binding.json` records the masters and helper hashes. The final evidence is `native-with-fonts/` and `native-with-fonts-records.json`.

The public Tabs class AST and existing internal renderer signatures/const constructor are unchanged. The new rules type/function live in `tabs_style.dart`, which is absent from the public barrel's361-library local export closure. Core Tabs contracts/themes/styles, Native Tabs, the public Web barrel, scope/conversion/ThemeConfig helpers, lockfile and232-package environment are byte-unchanged. Receipts bind these statements.

An owned Dart VM rendered the changed actual Tabs SSR, completed `reloadSources` successfully, rendered it again with the raw layer/private scope, and closed normally (HTTP200 before/after). This is a no-change SSR VM reload smoke check, not a Flutter app source-migration claim. Browser/server and docs build process group also closed; both recorded listening ports are closed.

## Limits and preserved earlier attempts

The original pure-token/default `hover:bg-on-surface/8` and `active:bg-on-surface/16` classes still produce no CSS in pinned Tailwind3.4.17. The actual rule dump and working error/25, primary/50 controls are preserved in `css-observation.json`. Pure-token selected-pill fill replacement also remains the previous behaviour; this PR fixes the raw-instance layer path, not every Tabs interaction. The new gradient path follows the existing repository state-layer mechanism. Intermediate animation parity was not assessed; the active-indicator transition values are unchanged.

Caller `css`/`classes` are applied to the public tablist, while the affected face is an internal span with no public gradient/ElementStyle slot. The caller root's gradient and child badge/close-button paint are preserved. Arbitrary external selectors aimed directly at private face markup still participate in the ordinary CSS cascade; universal compatibility with private-DOM overrides is not claimed.

Initial missing-method/nullable-console harness failures, touch-highlight controls and early Tailwind readiness attempts remain separately named. Two owned-VM assertions initially expected a different formatting of the shared raw alpha; their closed processes/logs are preserved. Only the corrected completed runs are reported as successful.

The changed-path tier1 manifest selects40 Tabs cells. The direct field/state controls above are the scoped verification; the official40-cell own-baseline VRT and the816-cell/full3814-style sweep were not rerun. The previous default582/234 pixel and402/368 property(+46 structural skip) results remain the last measured totals, not this head's new measurement. No default234 reduction, full manual CI, deployment, Figma Generate or designer approval is claimed. Core/design/export data are unchanged, so Figma is not an affected design axis.

## Artifacts

Raw audit root: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-tabs-raw-wash-audit-20261119.c8plry09`. Implementation proof: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-tabs-raw-wash-audit-20261119.c8plry09/implementation`. `selected-evidence8.json` selects exactly8 original PNGs (two paint cases × light/dark × Native/Web), already viewed by this worker; Root reviews/uploads them via the repository pr-evidence skill. No asset upload was performed here. `artifact-index.json` binds preserved proof files; browser profiles remain on disk but are excluded from the index.
