---
title: Chat
description: 보낸 쪽과 받은 쪽에 따라 말풍선의 색과 꼬리가 정해지는 채팅 메시지 행 · 말풍선 · 메시지 묶음입니다.
category: display
platforms: [flutter, web]
related: [avatar, loading, text-field]
tags: [messaging, conversation]
template: v2
source: display/chat
---

# Chat

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 메시지 한 행을 확인하고, 만들어진 코드를 그대로 복사하세요. `variant` 와 `꼬리` 의 `auto` 는 값을 적지 않은 상태라, `alignment` 를 바꾸면 말풍선의 색과 꼬리가 함께 바뀝니다. `start` 의 기본은 `neutral` 색에 꼬리 없음이라, 이때는 `neutral` 이나 `none` 을 골라도 화면이 같고 코드에만 값이 적힙니다. `꼬리` 의 `top` · `bottom` 은 꼬리를 켜고 놓을 변을 고르며, `none` 은 꼬리를 끕니다. 예시 글은 정렬마다 다릅니다. `Chat` 코드는 Flutter와 Web이 같습니다.

<Playground component="chat" />

<Note>

`plain` 은 면이 없는 variant라 `꼬리` 를 `top` 이나 `bottom` 으로 골라도 꼬리가 보이지 않습니다.

</Note>

<a id="기본-사용법-basic-usage"></a>

### 기본 사용

