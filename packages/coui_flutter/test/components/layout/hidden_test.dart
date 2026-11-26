import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestDuration = Duration(milliseconds: 300);
const _kTestCurve = CoreEasing.easeIn;

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
  group('Hidden', () {
    testWidgets('renders child when hidden=false (child visible)', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            hidden: false,
            child: material.Text('Visible Child'),
          ),
        ),
      );

      expect(find.byType(Hidden), findsOneWidget);
      expect(find.text('Visible Child'), findsOneWidget);
    });

    testWidgets('renders when hidden=true (child faded out)', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            hidden: true,
            child: material.Text('Hidden Child'),
          ),
        ),
      );

      expect(find.byType(Hidden), findsOneWidget);
      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animatedOpacity.opacity, equals(0.0));
    });

    testWidgets('opacity is 1.0 when hidden=false', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            hidden: false,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animatedOpacity.opacity, equals(1.0));
    });

    testWidgets('renders with direction param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            direction: .vertical,
            hidden: false,
            child: material.Text('Vertical'),
          ),
        ),
      );

      expect(find.byType(Hidden), findsOneWidget);
      expect(find.text('Vertical'), findsOneWidget);
    });

    testWidgets('renders with duration param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            duration: _kTestDuration,
            hidden: false,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animatedOpacity.duration, equals(_kTestDuration));
    });

    testWidgets('renders with curve param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(
            hidden: false,
            curve: _kTestCurve,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      // The Core token reaches the animation as the matching Flutter
      // curve — the same four control points the Web twin emits as its
      // `cubic-bezier(...)` timing function.
      expect(animatedOpacity.curve, _curveOf(_kTestCurve));
    });

    testWidgets('falls back to the design-system easing token', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Hidden(hidden: false, child: material.SizedBox.shrink()),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(
        animatedOpacity.curve,
        _curveOf(CoreHiddenStyle.defaultTransitionCurve),
      );
    });

    testWidgets('theme style overrides the easing token', (tester) async {
      final _ = await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                hidden: CoreHiddenTheme(
                  style: CoreHiddenStyle(transitionCurve: CoreEasing.easeOut),
                ),
              ),
            ),
            child: const Hidden(
              hidden: false,
              child: material.SizedBox.shrink(),
            ),
          ),
        ),
      );

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animatedOpacity.curve, _curveOf(CoreEasing.easeOut));
    });

    testWidgets('toggles opacity when hidden state changes', (tester) async {
      bool isHidden = false;
      final _ = await tester.pumpWidget(
        _buildApp(
          material.StatefulBuilder(
            builder: (context, setState) {
              return material.Column(
                children: [
                  Hidden(
                    hidden: isHidden,
                    child: const material.Text('Toggle Me'),
                  ),
                  material.TextButton(
                    onPressed: () => setState(() => isHidden = !isHidden),
                    child: const material.Text('Toggle'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      AnimatedOpacity opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(opacityWidget.opacity, equals(1.0));

      await tester.tap(find.text('Toggle'));
      await tester.pump();

      opacityWidget = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(opacityWidget.opacity, equals(0.0));
    });
  });
}
