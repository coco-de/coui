# Native docs Card semantic tone — #6522

Native documentation Cards now consume the existing exact `tone="do"` and `tone="dont"` attributes. The outer border, eyebrow and Card-stage bottom border use the existing success/error semantic roles. Previously all three stayed neutral or absent. Unknown and absent tones keep the neutral behavior.

The original Native tag documentation explicitly lists tone among attributes with the same meaning on the site. Designer #6416 (`b3c031a7cee92f75b5cb4d87f02364e6e3a20740`) defines the matching Web roles in `docs-shell.css:861–864,914–915`. No new palette, design value, Core/library default or public API is introduced. Figma canvas verification was not performed.

| Authored tone | Outer border | Eyebrow | Stage bottom |
|---|---|---|---|
| do | successContainer | onSuccessContainer | success |
| dont | errorContainer | onErrorContainer | error |

The Card receives only a partial instance `CoreCardStyle.borderColor`, through its existing merge chain. Other themed values remain effective. Existing semantic Text modifiers supply the eyebrow color. The stage uses its existing BoxDecoration/Padding owner through a standard Flutter Container: decoration border dimensions reserve real content space inside the outer min-height. The existing stroke2 passes through `theme.geometry.stroke` once. No Divider sibling, overlay, uniform Frame border, offset or height compensation is used.

The common Container owner emits the original neutral RenderDecoratedBox → Padding24 → Center structure when there is no border and preserves the preview subtree through live tone changes. Only `flatBottom=true` Card stages consume the tone; ordinary standalone Preview stages ignore it. Controlled min140/explicit240 cases keep outer height; hug88→90 at scale1 and108→111 at scale1.5 are the natural intrinsic effect of the actual2/3px bottom border. Content centers move by minus half the border width through normal deflation. All20 authored capture roots retained their height.

Caption24H/20V, internal gap8, resolved padding/scaling, media clipping, links and empty-body behavior remain. Web20H/16top caption layout and the dark stage surface role are separate HOLDs and were not changed.

## Source binding

Actual capture/build source is `3fbb71620a25d0b4d0ae907287ed97e43af5493c`, based on `b2a02cc9b52877783f6a43fcfd66a7bc0440f19b`. Only `flutter_card_view.dart` and `flutter_stage.dart` production build bodies change, accompanied by one new permanent test file. Public signatures, fields, constructors, const and other helpers are byte-identical. Core/component libraries, probes, normalization, comparator, thresholds, baselines, dependency declarations and lockfiles are unchanged.

Evidence pointer: `/tmp/weever-docs-card-tone-active-path`. Its phase contains the complete first attempts, raw captures and hash indexes. These verification documents are later documentation only; they do not change the measured runtime/test bytes. The focused and existing checks ran before the local source commit, at base HEAD with the identical owned product/test diff. Captures/build ran at the clean source above.

Original48 reuse is explicitly source-bound to actualAA8 `aa8a77d02c60433f27bf13c0f812d37fd8511aaf`; the complete relevant docs/runtime/probe/input path diff to baseb2a is empty. Both after platforms were freshly captured. The232 dependency tuples reuse the same220 external roots; only12 owned workspace roots are rebound. No pubget, global SDK/CLI mutation or browser/SDK cache copy was performed.

## Actual verification

| Check | Result |
|---|---|
| Original same-public-input negative | 4/4 fail as expected, do/dont ×L/D: actual RenderDecoratedBox border and RenderParagraph eyebrow stay neutral; stage bottom absent |
| New permanent suite | 26/26 pass: actual solid-border pixels, semantic render owners, height/hug/scaling, unknown/absent, live State/Element/render-object/focus, themed border/padding priority, nonpreview links, standalone Preview and empty tone caption |
| Existing suites | 98/98 pass: media54 +docs9 +Card/spacing/shadow-radius35 |
| Fatal analysis / format | 3 files exit0 / unchanged |
| Source-derived selection | 3894 all-style /832 default descriptors; ALL20 tone keys +22 neutral keys +6 ordinary Card controls;48 descriptors exact, originalAA8 capture order preserved |
| Fresh captures | Native48 exit0/26.72s; Web48 exit0/96.96s; Chrome150.0.7871.24;96 JSON +96 PNG verified |
| Native before/after | Only tone20 PNGs change; neutral22 +ordinaryCard6 PNGs and full raw JSONs byte-identical to AA8 |
| Native tone root properties | Only borderColor changes in20 keys, each mismatch→match; other root fields including heights unchanged |
| Web before/after | All48 PNGs/byRole exact;42 raw records differ only in source-origin paths |
| Official cross-platform pixel/property | Each actual exit1,6PASS/42FAIL/0infra/0skip, same whole-key counts as originalAA8 |
| Own baseline | Actual exit0;6 ordinary Card keys ×2 platforms =12 comparable images pass,0 fail;42 docs Card keys ×2 =84 images have no baseline and are first captures |
| Actual docs build | Pinned CLI0.24.0-beta.1, O2 default, one execution, exit0/303.06s;361 generated routes/363 HTML |
| Relevant owned headless debug app | Both changed helper libraries loaded; actual CLI exit0; standard reload/reassembly213ms, **0 libraries reloaded** at frozen source; two frames retain stroke2 and media insets1/1/1 |
| Protection/cleanup | 22763 tracked source files/modes delta0;232 config/graph/lock bytes exact;192 raw origin/combined hashes exact;5017 build outputs renamed outside WT with bytes/modes verified; owned app/VM/build ports closed |

No claim is made that20 whole-card parity failures were solved. The semantic contract is restored, while42 whole-card pixel/property failures remain because other caption/tone/typography/paint-owner differences remain. Root probes do not separately identify all stage/caption paint owners; owner-specific render and pixel tests cover the intended tone transfer. The baseline report covers12 images, not all96. Headless reassembly at unchanged source does not prove live replacement of edited code, physical-device behavior or every caller/theme/motion combination.

All first attempts are preserved: the first candidate used the wrong existing Card named argument (`style` instead of `cardStyle`); one expanded fixture had an extra closing parenthesis; the standalone fixture incorrectly treated min140 as a fixed height under its bounded600 host and was corrected to compare the existing neutral geometry; two null-aware-map lint infos were fixed without ignores. The first owned CLI attempt timed out before a frame/VM witness at its external45s startup bound and also exceeded its cleanup waits. Its exact owned PID/PPID/PGID/target audit later confirmed termination; no unrelated processes were signalled. A separate attempt with a180s startup bound completed normally. These driver/fixture failures are not hidden or counted as UI assertion passes.

Selected originals are Button do and TextField dont, L/D ×Native/Web, eight unedited captures. All remaining keys stay in the numeric comparison. No baseline promotion or remote write was performed by this worker.
