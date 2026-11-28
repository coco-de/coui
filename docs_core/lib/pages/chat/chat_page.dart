/// Chat 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `chat_web.dart` · `chat_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 `alignment`(행의 정렬), `variant`, `tail`, 그리고 슬롯을 켜는
/// `avatar` · `header` · `footer` 다. `variant` · `tail` 의 `auto` 는 값을 적지
/// 않은 상태라 정렬이 정하는 기본값이 보인다. `tail` 의 `top` · `bottom` 은
/// 꼬리를 켜고 놓을 변을 고르며 `none` 은 끈다. `bare` 는 행 없이 말풍선만
/// 그린다(variant 행이 쓴다).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/chat.md`.
const String slug = 'chat';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. 크기 축이 없는 컴포넌트는 `null`.
DocsSizeSpec Function()? get sizeSpec => null;

/// 값을 적지 않은 상태를 뜻하는 선택지.
const String _auto = 'auto';

/// 꼬리를 끄는 선택지.
const String _noTail = 'none';

/// 정렬마다의 예시 내용 — 두 플랫폼의 속성 빌더와 플레이그라운드 코드가 함께
/// 읽는다.
({String initials, String name, String message, String time}) chatSample(CoreChatAlignment alignment) =>
    switch (alignment) {
      CoreChatAlignment.start => (initials: 'C', name: '이코드', message: '오늘 점심 뭐 먹을까요?', time: '오전 11:30'),
      CoreChatAlignment.end => (initials: 'M', name: '나', message: '회사 앞 국숫집 어때요?', time: '오전 11:31'),
    };

/// 속성의 `variant`. `auto` 이거나 모르는 이름이면 `null` — 정렬이 정한다.
CoreChatBubbleVariant? chatPreviewVariant(Map<String, String> props) {
  for (final variant in CoreChatBubbleVariant.values) {
    if (variant.name == props['variant']) return variant;
  }
  return null;
}

/// 속성의 `tail` → `ChatBubble.tail`. `auto` 이거나 없으면 `null`.
bool? chatPreviewTail(Map<String, String> props) {
  if (props['tail'] == _noTail) return false;
  return CoreChatBubbleTailEdge.values.any((edge) => edge.name == props['tail']) ? true : null;
}

/// 속성의 `tail` 이 고른 변이 기본과 다를 때의 말풍선 스타일.
CoreChatBubbleStyle? chatPreviewBubbleStyle(Map<String, String> props) =>
    props['tail'] == CoreChatBubbleTailEdge.top.name
    ? const CoreChatBubbleStyle(tailEdge: CoreChatBubbleTailEdge.top)
    : null;

/// `chat/group` 장면의 말풍선 스타일. Web 의 묶음은 말풍선의 최대 폭 비율을
/// 묶음 상자의 내용 폭에 곱하므로, 비율을 1로 두어야 짧은 글이 한 줄에
/// 남는다. 두 플랫폼 장면이 함께 읽는다.
const CoreChatBubbleStyle chatGroupBubbleStyle = CoreChatBubbleStyle(maxWidthFactor: 1);

/// `chat/tail-corner` 장면의 말풍선 스타일 — 두 플랫폼 장면이 함께 읽는다.
const CoreChatBubbleStyle chatTailCornerStyle = CoreChatBubbleStyle(
  tailEdge: CoreChatBubbleTailEdge.top,
  tailCornerRadius: CoreRadius.radius6,
);

/// `chat/chain` 장면에서 `withStyle` 에 넘기는 스타일 — 빠른 덮어쓰기 예제
/// 코드와 같은 값이다.
const CoreChatStyle chatChainStyle = CoreChatStyle(
  avatarSpacing: CoreSpace.space16,
  groupSpacing: CoreSpace.space4,
  headerTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge, color: CoreColor.token(CoreColors.primary)),
  footerTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall, color: CoreColor.token(CoreColors.onSurfaceVariant)),
);

/// `chat/theme-instance` 장면의 행 스타일 — 두 플랫폼 장면이 함께 읽는다.
const CoreChatStyle chatDemoRowStyle = CoreChatStyle(
  headerTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
);

/// `chat/theme-instance` 장면의 말풍선 스타일 — 두 플랫폼 장면이 함께 읽는다.
const CoreChatBubbleStyle chatDemoBubbleStyle = CoreChatBubbleStyle(
  backgroundColor: CoreColor.token(CoreColors.primaryContainer),
  foregroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
  borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
);

/// `chat/width` 장면의 긴 글 — 두 플랫폼 장면이 함께 읽는다.
const String chatLongMessage = '비가 온다고 해서 실내에서 먹을 수 있는 곳으로 골라 봤어요. 걸어서 5분이면 도착해요.';

// 선택지는 enum 에서 읽는다 — variant 나 꼬리 변이 늘면 플레이그라운드도
// 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'alignment': CoreChatAlignment.defaultAlignment.name,
    'variant': _auto,
    'tail': _auto,
    'avatar': 'true',
    'header': 'true',
    'footer': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'alignment',
      prop: 'alignment',
      options: [for (final alignment in CoreChatAlignment.values) alignment.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'variant',
      prop: 'variant',
      options: [_auto, for (final variant in CoreChatBubbleVariant.values) variant.name],
    ),
    DocsPlaygroundChoice(
      label: '꼬리',
      prop: 'tail',
      options: [_auto, for (final edge in CoreChatBubbleTailEdge.values) edge.name, _noTail],
    ),
    const DocsPlaygroundFlag(label: 'avatar', on: {'avatar': 'true'}),
    const DocsPlaygroundFlag(label: 'header', on: {'header': 'true'}),
    const DocsPlaygroundFlag(label: 'footer', on: {'footer': 'true'}),
  ],
  code: _chatCode,
);

/// 속성 → 코드. 적지 않은 값(`auto`)과 기본 정렬은 코드에 쓰지 않는다.
String _chatCode(Map<String, String> props, String? label) {
  final alignment = previewEnum(CoreChatAlignment.values, props['alignment'], CoreChatAlignment.defaultAlignment);
  final sample = chatSample(alignment);
  final variant = chatPreviewVariant(props);
  final tail = chatPreviewTail(props);
  final style = chatPreviewBubbleStyle(props);
  final lines = [
    if (alignment != CoreChatAlignment.defaultAlignment) 'alignment: CoreChatAlignment.${alignment.name},',
    if (previewFlag(props, 'avatar')) "avatar: Avatar(initials: '${sample.initials}'),",
    if (previewFlag(props, 'header')) "header: Text('${sample.name}'),",
    'bubble: ChatBubble(',
    if (variant != null) '  variant: CoreChatBubbleVariant.${variant.name},',
    if (tail != null) '  tail: $tail,',
    if (style != null) ...[
      '  chatBubbleStyle: CoreChatBubbleStyle(',
      '    tailEdge: CoreChatBubbleTailEdge.${style.tailEdge!.name},',
      '  ),',
    ],
    "  child: Text('${label ?? sample.message}'),",
    '),',
    if (previewFlag(props, 'footer')) "footer: Text('${sample.time}'),",
  ];
  return 'Chat(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
