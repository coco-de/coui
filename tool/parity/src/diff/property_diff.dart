// #3607 — PropertyDiff, the 1st (primary) comparison signal.
//
// `.bmad/architecture-*.md` Component ⑤: field-by-field exact comparison
// (tolerance is a constant per field *type*, not per field), structured
// failure output naming which field differs how, and a 3-way verdict when
// an expected/token snapshot is supplied — which platform, if either,
// diverges from what the design token itself says. This is the signal that
// catches "same Core token, different render" defects (Command's label
// font-weight — PRD-confirmed, `.bmad/prd-*.md`) that a pixel threshold
// alone cannot: two renders can be visually near-identical in a screenshot
// diff while a single semantic field (fontWeight 600 vs 400) is flatly
// wrong.
import '../model/property_field.dart';
import '../model/property_snapshot.dart';

/// Tolerance for any px-valued field (length, radius, spacing, shadow
/// geometry). Provisional — SPIKE-4 (`.bmad/architecture-*.md` Component
/// ⑤'s own design note) calibrates this against Tier1 real captures; until
/// then this is set loose enough to absorb `roundPx`'s own 2-decimal
/// rounding plus a browser's fractional-px layout rounding, tight enough
/// to still catch DatePicker's confirmed multi-px focus-ring geometry
/// defect (PRD: "포커스 테두리 지오메트리 불일치", screenshot-confirmed).
const double kPxTolerance = 0.5;

/// Tolerance for a 0-255 color channel (r/g/b). `0` — computed-style colors
/// are exact integers on both platforms once normalized; any channel delta
/// is a real color difference, not noise (unlike a *rasterized pixel*,
/// which PixelDiff's much looser threshold accounts for separately).
const int kColorChannelTolerance = 0;

/// Tolerance finer than the shared three-decimal alpha/opacity precision.
///
/// Typed Flutter colours retain `Color.a`, CSS retains computed alpha, and
/// both opacity collectors retain their double property. Each observation
/// uses `roundAlpha`'s one-thousandth decimal grid. The original half-step
/// tolerance absorbs finer arithmetic noise
/// while keeping every distinct canonical observation visible.
///
/// Older ARGB-based captures have already lost their float alpha. Their
/// source cannot be recovered by recognizing a value's numeric shape, so
/// no byte-quantization allowance is inferred here.
const double kAlphaTolerance = 0.0005;

/// Which platform(s), if any, diverge from a supplied expected/token value
/// for one field — the "3-way" half of PropertyDiff's verdict.
enum TokenDivergence {
  /// No expected value was supplied — this field wasn't checked against a
  /// token, only Flutter vs Web.
  notChecked,

  /// Flutter and Web both match the expected value (or no divergence was
  /// possible to detect either way).
  neitherDiverges,

  /// Flutter's value differs from the expected value; Web matches it —
  /// the exact shape of the confirmed Command font-weight defect (Core
  /// token says regular/400, Web renders 400, Flutter renders 600).
  flutterDiverges,

  /// Web's value differs from the expected value; Flutter matches it.
  webDiverges,

  /// Both platforms differ from the expected value (and, depending on
  /// whether they agree with *each other*, may or may not also fail the
  /// Flutter-vs-Web check).
  bothDiverge,
}

/// One field's comparison result.
class FieldDivergence {
  const FieldDivergence({
    required this.field,
    required this.matches,
    required this.flutterDescription,
    required this.webDescription,
    this.tokenDescription,
    this.tokenDivergence = TokenDivergence.notChecked,
  });

  /// The `PropertySnapshot` field name, e.g. `'fontWeight'`.
  final String field;

  /// Whether Flutter's and Web's values are within tolerance of each
  /// other — the primary (cross-platform parity) verdict for this field.
  final bool matches;

  /// Human-readable rendering of Flutter's value for this field.
  final String flutterDescription;

  /// Human-readable rendering of Web's value for this field.
  final String webDescription;

  /// Human-readable rendering of the expected/token value, if one was
  /// supplied.
  final String? tokenDescription;

  /// The 3-way verdict against the expected/token value.
  final TokenDivergence tokenDivergence;

  /// `'fontWeight: flutter=600 web=400 (token=400 — flutter diverges)'` —
  /// the structured-failure format the completion definition names
  /// verbatim.
  String describe() {
    final buffer = StringBuffer(
      '$field: flutter=$flutterDescription web=$webDescription',
    );
    if (tokenDescription != null) {
      final note = switch (tokenDivergence) {
        .notChecked || .neitherDiverges => '',
        .flutterDiverges => ' — flutter diverges',
        .webDiverges => ' — web diverges',
        .bothDiverge => ' — both diverge',
      };
      buffer.write(' (token=$tokenDescription$note)');
    }
    return buffer.toString();
  }

