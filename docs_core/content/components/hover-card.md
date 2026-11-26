---
title: HoverCard
description: 트리거 요소에 호버 시 추가 정보를 표시하는 카드 컴포넌트
category: overlay
platforms: [flutter, web]
related: [popover, tooltip, popup]
tags: [hover-card, overlay, preview, hover]
template: v2
source: overlay/hover_card
---

# HoverCard

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 카드를 확인하고, 그림 아래의 **올려 보기** 버튼에 포인터를 올려 같은 속성의 `HoverCard`를 열어 보세요. 만들어진 코드는 두 플랫폼에서 그대로 쓸 수 있습니다.

<Playground component="hover-card" />

`HoverCard`는 트리거에 포인터를 올리고 0.5초(`openDelay`)가 지나면 열리고, 트리거와 카드를 모두 벗어난 뒤 0.5초(`closeDelay`)가 지나면 닫힙니다. 트리거를 길게 눌러도 열립니다. 키보드로는 열 수 없고, 코드로 여닫는 `open` 값이나 컨트롤러도 없습니다. 카드 안의 내용은 보조 미리 보기로만 씁니다.

<Note>

무대의 카드는 페이지 안에 그린 그림입니다. 실제 카드는 열리면 오버레이에 떠서 트리거에 붙으므로 문서의 그 자리에 둘 수 없습니다. 그림은 실제 카드와 같은 판(`Popup`)을 `HoverCard`가 쓰는 값으로 그린 것이라, 색 · 모서리 · 여백 · 그림자 · 폭 상한과 테마(`CoreHoverCardTheme` · `CorePopupTheme`) · 서페이스 스타일은 그림에도 닿습니다. 화면 가장자리에서 자리를 바꾸는 것, 대기 시간, 열고 닫는 움직임, 포인터를 카드로 옮겨 가는 동작은 **올려 보기**로 여는 실제 `HoverCard`에서만 볼 수 있습니다. 이 페이지의 다른 미리보기도 같은 그림입니다.

</Note>

## 구조

`HoverCard`는 늘 보이는 트리거와, 열려 있는 동안만 오버레이에 그려지는 카드로 이루어집니다. 두 위젯 슬롯 `trigger`와 `content`는 모두 필수입니다.

<Anatomy demo="hover-card/anatomy">
<AnatomyItem select="[data-docs-part=trigger]" side="left" name="trigger">

트리거. 포인터를 올리거나 길게 누르면 카드가 열립니다. 트리거 위의 마우스 커서는 손 모양이 되고, 트리거 안의 글자는 선택되지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

카드의 판. `Popup`으로 그립니다. 바탕은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12(패널 역할), 안쪽 여백은 16, 그림자는 `lg` 단계, 글자색은 `onSurface`입니다. 트리거에서 4(`placementOffset`) 떨어진 자리에 놓입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="content">

카드의 내용. `content`로 넘긴 위젯이 판의 안쪽 여백 안에 놓입니다.

</AnatomyItem>
</Anatomy>

### 판의 크기와 내용

카드의 폭은 `content`가 차지하는 만큼이고 256을 넘지 않습니다. 긴 글은 그 폭에서 줄을 바꿉니다.

<Preview component="hover-card" props="long" />

내용에는 원하는 위젯을 넣습니다. 여러 줄을 쌓을 때는 Flutter는 `Column`, Web은 `div`로 묶습니다. Flutter의 카드는 내용의 폭을 미리 재어 자기 폭을 정하므로, 크기를 미리 잴 수 없는 위젯(안에서 `LayoutBuilder`를 쓰는 위젯)을 그대로 넣으면 오류가 날 수 있습니다. 그런 위젯은 폭을 정한 `SizedBox`로 감쌉니다.

