@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, ThemeData;
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

/// 레지스트리의 모든 페이지(v2)가 선언한 장면이 서버 렌더에서 그려지는가.
///
/// 장면 이름 · 속성 · 예제 이름이 틀리면 페이지는 에러 없이 "미리보기 없음"
/// 을 그린다. 기준 페이지 둘만 보던 렌더 테스트는 새 페이지의 그 실수를 볼 수
/// 없었다 — 여기서는 페이지를 레지스트리에서 읽어 전부 돈다. 같은 검사의
/// Flutter 쪽은 `docs_core/test/shared/preview_scene_render_test.dart` 다.
void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));

  final pages = kDocsPlaygrounds.keys.toList()..sort();
  test('레지스트리의 페이지를 돈다', () => expect(pages, containsAll(['button', 'text-field'])));

  for (final page in pages) {
    final scenes = readDocsScenes(page);
    testServer('$page — 선언한 장면 ${scenes.length}개가 모두 그려진다', (tester) async {
      expect(scenes, isNotEmpty);
      for (final scene in scenes) {
        tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: renderWebScene(scene)));
        final document = (await tester.request('/')).document!;
        expect(
          document.querySelectorAll('.preview-unavailable').map((element) => element.text),
          isEmpty,
          reason: scene.origins.first,
        );
      }
    });
  }
}
