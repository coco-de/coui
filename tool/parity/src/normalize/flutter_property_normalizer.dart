// #3606 — Normalizer, Flutter half.
//
// These take **primitives** (`int`/`double`), not `dart:ui`/`package:flutter`
// types (`Color`, `FontWeight`, `TextStyle`) — this file has to stay
// importable from a pure-Dart context (`tool/parity` runs under plain
// `dart run`, no Flutter engine). The actual widget-tree extraction that
// produces those primitives runs inside `flutter test`
// (`packages/coui_flutter/test/src/parity_probe/` today, growing into
// Component ②/FlutterCaptureBackend under #3376) and calls these functions
// when its input really is an ARGB integer, a font-weight value or a
// line-height multiplier. The typed Flutter capture helper separately
// retains `Color.a` directly; converting it to ARGB first would discard
// observable alpha precision. The formulas below are Component ④'s
// "역방향 적용" of the
// exact asymmetries `cross-platform/api.md` and `core/design-tokens.md`
// document for these fields — each doc comment names which one.
import '../model/property_snapshot.dart';

/// Bit positions `dart:ui.Color.toARGB32()` packs each channel into —
/// alpha in bits 24-31, red 16-23, green 8-15, blue 0-7 (unshifted).
const int _kAlphaShift = 24;
const int _kRedShift = 16;
const int _kGreenShift = 8;

/// Masks one byte (0-255) out of a shifted channel.
const int _kByteMask = 0xFF;

/// Splits a Flutter 32-bit ARGB `int` (`Color.toARGB32()`) into a
/// [NormalizedColor].
///
/// This is a bit-shift decode, not a color-space conversion, so there's no
/// rounding-error concern the way there is for the alpha `double` (still
/// passed through [NormalizedColor]'s own `roundAlpha`).
NormalizedColor normalizeFlutterArgbColor(int argb) => .new(
  r: (argb >> _kRedShift) & _kByteMask,
  g: (argb >> _kGreenShift) & _kByteMask,
  b: argb & _kByteMask,
  a: ((argb >> _kAlphaShift) & _kByteMask) / _kByteMask,
);

/// `FontWeight.value` is already the CSS-style `100..900` int — identity,
/// not arithmetic.
///
/// A named pass-through function (not just `style.fontWeight?.value`
/// inlined at every call site) because `core/design-tokens.md` explicitly
/// warns this field is exactly the kind of "same physical quantity,
/// different unit" trap Component ④ exists to catch — recording "verified:
/// no conversion needed here" is itself the guard against a future reader
/// assuming there must be one and inventing a wrong scaling factor.
int normalizeFlutterFontWeight(int fontWeightValue) => fontWeightValue;

/// `TextStyle.letterSpacing` is already an absolute px value in Flutter —
/// identity, not arithmetic.
///
/// This is the *opposite* asymmetry from `CoreTextStyle.letterSpacing`
/// (documented in `core/design-tokens.md` as an **em ratio** requiring
/// `em × effectiveFontSize` to reach Flutter's `TextStyle.letterSpacing`).
/// This function's input is already past that conversion — it's reading
/// the *resolved* `TextStyle` off the widget tree
/// (`probeEffectiveTextStyle`, Epic A), not the `CoreTextStyle` token — so
/// by the time it reaches here, no further math applies. `null` means the
/// widget declared no letter-spacing override, matching how the Web side's
/// `letterSpacing: normal` also normalizes to `null`
/// (`css_value_parsers.dart`'s `parseCssPxOrNormal`).
double? normalizeFlutterLetterSpacingPx(double? letterSpacingPx) =>
    letterSpacingPx == null ? null : roundPx(letterSpacingPx);

/// Converts Flutter's unitless `TextStyle.height` line-height multiplier to
/// an absolute px value: `height × fontSizePx`.
///
/// This is the actual unit conversion `core/design-tokens.md` calls out —
/// `TextStyle.height` is a **multiplier of the font size**, not a length,
/// so `PropertySnapshot.lineHeightPx` (an absolute px, matching what the
/// Web side's `getComputedStyle().lineHeight` already resolves to) needs
/// this multiplication. `null` (an unset `TextStyle.height`) means "the
/// font's own default line height" the same way `normal` does on the Web
/// side — no multiplier to apply, so the result is `null` too rather than
/// guessing a value.
double? normalizeFlutterLineHeightPx(
  double? heightMultiplier,
  double fontSizePx,
) => heightMultiplier == null ? null : roundPx(heightMultiplier * fontSizePx);

/// Flutter's opacity values (e.g. `Opacity.opacity`) are already a plain
/// `0.0..1.0` double — no unit asymmetry the way font-related fields have,
/// but still routed through [roundAlpha] so this shares the exact rounding
/// policy `PropertySnapshot.opacity`'s Web counterpart
/// (`web_property_normalizer.dart`) uses, rather than each side picking its
/// own precision for the same 0.0..1.0 domain.
double normalizeFlutterOpacity(double opacity) => roundAlpha(opacity);
