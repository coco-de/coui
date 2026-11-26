# foldable 1.0.5 — what applies to CoUI

Reference: [foldable](https://pub.dev/packages/foldable) `1.0.5`, inspected 2026-11-17: the package source (Dart and the
iOS plugin), its README and changelog.

CoUI does not depend on the package and copies no code from it. The result of each part is one of **applied**,
**already handled**, **not applicable** or **decision**.

> **Later (2026-11-23).** coui_flutter now measures a folding iPhone itself: its own iOS plugin reads the hinge and the
> division with the public iOS 27.1 SDK APIs, and `FoldScopeHost` — mounted by `CoUILayer` — writes them into
> `MediaQuery.displayFeatures`. The reading below that the native half cannot land in CoUI, and the rows that leave the
> iPhone to a bridge an app adds, are this document's date's. CoUI still does not depend on the package and takes no
> code from it.

## Reading the result

`foldable` is an iOS plugin. Through the Objective-C runtime it reads the hinge of a folding iPhone (the hinge angle,
a posture of closed / partly open / fully open, the regions the system reserves on the inner display and the iOS size
classes) from SDK APIs of iOS 27.1, and hands them to Dart through `FoldableProvider`, `DuoMediaQuery` (an
`InheritedModel`) and `FoldAwareBuilder`. An opt-in bridge (`DisplayFeatureBridgeMode`) also writes the hinge into
Flutter's own `MediaQuery.displayFeatures` while it is partly open — as a `fold` with the width of the region it
reserves. The package offers no two-pane layout.

The native half cannot land in CoUI: the packages have no native code, and the same component draws on the Web. What
does apply is the question the package answers for iOS only — *where does the screen fold, what kind of device is it,
how is it held* — and that is answerable on both of CoUI's platforms without a plugin. Android reports folds and
hinges to Flutter through `MediaQuery.displayFeatures` already; Chromium reports them to a page through the Viewport
Segments API and the posture media query. So CoUI now measures folds itself, on Android, on iOS through the bridge an
app may add, and on the Web, and tells a flip from a fold.

## Disposition

| `foldable` | CoUI |
| --- | --- |
| The hinge's posture (partly open / fully open) and where it is | **Applied** — `FoldScope.of(context)` on both platforms returns a `CoreFoldLayout`: the folds that cross the viewport, the segments they split it into, `posture` (`flat`, `tabletop`, `book`). Flutter reads `MediaQuery.displayFeatures` (fold and hinge; Android reports them flat or half open, the iOS bridge while partly open); the Web reads `window.viewport.segments` and `(device-posture: …)` |
| What kind of foldable it is | **Applied, beyond the reference** — `kind` is `CoreFoldableKind.flip` (a compact that folds across its length: Galaxy Z Flip, Razr) or `.fold` (a book: Galaxy Z Fold, Pixel Fold, two screens and a hinge), read from the shape the fold leaves on either side, so it holds however the device is turned and needs no device list. The reference has one device and does not ask |
| The hinge angle, the iOS reserved regions, the size classes | Not applicable — native data with no counterpart on Android or the Web; CoUI lays out by width (`CoreBreakpoint`) |
| `DisplayFeatureBridgeMode` writes the hinge into `MediaQuery.displayFeatures` | Already handled — an app that turns the bridge on gets the iPhone's hinge through `FoldScope.of` with nothing else to do; the bridge writes a `fold` with a width, which the rule reads as splitting |
| A dialog opens on one half of the screen, not across the fold | **Applied on the Web**, already so on Flutter. Flutter's `DialogRoute` extends the SDK's `RawDialogRoute`, which keeps its page to one sub-screen (`DisplayFeatureSubScreen`). The Web dialog now opens in the segment the same rule names — the one at the top of the reading start — through `env(viewport-segment-*)`. A test reads Flutter's dialog against the same table |
| A drawer, a popover or a menu stays off the fold | Decision — see "Open decisions" |
| `FoldableProvider`, `DuoMediaQuery`, `FoldAwareBuilder` (app-level state) | Not applicable as such — the counterpart is the one call, `FoldScope.of` |
| No two-pane layout, by design | Not applicable — CoUI has none either |

## What changed

**One rule in Core** (`packages/coui_core/lib/src/viewport/core_fold.dart`). `CoreFoldLayout` takes the viewport's
size and the folds a platform reports and answers:

- which folds cross the viewport (a cutout, or a fold the window only partly covers, is not one);
- which of them separate it — a strip that hides part of the screen (a hinge), or anything half opened; a seamless
  screen lying flat reads as one surface. This is the rule Flutter's dialog route applies;
- the segments, left to right and top to bottom, and the one a panel with no anchor opens in: the segment at the top
  of the reading start. Also Flutter's rule. One place differs — with two folds that run the same way, Flutter's split
  stretches its first part to the second fold, and Core divides each part only by a fold inside it;
- `kind`: the fold runs along one side of each segment beside it; a side longer than the segment is deep is a page of
  a book (`fold`), a side no longer than it is deep is half of a compact (`flip`);
- `posture`: half open across the screen is `tabletop`, down the screen `book`, open `flat`; null when the platform
  did not say.

**Flutter** (`FoldScope.of`, `packages/coui_flutter/lib/src/theme/fold_scope.dart`) reads `MediaQuery.displayFeatures`,
so a widget that asks is rebuilt when the device folds or turns, and a subtree whose media query was narrowed reads
that.

