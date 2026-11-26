/// Per-instance style for `MockupCode`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MockupCode` should render.
///
/// `CoreMockupCodeStyle` carries chrome / colour flat fields.
/// Behavioural / content fields (`lines`) stay flat on the widget /
/// contract (Epic #1302 원칙 6/7 — semantic input).
///
/// ```text
/// design system default
///   → CoreMockupTheme.style (shared cross-variant fallback)
///   → CoreMockupCodeTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget.mockupCodeStyle                         // 인스턴스별
/// ```
@immutable
class CoreMockupCodeStyle implements CoreStyle<CoreMockupCodeStyle> {
  /// Creates a [CoreMockupCodeStyle].
  const CoreMockupCodeStyle({
    this.backgroundColor,
    this.textStyle,
    this.prefixTextStyle,
    this.borderRadius,
    this.padding,
    this.lineSpacing,
    this.lineNumberWidth,
    this.mutedToneColor,
    this.linkToneColor,
    this.successToneColor,
    this.warningToneColor,
    this.errorToneColor,
  });

  // ────────────────────────────────────────────────────────────────
  // Phase 6f defaults — single source of truth shared by Flutter /
  // Web resolvers. No `CoreMockupCodeDefaults.forSystem(...)` holder
  // pattern, no per-platform `_kDefault*` local constants.
  // ────────────────────────────────────────────────────────────────

  /// Default code block background colour role — `surfaceContainerLow`,
  /// the same face as the Browser's window body, so the two mockup
  /// bodies converge on one tone. The default text (`onSurface`) and
  /// gutter (`onSurfaceVariant`) inks are chosen against this face.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Default code text typography + colour — combines the `codeSm`
  /// typography role token (12 / regular / fixed 21px line box /
  /// monospace) and the `onSurface` colour role into one
  /// [CoreTextStyle] so both resolvers drive the text `<span>`'s
  /// font-size / weight / line box / colour from the single [textStyle]
  /// nested slot (`(merged.textStyle merged onto this).token / .color`).
  /// Mirrors `CoreCheckboxStyle.defaultLabelStyle`. Read the foreground
  /// colour default via `defaultTextStyle.color!`.
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeSm,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default line-number prefix typography + colour — combines the
  /// `codeSm` typography role token and the `onSurfaceVariant` colour
  /// role into one [CoreTextStyle] so both resolvers drive the prefix
  /// `<span>`'s typography / colour from the single [prefixTextStyle]
  /// nested slot. It is the same role as [defaultTextStyle], so the
  /// gutter and the code share one 21px line grid in each row. Read the
  /// prefix colour default via `defaultPrefixTextStyle.color!`.
  static const CoreTextStyle defaultPrefixTextStyle = CoreTextStyle.token(
    CoreTextStyles.codeSm,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default outer container border radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius8,
  );

  /// Default content padding — 10 above and below, 16 left and right.
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.symmetric(
    vertical: CoreSpace.space10,
    horizontal: CoreSpace.space16,
  );

  /// Default per-line bottom spacing.
  static const double defaultLineSpacing = CoreSpace.space4;

  /// Default fixed width allocated for the line-number prefix — a
  /// dimension, so it sits on the size ladder (`CoreSize.size28`, about
  /// three monospace `codeSm` characters). Density does not move it.
  static const double defaultLineNumberWidth = CoreSize.size28;

  /// Colour of a `CoreCodeLineTone.muted` line — de-emphasised text such as
  /// a command echo. The `onSurfaceVariant` slot, the same one the
  /// line-number prefix uses.
  static const CoreColor defaultMutedToneColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Colour of a `CoreCodeLineTone.link` line — a path or URL. The `link`
  /// slot, not `info`: the Dark `info` is 3.96 as text.
  static const CoreColor defaultLinkToneColor = CoreColor.token(
    CoreColors.link,
  );

  /// Colour of a `CoreCodeLineTone.success` line — `onSuccessContainer`, not
  /// `success`: `success` as text on the `surfaceContainerLow` face this
  /// block sits on reads 4.37:1 in the standard mapping's light scheme, under
  /// the 4.5 text bar, and the container ink clears it in every mode. The
  /// three status tones read the container inks together so one rule covers
  /// them.
  static const CoreColor defaultSuccessToneColor = CoreColor.token(
    CoreColors.onSuccessContainer,
  );

  /// Colour of a `CoreCodeLineTone.warning` line — `onWarningContainer`, not
  /// `warning`, for the reason [defaultSuccessToneColor] gives: `warning` as
  /// text on this face falls just under 4.5:1 in light (the syntax `invalid`
  /// role makes the same choice).
  static const CoreColor defaultWarningToneColor = CoreColor.token(
    CoreColors.onWarningContainer,
  );

