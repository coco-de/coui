// The deprecated flat option fields are exercised on purpose: this file
// pins that they still reach the composed chip.
// ignore_for_file: deprecated_member_use

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
);

const List<CoreMultipleChoiceOption<String>> _kOptions = [
  (value: 'a', label: 'Apple'),
  (value: 'b', label: 'Banana'),
];

void main() {
  group('MultipleChoice widget', () {
    testWidgets('renders the option labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (_) {},
            options: _kOptions,
          ),
        ),
      );

      expect(find.byType(MultipleChoice<String>), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-multiple-choice');

      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            key: testKey,
            onChanged: (_) {},
            options: _kOptions,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls onChanged when an option is selected', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (value) {
              changedValue = value;
            },
            options: _kOptions,
          ),
        ),
      );

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(changedValue, equals('b'));
    });

    testWidgets('does not call onChanged when disabled', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            enabled: false,
            onChanged: (value) {
              changedValue = value;
            },
            options: _kOptions,
          ),
        ),
      );

      await tester.tap(find.text('Apple'));
      await tester.pump();

      expect(changedValue, isNull);
    });

    testWidgets('reflects the initial value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (_) {},
            value: 'a',
            options: _kOptions,
          ),
        ),
      );

      expect(find.byType(MultipleChoice<String>), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });
  });

  group('MultipleChoice composes Chip', () {
    Finder chips() => find.byType(Chip);

    OutlinedContainer boxOf(WidgetTester tester, int index) =>
        tester.widget<OutlinedContainer>(
          find.descendant(
            of: chips().at(index),
            matching: find.byType(OutlinedContainer),
          ),
        );

    testWidgets('every option is a Chip — neutral resting, primary selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (_) {},
            value: 'b',
            options: _kOptions,
          ),
        ),
      );

      expect(chips(), findsNWidgets(2));
      final first = tester.widget<Chip>(chips().at(0));
      final second = tester.widget<Chip>(chips().at(1));
      expect(first.selected, isFalse);
      expect(second.selected, isTrue);
      expect(first.variant, CoreChipVariant.outlined);
      expect(second.chipColor, CoreChipColor.primary);
      // 선택 칩은 primary · low, 미선택 칩은 neutral · outlined · low.
      expect(second.variant, CoreChipVariant.outlined);
      expect(second.emphasis, CoreChipEmphasis.low);
      expect(first.chipColor, CoreChipColor.neutral);
      expect(first.emphasis, CoreChipEmphasis.low);
      expect(first.label, 'Apple');
      // The option draws no box of its own: the only box is the Chip's.
      expect(find.byType(OutlinedContainer), findsNWidgets(2));
    });

    testWidgets('a resting option paints as a standalone neutral · low chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Column(
            children: [
              MultipleChoice<String>(
                onChanged: (_) {},
                value: 'b',
                options: _kOptions,
              ),
              const Chip(
                label: 'Ref',
                chipColor: CoreChipColor.neutral,
                emphasis: CoreChipEmphasis.low,
              ),
            ],
          ),
        ),
      );
      final resting = tester
          .widget<OutlinedContainer>(
            find.descendant(
              of: chips().at(0),
              matching: find.byType(OutlinedContainer),
            ),
          )
          .containerStyle;
      final reference = tester
          .widget<OutlinedContainer>(
            find.descendant(
              of: chips().at(2),
              matching: find.byType(OutlinedContainer),
            ),
          )
          .containerStyle;
      expect(resting?.backgroundColor, reference?.backgroundColor);
      expect(resting?.borderColor, reference?.borderColor);
      expect(resting?.borderWidth, reference?.borderWidth);
    });

    testWidgets('options are 32 tall and 8 apart', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(onChanged: (_) {}, options: _kOptions),
        ),
      );

      expect(tester.getSize(chips().at(0)).height, 32);
      expect(tester.getSize(chips().at(1)).height, 32);
      final gap =
          tester.getTopLeft(chips().at(1)).dx -
          tester.getTopRight(chips().at(0)).dx;
      expect(gap, 8);
    });

    testWidgets('tapping a chip selects its option', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (v) => changed = v,
            options: _kOptions,
          ),
        ),
      );
      await tester.tap(chips().at(1));
      await tester.pump();
      expect(changed, 'b');
    });

    testWidgets('a disabled group disables its chips', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            enabled: false,
            onChanged: (_) {},
            options: _kOptions,
          ),
        ),
      );
      expect(tester.widget<Chip>(chips().at(0)).enabled, isFalse);
      expect(tester.widget<Chip>(chips().at(0)).onTap, isNull);
    });

    testWidgets('chipStyle reaches the painted chip box', (tester) async {
      const fill = CoreColor(0xFF123456);
      await tester.pumpWidget(
        _buildApp(
          MultipleChoice<String>(
            onChanged: (_) {},
            value: 'a',
            options: _kOptions,
            multipleChoiceStyle: const CoreMultipleChoiceStyle(
              chipStyle: CoreChipStyle(backgroundColor: fill),
            ),
          ),
        ),
      );
      expect(boxOf(tester, 0).containerStyle?.backgroundColor, fill);
      // …and the 32 row survives a chip override that does not state it.
      expect(tester.getSize(chips().at(0)).height, 32);
    });

    testWidgets(
      'deprecated flat fields still reach the painted chip box',
      (tester) async {
        const selectedFill = CoreColor(0xFFAA0000);
        const restingFill = CoreColor(0xFF00AA00);
        await tester.pumpWidget(
          _buildApp(
            MultipleChoice<String>(
              onChanged: (_) {},
              value: 'a',
              options: _kOptions,
              multipleChoiceStyle: const CoreMultipleChoiceStyle(
                selectedBackgroundColor: selectedFill,
                unselectedBackgroundColor: restingFill,
                optionBorderWidth: 3,
              ),
            ),
          ),
        );
        expect(boxOf(tester, 0).containerStyle?.backgroundColor, selectedFill);
        expect(boxOf(tester, 1).containerStyle?.backgroundColor, restingFill);
        expect(boxOf(tester, 0).containerStyle?.borderWidth, 3);
      },
    );

    testWidgets('the resolver hands the chip a raw partial style', (
      tester,
    ) async {
      late ResolvedMultipleChoice resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: Builder(
              builder: (context) {
                resolved = resolveMultipleChoice(context, enabled: true);
                return const material.SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(
        resolved.selectedChipStyle,
        CoreMultipleChoiceStyle.defaultChipStyle,
      );
      expect(
        resolved.unselectedChipStyle,
        CoreMultipleChoiceStyle.defaultChipStyle,
      );
    });
  });
}