<Preview demo="hover-card/profile" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
HoverCard(
  trigger: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: openProfile,
    child: Text('@hong'),
  ),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space8,
    children: [
      Avatar(initials: 'HG'),
      Text('홍길동').titleSmall.onSurface,
      Text('@hong · 프로덕트 디자이너').bodySmall.onSurfaceVariant,
      Text('팔로워 128 · 팔로잉 64').labelSmall.onSurfaceVariant,
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
HoverCard(
  trigger: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: openProfile,
    child: Text('@hong'),
  ),
  content: div(
    classes: 'flex flex-col items-start gap-space8',
    [
      Avatar(initials: 'HG'),
      Text('홍길동').titleSmall.onSurface,
      Text('@hong · 프로덕트 디자이너').bodySmall.onSurfaceVariant,
      Text('팔로워 128 · 팔로잉 64').labelSmall.onSurfaceVariant,
    ],
  ),
)
```

  </TabItem>
</Tabs>

<a id="동작-스펙-behavior"></a>

## 상태

`HoverCard`는 닫힘과 열림 두 상태를 가지며, 열림은 컴포넌트가 스스로 관리합니다. 앱이 여닫는 `open` 값이나 컨트롤러, 비활성 파라미터, 선택 콜백은 없습니다.

<a id="기본-사용법-basic-usage"></a>

### 열고 닫기

`trigger`와 `content`만 주면 아래쪽에 열립니다. 자리 · 대기 시간 · 닫힘 알림은 파라미터로 바꿉니다.

```dart
HoverCard(
  trigger: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: openProfile,
    child: Text('@coui'),
  ),
  content: Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
)

