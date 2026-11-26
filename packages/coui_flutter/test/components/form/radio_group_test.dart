import 'dart:ui' show CheckedState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('RadioGroupController', () {
    test('initializes with null by default', () {
      final controller = RadioGroupController<String>();
      expect(controller.value, isNull);
      controller.dispose();
    });

    test('initializes with provided value', () {
      final controller = RadioGroupController('option1');
      expect(controller.value, equals('option1'));
      controller.dispose();
    });

    test('value can be updated', () {
      final controller = RadioGroupController('option1');
      controller.value = 'option2';
      expect(controller.value, equals('option2'));
      controller.dispose();
    });
  });

  group('RadioGroup widget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'option1',
            options: const [
              (value: 'option1', label: 'Option 1'),
              (value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RadioGroup<String>), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('radio-group-key');

      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            key: testKey,
            onChanged: (_) {},
            value: null,
            options: const [(value: 'a', label: 'A')],
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls onChanged when an option is tapped', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (value) {
              selectedValue = value;
            },
            value: null,
            options: const [
              (value: 'optionA', label: 'Option A'),
              (value: 'optionB', label: 'Option B'),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Option A'));
      final _ = await tester.pumpAndSettle();

      expect(selectedValue, equals('optionA'));
    });

    testWidgets('renders options with labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            options: const [
              (value: 'a', label: 'Alpha'),
              (value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('initialValue sets starting selection', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            initialValue: 'x',
            options: const [
              (value: 'x', label: 'X'),
              (value: 'y', label: 'Y'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RadioGroup<String>), findsOneWidget);
    });

    // The dot is a decorative circle drawn at a stated side — the halo is a
    // circle too but takes its box from `Position`, and the ring's own
    // `AnimatedContainer` is a rounded rectangle.
    Finder dotFinder() => find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
          w.constraints != null,
    );

    // The ring is the `AnimatedContainer` that carries a border.
    Finder ringFinder() => find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).border != null,
    );

    List<double> ringWidths(WidgetTester tester) => [
      for (final w in tester.widgetList<AnimatedContainer>(ringFinder()))
        ((w.decoration! as BoxDecoration).border! as Border).top.width,
    ];

    List<Color> ringColors(WidgetTester tester) => [
      for (final w in tester.widgetList<AnimatedContainer>(ringFinder()))
        ((w.decoration! as BoxDecoration).border! as Border).top.color,
    ];

    List<Color?> ringFills(WidgetTester tester) => [
      for (final w in tester.widgetList<AnimatedContainer>(ringFinder()))
        (w.decoration! as BoxDecoration).color,
    ];

    // The selection is the ring, not a dot. A selected ring is heavier than a
    // resting one and the hole stays open.
    testWidgets('the selection is a heavier ring with no dot by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // `md`: resting ring is the 1 px line, selected is 4.
      expect(
        ringWidths(tester),
        [
          CoreRadioGroupStyle
              .defaultsBySize[CoreComponentSize.md]!
              .selectedIndicatorBorderWidth,
          CoreRadioGroupStyle
              .defaultsBySize[CoreComponentSize.md]!
              .indicatorBorderWidth,
        ],
      );
      expect(ringWidths(tester), [
        CoreStrokeWidth.stroke4,
        CoreStrokeWidth.stroke1,
      ]);
      // Neither radio draws a dot: both dot boxes are zero-sized.
      expect(dotFinder(), findsNWidgets(2));
      for (final dot in tester.widgetList<AnimatedContainer>(dotFinder())) {
        expect(dot.constraints!.maxWidth, 0);
        expect(dot.constraints!.maxHeight, 0);
      }
    });

    testWidgets('the selected width follows the size ladder, every size', (
      tester,
    ) async {
      Future<List<double>> widthsAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            RadioGroup<String>(
              onChanged: (_) {},
              value: 'a',
              size: size,
              options: const [
                (value: 'a', label: 'A'),
                (value: 'b', label: 'B'),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return ringWidths(tester);
      }

      expect(await widthsAt(.xs), [CoreStrokeWidth.stroke3, 1]);
      expect(await widthsAt(.sm), [CoreStrokeWidth.stroke4, 1]);
      expect(await widthsAt(.md), [CoreStrokeWidth.stroke4, 1]);
      expect(await widthsAt(.xl2), [CoreStrokeWidth.stroke6, 1]);
      expect(await widthsAt(.lg), [CoreStrokeWidth.stroke5, 1]);
      expect(await widthsAt(.xl), [CoreStrokeWidth.stroke5, 1]);
    });

    testWidgets('restating the resting width leaves the selected ring alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            radioGroupStyle: const CoreRadioGroupStyle(
              indicatorBorderWidth: CoreStrokeWidth.stroke3,
            ),
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(ringWidths(tester), [
        CoreStrokeWidth.stroke4,
        CoreStrokeWidth.stroke3,
      ]);

      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            radioGroupStyle: const CoreRadioGroupStyle(
              selectedIndicatorBorderWidth: CoreStrokeWidth.stroke6,
            ),
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(ringWidths(tester), [
        CoreStrokeWidth.stroke6,
        CoreStrokeWidth.stroke1,
      ]);
    });

    // A ring with a dot in its hole is stated: the dot size and the selected
    // width. Only the selected radio's dot has a size.
    testWidgets('a restated innerDotSize draws the dot for the selected one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            radioGroupStyle: const CoreRadioGroupStyle(
              innerDotSize: CoreSize.size8,
              selectedIndicatorBorderWidth: CoreStrokeWidth.stroke1_5,
            ),
            options: const [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final dots = tester
          .widgetList<AnimatedContainer>(dotFinder())
          .map((d) => d.constraints!.maxWidth)
          .toList();
      expect(dots, [8, 0]);
      expect(ringWidths(tester), [1.5, 1]);
    });

    // A disabled *selected* radio draws its dot in the disabled-content
    // colour, apart from the fill — read back off the painted widgets, not
    // the tokens. The dot is not drawn by default, so it is stated here to
    // read its colour.
    testWidgets('a disabled selected radio keeps a restated dot findable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const RadioGroup<String>(
            value: 'a',
            enabled: false,
            radioGroupStyle: CoreRadioGroupStyle(innerDotSize: CoreSize.size8),
            options: [(value: 'a', label: 'A')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final dot = tester.widget<AnimatedContainer>(dotFinder());
      expect(dot.constraints!.maxWidth, 8);
      final dotColor = (dot.decoration! as BoxDecoration).color!;
      final theme = Theme.of(tester.element(find.byType(RadioGroup<String>)));
      final expectedDot = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.disabledContent))
          .toValue();
      final expectedFill = theme.colorScheme
          .resolve(const CoreColor.token(CoreColors.disabledContainer))
          .toValue();
      expect(dotColor, expectedDot);
      expect(dotColor, isNot(expectedFill));
      // The selection is the ring, so a disabled selected ring keeps the
      // selected width — a restated dot does not change that.
      expect(ringWidths(tester), [CoreStrokeWidth.stroke4]);
    });

    // The dot is not drawn by default, so a disabled selected radio is told
    // from a disabled unselected one by its ring alone: the selected width
    // in the disabled-content colour, against the resting width in the
    // disabled-outline colour. Read off the painted widgets.
    testWidgets('a disabled selected ring is the selected width in '
        'disabledContent; an unselected one rests on disabledOutline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const RadioGroup<String>(
            value: 'a',
            enabled: false,
            options: [
              (value: 'a', label: 'A'),
              (value: 'b', label: 'B'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(RadioGroup<String>)));
      Color of(CoreColorToken token) =>
          theme.colorScheme.resolve(CoreColor.token(token)).toValue();

      // [selected, unselected]: width, colour, and the shared fill.
      expect(ringWidths(tester), [
        CoreStrokeWidth.stroke4,
        CoreStrokeWidth.stroke1,
      ]);
      expect(ringColors(tester), [
        of(CoreColors.disabledContent),
        of(CoreColors.disabledOutline),
      ]);
      expect(ringFills(tester), [
        of(CoreColors.disabledContainer),
        of(CoreColors.disabledContainer),
      ]);
      // The negative control: the two disabled rings must differ, or the
      // selection has no mark at all with the dot gone.
      expect(ringColors(tester).first, isNot(ringColors(tester).last));
      // No dot is drawn.
      for (final dot in tester.widgetList<AnimatedContainer>(dotFinder())) {
        expect(dot.constraints!.maxWidth, 0);
      }
    });

    testWidgets('the disabled selected width follows the size ladder', (
      tester,
    ) async {
      Future<List<double>> widthsAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            RadioGroup<String>(
              value: 'a',
              enabled: false,
              size: size,
              options: const [
                (value: 'a', label: 'A'),
                (value: 'b', label: 'B'),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return ringWidths(tester);
      }

      expect(await widthsAt(.xs), [CoreStrokeWidth.stroke3, 1]);
      expect(await widthsAt(.md), [CoreStrokeWidth.stroke4, 1]);
      expect(await widthsAt(.xl2), [CoreStrokeWidth.stroke6, 1]);
    });

    // The label steps with the ring — Button's ladder: 12 / 13 / 14, then
    // 16 from lg up. A label that stayed at 14 while the ring grew was the
    // pre-redesign state.
    testWidgets('label fontSize follows the size ladder', (tester) async {
      Future<double?> fontSizeAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            RadioGroup<String>(
              onChanged: (_) {},
              value: 'a',
              size: size,
              options: const [(value: 'a', label: 'Alpha')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return tester.widget<Text>(find.text('Alpha')).style?.fontSize;
      }

      expect(await fontSizeAt(.xs), CoreFontSize.s12);
      expect(await fontSizeAt(.sm), CoreFontSize.s13);
      expect(await fontSizeAt(.md), CoreFontSize.s14);
      expect(await fontSizeAt(.lg), CoreFontSize.s16);
      expect(await fontSizeAt(.xl), CoreFontSize.s16);
      expect(await fontSizeAt(.xl2), CoreFontSize.s16);
      final weight = tester.widget<Text>(find.text('Alpha')).style?.fontWeight;
      expect(weight, FontWeight.w400);
    });

    // Hover DETECTION is the row's — a pointer resting on the LABEL raises
    // the halo around the ring at the ramp's hover weight.
    testWidgets('hovering the label raises the halo around the ring', (
      tester,
    ) async {
      // A mouse connected BEFORE the first frame — `FocusableActionDetector`
      // snapshots the highlight mode in its first post-frame callback and a
      // later pointer never re-triggers it (see chip_hover_engage_test).
      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            options: const [(value: 'a', label: 'Alpha')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      Color haloColor() {
        // The halo is the circle positioned around the ring — the only
        // `AnimatedContainer` circle with no side of its own.
        final halo = tester.widget<AnimatedContainer>(
          find.byWidgetPredicate(
            (w) =>
                w is AnimatedContainer &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
                w.constraints == null,
          ),
        );
        return (halo.decoration! as BoxDecoration).color!;
      }

      // The row sits at the origin, so park the pointer well away first.
      await gesture.moveTo(const Offset(400, 400));
      final _ = await tester.pumpAndSettle();
      expect(haloColor().a, 0);

      await gesture.moveTo(tester.getCenter(find.text('Alpha')));
      final _ = await tester.pumpAndSettle();

      expect(
        haloColor().a,
        closeTo(CoreRadioGroupStyle.defaultStateLayer.hover, 0.01),
      );

      await gesture.moveTo(const Offset(400, 400));
      final _ = await tester.pumpAndSettle();
      expect(haloColor().a, 0);
    });

    testWidgets('works with a controller', (tester) async {
      final controller = RadioGroupController('x');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            controller: controller,
            options: const [
              (value: 'x', label: 'X'),
              (value: 'y', label: 'Y'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(RadioGroup<String>), findsOneWidget);
    });
  });

  // A radio outside any [RadioGroup] — one tile of a card-style choice, or a
  // set the caller lays out itself. The Web radio has always taken these
  // parameters; the Flutter one asserted it sat in a group.
  group('Radio on its own', () {
    SemanticsData semanticsOf(WidgetTester tester, Finder radio) => tester
        .getSemantics(
          find.descendant(of: radio, matching: find.byType(Clickable)),
        )
        .getSemanticsData();

    testWidgets('renders outside a RadioGroup', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Radio<String>(value: 'a', groupValue: 'a', onChanged: (_) {}),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Radio<String>), findsOneWidget);
    });

    testWidgets('is selected when groupValue equals its value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            mainAxisSize: .min,
            children: [
              Radio<String>(
                key: const Key('a'),
                value: 'a',
                groupValue: 'a',
                label: 'A',
                onChanged: (_) {},
              ),
              Radio<String>(
                key: const Key('b'),
                value: 'b',
                groupValue: 'a',
                label: 'B',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );

      final a = semanticsOf(tester, find.byKey(const Key('a')));
      final b = semanticsOf(tester, find.byKey(const Key('b')));
      expect(a.flagsCollection.isChecked, CheckedState.isTrue);
      expect(b.flagsCollection.isChecked, CheckedState.isFalse);
      expect(a.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      // The row's own text names the node that carries the state.
      expect(a.label, 'A');
      expect(
        a.flagsCollection.isButton,
        isFalse,
        reason: 'A radio should not be announced as a plain button.',
      );
    });

    testWidgets('a tap reports its value through onChanged', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _buildApp(
          Radio<String>(
            value: 'b',
            groupValue: 'a',
            label: 'B',
            onChanged: (v) => picked = v,
          ),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();

      expect(picked, 'b');
    });

    testWidgets('without onChanged it does not respond', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Radio<String>(value: 'b', groupValue: 'a', label: 'B'),
        ),
      );

      await tester.tap(find.text('B'));
      await tester.pump();

      // Still focusable and still announced as an unchecked radio — the Web
      // radio keeps its tab stop and drops only the handlers.
      expect(tester.takeException(), isNull);
      final data = semanticsOf(tester, find.byType(Radio<String>));
      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
    });

    testWidgets('an unselected radio keeps its own tab stop', (tester) async {
      // Outside a group there are no arrow keys to reach a sibling with, so
      // a roving tab stop would leave every unselected radio unreachable —
      // the Web radio keeps `tabindex="0"` here too.
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _buildApp(
          Radio<String>(
            value: 'b',
            groupValue: 'a',
            label: 'B',
            focusNode: node,
            onChanged: (_) {},
          ),
        ),
      );

      expect(node.skipTraversal, isFalse);
    });

    testWidgets('groupVariant card draws the tile', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Radio<String>(
                key: const Key('plain'),
                value: 'a',
                groupValue: 'a',
                label: 'Pick up',
                onChanged: (_) {},
              ),
              Radio<String>(
                key: const Key('card'),
                value: 'a',
                groupValue: 'a',
                groupVariant: .card,
                label: 'Pick up',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );

      // The tile pads the same row on every side, so the card radio is
      // taller and wider than the plain one with the same label.
      final plain = tester.getSize(find.byKey(const Key('plain')));
      final card = tester.getSize(find.byKey(const Key('card')));
      expect(card.height, greaterThan(plain.height));
      expect(card.width, greaterThan(plain.width));
    });

    testWidgets('groupSize picks the size step', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              Radio<String>(
                key: const Key('sm'),
                value: 'a',
                groupValue: 'a',
                groupSize: .sm,
                label: 'A',
                onChanged: (_) {},
              ),
              Radio<String>(
                key: const Key('lg'),
                value: 'a',
                groupValue: 'a',
                groupSize: .lg,
                label: 'A',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );

      final sm = tester.getSize(find.byKey(const Key('sm')));
      final lg = tester.getSize(find.byKey(const Key('lg')));
      expect(lg.width, greaterThan(sm.width));
    });
  });

  group('Radio inside a RadioGroup', () {
    testWidgets('an unselected radio leaves the tab order', (tester) async {
      final a = FocusNode();
      final b = FocusNode();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            value: 'a',
            onChanged: (_) {},
            child: Column(
              mainAxisSize: .min,
              children: [
                Radio<String>(value: 'a', label: 'A', focusNode: a),
                Radio<String>(value: 'b', label: 'B', focusNode: b),
              ],
            ),
          ),
        ),
      );

      expect(a.skipTraversal, isFalse);
      expect(b.skipTraversal, isTrue);
    });

    testWidgets('reports checked on the selected radio only', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            value: 'y',
            onChanged: (_) {},
            options: const [
              (value: 'x', label: 'X'),
              (value: 'y', label: 'Y'),
            ],
          ),
        ),
      );

      SemanticsData radio(String label) => tester
          .getSemantics(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(Clickable),
            ),
          )
          .getSemanticsData();

      expect(radio('X').flagsCollection.isChecked, CheckedState.isFalse);
      expect(radio('Y').flagsCollection.isChecked, CheckedState.isTrue);
    });

    testWidgets('a callback the radio passes wins over the group', (
      tester,
    ) async {
      String? fromGroup;
      String? fromRadio;
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            value: 'x',
            onChanged: (v) => fromGroup = v,
            child: Column(
              mainAxisSize: .min,
              children: [
                const Radio<String>(value: 'x', label: 'X'),
                Radio<String>(
                  value: 'y',
                  label: 'Y',
                  onChanged: (v) => fromRadio = v,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Y'));
      await tester.pump();

      expect(fromRadio, 'y');
      expect(fromGroup, isNull);
    });
  });
}