**Web** (`FoldScope.of`, `packages/coui_web/lib/src/base/`): `CoUIWeb` mounts a host (`FoldScopeHost`) that starts a
feed (`fold_feed_web.dart`): it reads the segments and the posture query and listens for a resize and for the
segment-count and posture queries to change. The host is a component of its own so that a resize — the browser fires
one for every frame a window is dragged — rebuilds the scope and what reads it, not the app root. The page reports
parts, not folds, so the fold is read as the gap between two neighbouring segments (`fold_reading.dart`). The host
publishes the layout with the root's reading direction. The Web `Dialog` opens in the start
segment, centred on it and sized by it with the route's padding on every side, all from `env(viewport-segment-*)` —
the browser's own geometry — so it follows the fold exactly; only which segment is decided by the rule.

**Found and fixed on the way: the Web dialog panel's sizes.** The kit turns Tailwind's preflight off, so a box is sized
by its content unless it says otherwise. The Web panel's width (`100%` less the route's padding), its 640 cap and its
height cap were content sizes, and its padding (48 across) came on top: the panel ran 688 wide on a wide page where
Flutter's is 640, and 416 on a 400-wide page — past the page. On a folded screen it crossed the fold by 8 px. The panel
is now sized by its whole box (`box-border`), as Toggle, AppBar, Scaffold, Stepper and BottomActionBar already are. Its
parity baselines capture the trigger, not the panel, so they do not change.

## Verification

- Core: `test/viewport/core_fold_test.dart`, 40 tests — every case of the table (`test/fixtures/fold_vectors.json`,
  14 cases: no fold, a flip half open / flat / on its side, a fold half open / flat / on its side, a fold whose inner
  screen is wider than tall, two screens and a hinge both ways, unreported postures, something that does not cross,
  three panels), each also turned a quarter to show its kind holds; the separation rule; the distance a tie breaks on;
  an unmeasured viewport; equality.
- Flutter: `test/theme/fold_scope_test.dart` — every case put on the test view as Android reports it
  (`tester.view.displayFeatures`; a line is a fold, a strip is a hinge) and read through `FoldScope.of`; a cutout is
  not a fold; a widget that asks is rebuilt when the device folds; and a `Dialog` opened in every one-fold case in both
  reading directions lies inside the segment the table names (26 dialogs).
- Web VM: `test/base/fold_scope_test.dart` — every case fed in as the browser reports it (its segments); a split case
  gives the table's kind, posture and start segments, an unsplit one no fold (the reach above); the posture queries;
  `FoldScope.of` with and without a scope above; `CoUIWeb` mounting the scope with the direction it writes on
  `<html dir>`, both ways; the dialog's `env()` for the start segment in every case and direction, and nothing where
  nothing splits.
- Web, real Chrome 158 (`tool/parity/test/web/fold_probe_test.dart`, 8 tests): the panel's width at 840 and 400 without
  a fold (640, 368); no fold; a fold half open as a book (kind, posture, segments; the dialog on the left), the same
  read right to left (the dialog on the right); a flip in its stand (the dialog on the upper half); a seamless fold
  lying flat (one surface, the dialog across it); a hinge (split while flat); an open dialog moving when the device
  folds. Chrome is told the fold through DevTools: the display feature of its device metrics and its device posture.
  The newer display-features override returned success and changed nothing on that version, and desktop Chrome has no
  `navigator.devicePosture`; the posture media query answers the emulated posture.
- Mutations, each restored and checked with `cmp` (counts are failing tests):

  | Mutation | Core | Flutter | Web VM | Chrome |
  | --- | --- | --- | --- | --- |
  | the kind rule inverted | 12 | 12 | 11 | — |
  | a part divided by a fold outside it (Flutter's two-fold split) | 1 | — | 1 | — |
  | a half-open line does not separate | 7 | 6 | 18 | — |
  | the start segment ignores the reading direction | 6 | — | 12 | — |
  | every fold counts as crossing the viewport | 1 | 1 | — | — |
  | a hinge is not read (Flutter transport) | — | 4 | — | — |
  | an unreported posture reads as flat (Flutter transport) | — | 2 | — | — |
  | stacked segments are not read (Web transport) | — | — | 10 | — |
  | the Web dialog ignores the root's direction | — | — | 6 | 1 |
  | the segment's column and row are not read (`env()`) | — | — | 6 | — |
  | the feed hears no segment or posture change | — | — | — | 1 |
  | the panel sized by its content alone | — | — | — | 5 |
  | the root always hands left to right to the scope | — | — | 1 | — |

  "—" is a suite the mutation was not run against.
- Full suites on this branch: Core 7,892; Flutter 12,173 (5 skipped); Web 9,053 passing and 25 failing — every one in
  `checkbox_mark_stroke_test.dart`, which fails the same way on main and passes on the commit before the change that
  moved the checkbox's sizes off the size classes its dash finder reads; the docs gates 1,548. The dialog's
  actions-stretch probe in Chrome reports the action row's `justify-content` as `flow-end` where it expects
  `flex-end`, on the branch base as here; its boxes — the footer's width and every action's place — all match.

### Not verified

- No folding device: Android, an iPhone with the bridge, or Chrome on a foldable. The Web probe runs on emulation.
- Whether Chrome on a real foldable reports segments only while half open, as the rule assumes, was read in the
  Viewport Segments explainer, not measured.
- Safari and Firefox, which report no segments.

## Open decisions

1. **Panels off the fold.** The drawer, the popover engine (popover, menus, tooltips, hover cards) and the toast layer
   can open across a fold. The segment rule is now in Core for both platforms to read; a panel that keeps to the
   anchor's segment is the next consumer of it.
2. **A fold-aware split view.** A component that puts two panes on the two segments. The reference has none; a
   designer's and a product's call.
3. **The two-fold split.** Flutter's dialog route and the Core rule part on a device with two folds running the same
   way (above). The Core rule is the correct one; making Flutter's dialog follow it would mean the kit placing the
   route's page itself.

## Next pass

Start after `1.0.5`.
