import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

/// A fully-resolved [CoreColorScheme]: every slot is guaranteed non-null
/// (missing authored slots are filled from CoUI's own scheme during
/// [CoreColorScheme.resolved]).
///
/// Consumers read `Theme.of(context).colorScheme.onSurface.toValue()`
/// with no `!` — the resolved scheme narrows each getter to non-null.
/// Authoring/partial parsing still uses the nullable [CoreColorScheme].
@immutable
class ResolvedColorScheme extends CoreColorScheme {
  /// Build a resolved scheme with every slot provided.
  ResolvedColorScheme({
    required super.primary,
    required super.secondary,
    required super.error,
    required super.success,
    required super.warning,
    required super.info,
    required CoreColor surface,
    required CoreColor surfaceDim,
    required CoreColor surfaceBright,
    required CoreColor surfaceContainerLowest,
    required CoreColor surfaceContainerLow,
    required CoreColor surfaceContainer,
    required CoreColor surfaceContainerHigh,
    required CoreColor surfaceContainerHighest,
    required CoreColor onSurface,
    required CoreColor onSurfaceVariant,
    required CoreColor placeholder,
    required CoreColor link,
    required CoreColor onSurfaceSubtle,
    required CoreColor surfaceRaised,
    required CoreColor surfaceTint,
    required CoreColor onPrimary,
    required CoreColor primaryContainer,
    required CoreColor onPrimaryContainer,
    required CoreColor primaryFixed,
    required CoreColor primaryFixedDim,
    required CoreColor onPrimaryFixed,
    required CoreColor onPrimaryFixedVariant,
    required CoreColor primaryText,
    required CoreColor primaryTextLarge,
    required CoreColor onSecondary,
    required CoreColor secondaryContainer,
    required CoreColor onSecondaryContainer,
    required CoreColor secondaryFixed,
    required CoreColor secondaryFixedDim,
    required CoreColor onSecondaryFixed,
    required CoreColor onSecondaryFixedVariant,
    required CoreColor tertiary,
    required CoreColor onTertiary,
    required CoreColor tertiaryContainer,
    required CoreColor onTertiaryContainer,
    required CoreColor tertiaryFixed,
    required CoreColor tertiaryFixedDim,
    required CoreColor onTertiaryFixed,
    required CoreColor onTertiaryFixedVariant,
    required CoreColor onError,
    required CoreColor errorContainer,
    required CoreColor onErrorContainer,
    required CoreColor errorStrong,
    required CoreColor focusRing,
    required CoreColor primaryHover,
    required CoreColor primaryPressed,
    required CoreColor secondaryHover,
    required CoreColor secondaryPressed,
    required CoreColor errorPressed,
    required CoreColor onSuccess,
    required CoreColor successContainer,
    required CoreColor onSuccessContainer,
    required CoreColor onWarning,
    required CoreColor warningContainer,
    required CoreColor onWarningContainer,
    required CoreColor onInfo,
    required CoreColor infoContainer,
    required CoreColor onInfoContainer,
    required CoreColor errorIcon,
    required CoreColor successIcon,
    required CoreColor warningIcon,
    required CoreColor infoIcon,
    required CoreColor outline,
    required CoreColor outlineVariant,
    required CoreColor outlineSubtle,
    required CoreColor inverseSurface,
    required CoreColor inverseOnSurface,
    required CoreColor inversePrimary,
    required CoreColor shadow,
    required CoreColor surfaceHighlight,
    required CoreColor scrim,
    required CoreColor disabledContent,
    required CoreColor disabledContainer,
    required CoreColor disabledOutline,
    required CoreColor syntaxKeyword,
    required CoreColor syntaxType,
    required CoreColor syntaxFunction,
    required CoreColor syntaxString,
    required CoreColor super.categoryRed,
    required CoreColor super.onCategoryRed,
    required CoreColor super.categoryRedContainer,
    required CoreColor super.onCategoryRedContainer,
    required CoreColor super.categoryRedOutline,
    required CoreColor super.categoryOrange,
    required CoreColor super.onCategoryOrange,
    required CoreColor super.categoryOrangeContainer,
    required CoreColor super.onCategoryOrangeContainer,
    required CoreColor super.categoryOrangeOutline,
    required CoreColor super.categoryYellow,
    required CoreColor super.onCategoryYellow,
    required CoreColor super.categoryYellowContainer,
    required CoreColor super.onCategoryYellowContainer,
    required CoreColor super.categoryYellowOutline,
    required CoreColor super.categoryGreen,
    required CoreColor super.onCategoryGreen,
    required CoreColor super.categoryGreenContainer,
    required CoreColor super.onCategoryGreenContainer,
    required CoreColor super.categoryGreenOutline,
    required CoreColor super.categoryBlue,
    required CoreColor super.onCategoryBlue,
    required CoreColor super.categoryBlueContainer,
    required CoreColor super.onCategoryBlueContainer,
    required CoreColor super.categoryBlueOutline,
    required CoreColor super.categoryPurple,
    required CoreColor super.onCategoryPurple,
    required CoreColor super.categoryPurpleContainer,
    required CoreColor super.onCategoryPurpleContainer,
    required CoreColor super.categoryPurpleOutline,
    required CoreColor super.categoryPink,
    required CoreColor super.onCategoryPink,
    required CoreColor super.categoryPinkContainer,
    required CoreColor super.onCategoryPinkContainer,
    required CoreColor super.categoryPinkOutline,
    required CoreColor super.categoryBrown,
    required CoreColor super.onCategoryBrown,
    required CoreColor super.categoryBrownContainer,
    required CoreColor super.onCategoryBrownContainer,
    required CoreColor super.categoryBrownOutline,
    required CoreColor super.categoryGray,
    required CoreColor super.onCategoryGray,
    required CoreColor super.categoryGrayContainer,
    required CoreColor super.onCategoryGrayContainer,
    required CoreColor super.categoryGrayOutline,
  }) : super(
         surface: surface,
         surfaceDim: surfaceDim,
         surfaceBright: surfaceBright,
         surfaceContainerLowest: surfaceContainerLowest,
         surfaceContainerLow: surfaceContainerLow,
         surfaceContainer: surfaceContainer,
         surfaceContainerHigh: surfaceContainerHigh,
         surfaceContainerHighest: surfaceContainerHighest,
         onSurface: onSurface,
         onSurfaceVariant: onSurfaceVariant,
         placeholder: placeholder,
         link: link,
         onSurfaceSubtle: onSurfaceSubtle,
         surfaceRaised: surfaceRaised,
         surfaceTint: surfaceTint,
         onPrimary: onPrimary,
         primaryContainer: primaryContainer,
         onPrimaryContainer: onPrimaryContainer,
         primaryFixed: primaryFixed,
         primaryFixedDim: primaryFixedDim,
         onPrimaryFixed: onPrimaryFixed,
         onPrimaryFixedVariant: onPrimaryFixedVariant,
         primaryText: primaryText,
         primaryTextLarge: primaryTextLarge,
         onSecondary: onSecondary,
         secondaryContainer: secondaryContainer,
         onSecondaryContainer: onSecondaryContainer,
         secondaryFixed: secondaryFixed,
         secondaryFixedDim: secondaryFixedDim,
         onSecondaryFixed: onSecondaryFixed,
         onSecondaryFixedVariant: onSecondaryFixedVariant,
         tertiary: tertiary,
         onTertiary: onTertiary,
         tertiaryContainer: tertiaryContainer,
         onTertiaryContainer: onTertiaryContainer,
         tertiaryFixed: tertiaryFixed,
         tertiaryFixedDim: tertiaryFixedDim,
         onTertiaryFixed: onTertiaryFixed,
         onTertiaryFixedVariant: onTertiaryFixedVariant,
         onError: onError,
         errorContainer: errorContainer,
         onErrorContainer: onErrorContainer,
         errorStrong: errorStrong,
         focusRing: focusRing,
         primaryHover: primaryHover,
         primaryPressed: primaryPressed,
         secondaryHover: secondaryHover,
         secondaryPressed: secondaryPressed,
         errorPressed: errorPressed,
         onSuccess: onSuccess,
         successContainer: successContainer,
         onSuccessContainer: onSuccessContainer,
         onWarning: onWarning,
         warningContainer: warningContainer,
         onWarningContainer: onWarningContainer,
         onInfo: onInfo,
         infoContainer: infoContainer,
         onInfoContainer: onInfoContainer,
         errorIcon: errorIcon,
         successIcon: successIcon,
         warningIcon: warningIcon,
         infoIcon: infoIcon,
         outline: outline,
         outlineVariant: outlineVariant,
         outlineSubtle: outlineSubtle,
         inverseSurface: inverseSurface,
         inverseOnSurface: inverseOnSurface,
         inversePrimary: inversePrimary,
         shadow: shadow,
         surfaceHighlight: surfaceHighlight,
         scrim: scrim,
         disabledContent: disabledContent,
         disabledContainer: disabledContainer,
         disabledOutline: disabledOutline,
         syntaxKeyword: syntaxKeyword,
         syntaxType: syntaxType,
         syntaxFunction: syntaxFunction,
         syntaxString: syntaxString,
       );

