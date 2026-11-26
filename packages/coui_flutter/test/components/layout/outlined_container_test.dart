import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kSurfaceBlurValue = 5.0;
const _kBorderColorValue = material.Color(0xFFFF0000);

void main() {
  group('SurfaceBlur', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const SurfaceBlur(
            child: material.Text('surface blur child'),
          ),
        ),
      );

      expect(find.text('surface blur child'), findsOneWidget);
    });

    testWidgets('renders without BackdropFilter when surfaceBlur is null', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const SurfaceBlur(
            child: material.Text('no blur'),
          ),
        ),
      );

      expect(find.text('no blur'), findsOneWidget);
      expect(find.byType(material.BackdropFilter), findsNothing);
    });

    testWidgets('renders with BackdropFilter when surfaceBlur is non-zero', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const SurfaceBlur(
            surfaceBlur: _kSurfaceBlurValue,
            child: material.Text('with blur'),
          ),
        ),
      );

      expect(find.text('with blur'), findsOneWidget);
      expect(find.byType(material.BackdropFilter), findsOneWidget);
    });

    testWidgets('renders without BackdropFilter when surfaceBlur is zero', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const SurfaceBlur(
            surfaceBlur: 0,
            child: material.Text('zero blur'),
          ),
        ),
      );

      expect(find.text('zero blur'), findsOneWidget);
      expect(find.byType(material.BackdropFilter), findsNothing);
    });
  });

  group('OutlinedContainer', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OutlinedContainer(
            child: material.Text('outlined child'),
          ),
        ),
      );

      expect(find.text('outlined child'), findsOneWidget);
    });

    testWidgets('renders with backgroundColor param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OutlinedContainer(
            containerStyle: CoreOutlinedContainerStyle(
              backgroundColor: CoreColor(0xFF0000FF),
            ),
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(OutlinedContainer), findsOneWidget);
    });

    testWidgets('renders with borderColor param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OutlinedContainer(
            containerStyle: CoreOutlinedContainerStyle(
              borderColor: CoreColor(0xFFFF0000),
            ),
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(OutlinedContainer), findsOneWidget);
    });

    testWidgets('renders with borderRadius param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OutlinedContainer(
            containerStyle: CoreOutlinedContainerStyle(
              borderRadius: CoreBorderRadius.circular(8),
            ),
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(OutlinedContainer), findsOneWidget);
    });

    testWidgets('renders OutlinedContainer widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const OutlinedContainer(
            child: material.Text('test'),
          ),
        ),
      );

      expect(find.byType(OutlinedContainer), findsOneWidget);
    });
  });

  group('DashedContainer', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const DashedContainer(
            child: material.Text('dashed child'),
          ),
        ),
      );

      expect(find.text('dashed child'), findsOneWidget);
    });

    testWidgets('renders DashedContainer widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const DashedContainer(
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(DashedContainer), findsOneWidget);
    });

    testWidgets('renders with color param', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const DashedContainer(
            color: _kBorderColorValue,
            child: material.Text('colored dashed'),
          ),
        ),
      );

      expect(find.text('colored dashed'), findsOneWidget);
    });
  });

  // The border style is decoration: whatever it is, the content inside the
  // container must stay in the semantics tree. The dashed and dotted styles
  // are the ones that draw through a painter on Flutter, and once hid the
  // whole child from assistive tech; the Web twin hides only its `<svg>`.
  group('OutlinedContainer semantics', () {
    for (final style in CoreOutlinedContainerBorderStyle.values) {
      testWidgets('${style.name} border keeps the child readable', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final _ = await tester.pumpWidget(
          _buildApp(
            OutlinedContainer(
              containerStyle: CoreOutlinedContainerStyle(borderStyle: style),
              child: material.Column(
                children: [
                  const material.Text('container label'),
                  material.Semantics(
                    button: true,
                    label: 'container action',
                    child: const material.SizedBox(width: 24, height: 24),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('container label'), findsOneWidget);
        expect(find.bySemanticsLabel('container action'), findsOneWidget);
        handle.dispose();
      });
    }

    // The edge sheen a surface style adds is drawn the same way — a painter
    // over the content — and once hid the content of every surface under a
    // style that states one.
    testWidgets('an edge sheen keeps the child readable', (tester) async {
      final handle = tester.ensureSemantics();
      final _ = await tester.pumpWidget(
        _buildApp(
          SurfaceBlur(
            surfaceSheen: const ResolvedSurfaceSheen(
              width: 1,
              lightColor: material.Color(0x80FFFFFF),
              darkColor: material.Color(0x40000000),
              fade: 0.5,
            ),
            borderRadius: material.BorderRadius.circular(8),
            child: material.Column(
              children: [
                const material.Text('surface label'),
                material.Semantics(
                  button: true,
                  label: 'surface action',
                  child: const material.SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('surface label'), findsOneWidget);
      expect(find.bySemanticsLabel('surface action'), findsOneWidget);
      handle.dispose();
    });
  });
}