  @override
  String toString() => describe();
}

/// All field comparisons for one `PropertySnapshot` pair (one probe role).
class PropertyDiffResult {
  const PropertyDiffResult({
    required this.key,
    required this.probeRole,
    required this.fields,
  });

  final String key;
  final String probeRole;

  /// Every field this comparison checked, matching and non-matching alike
  /// — callers wanting only the failures use [failures].
  final List<FieldDivergence> fields;

  /// Only the fields where Flutter and Web disagree beyond tolerance.
  List<FieldDivergence> get failures => [
    for (final f in fields)
      if (!f.matches) f,
  ];

  /// Whether any field failed — the gate this result feeds.
  bool get hasFailures => failures.isNotEmpty;

  /// One line per failing field, in [FieldDivergence.describe] format —
  /// the structured output the completion definition requires ("실패 시
  /// 어느 필드가 어떻게 다른지 구조화 출력").
  String describeFailures() => failures.map((f) => f.describe()).join('\n');

  @override
  String toString() =>
      'PropertyDiffResult($key/$probeRole, '
      '${failures.length}/${fields.length} fields failing)';
}

/// Compares [flutter] and [web] field by field, optionally against
/// [expected] (the Core-token-derived value a design-system author would
/// expect) for the 3-way verdict.
///
/// [flutter] and [web] must share the same `key`/`probeRole` — this
/// function doesn't reconcile snapshots for different probes, it assumes
/// the caller already matched them up (the same way `MatrixEntry.probes`
/// pairs a `ProbeSpec` across both platforms by `role`).
///
/// [reconcilePlatforms] is retained for existing callers. Both values
/// compare the captured fields directly; no authored padding is
/// reconstructed from a platform's border width.
/// Only [requestedFields] contribute to the verdict. Empty declarations are
/// invalid when this property signal runs; omitted declarations retain all
/// fields for existing direct callers. Full snapshots remain available for
/// paint visibility predicates even when their context fields are not
/// requested.
PropertyDiffResult comparePropertySnapshots({
  required PropertySnapshot flutter,
  required PropertySnapshot web,
  PropertySnapshot? expected,
  bool reconcilePlatforms = true,
  Set<PropertyField> requestedFields = PropertyField.all,
}) {
  if (requestedFields.isEmpty) {
    throw const FormatException(
      'Property comparison requires at least one declared field.',
    );
  }

  // A border nobody draws has no colour to disagree about.
  //
  // The capture pages mount a Preflight-derived reset that sets
  // `*, ::after, ::before { border: 0px solid rgb(229,231,235) }`, so
  // Chrome computes that grey for every element whether or not a border
  // is painted, while Flutter reports null when its decoration has no
  // side. Neither is wrong and neither reaches a pixel — at width 0 the
  // colour is unobservable on both. It was 78% of the corpus: 488 of 624
  // web role-captures carry a colour at zero width.
  //
  // Gated here rather than nulled in a normalizer for three reasons.
  // Flutter emits the same shape (a zero-width side that still carries a
  // colour), so a web-only null-out would trade these failures for a
  // fresh set. The normalizer layer cannot be made symmetric anyway —
  // Flutter baselines are stored already-normalized from inside `flutter
  // test` while Web baselines are normalized at compare time, so a
  // change there would not reach the stored artifacts. And the raw
  // measurement is worth keeping in the artifact; what belongs in the
  // comparator is the judgement about whether it is observable.
  final borderIsPainted =
      (flutter.borderWidthPx ?? 0) > 0 || (web.borderWidthPx ?? 0) > 0;

  // Same judgement for the outline, and it hid a larger share: 160 of the
  // corpus. Web reports a 3px outline on components that draw none —
  // `outline-width`'s initial `medium` computes to 3px on every element,
  // and the normalizer zeroes it once it can see `outline-style: none`.
  // Flutter has no outline concept at all (focus rings are painted as
  // shadows), so it reports null. Neither reaches a pixel.
  //
  // Gated rather than left to the normalizer alone because `null` and `0`
  // are not the same value to the comparator — zeroing the web side would
  // trade "3 vs null" for "0 vs null" and change nothing.
  final outlineIsPainted =
      (flutter.outlineWidthPx ?? 0) > 0 || (web.outlineWidthPx ?? 0) > 0;

  final fields = [
    _compareNullable(
      'fontFamily',
      flutter.fontFamily,
      web.fontFamily,
      expected?.fontFamily,
      equals: (a, b) => a == b,
      describe: (v) => v,
    ),
    _compareNullable(
      'fontWeight',
      flutter.fontWeight,
      web.fontWeight,
      expected?.fontWeight,
      equals: (a, b) => a == b,
      describe: (v) => '$v',
    ),
    _comparePx(
      'fontSizePx',
      flutter.fontSizePx,
      web.fontSizePx,
      expected?.fontSizePx,
    ),
    _comparePx(
      'lineHeightPx',
      flutter.lineHeightPx,
      web.lineHeightPx,
      expected?.lineHeightPx,
    ),
    _comparePx(
      'letterSpacingPx',
      flutter.letterSpacingPx,
      web.letterSpacingPx,
      expected?.letterSpacingPx,
    ),
    _compareColor('color', flutter.color, web.color, expected?.color),
    _compareColor(
      'backgroundColor',
      flutter.backgroundColor,
      web.backgroundColor,
      expected?.backgroundColor,
    ),
    if (borderIsPainted)
      _compareColor(
        'borderColor',
        flutter.borderColor,
        web.borderColor,
        expected?.borderColor,
      )
    else
      // Kept in the roster rather than dropped, so the report still shows
      // the field and what each side measured — the reader can see the
      // reset grey and know why it was not held against anything.
      FieldDivergence(
        field: 'borderColor',
        matches: true,
        flutterDescription: flutter.borderColor?.toString() ?? 'null',
        webDescription: web.borderColor?.toString() ?? 'null',
      ),
    // Same predicate on the width itself: `null` vs `0.0` is the same
    // "no border" said two ways, and `_withinTolerance` short-circuits
    // a null pair to `null == 0.0`, which is false.
    if (borderIsPainted)
      _comparePx(
        'borderWidthPx',
        flutter.borderWidthPx,
        web.borderWidthPx,
        expected?.borderWidthPx,
      )
    else
      FieldDivergence(
        field: 'borderWidthPx',
        matches: true,
        flutterDescription: flutter.borderWidthPx?.toString() ?? 'null',
        webDescription: web.borderWidthPx?.toString() ?? 'null',
      ),
    _compareFourSidePx(
      'borderRadiusPx',
      flutter.borderRadiusPx,
      web.borderRadiusPx,
      expected?.borderRadiusPx,
    ),
    _compareFourSidePx(
      'paddingPx',
      // The normalized inset is already a measurement. A border does
      // not establish which resolver/layout path produced it, or recover
      // authored padding after alignment and constraint clamping. Keep
      // the captured difference visible even when pixels happen to match.
      flutter.paddingPx,
      web.paddingPx,
      expected?.paddingPx,
    ),
    if (outlineIsPainted)
      _comparePx(
        'outlineWidthPx',
        flutter.outlineWidthPx,
        web.outlineWidthPx,
        expected?.outlineWidthPx,
      )
    else
      // Kept in the roster for the same reason as the border above — the
      // report still shows what each side measured.
      FieldDivergence(
        field: 'outlineWidthPx',
        matches: true,
        flutterDescription: flutter.outlineWidthPx?.toString() ?? 'null',
        webDescription: web.outlineWidthPx?.toString() ?? 'null',
      ),
    if (outlineIsPainted)
      _comparePx(
        'outlineOffsetPx',
        flutter.outlineOffsetPx,
        web.outlineOffsetPx,
        expected?.outlineOffsetPx,
      )
    else
      // An offset only positions an outline that exists.
      FieldDivergence(
        field: 'outlineOffsetPx',
        matches: true,
        flutterDescription: flutter.outlineOffsetPx?.toString() ?? 'null',
        webDescription: web.outlineOffsetPx?.toString() ?? 'null',
      ),
    _compareBoxShadow(
      'boxShadow',
      flutter.boxShadow,
      web.boxShadow,
      expected?.boxShadow,
    ),
    _compareAlpha('opacity', flutter.opacity, web.opacity, expected?.opacity),
    // Geometry last — the two fields that say how big the box came out
    // rather than how it was painted. A size token one platform honours
    // exactly and the other treats as a floor renders two different
    // boxes while every painted field above still matches, which is why
    // the gate could not see it before.
    _comparePx('widthPx', flutter.widthPx, web.widthPx, expected?.widthPx),
    _comparePx('heightPx', flutter.heightPx, web.heightPx, expected?.heightPx),
  ];

  final requestedNames = {for (final field in requestedFields) field.name};
  final comparedNames = {for (final field in fields) field.field};
  if (!comparedNames.containsAll(requestedNames)) {
    final unsupported = requestedNames.difference(comparedNames);
    throw FormatException('Unsupported property fields: $unsupported');
  }

  return PropertyDiffResult(
    key: flutter.key,
    probeRole: flutter.probeRole,
    fields: [
      for (final field in fields)
        if (requestedNames.contains(field.field)) field,
    ],
  );
}

