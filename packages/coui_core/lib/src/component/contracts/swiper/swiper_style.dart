/// Per-instance style for `Swiper`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/contracts/drawer/drawer_style.dart';
import 'package:coui_core/src/component/contracts/swiper/swiper_variant.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Swiper` should render.
///
/// The overlay panel itself is drawn by the composed unified `Drawer`
/// (child component composition — the panel surface, barrier, slide
/// animation, drag-to-dismiss and the grab handle all belong to that
/// component), so the panel chrome flows through the nested
/// [drawerStyle] slot rather than flat duplicate fields here. The
/// handle's chrome is the drawer's `CoreDrawerStyle.dragHandle*`; the
/// flat `dragHandle*` fields below are the deprecated spelling of the same
/// values and fold in under [drawerStyle].
///
/// ```text
/// design system default (defaultsByVariant)
///   → CoreSwiperTheme.style
///   → widget.swiperStyle
/// ```
@immutable
class CoreSwiperStyle implements CoreStyle<CoreSwiperStyle> {
  /// Creates a [CoreSwiperStyle].
  const CoreSwiperStyle({
    this.drawerStyle,
    @Deprecated(
      'Use drawerStyle: CoreDrawerStyle(dragHandleColor: …) (since 0.161).',
    )
    this.dragHandleColor,
    @Deprecated(
      'Use drawerStyle: CoreDrawerStyle(dragHandleWidth: …) (since 0.161).',
    )
    this.dragHandleWidth,
    @Deprecated(
      'Use drawerStyle: CoreDrawerStyle(dragHandleThickness: …) '
      '(since 0.161).',
    )
    this.dragHandleThickness,
    @Deprecated(
      'Use drawerStyle: CoreDrawerStyle(dragHandleInset: …) (since 0.161).',
    )
    this.dragHandleInset,
    @Deprecated(
      'Use drawerStyle: CoreDrawerStyle(dragHandleBorderRadius: …) '
      '(since 0.161).',
    )
    this.dragHandleBorderRadius,
  });

  // ── Design-system defaults ──────────────────────────────

  /// Per-variant partial `CoreDrawerStyle` forwarded into the composed
  /// `Drawer` — only the fields where the variant diverges from the
  /// drawer defaults; everything else stays null so the drawer's own
  /// resolver fills it.
  ///
  /// * [CoreSwiperVariant.drawer] — the drawer's stock chrome plus the
  ///   zoom-out backdrop (shadcn's drawer); the drawer's own default has no
  ///   zoom-out.
  /// * [CoreSwiperVariant.sheet] — minimal, edge-to-edge surface: no
  ///   elevation shadow, no border, square corners.
  static const Map<CoreSwiperVariant, CoreDrawerStyle> defaultsByVariant = {
    CoreSwiperVariant.drawer: CoreDrawerStyle(
      backdropScale: CoreDrawerStyle.zoomBackdropScale,
      backdropCornerRadius: CoreDrawerStyle.zoomBackdropCornerRadius,
    ),
    CoreSwiperVariant.sheet: CoreDrawerStyle(
      panelBorderRadius: .zero,
      panelBorderWidth: 0,
      panelBoxShadow: [],
    ),
  };

  /// The drawer's handle colour — kept as an alias while
  /// [dragHandleColor] is deprecated.
  @Deprecated(
    'Moved to CoreDrawerStyle.defaultDragHandleColor (since 0.161) — the '
    'handle is drawn by the composed Drawer.',
  )
  static const CoreColor defaultDragHandleColor =
      CoreDrawerStyle.defaultDragHandleColor;

  /// The drawer's handle length — kept as an alias while
  /// [dragHandleWidth] is deprecated.
  @Deprecated(
    'Moved to CoreDrawerStyle.defaultDragHandleWidth (since 0.161) — the '
    'handle is drawn by the composed Drawer.',
  )
  static const double defaultDragHandleWidth =
      CoreDrawerStyle.defaultDragHandleWidth;

  /// The drawer's handle thickness — kept as an alias while
  /// [dragHandleThickness] is deprecated.
  @Deprecated(
    'Moved to CoreDrawerStyle.defaultDragHandleThickness (since 0.161) — '
    'the handle is drawn by the composed Drawer.',
  )
  static const double defaultDragHandleThickness =
      CoreDrawerStyle.defaultDragHandleThickness;

  /// The drawer's space around the handle — kept as an alias while
  /// [dragHandleInset] is deprecated.
  @Deprecated(
    'Moved to CoreDrawerStyle.defaultDragHandleInset (since 0.161) — the '
    'handle is drawn by the composed Drawer.',
  )
  static const double defaultDragHandleInset =
      CoreDrawerStyle.defaultDragHandleInset;

  /// The drawer's handle corner — kept as an alias while
  /// [dragHandleBorderRadius] is deprecated.
  @Deprecated(
    'Moved to CoreDrawerStyle.defaultDragHandleBorderRadius (since 0.161) '
    '— the handle is drawn by the composed Drawer.',
  )
  static const CoreBorderRadius defaultDragHandleBorderRadius =
      CoreDrawerStyle.defaultDragHandleBorderRadius;

  // ── Nested slot ─────────────────────────────────────────

