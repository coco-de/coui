import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedContextMenu
// ═══════════════════════════════════════════════════

/// Resolver output for [ContextMenu].
///
/// The context menu composes the unified `Menu` for its panel (box + rows +
/// dividers + shortcuts), so all of that chrome resolves inside `Menu`.
/// This output carries the panel `Popup`'s resolved open/close animation
/// durations, the merged [menuStyle] raw-forwarded to the inner `Menu`, and
/// the settled numbers of the opt-in lift (`liftChild`), which the lift host
/// and the lifted copy read.
class ResolvedContextMenu {
  /// Creates a [ResolvedContextMenu].
  const ResolvedContextMenu({
    required this.panel,
    required this.menuStyle,
    required this.liftDuration,
    required this.liftScale,
    required this.liftDimOpacity,
    required this.liftCast,
    required this.liftRadius,
    required this.retractScale,
  });

  /// Resolved popup-panel chrome — read only for its open / close
  /// animation durations (the composed `Menu` paints the actual box).
  final ResolvedPopup panel;

  /// Merged [CoreMenuStyle] (`CoreMenuTheme.style` ←
  /// `CoreContextMenuTheme.style.menuStyle` ← `widget.contextMenuStyle
  /// .menuStyle`) raw-forwarded to the composed `Menu`'s `menuStyle` slot;
  /// `null` leaves the inner `Menu` at its design-system defaults.
  final CoreMenuStyle? menuStyle;

  /// How long the lift's rise (and its way back from a release) takes, as the
  /// style states it and after reduced motion: a transition, so it is zero
  /// when the person asked for less motion. The engine holds a held touch's
  /// rise to what the hold leaves (`CoreContextMenuLift.riseDuration`), so
  /// this is the ask, not always the run.
  final Duration liftDuration;

  /// The size the lifted copy reaches, as a multiple of the original's. The
  /// engine holds it to 1 or more.
  final double liftScale;

  /// How dark the page behind the lifted copy gets at full lift, as a share of
  /// the scrim colour. The engine holds it to 0..1.
  final double liftDimOpacity;

  /// The cast of the lifted copy at full lift, as Core layers. The one value
  /// here that stays a Core value: each frame scales its layers by the lift's
  /// progress before they are converted (`resolveContextMenuLift`), and the
  /// conversion needs that frame's theme.
  final List<CoreShadowLayer> liftCast;

  /// The corners of the box the cast is cast from, in the active size scaling:
  /// a length like the surfaces it hugs, so it follows the app's scaling.
  final BorderRadius liftRadius;

  /// The size the folding panel (and the preview) reach, as a multiple of
  /// their own. The engine holds it to 0..1.
  final double retractScale;
}

