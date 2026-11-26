/// Per-instance style for `CodeDiff`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `CodeDiff` should render.
///
/// `CoreCodeDiffStyle` carries every chrome / dimensional / colour /
/// typography override flat, plus the nested text style slots for the
/// body / gutter text. Behavioural fields (`showLineNumbers`) stay flat
/// on the widget / contract.
///
/// **Geometry — the 21px grid.** Body and gutter text are the monospace
/// code roles (`codeMd` 13 / `codeSm` 12), both on one fixed 21px line box
/// (`CoreLineBox.px21`); the row ([defaultLinePadding]) and the gutter
/// ([defaultLineNumberPadding]) add no vertical padding, so every row is
/// exactly 21px tall and rows abut. Horizontally a row starts 12px in
/// ([defaultLinePadding]), then the gutter cell ([defaultLineNumberWidth],
/// 40px = a 28px digit column + a 12px gap) puts the `+ ` / `- ` prefix at
/// x = 12 + 28 + 12 = 52.
///
/// **Colour — opaque bands.** An added / removed row is a solid band: its
/// face is [addedBackgroundColor] / [removedBackgroundColor] (the
/// `successContainer` / `errorContainer` tokens), and the `+ ` / `- ` prefix
/// and the gutter number on that band are [addedForegroundColor] /
/// [removedForegroundColor] (`onSuccessContainer` / `onErrorContainer`). The
/// diff text itself keeps the body ink ([unchangedTextStyle]'s colour,
/// `onSurface`) on every row, so a band never recolours code. A plain row has
/// no band and its gutter number is [lineNumberColor]. No colour in this
/// style is dimmed by an alpha: hierarchy is carried by the token chosen.
///
/// Every field follows the 1:1:1:1 rule — field : `defaultX` constant :
/// platform style emit : usage. A null field falls back to its matching
/// `defaultX` design-system constant at resolve time, so both Flutter
/// and Web resolvers read `merged.X ?? CoreCodeDiffStyle.defaultX`.
///
/// ```text
/// design system default (CoreCodeDiffStyle.defaultX)
///   → CoreCodeDiffTheme.style                       // 프로젝트 공통
///   → widget.codeDiffStyle                          // 인스턴스별
/// ```
@immutable
class CoreCodeDiffStyle implements CoreStyle<CoreCodeDiffStyle> {
  /// Creates a [CoreCodeDiffStyle].
  const CoreCodeDiffStyle({
    this.cornerRadius,
    this.borderWidth,
    this.prefixFontWeight,
    this.surfaceColor,
    this.outlineColor,
    this.addedBackgroundColor,
    this.addedForegroundColor,
    this.removedBackgroundColor,
    this.removedForegroundColor,
    @Deprecated(
      'Use addedBackgroundColor (the band) and addedForegroundColor (the '
      'prefix and gutter number) instead (since 0.162) — the band is now an '
      'opaque container token, so one colour can no longer be both the tint '
      'and the ink.',
    )
    this.addedColor,
    @Deprecated(
      'Use removedBackgroundColor (the band) and removedForegroundColor (the '
      'prefix and gutter number) instead (since 0.162) — the band is now an '
      'opaque container token, so one colour can no longer be both the tint '
      'and the ink.',
    )
    this.removedColor,
    this.unchangedTextStyle,
    this.lineNumberColor,
    @Deprecated(
      'Use addedBackgroundColor / removedBackgroundColor instead (since 0.162) '
      '— a band is an opaque container token, not success / error at a tint '
      'alpha.',
    )
    this.rowTintAlpha,
    @Deprecated(
      'Unused (since 0.162) — the gutter number is an opaque token: '
      'lineNumberColor on a plain row, addedForegroundColor / '
      'removedForegroundColor on a band. Hierarchy is the token, not an '
      'alpha.',
    )
    this.lineNumberAlpha,
    this.linePadding,
    this.lineNumberPadding,
    this.lineNumberWidth,
    this.bodyTypography,
    this.gutterTypography,
    this.bodyTextStyle,
    this.gutterTextStyle,
  });

