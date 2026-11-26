// The chroma lift, the angle of the edge light and the law of the rim are the
// terms of the glass an app can state per mode (the law: at all). This is the
// Web half of the table `surface_mode_vectors.json`: what the stylesheet says
// for each, in the light rule and in every form the dark palette is reached
// through, and what the per-element runtime is told about the two terms that
// are not CSS.
//
// A stylesheet is read by a browser that matches selectors, so a rule can be
// correct as text and still never apply. The browser half of this file is
// `tool/parity/test/web/surface_mode_probe_test.dart`; this one is the text.

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/surface_runtime_inputs.dart';
import 'package:test/test.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/surface_mode_vectors.json';

const CoreSurfaceStyleId _glass = CoreSurfaceStyleId.liquidGlass;

/// The class pair every functional surface carries; depth zero is the one
/// the runtime inputs and the per-mode restatements are written for.
const String _kTarget = '.$kWebSurfaceMarker.$kWebSurfaceRoleFunctional';

List<Map<String, Object?>> _cases() {
  final file = File(_kVectorsPath);
  if (!file.existsSync()) throw StateError('the shared table is gone');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

  return (decoded['cases']! as List<Object?>).cast<Map<String, Object?>>();
}

double? _opt(Map<String, Object?> from, String key) =>
    (from[key] as num?)?.toDouble();

CoreSurfaceTuning _tuningFrom(Map<String, Object?> tuning) => CoreSurfaceTuning(
  surfaceSaturation: _opt(tuning, 'surfaceSaturation'),
  surfaceSaturationInDarkMode: _opt(tuning, 'surfaceSaturationInDarkMode'),
  lightAngle: _opt(tuning, 'lightAngle'),
  lightAngleInDarkMode: _opt(tuning, 'lightAngleInDarkMode'),
  refractionModel: switch (tuning['refractionModel']) {
    final String name => CoreRefractionModel.values.byName(name),
    _ => null,
  },
);

({double light, double dark}) _pair(Object? value) {
  final map = value! as Map<String, Object?>;

  return (
    light: (map['light']! as num).toDouble(),
    dark: (map['dark']! as num).toDouble(),
  );
}

/// The sheet an app that states [tuning] ships.
String _sheet(CoreSurfaceTuning tuning) => ThemeConfig.from(
  CouiColorPresets.source,
  surfaceTunings: {_glass: tuning},
).surfaceStyleVariableBlocks;

/// The sheet an app that states nothing ships.
final String _untuned = ThemeConfig.defaults().surfaceStyleVariableBlocks;

/// The selectors one term of the material is written under: the light rule
/// and each of the four ways the dark palette is reached.
///
/// Four because a theme switch rebuilds nothing and the palette is a
/// document attribute, an OS preference, or a scope inside a page of the
/// other palette — and a statically rendered page has only the second.
class _Forms {
  const _Forms({
    required this.base,
    required this.darkAttribute,
    required this.darkMedia,
    required this.darkScope,
    required this.lightScope,
  });

  /// The forms of the document's own style, for the pseudo-element
  /// [pseudo] (empty for the surface itself).
  factory _Forms.global([String pseudo = '']) => _Forms(
    base: '[data-coui-style="${_glass.name}"] $_kTarget$pseudo',
    darkAttribute:
        '[data-theme="dark"][data-coui-style="${_glass.name}"] '
        '$_kTarget$pseudo',
    darkMedia:
        ':root:not([data-theme="light"]) '
        '[data-coui-style="${_glass.name}"] $_kTarget$pseudo',
    darkScope:
        '[data-coui-style="${_glass.name}"] [data-theme="dark"]:not(:root) '
        '$_kTarget$pseudo',
    lightScope:
        '[data-coui-style="${_glass.name}"] [data-theme="light"]:not(:root) '
        '$_kTarget$pseudo',
  );

  /// The forms of a surface that carries its own style class, for the
  /// pseudo-element [pseudo] (empty for the surface itself).
  factory _Forms.local([String pseudo = '']) {
    final scope =
        '.$kWebLocalSurfaceMarker.$kWebSurfaceRoleFunctional'
        '.coui-material-${_glass.name}';

    return _Forms(
      base: '$scope$pseudo',
      darkAttribute: '[data-theme="dark"] $scope$pseudo',
      darkMedia: ':root:not([data-theme="light"]) $scope$pseudo',
      darkScope: '[data-theme="dark"]:not(:root) $scope$pseudo',
      lightScope: '[data-theme="light"]:not(:root) $scope$pseudo',
    );
  }

