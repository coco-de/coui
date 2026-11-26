/// Toast 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `toast_web.dart` · `toast_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(메시지 · 설명 · 행동 이름)와 폭은 아래 상수 한 곳에 둔다 —
/// 두 플랫폼의 미리보기와 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/toast.md`.
const String slug = 'toast';

/// 속성 미리보기의 메시지 — 태그가 `label` 을 주지 않을 때.
const String demoMessage = '저장했어요';

/// 속성 미리보기의 설명.
const String demoDescription = '변경 사항을 저장했어요.';

/// 속성 미리보기의 행동 이름.
const String demoAction = '되돌리기';

/// 같은 속성의 토스트를 띄우는 버튼의 글자 — Flutter 플레이그라운드에만 있다.
const String demoOpener = '띄워 보기';

/// 미리보기에서 카드를 놓는 폭 — `ToastLayer` 가 토스트에 주는 기본 폭과 같다.
const double demoToastWidth = 320;

/// 구조 그림의 폭 — 설명과 행동이 나란히 놓일 자리를 둔다.
const double demoAnatomyWidth = 416;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 Flutter 미리보기는
/// 카드 아래에 `showToast` 로 같은 속성의 토스트를 띄우는 버튼을 둔다. Web 에는
/// 띄우는 함수가 없어 Web 미리보기는 이 속성을 읽지 않는다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'variant': 'success', 'description': demoDescription, 'dismiss': 'true', 'opener': 'true'},
  label: demoMessage,
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreToastVariant.values) variant.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '설명', on: {'description': demoDescription}),
    const DocsPlaygroundFlag(label: '행동 버튼', on: {'action': demoAction}),
    const DocsPlaygroundFlag(label: '닫기 버튼', on: {'dismiss': 'true'}),
    const DocsPlaygroundFlag(label: '아이콘 끄기', on: {'showIcon': 'false'}),
  ],
  code: _showToastCode,
  webCode: _cardCode,
);

/// 크기 표. Toast 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `variant` — 없거나 모르는 이름이면 위젯의 기본값.
CoreToastVariant demoVariant(Map<String, String> props) =>
    previewEnum(CoreToastVariant.values, props['variant'], CoreToastVariant.defaultVariant);

/// 속성 `showIcon` — 없으면 위젯의 기본값.
bool demoShowIcon(Map<String, String> props) =>
    previewFlag(props, 'showIcon', fallback: CoreToastContract.defaultShowIcon);

/// Flutter 코드 — 카드를 `showToast` 로 띄운다. Flutter 미리보기가 띄운 토스트처럼
/// 닫기 버튼과 행동 버튼은 그 토스트를 닫는다.
String _showToastCode(Map<String, String> props, String? label) {
  final lines = _cardLines(
    props,
    label,
    onDismiss: 'overlay.close',
    onAction: const ['onPressed: () {', '  undo();', '  overlay.close();', '},'],
  );
  return 'showToast(\n'
      '  context: context,\n'
      '  builder: (context, overlay) => Toast(\n'
      '${lines.map((l) => '    $l').join('\n')}\n'
      '  ),\n'
      ')';
}

/// Web 코드 — 카드 하나. 놓고 걷어내는 것은 앱의 몫이다.
String _cardCode(Map<String, String> props, String? label) {
  final lines = _cardLines(props, label, onDismiss: 'hideToast', onAction: const ['onPressed: undo,']);
  return 'Toast(\n${lines.map((l) => '  $l').join('\n')}\n)';
}

/// `Toast(` 안의 줄들. [onAction] 은 행동 버튼의 `onPressed` 줄들이다.
List<String> _cardLines(
  Map<String, String> props,
  String? label, {
  required String onDismiss,
  required List<String> onAction,
}) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final variant = demoVariant(props);
  return [
    'message: ${quoted(label ?? demoMessage)},',
    if (props['description'] case final description?) 'description: ${quoted(description)},',
    if (variant != CoreToastVariant.defaultVariant) 'variant: CoreToastVariant.${variant.name},',
    if (!demoShowIcon(props)) 'showIcon: false,',
    if (previewFlag(props, 'dismiss')) 'onDismiss: $onDismiss,',
    if (props['action'] case final action?) ...[
      'action: Button(',
      '  variant: CoreButtonVariant.plain,',
      '  size: CoreComponentSize.xs,',
      for (final line in onAction) '  $line',
      '  child: Text(${quoted(action)}),',
      '),',
    ],
  ];
}
