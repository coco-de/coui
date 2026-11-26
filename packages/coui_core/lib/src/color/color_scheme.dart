import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/color_conversion.dart';
import 'package:coui_core/src/color/color_presets.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/color/resolved_color_scheme.dart';
import 'package:coui_core/src/color/syntax_palette.dart';
import 'package:coui_core/src/theme/brightness.dart';
import 'package:meta/meta.dart';

/// How much lighter than its surface a derived highlight sits.
///
/// One delta for both modes. A fixed white would read as a rim on a
/// dark page and as nothing at all on a light one, where the surface is
/// already near the top of the range; lifting from wherever the surface
/// actually is gives a rim in both, and keeps the palette's own hue
/// rather than introducing a neutral no palette asked for.
const double _kDerivedHighlightLift = 0.12;

/// A highlight derived from the surface it will sit on.
///
/// Used when a palette states no [CoreColorScheme.surfaceHighlight] —
/// see that field for why leaving it unresolved is not an option.
///
/// Public so the colour-token accessor can use the same function: token
/// reads are the path the painted value actually takes, and a
/// derivation that lived only in [CoreColorScheme.resolved] would look
/// right in a unit test and never reach a pixel.
CoreColor deriveSurfaceHighlight(CoreColor surface) {
  final hsl = CoreColorConversion.colorToHSL(surface);
  final lifted = hsl.l + _kDerivedHighlightLift;

  return CoreColorConversion.fromHSL(
    hsl.h,
    hsl.s,
    lifted > 1 ? 1 : lifted,
    hsl.a,
  );
}

/// CoUI color scheme built from M3 Semantic tokens (designer spec).
///
/// **M3 Semantic tokens**: surface, onSurface, primary, onPrimary,
/// primaryContainer, tertiary, error, outline, etc.
///
/// **Category slots**: nine hues × five slots (`categoryRed` …
/// `categoryGrayOutline`) that tell things apart without meaning anything.
/// Not a brand's colours — every mapping writes them from
/// [CoreCategoryPalette] through [CoreCategoryPalette.applyTo].
///
/// **Syntax slots**: four code-highlighting colours (`syntaxKeyword`,
/// `syntaxType`, `syntaxFunction`, `syntaxString`). Every mapping writes
/// them through [CoreSyntaxPalette.applyTo]; three read the brand-less
/// [CoreSyntaxPalette], and `syntaxFunction` the brand's own info ramp.
@immutable
class CoreColorScheme {
  /// Build a colour scheme. Every supplied raw [CoreColor] is wrapped
  /// with its matching [CoreColorToken] so that downstream Web renderers
  /// can emit `var(--color-X)` and Flutter renderers can fast-path the
  /// cached ARGB.
  CoreColorScheme({
    // ── M3 Semantic: required ──
    required CoreColor primary,
    required CoreColor secondary,
    required CoreColor error,
    required CoreColor success,
    required CoreColor warning,
    required CoreColor info,
    // ── M3 Semantic: Surface ──
    CoreColor? surface,
    CoreColor? surfaceDim,
    CoreColor? surfaceBright,
    CoreColor? surfaceContainerLowest,
    CoreColor? surfaceContainerLow,
    CoreColor? surfaceContainer,
    CoreColor? surfaceContainerHigh,
    CoreColor? surfaceContainerHighest,
    CoreColor? onSurface,
    CoreColor? onSurfaceVariant,
    CoreColor? placeholder,
    CoreColor? link,
    CoreColor? onSurfaceSubtle,
    CoreColor? surfaceRaised,
    CoreColor? surfaceTint,
    CoreColor? onPrimary,
    CoreColor? primaryContainer,
    CoreColor? onPrimaryContainer,
    CoreColor? primaryFixed,
    CoreColor? primaryFixedDim,
    CoreColor? onPrimaryFixed,
    CoreColor? onPrimaryFixedVariant,
    CoreColor? primaryText,
    CoreColor? primaryTextLarge,
    CoreColor? onSecondary,
    CoreColor? secondaryContainer,
    CoreColor? onSecondaryContainer,
    CoreColor? secondaryFixed,
    CoreColor? secondaryFixedDim,
    CoreColor? onSecondaryFixed,
    CoreColor? onSecondaryFixedVariant,
    // ── M3 Semantic: Tertiary ──
    CoreColor? tertiary,
    CoreColor? onTertiary,
    CoreColor? tertiaryContainer,
    CoreColor? onTertiaryContainer,
    CoreColor? tertiaryFixed,
    CoreColor? tertiaryFixedDim,
    CoreColor? onTertiaryFixed,
    CoreColor? onTertiaryFixedVariant,
    CoreColor? onError,
    CoreColor? errorContainer,
    CoreColor? onErrorContainer,
    // Pressed-state background for `Button` destructive (B2 opaque
    // token-swap model, `CoUI_Button_State_Layer_Decision.md` §9) —
    // deliberately its own slot rather than reusing `errorContainer`:
    // the two answer different questions (a muted container fill vs. a
    // *more* emphasised error fill for the pressed step) and the Figma
    // source token (`color/error-strong`) is itself independent.
    CoreColor? errorStrong,
    CoreColor? focusRing,
    CoreColor? primaryHover,
    CoreColor? primaryPressed,
    CoreColor? secondaryHover,
    CoreColor? secondaryPressed,
    CoreColor? errorPressed,
    CoreColor? onSuccess,
    CoreColor? successContainer,
    CoreColor? onSuccessContainer,
    CoreColor? onWarning,
    CoreColor? warningContainer,
    CoreColor? onWarningContainer,
    CoreColor? onInfo,
    CoreColor? infoContainer,
    CoreColor? onInfoContainer,
    CoreColor? errorIcon,
    CoreColor? successIcon,
    CoreColor? warningIcon,
    CoreColor? infoIcon,
    // ── M3 Semantic: Outline ──
    CoreColor? outline,
    CoreColor? outlineVariant,
    CoreColor? outlineSubtle,
    // ── M3 Semantic: Inverse ──
    CoreColor? inverseSurface,
    CoreColor? inverseOnSurface,
    CoreColor? inversePrimary,
    // ── M3 Semantic: Special ──
    CoreColor? shadow,
    CoreColor? surfaceHighlight,
    CoreColor? scrim,
    // ── Disabled (nullable, tagged) ──
    CoreColor? disabledContent,
    CoreColor? disabledContainer,
    CoreColor? disabledOutline,
    // ── Syntax (code highlighting) ──
    CoreColor? syntaxKeyword,
    CoreColor? syntaxType,
    CoreColor? syntaxFunction,
    CoreColor? syntaxString,
    // ── Category (brand-neutral; values from CoreCategoryPalette) ──
    CoreColor? categoryRed,
    CoreColor? onCategoryRed,
    CoreColor? categoryRedContainer,
    CoreColor? onCategoryRedContainer,
    CoreColor? categoryRedOutline,
    CoreColor? categoryOrange,
    CoreColor? onCategoryOrange,
    CoreColor? categoryOrangeContainer,
    CoreColor? onCategoryOrangeContainer,
    CoreColor? categoryOrangeOutline,
    CoreColor? categoryYellow,
    CoreColor? onCategoryYellow,
    CoreColor? categoryYellowContainer,
    CoreColor? onCategoryYellowContainer,
    CoreColor? categoryYellowOutline,
    CoreColor? categoryGreen,
    CoreColor? onCategoryGreen,
    CoreColor? categoryGreenContainer,
    CoreColor? onCategoryGreenContainer,
    CoreColor? categoryGreenOutline,
    CoreColor? categoryBlue,
    CoreColor? onCategoryBlue,
    CoreColor? categoryBlueContainer,
    CoreColor? onCategoryBlueContainer,
    CoreColor? categoryBlueOutline,
    CoreColor? categoryPurple,
    CoreColor? onCategoryPurple,
    CoreColor? categoryPurpleContainer,
    CoreColor? onCategoryPurpleContainer,
    CoreColor? categoryPurpleOutline,
    CoreColor? categoryPink,
    CoreColor? onCategoryPink,
    CoreColor? categoryPinkContainer,
    CoreColor? onCategoryPinkContainer,
    CoreColor? categoryPinkOutline,
    CoreColor? categoryBrown,
    CoreColor? onCategoryBrown,
    CoreColor? categoryBrownContainer,
    CoreColor? onCategoryBrownContainer,
    CoreColor? categoryBrownOutline,
    CoreColor? categoryGray,
    CoreColor? onCategoryGray,
    CoreColor? categoryGrayContainer,
    CoreColor? onCategoryGrayContainer,
    CoreColor? categoryGrayOutline,
  }) : primary = _tag(primary, CoreColors.primary),
       secondary = _tag(secondary, CoreColors.secondary),
       error = _tag(error, CoreColors.error),
       success = _tag(success, CoreColors.success),
       warning = _tag(warning, CoreColors.warning),
       info = _tag(info, CoreColors.info),
       surface = _tagN(surface, CoreColors.surface),
       surfaceDim = _tagN(surfaceDim, CoreColors.surfaceDim),
       surfaceBright = _tagN(surfaceBright, CoreColors.surfaceBright),
       surfaceContainerLowest = _tagN(
         surfaceContainerLowest,
         CoreColors.surfaceContainerLowest,
       ),
       surfaceContainerLow = _tagN(
         surfaceContainerLow,
         CoreColors.surfaceContainerLow,
       ),
       surfaceContainer = _tagN(surfaceContainer, CoreColors.surfaceContainer),
       surfaceContainerHigh = _tagN(
         surfaceContainerHigh,
         CoreColors.surfaceContainerHigh,
       ),
       surfaceContainerHighest = _tagN(
         surfaceContainerHighest,
         CoreColors.surfaceContainerHighest,
       ),
       onSurface = _tagN(onSurface, CoreColors.onSurface),
       onSurfaceVariant = _tagN(onSurfaceVariant, CoreColors.onSurfaceVariant),
       placeholder = _tagN(placeholder, CoreColors.placeholder),
       link = _tagN(link, CoreColors.link),
       onSurfaceSubtle = _tagN(onSurfaceSubtle, CoreColors.onSurfaceSubtle),
       surfaceRaised = _tagN(surfaceRaised, CoreColors.surfaceRaised),
       surfaceTint = _tagN(surfaceTint, CoreColors.surfaceTint),
       onPrimary = _tagN(onPrimary, CoreColors.onPrimary),
       primaryContainer = _tagN(primaryContainer, CoreColors.primaryContainer),
       onPrimaryContainer = _tagN(
         onPrimaryContainer,
         CoreColors.onPrimaryContainer,
       ),
       primaryFixed = _tagN(primaryFixed, CoreColors.primaryFixed),
       primaryFixedDim = _tagN(primaryFixedDim, CoreColors.primaryFixedDim),
       onPrimaryFixed = _tagN(onPrimaryFixed, CoreColors.onPrimaryFixed),
       onPrimaryFixedVariant = _tagN(
         onPrimaryFixedVariant,
         CoreColors.onPrimaryFixedVariant,
       ),
       primaryText = _tagN(primaryText, CoreColors.primaryText),
       primaryTextLarge = _tagN(primaryTextLarge, CoreColors.primaryTextLarge),
       onSecondary = _tagN(onSecondary, CoreColors.onSecondary),
       secondaryContainer = _tagN(
         secondaryContainer,
         CoreColors.secondaryContainer,
       ),
       onSecondaryContainer = _tagN(
         onSecondaryContainer,
         CoreColors.onSecondaryContainer,
       ),
       secondaryFixed = _tagN(secondaryFixed, CoreColors.secondaryFixed),
       secondaryFixedDim = _tagN(
         secondaryFixedDim,
         CoreColors.secondaryFixedDim,
       ),
       onSecondaryFixed = _tagN(onSecondaryFixed, CoreColors.onSecondaryFixed),
       onSecondaryFixedVariant = _tagN(
         onSecondaryFixedVariant,
         CoreColors.onSecondaryFixedVariant,
       ),
       tertiary = _tagN(tertiary, CoreColors.tertiary),
       onTertiary = _tagN(onTertiary, CoreColors.onTertiary),
       tertiaryContainer = _tagN(
         tertiaryContainer,
         CoreColors.tertiaryContainer,
       ),
       onTertiaryContainer = _tagN(
         onTertiaryContainer,
         CoreColors.onTertiaryContainer,
       ),
       tertiaryFixed = _tagN(tertiaryFixed, CoreColors.tertiaryFixed),
       tertiaryFixedDim = _tagN(tertiaryFixedDim, CoreColors.tertiaryFixedDim),
       onTertiaryFixed = _tagN(onTertiaryFixed, CoreColors.onTertiaryFixed),
       onTertiaryFixedVariant = _tagN(
         onTertiaryFixedVariant,
         CoreColors.onTertiaryFixedVariant,
       ),
       onError = _tagN(onError, CoreColors.onError),
       errorContainer = _tagN(errorContainer, CoreColors.errorContainer),
       onErrorContainer = _tagN(onErrorContainer, CoreColors.onErrorContainer),
       errorStrong = _tagN(errorStrong, CoreColors.errorStrong),
       focusRing = _tagN(focusRing, CoreColors.focusRing),
       primaryHover = _tagN(primaryHover, CoreColors.primaryHover),
       primaryPressed = _tagN(primaryPressed, CoreColors.primaryPressed),
       secondaryHover = _tagN(secondaryHover, CoreColors.secondaryHover),
       secondaryPressed = _tagN(secondaryPressed, CoreColors.secondaryPressed),
       errorPressed = _tagN(errorPressed, CoreColors.errorPressed),
       onSuccess = _tagN(onSuccess, CoreColors.onSuccess),
       successContainer = _tagN(successContainer, CoreColors.successContainer),
       onSuccessContainer = _tagN(
         onSuccessContainer,
         CoreColors.onSuccessContainer,
       ),
       onWarning = _tagN(onWarning, CoreColors.onWarning),
       warningContainer = _tagN(warningContainer, CoreColors.warningContainer),
       onWarningContainer = _tagN(
         onWarningContainer,
         CoreColors.onWarningContainer,
       ),
       onInfo = _tagN(onInfo, CoreColors.onInfo),
       infoContainer = _tagN(infoContainer, CoreColors.infoContainer),
       onInfoContainer = _tagN(onInfoContainer, CoreColors.onInfoContainer),
       errorIcon = _tagN(errorIcon, CoreColors.errorIcon),
       successIcon = _tagN(successIcon, CoreColors.successIcon),
       warningIcon = _tagN(warningIcon, CoreColors.warningIcon),
       infoIcon = _tagN(infoIcon, CoreColors.infoIcon),
       outline = _tagN(outline, CoreColors.outline),
       outlineVariant = _tagN(outlineVariant, CoreColors.outlineVariant),
       outlineSubtle = _tagN(outlineSubtle, CoreColors.outlineSubtle),
       inverseSurface = _tagN(inverseSurface, CoreColors.inverseSurface),
       inverseOnSurface = _tagN(inverseOnSurface, CoreColors.inverseOnSurface),
       inversePrimary = _tagN(inversePrimary, CoreColors.inversePrimary),
       shadow = _tagN(shadow, CoreColors.shadow),
       surfaceHighlight = _tagN(
         surfaceHighlight,
         CoreColors.surfaceHighlight,
       ),
       scrim = _tagN(scrim, CoreColors.scrim),
       disabledContent = _tagN(disabledContent, CoreColors.disabledContent),
       disabledContainer = _tagN(
         disabledContainer,
         CoreColors.disabledContainer,
       ),
       disabledOutline = _tagN(disabledOutline, CoreColors.disabledOutline),
       syntaxKeyword = _tagN(syntaxKeyword, CoreColors.syntaxKeyword),
       syntaxType = _tagN(syntaxType, CoreColors.syntaxType),
       syntaxFunction = _tagN(syntaxFunction, CoreColors.syntaxFunction),
       syntaxString = _tagN(syntaxString, CoreColors.syntaxString),
       categoryRed = _tagN(categoryRed, CoreColors.categoryRed),
       onCategoryRed = _tagN(onCategoryRed, CoreColors.onCategoryRed),
       categoryRedContainer = _tagN(
         categoryRedContainer,
         CoreColors.categoryRedContainer,
       ),
       onCategoryRedContainer = _tagN(
         onCategoryRedContainer,
         CoreColors.onCategoryRedContainer,
       ),
       categoryRedOutline = _tagN(
         categoryRedOutline,
         CoreColors.categoryRedOutline,
       ),
       categoryOrange = _tagN(categoryOrange, CoreColors.categoryOrange),
       onCategoryOrange = _tagN(onCategoryOrange, CoreColors.onCategoryOrange),
       categoryOrangeContainer = _tagN(
         categoryOrangeContainer,
         CoreColors.categoryOrangeContainer,
       ),
       onCategoryOrangeContainer = _tagN(
         onCategoryOrangeContainer,
         CoreColors.onCategoryOrangeContainer,
       ),
       categoryOrangeOutline = _tagN(
         categoryOrangeOutline,
         CoreColors.categoryOrangeOutline,
       ),
       categoryYellow = _tagN(categoryYellow, CoreColors.categoryYellow),
       onCategoryYellow = _tagN(onCategoryYellow, CoreColors.onCategoryYellow),
       categoryYellowContainer = _tagN(
         categoryYellowContainer,
         CoreColors.categoryYellowContainer,
       ),
       onCategoryYellowContainer = _tagN(
         onCategoryYellowContainer,
         CoreColors.onCategoryYellowContainer,
       ),
       categoryYellowOutline = _tagN(
         categoryYellowOutline,
         CoreColors.categoryYellowOutline,
       ),
       categoryGreen = _tagN(categoryGreen, CoreColors.categoryGreen),
       onCategoryGreen = _tagN(onCategoryGreen, CoreColors.onCategoryGreen),
       categoryGreenContainer = _tagN(
         categoryGreenContainer,
         CoreColors.categoryGreenContainer,
       ),
       onCategoryGreenContainer = _tagN(
         onCategoryGreenContainer,
         CoreColors.onCategoryGreenContainer,
       ),
       categoryGreenOutline = _tagN(
         categoryGreenOutline,
         CoreColors.categoryGreenOutline,
       ),
       categoryBlue = _tagN(categoryBlue, CoreColors.categoryBlue),
       onCategoryBlue = _tagN(onCategoryBlue, CoreColors.onCategoryBlue),
       categoryBlueContainer = _tagN(
         categoryBlueContainer,
         CoreColors.categoryBlueContainer,
       ),
       onCategoryBlueContainer = _tagN(
         onCategoryBlueContainer,
         CoreColors.onCategoryBlueContainer,
       ),
       categoryBlueOutline = _tagN(
         categoryBlueOutline,
         CoreColors.categoryBlueOutline,
       ),
       categoryPurple = _tagN(categoryPurple, CoreColors.categoryPurple),
       onCategoryPurple = _tagN(onCategoryPurple, CoreColors.onCategoryPurple),
       categoryPurpleContainer = _tagN(
         categoryPurpleContainer,
         CoreColors.categoryPurpleContainer,
       ),
       onCategoryPurpleContainer = _tagN(
         onCategoryPurpleContainer,
         CoreColors.onCategoryPurpleContainer,
       ),
       categoryPurpleOutline = _tagN(
         categoryPurpleOutline,
         CoreColors.categoryPurpleOutline,
       ),
       categoryPink = _tagN(categoryPink, CoreColors.categoryPink),
       onCategoryPink = _tagN(onCategoryPink, CoreColors.onCategoryPink),
       categoryPinkContainer = _tagN(
         categoryPinkContainer,
         CoreColors.categoryPinkContainer,
       ),
       onCategoryPinkContainer = _tagN(
         onCategoryPinkContainer,
         CoreColors.onCategoryPinkContainer,
       ),
       categoryPinkOutline = _tagN(
         categoryPinkOutline,
         CoreColors.categoryPinkOutline,
       ),
       categoryBrown = _tagN(categoryBrown, CoreColors.categoryBrown),
       onCategoryBrown = _tagN(onCategoryBrown, CoreColors.onCategoryBrown),
       categoryBrownContainer = _tagN(
         categoryBrownContainer,
         CoreColors.categoryBrownContainer,
       ),
       onCategoryBrownContainer = _tagN(
         onCategoryBrownContainer,
         CoreColors.onCategoryBrownContainer,
       ),
       categoryBrownOutline = _tagN(
         categoryBrownOutline,
         CoreColors.categoryBrownOutline,
       ),
       categoryGray = _tagN(categoryGray, CoreColors.categoryGray),
       onCategoryGray = _tagN(onCategoryGray, CoreColors.onCategoryGray),
       categoryGrayContainer = _tagN(
         categoryGrayContainer,
         CoreColors.categoryGrayContainer,
       ),
       onCategoryGrayContainer = _tagN(
         onCategoryGrayContainer,
         CoreColors.onCategoryGrayContainer,
       ),
       categoryGrayOutline = _tagN(
         categoryGrayOutline,
         CoreColors.categoryGrayOutline,
       );

