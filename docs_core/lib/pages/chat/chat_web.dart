/// Chat 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="chat/...">` · 카드 · 구조 그림이 읽는다. 같은 이름의 Flutter
/// 파일(`chat_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'chat_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _chat;

/// 장면 이름(`chat/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 루트의 폭을 정해야 말풍선의 최대 폭이 기대대로 계산된다. 감싸는 상자를
  // 두면 구조 번호가 그 상자를 루트로 보므로 행의 `css` 에 폭을 준다. 좁은
  // 화면에서도 왼쪽에 번호 자리가 남도록 화면 폭에서 여백을 뺀 값이 상한이다.
  'chat/anatomy': () => Chat(
    css: Styles(raw: {'width': 'min(18rem, calc(100vw - 8rem))'}),
    avatar: Avatar(initials: 'C'),
    header: span(attributes: const {'data-docs-part': 'header'}, [const Text('이코드')]),
    bubble: const ChatBubble(attributes: {'data-docs-part': 'bubble'}, child: Text('점심 뭐 먹을까요?')),
    footer: span(attributes: const {'data-docs-part': 'footer'}, [const Text('오전 11:30')]),
  ),
  'chat/sides': () => _thread([
    Chat(
      avatar: Avatar(initials: 'C'),
      header: const Text('이코드'),
      bubble: const ChatBubble(child: Text('오늘 점심 뭐 먹을까요?')),
      footer: const Text('오전 11:30'),
    ),
    const Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('회사 앞 국숫집 어때요?')),
      footer: Text('오전 11:31'),
    ),
  ]),
  'chat/tail': () => _thread(const [
    Chat(bubble: ChatBubble(tail: true, child: Text('방금 출발했어요.'))),
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('천천히 오세요!')),
    ),
  ]),
  'chat/tail-edge': () => _thread(const [
    Chat(
      header: Text('박코드'),
      bubble: ChatBubble(
        tail: true,
        chatBubbleStyle: CoreChatBubbleStyle(tailEdge: CoreChatBubbleTailEdge.top),
        child: Text('10분 뒤에 도착해요.'),
      ),
    ),
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(
        chatBubbleStyle: CoreChatBubbleStyle(tailEdge: CoreChatBubbleTailEdge.top),
        child: Text('천천히 와요!'),
      ),
    ),
  ]),
  'chat/tail-corner': () => _thread([
    Chat(
      avatar: Avatar(initials: 'C'),
      bubble: const ChatBubble(chatBubbleStyle: chatTailCornerStyle, child: Text('3시 픽업은 그대로인가요?')),
      footer: const Text('오후 2:10'),
    ),
    const Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(tail: false, chatBubbleStyle: chatTailCornerStyle, child: Text('네, 역에서 봬요.')),
      footer: Text('오후 2:14'),
    ),
  ]),
  'chat/group': () => _thread([
    ChatGroup(
      avatar: Avatar(initials: 'C'),
      header: const Text('이코드'),
      bubbles: const [
        ChatBubble(chatBubbleStyle: chatGroupBubbleStyle, child: Text('오늘 점심 같이 먹을까요?')),
        ChatBubble(chatBubbleStyle: chatGroupBubbleStyle, child: Text('12시에 로비에서 봬요.')),
      ],
      footer: const Text('오전 11:30'),
    ),
    const ChatGroup(
      alignment: CoreChatAlignment.end,
      bubbles: [
        ChatBubble(
          alignment: CoreChatAlignment.end,
          tail: false,
          chatBubbleStyle: chatGroupBubbleStyle,
          child: Text('좋아요.'),
        ),
        ChatBubble(alignment: CoreChatAlignment.end, chatBubbleStyle: chatGroupBubbleStyle, child: Text('국숫집 어때요?')),
      ],
      footer: Text('오전 11:31'),
    ),
  ]),
  'chat/do-sender-name': () => _thread(const [
    Chat(
      header: Text('이코드'),
      bubble: ChatBubble(child: Text('회의실 잡았어요.')),
    ),
    Chat(
      header: Text('박코드'),
      bubble: ChatBubble(child: Text('몇 시인가요?')),
    ),
    Chat(
      alignment: CoreChatAlignment.end,
      header: Text('나'),
      bubble: ChatBubble(child: Text('3시예요.')),
    ),
  ]),
  'chat/dont-color-only': () => _thread(const [
    Chat(bubble: ChatBubble(child: Text('회의실 잡았어요.'))),
    Chat(bubble: ChatBubble(child: Text('몇 시인가요?'))),
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('3시예요.')),
    ),
  ]),
  'chat/do-row-align': () => _thread(const [
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('국숫집 어때요?')),
    ),
  ]),
  'chat/dont-bubble-align': () => _thread(const [
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(alignment: CoreChatAlignment.start, child: Text('국숫집 어때요?')),
    ),
  ]),
  'chat/do-plain-reply': () => _thread(const [
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('이번 주말에 뭐 해요?')),
    ),
    Chat(
      bubble: ChatBubble(
        variant: CoreChatBubbleVariant.plain,
        child: Text('등산 가려고요. 같이 갈래요?'),
      ),
    ),
  ]),
  'chat/width': () => _thread(const [
    Chat(bubble: ChatBubble(child: Text(chatLongMessage))),
    Chat(
      bubble: ChatBubble(variant: CoreChatBubbleVariant.plain, child: Text(chatLongMessage)),
    ),
  ]),
  'chat/theme-instance': () => _thread(const [
    Chat(
      alignment: CoreChatAlignment.end,
      header: Text('나'),
      chatStyle: chatDemoRowStyle,
      bubble: ChatBubble(chatBubbleStyle: chatDemoBubbleStyle, child: Text('색과 모서리를 바꿨어요')),
    ),
  ]),
  'chat/chain': () => _thread([
    Chat(
      avatar: Avatar(initials: 'C'),
      header: const Text('이코드'),
      bubble: const ChatBubble(child: Text('오늘 점심 뭐 먹을까요?')),
      footer: const Text('오전 11:30'),
    ).withStyle(chatChainStyle),
    const Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('회사 앞 국숫집 어때요?')),
      footer: Text('오전 11:31'),
    ),
  ]),
  'chat/related-avatar': () => Avatar(initials: 'C'),
  'chat/related-loading': () => const Loading(),
  'chat/related-text-field': () => div(
    styles: Styles(raw: {'width': 'min(12rem, 100%)'}),
    [const TextField(placeholder: Text('메시지 입력'))],
  ),
};

