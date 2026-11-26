// The rules that let a glass panel fade by its terms
// (`surfaceFadeTargetBlock`), in the parts a VM can see: which surfaces get
// them, what they state, that they state the same list the surface's own rule
// does, and where they are taken back.
//
// Whether a browser keeps a panel's blur while it fades under these rules is
// read in Chrome (`glass_fade_probe_test.dart`).
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

/// The rule for [role]'s panel under [id]'s style.
String _fade(
  CoreSurfaceStyleId id,
  CoreSurfaceRole role,
) => ThemeConfig.defaults().surfaceFadeTargetBlock(
  id,
  CoreSurfaceRecipe.of(id).surfaceFor(role),
  role: role,
);

/// The rule the surface itself has, that the fade states the same list as.
String _base(CoreSurfaceStyleId id, CoreSurfaceRole role) =>
    ThemeConfig.defaults().surfaceStyleTreatmentBlock(
      id,
      CoreSurfaceRecipe.of(id).surfaceFor(role),
      role: role,
    );

const Map<CoreSurfaceRole, String> _roleClass = {
  CoreSurfaceRole.functional: kWebSurfaceRoleFunctional,
  CoreSurfaceRole.content: kWebSurfaceRoleContent,
};

/// `blur(…px)`, `saturate(…)` and `brightness(…)` of the first list in [css].
({double blur, double saturate, double brightness}) _plainList(String css) {
  final list = RegExp('backdrop-filter:([^;]*);').firstMatch(css)!.group(1)!;

  return (
    blur: double.parse(
      RegExp(r'blur\(([\d.]+)px\)').firstMatch(list)!.group(1)!,
    ),
    saturate: double.parse(
      RegExp(r'saturate\(([\d.]+)\)').firstMatch(list)!.group(1)!,
    ),
    brightness: double.parse(
      RegExp(r'brightness\(([\d.]+)\)').firstMatch(list)!.group(1)!,
    ),
  );
}

/// The same three terms of the first fade list in [css], at a progress of 1:
/// the numbers it states, with the progress taken out.
({double blur, double saturate, double brightness}) _listAtRest(String css) {
  final list = RegExp(
    '$kWebSurfacePassVar:([^;]*);',
  ).firstMatch(css)!.group(1)!;
  final blur = RegExp(
    r'blur\(calc\(([\d.]+)px \* var\(--coui-fade,1\)\)\)',
  ).firstMatch(list)!.group(1)!;
  final saturate = RegExp(
    r'saturate\(calc\(1 \+ ([\d.]+) \* var\(--coui-fade,1\)\)\)',
  ).firstMatch(list)!.group(1)!;
  final brightness = RegExp(
    r'brightness\(calc\(1 - ([\d.]+) \* var\(--coui-fade,1\)\)\)',
  ).firstMatch(list)!.group(1)!;

  return (
    blur: double.parse(blur),
    saturate: 1 + double.parse(saturate),
    brightness: 1 - double.parse(brightness),
  );
}

/// The target a fade rule is about, in the form the stylesheet writes it.
const _fadeTarget =
    ':is(.$kFadeBoxClass>.$kWebSurfaceMarker,'
    '.$kFadePanelClass.$kWebSurfaceMarker)';

/// Class-column specificity: attributes, classes and pseudo-classes, which is
/// all these selectors use. `:is(…)` counts its most specific argument,
/// `:not(…)` its argument, and `:where(…)` nothing, as CSS counts them.
int _specificity(String selector) {
  var inside = 0;
  final rest = selector
      .replaceAll(RegExp(r':where\((?:[^()]|\([^()]*\))*\)'), '')
      .replaceAllMapped(RegExp(r':is\(([^()]*)\)'), (match) {
        inside += match[1]!.split(',').map(_specificity).reduce(math.max);

        return '';
      })
      .replaceAllMapped(RegExp(r':not\(([^()]*)\)'), (match) => match[1]!);

  return inside +
      RegExp(r'\[[^\]]+\]|:[a-z-]+|\.[\w-]+').allMatches(rest).length;
}

/// Every rule's selector and body in [css], one `@media` level deep.
List<({String selector, String body})> _rulesOf(String css) => [
  for (final match in RegExp(r'([^{}@]+)\{([^{}]*)\}').allMatches(css))
    (selector: match[1]!.trim(), body: match[2]!),
];

