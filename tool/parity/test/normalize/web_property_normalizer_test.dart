import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';
import '../../src/normalize/web_property_normalizer.dart';

/// Shape matches `computed_style_probe.dart`'s `_kComputedStyleJs` field
/// set exactly — this is what a real `captureComputedStyle(...)` call
/// returns for a matched element, not a fixture invented independently of
/// it.
Map<String, Object?> _rawFixture({
  String fontFamily = 'Pretendard, system-ui, sans-serif',
  String fontWeight = '600',
  String fontSize = '16px',
  String lineHeight = '24px',
  String letterSpacing = 'normal',
  String color = 'rgb(29, 29, 31)',
  String backgroundColor = 'rgb(255, 255, 255)',
  String borderTopColor = 'rgb(0, 0, 0)',
  String borderTopWidth = '1px',
  String boxShadow = 'none',
  String opacity = '1',
}) => {
  'fontFamily': fontFamily,
  'fontWeight': fontWeight,
  'fontSize': fontSize,
  'lineHeight': lineHeight,
  'letterSpacing': letterSpacing,
  'color': color,
  'backgroundColor': backgroundColor,
  'borderTopColor': borderTopColor,
  'borderRightColor': 'rgb(0, 0, 0)',
  'borderBottomColor': 'rgb(0, 0, 0)',
  'borderLeftColor': 'rgb(0, 0, 0)',
  'borderTopWidth': borderTopWidth,
  'borderRightWidth': '1px',
  'borderBottomWidth': '1px',
  'borderLeftWidth': '1px',
  'borderTopLeftRadius': '8px',
  'borderTopRightRadius': '8px',
  'borderBottomRightRadius': '8px',
  'borderBottomLeftRadius': '8px',
  'paddingTop': '16px',
  'paddingRight': '12px',
  'paddingBottom': '16px',
  'paddingLeft': '12px',
  'outlineWidth': '2px',
  // A drawn outline by default — the `none` case is its own test below.
  'outlineStyle': 'solid',
  'outlineOffset': '2px',
  'boxShadow': boxShadow,
  'opacity': opacity,
};

