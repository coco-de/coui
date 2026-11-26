# Token Tabs state composition — 2026-11-19

Issue #6448, Part of #6131. Verified product/test commit `cbc478159a9b94f9fb8cc7ad00d105fef8ef2a58`, based on merged raw Tabs #6446 at `64dd884831f12ee4d39aef9be3263481e94b168e`. Production changes only `packages/coui_web/lib/src/components/navigation/tabs/tabs_style.dart`. This worker has made local commits only; Root owns publication.

Previously, token hover/pressed utilities replaced the selected pill fill instead of composing over it. A caller's inline raw indicator could also prevent those utilities from applying. Tabs now uses the existing `stateLayerWashCss` recipe for the two per-face token fills and the existing Element-owned style child for hover/pressed selectors. Pressed remains last. The local priority follows Badge's existing pattern so the composed state can cover its own inline indicator base. Rest paint, disabled gating and the raw/mixed registered-colour gradient path remain intact. No colour, opacity, duration or design token is added.

The weight adapter preserves the existing Web token conversion: `.375` remains37%, `.255` remains25%, and `.005`/`.009` remain0%. It does not change shared helper precision to fit Native. The selected base follows the existing indicator merge; an inactive or underline face has a transparent base. Browser variables still resolve the live token/theme values. All-token Tabs now allocates the same private Element scope already used by raw Tabs. Its prefix differs from the roving host prefix; the shared context allocator is retained. Public explicit IDs and const constructors are unchanged.

The token face and underline indicator now state `CoreEasing.move` locally. The authoritative `.claude/rules/widget/interaction.md` requires the same easeInOut timing across platforms, and Native Tabs already uses it. Before this correction, Web token faces inherited Tailwind's `(.4,0,.2,1)` curve. Current all-token controls compute the existing CoreMove `(.42,0,.58,1)` at their unchanged resolved0/100/250ms durations. This does not modify global ThemeConfig or the raw/mixed branch.

## Current-source checks

| Check | Result |
|---|---:|
| Initial new regressions against merged base | 9 fail |
| Final focused Tabs/close/scroll/state/roving tests | 102 pass |
| Fatal infos / format drift | 0 /0 |
| Full resolver contract guard | exit0, seven existing non-enforced WARNs |
| Fresh actual Native face rows | 279, each rest/hover/pressed |
| Fresh Web before / after / optimized hydration | 279 /279 /279, each rest/hover/pressed |
| Rest / disabled / mixed unchanged state checks | 279 /303 /108 |
| SSR/hydrated paint-state checks | 837 equal |
| Current SSR/hydrated PNGs | 75/75 byte-equal |
| Before/current rest PNGs | 25/25 byte-equal |
| Isolated raw/mixed SSR in five modes | 5/5 byte-equal |
| Actual natural Web motion | 96 rows ×4 events, timeout0 |
| Actual Native motion | 48 rows ×4 events ×start/half/end |
| Actual roving owner browser integration | 4 pass |
| Optimized docs build | 359 routes, exit0,102.42s |
| Docs build tracked source changes | 0 of22,573 paths |

The real browser is the explicitly pinned bundled **Chrome150.0.7871.24**, not the newer system app. Endpoint, optimized hydration and natural motion runs have browser/console errors0 and external requests0. Motion uses actual pointer hover, press, release and leave; no animation currentTime is forced. Meaningful nonzero transitions have observed intermediate frames; zero-duration controls have animation frames0. Native reads the actual rendered `DecoratedBox` colour, including its intermediate value, with the canonical13-font loader. Every Native motion endpoint reaches its target. Frozen endpoint screenshots are not motion evidence.

The fixtures reproduce the official `_BuildContextlessWrapper`: `Style(styles:docsContentTheme().styles)` followed by `CoUIWeb(theme:ThemeData.coui)`. A shared fixture `CoreSchemeSource` supplies both Native schemes and Web `ThemeConfig.from(source)`; it covers default light/dark, caller RGB source light/dark and the explicit source-alpha negative. The actual computed root/face/clickable foundation is `border-box`, with `solid` border style and0px border width for these controls. Font/icon helpers and only the official animation-freeze input are used for endpoint capture; natural motion is unfrozen. No target-specific corrective CSS was introduced.

The first measurement used custom `ThemeData` without binding the matching stylesheet source. Its brand mismatch occurred before and after the change. That entire phase and its input scripts remain in `initial-theme-data-only/`, excluded from the corrected results. Literal SSR/client owner strings also differ because independent request/browser contexts allocate their private identities separately. `invariants.json` preserves their complete mapping and unique owners; paint comparison removes only that private identity class. All other classes, inline paint, geometry and state fields are compared. The real roving4 test independently checks30 unique SSR targets,56 keyboard inputs, repeated configuration, explicit IDs, stable rebuild ownership and a new owner on keyed remount.

## Explicit boundaries

Containing-pixel sampling uses the existing positive-coordinate `int`/floor rule, with no threshold change. Among75 selected PNG samples, before32 are exact with max channel delta165; after46 are exact with max32. Outside the deliberately translucent source-palette negative, after max delta is2. These are scoped diagnostic samples, not a global parity count or whole-image equality claim.

