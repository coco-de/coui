import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

// `role: .functional` at every liquidGlass call site below — that is the
// role this preset's material actually rides now (#4424); the content
// role draws flat under it and this builder emits nothing for a flat
// token.
String _treatment(
  CoreSurfaceStyleId id, {
  CoreSurfaceRole role = CoreSurfaceRole.content,
}) => ThemeConfig.defaults().surfaceStyleTreatmentBlock(
  id,
  CoreSurfaceRecipe.of(id).surfaceFor(role),
  role: role,
);

/// The sheet the page actually gets.
///
/// Read separately from [_treatment] because the two can disagree in the
/// way that matters: a builder can return the right rule while nothing
/// calls it. Removing the call from here left every direct-call
/// assertion green — which is how the transport came to be missing in
/// the first place.
String get _sheet => ThemeConfig.defaults().surfaceStyleVariableBlocks;

void main() {
  group('a material surface reaches the Web', () {
    test('the glass preset states translucency and blur', () {
      // Measured before this existed: the recipe stated `opacity: 70` and
      // `blur: 16`, Flutter read both, and the Web style block never
      // touched `.surface` at all — so `[data-coui-style="liquidGlass"]`
      // emitted zero CSS and the preset rendered exactly like the
      // default. The Web half of this axis was named and inert.
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(css, contains('[data-coui-style="liquidGlass"]'));
      expect(css, contains('.$kWebSurfaceMarker'));
      expect(css, contains('backdrop-filter:blur('));
      // Derived from the recipe, not written out. The claim is that the
      // fill is restated as a *percentage of the published variable* —
      // which is what makes the preset composable with whatever token a
      // component chose. Pinning the number instead turns every tuning of
      // the shipped material into a test edit, and this test has already
      // been that once.
      final opacity = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).functionalSurface!.opacity;
      // The light fill is the base rule's; the dark one is restated below
      // it (see 'the fill differs by mode as well').
      final pct = (opacity.light * 100).round();
      expect(
        css,
        contains(
          'rgb(var($kWebSurfaceFillVar) / '
          'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct%))',
        ),
      );
    });

    test('as a CSS rule, not a value resolved in Dart', () {
      // Why it has to be a rule: style switching writes a document
      // attribute and does not rebuild the tree, so a number baked at
      // build time is the number of whichever preset happened to be
      // active then. The blur radius must appear inside a selector.
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(css.indexOf('data-coui-style'), lessThan(css.indexOf('blur(')));
    });
  });

  group('and the sheet actually carries it', () {
    test('the emitted blocks include the glass rule', () {
      // Not a restatement of the group above. That one asks whether the
      // builder produces the rule; this asks whether anything calls the
      // builder. Deleting the call passes every direct-call test.
      // Role-qualified since the depth ladder: both roles carry a class so
      // that depth (one extra `.coui-surface` per level) can never tie with
      // role. The bare-marker spelling no longer appears in any rule.
      expect(
        _sheet,
        contains(
          '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional{background-color:',
        ),
        reason:
            "the functional role carries this preset's material now "
            '(#4424) — content draws flat and emits no rule at all',
      );
      expect(_sheet, contains('backdrop-filter:blur('));
    });
  });

  group('a style with no material says nothing', () {
    test('the default preset emits no rule', () {
      // The half a blanket `backdrop-filter` would fail. `blur(0px)`
      // still establishes a containing block, which moves every
      // absolutely positioned descendant of every card and dialog in the
      // default style — a layout change nobody asked for, to express
      // "no blur".
      expect(_treatment(.defaultId), isEmpty);
    });

    test('and neither does a style whose surface is an opaque fill', () {
      // Neo-brutalism restates geometry and colour, not material. It has
      // no business acquiring a backdrop filter because a sibling preset
      // needed one.
      expect(_treatment(.neoBrutalism), isEmpty);
    });
  });

  group('the two declarations are one statement', () {
    test('translucency and blur arrive together', () {
      // A blur behind an opaque fill is invisible, and translucency with
      // no blur is just a lighter surface. Emitting one without the other
      // is a preset that looks broken rather than half-applied, so the
      // recipe that states either gets both.
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(css, contains('background-color:'));
      expect(css, contains('backdrop-filter:'));
    });
  });

  group('the material is more than a blur', () {
    test('the chroma lift rides the same filter list', () {
      // One `backdrop-filter`, not two declarations — a second would
      // replace the first rather than add to it, and the surface would
      // trade its blur for chroma without anything saying so.
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);
      final filter = RegExp('backdrop-filter:([^;]+);').firstMatch(css);

      expect(filter, isNotNull);
      expect(filter!.group(1), contains('blur('));
      expect(filter.group(1), contains('saturate('));
    });

    test('the band is drawn', () {
      final css = _treatment(.liquidGlass, role: CoreSurfaceRole.functional);

      expect(css, contains('::after'));
      expect(css, contains('linear-gradient(to right'));
      expect(css, contains('linear-gradient(to bottom'));
    });

    test('the band survives the injection it travels in', () {
      // The stylesheet is written into the page as an unescaped
      // single-quoted JS string literal, so one apostrophe anywhere in
      // this rule terminates that literal and takes the whole injection
      // script down. The symptom is a blank page, not a missing band —
      // which is why this is asserted on the text rather than trusted to
      // review. `content:""` is the double-quoted spelling.
      expect(
        _treatment(.liquidGlass, role: CoreSurfaceRole.functional),
        isNot(contains("'")),
      );
    });

    test('the band is clipped to the surface it decorates', () {
      // Pseudo-elements do not inherit `border-radius`. Without this the
      // band paints square corners over a rounded card, which reads as a
      // rendering bug rather than a style.
      expect(
        _treatment(.liquidGlass, role: CoreSurfaceRole.functional),
        contains('border-radius:inherit'),
      );
    });

    test('the band does not eat pointer events', () {
      expect(
        _treatment(.liquidGlass, role: CoreSurfaceRole.functional),
        contains('pointer-events:none'),
      );
    });

    test('a style with no material gets neither', () {
      for (final id in [
        CoreSurfaceStyleId.defaultId,
        CoreSurfaceStyleId.neoBrutalism,
        CoreSurfaceStyleId.claymorphism,
        CoreSurfaceStyleId.neumorphism,
      ]) {
        expect(_treatment(id), isNot(contains('saturate(')));
        expect(_treatment(id), isNot(contains('::after')));
      }
    });
  });

  group('and the sheet defines every name the band references', () {
    test('no declaration is invalidated by a missing variable', () {
      // The failure this exists for is silent: a custom property the
      // sheet never defines invalidates the whole declaration, so the
      // band simply is not there and the CSS still parses. `glass-*` is
      // exactly that shape — four names no palette fills — which is why
      // the band is built from slots that are actually emitted.
      //
      // Compared as a set relation, not a substring search: a test that
      // looked for one name would pass while a sibling was missing.
      final sheet =
          ThemeConfig.defaults().cssVariables +
          ThemeConfig.defaults().darkVariableBlock +
          ThemeConfig.defaults().surfaceStyleVariableBlocks;

      // Scoped to the band rule *and only it*. Rules that style the
      // surface itself reference `--coui-surface-rgb`, which is
      // deliberately not in the sheet: each component writes it inline
      // from whichever token it chose, so the fill stays that component's
      // colour. The band has no such per-element source — it is one shared
      // rule — so every name it uses has to exist globally or the rule is
      // simply dead.
      //
      // Bounded at the rule's own closing brace rather than run to the end
      // of the string, so a rule emitted *after* the band is not judged by
      // the band's requirement. The first version scanned the tail and
      // flagged a later surface rule for the very name the paragraph above
      // excuses.
      final treatment = _treatment(
        .liquidGlass,
        role: CoreSurfaceRole.functional,
      );
      final bandStart = treatment.indexOf('::after');
      final bandEnd = treatment.indexOf('}', bandStart);
      final band = treatment.substring(
        bandStart,
        bandEnd < 0 ? treatment.length : bandEnd,
      );
      final referenced = RegExp(
        r'var\((--coui-[a-z0-9-]+)',
      ).allMatches(band).map((m) => m.group(1)!).toSet();

      expect(referenced, isNotEmpty, reason: 'the band must use variables');

      final undefined = referenced
          .where((name) => !sheet.contains('$name:'))
          .toSet();

      expect(
        undefined,
        isEmpty,
        reason: 'these names are referenced but never defined: $undefined',
      );
    });
  });

  group('and the sheet actually carries the material', () {
    test('the emitted blocks include the chroma lift and the band', () {
      // Same split as the group above on blur: one asks whether the
      // builder produces the rule, this asks whether anything calls it.
      // Deleting the call left every direct-call assertion green once
      // already.
      expect(_sheet, contains('saturate('));
      expect(
        _sheet,
        contains('.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional::after'),
        reason: 'the band rides the functional role now (#4424)',
      );
    });
  });

  group('the edge has a wall as well as a band', () {
    /// The band rule for [id]'s [role] — everything inside its `::after`
    /// block.
    String bandRule(
      CoreSurfaceStyleId id, {
      CoreSurfaceRole role = CoreSurfaceRole.functional,
    }) {
      final css = _treatment(id, role: role);
      final roleClass = switch (role) {
        CoreSurfaceRole.content => kWebSurfaceRoleContent,
        CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
      };
      final at = css.indexOf('.$kWebSurfaceMarker.$roleClass::after{');
      if (at < 0) return '';

      return css.substring(at, css.indexOf('}', at) + 1);
    }

    test('it lands on the band element, not on the surface box', () {
      // Where it lands is the whole design. The band element is the
      // material's edge — inset 0, the inherited radius — so the wall
      // gets the same geometry as the runs by construction. The surface
      // box would have been the other candidate, and it is the one that
      // only carries a rim when the component authored a shadow.
      final band = bandRule(.liquidGlass);

      expect(band, isNotEmpty, reason: 'the band rule is gone entirely');
      expect(band, contains('box-shadow:inset '));
      expect(
        band,
        contains('--coui-surface-highlight'),
        reason: 'a wall in any other tint inverts when the theme flips',
      );
    });

    test('and it survives into the sheet the page gets', () {
      // The builder-versus-caller split this file already exists for. A
      // rule that is produced and never emitted is the exact failure this
      // axis shipped once.
      final at = _sheet.indexOf(
        '[data-coui-style="liquidGlass"] '
        '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional::after{',
      );
      expect(at, greaterThan(-1));
      expect(
        _sheet.substring(at, _sheet.indexOf('}', at) + 1),
        contains('box-shadow:inset '),
      );
    });

    test('a material with no wall emits no box-shadow at all', () {
      // Otherwise the assertions above would pass on an emitter that
      // writes the declaration unconditionally, and every banded style
      // would inherit a wall it never asked for. Checked over both roles
      // — a preset can state a band on either one, or both.
      for (final id in CoreSurfaceStyleId.values) {
        for (final role in CoreSurfaceRole.values) {
          final sheen = CoreSurfaceRecipe.of(id).surfaceFor(role)?.sheen;
          if (sheen == null || sheen.bevel != null) continue;

          expect(
            bandRule(id, role: role),
            isNot(contains('box-shadow')),
            reason: '$id/$role draws a wall it does not state',
          );
        }
      }
    });
  });

  group('an app can tune the material it turned on', () {
    /// The whole `.coui-surface` rule for [id] out of [config]'s sheet.
    ///
    /// Whole rule, not a substring: `contains('blur(32.0px)')` passes on a
    /// sheet that also changed three other declarations, and this repo has
    /// already shipped one substring assertion that stayed green while the
    /// value beside it was wrong.
    String ruleFor(
      ThemeConfig config,
      CoreSurfaceStyleId id, {
      CoreSurfaceRole role = CoreSurfaceRole.content,
    }) {
      final roleClass = switch (role) {
        CoreSurfaceRole.content => kWebSurfaceRoleContent,
        CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
      };
      final marker = '.$kWebSurfaceMarker.$roleClass{';
      final sheet = config.surfaceStyleVariableBlocks;
      final at = sheet.indexOf('[data-coui-style="${id.name}"] $marker');
      expect(at, greaterThan(-1), reason: 'the style emits no surface rule');

      return sheet.substring(at, sheet.indexOf('}', at) + 1);
    }

    test('the values it states reach the sheet, and nothing else moves', () {
      const glass = CoreSurfaceStyleId.liquidGlass;
      // Both sides derived from the shipped recipe, so a retune of the
      // material changes what this compares rather than breaking it. The
      // tuned values are offsets from whatever ships, which also keeps
      // them inside the bounds `CoreSurfaceTuning` asserts.
      //
      // Read off the functional role — that is the one tuning actually
      // retunes for this preset (#4424; `CoreSurfaceTuning.applyTo`
      // follows whichever role holds the material).
      final shipped = CoreSurfaceRecipe.of(glass).functionalSurface!;
      // 0.2 above the light fill, so the tuned value matches neither mode
      // of the shipped pair (0.5 / 0.6): a fixture equal to one of them
      // would pass on a tuning that only reached the other.
      final tunedOpacity = shipped.opacity.light + 0.2;
      final tunedBlur = shipped.blurRadius! + 8;
      final tunedSaturation = shipped.saturation + 0.2;

      const role = CoreSurfaceRole.functional;
      final untuned = ruleFor(ThemeConfig.defaults(), glass, role: role);
      final tuned = ruleFor(
        ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {
            glass: CoreSurfaceTuning(
              surfaceOpacity: tunedOpacity,
              surfaceBlur: tunedBlur,
              surfaceSaturation: tunedSaturation,
            ),
          },
        ),
        glass,
        role: role,
      );

      // Built from the untuned rule rather than written out, so the
      // assertion states the *difference* and cannot drift into restating
      // whatever the emitter happens to produce.
      expect(
        tuned,
        untuned
            .replaceAll(
              '* ${(shipped.opacity.light * 100).round()}%)',
              '* ${(tunedOpacity * 100).round()}%)',
            )
            .replaceAll('blur(${shipped.blurRadius}px)', 'blur(${tunedBlur}px)')
            .replaceAll(
              'saturate(${shipped.saturation})',
              'saturate($tunedSaturation)',
            ),
      );
      expect(tuned, isNot(untuned));
    });

    test('a style nobody tuned emits what it always did', () {
      const glass = CoreSurfaceStyleId.liquidGlass;
      const role = CoreSurfaceRole.functional;
      final tunedElsewhere = ruleFor(
        const ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {
            CoreSurfaceStyleId.neoBrutalism: CoreSurfaceTuning(radiusFloor: 0),
          },
        ),
        glass,
        role: role,
      );

      expect(
        tunedElsewhere,
        ruleFor(ThemeConfig.defaults(), glass, role: role),
      );
    });

    test('and the band geometry travels with the rest', () {
      const glass = CoreSurfaceStyleId.liquidGlass;
      final tuned = const ThemeConfig.from(
        CouiColorPresets.source,
        surfaceTunings: {
          glass: CoreSurfaceTuning(sheenWidth: 2, sheenFade: 0.3),
        },
      ).surfaceStyleVariableBlocks;

      // 0.3 of a run rather than the preset's 0.18.
      expect(tuned, contains('30.00%'));
      expect(tuned, contains('70.00%'));
    });
  });

  group('the material dims as well as amplifies', () {
    // Built here rather than taken from the shipped recipe on purpose.
    // The emission has to be correct before any preset asks for it —
    // otherwise the first story to dim a surface would also be the first
    // to find out whether this worked, which is the trap the file above
    // records for the chroma lift.
    const dimmed = CoreSurfaceToken(
      type: SurfaceType.glass,
      opacity: CoreSurfaceOpacity.same(0.65),
      blurRadius: 12,
      saturation: 1.6,
      backdropBrightness: CoreBackdropBrightness.same(0.25),
    );

    String css(CoreSurfaceToken token) =>
        ThemeConfig.defaults().surfaceStyleTreatmentBlock(.liquidGlass, token);

    test('the dimming rides the same filter list', () {
      // One list, not a second declaration. A second `backdrop-filter`
      // replaces the first rather than adding to it, so a surface that
      // stated both would lose its blur to gain the dimming.
      final filter = RegExp(
        'backdrop-filter:([^;]+);',
      ).firstMatch(css(dimmed));

      expect(filter, isNotNull);
      expect(filter!.group(1), contains('blur('));
      expect(filter.group(1), contains('brightness(0.25)'));
    });

    test('and lands after the chroma lift', () {
      // Filter functions run left to right, so this is an ordering claim
      // and not a formatting one: dimming an amplified backdrop and
      // amplifying a dimmed one are different colours. Flutter
      // multiplies the two into one matrix in this same order.
      final filter = RegExp(
        'backdrop-filter:([^;]+);',
      ).firstMatch(css(dimmed))!.group(1)!;

      expect(
        filter.indexOf('saturate('),
        lessThan(filter.indexOf('brightness(')),
      );
    });

    test('a surface that dims nothing emits no brightness at all', () {
      // Identity is not "brightness(1)" written out — an extra filter
      // function is a real pass on every surface in the style, paid to
      // multiply by one.
      const undimmed = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
        blurRadius: 12,
        saturation: 1.6,
      );

      expect(css(undimmed), isNot(contains('brightness(')));
    });

    test('and the sheet carries whatever the shipped recipe states', () {
      // Derived rather than pinned, for the reason the opacity assertion
      // above gives: a hardcoded number turns every tuning of the
      // shipped material into a test edit. What is fixed is the
      // *correspondence* — the sheet dims exactly when the recipe says
      // to, so the rule cannot go on emitting a value the recipe stopped
      // stating, or stop emitting one it started.
      //
      // Asked per role, because the two roles state different dimming and
      // a sheet-wide `contains` would go green off whichever one happens
      // to be non-identity.
      final recipe = CoreSurfaceRecipe.of(.liquidGlass);
      for (final role in CoreSurfaceRole.values) {
        final stated = recipe.surfaceFor(role)!.backdropBrightness;
        final rule = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
          .liquidGlass,
          recipe.surfaceFor(role),
          role: role,
        );

        expect(
          rule.contains('brightness('),
          !stated.isIdentity,
          reason: '$role states $stated',
        );
      }
    });

    test('a mode-aware pair restates the filter under both dark forms', () {
      // The dimming differs by mode, and a theme switch writes a document
      // attribute without rebuilding anything — so the difference has to
      // be CSS the browser re-matches, not a number resolved once.
      //
      // Both forms are required and the reason is the palette's own: the
      // attribute form only applies when something writes
      // `data-theme="dark"`, and a statically rendered site with no theme
      // controller never does. Only the media form reaches those visitors,
      // and they are the ones the dark value exists for.
      final recipe = CoreSurfaceRecipe.of(.liquidGlass);
      final floating = recipe.surfaceFor(.functional)!;
      final rule = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
        .liquidGlass,
        floating,
        role: .functional,
      );

      expect(
        floating.backdropBrightness.light,
        isNot(
          floating.backdropBrightness.dark,
        ),
      );
      expect(
        rule,
        contains('brightness(${floating.backdropBrightness.light})'),
      );
      expect(
        rule,
        contains(
          '[data-theme="dark"][data-coui-style="liquidGlass"]',
        ),
      );
      expect(rule, contains('@media (prefers-color-scheme:dark)'));
      expect(rule, contains(':root:not([data-theme="light"])'));
      expect(
        'brightness(${floating.backdropBrightness.dark})'
            .allMatches(rule)
            .length,
        3,
        reason:
            'the dark value lands in exactly the attribute form, the media '
            'form and the dark brightness scope — one of the document forms '
            'missing is half the visitors',
      );
      // The scope forms: a dark scope in a light page draws the dark term,
      // a light scope in a dark page the light one.
      expect(
        rule,
        contains(
          '[data-coui-style="liquidGlass"] [data-theme="dark"]:not(:root)',
        ),
      );
      expect(
        rule,
        contains(
          '[data-coui-style="liquidGlass"] [data-theme="light"]:not(:root)',
        ),
      );
    });

    test('a mode-blind pair emits no dark rules at all', () {
      // Two extra rules per surface is not free, and a rule that restates
      // the value above it is a second place to change one number.
      final rule = css(dimmed);

      expect(rule, isNot(contains('prefers-color-scheme')));
      expect(rule, isNot(contains('[data-theme="dark"]')));
    });
  });

  group('the fill differs by mode as well', () {
    // The fill is the second term of this material that the two modes
    // disagree about, and it has to survive a theme switch for the same
    // reason the dimming does: a switch writes a document attribute and
    // rebuilds nothing. So it is CSS the browser re-matches, under both
    // dark forms, and the light value stays the base rule's.
    final recipe = CoreSurfaceRecipe.of(.liquidGlass);

    String fill(double share) =>
        'background-color:rgb(var($kWebSurfaceFillVar) / '
        'calc(var($kWebSurfaceFillAlphaVar, 1) * ${(share * 100).round()}%));';

    String roleClass(CoreSurfaceRole role) => switch (role) {
      CoreSurfaceRole.content => kWebSurfaceRoleContent,
      CoreSurfaceRole.functional => kWebSurfaceRoleFunctional,
    };

    String rule(
      CoreSurfaceToken token, {
      required CoreSurfaceRole role,
      int depth = 0,
    }) => ThemeConfig.defaults().surfaceStyleTreatmentBlock(
      .liquidGlass,
      token,
      role: role,
      depth: depth,
    );

    /// The body of the dark rule in the attribute form, or null.
    String? attributeForm(String css, CoreSurfaceRole role, int depth) {
      final ancestors = '.$kWebSurfaceMarker ' * depth;
      final scope = '$ancestors.$kWebSurfaceMarker.${roleClass(role)}';
      final match = RegExp(
        r'\[data-theme="dark"\]\[data-coui-style="liquidGlass"\] '
        '${RegExp.escape(scope)}'
        r'\{([^}]*)\}',
      ).firstMatch(css);

      return match?.group(1);
    }

    /// The body of the dark rule in the `prefers-color-scheme` form.
    String? mediaForm(String css, CoreSurfaceRole role, int depth) {
      final ancestors = '.$kWebSurfaceMarker ' * depth;
      final scope = '$ancestors.$kWebSurfaceMarker.${roleClass(role)}';
      final match = RegExp(
        r'@media \(prefers-color-scheme:dark\)\{'
        r':root:not\(\[data-theme="light"\]\) '
        r'\[data-coui-style="liquidGlass"\] '
        '${RegExp.escape(scope)}'
        r'\{([^}]*)\}\}',
      ).firstMatch(css);

      return match?.group(1);
    }

    test('the shipped glass restates the dark fill under both dark forms', () {
      for (final role in CoreSurfaceRole.values) {
        final token = recipe.surfaceFor(role)!;
        final css = rule(token, role: role);

        expect(token.opacity.light, isNot(token.opacity.dark));
        for (final body in [
          attributeForm(css, role, 0),
          mediaForm(css, role, 0),
        ]) {
          expect(
            body,
            isNotNull,
            reason: '${role.name} has a dark form missing',
          );
          expect(body, contains(fill(token.opacity.dark)), reason: role.name);
          expect(body, isNot(contains(fill(token.opacity.light))));
          // The dimming rides the same dark rule, so one rule states both
          // terms and neither can fall out of the other.
          expect(body, contains('backdrop-filter:blur('), reason: role.name);
        }
      }
    });

    test('and the light fill stays the base rule, before either dark form', () {
      for (final role in CoreSurfaceRole.values) {
        final token = recipe.surfaceFor(role)!;
        final css = rule(token, role: role);

        final base = css.indexOf(fill(token.opacity.light));
        expect(base, greaterThan(-1), reason: role.name);
        // Twice — the base rule and the light brightness scope, nowhere
        // else: a base rule that also carried the dark fill would put the
        // dark value on every light page.
        expect(fill(token.opacity.light).allMatches(css).length, 2);
        expect(
          css.indexOf(fill(token.opacity.light), base + 1),
          greaterThan(css.indexOf('[data-theme="light"]:not(:root)')),
          reason: '${role.name}: the second belongs to the light scope',
        );
        expect(css.indexOf('[data-theme="dark"]'), greaterThan(base));
        expect(
          css.indexOf('@media (prefers-color-scheme:dark)'),
          greaterThan(base),
        );
      }
    });

    test('a nested material keeps the fill pair with no filter to restate', () {
      // It drops the backdrop pass and keeps the rest, and the fill is part
      // of the rest. Its dark rule therefore states the fill alone — gating
      // the restatement on the blur would leave a card inside a card at the
      // light fill under a dark palette.
      for (final role in CoreSurfaceRole.values) {
        final nested = recipe.surfaceFor(role, depth: 1)!;
        final css = rule(nested, role: role, depth: 1);

        expect(nested.blurRadius, isNull);
        expect(css, contains('backdrop-filter:none;'));
        for (final body in [
          attributeForm(css, role, 1),
          mediaForm(css, role, 1),
        ]) {
          expect(body, isNotNull, reason: '${role.name} nested dark form');
          expect(body, contains(fill(nested.opacity.dark)));
          expect(body, isNot(contains('backdrop-filter')));
        }
      }
    });

    test('the sheet the page gets carries it for every role and depth', () {
      // The builder can be right while nothing calls it with the nested
      // materials, so this reads the sheet rather than the builder.
      final sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;

      for (final role in CoreSurfaceRole.values) {
        final steps = recipe.nestedSurfaces?[role]?.length ?? 0;
        for (var depth = 0; depth <= steps; depth++) {
          final token = recipe.surfaceFor(role, depth: depth)!;
          if (token.opacity.isOpaque) continue;

          expect(
            attributeForm(sheet, role, depth),
            contains(fill(token.opacity.dark)),
            reason: '${role.name} @ $depth, attribute form',
          );
          expect(
            mediaForm(sheet, role, depth),
            contains(fill(token.opacity.dark)),
            reason: '${role.name} @ $depth, media form',
          );
        }
      }
    });

    test('a fill that does not differ by mode emits no dark fill', () {
      const blind = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
        blurRadius: 12,
        backdropBrightness: CoreBackdropBrightness(light: 0.9, dark: 0.5),
      );
      final css = rule(blind, role: .functional);

      // The dark rule exists for the dimming and must not drag a fill in.
      final body = attributeForm(css, .functional, 0)!;
      expect(body, contains('brightness(0.5)'));
      expect(body, isNot(contains('background-color')));
    });

    test(
      'a fill that differs with a dimming that does not states the fill alone',
      () {
        const fillOnly = CoreSurfaceToken(
          type: SurfaceType.glass,
          opacity: CoreSurfaceOpacity(light: 0.5, dark: 0.6),
          blurRadius: 12,
          backdropBrightness: CoreBackdropBrightness.same(0.9),
        );
        final css = rule(fillOnly, role: .functional);

        final body = attributeForm(css, .functional, 0)!;
        expect(body, fill(0.6));
        expect(mediaForm(css, .functional, 0), fill(0.6));
      },
    );

    test('a mode-blind fill and dimming emit no dark rule', () {
      const blind = CoreSurfaceToken(
        type: SurfaceType.glass,
        opacity: CoreSurfaceOpacity.same(0.65),
        blurRadius: 12,
        backdropBrightness: CoreBackdropBrightness.same(0.9),
      );
      final css = rule(blind, role: .functional);

      expect(css, isNot(contains('prefers-color-scheme')));
      expect(css, isNot(contains('[data-theme="dark"]')));
    });

    test('an opaque surface emits no fill at all, in either mode', () {
      expect(
        rule(const CoreSurfaceToken.flat(), role: .functional),
        isEmpty,
      );
    });

    test('reduce-transparency still outranks the dark fill', () {
      // `!important` is what keeps the fallback opaque in dark. A dark fill
      // rule that outranked it would leave a user who asked for less
      // transparency on a translucent panel, in the one mode this change
      // made more opaque.
      final token = recipe.surfaceFor(.functional)!;
      final css = rule(token, role: .functional);

      const scope =
          '[data-coui-style="liquidGlass"] '
          '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional';
      const reduced = '@media (prefers-reduced-transparency:reduce){$scope{';
      const opaqueFill =
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'var($kWebSurfaceFillAlphaVar, 1)) !important;';
      expect(css, contains('$reduced$opaqueFill'));
    });

    test(
      'a tuned fill is stated for both modes with no dark fill rule',
      () {
        const config = ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {
            CoreSurfaceStyleId.liquidGlass: CoreSurfaceTuning(
              surfaceOpacity: 0.7,
            ),
          },
        );
        final sheet = config.surfaceStyleVariableBlocks;

        // The tuned fill is stated once for both modes, so the dark rules
        // that remain at the top level are the dimming's alone. The nested
        // materials are the recipe's own table and a tuning does not
        // rewrite it, which is why this reads depth 0 and not the sheet.
        expect(sheet, contains(fill(0.7)));
        for (final role in CoreSurfaceRole.values) {
          for (final body in [
            attributeForm(sheet, role, 0),
            mediaForm(sheet, role, 0),
          ]) {
            expect(body, isNotNull, reason: role.name);
            expect(
              body,
              isNot(contains('background-color')),
              reason: role.name,
            );
            expect(body, contains('backdrop-filter:blur('), reason: role.name);
          }
        }
      },
    );
  });

  group('a floating surface gets its own material', () {
    test('the marker cannot be attached without choosing a role', () {
      // The point of the helper: the role is a required argument, so a
      // new surface cannot mark itself and leave the role unstated. That
      // is a compile error rather than a guard someone has to run.
      expect(
        webSurfaceMarkerFor(CoreSurfaceRole.functional),
        [kWebSurfaceMarker, kWebSurfaceRoleFunctional],
      );
      expect(
        webSurfaceMarkerFor(CoreSurfaceRole.content),
        [kWebSurfaceMarker, kWebSurfaceRoleContent],
      );
    });

    test('the override is scoped so it outranks the base rule', () {
      // Two classes beat one within the same style scope, which is what
      // lets the base rule stay keyed on the marker alone — content
      // surfaces then render byte-for-byte as they did before roles.
      final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
        .liquidGlass,
        CoreSurfaceRecipe.of(.liquidGlass).surfaceFor(.functional),
        role: CoreSurfaceRole.functional,
      );

      expect(
        css,
        contains('.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional'),
      );
    });

    test('and the sheet carries both rules for the shipped style', () {
      // Not a restatement of the builder test above: a builder can
      // return the right rule while nothing calls it. That is exactly
      // how the material transport came to be missing the first time.
      const base = '[data-coui-style="liquidGlass"] .$kWebSurfaceMarker';

      expect(_sheet, contains(base));
      expect(_sheet, contains('$base.$kWebSurfaceRoleFunctional'));
    });

    test('the two rules do not state the same fill', () {
      // The acceptance criterion, read off the sheet rather than the
      // recipe: if both roles emitted the same declarations the axis
      // would be a field nobody can observe.
      final rules = RegExp(
        r'\[data-coui-style="liquidGlass"\] \.coui-surface'
        r'(\.coui-surface-functional)?\{([^}]*)\}',
      ).allMatches(_sheet).toList();

      expect(rules.length, greaterThanOrEqualTo(2));
      final content = rules.firstWhere((m) => m.group(1) == null).group(2);
      final functional = rules.firstWhere((m) => m.group(1) != null).group(2);

      expect(functional, isNot(content));
    });

    test('a style that draws no distinction emits no override', () {
      // An identical override would double every declaration for no
      // visual difference, and would make the sheet claim a distinction
      // the recipe does not make.
      for (final id in CoreSurfaceStyleId.values) {
        final recipe = CoreSurfaceRecipe.of(id);
        if (recipe.functionalSurface != null) continue;

        expect(
          _sheet.contains(
            '[data-coui-style="${id.name}"] '
            '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional',
          ),
          isFalse,
          reason: '${id.name} states one material but emits two rules',
        );
      }
    });
  });
}
