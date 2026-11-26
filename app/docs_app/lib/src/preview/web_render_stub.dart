/// 네이티브가 아닌(non-`dart:io`) 환경용 [renderWebPreviewHtml] 폴백
/// (Flutter Web 등).
///
/// Jaspr 서버 렌더러는 `dart:io` 에 의존하므로 여기서는 렌더할 수 없다.
/// 여기서 `null` 을 돌려주면 Web 페인이 안내로 저하한다.
library;

/// 이 플랫폼에서는 in-process 렌더가 불가능하다 — 항상 `null`.
Future<String?> renderWebPreviewHtml({
  required String component,
  required bool dark,
  String? variant,
  int? chainStep,
}) => .value();
