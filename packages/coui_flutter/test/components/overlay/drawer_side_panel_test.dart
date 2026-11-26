// The side panel the Drawer is drawn as — 400 wide, square, one line on the
// edge that faces the page, no shadow, a header that starts at the top with
// a 32 square close button, content that fills what is left, and an optional
// footer under its own rule. A top / bottom sheet keeps its rounded corners
// and has no line.
//
// The Web twin's markup for the same parts is in
// `packages/coui_web/test/components/overlay/drawer_side_panel_test.dart`.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _host(Drawer drawer) => material.MaterialApp(
  builder: (context, built) => Theme(data: const ThemeData(), child: built!),
  home: material.Builder(
    builder: (context) => material.Center(
      child: material.ElevatedButton(
        onPressed: () => openDrawer<void>(
          context: context,
          side: drawer.side,
          builder: (context) => drawer,
        ),
        child: const material.Text('open'),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Drawer drawer) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(drawer));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const _kContent = material.SizedBox(height: 40, width: 40, key: Key('body'));

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<material.DecoratedBox>(
    find
        .descendant(
          of: find.byType(Drawer),
          matching: find.byType(material.DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

Rect _panel(WidgetTester tester) => tester.getRect(find.byType(Drawer));

void main() {
  group('side panel', () {
    testWidgets('is 400 wide and square', (tester) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      expect(_panel(tester).width, CoreDrawerStyle.defaultPanelWidth);
      expect(_panel(tester).width, 400);
      expect(_decoration(tester).borderRadius, BorderRadius.zero);
    });

    testWidgets('has one line, on the edge facing the page', (tester) async {
      for (final entry in {
        CoreDrawerSide.left: 'right',
        CoreDrawerSide.right: 'left',
      }.entries) {
        await _open(
          tester,
          Drawer(side: entry.key, title: 'Title', content: _kContent),
        );
        final border = _decoration(tester).border! as Border;
        final lines = {
          'left': border.left,
          'right': border.right,
          'top': border.top,
          'bottom': border.bottom,
        };
        for (final line in lines.entries) {
          expect(
            line.value.width,
            line.key == entry.value ? 1 : 0,
            reason: '${entry.key} panel, ${line.key} edge',
          );
        }
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('casts no shadow', (tester) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      expect(_decoration(tester).boxShadow ?? const <BoxShadow>[], isEmpty);
    });

    testWidgets('header starts at the top with a 32 square close button', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      final button = tester.getRect(
        find.descendant(of: find.byType(Drawer), matching: find.byType(Button)),
      );
      expect(button.size, const Size(32, 32));
      // 24 of header padding above the row; the button sits at its top.
      expect(button.top - _panel(tester).top, 24);
      // 24 of padding at the end; the line is painted over the edge.
      expect(_panel(tester).right - button.right, 24);
    });

    testWidgets('space between the title and the close button is 16', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      final row = tester.getRect(
        find
            .ancestor(
              of: find.text('Title'),
              matching: find.byType(Row),
            )
            .first,
      );
      final button = tester.getRect(
        find.descendant(of: find.byType(Drawer), matching: find.byType(Button)),
      );
      final titleCell = tester.getRect(
        find
            .ancestor(of: find.text('Title'), matching: find.byType(Expanded))
            .first,
      );
      expect(button.left - titleCell.right, 16);
      expect(row.left, _panel(tester).left + 24);
    });

    testWidgets('content is padded 20 / 24 and fills the height left', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      final body = tester.getRect(find.byKey(const Key('body')));
      expect(body.left - _panel(tester).left, 24);
      final fill = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const Key('body')),
              matching: find.byType(Flexible),
            )
            .first,
      );
      expect(body.top - fill.top, 20);
      expect(_panel(tester).bottom - fill.bottom, 0);
    });
  });

  group('top / bottom sheet', () {
    testWidgets('keeps the 16 corners facing the page and has no line', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, title: 'Title', content: _kContent),
      );
      final decoration = _decoration(tester);
      expect(
        decoration.borderRadius,
        const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      );
      // No line at all — a zero-width side would be a hairline.
      expect(decoration.border, isNull);
      expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty);
    });
  });

  group('footer', () {
    testWidgets('is absent unless stated', (tester) async {
      await _open(
        tester,
        const Drawer(title: 'Title', content: _kContent),
      );
      expect(find.byKey(const Key('footer')), findsNothing);
      expect(find.byType(Divider), findsOneWidget); // the header rule only
    });

    testWidgets('sits under its own rule, right-aligned, padded 16 / 24', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          title: 'Title',
          content: _kContent,
          footer: material.SizedBox(width: 80, height: 32, key: Key('footer')),
        ),
      );
      expect(find.byType(Divider), findsNWidgets(2));
      final footer = tester.getRect(find.byKey(const Key('footer')));
      // 24 of padding at the end; the line is painted over the edge.
      expect(_panel(tester).right - footer.right, 24);
      // 16 below, and the footer is the last thing in the panel.
      expect(_panel(tester).bottom - footer.bottom, 16);
      final body = tester.getRect(find.byKey(const Key('body')));
      expect(footer.top, greaterThan(body.bottom));
    });
  });
}
