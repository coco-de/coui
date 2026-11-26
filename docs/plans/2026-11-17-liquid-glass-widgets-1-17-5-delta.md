# liquid_glass_widgets 1.17.4 → 1.17.5 — what applies to CoUI

Reference: [sdegenaar/liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets), published `1.17.5`
(2026-11-17; source commit `6c7752e1`, and the pub.dev archive is byte-identical to it for `lib/`, `shaders/`,
`pubspec.yaml` and `CHANGELOG.md`), inspected on 2026-11-17. The window starts where the previous audit stopped,
`1.17.4` (`5bad197a`): [1.15.1 → 1.17.4](2026-11-17-liquid-glass-widgets-1-17-delta.md). It holds four merged
changes — #491, #488, #489 and #492 — and nothing else; the three that had not been released when the previous audit
closed are the ones it named as first to read. No upstream commit followed `6c7752e1` when this was read.

CoUI has its own glass (Core contract, Flutter seat, Web seat) and does not depend on the package. The package is a
behavioural reference: each upstream change was read, the CoUI path that answers the same question was located on both
platforms, and the result is one of **applied**, **already handled**, **not applicable** (the structure that produced
the upstream defect does not exist here) or **designer decision** (a look or feel call, not a defect). No upstream code
was copied.

## Reading the result

One change in the window applies, and it is the same defect CoUI had already written down for popovers: an opacity
above a backdrop filter saves a layer the filter then reads nothing from, so a glass panel that fades loses its blur
for the whole of the fade and pops back at the end. CoUI had fixed that on Flutter for the panels the popover engine
fades, and wrote the reach down as "the popover engine only" (`cross-platform/api.md`, the surface-style guide); Web
had not been looked at. Upstream's #492 closes
the same gap for its alert platters — `GlassDialog` and the native action sheet — which it had faded through the route's
`FadeTransition`. CoUI's counterpart of the alert platter is `Dialog`, and it was in exactly that state: its route
wrapped the panel in a `FadeTransition`, and the panel drew a `SurfaceBlur` under it.

It is applied on Flutter, pinned by tests that read the layer tree, and measured on a device: at half of the open, the
middle of a glass dialog kept 0.72 of the page's stripes when the route faded it as a whole and keeps 0.03 now.

It is applied on Web too, where the defect had two shapes: the popover family fades a motion box that holds the panel
(the filter reads an isolated layer, so the glass is a plain plate for the whole fade), and the dialog fades the panel
itself (the browser applies the opacity after the filter, so a blurred plate cross-fades with the sharp page). Measured
in Chrome, at a quarter, a half and three quarters of the way in, the middle of the panel kept 0.88 / 0.75 / 0.62 of the
page's stripes in the popover family and 0.75 / 0.51 / 0.26 in the dialog, and keeps 0.02 / 0.004 / 0.004 in both now.

The rest of the window is the `standard` / `minimal` tier (a structure CoUI does not have), the search tab bar (a
component CoUI does not have), and a legibility calibration for iOS 26/27, which is a designer's call.

## Disposition of the upstream window

"Pinned" means a test reads the rendered result and fails if the behaviour is removed. "Read" means the code was read
on both platforms and judged to answer the question, without a new test.

