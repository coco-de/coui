/// Per-instance style for `InputOtp`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/input_otp/input_otp_size.dart';
import 'package:coui_core/src/component/contracts/input_otp/input_otp_variant.dart';
import 'package:coui_core/src/component/contracts/validator_hint/validator_hint_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `InputOtp` should render.
///
/// `CoreInputOtpStyle` carries chrome / dimensional flat fields and the
/// nested slots of the composed children. The inter-cell gap is exposed as
/// the scalar [cellSpacing] (consumed natively as `Row.spacing` on Flutter
/// and flex `gap` on Web). Behavioural fields (`length`, `obscured`,
/// callbacks) stay flat on the widget / contract.
///
/// A cell has two resting looks, decided by whether it holds a digit: an
/// empty cell takes [backgroundColor] / [borderColor], a filled one
/// [filledBackgroundColor] / [filledBorderColor]. The active cell keeps the
/// fill of its state and takes the neutral [defaultFocusBorderColor] edge —
/// focus is the caret and the `FocusOutline` ring, never a `primary` border.
///
/// ```text
/// design system default
///   → CoreInputOtpStyle.defaultsBySize[size]        // 크기 단계
///   → CoreInputOtpStyle.defaultsByVariant[variant]  // 변형 (error 보더)
///   → CoreInputOtpTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.inputOtpStyle                          // 인스턴스별
/// ```
@immutable
class CoreInputOtpStyle implements CoreStyle<CoreInputOtpStyle> {
  /// Creates a [CoreInputOtpStyle].
  const CoreInputOtpStyle({
    this.cellSpacing,
    this.cellSize,
    this.cellHeight,
    this.obscuredDotSize,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.filledBackgroundColor,
    this.filledBorderColor,
    this.hoverBorderColor,
    this.focusBackgroundColor,
    this.focusBorderColor,
    this.borderRadius,
    this.borderWidth,
    this.caretColor,
    this.caretWidth,
    this.caretHeight,
    this.caretBorderRadius,
    this.separatorPadding,
    this.separatorColor,
    this.separatorWidth,
    this.separatorThickness,
    this.separatorBorderRadius,
    this.transitionDuration,
    this.textStyle,
    @Deprecated(
      'The separator is a bar now (since 0.190) — style it with '
      'separatorColor, separatorWidth, separatorThickness and '
      'separatorBorderRadius. This field is no longer read.',
    )
    this.separatorTextStyle,
    @Deprecated(
      'Use errorValidatorHintStyle.messageTextStyle (since 0.190) — the '
      'error line is a composed ValidatorHint. Still forwarded to it.',
    )
    this.errorTextStyle,
    this.errorTextPadding,
    this.errorValidatorHintStyle,
  });

  /// Default width of each OTP cell (logical px).
  static const double defaultCellSize = CoreSpace.space44;

  /// Default height of each OTP cell (logical px) — taller than
  /// [defaultCellSize], so the resting cell is a 44 × 52 box. Both
  /// resolvers read the chain `cellHeight ?? cellSize ?? this`, so a caller
  /// who restates only [cellSize] gets a square cell of that size.
  static const double defaultCellHeight = CoreSpace.space52;

  /// Default gap between sibling OTP cells (logical px). Consumed
  /// natively as `Row.spacing` on Flutter and `gap-${cellSpacing
  /// .tailwindSpace}` on Web.
  static const double defaultCellSpacing = CoreSpace.space8;

  /// Default overall height of the OTP input row (logical px) — the cell's
  /// own height. The row is never shorter than its cells: both resolvers
  /// lay it out at the larger of this and the resolved cell height, so a
  /// taller cell does not get squeezed (Flutter) or overflow the row (Web).
  static const double defaultHeight = CoreSpace.space52;