bool _withinTolerance(double? a, double? b, double tolerance) {
  if (a == null || b == null) return a == b;
  return (a - b).abs() <= tolerance;
}

TokenDivergence _tokenDivergence({
  required bool flutterMatchesExpected,
  required bool webMatchesExpected,
}) {
  if (flutterMatchesExpected && webMatchesExpected) {
    return .neitherDiverges;
  }
  if (!flutterMatchesExpected && webMatchesExpected) {
    return .flutterDiverges;
  }
  if (flutterMatchesExpected && !webMatchesExpected) {
    return .webDiverges;
  }
  return .bothDiverge;
}

FieldDivergence _compareNullable<T>(
  String field,
  T? flutterValue,
  T? webValue,
  T? expectedValue, {
  required bool Function(T a, T b) equals,
  required String Function(T value) describe,
}) {
  final matches = flutterValue == null || webValue == null
      ? flutterValue == webValue
      : equals(flutterValue, webValue);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    final flutterOk =
        flutterValue != null && equals(flutterValue, expectedValue);
    final webOk = webValue != null && equals(webValue, expectedValue);
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: flutterOk,
      webMatchesExpected: webOk,
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: flutterValue == null ? 'null' : describe(flutterValue),
    webDescription: webValue == null ? 'null' : describe(webValue),
    tokenDescription: expectedValue == null ? null : describe(expectedValue),
    tokenDivergence: tokenDivergence,
  );
}

