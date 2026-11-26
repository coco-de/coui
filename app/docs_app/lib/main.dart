/// CoUI 문서 앱 — docs_site 의 네이티브 Flutter 쌍둥이.
///
/// 같은 마크다운, 같은 컴포넌트 카탈로그, 같은 예제를 웹사이트가 아니라
/// Flutter 런타임에서 연다. Flutter 프리뷰는 네이티브로 그리고(사이트 쪽은
/// jaspr 에 임베드된 Flutter Web 이다), Web 프리뷰는 coui_web 컴포넌트를
/// 앱이 자기 프로세스에서 HTML 로 렌더해 WebView 로 띄운다.
///
/// ```sh
/// cd app/docs_app && flutter run   # 선택한 기기로
/// ```
///
/// 서버도 jaspr serve 도 필요 없다 — Web 프리뷰는 in-process 로 렌더한다
/// (`preview/web_render.dart`). 인터넷만 있으면 된다(폰트·Tailwind CDN).
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/content/content_repository.dart';
import 'package:docs_app/src/docs_app.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  final _ = WidgetsFlutterBinding.ensureInitialized();

  // 콘텐츠는 `docs_site` 가 asset 으로 노출한 원본이다 — 사본이 없다.
  final repository = DocsContentRepository(rootBundle);
  await repository.load();

  runApp(DocsApp(repository: repository));
}
