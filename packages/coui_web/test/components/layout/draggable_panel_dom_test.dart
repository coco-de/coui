import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

// `h-full` on the panel root is a percentage, and a percentage height
// resolves against the caller's box only while nothing sits between the
// two. An element in that gap makes it resolve against `auto` instead,
// and every child of the root is absolutely positioned — so `auto` is
// zero and the whole component renders at zero height with nothing
// reported anywhere. The resolver still emits `h-full` either way, which
// is what a resolver-level test reads back as correct, and why these
// assertions are about DOM shape instead.
//
// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup.

const _kBoxId = 'sizing-box';
const _kPanelId = 'my-panel';

Component _panel({String? classes, Styles? css}) => div([
  DraggablePanel(
    classes: classes,
    css: css,
    id: _kPanelId,
    panel: const div([Text('PANEL')]),
    child: const div([Text('CANVAS')]),
  ),
], id: _kBoxId);

void main() {
  group('DraggablePanel root reaches the caller box', () {
    testServer('the drag scope contributes no element of its own', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _panel()));
      final response = await tester.request('/');

      // The scope adopts the panel root as its measurement origin, so it
      // renders nothing. A box here is the regression: it would sit
      // between the caller's box and this root and collapse `h-full`.
      expect(
        response.document?.querySelector('[id^="coui-drag-scope"]'),
        isNull,
      );
    });

    testServer('the root is a direct child of the box that sizes it', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _panel()));
      final response = await tester.request('/');
      final root = response.document?.querySelector('#$_kPanelId');

      expect(root, isNotNull);
      expect(root!.parent?.id, _kBoxId);
      // Named together on purpose: the parent relationship is only worth
      // anything because this class is what depends on it.
      expect(root.className, contains('h-full'));
    });

    testServer('caller chrome still lands on the root element', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _panel(
            classes: 'my-class',
            css: const Styles(raw: {'margin': '1rem'}),
          ),
        ),
      );
      final response = await tester.request('/');
      final root = response.document?.querySelector('#$_kPanelId');

      expect(root, isNotNull);
      expect(root!.parent?.id, _kBoxId);
      expect(root.className, allOf(contains('my-class'), contains('h-full')));
      expect(root.attributes['style'], contains('margin'));
    });
  });

  group('DraggablePanel dockType before the first measurement', () {
    // SSR has no container size, so the handle docks right in CSS alone.
    // Its inset is the dock type's resting inset — the same number the
    // Flutter twin paints from.
    String? handleRight(String html) {
      final match = RegExp(r'right:\s*(-?[0-9.]+)rem').firstMatch(html);
      return match?.group(1);
    }

    Component panelWith(CoreDraggablePanelDockType dockType) => div([
      DraggablePanel(
        dockType: dockType,
        id: _kPanelId,
        child: const div([Text('CANVAS')]),
      ),
    ], id: _kBoxId);

    testServer('inside docks dockOffset in from the right edge', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: panelWith(CoreDraggablePanelDockType.inside),
        ),
      );
      final response = await tester.request('/');
      final root = response.document!.querySelector('#$_kPanelId')!;

      expect(
        double.parse(handleRight(root.outerHtml)!) * kRemDivisor,
        CoreDraggablePanelContract.defaultDockOffset,
      );
    });

    testServer('outside rests past the right edge', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: panelWith(CoreDraggablePanelDockType.outside),
        ),
      );
      final response = await tester.request('/');
      final root = response.document!.querySelector('#$_kPanelId')!;

      expect(
        double.parse(handleRight(root.outerHtml)!) * kRemDivisor,
        CoreDraggablePanelDockType.outside.restingEdgeInset(
          handleSize: CoreDraggablePanelStyle.defaultHandleSize,
          dockOffset: CoreDraggablePanelContract.defaultDockOffset,
        ),
      );
      expect(root.className.split(' '), contains('overflow-hidden'));
    });
  });
}