// 위쪽에 열고, 대기 시간을 바꾸고, 닫힐 때 알림 받기
HoverCard(
  placement: CorePopoverPlacement.top,
  openDelay: Duration(milliseconds: CoreDuration.moderate),
  closeDelay: Duration(milliseconds: CoreDuration.normal),
  onClose: handleCardClose,
  trigger: Button(
    variant: CoreButtonVariant.outline,
    onPressed: openHelp,
    child: Text('도움말'),
  ),
  content: Text('추가 정보를 여기에 보여 줍니다.').bodySmall.onSurface,
)
```

<a id="인터랙션"></a>

### 여는 동작과 닫는 동작

| 동작 | Flutter | Jaspr Web |
| --- | --- | --- |
| 트리거에 포인터를 올림 | `openDelay`(기본 500ms) 뒤에 엽니다. 그 전에 벗어나면 열지 않습니다 | 같습니다 |
| 트리거에서 카드로 포인터를 옮김 | 열린 채로 둡니다 | 같습니다 |
| 트리거와 카드를 모두 벗어남 | `closeDelay`(기본 500ms) 뒤에 닫습니다 | 같습니다 |
| 트리거를 길게 누름 | 길게 누르기로 인식되면 바로 엽니다. `openDelay`는 쓰지 않습니다 | `openDelay` 동안 누르고 있으면 엽니다. 그 전에 떼면 길게 누르기로는 열지 않습니다. 다만 마우스는 트리거 위에 있으면 눌렀다 떼도 올려 둔 대기로 열리고, 터치 화면에서도 브라우저가 탭 뒤에 마우스 이벤트를 보내면 짧게 눌러 열릴 수 있습니다 |
| 카드 밖을 누름 | 닫습니다. 트리거를 눌러도 닫힙니다 | 닫지 않습니다 |
| `Escape` | 닫지 않습니다 | 닫지 않습니다 |

트리거와 카드 사이에는 `placementOffset`(기본 4)만큼 틈이 있습니다. 포인터는 `closeDelay` 안에 이 틈을 건너 카드에 닿아야 하므로, `closeDelay`를 0에 가깝게 두면 카드로 옮겨 가기 전에 닫힐 수 있습니다. 반대로 `openDelay`를 너무 짧게 두면 포인터가 지나가기만 해도 카드가 떠서 방해가 됩니다.

### 닫힘 알림

`onClose`는 카드가 닫히기 시작할 때 부릅니다. Web의 카드는 포인터가 벗어나야만 닫히므로 그렇게 닫힐 때마다 부릅니다. 다만 Web에서 `closeDelay`를 `transitionDuration`보다 짧게 두면, 닫히는 움직임 중에 포인터가 트리거에 들어왔다가 다시 나갈 때 한 번 더 부를 수 있습니다. Flutter는 포인터가 벗어나 닫힐 때만 부르고, 카드 밖을 눌러 닫힌 경우에는 부르지 않습니다. 두 플랫폼 모두 `HoverCard`가 화면에서 사라지며 카드가 함께 없어질 때는 부르지 않습니다. 열렸다고 알려 주는 콜백은 없습니다.

<a id="상태-전환"></a>

### 애니메이션

카드는 0.9배에서 1배로 커지면서 서서히 나타나고, 다시 0.9배로 작아지면서 서서히 사라집니다. 크기와 불투명도가 함께 바뀝니다(뒤를 흐리는 유리 스타일은 표 아래의 안내를 보세요). 크기가 바뀌는 기준점과 시간은 플랫폼마다 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 크기가 바뀌는 기준점 | 카드에서 트리거 쪽 변의 가운데 | 카드의 가운데 |
| 열 때 | 150ms, linear | `transitionDuration`(기본 200ms), `CoreEasing.enter` 곡선 |
| 닫을 때 | 100ms 동안이며, 보이는 변화는 앞의 3분의 2(약 67ms)에서 끝납니다 | `transitionDuration`, `CoreEasing.exit` 곡선 |
| `transitionDuration` 덮어쓰기 | 반영되지 않습니다 | 열 때와 닫을 때 모두 반영됩니다 |
| 동작 줄이기 | 킷의 동작 줄이기 처리가 이 전환에 닿지 않습니다. `disableAnimations`를 켜는 설정(Android의 애니메이션 삭제)에서는 Flutter가 전환을 거의 한 프레임으로 줄일 수 있고, iOS의 '동작 줄이기'에서는 그대로 움직일 수 있습니다 | 500ms 이하의 전환 시간(기본값 포함)이 0이 됩니다 |

`openDelay`와 `closeDelay`는 동작 줄이기를 켜도 그대로입니다. 뒤를 흐리는 유리 스타일에서 카드가 나타나고 사라지는 방식은 [서페이스 스타일](/guides/surface-styles#유리-패널이-나타나고-사라질-때)의 "유리 패널이 나타나고 사라질 때"를 보세요.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

`HoverCard`는 누르지 않고도 맥락을 더 보여 주는 보조 미리 보기입니다.

- 사용자 멘션이나 링크에 포인터를 올리면 미리 보기를 보여 줄 때
- 아이콘이나 줄인 글에 자세한 정보를 덧붙일 때
- `Tooltip`의 짧은 안내로는 모자란 정보를 보여 줄 때

키보드 사용자는 카드를 열 수 없습니다. 터치 화면에는 포인터를 올리는 동작이 없어 길게 눌러 열 수 있지만, 그 동작을 모르면 카드를 보지 못할 수 있습니다. 중요한 정보와 행동은 카드에만 두지 말고, 같은 곳에 닿는 다른 길을 함께 둡니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 버튼 이름이나 짧은 도움말 한 줄 | [Tooltip](/components/tooltip) |
| 눌러서 열고 안에서 조작하는 패널, 코드로 여닫아야 하는 패널 | [Popover](/components/popover) |
| 트리거에서 고를 행동 목록 | [DropdownMenu](/components/dropdown-menu) |
| 사용자의 응답이 필요한 확인 | [Dialog](/components/dialog) |

<a id="do"></a>
<a id="dont"></a>

### 내용과 트리거

<Cards columns="2">
<Card demo="hover-card/profile" tone="do" eyebrow="이렇게 하세요" height="240">

맥락을 미리 보여 주는 정보를 담습니다. 트리거는 눌러서 같은 정보가 있는 화면으로 갈 수 있게 둡니다.

</Card>
<Card demo="hover-card/dont-only-action" tone="dont" eyebrow="이렇게 하지 마세요" height="240">

꼭 해야 하는 행동을 카드에만 두지 않습니다. 키보드 사용자는 이 버튼에 닿을 카드를 열 수 없습니다.

</Card>
<Card demo="hover-card/link-preview" tone="do" eyebrow="이렇게 하세요" height="240">

링크 미리 보기처럼 제목과 요약 몇 줄을 짧게 보여 줍니다.

</Card>
<Card demo="hover-card/dont-form" tone="dont" eyebrow="이렇게 하지 마세요" height="240">

입력 폼은 넣지 않습니다. 입력하는 중이어도 포인터가 벗어나면 카드가 닫힙니다.

</Card>
</Cards>

<a id="조합-예제"></a>

### 문장 속에 넣기

문장 안의 멘션에 카드를 붙일 때 Flutter는 `WidgetSpan`으로 넣습니다. Web의 `HoverCard`는 바깥을 블록 `<div>`로 감싸므로 그대로 넣으면 줄이 바뀝니다. `classes`로 `inline-block`을 주고, 문장은 `<p>`가 아니라 `<div>`로 묶습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Text.rich(
  TextSpan(
    children: [
      TextSpan(text: '안녕하세요, '),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: HoverCard(
          trigger: Link(
            href: '/users/hong',
            onPressed: openProfile,
            child: Text('@홍길동'),
          ),
          content: Text('프로덕트 디자이너').bodySmall.onSurface,
        ),
      ),
      TextSpan(text: ' 반가워요!'),
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div([
  Text('안녕하세요, '),
  HoverCard(
    classes: 'inline-block',
    trigger: Link(
      href: '/users/hong',
      child: Text('@홍길동'),
    ),
    content: Text('프로덕트 디자이너').bodySmall.onSurface,
  ),
  Text(' 반가워요!'),
])
```

  </TabItem>
