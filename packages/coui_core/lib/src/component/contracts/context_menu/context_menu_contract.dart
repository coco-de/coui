/// Platform-independent contract for the unified `ContextMenu`.
library;

import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/context_menu/context_menu_style.dart';
import 'package:coui_core/src/component/contracts/menu/menu_contract.dart';
import 'package:coui_core/src/component/contracts/popover/popover_controller_contract.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/spacing/spacing.dart';

/// Contract for the unified `ContextMenu` component.
///
/// `ContextMenu` wraps a [child] region; right-clicking, long-pressing on
/// touch, or pressing the context-menu key (or `Shift+F10`) on a focused
/// element inside that region reveals its [items] as a floating panel
/// anchored at the pointer — or, from the keyboard, at the centre of the
/// focused element. Selecting an enabled action item invokes its
/// `onPressed` callback and closes the panel.
///
/// Four behaviours are opt-in and change nothing until asked for:
/// [glideToSelect] lets the finger that opened the menu keep moving and pick
/// a row on release, [preview] shows a widget beside the open menu,
/// [haptics] ticks as a glide's highlight moves, and [liftChild] lifts the
/// [child] off the page while the menu is open and folds the menu back into it
/// when it closes.
///
/// Generic over the platform widget type `W` (Flutter `Widget`, Web
/// `Component`). Shares the unified [CoreMenuItem] model with `Menu` /
/// `DropdownMenu` / `Menubar` — context menus and dropdown menus have
/// identical action / divider entry semantics.
abstract interface class CoreContextMenuContract<W> {
  /// How long a touch (or pen) has to rest on the [child] before the menu
  /// opens — [CoreDuration.slow] (500 ms), the hold Flutter's own long-press
  /// timeout states, so the Flutter trigger keeps the timing it always had
  /// and the Web trigger, which times the press itself, matches it.
  ///
  /// It is a hold threshold, not a transition. It does not go through the
  /// reduced-motion policy (`CoreReducedMotion` / `resolveMotionDuration`):
  /// that policy collapses every transition-tier duration to zero, and a
  /// zero hold would turn every touch into a long press.
  static const Duration defaultLongPressDuration = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// How far a touch (or pen) may drift from where it went down before the
  /// press stops counting as a long press — 18, in logical pixels on Flutter
  /// and CSS pixels on the Web (the unit `clientX` / `clientY` are in).
  /// 18 is Flutter's `kTouchSlop`.
  ///
  /// Flutter's recognizers default to the slop the platform reports (Android
  /// reports a tighter one than 18) and fall back to 18 where it reports none;
  /// a browser reports nothing. The context menu pins this one number on both
  /// seats so the same finger movement cancels the press on both. Whether a
  /// position is past it is [exceedsLongPressSlop].
  static const double defaultLongPressSlop = 18;

  /// Whether a pointer that went down at ([originX], [originY]) and is now at
  /// ([x], [y]) has drifted past [defaultLongPressSlop], so the press no
  /// longer counts. Every coordinate is in logical pixels (Flutter) or CSS
  /// pixels (Web).
  ///
  /// The slop is a distance, not a box: a pointer exactly
  /// [defaultLongPressSlop] away still counts as pressing in place, and one
  /// any farther does not. The arithmetic is the one Flutter's
  /// `PrimaryPointerGestureRecognizer` runs (`Offset.distance`, compared
  /// strictly), so a press the Flutter recognizer keeps is a press the Web
  /// keeps. The Web asks this on every move; Flutter's recognizer asks the
  /// same question itself, and one vector table
  /// (`test/fixtures/context_menu_long_press_vectors.json`) pins the two
  /// answers together.
  static bool exceedsLongPressSlop({
    required double originX,
    required double originY,
    required double x,
    required double y,
  }) => _exceeds(
    defaultLongPressSlop,
    originX: originX,
    originY: originY,
    x: x,
    y: y,
  );

  /// How far the finger that opened the menu has to move from the point the
  /// menu opened at before a glide has begun — the same disc, with the same
  /// radius, the finger had to stay inside for the hold to count.
  ///
  /// A menu opens flush at the touch, so the finger rests on its first row's
  /// corner. Lifting without having moved is a person letting go of a menu
  /// they meant to read, not choosing the row under their finger: until the
  /// finger leaves the disc, a release leaves the menu open for a tap. Once it
  /// has left, it has begun to glide, stays gliding if it comes back, and
  /// the release chooses.
  ///
  /// A designer-judgement value: it equals [defaultLongPressSlop] so the two
  /// phases of one touch share one disc. A larger number makes a glide less
  /// likely to begin by accident and the first rows harder to reach by glide;
  /// a smaller one would let a finger that drifted during the hold choose a
  /// row on lifting. Whether a position is past it is [exceedsGlideSlop].
  static const double defaultGlideSlop = defaultLongPressSlop;

