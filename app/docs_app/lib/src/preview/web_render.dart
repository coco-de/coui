/// Web 프리뷰를 in-process 로 HTML 문자열로 렌더한다.
///
/// 네이티브(dart:io)에서는 jaspr 서버 렌더러로 coui_web 컴포넌트를 HTTP
/// 서버 없이 렌더하고, Flutter Web(dart:io 없음)에서는 `null` 로 저하한다 —
/// jaspr 서버 렌더러가 `dart:io` 를 쓰기 때문이다. 호출부는 두 경우를
/// 동일하게 다룬다: 문자열이면 `WebView.loadHtmlString`, `null` 이면 안내.
library;

export 'web_render_stub.dart' if (dart.library.io) 'web_render_io.dart';
