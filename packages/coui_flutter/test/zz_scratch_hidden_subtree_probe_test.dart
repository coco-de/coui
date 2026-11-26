// TEMPORARY reconnaissance probe for issue #3392 — delete after measuring.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void _dump(String tag, WidgetTester tester) {
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
  final buf = StringBuffer();
  void walk(SemanticsNode n, int d) {
    final data = n.getSemanticsData();
    buf.writeln(
      '${'  ' * d}#${n.id} label="${data.label}" '
      'hidden=${data.flagsCollection.isHidden} '
      'blocked=${data.flagsCollection.isAccessibilityFocusBlocked} '
      'rect=${n.rect}',
    );
    n.visitChildren((c) {
      walk(c, d + 1);
      return true;
    });
  }

  walk(root, 0);
  print('=== $tag ===\n$buf');
}

int _focusableCount(WidgetTester tester) {
  var n = 0;
  void walk(FocusNode f) {
    if (f.canRequestFocus && f.context != null && f is! FocusScopeNode) n++;
    for (final c in f.children) {
      walk(c);
    }
  }

  walk(tester.binding.focusManager.rootScope);
  return n;
}

void main() {
  testWidgets('P1 collapsed Accordion content', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTestApp(
      tester,
      Accordion(
        items: [
          AccordionItem(
            title: 'trigger-A',
            content: Button(
              onPressed: () {},
              child: const Text('SECRET-BUTTON'),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    _dump('P1 collapsed accordion', tester);
    print(
      'P1 SECRET-BUTTON widgets=${find.text('SECRET-BUTTON').evaluate().length} '
      'focusables=${_focusableCount(tester)}',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    print('P1 focus#1=${tester.binding.focusManager.primaryFocus?.debugLabel}');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    print('P1 focus#2=${tester.binding.focusManager.primaryFocus?.debugLabel}');
    handle.dispose();
  });

  testWidgets('P2 Swap hidden face rotate', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTestApp(
      tester,
      Swap(
        animation: CoreSwapAnimation.rotate,
        onToggle: (_) {},
        onContent: Button(onPressed: () {}, child: const Text('ON-FACE')),
        offContent: const Text('OFF-FACE'),
      ),
    );
    await tester.pumpAndSettle();
    _dump('P2 swap rotate checked=false', tester);
    print(
      'P2 ON-FACE widgets=${find.text('ON-FACE').evaluate().length} '
      'focusables=${_focusableCount(tester)}',
    );
    handle.dispose();
  });

  testWidgets('P4 Carousel off-screen slides', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTestApp(
      tester,
      SizedBox(
        width: 300,
        height: 200,
        child: Carousel(
          transition: const SlidingCarouselTransition(),
          itemCount: 4,
          itemBuilder: (context, i) => Button(
            onPressed: () {},
            child: Text('SLIDE-$i'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _dump('P4 carousel index 0', tester);
    for (var i = 0; i < 4; i++) {
      print('P4 SLIDE-$i widgets=${find.text('SLIDE-$i').evaluate().length}');
    }
    print('P4 focusables=${_focusableCount(tester)}');
    handle.dispose();
  });
}
