import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {ThemeData theme = const ThemeData()}) {
  return material.MaterialApp(
    home: Theme(data: theme, child: child),
  );
}

/// The tag's own box — the one `Container` it paints.
Finder _box() =>
    find.descendant(of: find.byType(Tag), matching: find.byType(Container));

BoxDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(_box()).decoration! as BoxDecoration;

/// The text style the label is actually laid out with.
TextStyle _paintedLabelStyle(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style!;

Future<void> _pumpTag(
  WidgetTester tester,
  Tag tag, {
  ThemeData theme = const ThemeData(),
}) async {
  await tester.pumpWidget(_buildApp(theme: theme, Center(child: tag)));
  await tester.pumpAndSettle();
}

void main() {
  const expectedHeight = {CoreTagSize.sm: 20.0, CoreTagSize.md: 24.0};
  const expectedRadius = {CoreTagSize.sm: 4.0, CoreTagSize.md: 6.0};
  const expectedPadding = {CoreTagSize.sm: 6.0, CoreTagSize.md: 8.0};

  group('rendered geometry', () {
    for (final size in CoreTagSize.values) {
      for (final emphasis in CoreTagEmphasis.values) {
        testWidgets('${size.name} ${emphasis.name} — fixed height, centred '
            'label, the step corner', (tester) async {
          await _pumpTag(
            tester,
            Tag(emphasis: emphasis, size: size, child: const Text('Design')),
          );

          final box = tester.getRect(_box());
          final label = tester.getRect(find.text('Design'));

          // The step's height — the subtle line is drawn inside the box,
          // so it does not add to it.
          expect(box.height, expectedHeight[size]);
          // Vertically centred: the space above the label equals the space
          // below it (stack-alignment — the Web twin's `items-center`).
          expect(
            label.top - box.top,
            moreOrLessEquals(box.bottom - label.bottom, epsilon: 0.01),
          );
          expect(label.height, lessThan(box.height));
          // Horizontal padding is the step's, plus the line when drawn.
          final line = emphasis == CoreTagEmphasis.subtle ? 1.0 : 0.0;
          expect(
            label.left - box.left,
            moreOrLessEquals(expectedPadding[size]! + line, epsilon: 0.01),
          );
          expect(
            _decoration(tester).borderRadius,
            BorderRadius.circular(expectedRadius[size]!),
          );
        });
      }
    }

    testWidgets('as wide as its label, not the row', (tester) async {
      await _pumpTag(tester, const Tag(child: Text('A')));
      final box = tester.getRect(_box());
      expect(box.width, lessThan(100));
    });
  });

  group('border', () {
    testWidgets('subtle draws a 1px line in the hue outline', (tester) async {
      await _pumpTag(
        tester,
        const Tag(color: CoreCategoryColor.blue, child: Text('Design')),
      );
      final context = tester.element(find.byType(Tag));
      final scheme = Theme.of(context).colorScheme;
      final border = _decoration(tester).border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.categoryBlueOutline))
            .toValue(),
      );
    });

    testWidgets('bold draws no line', (tester) async {
      await _pumpTag(
        tester,
        const Tag(
          color: CoreCategoryColor.blue,
          emphasis: CoreTagEmphasis.bold,
          child: Text('Design'),
        ),
      );
      expect(_decoration(tester).border, isNull);
    });
  });

  group('colours and label', () {
    for (final hue in CoreCategoryColor.values) {
      testWidgets('${hue.name} — fill and label colour per emphasis', (
        tester,
      ) async {
        for (final emphasis in CoreTagEmphasis.values) {
          await _pumpTag(
            tester,
            Tag(color: hue, emphasis: emphasis, child: const Text('Label')),
          );
          final scheme = Theme.of(tester.element(find.byType(Tag))).colorScheme;
          final expected = CoreTagStyle.resting(hue, emphasis);
          expect(
            _decoration(tester).color,
            scheme.resolve(expected.backgroundColor!).toValue(),
          );
          expect(
            _paintedLabelStyle(tester, 'Label').color,
            scheme.resolve(expected.foregroundColor!).toValue(),
          );
        }
      });
    }

    testWidgets('subtle keeps the role weight, bold sets 600', (tester) async {
      await _pumpTag(tester, const Tag(child: Text('Label')));
      expect(_paintedLabelStyle(tester, 'Label').fontWeight, FontWeight.w500);

      await _pumpTag(
        tester,
        const Tag(emphasis: CoreTagEmphasis.bold, child: Text('Label')),
      );
      expect(_paintedLabelStyle(tester, 'Label').fontWeight, FontWeight.w600);
    });

    testWidgets('the label is set at the step role', (tester) async {
      await _pumpTag(
        tester,
        const Tag(size: CoreTagSize.sm, child: Text('Label')),
      );
      final theme = Theme.of(tester.element(find.byType(Tag)));
      final role = const CoreTextStyle.token(
        CoreTextStyles.labelXs,
      ).toValue(theme: theme);
      expect(_paintedLabelStyle(tester, 'Label').fontSize, role.fontSize);
    });
  });

  group('display only', () {
    testWidgets('takes no focus and handles no gesture', (tester) async {
      await _pumpTag(tester, const Tag(child: Text('Design')));
      expect(
        find.descendant(of: find.byType(Tag), matching: find.byType(Focus)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(Tag),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Tag), matching: find.byType(Clickable)),
        findsNothing,
      );
    });
  });

  group('overrides', () {
    testWidgets('the theme colour row and the instance style both reach the '
        'box, instance last', (tester) async {
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          tag: CoreTagTheme(
            style: CoreTagStyle(minHeight: 28),
            colorStyles: {
              CoreCategoryColor.red: CoreTagStyle(
                backgroundColor: CoreColor(0xFF112233),
              ),
            },
            emphasisStyles: {
              CoreTagEmphasis.subtle: CoreTagStyle(
                borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
              ),
            },
          ),
        ),
      );
      await _pumpTag(
        tester,
        const Tag(
          color: CoreCategoryColor.red,
          tagStyle: CoreTagStyle(minHeight: 30),
          child: Text('Design'),
        ),
        theme: theme,
      );
      expect(tester.getRect(_box()).height, 30);
      expect(_decoration(tester).color, const Color(0xFF112233));
      expect(
        _decoration(tester).borderRadius,
        BorderRadius.circular(CoreRadius.radius2),
      );
    });

    testWidgets('withStyle merges a patch into tagStyle', (tester) async {
      const base = Tag(
        tagStyle: CoreTagStyle(minHeight: 30),
        child: Text('Design'),
      );
      final chained = base.withStyle(
        const CoreTagStyle(borderRadius: CoreBorderRadius.all(2)),
      );
      expect(chained.tagStyle!.minHeight, 30);
      expect(chained.tagStyle!.borderRadius, const CoreBorderRadius.all(2));
    });
  });
}