// ═══════════════════════════════════════════════════
// resolveContextMenu — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedContextMenu] for the given [context].
///
/// Folds `CoreContextMenuTheme.style` over the design-system defaults and
/// the per-instance [contextMenuStyle], then delegates the panel chrome to
/// `resolvePopup` (for the open/close durations) on the merged
/// [CoreMenuStyle.popupStyle]. The lift's numbers come out of the same chain,
/// so a style states them per instance or through the theme, and the
/// per-instance value wins.
ResolvedContextMenu resolveContextMenu(
  BuildContext context, {
  CoreContextMenuStyle? contextMenuStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final menuTheme = theme.coreComponentTheme?.contextMenu;

  // Merge chain — design-system defaults → theme.style → instance.
  final merged = resolveStyleChain(const CoreContextMenuStyle(), [
    menuTheme?.style,
    contextMenuStyle,
  ]);

  // ─── Stage 1 RESOLVE — settle each value to its Core type ──
  // Nested slot — the context menu's (empty) partial with the
  // per-instance override merged on top, raw-forwarded so the inner
  // `Menu` resolver fills its own defaults (no field-by-field reach).
  final menuStyle = CoreContextMenuStyle.defaultMenuStyle.merge(
    merged.menuStyle,
  );
  final liftDuration =
      merged.liftDuration ?? CoreContextMenuStyle.defaultLiftDuration;
  final liftScale = merged.liftScale ?? CoreContextMenuStyle.defaultLiftScale;
  final liftDimOpacity =
      merged.liftDimOpacity ?? CoreContextMenuStyle.defaultLiftDimOpacity;
  final liftCast = merged.liftCast ?? CoreContextMenuStyle.defaultLiftCast;
  final liftRadius =
      merged.liftRadius ?? CoreContextMenuStyle.defaultLiftRadius;
  final retractScale =
      merged.retractScale ?? CoreContextMenuStyle.defaultRetractScale;

  // ─── Stage 2 EMIT — Flutter native (theme-dependent) ──
  // Panel durations come from the forwarded menu panel style (the inner
  // `Menu` paints the box; this only needs the open/close durations).
  final panel = resolvePopup(context, popupStyle: menuStyle.popupStyle);
  // The rise and the way back are a transition, so reduced motion makes them a
  // jump: the lifted state is still shown, since it is the feedback for the
  // hold, but it is not animated into.
  final liftDurationValue = resolveMotionDuration(context, liftDuration);
  // The corner is a length like the surfaces it hugs, so it follows the app's
  // size scaling (a card's radius does; a cast box with the unscaled corner
  // would show a seam against the child). The cast itself is not scaled: the
  // Web `box-shadow` never scales, the decision the window panel's frame
  // shadow makes too.
  final liftRadiusValue =
      liftRadius.toValue(geometry: theme.geometry) * scaling;

  return ResolvedContextMenu(
    panel: panel,
    menuStyle: menuStyle,
    liftDuration: liftDurationValue,
    liftScale: liftScale,
    liftDimOpacity: liftDimOpacity,
    liftCast: liftCast,
    liftRadius: liftRadiusValue,
    retractScale: retractScale,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedContextMenuLift
// ═══════════════════════════════════════════════════

/// Paint-ready values for one frame of the lift of a [ContextMenu]'s source.
class ResolvedContextMenuLift {
  /// Creates a [ResolvedContextMenuLift].
  const ResolvedContextMenuLift({
    required this.scale,
    required this.dimColor,
    required this.shadows,
    required this.borderRadius,
  });

  /// The size of the lifted copy, as a multiple of the original's.
  final double scale;

  /// The tint over the page, its alpha already the dim at this progress.
  final Color dimColor;

  /// The cast of the lifted copy at this progress, in the active surface
  /// style's geometry and brightness.
  final List<BoxShadow> shadows;

  /// The corners of the box the cast is cast from.
  final BorderRadius borderRadius;
}

/// Resolves [ResolvedContextMenuLift] for a lift that has come [progress] of
/// the way (0 at rest, 1 fully lifted) — what `CoreContextMenuLift` says that
/// progress looks like for the numbers [menu] settled, converted for this
/// platform and theme.
///
/// A second entry point beside [resolveContextMenu], for the same reason a
/// per-item sub-widget has one: it is resolved for every frame of an animation,
/// by a widget that is not the menu. It takes the menu's own resolved output
/// instead of merging a style again, so the numbers a frame draws with are the
/// ones the clock and the fold run on.
ResolvedContextMenuLift resolveContextMenuLift(
  BuildContext context, {
  required ResolvedContextMenu menu,
  required double progress,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  // Stage 1 RESOLVE — the Core values at this progress.
  final scale = CoreContextMenuLift.scale(progress, liftScale: menu.liftScale);
  // The dim is the scrim colour at this alpha, on the colour and not on the
  // node: the copy and the panel above it stay opaque.
  final dimAlpha = CoreContextMenuLift.dim(
    progress,
    opacity: menu.liftDimOpacity,
  );
  final dim = const CoreColor.token(CoreColors.scrim).scaleAlpha(dimAlpha);
  final cast = CoreContextMenuLift.cast(progress, layers: menu.liftCast);
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();

  // Stage 2 EMIT — Flutter native.
  final dimColor = scheme.resolve(dim).toValue();
  final shadows = cast.toValue(base: shadowBase, geometry: theme.geometry);

  return ResolvedContextMenuLift(
    scale: scale,
    dimColor: dimColor,
    shadows: shadows,
    borderRadius: menu.liftRadius,
  );
}
