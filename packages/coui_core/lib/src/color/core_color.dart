/// Platform-independent colour descriptor.
///
/// Single class with two modes (Epic #1415):
///
/// - **Raw ARGB** — `CoreColor(0xFFRRGGBB)`, `CoreColor.fromARGB(...)`,
///   `CoreColor.fromHex(...)`. Carries an actual 32-bit colour value;
///   ARGB channel helpers (`red`, `green`, `toHex`, …) operate on it.
///
/// - **Semantic token** — `CoreColor.token(CoreColors.primary)`. Carries
///   only a reference to a slot in [CoreColorScheme]; the actual ARGB
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
