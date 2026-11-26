import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disabled search icon honors its nested color override', (
    tester,
  ) async {
    await tester.pumpWidget(
      const material.MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: ItemPicker(items: ['A'], enabled: false),
        ),
      ),
    );
    final context = tester.element(find.byType(ItemPicker));
    final defaultStyle = resolveItemPicker(context, enabled: false);
    final customStyle = resolveItemPicker(
      context,
      enabled: false,
      itemPickerStyle: const CoreItemPickerStyle(
        searchIconStyle: CoreIconStyle(color: CoreColor(0xFF00FF00)),
      ),
    );

    expect(
      defaultStyle.searchIconStyle.color,
      CoreItemPickerStyle.defaultDisabledSearchIconColor,
    );
    expect(customStyle.searchIconStyle.color, const CoreColor(0xFF00FF00));
  });

  testWidgets('a disabled picker draws its option text and check in the '
      'disabled foreground, an enabled one does not', (tester) async {
    await tester.pumpWidget(
      const material.MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: ItemPicker(items: ['A'], enabled: false),
        ),
      ),
    );
    final context = tester.element(find.byType(ItemPicker));
    final enabled = resolveItemPicker(context);
    final disabled = resolveItemPicker(context, enabled: false);
    final custom = resolveItemPicker(
      context,
      enabled: false,
      itemPickerStyle: const CoreItemPickerStyle(
        disabledForegroundColor: CoreColor(0xFF00FF00),
      ),
    );
    final disabledTone = Theme.of(context).colorScheme
        .resolve(CoreItemPickerStyle.defaultDisabledForegroundColor)
        .toValue();

    expect(disabled.optionTextStyle.color, disabledTone);
    expect(disabled.optionSelectedTextStyle.color, disabledTone);
    expect(
      disabled.checkIconStyle.color,
      CoreItemPickerStyle.defaultDisabledForegroundColor,
    );
    expect(enabled.optionTextStyle.color, isNot(disabledTone));
    expect(enabled.checkIconStyle.color, CoreItemPickerStyle.defaultCheckColor);
    expect(custom.checkIconStyle.color, const CoreColor(0xFF00FF00));
    expect(custom.optionTextStyle.color, const Color(0xFF00FF00));
  });

  testWidgets('a disabled picker draws its title and empty-state line in '
      'the disabled foreground, an enabled one keeps their own', (
    tester,
  ) async {
    await tester.pumpWidget(
      const material.MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: ItemPicker(items: ['A'], enabled: false),
        ),
      ),
    );
    final context = tester.element(find.byType(ItemPicker));
    final scheme = Theme.of(context).colorScheme;
    final enabled = resolveItemPicker(context);
    final disabled = resolveItemPicker(context, enabled: false);
    final custom = resolveItemPicker(
      context,
      enabled: false,
      itemPickerStyle: const CoreItemPickerStyle(
        disabledForegroundColor: CoreColor(0xFF00FF00),
      ),
    );
    final disabledTone = scheme
        .resolve(CoreItemPickerStyle.defaultDisabledForegroundColor)
        .toValue();

    expect(disabled.titleTextStyle.color, disabledTone);
    expect(disabled.emptyTextStyle.color, disabledTone);
    expect(
      enabled.titleTextStyle.color,
      scheme
          .resolve(CoreItemPickerStyle.defaultTitleTextStyle.color!)
          .toValue(),
    );
    expect(
      enabled.emptyTextStyle.color,
      scheme
          .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
          .toValue(),
    );
    expect(custom.titleTextStyle.color, const Color(0xFF00FF00));
    expect(custom.emptyTextStyle.color, const Color(0xFF00FF00));
  });
}
