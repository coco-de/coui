/// Per-instance style for `Timeline`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Timeline` should render.
///
/// `CoreTimelineStyle` carries chrome flat fields for the dot
/// indicator + connector line, plus nested timestamp / title /
/// description text-style slots.
///
/// **Semantic enums (`orientation`) live on the widget, not on this
/// style** (Epic #1302 원칙 6/7).
///
/// ```text
/// design system default
///   → CoreTimelineTheme.style
///   → parent component slot override
///   → widget.timelineStyle
/// ```
@immutable
class CoreTimelineStyle implements CoreStyle<CoreTimelineStyle> {
  /// Creates a [CoreTimelineStyle].
  const CoreTimelineStyle({
    this.dotColor,
    this.dotSize,
    this.dotCornerRadius,
    this.dotBorderColor,
    this.dotBorderWidth,
    this.dotTopMargin,
    this.connectorColor,
    this.connectorThickness,
    this.connectorSpacing,
    this.rowSpacing,
    this.columnGapStyle,
    this.timeColumnWidth,
    this.titlePadding,
    this.contentTopGapStyle,
    this.timestampTextStyle,
    this.titleTextStyle,
    this.descriptionTextStyle,
  });

  // ─── Design-system defaults (Phase 6g batch 39) ───────────────────
  // Variant-independent dimensional defaults live as static const here
  // so the Flutter and Web resolvers share one source of truth instead
  // of file-local `_k*` constants. All values are single-axis logical
  // px scalars (raw `double` allowed per verify.md 7-6 (u-1)).

  /// Default width of the timestamp column (`space120` = 120px).
  static const double defaultTimeColumnWidth = CoreSpace.space120;

  /// Default top margin of the dot indicator (5 logical px) — the value
  /// that seats the dot's centre on the centre of the title's first line:
  /// `(title line box − [defaultDotSize]) / 2`.
  ///
  /// The title is set in `labelLarge` (14 × 140 % = 19.6), so the exact
  /// centring margin is 4.8; it is held to a whole logical px, which is
  /// also what the canvas draws. The spacing ladder has no 5 and this is
  /// not a spacing step — it is a number derived from the title's line
  /// box and the dot — so it is written as that number rather than as a
  /// new token. A test derives it from the `labelLarge` role and the dot
  /// size, so changing either without revisiting this value fails there.
  static const double defaultDotTopMargin = 5;

  /// Default padding of the item title — none. The title starts on the
  /// content column's start edge; the gap to the marker column is the
  /// column gap ([defaultColumnGapStyle]), not an inset on the title.
  static const CoreEdgeInsets defaultTitlePadding = CoreEdgeInsets.zero;

  /// Default vertical gap between the title and the description
  /// (`space2` = 2px). Nested [CoreGapStyle] slot — forwarded straight
  /// to `Gap(gapStyle: …)` (Flutter) / consumed as inline rem (Web)
  /// per Epic #1659 nested-slot pattern (1-off Gap between two named
  /// siblings inside the content column).
  static const CoreGapStyle defaultContentTopGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default spacing between the connector line and the dots at its two ends
  /// (`space4` = 4px): the line starts this far below its own dot and
  /// stops this far above the next item's dot. Both ends are anchored to
  /// the dots, so the line's length follows the dot size, the dot top
  /// margin and the row spacing without any of them being restated here.
  static const double defaultConnectorSpacing = CoreSpace.space4;

  /// Default horizontal gap between the timestamp / dot / content
  /// columns (`space16` = 16px). Nested [CoreGapStyle] slot — forwarded
  /// straight to `Gap(gapStyle: …)` (Flutter) / consumed as inline rem
  /// (Web) per Epic #1659 nested-slot pattern (1-off Gap between
  /// named siblings in the Row).
  static const CoreGapStyle defaultColumnGapStyle = CoreGapStyle(
    size: CoreSpace.space16,
  );

  /// Default vertical spacing between adjacent timeline rows
  /// (`space16` = 16px). Stays a flat double — the rows wrapper consumes
  /// this scalar via native `Column.spacing` (Flutter) / inline `gap`
  /// rem (Web). Epic #1659 N-sibling uniform distribution pattern.
  static const double defaultRowSpacing = CoreSpace.space16;

  /// Default dot indicator diameter (`space10` = 10px). The dot column is
  /// as wide as the dot (both platforms size it from the dot), so this
  /// is also the width of the marker column.
  static const double defaultDotSize = CoreSpace.space10;

  /// Default connector line thickness (`stroke2` = 2px).
  static const double defaultConnectorThickness = CoreStrokeWidth.stroke2;

  /// Default dot indicator corner radius — circular pill so the dot
  /// renders as a perfect circle regardless of the configured corner
  /// radius.
  static const double defaultDotCornerRadius = 9999;

