# FadeScroll native scroll timeline (#6394)

The candidate restores the existing Core fade contract in browsers that
support ScrollTimeline and animation ranges. It uses three owned native
effects on the existing viewport, retaining the existing caller nodes,
root forwarding and component structure. The unsupported path retains the
original scroll listener, viewport ResizeObserver, 1px boundary slack and
legacy gradient expression. This does not complete #6366 or Native #5134.

## Final state-identity candidate and current main

The final product/test source is95837c0a1ff23e5a88335eb7f73cb496b53288ac.
Root cherry-picks the two-file ownership follow-up as
f817af66b1d08f0a92005c087a17aede0a35df43, tree
4cbb5411ee317d2d5d6e22ccd26e6173069844b3. Its four Dart files are byte-identical
to95837. The earlier985a/56b/e326 phase is retained as superseded evidence;
it is not a shipping candidate after the local-key regression below.

Latest main is09644e164890b59385c614fbd8cefde21d638843. Independent NavigationBar
changes #6397/#6400 introduce87 upstream files, including Core APIs/default
selection faces, Scaffold, Figma data and committed baselines. Those are
main inputs, not changes made by this PR. The subsequent #6402 changes four
tests and adds a flex-alignment parser helper whose callers are tests only;
product, docs, capture/report entries and existing parser bodies are unchanged.
Fresh baseline5889 is explicitly bound to09644 through those unchanged inputs,
not renamed as a fresh09644 execution. Supported export closures are now
Core931/Native1351/Web1296, equal before/after our patch.

The final source builds359 unique optimized routes, exit0. Actual FadeScroll
variants/themes/strict boundaries/fit/refresh plus TextField and OTP controls
again pass72 records (44/12/16), runtime/action errors0. All22474 tracked inputs
retain their frozen hashes during build/runtime, including generated paths
and locks. Owned browser/HTTP54205/build53924 close; server exits143.

Eight unique tests pass: five actual Chrome tests plus three existing SSR
first-paint/selection tests. The earlier repeated four/three executions are
not additional unique tests. Changed Dart4 pass fatal-infos/format0/API0.
There are no added public fields, constructors, resolver arguments or
exports. Private viewport IDs intentionally change for keyed instances;
caller root id/Key forwarding and the existing node structure remain.

## Second rejected candidate: equal local keys and ownership

Jaspr local keys need only be unique among siblings. The previous private
ID used key.hashCode globally, so two equal local keys under different
parents produced duplicate viewport IDs. Both measurers attached to A:
A6/B0 effects. Disposing B left A3 effects but removed A's gradient carrier;
the same position130/max260 then had an opaque leading edge. Actual main5889
kept the correct fade. A-parent refresh repaired the candidate, so the
negative fixture disposes B in its own Stateful holder without rebuilding A.

The correction uses the existing private counter for every State instance.
It keeps the public root id and key unchanged, assigns distinct private
viewport IDs, and preserves them for that State's lifetime. This also routes
the existing legacy measurer to the right keyed viewport; its listener,
observer, tolerance and gradient policies are unchanged.

The new permanent test fails on the old56b source at the actual A-pixel
preservation assertion after B disposal, rather than an ID-count proxy or
setup failure. With the correction, both themes/axes pass. Independent same
fixture control changes from3000/10000 differing pixels to0, A/B3/3 effects,
then A3 with identical carrier, computed mask and byte-identical PNG after
B disposal. Caller nodes/value/selection/root geometry stay the same. An
actual pointer click may move focus to the removal button as normal; that
control does not claim focus stays on the input. All owned runtimes close.

Independent positive is e326's frozen fixture plus the corrected widget
file34d0b00461725340387d8f0a91b080e607a0b9be21ff6e32d59dbb1a2e9a30cf,
which is byte-identical in95837/f817. It is not labelled as a whole f817
browser build. The final full Web matrix and actual docs use f817 itself.

## Latest baseline and final matrix provenance

Exactmain5889/treee79b7cf11e0d600d670ec223e9f934c292c34332 is freshly captured on
both platforms: Native752/Web752, Web disjoint251/251/250, all exit0,
missing0/retry0, PNG1528 decode/JSON1504 parse, source22471 unchanged.
Manifest3494 all entries yields752 defaultStyle/163 components; key/role/field
roster is unchanged, SHA3f6e29e4edec05b1b3d6c2a1face4104c7ff889092e0f4199bd36febc94ad784.