| Upstream | CoUI |
| --- | --- |
| #492 `GlassDialog` and the native action sheet dissolve through the glass material instead of the route's `FadeTransition` | **Applied (Flutter `Dialog`; the Web dialog and the Web popover family)** — on Flutter the dialog route offers the fade to the panel's surface, which takes it where it draws a backdrop pass (the host the popover engine uses). On Web the panel walks a progress number and the stylesheet states each glass term as a function of it, see "What changed". Action sheet: no such component |
| #492 entrance from scale 1.06 with content sharpening from sigma 4; a settled exit holds scale 1.0 and dissolves glass and content together; a cancelled entrance rewinds continuously | Designer decision (motion). CoUI's dialog keeps its resolved `scaleAnimationStart` / `scaleAnimationEnd` and the enter curve; a cancelled open already reverses from where it is — one controller drives both directions, and `CurvedAnimation` keeps the curve it started with until the animation settles |
| #491 `standard` / `minimal` tier: a `uVisibility` term inside `lightweight_glass.frag`, an opacity around the child only, none above the backdrop layer | Not applicable as structure — CoUI has one refraction program and no lightweight tier; every term of its pass fades through `CoreSurfaceDissolve`. The defect it fixes is the one applied above |
| #491 / #492 the tree keeps one shape across `0.0 ↔ 1.0` (no early `Opacity(0)` return, a shadow `Stack` slot that does not move), so a focused field in a dialog is not remounted on frame 1 | Already handled structurally — `SurfaceBlur` keeps its child under a global key, and the fade box stays in the tree at every progress. **Pinned** for the dialog: the field's state and focus are the same from the first frame to rest |
| #491 `GlassControlledOpacity`: an opacity that requests no compositing at alpha 0 or 255 | Already handled where CoUI owns the opacity — `RenderSurfaceFadeBox` requests a layer only strictly between nothing and full (pinned: a settled dialog paints its content straight through). The route's own `FadeTransition` keeps a repaint boundary at every alpha above zero in Flutter 3.50 (read in `proxy_box.dart`); that is the same before and after this change |
| #491 no `t²` double fade (a post-hoc `Opacity(visibility)` over values already scaled by visibility) | Already handled — the "faded once" rule. **Pinned** for the dialog: with a surface claiming the fade the route's opacity is full, and exactly one layer fades the panel |
| #491 / #492 `GlassQuality.standard` alert legibility on iOS 26 / 27 (frost sigma kept as the blur, a higher dark tint floor) | Designer decision (calibration). CoUI has no tier that keeps the blur and drops the frost: the ladder drops the bend first and then the whole pass, and the lowest rung is an opaque fill |
| #488 `GlassTabBar.searchable` keeps the search pill anchored to the trailing edge while a parent resizes | Not applicable — no search tab bar |
| #489 `GlassTabBar.searchable` keeps its text-input client across compact and expanded; search controls above the keyboard take taps | Not applicable. The hit-test remark in it (`Clip.none` lets a child paint outside a `Stack`, not take taps there) is general; see "Found on the way" |
| #492 the dialog barrier colour resolved through a dynamic Cupertino colour | Not applicable |

## What changed

### The dialog route offers the fade; the dialog's panel takes it (Flutter)

The mechanism is the one the popover engine already used, moved to where both can use it:

- **One host.** The popover engine's private fade wrapper is now `SurfaceFadeHost` (`surface_fade.dart`), used by the
  engine and by the dialog route. It publishes the progress and a claim counter above the panel and mounts the
  framework's `FadeTransition`, whose opacity stays at full (or nothing, while the progress is nothing) once a surface
  has claimed the fade. The engine's behaviour is unchanged.
- **The host listens to its own animation.** The engine and the route both rebuild their panel on every frame, so
  either would look right with a host that read the progress only when its parent rebuilt it. A host that is correct
  only by that coincidence is a trap for the next one; it now rebuilds the scope itself, and a test mounts it with
  nothing else moving.
- **The dialog route mounts it** around the panel, except for a full-screen route (see below).
- **The panel adopts it** the way `Popup` does: a dialog panel under a host builds its `SurfaceBlur` with the
  progress, and claims the fade only if the panel draws a backdrop pass (`surfaceDrawsBackdropPass`, the one answer
  the surface mounts its pass by). A panel whose surface draws none — an opaque style, the `solid` tier, reduced
  transparency — is faded as a whole by the route, as before.

What the user sees: a glass dialog keeps blurring what is behind it while it opens and closes, and the blur recedes
with the fill instead of switching off in the first frame and back on in the last. Nothing changes under a style that
draws no pass. There is no API change.

**A full-screen dialog is left as it was.** Its content is the caller's page, with no one panel for a surface to be the
root of: a host would hand the fade to the first glass surface in it and leave the rest of the page unfaded.

**A custom dialog is faded as the engine's panels are.** A `showDialog` builder whose root is not a kit surface is
faded as a whole, as before. One whose root is a kit surface that draws a pass (a `Card`, say) now dissolves that
surface's material; siblings next to such a surface inside a non-surface root would not fade. The popover engine has
the same reach (`cross-platform/api.md`), now stated for the dialog route too.

### Follow-up: the dialog's cast is painted outside the box (Flutter)