  /// Style of the `Drawer` the swiper opens — panel surface, barrier, slide
  /// durations, drag-dismiss threshold and so on. Merges on top of the
  /// variant's partial style from [defaultsByVariant].
  ///
  /// **Deliberately has no flat `default*` — its baseline is
  /// [defaultsByVariant], which is this field's per-axis table.** Both
  /// resolvers read `defaultsByVariant[variant]!.merge(merged.drawerStyle)`,
  /// so the default is decided; it just varies along `variant`, which is
  /// where `core/layer-mapping.md` says a variant-dependent default
  /// belongs. The table is easy to miss with a name-matching search
  /// because its *value type* is this field's type, so no `drawerStyle:`
  /// key appears inside the literal.
  ///
  /// A flat constant could not represent it and would make things worse
  /// either way: empty, it is a no-op that adds a level to the merge chain
  /// for nothing; non-empty, it states panel chrome that
  /// [CoreSwiperVariant.sheet]'s partial (`panelBorderRadius: .zero`,
  /// `panelBorderWidth: 0`, `panelBoxShadow: []`) exists precisely to
  /// contradict — and any field it named that the sheet partial does not
  /// would silently reach the sheet too.
  final CoreDrawerStyle? drawerStyle;

  // ── Deprecated: the handle is the composed Drawer's ────

  /// Drag-handle colour — folds in under [drawerStyle]'s
  /// `dragHandleColor`, which wins when both are stated.
  @Deprecated(
    'Use drawerStyle: CoreDrawerStyle(dragHandleColor: …) (since 0.161) — '
    'the handle is drawn by the composed Drawer. Still read until removed.',
  )
  final CoreColor? dragHandleColor;

  /// Drag-handle length — folds in under [drawerStyle]'s `dragHandleWidth`.
  @Deprecated(
    'Use drawerStyle: CoreDrawerStyle(dragHandleWidth: …) (since 0.161) — '
    'the handle is drawn by the composed Drawer. Still read until removed.',
  )
  final double? dragHandleWidth;

  /// Drag-handle thickness — folds in under [drawerStyle]'s
  /// `dragHandleThickness`.
  @Deprecated(
    'Use drawerStyle: CoreDrawerStyle(dragHandleThickness: …) (since '
    '0.161) — the handle is drawn by the composed Drawer. Still read until '
    'removed.',
  )
  final double? dragHandleThickness;

  /// Space around the handle — folds in under [drawerStyle]'s
  /// `dragHandleInset`.
  @Deprecated(
    'Use drawerStyle: CoreDrawerStyle(dragHandleInset: …) (since 0.161) — '
    'the handle is drawn by the composed Drawer. Still read until removed.',
  )
  final double? dragHandleInset;

  /// Drag-handle corner — folds in under [drawerStyle]'s
  /// `dragHandleBorderRadius`.
  @Deprecated(
    'Use drawerStyle: CoreDrawerStyle(dragHandleBorderRadius: …) (since '
    '0.161) — the handle is drawn by the composed Drawer. Still read until '
    'removed.',
  )
  final CoreBorderRadius? dragHandleBorderRadius;

  /// The deprecated flat handle fields as the [CoreDrawerStyle] patch they
  /// now mean — both resolvers fold it in under [drawerStyle], so a value
  /// stated the old way still reaches the handle and the nested slot wins
  /// when both say something. Goes away with those fields.
  @Deprecated(
    'Reads the deprecated dragHandle* fields (since 0.161) — goes away with '
    'them; state the handle through drawerStyle.',
  )
  CoreDrawerStyle get legacyDragHandleStyle => CoreDrawerStyle(
    dragHandleColor: dragHandleColor,
    dragHandleWidth: dragHandleWidth,
    dragHandleThickness: dragHandleThickness,
    dragHandleInset: dragHandleInset,
    dragHandleBorderRadius: dragHandleBorderRadius,
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The nested [drawerStyle] is
  /// merged recursively.
  @override
  CoreSwiperStyle merge(CoreSwiperStyle? other) {
    if (other == null) return this;
    return CoreSwiperStyle(
      drawerStyle: drawerStyle?.merge(other.drawerStyle) ?? other.drawerStyle,
      dragHandleColor: other.dragHandleColor ?? dragHandleColor,
      dragHandleWidth: other.dragHandleWidth ?? dragHandleWidth,
      dragHandleThickness: other.dragHandleThickness ?? dragHandleThickness,
      dragHandleInset: other.dragHandleInset ?? dragHandleInset,
      dragHandleBorderRadius:
          other.dragHandleBorderRadius ?? dragHandleBorderRadius,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSwiperStyle copyWith({
    CoreDrawerStyle? drawerStyle,
    CoreColor? dragHandleColor,
    double? dragHandleWidth,
    double? dragHandleThickness,
    double? dragHandleInset,
    CoreBorderRadius? dragHandleBorderRadius,
  }) {
    return CoreSwiperStyle(
      drawerStyle: drawerStyle ?? this.drawerStyle,
      dragHandleColor: dragHandleColor ?? this.dragHandleColor,
      dragHandleWidth: dragHandleWidth ?? this.dragHandleWidth,
      dragHandleThickness: dragHandleThickness ?? this.dragHandleThickness,
      dragHandleInset: dragHandleInset ?? this.dragHandleInset,
      dragHandleBorderRadius:
          dragHandleBorderRadius ?? this.dragHandleBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwiperStyle &&
          runtimeType == other.runtimeType &&
          drawerStyle == other.drawerStyle &&
          dragHandleColor == other.dragHandleColor &&
          dragHandleWidth == other.dragHandleWidth &&
          dragHandleThickness == other.dragHandleThickness &&
          dragHandleInset == other.dragHandleInset &&
          dragHandleBorderRadius == other.dragHandleBorderRadius;

  @override
  int get hashCode => Object.hash(
    drawerStyle,
    dragHandleColor,
    dragHandleWidth,
    dragHandleThickness,
    dragHandleInset,
    dragHandleBorderRadius,
  );
}
