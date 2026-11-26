// The thumb this component draws is a decorative box with no role of its
// own, and the scroller it moves is not the place for one, so the phantom
// `role="scrollbar"` nodes are only visible from the rendered markup.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_style.dart'
    show kScrollbarLayerClass;
import 'package:jaspr_test/server_test.dart';

Component _scrollbar({
  CoreScrollbarAxis axis = .defaultAxis,
  CoreScrollbarVisibility visibility = .defaultVisibility,
  bool interactive = true,
  String? id,
}) => Scrollbar(
  axis: axis,
  id: id,
  visibility: visibility,
  interactive: interactive,
  child: const Component.element(
    tag: 'div',
    children: [Component.text('content')],
  ),
);

void main() {
  group('Scrollbar accessibility (#3494)', () {
    testServer('phantom role stays outside clickable content (#5265)', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Scrollbar(
            axis: .vertical,
            id: 'sb',
            child: Component.element(
              tag: 'button',
              attributes: {'type': 'button'},
              children: [Component.text('Select cat')],
            ),
          ),
        ),
      );
      final response = await tester.request('/');
      final root = response.document!.querySelector('#sb')!;
      final node = root.querySelector('[role="scrollbar"]')!;
      final button = root.querySelector('button')!;
      expect(node.className, contains('sr-only'));
      expect(node.parent, same(root));
      expect(node.querySelector('button'), isNull);
      expect(button.text, 'Select cat');
      expect(node.attributes.containsKey('tabindex'), isFalse);
      expect(node.attributes['aria-controls'], root.id);
    });

    testServer('vertical axis exposes exactly one role="scrollbar" node', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _scrollbar(axis: .vertical, id: 'sb'),
        ),
      );
      final response = await tester.request('/');
      final nodes = response.document?.querySelectorAll(
        '[role="scrollbar"]',
      );

      expect(nodes, hasLength(1));
      final node = nodes!.single;
      expect(node.attributes['aria-orientation'], 'vertical');
      expect(node.attributes['aria-valuenow'], '0');
      expect(node.attributes['aria-valuemin'], '0');
      expect(node.attributes['aria-valuemax'], '100');
      expect(node.attributes['aria-controls'], 'sb');
    });

    testServer('horizontal axis exposes exactly one role="scrollbar" node', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _scrollbar(axis: .horizontal, id: 'sb'),
        ),
      );
      final response = await tester.request('/');
      final nodes = response.document?.querySelectorAll(
        '[role="scrollbar"]',
      );

      expect(nodes, hasLength(1));
      expect(nodes!.single.attributes['aria-orientation'], 'horizontal');
    });

    testServer(
      'both axis exposes one role="scrollbar" node per axis',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _scrollbar(id: 'sb'),
          ),
        );
        final response = await tester.request('/');
        final nodes = response.document?.querySelectorAll(
          '[role="scrollbar"]',
        );

        expect(nodes, hasLength(2));
        final orientations = nodes!
            .map((e) => e.attributes['aria-orientation'])
            .toSet();
        expect(orientations, {'vertical', 'horizontal'});
        // Both report on the same scrollable root.
        for (final node in nodes) {
          expect(node.attributes['aria-controls'], 'sb');
        }
      },
    );

    testServer(
      'the phantom node is visually hidden but present in the DOM',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _scrollbar(axis: .vertical, id: 'sb'),
          ),
        );
        final response = await tester.request('/');
        final node = response.document?.querySelector('[role="scrollbar"]');

        expect(node?.className, contains('sr-only'));
      },
    );
  });

  // `interactive` used to stop at `overscroll-behavior` — the phantom
  // node's markup was byte-identical either way, while the Flutter twin
  // gated its increase/decrease actions on the same flag. And `hidden`
  // kept its node here while Flutter dropped one. Both halves of the
  // pair are locked from this side too, so a future edit cannot fix one
  // platform and leave the other.
  group('Scrollbar accessibility across visibility / interactive (#3983)', () {
    for (final visibility in CoreScrollbarVisibility.values) {
      testServer(
        'visibility ${visibility.name} still exposes the role="scrollbar" '
        'node',
        (tester) async {
          tester.pumpComponent(
            CoUIWeb(
              theme: .coui,
              child: _scrollbar(
                axis: .vertical,
                visibility: visibility,
                id: 'sb',
              ),
            ),
          );
          final response = await tester.request('/');
          final nodes = response.document?.querySelectorAll(
            '[role="scrollbar"]',
          );

          expect(
            nodes,
            hasLength(1),
            reason:
                'visibility ${visibility.name} hides pixels, not the '
                'accessibility node',
          );
          final node = response.document?.querySelector('[role="scrollbar"]');
          expect(node?.attributes['aria-valuenow'], '0');

          // Proves the value under test actually arrived. The phantom
          // node is (deliberately) identical across all four modes, so
          // without this the loop would keep passing even if `visibility`
          // stopped being forwarded to the component at all — four copies
          // of one assertion rather than four cases. What differs is the
          // drawn thumb: `hidden` has no layer to hold one, `thin` is a
          // 3px thumb (a 7px footprint), `auto` / `always` a 6px one (10px),
          // and only `auto` rests invisible.
          final layer = response.document?.querySelector(
            '#sb .$kScrollbarLayerClass',
          );
          final style = response.document?.querySelector('#sb style')?.text;
          switch (visibility) {
            case .hidden:
              expect(layer, isNull);
              expect(style, isNot(contains(kScrollbarLayerClass)));
            case .thin:
              expect(layer, isNotNull);
              expect(style, contains('width: 0.4375rem'));
              expect(style, contains('opacity: 0;'));
            case .auto:
              expect(layer, isNotNull);
              expect(style, contains('width: 0.625rem'));
              expect(style, contains('opacity: 0;'));
            case .always:
              expect(layer, isNotNull);
              expect(style, contains('width: 0.625rem'));
              expect(style, isNot(contains('opacity: 0;')));
          }
        },
      );
    }

    testServer('a non-interactive scrollbar states aria-disabled', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _scrollbar(axis: .vertical, interactive: false, id: 'sb'),
        ),
      );
      final response = await tester.request('/');
      final node = response.document?.querySelector('[role="scrollbar"]');

      expect(node?.attributes['aria-disabled'], 'true');
      // Reading the position is not operating the bar — `interactive`
      // gates the second, never the first.
      expect(node?.attributes['aria-valuenow'], '0');
    });

    testServer('an interactive scrollbar states no aria-disabled', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _scrollbar(axis: .vertical, id: 'sb'),
        ),
      );
      final response = await tester.request('/');
      final node = response.document?.querySelector('[role="scrollbar"]');

      expect(node?.attributes.containsKey('aria-disabled'), isFalse);
    });

    testServer('both axes carry aria-disabled when non-interactive', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _scrollbar(interactive: false, id: 'sb'),
        ),
      );
      final response = await tester.request('/');
      final nodes = response.document?.querySelectorAll('[role="scrollbar"]');

      expect(nodes, hasLength(2));
      for (final node in nodes!) {
        expect(node.attributes['aria-disabled'], 'true');
      }
    });

    testServer(
      'hidden and non-interactive still reports the position, without '
      'advertising an operation',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _scrollbar(
              axis: .vertical,
              visibility: .hidden,
              interactive: false,
              id: 'sb',
            ),
          ),
        );
        final response = await tester.request('/');
        final node = response.document?.querySelector('[role="scrollbar"]');

        expect(node, isNotNull);
        expect(node!.attributes['aria-valuenow'], '0');
        expect(node.attributes['aria-disabled'], 'true');
      },
    );

    // The phantom node is `sr-only`: focusing it would put keyboard
    // focus on a 1px clipped element with no visible indicator. Moving
    // the scroll position from the keyboard is browser-native on the
    // `overflow: auto` root instead, so the Flutter twin's hand-built
    // increase/decrease has a native counterpart rather than a missing
    // one. Locked so "reach parity with Flutter" is never read as
    // "add a tab stop nobody can see".
    testServer('the phantom node is never a keyboard tab stop', (
      tester,
    ) async {
      for (final interactive in [true, false]) {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: _scrollbar(
              axis: .vertical,
              interactive: interactive,
              id: 'sb',
            ),
          ),
        );
        final response = await tester.request('/');
        final node = response.document?.querySelector('[role="scrollbar"]');

        expect(
          node?.attributes.containsKey('tabindex'),
          isFalse,
          reason:
              'interactive: $interactive must not add an invisible '
              'focus target',
        );
      }
    });
  });
}