Compared with the earlier fresh12ac/tree-equal9f phase,1524/1528 PNGs are byte
identical; only NavigationBar default light/dark on both platforms change.
All752 key/role verdicts remain equal: pixel572/180 (dimension4/infra0/skip0),
property416/278 plus infra12/structural46. Official report exits remain1.
These identical counts do not mean the four upstream design images stayed
the same. Their API/default/baseline changes are separately attributed.

The superseded56b after matrix was18 new affected Web keys plus734 reused985a
keys and latest fresh Native reference reuse. It passed matrix comparison
but did not cover the equal-key ownership bug, so it is historical only.

The final after Web752 keys are all freshly captured on exactRootf817,
using three disjoint251/251/250 shards. Native752/764PNG is explicitly reused
from the fresh5889 reference; there is no734-Web reuse from the unsafe
candidate. All1528 PNGs decode and are byte/RGBA exact to before, missing0.
RawJSON1366/1504 are byte/value identical;138 differ only in
captureContext.text, preserved without normalization. All752 key/role
verdicts, property differences and infra/structural lists are identical.
Pixel572/180 and property416/278+12/46 keep official exits1. Own-platform
comparison against the fresh before reference passes752/0/infra0, exit0;
this is not a committed-baseline promotion or full manual CI run.

The final f817 docs pass359 routes and72 actual runtime records after the
counter correction, with all22474 source/generated/lock hashes unchanged.
Token1..7, isolated-SDK contract and Chrome passthrough guards pass; existing
non-enforced contract warnings remain. Only the ordinary expected-head
GitHub gate and final receipt review remain before merge.


Raw final Root phase: final-state-identity/ under the Root artifact directory.
Fresh final Web phase: /var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6401-final-key-scope-web-20261118.1remhlcu.
Fresh baseline: /var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-main5889-fresh-baseline-20261118.82k803zh.
Ownership negative/positive: /tmp/weever-6401-duplicate-local-key-20261118.bc9r5zmk.
Counter regression and source receipts: /tmp/weever-6394-fade-timeline-20261118.7359efzk/state-unique-ids.

## Historical985 source and public contract

Product/test commit985a615781f7537f0265e36ee50209ee64be8b96 is based on
main0b4c49d10969a9daa6028753222c2678e8f6beca. Root cherry-picks it as deb6995da4;
05d569ca06c9fa3de632cbf1a3cccb1d6d311658 adds only the plain Behavior docs line.
The optimized build runs on that exact clean source, tree
ed7fb8415de0f0c172841a1250e530cd1245f274.

Public fields, constructors, signatures, Core/defaults, Native, SDK,
locks and baselines stay unchanged. The supported export closures remain
Core930/Native1350/Web1295. Both exported source files have unchanged public
declaration shapes; a separate public-member projection also verifies the
unexported measurer's constructor/fields/attach/dispose. New JS interop,
fields and functions are private implementation details. A whole-class
hash changes for the measurer because it includes new private members;
it is not reported as a public-member change.

The active native path uses exact physical start/end positions, as Core's
very-top/bottom contract and Native position>min/position<max require. It
mixes the actual first/last Core gradient colours, including nontransparent
end alpha, and removes the whole mask when the timeline is inactive/fit.
Repeated attach restores owned carriers after style replacement without
restarting effects. In the final counter-corrected candidate, dispose cancels
only its three effects and own carriers. The historical985/e326 key-collision
exception is documented above and is not approved for shipping.
There is no new observer, polling, font listener, wrapper, caller clone,
platform patch, !important, per-key capture branch or numeric comparator fix.

