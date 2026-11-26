// Token reader functions deliberately return `CoreColor?` even for
// always-set scheme fields (primary, secondary, error, success, warning,
// info) so every token shares the same `CoreColor? Function(CoreColorScheme)`
// signature in `CoreColorToken._` — the uniformity is the point, so the
// nullability is not redundant even where the field is always set.

// The CoreColors abstract class is a flat catalog of semantic color tokens —
// the M3 roles (surface, primary, secondary, ..., disabledOutline), the
// syntax slots (syntaxKeyword, ..., syntaxString) and the category slots
// (categoryRed, ..., categoryGrayOutline). Each token is named
// after its kebab-case CSS variable (e.g. `surfaceContainerHigh` →
// `--color-surface-container-high`), making it self-documenting; the
// class-level dartdoc covers the catalog's purpose and section comments group
// related tokens. Adding a per-token dartdoc would be redundant boilerplate.
// ignore_for_file: public_member_api_docs

/// Semantic colour token identifiers.
///
/// Each [CoreColorToken] wraps:
/// - a `name` in kebab-case for CSS variable rendering
///   (`'on-surface'` → `var(--color-on-surface)`),
/// - a `read` accessor that pulls the matching field from a
///   [CoreColorScheme] at render time.
///
/// Tokens are exposed as compile-time constants on [CoreColors] so they
/// can be embedded inside `const` style definitions:
///
/// ```dart
/// const filled = CoreButtonStyle.filled(
///   backgroundColor: CoreColor.token(CoreColors.primary),
/// );
/// ```
///
/// The token list is the single source of truth for the semantic
/// vocabulary; it mirrors the non-deprecated fields on
/// [CoreColorScheme] exactly, the category slots included —
/// [CoreCategoryColor] names those by hue and slot. Adding a token here
/// without a matching scheme field (or vice-versa) is caught at compile
/// time by the accessor functions.
library;

import 'package:coui_core/src/color/category_palette.dart';
import 'package:coui_core/src/color/color_scheme.dart';
import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

/// A semantic colour token — a stable identifier for a slot in
/// [CoreColorScheme].
@immutable
class CoreColorToken {
  const CoreColorToken._(this.name, this.read);

  /// Kebab-case identifier used for CSS variable names
  /// (`var(--color-{name})`).
  final String name;

  /// Resolves this token against `scheme`. Returns `null` when the
  /// scheme leaves the slot unset.
  final CoreColor? Function(CoreColorScheme scheme) read;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CoreColorToken && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'CoreColorToken($name)';
}

/// All semantic colour tokens — compile-time constants.
///
/// Use as:
/// ```dart
/// CoreColor.token(CoreColors.primary)
/// CoreColor.token(CoreColors.onSurface)
/// ```
abstract final class CoreColors {
  // ── Surface ────────────────────────────────────────────────────────
  static const surface = CoreColorToken._('surface', _surface);
  static const surfaceDim = CoreColorToken._('surface-dim', _surfaceDim);
  static const surfaceBright = CoreColorToken._(
    'surface-bright',
    _surfaceBright,
  );
  static const surfaceContainerLowest = CoreColorToken._(
    'surface-container-lowest',
    _surfaceContainerLowest,
  );
  static const surfaceContainerLow = CoreColorToken._(
    'surface-container-low',
    _surfaceContainerLow,
  );
  static const surfaceContainer = CoreColorToken._(
    'surface-container',
    _surfaceContainer,
  );
  static const surfaceContainerHigh = CoreColorToken._(
    'surface-container-high',
    _surfaceContainerHigh,
  );
  static const surfaceContainerHighest = CoreColorToken._(
    'surface-container-highest',
    _surfaceContainerHighest,
  );
  static const onSurface = CoreColorToken._('on-surface', _onSurface);
  static const onSurfaceVariant = CoreColorToken._(
    'on-surface-variant',
    _onSurfaceVariant,
  );
  static const placeholder = CoreColorToken._('placeholder', _placeholder);
  static const link = CoreColorToken._('link', _link);
  static const onSurfaceSubtle = CoreColorToken._(
    'on-surface-subtle',
    _onSurfaceSubtle,
  );
  static const surfaceRaised = CoreColorToken._(
    'surface-raised',
    _surfaceRaised,
  );
  static const surfaceTint = CoreColorToken._('surface-tint', _surfaceTint);

