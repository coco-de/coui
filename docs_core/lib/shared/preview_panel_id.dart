/// 프리뷰 패널 DOM id 파생식 — **단일 출처**.
///
/// 순수 Dart 다: jaspr 도 Flutter 도 import 하지 않는다. 같은 파생식이
/// SSG(`live_preview.dart`) · Flutter 임베드 생성(`flutter_preview.dart`) ·
/// 임베드 높이 적용 JS(`preview_app.dart`) · Web 팬(`web_preview.dart`) ·
/// 셔플 컨트롤의 코드 패널 접근에 함께 쓰인다 — 파생식이 호출부마다
/// 손으로 복제되면 한 곳만 바뀌어 id 가 어긋나고, 그 증상은 "높이가 안
/// 적용된다 / 코드 패널이 안 바뀐다" 로 늦게 드러난다.
///
/// chain 패널은 같은 컴포넌트의 `<LivePreview>` 태그가 한 페이지에 여러 번
/// 나올 수 있어(복수 chain 패널) `component-variant` 파생으로는 id 가
/// 충돌한다 — SSG 가 부여한 인스턴스-유일 [panelId] 가 있으면 그것이
/// 파생의 근거가 된다.
library;

/// Flutter 임베드 컨테이너 id.
///
/// [panelId] 가 있으면(chain 패널) 인스턴스-유일 id, 없으면 기존
/// `flutter-{component}-{variant}` 파생 그대로.
String flutterEmbedElementId({
  required String component,
  String? variant,
  String? panelId,
}) => panelId != null ? 'flutter-$panelId' : 'flutter-$component-${variant ?? 'default'}';

/// Web 팬 컨테이너 id — [flutterEmbedElementId] 와 같은 파생 규칙.
String webPreviewElementId({
  required String component,
  String? variant,
  String? panelId,
}) => panelId != null ? 'web-$panelId' : 'web-$component-${variant ?? 'default'}';

/// chain 패널 코드 요소(`<code>`) id — Web/Flutter 탭 각각.
String chainCodeElementId(String panelId, {required bool forFlutter}) =>
    'code-${forFlutter ? 'flutter' : 'web'}-$panelId';

/// chain 패널 copy 버튼 id — 셔플 시 `data-code` 를 현재 순열 코드로
/// 갱신할 대상.
String chainCopyElementId(String panelId) => 'copy-$panelId';

/// 플레이그라운드의 **실제** 컴포넌트를 표시하는 DOM 속성. 값은 컴포넌트 slug 다.
///
/// 열린 모습을 합성한 그림에는 달지 않는다. 브라우저 프로브
/// (`tool/parity/oscillation_probe.dart`)가 이 속성으로 실제 컴포넌트를 찾고, 그
/// VM 테스트가 페이지의 플레이그라운드를 서버 렌더해 같은 속성을 확인한다.
const String kDocsLiveComponentAttribute = 'data-docs-live';
