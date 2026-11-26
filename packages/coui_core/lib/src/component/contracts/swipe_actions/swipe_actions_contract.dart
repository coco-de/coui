/// Cross-platform contract for `SwipeActions`.
library;

import 'package:coui_core/src/component/contracts/button/button_shape.dart';
import 'package:coui_core/src/component/contracts/swipe_actions/swipe_action.dart';
import 'package:coui_core/src/component/contracts/swipe_actions/swipe_actions_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for `SwipeActions` — a list row that reveals actions when it is
/// swiped sideways.
///
/// The row is [child]. Dragging it toward the end edge (right in a
/// left-to-right locale) reveals [leadingActions] at the start edge; dragging
/// it toward the start edge reveals [trailingActions] at the end edge. Each
/// action is a composed `Button`, so its chrome is the button's; the row only
/// decides where the button sits and how far the row has moved.
///
/// ### One engine, two seats
///
/// How far the row follows the pointer, how it resists past the actions, when
/// a pull runs the first action and where a released row comes to rest are
/// numbers and predicates, so they live in Core (`CoreSwipeGeometry`,
/// `CoreSwipeDrag`, `CoreSwipeGesture`) and both seats ask the same code.
/// The behaviour numbers below are widget-plane defaults, not `Style`
/// fields: a gesture threshold is compared against a live pull and draws
/// nothing, so it is not chrome (`core/style-contract.md`).
///
/// Units, throughout: pixels are logical pixels (CSS pixels on the Web),
/// velocities are pixels per second, thresholds written as a fraction are of
/// the stated base.
///
/// `W` is the platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSwipeActionsContract<W> {
  /// Default for [allowsFullSwipe] — on.
  ///
  /// A long pull is a deliberate act (it has to pass
  /// [defaultFullSwipeThreshold] of the row), and it is the gesture the
  /// platform list taught users: the outermost action runs. A row whose
  /// first action must never run unasked sets it `false`.
  static const bool defaultAllowsFullSwipe = true;

  /// Default for [fullSwipeThreshold], as a fraction of the row's width: a
  /// pull this far runs the first action on release.
  ///
  /// A designer-judgement feel value: far enough that opening the actions
  /// never gets near it, near enough that it is reachable with a thumb on a
  /// phone-width row.
  static const double defaultFullSwipeThreshold = 0.65;

  /// How far past the open pose a pull has to go before it runs the first
  /// action, in logical pixels, when the open pose already reaches
  /// [defaultFullSwipeThreshold] of the row.
  ///
  /// Without it a row whose actions are as wide as the threshold ran the
  /// first one on the pixel that crossed the open pose — opening the actions
  /// and running one were the same gesture, and a thumb that overshot the
  /// open pose by a hair did the second. A designer-judgement feel value; a
  /// row whose open pose is short of the threshold never reads it.
  static const double defaultFullSwipeOvershoot = 24;

  /// The share of a side's actions-width a released row has to be pulled
  /// past to settle open instead of closed, as a fraction of that width.
  ///
  /// Half: the row settles at the nearer of the two rest positions, so it is
  /// derived rather than tuned, and opening and closing feel the same.
  static const double defaultOpenThreshold = 0.5;

  /// Release speed, in logical **pixels per second**, at or above which a
  /// flick decides the settle whatever the distance: toward the actions it
  /// opens, away from them it closes.
  ///
  /// The same figure (0.4 px/ms) the drawer reads for its flick
  /// (`CoreDrawerContract.defaultDismissVelocity`) — one speed means "a
  /// flick" across the kit; a Core test pins the two together. A
  /// designer-judgement feel value.
  static const double defaultFlingVelocity = 400;

  /// How much of a pull past the actions the row follows when a full swipe
  /// is not allowed: the row moves `resistance × excess` beyond the actions'
  /// width, so it stretches and resists instead of stopping dead.
  ///
  /// A designer-judgement feel value; `0` would be a hard stop, `1` no
  /// resistance at all.
  static const double defaultResistance = 0.25;

  /// How far the pointer has to travel along the row before a press becomes
  /// a swipe, in logical pixels.
  ///
  /// 18 is Flutter's own touch slop (`kTouchSlop`); the Web seat, which has
  /// no gesture arena, arms its drag at the same distance so a swipe starts
  /// at the same pull on both. The Flutter seat leaves arming to the
  /// framework's recogniser — it reads the device's slop — and a Flutter
  /// test pins this figure to `kTouchSlop`.
  static const double defaultDragSlop = 18;

  /// A row within this many pixels of closed counts as closed — it has no
  /// side, a drag that starts on it is not locked to one, and it is not
  /// "open" for the purposes of tap-to-close.
  static const double restTolerance = 1;

  /// How long a released row takes to come to rest.
  ///
  /// The Flutter seat settles on a critically damped spring of this
  /// perceptual duration (`SpringDescription.withDurationAndBounce` with no
  /// bounce), carrying the release velocity; the Web seat, whose transitions
  /// cannot carry a velocity, settles with a transition of this duration and
  /// the `CoreEasing.enter` curve. Both decelerate into the rest position
  /// without overshooting and are at rest after the same duration; they are
  /// not the same curve (the spring leads in the first half, because it
  /// starts at the release speed), which is the one place the two idioms are
  /// allowed to differ. Because it is one duration — a transition-tier
  /// token — reduced motion reaches both. A designer-judgement value:
  /// [CoreDuration.moderate] would be slower.
  static const Duration defaultSettleDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  /// Whether each action's name is drawn under its button, on by default.
  ///
  /// The label is always the action's accessible name; this decides whether
  /// it is also seen. The label sits **under** the button: a fixed-width
  /// cell (the actions' width is a Core number, which is what lets both
  /// seats agree on how far the row opens without measuring text) cannot
  /// hold an icon and a label side by side, and a layout that hugged its
  /// text would make that width depend on the font. Icon-only is the
  /// alternative this switch offers. A designer-judgement value.
  static const bool defaultShowLabels = true;

  /// The `Button` shape of every action — a circle, the shape of the
  /// platform list's own swipe actions.
  static const CoreButtonShape actionButtonShape = CoreButtonShape.circle;

  /// The `Button` size of every action: the `lg` rung of the control ladder
  /// (48), the nearest rung to the 50-point circle the platform list draws.
  /// A designer-judgement value; [CoreSwipeActionsStyle.defaultActionWidth]
  /// is read from the same rung.
  static const CoreComponentSize actionButtonSize = CoreComponentSize.lg;

  /// The row itself — what the actions sit behind.
  W get child;

  /// Actions revealed at the start edge (left in a left-to-right locale), by
  /// dragging the row toward the end edge. The first is the outermost.
  List<CoreSwipeAction<W>> get leadingActions;

  /// Actions revealed at the end edge (right in a left-to-right locale), by
  /// dragging the row toward the start edge. The first is the outermost.
  List<CoreSwipeAction<W>> get trailingActions;

  /// Whether pulling the row far enough ([fullSwipeThreshold]) runs the first
  /// action of that side on release. When off, a pull past the actions
  /// resists ([defaultResistance]) and a release opens them.
  bool get allowsFullSwipe;

  /// How far the row has to be pulled to run the first action, as a fraction
  /// of its width. Must be above 0 and at most 1.
  double get fullSwipeThreshold;

  /// Whether the row can be swiped. `null` → enabled.
  bool? get enabled;

  /// Whether each action's name is drawn under its button
  /// ([defaultShowLabels]).
  bool get showLabels;

  /// Per-instance chrome.
  ///
  /// ```text
  /// design system default
  ///   → CoreSwipeActionsTheme.style
  ///   → widget.swipeActionsStyle
  /// ```
  CoreSwipeActionsStyle? get swipeActionsStyle;
}
