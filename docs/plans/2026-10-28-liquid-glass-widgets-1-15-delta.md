# liquid_glass_widgets 1.14.1 → 1.15.1 — what applies to CoUI

Reference: [sdegenaar/liquid_glass_widgets](https://github.com/sdegenaar/liquid_glass_widgets) at tag `v1.15.1`
(`6478c02`), inspected on 2026-10-28. This continues the earlier audits, which stopped at `v1.14.0` (`790521f`):
[benchmark](../discovery-liquid-glass-widgets-benchmark.md), [chrome](2026-10-19-liquid-glass-chrome-audit.md),
[motion](2026-10-19-liquid-glass-motion-analysis.md), [selectors](2026-10-19-liquid-glass-selector-audit.md),
[native chrome](2026-10-21-native-glass-chrome.md).

CoUI has its own glass (Core contract, Flutter seat, Web seat) and does not depend on the package. The package is a
behavioural reference: each upstream change was read, the CoUI code path that answers the same question was located
on both platforms, and the result is one of **applied**, **already handled**, **not applicable** (the structure that
produced the upstream defect does not exist here) or **designer decision** (a look or feel call, not a defect).
No upstream code was copied.

## Reading the result

Nothing in the upstream window reproduces in CoUI's rendering engine as such — CoUI has no geometry matte, writes
the refraction uniforms at composite time for every scene, draws each icon once, and expresses reach as a fraction
of the short side. What the comparison surfaced are behaviours both platforms share and the upstream release
happened to exercise: long menus, host updates, week start, logical indents, per-instance material, fling dismissal,
a keyboard and a touch path to the context menu, and an accessibility setting (iOS Reduce Motion) that the Flutter
seat never read. Comparing also turned up two defects that are older than the window: a glass surface under a layer
that saves its own pass was drawn with its band in the wrong place, and an inset divider on the Web ran out of its box.

## Disposition of the upstream window

| Upstream | CoUI |
| --- | --- |
| 1.14.1 glass moved by layout drawn one frame late | Already handled by construction (uniforms are written in `addToScene`, `alwaysNeedsAddToScene`); now pinned by a test that fails if that is changed |
| 1.14.1 no matte rebuild on layout-only moves; AA border at circle poles; single shared nav button is a true circle | Not applicable (no matte; silhouette is `ClipRRect`/CSS radius; circle shapes are `radius9999` tokens normalised by every renderer) |
| 1.14.1 `autoAdjustToScreen` for bar-item and pull-down menus | **Applied** — `CoreOverlayFit` (one rule, one vector table) and both seats: a menu taller than the viewport room takes the room and scrolls |
| 1.14.1 tab-bar icon mask alignment | Not applicable (icons are drawn once; the lens is real backdrop refraction) |
| 1.14.2 `holdMeasurement` for adaptive quality | **Applied** — an opt-in quality axis on both seats (`adaptiveQuality` on `CoUIApp` / `CoUIWeb`): one ladder in Core (`full` → `noRefraction` → `solid`, the last being the reduce-transparency fallback), one pure governor fed by raster time on Flutter and by rAF intervals on the Web, and `AdaptiveQualityScope.holdMeasurement` on both. Off by default; reduce transparency forces the lowest tier |
| 1.14.2 progressive blur repaint / zero-size guard | Not applicable (no progressive blur; shader divisors are guarded or engine-bound) |
| 1.14.2 open submenu follows parent row | `Menu` not applicable (submenus are inline); **applied** for Flutter overlay-hosted panels, which did not follow host updates (`PopoverEntryHandle.markNeedsBuild`; Web already did) |
| 1.14.2 dialog stacks two actions when a label does not fit | Already handled (`CoreDialogActionsLayout.stretch`); making it the default is a designer decision |
| 1.14.2 button press highlight clipped to the shape | Not applicable (no full-rect press overlay) |
| 1.15.0 swipe actions | **Applied** — a new component, `SwipeActions`, on both platforms with one Core engine and one vector table; its look and feel values are designer decisions (see decisions) |
| 1.15.0 disclosure group | Already handled (`Accordion`, `Collapsible`, `Disclosure`) |
| 1.15.0 edit mode and reorderable lists | Already handled (`Sortable`, keyboard reorder, lift shadow); press-and-hold activation is a possible follow-up |
| 1.15.0 context menus | **Applied** — Web touch long-press and Flutter keyboard open (two parity gaps) and, opt-in, glide-to-select, a preview slot, selection haptics and `liftChild` (a touch-and-hold row lift with retract-to-source) |
| 1.15.0 full-screen covers | `Drawer` covers distance-based dismissal and edge-to-edge; **applied** — fling-velocity dismissal, `openDrawer(routeSettings:)` and an opt-in rubber band (`rubberBand`, default off); corner rounding while dragging and the Done / Cancel bar are **not applied** — the bar is a row of `Button`s in `content` (shown in the docs example), not a component |
| 1.15.0 date and time pickers | Mostly already handled (`Calendar` multi/range, locale month and weekday names); **applied** — `firstDayOfWeek`, `minuteInterval` |
| 1.15.0 `dividerIndent` / `dividerEndIndent` | **Applied** — `Divider` indents are logical start/end, an inset line is shorter by its insets on Web as it is on Flutter, and a labelled divider with unequal insets centres its label in the box on both |
| 1.15.0 solid card surfaces | Flutter already complete (`SurfaceTheme`); **applied** — per-instance `surfaceStyle` on `Card` and `OutlinedContainer`, with a Web seat |
| 1.15.0 navigation stack, iOS 27 theme presets | Navigation stack: not applicable (routing). iOS 27: **applied** — per-mode saturation and light angle, a refraction law, the frost (`surfaceFrostBlur` / `surfaceFrostOpacity` / `…InDarkMode`) and the body shade (`surfaceBodyShade` / `…InDarkMode`) are `surfaceTuning` fields read by both seats, and the numeric preset is `CoreSurfaceTuning.ios27` (a constant, not a style; every number in it is a designer judgement). `rimShade` / `rimLight` and the frost's tonal clamp / weight are not built (see "Not applied") |
| 1.15.1 modal-sheet morph content reveal | Already handled (CoUI's morph is clip-only, content is visible from the first frame; no morphing sheet exists) |
| 1.15.1 dark context-menu platter blur | Already handled for the reported asymmetry (CoUI dark is denser than light); the frost is now an opt-in term an app can state (`surfaceFrost*`), its density is still a designer decision |

## Carried over from earlier releases (found while comparing)

| Upstream | CoUI |
| --- | --- |
| 1.7.2 iOS Reduce Motion | **Applied** — the Flutter seat honoured only `disableAnimations`, which iOS does not set |
| 1.10.0 dismiss action on menu/popover barriers | **Applied** — a `dismiss` accessibility action on Flutter and a screen-reader-only dismiss button on Web, both named by the locale's existing `dismissLabel`, so the localization-parity count does not move |
| 1.7.0 glass inside a `BackdropFilter` ancestor | **Defect confirmed on a device and fixed** — see below |
| 1.7.0 rim reach cap | Already handled for shipped values; **applied** — a tripwire test with a negative control (a runtime cap is a designer decision) |

## What changed

**Reduce Motion (Flutter).** `resolveReducedMotion` joins `MediaQuery.disableAnimations` (Android, macOS) with the
platform's iOS flag, and `ReducedMotionScope` (mounted by `CoUILayer`) makes a change made while the app runs reach what
already built. One seat: no component asks either flag for itself, a source scan pins that. Web already follows
`prefers-reduced-motion` through CSS variables and `matchMedia`.

**Glass under an enclosing pass (Flutter).** On Impeller/Metal the engine hands a refraction program the pixels and
coordinates of the pass a layer above it saves — an image filter, a layer-saving clip, or an opacity, shader mask, colour
filter or backdrop filter under a clip that does not start at the root origin — while the surface's rectangle is
measured against the root. The band was drawn displaced, at full strength: 16 of 50 measured enclosures were wrong, and the
existing edge probe could not see it (15 of the 16 passed it). `backdropReadsRootPass` walks the scene's own layers each
time the scene is built and the surface keeps the rest of its material, without the bend, where the pass does not start at
the root. Nothing above a surface (nearly every surface) costs a parent walk and no allocation.

**Long menus.** `CoreOverlayFit` states how much room a viewport leaves a panel and where an over-tall panel sits; Flutter
holds the panel with a layout constraint (`PopoverOverlayHandler.show(fitViewportHeight)`), Web measures and caps
(`OverlayPositioner(fitViewportHeight, onFit)`). `DropdownMenu`, `ContextMenu` and `Menubar` opt in; only a vertical,
non-nested `Menu` scrolls its rows, so a calendar or a form in a `Popup` is untouched. Menus that fit are placed exactly as
before. On the Web the host hands the cap to its `Menu` through a private scope and the `Menu` holds its own box to it and
scrolls its rows in a list *inside* the box. The box has to stay still: under a glass surface its rim is drawn by
pseudo-elements positioned inside it, and anything positioned inside a scroller moves with the scrolled content, so a
scrolling box carried its rim off the screen after the first scroll. The independent visual review caught that; the first
version scrolled the box itself.

**Hosts follow updates (Flutter).** A host that rebuilds with new items calls `PopoverEntryHandle.markNeedsBuild`
from `didUpdateWidget`; the panel lives in the app's `Overlay`, outside the host's subtree, and had kept the old rows.

**Context menu.** The hold (`CoreDuration.slow`, 500 ms) and the slop (18, a distance compared strictly) are Core numbers on
`CoreContextMenuContract`, with the one predicate that applies the slop. A touch or pen press is timed by each seat the same
way: Flutter hands the numbers to the framework's long-press recognizer, and the Web, which has no recognizer and cannot trust
`contextmenu` for a touch (Android sends it during the hold, a Windows touchscreen on lift, iOS Safari is not known to send it),
times the press itself. One vector table states, press by press, when the menu opens and where; Core reads it with a reference
reading, Flutter replays the shared rows as real pointer events, and the Web replays all of them on a DOM-free press tracker
with a manual clock. The native `contextmenu` of a touch belongs to the press for 150 ms after the lift, so it can neither
re-open nor toggle shut what the press just did, and the release of a press that opened the menu is consumed so the tap does not
reach the page under the menu (Flutter's long press wins the arena the same way). A `contextmenu` with no pointer position — the
keyboard's — anchors at the centre of its target on the Web. Flutter opens the menu from the context-menu key and `Shift+F10`
at the centre of the focused widget, with no tab stop of its own; `enabled: false` leaves both keys to ancestors.

**Divider.** `indent` is the start side and `endIndent` the end side in reading direction (Flutter
`EdgeInsetsDirectional`, Web `margin-inline-*`); a vertical divider keeps top and bottom. A standalone inset line on Web
is `calc(100% - indent - endIndent)` long, as Flutter's is, instead of `100%` plus margins running out of its box.
A labelled divider is a grid on the Web, one track each for the leading line, the label and the trailing line, so an
inset sits inside its segment's share as it does in Flutter's `Flexible` and the label stays at the centre of the box
whatever the insets (a flex row put the margins outside the share the segments divide). One vector table states the
expected rects; Core checks it against a closed-form rule, Flutter against the painted rects, a Chrome probe against
the real DOM.

**Calendar, pickers.** `firstDayOfWeek` (`DateTime.monday..sunday`, default Sunday, forwarded by the date pickers; the
header order is one Core helper, the grid and range band follow the first column) and `TimePicker.minuteInterval`
(a divisor of 60; `CoreMinuteInterval` snaps, steps and wraps without touching the hour). Neighbouring-month cells are
calendar arithmetic now, so a daylight-saving change cannot print the previous day's number.

**Material per instance.** `CoreSurfaceStyleId? surfaceStyle` on `CoreCardStyle` and `CoreOutlinedContainerStyle`:
null inherits the surrounding material (no default on purpose), a value replaces the material alone — an opaque card in a
glass theme, a glass card in an opaque one. Flutter resolves it through `resolveSurfaceTheme` like the other surfaces and
takes the refraction from the same material; Web swaps the document marker for the local one.

**Drawer.** A release dismisses on distance or on speed toward the docked edge
(`CoreDrawerContract.dismissesOnRelease(velocity:)`, `defaultDismissVelocity` 400 px/s). Flutter reads its recogniser's
velocity; the browser hands out positions and times, so `CoreDragVelocityTracker` estimates it in Core, in px/s, and both
platforms read one vector table. `openDrawer(routeSettings:)` names the route for a `NavigatorObserver` (Web has no
navigator stack).

**Drawer rubber band (opt-in).** `rubberBand` (default `false`; `Drawer.rubberBand` on the Web, `openDrawer(rubberBand:)`
decides on Flutter) lets a draggable panel be pulled past its dock. The panel's far edge follows the pointer with
diminishing returns (`CoreDrawerRubberBand.stretchOf`, bounded by `reach` × the panel's extent) while the docked edge
stays on the screen edge — the panel is scaled along its slide axis about it, so no gap opens. A stretched panel has
covered no dismiss distance, so a fling in the open direction never dismisses and the existing distance / fling rule
applies to a pull toward the dock unchanged. Letting go returns it over `CoreDuration.moderate` on `CoreEasing.enter`
(instant under reduced motion; the stretch while the finger is down still follows it); a pointer that lands on a returning
panel carries on from its current pose. One JSON table (`drawer_rubber_band_vectors.json`) is read by Core, Flutter, the
Web VM tests and a Chrome probe. On the Web the barrier hands a pointer that left the panel before the capture back to it:
a quick mouse pull in the open direction is past the panel's edge on its first move and otherwise never reaches the panel.

**Dismiss action.** A modal panel leaves the page behind it out of the accessibility tree, the tab order and hit
testing, and its scrim is `aria-hidden`, so a screen-reader user on a touch device has neither the scrim tap nor
`Escape`. A modal `Popover`, `DropdownMenu` or `ContextMenu` panel that closes on an outside tap exposes a `dismiss`
semantics action on Flutter and, on the Web, a screen-reader-only `role="button"` beside the panel (no tab stop: the
keyboard has `Escape`), both named by the locale's `dismissLabel`. A non-modal overlay, and a modal that ignores outside
taps, offers none, for the reason its scrim does nothing there.

**Surface tuning.** An app states three more terms of the glass material through `surfaceTuning`:
`surfaceSaturationInDarkMode`, `lightAngle` / `lightAngleInDarkMode` (the direction of the edge light) and
`refractionModel` (`snell`, the default, or `paraxial`: the law the refraction band bends light by, the shader's last
uniform). A term the app does not state is the preset's, so an app that states none renders what it rendered before
(the same theme on Flutter; on the Web the same stylesheet, byte for byte). A single statement covers both modes and
replaces the preset's dark statement; the `…InDarkMode` form leaves light alone. The Web client runtime bakes the rim
sweep and the displacement maps and cannot see the app's tuning, so the stylesheet declares only the values that differ
from the preset, as custom properties on the surface, and the runtime reads them.

**Frost, body shade and the `ios27` preset (opt-in).** Glass gets two terms an app states and a numeric preset. A *frost*
(`CoreSurfaceFrost`) is a second, wider blur of the backdrop mixed over it at a share: Flutter draws it as a sibling
backdrop pass under the material's, the Web as the first filter of the surface's own `backdrop-filter` list (an SVG
document carried as a data URL and defined once on `:root`). A *body shade* (`CoreSurfaceBodyShade`) multiplies each pixel
by `1 − strength·luma²`: Flutter draws it in the refraction program (a new uniform; a surface that bends nothing mounts
the program with the bend at zero, and the shade is kept where the bend is withdrawn because it reads no coordinates), the
Web in the same list. Both ride the backdrop pass, so a nested surface draws neither, and high contrast, forced colours
and reduced transparency take them away on both seats (the Web host re-binds when the preference flips, because it copies
the computed list inline). `CoreSurfaceTuning.ios27` states the look in one constant. Defaults are byte-identical: the
untuned Web sheet and `cssVariables` have the same sha256 as before, and an app that states neither term gets the same
Flutter theme. The earlier note that the Web has no handle for the backdrop's luminance was measured and is false for a
point operation: inside the surface's own list it reproduces the Core formula to one level, and a ring-shaped sibling
layer turns luminance upside down pixel for pixel; what the Web lacks is a place for a contour-confined term, not a
handle. **On the Web the two terms draw in Chromium only**: Safari draws nothing for a `backdrop-filter` list that names
an SVG filter, so in a browser that cannot draw them the stylesheet takes the two terms out of the list and the glass
keeps its blur, saturation and brightness — in WebKit from the first paint by a feature query on Apple's own features, in
the others by an attribute the client runtime writes from the refraction's user-agent answer (see the decision table).

**Context-menu interaction (opt-in).** `glideToSelect`, `preview` and `haptics` are off by default, so a menu that turns
none on renders and behaves as before. With glide on, the finger that opened a menu by long press picks a row by sliding
onto it and lifting: the glide begins once the finger is farther from the opening point than the slop (18, compared
strictly) and still counts after it returns; only the enabled row under the finger lights, and a disabled row counts as
itself so the row behind it does not; lifting on a row clears the highlight, ticks and runs the row, lifting elsewhere
closes the menu, and a finger that never began to glide leaves it open. `preview` shows the pressed target beside the
menu: above, else below, else at the end, else at the start, whole on the first side that holds it and otherwise shrunk
on the widest side, 8 from the menu, never over it and never outside the viewport. `haptics` ticks as the finger enters a
row (the system selection tick on Flutter, `navigator.vibrate(10)` on the Web where it exists). The decisions are Core's
(`CoreContextMenuGlide`, `CoreContextMenuPreview.place`, `CoreHapticCue`); two shared vector tables are replayed by
Core, Flutter (as real pointer events), the Web (on a DOM-free press tracker with a manual clock) and Chrome probes.
**Row lift and retract-to-source (opt-in).** `liftChild` is off by default, so a menu that does not turn it on renders and
behaves as before: the Flutter engine's `hostPaintsClose` defaults to false, the Web child is not wrapped, and the Web
overlay host's stylesheet carries two more rules that match nothing unless a lifting menu is on the page. A held touch
lifts the child after 150 ms over 300 ms to 1.04× with a `CoreShadow.lg` cast over a 20 % scrim tint, fully lifted before
the 500 ms hold commits; letting go, drifting past the slop, the system taking the touch or a scroll under it sets it down
from where it got to; openings with no hold lift with the menu and never delay it. The lifted child is a second build of
the same child — no state of its own, not interactive, focusable or announced — above the dim and below the menu's
barrier; the original keeps its slot, its state and its accessible element. Every close (Escape, outside press,
activation, controller, glide release) folds the panel and the preview toward the point of the source nearest the panel
(0.3×, fading, over the panel's own close duration) while the copy settles, and the copy, the dim and the panel leave in
the frame the original shows. The judgements are Core's (`CoreContextMenuLift`, `CoreContextMenuLiftTimeline`,
`CoreContextMenuRetract`, with the curve read by `CoreCubicBezierTransform`, the evaluator the drawer's table uses too);
one vector table of 14 traces is replayed by Core, Flutter (real pointer and key events), the Web (the touch tracker and
the timeline on a manual clock) and Chrome probes (real touch input, the computed style of every frame). The child is
built twice while the menu is open — once per copy, not once per frame. On the Web a surface style that bends `--shadow-*`
reaches the copy only when it is fully lifted. The six numbers of the look are `CoreContextMenuStyle` fields — a menu's
own style over the theme's over the defaults, chained the same way on both seats — and the engine holds a held touch's
rise to the room the hold leaves after the delay (and the scale, the fold size and the dim to their ranges), so an app's
longer duration cannot push the lift past the commit.

**SwipeActions.** `SwipeActions(child:, leadingActions:, trailingActions:)` slides a list row sideways to show actions
behind it, with the same names, order and defaults on both platforms. An action is a circular `Button` (`lg`) with its
label beneath; inside one `SwipeActionScope` a single row is open at a time. Every judgement of the gesture (follow,
rubber band, full swipe, close / open / run the first action on release, the sign in reading direction) is Core
(`CoreSwipeGeometry`, `CoreSwipeDrag`, `CoreSwipeGesture`, `CoreSwipeExclusivity`), and one vector table (constrain,
settle, gestures, extent, open) is replayed by Core, Flutter (as real pointer events), the Web (on a DOM-free row model
with a manual clock) and Chrome probes. Flutter's drag joins the gesture arena and settles with a critically damped
spring that inherits the release velocity (a jump under reduced motion); on the Web each action is a
`<button aria-label>`, the platter is always in the DOM (clipped, not hidden) and the root is `tabindex="-1"` on every
row, because an element that loses the attribute while it has focus drops focus to `body`. The keyboard path is the same
on both: an enabled action in a closed row is a tab stop (leading actions, row body, trailing actions), focus entering a
side opens it and takes the scope, `Enter` / `Space` runs the action and closes, `Escape` closes only an open row so an
enclosing dialog keeps its key, and whenever a row closes the focus inside its platter returns to the row after the
build pass, unless something else took the focus meanwhile. The Figma set is `Layout/SwipeActions` (Enabled × Pose).

**Adaptive quality (opt-in).** `CoUIApp(adaptiveQuality:)` / `CoUIWeb(adaptiveQuality:)` let an app trade the glass for
smoothness. `CoreQualityLadder.standard` orders what a surface can go without — the bend, then the backdrop pass with what
rides it (the blur, the chroma lift, the dimming, the frost, the body shade and the translucent fill) — as data;
`CoreQualityGovernor` (pure; skip, warm-up, windows, degrade fast / recover slowly, cooldown, probation with back-off,
nesting holds) is fed raster time by the Flutter seat and `requestAnimationFrame` intervals by the Web seat, against a
budget derived from the display's refresh rate. A tier reaches surfaces through the one place a recipe becomes a material
(Flutter: `applySurfaceStyle`, retained on `ThemeData.surfaceQuality`; Web: the `data-coui-quality` document attribute
read by the stylesheet's twin of the reduce-transparency rule and by the refraction host); a reduce-transparency
preference is the lowest tier whatever was stated; a tier never adds an effect. Unstated, nothing runs.
`tool/frame_timing` measures scenes × tiers on both platforms; the numbers are the evidence for the ladder order and the
starting thresholds.

## Verification

The replay below did not run on GitHub. The workflow's own `run:` steps (the `static-guards` and `flutter` jobs, the Chrome
steps of `web-selection`, the Figma plugin's static steps) were replayed on this machine with Flutter 3.47.6 (CI pins
3.47.5), once on pristine `a1b612621` and once on the integrated tree, so a red step can be told from a regression.

| | pristine `a1b612621` | integrated tree |
| --- | --- | --- |
| Steps passing | 22 of 28 | 22 of 28 |
| Structure guards | `phone_input` chromeless only | the same one line |
| Chain artifacts | `toggle.md` stale only | the same |
| Preset render snapshot | 291 pass, 4 `toggle` cases fail | 291 pass, the same 4 fail |
| `coui_flutter` tests | 9095 pass, 4 fail (the same four snapshots) | 9346 pass, the same 4 fail |
| `coui_core` tests | 5677 pass | 6010 pass |
| `coui_web` tests | 6910 pass, 3 fail (`Badge` previews) | 7132 pass, the same 3 fail |
| Tool tests | 594 pass, 1 fail (`radio-group` generated table) | 636 pass, 2 more skipped, the same 1 fail |
| Chrome steps, Figma plugin steps | — | all pass |

The six red steps are red on pristine `a1b612621` too, and nothing inside them differs: the failing test names and the one stale
document match line for line. No ratchet baseline, allowlist, waiver or `// ignore` was added or changed. The analyzer reports
317 findings on the changed files against 329 on pristine, and no finding is new.

The Figma freshness step reports green without checking whenever `components.json` already has uncommitted changes, so the
exporter was run on the tree and its output compared byte for byte with the file: identical. The change set also applies cleanly to
the current `origin/main` (38 commits ahead of the base when last checked), the export is still fresh there, and every new or
changed test file (Core 337, Web 273 and Flutter 449 cases) passes on Flutter 3.47.5, the CI pin, on top of a `main` a few
commits older than that.

Beyond the replay: every new rule was checked by mutation (break the behaviour in one place and at least one test must fail;
the reports list the mutants), the Web behaviours were driven in real Chrome 156 (drawer fling, long menus, touch long press,
RTL dividers and the inset line length, minute-interval keys), and the enclosing-pass defect was measured on a macOS Metal
device (28 probe cases: 15 pass and 13 fail without the fix, 28 of 28 with it).

The dismiss action, labelled-divider centring, surface tuning, context-menu interaction and `SwipeActions` were verified
the same way, each against the `main` it landed on: the replay of the workflow's non-test steps and the pull request's
own CI fail on the same steps, with the same messages and numbers, as a clean `main` (red steps these changes do not
touch), and each has shared vector tables, real-Chrome probes and mutation runs of its own. The numbers are in those
pull requests and are not repeated here.

### Visual review

The same scenes were rendered before (pristine `main`) and after on both renderers — Flutter on macOS Impeller (debug
builds) and Chromium 156 through the shipped client or server-rendered markup — in light and dark, `defaultStyle` and
`liquidGlass`: 130 images. Four independent reviewers (Codex `gpt-6.1-terra`, one per scene, working from the pixels and a
one-sentence intent per image) judged them, and the repository's own parity captures (VRT) were re-run on 13 component slugs.

- **Long menu.** A 30-row menu in a 360×480 viewport overflows by 670 px on Flutter and ends 1212 px below the screen on the
  Web before; after, both panels are the same box with an 8 px margin above and below, and the last row is reachable by
  scrolling. The review found one defect in the first Web version: the glass rim vanished after the first scroll, because the
  panel's box was the scroller and the rim is drawn by pseudo-elements inside it. The Web now scrolls an inner list, a Chrome
  probe pins that the box does not scroll, and the re-review of the new captures flags nothing of the kind. What it still lists
  predates this work and is the same before and after: the capture page has no `box-sizing` reset, so Web rows measure 52 px
  against Flutter's 36 (a page with Tailwind's preflight lays them out at 36); a glass panel's corner radius is smaller on the
  Web than on Flutter (not investigated); Flutter shows a scrollbar thumb where a still Web frame shows none.
- **Divider insets.** In RTL the Flutter line ran from 64 to 312 before and runs from 48 to 296 after — under the row title's
  first letter and ending at the value's end edge — and the Web LTR plain line no longer ends 32 px past the value. The
  captures also show a labelled divider with unequal insets centring its label in the box on Flutter and in the inset
  region on the Web (8 px apart at 24/8); the grid layout under **Divider** centres it in the box on both.
- **Week start.** The default calendar is pixel-identical before and after on both platforms; `monday` and `saturday`
  reorder the header, the grid and the leading days, and the explicit Sunday equals the default.
- **Per-instance material.** The default glass card is pixel-identical before and after; a card with
  `surfaceStyle: defaultStyle` is opaque and flat on both platforms with the same interior colour, equal to the
  `SurfaceTheme` cross-check on Flutter. A button inside such a card stays glass, which the reviewer found coherent and
  legible for a card-only override.
- **Regression pass.** 488 VRT cells: the 328 that pass have zero differing pixels against their baselines; the 160 that
  fail (7 slugs) fail identically on pristine `main`, where the render is pixel-identical to the patched one — baseline
  drift that predates this work and is not root-caused here. The VRT covers none of the new behaviours.
- **Limits.** The Web liquidGlass menu panel renders flat grey in headless Chrome 156 on pristine `main` as well, so the menu
  is judged there for fit and scrolling only. Flutter captures are debug builds. The context-menu long press and keyboard
  open are behavioural and in no frame. The Web captures of the long menu were re-taken after the scrolling fix; every
  other image predates it, and none of those scenes contains a menu.

### Not verified

- **Devices.** No iOS or Android device and no Windows touchscreen. iOS delivering the Reduce Motion flag, real touch
  long-press timing (the native `contextmenu` moments of Android and Windows were simulated by injecting events at the two moments
  browsers send them), iOS Safari, and a thumb on the drawer, on a swipe row or gliding across a context menu are untested.
  The enclosing-pass rule was measured on macOS Metal at a device pixel ratio of 2 only.
- **Assistive technology.** The `dismiss` action, the swipe-action semantics and the keyboard paths were checked through the
  semantics tree and the DOM (names, roles, focus, tab order), not with a screen reader on a device.
- **List cost.** A `SwipeActions` row builds both platters while it is closed (clipped to zero width, so that focus and the
  opening motion have a target); a long list of rows has not been benchmarked.
- **Browsers.** Chrome 156 only. Firefox and Safari keyboard coordinates for the context-menu key are unknown; a browser that
  coarsens event timestamps would make the drawer fall back to distance-only dismissal (reasoned, not run).
- **SDK.** CI pins Flutter 3.47.5; the full replay ran on 3.47.6 and only the new and changed tests were re-run on 3.47.5.
- **Figma canvas.** Import and Generate were not run. The `SwipeActions` set and the `ContextMenu` preview frame come from
  canvas builders that are new or changed, which the plugin's static steps and its runtime harness cover and a real canvas
  does not. `minuteInterval`, `dismissVelocity` and `longPressSlop` are behaviour defaults that reach `components.json` and
  no builder reads them.
- **Advisory CI jobs.** `parity-gate` and `perf-observe` were not replayed; the visual review above stands in for the first.
- **Context-menu lift.** Real touch (iOS, Android, a Windows touchscreen: the Chrome probes inject CDP touch events, the
  WebKit run synthetic pointer events and the Flutter tests the widget tester's pointers), Safari and Firefox themselves
  (the table's rows pass in Playwright's WebKit), screen readers, the lift under a high-contrast scheme or a surface style
  that bends shadows and radii, the cost of building a heavy child twice, a menu inside an iframe or a transformed
  ancestor, the Figma canvas (only five `behaviour` keys in `components.json` change, no builder reads them), and the feel
  of the numbers.
- **Opt-in features (frost, body shade, adaptive quality, drawer rubber band).** Frost and shade cost on any device (one
  extra backdrop pass per surface; the frame-timing harness measures the governor's rungs, not the frost); Firefox for
  every Web claim here; real iOS / Android touch for the rubber band (Chrome with synthesised touch only); the rubber
  band's feel, and the visual cost of scaling the content (one screenshot, no pixel baseline); forced colours and high
  contrast with a quality tier or the rubber band in a browser (reasoned from the diff); other GPUs than Apple Metal; a
  120 Hz machine for the interval threshold; thermal throttling and battery saver; the governor on a Flutter device under
  a natural load (run once against a 480 Hz target).

## Open decisions

Values the code carries that were chosen by judgement, not derived, and the one-line change for each alternative. None of
them blocks the change set.

| Decision | Current | Alternative |
| --- | --- | --- |
| iOS Reduce Motion | Transition-tier motion becomes instant; the dock flight, morph clip and status pulse are skipped; the glass nav bar drops its selection lens | Keep a cross-fade, as Flutter's own Cupertino menu does |
| `ReducedMotionScope`, `resolveReducedMotion` | Public, through the existing motion barrel, so an app that hosts CoUI widgets without `CoUIApp` can mount the scope | Private to the app seat |
| Menu taller than the room | Takes the whole usable viewport and covers its trigger | Cap at the room on one side of the trigger (one line per seat) |
| Safe area on the Web | The positioner has no safe-area input, so a capped panel can reach under a notch | Feed `env(safe-area-inset-*)` into the positioner |
| Drawer fling | 400 px/s toward the docked edge dismisses whatever the distance; the tracker windows (100 ms, 40 ms) equal Flutter's own | Tune on a device; the table keeps its rows 200 px/s clear of the figure |
| Context-menu hold and slop | 500 ms and 18 on both seats (Android reports a tighter slop; it is 18 now) | Per-platform values |
| Context-menu release window | 150 ms (`CoreDuration.fast`) during which a native `contextmenu` still belongs to the press | — |
| Web `Shift+F10` | Relies on the browser sending `contextmenu` (macOS Chrome does not) | A `keydown` fallback, de-duplicated against the native event |
| Web focus after a keyboard-opened menu closes | Stays on `body` (the modal portal makes the page inert; every modal overlay shares this) | Restore focus in the shared overlay layer |
| Context-menu glide and preview | A glide begins 18 from the opening point (the long-press slop); the preview sits above the menu, else below, else at the end, else at the start, 8 from it; the Web haptic is 10 ms (Flutter plays the system selection tick); all three are off by default | One constant each: `CoreContextMenuContract.defaultGlideSlop` / `defaultPreviewGap`, `CoreHapticCue.selectionTick` |
| Context-menu lift | Scale 1.04, delay 150 ms, rise and set-down 300 ms on `CoreEasing.enter`, cast `CoreShadow.lg`, dim 20 %, cast-box corner 16, fold to 0.3× over the panel's close time on `CoreEasing.exit`; off by default | One constant each: `CoreContextMenuStyle.defaultLiftScale` / `defaultLiftDuration` / `defaultLiftCast` / `defaultLiftDimOpacity` / `defaultLiftRadius` / `defaultRetractScale` and, on the contract, `CoreContextMenuContract.defaultLiftDelay`; the easings are `CoreContextMenuLift.easing` and `CoreContextMenuRetract.easing` |
| Context-menu lift on pointer and keyboard openings | A right click, the menu key, a controller and an assistive long press lift together with the menu | `CoreContextMenuContract.defaultLiftsWithoutHold = false` (only a held touch lifts) |
| Context-menu lift values live on the style | The six visual numbers (scale, rise duration, dim, cast, cast-box corner, fold size) are `CoreContextMenuStyle` fields with `default*` constants, overridable per instance and by theme, resolved by the usual chain on both seats and carried by the Figma export; the delay, the hold, the slop and `defaultLiftsWithoutHold` stay on the contract, because the two seats must wait the same time whatever a style says. The six old contract statics remain as deprecated aliases | Keep them as contract statics (one number for every app, no per-instance override). Figma's unread-field guard asks for a reason for five of the fields (a canvas cannot draw a gesture-time value): an allowlist entry each, not a builder |
| Surface style on the Web copy | The cast is `var(--shadow-lg)` when fully lifted and a literal below it, so a style that bends the variable reaches it at the top only (Flutter bends at every progress) | A way to bend a derived stack in CSS (none is known) |
| Turning `liftChild` off while lifted | The copy and the wrapper go at once; the menu stays open and closes without a fold | Close the menu with the option |
| `SwipeActions` look | Action cell 48 (the `lg` rung), spacing 12, platter inset 12, transparent platter, label under the button, full-swipe scale 1, a plain action is a `secondary` `Button` | iOS's 50 pt circle, a tinted platter, a scaled full-swipe action, icon-only; each is one constant in `CoreSwipeActionsStyle` / `CoreSwipeActionsContract` |
| `SwipeActions` feel | Full swipe at 0.65 of the width and on by default, open at 0.5, fling 400 px/s, resistance 0.25, drag slop 18, settle 200 ms (`CoreDuration.normal`) | Tune on a device; each is one constant on `CoreSwipeActionsContract` |
| Nested `SwipeActions` on the Web | The outer row's caller `onClick` / `onKeyDown` / `onKeyUp` skip any row's action, as Flutter's action takes the press; the outer row's content click handler still hears a nested row's action, as it hears any button in the content | Let a nested row's action reach the outer row's caller handlers (`identical(platter.parentElement, event.currentTarget)` in `_cameFromAction`); stopping propagation instead would hide the click from every ancestor |
| iOS 27 material | Per-mode saturation and light angle, the refraction law, a frost (σ, share, per-mode share) and a body shade (per-mode strength) are `surfaceTuning` fields; `CoreSurfaceTuning.ios27` states them (a constant, not a style: no Figma mode, snapshot or parity cell) | Make it a `CoreSurfaceStyleId` (and take the Figma mode, snapshot and parity cell with it), or leave the constant to apps |
| `ios27` blur | `surfaceBlur: 0.6` | The preset's 4 (the ghost under the cloud becomes a haze) |
| `ios27` chroma lift | 2 light / 1.4 dark; the reference states 2.1 but `maxSurfaceSaturation` is 2 | Raise the bound (a bound change of its own) |
| `ios27` light | `lightAngle` 0 (above) / 180 (below) | The preset's −45 |
| `ios27` refraction law | `paraxial` (width, strength and index stay the preset's; the travel scales with `index − 1`) | `snell`; judge the strength again |
| `ios27` frost | σ 14, share .73 light / .85 dark, the cloud made from the **raw** backdrop (before the material's blur) | Wider (cap 64) reads flatter, narrower keeps shapes; a cloud made from the blurred copy (the material's blur then shapes the cloud) |
| `ios27` body shade | .28 in dark (white → 184 of 255), none in light; the pull is `luma²` | State `surfaceBodyShade` to darken light as well; exponent 1 darkens mid-tones as much as the page (one change in the Core table, both shaders and both filter documents) |
| `ios27` fill | `surfaceOpacity` not stated: the preset keeps its 0.5 / 0.6 | The native dark fill (~12 %) is below `minSurfaceOpacity` (0.4); lowering the bound needs a contrast model for the preset |
| Frost cost | One extra backdrop pass per glass surface; off unless stated; shed at `resolveSurfaceFrost(BuildContext)` | A budget rule at that function (frame time, surface count, thermal state) |
| Frost and shade in Safari | In a browser that draws nothing for a backdrop list naming an SVG filter the sheet takes the two terms out of the list: WebKit from the first paint (a feature query on `-apple-pay-button-style` / `font: -apple-system-body`), the others by `data-coui-svg-backdrop="off"`, which the host writes from the refraction's user-agent answer; the surface keeps its blur, saturation and brightness | Leave the terms in the list for apps that target Chromium only (they lose the glass's blur in Safari), or draw them some other way than an SVG filter in a backdrop list there |
| Glass popover fade | The popover engine hands the fade to a surface that draws a backdrop pass: fill, content, edge light, rim and shadow follow the progress, and blur, chroma lift, frost, body shade and bend strength follow `CoreSurfaceDissolve.share(progress)` (the progress to the power 1), so the glass dissolves and a panel never turns into a plate; a panel that draws no pass keeps the engine's `FadeTransition` | `CoreSurfaceDissolve.materialExponent` above 1 loses the glass's character before its fill (a plate going), below 1 keeps the blur longer (glass going); fading by opacity as before loses the blur in the first frame |
| `Dock` bar height | `CoreDockStyle.height` is the bar's minimum: the bar is exactly that tall while its row — and the room kept for the active pill — fits and grows with it, items centred, so large text does not clip it | A fixed height with the label's text scale clamped or the labels ellipsized (Core height, both seats and the Figma export move together) |
| Drawer rubber band — stretch | Reach 0.1 of the extent (300 px → ≤ 30 px), tension 0.55 | Reach 0.05 barely shows, 0.15 is looser; tension 1 follows 1:1 before bending, 0.4 is firmer (`CoreDrawerRubberBand.defaultReach` / `defaultTension`) |
| Drawer rubber band — return | `CoreDuration.moderate` 300 ms on `CoreEasing.enter`, no bounce | `normal` 200 ms / `slow` 500 ms; `CoreEasing.move`; a spring needs a Web transport (a `linear()` easing or JS) |
| Drawer rubber band — default | Off | On for every draggable drawer (`CoreDrawerContract.defaultRubberBand`) |
| Drawer rubber band — how it is drawn | Scale about the docked edge (content stretched ≤ 10 %) | Translate and fill the gap with a skirt of the surface fill (no content distortion; needs the surface drawn outside `content`) — a design change, not a constant |
| Adaptive quality default | Off (`adaptiveQuality: null`); an app opts in with `const CoreAdaptiveQuality()` | On by default (the parameter default on `CoUIApp` and `CoUIWeb`) |
| Adaptive quality ladder order | Bend, then the backdrop pass (`CoreQualityLadder.standard`) | Insert a cheaper rung in front (one `CoreQualityStep`); the pass first is not expressible as a look |
| Adaptive quality governor constants | Skip 1.5 s, warm-up 3 s at P75, window 2 s at P95, degrade after 2 windows, recover after 10, probation 5 with ≤ 3 doublings, cooldown 8 s, Web grace 2 s | Each is one `CoreQualityTuning.default*` |
| Adaptive quality thresholds | Cost: start 1.0, stride 0.5, over 1.0, comfortable < 0.5 of a budget; interval: 1.5 / 1.0 / 1.5 / < 1.15 | `CoreQualityThresholds.cost` / `.interval`. `interval.under` was marginal at 120 Hz on a loaded M3 Max (healthy p95 = 1.09–1.19 budgets) and comfortable at 60 Hz on the M4 Max (≤ 1.04); 1.25 is the first alternative to measure on a quiet 120 Hz machine |
| Adaptive quality metric | Flutter raster time; Web rAF interval | Flutter total span |
| Adaptive quality step up | Allowed, slow, with probation | `allowStepUp: false` (a ratchet) |
| Adaptive quality, a rung below `solid` | None: at `solid` a Flutter card still costs ≈ 0.7 ms raster | A further `CoreQualityEffect` (rim, shadows) and one `CoreQualityStep` |
| Scope of a per-instance `surfaceStyle` | Replaces the Card's own material only; controls inside keep the surrounding material (a glass button on an opaque card stays glass) | Re-seat the whole subtree, which is what `SurfaceTheme` does |
| Calendar first day | Sunday, as before | Derive it from the locale |
| Minute interval typing | Typed minutes snap on blur and on save, not per keystroke | Snap per keystroke |
| Glass under an image filter | Every image filter counts as a pass of unknown origin: the surface keeps its material, without the bend | Measure each filter |
| Rim reach | A tripwire test fails if a shipped value crosses the reach the engine can read | A runtime cap |

## Found on the way, not changed

None of these is caused by this work and none was in scope; each is a separate decision.

- **Parity baselines have drifted on `main`.** 160 of the 488 parity cells of the thirteen slugs checked fail on pristine
  `main` exactly as they fail on the patched tree (the committed baselines date from a week earlier); the dominant change is
  in cells that contain a button. A baseline refresh is a design decision, so none was promoted.
- **The glass panel's corner radius in the captures is smaller on the Web than on Flutter** (about 11 against 23 logical
  pixels, before and after). Not investigated; the capture page may not carry the style's radius ladder.
- **The Web capture page has no `box-sizing` reset**, because `coui_web` ships without Tailwind's preflight, so Web menu rows
  measure 52 px in it against 36 on Flutter. A page with preflight gets 36.
- **Flutter's `ContextMenu` host does not close an open menu when `items` empties or `enabled` turns off**; the Web host
  does.
- **On the Web, a page whose style sits on `<html data-coui-style>` with no `data-theme` draws the light material under an
  OS dark preference**, because the dark rule's OS-setting form finds the style on a descendant and `<html>` is not one.
  The surface-styles guide documents it; the per-mode saturation and light angle follow the same limit.
- **On the Web a glass overlay panel loses its backdrop blur while it fades.** The open and close keyframes (opacity and
  scale) sit on the motion box that wraps the panel, and an ancestor's opacity below 1 isolates the `backdrop-filter`
  inside it, while an opacity on the filtered element itself keeps the backdrop. Chrome 156, a striped page: the page's
  contrast left in the panel is 0.875 under an ancestor's `opacity: .5` (the value of a plate with no filter) and 0.498
  on the element itself. Measured on a replica of the keyframe, not on the site's panel. Moving the opacity onto the
  panel's own box keeps the blur through a cross-fade, which is not the dissolve the Flutter engine does — a look
  decision.
- **Three Flutter panels still fade by an opacity over a glass surface**: the dialog box (a `FadeTransition` over the glass
  `SurfaceBlur`), the toast (an `Opacity` over the glass `SurfaceBlur`) and the window's open and close (an `Opacity` over
  the window panel's `OutlinedContainer`; whether its pass is drawn there was not measured). The popover engine hands its
  fade to the material; these do not.
- **The four `input-otp` preset snapshot tests (`preset_render_snapshot_test`) fail on `main` since the InputOtp border
  moved to the TextField's step**: the border's red channel renders 207 where the baseline says 111, in every preset that
  draws one. The baselines were not taken again with that change; this work neither causes nor touches it.
- **Two changes that each added a `transform` extension on `CoreCubicBezier` merged without a textual conflict and no
  longer compiled together** — the call is ambiguous when both extensions are in scope. A queue of changes that were each
  verified alone needs the next one tested on the merged tree after every merge; a clean merge says nothing about whether
  the result builds.
- **`check_web_resolver.sh` prints `Use of uninitialized value in substr at -e line 20.` once per `Resolved*` class** (one
  more line for each new class): its rule C extracts a match offset that is undefined for classes it does not parse. The
  verdict is unaffected.
- **`dart analyze` over a list of files can leave out the `coui_lints` plugin's diagnostics on its first run**; they
  appear on a second run over the same files. A count-aware comparison runs twice.
- **A `LongPressGestureRecognizer` that loses the arena to a scroll reports nothing** — no `onLongPressCancel`, only
  `state == defunct` — so code that ends a hold on `onLongPressCancel` alone misses scroll arbitration.
- **On the Galaxy Tab S10 FE+ (Android, Vulkan) the first two runs of a session drew the Dock bar about 22 levels brighter
  with a rectangular tint behind the pill's rounded ends** (interior (38, 40, 43) against (15, 17, 20), the rectangle (37,
  37, 39) on a (14, 14, 16) field); the next three runs, with and without the code change under test, matched macOS. Not
  code-dependent and not isolated.
- **The enclosing-pass device probe could not tell an enclosed pass's start from the root's at device pixel ratio 1** (M4
  Max, the three rows that wrap the glass in `Opacity(.99)`): its coordinate readback ran against a backdrop on which the
  two readings agree. The readbacks now run against a black backdrop and the probe passes 28 of 28 at ratios 1, 1.75 and
  2; the optics were never wrong.
- **A device probe that names "a layer that moves the pass" must assert that premise.** The first body-shade probe passed
  for a scene that did not move the pass (a `Padding` with an identity `ColorFiltered` and no clip leaves the pass at the
  root), so its mutant survived; the probe now uses a content-sized wrapper and a save-layer clip and asks the surface
  (`debugReadsRootPass`) before judging a pixel.
- **Flutter and the Web snap a short, non-dismissing drawer drag back differently with the rubber band off**: Flutter puts
  the panel back at once, the Web eases it over the 350 ms slide transition. With the band on both return over the same
  300 ms curve.
- **`applySurfaceStyle` does not settle `nestedSurfaces` under reduce transparency while `resolveSurfaceTheme` does**: the
  two seats of the material disagree about nested surfaces. Left as it was so the default output stays identical.

## Not applied, and why

- **The frost's tonal clamp and luminance weight; `rimShade` / `rimLight`.** The clamp and weight are a weighted mean:
  they need a division, and SVG filter primitives have none except a table lookup over 8-bit intermediates (not built, not
  measured). The rim terms are confined to a contour and, for the light, keyed on the luminance behind them. The Web does
  have a handle for that luminance — a point operation in the surface's own list (the body shade, one level) and a
  ring-shaped sibling layer whose `backdrop-filter` turns it upside down (pixel-exact, measured; a ring inside the glass
  sees nothing) — but a surface is one element, so the ring has to come from every surface component, from the host
  runtime (hydrated-only) or from a per-element baked mask in the filter (like the bend's displacement map). The
  reference's outline is also the raw backdrop darkened by a step, which the Flutter program, fed the material's output,
  would not read as it stands. Build when the placement is decided.
- **Backdrop grouping** — measured with `tool/frame_timing` (plain `BackdropFilter` against `BackdropFilter.grouped` in
  one `BackdropGroup`, Apple M3 Max, Flutter profile): 20 blurs 5.2 → 0.46 ms and 50 blurs 13.4 → 0.52 ms raster p50 — a
  material gain for plain blurs. Not applied: CoUI's surfaces are not bare blurs (colour matrix, shader filter, edge),
  they overlap, a shared snapshot cannot be imposed from a seat, and nothing measured a grouped CoUI surface against the
  enclosing-pass rule on a device.
- **Default dialog `stretch`, content zoom in morphs, menu frost density** — look and feel.
- **Drawer corner rounding while dragging and a Done / Cancel bar** — the corners are scaled with the panel (≤ 10 %); the
  bar is a composition of existing slots and `Button`s, shown in the docs example.
