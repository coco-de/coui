# adaptive_platform_ui 1.0.2 — what applies to CoUI

Reference: [adaptive_platform_ui](https://pub.dev/packages/adaptive_platform_ui) `1.0.2`, inspected 2026-11-17: the
package source (its widget list, the `toolbar/` host and the iPhone Duo bar, the iOS and Android plugin folders), its
pubspec and README.

CoUI does not depend on the package and copies no code from it. The result of each part is one of **applied**,
**already handled**, **not applicable** or **decision**.

## Reading the result

The package's premise is the opposite of CoUI's. Its description says it: "Auto renders native iOS 26+ liquid glass
designs, traditional Cupertino widgets for older iOS versions, Material Design for Android." Each of its widgets
(`AdaptiveButton`, `AdaptiveSwitch`, `AdaptiveScaffold`, `AdaptiveBottomNavigationBar`, … — 28 `adaptive_*` files
under `widgets/`) picks a different look per operating system, and the iOS 26 look is drawn by native views
(`UiKitView`) through a plugin. CoUI draws one look, the same on Flutter and the Web, from one Core contract, and its
glass is its own material on both platforms. So no widget is ported.

What does carry over is one decision the package makes in plain Dart: **when the controls belong in a vertical strip at
the side of the screen** (the folding iPhone's inner display). CoUI already draws what goes there — the glass rail and
the vertical `ToolbarGroup` — and its docs show an app how to read the strip. Their test was looser than the
reference's measured one, and that is corrected.

## Disposition

| `adaptive_platform_ui` | CoUI |
| --- | --- |
| A different widget per operating system (Cupertino, Material, iOS 26 native) | Not applicable — CoUI draws one look on every platform (`principles/vision.md`) |
| iOS 26 liquid glass by native views (`UiKitView`, method channels — 13 files) | Not applicable — no native code in the kit; CoUI's glass is its own material on Flutter and the Web |
| `AdaptiveApp`, `AdaptiveScaffold`, the fixed top toolbar (host, registry, blend) | Not applicable — they host native bars over Flutter content and cross-fade them with the route; CoUI's app bar is a component of each page |
| **When the controls go to a side strip** (`DuoLayout.barSide`): the view's safe-area insets have no top inset and an inset on one side only. Any other iPhone has a top inset in portrait and equal insets on both sides in landscape. Only the leading Split View pane, which reports no inset, falls back to a native trait | **Applied (docs)** — CoUI's recipes read `viewPaddingOf(context).right > 0`, which also fires on an ordinary iPhone turned to landscape. They now read the reference's rule (see "What changed") |
| What goes in the strip: the back button and the page actions in capsules, the tabs in a capsule at the bottom | Already handled in what CoUI draws — the glass rail (`NavigationBar(mode: .rail)`) and the vertical `ToolbarGroup`, each a 48-wide capsule. The layout of the strip is the app's, as the AppBar and NavigationBar docs show |
| The strip's camera clearance and the Split View edge (`foldable`'s regions, the iOS 27.1 `verticalBarEdge` trait over a channel) | Not applicable — native data |
| Actions that do not fit the strip fold into one overflow control, from the bottom up | Decision — the vertical `ToolbarGroup` has no overflow; see "Open decisions" |
| The tab bar minimizes while the page scrolls (`TabBarMinimizeBehavior`, iOS 26) | Decision — CoUI's bar has no scroll-linked state |
| The search tab bar | Not applicable — CoUI has no bar that turns into a search field (see the [liquid_glass_widgets 1.17.5 ledger](2026-11-17-liquid-glass-widgets-1-17-5-delta.md), #488/#489) |
| `AdaptiveBlurView` | Already handled — the surface material (`SurfaceBlur`) on both platforms |
| Widgets CoUI also has (switch, slider, segmented control, date and time pickers, context menu, tooltip, badge, card, list tile, text field, alert dialog, snackbar) | Not compared parameter by parameter in this pass — each is a platform look over a Flutter or native control; CoUI has its own component for each |
| SF Symbols | Not applicable — CoUI's icons are one set (Lucide) |

## What changed

The two docs recipes that read the side strip — the NavigationBar's "리퀴드 글래스의 바와 레일" and the AppBar's "옆
컨트롤 자리에 아이콘 동작 세우기" — read the strip as `viewPaddingOf(context).right`, and showed the rail whenever it
was above `0`. An ordinary iPhone in landscape has equal insets on both sides, so a copied recipe put the rail on every
landscape iPhone. Both recipes now take the width only where the view has no top inset and no left inset:

```dart
final inset = MediaQuery.viewPaddingOf(context);
final strip = inset.top == 0 && inset.left == 0 ? inset.right : 0.0;
```

and the NavigationBar prose says why. The rule is the reference's (`DuoLayout.barSide`), which its comment says was
measured on the device; CoUI has not measured it.

## Open decisions

1. **The side-strip decision as a kit function.** One rule in `coui_core` (insets in, a side and a width out, with a
   table of inputs read by Core, Flutter and Web tests), read on Flutter from `MediaQuery.viewPaddingOf` and on the Web
   from `env(safe-area-inset-*)` through a measured element. Not started: whether a browser on the device reports the
   strip as an inset is not known, and an axis waits for both handles (`core/theme-axis-composition.md`).
2. **Overflow in the vertical `ToolbarGroup`** — actions that do not fit fold into one control, as the RichEditor's
   selection toolbar already folds its formats.
3. **A bar that minimizes while the page scrolls** — a look and a motion, the designer's; it would also need its
   reduced-motion answer.
4. **The body under a floating header or footer.** CoUI's Scaffold docs tell the caller to pad the body by hand when
   `floatingHeader` is on. Flutter's own `Scaffold`, which the reference builds on, tells the body instead: with
   `extendBodyBehindAppBar` / `extendBody` it raises the body's `MediaQuery.padding` to the bars' heights. Doing that
   changes every floating layout, so it is the owner's call.

## Verification

- Read: the pubspec (its description and its `foldable` dependency, "used to place the iOS 26 toolbar on the trailing
  edge on the Duo inner display"); `DuoLayout.resolvePose` and `barSide` in `duo_vertical_bar.dart`, and the overflow
  fold in the same file; `TabBarMinimizeBehavior` in `adaptive_scaffold.dart`; the file list of `widgets/`, `toolbar/`
  and `platform/`; the 13 files that use `UiKitView`, `AndroidView` or a `MethodChannel`.
- Read in CoUI: the two recipes (`navigation-bar.md`, `app-bar.md`), the Scaffold docs' floating header note.
- Docs registry gates: passing after the change.
- Not done: no device; the shared widgets were not compared parameter by parameter.

## Next pass

Start after `1.0.2`.
