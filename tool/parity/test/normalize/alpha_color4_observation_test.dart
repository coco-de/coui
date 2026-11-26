import 'dart:io';

import 'package:puppeteer/puppeteer.dart' as pp;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/normalize/css_value_parsers.dart';
import '../../src/normalize/web_property_normalizer.dart';
import '../../src/web/computed_style_probe.dart';

// Computed Color 4 forms retain their color space, signed channels and
// missing components. Observing alpha must not require RGB conversion.
const _modernChannels = [
  'color(srgb -0.1 1.2 2e-3',
  'color(srgb-linear 0.1 0.2 0.3',
  'color(display-p3 1 0 0',
  'color(display-p3-linear 1 0 0',
  'color(a98-rgb 1 0 0',
  'color(prophoto-rgb 1 0 0',
  'color(rec2020 1 0 0',
  'color(xyz 0.1 0.2 0.3',
  'color(xyz-d50 0.1 0.2 0.3',
  'color(xyz-d65 0.1 0.2 0.3',
  'lab(70 -12 2e-3',
  'lch(70 12 30deg',
  'oklab(0.7 -0.1 0.2',
  'oklch(0.7 0.2 30',
  'hsl(none 50% 60%',
  'hwb(none 20% 30%',
  'rgb(none 10% 20',
];

void main() {
  for (final channels in _modernChannels) {
    test('alpha is independent of $channels)', () {
      expect(cssColorIsFullyTransparent('$channels)'), isFalse);
      for (final alpha in ['0', '-0', '+0e20%', '0%', 'none', '-0.1']) {
        expect(cssColorIsFullyTransparent('$channels / $alpha)'), isTrue);
      }
      for (final alpha in ['1', '.0004', '1e-7', '.04%', '+1e-999%']) {
        expect(cssColorIsFullyTransparent('$channels / $alpha)'), isFalse);
      }
    });
  }

  test(
    'legacy RGB alpha retains signs, percentages and exact positive values',
    () {
      for (final alpha in ['0', '-0', '0%', '-1e-7']) {
        expect(cssColorIsFullyTransparent('rgba(12, 34, 56, $alpha)'), isTrue);
      }
      for (final alpha in ['.0004', '1e-7', '.04%', '+1e-999%']) {
        expect(cssColorIsFullyTransparent('rgba(12, 34, 56, $alpha)'), isFalse);
      }
      expect(cssColorIsFullyTransparent('rgb(12, 34, 56)'), isFalse);
      expect(cssColorIsFullyTransparent('rgba(10%, 20%, 30%, 0%)'), isTrue);
      expect(cssColorIsFullyTransparent('hsla(30deg, 20%, 30%, 0%)'), isTrue);
    },
  );

  test(
    'malformed or unsupported observations never establish transparency',
    () {
      for (final color in [
        'unknown',
        'unknown(1 2 3 / 0)',
        'color(unknown 1 0 0 / 0)',
        'color(display-p3 1 0 / 0)',
        'color(display-p3 1 0 0 0 / 0)',
        'color(display-p3 nope 0 0 / 0)',
        'color(display-p3 1px 0 0 / 0)',
        'oklch(0.7 0.2 30% / 0)',
        'lab(70, 1, 2, 0)',
        'rgba(1, 2%, 3, 0)',
        'rgba(none, 2, 3, 0)',
        'rgba(1, 2, 3 / 0)',
        'lab(70 1 2 /)',
        'lab(70 1 2 / 0 / 0)',
        'lab(70 1 2 / 0) trailing',
        'lab(70 1 2 / 0.0.0)',
        'lab(70 1 2 / 1e)',
        'lab(70 1 2 / 0px)',
        'lab(70 1 2 / NaN)',
        'lab(70 1 2 / calc(0))',
      ]) {
        expect(
          () => cssColorIsFullyTransparent(color),
          throwsFormatException,
          reason: color,
        );
      }
    },
  );

  test('alpha observation leaves RGB conversion support unchanged', () {
    expect(parseCssColor('rgba(12, 34, 56, 0.125)').a, 0.125);
    for (final color in ['color(display-p3 1 0 0)', 'oklch(0.7 0.2 30)']) {
      expect(() => parseCssColor(color), throwsFormatException);
      expect(
        () => parseCssBoxShadow('$color 0px 4px 6px 2px'),
        throwsFormatException,
      );
    }
  });

  final chromePath = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
  ].where((path) => File(path).existsSync()).firstOrNull;
  test(
    'real Chrome Color4 outline observations retain zero and faint paint',
    () async {
      final browser = await launchCaptureBrowser(
        width: 400,
        height: 300,
        executablePath: chromePath,
      );
      try {
        final page = await browser.newPage();
        try {
          await page.setOfflineMode(true);
          // These Color 4 spaces are supported by the capture browser.
          // Percentages/exponents are authored here and read back from its
          // real computed serialization before the production normalizer.
          for (final channels in [
            'color(srgb -0.1 1.2 2e-3',
            'color(srgb-linear 0.1 0.2 0.3',
            'color(display-p3 1 0 0',
            'color(a98-rgb 1 0 0',
            'color(prophoto-rgb 1 0 0',
            'color(rec2020 1 0 0',
            'color(xyz-d50 0.1 0.2 0.3',
            'color(xyz-d65 0.1 0.2 0.3',
            'lab(70 -12 2e-3',
            'lch(70 12 30',
            'oklab(0.7 -0.1 0.2',
            'oklch(0.7 0.2 30',
          ]) {
            for (final alpha in ['0', '.0004', '1e-7', '0%', '.04%', '1']) {
              final color = '$channels / $alpha)';
              expect(
                await page.evaluate<bool>(
                  '(color) => CSS.supports("outline-color", color)',
                  args: [color],
                ),
                isTrue,
                reason: color,
              );
              await page.setContent('''
<!doctype html><html><body>
<div id="paint" style="width:80px;height:60px;background:rgb(200,210,220);
outline:3px solid $color;outline-offset:2px"></div>
</body></html>''', wait: pp.Until.load);
              final raw = (await captureComputedStyle(page, '#paint'))!;
              final normalized = normalizeWebSnapshot(
                raw,
                key: 'paint',
                probeRole: 'root',
              );
              expect(
                normalized.outlineWidthPx,
                alpha == '0' || alpha == '0%' ? 0 : 3,
                reason: '$color → ${raw['outlineColor']}',
              );
              expect(normalized.outlineOffsetPx, 2);
            }
          }
          await page.setContent('''
<div id="paint" style="width:80px;height:60px;background:rgb(200,210,220);
outline:3px solid rgba(12,34,56,.004)"></div>''', wait: pp.Until.load);
          final rgb = (await captureComputedStyle(page, '#paint'))!;
          expect(
            normalizeWebSnapshot(
              rgb,
              key: 'paint',
              probeRole: 'root',
            ).outlineWidthPx,
            3,
          );
        } finally {
          await page.close();
        }
      } finally {
        await browser.close();
      }
    },
    skip: chromePath == null ? 'Chrome executable unavailable' : null,
  );
}
