// The Flutter `DragItem` adds no geometry — it hands its parent's
// constraints to the child — and the Flutter `DragOverlay` that is idle is a
// zero-size box that is still a child of its parent.
//
// A plain block wrapper cannot be either: it leaves a child of a fixed-height
// parent at its own height, and it opens a line box around an inline child.
// `display: none` takes no part in a flex `gap` at all, where the Flutter
// zero box still takes its `spacing`.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _doms() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

void main() {
  group('DragItem', () {
    testComponents('wraps its child in a transparent grid', (tester) async {
      pumpWithTheme(
        tester,
        const DragScope(
          child: DragItem(
            id: CoreDragId('item'),
            child: Component.text('Row'),
          ),
        ),
      );

      final wrapper = _doms().singleWhere(
        (c) => (c.classes ?? '').split(' ').contains('cursor-grab'),
      );

      expect(
        wrapper.classes!.split(' '),
        containsAll(['grid', 'grid-cols-1', 'h-full']),
      );
    });

    testComponents('a disabled item keeps the transparent grid', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const DragScope(
          child: DragItem(
            id: CoreDragId('item'),
            enabled: false,
            child: Component.text('Row'),
          ),
        ),
      );

      final wrapper = _doms().singleWhere(
        (c) => (c.classes ?? '').split(' ').contains('grid'),
      );

      expect(wrapper.classes!.split(' '), isNot(contains('cursor-grab')));
      expect(wrapper.classes!.split(' '), contains('h-full'));
    });
  });

  group('an idle DragOverlay', () {
    testComponents('is a 0×0 box rather than display: none', (tester) async {
      pumpWithTheme(
        tester,
        DragScope(
          child: DragOverlay(
            builder: (context, session) => const Component.text('copy'),
          ),
        ),
      );

      final box = _doms().singleWhere(
        (c) => c.styles?.properties['width'] == '0',
      );

      expect(box.styles!.properties['height'], '0');
      expect(box.styles!.properties.containsKey('display'), isFalse);
    });
  });
}
