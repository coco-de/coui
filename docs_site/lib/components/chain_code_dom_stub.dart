/// 서버/비-web 스텁 — SSG 경로에서 DOM 은 없다 (no-op / null).
library;

/// [id] 요소의 textContent — 서버 경로에서는 항상 `null`.
String? readElementText(String id) => null;

/// [id] 요소의 textContent 교체 — 서버 경로 no-op.
void writeElementText(String id, String text) {}

/// [id] 요소의 attribute 세팅 — 서버 경로 no-op.
void setElementAttribute(String id, String name, String value) {}

/// [copyElementId] 가 속한 코드 헤더의 활성 탭 이름 — 서버 경로 `null`.
String? activeCodeTab(String copyElementId) => null;

/// 현재 URL 의 [name] 쿼리 파라미터 — 서버 경로에서는 항상 `null`.
String? readQueryParam(String name) => null;

/// [name] 쿼리 파라미터를 [value] 로 교체(`null` 이면 제거)하는
/// history.replaceState — 서버 경로 no-op.
void writeQueryParam(String name, String? value) {}