  /// Parse from a CoUI theme map (OKLch or hex strings).
  factory CoreColorScheme.fromMap(Map<String, dynamic> map) {
    return CoreColorScheme(
      primary: _required(map, 'primary'),
      secondary: _required(map, 'secondary'),
      error: _required(map, 'error'),
      success: _required(map, 'success'),
      warning: _required(map, 'warning'),
      info: _required(map, 'info'),
      // M3 Semantic
      surface: _nullable(map, 'surface'),
      surfaceDim: _nullable(map, 'surface-dim'),
      surfaceBright: _nullable(map, 'surface-bright'),
      surfaceContainerLowest: _nullable(
        map,
        'surface-container-lowest',
      ),
      surfaceContainerLow: _nullable(
        map,
        'surface-container-low',
      ),
      surfaceContainer: _nullable(map, 'surface-container'),
      surfaceContainerHigh: _nullable(
        map,
        'surface-container-high',
      ),
      surfaceContainerHighest: _nullable(
        map,
        'surface-container-highest',
      ),
      onSurface: _nullable(map, 'on-surface'),
      onSurfaceVariant: _nullable(map, 'on-surface-variant'),
      placeholder: _nullable(map, 'placeholder'),
      link: _nullable(map, 'link'),
      onSurfaceSubtle: _nullable(map, 'on-surface-subtle'),
      surfaceRaised: _nullable(map, 'surface-raised'),
      surfaceTint: _nullable(map, 'surface-tint'),
      onPrimary: _nullable(map, 'on-primary'),
      primaryContainer: _nullable(map, 'primary-container'),
      onPrimaryContainer: _nullable(
        map,
        'on-primary-container',
      ),
      primaryFixed: _nullable(map, 'primary-fixed'),
      primaryFixedDim: _nullable(map, 'primary-fixed-dim'),
      onPrimaryFixed: _nullable(map, 'on-primary-fixed'),
      onPrimaryFixedVariant: _nullable(
        map,
        'on-primary-fixed-variant',
      ),
      primaryText: _nullable(map, 'primary-text'),
      primaryTextLarge: _nullable(map, 'primary-text-large'),
      onSecondary: _nullable(map, 'on-secondary'),
      secondaryContainer: _nullable(
        map,
        'secondary-container',
      ),
      onSecondaryContainer: _nullable(
        map,
        'on-secondary-container',
      ),
      secondaryFixed: _nullable(map, 'secondary-fixed'),
      secondaryFixedDim: _nullable(
        map,
        'secondary-fixed-dim',
      ),
      onSecondaryFixed: _nullable(map, 'on-secondary-fixed'),
      onSecondaryFixedVariant: _nullable(
        map,
        'on-secondary-fixed-variant',
      ),
      tertiary: _nullable(map, 'tertiary'),
      onTertiary: _nullable(map, 'on-tertiary'),
      tertiaryContainer: _nullable(map, 'tertiary-container'),
      onTertiaryContainer: _nullable(
        map,
        'on-tertiary-container',
      ),
      tertiaryFixed: _nullable(map, 'tertiary-fixed'),
      tertiaryFixedDim: _nullable(map, 'tertiary-fixed-dim'),
      onTertiaryFixed: _nullable(map, 'on-tertiary-fixed'),
      onTertiaryFixedVariant: _nullable(
        map,
        'on-tertiary-fixed-variant',
      ),
      onError: _nullable(map, 'on-error'),
      errorContainer: _nullable(map, 'error-container'),
      onErrorContainer: _nullable(map, 'on-error-container'),
      errorStrong: _nullable(map, 'error-strong'),
      focusRing: _nullable(map, 'focus-ring'),
      primaryHover: _nullable(map, 'primary-hover'),
      primaryPressed: _nullable(map, 'primary-pressed'),
      secondaryHover: _nullable(map, 'secondary-hover'),
      secondaryPressed: _nullable(map, 'secondary-pressed'),
      errorPressed: _nullable(map, 'error-pressed'),
      onSuccess: _nullable(map, 'on-success'),
      successContainer: _nullable(map, 'success-container'),
      onSuccessContainer: _nullable(
        map,
        'on-success-container',
      ),
      onWarning: _nullable(map, 'on-warning'),
      warningContainer: _nullable(map, 'warning-container'),
      onWarningContainer: _nullable(
        map,
        'on-warning-container',
      ),
      onInfo: _nullable(map, 'on-info'),
      infoContainer: _nullable(map, 'info-container'),
      onInfoContainer: _nullable(map, 'on-info-container'),
      errorIcon: _nullable(map, 'error-icon'),
      successIcon: _nullable(map, 'success-icon'),
      warningIcon: _nullable(map, 'warning-icon'),
      infoIcon: _nullable(map, 'info-icon'),
      outline: _nullable(map, 'outline'),
      outlineVariant: _nullable(map, 'outline-variant'),
      outlineSubtle: _nullable(map, 'outline-subtle'),
      inverseSurface: _nullable(map, 'inverse-surface'),
      inverseOnSurface: _nullable(map, 'inverse-on-surface'),
      inversePrimary: _nullable(map, 'inverse-primary'),
      shadow: _nullable(map, 'shadow'),
      surfaceHighlight: _nullable(map, 'surface-highlight'),
      scrim: _nullable(map, 'scrim'),
      // Disabled
      disabledContent: _nullable(map, 'disabled-content'),
      disabledContainer: _nullable(map, 'disabled-container'),
      disabledOutline: _nullable(map, 'disabled-outline'),
      // Syntax
      syntaxKeyword: _nullable(map, 'syntax-keyword'),
      syntaxType: _nullable(map, 'syntax-type'),
      syntaxFunction: _nullable(map, 'syntax-function'),
      syntaxString: _nullable(map, 'syntax-string'),
      // Category
      categoryRed: _nullable(map, 'category-red'),
      onCategoryRed: _nullable(map, 'on-category-red'),
      categoryRedContainer: _nullable(map, 'category-red-container'),
      onCategoryRedContainer: _nullable(map, 'on-category-red-container'),
      categoryRedOutline: _nullable(map, 'category-red-outline'),
      categoryOrange: _nullable(map, 'category-orange'),
      onCategoryOrange: _nullable(map, 'on-category-orange'),
      categoryOrangeContainer: _nullable(map, 'category-orange-container'),
      onCategoryOrangeContainer: _nullable(map, 'on-category-orange-container'),
      categoryOrangeOutline: _nullable(map, 'category-orange-outline'),
      categoryYellow: _nullable(map, 'category-yellow'),
      onCategoryYellow: _nullable(map, 'on-category-yellow'),
      categoryYellowContainer: _nullable(map, 'category-yellow-container'),
      onCategoryYellowContainer: _nullable(map, 'on-category-yellow-container'),
      categoryYellowOutline: _nullable(map, 'category-yellow-outline'),
      categoryGreen: _nullable(map, 'category-green'),
      onCategoryGreen: _nullable(map, 'on-category-green'),
      categoryGreenContainer: _nullable(map, 'category-green-container'),
      onCategoryGreenContainer: _nullable(map, 'on-category-green-container'),
      categoryGreenOutline: _nullable(map, 'category-green-outline'),
      categoryBlue: _nullable(map, 'category-blue'),
      onCategoryBlue: _nullable(map, 'on-category-blue'),
      categoryBlueContainer: _nullable(map, 'category-blue-container'),
      onCategoryBlueContainer: _nullable(map, 'on-category-blue-container'),
      categoryBlueOutline: _nullable(map, 'category-blue-outline'),
      categoryPurple: _nullable(map, 'category-purple'),
      onCategoryPurple: _nullable(map, 'on-category-purple'),
      categoryPurpleContainer: _nullable(map, 'category-purple-container'),
      onCategoryPurpleContainer: _nullable(map, 'on-category-purple-container'),
      categoryPurpleOutline: _nullable(map, 'category-purple-outline'),
      categoryPink: _nullable(map, 'category-pink'),
      onCategoryPink: _nullable(map, 'on-category-pink'),
      categoryPinkContainer: _nullable(map, 'category-pink-container'),
      onCategoryPinkContainer: _nullable(map, 'on-category-pink-container'),
      categoryPinkOutline: _nullable(map, 'category-pink-outline'),
      categoryBrown: _nullable(map, 'category-brown'),
      onCategoryBrown: _nullable(map, 'on-category-brown'),
      categoryBrownContainer: _nullable(map, 'category-brown-container'),
      onCategoryBrownContainer: _nullable(map, 'on-category-brown-container'),
      categoryBrownOutline: _nullable(map, 'category-brown-outline'),
      categoryGray: _nullable(map, 'category-gray'),
      onCategoryGray: _nullable(map, 'on-category-gray'),
      categoryGrayContainer: _nullable(map, 'category-gray-container'),
      onCategoryGrayContainer: _nullable(map, 'on-category-gray-container'),
      categoryGrayOutline: _nullable(map, 'category-gray-outline'),
    );
  }

