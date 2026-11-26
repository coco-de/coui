import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kInitialValue = 50.0;
const _kSizedBoxWidth = 300.0;
const _kDragDistance = 20.0;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kSizedBoxWidth,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

/// Whether the slider currently shows its focus ring. The ring is drawn
/// by the composed `FocusOutline`, so its `focused` flag is the state
/// under test — not any particular decoration the ring happens to use.
bool _hasFocusOutline(WidgetTester tester) => tester
    .widgetList<FocusOutline>(
      find.descendant(
        of: find.byType(Slider),
        matching: find.byType(FocusOutline),
      ),
    )
    .any((outline) => outline.focused);

void main() {
  // Desktop platforms are the whole point: `FocusableActionDetector`
  // seeds its highlight gate from `FocusManager.highlightMode`, which
  // defaults to `traditional` on desktop and `touch` on mobile. Only
  // `traditional` shows a highlight for pointer-initiated focus, so a
  // mobile default would let these tests pass without exercising the
  // behaviour they describe.
  final desktop = TargetPlatformVariant.desktop();

  group('Slider focus outline', () {
    testWidgets(
      'stays hidden while a mouse drags the thumb',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(Slider(onChanged: (_) {}, value: _kInitialValue)),
        );
        final _ = await tester.pumpAndSettle();

        // The Web twin's `focus-visible:` outline does not match a mouse
        // press, so neither should this one.
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Slider)),
          kind: .mouse,
        );
        await gesture.moveBy(const Offset(_kDragDistance, 0));
        final _ = await tester.pumpAndSettle();

        expect(_hasFocusOutline(tester), isFalse);

        // Releasing keeps it hidden — the outline waits for a key.
        await gesture.up();
        final _ = await tester.pumpAndSettle();

        expect(_hasFocusOutline(tester), isFalse);
      },
      variant: desktop,
    );

    testWidgets(
      'appears once a key follows the mouse drag',
      (tester) async {
        double? changed;
        await tester.pumpWidget(
          _buildApp(
            Slider(onChanged: (v) => changed = v, value: _kInitialValue),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Slider)),
          kind: .mouse,
        );
        await gesture.up();
        final _ = await tester.pumpAndSettle();
        expect(_hasFocusOutline(tester), isFalse);

        // The pointer still took focus, so the arrow key reaches the
        // slider — and that keyboard interaction is what reveals the
        // outline (the browser turns `:focus-visible` on the same way).
        await tester.sendKeyEvent(.arrowRight);
        final _ = await tester.pumpAndSettle();

        expect(changed, isNotNull);
        expect(_hasFocusOutline(tester), isTrue);
      },
      variant: desktop,
    );

    testWidgets(
      'appears when focus arrives from the keyboard',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(Slider(onChanged: (_) {}, value: _kInitialValue)),
        );
        final _ = await tester.pumpAndSettle();

        await tester.sendKeyEvent(.tab);
        final _ = await tester.pumpAndSettle();

        expect(_hasFocusOutline(tester), isTrue);
      },
      variant: desktop,
    );
  });
}