/// The rules of [role]'s fade block that state the terms, which are the ones
/// that restate a rule the surface already has.
List<({String selector, String body})> _termRules(
  CoreSurfaceStyleId id,
  CoreSurfaceRole role,
) => [
  for (final rule in _rulesOf(_fade(id, role)))
    if (rule.body.contains('$kWebSurfacePassVar:')) rule,
];

void main() {
  group('which surfaces get fade rules', () {
    test('only a style that draws a backdrop pass', () {
      for (final id in CoreSurfaceStyleId.values) {
        for (final role in CoreSurfaceRole.values) {
          final surface = CoreSurfaceRecipe.of(id).surfaceFor(role);
          final fade = _fade(id, role);
          if (surface?.blurRadius == null) {
            expect(
              fade,
              isEmpty,
              reason: '${id.name} / ${role.name} draws no pass',
            );
          } else {
            expect(
              fade,
              isNotEmpty,
              reason: '${id.name} / ${role.name} draws one',
            );
          }
        }
      }
      // And the one the preset set draws one.
      expect(_fade(.liquidGlass, .functional), isNotEmpty);
      expect(_fade(.liquidGlass, .content), isNotEmpty);
    });

    test(
      'and only for a panel that fades: the motion box child or the dialog',
      () {
        for (final role in CoreSurfaceRole.values) {
          final fade = _fade(.liquidGlass, role);

          expect(
            fade,
            startsWith(
              '[data-coui-style="liquidGlass"] '
              ':is(.$kFadeBoxClass>.$kWebSurfaceMarker,'
              '.$kFadePanelClass.$kWebSurfaceMarker).${_roleClass[role]}{',
            ),
          );
        }
      },
    );

    test('and none of them breaks the injection they travel in', () {
      // The stylesheet is written into the page as an unescaped
      // single-quoted JS string literal, so one apostrophe anywhere in a rule
      // terminates the literal and takes the whole injection script down. The
      // symptom is a blank page, not a missing rule.
      for (final id in CoreSurfaceStyleId.values) {
        for (final role in CoreSurfaceRole.values) {
          expect(
            _fade(id, role),
            isNot(contains("'")),
            reason: '${id.name} / ${role.name}',
          );
        }
      }
    });

    test(
      'and the sheet carries each of them once, for the style that has them',
      () {
        final sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;
        const names =
            '$kFadeOpacityAnimationVar:$kFadeNoAnimation;'
            '$kFadePaintAnimationVar:var($kFadeGlassPaintNameVar);'
            '$kFadeLayerAnimationVar:var($kFadeGlassLayerNameVar);';

        expect(
          names.allMatches(sheet).length,
          CoreSurfaceRole.values.length,
          reason: 'one rule per role, for the one style that draws a pass',
        );
        for (final role in CoreSurfaceRole.values) {
          expect(sheet, contains(_fade(.liquidGlass, role)));
        }
        for (final other in [
          CoreSurfaceStyleId.neoBrutalism,
          CoreSurfaceStyleId.claymorphism,
        ]) {
          expect(
            sheet,
            isNot(contains('[data-coui-style="${other.name}"] :is(')),
          );
        }
      },
    );
  });

  group('what a panel with a pass states', () {
    test('takes its opacity away and names its other layers', () {
      expect(
        _fade(.liquidGlass, .functional),
        contains(
          '$kFadeOpacityAnimationVar:$kFadeNoAnimation;'
          '$kFadePaintAnimationVar:var($kFadeGlassPaintNameVar);'
          '$kFadeLayerAnimationVar:var($kFadeGlassLayerNameVar);',
        ),
      );
    });

    test('states the list the surface states, with the progress in it', () {
      for (final role in CoreSurfaceRole.values) {
        final fade = _fade(.liquidGlass, role);
        final base = _base(.liquidGlass, role);

        // At a progress of 1 — the surface at rest — it is the list the
        // surface's own rule states, term for term.
        final rest = _listAtRest(fade);
        final plain = _plainList(base);
        expect(rest.blur, plain.blur, reason: role.name);
        expect(rest.saturate, closeTo(plain.saturate, 1e-9), reason: role.name);
        expect(
          rest.brightness,
          closeTo(plain.brightness, 1e-9),
          reason: role.name,
        );
        // And `backdrop-filter` reads it from where the runtime can find it.
        expect(fade, contains('backdrop-filter:var($kWebSurfacePassVar);'));
      }
    });

    test('follows the share Core states, from nothing for the blur', () {
      // Linear in the progress while the exponent is 1; the rule says so by
      // using the progress itself, and would say `pow(…)` for another.
      expect(CoreSurfaceDissolve.materialExponent, 1);
      final fade = _fade(.liquidGlass, .functional);

      expect(fade, contains('blur(calc('));
      expect(fade, contains('var($kFadeProgressVar,1)'));
      expect(fade, isNot(contains('pow(')));
    });

    test(
      'keeps the order of the terms, and the frost and shade where they are',
      () {
        final fade = _fade(.liquidGlass, .functional);
        final list = RegExp(
          '$kWebSurfacePassVar:([^;]*);',
        ).firstMatch(fade)!.group(1)!;

        expect(
          list.indexOf('blur('),
          lessThan(list.indexOf('saturate(')),
          reason: 'the lift runs on the blurred backdrop',
        );
        expect(
          list.indexOf('saturate('),
          lessThan(list.indexOf('brightness(')),
          reason:
              'dimming an amplified backdrop is not amplifying a dimmed one',
        );
      },
    );

    test('fades the fill by the progress itself, not by the share', () {
      final glass = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).surfaceFor(.functional)!;
      final pct = (glass.opacity.light * kPercentScale).round();

      expect(
        _fade(.liquidGlass, .functional),
        contains(
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct% * '
          'var($kFadeProgressVar,1)));',
        ),
      );
    });

    test('is restated for dark where the palette disagrees, in every form', () {
      final glass = CoreSurfaceRecipe.of(
        .liquidGlass,
      ).surfaceFor(.functional)!;
      final fade = _fade(.liquidGlass, .functional);
      const target =
          ':is(.$kFadeBoxClass>.$kWebSurfaceMarker,'
          '.$kFadePanelClass.$kWebSurfaceMarker).$kWebSurfaceRoleFunctional';

      // The same four forms the surface's own rule restates in: the
      // attribute, the system preference, and a brightness scope in either
      // direction.
      expect(
        fade,
        contains('[data-theme="dark"][data-coui-style="liquidGlass"] $target{'),
      );
      expect(fade, contains('@media (prefers-color-scheme:dark){'));
      expect(
        fade,
        contains(
          '[data-coui-style="liquidGlass"] [data-theme="dark"]:not(:root) '
          '$target{',
        ),
      );
      expect(
        fade,
        contains(
          '[data-coui-style="liquidGlass"] [data-theme="light"]:not(:root) '
          '$target{',
        ),
      );
      // The dark numbers are the preset's dark numbers.
      final dark = RegExp(
        r'\[data-theme="dark"\]\[data-coui-style="liquidGlass"\] '
        r'[^{]*\{([^}]*)\}',
      ).firstMatch(fade)!.group(1)!;
      final dimming = double.parse(
        (1 - glass.backdropBrightness.dark).toStringAsFixed(4),
      );
      expect(
        dark,
        contains(
          'brightness(calc(1 - $dimming * var($kFadeProgressVar,1)))',
        ),
      );
    });
  });

  group('where a panel with a pass is taken back to fading by its opacity', () {
    const back =
        '$kFadeOpacityAnimationVar:var($kFadeOpacityNameVar) !important;'
        '$kFadePaintAnimationVar:$kFadeNoAnimation !important;'
        '$kFadeLayerAnimationVar:$kFadeNoAnimation !important;';

    test('the reduced-transparency preference', () {
      final fade = _fade(.liquidGlass, .functional);

      expect(fade, contains('@media (prefers-reduced-transparency:reduce){'));
      expect(fade, contains('{$back}}'));
    });

    test('every quality tier that goes without the pass, and no other', () {
      final fade = _fade(.liquidGlass, .functional);
      const ladder = CoreQualityLadder.standard;

      for (final tier in ladder.tiers) {
        final selector =
            '[data-coui-style="liquidGlass"]'
            '[$kQualityAttribute="${tier.name}"] ';
        if (ladder.withholds(tier, CoreQualityEffect.backdropPass)) {
          expect(fade, contains(selector), reason: tier.name);
        } else {
          expect(fade, isNot(contains(selector)), reason: tier.name);
        }
      }
    });

    test('forced colours, which replaces the fill the terms would fade', () {
      expect(
        _fade(.liquidGlass, .functional),
        contains('@media (forced-colors:active){'),
      );
    });

    test('and each of them states the same three, with !important', () {
      final fade = _fade(.liquidGlass, .functional);
      final dropped = '$back}'.allMatches(fade).length;

      // Reduced transparency, forced colours, and each tier without a pass.
      final tiers = CoreQualityLadder.standard.tiers
          .where(
            (tier) => CoreQualityLadder.standard.withholds(
              tier,
              CoreQualityEffect.backdropPass,
            ),
          )
          .length;
      expect(dropped, 2 + tiers);
    });
  });

  group('where a panel with a pass is read among the rules it restates', () {
    test('every form outranks the surface rule it restates', () {
      // The fade states the same terms as the surface's own rule, so which of
      // the two the browser reads is nothing but specificity. A form that lost
      // would leave the panel at its full terms for the whole fade, in the
      // palette that form is for and nowhere else — and a stylesheet that
      // reads right.
      for (final role in CoreSurfaceRole.values) {
        final base = _rulesOf(_base(.liquidGlass, role));
        final baseSelectors = [for (final rule in base) rule.selector];
        final forms = _termRules(.liquidGlass, role);

        // The light page, the dark attribute, the system preference, and a
        // scope in either direction.
        expect(forms, hasLength(5), reason: role.name);
        for (final form in forms) {
          final restated = form.selector.replaceFirst(
            _fadeTarget,
            '.$kWebSurfaceMarker',
          );

          expect(
            baseSelectors,
            contains(restated),
            reason: 'no rule of the surface to restate for ${form.selector}',
          );
          expect(
            _specificity(form.selector),
            greaterThan(_specificity(restated)),
            reason: '${form.selector} against $restated',
          );
        }
      }
    });

    test('and the specificity it is measured by counts what CSS counts', () {
      // The measure is a copy of CSS's arithmetic, so it is held to a few
      // cases CSS answers.
      expect(_specificity('.a.b'), 2);
      expect(_specificity('[x] .a'), 2);
      expect(_specificity(':is(.a>.b,.c).d'), 3);
      expect(_specificity(':where(.a.b.c).d'), 1);
      expect(_specificity(':not([x]).a'), 2);
      expect(_specificity('[x][y] :is(.a>.b,.c.d).e'), 5);
    });
  });

  group(
    'what a panel with a pass leaves to the palette and the preference',
    () {
      test('declares the pass and the names of the fade, and nothing else', () {
        // The palette and the preference contend for slots on the page's
        // elements, and the two ladder tests that hold that order leave these
        // rules out for it. That is only so while these rules declare nothing
        // they contend for.
        const mine = {
          'surface-pass',
          'fade-opacity',
          'fade-paint',
          'fade-layer',
        };
        for (final role in CoreSurfaceRole.values) {
          final declared = {
            for (final rule in _rulesOf(_fade(.liquidGlass, role)))
              for (final match in RegExp(
                r'(?:^|;)\s*--coui-([a-z-]+):',
              ).allMatches(rule.body))
                match[1]!,
          };

          expect(declared, mine, reason: role.name);
        }
      });

      test('none of them is a slot the page states elsewhere', () {
        final config = ThemeConfig.defaults();
        // The palette, the preference, the scopes: every block that is not a
        // surface style's.
        final elsewhere = config.cssVariables.replaceAll(
          config.surfaceStyleVariableBlocks,
          '',
        );

        for (final name in [
          kWebSurfacePassVar,
          kFadeOpacityAnimationVar,
          kFadePaintAnimationVar,
          kFadeLayerAnimationVar,
        ]) {
          expect(elsewhere, isNot(contains('$name:')), reason: name);
        }
      });
    },
  );
}
