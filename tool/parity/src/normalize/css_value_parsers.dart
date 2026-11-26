// #3606 — pure string parsers for `getComputedStyle()` output.
//
// Every function here takes a raw browser string (exactly what
// `computed_style_probe.dart` reads via `getComputedStyle()`) and returns a
// normalized value. None of these need a browser or `dart:html` — that's
// deliberate: `.bmad/architecture-*.md`'s Testing Strategy requires the
// comparison pipeline to be verifiable with synthetic fixtures alone (FR-005
// — "브라우저 없이 비교 로직만 검증"), and these parsers are the layer where
// that separation actually lives.
import '../model/property_snapshot.dart';

/// Matches Chrome's computed-style color serialization:
/// `rgb(r, g, b)` or `rgba(r, g, b, a)`, integer channels, `a` a decimal or
/// integer (`0`/`1`/`0.5`). Computed small numbers can use exponent notation.
final RegExp _kRgbaPattern = RegExp(
  r'^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+(?:[eE][+-]?\d+)?)\s*)?\)$',
);

/// [_kRgbaPattern]'s capture group indices — named so a reader doesn't have
/// to count parentheses in the pattern above to know which group is which.
const int _kRedGroup = 1;
const int _kGreenGroup = 2;
const int _kBlueGroup = 3;
const int _kAlphaGroup = 4;

/// Matches the CSS Color-4 `color(srgb r g b [/ a])` function — Chrome's
/// serialization for a color that doesn't round-trip through legacy
/// `rgb()`/`rgba()` syntax (observed in `box-shadow` layers whose color
/// derives from a `color-mix`/wide-gamut token). Unlike `rgb()`'s 0..255
/// integer channels, `color(srgb ...)` channels are 0..1 floats (including
/// exponent notation for tiny channels/alpha) — the same
/// physical quantity (an sRGB channel value), a different input unit, the
/// exact class of bug `cross-platform/api.md` warns about for any shared
/// physical-quantity parser.
final RegExp _kColorFunctionSrgbPattern = RegExp(
  r'^color\(srgb\s+([\d.]+(?:[eE][+-]?\d+)?)\s+([\d.]+(?:[eE][+-]?\d+)?)\s+([\d.]+(?:[eE][+-]?\d+)?)\s*(?:/\s*([\d.]+(?:[eE][+-]?\d+)?)\s*)?\)$',
);

/// [_kColorFunctionSrgbPattern]'s capture groups — same red/green/blue/alpha
/// ordering as [_kRgbaPattern], so callers that already destructure one can
/// destructure the other identically.
const int _kSrgbRedGroup = 1;
const int _kSrgbGreenGroup = 2;
const int _kSrgbBlueGroup = 3;
const int _kSrgbAlphaGroup = 4;

/// A whole 0..255 byte channel — `color(srgb ...)`'s 0..1 float channel
/// times this, rounded to nearest.
const double _kSrgbChannelScale = 255;

/// A computed `box-shadow` layer always resolves to exactly this many
/// length values: `offsetX offsetY blurRadius spreadRadius`.
const int _kBoxShadowLengthCount = 4;

/// Parses a `getComputedStyle()` length string (`'16px'`) to a px double.
///
/// `getComputedStyle()` always resolves lengths to **used values in px**
/// regardless of the CSS source's declared unit (`rem`, `em`, `%`) — the
/// browser has already done the rem→px conversion the architecture doc's
/// unit table calls out (`.bmad/architecture-*.md` Component ④) by the time
/// this string exists. This function's only job is stripping the `'px'`
/// suffix and parsing the number; there is no unit *math* here because the
/// browser already did it.
double parseCssPx(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.endsWith('px')) {
    throw FormatException('px 단위 CSS 값이 아님: "$raw"');
  }
  return roundPx(double.parse(trimmed.substring(0, trimmed.length - 2)));
}

/// Like [parseCssPx], but treats the CSS `normal` keyword (no fixed
/// value — the browser is free to pick its own) as "no opinion", matching
/// how `letterSpacingPx`/`lineHeightPx` being `null` in `PropertySnapshot`
/// means the same thing on the Flutter side (an unset `TextStyle` field).
double? parseCssPxOrNormal(String raw) {
  final trimmed = raw.trim();
  if (trimmed == 'normal') return null;
  return parseCssPx(trimmed);
}