  // ─── Design-system defaults ────────────────────────────────────
  // Both Flutter and Web read these constants — Flutter resolves
  // via `theme.colorScheme` / `resolveTypographyRole(...)`, Web via
  // the `core_to_css.dart` adapter extensions. Each constant is the
  // fallback for its matching nullable override field above.

  /// Default border-radius of the outer container — the `panel` role (12).
  static const CoreBorderRadius defaultCornerRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default border stroke width of the outer container (logical px) —
  /// **zero**. The block is told apart from the page by its
  /// [defaultSurfaceColor] face, not by an edge, so there is no border to
  /// stroke. Paired with the transparent [defaultOutlineColor]: a width of 0
  /// alone is a hairline on Flutter (`Border.all` with no colour guard) and
  /// nothing on Web, while a transparent colour collapses the width on both.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke0;

  /// Default font weight applied to the `+ ` / `- ` / `  ` prefix span.
  static const int defaultPrefixFontWeight = CoreFontWeight.bold;

  /// Default outer container background colour (`surfaceContainerLow`) — the
  /// face the block is told apart by now that it has no border.
  static const CoreColor defaultSurfaceColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Default outer container border colour — **transparent**, the pair to
  /// [defaultBorderWidth] being zero. A caller who raises [borderWidth] must
  /// also state an [outlineColor], or the border stays invisible.
  static const CoreColor defaultOutlineColor = CoreColor.transparent;

  /// Default band face of an added row (`successContainer`) — opaque, the
  /// whole row is painted with it. The `+ ` prefix and the gutter number on
  /// the band read [defaultAddedForegroundColor].
  static const CoreColor defaultAddedBackgroundColor = CoreColor.token(
    CoreColors.successContainer,
  );

  /// Default ink of an added row's `+ ` prefix and gutter number
  /// (`onSuccessContainer`) — the colour drawn on
  /// [defaultAddedBackgroundColor].
  static const CoreColor defaultAddedForegroundColor = CoreColor.token(
    CoreColors.onSuccessContainer,
  );

  /// Default band face of a removed row (`errorContainer`) — opaque, the
  /// whole row is painted with it. The `- ` prefix and the gutter number on
  /// the band read [defaultRemovedForegroundColor].
  static const CoreColor defaultRemovedBackgroundColor = CoreColor.token(
    CoreColors.errorContainer,
  );

  /// Default ink of a removed row's `- ` prefix and gutter number
  /// (`onErrorContainer`) — the colour drawn on
  /// [defaultRemovedBackgroundColor].
  static const CoreColor defaultRemovedForegroundColor = CoreColor.token(
    CoreColors.onErrorContainer,
  );

  /// Retired default of [addedColor] (`success`). Read by no platform — the
  /// band is [defaultAddedBackgroundColor] and its ink
  /// [defaultAddedForegroundColor].
  @Deprecated(
    'Use defaultAddedBackgroundColor / defaultAddedForegroundColor instead '
    '(since 0.162) — the band is now an opaque container token, so one colour '
    'can no longer be both the tint and the ink.',
  )
  static const CoreColor defaultAddedColor = CoreColor.token(
    CoreColors.success,
  );

  /// Retired default of [removedColor] (`error`). Read by no platform — the
  /// band is [defaultRemovedBackgroundColor] and its ink
  /// [defaultRemovedForegroundColor].
  @Deprecated(
    'Use defaultRemovedBackgroundColor / defaultRemovedForegroundColor '
    'instead (since 0.162) — the band is now an opaque container token, so '
    'one colour can no longer be both the tint and the ink.',
  )
  static const CoreColor defaultRemovedColor = CoreColor.token(
    CoreColors.error,
  );

