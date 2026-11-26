# Raw Tabs motion verification — 2026-11-19

Issue #6440, Part of #6131. Motion product/test commit `74f4e34b705202c473552edc2d257355ba4134a5` follows `bb3bb59669f571f15e5cff50ecbe4bdb3c5cca40` and preserved evidence head `534d46463f33403d8da1756e6d634ab9933b9f8f`. This supplements the [earlier endpoint verification](parity-tabs-raw-state-layers-2026-11-19.md); its files and SHA records were not overwritten. This worker has not pushed or created a PR.

The initial raw-state gradient reached the authored hover/pressed colours but snapped. Native wraps the state-layer colour in `AnimatedContainer`, using the existing resolved `indicatorTransitionDuration` and `CoreEasing.move`. The raw-only Web path now registers a private non-inherited `<color>` property, paints its gradient over the existing face fill, and explicitly transitions that property alongside `all`. The unchanged inline duration and existing Core easing conversion supply its timing. Loading's existing SSR-safe syntax escaping is reused. The selected pill base, pressed precedence, disabled gating, mixed token/raw path and Element-owned selectors remain intact. The all-token/default path is unchanged.

## Verified final source

| Check | Result |
|---|---:|
| Two new motion cases against prior production | 2 fail; existing10 pass |
| Final Tabs/state-layer/close/scroll tests | 63 pass |
| Touched fatal-infos / format drift | 0 / 0 |
| Full contract guard | exit0, seven existing non-enforced WARNs |
| Actual Native timelines | 120 rows ×4 events ×0/half/end |
| Natural Chrome150 motion | 90 rows, including12 old-flat negative controls |
| Natural Chrome157 motion | 90 rows, including12 old-flat negative controls |
| Meaningful transitions with observed intermediate frames | 160/160 per browser |
| Zero-duration / disabled / transparent animations | 0 / 0 / 0 per browser |
| Nonzero transition duration / easing | 100ms or caller250ms / CoreMove(.42,0,.58,1) |
| Browser errors / external requests | 0 / 0 per motion run |
| Final Native / Web SSR / optimized hydration endpoints | 144 /144 /144 rows |
| SSR versus hydrated endpoint field differences | 0 of144 rows |
| Actual Native/Web paint samples per endpoint phase | 20/24 exact, max channel delta1 (containing pixel: int/floor) |
| All-token/default serialized HTML subtrees | 4/4 byte-equal |
| Preserved versus final endpoint PNGs | 24/24 byte-identical |
| Optimized docs build | 359 routes, exit0, 81.13s |
| Build tracked source delta | 0 of22,552 paths |

Natural pointer hover, press, release to hover and leave were observed from the event frame through intermediate frames to the settled result, including zero/default/custom duration, both variants, selected/unselected/disabled faces, opaque/alpha/transparent washes, mixed states, closable faces and caller root CSS. No animation currentTime was forced. The Native timeline reads the actual `DecoratedBox` colour rather than the target `AnimatedContainer.decoration`. It uses the unchanged canonical13-font loader. Endpoint captures deliberately freeze animation and are not used as motion evidence.