Mechanism references: [CSSWG Scroll-driven Animations draft](https://drafts.csswg.org/scroll-animations-1/)
and [CSS custom-property invalid values](https://www.w3.org/TR/css-variables-1/#guaranteed-invalid-value).
These explain native progress/inactive timelines and variable fallback;
actual engine support is checked separately, not inferred from draft status.

## Rejected candidate and actual counterexample

The first product candidate retained the private legacy1px slack in the
modern path. Combining that slack with corrected gradient endpoints created
a new regression: maxScroll1/start before matched actual Flutter, but the
candidate removed the trailing fade (800 changed pixels, max channel234 in
each theme). The original36-case classification as entirely pre-existing
was incorrect. This candidate is held on audit/6394-rejected-modern-1px-20261118,
commit a76c7e90c3b1c2ae0ee6be1a39a12dbd9b7f458b; it is never merged.

Exact0%/100% ranges fix the demonstrated issue without epsilon or new design
values. Actual Flutter comparison for max1/start and max2/middle, two
alpha profiles and both themes is8/8 RGBA exact: before4/8, rejected0/8,
corrected8/8. The independent reviewer re-decodes the raw images. Permanent
regression tests check actual pixels in both axes, fit/zero/restore, and
three gradient profiles rather than just testing mask-image!=none.

## Historical985/e326 validation — superseded for ownership

- Seven unique tests: four new actual O2 Chrome contracts and three existing
  SSR first-paint/selection tests. Repeated executions are not added to the
  unique count. Four changed Dart files pass fatal-infos/format0/diff0.
- Optimized docs359 unique routes pass. Actual FadeScroll variants, themes,
  physical scroll boundaries, fit and refresh plus TextField/OTP head/focus
  controls pass72 records (Fade44, TextField12, OTP16), runtime/action errors0.
- All22456 tracked files retain their frozen hashes during build/runtime;
  generated files and locks are included. Owned browser/HTTP64487/build64246
  ports close, owned server exits143, unrelated processes remain untouched.
- Registered24 Web keys (three variants, two themes, four surface styles)
  are newly captured before0b and after985a: PNG24 byte/RGBA exact and JSON24
  byte exact, no normalization or baseline promotion.
- Actual public canonical216 records per engine (Chrome/Firefox/WebKit),
  including late FontFace load/add with no RO/MO/loadingdone/parent rebuild,
  nested viewports, caller state/focus/selection and owned-effect cleanup,
  pass648 records/errors0. Fifty-six within-engine metamorphic PNG pairs per
  engine are RGBA exact. Canonical harness evidence is labelled separately
  from runtime/no-freeze observations.
- Actual numeric162 records per engine all satisfy strict Core edge/fit
  predicates. Native raw-image equality is Chrome146/162 (other16 max1
  channel), Firefox38/162 (remaining max1), WebKit24/162 (remaining max1..6).
  These differences stay recorded; no threshold is relaxed and their
  pre-existing/new status is not assumed before the counterfactual finishes.
- Actual Firefox159 with scroll-driven platform support disabled has
  constructor undefined/supports false/own effects0. Forty-eight before/after
  pairs are byte/RGBA exact and preserve geometry, mask and legacy variables.
  This scoped fallback test does not certify every old Firefox version.

## Historical draft checklist before final state-identity fix

At the initial draft stage, full752 after-Web capture/report, the bounded
same-engine default raster counterfactual, fractional/RTL and final-source
first-paint receipts were pending. Those985-phase receipts were later
collected and retained, but the key-ownership counterexample superseded that
candidate. The final95837/f817 source has its own fresh Web752/docs/ownership
validation above. This paragraph preserves the historical draft checklist;
it is not the current capture status. The normal GitHub gate remains separate.

## Raw image provenance

Default Native light/dark are the actual fresh12ac/tree-equal-main9f capture,
explicitly reused with Native/Core unchanged; default Web comes from the
new registered24 source985a capture. Existing cross-platform pixel failures
are not described as exact Native equality. Fit impact images are raw
public O2 numeric widgets from exact0b/985a, both-alpha gradient, horizontal,
100px viewport in a220x20 capture host, 900x800/DPR1. Red content and blue
background are explicit example inputs, so the two theme images are
identical by design. No resizing/padding/background edit/CSS repair is used.
The before remains masked with no overflow; the candidate correctly uses
mask:none. These are fit examples, not relabelled late-font growth images.

Raw Root evidence: /var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-6394-fade-integrated-20261118.ekw79t23.
Worker: /tmp/weever-6394-fade-timeline-20261118.7359efzk/strict-edges.
Independent review: /tmp/weever-6394-independent-review-20261118.hxrjbd1j.