FieldDivergence _comparePx(
  String field,
  double? flutterValue,
  double? webValue,
  double? expectedValue,
) {
  final matches = _withinTolerance(flutterValue, webValue, kPxTolerance);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: _withinTolerance(
        flutterValue,
        expectedValue,
        kPxTolerance,
      ),
      webMatchesExpected: _withinTolerance(
        webValue,
        expectedValue,
        kPxTolerance,
      ),
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: flutterValue?.toString() ?? 'null',
    webDescription: webValue?.toString() ?? 'null',
    tokenDescription: expectedValue?.toString(),
    tokenDivergence: tokenDivergence,
  );
}

FieldDivergence _compareAlpha(
  String field,
  double? flutterValue,
  double? webValue,
  double? expectedValue,
) {
  final matches = _withinTolerance(flutterValue, webValue, kAlphaTolerance);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: _withinTolerance(
        flutterValue,
        expectedValue,
        kAlphaTolerance,
      ),
      webMatchesExpected: _withinTolerance(
        webValue,
        expectedValue,
        kAlphaTolerance,
      ),
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: flutterValue?.toString() ?? 'null',
    webDescription: webValue?.toString() ?? 'null',
    tokenDescription: expectedValue?.toString(),
    tokenDivergence: tokenDivergence,
  );
}

/// A colour nobody can see: absent, or fully transparent.
///
/// The two platforms spell "no fill" differently. Flutter reports `null`
/// when its decoration has no colour; Chrome computes
/// `rgba(0, 0, 0, 0)` for the same nothing, because every element has a
/// `background-color` whether or not one is painted. Neither reaches a
/// pixel, so holding one against the other reports a difference the eye
/// cannot find — the same judgement the border gate above already makes,
/// applied to the value itself rather than to a width beside it.
bool _colorIsInvisible(NormalizedColor? c) => c == null || c.a == 0;

bool _colorWithinTolerance(NormalizedColor? a, NormalizedColor? b) {
  if (_colorIsInvisible(a) && _colorIsInvisible(b)) return true;
  if (a == null || b == null) return a == b;
  return (a.r - b.r).abs() <= kColorChannelTolerance &&
      (a.g - b.g).abs() <= kColorChannelTolerance &&
      (a.b - b.b).abs() <= kColorChannelTolerance &&
      _withinTolerance(a.a, b.a, kAlphaTolerance);
}

