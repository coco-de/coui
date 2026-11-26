@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/shared/component_catalog.dart';
import 'package:docs_site/components/component_grid.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 갤러리가 **렌더된 HTML 로** 무엇을 내는지 본다.
///
/// 소스에서 카탈로그를 참조한다는 사실은 그 참조가 화면에 도달했다는
/// 증거가 아니다 — 참조해 놓고 렌더하지 않아도 그런 테스트는 통과한다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final allItems = [
    for (final group in kDocsComponentGroups) ...group.items,
  ];

  Future<DocumentResponse> renderGallery(ServerTester tester) {
    tester.pumpComponent(
      CoUIWeb(theme: ThemeData.coui, child: const ComponentGridView()),
    );
    return tester.request('/');
  }

  group('컴포넌트 갤러리 서버 렌더', () {
    testServer('모든 컴포넌트가 카드, 하위 링크 또는 유틸리티 행으로 나온다', (tester) async {
      final response = await renderGallery(tester);
      expect(response.statusCode, 200);

      expect(
        response.document!.querySelectorAll('a.showcase-title, a.catalog-member, a.catalog-utility'),
        hasLength(allItems.length),
        reason: '카탈로그의 모든 문서는 링크가 하나씩 있어야 한다',
      );
    });

    testServer('모든 갤러리 링크는 실제 컴포넌트 문서로 이동한다', (tester) async {
      final response = await renderGallery(tester);
      final hrefs = response.document!
          .querySelectorAll('a.showcase-title, a.catalog-member, a.catalog-utility')
          .map((e) => e.attributes['href'])
          .toSet();

      // 링크여야 크롤되고, 새 탭으로 열리고, 스크린 리더가 링크로
      // 읽는다. `Card.onTap` 은 그 셋 중 아무것도 주지 않는다.
      for (final item in allItems) {
        expect(
          hrefs,
          contains('/components/${item.slug}'),
          reason: '${item.name} 카드가 링크가 아니다',
        );
      }
    });

    testServer('그룹 제목이 앵커 id 를 유지한다', (tester) async {
      final response = await renderGallery(tester);
      final ids = response.document!
          .querySelectorAll('.showcase-group-header h2[id]')
          .map((e) => e.attributes['id'])
          .toSet();

      // 헤더 내비게이션이 `/components-overview#${group.id}` 를
      // 가리킨다. id 가 사라지면 그 링크들이 페이지 상단으로 떨어지고,
      // 아무것도 에러를 내지 않는다.
      for (final group in kDocsComponentGroups) {
        expect(ids, contains(group.id), reason: '${group.title} 앵커가 없다');
      }
    });

    testServer('빈 프리뷰가 없다', (tester) async {
      final response = await renderGallery(tester);
      final empty = response.document!.querySelectorAll('.showcase-preview').where((e) => e.children.isEmpty).length;

      // 레지스트리 누락은 조용한 빈 칸으로 나타난다. #4979 측정 시점에
      // 144/144 가 서버 렌더에 성공했고, 이 테스트가 그것을 지킨다.
      expect(empty, 0, reason: '프리뷰가 비어 있는 카드가 $empty 개다');
      expect(
        kWebPreviewRegistry.length,
        greaterThanOrEqualTo(allItems.length),
        reason: '레지스트리가 카탈로그보다 작다 — 누락이 생겼다',
      );
    });

    testServer('갤러리 썸네일이 키보드 탐색과 자동 포커스에서 제외된다', (tester) async {
      final response = await renderGallery(tester);
      final previews = response.document!.querySelectorAll('.showcase-preview');

      for (final preview in previews) {
        expect(preview.attributes.containsKey('inert'), isTrue);
        expect(preview.attributes['aria-hidden'], 'true');
      }
      expect(
        response.document!.querySelectorAll('[inert] [autofocus]'),
        hasLength(response.document!.querySelectorAll('[autofocus]').length),
      );
    });

    // ── 무게 게이트 ─────────────────────────────────────────────
    //
    // #4979 실측: 프리뷰만 35.8 KiB gzip, 카드 chrome 까지 붙여
    // **47.5 KiB gzip** (785.8 KiB raw). 압축비가 6% 대인 이유는
    // 마크업이 압도적으로 반복되는 Tailwind 클래스 문자열이기 때문이다.
    //
    // 전송되는 것은 gzip 쪽이므로 그쪽에 게이트를 건다. raw 는 재기만
    // 하고 막지 않는다 — 클래스 문자열이 길어지는 것은 그 자체로
    // 문제가 아니고, 압축이 흡수한다.
    //
    // 카드 162개 기준 실측은 **78.9 KiB gzip** 이다(카드당 0.49 KiB). 카드가
    // 144개였을 때 47.5 KiB(카드당 0.33)였고, 늘어난 것은 카드 수와 카드 한
    // 장의 크기 둘 다다 — 새로 들어온 복합 컴포넌트(편집기 · 사이드바 ·
    // 바텀시트 · 숫자 입력 · 스와이프 액션 …)의 프리뷰가 위쪽을 차지하고,
    // 가장 무거운 카드도 3.9 KiB 로 한 장이 튀어 나온 곳은 없다.
    //
    // 96 KiB 는 그 측정값 위의 여유다. 이걸 넘기면 다시 "카드 하나가
    // 무거워졌나"를 카드별로 들여다볼 값어치가 있다.
    testServer('갤러리 gzip 무게가 게이트 안에 있다', (tester) async {
      final response = await renderGallery(tester);
      final gzipKib = gzip.encode(utf8.encode(response.body)).length / 1024;

      expect(
        gzipKib,
        lessThan(96),
        reason:
            '갤러리가 ${gzipKib.toStringAsFixed(1)} KiB(gzip)로 커졌다 — '
            '카드 ${allItems.length}개 기준 측정값은 78.9 KiB 였다',
      );
    });
  });
}
