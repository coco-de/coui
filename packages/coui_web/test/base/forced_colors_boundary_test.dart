import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

void main() {
  final config = ThemeConfig.defaults();
  final blocks = config.surfaceStyleVariableBlocks;

  group('a shadow-bounded style gets a real edge in forced colours', () {
    test('the declared stroke is emitted, not a hardcoded one', () {
      // Read back through the contract rather than against a literal: the
      // point of this path is that the preset's own declaration reaches the
      // stylesheet, so a test asserting "1px" would still pass if the
      // declaration were ignored and the width came from somewhere else.
      final declared = CoreSurfaceRecipe.of(
        CoreSurfaceStyleId.neumorphism,
      ).a11y.forcedColorsBoundary;

      expect(declared, isNotNull, reason: 'the contract owes a fallback');
      expect(
        blocks,
        contains(
          '[data-coui-style="neumorphism"] .coui-surface'
          '{border-style:solid !important;'
          'border-width:${strokeWidthCss(declared!)} !important;}',
        ),
      );
    });

    test('it is inside a forced-colours query and nothing else', () {
      // Normal rendering must be untouched — the whole correction lives
      // behind the media query, so a style with a shadow boundary looks
      // exactly as authored until the mode is on.
      // Anchored on the boundary declaration rather than on the surface
      // marker. The marker is a general hook — a style preset targets the
      // same class to give the surface a material — so searching for it
      // finds whichever rule happens to come first in the sheet and says
      // nothing about where the correction lives.
      //
      // Every occurrence, not the first: one declaration escaping the
      // query is the whole failure this guards against.
      const boundary = 'border-style:solid !important';
      var found = 0;
      for (
        var at = blocks.indexOf(boundary);
        at >= 0;
        at = blocks.indexOf(boundary, at + 1)
      ) {
        found++;
        final opened = blocks.lastIndexOf('@media (forced-colors:active){', at);
        expect(opened, greaterThan(-1), reason: 'boundary outside any query');
        expect(
          blocks.substring(opened, at).contains('}}'),
          isFalse,
          reason: 'the forced-colours query closed before the boundary',
        );
      }
      expect(found, greaterThan(0));
    });

    test('the stroke wins over the inline width the surface writes', () {
      // The surface primitive always writes `border-width` inline, and an
      // inline declaration outranks every selector. Without `!important`
      // this rule would parse, match, and change nothing — the exact shape
      // of an accessibility promise that is declared and never drawn.
      expect(
        blocks,
        contains('border-width:${strokeWidthCss(1)} !important'),
      );
    });
  });

  group('styles that owe no fallback emit nothing', () {
    test('a style bounded by a real stroke is left alone', () {
      // Forced colours recolours a stroke, so such a boundary survives on
      // its own. Emitting a rule anyway would be dead CSS asserting a
      // difference no one can see.
      // Collected before it is asserted on, and checked for being there.
      // Filtered in place, this loop empties out the day every style
      // declares a fallback — and that is the direction the codebase
      // moves in, so the test would go quiet exactly as the thing it
      // guards became easier to break elsewhere. It was measured: giving
      // the contract a non-null default left this green and silent.
      final owingNothing = CoreSurfaceStyleId.values
          .where(
            (id) => CoreSurfaceRecipe.of(id).a11y.forcedColorsBoundary == null,
          )
          .toList();

      expect(owingNothing, isNotEmpty);
      for (final id in owingNothing) {
        expect(
          config.surfaceStyleForcedColorsBlock(
            id,
            CoreSurfaceRecipe.of(id).a11y,
          ),
          isEmpty,
          reason: '$id states no fallback',
        );
      }
    });

    test('exactly the shadow-bounded styles carry a rule', () {
      final owing = CoreSurfaceStyleId.values
          .where(
            (id) =>
                CoreSurfaceRecipe.of(id).a11y.boundaryMechanism ==
                CoreSurfaceBoundaryMechanism.shadow,
          )
          .toList();

      expect(owing, isNotEmpty);
      for (final id in owing) {
        expect(
          config.surfaceStyleForcedColorsBlock(
            id,
            CoreSurfaceRecipe.of(id).a11y,
          ),
          isNotEmpty,
          reason: '$id is bounded by shadow alone',
        );
      }
    });
  });

  group('the hook the rule matches on actually reaches the surface', () {
    testComponents('the primitive puts the marker on its root', (tester) async {
      // The rule above is written against `.coui-surface`. If the primitive
      // stopped emitting it the stylesheet would stay perfectly valid,
      // match nothing, and restore no boundary — a correction present in
      // the CSS and absent from the screen. A CSS-only test cannot see that
      // half, which is why this one resolves the primitive and reads the
      // class back.
      String? seen;

      pumpWithTheme(
        tester,
        _CaptureRoot(onResolved: (className) => seen = className),
      );
      await tester.pump();

      expect(seen, isNotNull);
      expect(seen, contains(kWebSurfaceMarker));
    });
  });

  group('the glass band is decoration, and forced colours erases it', () {
    // Measured in headless Chrome with `Emulation.setEmulatedMedia`
    // `forced-colors: active`, on a `.coui-surface` under
    // `[data-coui-style="liquidGlass"]`:
    //
    //   normal  background-image: linear-gradient(to right, …) ×4
    //           border:           1px solid rgb(174, 175, 178)
    //   forced  background-image: none, none, none, none   ← every layer
    //           border:           1px solid rgb(255, 255, 255)
    //
    // So the band does not survive the mode and the stroke does, recoloured
    // to a system colour. That is the right way round — but only because
    // the band never carried the boundary. These tests pin the structural
    // property that makes it so, since a Dart test cannot re-run Chrome and
    // a one-off measurement is not a regression net.

    test('the band declares paint, never an edge', () {
      // If a later edit moved `border-*` or `outline-*` into this rule, the
      // measurement above would silently invert: the edge would ride
      // `background-image`'s fate and vanish with it, leaving the surface
      // unbounded in exactly the mode a user turned on to see boundaries.
      final band = blocks.substring(
        // Role-qualified since the depth ladder — every rule carries a
        // role class so depth can never tie with role.
        blocks.indexOf(
          '[data-coui-style="liquidGlass"] '
          '.coui-surface.coui-surface-functional::after',
        ),
      );
      final rule = band.substring(0, band.indexOf('}') + 1);

      expect(rule, contains('background-image:'));

      // Read the property names rather than searching the rule for words.
      // A run's colour may legitimately name a token whose slot is called
      // `outline`, and that reaches the sheet as `var(--coui-outline)` —
      // a substring search cannot tell that apart from an `outline:`
      // declaration, and would report the band drawing an edge when it is
      // only borrowing a colour.
      final body = rule.substring(rule.indexOf('{') + 1, rule.lastIndexOf('}'));
      final declared = body
          .split(';')
          .where((part) => part.contains(':'))
          .map((part) => part.substring(0, part.indexOf(':')).trim())
          .toSet();

      expect(declared, contains('background-image'));
      // `border-radius` is exempt and has to be: the band inherits the
      // surface's corners so it does not paint square over a rounded
      // card. A radius states a shape, not an edge — what must stay out
      // is anything that would *draw* one.
      for (final property in const [
        'border-style',
        'border-width',
        'border-color',
        'border',
        'outline',
        'outline-style',
        'outline-width',
        'outline-color',
      ]) {
        expect(
          declared,
          isNot(contains(property)),
          reason: 'the band must not draw an edge',
        );
      }

      // `box-shadow` is admitted, but only inset.
      //
      // The property is two different things depending on that keyword. An
      // outer layer at zero blur is a ring around the shape — an outline
      // spelled differently, and one this mode does not force, so a style
      // leaning on it would lose its boundary exactly where a user turned
      // the mode on to get one. An inset layer is drawn *inside* the shape
      // and cannot reach the edge from outside, so it can decorate the
      // edge but never be it.
      //
      // The material's edge wall is that inset kind: light down the near
      // side of a pane. Like the runs above it disappears in forced
      // colours, and like them it is not what the boundary rests on — the
      // suppressed stroke is handed back for that, which the next test
      // checks.
      final shadow = body
          .split(';')
          .where((part) => part.trim().startsWith('box-shadow:'))
          .join();
      if (shadow.isNotEmpty) {
        // Split on top-level commas only. A layer's colour is a
        // `color-mix(in srgb, …, transparent)`, whose own commas would
        // otherwise cut it into fragments that start with neither
        // `inset` nor anything else meaningful — the assertion would then
        // fail on correct CSS and pass on nothing.
        final layers = <String>[];
        final layer = StringBuffer();
        var depth = 0;
        for (final ch in shadow.substring(shadow.indexOf(':') + 1).split('')) {
          if (ch == '(') depth++;
          if (ch == ')') depth--;
          if (ch == ',' && depth == 0) {
            layers.add(layer.toString());
            layer.clear();
          } else {
            layer.write(ch);
          }
        }
        layers.add(layer.toString());

        for (final one in layers) {
          expect(
            one.trim(),
            startsWith('inset '),
            reason: 'an outer layer on the band is an outline in disguise',
          );
        }
      }
    });

    test('so the style cannot lean on the stroke it suppresses', () {
      // This used to read the other way, and the reason it changed is the
      // point: the style now sets `drawsOwnEdge`, so the component's stroke
      // is painted transparent and the band above is the whole boundary.
      // The band is `background-image`, which the mode erases — leaving a
      // declaration of `.stroke` claiming an edge that does not survive.
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

      expect(recipe.functionalSurface?.drawsOwnEdge, isTrue);
      // The content role is the same glass, so its stroke is suppressed
      // the same way — and the restore below has to be emitted for it
      // too, or a card has no edge at all in the one mode a user turns on
      // to see edges. Pinned here so the role cannot regain a stroke on
      // one platform alone.
      expect(recipe.surface?.drawsOwnEdge, isTrue);
      expect(
        recipe.a11y.boundaryMechanism,
        CoreSurfaceBoundaryMechanism.shadow,
      );
      expect(recipe.a11y.forcedColorsBoundary, isNotNull);
    });

    test('the suppressed edge is handed back where the band dies', () {
      // Measured absence: deleting both media blocks left every suite in
      // this repo green. That is the whole accessibility half of the
      // suppression — without them a glass surface has no boundary at all
      // in the one mode a user turns on to see boundaries.
      // Both roles: each suppresses its stroke, so each needs the
      // restore. A loop rather than the floating role alone, because the
      // content role is the one every card draws.
      final recipe = CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);
      for (final role in CoreSurfaceRole.values) {
        final treatment = config.surfaceStyleTreatmentBlock(
          CoreSurfaceStyleId.liquidGlass,
          recipe.surfaceFor(role),
          role: role,
        );

        for (final query in const [
          '@media (forced-colors:active)',
          '@media (prefers-contrast:more)',
        ]) {
          final at = treatment.indexOf(query);
          expect(at, greaterThan(-1), reason: '$query is missing for $role');
          // The restore must name a real colour, not merely mention the
          // property — a block that repeated `transparent` would read as
          // present and hand back nothing.
          final block = treatment.substring(at, treatment.indexOf('}', at) + 1);
          expect(block, contains('border-color:rgb(var(--coui-outline))'));
          expect(block, contains('!important'));
          expect(block, isNot(contains('transparent')));
        }
      }
    });

    test('and only styles that suppress an edge emit that pair', () {
      // Non-derived on purpose. Both loops in this file filter on the
      // contract, so a preset that moved between mechanisms would change
      // which loop examines it without failing anything — the file has
      // already recorded one vacuity of exactly that shape.
      // Asked of **both roles**. A style suppresses an edge if either of
      // its materials does, and under liquid glass only the functional one
      // does — reading `surface` alone reports that nothing in the kit
      // suppresses anything, and the loop below then agrees with itself
      // about a restore nobody emits. Same rule the recipe states for its
      // own emptiness check: a style is not a no-op if *either* material
      // draws.
      bool suppressesAnEdge(CoreSurfaceStyleId id) {
        final recipe = CoreSurfaceRecipe.of(id);
        return CoreSurfaceRole.values.any(
          (role) => recipe.surfaceFor(role)?.drawsOwnEdge ?? false,
        );
      }

      final suppressing = CoreSurfaceStyleId.values
          .where(suppressesAnEdge)
          .toSet();

      expect(suppressing, {CoreSurfaceStyleId.liquidGlass});

      // Per role, because the restore is emitted per role too. The pair is
      // owed by the role that suppresses, and owed by no other — a style
      // that handed it to its content layer would be recolouring a stroke
      // it never took away.
      for (final id in CoreSurfaceStyleId.values) {
        for (final role in CoreSurfaceRole.values) {
          final material = CoreSurfaceRecipe.of(id).surfaceFor(role);
          final treatment = config.surfaceStyleTreatmentBlock(
            id,
            material,
            role: role,
          );
          expect(
            treatment.contains('forced-colors:active'),
            material?.drawsOwnEdge ?? false,
            reason:
                '$id/${role.name} emits a restore it does not owe, or owes '
                'one it omits',
          );
        }
      }
    });

    test('and the suppressed stroke keeps the box its fallback recolours', () {
      // Re-aimed from a geometry proxy. The property the fallback actually
      // rests on is that suppression is paint-only — a zeroed width would
      // leave forced colours nothing to paint, and would move layout on a
      // style swap that is supposed to change paint alone.
      final treatment = config.surfaceStyleTreatmentBlock(
        CoreSurfaceStyleId.liquidGlass,
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass).functionalSurface,
        role: CoreSurfaceRole.functional,
      );
      // The surface rule only — the media blocks below it legitimately name
      // `border-color` again to hand the edge back.
      final rule = treatment.substring(0, treatment.indexOf('}') + 1);

      expect(rule, contains('border-color:transparent !important'));
      expect(rule, isNot(contains('border-width')));
      expect(rule, isNot(contains('border:')));
    });
  });
}

class _CaptureRoot extends StatelessComponent {
  const _CaptureRoot({required this.onResolved});

  final void Function(String) onResolved;

  @override
  Component build(BuildContext context) {
    onResolved(resolveOutlinedContainer(context: context).root.className);

    return const Component.text('surface');
  }
}
