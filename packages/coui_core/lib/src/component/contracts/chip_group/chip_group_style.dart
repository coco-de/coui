/// Per-instance style for `ChipGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ChipGroup` should render.
///
/// `CoreChipGroupStyle` carries panel chrome (scroll-fade) overrides
/// as flat fields, plus nested `CoreTextStyle` for the title and
/// selection-hint slots and nested `CoreGapStyle`s for the title-to-hint
/// and header-to-chips spacer slots.
///
/// Semantic enums (`layout` / `selectionMode`) live on the widget, not
/// on this style (Epic #1302 원칙 6/7). All 시각 chrome — including
/// composite-layout gaps (`itemSpacing` / `rowSpacing` /
/// `titleHintGapStyle` / `titleGapStyle`) — lives here.
///
/// ```text
/// design system default
///   → CoreChipGroupTheme.style                     // 프로젝트 공통
///   → widget.chipGroupStyle                        // 인스턴스별
/// ```
@immutable
class CoreChipGroupStyle implements CoreStyle<CoreChipGroupStyle> {
  /// Creates a [CoreChipGroupStyle].
  const CoreChipGroupStyle({
    this.fadeWidth,
    this.fadeColor,
    this.itemSpacing,
    this.rowSpacing,
    this.titleHintGapStyle,
    this.titleGapStyle,
    this.titleTextStyle,
    this.selectionHintTextStyle,
  });

  // ── Panel chrome (flat) ──────────────────────

  /// Edge fade width in scroll layout (logical px, pre-scaling).
  final double? fadeWidth;

  /// Edge fade colour override (scroll layout).
  final CoreColor? fadeColor;

  /// Horizontal gap between sibling chips (logical px, pre-scaling),
  /// forwarded to `Wrap.spacing` / `Row.spacing` (Flutter) and
  /// `column-gap` (Web). Native paint-API scalar — not a `Gap`.
  final double? itemSpacing;

  /// Vertical gap between rows in wrap layout (logical px, pre-scaling),
  /// forwarded to `Wrap.runSpacing` (Flutter) / `row-gap` (Web).
  final double? rowSpacing;

  // ── Slot Styles (nested) ─────────────────────

  /// Gap between the title line and the selection-hint line in the header,
  /// passed to `Gap(gapStyle: …)`. Drawn only when both are present.
  final CoreGapStyle? titleHintGapStyle;

  /// Gap between the header (title and hint) and the chips, passed to
  /// `Gap(gapStyle: …)`.
  final CoreGapStyle? titleGapStyle;

  /// Title text style override (color + fontWeight + size + …).
  final CoreTextStyle? titleTextStyle;

  /// Selection-hint text style override.
  final CoreTextStyle? selectionHintTextStyle;

  // ── Phase 6f defaults — single source of truth ─────

  /// Default horizontal gap between sibling chips (logical px,
  /// pre-scaling) — forwarded to native `Wrap.spacing` / `column-gap`.
  static const double defaultItemSpacing = CoreSpace.space8;

  /// Default vertical gap between rows in wrap layout (logical px,
  /// pre-scaling).
  static const double defaultRowSpacing = CoreSpace.space8;

  /// Default vertical gap between the title line and the selection-hint
  /// line — the header stacks the two, title first.
  static const CoreGapStyle defaultTitleHintGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default vertical gap between the header and chips — forwarded to
  /// `Gap(gapStyle: …)`.
  static const CoreGapStyle defaultTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space8,
  );

  /// Default edge fade width in scroll layout (logical px, pre-scaling).
  static const double defaultFadeWidth = CoreSpace.space32;

  /// Default title slot text style — the 15px `labelXl` role in SemiBold
  /// with the `onSurface` colour. The title names the group above its
  /// chips, so it reads one weight above the role's `medium`. Per-instance
  /// overrides flow through [titleTextStyle].
  static final CoreTextStyle defaultTitleTextStyle = const CoreTextStyle.token(
    CoreTextStyles.labelXl,
    color: CoreColor.token(CoreColors.onSurface),
  ).copyWith(fontWeight: CoreFontWeight.semiBold);

  /// Default selection-hint slot text style — the 12px `bodyXs` role with
  /// the muted `onSurfaceVariant` colour. Per-instance overrides flow
  /// through [selectionHintTextStyle].
  static const CoreTextStyle defaultSelectionHintTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.bodyXs,
        color: CoreColor.token(CoreColors.onSurfaceVariant),
      );

  /// Default fade gradient base colour in scroll layout (matches the
  /// scroll container background so the fade blends seamlessly).
  static const CoreColor defaultFadeColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested text / gap styles are
  /// merged recursively.
  @override
  CoreChipGroupStyle merge(CoreChipGroupStyle? other) {
    if (other == null) return this;
    return CoreChipGroupStyle(
      fadeWidth: other.fadeWidth ?? fadeWidth,
      fadeColor: other.fadeColor ?? fadeColor,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      titleHintGapStyle: _mergeGap(
        titleHintGapStyle,
        other.titleHintGapStyle,
      ),
      titleGapStyle: _mergeGap(titleGapStyle, other.titleGapStyle),
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      selectionHintTextStyle: _mergeText(
        selectionHintTextStyle,
        other.selectionHintTextStyle,
      ),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreChipGroupStyle copyWith({
    double? fadeWidth,
    CoreColor? fadeColor,
    double? itemSpacing,
    double? rowSpacing,
    CoreGapStyle? titleHintGapStyle,
    CoreGapStyle? titleGapStyle,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? selectionHintTextStyle,
  }) {
    return CoreChipGroupStyle(
      fadeWidth: fadeWidth ?? this.fadeWidth,
      fadeColor: fadeColor ?? this.fadeColor,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      titleHintGapStyle: titleHintGapStyle ?? this.titleHintGapStyle,
      titleGapStyle: titleGapStyle ?? this.titleGapStyle,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      selectionHintTextStyle:
          selectionHintTextStyle ?? this.selectionHintTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChipGroupStyle &&
          runtimeType == other.runtimeType &&
          fadeWidth == other.fadeWidth &&
          fadeColor == other.fadeColor &&
          itemSpacing == other.itemSpacing &&
          rowSpacing == other.rowSpacing &&
          titleHintGapStyle == other.titleHintGapStyle &&
          titleGapStyle == other.titleGapStyle &&
          titleTextStyle == other.titleTextStyle &&
          selectionHintTextStyle == other.selectionHintTextStyle;

  @override
  int get hashCode => Object.hash(
    fadeWidth,
    fadeColor,
    itemSpacing,
    rowSpacing,
    titleHintGapStyle,
    titleGapStyle,
    titleTextStyle,
    selectionHintTextStyle,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreGapStyle? _mergeGap(
    CoreGapStyle? base,
    CoreGapStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
