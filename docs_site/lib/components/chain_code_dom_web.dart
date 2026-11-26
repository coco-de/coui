/// 브라우저 구현 — 조건부 export (`chain_code_dom.dart`) 로만 도달한다.
library;

import 'package:web/web.dart' as web;

/// [id] 요소의 textContent — 미발견이면 `null` (호출부가 skip).
String? readElementText(String id) => web.document.getElementById(id)?.textContent;

/// [id] 요소의 textContent 교체 — 미발견이면 조용히 skip
/// (코드 요소 id 미발견 시 코드 갱신 skip 계약).
void writeElementText(String id, String text) {
  web.document.getElementById(id)?.textContent = text;
}

/// [id] 요소의 attribute 세팅 — 미발견이면 조용히 skip.
void setElementAttribute(String id, String name, String value) {
  web.document.getElementById(id)?.setAttribute(name, value);
}

/// [copyElementId] 가 속한 코드 헤더의 활성 탭 이름(`web`/`flutter`) —
/// copy `data-code` 는 **지금 보이는 코드**를 담아야 하므로(활성 탭 추종)
/// 셔플이 어느 탭의 치환 결과를 기록할지 여기서 판정한다.
String? activeCodeTab(String copyElementId) => web.document
    .getElementById(copyElementId)
    ?.closest('.preview-code')
    ?.querySelector('.preview-code-tab--active')
    ?.getAttribute('data-tab');

/// 현재 URL 의 [name] 쿼리 파라미터 — 없으면 `null`.
String? readQueryParam(String name) => Uri.parse(web.window.location.href).queryParameters[name];

/// [name] 쿼리 파라미터를 [value] 로 교체한다 (`null` 이면 제거) —
/// `history.replaceState` 라 내비게이션·스크롤 위치를 건드리지 않는다.
/// 순열 딥링크(공유·버그 재현)용: 셔플할 때마다 URL 이 현재 좌표를 담는다.
void writeQueryParam(String name, String? value) {
  final uri = Uri.parse(web.window.location.href);
  final params = {...uri.queryParameters};
  if (value == null) {
    if (!params.containsKey(name)) return;
    params.remove(name);
  } else {
    params[name] = value;
  }
  final next = uri.replace(queryParameters: params.isEmpty ? null : params);
  // queryParameters 가 비면 `?` 잔재 없이 경로만 남긴다.
  web.window.history.replaceState(null, '', next.toString());
}
