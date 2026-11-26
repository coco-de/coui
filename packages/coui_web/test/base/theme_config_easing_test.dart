import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('ThemeConfig — easing CSS variables', () {
    final config = ThemeConfig.defaults();
    final css = config.cssVariables;

    test('contains --easing-linear', () {
      expect(css, contains('--easing-linear:linear;'));
    });

    test('contains --easing-ease-out cubic-bezier', () {
      expect(
        css,
        contains('--easing-ease-out:cubic-bezier(0.0, 0.0, 0.58, 1.0);'),
      );
    });

    test('contains --easing-fast-out-slow-in (Material default)', () {
      expect(
        css,
        contains('--easing-fast-out-slow-in:cubic-bezier(0.4, 0.0, 0.2, 1.0);'),
      );
    });

    test('contains all 34 cubic-bezier easing variables', () {
      // Spec: 5 standard + 3 sine + 3 quad + 3 cubic + 3 quart + 3 quint
      // + 3 expo + 3 circ + 3 back + 5 flutter-special = 34
      final easingMatches = RegExp(r'--easing-[a-z0-9-]+:').allMatches(css);
      expect(easingMatches, hasLength(34));
    });

    test('overshoot curves preserve negative / over-1 control points', () {
      expect(css, contains('--easing-ease-in-back:cubic-bezier(0.6, -0.28'));
      expect(css, contains('--easing-ease-out-back:cubic-bezier'));
      expect(css, contains('1.275'));
    });
  });

  group('ThemeConfig — Tailwind transitionTimingFunction', () {
    final config = ThemeConfig.defaults();
    final tw = config.tailwindConfig;

    test('contains transitionTimingFunction key', () {
      expect(tw, contains('transitionTimingFunction:{'));
    });

    test('linear maps to "linear" string (not cubic-bezier)', () {
      expect(tw, contains('"linear":"linear"'));
    });

    test('ease-out maps to cubic-bezier tuple', () {
      expect(
        tw,
        contains('"ease-out":"cubic-bezier(0.0, 0.0, 0.58, 1.0)"'),
      );
    });
  });
}
