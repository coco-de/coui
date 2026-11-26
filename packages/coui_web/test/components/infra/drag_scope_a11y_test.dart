import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  group('DragScope live region', () {
    testServer('renders one polite region with the scope box', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const DragScope(child: Text('scoped')),
        ),
      );
      final response = await tester.request('/');
      final regions = response.document?.querySelectorAll(
        '[aria-live="polite"]',
      );

      // One per scope, not one per drag: a region created on pick-up would
      // be empty at the moment the reader starts watching it, and the
      // first sentence would be lost.
      expect(regions, hasLength(1));
      expect(regions!.single.attributes['aria-atomic'], 'true');
    });

    testServer('an adopted origin still gets its region beside it', (
      tester,
    ) async {
      // The scope renders nothing of its own when the caller supplies the
      // measurement origin, so the region rides beside the child instead —
      // silently absent here is the failure this pins.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const DragScope(
            originElementId: 'host-root',
            child: div([Text('scoped')], id: 'host-root'),
          ),
        ),
      );
      final response = await tester.request('/');
      final regions = response.document?.querySelectorAll(
        '[aria-live="polite"]',
      );

      expect(regions, hasLength(1));
      expect(
        response.document?.querySelector('[id^="coui-drag-scope"]'),
        isNull,
      );
    });

    testServer('announcements: false renders no region', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const DragScope(announcements: false, child: Text('scoped')),
        ),
      );
      final response = await tester.request('/');

      expect(
        response.document?.querySelectorAll('[aria-live="polite"]'),
        isEmpty,
      );
    });
  });
}