  /// Builds a scheme whose every slot is [combine] of the matching slots
  /// of [a] and [b].
  ///
  /// Shared by every operation that walks two schemes slot by slot, so
  /// they cannot disagree about which slots exist; a source-reading test
  /// in `color_scheme_test.dart` holds this list to the equality list.
  /// The six root slots are non-null on both sides, and every combiner
  /// passed here returns non-null for two non-null inputs.
  CoreColorScheme._zipSlots(
    CoreColorScheme a,
    CoreColorScheme b,
    CoreColor? Function(CoreColor?, CoreColor?) combine,
  ) : this(
        surface: combine(a.surface, b.surface),
        surfaceDim: combine(a.surfaceDim, b.surfaceDim),
        surfaceBright: combine(a.surfaceBright, b.surfaceBright),
        surfaceContainerLowest: combine(
          a.surfaceContainerLowest,
          b.surfaceContainerLowest,
        ),
        surfaceContainerLow: combine(
          a.surfaceContainerLow,
          b.surfaceContainerLow,
        ),
        surfaceContainer: combine(a.surfaceContainer, b.surfaceContainer),
        surfaceContainerHigh: combine(
          a.surfaceContainerHigh,
          b.surfaceContainerHigh,
        ),
        surfaceContainerHighest: combine(
          a.surfaceContainerHighest,
          b.surfaceContainerHighest,
        ),
        onSurface: combine(a.onSurface, b.onSurface),
        onSurfaceVariant: combine(a.onSurfaceVariant, b.onSurfaceVariant),
        placeholder: combine(a.placeholder, b.placeholder),
        link: combine(a.link, b.link),
        onSurfaceSubtle: combine(a.onSurfaceSubtle, b.onSurfaceSubtle),
        surfaceRaised: combine(a.surfaceRaised, b.surfaceRaised),
        surfaceTint: combine(a.surfaceTint, b.surfaceTint),
        primary: combine(a.primary, b.primary)!,
        onPrimary: combine(a.onPrimary, b.onPrimary),
        primaryContainer: combine(a.primaryContainer, b.primaryContainer),
        onPrimaryContainer: combine(a.onPrimaryContainer, b.onPrimaryContainer),
        primaryFixed: combine(a.primaryFixed, b.primaryFixed),
        primaryFixedDim: combine(a.primaryFixedDim, b.primaryFixedDim),
        onPrimaryFixed: combine(a.onPrimaryFixed, b.onPrimaryFixed),
        onPrimaryFixedVariant: combine(
          a.onPrimaryFixedVariant,
          b.onPrimaryFixedVariant,
        ),
        primaryText: combine(a.primaryText, b.primaryText),
        primaryTextLarge: combine(a.primaryTextLarge, b.primaryTextLarge),
        secondary: combine(a.secondary, b.secondary)!,
        onSecondary: combine(a.onSecondary, b.onSecondary),
        secondaryContainer: combine(a.secondaryContainer, b.secondaryContainer),
        onSecondaryContainer: combine(
          a.onSecondaryContainer,
          b.onSecondaryContainer,
        ),
        secondaryFixed: combine(a.secondaryFixed, b.secondaryFixed),
        secondaryFixedDim: combine(a.secondaryFixedDim, b.secondaryFixedDim),
        onSecondaryFixed: combine(a.onSecondaryFixed, b.onSecondaryFixed),
        onSecondaryFixedVariant: combine(
          a.onSecondaryFixedVariant,
          b.onSecondaryFixedVariant,
        ),
        tertiary: combine(a.tertiary, b.tertiary),
        onTertiary: combine(a.onTertiary, b.onTertiary),
        tertiaryContainer: combine(a.tertiaryContainer, b.tertiaryContainer),
        onTertiaryContainer: combine(
          a.onTertiaryContainer,
          b.onTertiaryContainer,
        ),
        tertiaryFixed: combine(a.tertiaryFixed, b.tertiaryFixed),
        tertiaryFixedDim: combine(a.tertiaryFixedDim, b.tertiaryFixedDim),
        onTertiaryFixed: combine(a.onTertiaryFixed, b.onTertiaryFixed),
        onTertiaryFixedVariant: combine(
          a.onTertiaryFixedVariant,
          b.onTertiaryFixedVariant,
        ),
        error: combine(a.error, b.error)!,
        onError: combine(a.onError, b.onError),
        errorContainer: combine(a.errorContainer, b.errorContainer),
        onErrorContainer: combine(a.onErrorContainer, b.onErrorContainer),
        errorStrong: combine(a.errorStrong, b.errorStrong),
        focusRing: combine(a.focusRing, b.focusRing),
        primaryHover: combine(a.primaryHover, b.primaryHover),
        primaryPressed: combine(a.primaryPressed, b.primaryPressed),
        secondaryHover: combine(a.secondaryHover, b.secondaryHover),
        secondaryPressed: combine(a.secondaryPressed, b.secondaryPressed),
        errorPressed: combine(a.errorPressed, b.errorPressed),
        success: combine(a.success, b.success)!,
        onSuccess: combine(a.onSuccess, b.onSuccess),
        successContainer: combine(a.successContainer, b.successContainer),
        onSuccessContainer: combine(a.onSuccessContainer, b.onSuccessContainer),
        warning: combine(a.warning, b.warning)!,
        onWarning: combine(a.onWarning, b.onWarning),
        warningContainer: combine(a.warningContainer, b.warningContainer),
        onWarningContainer: combine(a.onWarningContainer, b.onWarningContainer),
        info: combine(a.info, b.info)!,
        onInfo: combine(a.onInfo, b.onInfo),
        infoContainer: combine(a.infoContainer, b.infoContainer),
        onInfoContainer: combine(a.onInfoContainer, b.onInfoContainer),
        errorIcon: combine(a.errorIcon, b.errorIcon),
        successIcon: combine(a.successIcon, b.successIcon),
        warningIcon: combine(a.warningIcon, b.warningIcon),
        infoIcon: combine(a.infoIcon, b.infoIcon),
        outline: combine(a.outline, b.outline),
        outlineVariant: combine(a.outlineVariant, b.outlineVariant),
        outlineSubtle: combine(a.outlineSubtle, b.outlineSubtle),
        inverseSurface: combine(a.inverseSurface, b.inverseSurface),
        inverseOnSurface: combine(a.inverseOnSurface, b.inverseOnSurface),
        inversePrimary: combine(a.inversePrimary, b.inversePrimary),
        shadow: combine(a.shadow, b.shadow),
        surfaceHighlight: combine(a.surfaceHighlight, b.surfaceHighlight),
        scrim: combine(a.scrim, b.scrim),
        disabledContent: combine(a.disabledContent, b.disabledContent),
        disabledContainer: combine(a.disabledContainer, b.disabledContainer),
        disabledOutline: combine(a.disabledOutline, b.disabledOutline),
        syntaxKeyword: combine(a.syntaxKeyword, b.syntaxKeyword),
        syntaxType: combine(a.syntaxType, b.syntaxType),
        syntaxFunction: combine(a.syntaxFunction, b.syntaxFunction),
        syntaxString: combine(a.syntaxString, b.syntaxString),
        categoryRed: combine(a.categoryRed, b.categoryRed),
        onCategoryRed: combine(a.onCategoryRed, b.onCategoryRed),
        categoryRedContainer: combine(
          a.categoryRedContainer,
          b.categoryRedContainer,
        ),
        onCategoryRedContainer: combine(
          a.onCategoryRedContainer,
          b.onCategoryRedContainer,
        ),
        categoryRedOutline: combine(a.categoryRedOutline, b.categoryRedOutline),
        categoryOrange: combine(a.categoryOrange, b.categoryOrange),
        onCategoryOrange: combine(a.onCategoryOrange, b.onCategoryOrange),
        categoryOrangeContainer: combine(
          a.categoryOrangeContainer,
          b.categoryOrangeContainer,
        ),
        onCategoryOrangeContainer: combine(
          a.onCategoryOrangeContainer,
          b.onCategoryOrangeContainer,
        ),
        categoryOrangeOutline: combine(
          a.categoryOrangeOutline,
          b.categoryOrangeOutline,
        ),
        categoryYellow: combine(a.categoryYellow, b.categoryYellow),
        onCategoryYellow: combine(a.onCategoryYellow, b.onCategoryYellow),
        categoryYellowContainer: combine(
          a.categoryYellowContainer,
          b.categoryYellowContainer,
        ),
        onCategoryYellowContainer: combine(
          a.onCategoryYellowContainer,
          b.onCategoryYellowContainer,
        ),
        categoryYellowOutline: combine(
          a.categoryYellowOutline,
          b.categoryYellowOutline,
        ),
        categoryGreen: combine(a.categoryGreen, b.categoryGreen),
        onCategoryGreen: combine(a.onCategoryGreen, b.onCategoryGreen),
        categoryGreenContainer: combine(
          a.categoryGreenContainer,
          b.categoryGreenContainer,
        ),
        onCategoryGreenContainer: combine(
          a.onCategoryGreenContainer,
          b.onCategoryGreenContainer,
        ),
        categoryGreenOutline: combine(
          a.categoryGreenOutline,
          b.categoryGreenOutline,
        ),
        categoryBlue: combine(a.categoryBlue, b.categoryBlue),
        onCategoryBlue: combine(a.onCategoryBlue, b.onCategoryBlue),
        categoryBlueContainer: combine(
          a.categoryBlueContainer,
          b.categoryBlueContainer,
        ),
        onCategoryBlueContainer: combine(
          a.onCategoryBlueContainer,
          b.onCategoryBlueContainer,
        ),
        categoryBlueOutline: combine(
          a.categoryBlueOutline,
          b.categoryBlueOutline,
        ),
        categoryPurple: combine(a.categoryPurple, b.categoryPurple),
        onCategoryPurple: combine(a.onCategoryPurple, b.onCategoryPurple),
        categoryPurpleContainer: combine(
          a.categoryPurpleContainer,
          b.categoryPurpleContainer,
        ),
        onCategoryPurpleContainer: combine(
          a.onCategoryPurpleContainer,
          b.onCategoryPurpleContainer,
        ),
        categoryPurpleOutline: combine(
          a.categoryPurpleOutline,
          b.categoryPurpleOutline,
        ),
        categoryPink: combine(a.categoryPink, b.categoryPink),
        onCategoryPink: combine(a.onCategoryPink, b.onCategoryPink),
        categoryPinkContainer: combine(
          a.categoryPinkContainer,
          b.categoryPinkContainer,
        ),
        onCategoryPinkContainer: combine(
          a.onCategoryPinkContainer,
          b.onCategoryPinkContainer,
        ),
        categoryPinkOutline: combine(
          a.categoryPinkOutline,
          b.categoryPinkOutline,
        ),
        categoryBrown: combine(a.categoryBrown, b.categoryBrown),
        onCategoryBrown: combine(a.onCategoryBrown, b.onCategoryBrown),
        categoryBrownContainer: combine(
          a.categoryBrownContainer,
          b.categoryBrownContainer,
        ),
        onCategoryBrownContainer: combine(
          a.onCategoryBrownContainer,
          b.onCategoryBrownContainer,
        ),
        categoryBrownOutline: combine(
          a.categoryBrownOutline,
          b.categoryBrownOutline,
        ),
        categoryGray: combine(a.categoryGray, b.categoryGray),
        onCategoryGray: combine(a.onCategoryGray, b.onCategoryGray),
        categoryGrayContainer: combine(
          a.categoryGrayContainer,
          b.categoryGrayContainer,
        ),
        onCategoryGrayContainer: combine(
          a.onCategoryGrayContainer,
          b.onCategoryGrayContainer,
        ),
        categoryGrayOutline: combine(
          a.categoryGrayOutline,
          b.categoryGrayOutline,
        ),
      );