/// 속성 → 메시지 한 행. `bare` 면 행 없이 말풍선만 그린다.
Component _chat(Map<String, String> props, String? label) {
  final alignment = previewEnum(CoreChatAlignment.values, props['alignment'], CoreChatAlignment.defaultAlignment);
  final sample = chatSample(alignment);
  final bubble = ChatBubble(
    variant: chatPreviewVariant(props),
    tail: chatPreviewTail(props),
    chatBubbleStyle: chatPreviewBubbleStyle(props),
    child: Text(label ?? sample.message),
  );
  if (previewFlag(props, 'bare')) return bubble;
  return _thread([
    Chat(
      alignment: alignment,
      avatar: previewFlag(props, 'avatar') ? Avatar(initials: sample.initials) : null,
      header: previewFlag(props, 'header') ? Text(sample.name) : null,
      bubble: bubble,
      footer: previewFlag(props, 'footer') ? Text(sample.time) : null,
    ),
  ]);
}

/// 메시지를 세로로 쌓는 상자. 무대는 flex 행이라 폭을 정하지 않으면 상자가
/// 내용 폭이 되고, 말풍선의 최대 폭 비율이 그 내용 폭에 곱해진다.
Component _thread(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': 'var(--coui-space-12)',
      'width': 'min(20rem, 100%)',
    },
  ),
  children,
);
