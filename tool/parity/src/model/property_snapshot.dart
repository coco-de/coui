import 'package:meta/meta.dart';

/// A normalized RGBA color — the common target of typed Flutter colours,
/// explicit ARGB integer inputs and Web computed-style colour strings.
///
/// `r`/`g`/`b` are `0..255` integers (both platforms' native channel
/// range — no conversion needed once each is parsed out of its source
/// format). `a` is a `0.0..1.0` alpha, rounded to 3 decimal places
/// (`.bmad/architecture-*.md` Component ④'s own rounding policy — floating
/// point alpha arithmetic on both sides otherwise produces cosmetic diffs
/// like `0.5` vs `0.4999999999999998`).
@immutable
class NormalizedColor {
  factory NormalizedColor({
    required int r,
    required int g,
    required int b,
    required double a,
  }) => NormalizedColor._(r: r, g: g, b: b, a: roundAlpha(a));

  const NormalizedColor._({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  /// Reconstructs a [NormalizedColor] from [toJson]'s output.
  factory NormalizedColor.fromJson(Map<String, Object?> json) =>
      NormalizedColor._(
        r: json['r']! as int,
        g: json['g']! as int,
        b: json['b']! as int,
        a: (json['a']! as num).toDouble(),
      );

  final int r;
  final int g;
  final int b;
  final double a;

  Map<String, Object?> toJson() => {'r': r, 'g': g, 'b': b, 'a': a};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizedColor &&
          r == other.r &&
          g == other.g &&
          b == other.b &&
          a == other.a;

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'NormalizedColor(r:$r, g:$g, b:$b, a:$a)';
}

/// One observed layer of a (possibly multi-layer) box shadow, in logical px.
/// Fresh captures express blur as the CSS radius (twice Gaussian sigma),
/// rather than the SDK's differently defined `BoxShadow.blurRadius`.
/// Legacy JSON numbers round-trip as recorded; decoding does not migrate
/// their units. Web layers come from `../normalize/css_value_parsers.dart`.
@immutable
class BoxShadowLayer {
  const BoxShadowLayer({
    required this.offsetX,
    required this.offsetY,
    required this.blur,
    required this.spread,
    required this.color,
    this.inset = false,
    this.blurStyle = 'normal',
  });

  /// Reconstructs a [BoxShadowLayer] from [toJson]'s output.
  factory BoxShadowLayer.fromJson(Map<String, Object?> json) => BoxShadowLayer(
    offsetX: (json['offsetX']! as num).toDouble(),
    offsetY: (json['offsetY']! as num).toDouble(),
    blur: (json['blur']! as num).toDouble(),
    spread: (json['spread']! as num).toDouble(),
    color: NormalizedColor.fromJson((json['color']! as Map).cast()),
    inset: json['inset'] as bool? ?? false,
    blurStyle: json['blurStyle'] as String? ?? 'normal',
  );

  final double offsetX;
  final double offsetY;
  final double blur;
  final double spread;
  final NormalizedColor color;

  /// Internal capture metadata: CSS inset placement is different from an
  /// outer cast even when its dimensions and colour are identical.
  /// Missing metadata in an older artifact retains its outer-cast meaning.
  final bool inset;

  /// Flutter's `BlurStyle.name`, or `normal` for a CSS shadow. Keeping the
  /// SDK name avoids importing dart:ui into this pure-Dart artifact model.
  /// A non-normal mask is not silently equated with an ordinary CSS blur.
  final String blurStyle;

  Map<String, Object?> toJson() => {
    'offsetX': offsetX,
    'offsetY': offsetY,
    'blur': blur,
    'spread': spread,
    'color': color.toJson(),
    // Optional additions to the internal JSON capture protocol. Defaults
    // stay absent so older normal/outset artifacts round-trip unchanged.
    if (inset) 'inset': true,
    if (blurStyle != 'normal') 'blurStyle': blurStyle,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxShadowLayer &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          blur == other.blur &&
          spread == other.spread &&
          color == other.color &&
          inset == other.inset &&
          blurStyle == other.blurStyle;

  @override
  int get hashCode =>
      Object.hash(offsetX, offsetY, blur, spread, color, inset, blurStyle);

  @override
  String toString() =>
      'BoxShadowLayer(x:$offsetX, y:$offsetY, blur:$blur, spread:$spread, '
      'color:$color${inset ? ', inset:true' : ''}'
      '${blurStyle == 'normal' ? '' : ', blurStyle:$blurStyle'})';
}

/// Four-corner px values — border radius (`[tl, tr, br, bl]`) and padding
/// (`[t, r, b, l]`) both use this shape, just with different corner/edge
/// semantics the field name (not this type) carries.
@immutable
class FourSidePx {
  const FourSidePx(this.a, this.b, this.c, this.d);

  /// Reconstructs a [FourSidePx] from [toJson]'s output.
  factory FourSidePx.fromJson(List<Object?> json) => FourSidePx(
    (json[0]! as num).toDouble(),
    (json[1]! as num).toDouble(),
    (json[2]! as num).toDouble(),
    (json[3]! as num).toDouble(),
  );

  final double a;
  final double b;
  final double c;
  final double d;

  List<double> toJson() => [a, b, c, d];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FourSidePx &&
          a == other.a &&
          b == other.b &&
          c == other.c &&
          d == other.d;

  @override
  int get hashCode => Object.hash(a, b, c, d);

  @override
  String toString() => 'FourSidePx($a, $b, $c, $d)';
}

/// Normalized render values for one probe role — platform-neutral.
///
/// Every numeric px field is rounded to 2 decimal places
/// (`.bmad/architecture-*.md` Component ④'s rounding policy) before
/// `Comparator` (#3607) ever sees it, so sub-pixel floating point noise
/// from either platform's own arithmetic (Flutter's `height` multiplier
/// math, a browser's subpixel layout) doesn't register as a diff.
///
/// Source: `.bmad/architecture-*.md` Data Architecture → `PropertySnapshot`.
/// Field set mirrors `../model/property_field.dart`'s `PropertyField` enum
/// exactly — every entry there has a field here with the matching name
/// (`PropertyField.fontSizePx` ↔ `fontSizePx`), so a `ProbeSpec.fields`
/// declaration can be checked against what actually got captured.
@immutable
class PropertySnapshot {
  const PropertySnapshot({
    required this.key,
    required this.platform,
    required this.probeRole,
    this.fontFamily,
    this.fontWeight,
    this.fontSizePx,
    this.lineHeightPx,
    this.letterSpacingPx,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.borderWidthPx,
    this.borderRadiusPx,
    this.paddingPx,
    this.outlineWidthPx,
    this.outlineOffsetPx,
    this.boxShadow,
    this.opacity,
    this.widthPx,
    this.heightPx,
  });

  /// Reconstructs a [PropertySnapshot] from [toJson]'s output.
  factory PropertySnapshot.fromJson(Map<String, Object?> json) =>
      PropertySnapshot(
        key: json['key']! as String,
        platform: json['platform']! as String,
        probeRole: json['probeRole']! as String,
        fontFamily: json['fontFamily'] as String?,
        fontWeight: json['fontWeight'] as int?,
        fontSizePx: (json['fontSizePx'] as num?)?.toDouble(),
        lineHeightPx: (json['lineHeightPx'] as num?)?.toDouble(),
        letterSpacingPx: (json['letterSpacingPx'] as num?)?.toDouble(),
        color: json['color'] == null
            ? null
            : NormalizedColor.fromJson((json['color']! as Map).cast()),
        backgroundColor: json['backgroundColor'] == null
            ? null
            : NormalizedColor.fromJson(
                (json['backgroundColor']! as Map).cast(),
              ),
        borderColor: json['borderColor'] == null
            ? null
            : NormalizedColor.fromJson((json['borderColor']! as Map).cast()),
        borderWidthPx: (json['borderWidthPx'] as num?)?.toDouble(),
        borderRadiusPx: json['borderRadiusPx'] == null
            ? null
            : FourSidePx.fromJson(json['borderRadiusPx']! as List),
        paddingPx: json['paddingPx'] == null
            ? null
            : FourSidePx.fromJson(json['paddingPx']! as List),
        outlineWidthPx: (json['outlineWidthPx'] as num?)?.toDouble(),
        outlineOffsetPx: (json['outlineOffsetPx'] as num?)?.toDouble(),
        boxShadow: json['boxShadow'] == null
            ? null
            : [
                for (final layer in json['boxShadow']! as List)
                  BoxShadowLayer.fromJson((layer as Map).cast()),
              ],
        opacity: (json['opacity'] as num?)?.toDouble(),
        widthPx: (json['widthPx'] as num?)?.toDouble(),
        heightPx: (json['heightPx'] as num?)?.toDouble(),
      );

  /// The `MatrixEntry.key` this snapshot was captured for.
  final String key;

  /// `ParityPlatform.wireName` (`'flutter'` | `'web'`) — kept as a plain
  /// `String` rather than importing `ParityPlatform` here so this pure data
  /// model has no dependency on the baseline module.
  final String platform;

  /// Which `ProbeSpec.role` this snapshot's values were read from.
  final String probeRole;

  final String? fontFamily;

  /// CSS-style `100..900` — already the common unit on both platforms
  /// (Flutter's `FontWeight.value` and the Web `font-weight` computed
  /// string both resolve to this range), so normalization is identity, not
  /// arithmetic. See `../normalize/flutter_property_normalizer.dart` for
  /// why that identity is still worth a named function.
  final int? fontWeight;

  final double? fontSizePx;

  final double? lineHeightPx;

  final double? letterSpacingPx;

  final NormalizedColor? color;

  final NormalizedColor? backgroundColor;

  /// A single representative side's color — see
  /// `../normalize/web_property_normalizer.dart`'s doc comment on why the
  /// schema (`.bmad/architecture-*.md`) states one scalar rather than
  /// four-sided here despite `borderRadiusPx`/`paddingPx` being arrays.
  final NormalizedColor? borderColor;

  final double? borderWidthPx;

  /// `[topLeft, topRight, bottomRight, bottomLeft]`.
  final FourSidePx? borderRadiusPx;

  /// `[top, right, bottom, left]`.
  final FourSidePx? paddingPx;

  final double? outlineWidthPx;

  final double? outlineOffsetPx;

  final List<BoxShadowLayer>? boxShadow;

  final double? opacity;

  /// Border-box width in px — Flutter's `RenderBox.size.width`, Web's
  /// `getBoundingClientRect().width`.
  final double? widthPx;

  /// Border-box height in px. The field that makes a size token the
  /// two platforms read differently visible to the gate.
  final double? heightPx;

  Map<String, Object?> toJson() => {
    'key': key,
    'platform': platform,
    'probeRole': probeRole,
    'fontFamily': fontFamily,
    'fontWeight': fontWeight,
    'fontSizePx': fontSizePx,
    'lineHeightPx': lineHeightPx,
    'letterSpacingPx': letterSpacingPx,
    'color': color?.toJson(),
    'backgroundColor': backgroundColor?.toJson(),
    'borderColor': borderColor?.toJson(),
    'borderWidthPx': borderWidthPx,
    'borderRadiusPx': borderRadiusPx?.toJson(),
    'paddingPx': paddingPx?.toJson(),
    'outlineWidthPx': outlineWidthPx,
    'outlineOffsetPx': outlineOffsetPx,
    'boxShadow': boxShadow?.map((l) => l.toJson()).toList(),
    'opacity': opacity,
    'widthPx': widthPx,
    'heightPx': heightPx,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertySnapshot &&
          key == other.key &&
          platform == other.platform &&
          probeRole == other.probeRole &&
          fontFamily == other.fontFamily &&
          fontWeight == other.fontWeight &&
          fontSizePx == other.fontSizePx &&
          lineHeightPx == other.lineHeightPx &&
          letterSpacingPx == other.letterSpacingPx &&
          color == other.color &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidthPx == other.borderWidthPx &&
          borderRadiusPx == other.borderRadiusPx &&
          paddingPx == other.paddingPx &&
          outlineWidthPx == other.outlineWidthPx &&
          outlineOffsetPx == other.outlineOffsetPx &&
          _boxShadowEquals(boxShadow, other.boxShadow) &&
          opacity == other.opacity &&
          widthPx == other.widthPx &&
          heightPx == other.heightPx;

  @override
  int get hashCode => Object.hash(
    key,
    platform,
    probeRole,
    fontFamily,
    fontWeight,
    fontSizePx,
    lineHeightPx,
    letterSpacingPx,
    color,
    backgroundColor,
    borderColor,
    Object.hash(
      borderWidthPx,
      borderRadiusPx,
      paddingPx,
      outlineWidthPx,
      outlineOffsetPx,
      opacity,
      widthPx,
      heightPx,
    ),
  );

  @override
  String toString() => 'PropertySnapshot(${toJson()})';
}

bool _boxShadowEquals(List<BoxShadowLayer>? a, List<BoxShadowLayer>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Decimal places [roundPx] keeps — the length half of Component ④'s
/// rounding policy (`.bmad/architecture-*.md`).
const int kPxRoundingDecimals = 2;

/// Decimal places [roundAlpha] keeps — the alpha half of Component ④'s
/// rounding policy. Finer than [kPxRoundingDecimals] because alpha's domain
/// is `0.0..1.0` rather than arbitrary px, so the same absolute rounding
/// step is a much larger relative error at 2 decimals.
const int kAlphaRoundingDecimals = 3;

/// Rounds a length in px to [kPxRoundingDecimals] places. A named function
/// (not an inline `double.parse(x.toStringAsFixed(2))` at every call site)
/// so every conversion formula in `../normalize/` visibly opts into the
/// same policy instead of picking its own precision.
double roundPx(double value) =>
    double.parse(value.toStringAsFixed(kPxRoundingDecimals));

/// Rounds an alpha channel to [kAlphaRoundingDecimals] places.
double roundAlpha(double value) =>
    double.parse(value.toStringAsFixed(kAlphaRoundingDecimals));