대화는 `Chat` 을 세로로 쌓아 만듭니다. 메시지를 담는 목록은 앱에서 만들기 때문에, 아래 코드는 감싸는 부분만 플랫폼마다 다릅니다. 감싸는 쪽이 가로 폭을 다 주어야 `end` 행이 끝 쪽에 붙습니다(배치 섹션).

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Chat(
      avatar: Avatar(initials: 'C'),
      header: Text('이코드'),
      bubble: ChatBubble(child: Text('오늘 점심 뭐 먹을까요?')),
      footer: Text('오전 11:30'),
    ),
    Gap.space12(),
    // end 행의 말풍선은 primary 색에 end 쪽 꼬리가 기본입니다.
    Chat(
      alignment: CoreChatAlignment.end,
      bubble: ChatBubble(child: Text('회사 앞 국숫집 어때요?')),
      footer: Text('오전 11:31'),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(classes: 'flex flex-col w-full', [
  Chat(
    avatar: Avatar(initials: 'C'),
    header: Text('이코드'),
    bubble: ChatBubble(child: Text('오늘 점심 뭐 먹을까요?')),
    footer: Text('오전 11:30'),
  ),
  Gap.space12(),
  // end 행의 말풍선은 primary 색에 end 쪽 꼬리가 기본입니다.
  Chat(
    alignment: CoreChatAlignment.end,
    bubble: ChatBubble(child: Text('회사 앞 국숫집 어때요?')),
    footer: Text('오전 11:31'),
  ),
])
```

  </TabItem>
</Tabs>

<a id="컴포넌트-구성"></a>

## 구조

`Chat` 은 메시지 한 행입니다. `bubble` 만 필수이고 `avatar` · `header` · `footer` 는 선택입니다.

<Anatomy demo="chat/anatomy">
<AnatomyItem part="container" name="Chat">

메시지 한 행. 배경이나 테두리를 그리지 않고 아바타와 내용의 자리만 잡습니다.

</AnatomyItem>
<AnatomyItem select="[role=img]" side="top" name="avatar">

내용 옆에 한 번 놓는 선택 슬롯. 위쪽에 맞춰 놓입니다. 그림은 [Avatar](/components/avatar)입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=header]" side="right" name="header">

말풍선 위의 선택 슬롯. 보통 보낸 사람 이름을 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=bubble]" side="right" name="bubble">

메시지 본문. 필수 슬롯이며 보통 `ChatBubble` 을 넣습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=footer]" side="right" name="footer">

말풍선 아래의 선택 슬롯. 보통 시각이나 전달 상태를 적습니다.

</AnatomyItem>
</Anatomy>

세 위젯이 일을 나눠 맡습니다.

| 위젯 | 하는 일 | 슬롯 |
| --- | --- | --- |
| `Chat` | 메시지 한 행 | `avatar` · `header` · `bubble` · `footer` |
| `ChatGroup` | 같은 발신자의 연속 메시지 | `avatar` · `header` · `bubbles` · `footer` |
| `ChatBubble` | 말풍선 | `child` |

- `header` → `bubble` → `footer` 순서로 세로로 쌓고, 세 칸 사이에는 간격을 두지 않습니다.
- 아바타는 `start` 행에서는 내용의 앞, `end` 행에서는 내용의 뒤에 놓입니다. 아바타와 내용 사이는 기본 8입니다.
- 두 플랫폼의 기본 글자는 같습니다. 머리글은 `labelSmall` 역할에 `onSurfaceVariant` 색, 바닥글은 `bodyXs` 역할에 `onSurfaceSubtle` 색, 말풍선은 `bodyLarge` 역할입니다. 슬롯에 따로 꾸미지 않고 넣은 `Text` 는 이 값을 이어받습니다.

## Variant

`ChatBubble.variant`(`CoreChatBubbleVariant`)는 말풍선의 면 색과 글자색을 고릅니다. 값은 아홉 가지이고, 적지 않으면 말풍선의 정렬이 정합니다(`start` 는 `neutral`, `end` 는 `primary`). 아래 무대는 행 없이 말풍선만 그린 것입니다. 행 밖의 말풍선은 정렬을 적지 않으면 `start` 라 꼬리가 없습니다.

<VariantRow name="neutral" component="chat" props="variant=neutral;bare=true" label="안녕하세요">

`start` 의 기본값입니다. 면은 `surfaceContainerHigh`, 글자는 `onSurface` 입니다.

</VariantRow>
<VariantRow name="primary" component="chat" props="variant=primary;bare=true" label="안녕하세요">

`end` 의 기본값입니다. 면은 `primary`, 글자는 `onPrimary` 입니다.

</VariantRow>
<VariantRow name="secondary" component="chat" props="variant=secondary;bare=true" label="안녕하세요">

면은 `secondary`, 글자는 `onSecondary` 입니다.

</VariantRow>
<VariantRow name="accent" component="chat" props="variant=accent;bare=true" label="안녕하세요">

이름은 `accent` 이고, 색은 `tertiary` 면에 `onTertiary` 글자를 씁니다.

</VariantRow>
<VariantRow name="info" component="chat" props="variant=info;bare=true" label="안내예요">

면은 `info`, 글자는 `onInfo` 입니다.

</VariantRow>
<VariantRow name="success" component="chat" props="variant=success;bare=true" label="보냈어요">

면은 `success`, 글자는 `onSuccess` 입니다.

</VariantRow>
<VariantRow name="warning" component="chat" props="variant=warning;bare=true" label="확인하세요">

면은 `warning`, 글자는 `onWarning` 입니다.

</VariantRow>
<VariantRow name="error" component="chat" props="variant=error;bare=true" label="실패했어요">

면은 `error`, 글자는 `onError` 입니다.

</VariantRow>
<VariantRow name="plain" component="chat" props="variant=plain;bare=true" label="면 없는 글">

면이 없는 말입니다. 투명한 면에 `onSurfaceVariant` 글자를 쓰고, 안쪽 여백은 0, 최대 폭은 100%입니다. 꼬리를 켜도 그리지 않습니다.

</VariantRow>

variant 이름은 색을 고를 뿐 보조 기술에 뜻을 전달하지 않습니다. 전달 실패처럼 중요한 상태는 `footer` 의 글로도 적으세요.

<a id="동작-스펙-behavior"></a>

## 정렬과 기본값

`Chat.alignment`(`CoreChatAlignment`, 기본 `start`)는 행에서 아바타와 내용이 놓이는 쪽을 정합니다. 행은 이 값을 `bubble` 슬롯의 말풍선에도 넘기고, `ChatBubble` 은 자기가 적지 않은 값을 이 정렬에 맞춰 채웁니다. 그래서 보낸 메시지는 `Chat` 에 `alignment: CoreChatAlignment.end` 한 번만 적으면 됩니다.

<Preview demo="chat/sides" />

| 정렬 | `variant` 기본값 | `tail` 기본값 |
| --- | --- | --- |
| `start` | `neutral` | 꼬리 없음 |
| `end` | `primary` | 꼬리 있음 |

값은 두 단계로 정해집니다.

1. 말풍선의 정렬: `ChatBubble.alignment` → 없으면 감싼 `Chat` 행의 `alignment`(아래의 `ChatAlignmentScope` 도 같습니다) → 둘 다 없으면 `start`.
2. `variant` · `tail`: 직접 적은 값 → 없으면 1에서 정해진 정렬의 기본값.

- 직접 적은 값은 그대로 씁니다. 행은 `end` 인데 말풍선에 `alignment: CoreChatAlignment.start` 를 적으면, 행의 `end` 쪽에 `start` 기본값(`neutral` · 꼬리 없음)의 말풍선이 놓입니다.
- `ChatBubble.alignment` 는 말풍선의 위치를 옮기지 않습니다. 색과 꼬리의 기본값, 꼬리가 붙는 쪽, 꼬리 쪽 모서리를 정합니다. 위치는 `Chat` · `ChatGroup` 의 `alignment` 나 바깥 레이아웃이 정합니다.
- `header` · `footer` · `avatar` 칸에 넣은 말풍선은 행의 정렬을 받지 않습니다.
- 행 안에서 연 대화상자나 팝오버처럼 오버레이에 띄운 화면 속 말풍선도 행의 정렬을 받지 않습니다.
- `ChatGroup` 은 자기 `alignment` 를 말풍선에 넘기지 않습니다(메시지 묶음 섹션).

### 직접 만든 행

`Chat` 대신 직접 만든 행을 쓸 때는 `ChatAlignmentScope` 로 감싸면 그 아래의 말풍선이 같은 방식으로 정렬을 받습니다. 두 플랫폼에서 이름과 사용법이 같습니다. 값만 전달하는 위젯이므로 행의 배치는 직접 만듭니다. Flutter에서 말풍선의 폭을 다룰 때의 주의점은 배치 섹션에 있습니다.

```dart
ChatAlignmentScope(
  alignment: CoreChatAlignment.end,
  // primary 색에 end 쪽 꼬리가 기본이 됩니다.
  child: ChatBubble(child: Text('직접 만든 행의 말풍선')),
)
```

## 꼬리

<Preview demo="chat/tail" />

`ChatBubble.tail` 은 말풍선 꼬리를 켜거나 끕니다. 적지 않으면 정렬이 정합니다(`start` 는 없음, `end` 는 있음). 위 그림의 받은 말풍선은 `tail: true` 를 직접 적었고, 보낸 말풍선은 기본값입니다.

- 꼬리는 말풍선의 정렬 쪽(`start` 는 왼쪽, `end` 는 오른쪽) 모서리에서 옆으로 나갑니다.
- 기본 크기는 폭 8 · 높이 8이고 끝을 반경 4로 둥글립니다. `chatBubbleStyle` 의 `tailWidth` · `tailHeight` · `tailTipRadius` 로 바꿉니다.
- 말풍선과 1px 겹쳐 그리므로 기본 크기에서는 말풍선 바깥으로 7px 나옵니다. 꼬리는 레이아웃 자리를 차지하지 않습니다.
- 색은 말풍선의 채움을 따릅니다. 채움이 없는 말풍선(`plain`, 배경을 투명으로 덮은 말풍선)은 `tail: true` 여도 꼬리를 그리지 않습니다.

### 꼬리가 놓이는 변

<Preview demo="chat/tail-edge" />

`CoreChatBubbleStyle.tailEdge` 로 아래(`bottom`, 기본)와 위(`top`) 가운데 고릅니다. `top` 은 메시지가 시작하는 쪽이며, 행이 아바타를 맞추는 쪽이기도 합니다. 꼬리를 그리면 그 꼬리가 붙는 모서리는 각이 집니다. 모서리가 둥글면 말풍선과 꼬리 사이에 홈이 생기기 때문입니다.

```dart
ChatBubble(
  tail: true,
  chatBubbleStyle: CoreChatBubbleStyle(
    tailEdge: CoreChatBubbleTailEdge.top,
  ),
  child: Text('방금 출발했어요.'),
)
```

### 꼬리 없는 말풍선의 모서리

<Preview demo="chat/tail-corner" />

꼬리를 그리지 않는 말풍선은 `CoreChatBubbleStyle.tailCornerRadius` 로 **꼬리 쪽 모서리 하나**만 다르게 둘 수 있습니다. 꼬리 쪽 모서리는 `tailEdge` 변에서 말풍선의 정렬 쪽에 있는 모서리입니다. 위 그림은 두 말풍선 모두 `tailEdge: top` 과 `tailCornerRadius: CoreRadius.radius6` 을 적었고, 보낸 말풍선은 `tail: false` 로 꼬리를 껐습니다.

- 값을 적지 않으면 그 모서리는 `borderRadius` 의 같은 모서리를 씁니다. 그래서 `borderRadius` 만 바꾸면 네 모서리가 함께 바뀝니다.
- 꼬리를 그리면 이 값과 관계없이 각이 집니다.
- 밀도와 서페이스 스타일은 이 모서리에도 다른 모서리와 같은 방식으로 적용됩니다.

## 메시지 묶음

`ChatGroup` 은 같은 발신자의 연속 메시지를 아바타 · 머리글 · 바닥글 하나씩으로 묶습니다. `bubbles` 는 준 순서대로 쌓고, 말풍선 사이는 기본 4입니다(`chatStyle` 의 `groupSpacing`).

<Preview demo="chat/group" />

`ChatGroup` 은 `Chat` 과 달리 정렬을 말풍선에 넘기지 않습니다. 바깥에서 정렬을 넘기는 것이 없으면, `alignment` 를 적지 않은 말풍선은 `end` 묶음 안에서도 `start` 기본값(`neutral` · 꼬리 없음)을 씁니다. 말풍선마다 `alignment: CoreChatAlignment.end` 를 적으면 `end` 기본값(`primary` · 꼬리)이 적용됩니다. 그러면 모든 말풍선에 꼬리가 켜지므로, 꼬리를 하나만 남기려면 나머지에 `tail: false` 를 적습니다.

```dart
// Web의 묶음에서 말풍선이 일찍 줄을 바꾸지 않게 합니다.
const fullWidth = CoreChatBubbleStyle(maxWidthFactor: 1);

ChatGroup(
  alignment: CoreChatAlignment.end,
  bubbles: [
    ChatBubble(
      alignment: CoreChatAlignment.end,
      tail: false,
      chatBubbleStyle: fullWidth,
      child: Text('좋아요.'),
    ),
    ChatBubble(
      alignment: CoreChatAlignment.end,
      chatBubbleStyle: fullWidth,
      child: Text('국숫집 어때요?'),
    ),
  ],
  footer: Text('오전 11:31'),
)
```

<Note>

Web의 `ChatGroup` 은 말풍선들을 내용 폭만큼만 넓어지는 상자에 담습니다. 말풍선의 최대 폭 비율이 이 상자의 폭에 곱해지므로, 기본값(75%)이면 묶음에서 가장 넓은 말풍선과 그 폭의 75%를 넘는 다른 말풍선은 옆에 자리가 남아도 줄이 바뀌거나 글자가 면을 벗어날 수 있습니다. 위 그림과 예제처럼 묶음 안의 말풍선에 `maxWidthFactor: 1` 을 적으면 피할 수 있습니다. 이 값은 두 플랫폼에 모두 적용되어, 긴 메시지는 쓸 수 있는 폭 전체까지 넓어집니다. Flutter의 비율은 묶음에서 말풍선이 쓸 수 있는 폭에 곱해지므로 이런 줄 바꿈이 생기지 않습니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 발신자에 따라 양쪽으로 나뉘는 메시지를 보여 줄 때 `Chat` 과 `ChatBubble` 을 씁니다.
- 같은 발신자가 이어 보낸 메시지를 아바타 하나로 묶을 때 `ChatGroup` 을 씁니다.
- AI 대화처럼 한쪽은 말풍선, 다른 쪽은 면 없는 긴 글로 보여 줄 때 `plain` 을 함께 씁니다.

### 다른 컴포넌트가 더 맞는 경우

- 말풍선이나 발신자 정렬 없이 행 · 열 목록만 필요하면 [Listing](/components/listing)을 씁니다.
- 세 위젯은 보여 주기만 합니다. 메시지 보내기 · 받기, 목록 스크롤과 자동 스크롤, 읽음 처리, 누름 콜백, 비활성 상태는 없으므로 앱에서 만듭니다. Web의 `eventHandlers` 는 DOM 이벤트를 연결할 뿐 누름 동작이나 역할을 만들지 않습니다.
- 메시지를 보내는 전용 위젯은 이 컴포넌트에 없습니다. 입력창은 [TextField](/components/text-field) 같은 입력 컴포넌트로 만듭니다.

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="chat/do-sender-name" title="발신자를 글로도 알리기" tone="do" eyebrow="이렇게 하세요">

`header` 에 보낸 사람 이름을 적습니다. 정렬과 색을 보지 못해도 누가 보냈는지 알 수 있습니다.

</Card>
<Card demo="chat/dont-color-only" title="정렬과 색에만 맡기기" tone="dont" eyebrow="이렇게 하지 마세요">

정렬과 면 색은 눈으로만 읽히는 신호입니다. 세 위젯은 보낸 쪽을 보조 기술에 따로 알리지 않습니다.

</Card>
<Card demo="chat/do-row-align" title="정렬은 Chat 에만 적기" tone="do" eyebrow="이렇게 하세요">

`Chat.alignment` 가 행의 배치와 말풍선의 기본 색 · 꼬리를 함께 정합니다. 같은 값을 말풍선에 다시 적지 않아도 됩니다.

</Card>
<Card demo="chat/dont-bubble-align" title="행과 말풍선에 다른 정렬 적기" tone="dont" eyebrow="이렇게 하지 마세요">

`end` 행의 말풍선에 `start` 를 적으면 보낸 쪽에 받은 말풍선 모양이 놓입니다. 행 밖의 말풍선처럼 필요할 때만 정렬을 적습니다.

</Card>
</Cards>

### 사용자 말과 AI 답

<Preview demo="chat/do-plain-reply" />

사용자의 말은 `end`(기본 `primary`)로, AI의 답은 `start` 에 `plain` 으로 놓으면 보낸 쪽에만 말풍선 면이 생깁니다. `plain` 은 최대 폭이 100%라 긴 답이 행의 폭을 따라 읽힙니다.

```dart
Chat(
  alignment: CoreChatAlignment.end,
  bubble: ChatBubble(child: Text('이번 주말에 뭐 해요?')),
)

Chat(
  bubble: ChatBubble(
    variant: CoreChatBubbleVariant.plain,
    child: Text('등산 가려고요. 같이 갈래요?'),
  ),
)
```

보낸 말풍선의 꼬리를 끄려면 `ChatBubble(tail: false, …)`, 받은 말풍선에 꼬리를 켜려면 `ChatBubble(tail: true, …)` 처럼 직접 적습니다.

## 배치

### 행의 가로 폭

- **Web** — `Chat` 과 `ChatGroup` 의 루트는 부모 폭의 100%를 씁니다. 부모의 폭이 내용에 맞춰 정해지는 자리(예: 폭을 주지 않은 가로 flex의 자식 `div`)에 두면 말풍선이 필요보다 일찍 줄을 바꿉니다. 대화를 담는 상자에 폭을 정해 주세요.
- **Flutter** — 부모가 가로 폭을 꽉 주어야 행이 전체 폭을 씁니다. 그렇지 않으면 행이 내용 폭만 차지해 `end` 메시지가 끝 쪽에 붙지 않습니다. 세로 `ListView`, `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`, `SizedBox(width: double.infinity)` 안에 두세요.

### 말풍선의 최대 폭

<Preview demo="chat/width" />

`Chat` 안의 말풍선은 아바타와 그 간격을 뺀 내용 칸의 75%까지 넓어집니다. 글이 더 길면 줄을 바꿉니다. `plain` 은 100%입니다. 비율은 `chatBubbleStyle` 의 `maxWidthFactor` 로 바꾸며, 꼬리가 있어도 같은 비율을 씁니다. 위 그림은 같은 긴 글을 `neutral` 과 `plain` 으로 그린 것입니다. Flutter에서 가로 폭 제한이 없는 자리(가로 스크롤 등)에 두면 최대 폭 한도가 없습니다. 반대로 Flutter에서 `Chat` 이나 `ChatGroup` 밖의 말풍선을 가로 폭을 꽉 주는 부모(예: 세로 `ListView`, `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`) 바로 아래에 두면 비율이 적용되지 않습니다. 꼬리가 없는 말풍선은 전체 폭으로 늘어납니다. 꼬리가 있는 말풍선은 면이 내용 폭으로 시작 쪽에 남고 꼬리는 전체 폭의 가장자리에 놓여, 왼쪽에서 오른쪽으로 쓰는 화면의 `end` 말풍선은 꼬리가 면에서 떨어집니다. 이런 자리에서는 말풍선을 `Align` 으로 감싸 주세요. `ChatGroup` 은 메시지 묶음 섹션의 Web 안내를 함께 보세요.

### 아바타 · 꼬리 · 목록

- 아바타가 없는 행은 아바타 자리를 비워 두지 않습니다. 그래서 같은 대화에서도 아바타가 있는 행과 없는 행은 말풍선이 시작하는 위치가 다릅니다.
- 꼬리는 말풍선 바깥으로 나오므로 목록의 좌우에 여백을 두세요.
- 행과 행 사이의 간격, 스크롤은 메시지를 담는 목록에서 정합니다.
- 오른쪽에서 왼쪽으로 쓰는 화면에서는 `start` · `end` 행의 배치가 방향을 따라 뒤집힙니다. 꼬리와 꼬리 쪽 모서리는 **물리 방향**(`start` 는 왼쪽, `end` 는 오른쪽)이라 뒤집히지 않습니다.

## 테마와 스타일

겉모습은 두 슬롯으로 바꿉니다. 행과 묶음은 `chatStyle`(`CoreChatStyle`), 말풍선은 `chatBubbleStyle`(`CoreChatBubbleStyle`)입니다. 앱 전체에는 `CoreComponentTheme.chat`(`CoreChatTheme`의 `style`)과 `CoreComponentTheme.chatBubble`(`CoreChatBubbleTheme`의 `style` · `variantStyles`)을 씁니다. `chatStyle` 은 안에 든 말풍선의 모양을 바꾸지 않습니다. `alignment` · `variant` · `tail` 은 위젯 파라미터라 테마로 정할 수 없습니다.

| 바꾸려는 것 | 필드 | 적용되는 위젯 |
| --- | --- | --- |
| 아바타와 내용 사이 | `avatarSpacing` | `Chat` · `ChatGroup` |
| 묶음의 말풍선 사이 | `groupSpacing` | `ChatGroup` |
| 머리글 · 바닥글 글자 | `headerTextStyle` · `footerTextStyle` | `Chat` · `ChatGroup` |
| 말풍선의 여백 · 모서리 · 색 · 폭 · 꼬리 · 글자 | API의 `CoreChatBubbleStyle` 필드 | `ChatBubble` |

### 값이 정해지는 순서

뒤에 있는 것이 앞의 값을 필드마다 덮습니다.

```text
CoreChatStyle.defaultX                                  // 디자인 시스템 기본값
  → CoreComponentTheme.chat.style                       // 앱 전체
  → chatStyle                                           // 행 · 묶음 하나

CoreChatBubbleStyle.defaultX                            // 공통 기본값
  → CoreChatBubbleStyle.defaultsByVariant[variant]      // variant 기본값
  → CoreComponentTheme.chatBubble.style                 // 앱 전체
  → CoreComponentTheme.chatBubble.variantStyles[variant] // 앱 전체, variant 하나
  → chatBubbleStyle                                     // 말풍선 하나
```

- 글자 스타일은 안의 필드까지 합칩니다. 색만 적으면 기본 글자 역할은 그대로 남습니다.
- `chatBubble.style` 은 variant 기본값보다 우선합니다. 여기에 `backgroundColor` 를 적으면 `plain` 을 포함한 모든 variant가 그 색을 쓰고, `padding` 이나 `maxWidthFactor` 를 적으면 `plain` 의 여백 0과 폭 100%도 바뀝니다. variant마다 다르게 바꾸려면 `variantStyles` 를 씁니다. 키는 정렬의 기본값까지 반영해 정해진 variant입니다.
- 말풍선 글자색은 `foregroundColor` 로 바꾸세요. `textStyle.color` 에 색 토큰을 적으면 Flutter에는 적용되지만 Web에는 적용되지 않습니다.
- 말풍선의 면은 콘텐츠 층의 서페이스입니다. 서페이스 스타일이 콘텐츠 층에 재질을 정하면 채움이 있는 말풍선에 적용됩니다. 밀도는 말풍선의 여백과 모서리를 바꾸고, 서페이스 스타일은 모서리를 바꿀 수 있습니다.

### 사용 예

<Preview demo="chat/theme-instance" />

<Split>

<Code language="dart" title="메시지 하나만 바꾸기">
Chat(
  alignment: CoreChatAlignment.end,
  header: Text('나'),
  chatStyle: CoreChatStyle(
    headerTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.primary),
    ),
  ),
  bubble: ChatBubble(
    chatBubbleStyle: CoreChatBubbleStyle(
      backgroundColor: CoreColor.token(CoreColors.primaryContainer),
      foregroundColor: CoreColor.token(CoreColors.onPrimaryContainer),
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
    child: Text('색과 모서리를 바꿨어요'),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    // 꼬리는 위에서 나가고, 꼬리 없는 말풍선은 그 모서리가 6이 됩니다.
    chatBubble: CoreChatBubbleTheme(
      style: CoreChatBubbleStyle(
        tailEdge: CoreChatBubbleTailEdge.top,
        tailCornerRadius: CoreRadius.radius6,
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Chat` 에 `withStyle` 을 이어 `chatStyle` 을 덧붙일 수 있습니다. 앞서 있던 `chatStyle` 위에 합치고, 같은 필드는 나중에 이은 값이 이깁니다. `ChatGroup` 에도 같은 `withStyle` 이 있고, `ChatBubble` 에는 없으므로 `chatBubbleStyle` 을 직접 넘깁니다. Web에서는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 체인 뒤에도 남습니다. 아래 예제의 `groupSpacing` 은 `ChatGroup` 만 읽는 값이라 `Chat` 에서는 달라지는 것이 없습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ChatChainExample extends StatelessWidget {
  const ChatChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Chat(
          avatar: Avatar(initials: 'C'),
          header: Text('이코드'),
          bubble: ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: Text('오전 11:30'),
        ).withStyle(
          const CoreChatStyle(
            avatarSpacing: CoreSpace.space16,
            groupSpacing: CoreSpace.space4,
            headerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelLarge,
              color: CoreColor.token(CoreColors.primary),
            ),
            footerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelSmall,
              color: CoreColor.token(CoreColors.onSurfaceVariant),
            ),
          ),
        ),
        const Gap.space12(),
        const Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('회사 앞 국숫집 어때요?'),
          ),
          footer: Text('오전 11:31'),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ChatChainExample extends StatelessComponent {
  const ChatChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Chat(
          avatar: Avatar(initials: 'C'),
          header: const Text('이코드'),
          bubble: const ChatBubble(
            child: Text('오늘 점심 뭐 먹을까요?'),
          ),
          footer: const Text('오전 11:30'),
        ).withStyle(
          const CoreChatStyle(
            avatarSpacing: CoreSpace.space16,
            groupSpacing: CoreSpace.space4,
            headerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelLarge,
              color: CoreColor.token(CoreColors.primary),
            ),
            footerTextStyle: CoreTextStyle.token(
              CoreTextStyles.labelSmall,
              color: CoreColor.token(CoreColors.onSurfaceVariant),
            ),
          ),
        ),
        const Gap.space12(),
        const Chat(
          alignment: CoreChatAlignment.end,
          bubble: ChatBubble(
            child: Text('회사 앞 국숫집 어때요?'),
          ),
          footer: Text('오전 11:31'),
        ),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<Preview demo="chat/chain" />

