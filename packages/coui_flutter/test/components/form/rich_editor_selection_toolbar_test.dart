import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/rich_editor/rich_editor_selection_toolbar.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The editor [width] wide with its top-left corner at ([left], [top]) of an
/// 800 × 600 screen, and a button outside it to take the focus away.
Widget _buildApp(
  Widget child, {
  double left = 240,
  double top = 200,
  double width = 480,
  TextDirection? editorDirection,
}) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Stacks(
        children: [
          Position(
            left: left,
            top: top,
            width: width,
            child: editorDirection == null
                ? child
                : Directionality(textDirection: editorDirection, child: child),
          ),
          Position(
            left: 0,
            bottom: 0,
            child: Button(
              key: const ValueKey<String>('elsewhere'),
              onPressed: () {},
              child: const Text('Elsewhere'),
            ),
          ),
        ],
      ),
    ),
  ),
);

Finder get _toolbar => find.byType(RichEditorSelectionToolbar);

/// The toolbar's panel — the composed `Popup`.
Finder get _panel => find.descendant(
  of: _toolbar,
  matching: find.byType(Popup),
);

Finder _selectionButton(String format) =>
    find.byKey(ValueKey<String>('richEditorSelection.$format'));

Finder _row(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(MenuItem),
);

RichEditorState _editor(WidgetTester tester) =>
    tester.state<RichEditorState>(find.byType(RichEditor));

/// Focuses the editor and selects everything in it.
Future<void> _selectAll(
  WidgetTester tester,
  RichEditorController controller,
) async {
  _editor(tester).focus();
  await tester.pump();
  controller.selectAll();
  await tester.pumpAndSettle();
}

/// The box of the characters `[start, end)` of the document text [text], in
/// global coordinates — measured from the paragraph, not from the editor.
Rect _textBox(WidgetTester tester, String text, int start, int end) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.text(text, findRichText: true),
  );
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  final local = boxes
      .map((box) => box.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return Rect.fromPoints(
    paragraph.localToGlobal(local.topLeft),
    paragraph.localToGlobal(local.bottomRight),
  );
}

/// Focuses the editor and selects the last [count] characters of its text
/// from the keyboard, then waits for the selection to hold still — the
/// toolbar over a keyboard selection waits that long.
Future<void> _selectTail(
  WidgetTester tester,
  RichEditorController controller,
  int count,
) async {
  _editor(tester).focus();
  await tester.pump();
  controller.moveCaretToEnd();
  await tester.pump();
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  for (var i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await _settleKeyboardSelection(tester);
}

/// Lets a selection grown from the keyboard hold still for the toolbar's
/// delay, and the toolbar come up.
Future<void> _settleKeyboardSelection(WidgetTester tester) async {
  await tester.pump(CoreRichEditorContract.selectionToolbarKeyboardDelay);
  await tester.pumpAndSettle();
}

/// Scrolls the editing area of the editor by [dy] with the mouse wheel.
Future<void> _wheel(WidgetTester tester, double dy) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(
    pointer.hover(tester.getCenter(find.byType(RichEditor))),
  );
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pumpAndSettle();
}

/// The bottom edge of the toolbar in the editor's box, in global coordinates.
double _ownToolbarBottom(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('richEditor.bold'))).bottom;

/// Several lines, the last of them `hello world`: a selection of the last
/// line has room above it inside the editing area, so the toolbar sits over
/// it as the design draws it.
const String _kLines = 'one\n\ntwo\n\nthree\n\nhello world';

BoxDecoration _panelDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: _panel, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

Color _token(BuildContext context, CoreColorToken token) => Theme.of(
  context,
).colorScheme.resolve(CoreColor.token(token)).toValue();

