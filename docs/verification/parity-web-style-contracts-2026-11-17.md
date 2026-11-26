# Existing Web style and lifecycle contracts (#6363, #6364, #6365, #6367)

This batch restores four existing contracts. It introduces no new public
Dart API, Core field, design default or token. Rendering and erroneous
behavior intentionally change in the affected non-default states.

## Latest main integration (authoritative final phase)

Main advanced through #6368 (bar actions), #6369 (IndexedSwitcher) and
#6371 (runner-captured baselines). Their additions are inherited upstream,
not new APIs or baseline promotion by these four repairs. Latest main is
`11aed12edcb8ebe92ce071a640261dec9c148684`.

Fresh rendering compares main `da560c1d9e4a1b02c4c7e61401e063dfa69ba7c9`
with integration `7929a05bd7f3dc79382549d66f6d1baa32e9d035`, whole tree
`bd5ef2418ee5c7c51cf2bc6706626f7b63c013e6`. The subsequent ordinary merge
`7137145039626635bf4862801b93ee1582469589`, whole tree
`7ac1f198e7ac48463bd37d45fc666c102419a4a7`, adds exactly72 upstream files
under test/parity/baseline/ and changes no rendering input. Final receipt
updates are documentation only. Our four product files remain byte-equal
to29ad. Core/Native/public barrels/defaults/Figma/SDK/locks and baseline
promotion by our patch have zero changes relative to latest main.

The canonical3494 all-style entries now contain **752 default keys**.
Both platforms and both phases are fresh; Web uses disjoint251/251/250
shards on each side, retry0. Pixel is **572 pass /180 fail**, dimension4,
infra0/skip0 on both sides. Property is416/278 plus stage infra12 and
structural skip46, also identical. Both official reports retain exit1.
All752 key verdicts are identical, new failures0/resolved0. Upstream's
new IndexedSwitcher two keys pass pixels but fail the existing property
probe on background/radius/padding. Existing750 verdicts are unchanged;
the new ownership/measurement question is tracked separately.

All1528 PNG files are byte-identical. Raw JSON1504 all parse;1366 are byte
identical and138 differ only in captureContext.text. Inputs5205 before and
5209 after are unchanged during capture. Raw artifacts and gate fields
are retained unchanged. These numbers replace the initial phase numbers
below, which remain historical evidence rather than being relabelled.

Latest Root tests pass75+8=83 unique tests across two commands (79 existing
Web +4 Chrome). Changed9 Dart files have fatal-infos0/format0; token
phases1..6, contract and Chrome passthrough pass. Supported export closures
are Core927/Native1345/Web1290 files on both sides, with public declaration
shapes unchanged. The initial absent guessed Star test path failed to load;
that diagnostic log remains separate from the successful actual suites.

The latest whole-tree-identical optimized docs build succeeds **359/359**
(two new IndexedSwitcher routes), with Chrome4 and actual HTTP4/UI40=44
records, runtime0. Source13909/generated185 and four locks/CLI lock remain
unchanged. Owned HTTP65188/build64486/browser/build processes are closed;
unrelated apps remain untouched. These are local validation results,
not full manual CI, deployment or live designer approval.

