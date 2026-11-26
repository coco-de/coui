# Loading raw-color forwarding

Part of [#6131](https://github.com/coco-de/coui/issues/6131),
[#6439](https://github.com/coco-de/coui/issues/6439).
Base: main `f27dc733a`. Final product/test source:
`e69dc3b61999793ad2d4e12abcc8121ce08fe2a5`.

`CoreLoadingStyle(color: CoreColor(0xFFB12345))` is an existing supported
input. Native resolves and paints this color. Web previously made
`text-#B12345` / `bg-#B12345` classes without inline color. The spinner
inherited its ancestor's text color; dots, bar fill and pulse lost their fill.
`CoreColor.toString()` already documents that raw colors require inline CSS.

The resolver now forwards the existing `emitColor` text/background inline
results only for raw colors. Original token classes still use
`CoreColor.toString()`, including its percentage rounding. Spinner sweep,
all three dots, bar fill, pulse halo and center dot receive the actual value.
Caller root CSS/classes/attributes and theme-to-instance precedence remain.

## Token compatibility correction

The intermediate `12afa6c04` used `emitColor` for tokens too. Independent
review caught a real behavior regression before any PR or merge:
`CoreColor.toString()` rounds percentages, while `tailwindColor` truncates.
The final implementation preserves the original token path without changing
either shared serializer. Original source and negative evidence are retained.

Three fractional inputs, `.005`, `.29`, `.625`, retain `/1`, `/29`, `/63`.
Four variants in light/dark give 24 actual paired rows. Final classes,
computed paint and geometry match base exactly; the rejected checkpoint
differs in all 24 class rows and eight computed-color rows. Existing unsupported
Tailwind-modifier behavior is preserved; this is not a Native fractional-alpha
parity claim.

## Validation

| Check | Result |
|---|---|
| Initial negative controls | Raw16 fail; default/token/caller8 pass |
| Final unit suites | New32 + existing Loading15 = 47 pass |
| Actual Chrome tests | Color2 + existing spinner geometry1 + zero-motion2 = 5 pass |
| Actual paint-color controls | Web before48 vs unchanged Native48: 28 match /20 differ; fixed48: 48 match /0 differ |
| Final raw48 binding | Fresh final SSR HTML byte-exact to the earlier fixed48 inputs; those actual observations are explicitly reused |
| Fractional token compatibility | 24 base/final actual rows exact; rejected checkpoint retained |
| Official default Loading8 | Fresh final Web PNG8 and JSON8 byte-exact to12afa, already exact to retained Web555 |
| Static checks | Changed Dart3 fatal-infos0; format changes0; full contract guard exit0 |
| Final optimized docs | 359 routes, 87.07s, tracked22551 SHA/mode changes0, clean source |
| Actual optimized Loading route | Real theme toggle, light/dark and refresh4 observations; visible16x16 spinner running; runtime/request errors0 |
| Owned debug runtime | HTTP200, successful `reloadSources`, HTTP200; same actual HTML; process/HTTP/VM ports closed |

Color observations use RGBA8. Alpha-zero RGB payloads remain in the original
raw records; their invisible paint is distinguished only in this temporary
evidence comparison. No official comparator, normalizer, field, skip or
threshold changes are involved. This is not whole-image or whole-property
cross-platform parity. Native product source is unchanged.

Core, public declarations, defaults, design values, original Markdown,
product CSS/JS, Native, dependency/lock/SDK, baseline and comparison criteria
change0. Workspace package-config232 tuples remain identical. The contract
guard retains its existing seven non-enforced warnings.

The last complete816 measurement remains bound to Web555/Native309:
**582 pass /234 fail**. This work does not claim a fresh full816 measurement
or resolution of the two default Loading.pulse pixel failures.

Initial helper compile/import/API, formatter/lint, readiness-witness and VM
endpoint errors remain separately preserved. Initial OS-dark assumptions,
in-progress theme-transition reads and Ahem-caption images are not final UI
evidence. Final Native captions use the existing font loader and
`CoreFontFamily.sans`; resolved48 rows and caption-excluded shape48 regions
are exact to the initial controls. Final docs observations wait for natural
CSS transitions and use the real theme control.

[Exact commands, sources, rows, limits and artifact paths](parity-loading-raw-colors-2026-11-19.json).
Canonical final proof directory:
`/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-loading-raw-color-20261119.89z0oz8s/token-compatibility`.
The parent directory preserves all prior raw evidence. `selected-evidence.json`
lists eight original, visually inspected PNGs with hashes and explicit reuse
bindings. No image edits, baseline promotion, push, PR, upload or merge occurred.

## Root integration with main

Latest main `6ec4d2078eb9dd3844febec56b41493be54fae91` (Icon #6441) was ordinarily merged at `16e8ff076e838055224665eec2f27a10b68d71ea`. Loading product/test files remain byte-exact to the worker freeze; only inherited Icon code and its verification files were added by the integration. Root reran Loading47 unit tests and5 actual browser tests successfully. A new standard O2 docs build on the integrated source generated359 routes in74.71seconds with22,557 tracked paths unchanged and its owned process group closed. These are fresh integrated checks; original e69 component evidence and Native48 reuse remain labelled with their actual source, not relabelled as fresh Native or full816 capture. The adjacent JSON binds Root receipts.
