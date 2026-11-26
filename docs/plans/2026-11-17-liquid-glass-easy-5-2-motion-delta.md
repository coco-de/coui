# liquid_glass_easy 5.2.0 — the motions that apply to CoUI

Reference: [liquid_glass_easy](https://pub.dev/packages/liquid_glass_easy) `5.2.0`, inspected 2026-11-17. Read: the
changelog from `5.0.0` to `5.2.0`, `LiquidGlassTabPillBehavior` (the pill's events, springs and landing wobble),
`LiquidGlassTabBarSwell`, and the places in `liquid_glass_animated_nav_bar.dart` that read the finger, step the swell
and anchor it. The morph (`LiquidGlassMorph`, its presets, `LiquidGlassMorphShared`), the touch flex, the blender and
the switch and slider thumbs were read for what they do, not compared with CoUI in depth — see "Next pass".

CoUI does not depend on the package and copies no code from it. It is a behavioural reference: each motion was read,
the CoUI path that answers the same question was located on both platforms, and the result is one of **applied**,
**already handled**, **partly**, **not applicable** or **decision**.

## Reading the result

The parts of 5.2.0's tab pill that decide what a press and a drag do, CoUI's glass navigation already does the same
way: a press sends the lens to the pressed destination and lifts it at once, a drag keeps the gap between the lens and
the finger, letting go selects the nearest destination, and a selection set from code travels like a tap. What CoUI
lacked was the bar's own answer to being held — in 5.2.0 the whole bar grows a little while the pill is up. That is
applied on both platforms. The rest of the window is a number that is the designer's (the springs, the landing wobble),
an API that is a decision (a haptic tap, a reselect callback), a behaviour CoUI keeps on purpose (the reference commits
the tab on the press; CoUI's host may decline it), or a candidate not compared in depth (the morph's content swap, the
touch flex, the thumbs).

## Disposition

| Upstream (5.2.0) | CoUI |
| --- | --- |
| A press lifts the pill at once and sends it to the pressed tab | Already handled — the press calls `moveTo(index, held: true)` on both platforms (Flutter `_handlePointerDown`, Web `_down`) |
| The press also commits the tab: `onChanged` fires on the press itself (`_travelTo(next, notify: true)` in `_onPointerDown`) | Not applied, deliberately — in CoUI the host owns the selection and may decline it, and a press can still turn into a scrub or a cancel; the selection is asked for on the tap or at the end of a drag |
| A finger past `10` px scrubs, keeping the gap to the finger | Partly — the gap is kept (`_grabOffset` / `_grab`); the threshold is not `10` and not the same on both platforms (see "Found on the way") |
| Letting go selects the nearest tab; a tie keeps the current one | Already handled for the nearest tab (`round()` on both platforms); an exact tie rounds away from zero instead of keeping the current tab. Read, not changed |
| One spring for every distance (`0.4` s, bounce `0.15`); the lift drops once `3.5` pt of a `62` pt bar remain, so the pill lands full size | Already handled in shape — one settling spring after release (`520` / `36`, ζ ≈ 0.79); CoUI's lift stays up until the lens has settled. The numbers differ; they are the designer's |
| A two-beat wobble at every landing — at its default strength (`1.939` × a table of about ±2 %) about +3 % then −3 % in width and −4 % then +4 % in height, over about `0.6` s | Partly — CoUI's deformation spring (`420` / `27`, ζ ≈ 0.66) dips once below rest after the lens stops. A scripted two-beat wobble is a look, the designer's |
| **The whole bar grows `3` % while the pill is up, about a point that follows the pill (`grip` `0.75`); `320` / `24` up, `320` / `17` down** | **Applied (Core, Flutter, Web)** — see "What changed" |
| A light haptic tap on changing tab | Decision — CoUI has the seam on both platforms (`CoreHapticCue.selectionTick`; Flutter `playHapticCue`, Web `navigator.vibrate`) and its rule is an opt-in flag per component, so a navigation bar flag is an API decision |
| `onReselected` (the selected tab tapped again) | Partly — on both platforms a tap on the selected destination already calls `onSelected` with its own index, so an app can tell (Flutter `_handleSelect`, Web `handler(thisIndex)`); a callback of its own is an API decision |
| A selection set from code travels like a tap | Already handled — a new selection releases the lens to it on the live spring (Flutter `didUpdateWidget`, Web `update`) |
| `opacity` on a lens, blender or morph: the glass fades and keeps refracting | Already handled — the surface fades its own terms (`CoreSurfaceDissolve`; see the [liquid_glass_widgets 1.17.5 ledger](2026-11-17-liquid-glass-widgets-1-17-5-delta.md)) |
| The tab bar's new default look (`328` × `62`, the light frost and dark smoke) | Not applicable — CoUI's look is its own preset |
| Shape cache, batch modes, lite glass in a batch | Not applicable — render paths of the package, not motions |
| The morph's content cross-fade and `LiquidGlassMorphShared` (a tagged element flies between the two sides) | Not applied — candidates. CoUI's `CoreMorphSpring` / `morphShapeAt` is a two-body silhouette morph (speeds `60` / `120` / `200` / `500`, ζ `0.73`); it has no content cross-fade and no shared flight. Read for what they do, not compared in depth |
| Touch flex (a lens stretches toward the finger), the switch and slider thumbs that lift and rubber-band, a sliding segmented indicator, a tint that adapts to the backdrop | Not applied — candidates, read for what they do, not compared in depth. The adaptive tint reads the backdrop's pixels, which the Web cannot |

## What changed

### Core: one more spring

`CoreGlassNavigationMotion` gains `swell`, beside the position, lift and deformation springs, and the motion steps it on
the same clock. Its target is `barSwell` (`0.03`) while the lens is up — held, or still travelling, the same condition
the lift uses — and `0` otherwise. It rises on `320` / `24` (ζ ≈ 0.67: it arrives a little past its size, without a
visible bounce) and falls on `320` / `17` (ζ ≈ 0.48: it dips once below rest and settles). `barScale` is `1 + swell`.

`barSwellOrigin(lens)` is `0.5 + (0.5 − lens) × barSwellGrip` (`0.75`): the lens's place mirrored about the middle, so a
lens near one end puts the point near the other and the lens's end moves out the most. Mirroring makes the answer the
same measured from either end, so each platform measures from the end it lays out from. Reduced motion snaps the swell
with the rest of the motion, a long pause snaps it to its target, and the clock keeps running until it has settled.

The values are the reference's and are stated as designer judgement in their doc comments.

### Flutter: the capsule is drawn through a transform

The bar owns the swell (`_GlassBarSwell`); the track, which owns the motion, writes it from the motion's clock; the
capsule is drawn through `Transform.scale` about that point on its middle line. The lens's centre is placed in the
capsule's own box (`localToGlobal(ancestor:)`), so the bar's padding and the capsule's border are counted as they are
laid out, and a right-to-left row needs nothing but the lens's physical place. At rest the transform is the identity
and paints without a layer, and only the floating glass bar has it.

Two paths do not come from the clock. Reduced motion snaps the motion without ticking, after the capsule has already
been built that frame, so the track puts the swell right after the frame. And a track that goes while the bar is
swollen (the row stops fitting and scrolls) hands the bar back at rest after the frame, because the tree is locked while
it is torn down.

### Both: the swell is drawn only — the finger is read on the bar as laid out

The reference draws the swell and reads the finger on an overlay that does not grow ("Cosmetic only — taps are owned by
the outer gesture overlay"). CoUI reads it the same way on both platforms: where the finger is, as if the bar were at
rest. That keeps a finger that stays where it chose a destination on that destination while the bar grows around it,
and it keeps where the lens goes independent of the point the bar grows from, which follows the lens.

Reading it through the drawn bar instead was measured first, and it is a loop: the point moves with the lens, so a
still finger maps to a target that moves, and the lens settles a px or two off the destination it was sent to. The
existing Chrome probe that holds a drag on the last destination and waits for the lens to sit on it timed out that way.
On Flutter the framework hands a drag its position through the transform as it was at the press, which is the bar at
rest only when the press started at rest; the track reads it through the capsule instead (scaled back out about the
point the capsule is drawn from), so a press that starts while the bar is still grown reads the same.

On Web the runtime reads the destinations' boxes as drawn and divides them back to laid-out lengths, and reads the
pointer against where the laid-out bar starts — `origin × (1 − scale)` before the drawn one.

### Web: the bar root's `scale`

The runtime writes the individual `scale` property and `transform-origin` on the bar's root each frame — `scale`, not
`transform`, so a transform the page gives the bar is kept — and removes both at rest. The capsule's material, the lens
and the destinations are all inside the root, so they grow together.

The runtime measures the destinations with `getBoundingClientRect`, which reads them as drawn, through the scale, and it
places the lens in the bar as laid out, so it divides what it measures by the scale it last drew (the pointer: see
below).

The pre-commit hook analyses every file a change touches with `--fatal-infos`, and this file carried 23 infos from
before. They are cleared in the same change: docs on its public members; `late` for the three fields `_attach` always
sets; and the `is` checks on `package:web` types replaced with `isA<…>()` and a cast. An `is` check on those types
always passes for any JavaScript object, so they guarded only against null; `isA` checks the real type. The events
these listeners receive are of the types checked, so their behaviour is unchanged.

## Verification

- Core: `glass_navigation_motion_test.dart`, 13 tests passing, 8 of them new — at rest before a hold; held, it grows and
  stays within 10 % past its size; released, it dips below rest and settles exactly at rest; it lasts while a released
  lens is still travelling; it keeps the clock running until settled; none under reduced motion; the same on a 60 and
  a 120 Hz clock; the point is mirrored, clamped and the same from either end.
- Flutter: `liquid_glass_navigation_swell_test.dart`, 11 tests passing — at rest; grows while held, settles at exactly
  its size and lets go; the point away from the lens in both directions; the point read back against the drawn capsule
  and lens to `1e-3` in both directions, with padding on one side only; the rail along its column; a press that starts
  while the bar is still grown reads the finger on the laid-out bar (the lens sits on the destination to `0.5` px);
  none under reduced motion; let go when reduced motion arrives mid-hold; let go when the lens goes mid-hold. Eight
  mutations, each restored afterwards, each failing the tests that pin it: the transform not scaling, the point not
  mirrored, a going track keeping the bar swollen, no swell after a snap without a tick, the right-to-left lens place
  ignored, the point measured against the track instead of the capsule, and the finger read through the press-time
  transform or through the drawn bar.
- The navigation suites (`liquid_glass_navigation_*`, `test/components/navigation`) and the parity probes: passing.
- Web, real Chrome (`dart test tool/parity/test/web/...`): the new `glass_bar_swell_probe_test.dart` (7 tests — at rest;
  the whole bar grows about the mirrored point, read against the drawn lens to 1 px; the lens sits on its destination
  while grown, to 0.5 px; a drag reads the finger on the laid-out bar, to 0.5 px; right to left; none under reduced
  motion; the rail) and the existing `glass_interaction_test.dart` (30): 37 passing. Three mutations, each restored, run
  in Chrome: the drawn boxes read as laid out (3 fail), the finger read through the drawn bar (1), the point not
  mirrored (3).
- Re-run on `main` as of the 1.17.5 dialog change, with nothing else of this work's code changed: the full
  `coui_flutter` suite without goldens, 12,134 passing, 5 skipped; `coui_core`, 7,846 passing; `coui_web` navigation
  tests, 300 passing; docs registry gates passing; design-token phases 6 and 7, `verify_contracts.sh`,
  `check_web_resolver.sh` and the structure guards for casts, DOM event targets, chrome literals, animation lifecycle,
  surface contracts, axis fields and barrel name collisions: passing. The mutations above were run on the tree before
  that rebase; the files they mutate did not change in it.
- `dart analyze --fatal-infos` and `dart format` on every touched file: nothing.

### Not verified

- No device. On Flutter the refraction under the grown capsule is placed through the transform
  (`surfaceRectInBackdropPixels` reads `getTransformTo(null)`); read, not measured on a device.
- Web was run in Chrome only.

## Open decisions

1. **The swell's numbers** — `3` %, the grip `0.75`, the two springs — are the reference's. A designer's to keep or tune;
   they live in one place (`CoreGlassNavigationMotion`).
2. **Whether an app can turn the swell off.** The reference takes `swell: null`; CoUI's swell is on for every floating
   glass bar and off only under reduced motion. A style field would need its reader and a rendered-value test in the
   same change.
3. **A haptic tap on changing tab** — an opt-in flag on the navigation bar, through the existing seam.
4. **`onReselected`** — a callback of its own for the selected destination pressed again (scroll to top, in the
   reference); today the app compares `onSelected`'s index with its selection.
5. **One scrub threshold** — see below.

## Found on the way, not changed

- **The distance a drag needs before the lens follows it differs by platform and pointer.** Flutter's track uses the
  framework's drag recognizer, whose slop is the platform's touch slop (`kTouchSlop`, `18`, unless the platform reports
  its own) for touch and `kPrecisePointerHitSlop` (`1`) for a mouse; the Web runtime uses `8` for every pointer. The
  reference uses `10`. Making it one value needs a recognizer of the track's own on Flutter.
- **A tie on release** rounds away from zero on both platforms rather than keeping the current destination; it needs
  the finger exactly between two centres.

## Not applied, and why

- **The springs and the landing wobble** — numbers and a look; decision 1's kind.
- **The haptic tap and `onReselected`** — API decisions 3 and 4.
- **Committing the tab on the press** — CoUI's selection is the host's to accept or decline after the gesture.
- **The default look** — CoUI's preset.

## Next pass

Compare the morph's content swap and shared flight, the touch flex and the thumbs with CoUI's `CoreMorphSpring` /
`morphShapeAt` and the toggle lens in depth, then start after `5.2.0`.