  /// Const default resolved scheme — every slot is a token reference
  /// (`var(--color-X)` on Web / cached ARGB on Flutter), so it is complete.
  const ResolvedColorScheme.tokenized() : super.tokenized();

  @override
  CoreColor get surface => super.surface!;

  @override
  CoreColor get surfaceDim => super.surfaceDim!;

  @override
  CoreColor get surfaceBright => super.surfaceBright!;

  @override
  CoreColor get surfaceContainerLowest => super.surfaceContainerLowest!;

  @override
  CoreColor get surfaceContainerLow => super.surfaceContainerLow!;

  @override
  CoreColor get surfaceContainer => super.surfaceContainer!;

  @override
  CoreColor get surfaceContainerHigh => super.surfaceContainerHigh!;

  @override
  CoreColor get surfaceContainerHighest => super.surfaceContainerHighest!;

  @override
  CoreColor get onSurface => super.onSurface!;

  @override
  CoreColor get onSurfaceVariant => super.onSurfaceVariant!;

  @override
  CoreColor get placeholder => super.placeholder!;

  @override
  CoreColor get link => super.link!;

  @override
  CoreColor get onSurfaceSubtle => super.onSurfaceSubtle!;

  @override
  CoreColor get surfaceRaised => super.surfaceRaised!;

