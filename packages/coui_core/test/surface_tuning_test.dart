import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreSurfaceStyleId _neo = CoreSurfaceStyleId.neoBrutalism;

void main() {
  group('a tuning that says nothing costs nothing', () {
    test('applyTo returns the very same recipe instance', () {
      final authored = CoreSurfaceRecipe.of(_neo);

      // Identity, not equality. An equal-but-new instance is the shape
      // that makes a value-compared axis carrier look changed, which is
      // how a parity baseline moves for no visible reason.
      expect(
        identical(CoreSurfaceTuning.none.applyTo(authored), authored),
        isTrue,
      );
    });

    test('the seat hands back the preset itself when untuned', () {
      expect(
        identical(
          resolveThemeRecipe(surfaceStyle: _neo),
          CoreSurfaceRecipe.of(_neo),
        ),
        isTrue,
      );
    });
  });

  group('a tuning bends the preset it is folded into', () {
    test('a squaring cap reaches the recipe geometry', () {
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(radiusCap: 0),
      );

      expect(tuned.geometry.radiusCap, 0);
      // The transform, not just the field: a cap of zero is the absolute
      // case that takes the fully-rounded sentinel with it.
      expect(tuned.geometry.radius(CoreRadius.radius16), 0);
      expect(tuned.geometry.radius(CoreRadius.radius9999), 0);
    });

    test('a floor makes corners rounder, which a cap alone cannot say', () {
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(
          radiusFloor: CoreRadius.radius16,
          radiusCap: CoreRadius.radius32,
        ),
      );

      expect(
        tuned.geometry.radius(CoreRadius.radius4),
        greaterThanOrEqualTo(CoreRadius.radius16),
      );
    });

    test('an offset replaces the diagonal the preset authored', () {
      final authored = CoreSurfaceRecipe.of(_neo).geometry.shadowOffsetAdd;
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(
          shadowOffsetX: 6,
          shadowOffsetY: 6,
        ),
      );

      expect(authored, isNot((dx: 6.0, dy: 6.0)));
      expect(tuned.geometry.shadowOffsetAdd, (dx: 6.0, dy: 6.0));
    });

    test('a stroke floor reaches drawn widths', () {
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(
          strokeFloor: CoreStrokeWidth.stroke2,
        ),
      );

      expect(tuned.geometry.stroke(CoreStrokeWidth.stroke1), 2);
      // A width of zero still means "no border" — a floor never draws one
      // where a variant deliberately removed it.
      expect(tuned.geometry.stroke(0), 0);
    });

    test('what the tuning does not name keeps the preset answer', () {
      final authored = CoreSurfaceRecipe.of(_neo);
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(radiusCap: 0),
      );

      expect(tuned.geometry.shadowBlurScale, authored.geometry.shadowBlurScale);
      expect(
        tuned.geometry.shadowOffsetAdd,
        authored.geometry.shadowOffsetAdd,
      );
      expect(tuned.typography, authored.typography);
    });
  });

  group('the accessibility contract is not negotiable', () {
    test('a tuned preset keeps its own a11y answers', () {
      final authored = CoreSurfaceRecipe.of(_neo);
      final tuned = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(
          radiusCap: 0,
          shadowOffsetX: 12,
          shadowOffsetY: 12,
          strokeFloor: CoreStrokeWidth.stroke2,
        ),
      );

      expect(tuned.a11y, authored.a11y);
      expect(tuned.id, authored.id);
      expect(tuned.surface, authored.surface);
    });

    test('a border may not reach the focus ring that has to outrank it', () {
      // The ring is what tells a keyboard user where they are. A border at
      // or above its weight stops reading as a separate indicator, which is
      // the failure the preset acceptance gate names — so this is refused
      // rather than clamped.
      final ring = CoreSurfaceRecipe.of(
        _neo,
      ).a11y.focusOutlineStyle.borderWidth;
      expect(ring, isNotNull);

      expect(
        () => CoreSurfaceTuning(strokeFloor: ring! + 1).applyTo(
          CoreSurfaceRecipe.of(_neo),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a hairline floor is refused outright', () {
      // Const-evaluable, so a `const` call site — which is every normal
      // one — fails to compile rather than reaching this assertion.
      expect(
        () => CoreSurfaceTuning(strokeFloor: CoreStrokeWidth.stroke1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a cast thrown backwards is refused', () {
      expect(
        () => CoreSurfaceTuning(shadowOffsetX: -1, shadowOffsetY: 4),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a floor above the cap has no values in it', () {
      expect(
        () => CoreSurfaceTuning(
          radiusFloor: CoreRadius.radius32,
          radiusCap: CoreRadius.radius4,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('value semantics — the axis is compared, not identified', () {
    test('equal tunings are equal', () {
      const a = CoreSurfaceTuning(
        radiusCap: 0,
        shadowOffsetX: 6,
        shadowOffsetY: 6,
      );
      const b = CoreSurfaceTuning(
        radiusCap: 0,
        shadowOffsetX: 6,
        shadowOffsetY: 6,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('every field participates in equality', () {
      // A field left out of equality is a field whose change cannot
      // trigger a rebuild: the value is computed correctly and the screen
      // never updates, with nothing in a screenshot to say why.
      const base = CoreSurfaceTuning.none;

      expect(base, isNot(const CoreSurfaceTuning(radiusFloor: 4)));
      expect(base, isNot(const CoreSurfaceTuning(radiusCap: 4)));
      expect(base, isNot(const CoreSurfaceTuning(shadowOffsetX: 1)));
      expect(base, isNot(const CoreSurfaceTuning(shadowOffsetY: 1)));
      expect(
        base,
        isNot(const CoreSurfaceTuning(strokeFloor: CoreStrokeWidth.stroke2)),
      );
    });

    test('every field participates in isIdentity', () {
      // `isIdentity` is a *second* hand-written enumeration of the same
      // field set, and `applyTo` short-circuits on it. A field added to
      // `==` but missed here makes that tuning a silent no-op — the recipe
      // comes back untouched, the equality test above still passes, and
      // nothing in a screenshot says why the screen did not change.
      //
      // The two enumerations are checked separately because that is the
      // shape of the failure: they can disagree, and only one of them
      // decides whether the fold runs at all.
      expect(const CoreSurfaceTuning(radiusFloor: 4).isIdentity, isFalse);
      expect(const CoreSurfaceTuning(radiusCap: 4).isIdentity, isFalse);
      expect(const CoreSurfaceTuning(shadowOffsetX: 1).isIdentity, isFalse);
      expect(const CoreSurfaceTuning(shadowOffsetY: 1).isIdentity, isFalse);
      expect(
        const CoreSurfaceTuning(
          strokeFloor: CoreStrokeWidth.stroke2,
        ).isIdentity,
        isFalse,
      );
      expect(CoreSurfaceTuning.none.isIdentity, isTrue);
    });
  });

  group('the page tint moves the page and nothing else', () {
    CoreColorScheme tinted({double chroma = 0.06}) => resolveThemeSchemeFrom(
      CouiColorPresets.source,
      brightness: .light,
      surfaceStyle: _neo,
      surfaceTuning: CoreSurfaceTuning(stageTintChroma: chroma),
    );

    CoreColorScheme plain() => resolveThemeSchemeFrom(
      CouiColorPresets.source,
      brightness: .light,
      surfaceStyle: _neo,
    );

    test('the page takes colour from the accent', () {
      final before = CoreColorConversion.colorToOKLch(plain().surface!);
      final after = CoreColorConversion.colorToOKLch(tinted().surface!);

      expect(after.c, greaterThan(before.c));
    });

    test('a different brand hue tints the page differently', () {
      // Hue is asserted this way rather than by comparing angles. At the
      // chroma a near-white page can hold, the colour is a couple of 8-bit
      // steps from grey and its measured hue is numerically unstable —
      // an exact comparison would be testing rounding, not the axis.
      CoreColor pageFor(double hue) => resolveThemeScheme(
        PrimitiveColors.generate(
          primaryHSL: (h: hue, s: 0.9, l: 0.5),
          secondaryHSL: (h: 265, s: 0.55, l: 0.45),
          tertiaryHSL: (h: 190, s: 0.55, l: 0.45),
          successHSL: (h: 145, s: 0.55, l: 0.38),
          infoHSL: (h: 205, s: 0.60, l: 0.45),
          warningHSL: (h: 40, s: 0.85, l: 0.55),
          errorHSL: (h: 0, s: 0.65, l: 0.50),
          neutralHue: 220,
        ),
        brightness: .dark,
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(stageTintChroma: 0.06),
      ).surface!;

      expect(pageFor(20), isNot(pageFor(200)));
    });

    test('the tint is fitted to the gamut, not clamped by it', () {
      // The request is an upper bound. sRGB has less colour available at
      // high lightness than in the middle, and CoUI's light page is
      // near-white — so what lands is well under what was asked for, and
      // that is the axis working rather than failing.
      final after = CoreColorConversion.colorToOKLch(tinted().surface!);

      expect(after.c, lessThan(0.06));
      expect(after.c, greaterThan(0));
    });

    test('a darker page holds more tint than a near-white one', () {
      // How much tint a page can take is a property of that page's
      // lightness. An app that wants the deeper background of the
      // reference implementations gets there by choosing a less-white
      // page, not by asking for more chroma.
      final light = CoreColorConversion.colorToOKLch(tinted().surface!);
      final dark = CoreColorConversion.colorToOKLch(
        resolveThemeSchemeFrom(
          CouiColorPresets.source,
          brightness: .dark,
          surfaceStyle: _neo,
          surfaceTuning: const CoreSurfaceTuning(stageTintChroma: 0.06),
        ).surface!,
      );

      expect(dark.c, greaterThan(light.c));
    });

    test('the page keeps its own lightness', () {
      // Contrast is a function of relative luminance. If lightness moved,
      // every foreground on the page would move with it and the audit
      // would have two free parameters to sweep instead of one.
      final before = CoreColorConversion.colorToOKLch(plain().surface!);
      final after = CoreColorConversion.colorToOKLch(tinted().surface!);

      expect(after.l, closeTo(before.l, 0.002));
    });

    test('container tones are left where the palette put them', () {
      // A card, an input and a popover are told apart *by* these tones.
      // Tinting them along with the page collapses that into one wash —
      // and the reference screens keep an untinted panel on a tinted page.
      final before = plain();
      final after = tinted();

      expect(after.surfaceContainerLow, before.surfaceContainerLow);
      expect(after.surfaceContainer, before.surfaceContainer);
      expect(after.surfaceContainerHigh, before.surfaceContainerHigh);
      expect(after.onSurface, before.onSurface);
    });

    test('a tuning that states no tint leaves the page alone', () {
      expect(tinted(chroma: 0).surface, plain().surface);
    });

    test('high contrast drops the tint', () {
      // The colour statement is skipped wholesale under the preference —
      // someone who asked for legibility did not ask for the app's cast.
      final highContrast = resolveThemeSchemeFrom(
        CouiColorPresets.source,
        brightness: .light,
        highContrast: true,
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(stageTintChroma: 0.06),
      );
      final plainHighContrast = resolveThemeSchemeFrom(
        CouiColorPresets.source,
        brightness: .light,
        highContrast: true,
        surfaceStyle: _neo,
      );

      expect(
        highContrast.resolved(.light).surface,
        plainHighContrast.resolved(.light).surface,
      );
    });

    test('geometry survives high contrast even though the tint does not', () {
      // Corners and casts are not contrast levers, so dropping them would
      // cost the preset its identity and buy nothing.
      final recipe = resolveThemeRecipe(
        surfaceStyle: _neo,
        surfaceTuning: const CoreSurfaceTuning(
          radiusCap: 0,
          stageTintChroma: 0.06,
        ),
      );

      expect(recipe.geometry.radiusCap, 0);
    });

    test('a tint past the measured bound is refused', () {
      expect(
        () => CoreSurfaceTuning(
          stageTintChroma: CoreSurfaceTuning.maxStageTintChroma + 0.01,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the tint participates in identity and equality', () {
      const base = CoreSurfaceTuning.none;
      const tint = CoreSurfaceTuning(stageTintChroma: 0.02);

      expect(tint.isIdentity, isFalse);
      expect(base, isNot(tint));
    });
  });

  // These read the *functional* role. The material a glass tuning aims at
  // lives there — the content layer is a standard material under this
  // style, so `recipe.surface` has nothing for a fill or a band to land
  // on. Reading it here would test that the tuning silently did nothing.
  group('an app tunes the glass without reaching its colours', () {
    const glass = CoreSurfaceStyleId.liquidGlass;

    test('the values it states arrive on the token', () {
      final base = CoreSurfaceRecipe.of(glass);
      // Every value differs from the shipped functional token (0.5 in
      // light and 0.6 in dark / 4.0 / 1.6), in every mode the fill is
      // stated for. A fixture that matched it would pass even if
      // `applyTo` handed the recipe straight back.
      const tuning = CoreSurfaceTuning(
        surfaceOpacity: 0.7,
        surfaceBlur: 32,
        surfaceSaturation: 1.2,
      );

      final tuned = tuning.applyTo(base).surfaceFor(.functional)!;

      // A fill the app states is stated for both modes.
      expect(tuned.opacity, const CoreSurfaceOpacity.same(0.7));
      expect(tuned.blurRadius, 32);
      expect(tuned.saturation, 1.2);
    });

    test('and it lands on every role made of that material', () {
      // The shipped glass makes both roles the same material, so a tuning
      // is a statement about cards as much as about popovers. A fold that
      // followed one role would move the floating panels and leave the
      // page's cards at the preset's frost — a divergence nobody could
      // see without a card and a popover side by side.
      const tuning = CoreSurfaceTuning(surfaceOpacity: 0.7, surfaceBlur: 32);
      final tuned = tuning.applyTo(CoreSurfaceRecipe.of(glass));

      for (final role in CoreSurfaceRole.values) {
        final surface = tuned.surfaceFor(role)!;

        expect(
          surface.opacity,
          const CoreSurfaceOpacity.same(0.7),
          reason: role.name,
        );
        expect(surface.blurRadius, 32, reason: role.name);
      }
      expect(tuned.surfaceFor(.content), tuned.surfaceFor(.functional));
    });

    test('but leaves a role that is not glass exactly as authored', () {
      // The other half: a preset that states an opaque content material
      // under a glass floating one is tuned on the glass alone. Writing
      // the glass constructor over a flat token would hand a card a frost
      // it never asked for.
      const flat = CoreSurfaceToken.flat();
      final split = CoreSurfaceRecipe.of(glass).copyWith(surface: flat);
      const tuning = CoreSurfaceTuning(surfaceOpacity: 0.7);

      final tuned = tuning.applyTo(split);

      expect(tuned.surfaceFor(.content), flat);
      expect(
        tuned.surfaceFor(.functional)!.opacity,
        const CoreSurfaceOpacity.same(0.7),
      );
    });

    test('and a tuning changes nothing it did not name', () {
      // The real net under this unit. `none.applyTo` returns the recipe
      // itself and never enters the glass branch, so it cannot catch a
      // branch that rebuilds the token and drops a field on the way.
      final base = CoreSurfaceRecipe.of(glass).surfaceFor(.functional)!;
      // 0.7, which matches neither mode of the shipped fill (0.5 / 0.6) —
      // `isNot(base.opacity)` below is the assertion that the named field
      // actually moved.
      const tuning = CoreSurfaceTuning(surfaceOpacity: 0.7);

      final tuned = tuning
          .applyTo(CoreSurfaceRecipe.of(glass))
          .surfaceFor(.functional)!;

      expect(tuned.opacity, isNot(base.opacity));
      expect(tuned.blurRadius, base.blurRadius);
      expect(tuned.saturation, base.saturation);
      expect(tuned.sheen, base.sheen);
      expect(tuned.backdropBrightness, base.backdropBrightness);
      expect(tuned.drawsOwnEdge, base.drawsOwnEdge);
      expect(tuned.type, base.type);
      expect(tuned.elevation, base.elevation);
    });

    test('the rim bends with the same light, on every glass role', () {
      // The crest is the wall's, so an app moving it moves the two numbers
      // on the bevel and nothing else about the light — the angle and the
      // crescents stay the preset's. And it lands on both roles, because
      // a card and a popover are edged alike under this style.
      final base = CoreSurfaceRecipe.of(glass);
      const tuning = CoreSurfaceTuning(rimWidth: 3, rimIntensity: 0.4);

      final tuned = tuning.applyTo(base);

      for (final role in CoreSurfaceRole.values) {
        final before = base.surfaceFor(role)!.sheen!.bevel!;
        final after = tuned.surfaceFor(role)!.sheen!.bevel!;

        expect(after.rimWidth, 3, reason: role.name);
        expect(after.rimIntensity, 0.4, reason: role.name);
        expect(after.lightAngle, before.lightAngle, reason: role.name);
        expect(after.lightIntensity, before.lightIntensity, reason: role.name);
        expect(after.thickness, before.thickness, reason: role.name);
        expect(after.glowSpread, before.glowSpread, reason: role.name);
      }
    });

    test('and a rim of zero width turns the crest off', () {
      const tuning = CoreSurfaceTuning(rimWidth: 0);
      final tuned = tuning.applyTo(CoreSurfaceRecipe.of(glass));

      expect(tuned.surfaceFor(.functional)!.sheen!.bevel!.drawsRim, isFalse);
    });

    test('a rim tuning on a style with no wall is rejected', () {
      expect(
        () => const CoreSurfaceTuning(rimWidth: 2).applyTo(
          CoreSurfaceRecipe.of(CoreSurfaceStyleId.claymorphism),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the band geometry bends without the band changing colour', () {
      final base = CoreSurfaceRecipe.of(glass).surfaceFor(.functional)!.sheen!;
      const tuning = CoreSurfaceTuning(sheenWidth: 2, sheenFade: 0.3);

      final tuned = tuning
          .applyTo(CoreSurfaceRecipe.of(glass))
          .surfaceFor(.functional)!
          .sheen!;

      expect(tuned.width, 2);
      expect(tuned.fade, 0.3);
      expect(tuned.lightColor, base.lightColor);
      expect(tuned.darkColor, base.darkColor);
    });

    test('no tuning can reach a colour statement', () {
      // G4. The colour constraint is where a preset says what it does to
      // the palette, and an app moving that would invalidate the contrast
      // audit the preset registered.
      for (final tuning in const [
        CoreSurfaceTuning(surfaceOpacity: 0.5),
        CoreSurfaceTuning(surfaceBlur: 32),
        CoreSurfaceTuning(surfaceSaturation: 1.6),
        CoreSurfaceTuning(sheenWidth: 2),
        CoreSurfaceTuning(sheenFade: 0.3),
      ]) {
        expect(
          tuning
              .applyTo(CoreSurfaceRecipe.of(glass))
              .colorConstraint
              .isIdentity,
          isTrue,
        );
      }
    });

    test('the material values are compared, not identified', () {
      // A field left out of `==` makes the app state a value, the theme
      // compute it, and the framework decline to rebuild.
      const base = CoreSurfaceTuning.none;
      for (final other in const [
        CoreSurfaceTuning(surfaceOpacity: 0.5),
        CoreSurfaceTuning(surfaceBlur: 32),
        CoreSurfaceTuning(surfaceSaturation: 1.6),
        CoreSurfaceTuning(sheenWidth: 2),
        CoreSurfaceTuning(sheenFade: 0.3),
      ]) {
        expect(base, isNot(other));
        expect(base.hashCode, isNot(other.hashCode));
        expect(other.isIdentity, isFalse);
      }
    });

    test('a material value on a style that draws none is rejected', () {
      // Which transport runs is the preset's statement. Without this the
      // value would be written, compared, serialised, and never drawn.
      expect(
        () => const CoreSurfaceTuning(
          surfaceSaturation: 1.6,
        ).applyTo(CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('band geometry with no band to land on is rejected', () {
      expect(
        () => const CoreSurfaceTuning(
          sheenWidth: 2,
        ).applyTo(CoreSurfaceRecipe.of(CoreSurfaceStyleId.neoBrutalism)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the page tint still lands when the glass is tuned too', () {
      // This unit and the page-tint one grow the same field list and the
      // same fold. Either could rewrite the other's branch out.
      // 0.7 rather than either mode of the shipped fill, so the material
      // half of the fold is observably present — at 0.5 or 0.6 this passes
      // whether or not it ran.
      final tuned = const CoreSurfaceTuning(
        surfaceOpacity: 0.7,
        stageTintChroma: 0.05,
      ).applyTo(CoreSurfaceRecipe.of(glass));

      expect(
        tuned.surfaceFor(.functional)!.opacity,
        const CoreSurfaceOpacity.same(0.7),
      );
      expect(tuned.colorConstraint.isIdentity, isFalse);
    });
  });

  group('a tuning carries the terms it never mentions', () {
    test('dimming survives a tuning that only moves the fill', () {
      // `applyTo` rebuilds the glass token by enumerating its fields, so
      // any field not named there is replaced by its default — silently,
      // and only for apps that tune. The shipped preset states identity
      // dimming today, which means dropping it would look exactly like
      // working. So the input is built here with a real value rather
      // than taken from the recipe.
      const dimmed = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.65),
        blur: 12,
        saturation: 1.6,
        backdropBrightness: CoreBackdropBrightness.same(0.25),
      );
      const recipe = CoreSurfaceRecipe(
        id: .liquidGlass,
        a11y: .liquidGlass,
        surface: dimmed,
      );

      const tuning = CoreSurfaceTuning(surfaceOpacity: 0.5);
      final tuned = tuning.applyTo(recipe).surface!;

      expect(
        tuned.opacity,
        const CoreSurfaceOpacity.same(0.5),
        reason: 'the tuning did not apply at all',
      );
      expect(
        tuned.backdropBrightness,
        const CoreBackdropBrightness.same(0.25),
        reason: 'a tuning that never mentioned dimming removed it',
      );
    });
  });
}
