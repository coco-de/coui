import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kMinValue = 20.0;
const _kMaxValue = 80.0;
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

/// How many thumbs currently show a focus ring. The ring is drawn by the
/// `FocusOutline` each thumb composes, so its `focused` flag is the state
/// under test — not any particular decoration the ring happens to use.
int _outlinedThumbs(WidgetTester tester) => tester
    .widgetList<FocusOutline>(
      find.descendant(
        of: find.byType(Range),
        matching: find.byType(FocusOutline),
      ),
    )
    .where((outline) => outline.focused)
    .length;

void main() {
  // Desktop platforms seed `FocusableActionDetector`'s highlight gate to
  // `traditional`, which is the mode that shows a highlight for
  // pointer-initiated focus. See `slider_focus_test.dart`.
  final desktop = TargetPlatformVariant.desktop();

  group('Range thumb focus outline', () {
    testWidgets(
      'stays hidden while a mouse drags a thumb',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Range(
              onChanged: (_, __) {},
              minValue: _kMinValue,
              maxValue: _kMaxValue,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Range)),
          kind: .mouse,
        );
        await gesture.moveBy(const Offset(_kDragDistance, 0));
        final _ = await tester.pumpAndSettle();

        expect(_outlinedThumbs(tester), 0);

        await gesture.up();
        final _ = await tester.pumpAndSettle();

        expect(_outlinedThumbs(tester), 0);
      },
      variant: desktop,
    );

    testWidgets(
      'appears on the dragged thumb once a key follows',
      (tester) async {
        double? changedMin;
        double? changedMax;
        await tester.pumpWidget(
          _buildApp(
            Range(
              onChanged: (min, max) {
                changedMin = min;
                changedMax = max;
              },
              minValue: _kMinValue,
              maxValue: _kMaxValue,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(Range)),
          kind: .mouse,
        );
        await gesture.moveBy(const Offset(_kDragDistance, 0));
        await gesture.up();
        final _ = await tester.pumpAndSettle();
        expect(_outlinedThumbs(tester), 0);

        // The drag handed focus to the thumb it grabbed, so the arrow
        // key keeps adjusting that same thumb — and reveals its outline.
        await tester.sendKeyEvent(.arrowRight);
        final _ = await tester.pumpAndSettle();

        expect(changedMin, isNotNull);
        expect(changedMax, isNotNull);
        expect(_outlinedThumbs(tester), 1);
      },
      variant: desktop,
    );

    testWidgets(
      'appears when focus arrives from the keyboard',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Range(
              onChanged: (_, __) {},
              minValue: _kMinValue,
              maxValue: _kMaxValue,
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        await tester.sendKeyEvent(.tab);
        final _ = await tester.pumpAndSettle();

        expect(_outlinedThumbs(tester), 1);
      },
      variant: desktop,
    );
  });
}