"Found on the way" below had left a question open: whether the dialog's elevation shows through its translucent fill.
It does. `Dialog` painted its cast through `BoxDecoration.boxShadow`, which Flutter draws as a filled shape behind the
box and lets the fill paint over; CSS draws an outer shadow outside the border box only. Under an opaque fill the two
look the same, but a glass panel's fill is translucent, so on Flutter the cast showed through the panel and darkened
it — the defect `cross-platform/api.md` ("그림자는 두 플랫폼이 다른 곳에 칠한다") describes, in a component that did not
yet follow it. `Popup` already did.

Now the resolver states where the cast goes (`ResolvedDialog.castOutsideBox`, true where the panel's fill is not
opaque), and such a panel paints it with `InjectedCast` (a cast with the box knocked out) instead of in its
decoration. That cast sits outside the fade box the fill and the content fade under, so it is faded by the progress
itself (`fadeShadows`), as `Popup`'s is. A panel with an opaque fill keeps the tree it had. No API change; the
resolved output gains an optional field.

### The Web panel walks a progress; the stylesheet states each term as a function of it (Web)

A browser has no host to hand the fade to, and no opacity fades a glass panel and keeps the glass: one above a
`backdrop-filter` isolates it, and one on the same element cross-fades its result with the sharp page. So the Web half is
a stylesheet and a naming scheme, with the same terms and the same curve as Flutter:

- **The progress is a number.** `--coui-fade` is a registered custom property (`<number>`, not inherited, initial `1`)
  that the element playing the open or close keyframe walks from `0` to `1` and back — the dialog's panel keyframe
  (which also scales it), or, in the popover family, the panel inside the motion box, which keeps only the scale. It is
  not inherited, so a surface inside a fading panel reads `1` and does not fade twice.
- **The glass terms are `calc()` of it.** Blur, chroma lift and dimming by `CoreSurfaceDissolve.share` of the progress
  (linear at an exponent of 1; the rule says `pow(…)` for another), the fill by the progress itself. The list a
  surface states stays term for term the list its own rule states, in the same order, so at a progress of 1 it is that
  list (a test reads both). The shadow, the border, the content and what the panel draws on its pseudo-elements fade by
  keyframes that name only where they start (or end), so each ends at its own value.
- **Which fade a panel plays is a name, not a length.** A fade root (the motion box, the dialog's panel) starts every
  subtree at "fade by opacity". The rule that gives a surface its pass names the other two animations instead and takes
  the opacity away; every rule that drops the pass — reduced transparency, a quality tier without the pass, forced
  colours — names the opacity again with `!important`. Silencing the animations by a length of zero was tried and is
  wrong: a zero-length animation that holds its end applies the end keyframe at once, and the end of a fade out is a
  panel that is not there.
- **The refraction runtime no longer freezes the list.** It appends the bend to the list the surface computes to and
  writes the result inline, where it outranks the stylesheet. A panel reaches it in the first frames of its fade, when
  that list is a blur of nothing, so the panel kept that blur for as long as it was open. A surface that states its
  list in `--coui-surface-pass` now gets a reference to it (`var(--coui-surface-pass) url(#…)`), which moves with the
  fade; a caller's own `backdrop-filter` on the element is still the base.
- **The host's stylesheet is written as raw text.** A `<style>` is not decoded, so the `>` the server escapes is a rule
  the browser drops, silently: the child combinators and the `@property` syntax are all affected. An early draft of
  this change lost the popover's fade rule that way, and nothing said so until a probe found its panel playing no
  animation.

What the user sees: a glass popover, menu or dialog keeps blurring what is behind it while it opens and closes, and the
blur recedes with the fill. Nothing changes under a style that draws no pass, under reduced transparency, a tier
without the pass or forced colours (they fade by opacity, as before), or for a panel that draws no pass.

**What does not dissolve on Web.** The frost and the shade a tuning adds (`ios27`) and the refraction bend are SVG filter
values, which CSS cannot scale, so they hold their stated value for the whole fade. The tooltip (opacity transition on
its bubble) and the retract motion of a lifted context menu (opacity keyframe on its box) fade a marked glass surface by
opacity and keep the defect; the drawer and the toast do not read this mechanism and were not examined for it (the
drawer slides its panel and fades only a flat scrim). A local material scope (a surface carrying no style attribute)
has no fade rule.

### Measurements

A probe on a device (`app/coui_widgetbook/integration_test/dialog_fade_probe_test.dart`) opens the shipped `Dialog`
through the shipped `showDialog` over two-pixel black and white stripes, holds the animation at chosen progresses with
`timeDilation`, captures the whole app and reads how much of the page's stripe contrast is left in the middle of the
panel. macOS 27.0, Flutter 3.50.0, Impeller (Metal), device pixel ratio 1.0, barrier transparent. "Kept" is the panel's
share of the page's stripes; the page beside it stayed at 127 throughout.

| Held at (opening) | Before — the route fades the panel as a whole | After |
| --- | --- | --- |
| 0.76 | 0.579 | 0.016 |
| 0.50 | 0.721 | 0.028 |
| 0.26 | 0.856 | 0.389 |
| 0.11 | 0.938 | 0.930 |
| settled | 0.008 | 0.008 |

Closing is the same within a few thousandths (after: 0.012, 0.016, 0.416, 0.941 at 0.75, 0.49, 0.24, 0.10). At the
lowest level both are near one on purpose: a panel with almost no fill has almost no blur left to show, and the probe
fails a panel that stayed blurred until the fill was gone.

"Before" is the real dialog with the route's offer switched off (the probe was run on that tree and failed on its own
verdict, "a plate, not glass", at 0.76). The probe also holds a control in every run: the same panel in a full-screen
route, which is faded as a whole, keeps 0.72 at half — so the probe could not have passed a plate. The existing popover
probe was run after the host was moved out of the engine and gives the numbers the guide records (0.031 at half, 0.008
settled).

