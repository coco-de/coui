import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// Some editors retain the offset while new dimensions are installed, then let
// the ballistic activity bring it back into range. The resulting scroll-start
// notification is delivered from viewport layout, not a pointer callback.
class _RetainOffsetPhysics extends ClampingScrollPhysics {
  const _RetainOffsetPhysics({super.parent});

  @override
  _RetainOffsetPhysics applyTo(ScrollPhysics? ancestor) =>
      _RetainOffsetPhysics(parent: buildParent(ancestor));

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) => newPosition.pixels;
}

SemanticsNode? _slider(WidgetTester tester) {
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isSlider) found = node;
    node.visitChildren((child) {
      visit(child);
      return found == null;
    });
  }

  final root =
      tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (root != null) visit(root);
  return found;
}

void main() {
  for (final visibility in [
    CoreScrollbarVisibility.always,
    CoreScrollbarVisibility.hidden,
  ]) {
    testWidgets(
      'layout-driven scroll start preserves accessibility: ${visibility.name}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final count = ValueNotifier(50);
        addTearDown(count.dispose);
        await pumpTestApp(
          tester,
          SizedBox(
            width: 300,
            height: 300,
            child: Scrollbar(
              visibility: visibility,
              controller: controller,
              child: ValueListenableBuilder<int>(
                valueListenable: count,
                builder: (_, items, _) => ListView.builder(
                  controller: controller,
                  physics: const _RetainOffsetPhysics(),
                  itemExtent: 40,
                  itemCount: items,
                  itemBuilder: (_, index) => Text('Item $index'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        controller.jumpTo(controller.position.maxScrollExtent / 2);
        await tester.pumpAndSettle();
        expect(_slider(tester)!.getSemanticsData().value, '50%');

        count.value = 3;
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(controller.offset, closeTo(0, 0.1));
        final slider = _slider(tester)!.getSemanticsData();
        expect(slider.value, '0%');
        expect(slider.hasAction(.increase), isFalse);
        expect(slider.hasAction(.decrease), isFalse);
        semantics.dispose();
      },
    );
  }
}
