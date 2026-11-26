import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CorePopupStyle padding presets', () {
    test('a list panel pads 6, a content panel 16', () {
      expect(
        CorePopupStyle.defaultListPadding,
        const CoreEdgeInsets.all(CoreSpace.space6),
      );
      expect(
        CorePopupStyle.defaultContentPadding,
        const CoreEdgeInsets.all(CoreSpace.space16),
      );
    });

    test('the popup itself defaults to the content preset', () {
      expect(
        CorePopupStyle.defaultPadding,
        CorePopupStyle.defaultContentPadding,
      );
    });

    test('the components that hold a list state the list preset', () {
      expect(
        CoreMenuStyle.defaultPopupStyle.padding,
        CorePopupStyle.defaultListPadding,
      );
      expect(
        CoreMenuStyle.defaultHorizontalPopupStyle.padding,
        CorePopupStyle.defaultListPadding,
      );
      expect(
        CoreMenubarStyle.defaultMenuPanelStyle.padding,
        CorePopupStyle.defaultListPadding,
      );
      expect(
        CoreSelectStyle.defaultPopoverStyle.panelStyle?.padding,
        CorePopupStyle.defaultListPadding,
      );
    });
  });
}
