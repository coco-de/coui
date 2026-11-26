import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoreTextStyleToFlutter.toValue(theme:)', () {
    const theme = ThemeData();

    test(
      'token-backed role materialises the slot into a Flutter TextStyle',
      () {
        const role = CoreTextStyle.token(CoreTextStyles.bodyMedium);

        final resolved = role.toValue(theme: theme);

        // bodyMedium slot: fontSize 14, lineHeight 1.5, regular (400),
        // letterSpacing −0.01 em (optical tracking) → −0.14 px.
        expect(resolved.fontSize, CoreFontSize.s14);
        expect(resolved.height, CoreLineHeight.h150);
        expect(resolved.fontWeight, FontWeight.w400);
        expect(resolved.letterSpacing, closeTo(-0.14, 1e-9));
      },
    );

    test('merged style overlays raw fields onto the token slot', () {
      // Mirrors `default.merge(override)`: a token role with a fontWeight
      // overlay applied on top.
      final merged = const CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
      ).merge(const CoreTextStyle(fontWeight: CoreFontWeight.semiBold));

      final resolved = merged.toValue(theme: theme);

      // Slot dimensions survive; the overlaid weight wins.
      expect(resolved.fontSize, CoreFontSize.s14);
      expect(resolved.fontWeight, FontWeight.w600);
    });
  });

  // A code role states a fixed line box (`lineHeightPx`) instead of a
  // multiplier. Flutter's `height` is a multiplier, so every conversion
  // draws the box as `px / final fontSize` — the line stays 21px whatever
  // size the glyphs end at, as the Web's rem line-height does.
  group('fixed line box (lineHeightPx)', () {
    const theme = ThemeData();

    // The line a style is drawn on: Flutter's multiplier times its size.
    double lineOf(TextStyle style) => style.height! * style.fontSize!;

    test('a code role draws its 21px box in the mono stack', () {
      final resolved = const CoreTextStyle.token(
        CoreTextStyles.codeMd,
      ).toValue(theme: theme);

      expect(resolved.fontSize, theme.typography.codeMd.fontSize);
      expect(lineOf(resolved), closeTo(CoreLineBox.px21, 1e-9));
      expect(resolved.letterSpacing, 0);
      expect(resolved.fontFamily, CoreFontFamily.mono);
      expect(resolved.fontFamilyFallback, kCoreMonoFontFallback);
    });

    test('every code role shares the one line box', () {
      for (final token in [
        CoreTextStyles.codeXs,
        CoreTextStyles.codeSm,
        CoreTextStyles.codeMd,
      ]) {
        final resolved = CoreTextStyle.token(token).toValue(theme: theme);

        expect(lineOf(resolved), closeTo(CoreLineBox.px21, 1e-9));
      }
    });

    test('a size overlay keeps the box — it divides by the final size', () {
      final resolved = const CoreTextStyle.token(CoreTextStyles.codeSm)
          .merge(const CoreTextStyle(fontSize: CoreFontSize.s16))
          .toValue(theme: theme);

      expect(resolved.fontSize, CoreFontSize.s16);
      expect(lineOf(resolved), closeTo(CoreLineBox.px21, 1e-9));
    });

    test('a later multiplier drops the box — the newest statement wins', () {
      final resolved = const CoreTextStyle.token(CoreTextStyles.codeSm)
          .merge(const CoreTextStyle(lineHeight: CoreLineHeight.h140))
          .toValue(theme: theme);

      expect(resolved.height, CoreLineHeight.h140);
    });

    test('the box scales with the text scale, as the glyphs do', () {
      final scaled = ThemeData.fromCore(
        CoreThemePresets.previewLight.copyWith(textScaling: 1.25),
      );

      final resolved = const CoreTextStyle.token(
        CoreTextStyles.codeMd,
      ).toValue(theme: scaled);

      expect(lineOf(resolved), closeTo(CoreLineBox.px21 * 1.25, 1e-9));
    });

    test('the value-only conversion draws the box, over a multiplier', () {
      final resolved = const CoreTextStyle(
        fontSize: CoreFontSize.s12,
        lineHeight: CoreLineHeight.h140,
        lineHeightPx: CoreLineBox.px21,
      ).toValue();

      expect(lineOf(resolved), closeTo(CoreLineBox.px21, 1e-9));
    });

    test('an inline overlay draws the box only with a size to divide by', () {
      expect(
        const CoreTextStyle(lineHeightPx: CoreLineBox.px21).toOverlayValue(),
        isA<TextStyle>().having((s) => s.height, 'height', isNull),
      );

      final sized = const CoreTextStyle(
        fontSize: CoreFontSize.s13,
        lineHeightPx: CoreLineBox.px21,
      ).toOverlayValue();
      expect(lineOf(sized), closeTo(CoreLineBox.px21, 1e-9));
    });

    test('applyCoreTextStyle divides the box by the effective size', () {
      final scheme = CoreThemePresets.lightColorScheme;
      const base = TextStyle(
        fontSize: CoreFontSize.s13,
        height: CoreLineHeight.h150,
      );

      final onBaseSize = applyCoreTextStyle(
        base,
        const CoreTextStyle(lineHeightPx: CoreLineBox.px21),
        scheme,
      );
      expect(lineOf(onBaseSize), closeTo(CoreLineBox.px21, 1e-9));

      final onOverrideSize = applyCoreTextStyle(
        base,
        const CoreTextStyle(
          fontSize: CoreFontSize.s16,
          lineHeightPx: CoreLineBox.px21,
        ),
        scheme,
      );
      expect(onOverrideSize.fontSize, CoreFontSize.s16);
      expect(lineOf(onOverrideSize), closeTo(CoreLineBox.px21, 1e-9));
    });
  });

  group('mono fallback', () {
    test('a style naming the mono face falls back to the bundled face', () {
      final resolved = const CoreTextStyle(
        fontSize: CoreFontSize.s13,
        fontFamily: CoreFontFamily.mono,
      ).toValue();

      expect(resolved.fontFamilyFallback, kCoreMonoFontFallback);
    });

    test('kCoreMonoTextStyle carries the same stack', () {
      expect(kCoreMonoTextStyle.fontFamily, CoreFontFamily.mono);
      expect(kCoreMonoTextStyle.fontFamilyFallback, kCoreMonoFontFallback);
      expect(kCoreMonoFontFallback, [
        'packages/coui_flutter/GeistMono',
        CoreFontFamily.sans,
      ]);
    });

    test('applyCoreTextStyle swaps the stack when the family changes', () {
      final scheme = CoreThemePresets.lightColorScheme;

      final mono = applyCoreTextStyle(
        kCoreSansTextStyle,
        const CoreTextStyle(fontFamily: CoreFontFamily.mono),
        scheme,
      );
      expect(mono.fontFamily, CoreFontFamily.mono);
      expect(mono.fontFamilyFallback, kCoreMonoFontFallback);

      final unnamed = applyCoreTextStyle(
        kCoreMonoTextStyle,
        const CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
        scheme,
      );
      expect(unnamed.fontFamilyFallback, kCoreMonoFontFallback);
    });
  });

  group('CoreGradientToFlutter.toValue', () {
    final scheme = CoreThemePresets.lightColorScheme;

    test('a linear gradient keeps colours, stops and its two anchors', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFFFF0000), CoreColor(0x800000FF)],
        stops: [0.25, 1],
        begin: CoreAlignment.topCenter,
        end: CoreAlignment.bottomCenter,
      );

      final resolved = gradient.toValue(scheme: scheme) as LinearGradient;

      expect(resolved.colors, const [Color(0xFFFF0000), Color(0x800000FF)]);
      expect(resolved.stops, const [0.25, 1.0]);
      expect(resolved.begin, AlignmentDirectional.topCenter);
      expect(resolved.end, AlignmentDirectional.bottomCenter);
    });

    test('a radial gradient is centred on the box and reaches half', () {
      // `begin` is a linear anchor: an unstated one and an off-centre one
      // draw the same centred gradient.
      for (final begin in [CoreAlignment.centerStart, CoreAlignment.topStart]) {
        final gradient = CoreGradient(
          type: CoreGradientType.radial,
          colors: const [CoreColor(0xFF000000), CoreColor(0xFFFFFFFF)],
          stops: const [0.2, 1],
          begin: begin,
        );

        final resolved = gradient.toValue(scheme: scheme) as RadialGradient;

        expect(resolved.center, Alignment.center);
        // Half the shorter side of the box: CSS `closest-side` on a circle.
        expect(resolved.radius, 0.5);
        expect(resolved.stops, const [0.2, 1.0]);
      }
    });

    test('alphaScale dims every stop and leaves its channels alone', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor(0xFFFF0000), CoreColor(0x80FF0000)],
      );

      final resolved =
          gradient.toValue(scheme: scheme, alphaScale: 0.5) as LinearGradient;

      expect(resolved.colors.first.a, closeTo(0.5, 1 / 255));
      expect(resolved.colors.last.a, closeTo(0.25, 1 / 255));
      expect(resolved.colors.first.r, closeTo(1, 1e-9));
    });

    test('token stops follow the scheme they are resolved against', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [CoreColor.token(CoreColors.surface)],
      );

      final light = gradient.toValue(scheme: CoreThemePresets.lightColorScheme);
      final dark = gradient.toValue(scheme: CoreThemePresets.darkColorScheme);

      expect(
        (light as LinearGradient).colors.single,
        isNot(
          (dark as LinearGradient).colors.single,
        ),
      );
    });
  });

  group('CoreColorToFlutter — token with opacity', () {
    // A fixed slot resolves to the same colour in every mode, so the colour
    // below is the slot's and the alpha is the stated opacity.
    const token = CoreColor.token(CoreColors.secondaryFixed, opacity: 0.55);
    const slot = CoreColor.token(CoreColors.secondaryFixed);

    test('scheme.resolve(c).toValue() keeps the slot colour at that alpha', () {
      for (final scheme in [
        CoreThemePresets.lightColorScheme,
        CoreThemePresets.darkColorScheme,
        CoreThemePresets.highContrastLightColorScheme,
        CoreThemePresets.highContrastDarkColorScheme,
      ]) {
        final opaque = scheme.resolve(slot).toValue();
        final translucent = scheme.resolve(token).toValue();

        expect(opaque.a, 1.0);
        expect(translucent.a, closeTo(0.55, 1e-9));
        expect(translucent.r, opaque.r);
        expect(translucent.g, opaque.g);
        expect(translucent.b, opaque.b);
      }
    });

    test('a gradient stop carries the same opacity as a solid does', () {
      const gradient = CoreGradient(
        type: CoreGradientType.linear,
        colors: [token, slot],
      );

      for (final scheme in [
        CoreThemePresets.lightColorScheme,
        CoreThemePresets.darkColorScheme,
      ]) {
        final resolved = gradient.toValue(scheme: scheme) as LinearGradient;

        expect(resolved.colors.first, scheme.resolve(token).toValue());
        expect(resolved.colors.last, scheme.resolve(slot).toValue());
      }
    });
  });

  group('CoreVectorGlyphToFlutter.toPath', () {
    const square = CoreVectorGlyph(
      path: 'M 0 0 L 10 0 L 10 4 L 0 4 Z M 2 1 C 3 1 4 1 4 2 L 4 3 Z',
      width: 10,
      height: 4,
      fillRule: CoreVectorFillRule.evenOdd,
    );

    test('scales the box the glyph states to the size it is filled into', () {
      final path = square.toPath(const Size(5, 8));

      final bounds = path.getBounds();
      expect(bounds.left, closeTo(0, 1e-9));
      expect(bounds.top, closeTo(0, 1e-9));
      expect(bounds.width, closeTo(5, 1e-9));
      expect(bounds.height, closeTo(8, 1e-9));
    });

    test("carries the glyph's fill rule", () {
      expect(square.toPath(const Size(10, 4)).fillType, PathFillType.evenOdd);
      const nonZero = CoreVectorGlyph(
        path: 'M 0 0 L 1 0 L 1 1 Z',
        width: 1,
        height: 1,
        fillRule: CoreVectorFillRule.nonZero,
      );
      expect(nonZero.toPath(const Size(1, 1)).fillType, PathFillType.nonZero);
    });

    test('a point inside the outline is inside the path, a hole is not', () {
      final path = square.toPath(const Size(10, 4));

      // The big square contains (8, 2); the inner shape is a hole under the
      // even-odd rule, so a point inside it is outside the fill.
      expect(path.contains(const Offset(8, 2)), isTrue);
      expect(path.contains(const Offset(3.8, 2.6)), isFalse);
    });

    test('a command outside the four-command grammar is refused', () {
      const arc = CoreVectorGlyph(
        path: 'M 0 0 A 1 1 0 0 1 2 2 Z',
        width: 2,
        height: 2,
        fillRule: CoreVectorFillRule.evenOdd,
      );

      expect(
        () => arc.toPath(const Size(2, 2)),
        throwsA(isA<FormatException>()),
      );
    });

    test('every glyph the status bar draws parses and fills its own box', () {
      for (final glyph in [
        CoreMockupDeviceStyle.phoneCellularGlyph,
        CoreMockupDeviceStyle.phoneWifiGlyph,
        CoreMockupDeviceStyle.phoneBatteryCapGlyph,
        CoreMockupDeviceStyle.tabletWifiGlyph,
        CoreMockupDeviceStyle.tabletBatteryGlyph,
      ]) {
        final path = glyph.toPath(Size(glyph.width, glyph.height));
        // `Path.getBounds` includes control points, which a curve never
        // reaches — walk the outline itself for its tight extent.
        var minX = double.infinity;
        var minY = double.infinity;
        var maxX = double.negativeInfinity;
        var maxY = double.negativeInfinity;
        for (final metric in path.computeMetrics()) {
          for (var i = 0; i <= 400; i++) {
            final p = metric.getTangentForOffset(metric.length * i / 400)!;
            minX = minX < p.position.dx ? minX : p.position.dx;
            minY = minY < p.position.dy ? minY : p.position.dy;
            maxX = maxX > p.position.dx ? maxX : p.position.dx;
            maxY = maxY > p.position.dy ? maxY : p.position.dy;
          }
        }
        expect(minX, closeTo(0, 0.05));
        expect(minY, closeTo(0, 0.05));
        expect(maxX, closeTo(glyph.width, 0.05));
        expect(maxY, closeTo(glyph.height, 0.05));
      }
    });
  });

  group('figmaLayerBlurToSigma', () {
    test('a Figma layer blur radius is twice the Gaussian σ', () {
      expect(figmaLayerBlurToSigma(0.8), closeTo(0.4, 1e-12));
      expect(figmaLayerBlurToSigma(0), 0);
    });
  });
}