</Tabs>

<a id="변형-variants"></a>
<a id="방향-placement"></a>

## 배치

카드가 놓일 쪽은 `placement`(`CorePopoverPlacement`)가 정합니다. 기본값은 `bottom`입니다. `HoverCard`에는 variant와 크기 축이 없습니다.

<Preview demo="hover-card/placements" />

```dart
HoverCard(
  placement: CorePopoverPlacement.right,
  trigger: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: openProfile,
    child: Text('@coui'),
  ),
  content: Text('오른쪽에 보여 줍니다.').bodySmall.onSurface,
)
```

### 시작과 끝 맞춤

`CorePopoverPlacement`는 네 방향마다 가운데 · `Start` · `End` 값을 가집니다. **맞춤을 따르는 것은 Web뿐입니다.** Flutter는 `Start` · `End`도 그 방향의 가운데 맞춤으로 그립니다.

| 값 | Jaspr Web | Flutter |
| --- | --- | --- |
| `top` · `bottom` | 트리거의 가로 가운데에 맞춥니다 | 같습니다 |
| `topStart` · `bottomStart` | 트리거의 왼쪽 끝에 맞춥니다 | 가로 가운데 |
| `topEnd` · `bottomEnd` | 트리거의 오른쪽 끝에 맞춥니다 | 가로 가운데 |
| `left` · `right` | 트리거의 세로 가운데에 맞춥니다 | 같습니다 |
| `leftStart` · `rightStart` | 트리거의 위쪽 끝에 맞춥니다 | 세로 가운데 |
| `leftEnd` · `rightEnd` | 트리거의 아래쪽 끝에 맞춥니다 | 세로 가운데 |

### 화면 가장자리와 거리

- 고른 쪽에 카드가 들어가지 않으면 반대쪽으로 넘기고, 놓는 쪽과 직각 방향으로 벗어난 만큼은 화면 안으로 밀어 넣습니다. 화면 가장자리에서는 8을 띄웁니다. Web은 반대쪽에서 덜 넘칠 때만 넘깁니다. Flutter는 놓는 방향으로 넘친 만큼도 밀어 넣어 카드가 트리거를 덮을 수 있고, 화면 키보드가 가린 높이도 비웁니다.
- 트리거와 카드의 거리는 `placementOffset`(기본 4)입니다. Flutter는 테마의 배율(`scaling`)을 곱합니다.
- 밀도를 바꾸면 카드의 안쪽 여백과 모서리는 따라 바뀌고, 폭 상한과 트리거와의 거리는 그대로입니다.
- 열린 동안 페이지를 스크롤하면 Web의 카드는 트리거를 따라가고, Flutter의 카드는 처음 연 자리에 남습니다. 다만 Web에서 카드가 열린 뒤에 `Tooltip` 같은 다른 떠 있는 패널이 열리면, 그 뒤로는 카드가 트리거를 따라가지 않을 수 있습니다.
- 열린 동안 바꾼 `placement`와 `placementOffset`은 두 플랫폼 모두 다음에 열 때 반영됩니다.

