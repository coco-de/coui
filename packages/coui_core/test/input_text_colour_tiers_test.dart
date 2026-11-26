// The text a field paints is three tiers, not one.
//
//   value            on-surface          the louder line — what was typed
//   label            on-surface-variant  names the control
//   helper · affix   on-surface-subtle   annotates the value, never carries it
//   disabled label   on-surface-subtle   one tier below the enabled label
//
// `TextField` and `TextArea` state the same tiers from the same tokens, and
// a `FormField` that cannot hand `enabled` to its label states the disabled
// tier in its overlay. This file pins the tokens, that the two inputs agree,
// that every colour slot is reachable through merge / copyWith / == (a slot
// that cannot be overridden is a slot nobody reads), and that the tiers are
// ordered by contrast rather than only by name.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _value = CoreColor.token(CoreColors.onSurface);
const _label = CoreColor.token(CoreColors.onSurfaceVariant);
const _subtle = CoreColor.token(CoreColors.onSurfaceSubtle);

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

int _argb(CoreColorScheme scheme, CoreColorToken token) =>
    scheme.resolve(CoreColor.token(token)).argb | 0xFF000000;

Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': source.light(),
    'dark': source.dark(),
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

void main() {
  group('TextField states the three tiers', () {
    test(
      'the helper, the affix and the disabled label are on-surface-subtle',
      () {
        expect(CoreTextFieldStyle.defaultDescriptionColor, _subtle);
        expect(CoreTextFieldStyle.defaultAffixColor, _subtle);
        expect(CoreTextFieldStyle.defaultLabelDisabledColor, _subtle);
      },
    );

    test('the helper can fall back through the tiers above it', () {
      // The fallback walk only matters for a scheme that leaves the subtle
      // slot unset; the order is the point — the next tier up, then the
      // value ink.
      expect(
        CoreTextFieldStyle.defaultDescriptionColor.fallbacks,
        [CoreColors.onSurfaceVariant, CoreColors.onSurface],
      );
    });

    test(
      'the value stays on-surface, the disabled value disabled-content',
      () {
        for (final entry in CoreTextFieldStyle.defaultsByVariant.entries) {
          expect(entry.value.foregroundColor, _value, reason: '${entry.key}');
          expect(
            entry.value.disabledForegroundColor,
            // A disabled value takes the controls' disabled ink (#5747).
            const CoreColor.token(CoreColors.disabledContent),
            reason: '${entry.key} disabled value',
          );
        }
      },
    );

    test('a disabled label is not the enabled label', () {
      expect(
        CoreTextFieldStyle.defaultLabelDisabledColor,
        isNot(CoreFormLabelStyle.defaultLabelStyle.color),
      );
    });
  });

  group('TextArea states the same tiers from its own slots', () {
    test('the helper, the affix and the disabled label match the field', () {
      expect(
        CoreTextAreaStyle.defaultHelperTextColor,
        CoreTextFieldStyle.defaultDescriptionColor,
      );
      expect(
        CoreTextAreaStyle.defaultAffixColor,
        CoreTextFieldStyle.defaultAffixColor,
      );
      expect(
        CoreTextAreaStyle.defaultLabelDisabledColor,
        CoreTextFieldStyle.defaultLabelDisabledColor,
      );
      expect(
        CoreTextAreaStyle.defaultHelperTextColor.token,
        CoreColors.onSurfaceSubtle,
      );
      expect(
        CoreTextAreaStyle.defaultAffixColor.token,
        CoreColors.onSurfaceSubtle,
      );
      expect(
        CoreTextAreaStyle.defaultLabelDisabledColor.token,
        CoreColors.onSurfaceSubtle,
      );
    });

    test('the helper and the affix are two slots, not one reused', () {
      // Overriding one must not move the other: they are drawn in different
      // places and a caller who recolours the helper has not asked for the
      // icons to change.
      const helperOnly = CoreTextAreaStyle(
        helperTextColor: CoreColor.token(CoreColors.error),
      );
      expect(helperOnly.helperTextColor, isNotNull);
      expect(helperOnly.affixColor, isNull);
      const affixOnly = CoreTextAreaStyle(
        affixColor: CoreColor.token(CoreColors.error),
      );
      expect(affixOnly.affixColor, isNotNull);
      expect(affixOnly.helperTextColor, isNull);
    });

    test(
      'the value stays on-surface, the disabled value disabled-content',
      () {
        for (final entry in CoreTextAreaStyle.defaultsByVariant.entries) {
          expect(entry.value.foregroundColor, _value, reason: '${entry.key}');
          expect(
            entry.value.disabledForegroundColor,
            // A disabled value takes the controls' disabled ink (#5747).
            const CoreColor.token(CoreColors.disabledContent),
            reason: '${entry.key} disabled value',
          );
        }
      },
    );

    test('labelDisabledColor and affixColor merge, copy and compare', () {
      const red = CoreColor.token(CoreColors.error);
      const base = CoreTextAreaStyle(labelDisabledColor: _label);
      const over = CoreTextAreaStyle(labelDisabledColor: red);

      // right-most non-null wins, null keeps the left
      expect(base.merge(over).labelDisabledColor, red);
      expect(base.merge(const CoreTextAreaStyle()).labelDisabledColor, _label);
      const affixBase = CoreTextAreaStyle(affixColor: _label);
      const affixOver = CoreTextAreaStyle(affixColor: red);
      expect(affixBase.merge(affixOver).affixColor, red);
      expect(affixBase.merge(const CoreTextAreaStyle()).affixColor, _label);

      // copyWith replaces only its own slot
      final copy = base.copyWith(labelDisabledColor: red);
      expect(copy.labelDisabledColor, red);
      expect(copy.affixColor, isNull);
      final affixCopy = affixBase.copyWith(affixColor: red);
      expect(affixCopy.affixColor, red);
      expect(affixCopy.labelDisabledColor, isNull);

      // == / hashCode read both
      expect(copy, isNot(base));
      expect(copy.hashCode, isNot(base.hashCode));
      expect(affixCopy, isNot(affixBase));
      expect(affixCopy.hashCode, isNot(affixBase.hashCode));
      expect(base.copyWith(), base);
      expect(base.copyWith().hashCode, base.hashCode);
    });
  });

  group('FormField, which cannot hand `enabled` to its label', () {
    test('the disabled overlay is the subtle tier, not the enabled label', () {
      const overlay = CoreFormFieldStyle.defaultDisabledFormLabelStyle;
      expect(overlay.labelStyle!.color, _subtle);
      // If the overlay were the enabled label's token, a disabled field would
      // be the one place a disabled label looks enabled.
      expect(
        overlay.labelStyle!.color,
        isNot(CoreFormLabelStyle.defaultLabelStyle.color),
      );
      // …and it states a colour only: the role stays the composed label's
      // own rung (see the note on the overlay).
      expect(overlay.labelStyle!.token, isNull);
    });

    test('it is the tier the fields state for their own disabled label', () {
      expect(
        CoreFormFieldStyle.defaultDisabledFormLabelStyle.labelStyle!.color,
        CoreTextFieldStyle.defaultLabelDisabledColor,
      );
    });
  });

  group('the tiers are ordered by contrast on the page', () {
    test('value > label > subtle, in every mode', () {
      _schemes().forEach((mode, scheme) {
        final surface = _argb(scheme, CoreColors.surface);
        final value = _contrast(_argb(scheme, CoreColors.onSurface), surface);
        final label = _contrast(
          _argb(scheme, CoreColors.onSurfaceVariant),
          surface,
        );
        final subtle = _contrast(
          _argb(scheme, CoreColors.onSurfaceSubtle),
          surface,
        );
        expect(value, greaterThan(label), reason: mode);
        expect(label, greaterThan(subtle), reason: mode);
      });
    });

    test('every tier a field paints as text clears 4.5:1 on the page', () {
      // The helper and the disabled label sit on the page, the affix text on
      // the field's own `surface` fill — the same ground.
      _schemes().forEach((mode, scheme) {
        final surface = _argb(scheme, CoreColors.surface);
        for (final token in [
          CoreColors.onSurface,
          CoreColors.onSurfaceVariant,
          CoreColors.onSurfaceSubtle,
        ]) {
          final ratio = _contrast(_argb(scheme, token), surface);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$mode ${token.name} — ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    });

    test('a disabled label steps off the enabled label in every mode', () {
      _schemes().forEach((mode, scheme) {
        final surface = _argb(scheme, CoreColors.surface);
        final enabled = _contrast(
          _argb(scheme, CoreColors.onSurfaceVariant),
          surface,
        );
        final disabled = _contrast(
          _argb(scheme, CoreColors.onSurfaceSubtle),
          surface,
        );
        expect(
          enabled - disabled,
          greaterThanOrEqualTo(1.0),
          reason:
              '$mode — enabled ${enabled.toStringAsFixed(2)}:1, disabled '
              '${disabled.toStringAsFixed(2)}:1; a step under a whole point '
              'reads as the same label',
        );
      });
    });
  });
}
