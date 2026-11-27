/// Platform-independent colour descriptor.
///
/// Single class with two modes (Epic #1415):
///
/// - **Raw ARGB** — `CoreColor(0xFFRRGGBB)`, `CoreColor.fromARGB(...)`,
///   `CoreColor.fromHex(...)`. Carries an actual 32-bit colour value;
///   ARGB channel helpers (`red`, `green`, `toHex`, …) operate on it.
///
/// - **Semantic token** — `CoreColor.primary` (`.primary` in a color slot).
///   Carries only a reference to a slot in [CoreColorScheme]; the actual ARGB
///   is `0` until the scheme resolves the token.
///
/// On the Web, the per-platform extension renders semantic tokens as
/// `var(--color-X)`, preserving daisyUI / dark-mode auto-switching.
/// On Flutter, the scheme is needed to look up the ARGB; the platform
/// extension throws if a token is converted without resolution.
///
/// ### Design rule
///
/// ARGB-only operations (`red`, `toHex`, `toRgba`, conversion to OKLch
/// / HSL) throw [StateError] when called on an unresolved token,
/// preventing silent "token → transparent black" bugs. Use
/// `CoreColorScheme.resolve` (or simply pass through a Co\* component)
/// to convert a token reference into a resolved colour first.
library;

import 'package:coui_core/src/color/color_scheme.dart' show CoreColorScheme;
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:meta/meta.dart';

/// Platform-agnostic colour value used across the CoUI token system.
///
/// A `CoreColor` may be a raw ARGB literal or a token reference; calling
/// `CoreColorScheme.resolve` materialises it into a concrete ARGB value.
@immutable
class CoreColor {
  /// Raw ARGB colour. `CoreColor(0xFFFF0000)` keeps working.
  const CoreColor(this.argb)
    : token = null,
      opacity = 1.0,
      fallbacks = const <CoreColorToken>[];

  /// ARGB colour from individual channels.
  const CoreColor.fromARGB(int a, int r, int g, int b)
    : argb =
          ((a & 0xFF) << 24) |
          ((r & 0xFF) << 16) |
          ((g & 0xFF) << 8) |
          (b & 0xFF),
      token = null,
      opacity = 1.0,
      fallbacks = const <CoreColorToken>[];

  /// ARGB colour from RGB bytes (alpha 255).
  const CoreColor.fromRGB(int r, int g, int b)
    : argb = (0xFF << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF),
      token = null,
      opacity = 1.0,
      fallbacks = const <CoreColorToken>[];

  /// Semantic token reference with optional opacity modifier and
  /// fallback chain.
  ///
  /// - [token] is the preferred slot.
  /// - [fallbacks] is an optional list of slots to try if the preferred
  ///   slot is `null` in the active scheme. Tried in order.
  /// - [opacity] (0.0–1.0) is multiplied on top of the resolved
  ///   colour's alpha. Defaults to fully opaque.
  ///
  /// The actual ARGB is `0` until resolved through a
  /// [CoreColorScheme]; the per-platform `.toValue()` extension
  /// performs that lookup at render time.
  const CoreColor.token(
    CoreColorToken this.token, {
    this.opacity = 1.0,
    this.fallbacks = const <CoreColorToken>[],
  }) : argb = 0;

  /// Tagged colour produced by [CoreColorScheme]: resolved ARGB **and**
  /// the originating token are preserved, so the Web side can still
  /// emit `var(--color-X)` and Flutter can fast-path the cached ARGB.
  ///
  /// Library-internal use; user code creates either raw or `token`
  /// colours.
  @internal
  const CoreColor.tagged(
    this.argb,
    CoreColorToken this.token, {
    this.opacity = 1.0,
    this.fallbacks = const <CoreColorToken>[],
  });

  /// Parse a hex string. Supports `#RGB`, `#RRGGBB`, `#RRGGBBAA`
  /// (and without `#`).
  factory CoreColor.fromHex(String hex) {
    var stripped = hex.replaceAll('#', '');
    if (stripped.length == _kHexShortLength) {
      stripped = stripped.split('').map((ch) => ch + ch).join();
    }
    if (stripped.length == _kHexMediumLength) {
      stripped = 'FF$stripped';
    }
    if (stripped.length != _kHexFullLength) {
      throw FormatException('Invalid hex color format: #$stripped');
    }
    return CoreColor(int.parse(stripped, radix: _kHexRadix));
  }

