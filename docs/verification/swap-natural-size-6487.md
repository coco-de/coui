# Swap natural-size ownership (#6487)

Non-flip Web Swap previously measured only offContent. A larger onContent could
shrink or overflow the root and miss a pointer hit on its far side. Native none
and rotate already measure both mounted faces under the parent's constraints.
Web now gives both slots one grid area and keeps their state mounted.

## Contract and design boundaries

- Public Swap constructor, copyWith/style chain, exported ResolvedSwap constructor
  and fields, resolveSwap signature, and the public barrel remain unchanged.
- Core, Native product code, tokens, ThemeConfig, components.json, comparison
  rules, thresholds, skips and committed images are unchanged.
- The private overlap node stays mounted when checked or animation changes.
  Flip uses display:contents so the existing root remains its containing block
  and 3D owner. This preserves flip rather than applying the non-flip size policy
  to it. Native flip's different current-face policy is still a separate gap.
- Structural 0/100% constraints have zero CSS specificity. Caller class, inline,
  important constraints and an explicit child max:none keep their priority.
  No clipping, offsets or new design dimensions were introduced.

## Actual validation

The initial reference was 704346fc; the same Swap product files were present at
8ce4a90e. The owned feature checkout was advanced to 2098a7c1 before final builds,
44 Native tests and the official 24-entry capture. The original session checkout
was not changed. Tests and captures are separate observations, not additive
counts of one full repository run.

| Check | Actual result |
|---|---|
| Native Swap natural sizing | 36 pass, including 16 public Frame compositions |
| Existing Native lifecycle | 8 pass (same final invocation: 44 total) |
| Existing Web hidden/Clickable/surface suites | 35 pass |
| SSR, standalone public resolver, O2 browser | 3 pass; 219 observations |
| Final browser source | 2098a7c1 + uncommitted product hashes listed below |
| Legacy Swap manifest | all 24 registered style/variant/light-dark combinations |
| Original vs changed Web captures | 24/24 PNG bytes and RGBA identical; 744 byRole fields identical |
| Literal Web JSON | only captureContext/text indentation changed, 16 to 18 spaces |
| Platform own-baseline VRT | 48/48 comparisons pass; missing/skip/infra 0 |
| Cross-platform pixel comparison | 12 pass / 12 existing dark failures; exit 1 retained |
| Cross-platform property comparison | 24 pass; infra/skip 0 |
| Final jaspr build | exit 0, 359 routes, 82.90 seconds; source/metadata unchanged |
| Changed Dart format | 5 files, no drift |
| Changed Dart analysis | errors/warnings 0; one SDK INFO for the Native test's deprecated flutter/material.dart import |
| Web product/fixture/test fatal-infos | 4 files, no issues |
| Token guards | phases 2, 3, 4 pass |
| Chrome passthrough and contracts | pass (contracts: 115.44 seconds) |
| Changed Swap resolver guard | pass |

The existing 12 dark pixel failures are unchanged: all original/changed Web PNGs
match, and the six common default Native captures also match the earlier actual
704346fc reference. This work does not claim a reduction of the last full
816-entry report's 234 failures. That full report was measured at 704346fc,
not remeasured on every subsequent main commit.

The first docs build regenerated ignored package metadata, which tripped the
strict byte-invariance check. All 232 resolved paths/language versions, the
package graph and lock were unchanged. The final build passed with byte-exact
metadata. The original logs and assertion failures remain in the session evidence.

## Structural dispatch and guard review

The initial helper selected an empty class for boxless flip with a ternary. The
whole-file resolver guard classified it as a chrome class-drop. The repository's
web-specifics rule explicitly allows intrinsic-size layout vocabulary; this
branch depends only on animation and never drops a Core size override.

The final implementation names complete immutable chrome for all three modes in
one typed const table. A source probe asserted literal className and inline
properties equality for every enum value. A fresh final browser run passed all
three tests and retained all 219 observations, including node identities.
No guard, baseline, allowlist, marker or file location was changed.

The full resolver guard still reports seven entries outside the changed Swap
path (AppBar, Scaffold, Join, Tabs and ColorPicker); those files are byte-identical
to main. That full failure is recorded separately from the passing scoped guard.
It is tracked in #6496, is not presented as a full-tree green result, and no public fields are removed
to silence it.

