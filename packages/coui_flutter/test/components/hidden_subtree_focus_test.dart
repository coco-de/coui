import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: SizedBox(width: 320, child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Whether [node] actually takes focus when it asks for it.
///
/// The property to read is not the node's own `canRequestFocus` — that
/// stays true. Excluding a subtree marks an *ancestor* as not passing
/// focus down, so the only honest question is whether the request lands.
Future<bool> _canTakeFocus(WidgetTester tester, FocusNode node) async {
  node.requestFocus();
  await tester.pumpAndSettle();

  return node.hasFocus;
}

void main() {
  group('a collapsed panel is out of the tab order', () {
    testWidgets('an accordion refuses focus while closed and grants it open', (
      tester,
    ) async {
      // The leak, measured before this existed: content inside a
      // collapsed panel produced no semantics — a zero-height clip hides
      // it from a screen reader on its own — but stayed focusable. Tab
      // walked into a control nobody could see and the page scrolled to
      // a panel that was shut.
      final node = FocusNode();
      addTearDown(node.dispose);

      await _pump(
        tester,
        Accordion(
          items: [
            AccordionItem(
              title: 'Shipping',
              content: Button(
                focusNode: node,
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      );

      expect(
        await _canTakeFocus(tester, node),
        isFalse,
        reason: 'a control in a closed panel took focus',
      );

      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();

      expect(
        await _canTakeFocus(tester, node),
        isTrue,
        reason: 'opening did not return the content to the tab order',
      );
    });

    testWidgets('and a collapsible behaves the same', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await _pump(
        tester,
        Collapsible(
          trigger: const Text('Details'),
          content: Button(
            focusNode: node,
            onPressed: () {},
            child: const Text('Edit'),
          ),
        ),
      );

      expect(await _canTakeFocus(tester, node), isFalse);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(await _canTakeFocus(tester, node), isTrue);
    });
  });

  group('closing and opening again still works', () {
    testWidgets('a reopened accordion is reachable', (tester) async {
      // The half a blunter primitive gets wrong. The framework has a
      // subtree-blocking flag that would also close the leak, but its
      // parent data is left out of the equality that decides
      // re-propagation — so a descendant blocked while closed stays
      // blocked after opening. Measured on the pinned SDK: the parent
      // flips and the child does not follow.
      //
      // A single open would not notice. This is the shape that would.
      final node = FocusNode();
      addTearDown(node.dispose);

      await _pump(
        tester,
        Accordion(
          items: [
            AccordionItem(
              title: 'Shipping',
              content: Button(
                focusNode: node,
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      );

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Shipping'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Shipping'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();

      expect(
        await _canTakeFocus(tester, node),
        isTrue,
        reason: 'the panel stopped granting focus after being toggled',
      );
    });
  });

  group('the wrapper is re-read, not read once', () {
    testWidgets('the panel does not need a rebuild from above', (
      tester,
    ) async {
      // Why this is the assertion and not "the flag has the right
      // value": expanding mutates state without `setState` and relies on
      // the animation to rebuild. A focus wrapper placed in the outer
      // build is evaluated once, and the panel then refuses focus for
      // the rest of its life — worse than the leak it was closing,
      // because it looks correct.
      //
      // Nothing here rebuilds the parent, so a wrapper that is not
      // driven by the animation cannot pass.
      final node = FocusNode();
      addTearDown(node.dispose);

      await _pump(
        tester,
        Accordion(
          items: [
            AccordionItem(
              title: 'Shipping',
              content: Button(
                focusNode: node,
                onPressed: () {},
                child: const Text('Edit'),
              ),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Shipping'));
      await tester.pumpAndSettle();

      expect(await _canTakeFocus(tester, node), isTrue);
    });
  });
}