The existing Web fractional alpha truncation remains different from Native's fractional colour math. Tiny token opacities `.005` and `.009` intentionally become0%; opaque/raw/alpha selected bases remain the mathematical fill with no token ink contribution. Chrome can serialize an alpha base through zero-percent `color-mix` as `.501961` instead of `rgba(...,.5)`; the alpha-base pressed sample can differ by one raster channel unit while the existing pressed scale also changes its image coordinate. No per-channel correction, hidden tolerance or forced animation bookkeeping equality is added.

The semantic Web CSS vocabulary stores RGB channels and already drops alpha authored on the source palette itself. The same source-alpha representation is emitted before and after this change; the explicit negative remains material, up to32 sampled channel units. This change restores composition within that existing Web representation. It does not claim exact Native parity for translucent token palettes or alter ThemeConfig to conceal the limitation.

Standard browser colour transitions use CSS Oklab/premultiplied interpolation; Native uses `Color.lerp`. Intermediate RGBA is therefore not promised equal, even at the same duration/curve. The natural Web250ms screenshot records its capture window in a sidecar and is not relabelled as Native's exact125ms frame. No channel tween, timing offset or snapping shortcut is introduced.

Already-hovered hydration records one non-hover frame in each old/new light/dark control, with the same node retained throughout. The runs observe17/17/16/17 frames respectively. This shared reconciliation behaviour remains visible and is not masked by delaying capture or moving the pointer. Steady paint and all75 selected PNGs match SSR after hydration; active-transition continuity is not guaranteed.

Caller root `css`/`classes` and its gradient remain intact. Arbitrary CSS selectors into private face markup still follow the ordinary cascade. Permanent tests cover selected/unselected/disabled faces, opaque/alpha/transparent washes, zero/tiny weights, raw and token indicator bases, mixed states, closing and pressed precedence. No skip, baseline, capture comparator or threshold is changed.

## API and environment

Public Tabs AST, existing internal signatures and const constructors are unchanged. The local public export closure is361 libraries for the default target and365 across all four conditional alternatives; `tabs_style.dart` is in neither. Widget, Core, Native, shared colour/scope helpers, ThemeConfig, public barrel and lockfile remain unchanged. The workspace resolves232 packages with the same names and exact root lockfile. The aggregate offline lock-enforced bootstrap generated the workspace configuration, then exited1 only at a separate example without a preexisting lock; that failure is preserved and is not reported as a successful aggregate install. Scoped checks use the generated locked workspace configuration and per-command pinned SDK.

A real owned Tabs SSR VM `reloadSources` smoke succeeds, HTTP200 before/after, with no source migration or received libraries. Browser/server owners, build process group and VM are closed. Build and runtime receipts bind the exact product commit above; documentation-only commits do not change that product source.

Proof root: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-tabs-token-implementation-20261119.x2z4wf96`. The adjacent JSON records source hashes and check receipts. Detailed originals are in `final-source-binding.json`, `paint-current.json`, `invariants.json`, `motion-summary.json`, `api-boundary.json`, `roving-browser/` and the raw execution logs. `selected-evidence8.json` selects eight unedited originals; Root must view them before upload. No images were edited or uploaded by this worker, and prior raw/prototype proof directories remain untouched.

The official40-cell own-baseline VRT,816-cell/full sweep, full manual CI, deployment and Figma Generate were not rerun. No global residual-count reduction or designer approval is claimed.

## Main integration after Dot #6449

Normal merge `b56c83284d04b0f69f6507f6cdf7c26a70fc361b` integrates live main `c6690e18cd13484a7b33a61806cf7b7938e6bee3` (tree `d1cf6eafc57ba41fbd4dfef46542c22fddcbfb9c`). Fetch used the pinned Kim session wrapper. There was no force, history rewrite or product edit during integration. Relative to this new main, the only production change remains `tabs_style.dart`.

Tabs production SHA256 remains `a65dda012478351d578e77aa0772442be0accb5758d3afdc5669ed396d360e7a`. Tabs and its45-file local Web implementation dependency closure, Core, Native, shared conversion/scope/base/theme code and capture sources are unchanged from the verified CBC product. The only inherited Web production change is DotIndicator style, which is absent from that Tabs dependency closure. Public export closure membership remains361/365, both complete closures are byte-identical to integrated main, and Tabs style is still absent. All232 package names, resolved roots, language versions and package URIs match; the root lockfile is exact.

Fresh integrated-source focused tests pass102, fatal-infos passes, the full contract guard exits0 with the same seven existing WARNs, and the actual roving owner integration passes4 with browser errors/external requests0 and browser/server cleanup complete. A fresh owned real Tabs SSR VM reload succeeds HTTP200→200 and closes normally. No-change runtime reload is not a source migration test.

Exactly one fresh optimized docs build completes359 routes, exit0 in85.25s. Its22,580 tracked paths have no source/mode differences, head remains `b56c83284d04b0f69f6507f6cdf7c26a70fc361b`, status is clean and its process group is closed. The prior build was preserved by same-volume rename to `integration-c669/previous-docs-build`; there was no duplicate large build. Remaining disk at completion was2.9GiB.

The original CBC endpoint/Native/motion captures above are reused through the exact unchanged source/environment closure, not relabelled as fresh captures at the merge head. All retained capture script hashes and eight selected PNG hashes still match. Their fractional alpha, source-palette RGB-model loss, CSS interpolation and shared one-frame hydration boundaries remain explicit. New integration receipts are in the original proof root's `integration-c669/`; the adjacent JSON's `integrationC669` section binds exact source and receipt hashes. Historical CBC facts and all earlier receipts remain intact. The final documentation-only commit changes no product or test source.
