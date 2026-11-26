/// Per-instance style for `Basic`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/basic/core_basic_alignment.dart';
import 'package:coui_core/src/component/contracts/basic/core_basic_main_axis_alignment.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Basic` should render.
///
/// `CoreBasicStyle` carries layout chrome (alignment / padding) as
/// flat fields, nested `CoreGapStyle` slots for the three inter-slot
/// gaps that flow straight into the inner `Gap` widgets (so each
/// `Gap` owns its own scaling — Epic #2228 4-principle), and nested
/// `CoreTextStyle` for the title / subtitle / content slot text
/// overrides.
///
/// ```text
/// design system default
///   → CoreBasicTheme (legacy flat fields)
///   → CoreBasicTheme.style                          // 프로젝트 공통
///   → parent component slot override
///   → widget.basicStyle                             // 인스턴스별
/// ```
@immutable
class CoreBasicStyle implements CoreStyle<CoreBasicStyle> {
  /// Creates a [CoreBasicStyle].
  const CoreBasicStyle({
    this.leadingAlignment,
    this.trailingAlignment,
    this.titleAlignment,
    this.subtitleAlignment,
    this.contentAlignment,
    this.titleContentGapStyle,
    this.leadingTitleGapStyle,
    this.titleSubtitleGapStyle,
    this.mainAxisAlignment,
    this.padding,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.contentTextStyle,
    this.trailingGapStyle,
    this.trailingTextStyle,
    this.trailingIconStyle,
  });

  // ── Layout chrome (flat) ─────────────────────

  /// Alignment of the leading slot inside its cell.
  final CoreBasicAlignment? leadingAlignment;

  /// Alignment of the trailing slot inside its cell.
  final CoreBasicAlignment? trailingAlignment;

  /// Alignment of the title slot inside its cell.
  final CoreBasicAlignment? titleAlignment;

  /// Alignment of the subtitle slot inside its cell.
  final CoreBasicAlignment? subtitleAlignment;

  /// Alignment of the content slot inside its cell.
  final CoreBasicAlignment? contentAlignment;

  /// Horizontal gap between `leading`, the body and `trailing`, passed to
  /// the `Gap` widgets between them as is. `null` defers to
  /// [defaultTitleContentGapStyle].
  ///
  /// (Per Epic #2228 the receiving `Gap` owns its own scaling).
  final CoreGapStyle? titleContentGapStyle;

  /// Vertical gap between the title and subtitle block and the `content`
  /// slot inside the body column, passed to the `Gap` there. `null`
  /// defers to [defaultLeadingTitleGapStyle].
  final CoreGapStyle? leadingTitleGapStyle;

  /// Vertical gap between the `title` and `subtitle` rows inside the body
  /// column, passed to the `Gap` there. `null` defers to
  /// [defaultTitleSubtitleGapStyle].
  final CoreGapStyle? titleSubtitleGapStyle;

  /// Outer row main-axis alignment.
  final CoreBasicMainAxisAlignment? mainAxisAlignment;

  /// Outer padding (pre-scaling). `null` defers to [defaultPadding].
  final CoreEdgeInsets? padding;

  // ── Slot Styles (nested) ─────────────────────

  /// Title slot text style override (color + fontWeight + size + …).
  final CoreTextStyle? titleTextStyle;

  /// Subtitle slot text style override.
  final CoreTextStyle? subtitleTextStyle;

  /// Content slot text style override.
  final CoreTextStyle? contentTextStyle;

  /// Gap between the trailing value text and the trailing icon inside the
  /// trailing cell. `null` defers to [defaultTrailingGapStyle].
  final CoreGapStyle? trailingGapStyle;

  /// Trailing value text style override. `null` defers to
  /// [defaultTrailingTextStyle].
  final CoreTextStyle? trailingTextStyle;

  /// Style of the built-in trailing chevron; a caller-supplied `trailing`
  /// widget is not touched. `null` defers to [defaultTrailingIconStyle].
  final CoreIconStyle? trailingIconStyle;

  // ── Phase 6f defaults — single source of truth ─────

  /// Default nested [CoreGapStyle] slot for the horizontal gap between
  /// the `leading`, body, and `trailing` cells. Forwarded as-is to the
  /// row's `Gap` children; `Gap` self-scales.
  static const CoreGapStyle defaultTitleContentGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default nested [CoreGapStyle] slot for the vertical gap between
  /// the title+subtitle block and the `content` row inside the body
  /// column.
  static const CoreGapStyle defaultLeadingTitleGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default nested [CoreGapStyle] slot for the vertical gap between
  /// the `title` and `subtitle` rows inside the body column.
  static const CoreGapStyle defaultTitleSubtitleGapStyle = CoreGapStyle(
    size: CoreSpace.space2,
  );

  /// Default alignment for the leading slot.
  static const CoreBasicAlignment defaultLeadingAlignment = .center;

  /// Default alignment for the trailing slot.
  static const CoreBasicAlignment defaultTrailingAlignment = .center;

