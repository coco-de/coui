// #3606 — Normalizer, Web half. Converts the raw `getComputedStyle()`
// strings `computed_style_probe.dart` captures (#3605) into the common
// `PropertySnapshot` schema (`.bmad/architecture-*.md` Component ④).
import '../model/property_snapshot.dart';
import 'css_value_parsers.dart';

/// Normalizes one role's raw `captureComputedStyle(...)` output (a
/// `Map<String, Object?>` of browser strings, exactly
/// `computed_style_probe.dart`'s `_kComputedStyleJs` field set) into a
/// [PropertySnapshot].
///
/// [raw] is nullable-per-field but never itself null here — a `null` role
/// result (the selector matched nothing) is a decision for the caller
/// (whoever reads `<key>.web.json`'s `byRole` map), not this function;
/// normalizing a role that wasn't captured has no meaning.
PropertySnapshot normalizeWebSnapshot(
  Map<String, Object?> raw, {
  required String key,
  required String probeRole,
}) {
  String rawString(String field) => raw[field]! as String;

  // The six text fields arrive as `null` when the probe found nothing
  // under the root that paints text (`computed_style_probe.dart`'s
  // `findTextSource`). Absence of text is not a value to parse — it stays
  // `null`, which is what the Flutter side says for the same root, so
  // "no text here" reads as agreement rather than as six divergent fields.
  T? parseText<T>(String field, T? Function(String raw) parse) {
    final value = raw[field];
    return value == null ? null : parse(value as String);
  }

  // Geometry arrives as a JS number from `getBoundingClientRect()`, not
  // as a CSS string — there is nothing to parse a unit off, and running
  // it through `parseCssPx` would only look consistent while failing on
  // every value. Nullable because a snapshot captured before this field
  // existed has no entry for it.
  double? rawPx(String field) {
    final value = raw[field];
    return value is num ? roundPx(value.toDouble()) : null;
  }

  // Unlike the Flutter side (see `flutter_property_normalizer.dart`'s
  // `normalizeFlutterLineHeightPx`), lineHeightPx here needs no fontSizePx
  // input — Chrome already resolves `line-height` to an absolute px used
  // value before `getComputedStyle()` ever returns it.
  final borderWidthPx = parseCssPx(rawString('borderTopWidth'));
  // A representative side, matching `PropertySnapshot.borderColor`'s single
  // scalar (see that field's doc comment) — `borderTopWidth`/`
  // borderTopColor` are the side this Normalizer treats as canonical.
  // Divergent per-side values (a component with an intentionally asymmetric
  // border) are outside what this schema can express; Comparator (#3607)
  // only ever sees this one side.
  final borderColor = parseCssColor(rawString('borderTopColor'));
  // outlineColor is an optional addition to the internal raw-capture
  // protocol. Older captures without it retain the previous style-only
  // interpretation; they do not establish a transparent solid outline.
  final outlineColor = raw['outlineColor'] as String?;
  final outlineIsAbsent =
      raw['outlineStyle'] == 'none' ||
      (outlineColor != null && cssColorIsFullyTransparent(outlineColor));

  return PropertySnapshot(
    key: key,
    platform: 'web',
    probeRole: probeRole,
    // Chain-first extraction, not passthrough — see
    // css_value_parsers.dart's parseCssFontFamily for why the raw
    // getComputedStyle() fallback chain (`'Pretendard, system-ui,
    // sans-serif'`) isn't directly comparable to Flutter's single-name
    // fontFamily (#3659).
    fontFamily: parseText('fontFamily', parseCssFontFamily),
    fontWeight: parseText('fontWeight', parseCssFontWeight),
    fontSizePx: parseText('fontSize', parseCssPx),
    lineHeightPx: parseText('lineHeight', parseCssPxOrNormal),
    // CSS Text: normal computes to zero, though getComputedStyle returns
    // the legacy keyword. Line-height normal remains font-dependent.
    letterSpacingPx: parseText(
      'letterSpacing',
      (raw) => raw.trim() == 'normal' ? 0.0 : parseCssPx(raw),
    ),
    color: parseText('color', parseCssColor),
    backgroundColor: parseCssColor(rawString('backgroundColor')),
    borderColor: borderColor,
    borderWidthPx: borderWidthPx,
    borderRadiusPx: FourSidePx(
      parseCssPx(rawString('borderTopLeftRadius')),
      parseCssPx(rawString('borderTopRightRadius')),
      parseCssPx(rawString('borderBottomRightRadius')),
      parseCssPx(rawString('borderBottomLeftRadius')),
    ),
    paddingPx: FourSidePx(
      parseCssPx(rawString('paddingTop')),
      parseCssPx(rawString('paddingRight')),
      parseCssPx(rawString('paddingBottom')),
      parseCssPx(rawString('paddingLeft')),
    ),
    // An outline whose style is `none` or raw alpha is exactly zero paints
    // nothing, whatever its width
    // says. Chrome computes `outline-width` to 3px on every element by
    // default (`medium`), so the raw number here is 3 for components that
    // draw no outline at all — the field measured a width nobody sees.
    //
    // Zeroed rather than nulled: the outline WAS measured, and the honest
    // answer is that its painted width is zero. `null` would mean the
    // opposite thing — that nothing was measured — which is the
    // distinction `flutter_property_snapshot.dart` exists to keep.
    //
    // Web captures are normalized at compare time. Missing outlineColor
    // retains the previous style-only interpretation; if outlineStyle is
    // also missing, the older capture keeps its raw width. Missing data
    // does not establish zero alpha. Keep the measured offset unchanged:
    // the comparator already treats an unpainted outline's width/offset
    // pair as absent, rather than comparing an offset that paints nothing.
    outlineWidthPx: outlineIsAbsent ? 0 : parseCssPx(rawString('outlineWidth')),
    outlineOffsetPx: parseCssPx(rawString('outlineOffset')),
    boxShadow: parseCssBoxShadow(rawString('boxShadow')),
    // roundAlpha, not a bare parse — opacity shares color.a's 0.0..1.0
    // domain and the same float-noise concern roundAlpha's own doc comment
    // exists for. Every other field here goes through a rounding helper
    // (parseCssPx/parseCssColor both call one internally); opacity is the
    // one raw scalar with no wrapper of its own, so it has to opt in
    // explicitly instead of getting rounding for free.
    opacity: roundAlpha(double.parse(rawString('opacity'))),
    widthPx: rawPx('widthPx'),
    heightPx: rawPx('heightPx'),
  );
}