  /// Default text style carrying the diff body ink — `onSurface`. It is the
  /// ink of the diff text on **every** row (added, removed and unchanged),
  /// and of an unchanged row's blank prefix: a band recolours the `+ ` / `- `
  /// prefix and the gutter number, never the code (sb8 — raw
  /// `unchangedTextColor` field replaced by the nested [CoreTextStyle] slot).
  static const CoreTextStyle defaultUnchangedTextStyle = CoreTextStyle(
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default text colour of the line-number gutter on a plain (unchanged)
  /// row — `onSurfaceVariant`, opaque. A band row's number reads
  /// [defaultAddedForegroundColor] / [defaultRemovedForegroundColor]
  /// instead; the subdued `onSurfaceVariant` is never drawn on a band.
  static const CoreColor defaultLineNumberColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Retired default of [rowTintAlpha] (0.15). Read by no platform — a band
  /// is an opaque container token, not success / error at an alpha.
  @Deprecated(
    'Use defaultAddedBackgroundColor / defaultRemovedBackgroundColor instead '
    '(since 0.162) — a band is an opaque container token, not success / '
    'error at a tint alpha.',
  )
  static const double defaultRowTintAlpha = 0.15;

  /// Retired default of [lineNumberAlpha] (0.5). Read by no platform — the
  /// gutter number is an opaque token, and hierarchy is the token chosen.
  @Deprecated(
    'Unused (since 0.162) — the gutter number is an opaque token: '
    'defaultLineNumberColor on a plain row, defaultAddedForegroundColor / '
    'defaultRemovedForegroundColor on a band. Hierarchy is the token, not an '
    'alpha.',
  )
  static const double defaultLineNumberAlpha = 0.5;

  /// Default padding inside each diff row — 12 logical px horizontal, no
  /// vertical padding. The row height is the code roles' 21px line box
  /// alone, so rows abut on the 21px grid.
  static const CoreEdgeInsets defaultLinePadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
  );

  /// Default padding around the line-number text — a 12 logical px gap on
  /// the end side (between the digit column and the `+ ` / `- ` prefix), no
  /// vertical padding. Directional: the gap sits on the side the code runs
  /// toward, so it follows the reading direction.
  static const CoreEdgeInsets defaultLineNumberPadding =
      CoreEdgeInsets.directional(end: CoreSpace.space12);

  /// Default width of the line-number gutter column (logical px,
  /// pre-scaling). This is the *total* cell width — the padding is inside
  /// it on both platforms — so 40 is a 28px digit column plus the 12px
  /// [defaultLineNumberPadding] gap, and the prefix starts at x = 52 with
  /// the row's 12px start padding. Three digits of `codeSm` (about 7.2px
  /// each) fit the 28px column; a longer number needs a wider
  /// [lineNumberWidth].
  static const double defaultLineNumberWidth = CoreSpace.space40;

  /// Default typography role for the diff body text —
  /// `CoreTypography.coui.codeMd` (13 / 21px line box, monospace). The
  /// `CoreTypography.coui.X` form rather than `CoreTextStyle.token(...)`:
  /// the Web emit finds the `text-code-md` class by identity against
  /// `CoreTypography.coui`. `static final` since record/class field access
  /// can't be const-eval'd; `CoreTypography.coui` itself is const so no
  /// runtime cost.
  static final CoreTextStyle defaultBodyTypography = CoreTypography.coui.codeMd;

  /// Default typography role for the line-number gutter —
  /// `CoreTypography.coui.codeSm` (12 / 21px line box, monospace), the same
  /// 21px line box as [defaultBodyTypography] so gutter and body share one
  /// row height.
  static final CoreTextStyle defaultGutterTypography =
      CoreTypography.coui.codeSm;

  // ── Chrome (flat) ────────────────────────────

  /// Outer container border-radius. Falls back to [defaultCornerRadius].
  final CoreBorderRadius? cornerRadius;

