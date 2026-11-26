// Tests for the CoreDefinitionListStyle default table and the fields it
// carries.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The four modes a colour slot is read in.
final List<(String, CoreColorScheme)> _kModes = [
  ('light', CouiColorPresets.source.light()),
  ('dark', CouiColorPresets.source.dark()),
  ('high-contrast light', CouiColorPresets.source.highContrastLight()),
  ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
];

/// `color` as each mode paints it, so a slot assertion reads the pixel the
/// default produces and not only the token it names.
void _expectSameInEveryMode(CoreColor? actual, CoreColorToken expected) {
  for (final (mode, scheme) in _kModes) {
    expect(
      scheme.resolve(actual!).argb,
      scheme.resolve(CoreColor.token(expected)).argb,
      reason: mode,
    );
  }
}

void main() {
  group('defaultsByLayout', () {
    test('has exactly one row per layout', () {
      expect(
        CoreDefinitionListStyle.defaultsByLayout.keys.toSet(),
        CoreDefinitionLayout.values.toSet(),
      );
    });

    test('every row states all four values', () {
      for (final entry in CoreDefinitionListStyle.defaultsByLayout.entries) {
        final row = entry.value;
        expect(row.entrySpacing, isNotNull, reason: entry.key.name);
        expect(row.pairSpacing, isNotNull, reason: entry.key.name);
        expect(row.termTextStyle?.token, isNotNull, reason: entry.key.name);
        expect(
          row.descriptionTextStyle?.token,
          isNotNull,
          reason: entry.key.name,
        );
        expect(
          row.entrySpacing,
          greaterThan(row.pairSpacing!),
          reason:
              '${entry.key.name}: proximity groups a term with its own '
              'value, so the pair gap stays the smaller of the two.',
        );
      }
    });

    test('a row never states the term column width', () {
      for (final row in CoreDefinitionListStyle.defaultsByLayout.values) {
        expect(row.termWidth, isNull);
      }
    });

    test('distances per layout', () {
      CoreDefinitionListStyle row(CoreDefinitionLayout layout) =>
          CoreDefinitionListStyle.defaultsByLayout[layout]!;

      expect(row(.stacked).entrySpacing, CoreSpace.space14);
      expect(row(.stacked).pairSpacing, CoreSpace.space2);
      expect(row(.columns).entrySpacing, CoreSpace.space24);
      expect(row(.columns).pairSpacing, CoreSpace.space8);
      expect(row(.inline).entrySpacing, CoreSpace.space16);
      expect(row(.inline).pairSpacing, CoreSpace.space8);
    });

    test('roles per layout', () {
      CoreDefinitionListStyle row(CoreDefinitionLayout layout) =>
          CoreDefinitionListStyle.defaultsByLayout[layout]!;

      expect(row(.stacked).termTextStyle!.token, CoreTextStyles.labelSmall);
      expect(row(.columns).termTextStyle!.token, CoreTextStyles.labelMedium);
      expect(row(.inline).termTextStyle!.token, CoreTextStyles.labelMedium);
      for (final layout in CoreDefinitionLayout.values) {
        expect(
          row(layout).descriptionTextStyle!.token,
          CoreTextStyles.labelMedium,
          reason: layout.name,
        );
      }
    });

    test('the term is muted and the description is not, on every row', () {
      for (final entry in CoreDefinitionListStyle.defaultsByLayout.entries) {
        expect(
          entry.value.termTextStyle!.color,
          isNot(entry.value.descriptionTextStyle!.color),
          reason: entry.key.name,
        );
      }
    });
  });

  group('colours as each mode paints them', () {
    test('the term is onSurfaceSubtle and the value onSurface per row', () {
      for (final entry in CoreDefinitionListStyle.defaultsByLayout.entries) {
        _expectSameInEveryMode(
          entry.value.termTextStyle!.color,
          CoreColors.onSurfaceSubtle,
        );
        _expectSameInEveryMode(
          entry.value.descriptionTextStyle!.color,
          CoreColors.onSurface,
        );
      }
    });

    test('the mono value keeps the value colour', () {
      _expectSameInEveryMode(
        CoreDefinitionListStyle.defaultMonoDescriptionTextStyle.color,
        CoreColors.onSurface,
      );
    });
  });

  group('defaultMonoDescriptionTextStyle', () {
    test('is the code-sm role', () {
      expect(
        CoreDefinitionListStyle.defaultMonoDescriptionTextStyle.token,
        CoreTextStyles.codeSm,
      );
    });

    test('shares the description colour of every row', () {
      for (final row in CoreDefinitionListStyle.defaultsByLayout.values) {
        expect(
          CoreDefinitionListStyle.defaultMonoDescriptionTextStyle.color,
          row.descriptionTextStyle!.color,
        );
      }
    });
  });

  group('monoDescriptionTextStyle', () {
    const style = CoreDefinitionListStyle(
      monoDescriptionTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
    );

    test('merge layers the nested style and copyWith keeps it', () {
      final merged = style.merge(
        const CoreDefinitionListStyle(
          monoDescriptionTextStyle: CoreTextStyle(fontSize: CoreFontSize.s14),
        ),
      );

      expect(merged.monoDescriptionTextStyle?.fontWeight, CoreFontWeight.bold);
      expect(merged.monoDescriptionTextStyle?.fontSize, CoreFontSize.s14);
      expect(
        style.copyWith(termWidth: 90).monoDescriptionTextStyle,
        style.monoDescriptionTextStyle,
      );
    });

    test('takes part in == and hashCode', () {
      const same = CoreDefinitionListStyle(
        monoDescriptionTextStyle: CoreTextStyle(
          fontWeight: CoreFontWeight.bold,
        ),
      );

      expect(style, same);
      expect(style.hashCode, same.hashCode);
      expect(style, isNot(const CoreDefinitionListStyle()));
    });
  });

  group('termWidth', () {
    const style = CoreDefinitionListStyle(termWidth: 90);

    test('is unset on an empty style', () {
      expect(const CoreDefinitionListStyle().termWidth, isNull);
    });

    test('merge: the patch wins and an absent patch keeps it', () {
      expect(
        style.merge(const CoreDefinitionListStyle(termWidth: 84)).termWidth,
        84,
      );
      expect(style.merge(const CoreDefinitionListStyle()).termWidth, 90);
      expect(
        const CoreDefinitionListStyle().merge(style).termWidth,
        90,
      );
      expect(style.merge(null), same(style));
    });

    test('copyWith replaces it and keeps it when omitted', () {
      expect(style.copyWith(termWidth: 84).termWidth, 84);
      expect(style.copyWith(entrySpacing: 3).termWidth, 90);
    });

    test('takes part in == and hashCode', () {
      const same = CoreDefinitionListStyle(termWidth: 90);
      const other = CoreDefinitionListStyle(termWidth: 84);

      expect(style, same);
      expect(style.hashCode, same.hashCode);
      expect(style, isNot(other));
      expect(style, isNot(const CoreDefinitionListStyle()));
    });
  });
}