The browser versions are separate, explicitly bound runs. The system executable `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` and this worker's preserved endpoint JSON both report `Chrome/157.0.8103.79`. The decisive repeat uses Root's exact bundled Chrome for Testing150.0.7871.24; `chrome150/browser-binding.json` records its executable hash, runtime version and hashes of the reused final HTML/optimized JS. It reuses those inputs via read-only symlinks, without another app/docs build. Safari and Firefox were not run. An engine without typed-property interpolation can paint the authored states but is not promised animated washes; no polyfill or timing shortcut is introduced. Registered properties interpolate according to their registered type. [W3C Properties and Values API](https://www.w3.org/TR/css-properties-values-api-1/#animation-behavior).

## Explicit platform boundaries

This restores standard Web colour motion with the existing Core duration and curve. It does **not** claim exact Native intermediate RGBA. CSS colour interpolation premultiplies alpha; Native `Color.lerp` interpolates its raw colour channels. [W3C CSS Color](https://www.w3.org/TR/css-color-4/#interpolation-alpha). For the inactive raw-alpha case near the halfway point of the100ms hover, Native at50ms is ARGB `4009521e`, while Web is approximately `rgba(18,164,60,.25)`. During hover-to-pressed Native is `60646962`, while Web is approximately `rgba(72,125,85,.376)`. Browser records include actual elapsed time/progress, so these are not relabelled exact50ms browser samples. The difference on transparent bases is material and is not attributed to rounding or AA. No per-channel tween machinery, new design values or Core/Native alteration is added to force equality.

The settled paint's remaining one-channel differences are a separate, existing shared conversion boundary: raw128/255 alpha becomes Web0.50 and64/255 becomes0.25. The shared `CoreColor.toValue()` helper is unchanged. There is no threshold, skip or baseline change and no whole-image parity claim.

An already-hovered hydration control records a brief `:hover` reset during reconciliation. On Chrome150, old raw-flat, new raw, unchanged old token and unchanged new token each show one observed non-hover frame with the same face node and rectangle preserved; the hit-test remains on its content and pointer out/over events recur. Token controls also restart their previous background-colour fade. This shared fixture/framework behaviour remains visible in the records; it is not masked by moving the pointer or delaying the recorder. The157 runs also retain their observations, including runs where that brief frame was not sampled. No claim that hydration always preserves an active transition is made.

Caller `css`/`classes` remain on the public tablist. Its gradient is preserved; the affected internal face has no public gradient/ElementStyle slot. Arbitrary selectors into private face markup still use the ordinary cascade. Whole-bar disabled rendering is also covered by permanent component tests. Default/token utility registration and selected-token composition remain separate work (#5603 and the #6131 follow-up); this change does not silently expand to them.

## API, environment and artifacts

Public Tabs AST and existing internal constructor/function signatures are unchanged, including the const constructor. The default-target local export closure is361 libraries; the union across the four conditional alternatives is365. `tabs_style.dart` is absent from both. The earlier361 count was the default-target count, not the union. Core contracts/styles/themes, Native Tabs, public barrel, conversion/scope/ThemeConfig helpers and dependency files remain byte-identical on all11 recorded paths; the environment still resolves232 packages.

The final source completed a real owned SSR VM `reloadSources` smoke check (HTTP200 before/after) and closed normally. This is a no-change SSR VM smoke, not a Flutter app migration claim. Browser/server owners and the docs build process group also closed. The docs build used the pinned SDK per command and preserved its previous build output by rename; no global SDK/account configuration changed.

Proof root: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-tabs-raw-motion-20261119.e5mavic6`. Final source/output receipts: `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-tabs-raw-motion-20261119.e5mavic6/final`. `motion-summary.json`, `endpoint-summary.json`, `old-final-endpoint-png-binding.json`, each browser's `hydration-audit.json`, and `product-source-binding.json` bind the observations. `selected-evidence8.json` selects eight original motion PNGs as an **alternative** to the old endpoint selection; Root may compose a final maximum-eight PR selection. Natural Web screenshot windows are recorded in sidecars and are not asserted to match the Native125ms screenshot timestamp exactly. No PNG was edited or uploaded here.

The first new timeline accidentally retained the harness's default animation freeze; it is preserved under `initial-default-harness-freeze/` and is not successful motion evidence. Initial duration-token expectations, a wrong scroll-suite filename, CSS whitespace infos, a favicon audit failure with uniquely-owned browser cleanup, and a sample-metadata variable-shadow harness failure are separately preserved. The corrected final runs above pass. Historical534/bb3 source/proof remains intact.

The official40-cell own-baseline VRT,816-cell/full sweep, full manual CI, deployment and Figma Generate were not rerun. No global parity-count reduction or designer approval is claimed. Core/design/export data and public API values were not changed.

## Final main/roving integration — PR #6446

Fresh verification source `274f4ee3200d3df30551394985315f35dc681ba6` includes main `b5a18a24b38481f853cc4770137fa60dfbbd7a5d` (#6445 roving ownership and #6444 existing Core opacity registration). Compared with prior integration `660e66c6dbad02f5f14692001472fcd9656e40d7`, the Tabs file changes only by the expected existing Element helper import and automatic roving-owner expression. The raw motion/style source and permanent motion tests are byte-identical to74f4/660. Against this main, own production paths remain Tabs and its style file only. Public API/const/caller settings/Core/Native/comparator/threshold/baselines were not changed by this integration.

At this source, Tabs63 tests, related roving160 tests and the actual SSR/O2 keyboard4 tests pass; these suites overlap and are not summed. The real keyboard run retains56 correct inputs,30 unique SSR targets, explicit IDs, stable rebuild owners and new owners on keyed remount. Touched3 Dart files pass fatal-infos and format without drift.

Fresh bundled Chrome150.0.7871.24 SSR144 and optimized-hydrated144 endpoint rows have no differences across the seven recorded endpoint fields, browser errors or external requests. The original containing-pixel sampling policy (`int`/floor for positive image-local coordinates) still yields20/24 exact samples with max channel delta1 in each phase. A separate fresh nearest-pixel diagnostic (`round`) yields18/24, also max1: `underline-alpha`, index1, pressed, light/dark records y=3.600006103515625, so floor chooses row3 (Web/Native224,190,212) while nearest chooses row4 (Web223,189,211; Native224,190,212). Applying the original floor policy reproduces all24 previously recorded Web/Native RGBA values. This is a named coordinate-selection difference, not an error in the old count or a product regression. No PNG, recorded coordinate, repository comparator or threshold was changed to reconcile it. Both readbacks and their original artifacts are retained.

The raw endpoint PNGs remain24/24 byte-identical to74 in both SSR and hydrated phases. Across the full endpoint fields,32 observations differ from74 only in `pill-default` and `underline-default`, consistent with inherited main's newly registered existing8/16 opacity utilities. This is not a new raw-state patch or a claim that the remaining pure-token selected composition is fixed. Previous74 default/token serialized HTML equality is not relabelled as current-source evidence.

The fresh Chrome150 natural run has90 rows:78 current-product rows and12 browser-rerun negative controls using preserved old flat-gradient HTML. All160 meaningful current transitions have observed intermediate values at the existing100/250ms Core easeInOut timing; zero-duration, disabled and transparent animations remain0. Runtime/errors/external requests are0. Hovered hydration preserves the same node but records one non-hover frame among17 on each theme; the previously disclosed shared reconciliation reset remains. Intermediate Native/CSS RGBA differences are still material and are not waived or called exact. Natural screenshot timing sidecars remain attached.

Root's fresh Native proof at660 supplies144 endpoint rows,120 actual timelines and28 PNG pairs, all identical to74 observations. Its source closure is reused explicitly: the660-to-current changes are confined to Web/tests/verification docs, dependency lock is exact, the232-package graph and pinned SDK are unchanged, and Native/Core/capture sources are unchanged. All28 original/fresh660 PNG hashes were checked. Native was not rerun at this current head.

The one fresh optimized docs build completes359 routes, exit0 in79.143s; tracked22,572 source/mode changes0 and git clean. The previous build was renamed to `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-root-6440-integration-20261119.pbumyt14/final-roving-integration/previous-docs-build`. Fresh built Tabs/TabPane routes yield8 light/dark/refresh records with runtime/console/request errors0. A fresh own actual Tabs SSR VM reload succeeds HTTP200→200 (no source change/received libraries0). Own browser/server/build group/VM/PIDs/ports closed.

The first endpoint HTTP harness omitted `/favicon.ico`, producing a proven404 RangeError and stopping after144 SSR rows. The initial log, output and closed owner are preserved. A separate retry returns204 only for that fixture resource; product code and assertions remain unchanged. Final source receipts, native closure, endpoint method comparison and natural motion are in `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-root-6440-integration-20261119.pbumyt14/final-roving-integration`. The original motion docs remain in Root's `worker-original-*` copies; historical endpoint docs are untouched. No full816/3814, official VRT or global count reduction is claimed, and Root's separate0a23 matrix audit is not relabelled as this merged source.
