# Existing Web style overrides (#6383, #6386)

Ten Web style resolvers used the token-only `tailwindDuration` conversion
for an existing public Duration override. Passing123ms caused SSR500 in
each component. They now use the existing `durationMsCss` inline emitter.
This restores value forwarding without adding an API or a design value.
The batch also restores ColorPicker's existing disabled edge-color value
after the duration-only phase below.

## Final integrated validation after host-head repair

Upstream head-ownership PR #6396 is merged as main
`ce2cda121c98494c10f2f983b15f53772dd168b7`, tree
`ef18950445c43d05c90cca12b4b3f5318f4e2a96`. This is exactly the whole tree
of the frozen before source3224883. Root ordinary merge6a2e84 has exactly
the already-tested f7fd7d88 tree
`a6fafa0633c7873b7af1ac1f9a599ea1bead8c6b`. The tests below ran on f7fd7d88,
which preintegrated the identical head repair; this is not a post-merge
rerun claim.

- **405 unique tests pass**, combining this batch's343 with head19 and
  capture-clock43, across23 test files. Fatal-infos/format cover the16
  changed batch Dart files. The ten existing public declaration shapes and
  supported export closures remain equal, including non-exported style
  files in the declaration comparison.
- Optimized docs generate **359 unique routes**, exit0. The actual ten
  component pages pass **140 runtime records**, with zero runtime errors
  or action failures. The OTP driver checks partial123 keeps cursor/focus
  and completed123456 releases focus, matching its existing public contract.
  The earlier incorrect completion-focus assumption remains a diagnostic.
- All40 affected defaultStyle Web keys are freshly captured again:
  **PNG40 byte same**, rawJSON36 same/four `captureContext.text` differences.
  The explicit after composite has40 new Web/712 reused Web/752 reused
  Native keys. All752 key/role verdicts, property differences and skip lists
  equal before: pixel572/180; property416/278 plus infra12/skip46. Official
  report exits remain1. These results establish no added default-matrix
  regressions; they do not establish complete platform parity.
- All22455 tracked-file hashes remain unchanged during this phase. Each
  of185 generated paths is checked against that frozen Root inventory;
  tracked locks are included. Owned browser/HTTP/build ports are closed.
  Pinned existing Tailwind/Iconify/font assets are supplied locally; no
  product CSS repair or theme assertion relaxation is injected.

The root `css`/`classes` passthrough and caller-last root style combination
are preserved. A normal global selector aimed directly at an internal
transition carrier can now lose to the explicit Core duration inline
value: known150ms observed200ms before and150ms after in the independent
cascade controls. This is an intentional precedence change and not a
claim that every arbitrary CSS winner remains unchanged. Existing public
root passthrough does not promise precedence over internal CoreStyle
properties; the existing root CSS/layout observations remain identical.
Sortable's known300ms was also corrected from the existing150ms surface
rule to the supplied300ms. No `!important` or selector exception was added.

The source23c67266 documentation phase corrects CoreSortableStyle Dartdoc
and regenerates its STYLE_TABLE with `tool/generate_style_tables.dart`.
It builds359 unique optimized routes and again passes the actual ten-page
140-record runtime driver, errors0. The build's source inventory records
22455 files. While it runs, only the two non-rendered verification reports
and four further default-duration Dartdocs are edited; all executable
sources, generated outputs and locks retain their frozen values.

The final five Core Dartdocs (Sortable, TextField, RadioGroup, ColorPicker,
Tree) describe CSS milliseconds instead of the old token class. All five
Core ASTs/declarations/default values remain identical. Five generated
style tables check with drift0, all five comment-only files pass fatal-infos
and format0, and the final15 public declaration comparisons pass. The own
Dart scope is21 files:16 tested/analyzed Web or test files plus five Core
comment-only files. The405 tests are not counted again for these edits.
Token phases1..7, isolated-SDK contract and Chrome passthrough guards pass;
existing non-enforced contract warnings remain. An earlier guard launch
with the global SDK is preserved as an excluded diagnostic.