  @override
  CoreColor get surfaceTint => super.surfaceTint!;

  @override
  CoreColor get onPrimary => super.onPrimary!;

  @override
  CoreColor get primaryContainer => super.primaryContainer!;

  @override
  CoreColor get onPrimaryContainer => super.onPrimaryContainer!;

  @override
  CoreColor get primaryFixed => super.primaryFixed!;

  @override
  CoreColor get primaryFixedDim => super.primaryFixedDim!;

  @override
  CoreColor get onPrimaryFixed => super.onPrimaryFixed!;

  @override
  CoreColor get onPrimaryFixedVariant => super.onPrimaryFixedVariant!;

  @override
  CoreColor get primaryText => super.primaryText!;

  @override
  CoreColor get primaryTextLarge => super.primaryTextLarge!;

  @override
  CoreColor get onSecondary => super.onSecondary!;

  @override
  CoreColor get secondaryContainer => super.secondaryContainer!;

  @override
  CoreColor get onSecondaryContainer => super.onSecondaryContainer!;

  @override
  CoreColor get secondaryFixed => super.secondaryFixed!;

  @override
  CoreColor get secondaryFixedDim => super.secondaryFixedDim!;

  @override
  CoreColor get onSecondaryFixed => super.onSecondaryFixed!;

  @override
  CoreColor get onSecondaryFixedVariant => super.onSecondaryFixedVariant!;

  @override
  CoreColor get tertiary => super.tertiary!;

  @override
  CoreColor get onTertiary => super.onTertiary!;

  @override
  CoreColor get tertiaryContainer => super.tertiaryContainer!;

  @override
  CoreColor get onTertiaryContainer => super.onTertiaryContainer!;

  @override
  CoreColor get tertiaryFixed => super.tertiaryFixed!;

  @override
  CoreColor get tertiaryFixedDim => super.tertiaryFixedDim!;

  @override
  CoreColor get onTertiaryFixed => super.onTertiaryFixed!;

  @override
  CoreColor get onTertiaryFixedVariant => super.onTertiaryFixedVariant!;

  @override
  CoreColor get onError => super.onError!;

  @override
  CoreColor get errorContainer => super.errorContainer!;

  @override
  CoreColor get onErrorContainer => super.onErrorContainer!;

  @override
  CoreColor get errorStrong => super.errorStrong!;

  @override
  CoreColor get focusRing => super.focusRing!;

  @override
  CoreColor get primaryHover => super.primaryHover!;

  @override
  CoreColor get primaryPressed => super.primaryPressed!;

  @override
  CoreColor get secondaryHover => super.secondaryHover!;

  @override
  CoreColor get secondaryPressed => super.secondaryPressed!;

  @override
  CoreColor get errorPressed => super.errorPressed!;

  @override
  CoreColor get onSuccess => super.onSuccess!;

  @override
  CoreColor get successContainer => super.successContainer!;

  @override
  CoreColor get onSuccessContainer => super.onSuccessContainer!;

  @override
  CoreColor get onWarning => super.onWarning!;

  @override
  CoreColor get warningContainer => super.warningContainer!;

  @override
  CoreColor get onWarningContainer => super.onWarningContainer!;

  @override
  CoreColor get onInfo => super.onInfo!;

  @override
  CoreColor get infoContainer => super.infoContainer!;

  @override
  CoreColor get onInfoContainer => super.onInfoContainer!;

  @override
  CoreColor get errorIcon => super.errorIcon!;

  @override
  CoreColor get successIcon => super.successIcon!;

  @override
  CoreColor get warningIcon => super.warningIcon!;

  @override
  CoreColor get infoIcon => super.infoIcon!;

  @override
  CoreColor get outline => super.outline!;

  @override
  CoreColor get outlineVariant => super.outlineVariant!;

  @override
  CoreColor get outlineSubtle => super.outlineSubtle!;

  @override
  CoreColor get inverseSurface => super.inverseSurface!;

