import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSwipeActions
// ═══════════════════════════════════════════════════

/// Resolver output for `SwipeActions`.
///
/// Every chrome / dimensional / nested-slot override has been merged
/// through:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.swipeActions.style
///   → widget.swipeActionsStyle
/// ```
///
/// Widget tree:
///
/// ```text
/// Listener (a pointer the system took is not a lift)
///   └─ GestureDetector (horizontal drag; the recogniser arms it)
///        └─ Focus (the row as a focus target; Escape)
///             └─ FocusTraversalGroup (leading · the row · trailing)
///                  └─ AnimatedBuilder (the row's offset)
///                       └─ Stacks (passthrough: the incoming constraints)
///                            ├─ PositionedDirectional · a platter per side
///                            │    └─ FocusTraversalOrder → Focus
///                            │         (focus in the platter opens it)
///                            │         └─ ExcludeSemantics (while closed)
///                            │              └─ ClipRect (revealed width)
///                            │                   └─ cells, outer edge first
///                            │                        └─ Button + Gap + label
///                            └─ FocusTraversalOrder → FocusTraversalGroup
///                                 └─ Transform.translate (the row)
///                                      └─ Semantics (custom actions)
///                                           └─ child (+ a tap catcher)
/// ```
///
/// The cell is a composed `Button` with its label under it, so almost nothing
/// here is SwipeActions' own: [actionButtonStyle] and [labelGapStyle] are
/// raw-forwarded and each child resolver fills its own ladder. What
/// SwipeActions settles is how wide a cell is, how far the row has to move to
/// uncover a side ([leadingExtent] / [trailingExtent]) and how long it takes
/// to come to rest.
///
/// Numbers are logical px with the density and the scaling already applied,
/// so the extents the drag runs in are the platters' drawn width.
class ResolvedSwipeActions {
  /// Creates a [ResolvedSwipeActions].
  const ResolvedSwipeActions({
    required this.actionWidth,
    required this.actionSpacing,
    required this.platterInset,
    required this.leadingExtent,
    required this.trailingExtent,
    required this.platterColor,
    required this.labelGapStyle,
    required this.labelTextStyle,
    required this.fullSwipeScale,
    required this.actionButtonStyle,
    required this.settleDuration,
    required this.scaleCurve,
  });

  /// The width of one action cell (logical px, density- and
  /// scaling-applied).
  final double actionWidth;

  /// The space between neighbouring cells (logical px).
  final double actionSpacing;

  /// The space between an end of the platter and the cell next to it
  /// (logical px).
  final double platterInset;

  /// How far the row has to move to uncover every leading action (logical
  /// px): `CoreSwipeActionsStyle.extentFor` of the resolved numbers, `0` for
  /// no actions.
  final double leadingExtent;

  /// How far the row has to move to uncover every trailing action (logical
  /// px).
  final double trailingExtent;

  /// The platter's fill, or `null` when it is fully transparent — a platter
  /// with no fill paints nothing.
  final Color? platterColor;

  /// Nested gap style — forwarded to the `Gap` between a button and its
  /// label.
  final CoreGapStyle labelGapStyle;

  /// The label under a button (type and colour, theme-resolved).
  final TextStyle labelTextStyle;

  /// The scale the first action's cell grows to while a release would run
  /// it, as a factor; `1` draws no cue.
  final double fullSwipeScale;

  /// Nested button style — forwarded raw to every action's `Button`; `null`
  /// when nothing is stated, so the button resolves its own defaults.
  final CoreButtonStyle? actionButtonStyle;

  /// How long a released row takes to come to rest, and how long the
  /// full-swipe cue takes to grow — after the reduced-motion preference, so
  /// [Duration.zero] means "jump".
  final Duration settleDuration;

  /// The curve of the full-swipe cue's growth. (The settle is a spring and
  /// has none.)
  final Curve scaleCurve;
}

// ═══════════════════════════════════════════════════
// resolveSwipeActions — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwipeActions] for the given [context].
///
/// [leadingCount] and [trailingCount] are the numbers of actions on each
/// side; they are what the extents are derived from.
ResolvedSwipeActions resolveSwipeActions(
  BuildContext context, {
  required int leadingCount,
  required int trailingCount,
  CoreSwipeActionsStyle? swipeActionsStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final swipeActionsTheme = theme.coreComponentTheme?.swipeActions;

  final merged = resolveStyleChain(const CoreSwipeActionsStyle(), [
    swipeActionsTheme?.style,
    swipeActionsStyle,
  ]);

  // Stage1 RESOLVE
  final actionWidthCore =
      merged.actionWidth ?? CoreSwipeActionsStyle.defaultActionWidth;
  final actionSpacingCore =
      merged.actionSpacing ?? CoreSwipeActionsStyle.defaultActionSpacing;
  final platterInsetCore =
      merged.platterInset ?? CoreSwipeActionsStyle.defaultPlatterInset;
  final platterColorCore =
      merged.platterColor ?? CoreSwipeActionsStyle.defaultPlatterColor;
  final labelGapStyle = CoreSwipeActionsStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final labelStyleCore = CoreSwipeActionsStyle.defaultLabelStyle.merge(
    merged.labelStyle,
  );
  final fullSwipeScale =
      merged.fullSwipeScale ?? CoreSwipeActionsStyle.defaultFullSwipeScale;
  // No default: the button is the chrome's owner, and an unstated slot
  // forwards nothing so each `Button` resolves its own ladder.
  final actionButtonStyle = merged.actionButtonStyle;

  // Stage2 EMIT. The cell is a row of the control ladder, so it moves a rung
  // under the theme density; the gaps are spacing, so they move a step.
  final actionWidth = theme.geometry.controlHeight(actionWidthCore) * scaling;
  final actionSpacing = theme.geometry.space(actionSpacingCore) * scaling;
  final platterInset = theme.geometry.space(platterInsetCore) * scaling;
  final leadingExtent = CoreSwipeActionsStyle.extentFor(
    leadingCount,
    actionWidth: actionWidth,
    actionSpacing: actionSpacing,
    platterInset: platterInset,
  );
  final trailingExtent = CoreSwipeActionsStyle.extentFor(
    trailingCount,
    actionWidth: actionWidth,
    actionSpacing: actionSpacing,
    platterInset: platterInset,
  );
  final platterFill = theme.colorScheme.resolve(platterColorCore).toValue();
  final platterColor = platterFill.a == 0 ? null : platterFill;
  final labelTextStyle = labelStyleCore.toValue(theme: theme);
  final settleDuration = resolveMotionDuration(
    context,
    CoreSwipeActionsContract.defaultSettleDuration,
  );
  final scaleCurve = CoreEasing.move.toValue();

  return ResolvedSwipeActions(
    actionWidth: actionWidth,
    actionSpacing: actionSpacing,
    platterInset: platterInset,
    leadingExtent: leadingExtent,
    trailingExtent: trailingExtent,
    platterColor: platterColor,
    labelGapStyle: labelGapStyle,
    labelTextStyle: labelTextStyle,
    fullSwipeScale: fullSwipeScale,
    actionButtonStyle: actionButtonStyle,
    settleDuration: settleDuration,
    scaleCurve: scaleCurve,
  );
}
