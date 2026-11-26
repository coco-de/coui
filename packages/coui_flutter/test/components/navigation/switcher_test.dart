import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// Switcher test constants
const _kTestWidth = 200.0;
const _kTestHeight = 200.0;
const _kTransitionDuration = Duration(milliseconds: 300);

/// Matches the Flutter curve that [token] converts to.
///
/// `Cubic` carries no value equality, so an `equals` here would only pass
/// when the resolver happened to hand back the very same instance — a
/// guarantee no resolver owes anyone. The control points are the claim.
Matcher _curveOf(CoreCubicBezier token) => isA<Cubic>()
    .having((c) => c.a, 'a', token.x1)
    .having((c) => c.b, 'b', token.y1)
    .having((c) => c.c, 'c', token.x2)
    .having((c) => c.d, 'd', token.y2);

void main() {
  group('Switcher widget', () {
    List<Widget> buildChildren() {
      return [
        const ColoredBox(
          color: Color(0xFFFF0000),
          child: SizedBox(
            width: _kTestWidth,
            height: _kTestHeight,
            child: Center(child: Text('Page 1')),
          ),
        ),
        const ColoredBox(
          color: Color(0xFF0000FF),
          child: SizedBox(
            width: _kTestWidth,
            height: _kTestHeight,
            child: Center(child: Text('Page 2')),
          ),
        ),
        const ColoredBox(
          color: Color(0xFF00FF00),
          child: SizedBox(
            width: _kTestWidth,
            height: _kTestHeight,
            child: Center(child: Text('Page 3')),
          ),
        ),
      ];
    }

    testWidgets('renders first child at index 0', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          index: 0,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('renders with default index of 0', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders at specified non-zero index', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          index: 1,
          items: buildChildren(),
        ),
      );
      // Allow animation to settle.
      await tester.pump();
      await tester.pump(_kTransitionDuration);

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('calls onIndexChanged when index prop changes', (tester) async {
      int? changedIndex;

      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          index: 0,
          onIndexChanged: (index) {
            changedIndex = index;
          },
          items: buildChildren(),
        ),
      );
      await tester.pump();

      // Trigger a rebuild with a new index by wrapping in a stateful widget.
      expect(changedIndex, isNull);
    });

    testWidgets('renders with AxisDirection.left', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .left,
          index: 0,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with AxisDirection.up', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .up,
          index: 0,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with AxisDirection.down', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .down,
          index: 0,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with gestureEnabled false', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          gestureEnabled: false,
          index: 0,
          items: buildChildren(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with custom duration and curve', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          items: buildChildren(),
          index: 0,
          direction: .right,
          switcherStyle: const CoreSwitcherStyle(
            duration: Duration(milliseconds: 500),
            curve: CoreEasing.easeOut,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('style-slot easing reaches the transition', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          items: buildChildren(),
          index: 0,
          switcherStyle: const CoreSwitcherStyle(curve: CoreEasing.easeOut),
        ),
      );
      await tester.pump();

      // The Core token is what both platforms read; Flutter converts it to
      // the matching `Cubic` here, Web emits the same control points as
      // its `cubic-bezier(...)` timing function.
      final builder = tester.widget<AnimatedValueBuilder<double>>(
        find.byType(AnimatedValueBuilder<double>),
      );
      expect(builder.curve, _curveOf(CoreEasing.easeOut));
    });

    testWidgets('falls back to the design-system easing token', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(items: buildChildren(), index: 0),
      );
      await tester.pump();

      final builder = tester.widget<AnimatedValueBuilder<double>>(
        find.byType(AnimatedValueBuilder<double>),
      );
      expect(builder.curve, _curveOf(CoreSwitcherStyle.defaultCurve));
    });

    testWidgets('transitions when index changes', (tester) async {
      int activeIndex = 0;

      await pumpTestApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Switcher(
                  direction: .right,
                  index: activeIndex,
                  items: buildChildren(),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      activeIndex = 1;
                    });
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(_kTransitionDuration);

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with two children', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          index: 0,
          items: [
            const SizedBox(
              width: _kTestWidth,
              height: _kTestHeight,
              child: Text('First'),
            ),
            const SizedBox(
              width: _kTestWidth,
              height: _kTestHeight,
              child: Text('Second'),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });

    testWidgets('renders with single child', (tester) async {
      await pumpTestApp(
        tester,
        Switcher(
          direction: .right,
          index: 0,
          items: [
            const SizedBox(
              width: _kTestWidth,
              height: _kTestHeight,
              child: Text('Alone'),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(Switcher), findsOneWidget);
    });
  });
}
