import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(
  Widget child, {
  double width = 640,
  double scaling = 1,
}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(scaling: scaling),
    child: material.Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

Finder _button(String name) => find.byKey(ValueKey<String>('richEditor.$name'));

/// The toolbar the app Figma layouts below were drawn with — the twelve icon
/// buttons, headings first, that an app lists itself.
const List<List<CoreRichEditorFormat>> _kAppToolbar = [
  [
    CoreRichEditorFormat.heading1,
    CoreRichEditorFormat.heading2,
    CoreRichEditorFormat.heading3,
  ],
  [
    CoreRichEditorFormat.bold,
    CoreRichEditorFormat.italic,
    CoreRichEditorFormat.strikethrough,
    CoreRichEditorFormat.code,
    CoreRichEditorFormat.link,
  ],
  [
    CoreRichEditorFormat.bulletedList,
    CoreRichEditorFormat.numberedList,
    CoreRichEditorFormat.taskList,
  ],
  [CoreRichEditorFormat.quote],
];

/// The `Divider`s of the editor: the line under the toolbar, then the lines
/// between its groups.
Finder get _dividers => find.descendant(
  of: find.byType(RichEditor),
  matching: find.byType(Divider),
);

void main() {
  group('RichEditor toolbar inside the field', () {
    testWidgets('sits at the top of the box, inside its border', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(RichEditor));
      final first = tester.getRect(_button('blockType'));
      // The border (1) and the toolbar's inset (12 on the start side, 4
      // above) — the block-type label starts 12 in.
      expect(first.left - box.left, 1 + 12);
      expect(first.top - box.top, 1 + 4);
      // Every button is inside the box; the toolbar is not above it.
      for (final format in CoreRichEditorFormat.values) {
        final finder = _button(format.name);
        if (finder.evaluate().isEmpty) continue;
        expect(
          box.contains(tester.getCenter(finder)),
          isTrue,
          reason: format.name,
        );
      }
    });

    testWidgets('the focus ring wraps the toolbar and the body together', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(RichEditor));
      // Every toolbar button has an outline of its own; the editor's is the
      // outermost one around the first of them.
      final ring = tester.getRect(
        find
            .ancestor(
              of: _button('blockType'),
              matching: find.byType(FocusOutline),
            )
            .last,
      );
      // The outline is the whole box — toolbar strip included — not just the
      // editing area under it.
      expect(ring, box);
      expect(ring.contains(tester.getCenter(_button('blockType'))), isTrue);
    });

    testWidgets('the toolbar stays at the top while a long body scrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            initialValue: [
              for (var i = 0; i < 60; i++) 'Paragraph $i',
            ].join('\n\n'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(RichEditor));
      final before = tester.getTopLeft(_button('blockType'));
      // The box grows to the editing area's `maxHeight` (240) and no further:
      // border 1 + strip 40 + rule 1 + area 240 + border 1.
      expect(box.height, 1 + 40 + 1 + 240 + 1);

      final scrollable = find
          .descendant(
            of: find.byType(RichEditor),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
        reason: 'the body scrolled',
      );
      expect(tester.getTopLeft(_button('blockType')), before);
      expect(tester.getRect(find.byType(RichEditor)), box);
    });

    testWidgets(
      'a line under the toolbar and one between each pair of groups',
      (
        tester,
      ) async {
        await tester.pumpWidget(_buildApp(const RichEditor()));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byType(RichEditor));
        // One horizontal rule and three vertical ones — four groups.
        expect(_dividers, findsNWidgets(4));
        final rects = [
          for (final element in _dividers.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ];
        final rule = rects.singleWhere((r) => r.width > r.height);
        final lines = rects.where((r) => r.height > r.width).toList();
        expect(lines, hasLength(3));
        expect(rule.top - box.top, 1 + 4 + 32 + 4, reason: 'under the strip');
        expect(rule.height, 1);
        expect(
          rule.left - box.left,
          1,
          reason: 'edge to edge inside the border',
        );
        // The lines between groups: 20 long, 1 wide, centred on the buttons.
        final blockType = tester.getRect(_button('blockType'));
        for (final line in lines) {
          expect(line.height, 20);
          expect(line.width, 1);
          expect(line.center.dy, blockType.center.dy);
        }
        // Each line stands a gap of 8 after the group before it and a gap of 8
        // before the group after it.
        lines.sort((a, b) => a.left.compareTo(b.left));
        final ends = [
          blockType.right,
          tester.getRect(_button('link')).right,
          tester.getRect(_button('taskList')).right,
        ];
        final starts = [
          tester.getRect(_button('bold')).left,
          tester.getRect(_button('bulletedList')).left,
          tester.getRect(_button('quote')).left,
        ];
        for (var i = 0; i < 3; i++) {
          expect(lines[i].left - ends[i], 8, reason: 'line $i');
          expect(starts[i] - lines[i].right, 8, reason: 'line $i');
        }
      },
    );

    testWidgets('the strip is filled, and the fill stops at the corners', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor()));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(RichEditor));
      final resolved = resolveRichEditor(context);
      final strip = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: _button('blockType'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        strip.color,
        Theme.of(context).colorScheme.surfaceContainer.toValue(),
      );
      expect(strip.color, resolved.toolbarBackgroundColor);
      expect(strip.color.a, 1);
    });

    testWidgets('a disabled editor draws no strip fill and a lighter rule', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor(enabled: false)));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(RichEditor));
      final resolved = resolveRichEditor(context, enabled: false);
      expect(resolved.toolbarBackgroundColor.a, 0);
      expect(
        resolved.toolbarDividerStyle.color,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        resolveRichEditor(context).toolbarDividerStyle.color,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      final strip = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: _button('blockType'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(strip.color.a, 0);
      // Only the line under the strip follows the editor into the disabled
      // outline; the three lines between groups keep the `Divider`'s own colour
      // — as in the designer's disabled frame (#5951), where they stay
      // `outline-variant`.
      expect(resolved.toolbarGroupDividerStyle.color, isNull);
      final dividers = tester.widgetList<Divider>(_dividers).toList();
      final vertical = dividers.where(
        (d) => d.orientation == CoreDividerOrientation.vertical,
      );
      final horizontal = dividers.where(
        (d) => d.orientation != CoreDividerOrientation.vertical,
      );
      expect(vertical, hasLength(3));
      for (final line in vertical) {
        expect(line.dividerStyle?.color, isNull);
      }
      expect(
        horizontal.single.dividerStyle?.color,
        const CoreColor.token(CoreColors.disabledOutline),
      );
    });

    testWidgets('a divider colour stated on the style wins in every state', (
      tester,
    ) async {
      const red = CoreColor(0xFFFF0000);
      await tester.pumpWidget(
        _buildApp(
          const RichEditor(
            enabled: false,
            richEditorStyle: CoreRichEditorStyle(
              toolbarDividerStyle: CoreDividerStyle(color: red),
            ),
          ),
        ),
      );
      final context = tester.element(find.byType(RichEditor));
      final resolved = resolveRichEditor(
        context,
        enabled: false,
        richEditorStyle: const CoreRichEditorStyle(
          toolbarDividerStyle: CoreDividerStyle(color: red),
        ),
      );
      expect(resolved.toolbarDividerStyle.color, red);
      expect(resolved.toolbarGroupDividerStyle.color, red);
    });

    testWidgets('without the toolbar the box has no strip and no rule', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const RichEditor(showToolbar: false)));
      await tester.pumpAndSettle();
      expect(_dividers, findsNothing);
      expect(_button('bold'), findsNothing);
    });

    testWidgets('a group divider length of 0 draws no lines between groups', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const RichEditor(
            richEditorStyle: CoreRichEditorStyle(toolbarGroupDividerHeight: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The rule under the toolbar stays; the groups sit a gap apart.
      expect(_dividers, findsNWidgets(1));
      expect(
        tester.getRect(_button('bold')).left -
            tester.getRect(_button('blockType')).right,
        8,
      );
    });

    testWidgets('the image button joins the quote in the last group', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            onImageUpload: (file) async => 'x',
            onImageDelete: (url) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Beside the quote, 2 apart — the last group is `[quote, image]`.
      expect(
        tester.getRect(_button('image')).left -
            tester.getRect(_button('quote')).right,
        2,
      );
      // Still four groups, so still three lines between them.
      expect(_dividers, findsNWidgets(4));
    });

    testWidgets('a press on the trailing control does not focus the editor', (
      tester,
    ) async {
      final key = GlobalKey<RichEditorState>();
      var pressed = 0;
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            key: key,
            toolbarTrailing: material.GestureDetector(
              key: const ValueKey('trailing'),
              behavior: HitTestBehavior.opaque,
              onTap: () => pressed++,
              child: const SizedBox(width: 80, height: 20),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trailing')));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(key.currentState!.focusNode.hasFocus, isFalse);
    });

    testWidgets('the trailing control sits at the right end, or wraps below', (
      tester,
    ) async {
      Future<(Rect, Rect, Rect)> rects(double width) async {
        await tester.pumpWidget(
          _buildApp(
            const RichEditor(
              toolbarTrailing: SizedBox(
                key: ValueKey('trailing'),
                width: 80,
                height: 20,
              ),
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();
        return (
          tester.getRect(find.byType(RichEditor)),
          tester.getRect(_button('quote')),
          tester.getRect(find.byKey(const ValueKey('trailing'))),
        );
      }

      // Wide: the control fits beside the buttons and is pushed to the right
      // end (inside the 1 border and the 8 inset on the end side).
      final (wideBox, wideQuote, wideTrailing) = await rects(640);
      expect(wideTrailing.right, wideBox.right - 1 - 8);
      expect(wideTrailing.center.dy, wideQuote.center.dy);

      // Narrow: no room beside the buttons — a row of its own, at the start
      // (the 12 inset), 4 under the buttons.
      final (narrowBox, narrowQuote, narrowTrailing) = await rects(400);
      expect(narrowTrailing.left, narrowBox.left + 1 + 12);
      expect(narrowTrailing.top, greaterThan(narrowQuote.bottom));
      expect(narrowTrailing.top - narrowQuote.bottom, 4);
    });
  });

  // The app Figma's toolbar (Figma 6yq0C3oSVVR2HdaOe807eB, SH-A11 新 버전 작성):
  // the 12 icon buttons (424 wide), an app control 103 × 21, in a strip padded
  // 12 at the sides and 8 above and below. At 1440 the strip is 700 wide and
  // the control stands at its right end on the buttons' row (x 585, y 13.5); at
  // 1024 it is 500 wide inside and the control wraps to a row of its own at the
  // start, 4 under the buttons (x 12, y 44).
  group(
    'RichEditorToolbar with a trailing control — the app Figma layouts',
    () {
      Future<(Offset, Offset)> place(
        WidgetTester tester, {
        required double width,
      }) async {
        final controller = RichEditorController(markdown: 'hello');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _buildApp(
            Padding(
              key: const ValueKey('strip'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: RichEditorToolbar(
                controller: controller,
                toolbar: _kAppToolbar,
                onFormat: (_) => true,
                trailing: const SizedBox(
                  key: ValueKey('checkbox'),
                  width: 103,
                  height: 21,
                ),
              ),
            ),
            width: width,
          ),
        );
        await tester.pumpAndSettle();
        final origin = tester.getTopLeft(find.byKey(const ValueKey('strip')));
        return (
          tester.getTopLeft(find.byKey(const ValueKey('checkbox'))) - origin,
          tester.getTopLeft(
                find.byKey(const ValueKey('richEditorToolbar.heading1')),
              ) -
              origin,
        );
      }

      testWidgets('1440: the control ends the buttons row (x 585, y 13.5)', (
        tester,
      ) async {
        final (checkbox, buttons) = await place(tester, width: 700);
        expect(buttons, const Offset(12, 8));
        expect(checkbox, const Offset(585, 13.5));
      });

      testWidgets('1024: the control wraps under the buttons (x 12, y 44)', (
        tester,
      ) async {
        final (checkbox, buttons) = await place(tester, width: 524);
        expect(buttons, const Offset(12, 8));
        expect(checkbox, const Offset(12, 44));
      });
    },
  );

  // The same two Figma layouts with only what v0.177.1 already ships: the app
  // lays `RichEditorToolbar` and its own control out in a `Wrap`.
  group('RichEditorToolbar inside an app Wrap — the released API', () {
    Future<Offset> checkboxAt(
      WidgetTester tester, {
      required double width,
    }) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          Padding(
            key: const ValueKey('strip'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                RichEditorToolbar(
                  controller: controller,
                  toolbar: _kAppToolbar,
                  onFormat: (_) => true,
                ),
                const SizedBox(
                  key: ValueKey('checkbox'),
                  width: 103,
                  height: 21,
                ),
              ],
            ),
          ),
          width: width,
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(const ValueKey('checkbox'))) -
          tester.getTopLeft(find.byKey(const ValueKey('strip')));
    }

    testWidgets('1440 (strip 700): the control ends the buttons row', (
      tester,
    ) async {
      expect(await checkboxAt(tester, width: 700), const Offset(585, 13.5));
    });

    testWidgets('1024 (strip 524): the control wraps under the buttons', (
      tester,
    ) async {
      expect(await checkboxAt(tester, width: 524), const Offset(12, 44));
    });
  });
}