  /// [base] with every slot where [normal] and [raised] disagree replaced
  /// by [raised]'s value; every slot where they agree keeps [base]'s value
  /// exactly as it is.
  ///
  /// The high-contrast door for a mapping that states high contrast as a
  /// complete table instead of a list of overrides. Comparing the two tables
  /// decides which slots high contrast governs, so editing a table moves the
  /// raise with it — there is no hand-kept list of "slots high contrast
  /// touches" to fall behind the tables. And because the agreeing slots come
  /// from [base] rather than from [raised], an axis applied to [base]
  /// earlier (a surface style bending the page) survives on exactly the
  /// slots high contrast has no opinion about.
  ///
  /// With `base == normal` the result equals [raised] slot for slot — on an
  /// agreeing slot [base]'s value is [normal]'s, which is [raised]'s — so a
  /// mapping that raises through this gets "the high-contrast builder equals
  /// raising the normal builder" by construction rather than by care.
  ///
  /// Slots agree when their colours compare equal (ARGB, token, opacity). A
  /// slot both tables leave unset agrees too, so [base] keeps whatever it
  /// has there.
  CoreColorScheme.raiseByDelta(
    CoreColorScheme base, {
    required CoreColorScheme normal,
    required CoreColorScheme raised,
  }) : this._zipSlots(
         base,
         CoreColorScheme._zipSlots(normal, raised, _markDisagreement),
         _keepBaseWhereAgreed,
       );

  /// A scheme whose every slot is [color].
  ///
  /// A probe, not a palette: hand it to an operation that writes slots and
  /// every slot it left alone still holds [color], so the slots it wrote
  /// are the ones that come back changed. This is how the Web
  /// high-contrast block learns which slots a source's raise governs
  /// without a hand-kept list. Built on [CoreColorScheme._zipSlots], so it
  /// cannot miss a slot the other whole-scheme walks see.
  ///
  /// Library-internal; user code builds schemes from a palette.
  @internal
  CoreColorScheme.uniform(CoreColor color)
    : this._zipSlots(
        const CoreColorScheme.tokenized(),
        const CoreColorScheme.tokenized(),
        (_, _) => color,
      );

  /// Token-only scheme — every field is a `const CoreColor.token(...)`.
  ///
  /// Used by the Web build context: the actual ARGB values live in CSS
  /// variables (`--color-X`), and the per-platform `.toValue()`
  /// extension emits `var(--color-X)` at render time. No Flutter
  /// `Color` resolution happens — the browser handles it via CSS.
  const CoreColorScheme.tokenized()
    : primary = const CoreColor.token(CoreColors.primary),
      secondary = const CoreColor.token(CoreColors.secondary),
      error = const CoreColor.token(CoreColors.error),
      success = const CoreColor.token(CoreColors.success),
      warning = const CoreColor.token(CoreColors.warning),
      info = const CoreColor.token(CoreColors.info),
      surface = const CoreColor.token(CoreColors.surface),
      surfaceDim = const CoreColor.token(CoreColors.surfaceDim),
      surfaceBright = const CoreColor.token(CoreColors.surfaceBright),
      surfaceContainerLowest = const CoreColor.token(
        CoreColors.surfaceContainerLowest,
      ),
      surfaceContainerLow = const CoreColor.token(
        CoreColors.surfaceContainerLow,
      ),
      surfaceContainer = const CoreColor.token(CoreColors.surfaceContainer),
      surfaceContainerHigh = const CoreColor.token(
        CoreColors.surfaceContainerHigh,
      ),
      surfaceContainerHighest = const CoreColor.token(
        CoreColors.surfaceContainerHighest,
      ),
      onSurface = const CoreColor.token(CoreColors.onSurface),
      onSurfaceVariant = const CoreColor.token(CoreColors.onSurfaceVariant),
      placeholder = const CoreColor.token(CoreColors.placeholder),
      link = const CoreColor.token(CoreColors.link),
      onSurfaceSubtle = const CoreColor.token(CoreColors.onSurfaceSubtle),
      surfaceRaised = const CoreColor.token(CoreColors.surfaceRaised),
      surfaceTint = const CoreColor.token(CoreColors.surfaceTint),
      onPrimary = const CoreColor.token(CoreColors.onPrimary),
      primaryContainer = const CoreColor.token(CoreColors.primaryContainer),
      onPrimaryContainer = const CoreColor.token(CoreColors.onPrimaryContainer),
      primaryFixed = const CoreColor.token(CoreColors.primaryFixed),
      primaryFixedDim = const CoreColor.token(CoreColors.primaryFixedDim),
      onPrimaryFixed = const CoreColor.token(CoreColors.onPrimaryFixed),
      onPrimaryFixedVariant = const CoreColor.token(
        CoreColors.onPrimaryFixedVariant,
      ),
      primaryText = const CoreColor.token(CoreColors.primaryText),
      primaryTextLarge = const CoreColor.token(CoreColors.primaryTextLarge),
      onSecondary = const CoreColor.token(CoreColors.onSecondary),
      secondaryContainer = const CoreColor.token(CoreColors.secondaryContainer),
      onSecondaryContainer = const CoreColor.token(
        CoreColors.onSecondaryContainer,
      ),
      secondaryFixed = const CoreColor.token(CoreColors.secondaryFixed),
      secondaryFixedDim = const CoreColor.token(CoreColors.secondaryFixedDim),
      onSecondaryFixed = const CoreColor.token(CoreColors.onSecondaryFixed),
      onSecondaryFixedVariant = const CoreColor.token(
        CoreColors.onSecondaryFixedVariant,
      ),
      tertiary = const CoreColor.token(CoreColors.tertiary),
      onTertiary = const CoreColor.token(CoreColors.onTertiary),
      tertiaryContainer = const CoreColor.token(CoreColors.tertiaryContainer),
      onTertiaryContainer = const CoreColor.token(
        CoreColors.onTertiaryContainer,
      ),
      tertiaryFixed = const CoreColor.token(CoreColors.tertiaryFixed),
      tertiaryFixedDim = const CoreColor.token(CoreColors.tertiaryFixedDim),
      onTertiaryFixed = const CoreColor.token(CoreColors.onTertiaryFixed),
      onTertiaryFixedVariant = const CoreColor.token(
        CoreColors.onTertiaryFixedVariant,
      ),
      onError = const CoreColor.token(CoreColors.onError),
      errorContainer = const CoreColor.token(CoreColors.errorContainer),
      onErrorContainer = const CoreColor.token(CoreColors.onErrorContainer),
      errorStrong = const CoreColor.token(CoreColors.errorStrong),
      focusRing = const CoreColor.token(CoreColors.focusRing),
      primaryHover = const CoreColor.token(CoreColors.primaryHover),
      primaryPressed = const CoreColor.token(CoreColors.primaryPressed),
      secondaryHover = const CoreColor.token(CoreColors.secondaryHover),
      secondaryPressed = const CoreColor.token(CoreColors.secondaryPressed),
      errorPressed = const CoreColor.token(CoreColors.errorPressed),
      onSuccess = const CoreColor.token(CoreColors.onSuccess),
      successContainer = const CoreColor.token(CoreColors.successContainer),
      onSuccessContainer = const CoreColor.token(CoreColors.onSuccessContainer),
      onWarning = const CoreColor.token(CoreColors.onWarning),
      warningContainer = const CoreColor.token(CoreColors.warningContainer),
      onWarningContainer = const CoreColor.token(CoreColors.onWarningContainer),
      onInfo = const CoreColor.token(CoreColors.onInfo),
      infoContainer = const CoreColor.token(CoreColors.infoContainer),
      onInfoContainer = const CoreColor.token(CoreColors.onInfoContainer),
      errorIcon = const CoreColor.token(CoreColors.errorIcon),
      successIcon = const CoreColor.token(CoreColors.successIcon),
      warningIcon = const CoreColor.token(CoreColors.warningIcon),
      infoIcon = const CoreColor.token(CoreColors.infoIcon),
      outline = const CoreColor.token(CoreColors.outline),
      outlineVariant = const CoreColor.token(CoreColors.outlineVariant),
      outlineSubtle = const CoreColor.token(CoreColors.outlineSubtle),
      inverseSurface = const CoreColor.token(CoreColors.inverseSurface),
      inverseOnSurface = const CoreColor.token(CoreColors.inverseOnSurface),
      inversePrimary = const CoreColor.token(CoreColors.inversePrimary),
      shadow = const CoreColor.token(CoreColors.shadow),
      surfaceHighlight = const CoreColor.token(CoreColors.surfaceHighlight),
      scrim = const CoreColor.token(CoreColors.scrim),
      disabledContent = const CoreColor.token(CoreColors.disabledContent),
      disabledContainer = const CoreColor.token(CoreColors.disabledContainer),
      disabledOutline = const CoreColor.token(CoreColors.disabledOutline),
      syntaxKeyword = const CoreColor.token(CoreColors.syntaxKeyword),
      syntaxType = const CoreColor.token(CoreColors.syntaxType),
      syntaxFunction = const CoreColor.token(CoreColors.syntaxFunction),
      syntaxString = const CoreColor.token(CoreColors.syntaxString),
      categoryRed = const CoreColor.token(CoreColors.categoryRed),
      onCategoryRed = const CoreColor.token(CoreColors.onCategoryRed),
      categoryRedContainer = const CoreColor.token(
        CoreColors.categoryRedContainer,
      ),
      onCategoryRedContainer = const CoreColor.token(
        CoreColors.onCategoryRedContainer,
      ),
      categoryRedOutline = const CoreColor.token(CoreColors.categoryRedOutline),
      categoryOrange = const CoreColor.token(CoreColors.categoryOrange),
      onCategoryOrange = const CoreColor.token(CoreColors.onCategoryOrange),
      categoryOrangeContainer = const CoreColor.token(
        CoreColors.categoryOrangeContainer,
      ),
      onCategoryOrangeContainer = const CoreColor.token(
        CoreColors.onCategoryOrangeContainer,
      ),
      categoryOrangeOutline = const CoreColor.token(
        CoreColors.categoryOrangeOutline,
      ),
      categoryYellow = const CoreColor.token(CoreColors.categoryYellow),
      onCategoryYellow = const CoreColor.token(CoreColors.onCategoryYellow),
      categoryYellowContainer = const CoreColor.token(
        CoreColors.categoryYellowContainer,
      ),
      onCategoryYellowContainer = const CoreColor.token(
        CoreColors.onCategoryYellowContainer,
      ),
      categoryYellowOutline = const CoreColor.token(
        CoreColors.categoryYellowOutline,
      ),
      categoryGreen = const CoreColor.token(CoreColors.categoryGreen),
      onCategoryGreen = const CoreColor.token(CoreColors.onCategoryGreen),
      categoryGreenContainer = const CoreColor.token(
        CoreColors.categoryGreenContainer,
      ),
      onCategoryGreenContainer = const CoreColor.token(
        CoreColors.onCategoryGreenContainer,
      ),
      categoryGreenOutline = const CoreColor.token(
        CoreColors.categoryGreenOutline,
      ),
      categoryBlue = const CoreColor.token(CoreColors.categoryBlue),
      onCategoryBlue = const CoreColor.token(CoreColors.onCategoryBlue),
      categoryBlueContainer = const CoreColor.token(
        CoreColors.categoryBlueContainer,
      ),
      onCategoryBlueContainer = const CoreColor.token(
        CoreColors.onCategoryBlueContainer,
      ),
      categoryBlueOutline = const CoreColor.token(
        CoreColors.categoryBlueOutline,
      ),
      categoryPurple = const CoreColor.token(CoreColors.categoryPurple),
      onCategoryPurple = const CoreColor.token(CoreColors.onCategoryPurple),
      categoryPurpleContainer = const CoreColor.token(
        CoreColors.categoryPurpleContainer,
      ),
      onCategoryPurpleContainer = const CoreColor.token(
        CoreColors.onCategoryPurpleContainer,
      ),
      categoryPurpleOutline = const CoreColor.token(
        CoreColors.categoryPurpleOutline,
      ),
      categoryPink = const CoreColor.token(CoreColors.categoryPink),
      onCategoryPink = const CoreColor.token(CoreColors.onCategoryPink),
      categoryPinkContainer = const CoreColor.token(
        CoreColors.categoryPinkContainer,
      ),
      onCategoryPinkContainer = const CoreColor.token(
        CoreColors.onCategoryPinkContainer,
      ),
      categoryPinkOutline = const CoreColor.token(
        CoreColors.categoryPinkOutline,
      ),
      categoryBrown = const CoreColor.token(CoreColors.categoryBrown),
      onCategoryBrown = const CoreColor.token(CoreColors.onCategoryBrown),
      categoryBrownContainer = const CoreColor.token(
        CoreColors.categoryBrownContainer,
      ),
      onCategoryBrownContainer = const CoreColor.token(
        CoreColors.onCategoryBrownContainer,
      ),
      categoryBrownOutline = const CoreColor.token(
        CoreColors.categoryBrownOutline,
      ),
      categoryGray = const CoreColor.token(CoreColors.categoryGray),
      onCategoryGray = const CoreColor.token(CoreColors.onCategoryGray),
      categoryGrayContainer = const CoreColor.token(
        CoreColors.categoryGrayContainer,
      ),
      onCategoryGrayContainer = const CoreColor.token(
        CoreColors.onCategoryGrayContainer,
      ),
      categoryGrayOutline = const CoreColor.token(
        CoreColors.categoryGrayOutline,
      );