## Evidence and limits

Final product SHA-256:

- swap.dart: 4621913a108494bdf2f92e28b0e7ab35a07ebd6fd9b49f23cb4b9e0888b0fd76
- swap_style.dart: 57949d593e9861400a559cd11742ad57f7336452efe7e8ee1eaaf26f1887b51b

The 24-entry captures used the preceding helper spelling. Its three mode outputs
are proven identical to the final const table, with a fresh final SSR/O2 run;
those captures are not relabeled as a second final-source capture invocation.

Independent review checked the public API, actual emitted zero-specificity CSS,
caller precedence, 308 face-center observations, and stable node/State identities
in 141 controlled/mode observations. The final flip controls matched the original
26 sampled paint/transform rows and three padding-box rows exactly.

A dedicated owned Dart SSR runtime also returned HTTP 200 before and after a
successful VM reload. Its unchanged-source reload received zero libraries; it
is not a claim that O2 JavaScript supports hot reload. Owned servers, VM service,
browsers and runner groups were closed after validation.

Fixed-face inline baseline observations do not certify arbitrary mixed text
baselines, every caller descendant selector, or every intermediate animation
pixel. The private wrapper is an internal DOM change. Stacks fit behavior is
tracked independently in #6490. Original failed prototypes and exact raw outputs
are preserved; no screenshot was promoted or committed.

## Later main integration

Banner main commit cade0e4f (#6484) was ordinarily merged into the feature branch
as 8f914888. Its unrelated design and baseline changes are preserved; they are
not part of this PR's diff. On that actual integrated source:

- Native 44 pass, 12.78 seconds; all 116 raw observations byte-identical.
- SSR/standalone resolver/O2 browser 3 pass, 57.84 seconds; all 219 observations
  literally identical to the preceding final candidate, errors/external 0.
- jaspr build exit 0, 359 routes, 103.77 seconds; tracked source and metadata exact.
- Changed-file analysis has errors/warnings 0 and the disclosed SDK INFO 1.
- The full resolver guard still reports the same seven outside-scope entries.

The first integrated browser invocation stopped before tests because its former
shared browser path had disappeared. That infrastructure error and teardown
error remain preserved. The successful invocation uses an already present
Chrome for Testing 150.0.7871.24 in the original checkout, with a separate owned
temporary browser profile; no checkout/cache download/copy or criteria changed.

Two test-host alternatives were rejected and not committed. The recommended
material_ui import retained all 44 results/116 raw rows but needs an additional
direct test dependency. A generic WidgetsApp builder broke two existing keyboard
focus assertions (42 pass/2 errors). The committed original host and assertions
were restored byte-for-byte; no warning suppression or dependency change was used.

## Final integration before merge

Main86dba7f0 (OptionItem #6485 and Figma #6497) was ordinarily merged as dff8799d.
On that actual source: Native44 pass/12.82s, Web3 pass/69.18s, Native116 raw bytes
and Web219 whole observations identical, errors/external0; jaspr build exit0,
359 unique routes/200.33s; changed analysis errors/warnings0 with SDK INFO1;
Swap resolver guard passes and full resolver guard retains the same seven
outside-scope entries. Every run retained byte-exact tracked source and metadata.

The live branch protection has no required status checks, no active branch rules
and zero required reviews. Redesign board/move is optional board automation,
not a code test. Its pending state is disclosed; the user's existing ordinary
merge authorization applies. No admin merge, protection/workflow change, skipped
code check, or fabricated successful check is used. The earlier wait treating
this optional job as a mandatory gate was corrected.

PhoneInput main70e3ccd8 (#6494) was subsequently ordinarily merged as b6f31273.
Its runtime changes are limited to PhoneInput; the Swap dependency implementation
is unchanged. On b6, Native44 passed again (12.32s), raw116 bytes matched, and
whole-catalog SSR compilation/Swap24 manifest succeeded (14.73s) with identical
descriptors. The preceding Web3/build are explicitly reused for the unchanged
Swap closure, not relabeled as new runs. An initial missing host-side evidence
directory error was preserved and corrected before the successful invocation.
