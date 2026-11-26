import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

const CoreSurfaceStyleId _neo = CoreSurfaceStyleId.neoBrutalism;

/// A tuning that moves all three geometry axes at once.
const CoreSurfaceTuning _tuned = CoreSurfaceTuning(
  radiusCap: 0,
  shadowOffsetX: 6,
  shadowOffsetY: 6,
  strokeFloor: CoreStrokeWidth.stroke2,
);

ThemeConfig get _untunedConfig => ThemeConfig.defaults();

/// The CoUI colours [_untunedConfig] renders, with one style tuned — so
/// the two configs differ in the tuning and nothing else.
ThemeConfig get _tunedConfig => const ThemeConfig.from(
  CouiColorPresets.source,
  surfaceTunings: {_neo: _tuned},
);

void main() {
  group('a tuning reaches the stylesheet', () {
    test('a squaring cap moves the radius variables', () {
      // The block emits the *result* of the transform, not the transform,
      // which is why tuning needs no new Web transport: a different recipe
      // is different numbers in the same variables.
      expect(
        _tunedConfig.surfaceStyleVariableBlocks,
        contains('--coui-radius-16:0.0px'),
      );
      expect(
        _untunedConfig.surfaceStyleVariableBlocks,
        isNot(contains('--coui-radius-16:0.0px')),
      );
    });

    test('an offset moves the press-affordance variables', () {
      final css = _tunedConfig.surfaceStyleVariableBlocks;

      expect(css, contains('--coui-control-shadow-offset-x:6.0px'));
      expect(css, contains('--coui-control-shadow-offset-y:6.0px'));
    });

    test('a stroke floor moves the border-width variables', () {
      expect(
        _tunedConfig.surfaceStyleVariableBlocks,
        contains('--coui-stroke-width-1:2.0px'),
      );
    });
  });

  group('a tuning is scoped to the style it names', () {
    test('another style keeps its own authored geometry', () {
      final tunedCss = _tunedConfig.surfaceStyleVariableBlocks;
      final untunedCss = _untunedConfig.surfaceStyleVariableBlocks;

      // Every rule the style emits, not the first one. A style contributes
      // several blocks under the same selector — colour, geometry, surface
      // treatment — and a geometry-only tuning moves exactly one of them,
      // so reading only the first would compare two colour blocks and call
      // them unchanged.
      String blocksFor(String css, CoreSurfaceStyleId id) => RegExp(
        r'\[data-coui-style="' + id.name + r'"\]\{[^}]*\}',
      ).allMatches(css).map((m) => m[0]).join();

      // Neumorphism sits in the same stylesheet and was not named by the
      // tuning. A shared mutable recipe container — or a fold applied to
      // the wrong id — would show up here and nowhere else, because on
      // screen it reads as "that style always looked like that".
      expect(
        blocksFor(tunedCss, .neumorphism),
        blocksFor(untunedCss, .neumorphism),
      );
      expect(
        blocksFor(tunedCss, _neo),
        isNot(blocksFor(untunedCss, _neo)),
      );
    });
  });

  group('an untuned app gets the stylesheet it had', () {
    test('an empty tuning map emits byte-identical rules', () {
      // Built at run time, the way an app that assembles its tunings hands
      // them over. The const empty map is the parameter's default, so
      // stating it would compare the default config with itself.
      final noTunings = <CoreSurfaceStyleId, CoreSurfaceTuning>{};
      expect(
        ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: noTunings,
        ).surfaceStyleVariableBlocks,
        _untunedConfig.surfaceStyleVariableBlocks,
      );
    });

    test('a tuning that states nothing emits byte-identical rules', () {
      // `CoreSurfaceTuning.none` folds to the preset instance itself, so
      // this is the same assertion one layer up: naming a style without
      // changing it must not perturb the output.
      expect(
        const ThemeConfig.from(
          CouiColorPresets.source,
          surfaceTunings: {_neo: .none},
        ).surfaceStyleVariableBlocks,
        _untunedConfig.surfaceStyleVariableBlocks,
      );
    });
  });

  group('the accessibility rules survive tuning', () {
    test('the forced-colours block still names the tuned style', () {
      // The a11y contract is not reachable from a tuning, so its rule has
      // to come out unchanged — a tuned preset that lost its forced-colours
      // boundary would be the exact failure the acceptance gate names.
      final tuned = _tunedConfig.surfaceStyleVariableBlocks;
      final untuned = _untunedConfig.surfaceStyleVariableBlocks;

      const marker = '@media (forced-colors:active)';
      expect(
        tuned.contains(marker),
        untuned.contains(marker),
        reason: 'tuning must not add or remove a forced-colours rule',
      );
    });
  });
}
