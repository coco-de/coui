// Tests for the CoreListingStyle design-system defaults.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreListingStyle row padding default', () {
    test('rows have no horizontal inset and 12 vertical', () {
      const padding = CoreListingStyle.defaultPadding;
      expect(padding.left, CoreSpace.space0);
      expect(padding.right, CoreSpace.space0);
      expect(padding.top, CoreSpace.space12);
      expect(padding.bottom, CoreSpace.space12);
    });

    test('a rule renders between rows unless the caller says otherwise', () {
      expect(CoreListingStyle.defaultItemBorder, isTrue);
      expect(const CoreListingStyle().itemBorder, isNull);
      expect(
        const CoreListingStyle(itemBorder: false).itemBorder,
        isFalse,
      );
    });

    test('the rule states no colour of its own — Divider owns it', () {
      expect(CoreListingStyle.defaultDividerStyle, const CoreDividerStyle());
    });

    test('column spacing is 12', () {
      expect(CoreListingStyle.defaultColSpacing, CoreSpace.space12);
    });
  });
}
