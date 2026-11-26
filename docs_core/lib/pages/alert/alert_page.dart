/// Alert 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `alert_web.dart` · `alert_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/alert.md`.
const String slug = 'alert';

/// 플레이그라운드에 처음 보이는 설명 — 설명 플래그를 켰을 때의 값과 같다.
const String _description = '다음 결제일 전에 카드 정보를 바꾸면 끊김 없이 이용할 수 있어요.';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// variant · layout 의 선택지는 Core 의 enum 에서 읽는다 — 값이 늘거나
/// 줄면 컨트롤이 함께 따라온다.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'variant': 'warning', 'layout': 'stacked', 'description': _description},
  label: '결제 수단을 확인해 주세요',
  controls: [
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [for (final variant in CoreAlertVariant.values) variant.name],
    ),
    DocsPlaygroundChoice(
      label: 'layout',
      prop: 'layout',
      options: [for (final layout in CoreAlertLayout.values) layout.name],
      segmented: true,
    ),
    const DocsPlaygroundFlag(label: '설명', on: {'description': _description}),
    const DocsPlaygroundFlag(label: '행동 버튼', on: {'action': '카드 바꾸기'}),
    const DocsPlaygroundFlag(label: '닫기 버튼', on: {'dismiss': 'true'}),
    const DocsPlaygroundFlag(label: '아이콘 끄기', on: {'showIcon': 'false'}),
  ],
  code: _alertCode,
);

/// 크기 표. Alert 는 크기 축이 없다 — `CoreAlertStyle` 에 `defaultsBySize`
/// 가 없고, 레이아웃(`defaultsByLayout`)이 여백 · 높이를 정한다.
DocsSizeSpec Function()? get sizeSpec => null;

String _alertCode(Map<String, String> props, String? label) {
  String quoted(String value) => "'${value.replaceAll("'", r"\'")}'";
  final variant = props['variant'] ?? CoreAlertVariant.defaultVariant.name;
  final layout = props['layout'] ?? CoreAlertLayout.defaultLayout.name;
  final lines = [
    'title: ${quoted(label ?? '알림')},',
    if (props['description'] case final description?) 'description: ${quoted(description)},',
    if (variant != CoreAlertVariant.defaultVariant.name) 'variant: CoreAlertVariant.$variant,',
    if (layout != CoreAlertLayout.defaultLayout.name) 'layout: CoreAlertLayout.$layout,',
    if (!previewFlag(props, 'showIcon', fallback: CoreAlertContract.defaultShowIcon)) 'showIcon: false,',
    if (previewFlag(props, 'dismiss')) 'onDismiss: hideAlert,',
    if (props['action'] case final action?) ...[
      'action: Button(',
      '  variant: CoreButtonVariant.outline,',
      '  size: CoreComponentSize.sm,',
      '  onPressed: changeCard,',
      '  child: Text(${quoted(action)}),',
      '),',
    ],
  ];
  return 'Alert(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
