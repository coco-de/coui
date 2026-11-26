import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The recipe's two halves reach components by different routes, and the
/// parity matrix prunes on that distinction — so the distinction has to
/// hold as a fact about the recipe, not as a belief written next to it.
void main() {
  final recipes = {
    for (final id in CoreSurfaceStyleId.values) id: CoreSurfaceRecipe.of(id),
  };

  group('statesTokenConstraint — the half that reaches every component', () {
    test('the baseline bends nothing', () {
      expect(
        recipes[CoreSurfaceStyleId.defaultId]!.statesTokenConstraint,
        isFalse,
      );
    });

    test('a constraint on any one axis is enough', () {
      const base = CoreSurfaceRecipe(id: .defaultStyle, a11y: .defaultSurface);
      expect(base.statesTokenConstraint, isFalse);
      expect(
        base
            .copyWith(
              typography: const CoreSurfaceTypographyConstraint(
                weightFloor: CoreFontWeight.semiBold,
              ),
            )
            .statesTokenConstraint,
        isTrue,
      );
      expect(
        base
            .copyWith(
              geometry: const CoreSurfaceGeometryConstraint(radiusCap: 0),
            )
            .statesTokenConstraint,
        isTrue,
      );
      expect(
        base
            .copyWith(
              colorConstraint: const CoreSurfaceColorConstraint(
                outlineEmphasis: 1,
              ),
            )
            .statesTokenConstraint,
        isTrue,
      );
    });

    test('a material alone is not a token constraint', () {
      // Glass reaches only what carries the marker. If this ever turns
      // true the matrix stops pruning glass for unmarked components, which
      // is safe but no longer what the recipe says.
      final materialOnly = recipes.values.where(
        (r) => r.statesMaterial && !r.statesTokenConstraint,
      );
      for (final recipe in materialOnly) {
        expect(recipe.statesTokenConstraint, isFalse, reason: recipe.id.name);
      }
    });
  });

  group('statesNothing is exactly the conjunction of the two halves', () {
    for (final entry in recipes.entries) {
      test(entry.key.name, () {
        final recipe = entry.value;
        expect(
          recipe.statesNothing,
          !recipe.statesTokenConstraint && !recipe.statesMaterial,
        );
      });
    }
  });
}
