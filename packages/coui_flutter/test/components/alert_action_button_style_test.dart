import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// `CoreAlertStyle.actionButtonStyle` reaches a `Button` action the way it
/// does on Web: laid under the button's own `buttonStyle`, which still
/// wins. Before this, the Flutter resolver carried the value and the widget
/// never read it, so the same alert style restyled the action on one
/// platform and not the other.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 420, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

const _slotFill = CoreColor.token(CoreColors.primaryContainer);
const _slotPadding = CoreEdgeInsets.all(CoreSpace.space4);
const _ownPadding = CoreEdgeInsets.all(CoreSpace.space12);

void main() {
  testWidgets('a Button action takes the slot under its own style', (
    tester,
  ) async {
    await _pump(
      tester,
      Alert(
        title: 'Could not save',
        action: Button(
          onPressed: () {},
          buttonStyle: const CoreButtonStyle(padding: _ownPadding),
          child: const Text('Retry'),
        ),
        alertStyle: const CoreAlertStyle(
          actionButtonStyle: CoreButtonStyle(
            backgroundColor: _slotFill,
            padding: _slotPadding,
          ),
        ),
      ),
    );

    final drawn = tester.widget<Button>(find.byType(Button)).buttonStyle;
    // The slot's value reaches the button…
    expect(drawn?.backgroundColor, _slotFill);
    // …and the button's own value wins where both state one.
    expect(drawn?.padding, _ownPadding);
  });

  testWidgets('without the slot the action is the widget it was handed', (
    tester,
  ) async {
    final action = Button(onPressed: () {}, child: const Text('Retry'));
    await _pump(tester, Alert(title: 'Could not save', action: action));

    expect(tester.widget<Button>(find.byType(Button)), same(action));
  });

  testWidgets('an action that is not a Button renders as given', (
    tester,
  ) async {
    await _pump(
      tester,
      const Alert(
        title: 'Could not save',
        action: Text('Undo'),
        alertStyle: CoreAlertStyle(
          actionButtonStyle: CoreButtonStyle(backgroundColor: _slotFill),
        ),
      ),
    );

    expect(find.text('Undo'), findsOneWidget);
    expect(find.byType(Button), findsNothing);
  });
}
