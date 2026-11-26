// #3605 — headless server-side render, without the `dart test` runner.
//
// `jaspr_test`'s `ServerTester` (used by SPIKE-3's own tests, see
// `offline_tailwind_harness_test.dart`) is the architecture doc's named
// mechanism ("jaspr_test 서버 렌더"), but its constructor is private
// (`ServerTester._()`) and it is only reachable through `testServer()`,
// which registers a `package:test` test case — it cannot be called from a
// plain `dart run` `main()` the way this CLI's contract
// (`dart run tool/parity/capture_web.dart`) requires.
//
// `ServerTester._start()` itself is built entirely from public
// `package:jaspr/server.dart` primitives (`ServerApp.createTestHandler` is
// a public alias for the same `createHandler` used everywhere else in
// Jaspr's own server pipeline). This file calls those same primitives
// directly, and `ssr_render_test.dart` asserts the output matches what
// `ServerTester.request()` produces for the same component — so the
// render mechanism is the one `jaspr_test` uses, only reached without
// needing the test runner's zone.
import 'package:html/parser.dart' as html_parser;
import 'package:jaspr/server.dart' hide Document;

const int _kHttpOk = 200;

/// How much of a failed SSR document to echo in an error message — enough
/// to see whether the root cause is visible near the top (a missing
/// ambient context assertion, a stack trace jaspr wrote inline), not the
/// whole document.
const int _kErrorPreviewLength = 200;

/// Server-renders [component] to a full HTML document string.
///
/// Optional [onMountedRoot] runs synchronously once on the actual first
/// post-frame root. It must only read the public mounted tree. The same
/// root/render object and its markup must remain unchanged. The observer's
/// first failure is forwarded after the actual SSR response is consumed.
/// This local identity hook does not support `Jaspr.useIsolates`.
Future<String> renderComponentToDocumentHtml(
  Component component, {
  void Function(Element root)? onMountedRoot,
}) async {
  // The observer needs the caller's actual Component identities. An isolate
  // copies the callback and captured state instead of sharing that mount.
  if (onMountedRoot != null && Jaspr.useIsolates) {
    throw StateError('Mounted SSR observation requires local rendering.');
  }
  Object? observerError;
  StackTrace? observerStack;
  var observerCalls = 0;
  final options = Jaspr.options;
  final handler = ServerApp.createTestHandler(
    (request, render) => render((binding) {
      if (onMountedRoot != null) {
        binding.addPostFrameCallback(() {
          try {
            if (observerCalls != 0) {
              throw StateError('Mounted SSR observer was scheduled twice.');
            }
            final root = binding.rootElement;
            if (root == null || root.renderObject is! MarkupRenderObject) {
              throw StateError('Mounted SSR root markup is unavailable.');
            }
            final rootComponent = root.component;
            final markup = root.renderObject as MarkupRenderObject;
            final before = markup.renderToHtml();
            observerCalls++;
            try {
              onMountedRoot(root);
            } on Object catch (error, stack) {
              observerError = error;
              observerStack = stack;
            }
            if (!identical(root, binding.rootElement) ||
                !identical(root.component, rootComponent) ||
                !identical(markup, root.renderObject)) {
              throw StateError('Mounted SSR observer changed root identity.');
            }
            if (before != markup.renderToHtml()) {
              throw StateError('Mounted SSR observer changed rendered HTML.');
            }
          } on Object catch (error, stack) {
            // Let Jaspr finish this actual response, including later frame
            // callbacks. Forward the first failure below with its stack.
            observerError ??= error;
            observerStack ??= stack;
          }
        });
      }
      binding
        ..initializeOptions(options)
        ..attachRootComponent(component);
    }),
    fileHandler: (request) => Response.notFound('Not Found'),
  );

  final response = await handler(
    Request('GET', Uri.parse('http://parity.test/')),
  );
  String? observedDocumentHtml;
  if (onMountedRoot != null) {
    observedDocumentHtml = await response.readAsString();
    final error = observerError;
    if (error != null) {
      Error.throwWithStackTrace(error, observerStack!);
    }
    if (observerCalls != 1) {
      throw StateError('Mounted SSR observer did not run exactly once.');
    }
  }
  if (response.statusCode != _kHttpOk) {
    throw StateError(
      'SSR 렌더가 ${response.statusCode} 를 돌려줌 — 컴포넌트 build 중 '
      '예외가 났을 가능성이 높다.',
    );
  }

  if (observedDocumentHtml != null) {
    return observedDocumentHtml;
  }
  return await response.readAsString();
}

/// Server-renders [component] and returns only the `<body>` inner HTML —
/// the fragment `buildOfflineTailwindHarnessHtml`'s `bodyHtml` expects.
/// Jaspr's SSR always emits a full `<!doctype html><html>...</html>`
/// document regardless of what [component] is (proven above); the harness
/// supplies its own `<head>`/`<html>`, so only the inner content survives.
Future<String> renderComponentBodyHtml(
  Component component, {
  void Function(Element root)? onMountedRoot,
}) async {
  final documentHtml = await renderComponentToDocumentHtml(
    component,
    onMountedRoot: onMountedRoot,
  );
  final parsed = html_parser.parse(documentHtml);
  final body = parsed.body;
  if (body == null) {
    final previewLength = documentHtml.length.clamp(0, _kErrorPreviewLength);
    throw StateError(
      'SSR 출력에 <body> 가 없음 — 렌더가 실패했거나 문서 구조가 예상과 '
      '다르다. 출력 앞부분: ${documentHtml.substring(0, previewLength)}',
    );
  }

  return body.innerHtml;
}