/// Parses a `getComputedStyle().fontFamily` string down to the single
/// family name Flutter's `TextStyle.fontFamily` is comparable to.
///
/// The browser always resolves `font-family` to the *full* CSS-declared
/// fallback chain (`'Pretendard, system-ui, sans-serif'`) — every name a
/// stylesheet listed, not just the one that actually painted. Flutter's
/// side only ever has a single name (`'Pretendard'`); it resolves its own
/// glyph fallback internally and never surfaces a chain. Comparing the raw
/// strings verbatim (`property_diff.dart`'s `_compareNullable` is an exact
/// match) flags every single component as a mismatch even when the same
/// font painted on both platforms (#3659).
///
/// The chain's first entry is the only one with a Flutter-comparable
/// meaning: CSS fallback only engages per *glyph* when the first font is
/// missing a character, so the first-listed family is what a browser
/// paints with whenever it's available — same as Flutter's single name.
/// A real divergence in *which* first font loaded (`Pretendard` vs
/// `Roboto`) still fails this comparison; only the fallback names *after*
/// the first stop being visible to it (documented trade-off, see #3659's
/// PR body).
///
/// Each entry may be quoted (`"Pretendard"` — CSS requires quoting a
/// `font-family` name that isn't a valid CSS identifier, e.g. contains a
/// space or starts with a digit); Flutter's `fontFamily` is never quoted,
/// so the first entry's surrounding quotes (if any) are stripped.
String parseCssFontFamily(String raw) {
  final first = raw.split(',').first.trim();
  final isSingleQuoted = first.startsWith("'") && first.endsWith("'");
  final isDoubleQuoted = first.startsWith('"') && first.endsWith('"');
  if (first.length >= 2 && (isSingleQuoted || isDoubleQuoted)) {
    return first.substring(1, first.length - 1);
  }
  return first;
}

/// Parses a `getComputedStyle().fontWeight` string to the common
/// `100..900` int scale.
///
/// Modern Chrome always resolves `font-weight` to a numeric string by the
/// time `getComputedStyle()` returns it — the `normal`/`bold` keyword
/// branches below exist only as a defensive fallback for the (currently
/// theoretical, for this harness) case of an unresolved keyword reaching
/// this function, not because real captures are expected to need them.
int parseCssFontWeight(String raw) {
  final trimmed = raw.trim();
  return switch (trimmed) {
    'normal' => 400,
    'bold' => 700,
    _ => int.parse(trimmed),
  };
}

/// Parses a `getComputedStyle()` color string — legacy `'rgb(29, 29, 31)'` /
/// `'rgba(29, 29, 31, 0.5)'`, CSS Color-4 `'color(srgb 0.11 0.11 0.12)'`, or
/// `'transparent'` — to a [NormalizedColor].
///
/// The alpha channel omitted from a 3-argument `rgb(...)` (or a `color(srgb
/// ...)` with no `/ a`) defaults to `1.0` (fully opaque) — that's each
/// syntax's own definition, not a guess this function is making.
NormalizedColor parseCssColor(String raw) {
  final trimmed = raw.trim();
  if (trimmed == 'transparent') {
    return NormalizedColor(r: 0, g: 0, b: 0, a: 0);
  }
  final rgba = _tryParseRgbaFunction(trimmed);
  if (rgba != null) return rgba;
  final srgb = _tryParseColorFunctionSrgb(trimmed);
  if (srgb != null) return srgb;
  throw FormatException('CSS 색상 값을 해석하지 못함: "$raw"');
}