  /// Outer container border stroke width (logical px). Falls back to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Font weight applied to the `+ ` / `- ` / `  ` prefix span. Falls
  /// back to [defaultPrefixFontWeight].
  final int? prefixFontWeight;

  /// Outer container background colour. Falls back to
  /// [defaultSurfaceColor].
  final CoreColor? surfaceColor;

  /// Outer container border colour. Falls back to [defaultOutlineColor]
  /// (transparent — only visible once [borderWidth] is raised).
  final CoreColor? outlineColor;

  /// Band face of an added row — opaque, painted across the whole row. Falls
  /// back to [defaultAddedBackgroundColor].
  final CoreColor? addedBackgroundColor;

  /// Ink of an added row's `+ ` prefix and gutter number — the colour drawn
  /// on [addedBackgroundColor]. Falls back to [defaultAddedForegroundColor].
  final CoreColor? addedForegroundColor;

  /// Band face of a removed row — opaque, painted across the whole row. Falls
  /// back to [defaultRemovedBackgroundColor].
  final CoreColor? removedBackgroundColor;

  /// Ink of a removed row's `- ` prefix and gutter number — the colour drawn
  /// on [removedBackgroundColor]. Falls back to
  /// [defaultRemovedForegroundColor].
  final CoreColor? removedForegroundColor;

  /// No longer used — setting it has no effect on either platform. Set
  /// [addedBackgroundColor] (the band) and [addedForegroundColor] (the
  /// prefix and gutter number) instead.
  @Deprecated(
    'Use addedBackgroundColor (the band) and addedForegroundColor (the '
    'prefix and gutter number) instead (since 0.162) — the band is now an '
    'opaque container token, so one colour can no longer be both the tint '
    'and the ink.',
  )
  final CoreColor? addedColor;

  /// No longer used — setting it has no effect on either platform. Set
  /// [removedBackgroundColor] (the band) and [removedForegroundColor] (the
  /// prefix and gutter number) instead.
  @Deprecated(
    'Use removedBackgroundColor (the band) and removedForegroundColor (the '
    'prefix and gutter number) instead (since 0.162) — the band is now an '
    'opaque container token, so one colour can no longer be both the tint '
    'and the ink.',
  )
  final CoreColor? removedColor;

  /// Text style carrying the diff body ink. Its colour is the ink of the diff
  /// text on every row — added, removed and unchanged — and of an unchanged
  /// row's blank prefix; a band never recolours code (sb8 — raw
  /// `unchangedTextColor` field removed). Falls back to
  /// [defaultUnchangedTextStyle].
  final CoreTextStyle? unchangedTextStyle;

  /// Line-number gutter text colour on a plain (unchanged) row — opaque. A
  /// band row's number reads [addedForegroundColor] / [removedForegroundColor]
  /// instead. Falls back to [defaultLineNumberColor].
  final CoreColor? lineNumberColor;

  /// No longer used — setting it has no effect on either platform. A band
  /// is [addedBackgroundColor] / [removedBackgroundColor], an opaque
  /// container token, not success / error at a tint alpha.
  @Deprecated(
    'Use addedBackgroundColor / removedBackgroundColor instead (since 0.162) '
    '— a band is an opaque container token, not success / error at a tint '
    'alpha.',
  )
  final double? rowTintAlpha;

  /// No longer used — setting it has no effect on either platform. The
  /// gutter number is an opaque token ([lineNumberColor] /
  /// [addedForegroundColor] / [removedForegroundColor]); hierarchy is the
  /// token chosen, not an alpha.
  @Deprecated(
    'Unused (since 0.162) — the gutter number is an opaque token: '
    'lineNumberColor on a plain row, addedForegroundColor / '
    'removedForegroundColor on a band. Hierarchy is the token, not an '
    'alpha.',
  )
  final double? lineNumberAlpha;

  /// Padding inside each diff row. Falls back to [defaultLinePadding].
  final CoreEdgeInsets? linePadding;