  // ── Primary ────────────────────────────────────────────────────────
  static const primary = CoreColorToken._('primary', _primary);
  static const onPrimary = CoreColorToken._('on-primary', _onPrimary);
  static const primaryContainer = CoreColorToken._(
    'primary-container',
    _primaryContainer,
  );
  static const onPrimaryContainer = CoreColorToken._(
    'on-primary-container',
    _onPrimaryContainer,
  );
  static const primaryFixed = CoreColorToken._('primary-fixed', _primaryFixed);
  static const primaryFixedDim = CoreColorToken._(
    'primary-fixed-dim',
    _primaryFixedDim,
  );
  static const onPrimaryFixed = CoreColorToken._(
    'on-primary-fixed',
    _onPrimaryFixed,
  );
  static const onPrimaryFixedVariant = CoreColorToken._(
    'on-primary-fixed-variant',
    _onPrimaryFixedVariant,
  );
  static const primaryText = CoreColorToken._('primary-text', _primaryText);
  static const primaryTextLarge = CoreColorToken._(
    'primary-text-large',
    _primaryTextLarge,
  );

  // ── Secondary ──────────────────────────────────────────────────────
  static const secondary = CoreColorToken._('secondary', _secondary);
  static const onSecondary = CoreColorToken._('on-secondary', _onSecondary);
  static const secondaryContainer = CoreColorToken._(
    'secondary-container',
    _secondaryContainer,
  );
  static const onSecondaryContainer = CoreColorToken._(
    'on-secondary-container',
    _onSecondaryContainer,
  );
  static const secondaryFixed = CoreColorToken._(
    'secondary-fixed',
    _secondaryFixed,
  );
  static const secondaryFixedDim = CoreColorToken._(
    'secondary-fixed-dim',
    _secondaryFixedDim,
  );
  static const onSecondaryFixed = CoreColorToken._(
    'on-secondary-fixed',
    _onSecondaryFixed,
  );
  static const onSecondaryFixedVariant = CoreColorToken._(
    'on-secondary-fixed-variant',
    _onSecondaryFixedVariant,
  );

  // ── Tertiary ───────────────────────────────────────────────────────
  static const tertiary = CoreColorToken._('tertiary', _tertiary);
  static const onTertiary = CoreColorToken._('on-tertiary', _onTertiary);
  static const tertiaryContainer = CoreColorToken._(
    'tertiary-container',
    _tertiaryContainer,
  );
  static const onTertiaryContainer = CoreColorToken._(
    'on-tertiary-container',
    _onTertiaryContainer,
  );
  static const tertiaryFixed = CoreColorToken._(
    'tertiary-fixed',
    _tertiaryFixed,
  );
  static const tertiaryFixedDim = CoreColorToken._(
    'tertiary-fixed-dim',
    _tertiaryFixedDim,
  );
  static const onTertiaryFixed = CoreColorToken._(
    'on-tertiary-fixed',
    _onTertiaryFixed,
  );
  static const onTertiaryFixedVariant = CoreColorToken._(
    'on-tertiary-fixed-variant',
    _onTertiaryFixedVariant,
  );

  // ── Accent ─────────────────────────────────────────────────────────
  // The brand accent. Same scheme fields as tertiary / onTertiary — a name
  // for the role, not a second palette. In CoUI's own mapping the tertiary
  // family restates primary, so `accent` is `primary`'s colour; a brand
  // gets its own accent from its own tertiary (a product mint is that
  // product's `PrimitiveColors` / `CoreBrand`, not a kit-wide hex).
  static const accent = CoreColorToken._('accent', _tertiary);
  static const onAccent = CoreColorToken._('on-accent', _onTertiary);

  // ── Error ──────────────────────────────────────────────────────────
  static const error = CoreColorToken._('error', _error);
  static const onError = CoreColorToken._('on-error', _onError);
  static const errorContainer = CoreColorToken._(
    'error-container',
    _errorContainer,
  );
  static const onErrorContainer = CoreColorToken._(
    'on-error-container',
    _onErrorContainer,
  );
  static const errorStrong = CoreColorToken._('error-strong', _errorStrong);
  static const focusRing = CoreColorToken._('focus-ring', _focusRing);
  static const primaryHover = CoreColorToken._(
    'primary-hover',
    _primaryHover,
  );
  static const primaryPressed = CoreColorToken._(
    'primary-pressed',
    _primaryPressed,
  );
  static const secondaryHover = CoreColorToken._(
    'secondary-hover',
    _secondaryHover,
  );
  static const secondaryPressed = CoreColorToken._(
    'secondary-pressed',
    _secondaryPressed,
  );
  static const errorPressed = CoreColorToken._(
    'error-pressed',
    _errorPressed,
  );