Independent read-only reviews find no code/API/default/design-contract
blocker. The cascade audit covers96 root cases in three representative
widgets, not every arbitrary external stylesheet. Reports:
`/tmp/weever-duration-caller-css-20261118.uld1h776/README.md` and
`/tmp/weever-6391-independent-review-20261118.faz86ivs/README.md`.
Raw final docs: `/tmp/weever-duration-contracts-20261118.jsuh0jdq/final-docs`.
Its browser and owned HTTP/build ports56910/56512 are closed (server exit143).
Head merge Release44231720855 succeeds; it is release automation, not full
manual CI or deployment.

Raw final integration: `/tmp/weever-duration-contracts-20261118.jsuh0jdq/final-integration`.
The historical failed77c0 docs phase below is retained as failed; #6396
resolves its upstream host-head cause without deleting/restoring host nodes.

## Duration-only product scope

| Component | Existing override |
|---|---|
| TextField, TextArea, InputOtp, ColorPicker, Tree | transitionDuration |
| RadioGroup | colorTransitionDuration, dotTransitionDuration |
| Tabs | indicatorTransitionDuration |
| Pagination | hoverDuration |
| Sortable | animationDuration |
| MultiAnswerCard | transitionDuration |

All ten original123ms failures are reproduced in `before.json`; all ten
render successfully in `after-combined.json`. The emitter preserves the
existing millisecond conversion, motion policy and CSS token remapping.
It also retains accepted display-duration2000ms values. No fractional or
negative-duration policy is newly specified here.

The ten product changes are Web style bodies only. Core runtime, Native, defaults,
Resolved fields, public helper outputs, exports, SDK and dependency locks
are unchanged by this patch. Declaration-shape comparisons cover all ten
files, including those not re-exported by the supported package barrel.
Supported export closures are unchanged: Core930/Native1350/Web1295.
There are no parse/API differences. The redundant, undocumented unnamed
`library;` directive in ColorPicker was removed for the analyzer's
`unnecessary_library_directive` diagnostic. An unnamed library remains
implicit; imports, exports and privacy scope do not change.

Internal duration classes and inline-style attributes intentionally
change. Existing tag trees, caller nodes and their order are preserved;
this is not a claim that all DOM attributes or erroneous behavior remain
identical. Baselines, comparator fields, allowlists and thresholds are
not changed by this patch. Upstream design changes are recorded separately.

## Duration-only tests and actual runtime

The integrated suite passes342 tests:335 existing units, five new
navigation SSR contracts and two actual Chrome contracts. Fourteen changed
Dart files pass
fatal-infos analyze with no issues and format with zero changes. Token
phases1..6, the contract guard and Chrome passthrough pass. Existing
non-enforced contract warnings are not called zero debt.

Input O2 verification observes158 affected faces per theme in each of four
phases: normal, reduced motion, token remapping and focused parent update.
The56 cases cover default/0/123/150/2000ms, RadioGroup's separate123/371ms
clocks, token150 remapped to73, both RadioGroup variants and both TextArea
faces. Focus, typed value, cursor, geometry, ARIA and tabstops are retained
across the exercised motion/state changes. Actual ColorPicker opening and
selected/unselected recent swatches are exercised in both themes.

Navigation O2 verification observes default/0/123/150/2000ms, reduced motion,
token150 remapped to73/0 and actual CSS Transition effect durations. Tabs
click/Arrow+Enter/disabled, Tree ArrowRight, Pagination change and
MultiAnswerCard selection/disabled are exercised. Actual Sortable pointer
reorder suppresses the dragged row to0s, moves its neighbor at123ms, emits
onReorder(0,1), then restores123ms after drop, in both themes.

The initial bare Sortable keyboard fixture did not commit a reorder. The
same token150 fixture has exactly the same observed state/event/order/clock
results before and after. This keyboard scenario is not certified, and
the observation is not assigned to a duration regression or a confirmed
product defect. No keyboard workaround was added.

Both private SSR Dart VMs execute successful `reloadSources` and retain
their observed123ms values. The input VM receives zero changed libraries
because no source was edited between calls. These are actual no-op SSR VM
reloads, not evidence of live source replacement or Flutter app reloads.
Owned VMs, browsers and HTTP servers are closed; unrelated apps are untouched.

## Initial2b matrix phase

