import 'package:coui_flutter/coui_flutter.dart';

/// Flex precision — ratios are stored as integers (ratio × [flexPrecision]).
const _kFlexPrecision = 1000;

// ═══════════════════════════════════════════════════
// ResolvedResizable
// ═══════════════════════════════════════════════════

/// Resolver output for `Resizable`.
///
/// Single struct that the widget reads — every chrome / dimensional
/// override has been merged through:
///
/// ```text
/// design system default
///   → theme.coreComponentTheme.resizable.style
///   → widget.resizableStyle
/// ```
class ResolvedResizable {
  /// Creates a [ResolvedResizable].
  const ResolvedResizable({
    required this.dividerThickness,
    required this.dividerColor,
    required this.dividerHoverColor,
    required this.dividerDraggingThickness,
    required this.dividerDraggingColor,
    required this.focusOutlineStyle,
    required this.dividerHitExtent,
    required this.transitionDuration,
    required this.flexPrecision,
    required this.handleHitExtent,
    required this.handleLength,
    required this.handleBreadth,
    required this.handleBorderRadius,
    required this.handleColor,
    required this.handleIconColor,
    required this.handleIconSize,
    required this.curve,
  });

  /// Divider stroke thickness (already scaled).
  final double dividerThickness;

  /// Divider stroke colour (idle).
  final Color dividerColor;

  /// Divider stroke colour on hover.
  final Color dividerHoverColor;

  /// Divider stroke thickness while dragged (already scaled).
  final double dividerDraggingThickness;

  /// Divider stroke colour while dragged.
  final Color dividerDraggingColor;

  /// Keyboard focus ring of a divider, forwarded to `FocusOutline`.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Hit-test region around the divider (already scaled).
  final double dividerHitExtent;

  /// Colour crossfade duration between the idle / hover states.
  final Duration transitionDuration;

  /// The shape the chrome change takes over time.
  ///
  /// Paired with the duration beside it rather than left to the framework.
  /// Flutter's implicit animations default to `Curves.linear` and the Web
  /// twin's CSS transition does not — same length, different shape, so
  /// side by side one pane slides at a constant rate while the other eases
  /// in and out. Both platforms name the same `CoreEasing` alias instead.
  final Curve curve;

  /// Multiplier used to convert float ratios to flex integer values.
  final int flexPrecision;

  /// Enlarged hit-test region used when a drag handle is shown (already
  /// scaled).
  final double handleHitExtent;

  /// Grab-handle length along the divider axis (already scaled).
  final double handleLength;

  /// Grab-handle breadth across the divider axis (already scaled).
  final double handleBreadth;

  /// Grab-handle corner radius (already scaled), bent through
  /// `theme.geometry.radius(...)` — the widget must not derive this from
  /// [handleBreadth] with a raw `BorderRadius.circular(...)`, which
  /// bypasses the surface-style geometry axis entirely.
  final BorderRadius handleBorderRadius;

  /// Grab-handle background colour.
  final Color handleColor;

  /// Drag-dot icon colour inside the grab handle.
  final Color handleIconColor;

  /// Drag-dot icon size inside the grab handle (already scaled).
  final double handleIconSize;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedResizable] for [Resizable].
