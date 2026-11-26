// The rules a brightness scope renders its subtree with — `data-theme` on an
// element below the root, which `BrightnessScope` writes.
//
// Read from the stylesheet the page is served. A scope restates what an
// element cannot inherit correctly from a root in the other brightness: its
// palette and shadow strength, every variable the root derives from them, the
// text colour, high contrast, and a surface style's colour and shadow bends.
// It restates nothing else — a plain value inherits unchanged, and writing it
// again would undo what a style moved on the root.

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// One rule: the `@media` it sits in (or null), its selector, its
/// declarations in order.
typedef _Rule = ({String? media, String selector, Map<String, String> body});

/// Every rule in [css], one `@media` level deep — all this stylesheet uses.
List<_Rule> _rules(String css, {String? media}) {
  final rules = <_Rule>[];
  var i = 0;
  while (i < css.length) {
    final open = css.indexOf('{', i);
    if (open < 0) break;
    final selector = css.substring(i, open).trim();
    // Brace-matched, so a media block ends where its own `}` closes it.
    var depth = 1;
    var j = open + 1;
    for (; j < css.length && depth > 0; j++) {
      if (css[j] == '{') depth++;
      if (css[j] == '}') depth--;
    }
    final inner = css.substring(open + 1, j - 1);
    if (selector.startsWith('@media')) {
      rules.addAll(_rules(inner, media: selector));
    } else if (selector.isNotEmpty) {
      rules.add((
        media: media,
        selector: selector,
        body: {
          for (final declaration in inner.split(';'))
            if (declaration.contains(':'))
              declaration.substring(0, declaration.indexOf(':')).trim():
                  declaration.substring(declaration.indexOf(':') + 1).trim(),
        },
      ));
    }
    i = j;
  }

  return rules;
}

/// The one rule in [css] whose selector is exactly [selector].
_Rule _only(String css, String selector, {String? media}) {
  final matches = _rules(
    css,
  ).where((rule) => rule.selector == selector && rule.media == media);
  expect(matches, hasLength(1), reason: '$selector in ${media ?? 'no media'}');

  return matches.single;
}

/// Class-column specificity — attributes and pseudo-classes, which is all
/// these selectors use. `:not(…)` counts its argument, as CSS does.
int _specificity(String selector) {
  final counted = selector
      .replaceAll(RegExp(r':where\((?:[^()]|\([^()]*\))*\)'), '')
      .replaceAllMapped(RegExp(r':not\(([^()]*)\)'), (m) => m[1]!);

  return RegExp(r'\[[^\]]+\]|:[a-z-]+|\.[\w-]+').allMatches(counted).length;
}

/// Whether [selector] is one of the rules that let a panel fade by its terms.
///
/// A scope restates them for the panels inside it, but the element they match
/// is the panel's surface, not the scope: they sit on no rung of the ladder
/// between the scope's palette and the preference, which is about what the
/// scope element itself says. What they declare is `--coui-surface-pass` and
/// the names of the fade, which neither the palette nor the preference writes
/// (`surface_fade_target_test.dart` holds that).
bool _isPanelFade(String selector) =>
    selector.contains('.$kFadeBoxClass') ||
    selector.contains('.$kFadePanelClass');

const _kLight = '[data-theme="light"]:not(:root)';
const _kDark = '[data-theme="dark"]:not(:root)';
const _kEither = '[data-theme]:not(:root)';
const _kContrast = '@media (prefers-contrast:more)';

