@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/internal/preview/web_playground_view.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 컨트롤이 없는 플레이그라운드는 컨트롤 열을 그리지 않는다.
///
/// 열을 그리면 테두리 친 빈 칸이 무대 옆에 남는다. 바꿔 볼 속성이 거의 없는
/// 컴포넌트는 줄인 플레이그라운드를 쓰므로, 그 페이지들이 컨트롤을 모두 빼는
/// 날 이 모양이 처음 나온다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final gap = kDocsPlaygrounds['gap']!;
  final bare = DocsPlaygroundSpec(initial: gap.initial, controls: const [], code: gap.code);

  Component view(DocsPlaygroundSpec spec) => buildWebPlaygroundRoot(
    buildWebPlaygroundView(
      componentName: 'gap',
      spec: spec,
      props: spec.initial,
      platform: DocsPlaygroundPlatform.web,
      showWeb: true,
      showFlutter: false,
      flutterContent: null,
      codeView: const Component.empty(),
      onSetProps: (_) {},
      onSetPlatform: (_) {},
    ),
  );

  testServer('컨트롤이 없으면 컨트롤 열이 없고 무대가 폭을 다 쓴다', (tester) async {
    tester.pumpComponent(view(bare));
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('.docs-playground-controls'), isEmpty);
    expect(document.querySelectorAll('.docs-playground-main.is-bare'), hasLength(1));
    expect(document.querySelectorAll('.docs-playground-stage'), hasLength(1));
  });

  testServer('컨트롤이 있으면 컨트롤 열을 그린다', (tester) async {
    tester.pumpComponent(view(gap));
    final document = (await tester.request('/')).document!;
    expect(document.querySelectorAll('.docs-playground-controls'), hasLength(1));
    expect(document.querySelectorAll('.docs-playground-main.is-bare'), isEmpty);
  });

  test('사이트 시트가 컨트롤 없는 칸을 한 열로 둔다', () {
    final css = File('web/docs-shell.css').readAsStringSync();
    expect(
      RegExp(r'\.docs-playground-main\.is-bare\s*\{\s*grid-template-columns:\s*minmax\(0,\s*1fr\);\s*\}').hasMatch(css),
      isTrue,
      reason: '.docs-playground-main 의 두 열(무대 · 컨트롤)이 컨트롤 없는 칸에도 남는다',
    );
  });
}
