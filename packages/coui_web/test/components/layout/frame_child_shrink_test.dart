// Children of a row / column Frame that did not ask for flex keep their
// intrinsic size, the way Flutter `Row` / `Column` lay out non-`Flexible`
// children: a too-narrow parent overflows instead of squeezing them.
// Children that set `flex` shrink / grow exactly as before.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The child-selector class the resolver emits on the parent.
const _kNoShrink = '[&>*]:shrink-0';

DomComponent _byId(String id) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .singleWhere((c) => c.id == id);

List<String> _classes(DomComponent c) => (c.classes ?? '').split(' ');

Map<String, String> _inline(DomComponent c) => c.styles?.properties ?? const {};

void main() {
  group('children without flex do not shrink', () {
    for (final direction in [
      CoreFrameDirection.row,
      CoreFrameDirection.column,
      CoreFrameDirection.rowReverse,
      CoreFrameDirection.columnReverse,
    ]) {
      testComponents('${direction.name} pins its children at shrink 0', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Frame(
            id: 'parent',
            direction: direction,
            children: [
              const Icon(LucideIcons.house),
              const Text('Frame primitive'),
            ],
          ),
        );

        expect(_classes(_byId('parent')), contains(_kNoShrink));
      });
    }

    testComponents('wrap keeps the default so text wraps inside a run', (
      tester,
    ) async {
      // Flutter `Wrap` hands each child the run width as its max
      // constraint, so a long label wraps there too.
      pumpWithTheme(
        tester,
        const Frame(
          id: 'parent',
          direction: CoreFrameDirection.wrap,
          children: [Text('a'), Text('b')],
        ),
      );

      expect(_classes(_byId('parent')), isNot(contains(_kNoShrink)));
    });

    testComponents('a non-flex frame emits no child rule', (tester) async {
      pumpWithTheme(
        tester,
        const Frame(id: 'parent', child: Text('a')),
      );

      expect(_classes(_byId('parent')), isNot(contains(_kNoShrink)));
    });
  });

  group('children with flex keep their own shrink / grow', () {
    testComponents('loose fit still shrinks — inline beats the class rule', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(
          id: 'parent',
          direction: CoreFrameDirection.row,
          children: [
            Frame(id: 'child', flex: 1, child: Text('grows')),
          ],
        ),
      );

      final child = _inline(_byId('child'));
      expect(child['flex-grow'], '1');
      expect(child['flex-shrink'], '1');
      expect(child['flex-basis'], 'auto');
    });

    testComponents('tight fit stays shrink 0 with a zero basis', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Frame(
          id: 'parent',
          direction: CoreFrameDirection.row,
          children: [
            Frame(
              id: 'child',
              flex: 2,
              fit: CoreFlexFit.tight,
              child: Text('expands'),
            ),
          ],
        ),
      );

      final child = _inline(_byId('child'));
      expect(child['flex-grow'], '2');
      expect(child['flex-shrink'], '0');
      expect(child['flex-basis'], '0');
    });
  });

  testComponents('CoUI Text is an element, so the child rule reaches it', (
    tester,
  ) async {
    // The rule selects `> *`, which only matches elements. A bare text
    // node would be an anonymous flex item that no selector can reach;
    // `Text` renders a `<span>`, so it is covered.
    pumpWithTheme(
      tester,
      const Frame(
        id: 'parent',
        direction: CoreFrameDirection.row,
        children: [Text('label')],
      ),
    );

    final parent = find
        .byType(DomComponent)
        .evaluate()
        .singleWhere((e) => (e.component as DomComponent).id == 'parent');
    final directChildren = <DomComponent>[];
    parent.visitChildren((e) {
      // Walk through non-DOM wrappers (Text is a component that builds
      // a `<span>`) down to the first DOM element.
      void firstDom(Element el) {
        if (el.component is DomComponent) {
          directChildren.add(el.component as DomComponent);
        } else {
          el.visitChildren(firstDom);
        }
      }

      firstDom(e);
    });

    expect(directChildren.map((c) => c.tag), ['span']);
  });
}