///
/// Priority (per-field):
/// `widget.resizableStyle` > `CoreResizableTheme.style` > design-system
/// defaults.
ResolvedResizable resolveResizable(
  BuildContext context, {
  bool optionalDivider = CoreResizableContract.defaultOptionalDivider,
  CoreResizableStyle? resizableStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final resizableTheme = theme.coreComponentTheme?.resizable;

  final merged = resolveStyleChain(const CoreResizableStyle(), [
    resizableTheme?.style,
    resizableStyle,
  ]);

  final thickness = theme.geometry.stroke(
    merged.dividerThickness ?? CoreResizableStyle.defaultDividerThickness,
    scaling: scaling,
  );
  final hitExtent =
      scaling *
      (merged.dividerHitExtent ?? CoreResizableStyle.defaultDividerHitExtent);
  // CoreColor → Flutter Color always flows through
  // `scheme.resolve(x).toValue()` (Epic #1603 C7 — single colour path,
  // #1601 dark-mode regression class). The idle / hover divider defaults
  // are `CoreResizableStyle.defaultDividerColor` / `defaultDividerHoverColor`
  // (`outlineVariant` / `outline` tokens), matching the Web resolver's
  // `bg-{outlineVariant}` / `hover:bg-{outline}` defaults (cross-platform parity).
  // `optionalDivider` decides the IDLE colour here rather than in the
  // widget: it is a build-time semantic prop, not an interaction state, so
  // it belongs on the resolver input the way `showDragHandle` already is on
  // the Web twin. Deciding it in `build` would put a colour literal in a
  // render-only widget.
  //
  // `CoreColor.transparent` rather than a raw `Color(0x00000000)` — the
  // shared sentinel for "no fill", so both platforms name the same thing.
  final dividerColor = scheme
      .resolve(
        optionalDivider
            ? CoreColor.transparent
            : (merged.dividerColor ?? CoreResizableStyle.defaultDividerColor),
      )
      .toValue();
  final dividerHoverColor = scheme
      .resolve(
        merged.dividerHoverColor ?? CoreResizableStyle.defaultDividerHoverColor,
      )
      .toValue();
  final draggingThickness = theme.geometry.stroke(
    merged.dividerDraggingThickness ??
        CoreResizableStyle.defaultDividerDraggingThickness,
    scaling: scaling,
  );
  final dividerDraggingColor = scheme
      .resolve(
        merged.dividerDraggingColor ??
            CoreResizableStyle.defaultDividerDraggingColor,
      )
      .toValue();
  final focusOutlineStyle = CoreResizableStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreResizableStyle.defaultTransitionDuration,
  );

  // Grab-handle dimensions — same scaling path as the divider hit extent.
  final handleHitExtent =
      scaling *
      (merged.handleHitExtent ?? CoreResizableStyle.defaultHandleHitExtent);
  final handleLength =
      scaling * (merged.handleLength ?? CoreResizableStyle.defaultHandleLength);
  final handleBreadthCore =
      merged.handleBreadth ?? CoreResizableStyle.defaultHandleBreadth;
  final handleBreadth = scaling * handleBreadthCore;
  // Bent on the unscaled value (geometry radius bounds read on the
  // authored ladder, before scaling multiplies — matches every other
  // dimensional value's scaling order), then scaled like `handleBreadth`
  // itself.
  final handleBorderRadius = BorderRadius.circular(
    theme.geometry.radius(handleBreadthCore / 2) * scaling,
  );
  final handleIconSize =
      scaling *
      (merged.handleIconSize ?? CoreResizableStyle.defaultHandleIconSize);
  final handleColor = scheme
      .resolve(merged.handleColor ?? CoreResizableStyle.defaultHandleColor)
      .toValue();
  final handleIconColor = scheme
      .resolve(
        merged.handleIconColor ?? CoreResizableStyle.defaultHandleIconColor,
      )
      .toValue();

  return ResolvedResizable(
    // The same alias the Web twin names for this element's CSS
    // transition. Chrome moving between states is `move`; a curve
    // stated on one platform and defaulted on the other is the
    // divergence nothing renders differently enough to notice until
    // the two are put side by side.
    curve: CoreEasing.move.toValue(),
    dividerThickness: thickness,
    dividerColor: dividerColor,
    dividerHoverColor: dividerHoverColor,
    dividerDraggingThickness: draggingThickness,
    dividerDraggingColor: dividerDraggingColor,
    focusOutlineStyle: focusOutlineStyle,
    dividerHitExtent: hitExtent,
    transitionDuration: transitionDuration,
    flexPrecision: _kFlexPrecision,
    handleHitExtent: handleHitExtent,
    handleLength: handleLength,
    handleBreadth: handleBreadth,
    handleBorderRadius: handleBorderRadius,
    handleColor: handleColor,
    handleIconColor: handleIconColor,
    handleIconSize: handleIconSize,
  );
}