FieldDivergence _compareColor(
  String field,
  NormalizedColor? flutterValue,
  NormalizedColor? webValue,
  NormalizedColor? expectedValue,
) {
  final matches = _colorWithinTolerance(flutterValue, webValue);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: _colorWithinTolerance(
        flutterValue,
        expectedValue,
      ),
      webMatchesExpected: _colorWithinTolerance(webValue, expectedValue),
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: flutterValue?.toString() ?? 'null',
    webDescription: webValue?.toString() ?? 'null',
    tokenDescription: expectedValue?.toString(),
    tokenDivergence: tokenDivergence,
  );
}

/// An inset that moves nothing: absent, or zero on all four sides.
bool _fourSideIsZero(FourSidePx? v) =>
    v == null || (v.a == 0 && v.b == 0 && v.c == 0 && v.d == 0);

bool _fourSideWithinTolerance(FourSidePx? a, FourSidePx? b) {
  if (_fourSideIsZero(a) && _fourSideIsZero(b)) return true;
  if (a == null || b == null) return a == b;
  return (a.a - b.a).abs() <= kPxTolerance &&
      (a.b - b.b).abs() <= kPxTolerance &&
      (a.c - b.c).abs() <= kPxTolerance &&
      (a.d - b.d).abs() <= kPxTolerance;
}

FieldDivergence _compareFourSidePx(
  String field,
  FourSidePx? flutterValue,
  FourSidePx? webValue,
  FourSidePx? expectedValue,
) {
  final matches = _fourSideWithinTolerance(flutterValue, webValue);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: _fourSideWithinTolerance(
        flutterValue,
        expectedValue,
      ),
      webMatchesExpected: _fourSideWithinTolerance(webValue, expectedValue),
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: flutterValue?.toString() ?? 'null',
    webDescription: webValue?.toString() ?? 'null',
    tokenDescription: expectedValue?.toString(),
    tokenDivergence: tokenDivergence,
  );
}

/// A shadow nobody draws: absent, or an empty layer list.
bool _shadowIsAbsent(List<BoxShadowLayer>? s) => s == null || s.isEmpty;

bool _boxShadowWithinTolerance(
  List<BoxShadowLayer>? a,
  List<BoxShadowLayer>? b,
) {
  if (identical(a, b)) return true;
  // `null` and `[]` are the same nothing said twice: Flutter omits the
  // field when its decoration carries no shadow, the Web probe reports
  // `box-shadow: none` as an empty layer list.
  if (_shadowIsAbsent(a) && _shadowIsAbsent(b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final layerA = a[i];
    final layerB = b[i];
    if (layerA.inset != layerB.inset || layerA.blurStyle != layerB.blurStyle) {
      return false;
    }
    final geometryMatches =
        (layerA.offsetX - layerB.offsetX).abs() <= kPxTolerance &&
        (layerA.offsetY - layerB.offsetY).abs() <= kPxTolerance &&
        (layerA.blur - layerB.blur).abs() <= kPxTolerance &&
        (layerA.spread - layerB.spread).abs() <= kPxTolerance;
    if (!geometryMatches ||
        !_colorWithinTolerance(layerA.color, layerB.color)) {
      return false;
    }
  }
  return true;
}

FieldDivergence _compareBoxShadow(
  String field,
  List<BoxShadowLayer>? flutterValue,
  List<BoxShadowLayer>? webValue,
  List<BoxShadowLayer>? expectedValue,
) {
  final matches = _boxShadowWithinTolerance(flutterValue, webValue);

  var tokenDivergence = TokenDivergence.notChecked;
  if (expectedValue != null) {
    tokenDivergence = _tokenDivergence(
      flutterMatchesExpected: _boxShadowWithinTolerance(
        flutterValue,
        expectedValue,
      ),
      webMatchesExpected: _boxShadowWithinTolerance(webValue, expectedValue),
    );
  }

  return FieldDivergence(
    field: field,
    matches: matches,
    flutterDescription: _describeShadow(flutterValue),
    webDescription: _describeShadow(webValue),
    tokenDescription: expectedValue == null
        ? null
        : _describeShadow(expectedValue),
    tokenDivergence: tokenDivergence,
  );
}

String _describeShadow(List<BoxShadowLayer>? layers) {
  if (layers == null) return 'null';
  if (layers.isEmpty) return 'none';
  return '${layers.length} layer(s)';
}
