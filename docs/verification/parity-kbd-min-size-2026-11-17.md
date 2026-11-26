# Kbd minimum size: keep the padded interior outside the border calculation

Part of #6131. Base main `938d1e29814b51bddd0c94a74a9438706a2ebf52`.

When `keyMinSize:40` binds, Flutter constrains the padded interior to40 and its surrounding Container adds the visible border. Web previously constrained the entire border box to40. With a2px border and two short keys, the existing Flutter result is two44×44 caps /92×44 combination, while Web was two40×40 /84×40. This contradicts the existing Flutter tree and Core's stated border growth.

Web now states `box-sizing:border-box` locally and adds twice the resolved border length to its minimum width/height. The existing adapter keeps the expression tied to the stroke variable, so the active surface geometry and transparent-border fold both reach the minimum. It keeps a real CSS border for forced-colours rendering. No new paint path or per-example offset is introduced. The minimum does not constrain the glyph itself and existing shrink-zero/gap/semantics remain.

The Web 1x hairline is intentionally1px (`theme_config.dart` hairline policy), while Flutter retains Core's0.5px. That design decision is preserved; the new browser tests expect the existing Web policy rather than asserting identical hairline geometry across engines. Neo Brutalism keeps its existing4px stroke floor. No public constructors, fields, function declarations or defaults change (AST declaration comparison passes). Core, Flutter library, Web widget/DOM/callbacks, themes, exported API, capture policy, thresholds, masks, fonts and baselines have no diff.

## Verification

- Real public-widget min40/stroke2 fixture in light/dark: Web84×40 →92×44; Native92×44. Both final caps44×44. This is a geometry result, not a claim that text antialiasing is identical. Native/Web screenshots were inspected.
- Native Kbd suites48 pass, including8 matrix cases across brightness, default/Neo and visible/transparent borders, each checking widths0/0.5/1/2. The temporary fixture loads the real shipped fonts; the deterministic widget minimum tests do not depend on glyph advances.
- Web44 pass, including10 real-Chrome cases: the same matrix plus a host's content-box reset. Gap4 and one accessible name remain. Negative control: replace only the renderer with exact main source, run these same10 cases →6 geometry assertion failures /4 transparent-border controls pass; restore exact accepted SHA →44 pass. Test-authoring failures are excluded from that control.
- `dart analyze --fatal-infos` on changed Dart paths: no issues. Format4 files0 changed; diff check clean. No new ignores.
- `jaspr build`:357/357 routes. Deploy-equivalent output includes the Flutter artifacts as in deploy.yaml. Actual `/embed/kbd/` SSR emits the existing border/radius/padding variables plus derived minimum. Optimized client/CDP: default minimum20px at1x, border1px, light border rgb(237,238,240), dark rgb(64,65,67), box-sizing border-box, window drag bridge registered, page errors0 in both themes after finite transitions settle. This verifies local release output, not a new deployment.

## Existing matrix remains visible

All40 Kbd catalog keys (four variants × light/dark × five surface styles) were freshly captured on main before the renderer change. Web was freshly captured after; the unchanged Flutter captures were reused. All80 platform/probe images have identical dimensions and exact RGBA before/after. The four catalog examples do not exercise this repaired custom minimum.

Cross-platform Kbd result remains0 pass /40 fail, including default8 failures. Own-baseline result remains76 pass /4 differences. The last full default748 measurement remains461 pass /287 fail from #6330. This change does not claim a fresh full748 sweep; only Kbd rendering changed and its complete fresh40-key comparison is identical. Baselines and parity rules are unchanged (DPR1,5%, regression0.1%, channel delta32, dimension mismatch fails).

[Raw numeric evidence](parity-kbd-min-size-2026-11-17.json) records fixture results, source SHA, test counts and release computed styles. UI screenshots are temporary private draft-release assets; they are not committed or promoted.
