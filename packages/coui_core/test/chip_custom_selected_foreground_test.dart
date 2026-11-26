// A selected custom chip at high emphasis is filled with the caller's seed,
// and its label is the seed's own on-colour (designer decision 22 of #5319,
// 2026-10-08) — not a fixed white. These read the label back from the Core
// function both resolvers call, and then measure it on the fill it sits on:
// a label that is the "right token" and still cannot be read would pass a
// name check and fail the person looking at it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreColor _labelFor(CoreColor fill) =>
    CoreChipStyle.defaultCustomSelectedForegroundColorFor(fill);

/// CoUI's own four modes — the look this product ships.
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
  group('a paired seed takes its own on-colour', () {
    test('each role answers with its on-token', () {
      // A list of records, not a map: a const map key may not override
      // `==`, and `CoreColorToken` compares by name.
      const pairs = [
        (CoreColors.primary, CoreColors.onPrimary),
        (CoreColors.secondary, CoreColors.onSecondary),
        (CoreColors.tertiary, CoreColors.onTertiary),
        (CoreColors.accent, CoreColors.onAccent),
        (CoreColors.error, CoreColors.onError),
        (CoreColors.success, CoreColors.onSuccess),
        (CoreColors.warning, CoreColors.onWarning),
        (CoreColors.info, CoreColors.onInfo),
        (CoreColors.successContainer, CoreColors.onSuccessContainer),
        (CoreColors.surfaceContainerHigh, CoreColors.onSurface),
        (CoreColors.inverseSurface, CoreColors.inverseOnSurface),
      ];

      for (final (fill, on) in pairs) {
        expect(
          _labelFor(CoreColor.token(fill)),
          CoreColor.token(on),
          reason: '${fill.name} did not answer with ${on.name}',
        );
      }
    });

    test('the label is readable on the role fills in every mode', () {
      // The point of the decision: a fixed white measured 1.25:1 on the
      // dark-mode `tertiary` and 1.09:1 in high-contrast dark. A chip label
      // is body-size text, so it is held to 4.5:1.
      const roles = [
        CoreColors.primary,
        CoreColors.secondary,
        CoreColors.tertiary,
        CoreColors.accent,
        CoreColors.error,
        CoreColors.success,
        CoreColors.warning,
        CoreColors.info,
      ];

      for (final MapEntry(key: mode, value: scheme) in _schemes().entries) {
        for (final role in roles) {
          final fill = scheme.resolve(CoreColor.token(role));
          final label = scheme.resolve(_labelFor(CoreColor.token(role)));
          final ratio = CoreContrast.ratio(label, fill);

          expect(
            CoreContrastLevel.aaNormalText.isMetBy(ratio),
            isTrue,
            reason:
                '$mode / ${role.name}: label measures '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
      }
    });

    test('the seed modifiers do not reach the label', () {
      // A translucent seed is still that role's fill; the label is the
      // role's on-colour at full strength, not a ghost of it.
      expect(
        _labelFor(const CoreColor.token(CoreColors.tertiary, opacity: 0.5)),
        const CoreColor.token(CoreColors.onTertiary),
      );
    });

    test('a colour read off a resolved scheme keeps its pairing', () {
      // `ResolvedColorScheme` hands back tagged colours — resolved channels
      // plus the token they came from. The token is what pairs.
      final tagged = CouiColorPresets.source.light().resolved(.light).tertiary;

      expect(tagged.token, CoreColors.tertiary);
      expect(_labelFor(tagged), const CoreColor.token(CoreColors.onTertiary));
    });
  });

  group('a raw seed is measured', () {
    test('a dark seed carries white and a light seed carries black', () {
      expect(
        _labelFor(const CoreColor(0xFF3366FF)),
        CoreChipStyle.defaultCustomSelectedForegroundColor,
      );
      expect(
        _labelFor(const CoreColor(0xFFFFE066)),
        CoreChipStyle.defaultCustomSelectedDarkForegroundColor,
      );
    });

    test('the chosen end is never the less readable one', () {
      const white = CoreChipStyle.defaultCustomSelectedForegroundColor;
      const black = CoreChipStyle.defaultCustomSelectedDarkForegroundColor;

      for (final seed in const [
        CoreColor(0xFF000000),
        CoreColor(0xFF1A2950),
        CoreColor(0xFF3366FF),
        CoreColor(0xFF808080),
        CoreColor(0xFF22C55E),
        CoreColor(0xFFFFE066),
        CoreColor(0xFFF1F5FE),
        CoreColor(0xFFFFFFFF),
      ]) {
        final chosen = _labelFor(seed);
        final other = chosen == white ? black : white;

        expect(
          CoreContrast.ratio(chosen, seed),
          greaterThanOrEqualTo(CoreContrast.ratio(other, seed)),
          reason: 'seed ${seed.argb.toRadixString(16)}',
        );
      }
    });

    test('the seed alpha is left out of the measurement', () {
      // A half-transparent yellow is still a yellow: the label is read
      // against its hue.
      expect(
        _labelFor(const CoreColor(0x80FFE066)),
        CoreChipStyle.defaultCustomSelectedDarkForegroundColor,
      );
    });
  });

  group('a token the scheme does not pair', () {
    test('keeps the light end, and the pairing says why', () {
      // Ink and stroke tones are drawn on a fill, not under a label. The
      // scheme states no on-colour for them, and a token has no channels to
      // measure until a scheme resolves it — which the Web never does at
      // build time.
      for (final token in const [
        CoreColors.outline,
        CoreColors.onPrimary,
        CoreColors.focusRing,
      ]) {
        expect(CoreColors.onColorOf(token), isNull, reason: token.name);
        expect(
          _labelFor(CoreColor.token(token)),
          CoreChipStyle.defaultCustomSelectedForegroundColor,
          reason: token.name,
        );
      }
    });
  });

  group('a caller override still wins', () {
    test('the field reaches past the derivation', () {
      // The derived value is the fallback; the field is the override slot
      // both resolvers put in front of it.
      const override = CoreColor(0xFFFF00FF);
      const style = CoreChipStyle(customSelectedForegroundColor: override);

      expect(style.customSelectedForegroundColor, override);
    });
  });
}