<a id="접근성-accessibility"></a>

## 접근성

`Chat` · `ChatGroup` · `ChatBubble` 은 메시지의 모양을 만드는 표시용 레이아웃입니다. 대화라는 구조는 전달하지 않으므로, 필요한 정보는 슬롯의 글과 감싸는 목록에서 알려야 합니다.

### 역할

세 위젯은 두 플랫폼 모두 역할이나 이름을 붙이지 않습니다.

| 플랫폼 | 그리는 것 |
| --- | --- |
| Jaspr Web | 루트는 `<div>` 이고 위젯이 정하는 role과 aria 속성은 없습니다. 꼬리가 있는 말풍선은 감싸는 `<div>` 안에 말풍선 `<div>` 를 두고, 빈 꼬리 `<div>` 는 말풍선 `<div>` 안에서 내용 뒤에 둡니다. `attributes` 에 적은 값은 루트에 붙습니다. `article` 같은 의미 태그는 쓰지 않습니다 |
| Flutter | 위젯이 직접 두는 `Semantics` 는 없습니다. 레이아웃과 장식을 그리는 위젯으로만 이루어집니다 |

슬롯에 넣은 자식은 자기 역할을 그대로 가집니다. 예를 들어 Web의 `Avatar` 는 `role="img"` 이고 이름은 `initials`(없으면 `avatar`)입니다.

