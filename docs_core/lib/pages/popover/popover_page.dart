/// Popover 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `popover_web.dart` · `popover_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자(트리거 · 패널의 제목과 본문)는 아래 상수 한 곳에 둔다 — 두
/// 플랫폼의 그림과 플레이그라운드의 코드가 같은 글자를 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/popover.md`.
const String slug = 'popover';

/// 트리거 버튼의 글자 — 태그가 `label` 을 주지 않을 때.
const String demoTrigger = '알림 설정';

/// 패널의 제목.
const String demoTitle = '알림';

/// 패널의 본문.
const String demoBody = '새 댓글이 달리면 알려 드려요.';

/// 폭 제약 장면의 짧은 본문 — 패널의 내용 폭이 트리거보다 좁다.
const String demoShortBody = '새 댓글';

/// 폭 제약 장면의 긴 본문 — 패널의 내용 폭이 트리거보다 넓다. 짧은 본문과
/// 함께 그려야 네 제약의 모양이 서로 갈린다.
const String demoLongBody = '새 댓글이 달리면 이메일과 앱 알림으로 알려 드려요.';

/// 폭 제약 장면의 트리거 폭(logical px).
const double demoAnchorWidth = 200;

/// 폭 제약 장면이 나란히 보이는 값.
const List<CorePopoverConstraint> demoConstraints = [
  CorePopoverConstraint.flexible,
  CorePopoverConstraint.anchorMinSize,
  CorePopoverConstraint.anchorMaxSize,
  CorePopoverConstraint.anchorFixedSize,
];

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 그림 아래에
/// 실제 `Popover` 를 둔다. 플레이그라운드만 켠다: 사이트의 다른 무대는
/// 브라우저에서 깨어나지 않아 트리거를 눌러도 아무것도 열리지 않는다.
///
/// `openTrigger` 에 `focus` 는 없다 — Web 에서 열리지 않아 두 팬이 다르게
/// 움직인다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'placement': 'bottom', 'openTrigger': 'click', 'opener': 'true'},
  label: demoTrigger,
  controls: [
    DocsPlaygroundChoice(
      label: 'placement',
      prop: 'placement',
      options: [
        'top',
        'topStart',
        'topEnd',
        'bottom',
        'bottomStart',
        'bottomEnd',
        'left',
        'leftStart',
        'leftEnd',
        'right',
        'rightStart',
        'rightEnd',
      ],
    ),
    DocsPlaygroundChoice(
      label: 'openTrigger',
      prop: 'openTrigger',
      options: ['click', 'hover', 'manual'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: 'modal', on: {'modal': 'true'}),
  ],
  code: _popoverCode,
);

/// 크기 표. Popover 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `placement` — 모르는 값은 위젯의 기본값이다.
CorePopoverPlacement demoPlacementOf(Map<String, String> props) =>
    previewEnum(CorePopoverPlacement.values, props['placement'], CorePopoverPlacement.bottom);

/// 속성 `openTrigger` — 모르는 값은 위젯의 기본값이다.
CorePopoverTrigger demoOpenTriggerOf(Map<String, String> props) =>
    previewEnum(CorePopoverTrigger.values, props['openTrigger'], CorePopoverTrigger.click);

/// 속성 `modal`. `hover` 에서는 켜지 않는다 — Web 의 배경막이 트리거를 덮어
/// 패널이 바로 닫힐 수 있다.
bool demoModalOf(Map<String, String> props) =>
    previewFlag(props, 'modal') && demoOpenTriggerOf(props) != CorePopoverTrigger.hover;

/// 실제 `Popover` 의 트리거 글자 — 여는 방법에 맞춘다.
String demoOpenerLabel(CorePopoverTrigger openTrigger) => switch (openTrigger) {
  CorePopoverTrigger.hover => '마우스를 올려 보세요',
  CorePopoverTrigger.click || CorePopoverTrigger.focus || CorePopoverTrigger.manual => '열어 보기',
};

String _popoverCode(Map<String, String> props, String? label) {
  final placement = demoPlacementOf(props);
  final openTrigger = demoOpenTriggerOf(props);
  final manual = openTrigger == CorePopoverTrigger.manual;
  final lines = [
    if (manual) 'controller: controller,',
    if (placement != CorePopoverPlacement.bottom) 'placement: CorePopoverPlacement.${placement.name},',
    if (openTrigger != CorePopoverTrigger.click) 'openTrigger: CorePopoverTrigger.${openTrigger.name},',
    if (demoModalOf(props)) 'modal: true,',
    'trigger: Button(',
    '  variant: CoreButtonVariant.outline,',
    manual ? '  onPressed: controller.toggle,' : '  onPressed: () {},',
    "  child: Text('${label ?? demoTrigger}'),",
    '),',
    "content: Text('$demoBody'),",
  ];
  return [
    if (manual) '// State 에서 만들고 dispose 합니다: final controller = PopoverController();',
    'Popover(',
    for (final line in lines) '  $line',
    ')',
  ].join('\n');
}