  @override
  CoreColor get inverseOnSurface => super.inverseOnSurface!;

  @override
  CoreColor get inversePrimary => super.inversePrimary!;

  @override
  CoreColor get shadow => super.shadow!;

  /// The tint an inset highlight is drawn in — always resolved, derived
  /// from the surface when the palette states none.
  @override
  CoreColor get surfaceHighlight => super.surfaceHighlight!;

  @override
  CoreColor get scrim => super.scrim!;

  @override
  CoreColor get disabledContent => super.disabledContent!;

  @override
  CoreColor get disabledContainer => super.disabledContainer!;

  @override
  CoreColor get disabledOutline => super.disabledOutline!;

  @override
  CoreColor get syntaxKeyword => super.syntaxKeyword!;

  @override
  CoreColor get syntaxType => super.syntaxType!;

  @override
  CoreColor get syntaxFunction => super.syntaxFunction!;

  @override
  CoreColor get syntaxString => super.syntaxString!;

  @override
  CoreColor get categoryRed => super.categoryRed!;

  @override
  CoreColor get onCategoryRed => super.onCategoryRed!;

  @override
  CoreColor get categoryRedContainer => super.categoryRedContainer!;

  @override
  CoreColor get onCategoryRedContainer => super.onCategoryRedContainer!;

  @override
  CoreColor get categoryRedOutline => super.categoryRedOutline!;

  @override
  CoreColor get categoryOrange => super.categoryOrange!;

  @override
  CoreColor get onCategoryOrange => super.onCategoryOrange!;

  @override
  CoreColor get categoryOrangeContainer => super.categoryOrangeContainer!;

  @override
  CoreColor get onCategoryOrangeContainer => super.onCategoryOrangeContainer!;

  @override
  CoreColor get categoryOrangeOutline => super.categoryOrangeOutline!;

  @override
  CoreColor get categoryYellow => super.categoryYellow!;

  @override
  CoreColor get onCategoryYellow => super.onCategoryYellow!;

  @override
  CoreColor get categoryYellowContainer => super.categoryYellowContainer!;

  @override
  CoreColor get onCategoryYellowContainer => super.onCategoryYellowContainer!;

  @override
  CoreColor get categoryYellowOutline => super.categoryYellowOutline!;

  @override
  CoreColor get categoryGreen => super.categoryGreen!;

  @override
  CoreColor get onCategoryGreen => super.onCategoryGreen!;

  @override
  CoreColor get categoryGreenContainer => super.categoryGreenContainer!;

  @override
  CoreColor get onCategoryGreenContainer => super.onCategoryGreenContainer!;

  @override
  CoreColor get categoryGreenOutline => super.categoryGreenOutline!;

  @override
  CoreColor get categoryBlue => super.categoryBlue!;

  @override
  CoreColor get onCategoryBlue => super.onCategoryBlue!;

  @override
  CoreColor get categoryBlueContainer => super.categoryBlueContainer!;

  @override
  CoreColor get onCategoryBlueContainer => super.onCategoryBlueContainer!;

  @override
  CoreColor get categoryBlueOutline => super.categoryBlueOutline!;

  @override
  CoreColor get categoryPurple => super.categoryPurple!;

  @override
  CoreColor get onCategoryPurple => super.onCategoryPurple!;

  @override
  CoreColor get categoryPurpleContainer => super.categoryPurpleContainer!;

  @override
  CoreColor get onCategoryPurpleContainer => super.onCategoryPurpleContainer!;

  @override
  CoreColor get categoryPurpleOutline => super.categoryPurpleOutline!;

  @override
  CoreColor get categoryPink => super.categoryPink!;

  @override
  CoreColor get onCategoryPink => super.onCategoryPink!;

  @override
  CoreColor get categoryPinkContainer => super.categoryPinkContainer!;

  @override
  CoreColor get onCategoryPinkContainer => super.onCategoryPinkContainer!;

  @override
  CoreColor get categoryPinkOutline => super.categoryPinkOutline!;

  @override
  CoreColor get categoryBrown => super.categoryBrown!;

  @override
  CoreColor get onCategoryBrown => super.onCategoryBrown!;

  @override
  CoreColor get categoryBrownContainer => super.categoryBrownContainer!;

  @override
  CoreColor get onCategoryBrownContainer => super.onCategoryBrownContainer!;

  @override
  CoreColor get categoryBrownOutline => super.categoryBrownOutline!;

  @override
  CoreColor get categoryGray => super.categoryGray!;

  @override
  CoreColor get onCategoryGray => super.onCategoryGray!;

  @override
  CoreColor get categoryGrayContainer => super.categoryGrayContainer!;

  @override
  CoreColor get onCategoryGrayContainer => super.onCategoryGrayContainer!;

  @override
  CoreColor get categoryGrayOutline => super.categoryGrayOutline!;
}