void main() {
  group('RichEditor selection toolbar — when it shows', () {
    testWidgets('shows over selected text and goes when it collapses', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);

      // A caret alone brings nothing up.
      _editor(tester).focus();
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);

      controller.selectAll();
      await tester.pumpAndSettle();
      expect(_toolbar, findsOneWidget);

      controller.moveCaretToEnd();
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);
    });

    testWidgets('a selection made from the keyboard brings it up', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      _editor(tester).focus();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await _settleKeyboardSelection(tester);
      expect(controller.hasSelectedText, isTrue);
      expect(_toolbar, findsOneWidget);
    });

    testWidgets('a selection grown from the keyboard waits for it to hold '
        'still, so a held key does not flicker it', (tester) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      _editor(tester).focus();
      await tester.pumpAndSettle();
      controller.moveCaretToEnd();
      await tester.pump();
      const delay = CoreRichEditorContract.selectionToolbarKeyboardDelay;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        // Each press comes within the delay of the one before.
        await tester.pump(delay ~/ 2);
        expect(controller.hasSelectedText, isTrue);
        expect(_toolbar, findsNothing, reason: 'press ${i + 1}: still moving');
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      // Held still for the delay: the toolbar comes up once.
      await tester.pump(delay);
      await tester.pumpAndSettle();
      expect(_toolbar, findsOneWidget);
      // Growing it again from the keyboard takes it away until it holds
      // still again.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      // Its exit plays out well within the delay (`pumpAndSettle` would run
      // the clock past the delay).
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.pump(delay ~/ 4);
      }
      expect(_toolbar, findsNothing);
      await tester.pump(delay);
      await tester.pumpAndSettle();
      expect(_toolbar, findsOneWidget);
      expect(
        CoreRichEditorContract.selectionToolbarKeyboardDelay,
        const Duration(milliseconds: CoreDuration.moderate),
      );
    });

    testWidgets('goes when the selection scrolls out of view, and is back '
        'when it scrolls in again', (tester) async {
      final controller = RichEditorController(
        markdown: [for (var i = 0; i < 30; i++) 'line $i'].join('\n\n'),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller), top: 40),
      );
      await tester.pumpAndSettle();
      // The last line is in view at first — the editor scrolls its text
      // within its height.
      await _selectTail(tester, controller, 7);
      expect(_toolbar, findsOneWidget);
      await _wheel(tester, -600);
      expect(controller.hasSelectedText, isTrue, reason: 'selection kept');
      expect(_toolbar, findsNothing, reason: 'the selection is out of view');
      await _wheel(tester, 600);
      expect(_toolbar, findsOneWidget, reason: 'the selection is back');
    });

    testWidgets('waits for the pointer to come up while a drag selects', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      final text = _textBox(tester, 'hello world', 0, 11);
      final gesture = await tester.startGesture(
        text.centerLeft + const Offset(1, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveTo(text.center);
      await tester.pump();
      await gesture.moveTo(text.centerRight - const Offset(1, 0));
      // The editor scrolls on its own clock while a drag is under way: the
      // frames are pumped by hand.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(controller.hasSelectedText, isTrue);
      expect(_toolbar, findsNothing, reason: 'the pointer is still down');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_toolbar, findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets('does not show without the focus, and goes when it leaves', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      // Selected from code, the editor never focused: nothing shows.
      controller.selectAll();
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);

      await _selectAll(tester, controller);
      expect(_toolbar, findsOneWidget);
      // A press elsewhere on the page takes the focus: the toolbar goes, the
      // selection stays.
      await tester.tap(find.byKey(const ValueKey<String>('elsewhere')));
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);
      expect(controller.hasSelectedText, isTrue);
    });

    testWidgets('showSelectionToolbar: false never shows it', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(controller: controller, showSelectionToolbar: false),
        ),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(controller.hasSelectedText, isTrue);
      expect(_toolbar, findsNothing);
    });

    testWidgets("the default is the contract's, on", (tester) async {
      expect(CoreRichEditorContract.defaultShowSelectionToolbar, isTrue);
      expect(const RichEditor().showSelectionToolbar, isTrue);
    });

    testWidgets('a read-only editor never shows it', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller, readOnly: true)),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(controller.hasSelectedText, isTrue);
      expect(_toolbar, findsNothing);
    });

    testWidgets('a disabled editor never shows it, and closes an open one', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(_toolbar, findsOneWidget);

      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller, enabled: false)),
      );
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);
    });

    testWidgets('an image selected alone is not text', (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      _editor(tester).focus();
      await tester.pumpAndSettle();
      expect(controller.hasSelectedText, isFalse);
      controller.selectAll();
      expect(controller.hasSelectedText, isTrue);
      controller
        ..markdown = ''
        ..selectAll();
      expect(controller.hasSelectedText, isFalse);
    });
  });

  group('RichEditor selection toolbar — where it sits', () {
    testWidgets('centred over the selection, 8 above it', (tester) async {
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      final selected = _textBox(tester, 'hello world', 0, 11);
      final panel = tester.getRect(_panel);
      expect(panel.bottom, moreOrLessEquals(selected.top - 8, epsilon: 0.5));
      expect(
        panel.center.dx,
        moreOrLessEquals(selected.center.dx, epsilon: 0.5),
      );
    });

    testWidgets('below the selection when there is no room above', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      // No toolbar in the box and the box at the top of the screen: the
      // text's first line is some 10 from the edge, less than the panel.
      await tester.pumpWidget(
        _buildApp(
          RichEditor(controller: controller, showToolbar: false),
          top: 0,
        ),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      final selected = _textBox(tester, 'hello world', 0, 11);
      final panel = tester.getRect(_panel);
      expect(selected.top, lessThan(panel.height + 8));
      expect(panel.top, moreOrLessEquals(selected.bottom + 8, epsilon: 0.5));
      expect(
        panel.center.dx,
        moreOrLessEquals(selected.center.dx, epsilon: 0.5),
      );
    });

    testWidgets('a selection on the first line gets the toolbar below it, '
        'clear of the toolbar in the box', (tester) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      // In the middle of the screen: the screen has room above, the editing
      // area under the toolbar in the box has not.
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      final selected = _textBox(tester, 'hello world', 0, 11);
      final panel = tester.getRect(_panel);
      final ownBottom = _ownToolbarBottom(tester);
      expect(selected.top - ownBottom, lessThan(panel.height + 8));
      expect(panel.top, moreOrLessEquals(selected.bottom + 8, epsilon: 0.5));
      expect(panel.top, greaterThan(selected.bottom));
      expect(
        panel.top,
        greaterThan(ownBottom),
        reason: 'the toolbar in the box is not covered',
      );
      expect(
        panel.center.dx,
        moreOrLessEquals(selected.center.dx, epsilon: 0.5),
      );
    });

    testWidgets('a line with room above it inside the editing area keeps '
        'the toolbar above', (tester) async {
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      final selected = _textBox(tester, 'hello world', 0, 11);
      final panel = tester.getRect(_panel);
      expect(panel.bottom, moreOrLessEquals(selected.top - 8, epsilon: 0.5));
      expect(panel.top, greaterThanOrEqualTo(_ownToolbarBottom(tester)));
    });

    testWidgets('moved inwards at the edge of the screen', (tester) async {
      final controller = RichEditorController(markdown: 'one\n\ntwo\n\nhi');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller), left: 0),
      );
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 2);
      final selected = _textBox(tester, 'hi', 0, 2);
      final panel = tester.getRect(_panel);
      // Centred it would start left of the screen; it is held 8 inside.
      expect(selected.center.dx - panel.width / 2, lessThan(0));
      expect(panel.left, moreOrLessEquals(8, epsilon: 0.5));
      expect(panel.bottom, moreOrLessEquals(selected.top - 8, epsilon: 0.5));
    });

    testWidgets('follows the selection as it changes', (tester) async {
      final controller = RichEditorController(markdown: 'hello\n\nworld');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      // Everything, from the first line: below the selection.
      final all = _textBox(tester, 'hello', 0, 5).expandToInclude(
        _textBox(tester, 'world', 0, 5),
      );
      final first = tester.getRect(_panel);
      expect(first.top, moreOrLessEquals(all.bottom + 8, epsilon: 0.5));
      // The second paragraph alone: the toolbar moves over it.
      _editor(tester).focus();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await _settleKeyboardSelection(tester);
      expect(controller.hasSelectedText, isTrue);
      final second = _textBox(tester, 'world', 0, 5);
      final moved = tester.getRect(_panel);
      expect(moved, isNot(first));
      expect(moved.bottom, moreOrLessEquals(second.top - 8, epsilon: 0.5));
      expect(
        moved.center.dx,
        moreOrLessEquals(second.center.dx, epsilon: 0.5),
      );
    });

    testWidgets('follows the editor when the page moves it', (tester) async {
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      final before = tester.getRect(_panel);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller), top: 260, left: 280),
      );
      await tester.pumpAndSettle();
      final after = tester.getRect(_panel);
      expect(after.top, moreOrLessEquals(before.top + 60, epsilon: 0.5));
      expect(after.left, moreOrLessEquals(before.left + 40, epsilon: 0.5));
    });

    testWidgets("the distance is the style's", (tester) async {
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            richEditorStyle: const CoreRichEditorStyle(
              selectionToolbarOffset: CoreSpace.space16,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      final selected = _textBox(tester, 'hello world', 0, 11);
      expect(
        tester.getRect(_panel).bottom,
        moreOrLessEquals(selected.top - 16, epsilon: 0.5),
      );
    });
  });

  group('RichEditor selection toolbar — what it holds', () {
    testWidgets('the block-type button and nine buttons, no image', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            onImageUpload: (_) async => 'https://example.com/a.png',
            onImageDelete: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      // The toolbar in the box has the image button; the one over the
      // selection does not.
      expect(find.byKey(const ValueKey('richEditor.image')), findsOneWidget);
      expect(_selectionButton('image'), findsNothing);
      final order = [
        'blockType',
        'bold',
        'italic',
        'strikethrough',
        'code',
        'link',
        'bulletedList',
        'numberedList',
        'taskList',
        'quote',
      ];
      final lefts = <double>[];
      for (final format in order) {
        expect(_selectionButton(format), findsOneWidget, reason: format);
        lefts.add(tester.getTopLeft(_selectionButton(format)).dx);
      }
      expect(lefts, [...lefts]..sort(), reason: 'in this order');
      expect(
        find
            .descendant(of: _toolbar, matching: find.byType(Button))
            .hitTestable(),
        findsNWidgets(10),
      );
      // The "more" button is laid out so its width is known, but with room
      // for every button it is neither shown nor reachable.
      expect(_selectionButton('more'), findsOneWidget);
      expect(_selectionButton('more').hitTestable(), findsNothing);
      expect(
        CoreRichEditorFormat.selectionToolbar.expand((group) => group),
        isNot(contains(CoreRichEditorFormat.image)),
      );
    });

    testWidgets("the buttons are the toolbar's own, with its gaps and lines", (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      for (final format in ['bold', 'quote']) {
        final own = tester.widget<Button>(
          find.byKey(ValueKey<String>('richEditor.$format')),
        );
        final floating = tester.widget<Button>(_selectionButton(format));
        expect(floating.variant, own.variant);
        expect(floating.size, own.size);
        expect(floating.buttonStyle, own.buttonStyle);
        expect(tester.getSize(_selectionButton(format)), const Size(32, 32));
      }
      // Buttons of one group are 2 apart.
      expect(
        tester.getRect(_selectionButton('italic')).left -
            tester.getRect(_selectionButton('bold')).right,
        2,
      );
      // Groups: a gap of 8, a line 20 long, a gap of 8.
      // Three between the groups — and one leading the "more" button, which
      // is laid out but out of sight with room for every button.
      final lines = find.descendant(
        of: _toolbar,
        matching: find.byType(Divider),
      );
      expect(lines, findsNWidgets(4));
      final line = tester.getRect(lines.first);
      expect(line.height, 20);
      expect(
        line.left - tester.getRect(_selectionButton('blockType')).right,
        8,
      );
      expect(tester.getRect(_selectionButton('bold')).left - line.right, 8);
      // The line is centred on the buttons.
      expect(
        line.center.dy,
        tester.getRect(_selectionButton('bold')).center.dy,
      );
      // The block-type button is the one in the box.
      final ownBlock = tester.widget<Button>(
        find
            .descendant(
              of: find.byKey(const ValueKey('richEditor.blockType')),
              matching: find.byType(Button),
            )
            .first,
      );
      final floatingBlock = tester.widget<Button>(
        find
            .descendant(
              of: _selectionButton('blockType'),
              matching: find.byType(Button),
            )
            .first,
      );
      expect(floatingBlock.variant, ownBlock.variant);
      expect(floatingBlock.size, ownBlock.size);
      expect(floatingBlock.buttonStyle, ownBlock.buttonStyle);
      expect(
        tester.getSize(_selectionButton('blockType')),
        tester.getSize(find.byKey(const ValueKey('richEditor.blockType'))),
      );
    });

    testWidgets('a press formats the selection and leaves the toolbar open', (
      tester,
    ) async {
      // The last of several lines, so the toolbar over it leaves the one in
      // the box uncovered.
      const before = 'one\n\ntwo\n\nthree\n\n';
      final controller = RichEditorController(markdown: '${before}hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 5);
      final selection = controller.selection;
      await tester.tap(_selectionButton('bold'));
      await tester.pumpAndSettle();
      expect(controller.markdown, '$before**hello**');
      expect(controller.selection, selection, reason: 'selection kept');
      expect(_toolbar, findsOneWidget);
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      // Both toolbars hold the button down.
      final active = tester
          .widget<Button>(_selectionButton('bold'))
          .buttonStyle;
      expect(
        active,
        tester
            .widget<Button>(find.byKey(const ValueKey('richEditor.bold')))
            .buttonStyle,
      );
      expect(
        active,
        isNot(tester.widget<Button>(_selectionButton('italic')).buttonStyle),
      );
      // And a press on the toolbar in the box is seen by the floating one.
      await tester.tap(find.byKey(const ValueKey('richEditor.italic')));
      await tester.pumpAndSettle();
      expect(controller.markdown, '$before***hello***');
      expect(_toolbar, findsOneWidget);
      expect(
        tester.widget<Button>(_selectionButton('italic')).buttonStyle,
        active,
      );
    });

    testWidgets('opens the same block-type menu, and a pick keeps it open', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      await tester.tap(
        find
            .descendant(
              of: _selectionButton('blockType'),
              matching: find.byType(Button),
            )
            .first,
      );
      await tester.pumpAndSettle();
      for (final label in ['Text', 'Heading 1', 'Heading 2', 'Heading 3']) {
        expect(_row(label), findsOneWidget, reason: label);
      }
      // The current block is checked, and the headings end in their Markdown.
      expect(
        find.descendant(
          of: _row('Text'),
          matching: find.byWidgetPredicate(
            (w) => w is Icon && w.icon == LucideIcons.check,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _row('Heading 2'), matching: find.text('##')),
        findsOneWidget,
      );
      expect(_toolbar, findsOneWidget, reason: 'open under its menu');

      await tester.tap(_row('Heading 2'));
      await tester.pumpAndSettle();
      expect(controller.markdown, '## hello');
      expect(_toolbar, findsOneWidget);
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      // Both block-type buttons read the heading.
      for (final key in ['richEditorSelection', 'richEditor']) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey<String>('$key.blockType')),
            matching: find.text('Heading 2'),
          ),
          findsOneWidget,
          reason: key,
        );
      }
    });

    testWidgets('a menu closed without a pick leaves the toolbar open', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      await tester.tap(
        find
            .descendant(
              of: _selectionButton('blockType'),
              matching: find.byType(Button),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(_row('Heading 1'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_row('Heading 1'), findsNothing);
      expect(_toolbar, findsOneWidget);
      expect(_editor(tester).focusNode.hasFocus, isTrue);
    });
  });

  group('RichEditor selection toolbar — too narrow for its buttons', () {
    /// A 320-wide screen: the toolbar's 411 do not fit between the 8
    /// margins. The editor is 300 wide at the left edge.
    Future<RichEditorController> pumpNarrow(WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(RichEditor(controller: controller), left: 0, width: 300),
      );
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      await tester.pumpAndSettle();

      return controller;
    }

    testWidgets('folds the quote into a more menu first; the block-type menu '
        'stays and nothing wraps', (tester) async {
      await pumpNarrow(tester);
      expect(_toolbar, findsOneWidget);
      final panel = tester.getRect(_panel);
      expect(panel.width, lessThanOrEqualTo(320 - 2 * 8 + 0.5));
      expect(panel.height, 40, reason: 'one row');
      expect(_selectionButton('blockType').hitTestable(), findsOneWidget);
      expect(_selectionButton('more').hitTestable(), findsOneWidget);
      expect(_selectionButton('quote').hitTestable(), findsNothing);
      // Whatever else folded went in the fold order: a button that shows
      // folds after every one that does not.
      const order = CoreRichEditorFormat.selectionToolbarFoldOrder;
      var folding = true;
      for (final unit in order) {
        final shown = _selectionButton(unit.first.name).hitTestable();
        if (shown.evaluate().isNotEmpty) folding = false;
        if (folding) continue;
        expect(shown, findsOneWidget, reason: '${unit.first.name} shows');
      }
      // Everything that shows sits on one row, in order, ending in more.
      final shownButtons = find
          .descendant(of: _toolbar, matching: find.byType(Button))
          .hitTestable();
      final rects = [
        for (final e in shownButtons.evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];
      expect(rects.map((r) => r.center.dy).toSet(), hasLength(1));
      expect(rects.last.right, moreOrLessEquals(panel.right - 4, epsilon: 0.5));
      expect(rects.last, tester.getRect(_selectionButton('more')));
      // The more button is one of the toolbar's.
      final more = tester.widget<Button>(
        find.descendant(
          of: _selectionButton('more'),
          matching: find.byType(Button),
        ),
      );
      final bold = tester.widget<Button>(_selectionButton('bold'));
      expect(more.variant, bold.variant);
      expect(more.buttonStyle, bold.buttonStyle);
      expect(tester.getSize(_selectionButton('more')), const Size(32, 32));
      expect(
        find.descendant(
          of: _selectionButton('more'),
          matching: find.byWidgetPredicate(
            (w) => w is Icon && w.icon == LucideIcons.ellipsis,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the more menu lists the folded formats as checkbox rows, '
        'and a pick applies one', (tester) async {
      final controller = await pumpNarrow(tester);
      await tester.tap(_selectionButton('more'));
      await tester.pumpAndSettle();
      expect(_row('Quote'), findsOneWidget);
      expect(_toolbar, findsOneWidget, reason: 'open under its menu');
      // Folded rows are the ones not showing, in toolbar order.
      final rows = find.byType(MenuItem);
      final labels = [
        for (final e in rows.evaluate())
          (find
                      .descendant(
                        of: find.byWidget(e.widget),
                        matching: find.byType(Text),
                      )
                      .evaluate()
                      .first
                      .widget
                  as Text)
              .data,
      ];
      expect(labels.last, 'Quote');
      final foldedCount = labels.length;
      final shownCount = find
          .descendant(of: _toolbar, matching: find.byType(Button))
          .hitTestable()
          .evaluate()
          .length;
      // Ten buttons: the block type, nine formats; more replaces the folded.
      expect(shownCount - 2 + foldedCount, 9);
      await tester.tap(_row('Quote'));
      await tester.pumpAndSettle();
      expect(controller.markdown, endsWith('> hello world'));
      expect(_toolbar, findsOneWidget);
      // The quote is on now: its row is checked.
      await tester.tap(_selectionButton('more'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: _row('Quote'),
          matching: find.byWidgetPredicate(
            (w) => w is Icon && w.icon == LucideIcons.check,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing folds with room for every button', (tester) async {
      final controller = RichEditorController(markdown: _kLines);
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectTail(tester, controller, 11);
      for (final format in ['blockType', 'bold', 'link', 'taskList', 'quote']) {
        expect(_selectionButton(format).hitTestable(), findsOneWidget);
      }
      expect(_selectionButton('more').hitTestable(), findsNothing);
    });
  });

  group('RichEditor selection toolbar — keyboard and names', () {
    testWidgets('Escape closes it until the selection changes', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(_toolbar, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);
      expect(controller.hasSelectedText, isTrue, reason: 'selection kept');
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      // Still closed on the same selection…
      await tester.pump(const Duration(seconds: 1));
      expect(_toolbar, findsNothing);
      // …and back on another one.
      controller.moveCaretToEnd();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await _settleKeyboardSelection(tester);
      expect(_toolbar, findsOneWidget);
    });

    testWidgets('Alt+F10 moves the focus into it, Escape brings it back', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      final selection = controller.selection;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect(_editor(tester).focusNode.hasFocus, isFalse);
      expect(_toolbar, findsOneWidget, reason: 'the focus is in the toolbar');
      final focused = FocusManager.instance.primaryFocus?.context;
      expect(focused, isNotNull);
      expect(
        find.descendant(
          of: _selectionButton('blockType'),
          matching: find.byElementPredicate((e) => e == focused),
        ),
        findsOneWidget,
        reason: 'the first button has the focus',
      );
      // Tab walks the buttons.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final next = FocusManager.instance.primaryFocus?.context;
      expect(
        find.descendant(
          of: _toolbar,
          matching: find.byElementPredicate((e) => e == next),
        ),
        findsOneWidget,
      );
      expect(next, isNot(focused));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_toolbar, findsNothing);
      expect(_editor(tester).focusNode.hasFocus, isTrue);
      expect(controller.hasSelectedText, isTrue);
      expect(
        controller.selection,
        selection,
        reason: 'the selection is the one the toolbar was opened on',
      );
    });

    testWidgets('is a named group, apart from the toolbar in the box', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(find.bySemanticsLabel('Selection formatting'), findsOneWidget);
      expect(find.bySemanticsLabel('Formatting'), findsOneWidget);
      // Each button keeps its name.
      expect(
        find.descendant(
          of: _toolbar,
          matching: find.bySemanticsLabel('Bold'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('RichEditor selection toolbar — panel', () {
    testWidgets('a Popup: bright face, panel line, 10 corner, lg cast', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(_panel, findsOneWidget);
      final context = tester.element(_panel);
      final decoration = _panelDecoration(tester);
      expect(decoration.color, _token(context, CoreColors.surfaceBright));
      expect(
        decoration.border,
        Border.all(color: _token(context, CoreColors.outlineVariant)),
      );
      expect(decoration.borderRadius, BorderRadius.circular(10));
      // The cast is the `Popup`'s own — the floating-panel rung.
      expect(CorePopupStyle.defaultBoxShadow, CoreShadow.lg);
      expect(decoration.boxShadow, hasLength(CoreShadow.lg.length));
      expect(decoration.boxShadow, resolvePopup(context).boxShadow);
    });

    testWidgets('inset 4, with 12 where the text starts — 40 tall', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(_buildApp(RichEditor(controller: controller)));
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      final panel = tester.getRect(_panel);
      final first = tester.getRect(_selectionButton('blockType'));
      final last = tester.getRect(_selectionButton('quote'));
      expect(first.left - panel.left, 12);
      expect(panel.right - last.right, 4);
      expect(first.top - panel.top, 4);
      expect(panel.bottom - first.bottom, 4);
      expect(panel.height, 40);
      // The space before the block-type label is the one in the box.
      final box = tester.getRect(find.byType(RichEditor));
      final own = tester.getRect(
        find.byKey(const ValueKey('richEditor.blockType')),
      );
      // The box draws a 1 border the strip sits inside of.
      expect(own.left - box.left, 12 + 1);
    });

    testWidgets('the 12 is on the right in a right-to-left locale', (
      tester,
    ) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(controller: controller),
          editorDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      final panel = tester.getRect(_panel);
      final first = tester.getRect(_selectionButton('blockType'));
      final last = tester.getRect(_selectionButton('quote'));
      expect(panel.right - first.right, 12);
      expect(last.left - panel.left, 4);
    });

    testWidgets("the panel style is the style's slot", (tester) async {
      final controller = RichEditorController(markdown: 'hello');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _buildApp(
          RichEditor(
            controller: controller,
            richEditorStyle: const CoreRichEditorStyle(
              selectionToolbarPanelStyle: CorePopupStyle(
                borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _selectAll(tester, controller);
      expect(_panelDecoration(tester).borderRadius, BorderRadius.circular(4));
      // The inset it did not state is still the default's.
      final panel = tester.getRect(_panel);
      expect(
        tester.getRect(_selectionButton('blockType')).left - panel.left,
        12,
      );
    });
  });
}
