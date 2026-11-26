// The whole stroke ladder as the Web reads it: every `CoreStrokeWidth` step
// has a `--coui-stroke-width-*` variable, a Tailwind `borderWidth` key that
// reads that variable, and a place in the surface style's stroke floor.
//
// A step that has the Dart constant but misses one of these three is silent:
// `border-strokeN` generates no rule and the border vanishes, or a surface
// style's floor never reaches the variable. Nothing throws, so the ladder is
// written out here and each step is read back.
import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// Every step by its variable / key spelling (`_` is the decimal point).
const _ladder = <String, double>{
  '0': CoreStrokeWidth.stroke0,
  '0_5': CoreStrokeWidth.stroke0_5,
  '1': CoreStrokeWidth.stroke1,
  '1_5': CoreStrokeWidth.stroke1_5,
  '2': CoreStrokeWidth.stroke2,
  '3': CoreStrokeWidth.stroke3,
  '4': CoreStrokeWidth.stroke4,
  '5': CoreStrokeWidth.stroke5,
  '6': CoreStrokeWidth.stroke6,
  '8': CoreStrokeWidth.stroke8,
};

void main() {
  final config = ThemeConfig.defaults();

  /// The body of `borderWidth:{...}` — the keys Tailwind turns into
  /// `border-<key>` rules.
  final borderWidthKeys = RegExp(
    r'borderWidth:\{([^}]*)\}',
  ).firstMatch(config.tailwindConfig)!.group(1)!;

  group('every stroke step', () {
    for (final MapEntry(key: leaf, value: px) in _ladder.entries) {
      test('stroke/$leaf has a variable, a Tailwind key and a floor', () {
        // The variable (the hairline reads 1px at `:root` for a 1x screen).
        expect(config.cssVariables, contains('--coui-stroke-width-$leaf:'));
        // The key `border-stroke<leaf>` resolves through.
        expect(
          borderWidthKeys,
          contains('stroke$leaf:"var(--coui-stroke-width-$leaf)"'),
        );
        // The inline route lands on the same variable.
        expect(strokeWidthCss(px), 'var(--coui-stroke-width-$leaf)');
      });
    }

    test('the ladder here is the whole of the class-key map', () {
      // A key in the config this list does not know would be a step the
      // tests above never read.
      final keys = RegExp(
        '(stroke[0-9_]+):',
      ).allMatches(borderWidthKeys).map((m) => m.group(1)).toSet();

      expect(keys, {for (final leaf in _ladder.keys) 'stroke$leaf'});
    });
  });

  group('the 5px step', () {
    test(':root declares it at its own width', () {
      expect(config.cssVariables, contains('--coui-stroke-width-5:5.0px;'));
    });

    test('the Tailwind key `stroke5` reads its variable', () {
      expect(
        borderWidthKeys,
        contains(
          '${CoreStrokeWidth.scale.stroke5}:"var(--coui-stroke-width-5)"',
        ),
      );
    });

    test('a style whose floor is above it lifts it like any other step', () {
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        const CoreSurfaceGeometryConstraint(
          strokeFloor: CoreStrokeWidth.stroke6,
        ),
      );

      expect(block, contains('--coui-stroke-width-5:6.0px'));
    });

    test('a floor below it leaves it alone', () {
      // The shipped heavy style floors at 4: a 5px line is already heavier,
      // so declaring the step would assert a difference that is not there.
      final block = config.surfaceStyleGeometryBlock(
        CoreSurfaceStyleId.neoBrutalism,
        const CoreSurfaceGeometryConstraint(
          strokeFloor: CoreStrokeWidth.stroke4,
        ),
      );

      expect(block, isNot(contains('--coui-stroke-width-5:')));
    });
  });
}
