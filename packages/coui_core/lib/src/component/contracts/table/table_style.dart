/// Per-instance style for `Table`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Table` should render.
///
/// `CoreTableStyle` carries chrome flat fields for header /
/// row / cell / border, plus nested header text + cell text slot
/// styles.
///
/// ```text
/// design system default
///   → CoreTableTheme.style
///   → parent component slot override
///   → widget.tableStyle
/// ```
@immutable
class CoreTableStyle implements CoreStyle<CoreTableStyle> {
  /// Creates a [CoreTableStyle].
  const CoreTableStyle({
    this.backgroundColor,
    this.borderRadius,
    this.viewportWidth,
    this.viewportHeight,
    this.headerBackgroundColor,
    this.headerHeight,
    this.headerPadding,
    this.footerBackgroundColor,
    this.rowBackgroundColor,
    this.rowAlternateBackgroundColor,
    this.rowHoverColor,
    this.rowSelectedColor,
    this.rowHeight,
    this.cellPadding,
    this.borderColor,
    this.borderWidth,
    this.outerBorderWidth,
    this.resizerHoverColor,
    this.resizerDragColor,
    this.resizerThickness,
    this.headerTextStyle,
    this.cellTextStyle,
    this.frozenCellBackgroundColor,
    this.resizerColor,
    this.foregroundColor,
    this.disabledForegroundColor,
  });

  // ─── Design-system defaults (Phase 6g) ────────────────────────────
  // Table has no variant — every default is variant-independent and
  // lives as a `static const` on this class. Flutter / Web resolvers
  // reference these directly so no file-local `_kDefault*` token
  // constant is needed in either platform package.

  /// Default table container border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default row / header separator border width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default outer box border width (logical px). The table draws no box
  /// around itself — only the row and header separators ([borderWidth]).
  static const double defaultOuterBorderWidth = CoreStrokeWidth.stroke0;

