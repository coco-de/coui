// A dialog with a field in it has to stay above the on-screen keyboard.
//
// The route centres the panel inside the whole window, and the window is
// what the keyboard covers: a centred panel put its actions under it. The
// readings here are laid-out rectangles on a 360 × 640 screen with a 300 px
// inset, so a panel that ignores the inset fails by where it is, not by what
// it declares.
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kBody = ValueKey<String>('dialog-keyboard-body');
const _kAction = ValueKey<String>('dialog-keyboard-action');

const _kScreen = Size(360, 640);
const _kKeyboard = 300.0;

/// Where the keyboard's top edge is.
const double _kKeyboardTop = 640 - _kKeyboard;

Widget _longBody() => material.Column(
  key: _kBody,
  crossAxisAlignment: .start,
  children: [
    for (var i = 0; i < 40; i++) material.Text('Line $i of the terms.'),
  ],
);

/// Opens a `Dialog` through `showDialog` on the test screen and leaves it
/// settled, with [keyboard] px of bottom inset from the start.
Future<void> _openDialog(
  WidgetTester tester, {
  required Widget content,
  double keyboard = 0,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _kScreen
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Theme(
      data: const ThemeData(),
      child: material.MaterialApp(
        home: material.Builder(
          builder: (context) => material.GestureDetector(
            onTap: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  title: const material.Text('Terms'),
                  content: content,
                  actions: const [
                    material.SizedBox(key: _kAction, width: 80, height: 40),
                  ],
                ),
              ),
            ),
            child: const material.Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Rect _action(WidgetTester tester) => tester.getRect(find.byKey(_kAction));

/// A body a little taller than half the screen — short enough to fit above
/// the keyboard, tall enough that a panel centred in the whole window would
/// reach well below the keyboard's top edge.
Widget _midBody() => const material.SizedBox(height: 180);

void main() {
  group('a dialog above the keyboard', () {
    testWidgets('keeps its actions clear of it', (tester) async {
      await _openDialog(tester, content: _midBody(), keyboard: _kKeyboard);

      expect(_action(tester).bottom, lessThanOrEqualTo(_kKeyboardTop));
      expect(_action(tester).top, greaterThanOrEqualTo(0));
    });

    testWidgets('and is centred in what the keyboard leaves', (tester) async {
      await _openDialog(tester, content: _midBody(), keyboard: _kKeyboard);

      final title = tester.getRect(find.text('Terms'));
      final action = _action(tester);
      final above = title.top;
      final below = _kKeyboardTop - action.bottom;

      // Equal room above and below, give or take the panel's own padding,
      // which is the same on both sides.
      expect((above - below).abs(), lessThan(24));
    });

    testWidgets('and follows a keyboard that arrives after it', (
      tester,
    ) async {
      await _openDialog(tester, content: _midBody());
      final before = _action(tester);
      // The control: with no keyboard the panel is where it always was —
      // centred in the whole screen, so its actions sit below the keyboard's
      // future top edge.
      expect(before.bottom, greaterThan(_kKeyboardTop));

      tester.view.viewInsets = const FakeViewPadding(bottom: _kKeyboard);
      await tester.pumpAndSettle();

      expect(_action(tester).bottom, lessThanOrEqualTo(_kKeyboardTop));
      expect(_action(tester).top, lessThan(before.top));
    });

    testWidgets('a tall body still scrolls with the actions pinned above it', (
      tester,
    ) async {
      await _openDialog(tester, content: _longBody(), keyboard: _kKeyboard);

      final scrollable = find.ancestor(
        of: find.byKey(_kBody),
        matching: find.byType(Scrollable),
      );
      final viewport = tester.getRect(scrollable);
      final position = tester.state<ScrollableState>(scrollable).position;

      expect(_action(tester).bottom, lessThanOrEqualTo(_kKeyboardTop));
      expect(viewport.bottom, lessThanOrEqualTo(_action(tester).top));
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('and leaves the descendants no inset to apply twice', (
      tester,
    ) async {
      await _openDialog(tester, content: _midBody(), keyboard: _kKeyboard);

      final inside = tester.element(find.byKey(_kAction));
      expect(material.MediaQuery.viewInsetsOf(inside).bottom, 0);
    });
  });
}
