import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// `MediaQueryVisibility` resolves against the actual layout width (via an
// internal LayoutBuilder), so constrain the real width with a SizedBox rather
// than overriding MediaQueryData.size.
material.Widget _buildApp(double width, material.Widget child) =>
    material.MaterialApp(
      home: Theme(
        data: const ThemeData(),
        child: material.Center(
          child: material.SizedBox(
            width: width,
            height: 100,
            child: child,
          ),
        ),
      ),
    );

const _kMinWidth = 400.0;
const _kMaxWidth = 800.0;
const _kNarrowScreenWidth = 300.0;
const _kWideScreenWidth = 1000.0;
const _kMidScreenWidth = 600.0;

void main() {
  group('MediaQueryVisibility', () {
    testWidgets('renders child when width is within range', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          _kMidScreenWidth,
          const MediaQueryVisibility(
            maxWidth: _kMaxWidth,
            minWidth: _kMinWidth,
            child: material.Text('visible child'),
          ),
        ),
      );

      expect(find.text('visible child'), findsOneWidget);
    });

    testWidgets('renders alternateChild when width is below minWidth', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          _kNarrowScreenWidth,
          const MediaQueryVisibility(
            alternateChild: material.Text('alternate child'),
            minWidth: _kMinWidth,
            child: material.Text('main child'),
          ),
        ),
      );

      expect(find.text('main child'), findsNothing);
      expect(find.text('alternate child'), findsOneWidget);
    });

    testWidgets('renders alternateChild when width exceeds maxWidth', (
      tester,
    ) async {
      // Width 600 exceeds maxWidth 400 (kept within the test surface so the
      // SizedBox width isn't clamped).
      final _ = await tester.pumpWidget(
        _buildApp(
          _kMidScreenWidth,
          const MediaQueryVisibility(
            alternateChild: material.Text('alternate child'),
            maxWidth: _kMinWidth,
            child: material.Text('main child'),
          ),
        ),
      );

      expect(find.text('main child'), findsNothing);
      expect(find.text('alternate child'), findsOneWidget);
    });

    testWidgets('renders child when no min/max constraints', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          _kWideScreenWidth,
          const MediaQueryVisibility(
            child: material.Text('always visible'),
          ),
        ),
      );

      expect(find.text('always visible'), findsOneWidget);
    });

    testWidgets(
      'renders empty SizedBox when alternateChild is null and width is out of range',
      (
        tester,
      ) async {
        final _ = await tester.pumpWidget(
          _buildApp(
            _kNarrowScreenWidth,
            const MediaQueryVisibility(
              minWidth: _kMinWidth,
              child: material.Text('hidden child'),
            ),
          ),
        );

        expect(find.text('hidden child'), findsNothing);
      },
    );
  });
}
