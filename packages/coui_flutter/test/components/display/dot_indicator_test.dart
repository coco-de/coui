import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestLength = 5;
const _kTestIndex = 2;
const _kTestSpacing = 12.0;
const _kTestPadding = 10.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: child,
    ),
  );
}

void main() {
  group('DotIndicator widget', () {
    for (final borderWidth in [0.0, 2.0]) {
      testWidgets('only inactive dots paint a $borderWidth border', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            DotIndicator(
              index: 0,
              length: 2,
              dotIndicatorStyle: CoreDotIndicatorStyle(
                inactiveBorderWidth: borderWidth,
              ),
            ),
          ),
        );
        final dots = find.descendant(
          of: find.byType(DotIndicator),
          matching: find.byType(AnimatedContainer),
        );
        final active = tester.widget<AnimatedContainer>(dots.at(0));
        final inactive = tester.widget<AnimatedContainer>(dots.at(1));
        expect((active.decoration! as BoxDecoration).border, isNull);
        final inactiveBorder = (inactive.decoration! as BoxDecoration).border;
        if (borderWidth == 0) {
          expect(inactiveBorder, isNull);
        } else {
          expect((inactiveBorder! as Border).top.width, borderWidth);
        }
      });
    }
    testWidgets('without active length the selected dot remains round', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(
            index: 0,
            length: 3,
            dotIndicatorStyle: CoreDotIndicatorStyle(dotSize: 6),
          ),
        ),
      );
      final active = find.descendant(
        of: find.byType(FocusOutline),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(active.first), const Size(6, 6));
    });
    for (final direction in CoreAxis.values) {
      testWidgets('active length follows the $direction axis', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            DotIndicator(
              index: 0,
              length: 3,
              direction: direction,
              dotIndicatorStyle: const CoreDotIndicatorStyle(
                dotSize: 6,
                activeLength: 18,
                padding: CoreEdgeInsets.zero,
                spacing: 6,
              ),
            ),
          ),
        );
        final active = find.descendant(
          of: find.byType(FocusOutline),
          matching: find.byType(AnimatedContainer),
        );
        expect(
          tester.getSize(active.first),
          direction == CoreAxis.horizontal
              ? const Size(18, 6)
              : const Size(6, 18),
        );
      });
    }
    for (final direction in CoreAxis.values) {
      testWidgets('paints a 6px gap along the $direction axis', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            DotIndicator(
              index: 0,
              length: 3,
              direction: direction,
              dotIndicatorStyle: const CoreDotIndicatorStyle(
                dotSize: 6,
                activeLength: 18,
                padding: CoreEdgeInsets.zero,
                spacing: 6,
              ),
            ),
          ),
        );
        final dots = find.descendant(
          of: find.byType(DotIndicator),
          matching: find.byType(AnimatedContainer),
        );
        expect(dots, findsNWidgets(3));
        final first = tester.getRect(dots.at(0));
        final second = tester.getRect(dots.at(1));
        final third = tester.getRect(dots.at(2));
        if (direction == CoreAxis.horizontal) {
          expect(second.left - first.right, 6);
          expect(third.left - second.right, 6);
        } else {
          expect(second.top - first.bottom, 6);
          expect(third.top - second.bottom, 6);
        }
      });
    }
    testWidgets('horizontal RTL keeps the spacing between markers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: DotIndicator(
              index: 0,
              length: 3,
              dotIndicatorStyle: CoreDotIndicatorStyle(
                dotSize: 6,
                activeLength: 18,
                padding: CoreEdgeInsets.zero,
                spacing: 6,
              ),
            ),
          ),
        ),
      );
      final dots = find.descendant(
        of: find.byType(DotIndicator),
        matching: find.byType(AnimatedContainer),
      );
      final first = tester.getRect(dots.at(0));
      final second = tester.getRect(dots.at(1));
      final third = tester.getRect(dots.at(2));
      expect(first.left - second.right, 6);
      expect(second.left - third.right, 6);
    });
    for (final direction in CoreAxis.values) {
      testWidgets('retains asymmetric outer padding for RTL $direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Directionality(
              textDirection: TextDirection.rtl,
              child: material.Center(
                child: DotIndicator(
                  index: 0,
                  length: 3,
                  direction: direction,
                  dotIndicatorStyle: const CoreDotIndicatorStyle(
                    dotSize: 6,
                    activeLength: 18,
                    spacing: 6,
                    padding: CoreEdgeInsets.only(
                      left: 3,
                      right: 5,
                      top: 10,
                      bottom: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final box = tester.getRect(find.byType(DotIndicator));
        final dots = find.descendant(
          of: find.byType(DotIndicator),
          matching: find.byType(AnimatedContainer),
        );
        final first = tester.getRect(dots.at(0));
        final last = tester.getRect(dots.at(2));
        if (direction == CoreAxis.horizontal) {
          expect(box.right - first.right, 5);
          expect(last.left - box.left, 3);
          expect(first.top - box.top, 10);
          expect(box.bottom - first.bottom, 14);
        } else {
          expect(first.top - box.top, 10);
          expect(box.bottom - last.bottom, 14);
          expect(first.left - box.left, 3);
          expect(box.right - first.right, 5);
        }
      });
    }
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(index: _kTestIndex, length: _kTestLength),
        ),
      );

      expect(find.byType(DotIndicator), findsOneWidget);
    });

    testWidgets('renders one Clickable per dot', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DotIndicator(
            onChanged: (_) {},
            index: 0,
            length: _kTestLength,
          ),
        ),
      );

      expect(find.byType(Clickable), findsNWidgets(_kTestLength));
    });

    testWidgets('renders with horizontal direction', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(index: 0, length: _kTestLength),
        ),
      );

      final widget = tester.widget<DotIndicator>(find.byType(DotIndicator));
      expect(widget.direction, equals(CoreAxis.horizontal));
    });

    testWidgets('renders with vertical direction', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(
            direction: .vertical,
            index: 0,
            length: _kTestLength,
          ),
        ),
      );

      final widget = tester.widget<DotIndicator>(find.byType(DotIndicator));
      expect(widget.direction, equals(CoreAxis.vertical));
    });

    testWidgets('renders with custom spacing via dotIndicatorStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(
            index: 0,
            length: _kTestLength,
            dotIndicatorStyle: CoreDotIndicatorStyle(spacing: _kTestSpacing),
          ),
        ),
      );

      final widget = tester.widget<DotIndicator>(find.byType(DotIndicator));
      expect(widget.dotIndicatorStyle?.spacing, equals(_kTestSpacing));
    });

    testWidgets('renders with custom padding via dotIndicatorStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(
            index: 0,
            length: _kTestLength,
            dotIndicatorStyle: CoreDotIndicatorStyle(
              padding: CoreEdgeInsets.all(_kTestPadding),
            ),
          ),
        ),
      );

      final widget = tester.widget<DotIndicator>(find.byType(DotIndicator));
      expect(
        widget.dotIndicatorStyle?.padding,
        equals(const CoreEdgeInsets.all(_kTestPadding)),
      );
    });

    testWidgets('onChanged callback fires on dot tap', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        _buildApp(
          DotIndicator(
            onChanged: (index) {
              tappedIndex = index;
            },
            index: 0,
            length: _kTestLength,
          ),
        ),
      );

      await tester.tap(find.byType(Clickable).last);
      await tester.pump();

      expect(tappedIndex, isNotNull);
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-dot-indicator');

      await tester.pumpWidget(
        _buildApp(
          const DotIndicator(
            key: testKey,
            index: 0,
            length: _kTestLength,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('default properties are correct', (tester) async {
      const widget = DotIndicator(index: 0, length: _kTestLength);

      expect(widget.direction, equals(CoreAxis.horizontal));
      expect(widget.dotIndicatorStyle, isNull);
      expect(widget.onChanged, isNull);
    });
  });
}