### Measurements (Web)

`tool/parity/test/web/glass_fade_probe_test.dart` renders the shipped `Dialog` and a popover panel built from the
shipped resolvers (their markup, their motion chrome, the host's stylesheet, the liquid glass style) over one-pixel
black and white stripes, holds every animation at a chosen fraction of its length with the Web Animations API, and reads
how much of the page's stripe contrast is left in the middle of the panel. Chrome 158 on macOS 27.0, device pixel ratio
1.0, no scrim. The fraction of the length is the same fraction of the progress while the probe holds the easing linear.

| Held at (opening) | Popover family before — opacity on the motion box | Dialog before — opacity on the panel | After (both) |
| --- | --- | --- | --- |
| 0.25 | 0.88 | 0.75 | 0.020 |
| 0.50 | 0.75 | 0.51 | 0.004 |
| 0.75 | 0.62 | 0.26 | 0.004 |

A settled panel keeps 0.004. Its computed list, fill, shadow and border were compared with `main`'s settled panel during
the work (a throwaway snapshot, not kept), and the probe keeps the comparison that matters: a settled panel equals a
panel that has no fade at all. After, the probe also reads the first frames: 0.973 at 0.05 and 0.863 at 0.10, because a
panel that has only just started has a blur of a fraction of a pixel and almost no fill — the same reason the Flutter
numbers stay near one at the lowest level. Closing is held at the same fractions of the exit keyframe and read the same
way; only the opening is tabulated. The computed `backdrop-filter` at those points is
`blur(1px) saturate(1.15) brightness(0.98)` at 0.25 and `blur(2px) saturate(1.3) brightness(0.96)` at 0.5, which is
Core's share of the preset's `blur(4px) saturate(1.6) brightness(0.92)`; the dark list is read against Core the same
way.

"Before" is the library at `main` (measured on the replica the guide recorded, and the numbers are in the probe's
header). The probe also holds controls in every run: a panel that draws no pass keeps fading by its opacity, and the
three conditions that drop the pass (reduced transparency, a tier without it, forced colours) keep fading by opacity,
so the probe could not have passed by dissolving everything.

## Verification

Tests added, each mutation-checked: the behaviour was removed, the named tests failed, and the code was restored with a
checksum.

- `packages/coui_flutter/test/components/overlay/dialog_glass_fade_test.dart` (15) — at held points of the open and of
  the close: no layer above the pass that saves a pass; one layer fades the panel, beside the pass; the pass states
  the material at the progress the route states; at rest nothing is saved and the content paints straight through; at
  nothing nothing is painted. A style that draws no pass, a full-screen route and a root that is not a kit surface are
  faded as a whole. A focused field keeps its state and focus from the first frame to rest. The host and its claim
  are gone with the dialog.
- `packages/coui_flutter/test/components/infra/surface_fade_host_test.dart` (6) — the host with nothing rebuilding it:
  the progress reaches the surface, the claim moves the opacity off the panel, a panel nobody claims is faded by the
  host, and a host given another animation follows the new one on both paths.
- `app/coui_widgetbook/integration_test/dialog_fade_probe_test.dart` — the device probe above.

| Mutation | Tests that failed |
| --- | --- |
| the route never offers the fade (the previous behaviour) | 10 of 15 |
| the panel never adopts it | 9 |
| the panel claims it but is not handed the progress | 8 |
| the panel declines it (`drawsPass` false) | 9 |
| the claim is ignored, so the panel is faded twice | 6 |
| a full-screen route is offered it | 1 |
| the panel's wrapper disappears once the progress reaches full | 2, including the state test |
| the host stops listening to its animation | 0 of the dialog tests, 6 of 6 host tests |
| the host keeps the old opacity after it is given another animation | 1 (host) |

Two of the new tests were weak and were rewritten after their mutation passed them: the walk of a closing dialog broke
out of its loop when it found no fade box to read, so it passed on the previous behaviour; and the swap of animations
read only the progress the surface sees, not the opacity on the panel. The host mutation passing the dialog tests is
why the host has tests of its own — the route rebuilds its transition every frame and hides a host that does not listen.

Commands and numbers, on Flutter 3.50.0 (Dart 3.14.0), macOS:

- `flutter test test/components/overlay` in `packages/coui_flutter`: 588 passed (the 15 dialog tests, the existing
  1,136-line popover fade test, every dialog, drawer, tooltip and popover test).
- The whole `packages/coui_flutter` suite: 12,131 passed, 5 skipped, 2 failed — `OutlinedContainer` and `Badge`
  goldens on macOS (2.56 % and 0.59 % of pixels). Both fail identically with the four changed source files restored
  to `main` (checked by running them on that tree), so they are drift on this machine and not this change. The two
  new test files were then edited for analyzer findings only and re-run.
- `dart format` has no drift and `dart analyze --fatal-infos` reports nothing on any file touched here.
- Docs gates `docs_plain_words`, `docs_section_contract`, `catalog_single_source`, `llms_txt_sync`, `docs_api_sync`
  and `guide_catalog_single_source` pass; `check_rule_writing.sh` is at its baseline (no net-new).

The follow-up (the cast), checked the same way:

- `dialog_glass_fade_test.dart` gains three tests (18 now): a translucent panel paints its cast outside the box and not
  in its decoration; an opaque panel keeps it in its decoration and mounts no `InjectedCast`; the outside cast is held
  at the progress times its rest alpha, layer by layer. Three mutations, each restored and checked with `cmp`: the cast
  never goes outside the box (2 of the 3 fail), the outside cast is not faded (1), the decoration keeps its cast too (1).
- On `main` with the follow-up: the whole `coui_flutter` suite without goldens, 12,134 passed and 5 skipped; the dialog
  golden passes; `check_cast_read_by_every_caller.sh` and `check_flutter_surface_contract.sh` pass.

### Verification (Web)

Tests added, each mutation-checked: one thing was broken, the named tests failed, and the file was restored.

- `packages/coui_web/test/overlay/overlay_fade_test.dart` (14) — what the motion chrome states and what the host's
  stylesheet carries. The box scales and has no opacity of its own, in both directions, and names the fade its child
  plays; a morph's box has no keyframe and still names it; a panel that is not placed yet fades nothing. The dialog's
  panel scales, walks the progress and names what it plays, and its scrim still fades by opacity. The stylesheet reaches
  the browser unescaped, defines every keyframe the chrome names, walks the progress beside the scale in the dialog
  keyframe, and gives a slot a panel does not play a name that no keyframes go by.
- `packages/coui_web/test/base/surface_fade_target_test.dart` (18) — which surfaces get fade rules (a style that draws a
  pass, for the two panel forms, once per role, and none carrying an apostrophe, which would end the single-quoted
  script string the sheet is injected in); what they state (the list the surface states, term for term and in
  its order, with the progress in it; the fill by the progress itself; the dark, system and scope forms); where a panel
  is taken back to fading by opacity (reduced transparency, each quality tier without the pass and no other, forced
  colours, every declaration `!important`); that every form outranks the surface rule it restates, by an exact pairing
  of the selectors; and that the rules declare nothing the palette or the preference contend for.
- Six existing test files changed. The adaptive-quality test now holds the tier rules to two statements (the surface's
  opaque fill, and the take-back) instead of one. The two specificity ladders (a scope's palette against a style's
  bends against high contrast, and the preference against a style) leave the fade rules off, because those rules match a
  panel's surface and write only the pass and the names of the fade; the new test above pins that. The top-layer and
  context-menu-lift tests find the host's stylesheet as raw text. The morph test says what a morph's box has now.
- Two existing Chrome probes changed. `menu_viewport_fit_probe_test.dart` and `rich_editor_selection_toolbar_probe_test.dart`
  waited for a panel's enter motion to finish by reading its motion box's opacity, which the box no longer carries, so
  they measured a panel that was still scaling in (3.6 px and 1.6 px off; the toolbar probe went from 1 red test to 9).
  They now read the animations themselves, and keep the opacity for what it still says: that the panel is placed.
- `tool/parity/test/web/glass_fade_probe_test.dart` (19) and `tool/parity/test/web/glass_fade_runtime_probe_test.dart`
  (4), with the hydrated fixture `tool/parity/src/web/glass_fade_entry.dart`, in Chrome: the measurements above; the
  computed list at held points against Core's share (light and dark); the settled panel equal to a panel with no fade;
  the fill, the shadow, the content and the decoration fading with it; the controls; and, on a hydrated page, the list
  the refraction runtime writes onto a dialog that is still fading in.

| Mutation | Tests that failed |
| --- | --- |
| the host's stylesheet is written as escaped text | 2 (host stylesheet) |
| a closing panel does not hold its end | 2 |
| the motion box is given an opacity of its own | 1 |
| the dialog's panel loses its fade root class | 1 |
| `!important` removed from the take-back | 3, including the tier test |
| the blur does not follow the progress | 2 |
| the forced-colours take-back is not written | 2 |
| the role class is dropped from the fade rules' target | 4, including the tier test |
| the scope forms lose the style attribute | 2 |
| the chroma lift does not follow the share | 2 |
| the fill does not follow the progress | 1 |
| saturate and brightness swapped | 1 |
| an apostrophe in a fade rule | 1 (the only test that reads for it) |
| the refraction runtime writes the list as it computes at first sight | 2 (runtime probe, both dialog tests) |

One of the new tests was weak and was rewritten after its mutation passed it: the specificity test paired each fade rule
with the surface's rule by substring, so a scope form that had lost its style attribute (and was lower) still found a
rule that ended the same way. It now pairs by the whole selector.

Commands and numbers, on Dart 3.14.0, macOS, Chrome 158, with `main` at `245f3c5e8` (the tree this was written on):

- The whole `packages/coui_web` suite: 9,038 passed and 25 failed. All 25 are `checkbox_mark_stroke_test.dart`, and they
  fail identically on a clean worktree of `main` (checked there), so they are not this change (see "Found on the way").
  Before the existing tests were updated, seven other tests were red; they are the six files above.
- The Chrome probes, from the repository root: 23 passed (19 and 4).
- The existing Chrome probes that touch an overlay or a glass surface (25 files), from the repository root: every test
  passes except those named in "Found on the way". Before the two probes above were repaired, `menu_viewport_fit_probe_test`
  failed twice in a row on this tree and passed on a clean worktree of `main`; that was the only difference found.
- `dart format` has no drift, and `dart analyze --fatal-infos` reports nothing on the new and changed tests, the probes
  and the fixture. The seven library files carry the same 21 findings as `main` and add none.
- Docs gates `docs_plain_words`, `docs_section_contract`, `catalog_single_source`, `llms_txt_sync`, `docs_api_sync` and
  `guide_catalog_single_source` pass; `check_rule_writing.sh` is at its baseline.

### Not verified

- Web, beyond Chrome on macOS. Safari and Firefox were not run: they parse the refraction filter and draw nothing for
  it, and whether they keep a blur through a registered-number keyframe was not read. A real screen reader and a real
  forced-colours or reduced-transparency device were not used; those conditions were emulated through the protocol,
  and a quality tier through its attribute. The frost, the shade and the bend are not dissolved (see "What changed").
- Impeller on iOS and Android, and Skia. The device probe ran on macOS only; the layer-tree tests do not depend on the
  backend, but whether the compositor keeps the blur is the engine's, and it was measured on that one.
- A real screen reader, a real keyboard, and a dialog with a caller-built page in it: the state test covers a field in
  the dialog's body, not an arbitrary page.

## Open decisions

1. **Web terms that hold while the panel fades.** The frost and the shade a tuning adds, and the refraction bend, are SVG
   filter values, which CSS cannot scale. Dissolving them means writing the filter's attributes from script on every
   frame, or a ladder of filters chosen by progress. Neither is justified while the default style states none of them:
   the frost and the shade belong to `ios27` only, and the bend is not drawn on a popover's bubble at all. A cost call.
2. **The entrance.** Upstream scales in from 1.06 and sharpens the content from sigma 4; CoUI scales from its resolved
   start scale through the enter curve and fades the content with the fill. Which is right is the designer's.
3. **Full-screen dialogs.** They stay faded as a whole. Letting a glass surface inside one dissolve means a rule for
   which surface is "the panel", and the engine's rule (the root) does not fit a page.
4. **A glass surface inside a non-surface root.** Today the route offers the fade to the first kit surface under it,
   so siblings beside a glass surface in a caller's root appear at full strength on the first frame of the open. The
   other answer was built and tested on a parallel branch and not merged: the route offers the fade to the `Dialog`
   panel only, so any other root is faded as a whole like a full-screen route. That keeps such a root's siblings in
   the fade, at the price of a glass surface that *is* the root (a glass `Card` returned by the builder) losing its
   blur for the length of the fade, as every panel under an opacity does. Which of the two misses is the lesser is
   a design call.

## Found on the way, not changed

- **Three existing Chrome probes are not green on `main` in this environment** (Chrome 158). Two fail the same way on a
  clean worktree: `dialog_actions_stretch_probe_test.dart` (`justify-content` computes to `flow-end` where the table
  expects `flex-end`) and `dialog_keyboard_test.dart` (a 30-second timeout, which includes compiling the fixture). The
  third, `context_menu_lift_probe_test.dart`, fails some of its tests on every run in both trees, a different set each
  time, and by a hair (one run missed a blur bound of 21.51 with 21.57). None of them reads a panel's fade.
- **Twenty-five Web checkbox tests are red on `main`.** `packages/coui_web/test/components/form/checkbox_mark_stroke_test.dart`
  finds the indeterminate dash as the one `<div>` with a `w-size<N>` class and no `h-size<N>` class, and finds none
  (`Bad state: No element`), for every size. Run on a clean worktree of `main` it fails the same way, so it predates this
  change; not looked into.
- **Toast.** The toast layer fades an entry with an `Opacity` over a panel that draws its own `SurfaceBlur`, and a
  toast behind another is held at a partial opacity for as long as it is behind. By the mechanism above its blur is
  lost for that time; not measured, and it needs the stack's own opacity untangled from the entry's.
- **The dialog's cast.** Looked at afterwards, and applied — see "Follow-up" under "What changed". `Drawer` and the
  toast panel have the same shape (a `SurfaceBlur` panel whose decoration states `boxShadow`); they were not changed
  here.
- **Hit tests outside a `Stack`.** #489's remark that `Clip.none` paints outside a `Stack` and does not take taps
  there is general. CoUI was not searched for a control that depends on it.
- **The macOS build rewrites tracked files.** Running a probe on macOS makes Flutter migrate the Runner to Swift
  Package Manager: `app/coui_widgetbook/macos/Podfile.lock`, `Runner.xcodeproj/project.pbxproj` and the `Runner`
  scheme change. They were restored here; do the same after a run.
- **Two goldens are red on the measuring machine** at `main` (above).

## Not applied, and why

- **The Web terms that cannot be scaled in CSS.** See open decision 1.
- **The action sheet and the search tab bar.** No such components.
- **The lightweight tier's visibility term.** No such tier.
- **Look calibrations.** The `standard` tier's dark tint floor and frost sigma, and the dialog entrance, are
  surface-style and motion decisions.

## Next pass

Start after `1.17.5` (`6c7752e1`).