  /// Surface color for backgrounds.
  final CoreColor? surface;

  /// Dimmed surface variant.
  final CoreColor? surfaceDim;

  /// Bright surface variant.
  final CoreColor? surfaceBright;

  /// Lowest surface container tone.
  final CoreColor? surfaceContainerLowest;

  /// Low surface container tone.
  final CoreColor? surfaceContainerLow;

  /// Default surface container tone.
  final CoreColor? surfaceContainer;

  /// High surface container tone.
  final CoreColor? surfaceContainerHigh;

  /// Highest surface container tone.
  final CoreColor? surfaceContainerHighest;

  /// Foreground on surface.
  final CoreColor? onSurface;

  /// Foreground variant on surface.
  final CoreColor? onSurfaceVariant;

  /// Foreground for text that stands in for a value not yet entered —
  /// an input's placeholder, and nothing else.
  ///
  /// Its own slot rather than [onSurfaceVariant] because the two answer
  /// different questions. `onSurfaceVariant` is secondary *content* and
  /// owes 4.5:1 on every surface tone it can land on. A placeholder is
  /// content that is absent, and has to read as weaker than the value
  /// that replaces it — a hierarchy it cannot express while also
  /// clearing 4.5:1 against the darkest container tones. Splitting the
  /// slot lets each keep its own contract: this one is audited against
  /// the surfaces an input actually sits on, not all eight.
  final CoreColor? placeholder;

  /// Foreground for a link — the colour that lets text say it leads
  /// somewhere.
  ///
  /// Its own slot rather than [primary] or [info]. `primary` is the brand's
  /// ink and, in CoUI, sits too close to body text to read as a link; `info`
  /// is a status colour that means something else. Neither can carry "this
  /// navigates", and a brand has to be able to recolour its links without
  /// touching either.
  ///
  /// A link is read as text, so it owes 4.5:1 on every surface tone it can
  /// land on — the eight tones from `surface` to `surfaceContainerHighest`.
  ///
  /// Optional like its siblings — [resolved] fills an unset slot from the
  /// default scheme.
  final CoreColor? link;

  /// The third text step — metadata, line numbers, help text, timestamps:
  /// content that is present and owes a reading, but sits below
  /// [onSurfaceVariant] in the hierarchy.
  ///
  /// Not [placeholder], which stands in for a value not yet entered and is
  /// audited only on the surfaces an input sits on. Not
  /// [disabledContent] either, which owes no ratio at all. This one is live
  /// text, so it owes 4.5:1 on seven tones — `surface`, `surfaceDim`,
  /// `surfaceBright`, `surfaceContainerLowest`, `surfaceContainerLow`,
  /// `surfaceContainer` and `surfaceContainerHigh`.
  /// `surfaceContainerHighest` is left out: on that tone [onSurfaceVariant]
  /// is itself the weakest step that clears 4.5:1, so there is no room
  /// below it for a third.
  final CoreColor? onSurfaceSubtle;

  /// The face that rises out of a track to mark the selected item — a
  /// segmented control's selected segment, a pill tab's selected tab.
  ///
  /// Its own slot because the answer turns over between modes: in light
  /// mode the raised face is the page white above a grey track, in dark
  /// mode it is the topmost surface tone above a darker one. Neither
  /// [surface] nor a container step says "above the track" in both.
  final CoreColor? surfaceRaised;

  /// Surface tint color.
  final CoreColor? surfaceTint;

  /// Primary brand color.
  final CoreColor primary;

  /// Foreground on primary.
  final CoreColor? onPrimary;

  /// Primary container background.
  final CoreColor? primaryContainer;

  /// Foreground on primary container.
  final CoreColor? onPrimaryContainer;

  /// Fixed primary tone.
  final CoreColor? primaryFixed;

  /// Dimmed fixed primary tone.
  final CoreColor? primaryFixedDim;

  /// Foreground on fixed primary.
  final CoreColor? onPrimaryFixed;

  /// Foreground variant on fixed primary.
  final CoreColor? onPrimaryFixedVariant;

  /// Primary used as body text on surfaces — a step chosen to clear 4.5:1
  /// (WCAG 1.4.3 normal text) against `surface` in its own mode.
  final CoreColor? primaryText;

  /// Primary used as large-scale text (18pt+/14pt bold) on surfaces — may
  /// sit one step lighter than [primaryText] because large text only needs
  /// 3:1 (WCAG 1.4.3 large text).
  final CoreColor? primaryTextLarge;

  /// Secondary brand color.
  final CoreColor secondary;

  /// Foreground on secondary.
  final CoreColor? onSecondary;

  /// Secondary container background.
  final CoreColor? secondaryContainer;

  /// Foreground on secondary container.
  final CoreColor? onSecondaryContainer;

  /// Fixed secondary tone.
  final CoreColor? secondaryFixed;

  /// Dimmed fixed secondary tone.
  final CoreColor? secondaryFixedDim;

  /// Foreground on fixed secondary.
  final CoreColor? onSecondaryFixed;

  /// Foreground variant on fixed secondary.
  final CoreColor? onSecondaryFixedVariant;

  /// Tertiary color — the accent role.
  ///
  /// `CoreColors.accent` reads this same slot; `tertiary` stays the M3
  /// field. CoUI's own mapping restates `primary` here, so the CoUI accent
  /// is `primary`; a brand that wants a second hue states it as its own
  /// tertiary.
  final CoreColor? tertiary;

  /// Foreground on tertiary.
  final CoreColor? onTertiary;

  /// Tertiary container background.
  final CoreColor? tertiaryContainer;

  /// Foreground on tertiary container.
  final CoreColor? onTertiaryContainer;

  /// Fixed tertiary tone.
  final CoreColor? tertiaryFixed;

  /// Dimmed fixed tertiary tone.
  final CoreColor? tertiaryFixedDim;

  /// Foreground on fixed tertiary.
  final CoreColor? onTertiaryFixed;

  /// Foreground variant on fixed tertiary.
  final CoreColor? onTertiaryFixedVariant;

  /// Error color.
  final CoreColor error;

  /// Foreground on error.
  final CoreColor? onError;

  /// Error container background.
  final CoreColor? errorContainer;

  /// Foreground on error container.
  final CoreColor? onErrorContainer;

  /// Pressed-state background for a destructive/danger fill — one step
  /// further than [error] in the direction that mode already moves
  /// (darker in light, lighter in dark; fixed at the already-extreme
  /// step in high contrast). Paired with [onError] as the foreground,
  /// not a dedicated `onErrorStrong` — every mode's `errorStrong` stays
  /// within the same contrast family as `error` against [onError].
  final CoreColor? errorStrong;

  /// Hover / focus fill for a filled `primary` control — the container
  /// swaps to this opaque step instead of compositing an alpha wash over
  /// [primary] (CoUI Button · Menu 개편 2026-09-08 §5: filled variants
  /// hover/focus → `*-hover`, pressed → `*-pressed`). One step along the
  /// mapping's own ramp — CoUI's neutral ramp, or a brand's chromatic
  /// one; the direction is whatever the Figma `color/primary-hover` variable
  /// measures in that mode, not a rule. Paired with [onPrimary] as the
  /// foreground.
  final CoreColor? primaryHover;

  /// Pressed fill for a filled `primary` control — one step beyond
  /// [primaryHover]. See [primaryHover].
  final CoreColor? primaryPressed;

  /// Hover / focus fill for a filled `secondary` control. See
  /// [primaryHover]; paired with [onSecondary].
  final CoreColor? secondaryHover;

  /// Pressed fill for a filled `secondary` control — one step beyond
  /// [secondaryHover]. See [primaryHover].
  final CoreColor? secondaryPressed;

  /// Pressed fill for the destructive control — the step the Figma
  /// `color/error-pressed` variable names, which is one step from
  /// [error] where [errorStrong] is two. Paired with [onError]. Kept
  /// apart from [errorStrong] because the two are different variables at
  /// the source and a consumer may still read the stronger one.
  final CoreColor? errorPressed;

  /// The focus ring's colour — its own slot rather than a reuse of
  /// [primary].
  ///
  /// A focus ring is a system affordance, not a brand statement — it says
  /// "you are here", and the thing it must not be confused with is the
  /// component's own chrome. A slot of its own lets a mapping pick the
  /// ring's step apart from the primary fill, one step per mode, the way
  /// every other semantic colour picks its step: the standard mapping
  /// takes the primary ramp's chromatic steps, and CoUI's own mapping
  /// states the same step its `primary` uses.
  final CoreColor? focusRing;

  /// Success color.
  final CoreColor success;

  /// Foreground on success.
  final CoreColor? onSuccess;

  /// Success container background.
  final CoreColor? successContainer;

  /// Foreground on success container.
  final CoreColor? onSuccessContainer;

  /// Warning color.
  final CoreColor warning;

  /// Foreground on warning.
  final CoreColor? onWarning;

  /// Warning container background.
  final CoreColor? warningContainer;

  /// Foreground on warning container.
  final CoreColor? onWarningContainer;

  /// Info color.
  final CoreColor info;

  /// Foreground on info.
  final CoreColor? onInfo;

  /// Info container background.
  final CoreColor? infoContainer;

  /// Foreground on info container.
  final CoreColor? onInfoContainer;

  /// Non-text error indicator — an icon, status dot, progress bar or
  /// chart mark that says "error" without being read as text. Owes 3:1
  /// against the page (WCAG 1.4.11; 4.5:1 in high contrast), not the
  /// 4.5:1 text contrast [error] owes, so it can sit one step lighter
  /// than [error] in light mode.
  final CoreColor? errorIcon;

  /// Non-text success indicator — see [errorIcon].
  final CoreColor? successIcon;

  /// Non-text warning indicator — see [errorIcon].
  final CoreColor? warningIcon;

  /// Non-text info indicator — see [errorIcon].
  final CoreColor? infoIcon;

  /// Outline color for borders.
  final CoreColor? outline;

  /// Subtle outline variant.
  final CoreColor? outlineVariant;

  /// The border of a surface that floats — a quieter line than
  /// [outlineVariant], for a panel whose edge is also carried by its fill
  /// and its shadow.
  ///
  /// Subtle on purpose in the normal modes: it sits one step off the page
  /// tone (CoUI light `neutral/150`, dark `neutral/900` — the panel's own
  /// fill), so it is not held to the 3:1 a control boundary owes
  /// ([outline]). It is the one outline slot that rises with high contrast:
  /// a floating panel leans on this line instead of its shadow there, so
  /// the high-contrast tables state it at 4.5:1 or better on the page and
  /// on the panel.
  ///
  /// Optional like its siblings — [resolved] fills an unset slot from the
  /// default scheme.
  final CoreColor? outlineSubtle;

  /// Inverse surface color.
  final CoreColor? inverseSurface;

  /// Foreground on inverse surface.
  final CoreColor? inverseOnSurface;

  /// Inverse primary for contrast.
  final CoreColor? inversePrimary;

  /// Shadow color.
  final CoreColor? shadow;

  /// The tint of light falling on a raised surface — the counterpart of
  /// [shadow], and what an inset highlight is drawn in.
  ///
  /// Optional. A palette that says nothing here still gets a usable
  /// value: [resolved] derives one by lifting [surface]'s lightness.
  /// That derivation is not a nicety — a surface style that states an
  /// inset rim and then meets a palette with no highlight fails
  /// asymmetrically and silently. On Flutter the token resolves to
  /// nothing and paints at alpha 0, so the rim is simply absent; on Web
  /// the undefined custom property invalidates the whole `box-shadow`
  /// declaration, so the surface loses *every* layer including the ones
  /// that had nothing to do with the rim. Switching from a palette that
  /// states it to one that does not is exactly how that reaches a user.
  ///
  /// The derivation is what keeps this slot from being a declared-but-
  /// unreachable one: a palette that never fills it still emits a usable
  /// value, so no component reads a slot nothing populates.
  final CoreColor? surfaceHighlight;

  /// Scrim color for overlays.
  final CoreColor? scrim;

  /// Foreground (text / icon) for disabled elements.
  ///
  /// A fixed colour rather than an opacity multiplier: the same
  /// `opacity-50` passes contrast over a light surface and fails over a
  /// dark one, and the code gives no hint which it is. Pinning the value
  /// decides the contrast once.
  final CoreColor? disabledContent;

