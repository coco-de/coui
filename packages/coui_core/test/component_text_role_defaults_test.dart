// The text role every component reads by default, written out.
//
// The role table (`CoreTypography.coui`) is pinned by its own test, and each
// component's resolver reads its default through a token. What neither
// states is WHICH role a component names — so a default moved back to the old
// role (a Kbd on mono, a Toast on 500, a Tooltip on labelLarge) would leave
// both of those green. Each line below is one component's decision, with the
// size and weight it resolves to against the CoUI scale so the pin reads as
// the rendered result and not only as a token name.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreTypography _scale = CoreTypography.coui;

/// The role [style] names, resolved against the CoUI scale.
CoreTextStyle _resolved(CoreTextStyle style) => _scale.resolve(style);

void _reads(
  String what,
  CoreTextStyle style,
  CoreTextStyleToken role, {
  required double size,
  required int weight,
}) {
  test('$what reads ${role.name} — $size / $weight', () {
    expect(style.token, role);
    final resolved = _resolved(style);
    expect(resolved.fontSize, size);
    expect(resolved.fontWeight, weight);
  });
}

void main() {
  group('Button label ladder', () {
    final expected = <CoreComponentSize, (CoreTextStyleToken, double)>{
      .xs: (CoreTextStyles.labelSmall, 12),
      .sm: (CoreTextStyles.labelMedium, 13),
      .md: (CoreTextStyles.labelLarge, 14),
      .lg: (CoreTextStyles.labelXl2, 16),
      .xl: (CoreTextStyles.labelXl2, 16),
      .xl2: (CoreTextStyles.labelXl2, 16),
    };
    for (final entry in expected.entries) {
      _reads(
        'Button ${entry.key.name}',
        CoreButtonStyle.defaultsBySize[entry.key]!.labelStyle!,
        entry.value.$1,
        size: entry.value.$2,
        weight: CoreFontWeight.medium,
      );
    }
  });

  group('Badge label ladder', () {
    final expected = <CoreComponentSize, (CoreTextStyleToken, double)>{
      .xs: (CoreTextStyles.labelXs, 11),
      .sm: (CoreTextStyles.labelXs, 11),
      .md: (CoreTextStyles.labelSmall, 12),
      .lg: (CoreTextStyles.labelMedium, 13),
      .xl: (CoreTextStyles.labelLarge, 14),
      .xl2: (CoreTextStyles.labelXl, 15),
    };
    // The size row names the role; a word keeps the role's 500 and a
    // figure takes 600, laid over it, so the pin is the two merged — what
    // the badge draws.
    final formWeights = <CoreBadgeForm, int>{
      .label: CoreFontWeight.medium,
      .count: CoreFontWeight.semiBold,
    };
    for (final entry in expected.entries) {
      for (final form in formWeights.entries) {
        final style = CoreBadgeStyle.defaultsBySize[entry.key]!.labelStyle!
            .merge(CoreBadgeStyle.defaultsByForm[form.key]!.labelStyle);
        test(
          'Badge ${entry.key.name} ${form.key.name} reads '
          '${entry.value.$1.name} — ${entry.value.$2} / ${form.value}',
          () {
            expect(style.token, entry.value.$1);
            expect(_resolved(style).fontSize, entry.value.$2);
            expect(style.fontWeight ?? _resolved(style).fontWeight, form.value);
          },
        );
      }
    }
  });

  group('overlays and captions', () {
    _reads(
      'Kbd key',
      CoreKbdStyle.defaultKeyTextStyle,
      CoreTextStyles.labelXs,
      size: 11,
      weight: CoreFontWeight.medium,
    );
    // Sans: neither the label role nor Kbd names a family, so the key caps
    // read in the body family.
    test('Kbd key names no family of its own', () {
      expect(CoreKbdStyle.defaultKeyTextStyle.fontFamily, isNull);
      expect(_resolved(CoreKbdStyle.defaultKeyTextStyle).fontFamily, isNull);
    });
    _reads(
      'Tooltip label',
      CoreTooltipStyle.defaultLabelStyle,
      CoreTextStyles.labelSmall,
      size: 12,
      weight: CoreFontWeight.medium,
    );
    // A component that states a weight of its own shows it here as a field —
    // Button's variant rows and Chip's size rows state a heavier one over their
    // label role, and so does Toast: the message is semibold over labelLarge.
    test('Toast message states a semibold weight over labelLarge', () {
      expect(
        CoreToastStyle.defaultMessageStyle.token,
        CoreTextStyles.labelLarge,
      );
      expect(_resolved(CoreToastStyle.defaultMessageStyle).fontSize, 14);
      expect(
        CoreToastStyle.defaultMessageStyle.fontWeight,
        CoreFontWeight.semiBold,
      );
    });
    _reads(
      'Dialog title',
      CoreDialogStyle.defaultTitleStyle,
      CoreTextStyles.titleLarge,
      size: 20,
      weight: CoreFontWeight.semiBold,
    );
    _reads(
      'Dialog body',
      CoreDialogStyle.defaultContentStyle,
      CoreTextStyles.bodyMedium,
      size: 14,
      weight: CoreFontWeight.regular,
    );
    _reads(
      'ChatBubble message',
      CoreChatBubbleStyle.defaultTextStyle,
      CoreTextStyles.bodyLarge,
      size: 15,
      weight: CoreFontWeight.regular,
    );
    // The sender name is not the message: it stays a size down, and a weight
    // up from the timestamp so the two lines under and over the bubble read
    // apart. Both name a role (the colour is a separate overlay on it).
    _reads(
      'Chat header',
      CoreChatStyle.defaultHeaderTextStyle,
      CoreTextStyles.labelSmall,
      size: 12,
      weight: CoreFontWeight.medium,
    );
    _reads(
      'Chat footer',
      CoreChatStyle.defaultFooterTextStyle,
      CoreTextStyles.bodyXs,
      size: 12,
      weight: CoreFontWeight.regular,
    );
    test('Chat header and footer are the quieter text colours', () {
      expect(
        CoreChatStyle.defaultHeaderTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreChatStyle.defaultFooterTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      // A role, not a size overlay: the tracking and leading come with it.
      expect(CoreChatStyle.defaultHeaderTextStyle.fontSize, isNull);
      expect(CoreChatStyle.defaultFooterTextStyle.fontSize, isNull);
    });
    _reads(
      'Stat value',
      CoreStatStyle.defaultValueTextStyle,
      CoreTextStyles.headlineLarge,
      size: 32,
      weight: CoreFontWeight.bold,
    );
    // The unit keeps its role's size but sits a weight under the figure:
    // the weight is a component overlay on the role (the scale's `resolve`
    // carries only a colour overlay, so the weight is read off the style).
    test('Stat unit is the titleMedium role (18) at medium 500', () {
      final unit = CoreStatStyle.defaultUnitTextStyle;
      expect(unit.token, CoreTextStyles.titleMedium);
      expect(unit.fontWeight, CoreFontWeight.medium);
      expect(_resolved(unit).fontSize, 18);
      // The role is 600, so the overlay steps the unit a weight under it.
      expect(_scale.titleMedium.fontWeight, CoreFontWeight.semiBold);
    });
    _reads(
      'Stat description',
      CoreStatStyle.defaultDescriptionTextStyle,
      CoreTextStyles.bodySmall,
      size: 13,
      weight: CoreFontWeight.regular,
    );
  });

  group('field helper and error text', () {
    _reads(
      'TextField helper',
      CoreTextFieldStyle.defaultDescriptionStyle,
      CoreTextStyles.bodyXs,
      size: 12,
      weight: CoreFontWeight.regular,
    );
    _reads(
      'TextField error',
      CoreTextFieldStyle.defaultErrorStyle,
      CoreTextStyles.bodyXs,
      size: 12,
      weight: CoreFontWeight.regular,
    );
    _reads(
      'InputOtp error',
      CoreInputOtpStyle.defaultErrorTextStyle,
      CoreTextStyles.bodyXs,
      size: 12,
      weight: CoreFontWeight.regular,
    );
    _reads(
      'ValidatorHint message',
      CoreValidatorHintStyle.defaultMessageTextStyle,
      CoreTextStyles.bodyXs,
      size: 12,
      weight: CoreFontWeight.regular,
    );
  });

  group('Basic title', () {
    test('is labelXl 15 at 600', () {
      expect(CoreBasicStyle.defaultTitleTypography, _scale.labelXl);
      expect(CoreBasicStyle.defaultTitleTypography.fontSize, 15);
    });
  });

  group('NumberTicker value', () {
    // One role for both platforms: the Flutter resolver materialises this
    // default and the Web resolver emits its role class, so the role named
    // here is the one that reaches both.
    _reads(
      'NumberTicker value',
      CoreNumberTickerStyle.defaultTextStyle,
      CoreTextStyles.titleLarge,
      size: 20,
      weight: CoreFontWeight.semiBold,
    );

    test(
      'states a role and nothing else — no size, weight, or ink overlay',
      () {
        // A `fontSize`-only overlay would leave the old role's tracking and
        // line height riding on the new size; the value is the role alone, and
        // its ink is whatever the surrounding foreground is.
        const style = CoreNumberTickerStyle.defaultTextStyle;
        expect(style.fontSize, isNull);
        expect(style.fontWeight, isNull);
        expect(style.lineHeight, isNull);
        expect(style.letterSpacing, isNull);
        expect(style.color, isNull);
      },
    );
  });

  group('Basic text slots', () {
    test('title is the labelXl role set at semiBold 600', () {
      expect(CoreBasicStyle.defaultTitleTypography, _scale.labelXl);
      expect(CoreBasicStyle.defaultTitleFontWeight, CoreFontWeight.semiBold);
      expect(CoreBasicStyle.defaultTitleFontWeight, 600);
    });

    test('subtitle and content read the bodySmall role', () {
      expect(CoreBasicStyle.defaultSubtitleTypography, _scale.bodySmall);
      expect(CoreBasicStyle.defaultContentTypography, _scale.bodySmall);
    });
  });

  group('Tabs and NavigationBar', () {
    final expected = <CoreTabsSize, (CoreTextStyleToken, double)>{
      .sm: (CoreTextStyles.labelMedium, 13),
      .md: (CoreTextStyles.labelLarge, 14),
      .lg: (CoreTextStyles.labelXl, 15),
    };
    for (final entry in expected.entries) {
      final style = CoreTabsStyle.defaultsBySize[entry.key]!.contentTextStyle!;
      _reads(
        'Tabs ${entry.key.name}',
        style,
        entry.value.$1,
        size: entry.value.$2,
        weight: CoreFontWeight.medium,
      );
      // The 400 overlay is gone: the role's weight is the tab's weight.
      test('Tabs ${entry.key.name} states no weight of its own', () {
        expect(style.fontWeight, isNull);
      });
    }
    _reads(
      'NavigationBar section label',
      CoreNavigationBarStyle.sectionLabelRole,
      CoreTextStyles.labelSmall,
      size: 12,
      weight: CoreFontWeight.medium,
    );
  });

  group('Tabs variant rows', () {
    final underline =
        CoreTabsStyle.defaultsByVariant[CoreTabVariant.underline]!;
    final pill = CoreTabsStyle.defaultsByVariant[CoreTabVariant.pill]!;

    test(
      'Tabs underline states no role on its row; the weights are fields',
      () {
        expect(underline.contentTextStyle, isNull);
        expect(underline.activeFontWeight, CoreFontWeight.semiBold);
        expect(underline.inactiveFontWeight, CoreFontWeight.medium);
      },
    );
    test('Tabs pill states no role on its row', () {
      expect(pill.contentTextStyle, isNull);
      expect(pill.activeFontWeight, CoreFontWeight.semiBold);
      expect(pill.inactiveFontWeight, CoreFontWeight.medium);
    });
  });

  group('Table cells', () {
    _reads(
      'Table header',
      CoreTableStyle.defaultHeaderTextStyle,
      CoreTextStyles.labelMedium,
      size: 13,
      weight: CoreFontWeight.medium,
    );
    _reads(
      'Table body and footer',
      CoreTableStyle.defaultCellTextStyle,
      CoreTextStyles.labelLarge,
      size: 14,
      weight: CoreFontWeight.medium,
    );
    test('Table text defaults state no overlay on their role', () {
      expect(CoreTableStyle.defaultHeaderTextStyle.fontWeight, isNull);
      expect(CoreTableStyle.defaultCellTextStyle.fontWeight, isNull);
      expect(CoreTableStyle.defaultHeaderTextStyle.fontSize, isNull);
      expect(CoreTableStyle.defaultCellTextStyle.fontSize, isNull);
    });
    test('Table cell heights follow from padding plus the role line box', () {
      double height(CoreEdgeInsets padding, CoreTextStyle style) {
        final role = _resolved(style);
        return padding.top + role.fontSize! * role.lineHeight! + padding.bottom;
      }

      expect(
        height(
          CoreTableStyle.defaultHeaderPadding,
          CoreTableStyle.defaultHeaderTextStyle,
        ),
        closeTo(38.2, 1e-9),
      );
      expect(
        height(
          CoreTableStyle.defaultCellPadding,
          CoreTableStyle.defaultCellTextStyle,
        ),
        closeTo(43.6, 1e-9),
      );
    });
  });

  group('DefinitionList term and value', () {
    CoreDefinitionListStyle row(CoreDefinitionLayout layout) =>
        CoreDefinitionListStyle.defaultsByLayout[layout]!;

    // A stacked term is a caption one step under its value.
    _reads(
      'stacked term',
      row(.stacked).termTextStyle!,
      CoreTextStyles.labelSmall,
      size: 12,
      weight: CoreFontWeight.medium,
    );
    // Beside the value, term and value are one role and position tells them
    // apart.
    _reads(
      'columns term',
      row(.columns).termTextStyle!,
      CoreTextStyles.labelMedium,
      size: 13,
      weight: CoreFontWeight.medium,
    );
    _reads(
      'inline term',
      row(.inline).termTextStyle!,
      CoreTextStyles.labelMedium,
      size: 13,
      weight: CoreFontWeight.medium,
    );
    for (final layout in CoreDefinitionLayout.values) {
      _reads(
        '${layout.name} value',
        row(layout).descriptionTextStyle!,
        CoreTextStyles.labelMedium,
        size: 13,
        weight: CoreFontWeight.medium,
      );
    }
    _reads(
      'mono value',
      CoreDefinitionListStyle.defaultMonoDescriptionTextStyle,
      CoreTextStyles.codeSm,
      size: 12,
      weight: CoreFontWeight.regular,
    );

    test('mono value sits on a fixed 21px line box', () {
      final resolved = _resolved(
        CoreDefinitionListStyle.defaultMonoDescriptionTextStyle,
      );
      expect(resolved.lineHeightPx, CoreLineBox.px21);
      expect(resolved.fontFamily, CoreFontFamily.mono);
    });

    test('a stacked term line is 16.8 and a column term line 18.2', () {
      double line(CoreTextStyle style) {
        final role = _resolved(style);
        return role.fontSize! * role.lineHeight!;
      }

      expect(line(row(.stacked).termTextStyle!), closeTo(16.8, 1e-9));
      expect(line(row(.columns).termTextStyle!), closeTo(18.2, 1e-9));
    });
  });

  // Meta text that no state layer washes reads the subtle ink. The role and
  // weight are pinned above; this group pins the colour as each mode paints
  // it, so a slot moved back to onSurfaceVariant fails here and not only in
  // a token-name assertion.
  group('Secondary text reads onSurfaceSubtle', () {
    final schemes = <String, CoreColorScheme>{
      'light': CouiColorPresets.source.light(),
      'dark': CouiColorPresets.source.dark(),
      'high-contrast light': CouiColorPresets.source.highContrastLight(),
      'high-contrast dark': CouiColorPresets.source.highContrastDark(),
    };

    void readsSubtle(String what, CoreColor? color) {
      test('$what is onSurfaceSubtle in every mode', () {
        for (final MapEntry(key: mode, value: scheme) in schemes.entries) {
          expect(
            scheme.resolve(color!).argb,
            scheme
                .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
                .argb,
            reason: mode,
          );
          expect(
            scheme.resolve(color).argb,
            isNot(
              scheme
                  .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
                  .argb,
            ),
            reason: '$mode: not the state-washed secondary ink',
          );
        }
      });
    }

    readsSubtle('Menu group title', CoreMenuStyle.defaultLabelTextStyle.color);
    readsSubtle(
      'Basic subtitle',
      CoreBasicStyle.defaultSubtitleTextStyle.color,
    );
    for (final layout in CoreDefinitionLayout.values) {
      readsSubtle(
        'DefinitionList ${layout.name} term',
        CoreDefinitionListStyle.defaultsByLayout[layout]!.termTextStyle!.color,
      );
    }

    test(
      'the Menu group title is the labelSmall role (12 Medium) as it is',
      () {
        const title = CoreMenuStyle.defaultLabelTextStyle;
        expect(title.token, CoreTextStyles.labelSmall);
        // The role states the weight; the slot writes none over it.
        expect(title.fontWeight, isNull);
        expect(_resolved(title).fontSize, 12);
        expect(_resolved(title).fontWeight, CoreFontWeight.medium);
      },
    );
  });
}
