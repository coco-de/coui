// The two stroke steps with half a pixel in them as the Web reads them: the
// hairline (`CoreStrokeWidth.stroke0_5`) and the active boundary
// (`CoreStrokeWidth.stroke1_5`) are variables that are one whole CSS px on a
// 1x screen and their own width on a dense screen — the widths Flutter folds
// into its theme geometry for the same screen — reachable by the same
// Tailwind key and the same surface-style floor as every other stroke step.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const _thick = CoreSurfaceGeometryConstraint(
  strokeFloor: CoreStrokeWidth.stroke3,
);

void main() {
  final config = ThemeConfig.defaults();
  final css = config.cssVariables;

  // `:root{...}` is declared first; the dense-screen override must come
  // after it or an equal-specificity rule above it would win.
  const baseDeclaration = '--coui-stroke-width-0_5:1.0px;';
  const activeBaseDeclaration = '--coui-stroke-width-1_5:1.0px;';
  const denseRule =
      '@media (min-resolution:2dppx) '
      '{:root{--coui-stroke-width-0_5:0.5px;--coui-stroke-width-1_5:1.5px;}}';

  group('--coui-stroke-width-0_5', () {
    test(':root states one whole CSS px for a 1x screen', () {
      // 0.5 CSS px on a 1x screen is half a device pixel: the browser
      // antialiases it into a line fainter than the colour states.
      expect(css, contains(baseDeclaration));
    });

    test('a dense screen overrides it with the token value', () {
      expect(css, contains(denseRule));
    });

    test('the dense rule comes after the declaration it overrides', () {
      expect(
        css.indexOf(denseRule),
        greaterThan(css.indexOf(baseDeclaration)),
        reason: 'at equal specificity the later rule wins',
      );
    });

    test('the dense rule moves only the two half-pixel steps', () {
      final start = css.indexOf(denseRule);
      final block = css.substring(start, start + denseRule.length);

      expect('--coui-stroke-width-'.allMatches(block), hasLength(2));
    });

    // Flutter reads these widths from the same Core functions, so the two
    // platforms draw the same width on each screen.
    test('both halves are the widths Core gives each screen', () {
      expect(
        baseDeclaration,
        contains('${CoreStrokeWidth.hairlineAt(1)}px'),
      );
      expect(denseRule, contains('0_5:${CoreStrokeWidth.hairlineAt(2)}px'));
    });

    test('the dense threshold is a device-pixel ratio, not a width', () {
      // A width query would hairline a narrow desktop window.
      expect(denseRule, contains('min-resolution'));
      expect(denseRule, isNot(contains('min-width')));
    });
  });

  group('--coui-stroke-width-1_5', () {
    test(':root states one whole CSS px for a 1x screen', () {
      // Chrome drew a 1.5 CSS px border as one device pixel on a 1x screen
      // already; stating it makes every browser and every non-border use
      // (inset shadows, offsets) agree with the frame Flutter draws there.
      expect(css, contains(activeBaseDeclaration));
      expect(
        activeBaseDeclaration,
        contains('${CoreStrokeWidth.activeBoundaryAt(1)}px'),
      );
    });

    test('a dense screen overrides it with the token value', () {
      expect(
        denseRule,
        contains('1_5:${CoreStrokeWidth.activeBoundaryAt(2)}px'),
      );
      expect(
        css.indexOf(denseRule),
        greaterThan(css.indexOf(activeBaseDeclaration)),
        reason: 'at equal specificity the later rule wins',
      );
    });
  });

  group('the Tailwind border width scale', () {
    test('has a key for the hairline that reads the variable', () {
      expect(
        config.tailwindConfig,
        contains(
          '${CoreStrokeWidth.scale.stroke0_5}:'
          '"var(--coui-stroke-width-0_5)"',
        ),
      );
    });

    test('the neighbouring steps are untouched', () {
      expect(
        config.tailwindConfig,
        contains(
          '${CoreStrokeWidth.scale.stroke1}:"var(--coui-stroke-width-1)"',
        ),
      );
      expect(
        config.tailwindConfig,
        contains(
          '${CoreStrokeWidth.scale.stroke0}:"var(--coui-stroke-width-0)"',
        ),
      );
    });
  });

  group('a surface style stroke floor', () {
    test('lifts the hairline like any step under the floor', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _thick,
      );

      expect(block, contains('--coui-stroke-width-0_5:3.0px'));
    });

    test('lifts the active boundary like any step under the floor', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _thick,
      );

      expect(block, contains('--coui-stroke-width-1_5:3.0px'));
    });

    test('still leaves a suppressed border suppressed', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _thick,
      );

      expect(block, isNot(contains('--coui-stroke-width-0:')));
    });
  });
}