Before is freshly captured main
`2b1a43f3e0331244ac7bd126b4e6974a2c8b6b79`, tree
`bd9703ceb8d81f5e6b6245f711aeae95d96326ab`. Native and Web752 keys are
fresh (Web disjoint251/251/250, retry0). All1528 PNGs decode and1504 JSONs
parse, with8015 recorded inputs and locks unchanged. Pixel572/180,
dimension4/infra0/skip0; property416/278 plus infra12/structural skip46.
The official reports retain exit1.

After source is `f738c01c61d54d864b8e0969ac54bf3e872b3d65`, tree
`0135f7e7e409a5a506f0c113636c886c55720df4`. The subsequent143b79 ordinary
merge only adds upstream version/release records. All40 registered
defaultStyle keys for these ten components are newly captured on Web:
40 PNGs are byte identical to2b; rawJSON36 are byte identical and four
differ only in captureContext.text. No field is removed or normalized.
The navigation worker's earlier10-key capture only covered its default
variants; the integrated40-key capture supplies the missing variants.

The whole after report is an explicit composite: Web40 new/712 reused,
Native752 reused from the same fresh2b phase. It is not an all-fresh after
matrix. All752 key/role verdicts match before; new/resolved failures0.
Own-platform committed-baseline comparison for these40 Web keys remains
34pass/6fail on both sides, exit1. The six existing failures are
ColorPicker default, RadioGroup default and Tabs line, each light/dark.
No baseline promotion is performed.

## ColorPicker disabled edge color (#6386)

Core's existing disabledBorderColor accepts raw as well as token colors.
Native already selects that value. Web omitted a raw disabled value; an
enabled raw inline color also outranked a disabled token class. Identical
96-case Native, SSR and O2 inputs prove40 failures per original Web mode,
all disabled, while Native96 match the existing Core merge expectations.

When either edge is raw, the existing trigger button now stores its
disabled value in a private CSS variable and reads its edge through a
second variable with the enabled value as fallback. A static native
:disabled utility selects the disabled value. The empty SVG still reads
currentColor. Both-token default paths retain their original classes.
There are three new private constants and no public declaration change,
resolver enabled argument, new node, wrapper, scoped rule or!important.
The other input/slider/recent-swatch paths keep their existing ownership.

Patched SSR96 and separately compiled O2 96 both match the actual Native96
reference. The Native/Core sources are unchanged; that reference is reused,
not called a fresh Native execution. These are exact Core8-bit RGBA field
comparisons, not96 custom screenshot pixel passes. Actual nested element
trees match192/192; raw-path class/style attributes intentionally change.

The new Chrome regression fails original expected18/actual115, then passes
480 state checks across light/dark, state inversion/restoration, token
remapping, two raw instances, empty SVG stroke, dimensions and opacity.
The existing nine ColorPicker units pass. Actual two-picker O2 interaction
preserves the sibling input node/value/#ABCDEF/selection[0,7]/focus when
the other picker disables. Disabled clicking opens no popup; re-enable,
normal-to-empty, two recent swatches, raw hover ring and history selection
are exercised. Runtime errors0. This does not claim focus stays unchanged
during that input's own value commit.

Worker2ef03b8590 is integrated as891f158221, tree
`32185a4d62e42be2816881bb933cafb62a9a099d`. Root's combined343 tests,
fatal-infos/format16 and public declaration comparisons for all ten product
files pass. Only the three private ColorPicker constants alter declaration
shapes. The support export closures remain930/1350/1295. All40 affected
Web keys are newly captured again against the latest base;40PNG bytes
match. The earlier duration-only342/14-file phases retain their original
source/count boundaries and are not relabelled as this phase.

ColorPicker evidence:
`/tmp/weever-6386-color-picker-disabled-20261118.juaz_8mo`;
original Native/Web negative:
`/tmp/weever-color-picker-disabled-20261118.nqb360_2`;
Root integration: the initial artifact directory's `color-batch/`.

## Upstream integration and remaining work

Main subsequently adds release8e0ac and NavigationBar design #6384 at2bca.
Those Core/design/default/baseline changes belong to upstream and are not
counted as part of these duration repairs. The initial2b numbers above
must not be presented as a new measurement of that design.