  final String base;
  final String darkAttribute;
  final String darkMedia;
  final String darkScope;
  final String lightScope;

  /// Every selector that reaches the dark palette.
  List<String> get dark => [darkAttribute, darkMedia, darkScope];
}

/// The body of the rule written under exactly [selector], or null.
///
/// Anchored to the end of the rule before it: the selector of the light rule
/// is the tail of every dark one, and a search that ignored that would find
/// the dark rule when asked for the light.
String? _body(String css, String selector, {bool inMedia = false}) {
  final escaped = RegExp.escape(selector);
  final pattern = inMedia
      ? RegExp(
          r'@media \(prefers-color-scheme:dark\)\{'
          '$escaped'
          r'\{([^}]*)\}\}',
        )
      : RegExp('(?:^|\\})$escaped\\{([^}]*)\\}');

  return pattern.firstMatch(css)?.group(1);
}

/// The body of the rule [forms] states for [selector], taking the media form
/// for what it is.
String? _bodyIn(String css, _Forms forms, String selector) =>
    _body(css, selector, inMedia: selector == forms.darkMedia);

/// The chroma multiplier the declaration states, or identity when it leaves
/// the function out (which is how identity is stated).
double _lift(String body) {
  final list = RegExp('backdrop-filter:([^;]*);').firstMatch(body)?.group(1);
  expect(list, isNotNull, reason: 'no backdrop-filter in: $body');
  final match = RegExp(r'saturate\(([0-9.]+)\)').allMatches(list!).toList();
  expect(match.length, lessThanOrEqualTo(1), reason: list);

  return match.isEmpty ? 1 : double.parse(match.single.group(1)!);
}

/// The first `inset X Y` layer of a `box-shadow`, in pixels.
({double x, double y}) _firstOffset(String body) {
  final match = RegExp(
    'box-shadow:inset (-?[0-9.]+)rem (-?[0-9.]+)rem',
  ).firstMatch(body);
  expect(match, isNotNull, reason: 'no wall layer in: $body');

  return (
    x: double.parse(match!.group(1)!) * 16,
    y: double.parse(match.group(2)!) * 16,
  );
}

CoreSurfaceEdgeBevel get _presetBevel =>
    CoreSurfaceRecipe.of(_glass).functionalSurface!.sheen!.bevel!;

