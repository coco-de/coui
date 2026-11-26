import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';
import '../../src/normalize/css_value_parsers.dart';
import '../../src/normalize/web_property_normalizer.dart';

Map<String, Object?> rawOutline({String? color, String? style = 'solid'}) => {
  'backgroundColor': 'rgb(12, 34, 56)',
  'borderTopColor': 'rgb(78, 90, 12)',
  'borderTopWidth': '1px',
  'borderTopLeftRadius': '8px',
  'borderTopRightRadius': '8px',
  'borderBottomRightRadius': '8px',
  'borderBottomLeftRadius': '8px',
  'paddingTop': '10px',
  'paddingRight': '11px',
  'paddingBottom': '12px',
  'paddingLeft': '13px',
  'outlineWidth': '3px',
  'outlineOffset': '2px',
  'outlineStyle': ?style,
  'outlineColor': ?color,
  'boxShadow': 'none',
  'opacity': '1',
};

void main() {
  group('exact raw alpha', () {
    for (final color in [
      'transparent',
      'rgba(12, 34, 56, 0)',
      'color(srgb 0.1 0.2 0.3 / 0)',
    ]) {
      test('$color is known transparent before rounding', () {
        expect(cssColorIsFullyTransparent(color), isTrue);
      });
    }

    for (final color in [
      'rgb(12, 34, 56)',
      'color(srgb 0.1 0.2 0.3)',
      'rgba(12, 34, 56, 0.0004)',
      'color(srgb 0.1 0.2 0.3 / 0.0004)',
      'color(srgb 1.00000e-7 0.2 0.3 / 1.00000e-7)',
    ]) {
      test('$color is retained as paint', () {
        expect(cssColorIsFullyTransparent(color), isFalse);
      });
    }

    test('an unsupported colour is not silently considered absent', () {
      expect(
        () => cssColorIsFullyTransparent('unknown'),
        throwsFormatException,
      );
    });
  });

  group('painted shadow layers', () {
    test('omits exact transparent layers of arbitrary geometry and tint', () {
      expect(
        parseCssBoxShadow(
          'rgba(12, 34, 56, 0) 7px 9px 24px 4px, '
          'color(srgb 1 0.5 0.25 / 0) 2px 3px 4px -1px inset',
        ),
        isEmpty,
      );
    });

    test(
      'retains faint positive alpha even if normalized alpha rounds to zero',
      () {
        for (final color in [
          'rgba(12, 34, 56, 0.0004)',
          'color(srgb 0.1 0.2 0.3 / 0.0004)',
          'color(srgb 1.00000e-7 0.2 0.3 / 1.00000e-7)',
        ]) {
          final layers = parseCssBoxShadow('$color 0px 4px 6px 2px');
          expect(layers, hasLength(1));
          expect(layers.single.color.a, 0);
        }
      },
    );

    test(
      'preserves visible layer order and inset on either side of lengths',
      () {
        final layers = parseCssBoxShadow(
          'rgba(0, 0, 0, 0.125) 1px 2px 3px 4px, '
          'rgba(99, 88, 77, 0) 10px 11px 12px 13px, '
          'inset color(srgb 1 0.5 0.25 / 0.25) 5px 6px 7px -1px',
        );
        expect(layers.map((layer) => layer.offsetX), [1, 5]);
        expect(layers.map((layer) => layer.inset), [false, true]);
        expect(layers.map((layer) => layer.blurStyle), ['normal', 'normal']);
        expect(
          parseCssBoxShadow(
            'rgba(0, 0, 0, 0.125) 1px 2px 3px 4px inset',
          ).single.inset,
          isTrue,
        );
      },
    );

    test(
      'invalid zero-alpha geometry still reports malformed capture data',
      () {
        expect(
          () => parseCssBoxShadow('rgba(12, 34, 56, 0) 1px 2px 3px'),
          throwsFormatException,
        );
      },
    );
  });

  group('outline visibility without rewriting other measured fields', () {
    for (final color in [
      'transparent',
      'rgba(12, 34, 56, 0)',
      'color(srgb 1 0.5 0.25 / 0)',
    ]) {
      test('$color has no painted outline', () {
        final snapshot = normalizeWebSnapshot(
          rawOutline(color: color),
          key: 'paint',
          probeRole: 'root',
        );
        expect(snapshot.outlineWidthPx, 0);
        expect(snapshot.outlineOffsetPx, 2);
        expect(snapshot.borderWidthPx, 1);
        expect(snapshot.paddingPx, const FourSidePx(10, 11, 12, 13));
        expect(snapshot.borderRadiusPx, const FourSidePx(8, 8, 8, 8));
        expect(snapshot.backgroundColor, parseCssColor('rgb(12, 34, 56)'));
        expect(snapshot.borderColor, parseCssColor('rgb(78, 90, 12)'));
      });
    }

    test('faint positive raw alpha retains outline width and offset', () {
      for (final color in [
        'rgba(12, 34, 56, 0.0004)',
        'color(srgb 1 0.5 0.25 / 0.0004)',
      ]) {
        final snapshot = normalizeWebSnapshot(
          rawOutline(color: color),
          key: 'paint',
          probeRole: 'root',
        );
        expect(snapshot.outlineWidthPx, 3);
        expect(snapshot.outlineOffsetPx, 2);
      }
    });

    test('legacy missing colour preserves prior style-only interpretation', () {
      for (final style in ['solid', null]) {
        final snapshot = normalizeWebSnapshot(
          rawOutline(style: style),
          key: 'paint',
          probeRole: 'root',
        );
        expect(snapshot.outlineWidthPx, 3);
        expect(snapshot.outlineOffsetPx, 2);
      }
      final none = normalizeWebSnapshot(
        rawOutline(style: 'none'),
        key: 'paint',
        probeRole: 'root',
      );
      expect(none.outlineWidthPx, 0);
      expect(none.outlineOffsetPx, 2);
    });

    test(
      'transparent and faint outlines remain distinguishable at comparison',
      () {
        final absent = normalizeWebSnapshot(
          rawOutline(color: 'rgba(12, 34, 56, 0)'),
          key: 'paint',
          probeRole: 'root',
        );
        final faint = normalizeWebSnapshot(
          rawOutline(color: 'rgba(12, 34, 56, 0.0004)'),
          key: 'paint',
          probeRole: 'root',
        );
        const native = PropertySnapshot(
          key: 'paint',
          platform: 'flutter',
          probeRole: 'root',
        );
        bool outlineMatches(PropertySnapshot web) => comparePropertySnapshots(
          flutter: native,
          web: web,
        ).fields.firstWhere((field) => field.field == 'outlineWidthPx').matches;
        expect(outlineMatches(absent), isTrue);
        expect(outlineMatches(faint), isFalse);
      },
    );
  });
}