  // ── Success ────────────────────────────────────────────────────────
  static const success = CoreColorToken._('success', _success);
  static const onSuccess = CoreColorToken._('on-success', _onSuccess);
  static const successContainer = CoreColorToken._(
    'success-container',
    _successContainer,
  );
  static const onSuccessContainer = CoreColorToken._(
    'on-success-container',
    _onSuccessContainer,
  );

  // ── Warning ────────────────────────────────────────────────────────
  static const warning = CoreColorToken._('warning', _warning);
  static const onWarning = CoreColorToken._('on-warning', _onWarning);
  static const warningContainer = CoreColorToken._(
    'warning-container',
    _warningContainer,
  );
  static const onWarningContainer = CoreColorToken._(
    'on-warning-container',
    _onWarningContainer,
  );

  // ── Info ───────────────────────────────────────────────────────────
  static const info = CoreColorToken._('info', _info);
  static const onInfo = CoreColorToken._('on-info', _onInfo);
  static const infoContainer = CoreColorToken._(
    'info-container',
    _infoContainer,
  );
  static const onInfoContainer = CoreColorToken._(
    'on-info-container',
    _onInfoContainer,
  );

  // ── Status indicators ──────────────────────────────────────────────
  // Non-text marks (icons, status dots, progress bars, chart marks): 3:1
  // against the page, 4.5:1 in high contrast.
  static const errorIcon = CoreColorToken._('error-icon', _errorIcon);
  static const successIcon = CoreColorToken._('success-icon', _successIcon);
  static const warningIcon = CoreColorToken._('warning-icon', _warningIcon);
  static const infoIcon = CoreColorToken._('info-icon', _infoIcon);

  // ── Outline / Inverse / Misc ───────────────────────────────────────
  static const outline = CoreColorToken._('outline', _outline);
  static const outlineVariant = CoreColorToken._(
    'outline-variant',
    _outlineVariant,
  );
  static const outlineSubtle = CoreColorToken._(
    'outline-subtle',
    _outlineSubtle,
  );
  static const inverseSurface = CoreColorToken._(
    'inverse-surface',
    _inverseSurface,
  );
  static const inverseOnSurface = CoreColorToken._(
    'inverse-on-surface',
    _inverseOnSurface,
  );
  static const inversePrimary = CoreColorToken._(
    'inverse-primary',
    _inversePrimary,
  );
  static const shadow = CoreColorToken._('shadow', _shadow);
  static const surfaceHighlight = CoreColorToken._(
    'surface-highlight',
    _surfaceHighlight,
  );
  static const scrim = CoreColorToken._('scrim', _scrim);

  // ── Disabled ───────────────────────────────────────────────────────

  /// Ink for a disabled control's **graphics** — a check mark, a
  /// chevron, a thumb. Deliberately low against [disabledContainer]
  /// (3.19:1 light, 3.67:1 dark): a glyph nobody needs to read carries
  /// the off state better by being faint.
  ///
  /// **Not for text.** A disabled label still has to be read — it is
  /// what tells someone which control is off and, often, how to turn it
  /// on. Labels drop one step to [onSurfaceVariant] instead (6.6:1 /
  /// 8.45:1 over the same fill). WCAG exempts disabled controls from
  /// the contrast floor, but exempt and legible are different claims.
  static const disabledContent = CoreColorToken._(
    'disabled-content',
    _disabledContent,
  );
  static const disabledContainer = CoreColorToken._(
    'disabled-container',
    _disabledContainer,
  );
  static const disabledOutline = CoreColorToken._(
    'disabled-outline',
    _disabledOutline,
  );

  // ── Syntax ─────────────────────────────────────────────────────────
  // Code highlighting. Keyword, type and string read CoreSyntaxPalette's
  // brand-less values; function reads the brand's info ramp.
  static const syntaxKeyword = CoreColorToken._(
    'syntax-keyword',
    _syntaxKeyword,
  );
  static const syntaxType = CoreColorToken._('syntax-type', _syntaxType);
  static const syntaxFunction = CoreColorToken._(
    'syntax-function',
    _syntaxFunction,
  );
  static const syntaxString = CoreColorToken._('syntax-string', _syntaxString);