  /// Default dot indicator fill colour.
  static const CoreColor defaultDotColor = CoreColor.token(CoreColors.primary);

  /// Default connector line colour — the quiet `outlineVariant` boundary
  /// tone, so the line recedes behind the primary-coloured dots and the
  /// content stands in front of it.
  static const CoreColor defaultConnectorColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default timestamp text style — `bodySmall` slot with the muted
  /// `onSurfaceVariant` colour layered on.
  static const CoreTextStyle defaultTimestampTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default item title text style — the `labelLarge` role with the
  /// `onSurface` colour. The role alone states the title's size, weight,
  /// line height and tracking; nothing is laid over it, so the title
  /// stays on the role's optical curve.
  static const CoreTextStyle defaultTitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default item description text style — `bodySmall` slot with the
  /// muted `onSurfaceVariant` colour.
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  // ── Dot chrome (flat) ────────────────────────

  /// Dot indicator fill colour.
  final CoreColor? dotColor;

  /// Dot indicator diameter (logical px).
  final double? dotSize;

  /// Dot indicator corner radius (logical px). `9999` = circle.
  final double? dotCornerRadius;

  // The dot's ring is opt-in, and the two fields below are how a caller
  // opts in — so neither has a `default*`. Both platforms gate the
  // stroke on the PAIR being present:
  //
  //   · Flutter — `border: dotBorderColor != null && dotBorderWidth != null
  //     ? .all(…) : null`, and a null `BoxDecoration.border` paints
  //     nothing.
  //   · Web — the `border` entry is only written into the dot's inline
  //     bundle inside that same `&&`, so no declaration is emitted.
  //
  // Defaulting BOTH draws a ring around every dot in every timeline.
  // Defaulting ONE is worse than leaving it alone: the `&&` still fails,
  // so the value can never take effect on its own, and the class would
  // then claim a default that is unreachable by construction. The dot's
  // own fill and radius are defaulted ([defaultDotColor],
  // [defaultDotCornerRadius]) precisely because those are always drawn.

  /// Dot indicator border stroke colour. Paired with [dotBorderWidth] —
  /// the ring is drawn only when BOTH are set; see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** The ring
  /// is opt-in and gated on the PAIR: Flutter `border: dotBorderColor !=
  /// null && dotBorderWidth != null ? .all(…) : null` (a null
  /// BoxDecoration.border paints nothing), Web writes the `border` entry
  /// only inside that same `&&`. Defaulting both draws a ring around
  /// every dot in every timeline. Defaulting only this one is worse than
  /// leaving it alone — the `&&` still fails, so the value can never take
  /// effect on its own and the class would advertise a default
  /// unreachable by construction.
  final CoreColor? dotBorderColor;

  /// Dot indicator border stroke width (logical px). Paired with
  /// [dotBorderColor]; see the note above.
  ///
  /// **Deliberately has no `default*` — absence is the design.** Other
  /// half of the same `&&` gate; identical reasoning.
  final double? dotBorderWidth;

  /// Dot indicator top margin (logical px) — lines the dot up with the
  /// first line of the title. See [defaultDotTopMargin] for how the
  /// default is derived.
  final double? dotTopMargin;

  // ── Connector chrome (flat) ──────────────────

  /// Connector line colour.
  final CoreColor? connectorColor;

  /// Connector line thickness (logical px).
  final double? connectorThickness;

  /// Spacing between the connector line and the dot at each of its ends
  /// (logical px) — the line starts this far below its own dot and stops
  /// this far above the next item's dot, so a larger value makes the line
  /// shorter. See [defaultConnectorSpacing].
  final double? connectorSpacing;

  /// Vertical spacing between adjacent timeline rows / blocks
  /// (logical px). Stays a flat double — the rows wrapper consumes this
  /// scalar via native `Column.spacing` (Flutter) / inline `gap` rem
  /// (Web) per Epic #1659 N-sibling uniform distribution pattern.
  final double? rowSpacing;

  /// Horizontal gap between the timestamp, dot and content columns.
  ///
  /// Forwarded straight to `Gap(gapStyle: …)` (Flutter) / consumed as
  /// inline rem (Web) per Epic #1659 nested-slot pattern (1-off Gap
  /// between named siblings inside the Row).
  final CoreGapStyle? columnGapStyle;

  // ── Layout chrome (flat) ─────────────────────

  /// Width of the timestamp column (logical px).
  final double? timeColumnWidth;

  /// Padding of the item title. Falls back to [defaultTitlePadding].
  final CoreEdgeInsets? titlePadding;

  /// Vertical gap between the title and the description.
  ///
  /// Forwarded straight to `Gap(gapStyle: …)` (Flutter) / consumed as
  /// inline rem (Web) per Epic #1659 nested-slot pattern (1-off Gap
  /// between named siblings inside the content column).
  final CoreGapStyle? contentTopGapStyle;

