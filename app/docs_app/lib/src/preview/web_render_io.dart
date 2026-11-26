/// 네이티브(dart:io)용 [renderWebPreviewHtml] 구현.
///
/// Jaspr 서버 렌더러로 docs_site 의 `EmbedPage` 를 HTTP 서버 없이 완전한
/// HTML 문서로 렌더한다. `EmbedPage` 는 `/embed` 라우트가 그리는 바로 그
/// 컴포넌트라, Tailwind/폰트 CDN·CoUI CSS 변수·테마·프리뷰 호스트 CSS 가
/// 사이트와 동일하게 들어간다 — 차이는 "서버로 서빙" 대신 "in-process 렌더"
/// 뿐이다.
library;

import 'dart:convert';
import 'dart:io';

import 'package:docs_core/embed/embed_page.dart';
import 'package:jaspr/server.dart';

var _initialized = false;

/// Jaspr 서버 렌더러가 `pubspec.yaml` 을 못 찾아 던지는 걸 막는다.
///
/// 정적 파일 핸들러를 구성하려고 `renderComponent` 가 현재 디렉터리에서 위로
/// 걸어 올라가며 `pubspec.yaml` 을 찾는데, 패키지된 앱(Android/iOS)에는 그게
/// 없어서 예외가 난다 (데스크톱은 cwd 에 pubspec 이 있어 우연히 통과). 유일한
/// public API 인 `renderComponent` 로는 이 경로를 우회할 수 없으므로, 쓰기
/// 가능한 temp 디렉터리에 빈 마커 `pubspec.yaml` 을 두고 cwd 를 그리로 옮겨
/// 탐색이 성공하게 한다. 프리뷰는 CDN 만 쓰므로 정적 핸들러가 실제로 파일을
/// 요구하지 않는다 — 마커의 `web/` 이 없어 404 를 내도 렌더에는 영향이 없다.
///
/// Jaspr 이 project dir 을 **최초 렌더 시 한 번** 계산해 캐시하므로, 반드시
/// 첫 `renderComponent` 전에 cwd 를 옮겨둬야 한다.
void _ensureRenderableCwd() {
  final marker = Directory('${Directory.systemTemp.path}/docs_app_jaspr')
    ..createSync(recursive: true);
  File(
    '${marker.path}/pubspec.yaml',
  ).writeAsStringSync('name: docs_app_jaspr_marker\n');
  Directory.current = marker.path;
}

/// [component] (+선택적 [variant]) 의 Web 프리뷰를 완전한 HTML 문서로 렌더한다.
///
/// 실패하면 `null` — 호출부가 안내로 저하한다.
Future<String?> renderWebPreviewHtml({
  required String component,
  required bool dark,
  String? variant,
  int? chainStep,
}) async {
  // 여기서는 예외를 삼키지 않는다 — 호출부(web_pane)가 잡아 실제 사유를
  // 화면에 노출한다. 그래야 플랫폼별 실패를 진단할 수 있다.
  if (!_initialized) {
    _ensureRenderableCwd();
    // 정적 SSR 렌더에는 빈 옵션으로 충분하다 (@client 하이드레이션은 안
    // 하므로 clients 맵이 필요 없다). 한 번만 초기화한다.
    Jaspr.initializeApp();
    _initialized = true;
  }

  final response = await renderComponent(
    EmbedPage(
      component: component,
      variant: variant,
      dark: dark,
      chainStep: chainStep,
    ),
  );
  if (response.statusCode != HttpStatus.ok) return null;
  return utf8.decode(response.body);
}