  /// Padding around the line-number text. Falls back to
  /// [defaultLineNumberPadding].
  final CoreEdgeInsets? lineNumberPadding;

  /// Total width of the line-number gutter cell, padding included (logical
  /// px, pre-scaling). Falls back to [defaultLineNumberWidth].
  final double? lineNumberWidth;

  /// Typography role for the diff body text. Falls back to
  /// [defaultBodyTypography].
  final CoreTextStyle? bodyTypography;

  /// Typography role for the line-number gutter text. Falls back to
  /// [defaultGutterTypography].
  final CoreTextStyle? gutterTypography;

  // ── Slot Styles (nested) ─────────────────────

  /// Body text style override (the diff content).
  ///
  /// **Deliberately has no `default*` — this is the overlay half of a
  /// pair whose other half already carries the default.** The typography
  /// comes from [bodyTypography] / [defaultBodyTypography]; this slot is
  /// merged *on top* of whatever that resolved to. A constant would
  /// therefore outrank the role a caller selected through
  /// [bodyTypography] — set the role to something larger and the default
  /// overlay's own size would win it back. On Web it would also move the
  /// typography off its class: the resolver adds
  /// `bodyTextStyle.toInlineCss()` only inside
  /// `if (bodyTextStyle != null)`, so a non-null default emits an inline
  /// overlay on every diff row and shadows the `text-{role}` class that
  /// carries the role today.
  final CoreTextStyle? bodyTextStyle;

