// Pins the `TextArea.footer` slot — one line of actions under the text,
// inside the area's box (a chat input's send button).
//
// Rendering the footer is the easy half. These cases also read where it
// lands (under the text row, `footerGapStyle` below it, inside the same
// padding), and what a pointer on it does: the footer is not part of the
// editing surface, so its content takes its own taps, a tap beside that
// content does not focus the area, and hovering it shows no I-beam. A
// build that only places the footer passes the first group and fails the
// rest.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _kFooterKey = Key('text-area-footer');
const _kFooterSpaceKey = Key('text-area-footer-space');
const _kSendKey = Key('text-area-send');
const _kWidth = 400.0;

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Center(
        child: SizedBox(width: _kWidth, child: child),
      ),
    ),
  ),
);

/// A footer the way a chat input states one — empty space on the leading
/// side, the send action on the trailing side.
Widget _footer({VoidCallback? onSend}) => Row(
  key: _kFooterKey,
  children: [
    const Expanded(child: SizedBox(key: _kFooterSpaceKey, height: 32)),
    Button(
      key: _kSendKey,
      size: .sm,
      onPressed: onSend ?? () {},
      child: const Text('Send'),
    ),
  ],
);

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The box — with no label or helper text the area's own rect is its box.
Rect _box(WidgetTester tester) => _rect(tester, find.byType(TextArea));

Rect _text(WidgetTester tester) => _rect(tester, find.byType(EditableText));

Finder get _dragHandle => find.byWidgetPredicate(
  (widget) =>
      widget is MouseRegion && widget.cursor == SystemMouseCursors.resizeUpDown,
);

