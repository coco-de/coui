import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kCloseDelay = Duration(milliseconds: 300);
const _kOpenDelay = Duration(milliseconds: 600);

// HoverCard is engine-direct (shared popover overlay handler) — it needs a
// root Overlay (MaterialApp provides one) plus a CoUI Theme ancestor.
material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('HoverCard', () {
    testWidgets('renders trigger widget', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            content: material.Text('hover content'),
            trigger: material.Text('hover target'),
          ),
        ),
      );

      expect(find.text('hover target'), findsOneWidget);
    });

    testWidgets('trigger is visible without hovering', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            content: material.Text('tooltip info'),
            trigger: material.Icon(material.Icons.info),
          ),
        ),
      );

      expect(find.byType(material.Icon), findsOneWidget);
      expect(find.text('tooltip info'), findsNothing);
    });

    testWidgets('renders with custom open/close delays', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            closeDelay: _kCloseDelay,
            openDelay: _kOpenDelay,
            content: material.Text('hover content'),
            trigger: material.Text('target'),
          ),
        ),
      );

      expect(find.text('target'), findsOneWidget);
    });

    testWidgets('renders with custom placement', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            placement: CorePopoverPlacement.top,
            content: material.Text('hover content'),
            trigger: material.Text('target'),
          ),
        ),
      );

      expect(find.text('target'), findsOneWidget);
    });

    testWidgets('wraps trigger in GestureDetector', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            content: material.Text('hover content'),
            trigger: material.Text('target'),
          ),
        ),
      );

      expect(find.byType(material.GestureDetector), findsOneWidget);
    });

    testWidgets('wraps trigger in MouseRegion', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const HoverCard(
            content: material.Text('hover content'),
            trigger: material.Text('target'),
          ),
        ),
      );

      expect(find.byType(material.MouseRegion), findsWidgets);
    });
  });
}