  /// Colour of a `CoreCodeLineTone.error` line — `onErrorContainer`, for the
  /// reason [defaultWarningToneColor] gives.
  static const CoreColor defaultErrorToneColor = CoreColor.token(
    CoreColors.onErrorContainer,
  );

  /// Code block background colour override.
  final CoreColor? backgroundColor;

  /// Code text style override (typography role + colour). Text colour
  /// is carried via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `textColor` field removed).
  final CoreTextStyle? textStyle;

  /// Line-number prefix text style override. Text colour is carried
  /// via [CoreTextStyle.color] inside this slot (sb8 — raw
  /// `prefixColor` field removed).
  final CoreTextStyle? prefixTextStyle;

  /// Outer container border radius override.
  final CoreBorderRadius? borderRadius;

  /// Outer container padding override.
  final CoreEdgeInsets? padding;

  /// Per-line bottom spacing override (logical px, pre-scaling).
  final double? lineSpacing;

  /// Line-number prefix gutter width override (logical px, pre-scaling).
  final double? lineNumberWidth;

  /// Colour override for `CoreCodeLineTone.muted` lines.
  ///
  /// There is no slot for `CoreCodeLineTone.neutral`: a neutral line is the
  /// code text itself, so it follows [textStyle]'s colour (default
  /// `onSurface`) and a caller who recolours the text recolours it too.
  /// Tone slots carry colour only — a tone never changes the typography.
  /// The tone → slot mapping is `muted` → [mutedToneColor], `link` →
  /// [linkToneColor], `success` → [successToneColor], `warning` →
  /// [warningToneColor], `error` → [errorToneColor], each falling back to
  /// its `default*ToneColor`.
  final CoreColor? mutedToneColor;

  /// Colour override for `CoreCodeLineTone.link` lines.
  final CoreColor? linkToneColor;

  /// Colour override for `CoreCodeLineTone.success` lines.
  final CoreColor? successToneColor;

  /// Colour override for `CoreCodeLineTone.warning` lines.
  final CoreColor? warningToneColor;

  /// Colour override for `CoreCodeLineTone.error` lines.
  final CoreColor? errorToneColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreMockupCodeStyle merge(CoreMockupCodeStyle? other) {
    if (other == null) return this;
    return CoreMockupCodeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      textStyle: _mergeText(textStyle, other.textStyle),
      prefixTextStyle: _mergeText(prefixTextStyle, other.prefixTextStyle),
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      lineSpacing: other.lineSpacing ?? lineSpacing,
      lineNumberWidth: other.lineNumberWidth ?? lineNumberWidth,
      mutedToneColor: other.mutedToneColor ?? mutedToneColor,
      linkToneColor: other.linkToneColor ?? linkToneColor,
      successToneColor: other.successToneColor ?? successToneColor,
      warningToneColor: other.warningToneColor ?? warningToneColor,
      errorToneColor: other.errorToneColor ?? errorToneColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMockupCodeStyle copyWith({
    CoreColor? backgroundColor,
    CoreTextStyle? textStyle,
    CoreTextStyle? prefixTextStyle,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? lineSpacing,
    double? lineNumberWidth,
    CoreColor? mutedToneColor,
    CoreColor? linkToneColor,
    CoreColor? successToneColor,
    CoreColor? warningToneColor,
    CoreColor? errorToneColor,
  }) {
    return CoreMockupCodeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      prefixTextStyle: prefixTextStyle ?? this.prefixTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      lineNumberWidth: lineNumberWidth ?? this.lineNumberWidth,
      mutedToneColor: mutedToneColor ?? this.mutedToneColor,
      linkToneColor: linkToneColor ?? this.linkToneColor,
      successToneColor: successToneColor ?? this.successToneColor,
      warningToneColor: warningToneColor ?? this.warningToneColor,
      errorToneColor: errorToneColor ?? this.errorToneColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupCodeStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          textStyle == other.textStyle &&
          prefixTextStyle == other.prefixTextStyle &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          lineSpacing == other.lineSpacing &&
          lineNumberWidth == other.lineNumberWidth &&
          mutedToneColor == other.mutedToneColor &&
          linkToneColor == other.linkToneColor &&
          successToneColor == other.successToneColor &&
          warningToneColor == other.warningToneColor &&
          errorToneColor == other.errorToneColor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    textStyle,
    prefixTextStyle,
    borderRadius,
    padding,
    lineSpacing,
    lineNumberWidth,
    mutedToneColor,
    linkToneColor,
    successToneColor,
    warningToneColor,
    errorToneColor,
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