/// Whether the raw computed colour has exactly zero alpha, before the
/// artifact's three-decimal colour rounding. A positive alpha such as
/// 0.0004 still describes paint and must not be mistaken for absence.
///
/// Alpha is independent of the channel colour space. Observe the absolute
/// computed Color 4 forms without converting Lab, P3 or out-of-gamut
/// channels to RGB. Unresolved expressions and unsupported/malformed forms
/// remain errors, rather than evidence of transparency.
bool cssColorIsFullyTransparent(String raw) {
  final trimmed = raw.trim().toLowerCase();
  if (trimmed == 'transparent') return true;

  Never invalid() => throw FormatException('CSS 색상 값을 해석하지 못함: "$raw"');
  final function = RegExp(r'^([a-z]+)\(([^()]*)\)$').firstMatch(trimmed);
  if (function == null) invalid();
  final name = function.group(1)!;
  if (!const {
    'rgb',
    'rgba',
    'hsl',
    'hsla',
    'hwb',
    'lab',
    'lch',
    'oklab',
    'oklch',
    'color',
  }.contains(name)) {
    invalid();
  }

  const number = r'[+-]?(?:\d+(?:\.\d+)?|\.\d+)(?:e[+-]?\d+)?';
  final numberOrPercent = RegExp('^$number%?\$');
  final hue = RegExp('^$number(?:deg|grad|rad|turn)?\$');
  final body = function.group(2)!;
  final legacy = body.contains(',');
  List<String> channels;
  String? alpha;
  if (legacy) {
    if (!const {'rgb', 'rgba', 'hsl', 'hsla'}.contains(name) ||
        body.contains('/')) {
      invalid();
    }
    final parts = body.split(',').map((part) => part.trim()).toList();
    if (parts.length != 3 && parts.length != 4) invalid();
    channels = parts.sublist(0, 3);
    alpha = parts.length == 4 ? parts[3] : null;
  } else {
    final parts = body.split('/');
    if (parts.length > 2) invalid();
    channels = parts[0].trim().split(RegExp(r'\s+'));
    alpha = parts.length == 2 ? parts[1].trim() : null;
    if (name == 'color') {
      if (channels.length != 4 ||
          !const {
            'srgb',
            'srgb-linear',
            'display-p3',
            'display-p3-linear',
            'a98-rgb',
            'prophoto-rgb',
            'rec2020',
            'xyz',
            'xyz-d50',
            'xyz-d65',
          }.contains(channels.first)) {
        invalid();
      }
      channels = channels.sublist(1);
    }
  }
  if (channels.length != 3) invalid();

  final hueIndex = switch (name) {
    'hsl' || 'hsla' || 'hwb' => 0,
    'lch' || 'oklch' => 2,
    _ => -1,
  };
  for (var index = 0; index < channels.length; index++) {
    final channel = channels[index];
    if (!legacy && channel == 'none') continue;
    if (!(index == hueIndex ? hue : numberOrPercent).hasMatch(channel)) {
      invalid();
    }
  }
  if (legacy) {
    if (name == 'rgb' || name == 'rgba') {
      // Legacy RGB cannot mix numeric and percentage channels.
      if (channels.any(
        (c) => c.endsWith('%') != channels.first.endsWith('%'),
      )) {
        invalid();
      }
    } else if (!channels[1].endsWith('%') || !channels[2].endsWith('%')) {
      invalid();
    }
  }

  if (alpha == null) return false; // Omitted alpha is opaque.
  // Color 4 missing components render as zero; negative alpha clamps to
  // zero. Neither rule changes the channels or rounds a positive alpha.
  // https://www.w3.org/TR/css-color-4/#alpha-syntax
  if (!legacy && alpha == 'none') return true;
  if (!numberOrPercent.hasMatch(alpha)) invalid();
  // Inspect the coefficient instead of parsing a double: a positive
  // exponent/percentage must not underflow into a false zero observation.
  return alpha.startsWith('-') ||
      !RegExp('[1-9]').hasMatch(alpha.split('e').first);
}

/// [_kRgbaPattern] branch of [parseCssColor] — split out so
/// [_parseBoxShadowLayer] can attempt it without duplicating the group
/// destructuring.
NormalizedColor? _tryParseRgbaFunction(String trimmed) {
  final match = _kRgbaPattern.firstMatch(trimmed);
  if (match == null) return null;
  final alphaGroup = match.group(_kAlphaGroup);
  return NormalizedColor(
    r: int.parse(match.group(_kRedGroup)!),
    g: int.parse(match.group(_kGreenGroup)!),
    b: int.parse(match.group(_kBlueGroup)!),
    a: alphaGroup == null ? 1 : double.parse(alphaGroup),
  );
}

/// [_kColorFunctionSrgbPattern] branch of [parseCssColor] — channels are
/// 0..1 floats (unit: fraction of full intensity), converted here to
/// [NormalizedColor]'s 0..255 int scale (unit: byte) by multiplying by
/// [_kSrgbChannelScale] and rounding — the same physical quantity (an sRGB
/// channel), a different input unit, same as this function's sibling.
NormalizedColor? _tryParseColorFunctionSrgb(String trimmed) {
  final match = _kColorFunctionSrgbPattern.firstMatch(trimmed);
  if (match == null) return null;
  int channelToByte(int group) =>
      (double.parse(match.group(group)!) * _kSrgbChannelScale).round().clamp(
        0,
        _kSrgbChannelScale.toInt(),
      );
  final alphaGroup = match.group(_kSrgbAlphaGroup);
  return NormalizedColor(
    r: channelToByte(_kSrgbRedGroup),
    g: channelToByte(_kSrgbGreenGroup),
    b: channelToByte(_kSrgbBlueGroup),
    a: alphaGroup == null ? 1 : double.parse(alphaGroup),
  );
}

