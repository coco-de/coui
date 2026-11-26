/// Platform-independent text style.
///
/// `CoreTextStyle` mirrors Flutter's `TextStyle` design — a single
/// class that doubles as both a typography token (all fields populated
/// in `CoreTypography` definitions) and a Layer-2 override style
/// (any subset of fields, used in nested style slots like
/// `CoreButtonStyle.labelStyle`).
///
/// ### Two-layer policy (Epic #1302)
///
/// - **Layer 1 — End-user code**: chain API
///   (`Text('...').bodyMedium.semibold.onSurface`). Uses tokens + tone
///   only. Lints/docs enforce this.
/// - **Layer 2 — Component internals + slot overrides**: raw
///   `CoreTextStyle` fields (`fontSize`, `fontWeight`, `color`,
///   `lineHeight`, …). Required for state-driven micro-tweaks that a
///   token alone cannot express (selected vs default cell, hover vs
///   active label, etc.).
///
/// Composes through `merge` just like Flutter's `TextStyle.merge` —
/// non-null fields in `other` win, null fields inherit.
///
/// ### Colour type (Epic #1415)
///
/// `color` is a [CoreColor] — a platform-neutral descriptor that can
/// carry an ARGB value or a semantic token reference. Resolution to
/// Flutter `Color` / CSS string happens through the per-platform
/// `.toValue()` extension at render time.
library;

import 'package:coui_core/coui_core.dart' show CoreFontWeight;
import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart' show CoreFontWeight;
import 'package:meta/meta.dart';

/// Platform-neutral text style descriptor.
@immutable
class CoreTextStyle {
  /// Creates a [CoreTextStyle].
  const CoreTextStyle({
    this.fontSize,
    this.lineHeight,
    this.lineHeightPx,
    this.fontWeight,
    this.letterSpacing,
    this.fontFamily,
    this.color,
  }) : token = null;

  /// Semantic typography token reference (Epic #1601 PoC).
  ///
  /// Mirrors [CoreColor.token]: carries only the slot identifier; the
  /// actual `CoreTextStyle` fields are materialised at render time by
  /// `token.read(typography)`. Optional [color] overrides the resolved
  /// slot's `color`.
  ///
  /// ```dart
  /// const filled = CoreButtonStyle(
  ///   labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
  /// );
  /// ```
  const CoreTextStyle.token(CoreTextStyleToken this.token, {this.color})
    : fontSize = null,
      lineHeight = null,
      lineHeightPx = null,
      fontWeight = null,
      letterSpacing = null,
      fontFamily = null;

  /// Library-internal: combined raw fields + token. Used by `merge` /
  /// `copyWith` to carry a token through field overlays without losing
  /// the token reference.
  const CoreTextStyle._({
    this.fontSize,
    this.lineHeight,
    this.lineHeightPx,
    this.fontWeight,
    this.letterSpacing,
    this.fontFamily,
    this.color,
    this.token,
  });

  /// Font size in logical pixels. `null` → inherit.
  final double? fontSize;

  /// Line height multiplier (e.g. `1.5` = 150%). `null` → inherit.
  ///
  /// [lineHeightPx] wins over it when both are set.
  final double? lineHeight;

  /// Fixed line box in logical pixels (e.g. `21`). `null` → [lineHeight].
  ///
  /// For roles that must share one line grid across sizes — the code roles
  /// sit 11 · 12 · 13px glyphs on the same 21px line, which no single
  /// multiplier can give. When set it wins over [lineHeight]; a later
  /// statement of [lineHeight] alone (an overlay through [merge] or
  /// [copyWith]) drops it, so the newer statement is the one drawn.
  ///
  /// Unlike [lineHeight], this is an absolute length: [scale] multiplies it.
  /// Flutter draws it as `height = lineHeightPx / fontSize` against the
  /// final font size; Web emits it as a length.
  final double? lineHeightPx;

  /// Font weight (CSS 100–900). `null` → inherit. Use
  /// [CoreFontWeight.medium] / `.semiBold` / `.bold` etc.
  final int? fontWeight;

  /// Letter spacing in logical pixels. `null` → inherit.
  final double? letterSpacing;

  /// Optional font family name. `null` → inherit.
  final String? fontFamily;

  /// Text colour. `null` → inherit.
  final CoreColor? color;

