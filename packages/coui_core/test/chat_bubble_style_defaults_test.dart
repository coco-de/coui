// What a chat bubble's box is made of, written out.
//
// The padding and the corner are two numbers the bubble's silhouette depends
// on, and both are states a component can drift from without anything
// failing: the resolvers read `defaultPadding` / `defaultBorderRadius`
// without naming a literal, so a default edited back to an old pair would
// leave every resolver test that compares against the default green. These
// lines say the values themselves, and the single-line height they add up to.
//
// The neutral bubble's face is the third thing a bubble can drift on without
// anything failing: the resolvers read it from the variant table, so a test
// that compared the painted fill against that same table would pass for any
// slot. The last group names the slot and reads it back through the four
// shipped schemes.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChatBubble tail default', () {
    test(
      'a bubble carries no tail unless asked: the shared default is off',
      () {
        expect(CoreChatBubbleContract.defaultTail, isFalse);
      },
    );
  });

  group('ChatBubble box defaults', () {
    test('padding is 14 across and 10 down', () {
      const padding = CoreChatBubbleStyle.defaultPadding;

      expect(padding.left, CoreSpace.space14);
      expect(padding.right, CoreSpace.space14);
      expect(padding.top, CoreSpace.space10);
      expect(padding.bottom, CoreSpace.space10);
      expect(
        padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space14,
          vertical: CoreSpace.space10,
        ),
      );
    });

    test('every corner is the 14 step', () {
      const radius = CoreChatBubbleStyle.defaultBorderRadius;

      expect(radius.topLeft, CoreRadius.radius14);
      expect(radius.topRight, CoreRadius.radius14);
      expect(radius.bottomLeft, CoreRadius.radius14);
      expect(radius.bottomRight, CoreRadius.radius14);
      expect(radius, const CoreBorderRadius.all(CoreRadius.radius14));
    });

    test('14 is a ladder step, not a role', () {
      // No role states 14, which is why the default names the primitive.
      const roles = [
        CoreRadiusRole.part,
        CoreRadiusRole.control,
        CoreRadiusRole.panel,
        CoreRadiusRole.surface,
        CoreRadiusRole.modal,
      ];

      expect(roles, isNot(contains(CoreRadius.radius14)));
    });

    test('one line of message text is 42.5 tall', () {
      // 10 + (15 x 1.5 = 22.5) + 10. The text role is the one the bubble
      // reads by default, resolved against the CoUI scale.
      final text = CoreTypography.coui.resolve(
        CoreChatBubbleStyle.defaultTextStyle,
      );
      final lineBox = text.fontSize! * text.lineHeight!;
      const padding = CoreChatBubbleStyle.defaultPadding;

      expect(lineBox, 22.5);
      expect(padding.top + lineBox + padding.bottom, 42.5);
    });

    test('density moves both off the 4px rungs along the space ladder', () {
      const padding = CoreChatBubbleStyle.defaultPadding;

      expect(
        [
          CoreDensity.compact.space(padding.top),
          CoreDensity.compact.space(padding.left),
        ],
        [8.0, 12.0],
      );
      expect(
        [
          CoreDensity.spacious.space(padding.top),
          CoreDensity.spacious.space(padding.left),
        ],
        [12.0, 16.0],
      );
    });

    test('density moves the corner along the row band', () {
      const radius = CoreChatBubbleStyle.defaultBorderRadius;

      expect(CoreDensity.standard.radius(radius.topLeft), 14.0);
      expect(CoreDensity.compact.radius(radius.topLeft), 12.0);
      expect(CoreDensity.spacious.radius(radius.topLeft), 16.0);
    });
  });

  group('ChatBubble neutral face', () {
    final neutral =
        CoreChatBubbleStyle.defaultsByVariant[CoreChatBubbleVariant.neutral]!;

    final schemes = <String, ResolvedColorScheme>{
      'Light': CoreThemePresets.lightColorScheme,
      'Dark': CoreThemePresets.darkColorScheme,
      'HCLight': CoreThemePresets.highContrastLightColorScheme,
      'HCDark': CoreThemePresets.highContrastDarkColorScheme,
    };

    test('the neutral face reads the surface-container-high slot', () {
      expect(
        neutral.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        neutral.backgroundColor,
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
    });

    test('the neutral text stays on the onSurface slot', () {
      expect(
        neutral.foregroundColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the other seven variants keep the slots they read', () {
      const expected = {
        CoreChatBubbleVariant.primary: (
          CoreColors.primary,
          CoreColors.onPrimary,
        ),
        CoreChatBubbleVariant.secondary: (
          CoreColors.secondary,
          CoreColors.onSecondary,
        ),
        CoreChatBubbleVariant.accent: (
          CoreColors.tertiary,
          CoreColors.onTertiary,
        ),
        CoreChatBubbleVariant.info: (CoreColors.info, CoreColors.onInfo),
        CoreChatBubbleVariant.success: (
          CoreColors.success,
          CoreColors.onSuccess,
        ),
        CoreChatBubbleVariant.warning: (
          CoreColors.warning,
          CoreColors.onWarning,
        ),
        CoreChatBubbleVariant.error: (CoreColors.error, CoreColors.onError),
      };

      expect(
        CoreChatBubbleStyle.defaultsByVariant.keys,
        unorderedEquals([
          CoreChatBubbleVariant.neutral,
          CoreChatBubbleVariant.plain,
          ...expected.keys,
        ]),
      );
      for (final entry in expected.entries) {
        final style = CoreChatBubbleStyle.defaultsByVariant[entry.key]!;
        expect(
          style.backgroundColor,
          CoreColor.token(entry.value.$1),
          reason: '${entry.key.name} face',
        );
        expect(
          style.foregroundColor,
          CoreColor.token(entry.value.$2),
          reason: '${entry.key.name} text',
        );
      }
    });

    for (final entry in schemes.entries) {
      test('${entry.key}: the face resolves to the high container tone', () {
        final scheme = entry.value;
        final face = scheme.resolve(neutral.backgroundColor);

        expect(face.argb, scheme.surfaceContainerHigh.argb);
        expect(
          face.argb,
          isNot(scheme.surfaceContainer.argb),
          reason: 'the swap is visible: the two tones differ in every mode',
        );
      });

      test('${entry.key}: the text on the new face keeps its 4.5:1', () {
        final scheme = entry.value;

        expect(
          CoreContrast.ratio(
            scheme.resolve(neutral.foregroundColor),
            scheme.resolve(neutral.backgroundColor),
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('ChatBubble plain variant', () {
    final plain =
        CoreChatBubbleStyle.defaultsByVariant[CoreChatBubbleVariant.plain]!;

    test(
      'the plain row states no face, the muted text, no padding, full width',
      () {
        expect(plain.backgroundColor, CoreColor.transparent);
        expect(
          plain.foregroundColor,
          const CoreColor.token(CoreColors.onSurfaceVariant),
        );
        expect(plain.padding, CoreEdgeInsets.zero);
        expect(plain.maxWidthFactor, 1);
      },
    );

    test('the table holds one row per variant, plain included', () {
      expect(
        CoreChatBubbleStyle.defaultsByVariant.keys,
        unorderedEquals(CoreChatBubbleVariant.values),
      );
      expect(CoreChatBubbleVariant.values, hasLength(9));
    });

    test('the default variant stays neutral', () {
      expect(
        CoreChatBubbleVariant.defaultVariant,
        CoreChatBubbleVariant.neutral,
      );
    });

    test('the other eight rows state neither padding nor width', () {
      for (final entry in CoreChatBubbleStyle.defaultsByVariant.entries) {
        if (entry.key == CoreChatBubbleVariant.plain) continue;
        expect(entry.value.padding, isNull, reason: entry.key.name);
        expect(entry.value.maxWidthFactor, isNull, reason: entry.key.name);
      }
    });

    test('the variant style compares padding and width', () {
      const face = CoreColor.token(CoreColors.primary);
      const ink = CoreColor.token(CoreColors.onPrimary);
      const a = CoreChatBubbleVariantStyle(
        backgroundColor: face,
        foregroundColor: ink,
        padding: CoreEdgeInsets.zero,
        maxWidthFactor: 1,
      );
      const same = CoreChatBubbleVariantStyle(
        backgroundColor: face,
        foregroundColor: ink,
        padding: CoreEdgeInsets.zero,
        maxWidthFactor: 1,
      );
      const otherPadding = CoreChatBubbleVariantStyle(
        backgroundColor: face,
        foregroundColor: ink,
        padding: CoreEdgeInsets.all(CoreSpace.space4),
        maxWidthFactor: 1,
      );
      const otherWidth = CoreChatBubbleVariantStyle(
        backgroundColor: face,
        foregroundColor: ink,
        padding: CoreEdgeInsets.zero,
        maxWidthFactor: 0.5,
      );

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(otherPadding));
      expect(a, isNot(otherWidth));
    });

    for (final entry in <String, ResolvedColorScheme>{
      'Light': CoreThemePresets.lightColorScheme,
      'Dark': CoreThemePresets.darkColorScheme,
      'HCLight': CoreThemePresets.highContrastLightColorScheme,
      'HCDark': CoreThemePresets.highContrastDarkColorScheme,
    }.entries) {
      test('${entry.key}: the plain text keeps its 4.5:1 on the surface', () {
        final scheme = entry.value;

        expect(
          CoreContrast.ratio(
            scheme.resolve(plain.foregroundColor),
            scheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