  // ── Category ───────────────────────────────────────────────────────
  // Nine hues × five slots, the same in every brand: the values are
  // CoreCategoryPalette's, and CoreCategoryColor names each token by hue
  // and slot.
  static const categoryRed = CoreColorToken._('category-red', _categoryRed);
  static const onCategoryRed = CoreColorToken._(
    'on-category-red',
    _onCategoryRed,
  );
  static const categoryRedContainer = CoreColorToken._(
    'category-red-container',
    _categoryRedContainer,
  );
  static const onCategoryRedContainer = CoreColorToken._(
    'on-category-red-container',
    _onCategoryRedContainer,
  );
  static const categoryRedOutline = CoreColorToken._(
    'category-red-outline',
    _categoryRedOutline,
  );
  static const categoryOrange = CoreColorToken._(
    'category-orange',
    _categoryOrange,
  );
  static const onCategoryOrange = CoreColorToken._(
    'on-category-orange',
    _onCategoryOrange,
  );
  static const categoryOrangeContainer = CoreColorToken._(
    'category-orange-container',
    _categoryOrangeContainer,
  );
  static const onCategoryOrangeContainer = CoreColorToken._(
    'on-category-orange-container',
    _onCategoryOrangeContainer,
  );
  static const categoryOrangeOutline = CoreColorToken._(
    'category-orange-outline',
    _categoryOrangeOutline,
  );
  static const categoryYellow = CoreColorToken._(
    'category-yellow',
    _categoryYellow,
  );
  static const onCategoryYellow = CoreColorToken._(
    'on-category-yellow',
    _onCategoryYellow,
  );
  static const categoryYellowContainer = CoreColorToken._(
    'category-yellow-container',
    _categoryYellowContainer,
  );
  static const onCategoryYellowContainer = CoreColorToken._(
    'on-category-yellow-container',
    _onCategoryYellowContainer,
  );
  static const categoryYellowOutline = CoreColorToken._(
    'category-yellow-outline',
    _categoryYellowOutline,
  );
  static const categoryGreen = CoreColorToken._(
    'category-green',
    _categoryGreen,
  );
  static const onCategoryGreen = CoreColorToken._(
    'on-category-green',
    _onCategoryGreen,
  );
  static const categoryGreenContainer = CoreColorToken._(
    'category-green-container',
    _categoryGreenContainer,
  );
  static const onCategoryGreenContainer = CoreColorToken._(
    'on-category-green-container',
    _onCategoryGreenContainer,
  );
  static const categoryGreenOutline = CoreColorToken._(
    'category-green-outline',
    _categoryGreenOutline,
  );
  static const categoryBlue = CoreColorToken._('category-blue', _categoryBlue);
  static const onCategoryBlue = CoreColorToken._(
    'on-category-blue',
    _onCategoryBlue,
  );
  static const categoryBlueContainer = CoreColorToken._(
    'category-blue-container',
    _categoryBlueContainer,
  );
  static const onCategoryBlueContainer = CoreColorToken._(
    'on-category-blue-container',
    _onCategoryBlueContainer,
  );
  static const categoryBlueOutline = CoreColorToken._(
    'category-blue-outline',
    _categoryBlueOutline,
  );
  static const categoryPurple = CoreColorToken._(
    'category-purple',
    _categoryPurple,
  );
  static const onCategoryPurple = CoreColorToken._(
    'on-category-purple',
    _onCategoryPurple,
  );
  static const categoryPurpleContainer = CoreColorToken._(
    'category-purple-container',
    _categoryPurpleContainer,
  );
  static const onCategoryPurpleContainer = CoreColorToken._(
    'on-category-purple-container',
    _onCategoryPurpleContainer,
  );
  static const categoryPurpleOutline = CoreColorToken._(
    'category-purple-outline',
    _categoryPurpleOutline,
  );
  static const categoryPink = CoreColorToken._('category-pink', _categoryPink);
  static const onCategoryPink = CoreColorToken._(
    'on-category-pink',
    _onCategoryPink,
  );
  static const categoryPinkContainer = CoreColorToken._(
    'category-pink-container',
    _categoryPinkContainer,
  );
  static const onCategoryPinkContainer = CoreColorToken._(
    'on-category-pink-container',
    _onCategoryPinkContainer,
  );
  static const categoryPinkOutline = CoreColorToken._(
    'category-pink-outline',
    _categoryPinkOutline,
  );
  static const categoryBrown = CoreColorToken._(
    'category-brown',
    _categoryBrown,
  );
  static const onCategoryBrown = CoreColorToken._(
    'on-category-brown',
    _onCategoryBrown,
  );
  static const categoryBrownContainer = CoreColorToken._(
    'category-brown-container',
    _categoryBrownContainer,
  );
  static const onCategoryBrownContainer = CoreColorToken._(
    'on-category-brown-container',
    _onCategoryBrownContainer,
  );
  static const categoryBrownOutline = CoreColorToken._(
    'category-brown-outline',
    _categoryBrownOutline,
  );
  static const categoryGray = CoreColorToken._('category-gray', _categoryGray);
  static const onCategoryGray = CoreColorToken._(
    'on-category-gray',
    _onCategoryGray,
  );
  static const categoryGrayContainer = CoreColorToken._(
    'category-gray-container',
    _categoryGrayContainer,
  );
  static const onCategoryGrayContainer = CoreColorToken._(
    'on-category-gray-container',
    _onCategoryGrayContainer,
  );
  static const categoryGrayOutline = CoreColorToken._(
    'category-gray-outline',
    _categoryGrayOutline,
  );