void main() {
  group('normalizeWebSnapshot', () {
    test('carries key/platform/probeRole through unchanged', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'card-default-light-defaultStyle',
        probeRole: 'root',
      );
      expect(snapshot.key, 'card-default-light-defaultStyle');
      expect(snapshot.platform, 'web');
      expect(snapshot.probeRole, 'root');
    });

    test('parses text fields', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'k',
        probeRole: 'root',
      );
      // #3659 — the raw fallback chain reduces to just its first entry,
      // the only one comparable to Flutter's single-name fontFamily.
      expect(snapshot.fontFamily, 'Pretendard');
      expect(snapshot.fontWeight, 600);
      expect(snapshot.fontSizePx, 16.0);
      expect(snapshot.lineHeightPx, 24.0);
      // CSS Text defines normal letter spacing as a computed zero.
      expect(snapshot.letterSpacingPx, 0);
    });

    test('normal spacing is zero while normal line height stays unknown', () {
      final raw = _rawFixture();
      raw['lineHeight'] = 'normal';
      final snapshot = normalizeWebSnapshot(raw, key: 'k', probeRole: 'root');
      expect(snapshot.letterSpacingPx, 0);
      expect(snapshot.lineHeightPx, isNull);
    });

    test('null text fields stay null — absence of text is not a value', () {
      // The probe reports the six text fields as null when nothing under
      // the root paints text (`computed_style_probe.dart`). Parsing a null
      // would throw; inventing a value would report text that does not
      // exist. They pass through as null, which is what the Flutter side
      // says for the same root.
      final raw = Map<String, Object?>.from(_rawFixture());
      for (final field in const [
        'fontFamily',
        'fontWeight',
        'fontSize',
        'lineHeight',
        'letterSpacing',
        'color',
      ]) {
        raw[field] = null;
      }
      final snapshot = normalizeWebSnapshot(raw, key: 'k', probeRole: 'root');

      expect(snapshot.fontFamily, isNull);
      expect(snapshot.fontWeight, isNull);
      expect(snapshot.fontSizePx, isNull);
      expect(snapshot.lineHeightPx, isNull);
      expect(snapshot.letterSpacingPx, isNull);
      expect(snapshot.color, isNull);
      // The box half is untouched by the text half being absent.
      expect(snapshot.backgroundColor, isNotNull);
      expect(snapshot.paddingPx, isNotNull);
    });

    test('parses colors', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'k',
        probeRole: 'root',
      );
      expect(snapshot.color, NormalizedColor(r: 29, g: 29, b: 31, a: 1));
      expect(
        snapshot.backgroundColor,
        NormalizedColor(r: 255, g: 255, b: 255, a: 1),
      );
      expect(snapshot.borderColor, NormalizedColor(r: 0, g: 0, b: 0, a: 1));
    });

    test('parses the four-corner border radius in tl/tr/br/bl order', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'k',
        probeRole: 'root',
      );
      expect(
        snapshot.borderRadiusPx,
        const FourSidePx(8, 8, 8, 8),
      );
    });

    test('parses the four-side padding in t/r/b/l order', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'k',
        probeRole: 'root',
      );
      expect(snapshot.paddingPx, const FourSidePx(16, 12, 16, 12));
    });

    test('a declared box-shadow parses to a non-empty layer list', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(boxShadow: 'rgba(0, 0, 0, 0.1) 0px 4px 6px 2px'),
        key: 'k',
        probeRole: 'root',
      );
      expect(snapshot.boxShadow, hasLength(1));
    });

    test('boxShadow: none normalizes to an empty list, not null', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(),
        key: 'k',
        probeRole: 'root',
      );
      expect(snapshot.boxShadow, isNotNull);
      expect(snapshot.boxShadow, isEmpty);
    });

    test('parses opacity', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(opacity: '0.5'),
        key: 'k',
        probeRole: 'root',
      );
      expect(snapshot.opacity, 0.5);
    });

    // `outline-width` initialises to `medium`, which Chrome computes to
    // 3px on every element whether or not an outline is drawn. Reading the
    // width alone reported a 3px outline on every component at rest.
    test('an outline styled none has a painted width of zero', () {
      final raw = Map<String, Object?>.from(_rawFixture())
        ..['outlineWidth'] = '3px'
        ..['outlineStyle'] = 'none';
      final snapshot = normalizeWebSnapshot(raw, key: 'k', probeRole: 'root');

      // Zero, not null: the outline WAS measured, and what it paints is
      // nothing. `null` would say nothing was measured, which is a
      // different fact and the one the Flutter side reserves it for.
      expect(snapshot.outlineWidthPx, 0);
    });

    test('a capture predating outlineStyle still normalizes', () {
      // Web captures are normalized at COMPARE time, so every stored
      // capture from before this field existed flows through here. A hard
      // read would have thrown on all of them at once.
      final raw = Map<String, Object?>.from(_rawFixture())
        ..['outlineWidth'] = '3px'
        ..remove('outlineStyle');
      final snapshot = normalizeWebSnapshot(raw, key: 'k', probeRole: 'root');

      // The raw width — what such a capture was compared against before.
      // A missing style is "this capture predates the question", not "no
      // outline is drawn".
      expect(snapshot.outlineWidthPx, 3);
    });

    test('a drawn outline keeps its width', () {
      final raw = Map<String, Object?>.from(_rawFixture())
        ..['outlineWidth'] = '3px'
        ..['outlineStyle'] = 'solid';
      final snapshot = normalizeWebSnapshot(raw, key: 'k', probeRole: 'root');

      expect(snapshot.outlineWidthPx, 3);
    });

    test('round-trips through toJson/fromJson', () {
      final snapshot = normalizeWebSnapshot(
        _rawFixture(boxShadow: 'rgba(0, 0, 0, 0.1) 0px 4px 6px 2px'),
        key: 'card-default-light-defaultStyle',
        probeRole: 'root',
      );
      final decoded = PropertySnapshot.fromJson(snapshot.toJson());
      expect(decoded, snapshot);
    });
  });
}