void main() {
  final cases = _cases();

  test('the table has the cases these groups loop over', () {
    // A loop over nothing passes.
    expect(cases.length, greaterThanOrEqualTo(9));
  });

  group('the chroma lift is stated for each mode', () {
    test('in the light rule, and in every form of the dark palette', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);
        final sheet = _sheet(tuning);
        final lift = _pair(each['saturation']);
        final forms = _Forms.global();
        final reason = each['name']! as String;

        expect(_lift(_body(sheet, forms.base)!), lift.light, reason: reason);
        for (final selector in forms.dark) {
          final body = _bodyIn(sheet, forms, selector);
          expect(body, isNotNull, reason: '$reason: $selector');
          expect(_lift(body!), lift.dark, reason: '$reason: $selector');
        }
        expect(
          _lift(_body(sheet, forms.lightScope)!),
          lift.light,
          reason: '$reason: a light scope in a dark page',
        );
      }
    });

    test('and the rest of the filter list is the one it always was', () {
      // The dimming rides the same list. A restatement that took the lift
      // from one mode and the dimming from the other would be a surface that
      // is right in neither.
      final brightness = CoreSurfaceRecipe.of(
        _glass,
      ).functionalSurface!.backdropBrightness;
      final forms = _Forms.global();

      for (final each in cases) {
        final sheet = _sheet(
          _tuningFrom(each['tuning']! as Map<String, Object?>),
        );

        expect(
          _body(sheet, forms.base),
          contains('brightness(${brightness.light})'),
          reason: each['name']! as String,
        );
        for (final selector in forms.dark) {
          expect(
            _bodyIn(sheet, forms, selector),
            contains('brightness(${brightness.dark})'),
            reason: '${each['name']}: $selector',
          );
        }
      }
    });

    test('a surface that states its own style gets the same forms', () {
      // The document's style and a surface's own are written by one builder
      // under two selectors, and the second is the one an embedded preview
      // uses. It has no `[data-coui-style]` ancestor, so the media form
      // reaches it where the document's cannot.
      const tuning = CoreSurfaceTuning(
        surfaceSaturation: 1.3,
        surfaceSaturationInDarkMode: 1.9,
      );
      final sheet = _sheet(tuning);
      final forms = _Forms.local();

      expect(_lift(_body(sheet, forms.base)!), 1.3);
      for (final selector in forms.dark) {
        expect(
          _lift(_bodyIn(sheet, forms, selector)!),
          1.9,
          reason: selector,
        );
      }
      expect(_lift(_body(sheet, forms.lightScope)!), 1.3);
    });

    test('a lift that differs by mode and nothing else restates the list', () {
      // The shipped glass dims by mode too, so the table above would pass
      // with the lift left out of the gate that decides whether a dark rule
      // exists at all. A token that differs in the lift alone cannot.
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.5),
        blur: 12,
        saturation: 1.4,
        saturationInDarkMode: 1.8,
      );
      final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
        _glass,
        token,
        role: CoreSurfaceRole.functional,
      );
      final forms = _Forms.global();

      expect(_lift(_body(css, forms.base)!), 1.4);
      for (final selector in forms.dark) {
        expect(
          _lift(_bodyIn(css, forms, selector)!),
          1.8,
          reason: selector,
        );
      }
    });

    test('a lift that does not differ by mode emits no dark rule', () {
      // Two extra rules per surface is not free, and a rule that restates
      // the value above it is a second place to change one number.
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.5),
        blur: 12,
        saturation: 1.4,
      );
      final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
        _glass,
        token,
        role: CoreSurfaceRole.functional,
      );

      expect(css, isNot(contains('prefers-color-scheme')));
      expect(css, isNot(contains('[data-theme="dark"]')));
    });

    test('a dark lift of exactly one leaves the function out there', () {
      // Identity is stated by omission, light or dark: `saturate(1)` is a
      // no-op the browser still has to evaluate, and the light rule has
      // never written it.
      const token = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.5),
        blur: 12,
        saturation: 1.4,
        saturationInDarkMode: 1,
      );
      final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
        _glass,
        token,
        role: CoreSurfaceRole.functional,
      );
      final forms = _Forms.global();

      expect(_body(css, forms.base), contains('saturate(1.4)'));
      for (final selector in forms.dark) {
        final body = _bodyIn(css, forms, selector)!;
        expect(body, contains('backdrop-filter:blur(12.0px)'));
        expect(body, isNot(contains('saturate(')), reason: selector);
      }
    });
  });

  group('the edge is lit from the angle of each mode', () {
    test('the wall is restated for dark only where the angles differ', () {
      final wall = _Forms.global('::after');
      final bevel = _presetBevel;

      for (final each in cases) {
        final sheet = _sheet(
          _tuningFrom(each['tuning']! as Map<String, Object?>),
        );
        final angle = _pair(each['lightAngle']);
        final reason = each['name']! as String;

        ({double x, double y}) expected(double degrees) {
          final layer = bevel.relit(angle: degrees).toLayers().first;

          return (x: layer.offsetX, y: layer.offsetY);
        }

        void expectOffset(String? body, double degrees, String where) {
          expect(body, isNotNull, reason: '$reason: $where');
          final got = _firstOffset(body!);
          expect(got.x, closeTo(expected(degrees).x, 1e-6), reason: where);
          expect(got.y, closeTo(expected(degrees).y, 1e-6), reason: where);
        }

        expectOffset(
          _body(sheet, wall.base),
          angle.light,
          '$reason: the wall of the light rule',
        );
        if (angle.light == angle.dark) {
          for (final selector in [...wall.dark, wall.lightScope]) {
            expect(
              _bodyIn(sheet, wall, selector),
              isNull,
              reason: '$reason: nothing to restate, but $selector exists',
            );
          }
          continue;
        }
        for (final selector in wall.dark) {
          expectOffset(
            _bodyIn(sheet, wall, selector),
            angle.dark,
            '$reason: $selector',
          );
        }
        expectOffset(
          _body(sheet, wall.lightScope),
          angle.light,
          '$reason: a light scope in a dark page',
        );
      }
    });

    test('the rim chooses the dark sweep only where the angles differ', () {
      final rim = _Forms.global('::before');
      const light = 'background:var($kWebSurfaceRimSweepVar,none);';
      const dark =
          'background:var($kWebSurfaceRimSweepDarkVar,'
          'var($kWebSurfaceRimSweepVar,none));';

      for (final each in cases) {
        final sheet = _sheet(
          _tuningFrom(each['tuning']! as Map<String, Object?>),
        );
        final angle = _pair(each['lightAngle']);
        final reason = each['name']! as String;

        expect(_body(sheet, rim.base), contains(light), reason: reason);
        if (angle.light == angle.dark) {
          expect(
            sheet,
            isNot(contains('var($kWebSurfaceRimSweepDarkVar')),
            reason: '$reason: there is no second sweep to choose',
          );
          continue;
        }
        for (final selector in rim.dark) {
          expect(
            _bodyIn(sheet, rim, selector),
            dark,
            reason: '$reason: $selector',
          );
        }
        expect(_body(sheet, rim.lightScope), light, reason: reason);
      }
    });
  });

  group('what the runtime cannot see, the sheet states on the surface', () {
    String? declared(String sheet, String name) {
      final base = _body(sheet, _Forms.global().base)!;

      return RegExp('$name:([^;]*);').firstMatch(base)?.group(1);
    }

    test('an angle and a law only where they differ from the preset', () {
      for (final each in cases) {
        final tuning = _tuningFrom(each['tuning']! as Map<String, Object?>);
        final sheet = _sheet(tuning);
        final angle = _pair(each['lightAngle']);
        final presetAngle = _presetBevel.lightAngle;
        final reason = each['name']! as String;

        expect(
          declared(sheet, kWebSurfaceRimAngleVar),
          angle.light == presetAngle ? isNull : '${angle.light}',
          reason: reason,
        );
        expect(
          declared(sheet, kWebSurfaceRimAngleDarkVar),
          angle.dark == presetAngle ? isNull : '${angle.dark}',
          reason: reason,
        );
        expect(
          declared(sheet, kWebSurfaceRefractionModelVar),
          each['refractionModel'] == 'snell' ? isNull : each['refractionModel'],
          reason: reason,
        );
      }
    });

    test("and read back, they are the table's light and law", () {
      // The loop the runtime closes: a tuning in, a stylesheet out, the
      // numbers the runtime reads off the surface, and the light and law it
      // draws with. Each step is tested alone above; this is the claim that
      // they compose.
      final refraction = CoreSurfaceRecipe.of(_glass).refraction!;

      for (final each in cases) {
        final sheet = _sheet(
          _tuningFrom(each['tuning']! as Map<String, Object?>),
        );
        final base = _body(sheet, _Forms.global().base)!;
        String property(String name) =>
            RegExp('$name:([^;]*);').firstMatch(base)?.group(1) ?? '';

        final inputs = SurfaceRuntimeInputs.read(property);
        final rims = inputs.rimsFor(_presetBevel);
        final angle = _pair(each['lightAngle']);
        final reason = each['name']! as String;

        expect(rims.light.lightAngle, angle.light, reason: reason);
        expect(
          rims.dark?.lightAngle ?? rims.light.lightAngle,
          angle.dark,
          reason: reason,
        );
        expect(
          inputs.refractionFor(refraction).model.name,
          each['refractionModel'],
          reason: reason,
        );
      }
    });

    test('and once, on the rule every surface of the style matches', () {
      // A nested surface matches the rule above as well as its own, so a
      // second copy at each depth would be a second place to change a number.
      final sheet = _sheet(
        const CoreSurfaceTuning(
          lightAngle: -30,
          refractionModel: CoreRefractionModel.paraxial,
        ),
      );
      final nested = _body(
        sheet,
        '[data-coui-style="${_glass.name}"] '
        '.$kWebSurfaceMarker .$kWebSurfaceMarker.$kWebSurfaceRoleFunctional',
      );

      expect(nested, isNotNull, reason: 'the premise: a nested rule exists');
      expect(nested, isNot(contains(kWebSurfaceRimAngleVar)));
      expect(nested, isNot(contains(kWebSurfaceRefractionModelVar)));
      expect(
        '$kWebSurfaceRefractionModelVar:paraxial;'.allMatches(sheet),
        hasLength(4),
        reason:
            "two roles, each under the document's style and under the "
            "surface's own class — and no copy per depth",
      );
    });

    test("a surface of another style does not inherit the page's", () {
      // A custom property inherits. Without a reset at zero specificity a
      // preview of an untuned style nested in a tuned surface would read the
      // surface's light and draw its own rim from it.
      final sheet = _sheet(const CoreSurfaceTuning(lightAngle: -30));
      const reset =
          ':where(.$kWebSurfaceMarker,.$kWebLocalSurfaceMarker){'
          '$kWebSurfaceRimAngleVar:initial;'
          '$kWebSurfaceRimAngleDarkVar:initial;'
          '$kWebSurfaceRefractionModelVar:initial;'
          '$kWebSurfaceRimSweepDarkVar:initial;'
          '}';

      expect(reset.allMatches(sheet), isNotEmpty);
      expect(
        reset.allMatches(sheet),
        hasLength(1),
        reason: 'one rule for every surface, not one per style',
      );
      // After the rules it must not outrank: zero specificity means order
      // is irrelevant, and a reset that carried any would win over them.
      expect(reset, startsWith(':where('));
    });
  });

  group('a sheet that states nothing new is the sheet it was', () {
    const names = [
      kWebSurfaceRimAngleVar,
      kWebSurfaceRimAngleDarkVar,
      kWebSurfaceRefractionModelVar,
      kWebSurfaceRimSweepDarkVar,
    ];

    test('the untuned sheet carries none of the new properties', () {
      for (final name in names) {
        expect(_untuned, isNot(contains(name)), reason: name);
      }
    });

    test('and none of the restatements the new terms bring', () {
      // The dark rules of a pseudo-element are the other thing a tuning adds.
      // An untuned sheet has never had a rim or a wall that differs by mode.
      final wall = _Forms.global('::after');
      final rim = _Forms.global('::before');

      for (final forms in [wall, rim]) {
        for (final selector in [...forms.dark, forms.lightScope]) {
          expect(_untuned, isNot(contains(selector)), reason: selector);
        }
      }
    });

    test('a tuning that restates the preset emits the same bytes', () {
      // Stating what the preset already states is not a change, and a sheet
      // that grew for it would make "an untuned app" depend on whether the
      // app happened to name a style.
      final preset = CoreSurfaceRecipe.of(_glass);
      final restated = CoreSurfaceTuning(
        surfaceSaturation: preset.functionalSurface!.saturation,
        lightAngle: _presetBevel.lightAngle,
        refractionModel: preset.refraction!.model,
      );

      expect(restated.isIdentity, isFalse, reason: 'the premise');
      expect(_sheet(restated), _untuned);
    });
  });

  group('the runtime reads what the sheet gave it', () {
    test('nothing stated is the preset, and nothing is rebuilt', () {
      final inputs = SurfaceRuntimeInputs.read((_) => '');
      final refraction = CoreSurfaceRecipe.of(_glass).refraction!;

      expect(inputs.isEmpty, isTrue);
      expect(identical(inputs.refractionFor(refraction), refraction), isTrue);
      expect(inputs.rimsFor(_presetBevel).dark, isNull);
      expect(inputs.rimsFor(_presetBevel).light, _presetBevel);
    });

    test('a number is read through the whitespace the browser keeps', () {
      final inputs = SurfaceRuntimeInputs.read(
        (name) => switch (name) {
          kWebSurfaceRimAngleVar => ' -30.0 ',
          kWebSurfaceRimAngleDarkVar => '-60.0',
          kWebSurfaceRefractionModelVar => ' paraxial',
          _ => '',
        },
      );

      expect(inputs.rimAngle, -30);
      expect(inputs.rimAngleInDarkMode, -60);
      expect(inputs.refractionModel, CoreRefractionModel.paraxial);
      expect(inputs.isEmpty, isFalse);
    });

    test('a value it does not know is not a statement', () {
      final inputs = SurfaceRuntimeInputs.read(
        (name) => switch (name) {
          kWebSurfaceRimAngleVar => 'calc(1 + 2)',
          kWebSurfaceRefractionModelVar => 'wobbly',
          _ => '',
        },
      );

      expect(inputs.isEmpty, isTrue);
    });

    test('the dark light is a second sweep only when it is another light', () {
      // Writing a dark sweep equal to the light one would be a second string
      // of the same stops on every refracted surface.
      final same = const SurfaceRuntimeInputs(
        rimAngle: -30,
        rimAngleInDarkMode: -30,
      ).rimsFor(_presetBevel);
      final other = const SurfaceRuntimeInputs(
        rimAngle: -30,
        rimAngleInDarkMode: -60,
      ).rimsFor(_presetBevel);
      final darkOnly = const SurfaceRuntimeInputs(
        rimAngleInDarkMode: -60,
      ).rimsFor(_presetBevel);

      expect(same.dark, isNull);
      expect(other.light.lightAngle, -30);
      expect(other.dark!.lightAngle, -60);
      expect(darkOnly.light.lightAngle, _presetBevel.lightAngle);
      expect(darkOnly.dark!.lightAngle, -60);
    });

    test("a sweep carries the rest of the preset's rim unchanged", () {
      final lit = const SurfaceRuntimeInputs(
        rimAngle: -30,
      ).rimsFor(_presetBevel).light;

      expect(lit.rimWidth, _presetBevel.rimWidth);
      expect(lit.rimIntensity, _presetBevel.rimIntensity);
      expect(lit.thickness, _presetBevel.thickness);
      expect(lit.lightAngleInDarkMode, isNull);
    });
  });
}