### 키보드

없음. 세 위젯은 보여 주기만 하므로 키 입력을 처리하지 않고, 조작할 요소도 만들지 않습니다. 슬롯에 넣은 버튼이나 링크는 각자의 키보드 동작을 따릅니다.

### 스크린 리더

세 위젯이 더하는 안내는 없습니다. 메시지라는 사실, 보낸 사람, 어느 쪽 메시지인지는 따로 전달하지 않고, 전달되는 것은 슬롯에 넣은 내용입니다.

- Web의 DOM 순서는 `start` 행이 `avatar` → `header` → `bubble` → `footer` 이고, `end` 행은 `header` → `bubble` → `footer` → `avatar` 입니다.
- 꼬리는 장식입니다. Web은 글이 없는 빈 `<div>` 이고, Flutter는 의미 정보 없이 `CustomPaint` 로 그립니다.
- 발신자 구분은 정렬과 면 색이라는 시각 신호이므로, 보낸 사람은 `header` 의 글로도 알려 주세요.

```dart
Chat(
  header: Text(senderName),
  bubble: ChatBubble(child: Text(message)),
)
```

### 포커스 관리

없음. 세 위젯에는 포커스를 받는 요소, 포커스 표시, `tabindex`, 자동 포커스가 없고, 메시지를 더해도 포커스를 옮기지 않습니다. 포커스를 받는 것은 슬롯에 넣은 자식뿐입니다.

