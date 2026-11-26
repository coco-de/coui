/// Per-instance style for `Fieldset`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/fieldset/fieldset_variant.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Fieldset` should render.
///
/// `CoreFieldsetStyle` carries every chrome / dimensional override for
/// the fieldset container (padding / fieldSpacing / border / radius /
/// colours) plus the nested legend and description text style slots and
/// the two gaps that set the header apart from the fields — Epic #1302's
/// single composite-style rule.
///
/// Three default tables feed the chain from below:
///
/// * [defaultsByVariant] — the box a variant draws (fill, edge, corner,
///   inner padding). `plain` draws none.
/// * [defaultsBySize] — the legend typography rung a size reads at.
/// * the `static const default*` fields — everything that does not depend
///   on either (field spacing, legend inset, description, header gaps).
///
/// ```text
/// defaultsByVariant[variant] + defaultsBySize[size] + default*
///   → CoreFieldsetTheme.style                       // 프로젝트 공통
///   → CoreFieldsetTheme.variantStyles[variant]      // 변형별 프로젝트 공통
///   → parent component slot override
///   → widget.fieldsetStyle                          // 인스턴스별
/// ```
@immutable
class CoreFieldsetStyle implements CoreStyle<CoreFieldsetStyle> {
  /// Creates a [CoreFieldsetStyle].
  const CoreFieldsetStyle({
    this.padding,
    this.fieldSpacing,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.borderColor,
    this.legendPadding,
    this.legendTextStyle,
    this.disabledLegendColor,
    this.descriptionTextStyle,
    this.legendDescriptionGapStyle,
    this.headerFieldsGapStyle,
  });

  // ─── Design-system defaults (Phase 6f/6g) ──────────────────────
  // Both Flutter and Web resolvers read these constants — Flutter
  // converts via `.toValue()` / `scheme.resolve(...)`, Web via the
  // `core_to_css.dart` adapter extensions.

