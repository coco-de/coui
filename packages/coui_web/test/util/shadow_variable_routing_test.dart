import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  group('a scale step goes through the variable', () {
    test('each step resolves to its own variable', () {
      // A surface style bends shadow geometry by re-pointing these
      // variables. A component that bakes the layers into a literal instead
      // is opted out of every preset, and on screen that reads as "this one
      // component didn't change" rather than as a missing indirection.
      for (final (layers, key) in [
        (CoreShadow.xs, 'xs'),
        (CoreShadow.sm, 'sm'),
        (CoreShadow.md, 'md'),
        (CoreShadow.lg, 'lg'),
        (CoreShadow.xl, 'xl'),
        (CoreShadow.xl2, '2xl'),
        (CoreShadow.xl3, '3xl'),
        (CoreShadow.inset, 'inset'),
      ]) {
        expect(
          emitShadow(layers, base: kShadowVariableBase),
          'var(--shadow-$key)',
        );
      }
    });

    test('an empty stack is none, not an empty declaration', () {
      expect(emitShadow(const [], base: kShadowVariableBase), 'none');
    });
  });

  group('anything off the scale stays a literal', () {
    test('a stack the scale does not contain', () {
      const odd = [
        (
          offsetX: 0.0,
          offsetY: 3.0,
          blurRadius: 7.0,
          spreadRadius: 0.0,
          opacity: 0.11,
          inset: false,
        ),
      ];

      final css = emitShadow(odd, base: kShadowVariableBase);
      expect(css, isNot(contains('var(--shadow-')));
      expect(css, contains('color-mix'));
    });

    test('a per-instance tint override', () {
      // The variables are baked with one base. Routing a stack that would
      // have been tinted differently would silently recolour it, so an
      // overridden tint keeps its literal.
      final css = emitShadow(CoreShadow.md, base: 'rgb(var(--coui-primary))');
      expect(css, isNot(contains('var(--shadow-')));
      expect(css, contains('--coui-primary'));
    });
  });

  group('the default tint is the one the variables carry', () {
    test('every component that draws a shadow qualifies', () {
      // Six components used to pick their own shadow tint and four picked a
      // different token from the other two — which is exactly what made
      // routing impossible without changing how they looked.
      for (final base in <CoreColor>[
        CoreCardStyle.defaultShadowBaseColor,
        CorePopupStyle.defaultShadowBaseColor,
        CoreDrawerStyle.defaultShadowBaseColor,
        CoreFrameStyle.defaultShadowBaseColor,
        CoreDescriptionCardStyle.defaultShadowBaseColor,
        CoreHoverStyle.defaultShadowBaseColor,
      ]) {
        expect(base.toValue(), kShadowVariableBase);
        expect(
          emitShadow(CoreShadow.md, base: base.toValue()),
          'var(--shadow-md)',
        );
      }
    });
  });

  group('the filter: drop-shadow() twin routes the same way', () {
    // `Hover`'s `shadow` effect casts through `filter: drop-shadow()`
    // (no wrapper `border-radius` needed to match a rounded child) rather
    // than `box-shadow`. Unrouted, it baked `CoreShadow.lg`'s literal
    // blur/offset straight into `filter`, so a surface style bending
    // `--shadow-lg` never reached it — every other cast on the page moved
    // and this one alone stayed put.
    test('each non-inset step resolves to its own filter variable', () {
      for (final (layers, key) in [
        (CoreShadow.none, 'none'),
        (CoreShadow.xs, 'xs'),
        (CoreShadow.sm, 'sm'),
        (CoreShadow.md, 'md'),
        (CoreShadow.lg, 'lg'),
        (CoreShadow.xl, 'xl'),
        (CoreShadow.xl2, '2xl'),
        (CoreShadow.xl3, '3xl'),
      ]) {
        expect(
          emitDropShadowFilter(layers, base: kShadowVariableBase),
          layers.isEmpty ? 'none' : 'var(--shadow-$key-filter)',
        );
      }
    });

    test('inset has no filter variable — drop-shadow() cannot express one', () {
      // `drop-shadow()` cannot express an inset layer at all — the same
      // precondition `toDropShadowValue` itself asserts. A caller only
      // reaches this stack by skipping the `hasInset` guard `Hover` (and
      // any future caller) must check before taking the `filter` path,
      // so this stays a hard failure rather than a silently wrong var.
      expect(
        () => emitDropShadowFilter(CoreShadow.inset, base: kShadowVariableBase),
        throwsA(isA<AssertionError>()),
      );
    });

    test('anything off the scale stays a literal', () {
      final css = emitDropShadowFilter(
        CoreShadow.md,
        base: 'rgb(var(--coui-primary))',
      );
      expect(css, isNot(contains('var(--shadow-')));
      expect(css, contains('--coui-primary'));
    });
  });
}
