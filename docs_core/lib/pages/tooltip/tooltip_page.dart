/// Tooltip 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `tooltip_web.dart` · `tooltip_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 글자와 스타일은 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/tooltip.md`.
const String slug = 'tooltip';

/// 속성 미리보기의 안내 글 — 태그가 `label` 을 주지 않을 때.
const String demoMessage = '링크 복사';

/// 속성 미리보기의 트리거 버튼 글자.
const String demoTrigger = '공유';

/// 실제 `Tooltip` 으로 감싼 버튼의 글자 — 플레이그라운드에만 있다.
const String demoOpener = '올려 보기';

/// 플레이그라운드에서 말풍선 그림과 실제 `Tooltip` 트리거 사이의 간격 — 위로
/// 열린 실제 말풍선(처음 값 `top`)이 그림의 트리거를 덮지 않는 거리다.
const double demoOpenerGap = CoreSpace.space48;

/// 폭을 제한해 줄을 바꾸는 긴 안내 글.
const String demoLongMessage = '배너 이미지는 가로 1200px 이상을 권장합니다. 더 작은 이미지는 확대되어 흐리게 보일 수 있습니다.';

/// 긴 안내 글의 폭 상한.
const double demoMaxWidth = CoreSpace.space256;

/// 꼬리를 준 그림의 스타일 — 기본값은 꼬리가 없다.
const CoreTooltipStyle demoTailStyle = CoreTooltipStyle(tailWidth: CoreSpace.space12, tailHeight: CoreSpace.space6);

/// 말풍선 안의 아이콘 — 색을 말풍선의 글자색과 같게 직접 준다.
const CoreIconStyle demoBubbleIconStyle = CoreIconStyle(
  size: CoreSize.size16,
  color: CoreColor.token(CoreColors.surface),
);

/// 리치 툴팁의 첫 줄.
const String demoRichTitle = '실행 취소';

/// 리치 툴팁의 둘째 줄.
const String demoRichShortcut = 'Ctrl + Z';

/// 짧고 분명한 안내 글.
const String demoShortMessage = '실행 취소 (Ctrl+Z)';

/// 너무 긴 안내 글 — 피할 예.
const String demoTooLongMessage = '이 버튼을 누르면 마지막 작업이 취소되고 바로 이전 상태로 돌아갑니다. 다시 실행 버튼으로 되돌릴 수 있습니다.';

/// 늘 보여야 하는 입력 규칙의 라벨.
const String demoFieldLabel = '비밀번호';

/// 늘 보여야 하는 입력 규칙.
const String demoRule = '8자 이상 입력해 주세요.';

/// 트리거 글자를 말풍선에 그대로 되풀이한 글 — 피할 예.
const String demoSave = '저장';

/// 긴 안내 글을 붙인 아이콘 버튼의 접근성 이름.
const String demoImageHelpName = '이미지 안내';

/// 입력 규칙을 숨긴 아이콘 버튼의 접근성 이름 — 피할 예.
const String demoRuleName = '비밀번호 규칙';

/// 말풍선 안에 넣은 질문 — 피할 예.
const String demoBubbleQuestion = '항목을 삭제할까요?';

/// 말풍선 안에 넣은 버튼 — 피할 예.
const String demoBubbleAction = '삭제';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `opener` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 말풍선 그림
/// 아래에 실제 `Tooltip` 으로 감싼 버튼을 둔다. 플레이그라운드만 켠다: 사이트의
/// 다른 무대는 브라우저에서 깨어나지 않아 그 버튼에 포인터를 올려도 열리지
/// 않는다. `tail` 과 `long` 은 `tooltipStyle` 의 값을 고르는 손잡이다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'position': 'top', 'opener': 'true'},
  label: demoMessage,
  controls: [
    DocsPlaygroundChoice(
      label: 'position',
      prop: 'position',
      options: ['top', 'bottom', 'left', 'right'],
      segmented: true,
    ),
    DocsPlaygroundFlag(label: '꼬리 (tailWidth · tailHeight)', on: {'tail': 'true'}),
    DocsPlaygroundFlag(label: '긴 안내 글 (panelMaxWidth)', on: {'long': 'true'}),
    DocsPlaygroundFlag(label: '1초 대기 (waitDuration)', on: {'waitDuration': '1000'}),
  ],
  code: _tooltipCode,
);

/// 크기 표. Tooltip 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성의 `position` — 없거나 모르는 값은 `top`.
CoreTooltipPosition demoPositionOf(Map<String, String> props) =>
    previewEnum(CoreTooltipPosition.values, props['position'], CoreTooltipPosition.top);

/// 속성이 고른 안내 글 — `long` 이면 긴 글.
String demoMessageOf(Map<String, String> props, String? label) =>
    previewFlag(props, 'long') ? demoLongMessage : label ?? demoMessage;

/// 속성이 고른 `tooltipStyle` — 아무것도 고르지 않으면 `null`.
CoreTooltipStyle? demoStyleOf(Map<String, String> props) {
  final tail = previewFlag(props, 'tail');
  final long = previewFlag(props, 'long');
  if (!tail && !long) return null;
  return CoreTooltipStyle(
    panelMaxWidth: long ? demoMaxWidth : null,
    tailWidth: tail ? demoTailStyle.tailWidth : null,
    tailHeight: tail ? demoTailStyle.tailHeight : null,
  );
}

/// 속성이 고른 대기 시간. 없으면 기본값을 그대로 넘긴다 — Flutter 는 `null` 을
/// 받으면 Tooltip 의 기본값이 아니라 `Hover` 의 기본값을 쓴다.
Duration demoWaitOf(Map<String, String> props) {
  final ms = int.tryParse(props['waitDuration'] ?? '');
  return ms == null ? CoreTooltipContract.defaultWaitDuration : Duration(milliseconds: ms);
}

String _tooltipCode(Map<String, String> props, String? label) {
  final position = demoPositionOf(props);
  final tail = previewFlag(props, 'tail');
  final long = previewFlag(props, 'long');
  final lines = [
    "message: '${demoMessageOf(props, label)}',",
    if (position != CoreTooltipPosition.top) 'position: CoreTooltipPosition.${position.name},',
    if (props['waitDuration'] == '1000') 'waitDuration: Duration(milliseconds: CoreDuration.ms1000),',
    if (tail || long) ...[
      'tooltipStyle: CoreTooltipStyle(',
      if (long) '  panelMaxWidth: CoreSpace.space256,',
      if (tail) '  tailWidth: CoreSpace.space12,',
      if (tail) '  tailHeight: CoreSpace.space6,',
      '),',
    ],
    'child: Button(',
    '  variant: CoreButtonVariant.outline,',
    '  onPressed: copyLink,',
    "  child: Text('$demoTrigger'),",
    '),',
  ];
  return 'Tooltip(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
