import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('ThemeConfig — box-shadow CSS variables', () {
    final config = ThemeConfig.defaults();
    final css = config.cssVariables;

    String shadowVar(String key) =>
        RegExp('--shadow-$key:([^;]*);').firstMatch(css)?.group(1) ?? '';

    test('generates a --shadow-* variable for every CoreShadow token', () {
      for (final key in const [
        'none',
        'xs',
        'sm',
        'md',
        'lg',
        'xl',
        '2xl',
        '3xl',
        'inset',
      ]) {
        expect(css, contains('--shadow-$key:'), reason: key);
      }
    });

    test('md is the designer one-layer floating cast', () {
      final md = shadowVar('md');
      // One layer: 0 8px 24px 0 @ 10% (px → rem at /16).
      expect(md.split('color-mix').length - 1, equals(1));
      expect(md, contains('0.0rem 0.5rem 1.5rem 0.0rem'));
      expect(md, contains('calc(10% * var(--coui-shadow-strength, 1))'));
    });

    test('sm keeps the attached two-layer lift (Sharp + Diffuse)', () {
      final sm = shadowVar('sm');
      expect(sm.split('color-mix').length - 1, equals(2));
      expect(sm, contains('0.125rem 0.25rem -0.0625rem'));
      expect(sm, contains('calc(5% * var(--coui-shadow-strength, 1))'));
      expect(sm, contains('calc(3% * var(--coui-shadow-strength, 1))'));
    });

    test('a fractional light alpha keeps its fraction (lg 12.5%)', () {
      expect(
        shadowVar('lg'),
        contains('calc(12.5% * var(--coui-shadow-strength, 1))'),
      );
    });

    test('shadow colour is the dark-mode-reactive --coui-shadow token', () {
      expect(shadowVar('md'), contains('rgb(var(--coui-shadow))'));
      // No fixed black alpha (Tailwind built-in) leaks in.
      expect(shadowVar('md'), isNot(contains('rgba(0')));
    });

    test('none is the keyword, inset carries the inset prefix', () {
      expect(shadowVar('none'), equals('none'));
      expect(shadowVar('inset'), startsWith('inset '));
    });
  });

  group('ThemeConfig — filter: drop-shadow() CSS variables', () {
    final config = ThemeConfig.defaults();
    final css = config.cssVariables;

    String filterVar(String key) =>
        RegExp('--shadow-$key-filter:([^;]*);').firstMatch(css)?.group(1) ?? '';

    test('generates a --shadow-*-filter variable for every non-inset step', () {
      // `Hover`'s `shadow` effect casts through `filter: drop-shadow()`,
      // not `box-shadow` — a stack with no inset layer follows the
      // child's rendered shape rather than the wrapper's square
      // border-box. Without a filter counterpart to route through, a
      // surface style bending `--shadow-*` never reached it.
      for (final key in const [
        'none',
        'xs',
        'sm',
        'md',
        'lg',
        'xl',
        '2xl',
        '3xl',
      ]) {
        expect(css, contains('--shadow-$key-filter:'), reason: key);
      }
    });

    test('drop-shadow() cannot express inset — no variable for it', () {
      expect(css, isNot(contains('--shadow-inset-filter:')));
    });

    test('sm is two chained drop-shadow() layers, not box-shadow syntax', () {
      final sm = filterVar('sm');
      // Layers chain space-separated (`drop-shadow(a) drop-shadow(b)`),
      // unlike --shadow-sm's comma-separated box-shadow layers.
      expect(sm.split('drop-shadow(').length - 1, equals(2));
      // Same designer numbers as --shadow-sm (px → rem at /16).
      expect(sm, contains('drop-shadow(0.0rem 0.125rem 0.25rem'));
      expect(sm, contains('drop-shadow(0.0rem 0.0625rem 0.125rem'));
    });

    test('lg is one drop-shadow() with the dark strength in its alpha', () {
      final lg = filterVar('lg');
      expect(lg.split('drop-shadow(').length - 1, equals(1));
      expect(lg, contains('drop-shadow(0.0rem 1.0rem 2.5rem'));
      expect(lg, contains('calc(12.5% * var(--coui-shadow-strength, 1))'));
    });

    test('shadow colour is the dark-mode-reactive --coui-shadow token', () {
      expect(filterVar('md'), contains('rgb(var(--coui-shadow))'));
    });

    test('none is the keyword', () {
      expect(filterVar('none'), equals('none'));
    });
  });

  group('ThemeConfig — Tailwind boxShadow scale', () {
    final config = ThemeConfig.defaults();
    final tw = config.tailwindConfig;

    test('overrides the boxShadow scale with the --shadow-* variables', () {
      expect(tw, contains('boxShadow:{'));
      expect(tw, contains('"sm":"var(--shadow-sm)"'));
      expect(tw, contains('"md":"var(--shadow-md)"'));
      expect(tw, contains('"lg":"var(--shadow-lg)"'));
      // Digit-first keys must be quoted to stay valid JS.
      expect(tw, contains('"2xl":"var(--shadow-2xl)"'));
      expect(tw, contains('"3xl":"var(--shadow-3xl)"'));
      expect(tw, contains('"inset":"var(--shadow-inset)"'));
    });
  });
}
