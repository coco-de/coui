/// Dialog 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `dialog_web.dart` · `dialog_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(제목 · 본문 · 행동 이름)는 아래 상수 한 곳에 둔다 — 두
/// 플랫폼의 그림과 플레이그라운드의 코드가 같은 글자를 쓴다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/dialog.md`.
const String slug = 'dialog';

/// 속성 미리보기의 제목 — 태그가 `label` 을 주지 않을 때.
const String demoTitle = '연결이 끊겼어요';

/// 속성 미리보기의 본문.
const String demoContent = '네트워크를 확인한 뒤 다시 시도해 주세요.';

/// 속성 미리보기의 보조 행동.
const String demoCancel = '취소';

/// 속성 미리보기의 주요 행동.
const String demoConfirm = '다시 시도';

/// 실제 `Dialog` 를 여는 버튼의 글자 — 플레이그라운드에만 있다.
const String demoOpener = '열어 보기';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 패널 그림 아래에
/// 실제 `Dialog` 를 여는 버튼을 둔다. 플레이그라운드만 켠다: 사이트의 다른
/// 무대는 브라우저에서 깨어나지 않아 그 버튼이 아무것도 열지 못한다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'actionsLayout': 'end', 'actions': '2', 'content': 'true', 'opener': 'true'},
  label: demoTitle,
  controls: [
    DocsPlaygroundChoice(label: 'actionsLayout', prop: 'actionsLayout', options: ['end', 'stretch'], segmented: true),
    DocsPlaygroundChoice(label: '행동 수', prop: 'actions', options: ['1', '2'], segmented: true),
    DocsPlaygroundFlag(label: 'leading 아이콘', on: {'leading': 'circle-alert'}),
    DocsPlaygroundFlag(label: '닫기 버튼 (trailing)', on: {'trailing': 'x'}),
    DocsPlaygroundFlag(label: '본문 (content)', on: {'content': 'true'}),
  ],
  code: _dialogCode,
);

/// 크기 표. Dialog 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `actions` 가 행동 둘을 고르는가 — `1` 이 아니면 둘이다.
bool demoHasTwoActions(Map<String, String> props) => props['actions'] != '1';

String _dialogCode(Map<String, String> props, String? label) {
  final leading = props['leading'];
  final trailing = props['trailing'];
  final lines = [
    'open: isOpen,',
    'onClose: close,',
    if (leading != null) 'leading: Icon(LucideIcons.${docsIconIdentifier(leading)}),',
    "title: Text('${label ?? demoTitle}'),",
    if (trailing != null) ...[
      'trailing: Button(',
      '  variant: CoreButtonVariant.plain,',
      '  size: CoreComponentSize.sm,',
      '  shape: CoreButtonShape.square,',
      '  onPressed: close,',
      '  child: Icon(LucideIcons.${docsIconIdentifier(trailing)}),',
      '),',
    ],
    if (previewFlag(props, 'content')) "content: Text('$demoContent'),",
    'actions: [',
    if (demoHasTwoActions(props)) ...[
      '  Button(',
      '    variant: CoreButtonVariant.outline,',
      '    onPressed: close,',
      "    child: Text('$demoCancel'),",
      '  ),',
    ],
    "  Button(onPressed: retry, child: Text('$demoConfirm')),",
    '],',
    if (props['actionsLayout'] == 'stretch') ...[
      'dialogStyle: CoreDialogStyle(',
      '  actionsLayout: CoreDialogActionsLayout.stretch,',
      '),',
    ],
  ];
  return 'Dialog(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
