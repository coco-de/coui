/// 컴포넌트 페이지(v2 템플릿)의 합성 장면 — Jaspr Web.
///
/// 속성 하나로 표현되지 않는 미리보기(버튼 여러 개의 배치, 상태 격자,
/// 관련 컴포넌트)는 이름으로 고른다: `<Preview demo="button/states" />`.
/// 이름은 `<문서 슬러그>/<장면>` 이고, 같은 이름을 Flutter
/// (`flutter_doc_demos.dart`)가 갖는다.
///
/// 장면 안의 컴포넌트는 킷의 컴포넌트다. 장면을 담는 틀(다이얼로그 판,
/// 휴대폰 틀, 적용 순서 상자)은 문서의 그림이라 `docs-demo-*` 클래스로
/// 문서 시트가 그린다.
library;

export '../../pages/page_registry_web.g.dart' show kWebDocDemos;
