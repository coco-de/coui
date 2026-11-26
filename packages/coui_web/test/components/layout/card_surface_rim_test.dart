import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveCard` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

List<String> _classes(ResolvedCard resolved) =>
    resolved.root.className.split(' ');

String? _rootShadow(ResolvedCard resolved) =>
    resolved.root.inlineStyles?.properties['box-shadow'];

/// The single global rule the marker selects, pulled out of the theme's
/// stylesheet so the assertions read the declaration rather than the
/// whole sheet.
String _markerRule() {
  final css = ThemeConfig.defaults().cssVariables;
  final start = css.indexOf('.$kSurfaceRimLiftMarker');
  if (start < 0) return '';
  final end = css.indexOf('}', start);
  return css.substring(start, end + 1);
}

void main() {
  group('a card whose lift rides the elevation classes', () {
    testComponents('carries the rim marker beside its shadow class', (
      tester,
    ) async {
      // The Flutter twin draws the rim on any surface that casts
      // (`resolveSurfaceRim` gates on the stack, not on hover). The Web
      // default-elevation path used to cast through a class alone, so
      // under a style that states a rim it was the one surface drawn
      // without one.
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(elevation: .medium),
      );

      expect(_classes(resolved), contains('shadow-md'));
      expect(_classes(resolved), contains(kSurfaceRimLiftMarker));
      // Not inline — an inline box-shadow is what froze the hover lift.
      expect(_rootShadow(resolved), isNull);
    });

    testComponents(
      'a hoverable one keeps its hover class and gains no inline shadow',
      (tester) async {
        final resolved = resolveCard(
          _themedContext(tester),
          variant: .defaultVariant,
          hasMedia: false,
          interactive: true,
          cardStyle: const CoreCardStyle(
            elevation: .soft,
            hoverElevation: .strong,
          ),
        );

        expect(_classes(resolved), contains('shadow-sm'));
        expect(_classes(resolved), contains('hover:shadow-lg'));
        expect(_classes(resolved), contains(kSurfaceRimLiftMarker));
        expect(_rootShadow(resolved), isNull);
      },
    );

    testComponents('a flat card does not take it — a rim needs a lift', (
      tester,
    ) async {
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: true,
      );

      expect(_classes(resolved), isNot(contains(kSurfaceRimLiftMarker)));
    });

    testComponents('an authored shadow carries its own rim inline instead', (
      tester,
    ) async {
      const explicit = <CoreShadowLayer>[
        (
          offsetX: 0.0,
          offsetY: 2.0,
          blurRadius: 8.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(
          elevation: .medium,
          boxShadow: explicit,
        ),
      );

      expect(_classes(resolved), isNot(contains(kSurfaceRimLiftMarker)));
      expect(_rootShadow(resolved), endsWith(kSurfaceRimVar));
    });
  });

  group('the marker rule', () {
    test('appends the rim to the elevation composition, last', () {
      final rule = _markerRule();

      // The elevation classes vary `--tw-shadow` only; restating their
      // composition is what lets `hover:shadow-*` keep changing the lift.
      expect(rule, contains('var(--tw-shadow'));
      expect(rule, contains('var(--tw-ring-shadow'));
      expect(rule, contains('var(--tw-ring-offset-shadow'));
      expect(rule, endsWith('$kSurfaceRimVar;}'));
    });

    test('out-ranks the hover class by selector, not by sheet order', () {
      // `hover:shadow-*` is (0,2,0). Tying it would leave the rim's
      // survival on hover to whichever stylesheet lands later.
      final selector = _markerRule().split('{').first;
      final classCount = '.'.allMatches(selector).length;

      expect(classCount, greaterThan(2));
    });

    test('a style that states a rim gives the variable a value', () {
      final recipe = CoreSurfaceRecipe.of(.claymorphism);
      final css = ThemeConfig.defaults().surfaceStyleGeometryBlock(
        .claymorphism,
        recipe.geometry,
        typography: recipe.typography,
      );

      expect(css, contains('--coui-surface-rim:'));
    });
  });
}
