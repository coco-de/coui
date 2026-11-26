import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreSurfaceRecipe _glass() =>
    CoreSurfaceRecipe.of(CoreSurfaceStyleId.liquidGlass);

/// The glass preset with an opaque content layer — a recipe that states
/// two materials, which the shipped one no longer does. What the axis can
/// express is asserted here; what the preset chose is asserted on
/// [_glass].
CoreSurfaceRecipe _twoMaterials() =>
    _glass().copyWith(surface: const CoreSurfaceToken.flat());

void main() {
  group('the role is stated by the surface, not inferred by the axis', () {
    test('the axis carries no component list', () {
      // The failure this shape exists to prevent: a table of which
      // components float, which is wrong the day someone adds one and
      // does not find it — silently, because the new surface just gets
      // the other material.
      //
      // Checked as a property of the type rather than by grepping a
      // file: an enum with exactly two members cannot be a component
      // list, and a third member would have to be named here.
      expect(CoreSurfaceRole.values, hasLength(2));
      expect(
        CoreSurfaceRole.values.toSet(),
        {CoreSurfaceRole.functional, CoreSurfaceRole.content},
      );
    });

    test('a surface that says nothing sits in the content layer', () {
      // The safe direction. Being wrong this way costs a material that
      // is slightly too plain; being wrong the other way gives a
      // component in the page flow a material designed to sit over it.
      expect(CoreSurfaceRole.defaultRole, CoreSurfaceRole.content);
    });
  });

  group('a style states a material per role', () {
    test('the two roles can resolve to different materials', () {
      // The acceptance criterion: the split has to be able to reach
      // something. An axis whose two roles could only ever resolve to the
      // same token would be a field, not an axis.
      //
      // Asserted on a recipe that states two materials, not on the shipped
      // glass preset — which, by decision, dresses both roles in the same
      // glass (see the preset's note). The axis still carries the split;
      // that preset just does not use it.
      final recipe = _twoMaterials();

      expect(recipe.surfaceFor(CoreSurfaceRole.content), isNotNull);
      expect(
        recipe.surfaceFor(CoreSurfaceRole.functional),
        isNot(recipe.surfaceFor(CoreSurfaceRole.content)),
      );
    });

    test('and the shipped glass gives both roles one material', () {
      // The decision, pinned so it cannot drift back one field at a time:
      // a card and a popover are made of the same glass. The roles differ
      // by where they sit and by what nesting hands them, not by material.
      final recipe = _glass();

      expect(
        recipe.surfaceFor(CoreSurfaceRole.content)!.type,
        SurfaceType.glass,
      );
      expect(
        recipe.surfaceFor(CoreSurfaceRole.functional),
        recipe.surfaceFor(CoreSurfaceRole.content),
      );
    });

    test('a style with one material gives it to both roles', () {
      // Null does not mean "floating surfaces get nothing" — it means
      // the style draws no distinction. Most styles have one material or
      // none, and making them restate it is how two copies drift.
      const one = CoreSurfaceToken.flat();
      const recipe = CoreSurfaceRecipe(
        id: .defaultStyle,
        a11y: .defaultSurface,
        surface: one,
      );

      expect(recipe.surfaceFor(CoreSurfaceRole.functional), one);
      expect(recipe.surfaceFor(CoreSurfaceRole.content), one);
    });

    test('a style with no material gives neither role one', () {
      const recipe = CoreSurfaceRecipe(
        id: .defaultStyle,
        a11y: .defaultSurface,
      );

      expect(recipe.surfaceFor(CoreSurfaceRole.functional), isNull);
      expect(recipe.surfaceFor(CoreSurfaceRole.content), isNull);
    });

    test('dressing only the floating half is not expressible', () {
      // A functional material with no content material would dress every
      // overlay and leave every card bare. Expressible in the field
      // layout, never intended, and silent if it happened.
      expect(
        () => CoreSurfaceRecipe(
          id: .defaultStyle,
          a11y: .defaultSurface,
          functionalSurface: const CoreSurfaceToken.flat(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the role material survives the value-equality gate', () {
    test('two recipes differing only in the floating material differ', () {
      // Left out of `==`, a restyled overlay compares equal to the
      // shipped one, the framework decides nothing needs rebuilding, and
      // the material is computed correctly and never drawn.
      final base = _glass();
      final swapped = CoreSurfaceRecipe(
        id: base.id,
        a11y: base.a11y,
        colorConstraint: base.colorConstraint,
        geometry: base.geometry,
        typography: base.typography,
        surface: base.surface,
        functionalSurface: base.surface,
        overlayMorph: base.overlayMorph,
        refraction: base.refraction,
      );

      expect(swapped, isNot(base));
      expect(swapped.hashCode, isNot(base.hashCode));
    });
  });

  group('a style is a no-op only when neither material draws', () {
    test('a style whose floating material draws is not pruned', () {
      // `statesNothing` gates two independent things — whether the Web
      // sheet emits a rule and whether the parity matrix keeps a row.
      // Reading only the content material would drop both for a style
      // whose floating material is the interesting one, silently.
      const recipe = CoreSurfaceRecipe(
        id: .defaultStyle,
        a11y: .defaultSurface,
        surface: CoreSurfaceToken.flat(),
        functionalSurface: CoreSurfaceToken.glass(
          opacity: CoreSurfaceOpacity.same(0.5),
          blur: 12,
        ),
      );

      expect(recipe.statesNothing, isFalse);
    });

    test('and the baseline style still states nothing', () {
      expect(
        CoreSurfaceRecipe.of(CoreSurfaceStyleId.defaultStyle).statesNothing,
        isTrue,
      );
    });
  });

  group('a material thins once it sits inside another surface', () {
    test('the two platforms read one statement, not two', () {
      // The reason this moved to the recipe at all. The policy used to
      // live in the Web emitter alone, so Flutter never had it and ran a
      // second backdrop pass at full strength — measured at two σ-16
      // filters, composing to σ≈22.6 where the Web drew σ-16. Same code,
      // two screens.
      final recipe = _glass();

      expect(recipe.nestedSurfaces, isNotNull);
      for (final role in CoreSurfaceRole.values) {
        expect(
          recipe.nestedSurfaces![role],
          isNotEmpty,
          reason:
              '${role.name} has no nested material, so one platform '
              'will keep whatever it happened to do',
        );
      }
    });

    test('nesting drops the backdrop pass and keeps the rest', () {
      // Both roles are glass, so both have a backdrop pass to drop, and
      // both drop it the same way — one written answer per role, so the
      // two platforms cannot each decide for themselves.
      final recipe = _glass();

      for (final role in CoreSurfaceRole.values) {
        final base = recipe.surfaceFor(role)!;
        final nested = recipe.surfaceFor(role, depth: 1)!;

        expect(base.blurRadius, isNotNull, reason: role.name);
        expect(
          nested.blurRadius,
          isNull,
          reason: '${role.name} stacks glass on glass',
        );
        // Deliberate: a nested surface still reads as translucent and
        // still draws its own edge.
        expect(nested.opacity, base.opacity, reason: role.name);
        expect(nested.sheen, base.sheen, reason: role.name);
      }
    });

    test('the content layer is glass at the top and thin underneath', () {
      // The content layer used to be pinned opaque at every depth; that
      // was the previous decision and this is the new one, stated with
      // the same precision. At the top a card is the full material. Inside
      // another surface it keeps the fill and the band and drops the
      // backdrop pass — the same thinning the functional layer gets,
      // because a card in a dialog and a menu in a dialog are the same
      // situation.
      final recipe = _glass();
      final top = recipe.surfaceFor(CoreSurfaceRole.content)!;

      expect(top.type, SurfaceType.glass);
      expect(top.opacity.isOpaque, isFalse);
      expect(top.blurRadius, isNotNull);
      expect(top.sheen, isNotNull);

      for (final depth in [1, 2, 9]) {
        final content = recipe.surfaceFor(
          CoreSurfaceRole.content,
          depth: depth,
        )!;

        expect(content.blurRadius, isNull, reason: 'depth $depth frosts again');
        expect(content.opacity, top.opacity, reason: 'depth $depth');
        expect(content.sheen, top.sheen, reason: 'depth $depth');
        expect(
          content,
          recipe.surfaceFor(CoreSurfaceRole.functional, depth: depth),
          reason: 'depth $depth: the two roles thin differently',
        );
      }
    });

    test('and deeper keeps the floor rather than thinning away', () {
      // Without a floor a card inside a dialog inside a menu thins into
      // a material that is not there — and three deep is a real screen,
      // not a hypothetical.
      final recipe = _glass();
      final floor = recipe.surfaceFor(CoreSurfaceRole.content, depth: 1);

      for (final depth in [2, 3, 9]) {
        expect(
          recipe.surfaceFor(CoreSurfaceRole.content, depth: depth),
          floor,
          reason: 'depth $depth ran past the end of the table',
        );
      }
    });

    test('a style that states no nesting is unchanged at any depth', () {
      const recipe = CoreSurfaceRecipe(
        id: .defaultStyle,
        a11y: .defaultSurface,
        surface: CoreSurfaceToken.flat(),
      );

      expect(
        recipe.surfaceFor(CoreSurfaceRole.content, depth: 3),
        recipe.surfaceFor(CoreSurfaceRole.content),
      );
    });

    test('the table compares by value, not by identity', () {
      // A `Map` of `List`s hashes by reference. Left that way, an author
      // retuning the table in place would compare *equal* to the shipped
      // one and the framework would never rebuild — the material would be
      // computed correctly and never drawn.
      final a = _glass();
      final b = a.copyWith(
        nestedSurfaces: {
          CoreSurfaceRole.content: [const CoreSurfaceToken.flat()],
          CoreSurfaceRole.functional: [const CoreSurfaceToken.flat()],
        },
      );

      expect(b, isNot(a));
      expect(b.hashCode, isNot(a.hashCode));
    });
  });

  group('a role flip is a no-op on the styles that state no material', () {
    // The acceptance condition this story ships under: the four
    // non-glass presets must render the 29 surfaces exactly as before.
    //
    // Asserted at the axis rather than by counting pixels, because that
    // is where the property actually lives — a preset that hands both
    // roles the same answer cannot draw them differently no matter which
    // one a component declares. The pixel half is the parity gate's job;
    // this is the half that says *why* those pixels cannot move.
    const nonGlass = [
      CoreSurfaceStyleId.defaultStyle,
      CoreSurfaceStyleId.neoBrutalism,
      CoreSurfaceStyleId.claymorphism,
      CoreSurfaceStyleId.neumorphism,
    ];

    for (final id in nonGlass) {
      test('${id.name}: both roles resolve to the same material', () {
        final recipe = CoreSurfaceRecipe.of(id);

        expect(
          recipe.surfaceFor(CoreSurfaceRole.functional),
          recipe.surfaceFor(CoreSurfaceRole.content),
          reason:
              'a component switching its declared role under ${id.name} '
              'would change what it draws, and this story switches one',
        );
      });

      test('${id.name}: depth resolves the same way for both roles', () {
        // Nesting is the second place a role could split a preset that
        // states one material. A style with no nesting table returns the
        // base at every depth; one with a table has to answer per role.
        final recipe = CoreSurfaceRecipe.of(id);

        for (var depth = 0; depth <= 4; depth++) {
          expect(
            recipe.surfaceFor(CoreSurfaceRole.functional, depth: depth),
            recipe.surfaceFor(CoreSurfaceRole.content, depth: depth),
            reason: 'depth $depth under ${id.name}',
          );
        }
      });
    }

    test('a style that states two materials is where the flip is visible', () {
      // The negative control. Without it the four assertions above pass
      // just as well against a build where roles stopped working at all,
      // which is the failure mode a same-value check cannot see. It runs
      // on a two-material recipe because the shipped glass no longer is
      // one — both of its roles are glass by decision.
      final recipe = _twoMaterials();

      expect(
        recipe.surfaceFor(CoreSurfaceRole.functional),
        isNot(recipe.surfaceFor(CoreSurfaceRole.content)),
      );
    });
  });
}