void main() {
  final config = ThemeConfig.defaults();
  final block = config.brightnessScopeBlock;

  group('each scope restates its palette', () {
    test('a light scope: every light slot, and the light strength', () {
      final light = _only(block, _kLight).body;

      for (final MapEntry(:key, :value) in config.semanticLightVars.entries) {
        expect(light[key], value, reason: key);
      }
      expect(light[kShadowStrengthVariable], '1');
    });

    test('a dark scope too — a light-only app injects no dark block', () {
      final dark = _only(block, _kDark).body;

      for (final MapEntry(:key, :value) in config.semanticDarkVars.entries) {
        expect(dark[key], value, reason: key);
      }
      expect(dark[kShadowStrengthVariable], '${CoreShadow.darkStrength}');
    });

    test('the attribute a scope writes is the one the rules key off', () {
      // `BrightnessScope` writes `brightness.name`; a renamed value would
      // leave the wrapper matching no rule, with nothing failing to say so.
      for (final brightness in CoreBrightness.values) {
        expect(
          block,
          contains('[data-theme="${brightness.name}"]:not(:root){'),
          reason: brightness.name,
        );
      }
    });

    test('the stylesheet the page is served carries the scope rules', () {
      // The SSR sheet, so a scope is right on first paint.
      expect(config.cssVariables, contains(block));
    });
  });

  group('derived from the palette, restated', () {
    final root = _rules(
      config.cssVariables,
    ).where((rule) => rule.selector == ':root' && rule.media == null);
    final rootDeclarations = {for (final rule in root) ...rule.body};
    // Read inside each test: `expect` cannot run while the group is being
    // declared.
    Map<String, String> either() => _only(block, _kEither).body;

    test('every legacy alias', () {
      for (final key in {
        ...PrimitiveCssGenerator.generateDaisyUiAliases().keys,
        ...PrimitiveCssGenerator.generateShadcnAliases().keys,
      }) {
        expect(either(), contains(key), reason: key);
      }
    });

    test('every shadow stack that names a variable, and only those', () {
      // A custom property that names another is substituted where it is
      // declared: the root's stacks arrive computed with the root's colour
      // and strength.
      final derived = rootDeclarations.entries.where(
        (e) => e.key.startsWith('--') && e.value.contains('var('),
      );
      final shadows = derived.where((e) => e.key.startsWith('--shadow-'));
      expect(shadows, isNotEmpty);
      for (final MapEntry(:key, :value) in shadows) {
        expect(either()[key], value, reason: key);
      }

      // A plain value inherits unchanged; restating it would undo a
      // surface style's root value inside the scope.
      for (final plain in [
        '--coui-surface-rim',
        '--coui-control-shadow',
        '--coui-control-shadow-ghost',
        '--coui-control-shadow-offset-x',
        '--coui-control-shadow-offset-y',
        '--shadow-none',
      ]) {
        expect(rootDeclarations, contains(plain), reason: 'premise: $plain');
        expect(either(), isNot(contains(plain)), reason: plain);
      }
    });

    test('everything the root derives from what a scope changes', () {
      // Transitively: a declaration naming a palette slot or the strength,
      // or naming one that does. A variable added to the root that way and
      // left out of the scope would arrive in it computed with the root's
      // brightness — this is where that would show.
      final changed = {
        ..._only(block, _kLight).body.keys,
        ..._only(block, _kDark).body.keys,
      };
      final derived = <String>{};
      var grew = true;
      while (grew) {
        grew = false;
        for (final MapEntry(:key, :value) in rootDeclarations.entries) {
          if (!key.startsWith('--') || changed.contains(key)) continue;
          if (derived.contains(key)) continue;
          final names = RegExp(
            r'var\((--[\w-]+)',
          ).allMatches(value).map((m) => m[1]!);
          if (names.any(
            (name) => changed.contains(name) || derived.contains(name),
          )) {
            derived.add(key);
            grew = true;
          }
        }
      }

      expect(derived, isNotEmpty);
      for (final key in derived) {
        expect(either(), contains(key), reason: key);
      }
    });

    test("the text colour restarts from the scope's onSurface", () {
      expect(either()['color'], 'rgb(var(--coui-on-surface))');
    });
  });

  group('high contrast raises each scope over its own palette', () {
    final rootContrast = _rules(
      config.cssVariables.replaceAll(block, ''),
    ).where((rule) => rule.media == _kContrast).toList();

    for (final mode in ['light', 'dark']) {
      test('$mode: the same slots, the same values as the root raise', () {
        final scoped = _rules(block).where(
          (rule) =>
              rule.media == _kContrast &&
              rule.selector.contains('[data-theme="$mode"]'),
        );
        expect(scoped, hasLength(1));
        // The root's raise for this mode — the rule whose required
        // attributes name dark, or do not. A light rule that excludes dark
        // inside `:where(:not(…))` is still a light rule.
        final root = rootContrast.singleWhere(
          (rule) =>
              rule.selector
                  .replaceAll(RegExp(r':where\((?:[^()]|\([^()]*\))*\)'), '')
                  .contains('[data-theme="dark"]') ==
              (mode == 'dark'),
        );

        expect(scoped.single.body, root.body);
        expect(scoped.single.body, isNotEmpty);
      });
    }
  });

  group('every scope rule leaves the root alone', () {
    test('the scope block', () {
      for (final rule in _rules(block)) {
        expect(rule.selector, contains(':not(:root)'), reason: rule.selector);
      }
    });
  });

  group('the ladder inside a scope', () {
    test('palette < a style’s bends < high contrast', () {
      final palette = [
        _specificity(_kLight),
        _specificity(_kDark),
      ];
      final bends = _rules(config.surfaceStyleVariableBlocks)
          .where(
            (rule) =>
                rule.selector.contains(':not(:root)') &&
                !_isPanelFade(rule.selector) &&
                rule.body.keys.any((key) => key.startsWith('--coui-')),
          )
          .map((rule) => _specificity(rule.selector))
          .toList();
      final contrast = _rules(block)
          .where((rule) => rule.media == _kContrast)
          .map((rule) => _specificity(rule.selector))
          .toList();

      expect(bends, isNotEmpty, reason: 'some style bends a slot');
      expect(contrast, hasLength(2));
      expect(
        bends.reduce((low, next) => low < next ? low : next),
        greaterThan(palette.reduce((high, next) => high > next ? high : next)),
      );
      expect(
        contrast.reduce((low, next) => low < next ? low : next),
        greaterThan(bends.reduce((high, next) => high > next ? high : next)),
      );
    });
  });

  group('a surface style restated for a scope', () {
    const accentOnly = CoreSurfaceColorConstraint(accentChromaScale: 1.6);

    test('the colour bends, mode for mode', () {
      final css = config.surfaceStyleBlock(.neoBrutalism, accentOnly);
      final rootLight = _only(css, '[data-coui-style="neoBrutalism"]');
      final rootDark = _only(
        css,
        '[data-theme="dark"][data-coui-style="neoBrutalism"]',
      );

      expect(
        _only(css, '[data-coui-style="neoBrutalism"] $_kLight').body,
        rootLight.body,
      );
      expect(
        _only(css, '[data-coui-style="neoBrutalism"] $_kDark').body,
        rootDark.body,
      );
    });

    for (final id in CoreSurfaceStyleId.values) {
      test('$id: the shadow bends, and no geometry', () {
        final recipe = CoreSurfaceRecipe.of(id);
        final css = config.surfaceStyleGeometryBlock(
          id,
          recipe.geometry,
          typography: recipe.typography,
        );
        if (css.isEmpty) return;
        final root = _only(css, '[data-coui-style="${id.name}"]').body;
        final derived = {
          for (final MapEntry(:key, :value) in root.entries)
            if (value.contains('var(')) key: value,
        };
        final scoped = _rules(
          css,
        ).where((rule) => rule.selector.contains(':not(:root)')).toList();

        if (derived.isEmpty) {
          expect(scoped, isEmpty, reason: 'nothing to restate');
          return;
        }
        expect(scoped, hasLength(1));
        expect(
          scoped.single.selector,
          '[data-coui-style="${id.name}"] $_kEither',
        );
        expect(scoped.single.body, derived);
      });
    }
  });

  group('the material reads the scope', () {
    test('a scope form for each mode, level with the document forms', () {
      final recipe = CoreSurfaceRecipe.of(.liquidGlass);
      final floating = recipe.surfaceFor(.functional)!;
      final rules = _rules(
        config.surfaceStyleTreatmentBlock(
          .liquidGlass,
          floating,
          role: .functional,
        ),
      );
      int specificityOf(bool Function(_Rule rule) where) =>
          _specificity(rules.singleWhere(where).selector);

      final attribute = specificityOf(
        (r) =>
            r.media == null &&
            r.selector.startsWith('[data-theme="dark"][data-coui-style'),
      );
      final media = specificityOf(
        (r) => r.media == '@media (prefers-color-scheme:dark)',
      );
      for (final mode in ['light', 'dark']) {
        final scoped = rules.indexWhere(
          (r) => r.selector.contains('[data-theme="$mode"]:not(:root)'),
        );
        expect(scoped, isNonNegative, reason: mode);
        expect(
          _specificity(rules[scoped].selector),
          allOf(greaterThan(attribute), greaterThanOrEqualTo(media)),
          reason: mode,
        );
        // Written after the document forms, so a tie goes to the scope.
        expect(
          scoped,
          greaterThan(
            rules.indexWhere(
              (r) => r.media == '@media (prefers-color-scheme:dark)',
            ),
          ),
          reason: mode,
        );
      }
    });
  });
}
