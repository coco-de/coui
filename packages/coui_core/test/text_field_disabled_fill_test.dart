// A disabled TextField says so in its fill too, not only in its text and
// border.
//
// #3469 moved the disabled foreground and border onto dedicated tokens and
// left the fill on `surface` — the same fill the enabled field uses. So the
// field's largest area, the one the eye reads first, was the one part of
// "disabled" that said nothing. The comment explaining why the other two
// moved sits directly below the line that did not.
//
// Worth its own test rather than a look because the gap is invisible in a
// screenshot of a single state: a disabled field on a `surface` page is
// exactly a normal field, and it takes putting the two states side by side
// to see that nothing changed.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

// `plain` is the exception: it has no box at rest, and the host that
// composes it draws the disabled box. A disabled fill here painted a second,
// narrower face inside the host's disabled one (an ItemPicker search row on
// the canvas), so plain stays chromeless and says "disabled" in its text.
final List<CoreTextFieldVariant> _boxed = [
  for (final v in CoreTextFieldVariant.values)
    if (v != CoreTextFieldVariant.plain) v,
];

CoreTextFieldVariantStyle _row(CoreTextFieldVariant variant) =>
    CoreTextFieldStyle.defaultsByVariant[variant]!;

void main() {
  group('every boxed TextField variant states a disabled fill of its own', () {
    for (final variant in _boxed) {
      test('${variant.name} — the fill is the disabled token', () {
        expect(
          _row(variant).disabledBackgroundColor,
          // The filled variant's disabled fill is the lowest container
          // tone (#5747); every other variant takes `disabledContainer`.
          CoreColor.token(
            variant == CoreTextFieldVariant.filled
                ? CoreColors.surfaceContainerLow
                : CoreColors.disabledContainer,
          ),
          reason:
              'the canvas states color/disabled-container here; a fill that '
              'equals the enabled one leaves the state to the border alone',
        );
      });

      test('${variant.name} — and it differs from the enabled fill', () {
        final row = _row(variant);

        // Asserted separately from the token identity above. If
        // `disabledContainer` and the enabled fill ever resolved to the
        // same value the assertion above would still pass while the two
        // states rendered identically — which is the failure this file
        // exists for, in a different disguise.
        expect(row.disabledBackgroundColor, isNot(row.backgroundColor));
      });

      test('${variant.name} — all three disabled slots carry tokens', () {
        final row = _row(variant);

        // The state has to survive a colour-forcing accessibility mode,
        // which substitutes colours and leaves alpha alone. Three tokens
        // survive that; an opacity over the enabled palette does not.
        expect(row.disabledBackgroundColor.token, isNotNull);
        expect(row.disabledForegroundColor.token, isNotNull);
        expect(row.disabledBorderColor.token, isNotNull);
      });
    }
  });

  group('plain stays chromeless when disabled', () {
    final row = _row(CoreTextFieldVariant.plain);

    test('no disabled fill or border — the host draws the disabled box', () {
      expect(row.disabledBackgroundColor, CoreColor.transparent);
      expect(row.disabledBorderColor, CoreColor.transparent);
      expect(row.disabledBackgroundColor, row.backgroundColor);
      expect(row.disabledBorderColor, row.borderColor);
    });

    test('the text carries the state instead', () {
      expect(
        row.disabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(row.disabledForegroundColor, isNot(row.foregroundColor));
    });
  });

  group('disabled outranks error — the disabled trio is variant-invariant', () {
    // Both resolvers gate the error row on `enabled` (`disabled > error`,
    // Carbon's `!disabled && invalid`), so a disabled field never reads
    // the error row at all. The rows still agree on the disabled trio, so
    // that a row picked any other way — a Theme `variantStyles[error]`
    // entry, a caller that resolves the error row directly — paints the
    // same disabled field rather than an error-toned one.
    final normal = _row(CoreTextFieldVariant.defaultVariant);
    final error = _row(CoreTextFieldVariant.error);

    test('disabledBackgroundColor is the same token on error as on normal', () {
      expect(error.disabledBackgroundColor, normal.disabledBackgroundColor);
    });

    test('disabledForegroundColor is the same token on error as on normal', () {
      expect(error.disabledForegroundColor, normal.disabledForegroundColor);
    });

    test('disabledBorderColor is the same token on error as on normal — '
        'the border does not stay error-red once disabled', () {
      expect(error.disabledBorderColor, normal.disabledBorderColor);
      expect(
        error.disabledBorderColor,
        isNot(error.borderColor),
        reason:
            "a stale error field's disabled border must not equal its "
            'own error-tone resting border, or the two states would '
            'paint identically',
      );
    });
  });
}
