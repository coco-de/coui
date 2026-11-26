// Pins `skipInputFeatureFocusTraversal` to the focus node the affordance
// button actually gets.
//
// The flag was declared on the contract and on both widgets and read by
// nobody: Flutter emitted nothing at all (so affordances always sat in the
// Tab order), Web emitted `tabindex="-1"` unconditionally. Same field,
// opposite answers, neither moving when a caller set it.
//
// These cases read `skipTraversal` off the node the button was handed
// rather than asserting the widget carries the field, so they fail on an
// unpatched build — where `Button` receives no `focusNode` at all and the
// finder below comes back empty.
//
// `skipTraversal` — not `ExcludeFocus`: the affordance has to stay
// reachable by pointer and by `requestFocus`, and only drop out of Tab.
// That is what `tabindex="-1"` means on the Web side.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// The focus node handed to the affordance button.
///
/// Located through `Button` rather than through the raw `Focus` widgets so
/// the assertion is about what the affordance was given, not about how
/// `Clickable` happens to nest its nodes today.
FocusNode? _featureFocusNode(WidgetTester tester) {
  final buttons = tester.widgetList<Button>(find.byType(Button));
  return buttons.singleOrNull?.focusNode;
}

void main() {
  group('TextField skipInputFeatureFocusTraversal', () {
    testWidgets(
      'affordance joins the Tab order when traversal is not skipped',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            TextField(
              initialValue: 'abc',
              features: const [CoreInputFeature.clear()],
              skipInputFeatureFocusTraversal: false,
            ),
          ),
        );

        final node = _featureFocusNode(tester);
        expect(node, isNotNull, reason: 'the affordance must own a focus node');
        expect(node!.skipTraversal, isFalse);
      },
    );

    testWidgets('affordance leaves the Tab order but stays focusable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [CoreInputFeature.clear()],
            skipInputFeatureFocusTraversal: true,
          ),
        ),
      );

      final node = _featureFocusNode(tester);
      expect(node, isNotNull);
      expect(node!.skipTraversal, isTrue);

      // Skipped, not excluded — programmatic focus still lands.
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('defaults to skipping traversal', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [CoreInputFeature.clear()],
          ),
        ),
      );

      expect(_featureFocusNode(tester)?.skipTraversal, isTrue);
    });

    testWidgets('a flag flip reaches the node already built', (tester) async {
      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [CoreInputFeature.clear()],
            skipInputFeatureFocusTraversal: true,
          ),
        ),
      );
      expect(_featureFocusNode(tester)?.skipTraversal, isTrue);

      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [CoreInputFeature.clear()],
            skipInputFeatureFocusTraversal: false,
          ),
        ),
      );

      expect(
        _featureFocusNode(tester)?.skipTraversal,
        isFalse,
        reason: 'skipTraversal is mutable — the flip must not need a rebuild',
      );
    });

    testWidgets('a shrinking feature list disposes without leaking', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [
              CoreInputFeature.clear(),
              CoreInputFeature.passwordToggle(),
            ],
          ),
        ),
      );
      expect(find.byType(Button), findsNWidgets(2));

      await tester.pumpWidget(
        _app(
          TextField(
            initialValue: 'abc',
            features: const [CoreInputFeature.clear()],
          ),
        ),
      );

      expect(find.byType(Button), findsOneWidget);
      expect(_featureFocusNode(tester)?.skipTraversal, isTrue);
    });
  });
}