/// Parses a `getComputedStyle().boxShadow` string into its painted layers.
/// Exactly zero-alpha layers paint nothing and are omitted, independently
/// of their geometry. This decision uses the raw alpha before rounding.
/// Positive-alpha layers retain their order and inset placement.
///
/// `none` (no shadow declared) returns an empty list rather than `null` —
/// "this element has zero shadow layers" and "this field wasn't probed"
/// are different facts, and only the latter should ever produce `null` at
/// the `PropertySnapshot` level.
///
/// Chrome's computed serialization puts the color **first** in each layer,
/// followed by `offsetX offsetY blurRadius spreadRadius` (all four lengths
/// always present, `spreadRadius` defaulting to `0px` even when the
/// original CSS omitted it) — e.g.
/// `'rgba(0, 0, 0, 0.1) 0px 4px 6px 2px, rgba(0, 0, 0, 0.06) 0px 1px 2px 0px'`
/// for two layers. Layers are comma-separated, but a naive split on `,`
/// would also split *inside* each layer's own `rgba(...)` — [_splitTopLevel]
/// only splits where paren-nesting depth is zero.
List<BoxShadowLayer> parseCssBoxShadow(String raw) {
  final trimmed = raw.trim();
  if (trimmed == 'none' || trimmed.isEmpty) return const [];

  final layers = <BoxShadowLayer>[];
  for (final layerText in _splitTopLevel(trimmed, ',')) {
    final layer = _parseBoxShadowLayer(layerText.trim());
    if (layer != null) layers.add(layer);
  }
  return layers;
}

/// Matches either color syntax a box-shadow layer's color component can use
/// — legacy `rgb()`/`rgba()` or CSS Color-4 `color(srgb ...)` — as a whole
/// substring, so it can both be extracted (fed to [parseCssColor]) and
/// stripped from the layer text before the remaining lengths are parsed.
final RegExp _kBoxShadowColorFunctionPattern = RegExp(
  r'(rgba?\([^)]*\)|color\(srgb[^)]*\))',
);

BoxShadowLayer? _parseBoxShadowLayer(String layerText) {
  final colorText = _kBoxShadowColorFunctionPattern
      .firstMatch(layerText)
      ?.group(0);
  if (colorText == null) {
    throw FormatException('box-shadow 레이어에 색상이 없음: "$layerText"');
  }
  final transparent = cssColorIsFullyTransparent(colorText);
  final inset = RegExp(r'\binset\b').hasMatch(layerText);

  // Remove the color and the (optional) `inset` keyword, leaving only the
  // four whitespace-separated px lengths.
  final withoutColor = layerText
      .replaceAll(_kBoxShadowColorFunctionPattern, '')
      .replaceAll(RegExp(r'\binset\b'), '')
      .trim();
  final lengths = withoutColor
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .map(parseCssPx)
      .toList(growable: false);
  if (lengths.length != _kBoxShadowLengthCount) {
    throw FormatException(
      'box-shadow 레이어에서 $_kBoxShadowLengthCount개 길이(offsetX offsetY '
      'blur spread)를 기대했으나 ${lengths.length}개 발견: "$layerText"',
    );
  }
  if (transparent) return null;

  return BoxShadowLayer(
    offsetX: lengths[0],
    offsetY: lengths[1],
    blur: lengths[2],
    spread: lengths[3],
    color: parseCssColor(colorText),
    inset: inset,
  );
}

/// Reads a computed box-alignment keyword (`justify-content`, `align-items`
/// and their kin) by what it means rather than how it is spelled.
///
/// Chrome 158 reads `flex-start` and `flex-end` back as `flow-start` and
/// `flow-end` (`start` and `end` stay as they are), so a stylesheet that
/// declares `justify-content: flex-end` computes to `flow-end` while every
/// box lands exactly where it did. Those two spellings come back as the
/// declared `flex-start` / `flex-end`, so a probe compares the same value on
/// a browser that spells them either way; every other keyword comes back
/// unchanged, so a real change of alignment still fails the comparison.
String parseCssFlexAlignment(String raw) => switch (raw.trim()) {
  'flow-start' => 'flex-start',
  'flow-end' => 'flex-end',
  final keyword => keyword,
};

/// Splits [input] on [separator], but only where paren-nesting depth is
/// zero — so `'rgba(0, 0, 0, 1) 0px', 'rgba(0, 0, 0, 1) 1px'` splits into
/// exactly 2 parts at the top-level comma, not 2 + the commas inside each
/// `rgba(...)`.
List<String> _splitTopLevel(String input, String separator) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
    } else if (char == separator && depth == 0) {
      parts.add(input.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(input.substring(start));
  return parts;
}