  /// Default inner padding of the boxed variants (`filled`, `outlined`).
  /// `plain` draws no box and takes no padding — see [defaultsByVariant].
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space16,
  );

  /// Default spacing between the fields inside the group (logical px).
  ///
  /// `space16`: the gap that keeps two label-less fields reading as one
  /// group. A form whose fields carry their own label and hint rows wants
  /// the full form row gap (`space24`) — state it through [fieldSpacing].
  /// The legend and the description are not counted here: they sit apart
  /// from the first field by [defaultHeaderFieldsGapStyle].
  static const double defaultFieldSpacing = CoreSpace.space16;

  /// Default outer border radius of the boxed variants — the `surface`
  /// role, the corner of a card or any large container that sits on the
  /// page.
  ///
  /// The fields inside are elements that sit in the container, not
  /// children that fill it, so they keep their own corner (`md` field:
  /// 10); the container does not derive from them. A field's corner is
  /// per size (6 to 16), and a fieldset wraps fields of any size, so no
  /// single field is concentric with it anyway. A caller override flows
  /// through [borderRadius] as every override does.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.surface,
  );

  /// Default outer border stroke width of the boxed variants (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default container background fill of `outlined` and `plain`.
  /// Token-less transparent sentinel (no fill) — both platforms emit it as
  /// transparent (`emitColor` inline on Web, `scheme.resolve(...).toValue()`
  /// on Flutter) so the single source-of-truth default reaches both
  /// renderers.
  static const CoreColor defaultBackgroundColor = .transparent;

  /// Default container background fill of `filled` — a faint panel tone,
  /// so the page-coloured fields inside read as raised inputs.
  static const CoreColor defaultFilledBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Default outer border stroke colour of the boxed variants. A tier
  /// lighter than the fields' own edge (`outline-variant`), so the
  /// container never reads stronger than what it holds.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default padding applied around the legend widget (logical px,
  /// pre-scaling). Zero: the legend starts on the same line as the fields
  /// below it. A caller who wants an inset states it through
  /// [legendPadding].
  static const CoreEdgeInsets defaultLegendPadding = CoreEdgeInsets.zero;

  /// Default description slot text style — the `bodySmall` role in
  /// `onSurfaceVariant`, the secondary tier under the legend. Token-backed
  /// (same rationale as [defaultLegendTextStyle]). Per-instance override
  /// flows through [descriptionTextStyle] (merged on top of this default).
  static const CoreTextStyle defaultDescriptionTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default gap between the legend and the description beneath it — a
  /// nested [CoreGapStyle] slot forwarded to the `Gap` widget that
  /// separates the two.
  static const CoreGapStyle defaultLegendDescriptionGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default gap between the header (legend, then description) and the
  /// first field — tighter than [defaultFieldSpacing], so the header reads
  /// as belonging to the fields under it rather than as one more row.
  static const CoreGapStyle defaultHeaderFieldsGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// The box each variant draws: fill, edge, corner and inner padding.
  ///
  /// * `filled` — the faint panel fill inside the hairline edge.
  /// * `outlined` — the same edge and corner, no fill.
  /// * `plain` — no box at all: no fill, no edge, no corner, no padding.
  ///
  /// Everything the variants share (field spacing, legend, description,
  /// header gaps) is a flat `default*` field above. A caller who states a
  /// field on `fieldsetStyle` wins over the row's value for it.
  static const Map<CoreFieldsetVariant, CoreFieldsetStyle> defaultsByVariant = {
    CoreFieldsetVariant.filled: CoreFieldsetStyle(
      padding: defaultPadding,
      borderRadius: defaultBorderRadius,
      borderWidth: defaultBorderWidth,
      backgroundColor: defaultFilledBackgroundColor,
      borderColor: defaultBorderColor,
    ),
    CoreFieldsetVariant.outlined: CoreFieldsetStyle(
      padding: defaultPadding,
      borderRadius: defaultBorderRadius,
      borderWidth: defaultBorderWidth,
      backgroundColor: defaultBackgroundColor,
      borderColor: defaultBorderColor,
    ),
    CoreFieldsetVariant.plain: CoreFieldsetStyle(
      padding: CoreEdgeInsets.zero,
      borderRadius: CoreBorderRadius.zero,
      borderWidth: CoreStrokeWidth.stroke0,
      backgroundColor: defaultBackgroundColor,
      borderColor: .transparent,
    ),
  };

  /// Default legend slot text style for the `md` rung (and the `xs` /
  /// `sm` rungs, which join it — see [defaultsBySize]) — token-backed
  /// reference to the `titleSmall` role (16px, semibold + 140% leading
  /// natively — Figma "❖ Fieldset" 2026-09 개정 introduced the `Size`
  /// axis, replacing the old flat `bodyMedium` + hand-overlaid
  /// semi-bold) with the `onSurface` colour. No `.copyWith` needed: the
  /// role itself is already bold, so this stays a pure token
  /// reference (`static const`, not `static final`).
  ///
  /// Named to mirror the [legendTextStyle] override field (1:1:1:1 —
  /// strip `default`, lower-case the first letter ⇒ `legendTextStyle`).
  static const CoreTextStyle defaultLegendTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleSmall,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default legend slot text style for the `lg` rung (and `xl` / `xl2`,
  /// which join it) — same shape as [defaultLegendTextStyle] but the
  /// `titleMedium` role (18px, semibold + 140% leading natively).
  static const CoreTextStyle defaultLegendTextStyleLarge = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The size-keyed legend typography ladder — `xs`/`sm`/`md` read at
  /// [defaultLegendTextStyle] (16px `titleSmall`), `lg`/`xl`/`xl2` at
  /// [defaultLegendTextStyleLarge] (18px `titleMedium`). Only `md`/`lg`
  /// are canvas-confirmed pivots; the rest extend to the nearest defined
  /// rung (mirrors `CoreFormLabelStyle.defaultsBySize`'s "extend
  /// down"/"extend up" convention — same shared six-tier
  /// `CoreComponentSize` scale, different split point since it comes
  /// from Fieldset's own canvas evidence).
  static const Map<CoreComponentSize, CoreFieldsetStyle> defaultsBySize = {
    CoreComponentSize.xs: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyle,
    ),
    CoreComponentSize.sm: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyle,
    ),
    CoreComponentSize.md: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyle,
    ),
    CoreComponentSize.lg: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyleLarge,
    ),
    CoreComponentSize.xl: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyleLarge,
    ),
    CoreComponentSize.xl2: CoreFieldsetStyle(
      legendTextStyle: defaultLegendTextStyleLarge,
    ),
  };

  /// The default size tier — `md`, matching the flat pre-ladder default.
  static const CoreComponentSize defaultSize = CoreComponentSize.md;

  /// Default disabled-state legend colour. `disabledContent` (not the
  /// `onSurfaceSubtle` text tier `TextField` / `TextArea` use for their
  /// disabled labels, one tier below the enabled label's
  /// `onSurfaceVariant`) — an
  /// explicit canvas-literal decision (2026-09-11), not an oversight:
  /// the legend is closer to a section heading than a field label, and
  /// the canvas states the graphics-only ink for it.
  static const CoreColor defaultDisabledLegendColor = CoreColor.token(
    CoreColors.disabledContent,
  );

  // ── Chrome (flat) ────────────────────────────

  /// Inner padding.
  final CoreEdgeInsets? padding;

  /// Spacing between child widgets within the fieldset (logical px).
  final double? fieldSpacing;

  /// Outer border radius.
  final CoreBorderRadius? borderRadius;

  /// Outer border stroke width (logical px).
  final double? borderWidth;

  /// Container background colour.
  final CoreColor? backgroundColor;

  /// Outer border stroke colour.
  final CoreColor? borderColor;

  /// Padding applied around the legend widget. `null` defers to
  /// [defaultLegendPadding].
  final CoreEdgeInsets? legendPadding;

  // ── Slot Styles (nested) ─────────────────────

  /// Legend text style override.
  final CoreTextStyle? legendTextStyle;

  /// Disabled-state legend colour override.
  /// `null` → [defaultDisabledLegendColor].
  final CoreColor? disabledLegendColor;

  /// Description text style override. `null` →
  /// [defaultDescriptionTextStyle].
  final CoreTextStyle? descriptionTextStyle;

  /// Gap between the legend and the description. `null` →
  /// [defaultLegendDescriptionGapStyle].
  final CoreGapStyle? legendDescriptionGapStyle;

  /// Gap between the header (legend, description) and the first field.
  /// `null` → [defaultHeaderFieldsGapStyle].
  final CoreGapStyle? headerFieldsGapStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreFieldsetStyle merge(CoreFieldsetStyle? other) {
    if (other == null) return this;
    return CoreFieldsetStyle(
      padding: other.padding ?? padding,
      fieldSpacing: other.fieldSpacing ?? fieldSpacing,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      legendPadding: other.legendPadding ?? legendPadding,
      legendTextStyle: _mergeText(legendTextStyle, other.legendTextStyle),
      disabledLegendColor: other.disabledLegendColor ?? disabledLegendColor,
      descriptionTextStyle: _mergeText(
        descriptionTextStyle,
        other.descriptionTextStyle,
      ),
      legendDescriptionGapStyle:
          legendDescriptionGapStyle?.merge(other.legendDescriptionGapStyle) ??
          other.legendDescriptionGapStyle,
      headerFieldsGapStyle:
          headerFieldsGapStyle?.merge(other.headerFieldsGapStyle) ??
          other.headerFieldsGapStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreFieldsetStyle copyWith({
    CoreEdgeInsets? padding,
    double? fieldSpacing,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreEdgeInsets? legendPadding,
    CoreTextStyle? legendTextStyle,
    CoreColor? disabledLegendColor,
    CoreTextStyle? descriptionTextStyle,
    CoreGapStyle? legendDescriptionGapStyle,
    CoreGapStyle? headerFieldsGapStyle,
  }) {
    return CoreFieldsetStyle(
      padding: padding ?? this.padding,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      legendPadding: legendPadding ?? this.legendPadding,
      legendTextStyle: legendTextStyle ?? this.legendTextStyle,
      disabledLegendColor: disabledLegendColor ?? this.disabledLegendColor,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      legendDescriptionGapStyle:
          legendDescriptionGapStyle ?? this.legendDescriptionGapStyle,
      headerFieldsGapStyle: headerFieldsGapStyle ?? this.headerFieldsGapStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFieldsetStyle &&
          runtimeType == other.runtimeType &&
          padding == other.padding &&
          fieldSpacing == other.fieldSpacing &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          legendPadding == other.legendPadding &&
          legendTextStyle == other.legendTextStyle &&
          disabledLegendColor == other.disabledLegendColor &&
          descriptionTextStyle == other.descriptionTextStyle &&
          legendDescriptionGapStyle == other.legendDescriptionGapStyle &&
          headerFieldsGapStyle == other.headerFieldsGapStyle;

  @override
  int get hashCode => Object.hash(
    padding,
    fieldSpacing,
    borderRadius,
    borderWidth,
    backgroundColor,
    borderColor,
    legendPadding,
    legendTextStyle,
    disabledLegendColor,
    descriptionTextStyle,
    legendDescriptionGapStyle,
    headerFieldsGapStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