  /// Background fill for disabled elements.
  final CoreColor? disabledContainer;

  /// Border for disabled elements.
  final CoreColor? disabledOutline;

  // ── Syntax ──
  // Code highlighting. Keyword, type and string read brand-less values
  // from [CoreSyntaxPalette], the same in every brand; function reads the
  // brand's own info ramp. Each owes 4.5:1 as text on the tones code is
  // shown on — `surface`, `surfaceContainerLow`, `surfaceContainer`,
  // `surfaceContainerHigh` and the four status containers.

  /// Syntax keyword — keywords, storage and control words.
  final CoreColor? syntaxKeyword;

  /// Syntax type — type names, classes and numeric constants.
  final CoreColor? syntaxType;

  /// Syntax function — function names. The one syntax slot a brand
  /// colours: it reads the brand's own info step, where the other three
  /// read [CoreSyntaxPalette].
  final CoreColor? syntaxFunction;

  /// Syntax string — string literals.
  final CoreColor? syntaxString;

  // ── Category ──
  // Nine hues × five slots that tell things apart without meaning
  // anything. The same in every brand: each mapping writes them through
  // [CoreCategoryPalette.applyTo] in all four modes, and [resolved] fills
  // an unset one from CoUI's normal value.

  /// Category red — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryRed;

  /// Category red — the label on [categoryRed].
  final CoreColor? onCategoryRed;

  /// Category red — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryRedContainer;

  /// Category red — the label on [categoryRedContainer]; also any text coloured
  /// red.
  final CoreColor? onCategoryRedContainer;

  /// Category red — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryRedOutline;

  /// Category orange — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryOrange;

  /// Category orange — the label on [categoryOrange].
  final CoreColor? onCategoryOrange;

  /// Category orange — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryOrangeContainer;

  /// Category orange — the label on [categoryOrangeContainer]; also any text
  /// coloured orange.
  final CoreColor? onCategoryOrangeContainer;

  /// Category orange — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryOrangeOutline;

  /// Category yellow — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryYellow;

  /// Category yellow — the label on [categoryYellow].
  final CoreColor? onCategoryYellow;

  /// Category yellow — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryYellowContainer;

  /// Category yellow — the label on [categoryYellowContainer]; also any text
  /// coloured yellow.
  final CoreColor? onCategoryYellowContainer;

  /// Category yellow — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryYellowOutline;

  /// Category green — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryGreen;

  /// Category green — the label on [categoryGreen].
  final CoreColor? onCategoryGreen;

  /// Category green — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryGreenContainer;

  /// Category green — the label on [categoryGreenContainer]; also any text
  /// coloured green.
  final CoreColor? onCategoryGreenContainer;

  /// Category green — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryGreenOutline;

  /// Category blue — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryBlue;

  /// Category blue — the label on [categoryBlue].
  final CoreColor? onCategoryBlue;

  /// Category blue — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryBlueContainer;

  /// Category blue — the label on [categoryBlueContainer]; also any text
  /// coloured blue.
  final CoreColor? onCategoryBlueContainer;

  /// Category blue — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryBlueOutline;

  /// Category purple — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryPurple;

  /// Category purple — the label on [categoryPurple].
  final CoreColor? onCategoryPurple;

  /// Category purple — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryPurpleContainer;

  /// Category purple — the label on [categoryPurpleContainer]; also any text
  /// coloured purple.
  final CoreColor? onCategoryPurpleContainer;

  /// Category purple — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryPurpleOutline;

  /// Category pink — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryPink;

  /// Category pink — the label on [categoryPink].
  final CoreColor? onCategoryPink;

  /// Category pink — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryPinkContainer;

  /// Category pink — the label on [categoryPinkContainer]; also any text
  /// coloured pink.
  final CoreColor? onCategoryPinkContainer;

  /// Category pink — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryPinkOutline;

  /// Category brown — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryBrown;

  /// Category brown — the label on [categoryBrown].
  final CoreColor? onCategoryBrown;

  /// Category brown — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryBrownContainer;

  /// Category brown — the label on [categoryBrownContainer]; also any text
  /// coloured brown.
  final CoreColor? onCategoryBrownContainer;

  /// Category brown — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryBrownOutline;

  /// Category gray — the strong chip's fill, a chart series, a legend dot.
  final CoreColor? categoryGray;

  /// Category gray — the label on [categoryGray].
  final CoreColor? onCategoryGray;

  /// Category gray — the soft chip, avatar and calendar-block background.
  final CoreColor? categoryGrayContainer;

  /// Category gray — the label on [categoryGrayContainer]; also any text
  /// coloured gray.
  final CoreColor? onCategoryGrayContainer;

  /// Category gray — the soft chip, avatar and calendar-block border.
  final CoreColor? categoryGrayOutline;

  // The unset-slot fallback is "the CoUI look", so it reads CoUI's OWN
  // source (its fixed palette through its own mapping) rather than any
  // brand's — a partial scheme resolved against the default must fill its
  // gaps with the same values a full CoUI theme would have had there.
  static final CoreColorScheme _defaultLight = CouiColorPresets.source.light();

  static final CoreColorScheme _defaultDark = CouiColorPresets.source.dark();

  /// Resolves a [CoreColor] against this scheme. Token references are
  /// looked up via the scheme; raw colours pass through unchanged.
  /// Walks [CoreColor.fallbacks] when the primary token is unset.
  /// Returns a tagged colour so the originating token survives for Web
  /// rendering.
  CoreColor resolve(CoreColor color) {
    final tok = color.token;
    if (tok == null) return color;
    if (color.isResolved) return color;
    final raw = tok.read(this);
    if (raw != null) {
      return CoreColor.tagged(
        raw.argb,
        tok,
        opacity: color.opacity,
        fallbacks: color.fallbacks,
      );
    }
    for (final fb in color.fallbacks) {
      final fbRaw = fb.read(this);
      if (fbRaw != null) {
        return CoreColor.tagged(
          fbRaw.argb,
          tok,
          opacity: color.opacity,
          fallbacks: color.fallbacks,
        );
      }
    }
    return color; // remains unresolved
  }

  /// Export to hex color map for serialization.
  Map<String, String> toMap() {
    final result = <String, String>{};
    void add(String key, CoreColor? color) {
      if (color == null) return;
      result[key] = color.toHex();
    }

    // M3 Semantic
    add('primary', primary);
    add('on-primary', onPrimary);
    add('primary-container', primaryContainer);
    add('on-primary-container', onPrimaryContainer);
    add('secondary', secondary);
    add('on-secondary', onSecondary);
    add('secondary-container', secondaryContainer);
    add('on-secondary-container', onSecondaryContainer);
    add('tertiary', tertiary);
    add('on-tertiary', onTertiary);
    add('tertiary-container', tertiaryContainer);
    add('on-tertiary-container', onTertiaryContainer);
    add('error', error);
    add('on-error', onError);
    add('error-container', errorContainer);
    add('on-error-container', onErrorContainer);
    add('error-strong', errorStrong);
    add('focus-ring', focusRing);
    add('primary-hover', primaryHover);
    add('primary-pressed', primaryPressed);
    add('secondary-hover', secondaryHover);
    add('secondary-pressed', secondaryPressed);
    add('error-pressed', errorPressed);
    add('success', success);
    add('on-success', onSuccess);
    add('success-container', successContainer);
    add('on-success-container', onSuccessContainer);
    add('warning', warning);
    add('on-warning', onWarning);
    add('warning-container', warningContainer);
    add('on-warning-container', onWarningContainer);
    add('info', info);
    add('on-info', onInfo);
    add('info-container', infoContainer);
    add('on-info-container', onInfoContainer);
    add('error-icon', errorIcon);
    add('success-icon', successIcon);
    add('warning-icon', warningIcon);
    add('info-icon', infoIcon);
    add('surface', surface);
    add('on-surface', onSurface);
    add('on-surface-variant', onSurfaceVariant);
    add('placeholder', placeholder);
    add('link', link);
    add('on-surface-subtle', onSurfaceSubtle);
    add('surface-raised', surfaceRaised);
    add('surface-tint', surfaceTint);
    add('surface-dim', surfaceDim);
    add('surface-bright', surfaceBright);
    add('surface-container-lowest', surfaceContainerLowest);
    add('surface-container-low', surfaceContainerLow);
    add('surface-container', surfaceContainer);
    add('surface-container-high', surfaceContainerHigh);
    add('surface-container-highest', surfaceContainerHighest);
    add('outline', outline);
    add('outline-variant', outlineVariant);
    add('outline-subtle', outlineSubtle);
    add('inverse-surface', inverseSurface);
    add('inverse-on-surface', inverseOnSurface);
    add('inverse-primary', inversePrimary);
    add('shadow', shadow);
    add('surface-highlight', surfaceHighlight);
    add('scrim', scrim);
    // Disabled
    add('disabled-content', disabledContent);
    add('disabled-container', disabledContainer);
    add('disabled-outline', disabledOutline);
    // Syntax
    add('syntax-keyword', syntaxKeyword);
    add('syntax-type', syntaxType);
    add('syntax-function', syntaxFunction);
    add('syntax-string', syntaxString);
    // Category — written so a theme map read back through [fromMap]
    // keeps them.
    for (final color in CoreCategoryColor.values) {
      for (final slot in CoreCategorySlot.values) {
        final token = color.token(slot);
        add(token.name, token.read(this));
      }
    }
    return result;
  }

