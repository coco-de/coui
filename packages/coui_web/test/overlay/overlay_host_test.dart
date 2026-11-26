import 'package:coui_web/src/overlay/overlay_host.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr_test/jaspr_test.dart';

/// Finds `<div>` components carrying the page-level backdrop target
/// attribute (`data-coui-backdrop`).
Finder _backdropWrappers({bool layoutNeutral = false}) =>
    find.byComponentPredicate(
      (component) =>
          component is div &&
          (component.attributes?.containsKey('data-coui-backdrop') ?? false) &&
          (!layoutNeutral || component.classes == 'contents'),
    );

/// Finds anonymous `contents` carrier `<div>`s — no id, no attributes,
/// only the `contents` class. The host must never emit one: stacked on
/// the backdrop wrapper it puts app content under TWO nested
/// `display: contents` boxes, and Chromium's shrink-to-fit intrinsic
/// sizing collapses `w-full` descendants through nested `contents`
/// chains (components rendered at word width inside fit-content
/// ancestors). The host root is a DOM-less fragment instead.
Finder _anonymousContentsCarriers() => find.byComponentPredicate(
  (component) =>
      component is div &&
      component.classes == 'contents' &&
      component.id == null &&
      (component.attributes?.isEmpty ?? true),
);

void main() {
  group('OverlayHost DOM shape', () {
    testComponents(
      'the backdrop wrapper is layout-neutral (display: contents)',
      (tester) async {
        // The wrapper must NEVER be a layout box: a plain block <div>
        // becomes the flex item in whatever context hosts the subtree
        // and breaks the child's centering/width — the regression that
        // hit Toast / RefreshTrigger previews when their
        // nested hosts gained a block wrapper. The drawer's backdrop
        // transform flips the styled target to `display: block`
        // imperatively only while the effect runs.
        tester.pumpComponent(OverlayHost(child: span([], id: 'marker')));

        expect(_backdropWrappers(), findsOneComponent);
        expect(_backdropWrappers(layoutNeutral: true), findsOneComponent);
        // And the wrapper must be the ONLY `contents` layer above the
        // app content — an anonymous carrier div stacked on it makes
        // two nested `contents` boxes, which Chromium's intrinsic
        // sizing cannot see through (the RefreshTrigger / Toast
        // previews collapsed to word width inside their fit-content
        // scrollview anchor).
        expect(_anonymousContentsCarriers(), findsNothing);
      },
    );

    testComponents(
      'nested hosts stay layout-neutral too (preview-pane topology)',
      (tester) async {
        tester.pumpComponent(
          OverlayHost(
            child: OverlayHost(child: span([], id: 'marker')),
          ),
        );

        // Every wrapper — root and nested — must carry the
        // `contents` class; a single non-neutral wrapper anywhere
        // regresses arbitrary component layouts.
        expect(_backdropWrappers(), findsNComponents(2));
        expect(
          _backdropWrappers(layoutNeutral: true),
          findsNComponents(2),
        );
        expect(_anonymousContentsCarriers(), findsNothing);
      },
    );
  });
}
