import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme) in [
    ('light', CoreThemePresets.light),
    ('dark', CoreThemePresets.dark),
  ]) {
    for (final variant in CoreBadgeVariant.values) {
      testWidgets('interactive $variant responds to keyboard in $name', (
        tester,
      ) async {
        var presses = 0;
        final previous = material.FocusManager.instance.highlightStrategy;
        material.FocusManager.instance.highlightStrategy = .alwaysTraditional;
        addTearDown(
          () => material.FocusManager.instance.highlightStrategy = previous,
        );
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: ThemeData.fromCore(theme),
              child: Center(
                child: Badge(
                  variant: variant,
                  onPressed: () => presses++,
                  badgeStyle: const CoreBadgeStyle(
                    transitionDuration: Duration(milliseconds: 175),
                  ),
                  child: const Text('Activate'),
                ),
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<AnimatedOpacity>(
                find.descendant(
                  of: find.byType(FocusOutline),
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .last
              .opacity,
          1,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(presses, 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(presses, 2);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