  /// Create a copy with modified colors.
  CoreColorScheme copyWith({
    CoreColor? surface,
    CoreColor? surfaceDim,
    CoreColor? surfaceBright,
    CoreColor? surfaceContainerLowest,
    CoreColor? surfaceContainerLow,
    CoreColor? surfaceContainer,
    CoreColor? surfaceContainerHigh,
    CoreColor? surfaceContainerHighest,
    CoreColor? onSurface,
    CoreColor? onSurfaceVariant,
    CoreColor? placeholder,
    CoreColor? link,
    CoreColor? onSurfaceSubtle,
    CoreColor? surfaceRaised,
    CoreColor? surfaceTint,
    CoreColor? primary,
    CoreColor? onPrimary,
    CoreColor? primaryContainer,
    CoreColor? onPrimaryContainer,
    CoreColor? primaryFixed,
    CoreColor? primaryFixedDim,
    CoreColor? onPrimaryFixed,
    CoreColor? onPrimaryFixedVariant,
    CoreColor? primaryText,
    CoreColor? primaryTextLarge,
    CoreColor? secondary,
    CoreColor? onSecondary,
    CoreColor? secondaryContainer,
    CoreColor? onSecondaryContainer,
    CoreColor? secondaryFixed,
    CoreColor? secondaryFixedDim,
    CoreColor? onSecondaryFixed,
    CoreColor? onSecondaryFixedVariant,
    CoreColor? tertiary,
    CoreColor? onTertiary,
    CoreColor? tertiaryContainer,
    CoreColor? onTertiaryContainer,
    CoreColor? tertiaryFixed,
    CoreColor? tertiaryFixedDim,
    CoreColor? onTertiaryFixed,
    CoreColor? onTertiaryFixedVariant,
    CoreColor? error,
    CoreColor? onError,
    CoreColor? errorContainer,
    CoreColor? onErrorContainer,
    CoreColor? errorStrong,
    CoreColor? focusRing,
    CoreColor? primaryHover,
    CoreColor? primaryPressed,
    CoreColor? secondaryHover,
    CoreColor? secondaryPressed,
    CoreColor? errorPressed,
    CoreColor? success,
    CoreColor? onSuccess,
    CoreColor? successContainer,
    CoreColor? onSuccessContainer,
    CoreColor? warning,
    CoreColor? onWarning,
    CoreColor? warningContainer,
    CoreColor? onWarningContainer,
    CoreColor? info,
    CoreColor? onInfo,
    CoreColor? infoContainer,
    CoreColor? onInfoContainer,
    CoreColor? errorIcon,
    CoreColor? successIcon,
    CoreColor? warningIcon,
    CoreColor? infoIcon,
    CoreColor? outline,
    CoreColor? outlineVariant,
    CoreColor? outlineSubtle,
    CoreColor? inverseSurface,
    CoreColor? inverseOnSurface,
    CoreColor? inversePrimary,
    CoreColor? shadow,
    CoreColor? surfaceHighlight,
    CoreColor? scrim,
    CoreColor? disabledContent,
    CoreColor? disabledContainer,
    CoreColor? disabledOutline,
    CoreColor? syntaxKeyword,
    CoreColor? syntaxType,
    CoreColor? syntaxFunction,
    CoreColor? syntaxString,
    CoreColor? categoryRed,
    CoreColor? onCategoryRed,
    CoreColor? categoryRedContainer,
    CoreColor? onCategoryRedContainer,
    CoreColor? categoryRedOutline,
    CoreColor? categoryOrange,
    CoreColor? onCategoryOrange,
    CoreColor? categoryOrangeContainer,
    CoreColor? onCategoryOrangeContainer,
    CoreColor? categoryOrangeOutline,
    CoreColor? categoryYellow,
    CoreColor? onCategoryYellow,
    CoreColor? categoryYellowContainer,
    CoreColor? onCategoryYellowContainer,
    CoreColor? categoryYellowOutline,
    CoreColor? categoryGreen,
    CoreColor? onCategoryGreen,
    CoreColor? categoryGreenContainer,
    CoreColor? onCategoryGreenContainer,
    CoreColor? categoryGreenOutline,
    CoreColor? categoryBlue,
    CoreColor? onCategoryBlue,
    CoreColor? categoryBlueContainer,
    CoreColor? onCategoryBlueContainer,
    CoreColor? categoryBlueOutline,
    CoreColor? categoryPurple,
    CoreColor? onCategoryPurple,
    CoreColor? categoryPurpleContainer,
    CoreColor? onCategoryPurpleContainer,
    CoreColor? categoryPurpleOutline,
    CoreColor? categoryPink,
    CoreColor? onCategoryPink,
    CoreColor? categoryPinkContainer,
    CoreColor? onCategoryPinkContainer,
    CoreColor? categoryPinkOutline,
    CoreColor? categoryBrown,
    CoreColor? onCategoryBrown,
    CoreColor? categoryBrownContainer,
    CoreColor? onCategoryBrownContainer,
    CoreColor? categoryBrownOutline,
    CoreColor? categoryGray,
    CoreColor? onCategoryGray,
    CoreColor? categoryGrayContainer,
    CoreColor? onCategoryGrayContainer,
    CoreColor? categoryGrayOutline,
  }) {
    return CoreColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surface: surface ?? this.surface,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      surfaceContainerLowest:
          surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      placeholder: placeholder ?? this.placeholder,
      link: link ?? this.link,
      onSurfaceSubtle: onSurfaceSubtle ?? this.onSurfaceSubtle,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      primaryFixedDim: primaryFixedDim ?? this.primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed ?? this.onPrimaryFixed,
      onPrimaryFixedVariant:
          onPrimaryFixedVariant ?? this.onPrimaryFixedVariant,
      primaryText: primaryText ?? this.primaryText,
      primaryTextLarge: primaryTextLarge ?? this.primaryTextLarge,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      secondaryFixed: secondaryFixed ?? this.secondaryFixed,
      secondaryFixedDim: secondaryFixedDim ?? this.secondaryFixedDim,
      onSecondaryFixed: onSecondaryFixed ?? this.onSecondaryFixed,
      onSecondaryFixedVariant:
          onSecondaryFixedVariant ?? this.onSecondaryFixedVariant,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      tertiaryFixed: tertiaryFixed ?? this.tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim ?? this.tertiaryFixedDim,
      onTertiaryFixed: onTertiaryFixed ?? this.onTertiaryFixed,
      onTertiaryFixedVariant:
          onTertiaryFixedVariant ?? this.onTertiaryFixedVariant,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      errorStrong: errorStrong ?? this.errorStrong,
      focusRing: focusRing ?? this.focusRing,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      secondaryHover: secondaryHover ?? this.secondaryHover,
      secondaryPressed: secondaryPressed ?? this.secondaryPressed,
      errorPressed: errorPressed ?? this.errorPressed,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      errorIcon: errorIcon ?? this.errorIcon,
      successIcon: successIcon ?? this.successIcon,
      warningIcon: warningIcon ?? this.warningIcon,
      infoIcon: infoIcon ?? this.infoIcon,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      outlineSubtle: outlineSubtle ?? this.outlineSubtle,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
      inversePrimary: inversePrimary ?? this.inversePrimary,
      shadow: shadow ?? this.shadow,
      surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
      scrim: scrim ?? this.scrim,
      disabledContent: disabledContent ?? this.disabledContent,
      disabledContainer: disabledContainer ?? this.disabledContainer,
      disabledOutline: disabledOutline ?? this.disabledOutline,
      syntaxKeyword: syntaxKeyword ?? this.syntaxKeyword,
      syntaxType: syntaxType ?? this.syntaxType,
      syntaxFunction: syntaxFunction ?? this.syntaxFunction,
      syntaxString: syntaxString ?? this.syntaxString,
      categoryRed: categoryRed ?? this.categoryRed,
      onCategoryRed: onCategoryRed ?? this.onCategoryRed,
      categoryRedContainer: categoryRedContainer ?? this.categoryRedContainer,
      onCategoryRedContainer:
          onCategoryRedContainer ?? this.onCategoryRedContainer,
      categoryRedOutline: categoryRedOutline ?? this.categoryRedOutline,
      categoryOrange: categoryOrange ?? this.categoryOrange,
      onCategoryOrange: onCategoryOrange ?? this.onCategoryOrange,
      categoryOrangeContainer:
          categoryOrangeContainer ?? this.categoryOrangeContainer,
      onCategoryOrangeContainer:
          onCategoryOrangeContainer ?? this.onCategoryOrangeContainer,
      categoryOrangeOutline:
          categoryOrangeOutline ?? this.categoryOrangeOutline,
      categoryYellow: categoryYellow ?? this.categoryYellow,
      onCategoryYellow: onCategoryYellow ?? this.onCategoryYellow,
      categoryYellowContainer:
          categoryYellowContainer ?? this.categoryYellowContainer,
      onCategoryYellowContainer:
          onCategoryYellowContainer ?? this.onCategoryYellowContainer,
      categoryYellowOutline:
          categoryYellowOutline ?? this.categoryYellowOutline,
      categoryGreen: categoryGreen ?? this.categoryGreen,
      onCategoryGreen: onCategoryGreen ?? this.onCategoryGreen,
      categoryGreenContainer:
          categoryGreenContainer ?? this.categoryGreenContainer,
      onCategoryGreenContainer:
          onCategoryGreenContainer ?? this.onCategoryGreenContainer,
      categoryGreenOutline: categoryGreenOutline ?? this.categoryGreenOutline,
      categoryBlue: categoryBlue ?? this.categoryBlue,
      onCategoryBlue: onCategoryBlue ?? this.onCategoryBlue,
      categoryBlueContainer:
          categoryBlueContainer ?? this.categoryBlueContainer,
      onCategoryBlueContainer:
          onCategoryBlueContainer ?? this.onCategoryBlueContainer,
      categoryBlueOutline: categoryBlueOutline ?? this.categoryBlueOutline,
      categoryPurple: categoryPurple ?? this.categoryPurple,
      onCategoryPurple: onCategoryPurple ?? this.onCategoryPurple,
      categoryPurpleContainer:
          categoryPurpleContainer ?? this.categoryPurpleContainer,
      onCategoryPurpleContainer:
          onCategoryPurpleContainer ?? this.onCategoryPurpleContainer,
      categoryPurpleOutline:
          categoryPurpleOutline ?? this.categoryPurpleOutline,
      categoryPink: categoryPink ?? this.categoryPink,
      onCategoryPink: onCategoryPink ?? this.onCategoryPink,
      categoryPinkContainer:
          categoryPinkContainer ?? this.categoryPinkContainer,
      onCategoryPinkContainer:
          onCategoryPinkContainer ?? this.onCategoryPinkContainer,
      categoryPinkOutline: categoryPinkOutline ?? this.categoryPinkOutline,
      categoryBrown: categoryBrown ?? this.categoryBrown,
      onCategoryBrown: onCategoryBrown ?? this.onCategoryBrown,
      categoryBrownContainer:
          categoryBrownContainer ?? this.categoryBrownContainer,
      onCategoryBrownContainer:
          onCategoryBrownContainer ?? this.onCategoryBrownContainer,
      categoryBrownOutline: categoryBrownOutline ?? this.categoryBrownOutline,
      categoryGray: categoryGray ?? this.categoryGray,
      onCategoryGray: onCategoryGray ?? this.onCategoryGray,
      categoryGrayContainer:
          categoryGrayContainer ?? this.categoryGrayContainer,
      onCategoryGrayContainer:
          onCategoryGrayContainer ?? this.onCategoryGrayContainer,
      categoryGrayOutline: categoryGrayOutline ?? this.categoryGrayOutline,
    );
  }

  /// Linearly interpolate between two color schemes.
  ///
  /// Every slot is interpolated, through the same slot list the other
  /// two-scheme operations use. A slot left out would not glide during
  /// a theme crossfade: the interpolated scheme would leave it null,
  /// whoever resolves that scheme would fill it from a default palette —
  /// neither endpoint's value — and the slot would jump on the first
  /// frame while its neighbours were still mid-way. A light↔dark switch
  /// moves nearly every slot at once, so the gap shows.
  ///
  /// Both schemes must be free of unresolved token references — see
  /// [resolveTokensAgainst].
  // Matches Flutter's `ThemeData.lerp` convention — keep as static.
  // ignore: prefer_constructors_over_static_methods
  static CoreColorScheme lerp(
    CoreColorScheme a,
    CoreColorScheme b,
    double t,
  ) => CoreColorScheme._zipSlots(
    a,
    b,
    (x, y) => _lerpNullable(x, y, t),
  );

  /// A copy whose unresolved token references are looked up in
  /// [palette]; raw and already-resolved slots are kept as they are.
  ///
  /// A token-only scheme ([CoreColorScheme.tokenized]) carries names,
  /// not colours — the Web reads those names as CSS variables, and a
  /// Flutter widget falls back to a palette when it converts one. Code
  /// that needs the numbers themselves, such as [lerp], has neither
  /// escape: it resolves the tokens first, against the same palette the
  /// widgets would have painted with, so an animation's first frame
  /// matches the screen it starts from.
  CoreColorScheme resolveTokensAgainst(CoreColorScheme palette) =>
      CoreColorScheme._zipSlots(
        this,
        this,
        (x, _) => x == null ? null : palette.resolve(x),
      );

  /// Every slot in declaration order.
  ///
  /// A theme axis (high-contrast set, surface preset, brightness) works by
  /// building a new scheme and handing it to the framework, which decides
  /// whether to rebuild by comparing values. A slot missing from that
  /// comparison is a slot an axis cannot move: the new scheme compares equal
  /// to the old one, no rebuild happens, and the axis silently does nothing
  /// even though it computed the right colours. That failure leaves no trace
  /// on screen — the render is identical to "before" — so it is diagnosed by
  /// reading this list, not by looking at the app.
  ///
  /// Kept as one list so [operator ==] and [hashCode] cannot drift apart, and
  /// so adding a slot has exactly one place to forget.
  List<CoreColor?> get _equalitySlots => [
    surface,
    surfaceDim,
    surfaceBright,
    surfaceContainerLowest,
    surfaceContainerLow,
    surfaceContainer,
    surfaceContainerHigh,
    surfaceContainerHighest,
    onSurface,
    onSurfaceVariant,
    placeholder,
    link,
    onSurfaceSubtle,
    surfaceRaised,
    surfaceTint,
    primary,
    onPrimary,
    primaryContainer,
    onPrimaryContainer,
    primaryFixed,
    primaryFixedDim,
    onPrimaryFixed,
    onPrimaryFixedVariant,
    primaryText,
    primaryTextLarge,
    secondary,
    onSecondary,
    secondaryContainer,
    onSecondaryContainer,
    secondaryFixed,
    secondaryFixedDim,
    onSecondaryFixed,
    onSecondaryFixedVariant,
    tertiary,
    onTertiary,
    tertiaryContainer,
    onTertiaryContainer,
    tertiaryFixed,
    tertiaryFixedDim,
    onTertiaryFixed,
    onTertiaryFixedVariant,
    error,
    onError,
    errorContainer,
    onErrorContainer,
    errorStrong,
    focusRing,
    primaryHover,
    primaryPressed,
    secondaryHover,
    secondaryPressed,
    errorPressed,
    success,
    onSuccess,
    successContainer,
    onSuccessContainer,
    warning,
    onWarning,
    warningContainer,
    onWarningContainer,
    info,
    onInfo,
    infoContainer,
    onInfoContainer,
    errorIcon,
    successIcon,
    warningIcon,
    infoIcon,
    outline,
    outlineVariant,
    outlineSubtle,
    inverseSurface,
    inverseOnSurface,
    inversePrimary,
    shadow,
    surfaceHighlight,
    scrim,
    disabledContent,
    disabledContainer,
    disabledOutline,
    syntaxKeyword,
    syntaxType,
    syntaxFunction,
    syntaxString,
    categoryRed,
    onCategoryRed,
    categoryRedContainer,
    onCategoryRedContainer,
    categoryRedOutline,
    categoryOrange,
    onCategoryOrange,
    categoryOrangeContainer,
    onCategoryOrangeContainer,
    categoryOrangeOutline,
    categoryYellow,
    onCategoryYellow,
    categoryYellowContainer,
    onCategoryYellowContainer,
    categoryYellowOutline,
    categoryGreen,
    onCategoryGreen,
    categoryGreenContainer,
    onCategoryGreenContainer,
    categoryGreenOutline,
    categoryBlue,
    onCategoryBlue,
    categoryBlueContainer,
    onCategoryBlueContainer,
    categoryBlueOutline,
    categoryPurple,
    onCategoryPurple,
    categoryPurpleContainer,
    onCategoryPurpleContainer,
    categoryPurpleOutline,
    categoryPink,
    onCategoryPink,
    categoryPinkContainer,
    onCategoryPinkContainer,
    categoryPinkOutline,
    categoryBrown,
    onCategoryBrown,
    categoryBrownContainer,
    onCategoryBrownContainer,
    categoryBrownOutline,
    categoryGray,
    onCategoryGray,
    categoryGrayContainer,
    onCategoryGrayContainer,
    categoryGrayOutline,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreColorScheme) return false;
    final a = _equalitySlots;
    final b = other._equalitySlots;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'CoreColorScheme(primary: $primary, secondary: $secondary, '
        'surface: $surface, onSurface: $onSurface, error: $error)';
  }

  /// Resolve every slot to a non-null value, filling any unset slot from
  /// CoUI's own normal scheme for [brightness]. Roots
  /// (primary/secondary/error/success/warning/info) are already non-null.
  ///
  /// The fill is the normal scheme even for a high-contrast one: a source
  /// that never states the category slots shows CoUI's normal values for
  /// them in high contrast too — see [CoreCategoryPalette.applyTo].
  ResolvedColorScheme resolved(CoreBrightness brightness) {
    final base = brightness == .light ? _defaultLight : _defaultDark;
    return ResolvedColorScheme(
      primary: primary,
      secondary: secondary,
      error: error,
      success: success,
      warning: warning,
      info: info,
      surface: surface ?? base.surface!,
      surfaceDim: surfaceDim ?? base.surfaceDim!,
      surfaceBright: surfaceBright ?? base.surfaceBright!,
      surfaceContainerLowest:
          surfaceContainerLowest ?? base.surfaceContainerLowest!,
      surfaceContainerLow: surfaceContainerLow ?? base.surfaceContainerLow!,
      surfaceContainer: surfaceContainer ?? base.surfaceContainer!,
      surfaceContainerHigh: surfaceContainerHigh ?? base.surfaceContainerHigh!,
      surfaceContainerHighest:
          surfaceContainerHighest ?? base.surfaceContainerHighest!,
      onSurface: onSurface ?? base.onSurface!,
      onSurfaceVariant: onSurfaceVariant ?? base.onSurfaceVariant!,
      placeholder: placeholder ?? base.placeholder!,
      link: link ?? base.link!,
      onSurfaceSubtle: onSurfaceSubtle ?? base.onSurfaceSubtle!,
      surfaceRaised: surfaceRaised ?? base.surfaceRaised!,
      surfaceTint: surfaceTint ?? base.surfaceTint!,
      onPrimary: onPrimary ?? base.onPrimary!,
      primaryContainer: primaryContainer ?? base.primaryContainer!,
      onPrimaryContainer: onPrimaryContainer ?? base.onPrimaryContainer!,
      primaryFixed: primaryFixed ?? base.primaryFixed!,
      primaryFixedDim: primaryFixedDim ?? base.primaryFixedDim!,
      onPrimaryFixed: onPrimaryFixed ?? base.onPrimaryFixed!,
      onPrimaryFixedVariant:
          onPrimaryFixedVariant ?? base.onPrimaryFixedVariant!,
      primaryText: primaryText ?? base.primaryText!,
      primaryTextLarge: primaryTextLarge ?? base.primaryTextLarge!,
      onSecondary: onSecondary ?? base.onSecondary!,
      secondaryContainer: secondaryContainer ?? base.secondaryContainer!,
      onSecondaryContainer: onSecondaryContainer ?? base.onSecondaryContainer!,
      secondaryFixed: secondaryFixed ?? base.secondaryFixed!,
      secondaryFixedDim: secondaryFixedDim ?? base.secondaryFixedDim!,
      onSecondaryFixed: onSecondaryFixed ?? base.onSecondaryFixed!,
      onSecondaryFixedVariant:
          onSecondaryFixedVariant ?? base.onSecondaryFixedVariant!,
      tertiary: tertiary ?? base.tertiary!,
      onTertiary: onTertiary ?? base.onTertiary!,
      tertiaryContainer: tertiaryContainer ?? base.tertiaryContainer!,
      onTertiaryContainer: onTertiaryContainer ?? base.onTertiaryContainer!,
      tertiaryFixed: tertiaryFixed ?? base.tertiaryFixed!,
      tertiaryFixedDim: tertiaryFixedDim ?? base.tertiaryFixedDim!,
      onTertiaryFixed: onTertiaryFixed ?? base.onTertiaryFixed!,
      onTertiaryFixedVariant:
          onTertiaryFixedVariant ?? base.onTertiaryFixedVariant!,
      onError: onError ?? base.onError!,
      errorContainer: errorContainer ?? base.errorContainer!,
      onErrorContainer: onErrorContainer ?? base.onErrorContainer!,
      errorStrong: errorStrong ?? base.errorStrong!,
      focusRing: focusRing ?? base.focusRing!,
      primaryHover: primaryHover ?? base.primaryHover!,
      primaryPressed: primaryPressed ?? base.primaryPressed!,
      secondaryHover: secondaryHover ?? base.secondaryHover!,
      secondaryPressed: secondaryPressed ?? base.secondaryPressed!,
      errorPressed: errorPressed ?? base.errorPressed!,
      onSuccess: onSuccess ?? base.onSuccess!,
      successContainer: successContainer ?? base.successContainer!,
      onSuccessContainer: onSuccessContainer ?? base.onSuccessContainer!,
      onWarning: onWarning ?? base.onWarning!,
      warningContainer: warningContainer ?? base.warningContainer!,
      onWarningContainer: onWarningContainer ?? base.onWarningContainer!,
      onInfo: onInfo ?? base.onInfo!,
      infoContainer: infoContainer ?? base.infoContainer!,
      onInfoContainer: onInfoContainer ?? base.onInfoContainer!,
      errorIcon: errorIcon ?? base.errorIcon!,
      successIcon: successIcon ?? base.successIcon!,
      warningIcon: warningIcon ?? base.warningIcon!,
      infoIcon: infoIcon ?? base.infoIcon!,
      outline: outline ?? base.outline!,
      outlineVariant: outlineVariant ?? base.outlineVariant!,
      outlineSubtle: outlineSubtle ?? base.outlineSubtle!,
      inverseSurface: inverseSurface ?? base.inverseSurface!,
      inverseOnSurface: inverseOnSurface ?? base.inverseOnSurface!,
      inversePrimary: inversePrimary ?? base.inversePrimary!,
      shadow: shadow ?? base.shadow!,
      // Derived from this palette's own surface rather than copied from
      // the default one, which is what every slot above does. A
      // highlight is a statement about the surface it sits on, so a dark
      // palette that omits it would inherit the light palette's
      // near-white and paint a rim belonging to a page it is not on.
      surfaceHighlight:
          surfaceHighlight ?? deriveSurfaceHighlight(surface ?? base.surface!),
      scrim: scrim ?? base.scrim!,
      disabledContent: disabledContent ?? base.disabledContent!,
      disabledContainer: disabledContainer ?? base.disabledContainer!,
      disabledOutline: disabledOutline ?? base.disabledOutline!,
      syntaxKeyword: syntaxKeyword ?? base.syntaxKeyword!,
      syntaxType: syntaxType ?? base.syntaxType!,
      syntaxFunction: syntaxFunction ?? base.syntaxFunction!,
      syntaxString: syntaxString ?? base.syntaxString!,
      categoryRed: categoryRed ?? base.categoryRed!,
      onCategoryRed: onCategoryRed ?? base.onCategoryRed!,
      categoryRedContainer: categoryRedContainer ?? base.categoryRedContainer!,
      onCategoryRedContainer:
          onCategoryRedContainer ?? base.onCategoryRedContainer!,
      categoryRedOutline: categoryRedOutline ?? base.categoryRedOutline!,
      categoryOrange: categoryOrange ?? base.categoryOrange!,
      onCategoryOrange: onCategoryOrange ?? base.onCategoryOrange!,
      categoryOrangeContainer:
          categoryOrangeContainer ?? base.categoryOrangeContainer!,
      onCategoryOrangeContainer:
          onCategoryOrangeContainer ?? base.onCategoryOrangeContainer!,
      categoryOrangeOutline:
          categoryOrangeOutline ?? base.categoryOrangeOutline!,
      categoryYellow: categoryYellow ?? base.categoryYellow!,
      onCategoryYellow: onCategoryYellow ?? base.onCategoryYellow!,
      categoryYellowContainer:
          categoryYellowContainer ?? base.categoryYellowContainer!,
      onCategoryYellowContainer:
          onCategoryYellowContainer ?? base.onCategoryYellowContainer!,
      categoryYellowOutline:
          categoryYellowOutline ?? base.categoryYellowOutline!,
      categoryGreen: categoryGreen ?? base.categoryGreen!,
      onCategoryGreen: onCategoryGreen ?? base.onCategoryGreen!,
      categoryGreenContainer:
          categoryGreenContainer ?? base.categoryGreenContainer!,
      onCategoryGreenContainer:
          onCategoryGreenContainer ?? base.onCategoryGreenContainer!,
      categoryGreenOutline: categoryGreenOutline ?? base.categoryGreenOutline!,
      categoryBlue: categoryBlue ?? base.categoryBlue!,
      onCategoryBlue: onCategoryBlue ?? base.onCategoryBlue!,
      categoryBlueContainer:
          categoryBlueContainer ?? base.categoryBlueContainer!,
      onCategoryBlueContainer:
          onCategoryBlueContainer ?? base.onCategoryBlueContainer!,
      categoryBlueOutline: categoryBlueOutline ?? base.categoryBlueOutline!,
      categoryPurple: categoryPurple ?? base.categoryPurple!,
      onCategoryPurple: onCategoryPurple ?? base.onCategoryPurple!,
      categoryPurpleContainer:
          categoryPurpleContainer ?? base.categoryPurpleContainer!,
      onCategoryPurpleContainer:
          onCategoryPurpleContainer ?? base.onCategoryPurpleContainer!,
      categoryPurpleOutline:
          categoryPurpleOutline ?? base.categoryPurpleOutline!,
      categoryPink: categoryPink ?? base.categoryPink!,
      onCategoryPink: onCategoryPink ?? base.onCategoryPink!,
      categoryPinkContainer:
          categoryPinkContainer ?? base.categoryPinkContainer!,
      onCategoryPinkContainer:
          onCategoryPinkContainer ?? base.onCategoryPinkContainer!,
      categoryPinkOutline: categoryPinkOutline ?? base.categoryPinkOutline!,
      categoryBrown: categoryBrown ?? base.categoryBrown!,
      onCategoryBrown: onCategoryBrown ?? base.onCategoryBrown!,
      categoryBrownContainer:
          categoryBrownContainer ?? base.categoryBrownContainer!,
      onCategoryBrownContainer:
          onCategoryBrownContainer ?? base.onCategoryBrownContainer!,
      categoryBrownOutline: categoryBrownOutline ?? base.categoryBrownOutline!,
      categoryGray: categoryGray ?? base.categoryGray!,
      onCategoryGray: onCategoryGray ?? base.onCategoryGray!,
      categoryGrayContainer:
          categoryGrayContainer ?? base.categoryGrayContainer!,
      onCategoryGrayContainer:
          onCategoryGrayContainer ?? base.onCategoryGrayContainer!,
      categoryGrayOutline: categoryGrayOutline ?? base.categoryGrayOutline!,
    );
  }

  /// Tag a raw [CoreColor] with its semantic [CoreColorToken]. If the
  /// colour is already tagged (or is itself a token reference), returns
  /// it unchanged.
  static CoreColor _tag(CoreColor c, CoreColorToken t) {
    if (c.token != null) return c;
    return CoreColor.tagged(c.argb, t, opacity: c.opacity);
  }

  /// Nullable variant of [_tag].
  static CoreColor? _tagN(CoreColor? c, CoreColorToken t) =>
      c == null ? null : _tag(c, t);

  /// Marks a slot [CoreColorScheme.raiseByDelta] leaves to its base.
  ///
  /// Compared by identity, never by value: built without `const` (the
  /// non-constant fallback list keeps it from being canonicalised) so no
  /// colour authored anywhere else can be this object. It carries a token so
  /// the constructor's tagging hands it back untouched — [_tag] keeps any
  /// colour that already has one — and it never escapes, because the second
  /// walk replaces every occurrence with the base slot.
  static final CoreColor _agreedSlot = CoreColor.token(
    CoreColors.surface,
    fallbacks: List<CoreColorToken>.empty(),
  );

  /// First walk of [CoreColorScheme.raiseByDelta]: the raised value where
  /// the two tables disagree, the [_agreedSlot] marker where they agree.
  static CoreColor? _markDisagreement(CoreColor? normal, CoreColor? raised) =>
      normal == raised ? _agreedSlot : raised;

  /// Second walk of [CoreColorScheme.raiseByDelta]: the base slot wherever
  /// the first walk left the marker.
  static CoreColor? _keepBaseWhereAgreed(CoreColor? base, CoreColor? delta) =>
      identical(delta, _agreedSlot) ? base : delta;

  /// Interpolates two slots, either of which may be unset.
  ///
  /// When only one side is set, the result is that side for the whole
  /// transition — a snap, not a fade. Flutter's `Color.lerp` does the
  /// opposite and fades the missing side in from transparent, but a null
  /// here means "this scheme does not define the role", not "the role is
  /// transparent". Fading would paint an undefined role for the length
  /// of the animation, as a tint nobody authored.
  static CoreColor? _lerpNullable(
    CoreColor? a,
    CoreColor? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return CoreColor.lerp(a, b, t);
  }

  // `Object.hash` takes at most 20 positional arguments and the slot list is
  // several times that, so this must be `hashAll`.
  @override
  int get hashCode => Object.hashAll(_equalitySlots);
}

CoreColor _required(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw ArgumentError('Missing required color: $key');
  }
  return _parseColorValue(value);
}

CoreColor? _nullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  return _parseColorValue(value);
}

CoreColor _parseColorValue(dynamic value) {
  if (value is CoreColor) return value;
  if (value is int) return CoreColor(value);

  final stringValue = value as String;
  if (stringValue.startsWith('oklch(')) {
    return CoreColorConversion.fromOKLch(stringValue);
  }
  // fromHex returns CoreColor via the sealed factory.
  final hex = CoreColor.fromHex(stringValue);
  return hex;
}
