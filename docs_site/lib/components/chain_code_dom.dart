/// SSR-safe 코드 패널 DOM 접근.
///
/// `web_navigation.dart` 와 같은 분할: 서버/비-web 빌드는 inert stub,
/// 브라우저 빌드만 실제 DOM 호출을 받는다 — 서버 컴파일 타깃이
/// `package:web` 을 resolve 하지 않게 하기 위함이다. 셔플 컨트롤이
/// 코드 패널(`<code>`)의 textContent 를 읽고/바꾸고 copy 버튼의
/// `data-code` 를 갱신하는 데 쓴다 — textContent/attribute 만 만지고
/// innerHTML·eval 은 없다.
library;

export 'chain_code_dom_stub.dart' if (dart.library.js_interop) 'chain_code_dom_web.dart';