  // ── Fill → on-colour pairing ────────────────────────────────────────

  /// The on-colour a scheme states for drawing on [fill], or `null` when
  /// [fill] is not a fill the scheme pairs with one.
  ///
  /// The pairs are the ones the mapping is written to: each role, its
  /// container and its fixed tones carry their own `on*` slot, the
  /// hover / pressed steps of a role keep the role's on-colour, every
  /// surface tone carries [onSurface], [inverseSurface] carries
  /// [inverseOnSurface], and each category hue's fill and container carry
  /// their own `on-category-*` slot. Answering with a token rather than a
  /// colour keeps the label in the scheme's hands — it follows the mode,
  /// high contrast and a brand's own mapping exactly as the fill does, and
  /// the Web emits it as a class like any other token.
  ///
  /// `null` for everything else — the on-colours themselves, the ink and
  /// stroke tones (`outline`, `primaryText`, `focusRing`, a category
  /// outline, …) and the effect tones (`shadow`, `scrim`,
  /// `surfaceHighlight`). Those are drawn *on* a fill, not filled under a
  /// label, so the scheme states no on-colour for them and a caller that
  /// fills with one has to decide the label itself.
  static CoreColorToken? onColorOf(CoreColorToken fill) => _onColorPairs[fill];
}

/// [CoreColors.onColorOf]'s table. A `final` map, not `const`: a constant
/// map's keys may not override `==`, and [CoreColorToken] compares by name.
final Map<CoreColorToken, CoreColorToken> _onColorPairs = {
  // Surface — every tone carries the same on-colour.
  CoreColors.surface: CoreColors.onSurface,
  CoreColors.surfaceDim: CoreColors.onSurface,
  CoreColors.surfaceBright: CoreColors.onSurface,
  CoreColors.surfaceContainerLowest: CoreColors.onSurface,
  CoreColors.surfaceContainerLow: CoreColors.onSurface,
  CoreColors.surfaceContainer: CoreColors.onSurface,
  CoreColors.surfaceContainerHigh: CoreColors.onSurface,
  CoreColors.surfaceContainerHighest: CoreColors.onSurface,
  CoreColors.surfaceRaised: CoreColors.onSurface,
  // Primary
  CoreColors.primary: CoreColors.onPrimary,
  CoreColors.primaryHover: CoreColors.onPrimary,
  CoreColors.primaryPressed: CoreColors.onPrimary,
  CoreColors.primaryContainer: CoreColors.onPrimaryContainer,
  CoreColors.primaryFixed: CoreColors.onPrimaryFixed,
  CoreColors.primaryFixedDim: CoreColors.onPrimaryFixed,
  // Secondary
  CoreColors.secondary: CoreColors.onSecondary,
  CoreColors.secondaryHover: CoreColors.onSecondary,
  CoreColors.secondaryPressed: CoreColors.onSecondary,
  CoreColors.secondaryContainer: CoreColors.onSecondaryContainer,
  CoreColors.secondaryFixed: CoreColors.onSecondaryFixed,
  CoreColors.secondaryFixedDim: CoreColors.onSecondaryFixed,
  // Tertiary and its accent alias
  CoreColors.tertiary: CoreColors.onTertiary,
  CoreColors.tertiaryContainer: CoreColors.onTertiaryContainer,
  CoreColors.tertiaryFixed: CoreColors.onTertiaryFixed,
  CoreColors.tertiaryFixedDim: CoreColors.onTertiaryFixed,
  CoreColors.accent: CoreColors.onAccent,
  // Error
  CoreColors.error: CoreColors.onError,
  CoreColors.errorPressed: CoreColors.onError,
  CoreColors.errorContainer: CoreColors.onErrorContainer,
  // Status
  CoreColors.success: CoreColors.onSuccess,
  CoreColors.successContainer: CoreColors.onSuccessContainer,
  CoreColors.warning: CoreColors.onWarning,
  CoreColors.warningContainer: CoreColors.onWarningContainer,
  CoreColors.info: CoreColors.onInfo,
  CoreColors.infoContainer: CoreColors.onInfoContainer,
  // Inverse
  CoreColors.inverseSurface: CoreColors.inverseOnSurface,
  // Category — the fill and the container each carry their own label. The
  // outline is a border, drawn on a fill rather than under a label.
  for (final color in CoreCategoryColor.values) ...{
    color.fill: color.onFill,
    color.container: color.onContainer,
  },
};

