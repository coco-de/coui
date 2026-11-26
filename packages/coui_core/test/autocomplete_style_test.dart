import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreAutocompleteStyle defaults — the ItemPicker option row', () {
    test('an option row is inset 8 on every side with the control radius', () {
      expect(
        CoreAutocompleteStyle.defaultOptionPadding,
        const CoreEdgeInsets.all(CoreSpace.space8),
      );
      expect(
        CoreAutocompleteStyle.defaultOptionBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.control),
      );
    });

    test('the label and hover text read the bodyMedium role', () {
      expect(
        CoreAutocompleteStyle.defaultDropdownTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
      expect(
        CoreAutocompleteStyle.defaultOptionHoverTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
    });

    test('an accented row keeps the non-matching text on-surface-variant', () {
      expect(
        CoreAutocompleteStyle.defaultOptionHoverTextStyle.color,
        CoreAutocompleteStyle.defaultDropdownTextStyle.color,
      );
      expect(
        CoreAutocompleteStyle.defaultOptionHoverTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the panel sits 4 off the field and holds the list inset', () {
      final popover = CoreAutocompleteStyle.defaultPopoverStyle;
      expect(popover.placementOffset, CoreSpace.space4);
      expect(popover.panelStyle?.padding, CorePopupStyle.defaultListPadding);
      expect(popover.triggerSizing, CorePopoverTriggerSizing.expand);
    });
  });

  group('match emphasis', () {
    test('non-match text is Regular onSurfaceVariant', () {
      final base = CoreAutocompleteStyle.defaultDropdownTextStyle;
      expect(base.color, const CoreColor.token(CoreColors.onSurfaceVariant));
      expect(base.fontWeight, isNull);
    });

    test('match text is SemiBold onSurface', () {
      final match = CoreAutocompleteStyle.defaultMatchTextStyle;
      expect(match.token, CoreTextStyles.bodyMedium);
      expect(match.fontWeight, CoreFontWeight.semiBold);
      expect(match.color, const CoreColor.token(CoreColors.onSurface));
    });

    test('matchTextStyle takes part in merge / copyWith / ==', () {
      const patch = CoreTextStyle(fontWeight: CoreFontWeight.semiBold);
      final merged = const CoreAutocompleteStyle().merge(
        const CoreAutocompleteStyle(matchTextStyle: patch),
      );
      expect(merged.matchTextStyle, patch);
      expect(
        const CoreAutocompleteStyle().copyWith(matchTextStyle: patch),
        merged,
      );
      expect(merged, isNot(const CoreAutocompleteStyle()));
    });
  });

  group('CoreAutocompleteMatch', () {
    test('match at the start', () {
      final m = CoreAutocompleteMatch.of('Apple', 'ap');
      expect((m.before, m.match, m.after), ('', 'Ap', 'ple'));
    });

    test('match in the middle', () {
      final m = CoreAutocompleteMatch.of('Grape', 'ap');
      expect((m.before, m.match, m.after), ('Gr', 'ap', 'e'));
    });

    test('match at the end', () {
      final m = CoreAutocompleteMatch.of('Wrap', 'AP');
      expect((m.before, m.match, m.after), ('Wr', 'ap', ''));
    });

    test('the first occurrence wins and the query is trimmed', () {
      final m = CoreAutocompleteMatch.of('banana', ' an ');
      expect((m.before, m.match, m.after), ('b', 'an', 'ana'));
    });

    test('an empty or absent query leaves the label unemphasised', () {
      for (final q in ['', '  ', 'zz']) {
        final m = CoreAutocompleteMatch.of('Apple', q);
        expect(m.hasMatch, isFalse);
        expect(m.before, 'Apple');
      }
    });
  });
}