### 접히는 화면

화면이 접힘으로 나뉘어 있으면 카드는 트리거의 가운데가 놓인 조각 안에 머뭅니다. 반대쪽으로 넘기고 밀어 넣는 일도 그 조각 안에서 합니다. 화면이 언제 나뉘는지는 [레이아웃](/guides/layout)의 "접히는 화면"을 보세요.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

카드의 모양 · 거리 · 대기 시간 · 전환은 `hoverCardStyle`(`CoreHoverCardStyle`) 하나로 바꿉니다. 판의 색 · 모서리 · 여백 · 그림자 · 폭은 그 안의 `panelStyle`(`CorePopupStyle`)에 줍니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="카드 하나만 바꾸기">
HoverCard(
  trigger: trigger,
  content: content,
  hoverCardStyle: CoreHoverCardStyle(
    placementOffset: CoreSpace.space8,
    panelStyle: CorePopupStyle(
      maxWidth: CoreLayout.layout320,
      borderRadius: CoreBorderRadius.all(
        CoreRadiusRole.surface,
      ),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    hoverCard: CoreHoverCardTheme(
      style: CoreHoverCardStyle(
        openDelay: Duration(
          milliseconds: CoreDuration.moderate,
        ),
        closeDelay: Duration(
          milliseconds: CoreDuration.moderate,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

카드의 판은 `Popup`이라 앱의 `CorePopupTheme`도 카드에 닿습니다. 다만 최소 폭 0과 최대 폭 256은 `HoverCard`의 기본값이 그 위에 덮이므로, 카드의 폭은 `CoreHoverCardTheme`이나 `hoverCardStyle`의 `panelStyle`로 바꿉니다.

</Note>

### 값이 정해지는 순서

```text
대기 시간 (openDelay · closeDelay)
  CoreHoverCardStyle 기본값 500ms
    → CoreHoverCardTheme.style          // 앱 전체
    → hoverCardStyle                    // 카드 하나
    → openDelay · closeDelay 파라미터

카드의 판 (panelStyle)
  CorePopupStyle 기본값
    → CorePopupTheme.style              // 앱의 모든 Popup
    → HoverCard 기본값 (최소 폭 0 · 최대 폭 256)
    → CoreHoverCardTheme.style.panelStyle
    → hoverCardStyle.panelStyle
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다. `placementOffset`과 `transitionDuration`은 기본값 → 테마 → `hoverCardStyle` 순서입니다.

### 빠른 오버라이드 (Chain)

이미 만든 `HoverCard`에 스타일을 덧붙일 때는 `withStyle`을 이어 씁니다. `hoverCardStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다. `.radius16` · `.primary` 같은 getter는 이름이 같은 Core 토큰으로 카드 판의 모서리 · 바탕을 바꿉니다. 바탕만 바꾸고 글자색은 그대로이므로, `.primary`처럼 진한 바탕을 쓰면 `content`의 글자색도 함께 정합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class HoverCardChainExample extends StatelessWidget {
  const HoverCardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        HoverCard(
          trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·padding)까지 한 번에.
        HoverCard(
          trigger: const Text('직접 지정').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).withStyle(
          const CoreHoverCardStyle(
            panelStyle: CorePopupStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
              borderColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class HoverCardChainExample extends StatelessComponent {
  const HoverCardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        HoverCard(
          trigger: const Text('@coui').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·padding)까지 한 번에.
        HoverCard(
          trigger: const Text('직접 지정').bodyMedium.onPrimaryContainer.underline,
          content: const Text('크로스 플랫폼 UI 디자인 시스템.').bodySmall.onSurface,
          placement: CorePopoverPlacement.bottom,
        ).withStyle(
          const CoreHoverCardStyle(
            panelStyle: CorePopupStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
              borderColor: CoreColor.token(CoreColors.tertiary),
              borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space24,
                vertical: CoreSpace.space8,
              ),
            ),
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

`HoverCard`는 포인터로 여는 미리 보기입니다. 트리거에는 눌러서 쓸 수 있는 버튼이나 링크를 두고, 카드의 내용에 닿는 다른 길을 함께 만듭니다.

### 역할

| 플랫폼 | 트리거 | 카드 |
| --- | --- | --- |
| Flutter | `Semantics(container: true, expanded: …)` — 라벨과 역할은 더하지 않고, 카드가 열렸는지만 싣습니다 | `Popup`의 `Semantics(container: true)` — 역할과 이름이 없습니다 |
| Jaspr Web | 트리거를 감싼 `<div>`에 `aria-haspopup="dialog"`와 `aria-expanded` | `role="dialog"` — 이름이 없습니다 |

Web의 두 `aria-*` 값은 컴포넌트가 트리거를 감싼 상자에 붙이고, 호출자가 준 `attributes`는 컴포넌트의 바깥 상자에 붙습니다. 그래서 이 두 값을 바꾸거나 카드에 `aria-label`을 줄 수 없습니다. 트리거와 카드를 잇는 `aria-controls` · `aria-describedby`도 없습니다.

### 키보드

카드를 여닫는 키가 없습니다.

| 키 | 동작 |
| --- | --- |
| `Tab` | 트리거에 넣은 버튼이나 링크로 갑니다. `HoverCard`가 트리거를 감싸는 상자는 포커스를 받지 않습니다 |
| `Enter` · `Space` | 트리거에 넣은 위젯의 동작만 실행합니다. 카드는 열리지 않습니다 |
| `Escape` | 열린 카드를 닫지 않습니다 |

트리거가 포커스를 받아도 카드는 열리지 않습니다. 두 플랫폼 모두 포커스를 듣지 않습니다.

### 스크린 리더

- 트리거의 이름은 `trigger`에 넣은 위젯에서만 옵니다. 아이콘만 있는 트리거는 앱이 이름을 붙입니다 — Flutter는 `Semantics(label: …)`로 감싸고, Web은 버튼의 `attributes`에 `aria-label`을 줍니다.
- 카드가 열리고 닫히는 것을 따로 알리는 라이브 영역은 없습니다.
- Flutter 트리거의 '펼쳐짐' 값은 카드가 열리거나 닫혀도 바로 바뀌지 않을 수 있습니다. 컴포넌트가 다시 그려질 때 반영됩니다.
- Web의 `aria-expanded`는 카드가 열리면 `true`, 닫히는 움직임이 끝나면 `false`가 됩니다. 다만 역할이 없는 `<div>`에 붙어 있어, 안의 버튼을 읽을 때 함께 읽히지 않을 수 있습니다. 카드는 열려 있는 동안에만 문서에 있습니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 카드 안의 요소로 포커스를 옮기지 않습니다 | 같습니다 |
| 닫을 때 | 포커스를 되돌리는 동작이 없습니다 | 같습니다. 카드 안에 있던 포커스는 카드와 함께 사라집니다 |
| 가두기 | 없습니다 | 없습니다 |
| 카드 안의 `Tab` 순서 | 카드는 루트 `Overlay`의 별도 포커스 범위에 놓여, 트리거에서 `Tab`을 눌러도 카드 안으로 바로 가지 않을 수 있습니다 | 카드는 오버레이 호스트의 팝오버 층에 놓여, 카드 안의 요소는 트리거 바로 다음이 아니라 앱 콘텐츠 뒤의 순서에 놓입니다 |

카드 안에 포커스가 있어도 포인터가 트리거와 카드를 벗어나면 카드는 닫힙니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드만으로는 카드를 열 수 없습니다. 카드 안의 정보와 행동은 보조 미리 보기로만 쓰고, 같은 곳에 닿는 다른 길(트리거를 누르면 상세 화면으로 가는 식)을 반드시 둡니다. |
| 공통 | 포인터를 옮기지 않고 카드를 닫는 키(`Escape`)가 없습니다. |
| 공통 | 트리거 크기에 하한이 없습니다. 24×24를 보장하지 않으므로, 터치를 지원하면 앱이 충분한 누를 자리를 확보합니다. |
| Flutter | 트리거의 '펼쳐짐' 값이 카드의 열림과 어긋나 있을 수 있습니다. |
| Jaspr Web | 카드(`role="dialog"`)에 이름을 줄 방법이 없습니다. |
| Jaspr Web | 카드는 포인터가 벗어났다고 브라우저가 알려 줄 때만 닫힙니다. 터치로 길게 눌러 연 카드를 바깥 누르기나 `Escape`로 닫는 처리는 따로 없습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름과 파라미터 이름, 대기 시간의 기본값은 같습니다. 다음은 다르게 동작하는 자리입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯과 콜백의 타입 | `Widget`, `VoidCallback` | `Component`, `CoreVoidCallback` |
| 추가 파라미터 | 없습니다 | `id` · `classes` · `css` · `attributes` · 이벤트 처리기 — 트리거나 카드가 아니라 컴포넌트의 바깥 상자에 붙습니다 |
| 호버 감지 | `MouseRegion` | `mouseenter` · `mouseleave` 이벤트 |
| 길게 누르기 | `GestureDetector`의 길게 누르기. `openDelay`를 쓰지 않습니다 | `pointerdown`에서 `openDelay`를 재고 `pointerup` · `pointercancel`에서 그 대기를 취소합니다. 포인터를 올려 시작한 대기는 취소하지 않습니다 |
| 카드 밖 누르기 | 닫습니다(`onClose`는 부르지 않음). 트리거를 눌러 닫은 뒤에는 포인터를 벗어났다 다시 올려야 열립니다 | 닫지 않습니다 |
| 마우스를 누른 채 트리거 밖으로 나가 뗄 때 | — | 누른 지 `openDelay`가 지나면 카드가 열려 그대로 남을 수 있습니다 |
| 닫히는 중에 트리거로 돌아올 때 | `openDelay` 뒤에 다시 엽니다 | 그대로 닫히고 다시 열리지 않습니다. 벗어났다가 다시 올려야 합니다. `closeDelay`가 `transitionDuration`보다 짧으면, 닫히는 중에 트리거를 다시 벗어날 때 `onClose`를 한 번 더 부를 수 있습니다 |
| 열린 동안 `content` 바꾸기 | 열린 카드는 따라가지 않을 수 있습니다. 다음에 열 때 반영됩니다 | 열린 카드의 내용이 바로 따라갑니다 |
| `Start` · `End` 배치 | 가운데에 맞춥니다 | 트리거의 끝에 맞춥니다 |
| 화면 가장자리 | 고른 쪽에서 넘치면 반대쪽으로 넘기고, 남은 넘침은 가로 · 세로 모두 밀어 넣습니다 | 반대쪽에서 덜 넘칠 때만 넘기고, 놓는 쪽과 직각 방향으로만 밀어 넣습니다 |
| 열린 동안 스크롤 | 처음 연 자리에 남습니다 | 트리거를 따라갑니다. 예외는 아래 '다른 떠 있는 패널' 행을 보세요 |
| 전환 시간 | 열기 150ms, 닫기 100ms. `transitionDuration`은 반영되지 않습니다 | 열기와 닫기 모두 `transitionDuration`(기본 200ms) |
| 크기가 바뀌는 기준점 | 카드에서 트리거 쪽 변의 가운데 | 카드의 가운데 |
| 동작 줄이기 | 킷의 처리가 닿지 않습니다. Android의 애니메이션 삭제처럼 `disableAnimations`를 켜면 Flutter가 거의 한 프레임으로 줄일 수 있고, iOS의 '동작 줄이기'에서는 그대로 움직일 수 있습니다 | 500ms 이하의 전환 시간(기본값 포함)이 0이 됩니다 |
| 카드의 폭 | 내용의 폭을 미리 재어 정합니다. 크기를 잴 수 없는 위젯은 오류가 날 수 있습니다 | CSS가 정합니다 |
| 테마 배율(`scaling`) | 카드의 안쪽 여백 · 폭 상한 · 트리거와의 거리에 곱합니다. 화면 가장자리에서 띄우는 8에는 곱하지 않습니다 | 곱하지 않습니다 |
| 마운트 | 루트 `Overlay` — 트리거 조상의 클립에 잘리지 않습니다 | 오버레이 호스트의 팝오버 층 + top layer — 조상의 `overflow` · `transform`에 잘리지 않습니다. 호스트(`CoUIWeb` · `OverlayHost`)가 없으면 트리거 옆의 DOM에 그립니다 |
| 다른 떠 있는 패널 | — | 카드가 열리면 그때 열려 있던 `DropdownMenu` · `ContextMenu`가 닫힐 수 있습니다. 반대로 카드가 열린 뒤에 다른 떠 있는 패널(`Tooltip` · `Popover` 등)이 열리면, 카드는 열린 채 남지만 스크롤을 따라가지 않을 수 있습니다 |
| ARIA / Semantics | `Semantics`의 펼쳐짐 값 | `aria-haspopup` · `aria-expanded`, 카드의 `role="dialog"` |

<a id="props-parameters"></a>

## API

`HoverCard`는 두 플랫폼이 같은 파라미터를 씁니다. Web의 슬롯 타입은 `Component`이고 `onClose`의 타입은 `CoreVoidCallback?`입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `trigger` | `Widget` | 필수 | 카드를 여는 위젯 |
| `content` | `Widget` | 필수 | 카드 안에 보여 줄 위젯 |
| `placement` | `CorePopoverPlacement` | `CorePopoverPlacement.bottom` | 카드가 놓일 쪽 |
| `openDelay` | `Duration?` | `null` | 포인터를 올린 뒤 열기까지의 시간. `null`이면 `hoverCardStyle`, 테마, 500ms 순서로 정합니다 |
| `closeDelay` | `Duration?` | `null` | 포인터가 벗어난 뒤 닫기까지의 시간. `openDelay`와 같은 순서로 정합니다 |
| `onClose` | `VoidCallback?` | `null` | 카드가 닫히기 시작할 때. Flutter는 포인터가 벗어나 닫힐 때만 부릅니다 |
| `hoverCardStyle` | `CoreHoverCardStyle?` | `null` | 카드의 모양 · 거리 · 대기 시간 · 전환 덮어쓰기 |

두 플랫폼 모두 `copyWith`와 `withStyle(CoreHoverCardStyle patch)`가 있습니다. Web은 여기에 `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 처리기를 더 받고, 모두 컴포넌트의 바깥 상자에 붙습니다.

### 테마 — `CoreHoverCardTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreHoverCardStyle?` | `null` | 앱의 모든 `HoverCard`에 깔리는 값. variant가 없어 variant별 값은 없습니다 |

`CoreComponentTheme(hoverCard: …)`에 넣습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreHoverCardStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelStyle` | `CorePopupStyle?` | Look of the hover card panel, which is a `Popup` — fill, border, corners, shadow, padding, width limits, content colour. Passed to the `Popup` as is. `null` → [defaultPanelStyle] (which itself leaves most fields to `CorePopupStyle`'s defaults). |
| `placementOffset` | `double?` | Placement-axis offset between the trigger edge and the floating panel override — projected onto the placement axis (top/bottom or left/right). The native overlay positioning value (not a child-gap slot). |
| `openDelay` | `Duration?` | Delay before showing the hover card after pointer enter. |
| `closeDelay` | `Duration?` | Delay before hiding the hover card after pointer exit. |
| `transitionDuration` | `Duration?` | Panel enter/exit transition duration override. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `panelStyle` 설명과 달리, 준 값은 `HoverCard`의 기본값(최소 폭 0 · 최대 폭 256) 위에 필드마다 덮여 `Popup`에 넘어갑니다. 다른 필드만 적으면 폭의 두 값은 그대로이고, 폭을 바꾸려면 `minWidth` · `maxWidth`를 적습니다. 표의 `transitionDuration`은 Web에서만 반영됩니다. Flutter의 카드는 150ms로 열리고 100ms로 닫힙니다. `openDelay` · `closeDelay`는 같은 이름의 위젯 파라미터를 주면 그 값이 이깁니다. `placementOffset`은 Flutter에서 테마 배율을 곱한 값으로 쓰입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Popover" href="/components/popover" more="Popover 보기">

눌러서 열고 안에서 조작하는, 트리거에 붙는 패널입니다.

</Card>
<Card title="Tooltip" href="/components/tooltip" more="Tooltip 보기">

포인터를 올리면 뜨는 짧은 안내입니다.

</Card>
<Card title="Popup" href="/components/popup" more="Popup 보기">

`HoverCard`의 카드를 그리는 떠 있는 판입니다.

</Card>
</Cards>