[PR evidence](https://github.com/coco-de/coui/pull/6370#issuecomment-6947530776)
contains eight raw light/dark before/after images of the affected Checkbox
and Star custom states. They use frozen canonical hosts whose component
sources match final integration; they are not a claimed recapture of whole
latest main. Images are private draft assets with three-day expiry. Toggle
time and Dialog callback contracts are supported by observed events and
numbers, not inferred from a still frame.

Intermediate #6368 phase remains in JSON and raw artifacts:750 keys,
570/180, PNG1524 exact, JSON136 captureContext.text differences. Its one
unchanged rail retry after30s timeout is explicitly preserved. The latest
752-key phase above has no capture retry.

## Initial D551 phase (historical)

The following initial validation sections describe D551/29ad and retain
their original counts and artifact boundaries. Use the latest phase above
for current main and totals.

Validated code is `29adab2c3a280b14dc65c64b22fb52872b51c209`, tree
`ec616607d25f0102495ed1d05152f20128458be8`, based on main
`d5517009091e44620e02d3dd32483ca1b559e479`. The verification documentation
commit adds no rendered input. The JSON receipt records exact counts,
source boundaries, raw artifact paths and limits.

## What changes and why

- **Checkbox (#6363):** existing double box/dash dimensions were truncated
  into nonexistent or incorrect Tailwind size classes. One inline path now
  uses the existing size CSS variable for an exact CoreSize step, and exact
  rem for other dimensions. The private 24-entry palette is a conversion
  mechanic referencing the existing Core constants, not new component
  design values. The public token-only helper is unchanged.
- **StarRating (#6365):** value/count labels discarded their Core typography
  roles. Each existing span now receives one canonical emitTypography
  result, preserving scalar overlays and the existing forced disabled
  color. Star shapes, gaps and showValue/showCount defaults are unchanged.
- **ToggleGroup (#6367):** an allowed 123ms transition caused SSR500 through
  a token-only class helper. The existing durationMsCss converter now emits
  the duration inline, retaining token variable remapping and the existing
  reduced-motion policy. No helper or duration default changes.
- **Dialog (#6364):** a closed instance received Escape and notified onClose.
  The existing listener now checks current open state. Registration,
  disposal, callback nullability and multiple-open-dialog policy are
  unchanged.

Checkbox, StarRating and ToggleGroup intentionally change internal
class/style attributes. Existing tag trees, caller nodes/order and exported
signatures remain intact. These are not claims that every DOM attribute or
observable behavior is unchanged. A redundant unnamed library directive
was removed from StarRating to clear a pre-existing fatal info; public
imports/exports and declarations are unchanged.

This batch also corrects the previous DescriptionCard receipt: for a
non-null title with showDivider:false, restoring the missing Gap adds its
div. Only the rows-key-only change preserves every DOM node. The default
true-divider tree and public API are unchanged; the earlier combined
DOM-preservation claim was too broad.

## Observable failures and positive controls

The canonical docs reset is used for the Checkbox evidence. Its 17.25px
box measured 2x2 before (the residual border), then 17.25x17.25 after. An
initial minimal-host 0px reading is retained as a diagnostic, not production
host evidence. Native/Web box36 and dash12 cases go from18/8 failures to0/0.
Size variable remapping, root font-size scaling and density independence
are verified in actual Chrome. All40 registered Web PNGs and JSONs are
byte-identical before/after.

StarRating canonical SSR/O2 has44 cases each and matching label fields.
Native comparisons match152/160 fields. The other8 remain visible in the
receipt: custom codeMd font19/fixed23.5 draws a Native23px paragraph while
the unchanged Web round-to-pixel policy yields24px, in four slots across
SSR/O2. No epsilon, font adjustment or shared helper change hides this.
All8 registered default Web PNGs/RGBA remain exact. Label role/glyph/line
geometry changes in the enabled custom cases are intentional, not claimed
unchanged.

ToggleGroup's old123ms SSR500 is reproduced before the fix. Actual browser
80 observations cover both themes, normal/reduced motion,0/150/123/2000ms,
150ms token remapping to73ms and raw123ms preservation. Geometry, ARIA,
tabstop and hit area remain unchanged. All30 registered Web PNG/JSON pairs
are byte-identical.

Dialog's optimized keyboard regression fails original Expected0/0,
Actual1/1, then passes. Closed siblings and the closing window do not emit
extra callbacks. Native independently records6 matching checkpoints.
Its10 registered Web PNG/JSON pairs are unchanged; these are closed demo
triggers and do not constitute open-panel visual coverage.

Root runs83 tests:79 existing Web tests and4 Chrome contracts. The worker
repeats those same4 Chrome contracts on a whole-tree-identical integration;
this is another execution, not4 additional unique tests. Existing Native
StarRating30 and the dedicated Dialog Native reference pass. The9 changed
Dart files pass analyze --fatal-infos with no issues and format0 changes.
Token phases1..6, the contract guard and Chrome passthrough guard pass.
Existing non-enforced contract warnings are not presented as zero debt.

## Whole default matrix: still incomplete

Both platforms are freshly captured twice: clean main and the frozen
integration. The canonical3484-key all-style manifest supplies the same
750 defaultStyle keys. The final Web capture uses three disjoint250-key
shards; each key is captured once. Native750 and all Web shards finish
successfully, without missing artifacts or baseline promotion.

Both pixel reports are **570 pass /180 fail**, with dimension4, infra0,
skip0. New failures0, resolved failures0 and identical key sets. Property
reports remain416 pass /276 fail, stage infra12 /structural skip46. Both
official reports retain exit1. These fixes do not solve180 default pixels.

All1524 PNG files are byte-identical before/after. All1500 raw JSON files
parse;1332 are byte-identical and168 differ only in captureContext.text.
That metadata includes SSR style/scoping text across separate renderer
processes. The raw files are retained; no field is removed or normalized
in the gate. The official property verdicts are unchanged. Do not call all
raw JSON files identical. Recorded4124 final source inputs are unchanged
through capture.

## Optimized documentation and runtime scope

Own worker integration51a5ca1e4a0aa3804704caabbba18ddcf0388cbd has exactly
the validated code tree. An isolated Jaspr0.24beta1 CLI and official
Flutter3.50/Dart3.14 build357 routes, without changing global FVM3.47.9,
SDK defaults, constraints or locks. Generated185 and recorded source/config
13882 files are unchanged through build. Root curl independently receives
HTTP200 for all four pages, valid token classes, no bare inline color token
and no rgba class.

Actual optimized documentation produces44 records (4 HTTP,40 UI),
runtime errors0, light/dark document/controller/computed-color agreement,
selection/variant roundtrips and fresh refreshes. StarRating pointer3->4->3,
Checkbox controls, ToggleGroup selection and Dialog open/Escape/closed
cycles are exercised. Existing Web StarRating arrow-key behavior is a
documented pointer-only limitation in the baseline; it is not newly
implemented or called keyboard parity. Wrong driver assumptions and
failed attempts are preserved separately from final successful evidence.
All owned build/browser/server processes are stopped; HTTP60235 and
build59686 are closed, with unrelated applications untouched.

## Held work and limits

FadeScroll #6366 is excluded. Its RO-only candidate passed120 static
Native/Web pixel comparisons but an independent32-profile/128-record
review found8/8 inline self-state paths stale. A normal content-notification
fix using content MutationObserver notifications and a nested CSS-variable
reset has since passed independent replay; integration continues separately.
Neither that fix nor its results are included in this four-repair PR. Native FadeScroll metrics staleness
and #5134 state loss are separate existing limits.

Generic CSS inheritance #6342 and DefinitionList's explicit direct-dt/dd
DOM contract conflict #6354 remain open. No offset, image mask, threshold,
allowance, baseline or designer value was changed. This record is scoped
verification, not whole parity completion, full manual CI, deployment or
live Figma/designer approval.
