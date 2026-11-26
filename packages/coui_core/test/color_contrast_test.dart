import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _black = CoreColor(0xFF000000);
const _white = CoreColor(0xFFFFFFFF);
const _grey777 = CoreColor(0xFF777777);

/// Tolerance for ratios quoted to two decimals in the WCAG literature.
const _kQuoted = 0.005;

void main() {
  group('CoreContrast.relativeLuminance', () {
    test('black is 0 and white is 1', () {
      expect(CoreContrast.relativeLuminance(_black), 0);
      expect(CoreContrast.relativeLuminance(_white), closeTo(1, 1e-12));
    });

    test('weights green over red over blue (BT.709)', () {
      final red = CoreContrast.relativeLuminance(const CoreColor(0xFFFF0000));
      final green = CoreContrast.relativeLuminance(
        const CoreColor(0xFF00FF00),
      );
      final blue = CoreContrast.relativeLuminance(const CoreColor(0xFF0000FF));

      expect(red, closeTo(0.2126, 1e-12));
      expect(green, closeTo(0.7152, 1e-12));
      expect(blue, closeTo(0.0722, 1e-12));
    });

    test('decodes sRGB through the shared transfer function', () {
      // #777777 → 119/255 → linear 0.18447.
      expect(
        CoreContrast.relativeLuminance(_grey777),
        closeTo(CoreColorConversion.srgbToLinear(119 / 255), 1e-12),
      );
    });

    test('rejects a translucent colour', () {
      expect(
        () => CoreContrast.relativeLuminance(const CoreColor(0x80000000)),
        throwsArgumentError,
      );
    });

    test('rejects an unresolved token', () {
      expect(
        () => CoreContrast.relativeLuminance(
          const CoreColor.token(CoreColors.primary),
        ),
        throwsStateError,
      );
    });
  });

  group('CoreContrast.ratio', () {
    test('black on white is 21:1', () {
      expect(CoreContrast.ratio(_black, _white), CoreContrast.maxRatio);
    });

    test('identical colours are 1:1', () {
      expect(CoreContrast.ratio(_white, _white), CoreContrast.minRatio);
      expect(CoreContrast.ratio(_grey777, _grey777), CoreContrast.minRatio);
    });

    test('#777777 on white is 4.48:1 — just under AA', () {
      expect(CoreContrast.ratio(_grey777, _white), closeTo(4.48, _kQuoted));
    });

    test('#767676 on white is 4.54:1 — the lightest grey that passes AA', () {
      expect(
        CoreContrast.ratio(const CoreColor(0xFF767676), _white),
        closeTo(4.54, _kQuoted),
      );
    });

    test('is symmetric for opaque colours', () {
      const navy = CoreColor(0xFF1E3A8A);
      expect(
        CoreContrast.ratio(navy, _white),
        CoreContrast.ratio(_white, navy),
      );
    });

    test(
      'measures a translucent foreground composited over the background',
      () {
        // 50% black over white → #808080.
        const halfBlack = CoreColor(0x80000000);
        expect(
          CoreContrast.ratio(halfBlack, _white),
          CoreContrast.ratio(const CoreColor(0xFF7F7F7F), _white),
        );
      },
    );

    test('rejects a translucent background', () {
      expect(
        () => CoreContrast.ratio(_black, const CoreColor(0x80FFFFFF)),
        throwsArgumentError,
      );
    });
  });

  group('CoreContrast.compositeOver', () {
    test('returns an opaque foreground unchanged', () {
      expect(CoreContrast.compositeOver(_grey777, _white), _grey777);
    });

    test('blends source-over and rounds to 8-bit channels', () {
      // 25% red over white: 255·0.25 + 255·0.75 = 255 red,
      // 0·0.25 + 255·0.75 = 191.25 → 191 green / blue.
      expect(
        CoreContrast.compositeOver(const CoreColor(0x40FF0000), _white),
        const CoreColor(0xFFFFBFBF),
      );
    });

    test('fully transparent shows the background', () {
      expect(CoreContrast.compositeOver(CoreColor.transparent, _white), _white);
    });
  });

  group('CoreContrastLevel', () {
    test('states the WCAG 2.x minimums', () {
      expect(CoreContrastLevel.aaNormalText.minimumRatio, 4.5);
      expect(CoreContrastLevel.aaLargeText.minimumRatio, 3);
      expect(CoreContrastLevel.aaaNormalText.minimumRatio, 7);
      expect(CoreContrastLevel.aaaLargeText.minimumRatio, 4.5);
      expect(CoreContrastLevel.nonText.minimumRatio, 3);
    });

    test('judges unrounded — 4.48:1 fails AA normal, passes AA large', () {
      expect(
        CoreContrast.meets(_grey777, _white, .aaNormalText),
        isFalse,
      );
      expect(CoreContrast.meets(_grey777, _white, .aaLargeText), isTrue);
      expect(CoreContrast.meets(_grey777, _white, .nonText), isTrue);
      expect(CoreContrast.meets(_grey777, _white, .aaaNormalText), isFalse);
    });

    test('a ratio exactly at the minimum passes', () {
      expect(CoreContrastLevel.aaNormalText.isMetBy(4.5), isTrue);
      expect(CoreContrastLevel.aaNormalText.isMetBy(4.4999), isFalse);
    });
  });

  group('CoreContrastCheck / CoreContrastReport', () {
    const failing = CoreContrastCheck(
      foregroundName: 'grey',
      foreground: _grey777,
      backgroundName: 'white',
      background: _white,
      level: .aaNormalText,
    );
    const passing = CoreContrastCheck(
      foregroundName: 'black',
      foreground: _black,
      backgroundName: 'white',
      background: _white,
      level: .aaNormalText,
    );

    test('a check reports its ratio and verdict', () {
      expect(failing.ratio, closeTo(4.48, _kQuoted));
      expect(failing.passes, isFalse);
      expect(passing.passes, isTrue);
      expect(
        failing.toString(),
        'grey on white 4.48:1 ✗ aaNormalText (≥4.5)',
      );
    });

    test('a report collects failures and lists them first', () {
      final report = CoreContrastReport(const [passing, failing]);

      expect(report.passes, isFalse);
      expect(report.failures, [failing]);
      expect(
        report.toString().split('\n'),
        [
          'CoreContrastReport: 1 of 2 pairs fail',
          '  grey on white 4.48:1 ✗ aaNormalText (≥4.5)',
          '  black on white 21.00:1 ✓ aaNormalText (≥4.5)',
        ],
      );
    });

    test('a report is unmodifiable', () {
      final report = CoreContrastReport(const [passing]);
      expect(() => report.checks.add(failing), throwsUnsupportedError);
    });
  });

  group('CoreContrast.auditScheme — default presets', () {
    const source = CouiColorPresets.source;

    // The schemes `CoreThemePresets` ships, built the same way.
    final schemes = {
      'light': source.light().resolved(.light),
      'dark': source.dark().resolved(.dark),
      'high-contrast light': source.highContrastLight().resolved(.light),
      'high-contrast dark': source.highContrastDark().resolved(.dark),
    };

    for (final entry in schemes.entries) {
      test('${entry.key}: every representative pair passes', () {
        final report = CoreContrast.auditScheme(entry.value);

        expect(report.failures, isEmpty, reason: report.toString());
        expect(report.passes, isTrue);
      });
    }

    test('holds each pair to the level its slot is named for', () {
      final report = CoreContrast.auditScheme(schemes['light']!);
      CoreContrastLevel levelOf(String foreground, String background) => report
          .checks
          .singleWhere(
            (c) =>
                c.foregroundName == foreground &&
                c.backgroundName == background,
          )
          .level;

      expect(levelOf('onSurface', 'surface'), CoreContrastLevel.aaNormalText);
      expect(
        levelOf('onSurfaceSubtle', 'surface'),
        CoreContrastLevel.aaNormalText,
      );
      expect(levelOf('primaryText', 'surface'), CoreContrastLevel.aaNormalText);
      expect(
        levelOf('primaryTextLarge', 'surface'),
        CoreContrastLevel.aaLargeText,
      );
      expect(levelOf('error', 'surface'), CoreContrastLevel.aaNormalText);
      expect(levelOf('outline', 'surface'), CoreContrastLevel.nonText);
    });

    test('flags a scheme whose pair falls short', () {
      final light = schemes['light']!;
      final broken = CoreContrast.auditScheme(
        light.copyWith(onSurfaceVariant: _grey777).resolved(.light),
      );

      expect(broken.passes, isFalse);
      expect(
        broken.failures.map((c) => '${c.foregroundName}/${c.backgroundName}'),
        contains('onSurfaceVariant/surface'),
      );
    });

    test('audits the third text tier on the page', () {
      final light = schemes['light']!;
      final broken = CoreContrast.auditScheme(
        light.copyWith(onSurfaceSubtle: _grey777).resolved(.light),
      );

      expect(
        broken.failures.map((c) => '${c.foregroundName}/${c.backgroundName}'),
        contains('onSurfaceSubtle/surface'),
      );
    });
  });
}
