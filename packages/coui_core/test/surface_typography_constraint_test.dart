import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  const bold = CoreSurfaceTypographyConstraint(
    weightFloor: CoreFontWeight.semiBold,
  );
  const identity = CoreSurfaceTypographyConstraint();
  const scale = CoreTypography.coui;

  group('the floor raises only what is under it', () {
    test('a light role is raised', () {
      expect(scale.bodyMedium.fontWeight, lessThan(CoreFontWeight.semiBold));
      expect(
        bold.apply(scale).bodyMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    test('a role already heavier keeps its own weight', () {
      // The scale's hierarchy has to survive. A floor that flattened
      // everything to one weight would erase the difference between a
      // heading and body text, which is the thing the scale encodes.
      final heavy = scale.titleLarge.fontWeight!;
      expect(heavy, greaterThanOrEqualTo(CoreFontWeight.semiBold));
      expect(bold.apply(scale).titleLarge.fontWeight, heavy);
    });

    test('the hierarchy is compressed, not removed', () {
      final applied = bold.apply(scale);
      // Display keeps its own weight (700); title (600) stays below it.
      expect(
        applied.titleLarge.fontWeight,
        lessThanOrEqualTo(applied.displayLarge.fontWeight!),
      );
    });

    test('a role that states no weight is left stating none', () {
      // A null weight means the role defers. Writing one here would be the
      // style inventing a value the scale deliberately left open.
      expect(bold.weight(null), isNull);
    });
  });

  group('every role is covered', () {
    test('no role escapes the floor', () {
      // The roles live in one place precisely so a transform cannot cover
      // all but one of them. Read through the token list — the same list
      // every reader of the scale walks — so a role that `map` forgets
      // fails here by name.
      final applied = bold.apply(scale);
      expect(CoreTextStyles.values, hasLength(22));
      for (final token in CoreTextStyles.values) {
        final w = token.read(applied).fontWeight;
        if (w == null) continue;
        expect(
          w,
          greaterThanOrEqualTo(CoreFontWeight.semiBold),
          reason: token.name,
        );
      }
    });

    test('the floor reaches the code roles and keeps their line box', () {
      // A code role states its line as a fixed box rather than a
      // multiplier. Raising its weight must not drop that box — the editor
      // line grid would come apart under a heavier preset.
      final applied = bold.apply(scale);
      for (final token in [
        CoreTextStyles.codeXs,
        CoreTextStyles.codeSm,
        CoreTextStyles.codeMd,
      ]) {
        final role = token.read(applied);
        expect(role.fontWeight, CoreFontWeight.semiBold, reason: token.name);
        expect(role.lineHeightPx, CoreLineBox.px21, reason: token.name);
        expect(
          role.fontFamily,
          token.read(scale).fontFamily,
          reason: token.name,
        );
      }
    });

    test('map preserves everything else about a role', () {
      final applied = bold.apply(scale);
      expect(applied.bodyMedium.fontSize, scale.bodyMedium.fontSize);
      expect(applied.bodyMedium.lineHeight, scale.bodyMedium.lineHeight);
    });
  });

  group('identity and equality', () {
    test("identity returns the caller's own scale", () {
      expect(identical(identity.apply(scale), scale), isTrue);
      expect(identity.isIdentity, isTrue);
    });

    test('a floor makes the constraint non-identity', () {
      expect(bold.isIdentity, isFalse);
    });

    test('it is inside value equality', () {
      expect(bold, isNot(equals(identity)));
      expect(bold.hashCode, isNot(equals(identity.hashCode)));
    });

    test('a weight outside the CSS range is rejected', () {
      expect(
        () => CoreSurfaceTypographyConstraint(weightFloor: 950),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the shipped styles', () {
    test('neo-brutalism sets a floor', () {
      expect(
        CoreSurfaceRecipe.of(
          CoreSurfaceStyleId.neoBrutalism,
        ).typography.weightFloor,
        CoreFontWeight.semiBold,
      );
    });

    test('every other style leaves type alone', () {
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.neoBrutalism) continue;
        expect(
          CoreSurfaceRecipe.of(id).typography.isIdentity,
          isTrue,
          reason: '$id',
        );
      }
    });
  });
}
