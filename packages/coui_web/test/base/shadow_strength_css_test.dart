import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The Web transport of the dark shadow strength: the dark scopes set
/// `--coui-shadow-strength` to `CoreShadow.darkStrength`, and every cast
/// layer multiplies its alpha by it — the same ×4 the Flutter seat applies
/// (`CoreSurfaceGeometryConstraint.shadow`).
void main() {
  final config = ThemeConfig.defaults();
  const declaration = '$kShadowStrengthVariable:${CoreShadow.darkStrength}';

  group('the dark scopes state the strength', () {
    test('the attribute form and the OS-preference form both carry it', () {
      expect(config.darkVariableBlock, contains(declaration));
      expect(config.darkAutoVariableBlock, contains(declaration));
      expect(config.cssVariablesDark, contains(declaration));
    });

    test(
      'the light stylesheet does not — a light page reads the fallback 1',
      () {
        // The root's rules: everything but the brightness scopes, which
        // never match the root.
        final page = config.cssVariables.replaceAll(
          config.brightnessScopeBlock,
          '',
        );

        expect(page, isNot(contains('$kShadowStrengthVariable:')));
      },
    );

    test('each brightness scope states its own strength', () {
      // Inside a page of the other brightness the root's strength would
      // reach a scope by inheritance, and its casts would carry that alpha.
      final scope = config.brightnessScopeBlock;
      String? rule(String mode) => RegExp(
        '(?:^|\\})\\[data-theme="$mode"\\]:not\\(:root\\)\\{([^}]*)\\}',
      ).firstMatch(scope)?.group(1);

      expect(rule('light'), contains('$kShadowStrengthVariable:1;'));
      expect(
        rule('dark'),
        contains('$kShadowStrengthVariable:${CoreShadow.darkStrength};'),
      );
      expect('$kShadowStrengthVariable:'.allMatches(scope).length, 2);
    });

    test('no style block writes it, so a bent stack takes the same rule', () {
      for (final id in CoreSurfaceStyleId.values) {
        final recipe = CoreSurfaceRecipe.of(id);
        final block = config.surfaceStyleGeometryBlock(
          id,
          recipe.geometry,
          typography: recipe.typography,
        );
        expect(
          block,
          isNot(contains('$kShadowStrengthVariable:')),
          reason: '$id',
        );
      }
    });

    test(
      'it carries no quote — the dark blocks ride a single-quoted script',
      () {
        expect(config.darkVariableBlock, isNot(contains("'")));
      },
    );
  });

  group('a cast layer multiplies its alpha by the strength', () {
    test('every rung of the scale reaches it through --shadow-*', () {
      for (final token in [
        CoreShadow.xs,
        CoreShadow.sm,
        CoreShadow.md,
        CoreShadow.lg,
        CoreShadow.xl,
        CoreShadow.xl2,
        CoreShadow.xl3,
        CoreShadow.inset,
      ]) {
        final css = token.toValue(base: kShadowVariableBase);
        expect(
          'var($kShadowStrengthVariable, 1)'.allMatches(css).length,
          token.length,
          reason: css,
        );
      }
    });

    test('a literal stack with a pinned colour is strengthened too', () {
      final css = CoreShadow.xl.toValue(base: 'rgb(0, 0, 0)');
      expect(
        css,
        contains(
          'color-mix(in srgb, rgb(0, 0, 0) '
          'calc(12.5% * var($kShadowStrengthVariable, 1)), transparent)',
        ),
      );
    });

    test('a layer already at full opacity has nothing to strengthen', () {
      const solid = [
        (
          offsetX: 4.0,
          offsetY: 4.0,
          blurRadius: 0.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      expect(
        solid.toValue(base: kShadowVariableBase),
        '0.25rem 0.25rem 0.0rem 0.0rem $kShadowVariableBase',
      );
    });

    test('a highlight opts out — light, not shadow', () {
      final css = CoreShadow.inset.toValue(
        base: 'rgb(255, 255, 255)',
        strengthens: false,
      );
      expect(css, isNot(contains(kShadowStrengthVariable)));
      expect(css, contains('6%'));
    });

    test("the style's rim is never strengthened", () {
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.claymorphism);
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.claymorphism,
        recipe.geometry,
        typography: recipe.typography,
      );
      final rim = RegExp(
        '--coui-surface-rim:([^;]*);',
      ).firstMatch(block)?.group(1);
      expect(rim, isNotNull);
      expect(rim, isNot(contains(kShadowStrengthVariable)));
    });

    test('drop-shadow() takes the same strength', () {
      expect(
        CoreShadow.lg.toDropShadowValue(base: kShadowVariableBase),
        contains('calc(12.5% * var($kShadowStrengthVariable, 1))'),
      );
    });
  });

  group('the new steps have their variables', () {
    final css = config.cssVariables;

    test('stroke 1.5 and space 18', () {
      // One whole px on a 1x screen, its own 1.5 from 2x up — the
      // half-pixel steps rule pins both halves.
      expect(css, contains('--coui-stroke-width-1_5:1.0px;'));
      expect(css, contains('--coui-stroke-width-1_5:1.5px;'));
      expect(css, contains('--coui-space-18:1.125rem;'));
      expect(
        strokeWidthCss(CoreStrokeWidth.stroke1_5),
        'var(--coui-stroke-width-1_5)',
      );
      expect(spaceCss(CoreSpace.space18), 'var(--coui-space-18)');
    });

    test('the Tailwind config names both', () {
      final tw = config.tailwindConfig;
      expect(tw, contains('stroke1_5:"var(--coui-stroke-width-1_5)"'));
      expect(tw, contains('space18:"var(--coui-space-18)"'));
    });

    test('a hard-edged style lifts the 1.5 boundary to its floor', () {
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism);
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        recipe.geometry,
        typography: recipe.typography,
      );
      expect(block, contains('--coui-stroke-width-1_5:4.0px'));
    });
  });
}
