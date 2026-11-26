import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedSwiper
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Swiper`.
///
/// The overlay panel is drawn by the composed unified `Drawer`
/// (`openDrawer` — slide animation, barrier, drag-to-dismiss and the grab
/// handle), so the panel chrome — the handle's included — travels as the
/// raw-forwarded [drawerStyle] nested slot and the drawer's own resolver
/// finishes it:
///
/// ```text
/// openDrawer(builder:)
///   └─ Drawer(showDragHandle:, drawerStyle: drawerStyle)
///        └─ overlayContent
/// ```
///
/// The `dragHandle*` fields below are deprecated: they describe the handle
/// the drawer now draws, read off the drawer's own resolver for
/// [drawerStyle].
class ResolvedSwiper {
  /// Creates a [ResolvedSwiper].
  const ResolvedSwiper({
    required this.drawerStyle,
    @Deprecated('Read resolveDrawer (since 0.162).')
    required this.dragHandleColor,
    @Deprecated('Read resolveDrawer (since 0.162).')
    required this.dragHandleWidth,
    @Deprecated('Read resolveDrawer (since 0.162).')
    required this.dragHandleThickness,
    @Deprecated('Read resolveDrawer (since 0.162).')
    required this.dragHandleInset,
    @Deprecated('Read resolveDrawer (since 0.162).')
    required this.dragHandleBorderRadius,
  });

  /// Nested chrome for the composed `Drawer` — the variant partial
  /// (`CoreSwiperStyle.defaultsByVariant`) merged with the caller's
  /// `drawerStyle` slot, raw-forwarded so the drawer's own resolver
  /// applies scaling / token resolution.
  final CoreDrawerStyle drawerStyle;

  /// Effective drag-handle pill colour.
  @Deprecated(
    'The handle is drawn by the composed Drawer (since 0.162) — read '
    'resolveDrawer(...).dragHandleColor.',
  )
  final Color dragHandleColor;

  /// Effective drag-handle pill width (logical px, scaling applied).
  @Deprecated(
    'The handle is drawn by the composed Drawer (since 0.162) — read '
    'resolveDrawer(...).dragHandleWidth.',
  )
  final double dragHandleWidth;

  /// Effective drag-handle pill thickness (logical px, scaling
  /// applied).
  @Deprecated(
    'The handle is drawn by the composed Drawer (since 0.162) — read '
    'resolveDrawer(...).dragHandleThickness.',
  )
  final double dragHandleThickness;

  /// Effective drag-handle inset padding (logical px, scaling
  /// applied).
  @Deprecated(
    'The handle is drawn by the composed Drawer (since 0.162) — read '
    'resolveDrawer(...).dragHandleInset.',
  )
  final double dragHandleInset;

  /// Effective drag-handle pill corner radius (scaling applied).
  @Deprecated(
    'The handle is drawn by the composed Drawer (since 0.162) — read '
    'resolveDrawer(...).dragHandleBorderRadius.',
  )
  final BorderRadius dragHandleBorderRadius;
}

// ═══════════════════════════════════════════════════
// Resolver
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwiper] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreSwiperStyle.defaultsByVariant[variant] (drawer partial)
///   → theme.coreComponentTheme.swiper.style
///   → theme.coreComponentTheme.swiper.variantStyles[variant]
///   → widget.swiperStyle
/// ```
ResolvedSwiper resolveSwiper(
  BuildContext context, {
  required CoreSwiperVariant variant,
  CoreSwiperStyle? swiperStyle,
}) {
  final theme = Theme.of(context);
  final swiperTheme = theme.coreComponentTheme?.swiper;

  // ─── Stage 1 RESOLVE — merge chain ────────────────────
  final merged = resolveStyleChain(const CoreSwiperStyle(), [
    swiperTheme?.style,
    swiperTheme?.variantStyles?[variant],
    swiperStyle,
  ]);

  // Composite nested slot — the variant's divergent drawer chrome, the
  // handle values a caller still states through the deprecated flat
  // `dragHandle*` fields, then the caller's own `drawerStyle` (which wins),
  // raw-forwarded: the composed drawer's resolver applies scaling and
  // resolves the colour tokens.
  final drawerStyle = CoreSwiperStyle.defaultsByVariant[variant]!
      // The deprecated spelling is still honoured until it is removed.
      // ignore: deprecated_member_use
      .merge(merged.legacyDragHandleStyle)
      .merge(merged.drawerStyle);

  // ─── The (deprecated) handle readout ──────────────────
  // What the composed drawer draws for these values — read off the drawer's
  // own resolver, which owns the handle's defaults and its theme row. The
  // handle does not depend on the edge it lies on, so any side reads the
  // same values.
  final drawer = resolveDrawer(
    context,
    side: CoreDrawerSide.defaultSide,
    drawerStyle: drawerStyle,
  );
  final dragHandleColor = drawer.dragHandleColor;
  final dragHandleWidth = drawer.dragHandleWidth;
  final dragHandleThickness = drawer.dragHandleThickness;
  final dragHandleInset = drawer.dragHandleInset;
  final dragHandleBorderRadius = drawer.dragHandleBorderRadius;

  return ResolvedSwiper(
    drawerStyle: drawerStyle,
    dragHandleColor: dragHandleColor,
    dragHandleWidth: dragHandleWidth,
    dragHandleThickness: dragHandleThickness,
    dragHandleInset: dragHandleInset,
    dragHandleBorderRadius: dragHandleBorderRadius,
  );
}
