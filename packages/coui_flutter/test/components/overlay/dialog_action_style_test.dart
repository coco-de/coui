import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final layout in CoreDialogActionsLayout.values) {
    testWidgets('dialog action style reaches Buttons with $layout', (
      tester,
    ) async {
      var firstCalls = 0;
      var secondCalls = 0;
      const defaultKey = ValueKey('default-action');
      const localKey = ValueKey('local-action');
      const custom = material.Text('custom action');
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Dialog(
              content: const material.Text('Body'),
              dialogStyle: CoreDialogStyle(
                actionsLayout: layout,
                actionButtonStyle: const CoreButtonStyle(height: 64),
              ),
              actions: [
                Button(
                  key: defaultKey,
                  onPressed: () => firstCalls++,
                  child: const material.Text('Accept'),
                ),
                Button(
                  key: localKey,
                  buttonStyle: const CoreButtonStyle(
                    height: 52,
                    foregroundColor: CoreColor.token(CoreColors.primary),
                  ),
                  onPressed: () => secondCalls++,
                  child: const material.Text('Cancel'),
                ),
                custom,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(defaultKey)).height, 64);
      expect(tester.getSize(find.byKey(localKey)).height, 52);
      expect(
        tester
            .widget<Button>(find.byKey(localKey))
            .buttonStyle
            ?.foregroundColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        identical(tester.widget(find.text('custom action')), custom),
        isTrue,
      );
      await tester.tap(find.byKey(defaultKey));
      await tester.tap(find.byKey(localKey));
      expect(firstCalls, 1);
      expect(secondCalls, 1);
      await tester.pumpWidget(const material.SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('without a dialog style the original action is retained', (
    tester,
  ) async {
    const button = Button(child: material.Text('Original'));
    await tester.pumpWidget(
      const material.MaterialApp(
        home: Theme(
          data: ThemeData(),
          child: Dialog(actions: [button]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      identical(tester.widget<Button>(find.byType(Button)), button),
      isTrue,
    );
    await tester.pumpWidget(const material.SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'theme override preserves focus, keyboard and disabled behavior',
    (
      tester,
    ) async {
      final focus = FocusNode();
      var activated = 0;
      var disabledCalls = 0;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                dialog: CoreDialogTheme(
                  style: CoreDialogStyle(
                    actionButtonStyle: CoreButtonStyle(height: 64),
                  ),
                ),
              ),
            ),
            child: Dialog(
              actions: [
                Button(
                  key: const ValueKey('keyboard-action'),
                  focusNode: focus,
                  onPressed: () => activated++,
                  child: const material.Text('Enabled'),
                ),
                Button(
                  key: const ValueKey('disabled-action'),
                  enabled: false,
                  onPressed: () => disabledCalls++,
                  child: const material.Text('Disabled'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('keyboard-action'))).height,
        64,
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activated, 1);
      await tester.tap(find.byKey(const ValueKey('disabled-action')));
      expect(disabledCalls, 0);
      await tester.pumpWidget(const material.SizedBox());
      await tester.pumpAndSettle();
      focus.dispose();
    },
  );
}