  /// Default body / footer cell padding — 12 vertical, 4 horizontal.
  static const CoreEdgeInsets defaultCellPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space12,
    horizontal: CoreSpace.space4,
  );

  /// Default header cell padding — 10 vertical, 4 horizontal, so the
  /// header row is shorter than a body row.
  static const CoreEdgeInsets defaultHeaderPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space10,
    horizontal: CoreSpace.space4,
  );

  /// Default column / row resizer handle thickness (logical px).
  static const double defaultResizerThickness = CoreStrokeWidth.stroke2;

  // ── Color defaults (token-backed) ────────────────────
  // Every fallback colour the platform resolvers previously baked from a
  // raw `cs` token now lives here as a single token-backed source of
  // truth. Flutter resolves each through the scheme; Web routes each
  // through the emit family, so the same token name drives both platforms
  // (1:1:1:1:1:1).

  /// Default row / header separator border colour — the hairline
  /// `outlineVariant`. The outer box, when [outerBorderWidth] draws one,
  /// reads the same colour.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default header row background colour — none. The header reads as the
  /// top of the same surface the table sits on; the frozen-cell base
  /// ([defaultFrozenCellBackgroundColor]) keeps a sticky header opaque.
  static const CoreColor defaultHeaderBackgroundColor = CoreColor.transparent;

  /// Default footer row background colour.
  static const CoreColor defaultFooterBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default body-row hover background colour — `on-surface` at
  /// `opacity/hover`, a wash that reads on a card face as well as on the
  /// page (Web emits `on-surface/3`).
  static const CoreColor defaultRowHoverColor = CoreColor.token(
    CoreColors.onSurface,
    opacity: CoreOpacity.hover,
  );

  /// Default body-row selected background colour — `surfaceContainerHigh`,
  /// an opaque fill (the selected row replaces the hover wash rather than
  /// stacking on it).
  static const CoreColor defaultRowSelectedColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default frozen-cell base background colour (sticky cells layer over
  /// the table surface so scrolled content doesn't bleed through).
  static const CoreColor defaultFrozenCellBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default column/row resizer handle colour on hover / drag.
  static const CoreColor defaultResizerColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default resizer handle colour while hovered. Names
  /// [defaultResizerColor] — the hover tint is the resizer's own colour,
  /// which is what both resolvers already fell back to. Its own named
  /// default because [resizerHoverColor] is its own override slot.
  static const CoreColor defaultResizerHoverColor = defaultResizerColor;

  /// Default resizer handle colour while dragging. Names
  /// [defaultResizerColor] for the same reason as
  /// [defaultResizerHoverColor].
  static const CoreColor defaultResizerDragColor = defaultResizerColor;

  /// Default enabled cell foreground (text) colour.
  static const CoreColor defaultForegroundColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default disabled cell foreground (text) colour — the dedicated
  /// `disabledContent` token rather than `onSurface` at half alpha, so a
  /// disabled row reads the same in every scheme and under forced colours
  /// (alpha is not a property those modes replace).
  static const CoreColor defaultDisabledForegroundColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  /// Default header cell text style — token-backed reference to the
  /// `labelMedium` role (13 / 500) in `onSurfaceSubtle`. The colour is the
  /// enabled header cell's: a [foregroundColor] or a [headerTextStyle]
  /// colour states a different one. A disabled cell reads
  /// [defaultDisabledForegroundColor] instead (per-cell state is resolved
  /// by each platform resolver). Web emits `text-label-medium` +
  /// `text-on-surface-subtle`; Flutter resolves the slot through
  /// `theme.coreTypography.resolve(...)`.
  static const CoreTextStyle defaultHeaderTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelMedium,
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Default body / footer cell text style — token-backed reference to
  /// the `labelLarge` role (14 / 500). Colour is resolved separately
  /// (per-cell enabled / disabled state) by each platform resolver, so
  /// this default carries no `color`. Web emits `text-label-large`;
  /// Flutter resolves the slot through `theme.coreTypography.resolve(...)`.
  static const CoreTextStyle defaultCellTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
  );

  // ── Container chrome (flat) ──────────────────

  /// Table container background colour.
  ///
  /// Deliberately without a `default*`, and it must not gain one: an
  /// unfilled container is what lets a table read on whatever surface it
  /// lands on. A non-null default — `transparent` included — makes the
  /// Web resolver's `containerBgOverride` non-null, and the frozen-cell
  /// branch reads that as "the caller chose a fill" and emits it inline
  /// over the opaque [defaultFrozenCellBackgroundColor] class, so sticky
  /// cells would stop covering the rows scrolling under them. Flutter
  /// reaches the same fill as the tail of the row-base chain
  /// (`rowAlternate ?? frozen ?? row ?? container ?? transparent`).
  final CoreColor? backgroundColor;

  /// Table container border radius.
  final CoreBorderRadius? borderRadius;

  /// Viewport width (logical px). When set together with the widget's
  /// `horizontalOffset`, the table enables horizontal virtual scroll
  /// inside this width.
  ///
  /// Deliberately without a `default*`: the null test is the switch.
  /// Both resolvers read "is a viewport extent set" to decide whether
  /// the table sits inside a scroll container — Web lays out at the
  /// natural grid size (`w-max`) instead of filling its parent
  /// (`w-full`), Flutter builds a `viewportSize` at all — so any default
  /// would put every table into virtual-scroll layout.
  final double? viewportWidth;

  /// Viewport height (logical px). When set together with the widget's
  /// `verticalOffset`, the table enables vertical virtual scroll
  /// inside this height.
  ///
  /// Deliberately without a `default*` — same switch as
  /// [viewportWidth], which names it.
  final double? viewportHeight;

  // ── Header chrome (flat) ─────────────────────

  /// Header row background colour.
  final CoreColor? headerBackgroundColor;

  /// Header row height (logical px).
  ///
  /// Deliberately without a `default*`: unset means the grid track
  /// sizing (`CoreTableSize`) drives the natural header height. A
  /// default would floor every table's header — a `min-height` rule on
  /// each header cell (Web) and a `BoxConstraints` minimum (Flutter) —
  /// including the ones sized by their content today.
  final double? headerHeight;

  /// Header cell padding.
  final CoreEdgeInsets? headerPadding;

  // ── Footer chrome (flat) ─────────────────────

  /// Footer row background colour.
  final CoreColor? footerBackgroundColor;

  // ── Row chrome (flat) ────────────────────────

  /// Body row background colour.
  ///
  /// Deliberately without a `default*`: it is one link in the row-base
  /// chain (`rowAlternate ?? frozen ?? row ?? container ?? transparent`)
  /// and unset means "this row states no fill of its own". A default
  /// would fill every body row, and in `Table` (the caller that opts into
  /// the row fallback) it would also stand in for the container fill —
  /// the same frozen-cell path written down on [backgroundColor].
  final CoreColor? rowBackgroundColor;

  /// Alternate (zebra-stripe) body row background colour.
  ///
  /// Deliberately without a `default*`: both resolvers gate the stripe
  /// on this being set — `usesZebra` on Web, the `bodyRowEven ? … : null`
  /// head of the Flutter row-base chain — so a default would stripe
  /// every table rather than the ones that ask for it.
  final CoreColor? rowAlternateBackgroundColor;

  /// Body row background colour on hover.
  final CoreColor? rowHoverColor;

  /// Body row background colour when selected.
  final CoreColor? rowSelectedColor;

  /// Body row height (logical px).
  ///
  /// Deliberately without a `default*` for the reason written on
  /// [headerHeight] — unset lets the grid track sizing drive the natural
  /// row height, and a default would floor every body row on both
  /// platforms.
  final double? rowHeight;

  // ── Cell chrome (flat) ───────────────────────

  /// Body cell padding.
  final CoreEdgeInsets? cellPadding;

  // ── Border chrome (flat) ─────────────────────

  /// Row / header separator border colour. The outer box, when
  /// [outerBorderWidth] draws one, reads the same colour.
  final CoreColor? borderColor;

  /// Row / header separator border width (logical px).
  final double? borderWidth;

  /// Outer box border width (logical px). `0` draws no box around the
  /// table; the row and header separators keep reading [borderWidth].
  /// `null` → [defaultOuterBorderWidth].
  final double? outerBorderWidth;

  // ── Resizer chrome (flat) ────────────────────

  /// Column/row resizer handle colour on hover.
  final CoreColor? resizerHoverColor;

  /// Column/row resizer handle colour while dragging.
  final CoreColor? resizerDragColor;

  /// Resizer handle thickness (logical px).
  final double? resizerThickness;

  // ── Slot Styles (nested) ─────────────────────

  /// Header cell text style override.
  final CoreTextStyle? headerTextStyle;

  /// Body cell text style override.
  final CoreTextStyle? cellTextStyle;

  /// Frozen (pinned) cell background colour override.
  /// `null` → [defaultFrozenCellBackgroundColor].
  final CoreColor? frozenCellBackgroundColor;

  /// Column-resizer handle idle colour override.
  /// `null` → [defaultResizerColor].
  final CoreColor? resizerColor;

  /// Cell foreground (text) colour override.
  /// `null` → [defaultForegroundColor].
  final CoreColor? foregroundColor;

  /// Disabled-state cell foreground colour override.
  /// `null` → [defaultDisabledForegroundColor].
  final CoreColor? disabledForegroundColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreTableStyle merge(CoreTableStyle? other) {
    if (other == null) return this;
    return CoreTableStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      viewportWidth: other.viewportWidth ?? viewportWidth,
      viewportHeight: other.viewportHeight ?? viewportHeight,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      headerHeight: other.headerHeight ?? headerHeight,
      headerPadding: other.headerPadding ?? headerPadding,
      footerBackgroundColor:
          other.footerBackgroundColor ?? footerBackgroundColor,
      rowBackgroundColor: other.rowBackgroundColor ?? rowBackgroundColor,
      rowAlternateBackgroundColor:
          other.rowAlternateBackgroundColor ?? rowAlternateBackgroundColor,
      rowHoverColor: other.rowHoverColor ?? rowHoverColor,
      rowSelectedColor: other.rowSelectedColor ?? rowSelectedColor,
      rowHeight: other.rowHeight ?? rowHeight,
      cellPadding: other.cellPadding ?? cellPadding,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      outerBorderWidth: other.outerBorderWidth ?? outerBorderWidth,
      resizerHoverColor: other.resizerHoverColor ?? resizerHoverColor,
      resizerDragColor: other.resizerDragColor ?? resizerDragColor,
      resizerThickness: other.resizerThickness ?? resizerThickness,
      headerTextStyle: _mergeText(headerTextStyle, other.headerTextStyle),
      cellTextStyle: _mergeText(cellTextStyle, other.cellTextStyle),
      frozenCellBackgroundColor:
          other.frozenCellBackgroundColor ?? frozenCellBackgroundColor,
      resizerColor: other.resizerColor ?? resizerColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      disabledForegroundColor:
          other.disabledForegroundColor ?? disabledForegroundColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTableStyle copyWith({
    CoreColor? backgroundColor,
    CoreBorderRadius? borderRadius,
    double? viewportWidth,
    double? viewportHeight,
    CoreColor? headerBackgroundColor,
    double? headerHeight,
    CoreEdgeInsets? headerPadding,
    CoreColor? footerBackgroundColor,
    CoreColor? rowBackgroundColor,
    CoreColor? rowAlternateBackgroundColor,
    CoreColor? rowHoverColor,
    CoreColor? rowSelectedColor,
    double? rowHeight,
    CoreEdgeInsets? cellPadding,
    CoreColor? borderColor,
    double? borderWidth,
    double? outerBorderWidth,
    CoreColor? resizerHoverColor,
    CoreColor? resizerDragColor,
    double? resizerThickness,
    CoreTextStyle? headerTextStyle,
    CoreTextStyle? cellTextStyle,
    CoreColor? frozenCellBackgroundColor,
    CoreColor? resizerColor,
    CoreColor? foregroundColor,
    CoreColor? disabledForegroundColor,
  }) {
    return CoreTableStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      headerHeight: headerHeight ?? this.headerHeight,
      headerPadding: headerPadding ?? this.headerPadding,
      footerBackgroundColor:
          footerBackgroundColor ?? this.footerBackgroundColor,
      rowBackgroundColor: rowBackgroundColor ?? this.rowBackgroundColor,
      rowAlternateBackgroundColor:
          rowAlternateBackgroundColor ?? this.rowAlternateBackgroundColor,
      rowHoverColor: rowHoverColor ?? this.rowHoverColor,
      rowSelectedColor: rowSelectedColor ?? this.rowSelectedColor,
      rowHeight: rowHeight ?? this.rowHeight,
      cellPadding: cellPadding ?? this.cellPadding,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      outerBorderWidth: outerBorderWidth ?? this.outerBorderWidth,
      resizerHoverColor: resizerHoverColor ?? this.resizerHoverColor,
      resizerDragColor: resizerDragColor ?? this.resizerDragColor,
      resizerThickness: resizerThickness ?? this.resizerThickness,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      frozenCellBackgroundColor:
          frozenCellBackgroundColor ?? this.frozenCellBackgroundColor,
      resizerColor: resizerColor ?? this.resizerColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTableStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderRadius == other.borderRadius &&
          viewportWidth == other.viewportWidth &&
          viewportHeight == other.viewportHeight &&
          headerBackgroundColor == other.headerBackgroundColor &&
          headerHeight == other.headerHeight &&
          headerPadding == other.headerPadding &&
          footerBackgroundColor == other.footerBackgroundColor &&
          rowBackgroundColor == other.rowBackgroundColor &&
          rowAlternateBackgroundColor == other.rowAlternateBackgroundColor &&
          rowHoverColor == other.rowHoverColor &&
          rowSelectedColor == other.rowSelectedColor &&
          rowHeight == other.rowHeight &&
          cellPadding == other.cellPadding &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          outerBorderWidth == other.outerBorderWidth &&
          resizerHoverColor == other.resizerHoverColor &&
          resizerDragColor == other.resizerDragColor &&
          resizerThickness == other.resizerThickness &&
          headerTextStyle == other.headerTextStyle &&
          cellTextStyle == other.cellTextStyle &&
          frozenCellBackgroundColor == other.frozenCellBackgroundColor &&
          resizerColor == other.resizerColor &&
          foregroundColor == other.foregroundColor &&
          disabledForegroundColor == other.disabledForegroundColor;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderRadius,
    viewportWidth,
    viewportHeight,
    headerBackgroundColor,
    headerHeight,
    headerPadding,
    footerBackgroundColor,
    rowBackgroundColor,
    rowAlternateBackgroundColor,
    rowHoverColor,
    rowSelectedColor,
    rowHeight,
    cellPadding,
    borderColor,
    borderWidth,
    outerBorderWidth,
    resizerHoverColor,
    resizerDragColor,
    resizerThickness,
    headerTextStyle,
    cellTextStyle,
    frozenCellBackgroundColor,
    resizerColor,
    foregroundColor,
    disabledForegroundColor,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
