import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  // The CoUI Theme must wrap the Navigator so dialog routes (pushed on the
  // root navigator) can resolve it from their barrier/content builders.
  builder: (context, navigator) =>
      Theme(data: const ThemeData(), child: navigator!),
  home: child,
);

// `Dialog` self-pushes a modal route when `open` is true. Re-pumping it with
// `open: false` triggers `didUpdateWidget` -> dismiss synchronously, popping
// the route so the widget's dispose doesn't leave a dangling post-frame
// callback that touches a defunct context.
Future<void> _dismiss(WidgetTester tester) async {
  await tester.pumpWidget(_buildApp(const Dialog(open: false)));
  await tester.pumpAndSettle();
}

void main() {
  group('Dialog', () {
    testWidgets('renders with title widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Dialog(
            title: material.Text('Dialog Title'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Dialog Title'), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with content widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Dialog(
            content: material.Text('Dialog content description'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dialog content description'), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with actions list', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Dialog(
            actions: [
              Button(
                variant: .secondary,
                onPressed: () {},
                child: const material.Text('Cancel'),
              ),
              Button(
                variant: .primary,
                onPressed: () {},
                child: const material.Text('Confirm'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with leading widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Dialog(
            leading: material.Icon(material.Icons.warning),
            title: material.Text('Warning'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(material.Icons.warning), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with trailing widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Dialog(
            title: material.Text('With Trailing'),
            trailing: material.Icon(material.Icons.close),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(material.Icons.close), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with all optional widgets combined', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Dialog(
            actions: [
              Button(
                variant: .secondary,
                onPressed: () {},
                child: const material.Text('Cancel'),
              ),
            ],
            content: const material.Text('Are you sure?'),
            leading: const material.Icon(material.Icons.info),
            title: const material.Text('Confirm'),
            trailing: const material.Icon(material.Icons.close),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(material.Icons.info), findsOneWidget);
      expect(find.byIcon(material.Icons.close), findsOneWidget);
      await _dismiss(tester);
    });

    testWidgets('renders with no optional widgets', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Dialog()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      await _dismiss(tester);
    });
  });
}