  /// Whether a finger that opened the menu at ([originX], [originY]) and is
  /// now at ([x], [y]) has begun to glide — farther than [defaultGlideSlop],
  /// a distance compared strictly like [exceedsLongPressSlop]. One vector
  /// table (`test/fixtures/context_menu_glide_vectors.json`) pins the two
  /// seats' glides to it.
  static bool exceedsGlideSlop({
    required double originX,
    required double originY,
    required double x,
    required double y,
  }) => _exceeds(
    defaultGlideSlop,
    originX: originX,
    originY: originY,
    x: x,
    y: y,
  );

  /// The distance between the preview and the menu it sits beside — 8, the
  /// grid step the menu keeps from the viewport edge, so the two panels read
  /// as a pair and not as one.
  ///
  /// A designer-judgement value: 12 or 16 would separate the pair further
  /// (iOS uses 16), 4 would join it. The placement rule that reads it is
  /// `CoreContextMenuPreview.place`.
  static const double defaultPreviewGap = CoreSpace.space8;

  /// How long after a touch begins to rest on the [child] the [child] starts
  /// to lift — [CoreDuration.fast] (150 ms).
  ///
  /// A touch that lets go before this has lifted nothing: a tap, or a scroll
  /// that began on the child, never shows the lift. The delay plus the rise
  /// ([CoreContextMenuStyle.liftDuration]) has to end before
  /// [defaultLongPressDuration] does, so the child is fully lifted when the
  /// menu appears and the appearance reads as the lift's completion. A style
  /// may state a longer rise, so this is not a fact about the default numbers:
  /// `CoreContextMenuLift.riseDuration` holds a held touch's rise to what is
  /// left of the hold after this delay, on both seats. An opening that has no
  /// hold (a right click, a key, a controller) has nothing to wait for and
  /// lifts at once (`CoreContextMenuLift.delayFor`).
  ///
  /// A designer-judgement value: iOS lifts after about 200 ms; a shorter delay
  /// shows the lift on touches that were going to be taps, a longer one leaves
  /// less of the hold to show it in. Like the hold itself it is a press
  /// threshold, not a transition, so reduced motion does not shorten it. It
  /// stays here, and not on the style, because it is the other half of a pair
  /// with the hold: the two seats must wait the same time whatever an app's
  /// style says.
  static const Duration defaultLiftDelay = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Whether an opening with no hold — a right click, a context-menu key, a
  /// controller — lifts the [child] too (concurrently with the menu opening,
  /// never delaying it).
  ///
  /// A designer-judgement value: a touch hold needs the lift to say "this is
  /// registering", a click does not. Left on, the menu looks the same however
  /// it was opened; off, only a held touch lifts. The one place it is read is
  /// `CoreContextMenuLift.lifts`.
  static const bool defaultLiftsWithoutHold = true;