  /// The [CoreColors.surface] theme color.
  static const surface = CoreColor.token(CoreColors.surface);

  /// The [CoreColors.surfaceDim] theme color.
  static const surfaceDim = CoreColor.token(CoreColors.surfaceDim);

  /// The [CoreColors.surfaceBright] theme color.
  static const surfaceBright = CoreColor.token(CoreColors.surfaceBright);

  /// The [CoreColors.surfaceContainerLowest] theme color.
  static const surfaceContainerLowest = CoreColor.token(
    CoreColors.surfaceContainerLowest,
  );

  /// The [CoreColors.surfaceContainerLow] theme color.
  static const surfaceContainerLow = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// The [CoreColors.surfaceContainer] theme color.
  static const surfaceContainer = CoreColor.token(CoreColors.surfaceContainer);

  /// The [CoreColors.surfaceContainerHigh] theme color.
  static const surfaceContainerHigh = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// The [CoreColors.surfaceContainerHighest] theme color.
  static const surfaceContainerHighest = CoreColor.token(
    CoreColors.surfaceContainerHighest,
  );

  /// The [CoreColors.onSurface] theme color.
  static const onSurface = CoreColor.token(CoreColors.onSurface);

  /// The [CoreColors.onSurfaceVariant] theme color.
  static const onSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);

  /// The [CoreColors.placeholder] theme color.
  static const placeholder = CoreColor.token(CoreColors.placeholder);

  /// The [CoreColors.link] theme color.
  static const link = CoreColor.token(CoreColors.link);

  /// The [CoreColors.onSurfaceSubtle] theme color.
  static const onSurfaceSubtle = CoreColor.token(CoreColors.onSurfaceSubtle);

  /// The [CoreColors.surfaceRaised] theme color.
  static const surfaceRaised = CoreColor.token(CoreColors.surfaceRaised);

  /// The [CoreColors.surfaceTint] theme color.
  static const surfaceTint = CoreColor.token(CoreColors.surfaceTint);

  /// The [CoreColors.primary] theme color.
  static const primary = CoreColor.token(CoreColors.primary);

  /// The [CoreColors.onPrimary] theme color.
  static const onPrimary = CoreColor.token(CoreColors.onPrimary);

  /// The [CoreColors.primaryContainer] theme color.
  static const primaryContainer = CoreColor.token(CoreColors.primaryContainer);

  /// The [CoreColors.onPrimaryContainer] theme color.
  static const onPrimaryContainer = CoreColor.token(
    CoreColors.onPrimaryContainer,
  );

  /// The [CoreColors.primaryFixed] theme color.
  static const primaryFixed = CoreColor.token(CoreColors.primaryFixed);

  /// The [CoreColors.primaryFixedDim] theme color.
  static const primaryFixedDim = CoreColor.token(CoreColors.primaryFixedDim);

  /// The [CoreColors.onPrimaryFixed] theme color.
  static const onPrimaryFixed = CoreColor.token(CoreColors.onPrimaryFixed);

  /// The [CoreColors.onPrimaryFixedVariant] theme color.
  static const onPrimaryFixedVariant = CoreColor.token(
    CoreColors.onPrimaryFixedVariant,
  );

  /// The [CoreColors.primaryText] theme color.
  static const primaryText = CoreColor.token(CoreColors.primaryText);

  /// The [CoreColors.primaryTextLarge] theme color.
  static const primaryTextLarge = CoreColor.token(CoreColors.primaryTextLarge);

  /// The [CoreColors.secondary] theme color.
  static const secondary = CoreColor.token(CoreColors.secondary);

  /// The [CoreColors.onSecondary] theme color.
  static const onSecondary = CoreColor.token(CoreColors.onSecondary);

  /// The [CoreColors.secondaryContainer] theme color.
  static const secondaryContainer = CoreColor.token(
    CoreColors.secondaryContainer,
  );

  /// The [CoreColors.onSecondaryContainer] theme color.
  static const onSecondaryContainer = CoreColor.token(
    CoreColors.onSecondaryContainer,
  );

  /// The [CoreColors.secondaryFixed] theme color.
  static const secondaryFixed = CoreColor.token(CoreColors.secondaryFixed);

  /// The [CoreColors.secondaryFixedDim] theme color.
  static const secondaryFixedDim = CoreColor.token(
    CoreColors.secondaryFixedDim,
  );

  /// The [CoreColors.onSecondaryFixed] theme color.
  static const onSecondaryFixed = CoreColor.token(CoreColors.onSecondaryFixed);

  /// The [CoreColors.onSecondaryFixedVariant] theme color.
  static const onSecondaryFixedVariant = CoreColor.token(
    CoreColors.onSecondaryFixedVariant,
  );

  /// The [CoreColors.tertiary] theme color.
  static const tertiary = CoreColor.token(CoreColors.tertiary);

  /// The [CoreColors.onTertiary] theme color.
  static const onTertiary = CoreColor.token(CoreColors.onTertiary);

  /// The [CoreColors.tertiaryContainer] theme color.
  static const tertiaryContainer = CoreColor.token(
    CoreColors.tertiaryContainer,
  );

  /// The [CoreColors.onTertiaryContainer] theme color.
  static const onTertiaryContainer = CoreColor.token(
    CoreColors.onTertiaryContainer,
  );

  /// The [CoreColors.tertiaryFixed] theme color.
  static const tertiaryFixed = CoreColor.token(CoreColors.tertiaryFixed);

  /// The [CoreColors.tertiaryFixedDim] theme color.
  static const tertiaryFixedDim = CoreColor.token(CoreColors.tertiaryFixedDim);

  /// The [CoreColors.onTertiaryFixed] theme color.
  static const onTertiaryFixed = CoreColor.token(CoreColors.onTertiaryFixed);

  /// The [CoreColors.onTertiaryFixedVariant] theme color.
  static const onTertiaryFixedVariant = CoreColor.token(
    CoreColors.onTertiaryFixedVariant,
  );

  /// The [CoreColors.accent] theme color.
  static const accent = CoreColor.token(CoreColors.accent);

  /// The [CoreColors.onAccent] theme color.
  static const onAccent = CoreColor.token(CoreColors.onAccent);

  /// The [CoreColors.error] theme color.
  static const error = CoreColor.token(CoreColors.error);

  /// The [CoreColors.onError] theme color.
  static const onError = CoreColor.token(CoreColors.onError);

  /// The [CoreColors.errorContainer] theme color.
  static const errorContainer = CoreColor.token(CoreColors.errorContainer);

  /// The [CoreColors.onErrorContainer] theme color.
  static const onErrorContainer = CoreColor.token(CoreColors.onErrorContainer);

  /// The [CoreColors.errorStrong] theme color.
  static const errorStrong = CoreColor.token(CoreColors.errorStrong);

  /// The [CoreColors.focusRing] theme color.
  static const focusRing = CoreColor.token(CoreColors.focusRing);

  /// The [CoreColors.primaryHover] theme color.
  static const primaryHover = CoreColor.token(CoreColors.primaryHover);

  /// The [CoreColors.primaryPressed] theme color.
  static const primaryPressed = CoreColor.token(CoreColors.primaryPressed);

  /// The [CoreColors.secondaryHover] theme color.
  static const secondaryHover = CoreColor.token(CoreColors.secondaryHover);

  /// The [CoreColors.secondaryPressed] theme color.
  static const secondaryPressed = CoreColor.token(CoreColors.secondaryPressed);

  /// The [CoreColors.errorPressed] theme color.
  static const errorPressed = CoreColor.token(CoreColors.errorPressed);

  /// The [CoreColors.success] theme color.
  static const success = CoreColor.token(CoreColors.success);

  /// The [CoreColors.onSuccess] theme color.
  static const onSuccess = CoreColor.token(CoreColors.onSuccess);

  /// The [CoreColors.successContainer] theme color.
  static const successContainer = CoreColor.token(CoreColors.successContainer);

  /// The [CoreColors.onSuccessContainer] theme color.
  static const onSuccessContainer = CoreColor.token(
    CoreColors.onSuccessContainer,
  );

  /// The [CoreColors.warning] theme color.
  static const warning = CoreColor.token(CoreColors.warning);

  /// The [CoreColors.onWarning] theme color.
  static const onWarning = CoreColor.token(CoreColors.onWarning);

  /// The [CoreColors.warningContainer] theme color.
  static const warningContainer = CoreColor.token(CoreColors.warningContainer);

  /// The [CoreColors.onWarningContainer] theme color.
  static const onWarningContainer = CoreColor.token(
    CoreColors.onWarningContainer,
  );

  /// The [CoreColors.info] theme color.
  static const info = CoreColor.token(CoreColors.info);

  /// The [CoreColors.onInfo] theme color.
  static const onInfo = CoreColor.token(CoreColors.onInfo);

  /// The [CoreColors.infoContainer] theme color.
  static const infoContainer = CoreColor.token(CoreColors.infoContainer);

  /// The [CoreColors.onInfoContainer] theme color.
  static const onInfoContainer = CoreColor.token(CoreColors.onInfoContainer);

  /// The [CoreColors.errorIcon] theme color.
  static const errorIcon = CoreColor.token(CoreColors.errorIcon);

  /// The [CoreColors.successIcon] theme color.
  static const successIcon = CoreColor.token(CoreColors.successIcon);

  /// The [CoreColors.warningIcon] theme color.
  static const warningIcon = CoreColor.token(CoreColors.warningIcon);

  /// The [CoreColors.infoIcon] theme color.
  static const infoIcon = CoreColor.token(CoreColors.infoIcon);

  /// The [CoreColors.outline] theme color.
  static const outline = CoreColor.token(CoreColors.outline);

  /// The [CoreColors.outlineVariant] theme color.
  static const outlineVariant = CoreColor.token(CoreColors.outlineVariant);

  /// The [CoreColors.outlineSubtle] theme color.
  static const outlineSubtle = CoreColor.token(CoreColors.outlineSubtle);

  /// The [CoreColors.inverseSurface] theme color.
  static const inverseSurface = CoreColor.token(CoreColors.inverseSurface);

  /// The [CoreColors.inverseOnSurface] theme color.
  static const inverseOnSurface = CoreColor.token(CoreColors.inverseOnSurface);

  /// The [CoreColors.inversePrimary] theme color.
  static const inversePrimary = CoreColor.token(CoreColors.inversePrimary);

  /// The [CoreColors.shadow] theme color.
  static const shadow = CoreColor.token(CoreColors.shadow);

  /// The [CoreColors.surfaceHighlight] theme color.
  static const surfaceHighlight = CoreColor.token(CoreColors.surfaceHighlight);

  /// The [CoreColors.scrim] theme color.
  static const scrim = CoreColor.token(CoreColors.scrim);

  /// The [CoreColors.disabledContent] theme color.
  static const disabledContent = CoreColor.token(CoreColors.disabledContent);

  /// The [CoreColors.disabledContainer] theme color.
  static const disabledContainer = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// The [CoreColors.disabledOutline] theme color.
  static const disabledOutline = CoreColor.token(CoreColors.disabledOutline);

  /// The [CoreColors.syntaxKeyword] theme color.
  static const syntaxKeyword = CoreColor.token(CoreColors.syntaxKeyword);

  /// The [CoreColors.syntaxType] theme color.
  static const syntaxType = CoreColor.token(CoreColors.syntaxType);

  /// The [CoreColors.syntaxFunction] theme color.
  static const syntaxFunction = CoreColor.token(CoreColors.syntaxFunction);

  /// The [CoreColors.syntaxString] theme color.
  static const syntaxString = CoreColor.token(CoreColors.syntaxString);

  /// The [CoreColors.categoryRed] theme color.
  static const categoryRed = CoreColor.token(CoreColors.categoryRed);

  /// The [CoreColors.onCategoryRed] theme color.
  static const onCategoryRed = CoreColor.token(CoreColors.onCategoryRed);

  /// The [CoreColors.categoryRedContainer] theme color.
  static const categoryRedContainer = CoreColor.token(
    CoreColors.categoryRedContainer,
  );

  /// The [CoreColors.onCategoryRedContainer] theme color.
  static const onCategoryRedContainer = CoreColor.token(
    CoreColors.onCategoryRedContainer,
  );

  /// The [CoreColors.categoryRedOutline] theme color.
  static const categoryRedOutline = CoreColor.token(
    CoreColors.categoryRedOutline,
  );

  /// The [CoreColors.categoryOrange] theme color.
  static const categoryOrange = CoreColor.token(CoreColors.categoryOrange);

  /// The [CoreColors.onCategoryOrange] theme color.
  static const onCategoryOrange = CoreColor.token(CoreColors.onCategoryOrange);

  /// The [CoreColors.categoryOrangeContainer] theme color.
  static const categoryOrangeContainer = CoreColor.token(
    CoreColors.categoryOrangeContainer,
  );

  /// The [CoreColors.onCategoryOrangeContainer] theme color.
  static const onCategoryOrangeContainer = CoreColor.token(
    CoreColors.onCategoryOrangeContainer,
  );

  /// The [CoreColors.categoryOrangeOutline] theme color.
  static const categoryOrangeOutline = CoreColor.token(
    CoreColors.categoryOrangeOutline,
  );

  /// The [CoreColors.categoryYellow] theme color.
  static const categoryYellow = CoreColor.token(CoreColors.categoryYellow);

  /// The [CoreColors.onCategoryYellow] theme color.
  static const onCategoryYellow = CoreColor.token(CoreColors.onCategoryYellow);

  /// The [CoreColors.categoryYellowContainer] theme color.
  static const categoryYellowContainer = CoreColor.token(
    CoreColors.categoryYellowContainer,
  );

  /// The [CoreColors.onCategoryYellowContainer] theme color.
  static const onCategoryYellowContainer = CoreColor.token(
    CoreColors.onCategoryYellowContainer,
  );

  /// The [CoreColors.categoryYellowOutline] theme color.
  static const categoryYellowOutline = CoreColor.token(
    CoreColors.categoryYellowOutline,
  );

  /// The [CoreColors.categoryGreen] theme color.
  static const categoryGreen = CoreColor.token(CoreColors.categoryGreen);

  /// The [CoreColors.onCategoryGreen] theme color.
  static const onCategoryGreen = CoreColor.token(CoreColors.onCategoryGreen);

  /// The [CoreColors.categoryGreenContainer] theme color.
  static const categoryGreenContainer = CoreColor.token(
    CoreColors.categoryGreenContainer,
  );

  /// The [CoreColors.onCategoryGreenContainer] theme color.
  static const onCategoryGreenContainer = CoreColor.token(
    CoreColors.onCategoryGreenContainer,
  );

  /// The [CoreColors.categoryGreenOutline] theme color.
  static const categoryGreenOutline = CoreColor.token(
    CoreColors.categoryGreenOutline,
  );

  /// The [CoreColors.categoryBlue] theme color.
  static const categoryBlue = CoreColor.token(CoreColors.categoryBlue);

  /// The [CoreColors.onCategoryBlue] theme color.
  static const onCategoryBlue = CoreColor.token(CoreColors.onCategoryBlue);

  /// The [CoreColors.categoryBlueContainer] theme color.
  static const categoryBlueContainer = CoreColor.token(
    CoreColors.categoryBlueContainer,
  );

  /// The [CoreColors.onCategoryBlueContainer] theme color.
  static const onCategoryBlueContainer = CoreColor.token(
    CoreColors.onCategoryBlueContainer,
  );

  /// The [CoreColors.categoryBlueOutline] theme color.
  static const categoryBlueOutline = CoreColor.token(
    CoreColors.categoryBlueOutline,
  );

  /// The [CoreColors.categoryPurple] theme color.
  static const categoryPurple = CoreColor.token(CoreColors.categoryPurple);

  /// The [CoreColors.onCategoryPurple] theme color.
  static const onCategoryPurple = CoreColor.token(CoreColors.onCategoryPurple);

  /// The [CoreColors.categoryPurpleContainer] theme color.
  static const categoryPurpleContainer = CoreColor.token(
    CoreColors.categoryPurpleContainer,
  );

  /// The [CoreColors.onCategoryPurpleContainer] theme color.
  static const onCategoryPurpleContainer = CoreColor.token(
    CoreColors.onCategoryPurpleContainer,
  );

  /// The [CoreColors.categoryPurpleOutline] theme color.
  static const categoryPurpleOutline = CoreColor.token(
    CoreColors.categoryPurpleOutline,
  );

  /// The [CoreColors.categoryPink] theme color.
  static const categoryPink = CoreColor.token(CoreColors.categoryPink);

  /// The [CoreColors.onCategoryPink] theme color.
  static const onCategoryPink = CoreColor.token(CoreColors.onCategoryPink);

  /// The [CoreColors.categoryPinkContainer] theme color.
  static const categoryPinkContainer = CoreColor.token(
    CoreColors.categoryPinkContainer,
  );

  /// The [CoreColors.onCategoryPinkContainer] theme color.
  static const onCategoryPinkContainer = CoreColor.token(
    CoreColors.onCategoryPinkContainer,
  );

  /// The [CoreColors.categoryPinkOutline] theme color.
  static const categoryPinkOutline = CoreColor.token(
    CoreColors.categoryPinkOutline,
  );

  /// The [CoreColors.categoryBrown] theme color.
  static const categoryBrown = CoreColor.token(CoreColors.categoryBrown);

  /// The [CoreColors.onCategoryBrown] theme color.
  static const onCategoryBrown = CoreColor.token(CoreColors.onCategoryBrown);

  /// The [CoreColors.categoryBrownContainer] theme color.
  static const categoryBrownContainer = CoreColor.token(
    CoreColors.categoryBrownContainer,
  );

  /// The [CoreColors.onCategoryBrownContainer] theme color.
  static const onCategoryBrownContainer = CoreColor.token(
    CoreColors.onCategoryBrownContainer,
  );

  /// The [CoreColors.categoryBrownOutline] theme color.
  static const categoryBrownOutline = CoreColor.token(
    CoreColors.categoryBrownOutline,
  );

  /// The [CoreColors.categoryGray] theme color.
  static const categoryGray = CoreColor.token(CoreColors.categoryGray);

  /// The [CoreColors.onCategoryGray] theme color.
  static const onCategoryGray = CoreColor.token(CoreColors.onCategoryGray);

  /// The [CoreColors.categoryGrayContainer] theme color.
  static const categoryGrayContainer = CoreColor.token(
    CoreColors.categoryGrayContainer,
  );

  /// The [CoreColors.onCategoryGrayContainer] theme color.
  static const onCategoryGrayContainer = CoreColor.token(
    CoreColors.onCategoryGrayContainer,
  );

  /// The [CoreColors.categoryGrayOutline] theme color.
  static const categoryGrayOutline = CoreColor.token(
    CoreColors.categoryGrayOutline,
  );

  /// Fully transparent sentinel (raw ARGB `0x00000000`, no token).
  /// Component styles use this to express "no fill" instead of
  /// reaching for a token whose resolved colour might be opaque.
  /// Web sees `token == null` and omits the Tailwind class; Flutter
  /// renders it as `Color(0x00000000)` (zero alpha).
  static const CoreColor transparent = CoreColor(0x00000000);

  /// The 32-bit ARGB integer. `0` on an unresolved token reference.
  final int argb;

  /// Semantic token reference, or `null` for raw ARGB colours.
  final CoreColorToken? token;

  /// Opacity multiplier (0.0–1.0). Defaults to 1.0 (no scaling).
  ///
  /// Composed with the stored alpha byte at render time (Flutter
  /// `.toValue()`) or expressed via `color-mix(...)` on the Web. Set
  /// via [CoreColor.token]'s named arg or [withOpacity] / [scaleAlpha].
  final double opacity;

  /// Fallback token slots tried in order when [token] is `null` in
  /// the active [CoreColorScheme]. Empty for raw colours and for
  /// tokens that don't need a fallback chain.
  ///
  /// Used to express patterns like `outline ?? onSurface` without
  /// resorting to a `ColorResolver` function.
  final List<CoreColorToken> fallbacks;

  /// Whether this colour has a resolved ARGB value (raw colour or
  /// tagged token). `false` for unresolved [CoreColor.token]
  /// references.
  bool get isResolved => token == null || argb != 0;

  // ─── ARGB channel accessors — throw on unresolved token ───────────

  /// Alpha channel as a 0-255 byte. Throws on unresolved token.
  ///
  /// Does **not** include the [opacity] multiplier — pure ARGB channel.
  int get alpha {
    _requireResolved('alpha');
    return (argb >> 24) & 0xFF;
  }

  /// Red channel (0-255). Throws on unresolved token.
  int get red {
    _requireResolved('red');
    return (argb >> 16) & 0xFF;
  }

  /// Green channel (0-255). Throws on unresolved token.
  int get green {
    _requireResolved('green');
    return (argb >> 8) & 0xFF;
  }

  /// Blue channel (0-255). Throws on unresolved token.
  int get blue {
    _requireResolved('blue');
    return argb & 0xFF;
  }

  /// Backwards-compatible alias for [argb].
  int get value => argb;

  /// Effective opacity = stored alpha byte / 255 × [opacity] modifier
  /// (0.0-1.0). Throws on unresolved token (the alpha byte is unknown
  /// without resolution).
  double get effectiveOpacity {
    _requireResolved('effectiveOpacity');
    return ((alpha / _kChannelMax) * opacity).clamp(0.0, 1.0);
  }

  // ─── Mutation — works on both modes ───────────────────────────────

  /// Returns a copy with the given opacity (0.0–1.0). For tokens the
  /// reference is preserved with the new opacity modifier; for raw
  /// colours a new ARGB is produced.
  CoreColor withOpacity(double newOpacity) {
    final clamped = newOpacity.clamp(0.0, 1.0);
    if (token != null) {
      return CoreColor.token(token!, opacity: clamped, fallbacks: fallbacks);
    }
    return CoreColor.fromARGB(
      (clamped * _kChannelMax).round(),
      red,
      green,
      blue,
    );
  }

  /// Returns a copy with the existing opacity multiplied by [factor].
  /// Differs from [withOpacity], which replaces opacity outright.
  CoreColor scaleAlpha(double factor) {
    if (token != null) {
      return CoreColor.token(
        token!,
        opacity: (opacity * factor).clamp(0.0, 1.0),
        fallbacks: fallbacks,
      );
    }
    return CoreColor.fromARGB(
      (alpha * factor).round().clamp(0, _kAlphaOpaque),
      red,
      green,
      blue,
    );
  }

  /// Returns a copy with alpha set to [a] (0-255). Raw colours only —
  /// throws on unresolved token.
  CoreColor withAlpha(int a) {
    _requireResolved('withAlpha');
    return CoreColor.fromARGB(a, red, green, blue);
  }

  // ─── Formatting — raw only ────────────────────────────────────────

  /// Hex string: `#RRGGBB`, or `#RRGGBBAA` when alpha < 255. Throws on
  /// unresolved token.
  String toHex() {
    _requireResolved('toHex');
    if (alpha == _kAlphaOpaque) {
      final rgb = argb & 0xFFFFFF;
      final hex = rgb
          .toRadixString(_kHexRadix)
          .padLeft(_kHexMediumLength, '0')
          .toUpperCase();
      return '#$hex';
    }
    final hex = argb
        .toRadixString(_kHexRadix)
        .padLeft(_kHexFullLength, '0')
        .toUpperCase();
    return '#$hex';
  }

  /// CSS `rgb()` / `rgba()` string. Throws on unresolved token.
  String toRgba() {
    _requireResolved('toRgba');
    if (alpha == _kAlphaOpaque && opacity >= 1.0) {
      return 'rgb($red, $green, $blue)';
    }
    final alphaStr = effectiveOpacity.toStringAsFixed(_kDecimalPrecision);
    return 'rgba($red, $green, $blue, $alphaStr)';
  }

  // ─── Lerp ─────────────────────────────────────────────────────────

  /// Linearly interpolates between two raw ARGB colours. Throws if
  /// either side is an unresolved token reference.
  ///
  /// [t] is not clamped — each channel is. An overshooting curve
  /// (`elasticOut`, `bounceIn` …) hands in `t` outside 0–1, and the
  /// colour carries that overshoot until a channel hits the edge of its
  /// range, where it saturates. That is what `dart:ui`'s `Color.lerp`
  /// does, and it keeps a motion token meaning the same thing for a
  /// colour as for a length: clamping `t` instead would stop the colour
  /// dead while the geometry driven by the same curve kept swinging.
  ///
  /// The clamp has to be here, not left to [CoreColor.fromARGB]: that
  /// constructor masks each channel to its low byte, so an unclamped
  /// 260 would come out as 4 and a near-white would flash near-black
  /// mid-animation.
  // Static to mirror Flutter's `Color.lerp`, so call sites read the same.
  // ignore: prefer_constructors_over_static_methods
  static CoreColor lerp(CoreColor a, CoreColor b, double t) {
    a._requireResolved('lerp.a');
    b._requireResolved('lerp.b');
    return CoreColor.fromARGB(
      _lerpChannel(a.alpha, b.alpha, t),
      _lerpChannel(a.red, b.red, t),
      _lerpChannel(a.green, b.green, t),
      _lerpChannel(a.blue, b.blue, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreColor &&
          argb == other.argb &&
          token == other.token &&
          opacity == other.opacity;

  /// Renders the colour as a Tailwind-friendly string for class
  /// composition (`bg-${cs.surface}` → `bg-surface`, `bg-on-surface/60`).
  ///
  /// - Token: returns the token name (`'primary'`, `'on-surface'`),
  ///   appending `/NN` (1-100) when [opacity] < 1.0 to match Tailwind's
  ///   opacity modifier syntax.
  /// - Raw ARGB: returns the hex string (`'#FF0000'`). Tailwind cannot
  ///   use this directly — for raw colours, pass through `.toValue()`
  ///   and inject as inline CSS instead.
  @override
  String toString() {
    if (token != null) {
      if (opacity < 1.0) {
        final pct = (opacity * _kPercent).round().clamp(0, _kPercent);
        return '${token!.name}/$pct';
      }
      return token!.name;
    }
    return toHex();
  }

  /// One channel of [lerp].
  ///
  /// `lerp(a, b, t)` and `lerp(b, a, 1 - t)` must give the same byte — a
  /// theme crossfade must not depend on which end it started from — and
  /// each must round the way the exact value rounds. The plain
  /// `a + (b - a) * t` fails both only at a `.5` tie: the caller's `t` and
  /// `1 - t` are themselves rounded, so a value that is exactly `x.5` lands
  /// a few ulps to one side or the other and `round` picks a neighbouring
  /// byte by accident. Away from a tie those ulps cannot move the byte. So
  /// a value within [_kLerpTieTolerance] of `.5` is read as the tie it is
  /// and rounded up, as `round` rounds an exact one; everything else
  /// rounds as computed. Re-deriving `t` from the other end instead would
  /// make the two orders agree by moving both off the exact rounding.
  static int _lerpChannel(int a, int b, double t) {
    final value = a + (b - a) * t;
    final whole = value.floorToDouble();
    final isTie = (value - whole - _kLerpHalf).abs() <= _kLerpTieTolerance;

    return (isTie ? whole.toInt() + 1 : value.round()).clamp(
      0,
      _kChannelMaxByte,
    );
  }

  void _requireResolved(String op) {
    if (!isResolved) {
      throw StateError(
        'CoreColor.$op called on unresolved token "${token!.name}". '
        'Resolve the token through CoreColorScheme.resolve(color) or '
        'pass the colour through a * component before reading ARGB.',
      );
    }
  }

  @override
  int get hashCode => Object.hash(argb, token, opacity);
}

const _kHexRadix = 16;
const _kHexShortLength = 3;
const _kHexMediumLength = 6;
const _kHexFullLength = 8;
const _kChannelMax = 255.0;
const _kChannelMaxByte = 255;
const _kAlphaOpaque = 255;
const _kDecimalPrecision = 2;
const _kPercent = 100;

/// The fraction [CoreColor._lerpChannel] treats as a rounding tie.
const _kLerpHalf = 0.5;

/// How close to [_kLerpHalf] a channel value has to land to count as that
/// tie. The two argument orders of a lerp miss an exact tie by a few ulps
/// (~1e-13 at channel scale); this is far wider than that and far narrower
/// than anything a curve's `t` lands on by chance.
const _kLerpTieTolerance = 1e-9;