### 알려진 제약

- `role="log"` 나 `aria-live`(Flutter의 `liveRegion`)를 두지 않아, 새로 도착한 메시지를 위젯이 알리지 않습니다. 실시간 대화라면 메시지를 담는 목록에서 알림 방법을 정해야 합니다.
- 목록과 항목 구조가 없습니다. `ChatGroup` 의 연속 말풍선도 목록 항목이 아닙니다.
- `header` 와 `footer` 는 말풍선과 `aria-labelledby` 나 `Semantics` 로 연결되지 않은 별도의 글입니다.
- 보낸 쪽과 받은 쪽은 정렬과 색으로만 구분됩니다.
- 오른쪽에서 왼쪽으로 쓰는 화면에서는 행의 배치만 뒤집히고 꼬리의 방향은 그대로입니다.

모션 감소 · 고대비 · 최소 터치 타깃처럼 모든 컴포넌트에 공통으로 적용되는 축은 [전역 접근성 축](/accessibility) 에 정리되어 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

위젯 이름과 `alignment` · `variant` · `tail` · 스타일 슬롯은 두 플랫폼이 같습니다. 아래는 다른 점입니다.

| 항목 | Flutter | Web |
| --- | --- | --- |
| 행 구조 | `Row` · `Column` | flex 행 · 열인 `div` |
| 행의 폭 | 부모가 폭을 꽉 줄 때 전체 폭 | 부모 폭의 100% |
| 최대 폭 | 부모가 주는 최대 폭 × 비율 | CSS `max-width` 백분율 |
| 묶음의 최대 폭 | 말풍선이 쓸 수 있는 폭 기준 | 묶음 상자의 내용 폭 기준 |
| 꼬리 | `CustomPaint` 경로 | `clip-path` 로 자른 `div`, 배경은 말풍선에서 상속 |
| 아이콘 색 | 말풍선 글자색을 따르지 않음 | 말풍선 글자색을 따름 |
| `textStyle` 의 색 토큰 | 적용됨 | 적용되지 않음 |
| 추가 파라미터 | `key` | `key` · `id` · `classes` · `css` · `attributes` · `eventHandlers` |
| `ChatBubble.copyWith` | 없음 | 있음 |