  /// The size the lifted [child] reaches. Alias of
  /// [CoreContextMenuStyle.defaultLiftScale].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultLiftScale (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the number is unchanged.',
  )
  static const double defaultLiftScale = CoreContextMenuStyle.defaultLiftScale;

  /// How long the lift takes to reach its full size. Alias of
  /// [CoreContextMenuStyle.defaultLiftDuration].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultLiftDuration (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the number is unchanged.',
  )
  static const Duration defaultLiftDuration =
      CoreContextMenuStyle.defaultLiftDuration;

  /// How dark the page behind the lifted [child] gets. Alias of
  /// [CoreContextMenuStyle.defaultLiftDimOpacity].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultLiftDimOpacity (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the number is unchanged.',
  )
  static const double defaultLiftDimOpacity =
      CoreContextMenuStyle.defaultLiftDimOpacity;

  /// The shadow the lifted [child] casts. Alias of
  /// [CoreContextMenuStyle.defaultLiftCast].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultLiftCast (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the number is unchanged.',
  )
  static const List<CoreShadowLayer> defaultLiftCast =
      CoreContextMenuStyle.defaultLiftCast;

  /// The corner radius of the box the lifted [child]'s shadow is cast from, as
  /// a plain number: the same corner as
  /// [CoreContextMenuStyle.defaultLiftRadius].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultLiftRadius (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the Style states the '
    'corner as a CoreBorderRadius, this stays the plain number (16).',
  )
  static const double defaultLiftRadius = CoreRadiusRole.surface;

  /// The size the menu panel and the preview shrink to as they fold back into
  /// the [child]. Alias of [CoreContextMenuStyle.defaultRetractScale].
  @Deprecated(
    'Read CoreContextMenuStyle.defaultRetractScale (since 0.173) — the lift '
    'numbers are visual values, so they live on the Style where an app '
    'restyles them per instance or through the theme; the number is unchanged.',
  )
  static const double defaultRetractScale =
      CoreContextMenuStyle.defaultRetractScale;

  static bool _exceeds(
    double slop, {
    required double originX,
    required double originY,
    required double x,
    required double y,
  }) {
    final dx = x - originX;
    final dy = y - originY;

    return math.sqrt(dx * dx + dy * dy) > slop;
  }

  /// The region that triggers the context menu when right-clicked.
  W get child;

  /// The action / divider rows revealed in the context-menu panel — the
  /// unified [CoreMenuItem] model.
  List<CoreMenuItem<W>> get items;

  /// A widget shown beside the menu while it is open — the thing the menu is
  /// about (a photo, a message, a record), seen larger than the row that
  /// opened it. `null` shows nothing.
  ///
  /// The menu stays where it always was; the preview is placed around it by
  /// `CoreContextMenuPreview.place` — above the menu when the room above
  /// holds it, otherwise below, otherwise beside — and never overlaps the menu
  /// or leaves the viewport. It is drawn in the floating-panel chrome (a
  /// `Popup`), is not interactive, and a tap on it is a tap outside the menu.
  W? get preview;

  /// Whether the finger that opened the menu with a long press may keep
  /// moving and choose a row by lifting over it.
  ///
  /// While the finger glides, the row under it is highlighted. Lifting over
  /// an enabled row activates it exactly as a tap on it would; lifting
  /// outside every row, or over a disabled one, closes the menu. A finger that
  /// lifts without having left the [defaultGlideSlop] disc leaves the menu
  /// open for a tap. A mouse right-click opens a menu with no finger to glide,
  /// and is unchanged.
  ///
  /// Off by default: a context menu that opens flush at the finger would
  /// otherwise start choosing rows for people who only wanted to look.
  bool get glideToSelect;

  /// Whether a glide ticks (`CoreHapticCue.selectionTick`) when its highlight
  /// enters a row and when a release activates one, and a held touch ticks as
  /// the lift commits and the menu appears ([liftChild]).
  ///
  /// Off by default. It does nothing without [glideToSelect] or [liftChild]: a
  /// tap has the system's own feedback, and the tick belongs to the finger
  /// moving or to the hold that just paid off.
  bool get haptics;

  /// Whether the [child] lifts off the page while the menu is open, and the
  /// menu folds back into it when it closes.
  ///
  /// A touch that rests on the child lifts it after [defaultLiftDelay]: it
  /// grows to [CoreContextMenuStyle.liftScale] and casts
  /// [CoreContextMenuStyle.liftCast] over a page dimmed by
  /// [CoreContextMenuStyle.liftDimOpacity], reaching its full lift before the
  /// hold ends and the menu appears; letting go or drifting past
  /// [defaultLongPressSlop] first sets it back down. An opening with no hold
  /// lifts it at the same time as the menu appears, not before
  /// ([defaultLiftsWithoutHold]). Whichever way it opened, every way of closing
  /// it — Escape, a tap outside, choosing a row, the controller — plays the
  /// lift backwards: the panel and the preview shrink toward the [child] (to
  /// [CoreContextMenuStyle.retractScale]) and fade, the child settles back,
  /// and only then do the copy and the dim go and the original show again, in
  /// one frame. The numbers of the look are the style's, so an app restyles
  /// them through [contextMenuStyle] or a theme; the timing of the gesture is
  /// this contract's.
  ///
  /// The lifted child is a second rendering of [child] above the dim, at the
  /// original's place and size: **built twice while the menu is open**, with no
  /// state of its own (a stateful descendant starts from its initial state),
  /// not interactive, not announced, and not focusable. The original keeps its
  /// place in the layout and is the only one a screen reader reads. The
  /// judgements of the lift — when it begins, how far it has come, what each
  /// frame draws, where the panel folds to — are `CoreContextMenuLift` and
  /// `CoreContextMenuRetract`, read by both seats.
  ///
  /// Off by default: the page is not dimmed, nothing is built twice and the
  /// menu closes with the panel's own exit. Reduced motion makes the lift and
  /// the fold instant (the lifted state is still shown, since it is feedback
  /// for the hold, not decoration); where the platform draws no see-through
  /// scrim (forced colours on the Web) the dim is left out and the lift is the
  /// scale alone.
  bool get liftChild;

  /// Whether the context menu is enabled.
  ///
  /// When false the right-click, long-press and keyboard triggers are inert.
  bool get enabled;

  /// Per-instance style.
  ///
  /// The context menu composes the unified `Menu`, so its chrome flows
  /// through the single [CoreContextMenuStyle] slot:
  /// [CoreContextMenuStyle.menuStyle] (a `CoreMenuStyle`) raw-forwarded to
  /// the inner `Menu`. The same slot carries the look of the [liftChild] lift
  /// (scale, duration, dim, cast, radius, and how small the panel folds), so
  /// an app restyles it per instance or through the theme. Resolves through
  /// the nested-merge chain (`CoreMenuTheme.style` ←
  /// `CoreContextMenuTheme.style` ← `widget.contextMenuStyle`).
  CoreContextMenuStyle? get contextMenuStyle;

  /// Optional controller for imperative open / close.
  ///
  /// Shares the unified [CorePopoverControllerContract] surface with
  /// `Popover` / `DropdownMenu` — the context menu is a single panel, so
  /// it reuses the same binary controller. `show()` opens the panel
  /// anchored at the [child]'s center (no pointer event); pointer
  /// right-click / long-press still opens at the pointer, and the keyboard
  /// at the focused element.
  CorePopoverControllerContract? get controller;
}