  /// Default alignment for the title slot.
  static const CoreBasicAlignment defaultTitleAlignment = .topStart;

  /// Default alignment for the subtitle slot.
  static const CoreBasicAlignment defaultSubtitleAlignment = .topStart;

  /// Default alignment for the content slot.
  static const CoreBasicAlignment defaultContentAlignment = .topStart;

  /// Default outer row main-axis alignment.
  static const CoreBasicMainAxisAlignment defaultMainAxisAlignment = .center;

  /// Default outer padding — none. `Basic` is a layout primitive that
  /// sits inside whatever surface owns the inset (list tile, card body,
  /// menu row), so the row itself contributes no padding unless the
  /// caller asks for it. Both platforms already resolved an unset
  /// `padding` slot to zero; naming it here makes that the single
  /// source instead of two inline zero literals.
  ///
  /// Spelled as `.all(CoreSpace.space0)` rather than `CoreEdgeInsets.zero`
  /// for two reasons: the value keeps its spacing-token provenance
  /// (`core/design-tokens.md` — a dimension reaches a Style through a
  /// token, and `zero` is a bare sentinel with no token identity), and the
  /// constructor form is the only one the Figma reader can evaluate
  /// (`CoreEdgeInsets` lives outside `contracts/`, so a static-const
  /// reference on it resolves to nothing and the field would drop out of
  /// `components.json` unread).
  // ignore: use_named_constants
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space0,
  );

  /// Default typography + colour tokens for slot text rendering when
  /// `forceTextStyle: true` (Flutter / Web both consume the same tokens).
  ///
  /// `title` — `label-xl` (15), weight semiBold (600), on `onSurface`.
  /// `subtitle` — `body-small` on `onSurfaceSubtle`.
  /// `content` — `body-small` on `onSurface`.
  static final CoreTextStyle defaultTitleTypography =
      CoreTypography.coui.labelXl;

  /// Default subtitle typography role — `CoreTypography.coui.bodySmall`.
  static final CoreTextStyle defaultSubtitleTypography =
      CoreTypography.coui.bodySmall;

  /// Default content typography role (same as subtitle).
  static final CoreTextStyle defaultContentTypography =
      defaultSubtitleTypography;

  /// Default title font weight applied on top of [defaultTitleTypography].
  ///
  /// A list row's title is a label one step heavier than its role — the
  /// design sets it at SemiBold 15.
  static const int defaultTitleFontWeight = CoreFontWeight.semiBold;

  /// Default title slot text colour.
  static const CoreColor defaultTitleColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default subtitle slot text colour (muted).
  static const CoreColor defaultSubtitleColor = CoreColor.token(
    CoreColors.onSurfaceSubtle,
  );

  /// Default content slot text colour (same as title — both `onSurface`).
  static const CoreColor defaultContentColor = defaultTitleColor;

  /// Default title slot [CoreTextStyle] — token-backed reference to the
  /// `label-xl` slot with the `onSurface` colour and `semiBold` weight
  /// overlay. Single source consumed by both platforms when
  /// `forceTextStyle: true`: Web emits the `text-label-xl` role class plus
  /// the `fontWeight` / `color` overlays, while
  /// Flutter resolves the slot through `theme.coreTypography` then applies
  /// the colour / weight overlays. The merged slot folds the scalar
  /// [defaultTitleTypography] / [defaultTitleFontWeight] /
  /// [defaultTitleColor] holders into one Layer-2 style.
  static final CoreTextStyle defaultTitleTextStyle = const CoreTextStyle.token(
    CoreTextStyles.labelXl,
    color: defaultTitleColor,
  ).copyWith(fontWeight: defaultTitleFontWeight);

  /// Default subtitle slot [CoreTextStyle] — token-backed reference to
  /// the `body-small` slot with the muted `onSurfaceSubtle` colour. Web
  /// emits `text-body-small text-on-surface-subtle`; Flutter resolves
  /// the slot then applies the colour overlay.
  static const CoreTextStyle defaultSubtitleTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: defaultSubtitleColor,
  );

  /// Default content slot [CoreTextStyle] — token-backed reference to the
  /// `body-small` slot with the `onSurface` colour. Web emits
  /// `text-body-small text-on-surface`; Flutter resolves the slot then
  /// applies the colour overlay.
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: defaultContentColor,
  );

  /// Default nested [CoreGapStyle] slot for the gap between the trailing
  /// value text and the trailing icon.
  static const CoreGapStyle defaultTrailingGapStyle = CoreGapStyle(
    size: CoreSpace.space4,
  );

  /// Default trailing value text style — token-backed `label-xl`
  /// (Medium 15) on `onSurface`: the value reads as the row's figure,
  /// one tier above the muted subtitle.
  static const CoreTextStyle defaultTrailingTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelXl,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default style of the built-in trailing chevron — the second
  /// text tier's stroke colour (`onSurfaceSubtle`), size from the icon
  /// default.
  static const CoreIconStyle defaultTrailingIconStyle = CoreIconStyle(
    color: CoreColor.token(CoreColors.onSurfaceSubtle),
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested gap and text styles
  /// are merged recursively.
  @override
  CoreBasicStyle merge(CoreBasicStyle? other) {
    if (other == null) return this;
    return CoreBasicStyle(
      leadingAlignment: other.leadingAlignment ?? leadingAlignment,
      trailingAlignment: other.trailingAlignment ?? trailingAlignment,
      titleAlignment: other.titleAlignment ?? titleAlignment,
      subtitleAlignment: other.subtitleAlignment ?? subtitleAlignment,
      contentAlignment: other.contentAlignment ?? contentAlignment,
      titleContentGapStyle: _mergeGap(
        titleContentGapStyle,
        other.titleContentGapStyle,
      ),
      leadingTitleGapStyle: _mergeGap(
        leadingTitleGapStyle,
        other.leadingTitleGapStyle,
      ),
      titleSubtitleGapStyle: _mergeGap(
        titleSubtitleGapStyle,
        other.titleSubtitleGapStyle,
      ),
      mainAxisAlignment: other.mainAxisAlignment ?? mainAxisAlignment,
      padding: other.padding ?? padding,
      titleTextStyle: _mergeText(titleTextStyle, other.titleTextStyle),
      subtitleTextStyle: _mergeText(subtitleTextStyle, other.subtitleTextStyle),
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      trailingGapStyle: _mergeGap(trailingGapStyle, other.trailingGapStyle),
      trailingTextStyle: _mergeText(trailingTextStyle, other.trailingTextStyle),
      trailingIconStyle:
          trailingIconStyle?.merge(other.trailingIconStyle) ??
          other.trailingIconStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreBasicStyle copyWith({
    CoreBasicAlignment? leadingAlignment,
    CoreBasicAlignment? trailingAlignment,
    CoreBasicAlignment? titleAlignment,
    CoreBasicAlignment? subtitleAlignment,
    CoreBasicAlignment? contentAlignment,
    CoreGapStyle? titleContentGapStyle,
    CoreGapStyle? leadingTitleGapStyle,
    CoreGapStyle? titleSubtitleGapStyle,
    CoreBasicMainAxisAlignment? mainAxisAlignment,
    CoreEdgeInsets? padding,
    CoreTextStyle? titleTextStyle,
    CoreTextStyle? subtitleTextStyle,
    CoreTextStyle? contentTextStyle,
    CoreGapStyle? trailingGapStyle,
    CoreTextStyle? trailingTextStyle,
    CoreIconStyle? trailingIconStyle,
  }) {
    return CoreBasicStyle(
      leadingAlignment: leadingAlignment ?? this.leadingAlignment,
      trailingAlignment: trailingAlignment ?? this.trailingAlignment,
      titleAlignment: titleAlignment ?? this.titleAlignment,
      subtitleAlignment: subtitleAlignment ?? this.subtitleAlignment,
      contentAlignment: contentAlignment ?? this.contentAlignment,
      titleContentGapStyle: titleContentGapStyle ?? this.titleContentGapStyle,
      leadingTitleGapStyle: leadingTitleGapStyle ?? this.leadingTitleGapStyle,
      titleSubtitleGapStyle:
          titleSubtitleGapStyle ?? this.titleSubtitleGapStyle,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      padding: padding ?? this.padding,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      trailingGapStyle: trailingGapStyle ?? this.trailingGapStyle,
      trailingTextStyle: trailingTextStyle ?? this.trailingTextStyle,
      trailingIconStyle: trailingIconStyle ?? this.trailingIconStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreBasicStyle &&
          runtimeType == other.runtimeType &&
          leadingAlignment == other.leadingAlignment &&
          trailingAlignment == other.trailingAlignment &&
          titleAlignment == other.titleAlignment &&
          subtitleAlignment == other.subtitleAlignment &&
          contentAlignment == other.contentAlignment &&
          titleContentGapStyle == other.titleContentGapStyle &&
          leadingTitleGapStyle == other.leadingTitleGapStyle &&
          titleSubtitleGapStyle == other.titleSubtitleGapStyle &&
          mainAxisAlignment == other.mainAxisAlignment &&
          padding == other.padding &&
          titleTextStyle == other.titleTextStyle &&
          subtitleTextStyle == other.subtitleTextStyle &&
          contentTextStyle == other.contentTextStyle &&
          trailingGapStyle == other.trailingGapStyle &&
          trailingTextStyle == other.trailingTextStyle &&
          trailingIconStyle == other.trailingIconStyle;

  @override
  int get hashCode => Object.hashAll([
    leadingAlignment,
    trailingAlignment,
    titleAlignment,
    subtitleAlignment,
    contentAlignment,
    titleContentGapStyle,
    leadingTitleGapStyle,
    titleSubtitleGapStyle,
    mainAxisAlignment,
    padding,
    titleTextStyle,
    subtitleTextStyle,
    contentTextStyle,
    trailingGapStyle,
    trailingTextStyle,
    trailingIconStyle,
  ]);

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
