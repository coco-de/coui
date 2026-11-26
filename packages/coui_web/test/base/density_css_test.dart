// The density axis on Web — the rules a `data-coui-density` attribute
// switches, read back from the stylesheet the theme emits.
//
// The values are what `CoreDensity` draws — the function Flutter applies at
// its conversions — and a few are written out as numbers, so a change to the
// rungs fails here instead of moving the CSS and the Core seat together.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  final config = ThemeConfig.defaults();

  group('the control rows have their own variables', () {
    test('every rung of the control ladder is a root variable', () {
      for (final h in CoreControlSize.steps) {
        expect(
          config.cssVariables,
          contains('--coui-control-height-${h.toInt()}:${h / 16}rem;'),
        );
      }
    });

    test('the height classes a row emits point at them', () {
      expect(
        config.tailwindConfig,
        contains('control40:"var(--coui-control-height-40)"'),
      );
    });

    test('every button size names a rung, so its height class has a key', () {
      // The button emits `h-control<N>` from its size row; a size off the
      // ladder would name a class Tailwind never generates, and the row
      // would collapse to its content.
      for (final row in CoreButtonStyle.defaultsBySize.values) {
        final height = row.height;
        if (height == null) continue;
        expect(CoreControlSize.steps, contains(height));
      }
    });

    test('a rung goes out as its variable, anything else as a literal', () {
      expect(controlHeightCss(40), 'var(--coui-control-height-40)');
      expect(controlHeightCss(37), '2.3125rem');
    });
  });

  group('a density is one rule per density', () {
    final blocks = config.densityVariableBlocks;

    test('the default density writes no rule', () {
      expect(blocks, isNot(contains('="standard"')));
    });

    test('compact re-points the spacing, the rows and their corners', () {
      final compact = RegExp(
        r'\[data-coui-density="compact"\]\{([^}]*)\}',
      ).firstMatch(blocks)!.group(1)!;
      expect(compact, contains('--coui-space-16:0.75rem;'));
      expect(compact, contains('--coui-space-8:0.25rem;'));
      expect(compact, contains('--coui-control-height-40:2.0rem;'));
      expect(compact, contains('--coui-radius-10:8.0px;'));
      // Steps a density does not move are not written.
      expect(compact, isNot(contains('--coui-space-4:')));
      expect(compact, isNot(contains('--coui-control-height-32:')));
      expect(compact, isNot(contains('--coui-radius-4:')));
    });

    test('spacious moves the other way and stops at the top rung', () {
      final spacious = RegExp(
        r'\[data-coui-density="spacious"\]\{([^}]*)\}',
      ).firstMatch(blocks)!.group(1)!;
      expect(spacious, contains('--coui-space-16:1.25rem;'));
      expect(spacious, contains('--coui-control-height-40:3.0rem;'));
      expect(spacious, isNot(contains('--coui-control-height-64:')));
    });

    test('every value is the one the shared seat draws', () {
      for (final density in CoreDensity.values) {
        if (density == .defaultDensity) continue;
        for (final step in CoreSpace.steps) {
          final bent = density.space(step);
          final declaration = '--coui-space-${step.toInt()}:${bent / 16}rem;';
          expect(
            blocks.contains(declaration),
            bent != step,
            reason: '${density.name} space $step',
          );
        }
      }
    });

    test('the rules ship with the root variables', () {
      expect(config.cssVariables, contains(blocks));
    });
  });

  group('a style and a density compose on the pair', () {
    final blocks = config.surfaceStyleVariableBlocks;

    String? pairRule(CoreSurfaceStyleId id, CoreDensity density) => RegExp(
      '\\[data-coui-style="${id.name}"\\]'
      '\\[data-coui-density="${density.name}"\\]\\{([^}]*)\\}',
    ).firstMatch(blocks)?.group(1);

    test('exactly the styles that bend corners write a pair rule', () {
      for (final id in CoreSurfaceStyleId.values) {
        final geometry = resolveThemeGeometry(surfaceStyle: id);
        final bends =
            geometry.radiusFloor != null || geometry.radiusCap != null;
        for (final density in CoreDensity.values) {
          if (density == .defaultDensity) continue;
          expect(
            pairRule(id, density) != null,
            bends,
            reason: '${id.name} × ${density.name}',
          );
        }
      }
    });

    test('each pair rule states the corner the shared seat composes', () {
      for (final id in CoreSurfaceStyleId.values) {
        for (final density in CoreDensity.values) {
          final rule = pairRule(id, density);
          if (rule == null) continue;
          final style = resolveThemeGeometry(surfaceStyle: id);
          final composed = resolveThemeGeometry(
            surfaceStyle: id,
            density: density,
          );
          for (final step in CoreRadius.steps) {
            final written =
                step != style.radius(step) || step != density.radius(step);
            expect(
              rule.contains('--coui-radius-${step.toInt()}:'),
              written,
              reason: '${id.name} × ${density.name} radius $step',
            );
            if (written) {
              expect(
                rule,
                contains(
                  '--coui-radius-${step.toInt()}:${composed.radius(step)}px;',
                ),
              );
            }
          }
        }
      }
    });

    test('the pair is neither single rule', () {
      // Written out: a neo-brutalist corner of 10 is 4 under the style, 8
      // under compact, and 2 under both — the style's cap redistributes the
      // corner the density already moved, so neither single rule is right.
      final styleRules = RegExp(
        r'\[data-coui-style="neoBrutalism"\]\{([^}]*)\}',
      ).allMatches(blocks).map((m) => m.group(1)!).join();
      final densityRule = RegExp(
        r'\[data-coui-density="compact"\]\{([^}]*)\}',
      ).firstMatch(config.densityVariableBlocks)!.group(1)!;
      expect(styleRules, contains('--coui-radius-10:4.0px;'));
      expect(densityRule, contains('--coui-radius-10:8.0px;'));
      expect(
        pairRule(.neoBrutalism, .compact),
        contains('--coui-radius-10:2.0px;'),
      );
    });
  });

  group('the document carries the density', () {
    testServer('a stated density reaches the server-rendered markup', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, density: .compact, child: const div([])),
      );
      final html = (await tester.request('/')).document?.documentElement;
      expect(html?.attributes[kDensityAttribute], 'compact');
    });

    testServer('the default writes no attribute', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: const div([])));
      final html = (await tester.request('/')).document?.documentElement;
      expect(html?.attributes.containsKey(kDensityAttribute), isFalse);
    });
  });
}
