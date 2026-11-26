import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The material the *floating* layer gets under liquid glass — the glass one.
CoreSurfaceToken _functionalSurface() => CoreSurfaceRecipe.of(
  CoreSurfaceStyleId.liquidGlass,
).surfaceFor(CoreSurfaceRole.functional)!;

/// The material the *content* layer gets — a standard material, not glass.
///
/// Apple's line, and the reason the role axis exists: the functional layer
/// is glass, the content layer is not. Kept as its own accessor so the
/// tests below can assert the absence as deliberately as the presence.
CoreSurfaceToken _contentSurface() => CoreSurfaceRecipe.of(
  CoreSurfaceStyleId.liquidGlass,
).surfaceFor(CoreSurfaceRole.content)!;

void main() {
  group('what liquid glass actually renders', () {
    test('is the translucency and the blur, and both are stated', () {
      // These two are what reach a renderer — Flutter reads them into
      // `surfaceOpacity` / `surfaceBlur` and draws a `BackdropFilter`,
      // and the Web has the same pair. The style is not a placeholder;
      // it produces a visible result today.
      final surface = _functionalSurface();

      expect(surface.opacity.isOpaque, isFalse);
      expect(surface.blurRadius, isNotNull);
      expect(surface.blurRadius, greaterThan(0));
    });

    test('and the style is the only one stating a translucent surface', () {
      // Pins the reason the a11y contract reports `usesTransparency` for
      // this style and no other: a reduce-transparency request has
      // exactly one style to fall back from.
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.liquidGlass) continue;
        final surface = CoreSurfaceRecipe.of(id).surface;

        expect(
          surface == null || surface.opacity.isOpaque,
          isTrue,
          reason: '${id.name} states a translucent surface too',
        );
      }
    });
  });

  group('the edge wall is a value the axis can carry', () {
    test('the glass edge states one', () {
      final sheen = _functionalSurface().sheen;

      expect(sheen, isNotNull);
      expect(
        sheen!.bevel,
        isNotNull,
        reason: 'the edge is a band again, so it reads as a line',
      );
      expect(sheen.bevel!.toLayers(), isNotEmpty);
    });

    test('changing it changes the value', () {
      // The rule this axis breaks most quietly. A field left out of `==`
      // makes a retuned recipe compare equal to the shipped one, the
      // framework decides nothing needs rebuilding, and the wall is
      // computed correctly and never drawn — with nothing in any output
      // to say why. Both directions, because a `hashCode` that ignores
      // the field lands two unequal values in one bucket.
      final shipped = _functionalSurface().sheen!;
      final without = CoreSurfaceEdgeSheen(
        width: shipped.width,
        lightColor: shipped.lightColor,
        darkColor: shipped.darkColor,
        fade: shipped.fade,
      );

      expect(without, isNot(shipped));
      expect(without.hashCode, isNot(shipped.hashCode));
    });

    test('and two walls stated apart still compare equal', () {
      // The other half. A value type that compared by identity would make
      // every rebuild look like a change, and every theme crossfade would
      // repaint a wall that did not move.
      final shipped = _functionalSurface().sheen!;
      final copied = shipped.copyWith(
        bevel: CoreSurfaceEdgeBevel(
          thickness: shipped.bevel!.thickness,
          lightAngle: shipped.bevel!.lightAngle,
          lightIntensity: shipped.bevel!.lightIntensity,
          glowSpread: shipped.bevel!.glowSpread,
          rimWidth: shipped.bevel!.rimWidth,
          rimIntensity: shipped.bevel!.rimIntensity,
        ),
      );

      expect(copied, shipped);
      expect(copied.hashCode, shipped.hashCode);
    });
  });

  group('the dimming term is a value the axis can carry', () {
    test('an unstated one is identity, not zero', () {
      // A default of 0 would make every surface that never mentions
      // brightness paint its backdrop black. The identity for a
      // multiply is 1, and every constructor has to agree — the flat
      // and tonal ones state it in an initializer list where a missed
      // field is a compile error, but the main constructor takes a
      // default and a wrong one there is silent.
      expect(
        const CoreSurfaceToken.flat().backdropBrightness,
        CoreBackdropBrightness.identity,
      );
      expect(
        const CoreSurfaceToken.tonalElevation(
          elevation: 2,
        ).backdropBrightness,
        CoreBackdropBrightness.identity,
      );
      expect(
        const CoreSurfaceToken(type: SurfaceType.flat).backdropBrightness,
        CoreBackdropBrightness.identity,
      );
    });

    test('changing it changes the value', () {
      // The rule this axis breaks most quietly, and the one the
      // acceptance criteria name first: a field left out of `==` makes a
      // dimmed recipe compare equal to an undimmed one, the framework
      // decides nothing needs rebuilding, and the term is computed
      // correctly and never drawn. Both directions, because a `hashCode`
      // that ignores the field lands two unequal values in one bucket.
      const bright = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
      );
      const dim = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
        backdropBrightness: CoreBackdropBrightness.same(0.25),
      );

      expect(dim, isNot(bright));
      expect(dim.hashCode, isNot(bright.hashCode));
    });

    test('only the glass material dims, and it dims in both roles', () {
      // The acceptance criterion this story states last: the non-glass
      // presets render one pixel for one pixel. They get that from the
      // identity default — a preset that started stating a value here
      // would emit a filter function it never had.
      //
      // Written as a loop over every style rather than a list of four, so
      // a fifth preset added later cannot slip past by not being named,
      // and over both roles, so the content material — which every card,
      // command and description-card draws — is held to the same answer
      // as the functional one: glass dims, everything else does not.
      for (final id in CoreSurfaceStyleId.values) {
        final recipe = CoreSurfaceRecipe.of(id);
        for (final role in CoreSurfaceRole.values) {
          final surface = recipe.surfaceFor(role);
          if (surface == null) continue;

          final dims = !surface.backdropBrightness.isIdentity;
          final expected = id == CoreSurfaceStyleId.liquidGlass;

          expect(
            dims,
            expected,
            reason:
                '${id.name}/${role.name} states '
                '${surface.backdropBrightness} — if that is intended, this '
                'expectation is the thing to update, deliberately',
          );
        }
      }
    });

    test('the floating material dims by a different amount per mode', () {
      // The whole reason the value is a pair. A single number cannot open
      // the gap: the direction with authority is downward, and downward
      // helps a dark panel's light text while hurting a light panel's dark
      // text. Pinned as *different*, not as two literals, so retuning the
      // material is a recipe edit rather than a test edit — but a change
      // that collapsed the pair back to one number fails here.
      final floating = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).surfaceFor(.functional)!.backdropBrightness;

      expect(floating.isIdentity, isFalse);
      expect(floating.light, isNot(floating.dark));
      expect(
        floating.resolve(CoreBrightness.dark),
        lessThan(floating.resolve(CoreBrightness.light)),
        reason:
            'dark has to travel further down: the term is proportional '
            'to the fill, and the dark surface token is a tenth of the '
            'light one',
      );
    });

    test('both roles are the one glass material', () {
      // The decision reversed here: the content layer shipped opaque for a
      // while (Apple's "glass is for the navigation layer"), and on screen
      // that read as a bar treatment rather than a material — a card
      // beside a glass dock was a solid slab. Now a panel is glass
      // whatever it is for. Asserted as token equality so the two roles
      // cannot drift apart one field at a time.
      final recipe = CoreSurfaceRecipe.of(.liquidGlass);

      expect(recipe.surfaceFor(.functional)!.type, SurfaceType.glass);
      expect(recipe.surfaceFor(.content)!.type, SurfaceType.glass);
      expect(recipe.surfaceFor(.content), recipe.surfaceFor(.functional));
    });

    test('and it survives the round trip', () {
      expect(
        const CoreSurfaceToken(
          type: SurfaceType.glass,
          backdropBrightness: CoreBackdropBrightness(light: 0.25, dark: 0.4),
        ).toJson()['backdropBrightness'],
        {'light': 0.25, 'dark': 0.4},
      );
    });

    test('reduce-transparency takes it along with the rest of the pass', () {
      // It rides one `backdrop-filter` with the blur and the chroma
      // lift, so a fallback that dropped those and kept this would leave
      // an opaque surface still dimming a backdrop nobody can see
      // through — the same material with one symptom hidden.
      const dimmed = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
        blurRadius: 12,
        backdropBrightness: CoreBackdropBrightness.same(0.25),
      );

      expect(
        dimmed.withoutTransparency().backdropBrightness,
        CoreBackdropBrightness.identity,
      );
    });
  });
}
