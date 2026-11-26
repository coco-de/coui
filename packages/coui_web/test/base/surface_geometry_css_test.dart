import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const _square = CoreSurfaceGeometryConstraint(radiusCap: 0);
const _thick = CoreSurfaceGeometryConstraint(
  strokeFloor: CoreStrokeWidth.stroke3,
);

void main() {
  mirrorGroup();
  final config = ThemeConfig.defaults();

  group('the bare border class is reachable', () {
    test('borderWidth declares a DEFAULT key', () {
      // Tailwind's own `border` utility reads `borderWidth.DEFAULT`. Without
      // this key it keeps Tailwind's built-in literal 1px, which would make
      // the most widely used border in the component set the one border a
      // surface style could never move.
      expect(
        config.tailwindConfig,
        contains('DEFAULT:"var(--coui-stroke-width-1)"'),
      );
    });

    test('the variable it points at is defined', () {
      expect(config.cssVariables, contains('--coui-stroke-width-1:'));
    });
  });

  group('a geometry statement becomes a rule', () {
    test('squaring corners moves every non-zero radius step', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _square,
      );

      expect(block, startsWith('[data-coui-style="neoBrutalism"]{'));
      expect(block, contains('--coui-radius-16:0.0px'));
      expect(block, contains('--coui-radius-9999:0.0px'));
    });

    test('a step the constraint does not move is omitted', () {
      // radius-0 is already 0, so writing it would assert a difference that
      // does not exist and grow the stylesheet for nothing.
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _square,
      );
      expect(block, isNot(contains('--coui-radius-0:')));
    });

    test('a stroke floor raises only the steps under it', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _thick,
      );

      expect(block, contains('--coui-stroke-width-1:3.0px'));
      expect(block, contains('--coui-stroke-width-2:3.0px'));
      expect(block, isNot(contains('--coui-stroke-width-4:')));
      expect(
        block,
        isNot(contains('--coui-stroke-width-0:')),
        reason: 'a suppressed border must stay suppressed',
      );
    });

    test('it is not qualified by brightness', () {
      // A radius is the same in light and dark; emitting it under both
      // would be two places to change one value.
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        _square,
      );
      expect(block, isNot(contains('data-theme')));
    });

    test('an identity constraint emits nothing', () {
      expect(
        config.surfaceStyleGeometryBlock(
          CoreSurfaceStyleId.neoBrutalism,
          const CoreSurfaceGeometryConstraint(),
        ),
        isEmpty,
      );
    });
  });

  group('a range reaches the stylesheet', () {
    test('clay redistributes the steps rather than flattening them', () {
      // The Flutter side reads the same function, so what this pins is
      // that the Web transport carries the *result* — a style whose
      // range only existed in Dart would leave every variable at its
      // authored value and the preset would look like the default.
      final recipe = CoreSurfaceRecipe.of(.claymorphism);
      final css = ThemeConfig.defaults().surfaceStyleGeometryBlock(
        .claymorphism,
        recipe.geometry,
        typography: recipe.typography,
      );

      final emitted = RegExp(r'--coui-radius-(\d+):([\d.]+)px')
          .allMatches(css)
          .map((m) => (double.parse(m.group(1)!), double.parse(m.group(2)!)))
          .toList();

      expect(emitted, isNotEmpty);
      for (final (authored, rendered) in emitted) {
        expect(
          rendered,
          recipe.geometry.radius(authored),
          reason: 'the stylesheet disagrees with the constraint at $authored',
        );
      }
      // Distinct in, distinct out — a clamp would emit one value.
      expect(emitted.map((e) => e.$2).toSet().length, greaterThan(1));
    });
  });

  group('shipped recipes', () {
    test('a rule exists exactly for the styles that state geometry', () {
      // Derived from the recipes rather than listing style names, so a new
      // style cannot be added without either emitting a rule or being
      // visibly neutral.
      final blocks = config.surfaceStyleVariableBlocks;
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.defaultId) continue;
        final recipe = CoreSurfaceRecipe.of(id);
        final states = !recipe.geometry.isIdentity;
        // A material surface — translucency, a blur — is the fourth thing
        // a recipe can state, and the glass preset states only that. Left
        // out, this reads its rule as unexplained.
        //
        // Checked over both roles: liquidGlass states the material on
        // functional and draws content flat (#4424), so a check scoped
        // to content alone would call this preset's own rule
        // unexplained.
        final material = CoreSurfaceRole.values.any((role) {
          final surface = recipe.surfaceFor(role);
          return surface != null &&
              (surface.blurRadius != null || !surface.opacity.isOpaque);
        });
        expect(
          blocks.contains('data-coui-style="${id.name}"'),
          states ||
              material ||
              !recipe.colorConstraint.isIdentity ||
              !recipe.typography.isIdentity,
          reason: '$id: rule presence disagrees with its recipe',
        );
      }
    });

    test('neo-brutalism raises the weight of light roles only', () {
      final blocks = config.surfaceStyleVariableBlocks;
      final overrides = RegExp(
        r'--coui-text-([a-z-]+)-weight:(\d+)',
      ).allMatches(blocks).toList();

      expect(overrides, isNotEmpty, reason: 'no weight override emitted');
      // Every emitted value is the floor, and a role already at or above it
      // is absent — writing it would claim a change that is not one.
      for (final m in overrides) {
        expect(m.group(2), '${CoreFontWeight.semiBold}');
      }
      expect(
        blocks,
        isNot(contains('--coui-text-title-large-weight')),
        reason: 'a role already at the floor was rewritten',
      );
    });

    test('neo-brutalism caps corners small and thickens borders', () {
      final blocks = config.surfaceStyleVariableBlocks;
      expect(blocks, contains('[data-coui-style="neoBrutalism"]{'));
      // Capped at 6, not squared to 0 — a true 0 reads as raw/unstyled
      // rather than the recognisable "neo-brutalism" look the reference
      // implementations this style is drawn from settle on.
      expect(blocks, contains('--coui-radius-16:4.0px'));
      expect(blocks, contains('--coui-stroke-width-1:4.0px'));
      expect(
        blocks,
        isNot(contains('--coui-stroke-width-0:')),
        reason: 'a suppressed border must stay suppressed',
      );
    });

    test('neo-brutalism bends the drop-shadow filter var too', () {
      // `Hover`'s `shadow` effect casts a non-inset stack through
      // `filter: drop-shadow()`, not `box-shadow`. Before `--shadow-*-filter`
      // existed, this variable simply was not written, so the effect stayed
      // the soft ambient `CoreShadow.lg` look under every style while its
      // `box-shadow` siblings (`--shadow-lg`, `--coui-control-shadow`) bent
      // to neo-brutalism's hard, opaque, diagonally-offset cast — the one
      // component on the page that visibly did not change preset.
      final blocks = config.surfaceStyleVariableBlocks;
      final recipe = CoreSurfaceRecipe.of(.neoBrutalism);
      final bent = recipe.geometry.shadow(CoreShadow.lg);

      // The bend actually changed the stack — otherwise this pins nothing.
      expect(bent, isNot(equals(CoreShadow.lg)));
      expect(bent.hasInset, isFalse);

      final expected = bent.toDropShadowValue(
        base: 'rgb(var(--coui-shadow))',
      );
      expect(blocks, contains('--shadow-lg-filter:$expected;'));
      // No blur, thrown down-and-right, fully opaque — the same reading
      // as the `--shadow-lg` (`box-shadow`) sibling this variable mirrors.
      expect(expected, isNot(contains('color-mix')));
    });

    test('drop-shadow() cannot express inset — no filter var for it', () {
      final blocks = config.surfaceStyleVariableBlocks;
      expect(blocks, isNot(contains('--shadow-inset-filter:')));
    });
  });
}

void mirrorGroup() {
  group('a mirrored stack reaches the browser as two layers', () {
    test('neumorphism emits each layer beside its opposite', () {
      // Both platforms run the same `geometry.shadow`, so this is not a
      // second implementation — it pins that the Web transport carries
      // the result rather than dropping it. A style whose signature is a
      // doubled shadow would otherwise look identical to one without on
      // exactly one platform.
      final css = ThemeConfig.defaults().surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neumorphism,
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.neumorphism).geometry,
      );
      final md = RegExp(r'--shadow-md:([^;]*);').firstMatch(css)?.group(1);

      expect(md, isNotNull);
      // Down-and-right, then up-and-left.
      expect(md, contains('0.5rem'));
      expect(md, contains('-0.5rem'));
    });

    test('and states no negative zero', () {
      // Valid CSS, pure noise. Negating a zero offset produces it unless
      // the subtraction is written the other way round.
      final css = ThemeConfig.defaults().surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neumorphism,
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.neumorphism).geometry,
      );

      expect(css, isNot(contains('-0rem')));
      expect(css, isNot(contains('-0.0rem')));
    });
  });
}