- **꼬리 모양** — 두 플랫폼은 같은 경로를 그리며, 위쪽 꼬리는 그 경로를 위아래로 뒤집은 모양입니다. Web은 꼬리 상자의 크기와 위치를 `rem` 으로, 상자를 자르는 경로를 `px` 로 적습니다. 그래서 브라우저의 루트 글자 크기가 16px가 아니면 꼬리의 위치나 모양이 어긋날 수 있습니다.
- **아이콘 색** — Flutter의 `ChatBubble` 은 글자색만 아래로 전달합니다. 말풍선에 넣은 `Icon` 은 바깥의 아이콘 색(`CoUIApp` 기본은 `onSurface`)을 쓰므로, `primary` 같은 말풍선에서는 `iconStyle: CoreIconStyle(color: …)` 로 색을 직접 적으세요. Web의 `Icon` 은 따로 정한 색이 없으면 글자색을 따릅니다.
- **Web 속성이 붙는 곳** — 꼬리가 없는 말풍선은 말풍선 `div` 에 `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 붙습니다. 꼬리가 있으면 바깥의 감싸는 `div` 에 붙으므로, `css` 에 적은 배경색 같은 값은 말풍선 면이 아니라 감싸는 상자에 적용됩니다. 면의 모양은 `chatBubbleStyle` 로 바꾸세요.
- **Flutter의 크기 계산** — `ChatBubble` 은 폭을 `LayoutBuilder` 로 잽니다. `LayoutBuilder` 는 내용 크기를 미리 알려 주지 못하므로, `IntrinsicWidth` · `IntrinsicHeight` 가 그 크기를 물으면 디버그 빌드에서 레이아웃 오류가 납니다. 기본 `Card` 도 가로 폭을 꽉 받지 못하면 `IntrinsicWidth` 로 폭을 정합니다. 대화를 `Card` 에 담을 때는 부모가 폭을 꽉 주게 하거나 `cardStyle: CoreCardStyle(sizing: CoreCardSizing.expand)` 를 적으세요.

<a id="props"></a>
<a id="props-parameters"></a>

## API

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다. 세 위젯 모두 선택 파라미터 `key` 를 받습니다.

### `Chat` 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `bubble` | `W` | 필수 | 메시지 본문. 보통 `ChatBubble` |
| `avatar` | `W?` | `null` | 내용 옆에 놓는 아바타 |
| `header` | `W?` | `null` | 말풍선 위의 글. 보낸 사람 이름 등 |
| `footer` | `W?` | `null` | 말풍선 아래의 글. 시각 · 전달 상태 등 |
| `alignment` | `CoreChatAlignment` | `start` | 행이 놓이는 쪽. `bubble` 슬롯의 말풍선에도 넘깁니다 |
| `chatStyle` | `CoreChatStyle?` | `null` | 아바타 간격과 머리글 · 바닥글 글자 덮어쓰기 |

<a id="chatgroup"></a>

### `ChatGroup` 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `bubbles` | `List<W>` | 필수 | 같은 발신자의 연속 메시지. 준 순서대로 쌓습니다 |
| `avatar` | `W?` | `null` | 묶음에 한 번 놓는 아바타 |
| `header` | `W?` | `null` | 첫 말풍선 위의 글 |
| `footer` | `W?` | `null` | 마지막 말풍선 아래의 글 |
| `alignment` | `CoreChatAlignment` | `start` | 묶음이 놓이는 쪽. 말풍선에는 넘기지 않습니다 |
| `chatStyle` | `CoreChatStyle?` | `null` | 아바타 · 말풍선 간격과 머리글 · 바닥글 글자 덮어쓰기 |

<a id="chatbubble"></a>

### `ChatBubble` 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 메시지 내용 |
| `variant` | `CoreChatBubbleVariant?` | `null` | 색 variant. `null` 이면 `start` 는 `neutral`, `end` 는 `primary` |
| `alignment` | `CoreChatAlignment?` | `null` | 말풍선의 정렬. `null` 이면 감싼 행의 정렬, 행 밖이면 `start`. 위치는 옮기지 않습니다 |
| `tail` | `bool?` | `null` | 꼬리 표시. `null` 이면 `start` 는 없음, `end` 는 있음. 채움이 없으면 그리지 않습니다 |
| `chatBubbleStyle` | `CoreChatBubbleStyle?` | `null` | 말풍선 하나의 겉모습 덮어쓰기 |

### Web 전용 속성

`Chat` · `ChatGroup` · `ChatBubble` 의 Web 생성자는 아래 값도 받습니다. 붙는 요소는 플랫폼 차이 섹션을 보세요.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트의 HTML `id` |
| `classes` | `String?` | `null` | 루트에 더하는 CSS 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트에 더하는 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트에 연결하는 DOM 이벤트 |

### 메서드

- `Chat.copyWith` · `ChatGroup.copyWith` — 두 플랫폼에 있습니다. 준 값만 바꾼 새 위젯을 돌려줍니다.
- `ChatBubble.copyWith` — Web에만 있습니다.
- `Chat.withStyle(patch)` · `ChatGroup.withStyle(patch)` — `CoreChatStyle` 을 `chatStyle` 에 합친 새 위젯을 돌려줍니다.

### `ChatAlignmentScope`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `alignment` | `CoreChatAlignment` | 필수 | 아래의 말풍선에 넘기는 정렬 |
| `child` | `W` | 필수 | 정렬을 받는 하위 트리 |

정적 메서드 `ChatAlignmentScope.maybeOf(context)` 는 위에서 가장 가까운 정렬을 돌려주고, 없으면 `null` 입니다.

### 값 타입

- `CoreChatAlignment` — `start` · `end`. `CoreChatAlignment.defaultAlignment` 는 `start` 입니다.
- `CoreChatBubbleVariant` — `neutral` · `primary` · `secondary` · `accent` · `info` · `success` · `warning` · `error` · `plain`. `CoreChatBubbleVariant.defaultVariant` 는 `neutral` 입니다.
- `CoreChatBubbleTailEdge` — `top` · `bottom`.
- `CoreChatBubbleContract.defaultVariantFor(alignment)` · `CoreChatBubbleContract.defaultTailFor(alignment)` — 정렬이 정하는 기본 variant와 꼬리를 돌려주는 정적 메서드입니다.

### `CoreChatBubbleStyle` 필드

모든 필드는 선택이고, 적지 않으면 아래 기본값을 씁니다. 길이는 logical px 기준입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `padding` | `CoreEdgeInsets?` | 상하 10 · 좌우 14 (`plain` 은 0) | 말풍선 안쪽 여백 |
| `borderRadius` | `CoreBorderRadius?` | 네 모서리 14 | 말풍선 모서리 |
| `backgroundColor` | `CoreColor?` | variant의 면 색 | 면 색. 꼬리도 이 색을 따릅니다 |
| `foregroundColor` | `CoreColor?` | variant의 글자색 | 내용의 글자색 |
| `maxWidthFactor` | `double?` | 0.75 (`plain` 은 1) | 쓸 수 있는 폭에 대한 최대 폭 비율 |
| `tailWidth` | `double?` | 8 | 꼬리 폭 |
| `tailHeight` | `double?` | 8 | 꼬리 높이 |
| `tailTipRadius` | `double?` | 4 | 꼬리 끝의 둥글기 |
| `tailEdge` | `CoreChatBubbleTailEdge?` | `bottom` | 꼬리와 꼬리 쪽 모서리가 놓이는 변 |
| `tailCornerRadius` | `double?` | `borderRadius` 의 같은 모서리 | 꼬리를 그리지 않을 때의 꼬리 쪽 모서리 |
| `textStyle` | `CoreTextStyle?` | `bodyLarge` 역할 | 내용의 글자. 색은 `foregroundColor` 로 바꾸세요 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreChatStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `avatarSpacing` | `double?` | Padding spacing between the avatar and the message column (logical px). Fed into the avatar wrapper's `EdgeInsetsDirectional` (Flutter) / `margin-inline-*` (Web) — not a `Gap`, so the value stays a raw double. |
| `groupSpacing` | `double?` | Inter-bubble spacing between consecutive bubbles inside a `ChatGroup` (logical px, pre-scaling). Forwarded directly to `Column.spacing` (Flutter) / flex `gap` CSS (Web) — both are native paint-API arguments that consume raw doubles, so this slot stays scalar (`double`). |
| `headerTextStyle` | `CoreTextStyle?` | Optional text style for the header slot (sender name). |
| `footerTextStyle` | `CoreTextStyle?` | Optional text style for the footer slot (timestamp / status). |

### `CoreChatStyle` 변형별 기본값 (`CoreChatBubbleVariantStyle`)

| 필드 | `neutral` | `primary` | `secondary` | `accent` | `info` | `success` | `warning` | `error` | `plain` |
|------|------|------|------|------|------|------|------|------|------|
| `backgroundColor` | surfaceContainerHigh | primary | secondary | tertiary | info | success | warning | error | transparent |
| `foregroundColor` | onSurface | onPrimary | onSecondary | onTertiary | onInfo | onSuccess | onWarning | onError | onSurfaceVariant |
| `padding` | — | — | — | — | — | — | — | — | zero |
| `maxWidthFactor` | — | — | — | — | — | — | — | — | 1 |

<!-- STYLE_TABLE:END -->

<Note>

생성된 두 번째 표는 제목에 `CoreChatStyle` 이 적혀 있지만, 실제로는 `ChatBubble` 의 variant별 기본값(`CoreChatBubbleStyle.defaultsByVariant`)입니다. `—` 칸은 공통 기본값(여백 상하 10 · 좌우 14, 최대 폭 비율 0.75)을 씁니다. `CoreChatStyle` 의 필드를 적지 않으면 `avatarSpacing` 은 8, `groupSpacing` 은 4이고, 머리글과 바닥글은 구조 섹션에 적은 기본 글자를 씁니다. 첫 표의 두 간격은 적은 값이 늘 그대로 그려지지는 않습니다. Flutter는 테마의 밀도와 `scaling` 을 적용하고, Web은 간격 단계에 있는 값을 `--coui-space-*` 변수로 씁니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="chat/related-avatar" title="Avatar">

메시지를 보낸 사람을 사진이나 이니셜로 보여 줍니다. `avatar` 슬롯에 넣습니다. [Avatar](/components/avatar)

</Card>
<Card demo="chat/related-loading" title="Loading">

AI 답을 기다리는 동안의 진행 표시입니다. [Loading](/components/loading)

</Card>
<Card demo="chat/related-text-field" title="TextField">

메시지를 입력하는 칸입니다. [TextField](/components/text-field)

</Card>
</Cards>