The first143b79 optimized docs build fails on an upstream FoldScope switch:
the same official Flutter3.50 SDK provides three Native states and four Web
states. Separate issue #6385/PR #6387 replaces the last explicit unknown arm
with a wildcard normalization to the existing Core unknown state. Known
states, fold/hinge geometry and public declarations are retained. Native44,
tiny Flutter Web O2 negative-to-positive and Chrome16 geometry observations
are separate evidence; they are not342 additional duration tests. The
original failed docs log is preserved rather than relabelled successful.

The latest validation-only base is12ac99ce65/tree
`d7f8f3f1a7d956f839f03bd7a120ba166a36c7e4`: NavigationBar2bca plus the
independent FoldScope repair. Its Native/Web752 keys are all freshly
captured again, not borrowed from2b. All1528 PNGs decode and1504 JSONs
parse, capture exits0/retries0/missing0;22447 tracked files and the two
present pubspec.lock files remain unchanged. NavigationBar's16 PNGs
really change, with unchanged dimensions. Pixel572/180 and property
416/278 plus12/46, all752 key/role verdicts, remain the same as2b.
This is a measurement of that integrated source, not yet a merge receipt.

FoldScope PR #6387 subsequently merges as main9f78e5cb9f, whose whole tree
is exactly the measured base d7f8. Root ordinary-merges it as f84c5de9f8;
the duration render tree remains77c0. This binds the existing captures to
merged sources and is not a claimed recapture.

Duration integration1746c4a321/tree
`77c0ce3b8bc8d265cb3bb50284a07454d757b5ce` has exactly the optimized docs
worker6b59b6c3e1's whole tree. Root repeats342 tests, fatal-infos/format14
and the ten declaration-shape comparisons on this source successfully.
All40 affected Web keys are newly captured again against the latest
base: PNG40 byte same; JSON36 byte same/four captureContext.text changes.
The resulting explicit40-new/712-Web-reused/752-Native-reused composite
retains all752 key/role verdicts and the failing official report exits1.
Raw latest-base data is
`/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-main-navigation-matrix-20261118.ynn4kxcq`;
latest duration data is the initial artifact directory's `latest-main/`.

## Historical77c0 docs phase: build passed, UI verification blocked

The exact77c0 tree builds359 unique optimized routes, including the Flutter
Web embed. Recorded13963 source inputs,185 generated files, four tracked
locks and the isolated CLI lock remain unchanged. Ten actual component
pages returnHTTP200.
The attempted theme assertions do not pass: document light state and the
toggle's ARIA agree, but the live on-surface CSS variable is empty and the
rendered root becomes black.

This is tracked independently as #6389. Upstream #6373's automatically
mounted PageTransition Document.head causes Jaspr's head reconciler to
remove initial unkeyed host assets. SSR still contains the correct theme
CSS, while the actual hydrated head loses it. Runtime JS errors0 and
successful compilation are not presented as UI success. The10-page driver
failure, DOM/CSS diagnostics and original source remain preserved at
`/tmp/weever-6383-integrated-final-20261118.eavdv_ut`.

At that historical phase the duration repair was not ready to merge until
the upstream runtime blocker was resolved and integrated docs rechecked.
No CSS injection, weakened theme expectation, host-node restoration or
SDK patch is used to bypass it.

The companion JSON records the final integrated docs/matrix phases and
their exact source boundaries. Local validation does not establish full
manual CI, deployment, live Figma review or completion of the remaining
default pixels. FadeScroll's late-font candidate (#6366), measurement
ownership (#6374), inheritance
(#6342) and DefinitionList's direct-dt/dd contract (#6354) are separate.

Raw initial inputs: `/tmp/weever-duration-contracts-20261118.jsuh0jdq`.
Navigation runtime: `/tmp/weever-6383-navigation-duration-20261118.cy0t5aey`.
Fresh2b matrix: `/tmp/weever-main-matrix-20261118.zsojl31g`.
FoldScope: `/tmp/weever-6385-foldscope-20261118.ki7rbpsl`.
Failed docs: `/tmp/weever-6383-docs-20261118.a0bkw250`.
Initial guessed probe/test-runner/lint failures remain in these directories
and are excluded from final successful counts.
