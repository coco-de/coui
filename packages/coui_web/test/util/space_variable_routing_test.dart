import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// The `--coui-space-N` definitions in the `:root` block, by N, as rem.
Map<int, double> _definedSpaceVariables() {
  // The authored definitions only. The sheet also carries the density rules,
  // which re-point some of the same variables under `[data-coui-density]`;
  // those are a density's answer, not the length a literal used to be.
  final config = ThemeConfig.defaults();
  final css = config.cssVariables.replaceAll(config.densityVariableBlocks, '');
  final pattern = RegExp(r'--coui-space-(\d+):(-?[0-9.]+)rem;');

  return {
    for (final m in pattern.allMatches(css))
      int.parse(m.group(1)!): double.parse(m.group(2)!),
  };
}

void main() {
  group('a spacing step names its variable', () {
    test('every step of the scale', () {
      // A density axis or a designer override re-points these variables. An
      // inline declaration that bakes the length instead is the one place
      // the re-map does not reach — on screen, "this one component kept its
      // old spacing".
      for (final step in CoreSpace.steps) {
        expect(
          spaceCss(step),
          'var(--coui-space-${step.toInt()})',
          reason: '$step',
        );
      }
    });

    test('the ends of the scale, spelled out', () {
      expect(spaceCss(CoreSpace.space0), 'var(--coui-space-0)');
      expect(spaceCss(CoreSpace.space2), 'var(--coui-space-2)');
      expect(spaceCss(CoreSpace.space16), 'var(--coui-space-16)');
      expect(spaceCss(CoreSpace.space256), 'var(--coui-space-256)');
    });

    test('each named variable is defined, as the length the literal was', () {
      // The swap is only free if the variable renders what the literal did:
      // `var(--coui-space-16)` must be the `1rem` that `16 / 16` produced. A
      // step with no definition would be dropped by the browser instead.
      final defined = _definedSpaceVariables();
      for (final step in CoreSpace.steps) {
        final n = step.toInt();
        expect(defined, contains(n), reason: '--coui-space-$n is not defined');
        expect(defined[n], step / kRemDivisor, reason: '--coui-space-$n');
      }
    });
  });

  group('anything else stays the literal it was', () {
    test('a value between steps', () {
      expect(spaceCss(19), '1.1875rem');
      expect(spaceCss(4.5), '0.28125rem');
    });

    test('a fraction is not truncated onto the step below it', () {
      // `toInt()` would map 16.5 onto `--coui-space-16` — a length the
      // caller did not ask for, and one a re-map would then move.
      expect(spaceCss(16.5), '1.03125rem');
      expect(spaceCss(15.9), isNot(contains('var(')));
    });

    test('a negative value', () {
      expect(spaceCss(-8), '-0.5rem');
      expect(spaceCss(-CoreSpace.space16), '-1.0rem');
    });
  });

  group('pinnedLengthCss never names a spacing variable', () {
    test('not even for a value that equals a step', () {
      expect(pinnedLengthCss(CoreSpace.space16), '1.0rem');
      expect(pinnedLengthCss(CoreSpace.space0), '0.0rem');
      expect(pinnedLengthCss(-6), '-0.375rem');
    });
  });

  group('CoreEdgeInsets routes every side', () {
    test('the shorthand names a variable per step side', () {
      expect(
        const CoreEdgeInsets.all(CoreSpace.space16).toValue(),
        'var(--coui-space-16) var(--coui-space-16) '
        'var(--coui-space-16) var(--coui-space-16)',
      );
    });

    test('sides are judged one by one, in shorthand order', () {
      // top right bottom left — an off-scale side stays a literal next to
      // its routed neighbours.
      expect(
        const CoreEdgeInsets.fromLTRB(4, 8, 19, 0).toValue(),
        'var(--coui-space-8) 1.1875rem var(--coui-space-0) var(--coui-space-4)',
      );
    });

    test('logical declarations route the same way', () {
      expect(
        const CoreEdgeInsets.directional(
          start: CoreSpace.space24,
          top: CoreSpace.space8,
          end: 13,
        ).toLogicalDeclarations('padding'),
        {
          'padding-block-start': 'var(--coui-space-8)',
          'padding-block-end': 'var(--coui-space-0)',
          'padding-inline-start': 'var(--coui-space-24)',
          'padding-inline-end': '0.8125rem',
        },
      );
    });

    test('a physical value keeps its one shorthand declaration', () {
      expect(
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
        ).toLogicalDeclarations('margin'),
        {
          'margin':
              'var(--coui-space-0) var(--coui-space-12) '
              'var(--coui-space-0) var(--coui-space-12)',
        },
      );
    });

    test('an emitSpacing override goes inline through the same route', () {
      final emitted = emitSpacing(
        const CoreEdgeInsets.all(CoreSpace.space4),
        const CoreEdgeInsets.all(CoreSpace.space8),
        prefix: 'p',
        cssProperty: 'padding',
      );
      expect(emitted.className, isEmpty);
      expect(emitted.inline, {
        'padding':
            'var(--coui-space-4) var(--coui-space-4) '
            'var(--coui-space-4) var(--coui-space-4)',
      });
    });
  });
}
