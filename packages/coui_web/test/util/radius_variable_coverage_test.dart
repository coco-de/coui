import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// Radius steps referenced by a `CoreBorderRadius` default anywhere in the
/// contracts, discovered from source rather than listed here.
///
/// Listing them would be a fourth copy of the same set, which is the thing
/// these tests exist to prevent.
Set<String> _radiusStepsUsedByContracts() {
  final dir = Directory('../coui_core/lib/src/component/contracts');
  final used = <String>{};
  final pattern = RegExp(r'CoreRadius\.(radius\d+)');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_style.dart')) continue;
    for (final m in pattern.allMatches(entity.readAsStringSync())) {
      used.add(m.group(1)!);
    }
  }

  return used;
}

void main() {
  final config = ThemeConfig.defaults();

  group('a radius step that is emitted must also be defined', () {
    test('every step a contract default uses has a CSS variable', () {
      // The inline emitter turns a matching value into
      // `var(--coui-radius-N)`. If the `:root` block does not define that
      // variable, the browser drops the declaration and the corner silently
      // renders square.
      final used = _radiusStepsUsedByContracts();
      expect(
        used,
        isNotEmpty,
        reason: 'source scan found nothing — check path',
      );

      final css = config.cssVariables;
      for (final step in used) {
        final n = step.replaceFirst('radius', '');
        expect(
          css,
          contains('--coui-radius-$n:'),
          reason: '$step is used by a contract default but has no variable',
        );
      }
    });

    test('a runtime custom theme rewrites every step the emitter names', () {
      // `CoUIThemeController.setCustomTheme` writes the generator's map
      // onto the document root. A step `radiusCss` references but the map
      // leaves out keeps its `:root` value while its neighbours scale.
      final vars = CssVariableGenerator.generate(
        CoreThemeData(
          colorScheme: CouiColorPresets.source.light(),
          brightness: .light,
          designSystem: .coui,
          radiusScaling: 1.5,
        ),
      );
      for (final step in kRadiusSteps) {
        expect(
          vars.containsKey('--coui-radius-${step.key}'),
          isTrue,
          reason: 'radius-${step.key} is emitted but not rescaled',
        );
      }
    });

    test('the Tailwind key map covers the same steps', () {
      final used = _radiusStepsUsedByContracts();
      final tailwind = config.tailwindConfig;
      for (final step in used) {
        final n = step.replaceFirst('radius', '');
        expect(
          tailwind,
          contains('var(--coui-radius-$n)'),
          reason: '$step has no Tailwind key',
        );
      }
    });
  });

  group('an off-scale value is not mistaken for a token', () {
    test('a deliberate 4.7 stays a literal', () {
      // This used to compare `px.toInt()`, so 4.7 matched the radius-4 step
      // and emitted that token's variable — contradicting the documented
      // promise that arbitrary values emit literally, and letting a surface
      // style move a value the caller had pinned.
      const arbitrary = CoreBorderRadius.all(4.7);
      final css = arbitrary.toValue();
      expect(css, contains('4.7px'));
      expect(css, isNot(contains('--coui-radius-4')));
    });

    test('an exact token value still resolves to its variable', () {
      const exact = CoreBorderRadius.all(CoreRadius.radius8);
      expect(exact.toValue(), contains('var(--coui-radius-8)'));
    });

    test('a step added since the original five resolves too', () {
      const twelve = CoreBorderRadius.all(CoreRadius.radius12);
      expect(twelve.toValue(), contains('var(--coui-radius-12)'));
    });
  });
}