  /// Default padding around the separator bar — horizontal symmetric.
  static const CoreEdgeInsets defaultSeparatorPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4);

  /// Default diameter of the obscured-value dot (logical px).
  static const double defaultObscuredDotSize = CoreSize.size10;

  /// Default background colour of an EMPTY OTP cell —
  /// `surfaceContainerLow`, a step below the [defaultFilledBackgroundColor]
  /// a typed cell takes, so the cells still to fill read apart from the
  /// ones already filled.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Default border colour of an EMPTY OTP cell — `outlineVariant`, the
  /// resting edge `CoreTextFieldStyle` draws.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default background colour of a cell that holds a digit — `surface`.
  static const CoreColor defaultFilledBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default border colour of a cell that holds a digit — `outline`, one
  /// step past the empty cell's [defaultBorderColor].
  static const CoreColor defaultFilledBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default background colour of the active EMPTY cell. Names
  /// [defaultBackgroundColor] — focus is signalled by the caret and the
  /// focus ring, not by the fill, so the active cell keeps the look of its
  /// fill state. Its own named default because [focusBackgroundColor] is
  /// its own override slot (1:1:1:1:1:1). The active cell that holds a
  /// digit takes the filled background instead.
  static const CoreColor defaultFocusBackgroundColor = defaultBackgroundColor;

  /// Default border colour of the active cell, empty or filled — `outline`,
  /// the filled cell's edge, never `primary`: the caret and the focus ring
  /// say which cell is active, and a coloured edge would draw a second ring
  /// inside the first. The error variant restates `error`.
  static const CoreColor defaultFocusBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default border colour of each OTP cell while the pointer is over the
  /// control — `outline`, one step past the resting [defaultBorderColor]
  /// (the same step `CoreTextFieldStyle` takes, since a cell is a text
  /// input). Rungs below it on the ladder
  /// `disabled > error > focus > hover > rest`: a disabled control has no
  /// hover step, the error variant restates its own error border
  /// ([defaultErrorVariantStyle]), and a focused control keeps its focus
  /// chrome instead of stepping.
  static const CoreColor defaultHoverBorderColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default border radius of each OTP cell.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// Default border width of each OTP cell.
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default colour of the caret drawn in the active empty cell —
  /// `primary`. The error variant restates `error`.
  static const CoreColor defaultCaretColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default width of the caret (logical px) — a 2 px stroke.
  static const double defaultCaretWidth = CoreStrokeWidth.stroke2;

  /// Default height of the caret (logical px). `lg` restates 24.
  static const double defaultCaretHeight = CoreSize.size20;

  /// Default corner of the caret — fully rounded, so the 2 px stroke has
  /// round ends.
  static const CoreBorderRadius defaultCaretBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius9999,
  );

  /// Default colour of the separator bar — `outline`.
  static const CoreColor defaultSeparatorColor = CoreColor.token(
    CoreColors.outline,
  );

  /// Default length of the separator bar (logical px).
  static const double defaultSeparatorWidth = CoreSize.size8;

  /// Default thickness of the separator bar (logical px).
  static const double defaultSeparatorThickness = CoreStrokeWidth.stroke2;

  /// Default corner of the separator bar — fully rounded, so the 2 px bar
  /// has round ends.
  static const CoreBorderRadius defaultSeparatorBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Default transition duration for cell focus / value changes.
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default OTP value text style — the `titleMedium` typography role
  /// (18 px, the role's own semi-bold) in the `onSurface` foreground
  /// colour. Both platforms lay the per-instance [textStyle] over it.
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.titleMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// The separator glyph's text style, from before the separator was a
  /// bar. Nothing reads it.
  @Deprecated(
    'The separator is a bar now (since 0.190) — see defaultSeparatorColor, '
    'defaultSeparatorWidth and defaultSeparatorThickness.',
  )
  static const CoreTextStyle defaultSeparatorTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// The error line's text style from before the line was a composed
  /// `ValidatorHint`. Nothing reads it — the hint's own
  /// `defaultMessageTextStyle` (`bodyXs`) and its `error` accent are the
  /// line's look now.
  @Deprecated(
    'The error line is a composed ValidatorHint (since 0.190) — see '
    'defaultErrorValidatorHintStyle.',
  )
  static const CoreTextStyle defaultErrorTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyXs,
    color: CoreColor.token(CoreColors.error),
  );

  /// Default padding above the error line (4 logical px on the top edge
  /// only — separates the message from the cell row above). Pairs 1:1 with
  /// the per-instance [errorTextPadding] override.
  static const CoreEdgeInsets defaultErrorTextPadding = CoreEdgeInsets.only(
    top: CoreSpace.space4,
  );

  /// Default partial for the composed error `ValidatorHint` — states only
  /// what diverges from the hint's own defaults: a 14 px `circle-alert`
  /// glyph. The hint fills the rest itself (`bodyXs` message, `error`
  /// accent on the glyph and the message, the 4 px glyph–message gap).
  static const CoreValidatorHintStyle defaultErrorValidatorHintStyle =
      CoreValidatorHintStyle(
        iconStyle: CoreIconStyle(size: CoreIconSize.size14),
      );

  /// Chrome overrides applied when `widget.errorText != null`. Every cell
  /// border (empty, filled, hovered and active) and the caret switch to
  /// the `error` token — hover restates it so an invalid control does not
  /// soften under the pointer; every other field stays null so the
  /// resolver's per-field fallback chain
  /// (`merged.X ?? variantStyle.X ?? CoreInputOtpStyle.defaultX`) keeps
  /// the design-system default for everything else. Single source shared
  /// by both platform resolvers — mirrors
  /// `CoreTextFieldStyle.defaultErrorVariant`.
  static const CoreInputOtpStyle defaultErrorVariantStyle = CoreInputOtpStyle(
    borderColor: CoreColor.token(CoreColors.error),
    filledBorderColor: CoreColor.token(CoreColors.error),
    hoverBorderColor: CoreColor.token(CoreColors.error),
    focusBorderColor: CoreColor.token(CoreColors.error),
    caretColor: CoreColor.token(CoreColors.error),
  );

  /// Per-[CoreInputOtpVariant] chrome overrides. `defaultVariant` maps
  /// to an empty style (no overrides — pure design-system defaults);
  /// `error` maps to [defaultErrorVariantStyle]. Both platform resolvers
  /// key this map with `widget.errorText != null ? .error :
  /// .defaultVariant` — Map dispatch per the resolver-pattern rule
  /// (never an inline `if (hasError)` branch scattered across fields).
  static const Map<CoreInputOtpVariant, CoreInputOtpStyle> defaultsByVariant = {
    CoreInputOtpVariant.defaultVariant: CoreInputOtpStyle(),
    CoreInputOtpVariant.error: defaultErrorVariantStyle,
  };

  /// Per-[CoreInputOtpSize] defaults — the head of both platforms' merge
  /// chain, so the theme's `style` and the widget's `inputOtpStyle` still
  /// win over a size's value.
  ///
  /// `md` is empty: every field falls through to the `default*` constants
  /// above — the 44 × 52 cell, the corner 10 and the 20 caret.
  ///
  /// `lg` states:
  /// - a 56 × 64 cell and a 64 row floor, on the size scale — not the
  ///   control ladder's rung. The cell box does not move with a density on
  ///   either platform (the `md` cell does not either).
  /// - the corner 14 and a 24 caret.
  /// - the `headlineSmall` role for the digit (24), at semi-bold — the
  ///   role's own weight is bold, so the row restates the weight alone, never
  ///   a size. The digit fills a fixed cell, so both widgets pin their digits
  ///   to the desktop typography tier and a narrow viewport cannot shrink
  ///   the headline inside an unchanged box.
  ///
  /// Colours, the dot, the separator bar and the error line do not vary by
  /// size, and the error variant's colours reach an `lg` field unchanged.
  static final Map<CoreInputOtpSize, CoreInputOtpStyle> defaultsBySize = {
    CoreInputOtpSize.md: const CoreInputOtpStyle(),
    CoreInputOtpSize.lg: CoreInputOtpStyle(
      cellSize: CoreSize.size56,
      cellHeight: CoreSize.size64,
      height: CoreSize.size64,
      borderRadius: const CoreBorderRadius.all(CoreRadius.radius14),
      caretHeight: CoreSize.size24,
      textStyle: const CoreTextStyle.token(
        CoreTextStyles.headlineSmall,
      ).copyWith(fontWeight: CoreFontWeight.semiBold),
    ),
  };

  /// The head of both platforms' merge chain for [size] and [variant] —
  /// the size row with the variant row laid over it.
  ///
  /// The variant comes second so it wins where both state a field. The two
  /// rows do not meet today (the size row states no colour and the variant
  /// states nothing else), so every dimension, corner and text role comes
  /// from the size row and every error colour from the variant. The
  /// theme's `style`, its `variantStyles[variant]` and the widget's
  /// `inputOtpStyle` follow this head and win over both.
  static CoreInputOtpStyle chainHeadFor(
    CoreInputOtpSize size,
    CoreInputOtpVariant variant,
  ) => defaultsBySize[size]!.merge(defaultsByVariant[variant]);

  /// Gap between sibling OTP cells (logical px). `null` defers to
  /// [defaultCellSpacing]. Consumed natively as `Row.spacing` on
  /// Flutter and `gap-${cellSpacing.tailwindSpace}` on Web.
  final double? cellSpacing;

  /// Width of each OTP cell (logical px) — and its height too, unless
  /// [cellHeight] says otherwise.
  final double? cellSize;

  /// Height of each OTP cell (logical px). `null` follows [cellSize], whose
  /// own fallback is [defaultCellHeight] — so a caller who states only a
  /// width gets a square cell (a 50 × 58 cell is `cellSize: 50,
  /// cellHeight: 58`).
  final double? cellHeight;

  /// Size (logical px, square) of the dot shown for an obscured character.
  /// `null` → [defaultObscuredDotSize].
  final double? obscuredDotSize;

  /// Overall height of the OTP input row (logical px). Never shorter than
  /// the cells' own height — see [defaultHeight].
  final double? height;

  /// Background colour of an empty OTP cell. `null` →
  /// [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Border colour of an empty OTP cell. `null` falls through to the
  /// variant's own (the error variant states `error`), then to
  /// [defaultBorderColor].
  final CoreColor? borderColor;

  /// Background colour of a cell that holds a digit. `null` →
  /// [defaultFilledBackgroundColor].
  final CoreColor? filledBackgroundColor;

  /// Border colour of a cell that holds a digit. `null` falls through to
  /// the variant's own (the error variant states `error`), then to
  /// [defaultFilledBorderColor].
  final CoreColor? filledBorderColor;

  /// Border colour of each OTP cell while the pointer is over the control
  /// and no cell holds focus. `null` falls through to the variant's own
  /// hover border (the error variant restates `error`), then to
  /// [defaultHoverBorderColor]. A disabled control never takes it.
  final CoreColor? hoverBorderColor;

  /// Background colour of the active cell. `null` keeps the background of
  /// the cell's fill state — [backgroundColor] for an empty cell (whose own
  /// fallback is [defaultFocusBackgroundColor]), [filledBackgroundColor]
  /// for one that holds a digit.
  final CoreColor? focusBackgroundColor;

  /// Border colour of the active cell, empty or filled. `null` falls through
  /// to the variant's own (the error variant states `error`), then to
  /// [defaultFocusBorderColor]. The variant's or a caller's value also
  /// colours the focus ring.
  final CoreColor? focusBorderColor;

  /// Border radius of each OTP cell.
  final CoreBorderRadius? borderRadius;

  /// Border stroke width of each OTP cell (logical px) — defaults to
  /// [defaultBorderWidth].
  final double? borderWidth;

  /// Colour of the caret in the active empty cell. `null` falls through to
  /// the variant's own (the error variant states `error`), then to
  /// [defaultCaretColor].
  final CoreColor? caretColor;

  /// Width of the caret (logical px) — defaults to [defaultCaretWidth].
  final double? caretWidth;

  /// Height of the caret (logical px) — defaults to [defaultCaretHeight].
  final double? caretHeight;

  /// Corner of the caret — defaults to [defaultCaretBorderRadius].
  final CoreBorderRadius? caretBorderRadius;

  /// Padding around the separator bar — defaults to
  /// [defaultSeparatorPadding].
  final CoreEdgeInsets? separatorPadding;

  /// Colour of the separator bar — defaults to [defaultSeparatorColor].
  final CoreColor? separatorColor;

  /// Length of the separator bar (logical px) — defaults to
  /// [defaultSeparatorWidth].
  final double? separatorWidth;

  /// Thickness of the separator bar (logical px) — defaults to
  /// [defaultSeparatorThickness].
  final double? separatorThickness;

  /// Corner of the separator bar — defaults to
  /// [defaultSeparatorBorderRadius].
  final CoreBorderRadius? separatorBorderRadius;

  /// Transition duration for cell focus / value changes —
  /// defaults to [defaultTransitionDuration].
  final Duration? transitionDuration;

  /// Text style applied to the OTP input value. Layered on top of
  /// [defaultTextStyle].
  final CoreTextStyle? textStyle;

  /// The separator glyph's text style, from before the separator was a
  /// bar. Nothing reads it.
  @Deprecated(
    'The separator is a bar now (since 0.190) — style it with '
    'separatorColor, separatorWidth, separatorThickness and '
    'separatorBorderRadius. This field is no longer read.',
  )
  final CoreTextStyle? separatorTextStyle;

  /// Text style of the error message. Forwarded to the composed
  /// `ValidatorHint` as its `messageTextStyle` (its colour as the hint's
  /// accent), under [errorValidatorHintStyle].
  @Deprecated(
    'Use errorValidatorHintStyle.messageTextStyle (since 0.190) — the '
    'error line is a composed ValidatorHint. Still forwarded to it.',
  )
  final CoreTextStyle? errorTextStyle;

  /// Padding above the error line — defaults to [defaultErrorTextPadding].
  final CoreEdgeInsets? errorTextPadding;

  /// The style of the composed `ValidatorHint` that draws the error line,
  /// laid over [defaultErrorValidatorHintStyle]. The hint fills the rest
  /// itself — the `error` accent, the `circle-alert` glyph, the message role.
  ///
  /// A nested slot, raw-forwarded: the hint's own resolver reads it.
  final CoreValidatorHintStyle? errorValidatorHintStyle;

  /// The composed error `ValidatorHint`'s style for this merged style —
  /// [defaultErrorValidatorHintStyle], then the deprecated [errorTextStyle]
  /// (its role as the message style, its colour as the accent), then
  /// [errorValidatorHintStyle]. Both platform resolvers forward exactly this
  /// value, so the two cannot disagree on how the deprecated field folds in.
  CoreValidatorHintStyle resolveErrorValidatorHintStyle() {
    final legacy = errorTextStyle;
    return defaultErrorValidatorHintStyle
        .merge(
          legacy == null
              ? null
              : CoreValidatorHintStyle(
                  messageTextStyle: legacy,
                  accentColor: legacy.color,
                ),
        )
        .merge(errorValidatorHintStyle);
  }

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreInputOtpStyle merge(CoreInputOtpStyle? other) {
    if (other == null) return this;
    return CoreInputOtpStyle(
      cellSpacing: other.cellSpacing ?? cellSpacing,
      cellSize: other.cellSize ?? cellSize,
      cellHeight: other.cellHeight ?? cellHeight,
      obscuredDotSize: other.obscuredDotSize ?? obscuredDotSize,
      height: other.height ?? height,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      filledBackgroundColor:
          other.filledBackgroundColor ?? filledBackgroundColor,
      filledBorderColor: other.filledBorderColor ?? filledBorderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      focusBackgroundColor: other.focusBackgroundColor ?? focusBackgroundColor,
      focusBorderColor: other.focusBorderColor ?? focusBorderColor,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      caretColor: other.caretColor ?? caretColor,
      caretWidth: other.caretWidth ?? caretWidth,
      caretHeight: other.caretHeight ?? caretHeight,
      caretBorderRadius: other.caretBorderRadius ?? caretBorderRadius,
      separatorPadding: other.separatorPadding ?? separatorPadding,
      separatorColor: other.separatorColor ?? separatorColor,
      separatorWidth: other.separatorWidth ?? separatorWidth,
      separatorThickness: other.separatorThickness ?? separatorThickness,
      separatorBorderRadius:
          other.separatorBorderRadius ?? separatorBorderRadius,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      textStyle: _mergeText(textStyle, other.textStyle),
      separatorTextStyle: _mergeText(
        separatorTextStyle,
        other.separatorTextStyle,
      ),
      errorTextStyle: _mergeText(errorTextStyle, other.errorTextStyle),
      errorTextPadding: other.errorTextPadding ?? errorTextPadding,
      errorValidatorHintStyle:
          errorValidatorHintStyle?.merge(other.errorValidatorHintStyle) ??
          other.errorValidatorHintStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreInputOtpStyle copyWith({
    double? cellSpacing,
    double? cellSize,
    double? cellHeight,
    double? obscuredDotSize,
    double? height,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    CoreColor? filledBackgroundColor,
    CoreColor? filledBorderColor,
    CoreColor? hoverBorderColor,
    CoreColor? focusBackgroundColor,
    CoreColor? focusBorderColor,
    CoreBorderRadius? borderRadius,
    double? borderWidth,
    CoreColor? caretColor,
    double? caretWidth,
    double? caretHeight,
    CoreBorderRadius? caretBorderRadius,
    CoreEdgeInsets? separatorPadding,
    CoreColor? separatorColor,
    double? separatorWidth,
    double? separatorThickness,
    CoreBorderRadius? separatorBorderRadius,
    Duration? transitionDuration,
    CoreTextStyle? textStyle,
    CoreTextStyle? separatorTextStyle,
    CoreTextStyle? errorTextStyle,
    CoreEdgeInsets? errorTextPadding,
    CoreValidatorHintStyle? errorValidatorHintStyle,
  }) {
    return CoreInputOtpStyle(
      cellSpacing: cellSpacing ?? this.cellSpacing,
      cellSize: cellSize ?? this.cellSize,
      cellHeight: cellHeight ?? this.cellHeight,
      obscuredDotSize: obscuredDotSize ?? this.obscuredDotSize,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      filledBackgroundColor:
          filledBackgroundColor ?? this.filledBackgroundColor,
      filledBorderColor: filledBorderColor ?? this.filledBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      focusBackgroundColor: focusBackgroundColor ?? this.focusBackgroundColor,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      caretColor: caretColor ?? this.caretColor,
      caretWidth: caretWidth ?? this.caretWidth,
      caretHeight: caretHeight ?? this.caretHeight,
      caretBorderRadius: caretBorderRadius ?? this.caretBorderRadius,
      separatorPadding: separatorPadding ?? this.separatorPadding,
      separatorColor: separatorColor ?? this.separatorColor,
      separatorWidth: separatorWidth ?? this.separatorWidth,
      separatorThickness: separatorThickness ?? this.separatorThickness,
      separatorBorderRadius:
          separatorBorderRadius ?? this.separatorBorderRadius,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      textStyle: textStyle ?? this.textStyle,
      separatorTextStyle: separatorTextStyle ?? this.separatorTextStyle,
      errorTextStyle: errorTextStyle ?? this.errorTextStyle,
      errorTextPadding: errorTextPadding ?? this.errorTextPadding,
      errorValidatorHintStyle:
          errorValidatorHintStyle ?? this.errorValidatorHintStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreInputOtpStyle &&
          runtimeType == other.runtimeType &&
          cellSpacing == other.cellSpacing &&
          cellSize == other.cellSize &&
          cellHeight == other.cellHeight &&
          obscuredDotSize == other.obscuredDotSize &&
          height == other.height &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          filledBackgroundColor == other.filledBackgroundColor &&
          filledBorderColor == other.filledBorderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          focusBackgroundColor == other.focusBackgroundColor &&
          focusBorderColor == other.focusBorderColor &&
          borderRadius == other.borderRadius &&
          borderWidth == other.borderWidth &&
          caretColor == other.caretColor &&
          caretWidth == other.caretWidth &&
          caretHeight == other.caretHeight &&
          caretBorderRadius == other.caretBorderRadius &&
          separatorPadding == other.separatorPadding &&
          separatorColor == other.separatorColor &&
          separatorWidth == other.separatorWidth &&
          separatorThickness == other.separatorThickness &&
          separatorBorderRadius == other.separatorBorderRadius &&
          transitionDuration == other.transitionDuration &&
          textStyle == other.textStyle &&
          separatorTextStyle == other.separatorTextStyle &&
          errorTextStyle == other.errorTextStyle &&
          errorTextPadding == other.errorTextPadding &&
          errorValidatorHintStyle == other.errorValidatorHintStyle;

  @override
  int get hashCode => Object.hashAll([
    cellSpacing,
    cellSize,
    cellHeight,
    obscuredDotSize,
    height,
    backgroundColor,
    borderColor,
    filledBackgroundColor,
    filledBorderColor,
    hoverBorderColor,
    focusBackgroundColor,
    focusBorderColor,
    borderRadius,
    borderWidth,
    caretColor,
    caretWidth,
    caretHeight,
    caretBorderRadius,
    separatorPadding,
    separatorColor,
    separatorWidth,
    separatorThickness,
    separatorBorderRadius,
    transitionDuration,
    textStyle,
    separatorTextStyle,
    errorTextStyle,
    errorTextPadding,
    errorValidatorHintStyle,
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