  /// Semantic typography token reference. Set when constructed via
  /// [CoreTextStyle.token]; the per-platform `.toValue()` extension
  /// performs the `token.read(typography)` lookup at render time.
  /// Mirrors [CoreColor.token].
  final CoreTextStyleToken? token;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Mirrors
  /// `flutter:TextStyle.merge`.
  ///
  /// A role fixes how large its text is and how tall its line is, so when
  /// both sides state a role and the roles differ, [other]'s role replaces
  /// this one's size and line box: the [fontSize], [lineHeight] and
  /// [lineHeightPx] overlays that sat on this role do not follow it. The
  /// newer statement is the one drawn — the same order [lineHeight] and
  /// [lineHeightPx] keep between themselves.
  ///
  /// Weight, family, tracking and colour are laid over whichever role is
  /// drawn (a selected label's emphasis, a code face), so they carry over.
  /// Anything else composes field by field too: the same role stated again,
  /// a role stated over a style with no role, and an [other] with no role
  /// all keep this style's overlays.
  CoreTextStyle merge(CoreTextStyle? other) {
    if (other == null) return this;
    // Token merge — when both sides have a token, `other` wins (override
    // semantics); when only one side has a token, that token survives.
    // Token reference + raw field overlay coexist: the resolver applies
    // the token first (materialising the slot), then overlays remaining
    // non-null fields.
    final mergedToken = other.token ?? token;
    // The size and line box below were laid over the replaced role; applied
    // to the new one at render time they would override what it states (a
    // fixed `codeMd` line box lost to a 140% multiplier left by the earlier
    // role).
    final earlier = _replacesRole(other) ? _withoutRoleMeasure() : this;
    return CoreTextStyle._(
      fontSize: other.fontSize ?? earlier.fontSize,
      lineHeight: other.lineHeight ?? earlier.lineHeight,
      lineHeightPx: _lineBoxAfter(
        lineHeight: other.lineHeight,
        lineHeightPx: other.lineHeightPx,
        previous: earlier.lineHeightPx,
      ),
      fontWeight: other.fontWeight ?? earlier.fontWeight,
      letterSpacing: other.letterSpacing ?? earlier.letterSpacing,
      fontFamily: other.fontFamily ?? earlier.fontFamily,
      color: other.color ?? earlier.color,
      token: mergedToken,
    );
  }

  /// Whether merging [other] over this style swaps one role for another.
  bool _replacesRole(CoreTextStyle other) =>
      token != null && other.token != null && token != other.token;

  /// This style without the size and line box its role fixed. Weight,
  /// family, tracking and colour stay.
  CoreTextStyle _withoutRoleMeasure() => CoreTextStyle._(
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    fontFamily: fontFamily,
    color: color,
    token: token,
  );

  /// Returns a copy with the supplied non-null fields overridden.
  CoreTextStyle copyWith({
    double? fontSize,
    double? lineHeight,
    double? lineHeightPx,
    int? fontWeight,
    double? letterSpacing,
    String? fontFamily,
    CoreColor? color,
    CoreTextStyleToken? token,
  }) {
    return CoreTextStyle._(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      lineHeightPx: _lineBoxAfter(
        lineHeight: lineHeight,
        lineHeightPx: lineHeightPx,
        previous: this.lineHeightPx,
      ),
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      token: token ?? this.token,
    );
  }

  /// Returns a copy of this style with [fontSize] and [lineHeightPx] scaled
  /// by [factor]. Helper for typography scale variants
  /// (`CoreTypography.scale`).
  ///
  /// [lineHeight] (unitless multiplier) and [letterSpacing] (em ratio) are
  /// scale-INVARIANT: both are ratios relative to the font size, so they
  /// track the scaled [fontSize] automatically at conversion time
  /// (letterSpacing px = em × scaled fontSize). Multiplying them here would
  /// double-apply [factor]. Mirrors Web `Typography.scale`, which likewise
  /// scales only `fontSize`. [lineHeightPx] is a length, not a ratio, so it
  /// scales with the glyphs it boxes.
  CoreTextStyle scale(double factor) {
    return CoreTextStyle._(
      fontSize: fontSize == null ? null : fontSize! * factor,
      lineHeight: lineHeight,
      lineHeightPx: lineHeightPx == null ? null : lineHeightPx! * factor,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
      color: color,
      token: token,
    );
  }

  /// Converts the *populated* subset of this style to a CSS
  /// font-shorthand-compatible string. Fields left as `null` are
  /// omitted.
  String toCss() {
    final buffer = StringBuffer();
    if (fontWeight != null) buffer.write('font-weight: $fontWeight; ');
    if (fontSize != null) buffer.write('font-size: ${fontSize}px; ');
    if (lineHeightPx != null) {
      buffer.write('line-height: ${lineHeightPx}px; ');
    } else if (lineHeight != null) {
      buffer.write('line-height: $lineHeight; ');
    }
    if (letterSpacing != null && letterSpacing != 0) {
      buffer.write('letter-spacing: ${letterSpacing}em; ');
    }
    if (fontFamily != null) buffer.write("font-family: '$fontFamily'; ");
    return buffer.toString().trimRight();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextStyle &&
          fontSize == other.fontSize &&
          lineHeight == other.lineHeight &&
          lineHeightPx == other.lineHeightPx &&
          fontWeight == other.fontWeight &&
          letterSpacing == other.letterSpacing &&
          fontFamily == other.fontFamily &&
          color == other.color &&
          token == other.token;

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineHeight,
    lineHeightPx,
    fontWeight,
    letterSpacing,
    fontFamily,
    color,
    token,
  );

  @override
  String toString() =>
      'CoreTextStyle(fontSize: $fontSize, '
      'fontWeight: $fontWeight, lineHeight: $lineHeight, '
      'lineHeightPx: $lineHeightPx, color: $color)';

  /// The line box after an overlay: a stated [lineHeightPx] wins; a stated
  /// multiplier alone replaces the [previous] box (the newer statement is
  /// the one drawn); stating neither keeps [previous].
  static double? _lineBoxAfter({
    required double? lineHeight,
    required double? lineHeightPx,
    required double? previous,
  }) {
    if (lineHeightPx != null) return lineHeightPx;
    if (lineHeight != null) return null;
    return previous;
  }
}
