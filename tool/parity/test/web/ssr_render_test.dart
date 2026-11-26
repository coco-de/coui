import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart'
    show BuildContext, Component, StatelessComponent;
import 'package:jaspr/server.dart'
    show
        Element,
        MarkupRenderElement,
        MarkupRenderObject,
        RenderAdapter,
        RenderObjectElement,
        ServerAppBinding;
import 'package:jaspr_test/server_test.dart';

import '../../src/web/ssr_render.dart';

void main() {
  group('renderComponentToDocumentHtml', () {
    testServer(
      "matches jaspr_test's ServerTester byte-for-byte for the same component",
      (tester) async {
        Component buildProbe() => const div(
          [],
          id: 'probe',
          classes: 'bg-primary text-on-primary rounded-radius16',
        );

        final custom = await renderComponentToDocumentHtml(buildProbe());

        tester.pumpComponent(buildProbe());
        final viaServerTester = (await tester.request('/')).body;

        expect(custom, viaServerTester);
      },
    );

    test('a component tree renders its classes and text content', () async {
      final html = await renderComponentToDocumentHtml(
        const div(
          [Component.text('hello')],
          id: 'probe',
          classes: 'bg-primary',
        ),
      );
      expect(html, contains('id="probe"'));
      expect(html, contains('bg-primary'));
      expect(html, contains('hello'));
    });
  });

  group('renderComponentBodyHtml', () {
    test(
      'returns only the body inner content, not the surrounding document',
      () async {
        final body = await renderComponentBodyHtml(
          const div([], id: 'probe', classes: 'bg-primary'),
        );
        expect(body, contains('id="probe"'));
        expect(body, isNot(contains('<!doctype')));
        expect(body, isNot(contains('<html')));
        expect(body, isNot(contains('<head>')));
        expect(body, isNot(contains('<body>')));
      },
    );
  });
  group('mounted root observer', () {
    test(
      'reads the actual root once without replay or markup changes',
      () async {
        var builds = 0;
        var observations = 0;
        var responses = 0;
        const content = Component.element(
          tag: 'div',
          id: 'current-probe',
          children: [Component.text('actual current content')],
        );
        final probe = _CountingSsrProbe(
          content,
          onBuild: () => builds++,
          onResponse: () => responses++,
        );
        Element? observedRoot;
        MarkupRenderObject? observedMarkup;
        final html = await renderComponentToDocumentHtml(
          probe,
          onMountedRoot: (root) {
            observations++;
            expect(builds, 1);
            expect(responses, 0);
            expect(root.binding.rootElement, same(root));
            final producer = _oneCurrentComponent(root, probe);
            expect(producer.component, same(probe));
            final rootElement = root as RenderObjectElement;
            final markup = rootElement.renderObject as MarkupRenderObject;
            final before = markup.renderToHtml();
            expect(
              _oneCurrentComponent(root, content).component,
              same(content),
            );
            expect(markup.renderToHtml(), before);
            expect(rootElement.renderObject, same(markup));
            observedRoot = root;
            observedMarkup = markup;
          },
        );
        expect(observations, 1);
        expect(builds, 1);
        expect(responses, 1);
        expect(observedRoot, isNotNull);
        expect(observedRoot!.binding.rootElement, same(observedRoot));
        expect(
          (observedRoot! as RenderObjectElement).renderObject,
          same(observedMarkup),
        );
        expect(html, contains('id="current-probe"'));
        expect(html, contains('actual current content'));
      },
    );

    test('body renderer forwards the same current observer once', () async {
      var builds = 0;
      var observations = 0;
      const content = Component.element(tag: 'div', id: 'body-observer');
      final probe = _CountingSsrProbe(content, onBuild: () => builds++);
      final body = await renderComponentBodyHtml(
        probe,
        onMountedRoot: (root) {
          observations++;
          expect(_oneCurrentComponent(root, probe).component, same(probe));
          expect(builds, 1);
        },
      );
      expect(observations, 1);
      expect(builds, 1);
      expect(body, contains('id="body-observer"'));
      expect(body, isNot(contains('<!doctype')));
      expect(body, isNot(contains('<body>')));
    });

    test('rejects an observer that changes actual rendered markup', () async {
      var observations = 0;
      const content = Component.element(tag: 'div', id: 'mutation-probe');
      await expectLater(
        renderComponentToDocumentHtml(
          content,
          onMountedRoot: (root) {
            observations++;
            final element = _oneCurrentComponent(root, content);
            final markup =
                (element as RenderObjectElement).renderObject
                    as MarkupRenderElement;
            markup.attributes = {
              ...?markup.attributes,
              'data-observer-write': 'forbidden',
            };
          },
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('observer changed rendered HTML'),
          ),
        ),
      );
      expect(observations, 1);
    });

    test('forwards the original observer error after the response', () async {
      var builds = 0;
      var observations = 0;
      var responses = 0;
      final failure = StateError('observer failure');
      final originalStack = StackTrace.fromString(
        'SSR observer original stack',
      );
      final probe = _CountingSsrProbe(
        const Component.element(tag: 'div', id: 'error-probe'),
        onBuild: () => builds++,
        onResponse: () => responses++,
      );
      try {
        await renderComponentToDocumentHtml(
          probe,
          onMountedRoot: (root) {
            observations++;
            expect(_oneCurrentComponent(root, probe).component, same(probe));
            expect(responses, 0);
            Error.throwWithStackTrace(failure, originalStack);
          },
        );
        fail('The observer error must reach the caller.');
      } on Object catch (error, stack) {
        expect(error, same(failure));
        expect(stack.toString(), contains('SSR observer original stack'));
      }
      expect(observations, 1);
      expect(builds, 1);
      expect(responses, 1);
    });
  });
}

Element _oneCurrentComponent(Element root, Component component) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, component)) {
      matches.add(element);
    }
    element.visitChildren(visit);
  }

  visit(root);
  expect(matches, hasLength(1));
  return matches.single;
}

class _CountingSsrProbe extends StatelessComponent {
  const _CountingSsrProbe(this.child, {required this.onBuild, this.onResponse});

  final Component child;
  final void Function() onBuild;
  final void Function()? onResponse;

  @override
  Component build(BuildContext context) {
    onBuild();
    final afterResponse = onResponse;
    if (afterResponse != null) {
      (context.binding as ServerAppBinding).addRenderAdapter(
        _ResponseCompletion(afterResponse),
      );
    }
    return child;
  }
}

final class _ResponseCompletion extends RenderAdapter {
  _ResponseCompletion(this.onResponse);

  final void Function() onResponse;

  @override
  void apply(MarkupRenderObject root) => onResponse();
}
