import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

String _rgb(CoreColor c) => '${c.red} ${c.green} ${c.blue}';

void main() {
  final config = ThemeConfig.defaults();
  const source = CouiColorPresets.source;

  group('the dark rule comes from the library', () {
    test('it is a complete, selector-qualified rule', () {
      // Assembling this selector used to be each app's job, which meant
      // every app had to know the attribute name and the variable list.
      final block = config.darkVariableBlock;
      expect(block, startsWith('[data-theme="dark"]{'));
      expect(block, endsWith('}'));
    });

    test('it carries the dark semantic values', () {
      final block = config.darkVariableBlock;
      config.semanticDarkVars.forEach((key, value) {
        expect(block, contains('$key:$value'));
      });
    });
  });

  group('surface-style rules', () {
    test('a style that says nothing at all emits nothing', () {
      // Emitting a block for a style that changes nothing would be
      // identical CSS that still has to be parsed, and would imply a
      // difference nobody can see.
      final blocks = config.surfaceStyleVariableBlocks;
      for (final id in CoreSurfaceStyleId.values) {
        final recipe = CoreSurfaceRecipe.of(id);
        // `statesNothing` is the single source for this predicate — shared
        // with the parity pipeline's pruning rule (`kRedundantSurfaceStyles`)
        // so the two never drift on what "this style is a no-op" means. A
        // material surface is a fourth thing a recipe can state, and it is
        // stated by exactly the style this test used to certify as silent —
        // the glass preset carried a translucency and a blur that the Web
        // never emitted, so "emits nothing" was true and was the defect.
        if (!recipe.statesNothing) continue;
        expect(
          blocks,
          isNot(contains('data-coui-style="${id.name}"')),
          reason: '$id states nothing but got a rule',
        );
      }
    });

    test('the style that does make one is emitted', () {
      // Neo-brutalism pushes the boundary tones toward the foreground, so
      // it writes those and only those.
      final blocks = config.surfaceStyleVariableBlocks;
      expect(blocks, contains('[data-coui-style="neoBrutalism"]{'));
      expect(blocks, contains('--coui-outline:'));
      expect(
        blocks,
        isNot(contains('--coui-on-surface:')),
        reason: 'a slot it did not change would override high contrast',
      );
    });

    test('a style that does make one emits both modes', () {
      // Exercises the real generator with a colour statement so the path is
      // proven now rather than the first time a preset story needs it.
      const vivid = CoreSurfaceColorConstraint(accentChromaScale: 1.6);
      final block = config.surfaceStyleBlock(
        CoreSurfaceStyleId.neoBrutalism,
        vivid,
      );

      expect(block, contains('[data-coui-style="neoBrutalism"]{'));
      expect(
        block,
        contains('[data-theme="dark"][data-coui-style="neoBrutalism"]{'),
      );

      // `defaults()` renders the CoUI look, so the expectation reads CoUI's
      // OWN source — the base the style block deltas against.
      final expected = vivid.apply(source.light()).resolved(.light);
      expect(block, contains('--coui-primary:${_rgb(expected.primary)};'));
      expect(
        _rgb(expected.primary),
        isNot(_rgb(source.light().resolved(.light).primary)),
        reason: 'the rule must differ from the base or it is dead CSS',
      );
    });

    test('the default style is never given a rule', () {
      // The base rules already describe it, so a rule would be a second
      // spelling of the same state.
      expect(
        config.surfaceStyleVariableBlocks,
        isNot(contains('data-coui-style="defaultStyle"')),
      );
    });
  });

  group('brightness and style stay independent', () {
    test('the seat combines them without either erasing the other', () {
      // Through `surfaceStyleBlock` — the transport, not `.apply()` alone.
      // `.apply()` proves the Core constraint computes the fold; it says
      // nothing about whether that fold reaches a CSS variable a browser
      // will read. #3462 was exactly that gap: this exact assertion
      // passed against `.apply()` while `_schemeVarsDelta` dropped every
      // surface-family slot, so neumorphism computed correctly and
      // rendered as whatever the base surface tones already were.
      const flat = CoreSurfaceColorConstraint(surfaceMatchesStage: true);
      final block = config.surfaceStyleBlock(.neumorphism, flat);

      final lightSurface = source.light().resolved(.light).surface;
      final darkSurface = source.dark().resolved(.dark).surface;

      // The style's effect survives in both modes: the emitted rule
      // restates `surface-container` as the *page* surface colour, not
      // as whatever tone the unstyled scheme would have used there.
      expect(
        block,
        contains('--coui-surface-container:${_rgb(lightSurface)};'),
      );
      expect(
        block,
        contains('--coui-surface-container:${_rgb(darkSurface)};'),
      );
      // ...and the modes remain distinguishable under the style — light's
      // fold and dark's fold restate two different colours, not the same
      // one twice.
      expect(_rgb(lightSurface), isNot(equals(_rgb(darkSurface))));
    });

    test('the dark style rule outranks the plain style rule', () {
      // Both would be single-attribute selectors, so at equal specificity
      // the later rule wins outright and dark loses to styled — the two
      // axes stop combining. The dark rule qualifies both attributes to
      // outrank it, and it must also come after in source order.
      const vivid = CoreSurfaceColorConstraint(accentChromaScale: 1.6);
      final block = config.surfaceStyleBlock(
        CoreSurfaceStyleId.neoBrutalism,
        vivid,
      );

      final plain = block.indexOf('[data-coui-style="neoBrutalism"]{');
      final qualified = block.indexOf(
        '[data-theme="dark"][data-coui-style="neoBrutalism"]{',
      );

      expect(plain, isNonNegative);
      expect(qualified, greaterThan(plain));
    });
  });

  group('the switch and the stylesheet agree on one attribute name', () {
    test('the exported constant is what the rules use', () {
      expect(kSurfaceStyleAttribute, 'data-coui-style');
    });

    test('reading with no attribute set gives the default', () {
      // Server-side there is no document at all, which must read as "no
      // style chosen" rather than throwing.
      expect(
        SurfaceStyleScope.currentSurfaceStyle(),
        CoreSurfaceStyleId.defaultId,
      );
    });
  });
}
