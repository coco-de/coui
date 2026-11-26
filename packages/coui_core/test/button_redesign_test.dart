// Button redesign — the table the two platforms read.
//
// Everything here is a statement about `CoreButtonStyle` and the tokens it
// names. What reaches a pixel is the platforms' job and their own tests'
// (`button_redesign_test.dart` in `coui_flutter` and `coui_web`); this file
// pins the one place both of them read, so the two cannot be right about
// different tables.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CouiSchemeSource _kSource = CouiColorPresets.source;
const CouiPalette _kPalette = CouiColorPresets.palette;

CoreColor _token(CoreColorToken token) => CoreColor.token(token);

double _contrast(CoreColorScheme scheme, CoreColorToken a, CoreColorToken b) =>
    CoreContrast.ratio(
      scheme.resolve(_token(a)),
      scheme.resolve(_token(b)),
    );

void main() {
  group('the variant set', () {
    test('has no link — a destination is a Link, an action is plain', () {
      expect(CoreButtonVariant.values.map((v) => v.name), [
        'primary',
        'secondary',
        'tonal',
        'outline',
        'ghost',
        'plain',
        'destructive',
        'menu',
        'menubar',
        'fixed',
      ]);
    });

    test('every variant has a row, and no row is orphaned', () {
      expect(
        CoreButtonStyle.defaultsByVariant.keys.toSet(),
        CoreButtonVariant.values.toSet(),
      );
    });
  });

  group('secondary is a tonal fill', () {
    final secondary =
        CoreButtonStyle.defaultsByVariant[CoreButtonVariant.secondary]!;

    test('rests on secondaryContainer with onSecondaryContainer ink', () {
      expect(secondary.backgroundColor, _token(CoreColors.secondaryContainer));
      expect(
        secondary.foregroundColor,
        _token(CoreColors.onSecondaryContainer),
      );
    });

    test('answers hover and press with a wash, not a swapped fill', () {
      // A variant states a swap or a wash and never both: a wash over an
      // already-swapped fill would darken twice.
      expect(secondary.hoverBackgroundColor, secondary.backgroundColor);
      expect(secondary.pressedBackgroundColor, isNull);
      expect(secondary.stateLayer, CoreStateLayer.subtle);
      expect(secondary.stateLayer!.hover, CoreOpacity.hover);
      expect(secondary.stateLayer!.pressed, CoreOpacity.pressed);
    });

    test('is tonal in every mode: ink clears 4.5:1 on the fill', () {
      for (final (name, scheme) in [
        ('light', _kSource.light()),
        ('dark', _kSource.dark()),
        ('high-contrast light', _kSource.highContrastLight()),
        ('high-contrast dark', _kSource.highContrastDark()),
      ]) {
        expect(
          _contrast(
            scheme,
            CoreColors.onSecondaryContainer,
            CoreColors.secondaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
          reason: name,
        );
      }
    });
  });

  group('tonal is secondary with the brand container pair', () {
    final tonal = CoreButtonStyle.defaultsByVariant[CoreButtonVariant.tonal]!;
    final secondary =
        CoreButtonStyle.defaultsByVariant[CoreButtonVariant.secondary]!;

    test('rests on primaryContainer with onPrimaryContainer ink', () {
      expect(tonal.backgroundColor, _token(CoreColors.primaryContainer));
      expect(tonal.foregroundColor, _token(CoreColors.onPrimaryContainer));
    });

    test('shares every state rule with secondary', () {
      expect(tonal.hoverBackgroundColor, tonal.backgroundColor);
      expect(tonal.pressedBackgroundColor, isNull);
      expect(tonal.stateLayer, secondary.stateLayer);
      expect(tonal.labelStyle, secondary.labelStyle);
      expect(tonal.disabledBackgroundColor, secondary.disabledBackgroundColor);
      expect(tonal.disabledForegroundColor, secondary.disabledForegroundColor);
      expect(tonal.borderColor, isNull);
      expect(tonal.borderWidth, secondary.borderWidth);
    });

    test('ink clears 4.5:1 on the fill in every mode', () {
      for (final (name, scheme) in [
        ('light', _kSource.light()),
        ('dark', _kSource.dark()),
        ('high-contrast light', _kSource.highContrastLight()),
        ('high-contrast dark', _kSource.highContrastDark()),
      ]) {
        expect(
          _contrast(
            scheme,
            CoreColors.onPrimaryContainer,
            CoreColors.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
          reason: name,
        );
      }
    });
  });

  group('destructive is tinted at rest and filled under the pointer', () {
    final destructive =
        CoreButtonStyle.defaultsByVariant[CoreButtonVariant.destructive]!;

    test('errorContainer at rest, error on hover, errorPressed on press', () {
      expect(destructive.backgroundColor, _token(CoreColors.errorContainer));
      expect(destructive.hoverBackgroundColor, _token(CoreColors.error));
      expect(
        destructive.pressedBackgroundColor,
        _token(CoreColors.errorPressed),
      );
    });

    test('the label is onErrorContainer at rest and onError once filled', () {
      expect(destructive.foregroundColor, _token(CoreColors.onErrorContainer));
      expect(destructive.hoverForegroundColor, _token(CoreColors.onError));
      expect(destructive.pressedForegroundColor, _token(CoreColors.onError));
    });

    test('draws no stroke in any state, disabled included', () {
      expect(destructive.borderWidth, 0);
      expect(destructive.borderColor, isNull);
      expect(destructive.hoverBorderColor, isNull);
      expect(destructive.pressedBorderColor, isNull);
      expect(destructive.disabledBorderColor, isNull);
    });

    test('disabled is the disabled container', () {
      expect(
        destructive.disabledBackgroundColor,
        _token(CoreColors.disabledContainer),
      );
    });

    test(
      'states no state layer — its hover is a colour, not a heavier one',
      () {
        expect(destructive.stateLayer, isNull);
      },
    );
  });

  group('error-pressed', () {
    test('light is error 800 — one step past the 700 hover fill', () {
      expect(_kSource.light().errorPressed!.argb, _kPalette.error.s800.argb);
      expect(
        _kSource.light().errorPressed!.argb,
        isNot(_kSource.light().errorStrong!.argb),
        reason: 'a press that cannot be told from a hover is a missing state',
      );
    });

    test('the other three modes are where they were', () {
      expect(_kSource.dark().errorPressed!.argb, _kPalette.error.s300.argb);
      expect(
        _kSource.highContrastLight().errorPressed!.argb,
        _kPalette.error.s700.argb,
      );
      expect(
        _kSource.highContrastDark().errorPressed!.argb,
        _kPalette.error.s300.argb,
      );
    });

    test('white ink clears 4.5:1 on every destructive fill, in four modes', () {
      for (final (name, scheme) in [
        ('light', _kSource.light()),
        ('dark', _kSource.dark()),
        ('high-contrast light', _kSource.highContrastLight()),
        ('high-contrast dark', _kSource.highContrastDark()),
      ]) {
        for (final fill in [
          CoreColors.error,
          CoreColors.errorStrong,
          CoreColors.errorPressed,
        ]) {
          expect(
            _contrast(scheme, CoreColors.onError, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$name onError on ${fill.name}',
          );
        }
      }
    });
  });

  group('a disabled label is one ink', () {
    test('every variant states disabledContent', () {
      for (final entry in CoreButtonStyle.defaultsByVariant.entries) {
        expect(
          entry.value.disabledForegroundColor,
          _token(CoreColors.disabledContent),
          reason: entry.key.name,
        );
      }
    });
  });

  group('the xs row', () {
    test('sets its label in the 12px role, and still fits 24', () {
      final xs = CoreButtonStyle.defaultsBySize[CoreComponentSize.xs]!;
      // Read the role's size back rather than naming the role: the role
      // that carries 12px is the typography scale's to decide.
      final typography = xs.labelStyle!.token!.read(CoreTypography.coui);
      expect(typography.fontSize, CoreFontSize.s12);
      expect(xs.height, CoreControlSize.heightXs);

      // The label's line box plus the row's block padding.
      final content = typography.fontSize! * typography.lineHeight!;
      final blockPadding = xs.padding!.top + xs.padding!.bottom;
      expect(content + blockPadding, lessThanOrEqualTo(xs.height!));
    });

    test('no other row changed its label role', () {
      final roles = {
        for (final e in CoreButtonStyle.defaultsBySize.entries)
          e.key: e.value.labelStyle!.token,
      };
      expect(roles[CoreComponentSize.sm], CoreTextStyles.labelMedium);
      expect(roles[CoreComponentSize.md], CoreTextStyles.labelLarge);
      expect(roles[CoreComponentSize.lg], CoreTextStyles.labelXl2);
      expect(roles[CoreComponentSize.xl], CoreTextStyles.labelXl2);
      expect(roles[CoreComponentSize.xl2], CoreTextStyles.labelXl2);
    });
  });

  group('focus', () {
    test('only the two rows that opt in fold it into hover', () {
      final folds = {
        for (final e in CoreButtonStyle.defaultsByVariant.entries)
          if (e.value.useFocusedAsHover) e.key,
      };
      expect(folds, {CoreButtonVariant.menu, CoreButtonVariant.menubar});
    });
  });

  group('the picker error trigger default', () {
    test('DatePicker and TimePicker state the same error look', () {
      expect(
        CoreDatePickerStyle.defaultErrorTriggerStyle,
        CoreTimePickerStyle.defaultErrorTriggerStyle,
      );
    });

    test('is an error edge and an error focus ring — and nothing else', () {
      // Exact equality: a text field's error look changes the edge and the
      // ring, so a field added here (a label colour, a fill, a hover wash)
      // is a statement the outline row was meant to keep making.
      expect(
        CoreDatePickerStyle.defaultErrorTriggerStyle,
        const CoreButtonStyle(
          borderColor: CoreColor.token(CoreColors.error),
          hoverBorderColor: CoreColor.token(CoreColors.error),
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderColor: CoreColor.token(CoreColors.error),
          ),
        ),
      );
    });

    test('leaves the label, the fill and the wash to the outline row', () {
      const style = CoreDatePickerStyle.defaultErrorTriggerStyle;
      expect(style.labelStyle, isNull);
      expect(style.backgroundColor, isNull);
      expect(style.hoverBackgroundColor, isNull);
      expect(style.foregroundColor, isNull);
    });

    test('the ring colour is the one a text field error uses', () {
      expect(
        CoreDatePickerStyle
            .defaultErrorTriggerStyle
            .focusOutlineStyle!
            .borderColor,
        CoreTextFieldStyle.defaultErrorVariant.focusRingColor,
      );
      expect(
        CoreDatePickerStyle.defaultErrorTriggerStyle.borderColor,
        CoreTextFieldStyle.defaultErrorVariant.borderColor,
      );
    });

    test('errorTriggerStyle takes part in merge, copyWith and equality', () {
      const a = CoreDatePickerStyle(
        errorTriggerStyle: CoreButtonStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      );
      const b = CoreDatePickerStyle(
        errorTriggerStyle: CoreButtonStyle(
          hoverBorderColor: CoreColor.token(CoreColors.tertiary),
        ),
      );

      final merged = a.merge(b).errorTriggerStyle!;
      expect(merged.borderColor, _token(CoreColors.primary));
      expect(merged.hoverBorderColor, _token(CoreColors.tertiary));

      expect(a.copyWith(errorTriggerStyle: b.errorTriggerStyle), b);
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);

      const timeA = CoreTimePickerStyle(
        errorTriggerStyle: CoreButtonStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      );
      const timeB = CoreTimePickerStyle(
        errorTriggerStyle: CoreButtonStyle(
          hoverBorderColor: CoreColor.token(CoreColors.tertiary),
        ),
      );
      final timeMerged = timeA.merge(timeB).errorTriggerStyle!;
      expect(timeMerged.borderColor, _token(CoreColors.primary));
      expect(timeMerged.hoverBorderColor, _token(CoreColors.tertiary));
      expect(timeA.copyWith(errorTriggerStyle: timeB.errorTriggerStyle), timeB);
      expect(timeA == timeB, isFalse);
      expect(timeA.hashCode == timeB.hashCode, isFalse);
    });
  });
}
