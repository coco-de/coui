// Tests for CoreLinkStyle / CoreLinkTheme / CoreLinkVariant.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRed = CoreColor(0xFFAA0000);
const _kBlue = CoreColor(0xFF0000AA);

void main() {
  group('CoreLinkVariant', () {
    test('has the standard and muted tones, standard by default', () {
      expect(CoreLinkVariant.values, [
        CoreLinkVariant.standard,
        CoreLinkVariant.muted,
      ]);
      expect(CoreLinkVariant.defaultVariant, CoreLinkVariant.standard);
    });
  });

  group('CoreLinkStyle.defaultsByVariant', () {
    test('states a row for every variant', () {
      expect(
        CoreLinkStyle.defaultsByVariant.keys,
        unorderedEquals(CoreLinkVariant.values),
      );
    });

    test('standard reads the link colour, muted the secondary text colour', () {
      const standard = CoreLinkStyle.defaultsByVariant;
      expect(
        standard[CoreLinkVariant.standard]!.color,
        const CoreColor.token(CoreColors.link),
      );
      expect(
        standard[CoreLinkVariant.muted]!.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the underline follows the text tone in every variant', () {
      for (final row in CoreLinkStyle.defaultsByVariant.values) {
        expect(row.underlineColor, isNotNull);
        expect(row.underlineColor, row.color);
      }
    });

    test('a link is not the brand ink', () {
      // `primary` sits too close to body text to read as a link — the reason
      // the slot exists.
      for (final row in CoreLinkStyle.defaultsByVariant.values) {
        expect(row.color, isNot(const CoreColor.token(CoreColors.primary)));
      }
    });
  });

  group('CoreLinkStyle defaults', () {
    test('a standalone link reveals an underline on interaction', () {
      expect(
        CoreLinkStyle.defaultInteractionTextDecoration,
        CoreTextDecoration.underline,
      );
    });

    test('the label is the labelXl role, with no colour overlay', () {
      expect(CoreLinkStyle.defaultLabelStyle.token, CoreTextStyles.labelXl);
      expect(CoreLinkStyle.defaultLabelStyle.color, isNull);
    });

    test('inline text must not press-shrink', () {
      expect(CoreLinkStyle.defaultClickableStyle.pressedScale, 1);
    });
  });

  group('CoreLinkStyle value semantics', () {
    const full = CoreLinkStyle(
      color: _kRed,
      underlineColor: _kBlue,
      interactionTextDecoration: CoreTextDecoration.lineThrough,
      transitionDuration: Duration(milliseconds: 90),
      labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
      clickableStyle: CoreClickableStyle(pressedScale: 0.9),
    );

    test('merge: a null other returns this', () {
      expect(identical(full.merge(null), full), isTrue);
    });

    test('merge: the right side wins field by field', () {
      const base = CoreLinkStyle(color: _kRed, underlineColor: _kRed);
      const patch = CoreLinkStyle(
        color: _kBlue,
        interactionTextDecoration: CoreTextDecoration.none,
      );
      final merged = base.merge(patch);

      expect(merged.color, _kBlue);
      expect(merged.underlineColor, _kRed);
      expect(merged.interactionTextDecoration, CoreTextDecoration.none);
    });

    test('merge: the nested label and clickable slots merge recursively', () {
      const base = CoreLinkStyle(
        labelStyle: CoreTextStyle(fontSize: 14),
        clickableStyle: CoreClickableStyle(pressedScale: 0.9),
      );
      const patch = CoreLinkStyle(
        labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
        clickableStyle: CoreClickableStyle(disabledOpacity: 0.4),
      );
      final merged = base.merge(patch);

      expect(merged.labelStyle?.fontSize, 14);
      expect(merged.labelStyle?.fontWeight, CoreFontWeight.semiBold);
      expect(merged.clickableStyle?.pressedScale, 0.9);
      expect(merged.clickableStyle?.disabledOpacity, 0.4);
    });

    test(
      'copyWith carries every field, including the interaction decoration',
      () {
        final copy = full.copyWith();
        expect(copy, full);

        final changed = full.copyWith(
          interactionTextDecoration: CoreTextDecoration.underline,
        );
        expect(
          changed.interactionTextDecoration,
          CoreTextDecoration.underline,
        );
        expect(changed.color, full.color);
        expect(changed, isNot(full));
      },
    );

    test('== and hashCode read every field', () {
      const base = CoreLinkStyle();
      final variants = <CoreLinkStyle>[
        const CoreLinkStyle(color: _kRed),
        const CoreLinkStyle(underlineColor: _kRed),
        const CoreLinkStyle(
          interactionTextDecoration: CoreTextDecoration.underline,
        ),
        const CoreLinkStyle(transitionDuration: Duration(milliseconds: 10)),
        const CoreLinkStyle(labelStyle: CoreTextStyle(fontSize: 12)),
        const CoreLinkStyle(
          clickableStyle: CoreClickableStyle(pressedScale: 1),
        ),
      ];
      for (final v in variants) {
        expect(v, isNot(base));
        expect(v.hashCode, isNot(base.hashCode));
      }
      expect(
        const CoreLinkStyle(color: _kRed),
        const CoreLinkStyle(color: _kRed),
      );
    });
  });

  group('CoreLinkTheme', () {
    test('holds a style and a per-variant layer', () {
      const theme = CoreLinkTheme(
        style: CoreLinkStyle(color: _kRed),
        variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kBlue)},
      );

      expect(theme.style?.color, _kRed);
      expect(theme.variantStyles?[CoreLinkVariant.muted]?.color, _kBlue);
      expect(theme.variantStyles?[CoreLinkVariant.standard], isNull);
    });

    test('== and hashCode read the per-variant layer', () {
      // A theme that differs only in the variant layer must not compare equal:
      // equality decides whether the tree below rebuilds.
      const a = CoreLinkTheme(
        variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kRed)},
      );
      const b = CoreLinkTheme(
        variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kBlue)},
      );
      const same = CoreLinkTheme(
        variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kRed)},
      );

      expect(a, isNot(b));
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(const CoreLinkTheme()));
    });

    test('equal themes built from different map instances hash alike', () {
      // Built through a function, so the two maps are distinct objects — a
      // `const` literal would canonicalise them into one and prove nothing.
      CoreLinkTheme themeWith(CoreLinkStyle style) =>
          CoreLinkTheme(variantStyles: {CoreLinkVariant.muted: style});
      final x = themeWith(const CoreLinkStyle(color: _kRed));
      final y = themeWith(const CoreLinkStyle(color: _kRed));

      expect(identical(x.variantStyles, y.variantStyles), isFalse);
      expect(x, y);
      expect(x.hashCode, y.hashCode);
    });
  });
}
