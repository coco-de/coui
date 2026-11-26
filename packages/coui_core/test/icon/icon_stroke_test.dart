// #5377 — Lucide icons draw max(1.25, tokenSize / 16) token px of stroke.
// CoreIconStroke is the one place that rule lives: the Flutter icon resolver
// and the Web inline <svg> both rewrite the glyph body through it, and read
// the same vector table this file checks the helper against.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The vector table shared with the Flutter and Web icon tests.
const String kIconStrokeVectorsPath = 'test/fixtures/icon_stroke_vectors.json';

/// A one-path Lucide-shaped body: the glyphs ship `stroke-width="2"`.
const String _kBody =
    '<path fill="none" stroke="currentColor" stroke-linecap="round" '
    'stroke-linejoin="round" stroke-width="2" d="M5 12h14"/>';

void main() {
  final vectors = _loadVectors();

  group('vector table', () {
    test('covers the whole size ladder and the sizes off it', () {
      final sizes = vectors.cases.map((c) => c.tokenSize).toSet();
      expect(
        sizes,
        containsAll(<double>[
          8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 48, //
        ]),
      );
      expect(vectors.viewBox, 24);
    });

    for (final c in vectors.cases) {
      group('token ${c.tokenSize}', () {
        test('renderedWidth', () {
          expect(CoreIconStroke.renderedWidth(c.tokenSize), c.renderedWidth);
        });

        test('svgStrokeWidth', () {
          expect(
            CoreIconStroke.svgStrokeWidth(
              c.tokenSize,
              viewBox: vectors.viewBox,
            ),
            closeTo(c.svgValue, 1e-9),
          );
        });

        test('formatNumber writes the attribute string', () {
          expect(CoreIconStroke.formatNumber(c.svgValue), c.svgString);
        });

        test('apply rewrites the authored stroke to the attribute string', () {
          expect(
            CoreIconStroke.apply(
              prefix: CoreIconStroke.lucidePrefix,
              body: _kBody,
              tokenSize: c.tokenSize,
              viewBox: vectors.viewBox,
            ),
            _kBody.replaceAll(
              'stroke-width="2"',
              'stroke-width="${c.svgString}"',
            ),
          );
        });
      });
    }
  });

  group('the rule', () {
    test('holds at the floor up to 20 and follows the size from 24', () {
      expect(CoreIconStroke.renderedWidth(10), 1.25);
      expect(CoreIconStroke.renderedWidth(16), 1.25);
      expect(CoreIconStroke.renderedWidth(20), 1.25);
      expect(CoreIconStroke.renderedWidth(24), 1.5);
      expect(CoreIconStroke.renderedWidth(28), 1.75);
      expect(CoreIconStroke.renderedWidth(32), 2);
    });

    test('sizes off the ladder use the same formula', () {
      expect(CoreIconStroke.renderedWidth(8), 1.25);
      expect(CoreIconStroke.renderedWidth(22), 1.375);
    });

    test('is never below the floor and never shrinks as the size grows', () {
      var previous = 0.0;
      for (var size = 1.0; size <= 96; size += 0.5) {
        final width = CoreIconStroke.renderedWidth(size);
        expect(width, greaterThanOrEqualTo(CoreIconStroke.minRenderedWidth));
        expect(width, greaterThanOrEqualTo(previous), reason: 'size $size');
        previous = width;
      }
    });

    test('the SVG attribute is max(1.5, 30 / size) on a 24 viewBox', () {
      for (var size = 4.0; size <= 96; size += 1) {
        expect(
          CoreIconStroke.svgStrokeWidth(size, viewBox: 24),
          closeTo(math.max(1.5, 30 / size), 1e-9),
          reason: 'size $size',
        );
      }
    });

    test('the rendered stroke is the attribute scaled to the drawn size', () {
      // viewBox units → token px is size / viewBox.
      for (final size in <double>[10, 16, 20, 24, 32]) {
        final attribute = CoreIconStroke.svgStrokeWidth(size, viewBox: 24);
        expect(
          attribute * size / 24,
          closeTo(CoreIconStroke.renderedWidth(size), 1e-9),
        );
      }
    });

    test('lucidePrefix is the prefix LucideIcons carries', () {
      expect(LucideIcons.check.prefix, CoreIconStroke.lucidePrefix);
    });
  });

  group('apply leaves the body alone', () {
    test('for any prefix but lucide', () {
      for (final prefix in <String>[
        'heroicons',
        'heroicons-outline',
        'radix-icons',
        'bootstrap-icons',
        'Lucide',
        'lucide-lab',
        '',
      ]) {
        expect(
          CoreIconStroke.apply(
            prefix: prefix,
            body: _kBody,
            tokenSize: 16,
            viewBox: 24,
          ),
          _kBody,
          reason: 'prefix "$prefix"',
        );
      }
    });

    test('when the body carries no stroke-width', () {
      const filled = '<path fill="currentColor" d="M0 0h24v24H0z"/>';
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: filled,
          tokenSize: 16,
          viewBox: 24,
        ),
        filled,
      );
    });

    test('when the stroke is not the authored 2', () {
      const other =
          '<path stroke="currentColor" stroke-width="1" d="M5 12h14"/> '
          '<path stroke="currentColor" stroke-width="2.5" d="M5 6h14"/> '
          '<path stroke="currentColor" stroke-width="20" d="M5 3h14"/>';
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: other,
          tokenSize: 16,
          viewBox: 24,
        ),
        other,
      );
    });

    test('for a size that is not finite and positive', () {
      for (final size in <double>[
        0,
        -1,
        -16,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          CoreIconStroke.apply(
            prefix: CoreIconStroke.lucidePrefix,
            body: _kBody,
            tokenSize: size,
            viewBox: 24,
          ),
          _kBody,
          reason: 'size $size',
        );
      }
    });

    test('for a viewBox that is not positive', () {
      for (final viewBox in <num>[0, -24, double.nan]) {
        expect(
          CoreIconStroke.apply(
            prefix: CoreIconStroke.lucidePrefix,
            body: _kBody,
            tokenSize: 16,
            viewBox: viewBox,
          ),
          _kBody,
          reason: 'viewBox $viewBox',
        );
      }
    });

    test('and returns the same instance when nothing changes', () {
      const body = '<path d="M5 12h14"/>';
      expect(
        identical(
          CoreIconStroke.apply(
            prefix: 'radix-icons',
            body: body,
            tokenSize: 16,
            viewBox: 24,
          ),
          body,
        ),
        isTrue,
      );
    });
  });

  group('apply rewrites every authored stroke', () {
    test('on each element of a multi-element body', () {
      const body =
          '<g fill="none" stroke="currentColor" stroke-width="2"> '
          '<circle cx="12" cy="12" r="1" stroke-width="2"/> '
          '<path stroke-width="2" d="M5 12h14"/> '
          '</g>';
      final result = CoreIconStroke.apply(
        prefix: CoreIconStroke.lucidePrefix,
        body: body,
        tokenSize: 16,
        viewBox: 24,
      );
      expect(result, isNot(contains('stroke-width="2"')));
      expect('stroke-width="1.875"'.allMatches(result), hasLength(3));
      expect(
        result,
        body.replaceAll('stroke-width="2"', 'stroke-width="1.875"'),
      );
    });

    test('with either quote style, keeping the quote it found', () {
      const body =
          "<path stroke-width='2' d='M5 12h14'/> "
          '<path stroke-width="2" d="M5 6h14"/>';
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: body,
          tokenSize: 24,
          viewBox: 24,
        ),
        "<path stroke-width='1.5' d='M5 12h14'/> "
        '<path stroke-width="1.5" d="M5 6h14"/>',
      );
    });

    test('but not an attribute that merely ends in stroke-width', () {
      const body = '<path data-stroke-width="2" stroke-width="2" d="M0 0"/>';
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: body,
          tokenSize: 24,
          viewBox: 24,
        ),
        '<path data-stroke-width="2" stroke-width="1.5" d="M0 0"/>',
      );
    });

    test('against a viewBox other than 24', () {
      // A 16-unit glyph at token 32: rendered 2 px over a 2x scale-up is 1.
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: _kBody,
          tokenSize: 32,
          viewBox: 16,
        ),
        _kBody.replaceAll('stroke-width="2"', 'stroke-width="1"'),
      );
      // The same glyph at token 16 holds the 1.25 floor over a 1x scale.
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: _kBody,
          tokenSize: 16,
          viewBox: 16,
        ),
        _kBody.replaceAll('stroke-width="2"', 'stroke-width="1.25"'),
      );
      // A 48-unit viewBox is drawn at half scale at token 24.
      expect(
        CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: _kBody,
          tokenSize: 24,
          viewBox: 48,
        ),
        _kBody.replaceAll('stroke-width="2"', 'stroke-width="3"'),
      );
    });
  });

  group('formatNumber', () {
    test('keeps at most four decimals and trims trailing zeros', () {
      expect(CoreIconStroke.formatNumber(1.5), '1.5');
      expect(CoreIconStroke.formatNumber(1.25), '1.25');
      expect(CoreIconStroke.formatNumber(1.875), '1.875');
      expect(CoreIconStroke.formatNumber(1.3636363636), '1.3636');
      expect(CoreIconStroke.formatNumber(2.142857142857143), '2.1429');
      expect(CoreIconStroke.formatNumber(1.6666666666666667), '1.6667');
    });

    test('writes a whole number without a point', () {
      expect(CoreIconStroke.formatNumber(3), '3');
      expect(CoreIconStroke.formatNumber(3), '3');
      expect(CoreIconStroke.formatNumber(0), '0');
      expect(CoreIconStroke.formatNumber(1.00001), '1');
    });

    test('absorbs the float noise a ratio leaves behind', () {
      expect(CoreIconStroke.formatNumber(1.5000000000000002), '1.5');
      expect(CoreIconStroke.formatNumber(1.4999999999999998), '1.5');
    });

    test('rounds half away from zero on the fourth decimal', () {
      expect(CoreIconStroke.formatNumber(0.00005), '0.0001');
      expect(CoreIconStroke.formatNumber(0.00004), '0');
      expect(CoreIconStroke.formatNumber(-0.00005), '-0.0001');
    });

    test('writes a value that has no attribute form as 0', () {
      expect(CoreIconStroke.formatNumber(double.nan), '0');
      expect(CoreIconStroke.formatNumber(double.infinity), '0');
    });
  });

  group('over the bundled Lucide set', () {
    final lucide = CoreBundledIcons.icons.entries
        .where((e) => e.key.startsWith('${CoreIconStroke.lucidePrefix}:'))
        .toList();

    test('the bundle carries Lucide glyphs with the authored stroke', () {
      expect(lucide, isNotEmpty);
      for (final MapEntry(key: id, value: data) in lucide) {
        expect(data.body, contains('stroke-width="2"'), reason: id);
        expect(data.width, 24, reason: id);
      }
    });

    test('no authored stroke survives at size 24, each becomes 1.5', () {
      for (final MapEntry(key: id, value: data) in lucide) {
        final result = CoreIconStroke.apply(
          prefix: CoreIconStroke.lucidePrefix,
          body: data.body,
          tokenSize: 24,
          viewBox: data.width,
        );
        expect(result, isNot(contains('stroke-width="2"')), reason: id);
        expect(
          'stroke-width="1.5"'.allMatches(result).length,
          'stroke-width="2"'.allMatches(data.body).length,
          reason: id,
        );
      }
    });

    test('only the stroke width differs, at every ladder size', () {
      for (final size in <double>[10, 12, 14, 16, 18, 20, 24, 28, 32]) {
        final value = CoreIconStroke.formatNumber(
          CoreIconStroke.svgStrokeWidth(size, viewBox: 24),
        );
        for (final MapEntry(key: id, value: data) in lucide) {
          expect(
            CoreIconStroke.apply(
              prefix: CoreIconStroke.lucidePrefix,
              body: data.body,
              tokenSize: size,
              viewBox: data.width,
            ),
            data.body.replaceAll(
              'stroke-width="2"',
              'stroke-width="$value"',
            ),
            reason: '$id @ $size',
          );
        }
      }
    });

    test('a prefix other than lucide leaves every bundled body untouched', () {
      for (final MapEntry(key: id, value: data) in lucide) {
        expect(
          CoreIconStroke.apply(
            prefix: 'heroicons',
            body: data.body,
            tokenSize: 16,
            viewBox: data.width,
          ),
          data.body,
          reason: id,
        );
      }
    });
  });
}

({double viewBox, List<_Vector> cases}) _loadVectors() {
  final doc =
      jsonDecode(File(kIconStrokeVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final cases = (doc['cases']! as List)
      .cast<Map<String, Object?>>()
      .map(
        (row) => _Vector(
          tokenSize: (row['tokenSize']! as num).toDouble(),
          renderedWidth: (row['renderedWidth']! as num).toDouble(),
          svgValue: (row['svgValue']! as num).toDouble(),
          svgString: row['svgString']! as String,
        ),
      )
      .toList();

  return (viewBox: (doc['viewBox']! as num).toDouble(), cases: cases);
}

class _Vector {
  const _Vector({
    required this.tokenSize,
    required this.renderedWidth,
    required this.svgValue,
    required this.svgString,
  });

  final double tokenSize;
  final double renderedWidth;
  final double svgValue;
  final String svgString;
}
