@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, CoreBreakpointTier, ThemeData, kTypographyTierAttribute;
import 'package:docs_core/components/web_preview.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// Web 프리뷰 팬이 **렌더된 HTML 로** 어떤 모양인지 본다.
///
/// 프리뷰 CSS(`docs_core/lib/site_head.dart`)는 팬의 `CoUIWeb` 루트를 팬
/// 요소의 직계 자식으로 고른다(`#web-… > div.w-full`). 둘 사이에 무엇이든
/// 끼면 가운데 정렬 · 꽉 채움 · 폭 상한이 조용히 꺼지는데, 렌더는 그대로라
/// 소스를 읽는 테스트로는 보이지 않는다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  Future<DocumentResponse> renderPane(ServerTester tester) {
    tester.pumpComponent(
      CoUIWeb(
        theme: ThemeData.coui,
        child: div(classes: 'preview-content', const [
          WebPreview(component: 'button'),
        ]),
      ),
    );
    return tester.request('/');
  }

  testServer('CoUIWeb 루트가 팬 요소의 직계 자식이다', (tester) async {
    final response = await renderPane(tester);

    expect(
      response.document!.querySelector(
        '.preview-content > div[id^="web-"] > div.coui-root.w-full',
      ),
      isNotNull,
      reason: '프리뷰 CSS 가 고르는 체인 — 팬과 루트 사이에 래퍼가 끼면 끊긴다',
    );
  });

  testServer('팬 요소가 제목을 데스크톱 단계로 고정한다', (tester) async {
    final response = await renderPane(tester);
    final pane = response.document!.querySelector(
      '.preview-content > div[id^="web-"]',
    );

    // 컴포넌트를 저작한 크기로 보여 주는 팬이다 — 옆의 Flutter 팬도 같은
    // 단계로 고정한다.
    expect(pane, isNotNull);
    expect(
      pane!.attributes[kTypographyTierAttribute],
      CoreBreakpointTier.desktop.name,
    );
  });
}