  // ── Slot Styles (nested) ─────────────────────

  /// Timestamp text style override. `null` defers to
  /// [defaultTimestampTextStyle].
  final CoreTextStyle? timestampTextStyle;

  /// Item title text style override. `null` defers to
  /// [defaultTitleTextStyle].
  final CoreTextStyle? titleTextStyle;

  /// Item description text style override. `null` defers to
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreTimelineStyle merge(CoreTimelineStyle? other) {
    if (other == null) return this;
    return CoreTimelineStyle(
      dotColor: other.dotColor ?? dotColor,
      dotSize: other.dotSize ?? dotSize,
      dotCornerRadius: other.dotCornerRadius ?? dotCornerRadius,
      dotBorderColor: other.dotBorderColor ?? dotBorderColor,
      dotBorderWidth: other.dotBorderWidth ?? dotBorderWidth,
      dotTopMargin: other.dotTopMargin ?? dotTopMargin,
      connectorColor: other.connectorColor ?? connectorColor,
      connectorThickness: other.connectorThickness ?? connectorThickness,
      connectorSpacing: other.connectorSpacing ?? connectorSpacing,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      columnGapStyle: _mergeGap(columnGapStyle, other.columnGapStyle),
      timeColumnWidth: other.timeColumnWidth ?? timeColumnWidth,
      titlePadding: other.titlePadding ?? titlePadding,
      contentTopGapStyle: _mergeGap(
        contentTopGapStyle,
        other.contentTopGapStyle,
      ),
      timestampTextStyle: _mergeText(
        timestampTextStyle,
        other.timestampTextStyle,
      ),
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreTimelineStyle copyWith({
    CoreColor? dotColor,
    double? dotSize,
    double? dotCornerRadius,
    CoreColor? dotBorderColor,
    double? dotBorderWidth,
    double? dotTopMargin,
    CoreColor? connectorColor,
    double? connectorThickness,
    double? connectorSpacing,
    double? rowSpacing,
    CoreGapStyle? columnGapStyle,
    double? timeColumnWidth,
    CoreEdgeInsets? titlePadding,
    CoreGapStyle? contentTopGapStyle,
    CoreTextStyle? timestampTextStyle,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? descriptionTextStyle,
  }) {
    return CoreTimelineStyle(
      dotColor: dotColor ?? this.dotColor,
      dotSize: dotSize ?? this.dotSize,
      dotCornerRadius: dotCornerRadius ?? this.dotCornerRadius,
      dotBorderColor: dotBorderColor ?? this.dotBorderColor,
      dotBorderWidth: dotBorderWidth ?? this.dotBorderWidth,
      dotTopMargin: dotTopMargin ?? this.dotTopMargin,
      connectorColor: connectorColor ?? this.connectorColor,
      connectorThickness: connectorThickness ?? this.connectorThickness,
      connectorSpacing: connectorSpacing ?? this.connectorSpacing,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      columnGapStyle: columnGapStyle ?? this.columnGapStyle,
      timeColumnWidth: timeColumnWidth ?? this.timeColumnWidth,
      titlePadding: titlePadding ?? this.titlePadding,
      contentTopGapStyle: contentTopGapStyle ?? this.contentTopGapStyle,
      timestampTextStyle: timestampTextStyle ?? this.timestampTextStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTimelineStyle &&
          runtimeType == other.runtimeType &&
          dotColor == other.dotColor &&
          dotSize == other.dotSize &&
          dotCornerRadius == other.dotCornerRadius &&
          dotBorderColor == other.dotBorderColor &&
          dotBorderWidth == other.dotBorderWidth &&
          dotTopMargin == other.dotTopMargin &&
          connectorColor == other.connectorColor &&
          connectorThickness == other.connectorThickness &&
          connectorSpacing == other.connectorSpacing &&
          rowSpacing == other.rowSpacing &&
          columnGapStyle == other.columnGapStyle &&
          timeColumnWidth == other.timeColumnWidth &&
          titlePadding == other.titlePadding &&
          contentTopGapStyle == other.contentTopGapStyle &&
          timestampTextStyle == other.timestampTextStyle &&
          titleTextStyle == other.titleTextStyle &&
          descriptionTextStyle == other.descriptionTextStyle;

  @override
  int get hashCode => Object.hashAll([
    dotColor,
    dotSize,
    dotCornerRadius,
    dotBorderColor,
    dotBorderWidth,
    dotTopMargin,
    connectorColor,
    connectorThickness,
    connectorSpacing,
    rowSpacing,
    columnGapStyle,
    timeColumnWidth,
    titlePadding,
    contentTopGapStyle,
    timestampTextStyle,
    titleTextStyle,
    descriptionTextStyle,
  ]);

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(CoreGapStyle? base, CoreGapStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