// ── Accessor functions ────────────────────────────────────────────────
// Each token's `read` points to one of these. A separate top-level
// function (rather than a closure on CoreColorScheme) keeps the token
// declarations `const`.

CoreColor? _surface(CoreColorScheme s) => s.surface;
CoreColor? _surfaceDim(CoreColorScheme s) => s.surfaceDim;
CoreColor? _surfaceBright(CoreColorScheme s) => s.surfaceBright;
CoreColor? _surfaceContainerLowest(CoreColorScheme s) =>
    s.surfaceContainerLowest;
CoreColor? _surfaceContainerLow(CoreColorScheme s) => s.surfaceContainerLow;
CoreColor? _surfaceContainer(CoreColorScheme s) => s.surfaceContainer;
CoreColor? _surfaceContainerHigh(CoreColorScheme s) => s.surfaceContainerHigh;
CoreColor? _surfaceContainerHighest(CoreColorScheme s) =>
    s.surfaceContainerHighest;
CoreColor? _onSurface(CoreColorScheme s) => s.onSurface;
CoreColor? _onSurfaceVariant(CoreColorScheme s) => s.onSurfaceVariant;
CoreColor? _placeholder(CoreColorScheme s) => s.placeholder;
CoreColor? _link(CoreColorScheme s) => s.link;
CoreColor? _onSurfaceSubtle(CoreColorScheme s) => s.onSurfaceSubtle;
CoreColor? _surfaceRaised(CoreColorScheme s) => s.surfaceRaised;
CoreColor? _surfaceTint(CoreColorScheme s) => s.surfaceTint;

CoreColor _primary(CoreColorScheme s) => s.primary;
CoreColor? _onPrimary(CoreColorScheme s) => s.onPrimary;
CoreColor? _primaryContainer(CoreColorScheme s) => s.primaryContainer;
CoreColor? _onPrimaryContainer(CoreColorScheme s) => s.onPrimaryContainer;
CoreColor? _primaryFixed(CoreColorScheme s) => s.primaryFixed;
CoreColor? _primaryFixedDim(CoreColorScheme s) => s.primaryFixedDim;
CoreColor? _onPrimaryFixed(CoreColorScheme s) => s.onPrimaryFixed;
CoreColor? _onPrimaryFixedVariant(CoreColorScheme s) => s.onPrimaryFixedVariant;
CoreColor? _primaryText(CoreColorScheme s) => s.primaryText;
CoreColor? _primaryTextLarge(CoreColorScheme s) => s.primaryTextLarge;

CoreColor _secondary(CoreColorScheme s) => s.secondary;
CoreColor? _onSecondary(CoreColorScheme s) => s.onSecondary;
CoreColor? _secondaryContainer(CoreColorScheme s) => s.secondaryContainer;
CoreColor? _onSecondaryContainer(CoreColorScheme s) => s.onSecondaryContainer;
CoreColor? _secondaryFixed(CoreColorScheme s) => s.secondaryFixed;
CoreColor? _secondaryFixedDim(CoreColorScheme s) => s.secondaryFixedDim;
CoreColor? _onSecondaryFixed(CoreColorScheme s) => s.onSecondaryFixed;
CoreColor? _onSecondaryFixedVariant(CoreColorScheme s) =>
    s.onSecondaryFixedVariant;

CoreColor? _tertiary(CoreColorScheme s) => s.tertiary;
CoreColor? _onTertiary(CoreColorScheme s) => s.onTertiary;
CoreColor? _tertiaryContainer(CoreColorScheme s) => s.tertiaryContainer;
CoreColor? _onTertiaryContainer(CoreColorScheme s) => s.onTertiaryContainer;
CoreColor? _tertiaryFixed(CoreColorScheme s) => s.tertiaryFixed;
CoreColor? _tertiaryFixedDim(CoreColorScheme s) => s.tertiaryFixedDim;
CoreColor? _onTertiaryFixed(CoreColorScheme s) => s.onTertiaryFixed;
CoreColor? _onTertiaryFixedVariant(CoreColorScheme s) =>
    s.onTertiaryFixedVariant;

