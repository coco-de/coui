# DescriptionCard: preserve spacing and caller state (#6355, #6360)

Web now follows two existing contracts. Hiding the title divider removes
only the rule, retaining the two Core gaps that Native has always used.
Removing or restoring the title preserves the existing rows and their
caller state, selection and focus.

Final integration base is main `141ccf6f7c` (#6357, including #6359).
Earlier isolated evidence is explicitly pinned to main `6b18d85de9`.
[The JSON receipt](parity-description-renderer-contracts-2026-11-17.json)
records source hashes, exact counts and local artifact paths. Verification
uses official Flutter 3.50.0 / Dart 3.14.0 / Jaspr 0.24.0-beta.1 without
changing global FVM, package constraints or locks.

## Existing contracts and implementation

Core defines `showDivider` as whether to draw a divider below the title;
gap styling is a separate field. Both legacy and current Native use
`[title, Gap, optional Divider, Gap, rows]`. The Figma source comment at
`tools/figma-token-sync/src/components/display-data.ts:2608` describes the
same tree. Figma does not generate a false-divider axis, so this is not
represented as a new designer approval of that state. Web's second Gap
moves outside the divider condition. No new spacing value is introduced.
For a non-null title with `showDivider:false`, that restored Gap also
adds its own `div` before the rows. This is an intentional change in the
previously incorrect state, not a claim that all DOM is unchanged. The
default `showDivider:true` tree remains unchanged. No public direct-child
structure guarantee was found in the component API or user documentation.

Web's optional title and rows were both unkeyed divs. Jaspr could reuse
the old title div as the new rows div and discard the actual row callers.
Native's title Row and rows Column remain distinct. The existing Web
rows div now has a stable ValueKey backed by a private enum, avoiding
collision with caller string keys. This key-only change adds no wrapper,
tag, order, user key, style, Core value or exported API. The conditional
Gap-node restoration above is a separate part of the combined patch.

Only one product file changes. The existing component Chrome test file
gets observable regressions for both contracts. Two pre-existing infos
in the touched widget are also resolved: a long comment is wrapped and
radius0 uses `CoreBorderRadius.zero`. Independent Dart evaluation proves
identical const identity, equality, hash and all four CSS corners for
that existing alias. No shape or default changes.

## Spacing evidence

The permanent Chrome test measures the shared rendered Divider itself.
Across five sizes, three gaps (default/7.25/zero), three title settings
(null/empty/text), and light/dark, its 90 true/false pairs compare card
height, row position, surrounding spacing and caller content. It does
not copy Core arithmetic or assert a particular Gap count. On original
main it fails Expected 1 / Actual 7 at xs: a 1px rule incorrectly removed
another 6px of spacing. The fixed widget passes with zero epsilon.
An earlier count-only test was discarded, not landed as the regression.

Independent actual Native/Web measurements cover another 80 cases:
60 exact / 20 failures before, 80 exact / 0 failures after. Every original
failure is title-present and divider-false, differing by the existing
resolved gap (6/8/12/16/20 or custom7.25). Null-title and true-divider
controls remain unchanged.

Another 72 caller cases preserve nodes, text/copy order, ARIA and
horizontal dimensions, restoring only the missing vertical gap. The
specific empty-title fixture's 24 cases retain a pre-existing 11px
residual after accounting for that gap. The 80px custom value widget's
existing Native/Web width-constraint difference is also preserved.
Neither is claimed fixed or classified as unavoidable engine behavior.

## State and identity evidence

An independent actual Native test on main6b records 104 checkpoints in
light/dark counter and selection profiles. Title null/String transitions
preserve State, Element, row-wrapper identity, counters, selection and
focus. It uses 720px after preserving an initial side-counter overflow
at420px; this is not every-width coverage.

Optimized Web tests use fresh caller instances with keyed/unkeyed and
direct/copyWith profiles. Original208 checkpoints include80 losses; the
rows-key candidate preserves all208 with zero runtime errors. The
permanent browser regression reproduces the original failure on the
first title removal and passes the candidate. Parent updates invoke
handlers without an unrelated physical button focus transfer, while
counter clicks are real pointer clicks. This tests parent rebuilds, not
a promise that clicking another control leaves input focus unchanged.

Independent inspection confirms LocalKey is not passed into Jaspr DOM
renderObject.update. The isolated key comparison preserves all60 PNGs,
raw JSONs and SSR HTMLs byte-for-byte, plus eight initial client DOMs.
Caller keys, copy text, ARIA and node order remain intact. Final combined
tests retain Native83, Web8 and the original Chrome2, adding the spacing
and optimized state regressions for Chrome4. Changed files pass
`analyze --fatal-infos` with zero issues; no new ignore is added.

## Visual scope and current main

Each isolated fix preserves all60 registered default variant/theme/style
captures. Root also captures all60 on both platforms after integration.
Final counts and exact source/reuse boundaries are in the JSON receipt.

Main #6359 adds vertical ToolbarGroup light/dark entries, making the
latest default manifest750 keys rather than748. That full main baseline
is freshly captured on both engines. New entries are counted separately
from verdict changes on the common748. The older568/180 result is
historical; it must not be relabeled as a new750-key measurement.

The actual new750-key result is **570 pass /180 fail**: both new vertical
ToolbarGroup keys pass, while the original748 keep exactly568/180 with
zero new failure and zero resolved failure. Property is416 pass /276
fail, with12 stage infra and46 structural skips. New entries' property
failures are retained. These upstream additions are not improvements
credited to this patch.

Root's integrated60-key capture has all120 images and120 JSONs equal to
the prior validated component dataset. The full dataset explicitly reuses
the other738 keys and replaces12 related default keys. All1,524 PNG
files and1,500 property JSONs equal the new clean-main capture, and the
official integrated reports retain570/180 and416/276+12/46. This is not
a second new full capture. Committed component own-baseline remains
Native10 pass/50 fail and Web0 pass/60 fail; report exit1 is preserved.

No baseline promotion, allowance, threshold, offset, mask, font flag,
Figma input or SDK change is introduced by these two fixes. Existing
property stage infra and structural skips are retained. Whole parity,
full manual CI, deployment and designer approval are not claimed.

## Optimized evidence and diagnostic limits

The final combined optimized run passes with zero runtime errors. It
records208 checkpoints each for original main141 and the integrated
candidate: original state loss80 and spacing failures40 become0/0.
Both themes, caller keys, direct/copyWith construction, ten divider
toggles, three gap changes, empty-title controls and ten title changes
are exercised with actual DOM/counter/selection/focus/copy/ARIA checks.
Registered docs also pass actual-theme and variant round trips. The
357-route build preserves185 tracked generated files and all3,128
recorded source hashes; the worker's merged tree equals the requested
Root code tree. Source is unchanged by that validation.

The isolated Gap optimized check passes67 records with zero runtime
errors. Real data-theme, public controller state and computed onSurface
agree (light31/32/33, dark244/245/246); divider10/gap3 transitions preserve
caller state. Four unedited420px screenshots use identical md/String,
gap12, divider-false inputs: original88px high, corrected100px.

An early diagnostic fixture replaced a data-theme substring inside built
content incorrectly. Failed/mislabeled outputs are preserved, excluded
from final pass claims. Its title-off reset is kept as original-state
bug evidence, not hidden or attributed to the Gap change. Final combined
optimized results are recorded separately from this older Gap-only run.

The #6359 upstream NavigationBar/ToolbarGroup API changes are inherited
main work; they are not API changes made by this patch. #6131 and #6342
remain open. #6354's public direct-dt/dd promise is preserved, so its
pair-wrap grouping candidate remains held rather than silently changing
that documented DOM contract.