void main() {
  group('TextArea footer — placement', () {
    testWidgets('sits under the text row, 12 below it', (tester) async {
      await tester.pumpWidget(_app(TextArea(rows: 2, footer: _footer())));

      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      expect(footer.top - text.bottom, 12);
    });

    testWidgets('inside the box, inset by the same padding as the text', (
      tester,
    ) async {
      await tester.pumpWidget(_app(TextArea(rows: 2, footer: _footer())));

      final box = _box(tester);
      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      // The padding is symmetric on every rung, so the footer sits as far
      // above the box's bottom as the text sits below its top — the footer
      // is inside the padding, not under the box.
      expect(footer.left, text.left);
      expect(footer.right, text.right);
      expect(box.bottom - footer.bottom, closeTo(text.top - box.top, 0.01));
    });

    testWidgets('a fixed-height box gives the text row what the footer '
        'leaves', (tester) async {
      // No `rows`: the box keeps its own height (the `md` row's four lines,
      // #5747) and the text row
      // takes the rest, so the footer does not push the box taller — it
      // stays on the box's bottom padding, the text on its top.
      await tester.pumpWidget(_app(TextArea(footer: _footer())));

      final box = _box(tester);
      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      expect(
        box.height,
        CoreTextAreaStyle.defaultsBySize[CoreComponentSize.md]!.initialHeight,
      );
      expect(footer.top - text.bottom, greaterThanOrEqualTo(12));
      expect(box.bottom - footer.bottom, closeTo(text.top - box.top, 0.01));
    });

    testWidgets('text alignment applies inside the share the footer leaves', (
      tester,
    ) async {
      // `textAlignVertical: bottom` puts the text on the bottom of the text
      // row — right above the gap — rather than on the box's bottom, where
      // the footer is.
      await tester.pumpWidget(
        _app(
          TextArea(
            footer: _footer(),
            textAreaStyle: const CoreTextAreaStyle(
              textAlignVertical: CoreVerticalAlign.bottom,
            ),
          ),
        ),
      );

      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      expect(footer.top - text.bottom, 12);
    });

    testWidgets('the gap follows footerGapStyle', (tester) async {
      await tester.pumpWidget(
        _app(
          TextArea(
            rows: 2,
            footer: _footer(),
            textAreaStyle: const CoreTextAreaStyle(
              footerGapStyle: CoreGapStyle(size: CoreSpace.space16),
            ),
          ),
        ),
      );

      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      expect(footer.top - text.bottom, 16);
    });

    testWidgets('absent when null — no gap, no footer row', (tester) async {
      await tester.pumpWidget(_app(TextArea(rows: 2)));

      expect(find.byKey(_kFooterKey), findsNothing);
      expect(
        find.descendant(of: find.byType(TextArea), matching: find.byType(Gap)),
        findsNothing,
      );
    });
  });

  group('TextArea footer — the footer is not the editing surface', () {
    testWidgets('a Button in the footer fires and leaves the area unfocused', (
      tester,
    ) async {
      var sent = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(
          TextArea(
            focusNode: focusNode,
            rows: 2,
            footer: _footer(onSend: () => sent++),
          ),
        ),
      );

      await tester.tap(find.byKey(_kSendKey));
      await tester.pumpAndSettle();

      expect(sent, 1);
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('a tap beside the footer content does not focus the area', (
      tester,
    ) async {
      var taps = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _app(
          TextArea(
            focusNode: focusNode,
            rows: 2,
            footer: _footer(),
            onTap: () => taps++,
          ),
        ),
      );

      // An empty box takes no hit of its own, so tap its position — the
      // pointer lands on the footer's empty space, inside the area's box.
      await tester.tapAt(tester.getCenter(find.byKey(_kFooterSpaceKey)));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isFalse);
      expect(taps, 0);

      // The text row above it still is the editing surface.
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
      expect(taps, 1);
    });

    testWidgets('a tap on the footer is not a tap outside the area', (
      tester,
    ) async {
      var outside = 0;
      await tester.pumpWidget(
        _app(
          TextArea(
            rows: 2,
            footer: _footer(),
            onTapOutside: (_) => outside++,
          ),
        ),
      );
      // `onTapOutside` reports only while the area holds focus.
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_kSendKey));
      await tester.pumpAndSettle();
      expect(outside, 0);

      // The control: a tap beside the area is outside.
      await tester.tapAt(_box(tester).bottomCenter + const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(outside, 1);
    });

    testWidgets('hovering the footer shows no I-beam; the text row does', (
      tester,
    ) async {
      await tester.pumpWidget(_app(TextArea(rows: 2, footer: _footer())));

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(
        location: tester.getCenter(find.byKey(_kFooterSpaceKey)),
      );
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.basic,
      );

      await gesture.moveTo(tester.getCenter(find.byType(EditableText)));
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.text,
      );
    });

    testWidgets('disabled, the box around the text shows the forbidden '
        "cursor — the footer's space and the gap", (tester) async {
      // The disabled state is the box's, as it is without a footer, so the
      // footer's empty space and the gap above it read the box's cursor.
      // The web frame states the same not-allowed cursor over its box.
      await tester.pumpWidget(
        _app(TextArea(enabled: false, rows: 2, footer: _footer())),
      );

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(
        location: tester.getCenter(find.byKey(_kFooterSpaceKey)),
      );
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );

      final text = _text(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));
      await gesture.moveTo(
        Offset(footer.left + 2, (text.bottom + footer.top) / 2),
      );
      await tester.pump();

      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
      );
    });

    testWidgets('without a footer the box padding still focuses the area', (
      tester,
    ) async {
      // The footer-less tree keeps the gestures on the whole box.
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(_app(TextArea(focusNode: focusNode, rows: 2)));

      await tester.tapAt(_box(tester).topLeft + const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('TextArea footer — resizing', () {
    testWidgets('the drag handle takes the text row corner, off the footer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(TextArea(expandableHeight: true, footer: _footer())),
      );

      final handle = _rect(tester, _dragHandle);
      final footer = _rect(tester, find.byKey(_kFooterKey));
      final send = _rect(tester, find.byKey(_kSendKey));

      expect(handle.bottom, lessThanOrEqualTo(footer.top));
      expect(handle.overlaps(send), isFalse);
    });

    testWidgets('a resize reports the whole box, footer included', (
      tester,
    ) async {
      double? reported;
      await tester.pumpWidget(
        _app(
          TextArea(
            expandableHeight: true,
            footer: _footer(),
            onHeightChanged: (height) => reported = height,
          ),
        ),
      );

      await tester.drag(_dragHandle, const Offset(0, 40));
      await tester.pumpAndSettle();

      final box = _box(tester);
      final footer = _rect(tester, find.byKey(_kFooterKey));

      expect(reported, isNotNull);
      expect(reported, greaterThan(CoreTextAreaStyle.defaultInitialHeight));
      // What the callback reports is the box the user sees — the height a
      // caller can feed back into `initialHeight` — and the footer is
      // inside it, not below it.
      expect(box.height, reported);
      expect(footer.bottom, lessThan(box.bottom));
    });
  });
}