CoreColor _error(CoreColorScheme s) => s.error;
CoreColor? _onError(CoreColorScheme s) => s.onError;
CoreColor? _errorContainer(CoreColorScheme s) => s.errorContainer;
CoreColor? _onErrorContainer(CoreColorScheme s) => s.onErrorContainer;
CoreColor? _errorStrong(CoreColorScheme s) => s.errorStrong;
CoreColor? _focusRing(CoreColorScheme s) => s.focusRing;
CoreColor? _primaryHover(CoreColorScheme s) => s.primaryHover;
CoreColor? _primaryPressed(CoreColorScheme s) => s.primaryPressed;
CoreColor? _secondaryHover(CoreColorScheme s) => s.secondaryHover;
CoreColor? _secondaryPressed(CoreColorScheme s) => s.secondaryPressed;
CoreColor? _errorPressed(CoreColorScheme s) => s.errorPressed;

CoreColor _success(CoreColorScheme s) => s.success;
CoreColor? _onSuccess(CoreColorScheme s) => s.onSuccess;
CoreColor? _successContainer(CoreColorScheme s) => s.successContainer;
CoreColor? _onSuccessContainer(CoreColorScheme s) => s.onSuccessContainer;

CoreColor _warning(CoreColorScheme s) => s.warning;
CoreColor? _onWarning(CoreColorScheme s) => s.onWarning;
CoreColor? _warningContainer(CoreColorScheme s) => s.warningContainer;
CoreColor? _onWarningContainer(CoreColorScheme s) => s.onWarningContainer;

CoreColor _info(CoreColorScheme s) => s.info;
CoreColor? _onInfo(CoreColorScheme s) => s.onInfo;
CoreColor? _infoContainer(CoreColorScheme s) => s.infoContainer;
CoreColor? _onInfoContainer(CoreColorScheme s) => s.onInfoContainer;
CoreColor? _errorIcon(CoreColorScheme s) => s.errorIcon;
CoreColor? _successIcon(CoreColorScheme s) => s.successIcon;
CoreColor? _warningIcon(CoreColorScheme s) => s.warningIcon;
CoreColor? _infoIcon(CoreColorScheme s) => s.infoIcon;

CoreColor? _outline(CoreColorScheme s) => s.outline;
CoreColor? _outlineVariant(CoreColorScheme s) => s.outlineVariant;
CoreColor? _outlineSubtle(CoreColorScheme s) => s.outlineSubtle;
CoreColor? _inverseSurface(CoreColorScheme s) => s.inverseSurface;
CoreColor? _inverseOnSurface(CoreColorScheme s) => s.inverseOnSurface;
CoreColor? _inversePrimary(CoreColorScheme s) => s.inversePrimary;
CoreColor? _shadow(CoreColorScheme s) => s.shadow;
CoreColor? _surfaceHighlight(CoreColorScheme s) {
  final stated = s.surfaceHighlight;
  if (stated != null) return stated;
  // Derived here, not only in `resolved()`, because this is the read a
  // painted colour goes through. A palette that states no highlight
  // would otherwise resolve to nothing and paint at alpha 0 on Flutter
  // while invalidating the whole `box-shadow` declaration on Web.
  final surface = s.surface;

  return surface == null || !surface.isResolved
      ? null
      : deriveSurfaceHighlight(surface);
}

CoreColor? _scrim(CoreColorScheme s) => s.scrim;

CoreColor? _disabledContent(CoreColorScheme s) => s.disabledContent;
CoreColor? _disabledContainer(CoreColorScheme s) => s.disabledContainer;
CoreColor? _disabledOutline(CoreColorScheme s) => s.disabledOutline;

CoreColor? _syntaxKeyword(CoreColorScheme s) => s.syntaxKeyword;
CoreColor? _syntaxType(CoreColorScheme s) => s.syntaxType;
CoreColor? _syntaxFunction(CoreColorScheme s) => s.syntaxFunction;
CoreColor? _syntaxString(CoreColorScheme s) => s.syntaxString;

