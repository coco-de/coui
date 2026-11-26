import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('ScrollableClient', () {
    testWidgets('renders with builder callback', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          ScrollableClient(
            builder: (context, offset, viewportSize, child) {
              return const material.Text('built content');
            },
          ),
        ),
      );

      expect(find.text('built content'), findsOneWidget);
    });

    testWidgets('builder receives offset and viewportSize', (tester) async {
      material.Offset? receivedOffset;
      material.Size? receivedViewportSize;

      final _ = await tester.pumpWidget(
        _buildApp(
          ScrollableClient(
            builder: (context, offset, viewportSize, child) {
              receivedOffset = offset;
              receivedViewportSize = viewportSize;

              return const material.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(receivedOffset, isNotNull);
      expect(receivedViewportSize, isNotNull);
    });

    testWidgets('builder receives child when provided', (tester) async {
      material.Widget? receivedChild;

      final _ = await tester.pumpWidget(
        _buildApp(
          ScrollableClient(
            builder: (context, offset, viewportSize, child) {
              receivedChild = child;

              return child ?? const material.SizedBox.shrink();
            },
            child: const material.Text('passed child'),
          ),
        ),
      );

      expect(receivedChild, isNotNull);
    });

    testWidgets('renders ScrollableClient widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          ScrollableClient(
            builder: (context, offset, viewportSize, child) {
              return const material.SizedBox.shrink();
            },
          ),
        ),
      );

      expect(find.byType(ScrollableClient), findsOneWidget);
    });
  });
}