  /// Line-number gutter text style override.
  ///
  /// **Deliberately has no `default*` — same pairing as [bodyTextStyle]**,
  /// against [gutterTypography] / [defaultGutterTypography]. Both
  /// platforms consume it the same way (Flutter merges it over the
  /// resolved role, Web emits it inline only when present), so a constant
  /// would both outrank a caller-chosen gutter role and put inline
  /// typography on every gutter cell.
  final CoreTextStyle? gutterTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text styles are
  /// merged recursively.
  @override
  CoreCodeDiffStyle merge(CoreCodeDiffStyle? other) {
    if (other == null) return this;
    return CoreCodeDiffStyle(
      cornerRadius: other.cornerRadius ?? cornerRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      prefixFontWeight: other.prefixFontWeight ?? prefixFontWeight,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      outlineColor: other.outlineColor ?? outlineColor,
      addedBackgroundColor: other.addedBackgroundColor ?? addedBackgroundColor,
      addedForegroundColor: other.addedForegroundColor ?? addedForegroundColor,
      removedBackgroundColor:
          other.removedBackgroundColor ?? removedBackgroundColor,
      removedForegroundColor:
          other.removedForegroundColor ?? removedForegroundColor,
      addedColor: other.addedColor ?? addedColor,
      removedColor: other.removedColor ?? removedColor,
      unchangedTextStyle: _mergeText(
        unchangedTextStyle,
        other.unchangedTextStyle,
      ),
      lineNumberColor: other.lineNumberColor ?? lineNumberColor,
      rowTintAlpha: other.rowTintAlpha ?? rowTintAlpha,
      lineNumberAlpha: other.lineNumberAlpha ?? lineNumberAlpha,
      linePadding: other.linePadding ?? linePadding,
      lineNumberPadding: other.lineNumberPadding ?? lineNumberPadding,
      lineNumberWidth: other.lineNumberWidth ?? lineNumberWidth,
      bodyTypography: other.bodyTypography ?? bodyTypography,
      gutterTypography: other.gutterTypography ?? gutterTypography,
      bodyTextStyle: _mergeText(bodyTextStyle, other.bodyTextStyle),
      gutterTextStyle: _mergeText(gutterTextStyle, other.gutterTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCodeDiffStyle copyWith({
    CoreBorderRadius? cornerRadius,
    double? borderWidth,
    int? prefixFontWeight,
    CoreColor? surfaceColor,
    CoreColor? outlineColor,
    CoreColor? addedBackgroundColor,
    CoreColor? addedForegroundColor,
    CoreColor? removedBackgroundColor,
    CoreColor? removedForegroundColor,
    CoreColor? addedColor,
    CoreColor? removedColor,
    CoreTextStyle? unchangedTextStyle,
    CoreColor? lineNumberColor,
    double? rowTintAlpha,
    double? lineNumberAlpha,
    CoreEdgeInsets? linePadding,
    CoreEdgeInsets? lineNumberPadding,
    double? lineNumberWidth,
    CoreTextStyle? bodyTypography,
    CoreTextStyle? gutterTypography,
    CoreTextStyle? bodyTextStyle,
    CoreTextStyle? gutterTextStyle,
  }) {
    return CoreCodeDiffStyle(
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      prefixFontWeight: prefixFontWeight ?? this.prefixFontWeight,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      outlineColor: outlineColor ?? this.outlineColor,
      addedBackgroundColor: addedBackgroundColor ?? this.addedBackgroundColor,
      addedForegroundColor: addedForegroundColor ?? this.addedForegroundColor,
      removedBackgroundColor:
          removedBackgroundColor ?? this.removedBackgroundColor,
      removedForegroundColor:
          removedForegroundColor ?? this.removedForegroundColor,
      addedColor: addedColor ?? this.addedColor,
      removedColor: removedColor ?? this.removedColor,
      unchangedTextStyle: unchangedTextStyle ?? this.unchangedTextStyle,
      lineNumberColor: lineNumberColor ?? this.lineNumberColor,
      rowTintAlpha: rowTintAlpha ?? this.rowTintAlpha,
      lineNumberAlpha: lineNumberAlpha ?? this.lineNumberAlpha,
      linePadding: linePadding ?? this.linePadding,
      lineNumberPadding: lineNumberPadding ?? this.lineNumberPadding,
      lineNumberWidth: lineNumberWidth ?? this.lineNumberWidth,
      bodyTypography: bodyTypography ?? this.bodyTypography,
      gutterTypography: gutterTypography ?? this.gutterTypography,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      gutterTextStyle: gutterTextStyle ?? this.gutterTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCodeDiffStyle &&
          runtimeType == other.runtimeType &&
          cornerRadius == other.cornerRadius &&
          borderWidth == other.borderWidth &&
          prefixFontWeight == other.prefixFontWeight &&
          surfaceColor == other.surfaceColor &&
          outlineColor == other.outlineColor &&
          addedBackgroundColor == other.addedBackgroundColor &&
          addedForegroundColor == other.addedForegroundColor &&
          removedBackgroundColor == other.removedBackgroundColor &&
          removedForegroundColor == other.removedForegroundColor &&
          addedColor == other.addedColor &&
          removedColor == other.removedColor &&
          unchangedTextStyle == other.unchangedTextStyle &&
          lineNumberColor == other.lineNumberColor &&
          rowTintAlpha == other.rowTintAlpha &&
          lineNumberAlpha == other.lineNumberAlpha &&
          linePadding == other.linePadding &&
          lineNumberPadding == other.lineNumberPadding &&
          lineNumberWidth == other.lineNumberWidth &&
          bodyTypography == other.bodyTypography &&
          gutterTypography == other.gutterTypography &&
          bodyTextStyle == other.bodyTextStyle &&
          gutterTextStyle == other.gutterTextStyle;

  @override
  int get hashCode => Object.hashAll([
    cornerRadius,
    borderWidth,
    prefixFontWeight,
    surfaceColor,
    outlineColor,
    addedBackgroundColor,
    addedForegroundColor,
    removedBackgroundColor,
    removedForegroundColor,
    addedColor,
    removedColor,
    unchangedTextStyle,
    lineNumberColor,
    rowTintAlpha,
    lineNumberAlpha,
    linePadding,
    lineNumberPadding,
    lineNumberWidth,
    bodyTypography,
    gutterTypography,
    bodyTextStyle,
    gutterTextStyle,
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