CoreColor? _categoryRed(CoreColorScheme s) => s.categoryRed;
CoreColor? _onCategoryRed(CoreColorScheme s) => s.onCategoryRed;
CoreColor? _categoryRedContainer(CoreColorScheme s) => s.categoryRedContainer;
CoreColor? _onCategoryRedContainer(CoreColorScheme s) =>
    s.onCategoryRedContainer;
CoreColor? _categoryRedOutline(CoreColorScheme s) => s.categoryRedOutline;
CoreColor? _categoryOrange(CoreColorScheme s) => s.categoryOrange;
CoreColor? _onCategoryOrange(CoreColorScheme s) => s.onCategoryOrange;
CoreColor? _categoryOrangeContainer(CoreColorScheme s) =>
    s.categoryOrangeContainer;
CoreColor? _onCategoryOrangeContainer(CoreColorScheme s) =>
    s.onCategoryOrangeContainer;
CoreColor? _categoryOrangeOutline(CoreColorScheme s) => s.categoryOrangeOutline;
CoreColor? _categoryYellow(CoreColorScheme s) => s.categoryYellow;
CoreColor? _onCategoryYellow(CoreColorScheme s) => s.onCategoryYellow;
CoreColor? _categoryYellowContainer(CoreColorScheme s) =>
    s.categoryYellowContainer;
CoreColor? _onCategoryYellowContainer(CoreColorScheme s) =>
    s.onCategoryYellowContainer;
CoreColor? _categoryYellowOutline(CoreColorScheme s) => s.categoryYellowOutline;
CoreColor? _categoryGreen(CoreColorScheme s) => s.categoryGreen;
CoreColor? _onCategoryGreen(CoreColorScheme s) => s.onCategoryGreen;
CoreColor? _categoryGreenContainer(CoreColorScheme s) =>
    s.categoryGreenContainer;
CoreColor? _onCategoryGreenContainer(CoreColorScheme s) =>
    s.onCategoryGreenContainer;
CoreColor? _categoryGreenOutline(CoreColorScheme s) => s.categoryGreenOutline;
CoreColor? _categoryBlue(CoreColorScheme s) => s.categoryBlue;
CoreColor? _onCategoryBlue(CoreColorScheme s) => s.onCategoryBlue;
CoreColor? _categoryBlueContainer(CoreColorScheme s) => s.categoryBlueContainer;
CoreColor? _onCategoryBlueContainer(CoreColorScheme s) =>
    s.onCategoryBlueContainer;
CoreColor? _categoryBlueOutline(CoreColorScheme s) => s.categoryBlueOutline;
CoreColor? _categoryPurple(CoreColorScheme s) => s.categoryPurple;
CoreColor? _onCategoryPurple(CoreColorScheme s) => s.onCategoryPurple;
CoreColor? _categoryPurpleContainer(CoreColorScheme s) =>
    s.categoryPurpleContainer;
CoreColor? _onCategoryPurpleContainer(CoreColorScheme s) =>
    s.onCategoryPurpleContainer;
CoreColor? _categoryPurpleOutline(CoreColorScheme s) => s.categoryPurpleOutline;
CoreColor? _categoryPink(CoreColorScheme s) => s.categoryPink;
CoreColor? _onCategoryPink(CoreColorScheme s) => s.onCategoryPink;
CoreColor? _categoryPinkContainer(CoreColorScheme s) => s.categoryPinkContainer;
CoreColor? _onCategoryPinkContainer(CoreColorScheme s) =>
    s.onCategoryPinkContainer;
CoreColor? _categoryPinkOutline(CoreColorScheme s) => s.categoryPinkOutline;
CoreColor? _categoryBrown(CoreColorScheme s) => s.categoryBrown;
CoreColor? _onCategoryBrown(CoreColorScheme s) => s.onCategoryBrown;
CoreColor? _categoryBrownContainer(CoreColorScheme s) =>
    s.categoryBrownContainer;
CoreColor? _onCategoryBrownContainer(CoreColorScheme s) =>
    s.onCategoryBrownContainer;
CoreColor? _categoryBrownOutline(CoreColorScheme s) => s.categoryBrownOutline;
CoreColor? _categoryGray(CoreColorScheme s) => s.categoryGray;
CoreColor? _onCategoryGray(CoreColorScheme s) => s.onCategoryGray;
CoreColor? _categoryGrayContainer(CoreColorScheme s) => s.categoryGrayContainer;
CoreColor? _onCategoryGrayContainer(CoreColorScheme s) =>
    s.onCategoryGrayContainer;
CoreColor? _categoryGrayOutline(CoreColorScheme s) => s.categoryGrayOutline;
