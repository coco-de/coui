# Stepper vertical alignment — #5966

The final alignment calculation has **zero net-new property failures against main** across the same30 Stepper keys. Existing property debts remain; this is not an assertion that the full property gate passes. Final-source self-hosted captures independently pass60/60 pixel-regression checks; source and raw property provenance are recorded below.

## Layout policy and metric semantics

The authored non-final bottom inset is the existing Core space20 token. Alignment is `max(0, (actual indicator height - canonical first-line metric) / 2)`, independent of density spacing. Authored top padding is added separately; all authored sides are omitted on the final row, while alignment still applies. Multi-line labels use their first line for alignment and the full paragraph for row height. Active/upcoming/disabled merges and instance overrides remain effective.

Flutter measures the actual first line using final resolved style, scaler, locale, direction and leading behavior at layout width. [LineMetrics.height](https://api.flutter.dev/flutter/dart-ui/LineMetrics/height.html) is `round(ascent + descent)`; the installed3.47.0 SDK documents that rule at sky_engine/lib/ui/text.dart:2925. Web projects the effective label-context1lh with `round(nearest, 1lh, 1px)` **only in the alignment calculation**. The1px is the logical metric quantum specified by that API, not authored spacing, a cached inset, or a new Core token. The quantum does not scale again after1lh has resolved at the current root font size. Web typography, unitless leading and native paragraph heights remain untouched; the upcoming circle uses border-box to keep its border inside the resolved diameter.

This centers the canonical metric, not the raw browser paint box. Native shaping, fallback fonts and mixed runs can differ between engines; the tests prove the listed Pretendard fixtures and overrides, not universal font equivalence. There is no root-height rounding, compensating spacing, excluded property, new public chrome, typography override or tolerance change.

## Measured actual components

Pretendard from the repository; local Flutter3.47.0, actual DOM probe Chrome157.0.8103.38. Standard density; first description only:

| Measurement | Flutter | Web raw DOM |
| --- | --- | --- |
| Row heights | 65 / 43 / 24 | 64.890625 / 43.390625 / 24 |
| Connector heights | 33 / 11 | 32.890625 / 11.390625 |
| Title top offset | 1 | 1 |
| First-line alignment metric | 22 | 22 |
| Actual title line box | 22 | computed22.4, native box22.390625 |
| Description box | 20 | 19.5 |
| Connector top / bottom margins | 4 / 4 | 4 / 4 |

The existing property comparator tolerance is0.5px. Raw fractions are preserved, not relabeled as integers. The full actual example has descriptions on **all three** rows, including the last:

| Cohort | Flutter root | Web root, raw | Absolute gap | New height failures |
| --- | --- | --- | --- | --- |
| Independent base5a88dc00f | 180 | 179.671875 | 0.328125 | 0 |
| Historical c12e5e8ac, raw1lh alignment | 175 | 174.0625 | 0.9375 | 10 |
| Final canonical metric projection | 175 | 174.671875 | 0.328125 | 0 |

Final full-fixture rows are Flutter65/65/45 and Web64.890625/64.890625/44.890625. The previous extra divergence was3×(1−0.796875)=0.609375. Matching metric semantics removes that added divergence while preserving the browser's existing native paragraph fractions. The small copy sample alone would not prove this cumulative case.

## Same-base property audit and raw evidence

The manifest includes root heightPx on all30 entries. Both cohorts use the same manifest/tools/environment (local Flutter3.47.0, matrix Chrome150.0.7871.24); base was independently captured from a clean detached worktree at5a88dc00f. The raw1lh historical cohort is retained too. [Raw snapshots](paired-property-raw.json) contain every original root property value from Flutter/Web for all30 keys in each cohort; native browser version and manifest are included. [Paired field counts](parity-property-before-after.md) compare base to final.

All reports still exit1 because of existing mismatches. Exact failed (key,role,field) sets are equal for base and final: **124 existing failed fields, NET-NEW0, removed0**. The historical raw1lh head had134 failed fields. Existing counts remain fontSize30, lineHeight30, fontWeight24, color20, padding10 and width10; height failures are0→10→0. No probe is skipped or missing. Pixel-regression success is a separate signal, not property proof.

```sh
dart run tool/parity/report.dart --manifest=MANIFEST --captured=CAPTURES \
  --signal=property --mode=regression --report-json=REPORT \
  --comment-out=COMMENT --vrt-out=VRT
dart run tool/parity/compare_reports.dart --before=BASE_REPORT \
  --after=FINAL_REPORT --out=COMPARISON
```

## Standards and compatibility

[CSS Values4 §10.3](https://www.w3.org/TR/css-values-4/#round-func) defines the explicit nearest strategy, interval and upward tie. [Dart round](https://api.dart.dev/dart-core/double/round.html) ties away from zero, which is the same for positive line heights. The actual21.5px override test confirms22 as the canonical metric and1px alignment in both implementations. Root21/24px tests resolve1lh first, then quantize; the24px root yields a36px indicator and rounded34px line, so its offset is1 rather than a cached1×1.5.

Vendor release evidence: [Chrome125](https://developer.chrome.com/release-notes/125), [Mozilla Firefox118 developer release notes](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Releases/118#css), and [WebKit Safari17.2's account of CSS math shipping in15.4](https://webkit.org/blog/14787/webkit-features-in-safari-17-2/#math-functions). The explicit strategy and interval avoid [Safari's historical optional-argument issue](https://bugs.webkit.org/show_bug.cgi?id=278714). Google records [round as Baseline2024](https://web.dev/blog/css-stepped-value-functions). Repository rules, README, contributing docs and public guides specify no numeric browser floor; this implementation already depends on1lh. Current Chrome150/157 are measured; Safari/Firefox compatibility is vendor evidence, not local native execution. Unsupported older browsers are not claimed equivalent.

## Source guard distinction

The spacing scanner distinguishes only the unit argument of the complete literal `round(nearest, 1lh, 1px)` operation. It still scans every other length in that same string;8px additions/inputs, other quanta/strategies, incomplete functions, interpolation and adjacent-string spacing are rejected, including a number and unit split across separate strings. Geometry zero uses pinnedLengthCss(0). All314 actual spacing declarations pass, with **21 pinned declarations / existing baseline21**; floor, thresholds, ratchets and allowlists are unchanged. Guard self-tests cover positive and negative cases. Injecting+8px into a scratch copy of the actual Stepper expression makes the full-source scan fail at that exact literal; no tracked injection remains.

## Focused verification

- 72 actual Flutter Stepper tests, including exact enabled/disabled small fixture, full-fixture cumulative height, positive half-pixel fixed leading, density compact/spacious, explicit/natural wrapping, text scale1.5, diameter/font/per-state overrides, explicit/zero padding and final-row behavior.
- 67 Core/Web/property comparator regressions.
- 4 actual Chrome DOM tests using production HTML/styles and loaded local fonts: native row/connectors, line-height and paragraph-height preservation with alignment removed, half-pixel ties, diameter/typography/density/insets and root21/24 scaling. Final label typography supplies1lh, not the body's context.
- Targeted Dart analyzer/format and spacing guard self-test/full scan; authored-literal regression injection fails as intended. The Web resolver guard retains its pre-existing warning behavior; chrome and widget-scaling guards also pass.
- The original implementation also passed contracts/export freshness, Figma TypeScript and registry/hash/redraw/binding self-tests, Flutter/Web geometry/chrome guards and355-route Jaspr build. Those broader checks predate this narrow Web metric correction and are not represented as newly rerun. The preset snapshot surface list excludes Stepper; targeted five-preset captures provide its rendered preset evidence. No full ci.yaml dispatch.

## Runner baseline provenance

The approved `parity-baseline.yml` was dispatched from the PR source branch at **c18467778303188e70030ec2453aa2d0eb90b3ab**, with components=stepper. No full ci.yaml was dispatched.

- [Successful final-source run42217213581](https://github.com/coco-de/coui/actions/runs/42217213581), self-hosted runner **cocode-m2-ultra-kentrosaurus**, workflow Flutter3.47.5; Web capture JSON records Chrome150.0.7871.24. This is the same self-hosted runner pool used by the future parity gate.
- First Flutter/Web captures were promoted, then **new independent second Flutter/Web captures** were written into captured2 and compared under the unchanged pixel-regression criterion: **60/60 PASS**, zero failures, missing baselines, skips, allowlist approvals or infra failures. [Downloaded runner VRT report](runner-vrt-report.md). This is independent reproducibility evidence, not a reuse of retained first captures or an assertion of unavailable second-file byte hashes.
- Runner branch chore/parity-baseline-42217213581, commit **cb245ab37ecb997928c43a4c32b885d530ed06cc**, was fast-forwarded into this PR. Its delta from final source is exactly **20 vertical Web files:10 PNG+10 JSON**. The other100 capture files were already identical; **no non-vertical raster drift** was imported or suppressed.
- Every one of the final40 vertical PNG/JSON baselines byte-matches that runner commit. Relative to main, exactly those40 paths change. Historical ff5658c81 already supplied the10 vertical Flutter raster changes; the final workflow confirms their reproducibility too. No thresholds, allowlists, ratchets, workflow changes or non-Stepper baselines changed.
- Running the property comparator against the actual final runner baseline JSON also yields the exact same124 failed (key,role,field) set as base: **NET-NEW0**, height failures0. The runner's full fixture remains175 versus174.671875.

Historical run[42212409367](https://github.com/coco-de/coui/actions/runs/42212409367) proved the earlier135d20356 source only. An interim projection run[42216914920](https://github.com/coco-de/coui/actions/runs/42216914920) also passed, then the guard gained adjacent numeric/unit-string negative cases; that interim baseline was not imported. The final-source run above supersedes both for this handoff.

Latest fetched main5a88dc00fd7b8aaa4af29f062b25ecd3016e124e is already an ancestor; no main merge was needed. Post-capture changes are verification documentation only.

## Figma boundary

The builder reads the final visible single-line fixture title and actual circle heights. A separate content alignment wrapper carries the derived offset; inner content keeps authored stepPadding variable bindings. No new generator data field exists. The fake-node registry harness has no layout engine and cannot prove canvas pixels. As with pre-existing generation-sized labelStack, arbitrary font/diameter edits require Generate to recalculate; live responsive instance behavior is not added.

No canvas was mutated. Parent review/merge/bundle handling and user Generate/native read remain pending on actual page2467:119903, generated2467:120098 versus copy8225:134: rows65/43/24, connectors33/11, title y1, description y25, root125×132. This PR does not move an unverified component to canvas-check.
