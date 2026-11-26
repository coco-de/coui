---
title: Popover
description: 팝오버 컴포넌트
category: overlay
platforms: [flutter, web]
related: [tooltip, dialog, menu]
tags: [floating, interactive, positioning]
template: v2
source: overlay/popover
---

# Popover

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 패널이 놓이는 자리를 확인하고, 그림 아래의 트리거로 같은 속성의 `Popover`를 실제로 열어 보세요. 만들어진 코드는 그대로 복사할 수 있습니다.

<Playground component="popover" />

Popover는 트리거 하나와, 그 옆에 뜨는 패널 하나로 이루어집니다. 패널의 상자는 [Popup](/components/popup)이고, 그 안에는 `content`에 넣은 위젯이 그대로 그려집니다. 앱 루트 아래에서 패널은 화면 위의 층에 그려지므로 부모의 `overflow`나 클리핑에 잘리지 않습니다.

<Note>

무대의 위쪽 그림은 실제 `Popup`에 `Popover`의 패널 기본값을 넘겨 트리거 옆에 놓은 그림입니다. 앱 테마의 색 · 글자 · 밀도와 `Popup` 테마, 서페이스 스타일의 재질은 이 그림에도 닿지만, `CorePopoverTheme`의 값, 화면 가장자리에서의 뒤집기 · 밀기, 열고 닫는 전환은 없습니다. 그 아래의 트리거는 실제 `Popover`입니다. 이 페이지에서 눌러서 열 수 있는 것은 플레이그라운드뿐이고, 다른 미리보기는 같은 방식의 그림입니다. `openTrigger`의 `focus`는 Web에서 동작하지 않을 수 있어 선택지에 없습니다. 플레이그라운드의 패널은 아래 코드처럼 본문 한 줄만 담습니다. `hover`를 고르면 `modal`은 적용하지 않습니다. Web에서는 배경막이 트리거를 덮어 패널이 바로 닫힐 수 있기 때문입니다.

</Note>

## 구조

<Anatomy demo="popover/anatomy">
<AnatomyItem select="[data-docs-part=trigger]" side="left" name="trigger">

`trigger`에 넣은 위젯이 그대로 놓입니다. 패널은 이 위젯을 감싼 자리를 기준으로 놓입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=panel]" side="left" name="panel">

패널의 상자(`Popup`)입니다. 배경은 `surfaceBright`, 테두리는 1px `outlineVariant`, 모서리는 12, 그림자는 `lg` 단계, 안쪽 여백은 16, 최소 폭은 0, 글자색은 `onSurface`입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="content">

`content`에 넣은 위젯입니다. 패널은 글자색만 정합니다. 글자의 크기와 굵기는 Flutter에서는 트리거가 놓인 자리의 것을 이어받고, Web에서는 패널이 올라가는 오버레이 호스트 자리의 것을 따릅니다. 두 곳에서 같게 보이려면 `content`의 글자에 `.bodyMedium` 같은 글자 역할을 직접 줍니다.

</AnatomyItem>
</Anatomy>

트리거와 패널 사이는 4(`placementOffset`)입니다. 패널의 폭은 기본적으로 내용의 폭을 따릅니다.

<a id="동작-스펙-behavior"></a>

## 상태

Popover에는 `open` 파라미터가 없습니다. 열림과 닫힘은 Popover가 스스로 갖고, 밖에서는 `controller`로 바꿉니다. 고르는 값 같은 상태는 갖지 않습니다.

### 여는 방법

`openTrigger`(`CorePopoverTrigger`)가 트리거의 어떤 조작이 패널을 여는지 정합니다.

| 값 | 열리고 닫히는 때 |
| --- | --- |
| `click` (기본) | 트리거를 누르면 열리고, 다시 누르면 닫힙니다. |
| `hover` | 포인터가 트리거에 올라오면 열리고, 벗어나면 바로 닫힙니다. 포인터를 패널로 옮기는 순간에도 닫히므로 패널 안의 버튼이나 링크는 누를 수 없습니다. |
| `focus` | Flutter는 트리거(와 그 안의 위젯)가 포커스를 받으면 열고 잃으면 닫습니다. 포커스를 패널 안으로 옮겨도 닫힙니다. Web은 열리지 않을 수 있습니다([알려진 제약](#알려진-제약)). |
| `manual` | 트리거를 눌러도 아무 일이 없습니다. 여는 것은 `PopoverController`만 합니다. 바깥 누르기 · `Escape` 같은 [닫는 방법](#닫는-방법)은 그대로 적용됩니다. |

<Note>

`Button`을 트리거로 쓸 때는 `onPressed`를 꼭 줍니다. 없으면 버튼이 비활성으로 그려지고, Web의 비활성 버튼은 클릭 이벤트를 내지 않아 `click` 패널이 열리지 않을 수 있습니다. `click` · `hover`에는 `() {}`처럼 빈 함수를, `manual`에는 `controller.toggle`을 줍니다.

</Note>

<a id="명시적-controller-제어"></a>

### 컨트롤러로 여닫기

트리거 밖에서 패널을 여닫거나, 키보드로도 열리는 트리거가 필요하면 `PopoverController`를 줍니다. `openTrigger: CorePopoverTrigger.manual`과 `Button(onPressed: controller.toggle)`을 함께 쓰면 두 플랫폼 모두 Enter · Space로 열 수 있습니다.

```dart
// State 의 필드로 한 번 만들고, State.dispose 에서 controller.dispose() 를 부릅니다.
final controller = PopoverController();

Popover(
  controller: controller,
  openTrigger: CorePopoverTrigger.manual,
  trigger: Button(
    variant: CoreButtonVariant.outline,
    onPressed: controller.toggle,
    child: Text('팝오버 열기'),
  ),
  content: Button(
    variant: CoreButtonVariant.ghost,
    onPressed: controller.close,
    child: Text('닫기'),
  ),
)
```

| 하는 일 | 멤버 | 설명 |
| --- | --- | --- |
| 열기 | `show()` | 이미 열려 있으면 아무것도 하지 않습니다. |
| 닫기 | `close()` | 닫혀 있으면 아무것도 하지 않습니다. |
| 번갈아 여닫기 | `toggle()` | 열려 있으면 닫고, 닫혀 있으면 엽니다. |
| 열림 확인 | `isOpen` | 지금 열려 있는지 알려 줍니다. |
| 변화 받기 | `addListener` · `removeListener` | 열리거나 닫힐 때마다 부릅니다. |
| 정리 | `dispose()` | controller를 만든 쪽이 부릅니다. |

- 두 플랫폼의 멤버 이름은 같지만 클래스는 플랫폼마다 따로 있어, 인스턴스를 플랫폼 사이에 공유하지 않습니다.
- controller 하나는 `Popover` 하나에 붙입니다. 여러 곳에 붙이면 마지막에 붙은 하나만 움직입니다.
- 패널 안에서 닫을 때는 `controller.close()`를 부릅니다. Flutter는 `content` 안에서 `closeOverlay(context)`로도 닫을 수 있습니다.

### 닫는 방법

| 방법 | 조건 |
| --- | --- |
| 바깥 누르기 | `dismissOnOutsideTap: true`(기본). Flutter는 `false`여도 닫힐 수 있습니다([알려진 제약](#알려진-제약)). `modal: false`면 누른 바깥 요소도 그 누름을 받습니다. |
| 트리거 다시 누르기 | `openTrigger: click`. Web의 `modal` 패널은 배경막이 트리거를 덮으므로, 다시 누르면 바깥 누르기로 처리됩니다(`dismissOnOutsideTap: false`면 닫히지 않습니다). |
| `Escape` | Web은 `dismissOnEscape: true`(기본). Flutter는 `modal`과 `dismissOnOutsideTap`이 모두 `true`일 때입니다. |
| 스크롤 | `closeOnScroll: true` |
| controller | `close()` · `toggle()` |
| `Popover`가 트리에서 빠질 때 | 전환 없이 바로 사라지고 `onClose`는 불리지 않습니다. |

`onClose`는 닫기가 **시작될 때** 불립니다. 닫히는 전환이 끝나기를 기다리지 않습니다.

`closeOnScroll`의 기본은 `false`라, 마우스 휠이나 트랙패드로 스크롤하면 패널은 열린 채 트리거를 따라갑니다. 다만 Flutter의 `modal: false` 패널은 바깥에 포인터가 닿는 순간 닫히므로, 터치로 바깥을 끌어 스크롤해도 닫힐 수 있습니다. Web은 바깥 누르기를 클릭으로만 받으므로, 터치로 바깥을 끌어 스크롤해도 닫히지 않습니다. `true`면 트리거를 담은 스크롤 영역이 움직일 때 닫습니다 — Web은 문서 · 화면의 스크롤도 포함합니다. 패널 안이나 상관없는 스크롤 영역의 스크롤은 닫지 않고, 열려 있는 동안 값을 바꿔도 새 값이 적용됩니다. [Select](/components/select)는 이 값을 `true`로 넘기므로 두 컴포넌트의 기본 동작이 다릅니다.

### 모달

`modal: true`면 패널 뒤에 투명한 배경막을 깝니다. 화면은 어두워지지 않습니다. Web은 배경막이 클릭을 받고, 오버레이 호스트가 앱 콘텐츠에 `inert`를 겁니다. Flutter는 뒤 화면을 접근성 트리에서 빼고 포커스를 패널 안으로 옮깁니다. 다만 Flutter의 배경막은 뒤 화면의 입력을 모두 막지는 않습니다([알려진 제약](#알려진-제약)). 확인을 꼭 받아야 하는 흐름에는 [Dialog](/components/dialog)를 씁니다.

### 열고 닫는 전환

- 여는 데 150ms, 닫는 데 100ms가 기본입니다(`openAnimationDuration` · `closeAnimationDuration`). 패널은 0.9배에서 1배로 커지며 나타나고, 반대로 줄며 사라집니다.
- Flutter는 열 때 일정한 속도로, 닫을 때는 시간의 앞 3분의 2 안에 움직임을 끝냅니다. Web은 `CoreEasing.enter` · `CoreEasing.exit` 곡선을 씁니다.
- 동작 줄이기를 켜면 두 플랫폼 모두 전환 시간이 0이 됩니다. 500ms보다 긴 값을 직접 적으면 그대로 남습니다.
- 뒤를 흐리는 유리 스타일에서는 패널 전체에 불투명도를 걸지 않고 흐림 · 채도를 함께 줄여, 열고 닫는 동안에도 뒤가 흐립니다([유리 패널이 나타나고 사라질 때](/guides/surface-styles#유리-패널이-나타나고-사라질-때)). `liquidGlass` 스타일에서는 패널이 트리거에서 자라나듯 열립니다.

### 열린 동안 바꾸기

열려 있는 동안 `content`를 바꾸면 열린 패널이 따라갑니다. `placement`를 바꾼 값은 다음에 열 때 반영됩니다.

<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

트리거 바로 옆에서 설정 몇 가지를 바꾸거나, 짧은 값을 넣거나, 추가 정보와 행동을 보여 줄 때 씁니다. 기본값(`modal: false`)은 뒤 화면을 막지 않습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 행동 없이 짧은 도움말 한 줄 | [Tooltip](/components/tooltip) |
| 호버로 보고, 포인터를 패널로 옮겨 가야 하는 미리보기 | [HoverCard](/components/hover-card) |
| 정해진 선택지에서 값 고르기 | [Select](/components/select) |
| 명령 목록 | [DropdownMenu](/components/dropdown-menu) |
| 응답을 받아야 하는 확인 · 입력 | [Dialog](/components/dialog) |
| 화면 가장자리에서 여는 패널, 긴 폼 | [Drawer](/components/drawer) |
| 위치와 열림을 이미 직접 관리하는 패널의 겉모습만 | [Popup](/components/popup) |

<a id="do"></a>
<a id="dont"></a>

### 패널에 담는 것과 여는 방법

<Cards columns="2">
<Card demo="popover/do-focused" tone="do" eyebrow="이렇게 하세요" height="240">

한 가지 일에 필요한 짧은 내용과 행동만 담습니다.

</Card>
<Card demo="popover/dont-long-form" tone="dont" eyebrow="이렇게 하지 마세요" height="340">

긴 폼을 담지 않습니다. 바깥을 한 번 누르면 패널이 닫히고, 패널 안의 위젯만 갖고 있던 입력은 사라집니다. 긴 입력은 Dialog · Drawer · 별도 페이지에 둡니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="키보드로도 여는 트리거">

`manual`과 `controller.toggle`을 씁니다. `Button`의 `onPressed`는 Enter · Space로도 불립니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="기본 click에 키보드 기대하기">

Flutter의 기본 `click`은 포인터만 듣습니다. 포커스한 트리거에서 Enter · Space를 눌러도 열리지 않습니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="누를 것이 있으면 click · manual">

패널 안에 버튼이나 입력이 있으면 눌러서 여는 `click`이나 `manual`을 씁니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="hover 패널에 버튼 담기">

포인터가 트리거를 벗어나는 순간 닫혀, 패널 안의 버튼에 닿을 수 없습니다. 패널까지 포인터를 옮겨야 하면 HoverCard를 씁니다.

</Card>
</Cards>

## 배치

<a id="배치-옵션-12-direction-placement"></a>

### 열두 방향

`placement`(`CorePopoverPlacement`)는 열두 값입니다. 앞의 `top` · `bottom` · `left` · `right`가 패널이 놓일 쪽이고, 뒤의 `Start` · `End`가 트리거와 맞추는 자리입니다. 아무것도 붙지 않으면 가운데를 맞춥니다.

| 놓이는 쪽 | `Start` | `End` |
| --- | --- | --- |
| 위 · 아래 | 왼쪽 가장자리를 맞춤 | 오른쪽 가장자리를 맞춤 |
| 왼쪽 · 오른쪽 | 위 가장자리를 맞춤 | 아래 가장자리를 맞춤 |

기준은 화면의 왼쪽 · 오른쪽이라, 오른쪽에서 왼쪽으로 읽는 언어에서도 뒤집히지 않습니다. Web의 패널은 실제로 놓인 쪽을 `data-placement` 속성에 적습니다.

<Cards columns="3">
<Card component="popover" props="placement=bottomStart" title="bottomStart">

트리거와 왼쪽 가장자리를 맞춥니다.

</Card>
<Card component="popover" props="placement=bottom" title="bottom (기본)">

트리거의 가운데에 맞춥니다.

</Card>
<Card component="popover" props="placement=bottomEnd" title="bottomEnd">

트리거와 오른쪽 가장자리를 맞춥니다.

</Card>
</Cards>

<Cards columns="2">
<Card component="popover" props="placement=rightStart" title="rightStart">

오른쪽에 놓고 위 가장자리를 맞춥니다.

</Card>
<Card component="popover" props="placement=left" title="left">

왼쪽에 놓고 가운데에 맞춥니다.

</Card>
</Cards>

### 충돌 정책

패널이 화면을 넘을 때의 처리는 `collision`(`Set<CorePopoverCollision>`)이 정합니다. 적지 않으면 `CorePopoverStyle.defaultCollision` — `flip`과 `shift`입니다.

```dart
// 기본값 — 반대쪽으로 뒤집고(flip), 화면 안으로 밉니다(shift)
collision: const {CorePopoverCollision.flip, CorePopoverCollision.shift},

// 뒤집기만 고르기 — Flutter 는 그래도 화면 안으로 밉니다
collision: const {CorePopoverCollision.flip},

// 아무 처리도 고르지 않기 — Flutter 는 그래도 화면 안으로 밉니다
collision: const {CorePopoverCollision.none},
```

두 플랫폼의 처리 방식은 다릅니다.

| 값 | Flutter | Jaspr Web |
| --- | --- | --- |
| `flip` | 패널이 넘치면 넘친 축을 뒤집습니다. 반대쪽에 자리가 더 있는지는 보지 않고, 위 · 아래 배치에서 좌우가 넘치면 `Start` ↔ `End`도 바꿉니다. | 놓인 쪽(위 ↔ 아래, 왼쪽 ↔ 오른쪽)이 넘치고 반대쪽이 덜 넘칠 때만 뒤집습니다. |
| `shift` | 값에 없어도 늘 패널을 화면 안으로 밉니다. | 값에 있을 때만, 놓인 쪽과 직각인 방향으로 밉니다. |
| `clip` · `none` | 따로 하는 일이 없습니다. `flip`이 없으면 뒤집지 않고, 밀기는 남습니다. | 따로 하는 일이 없습니다. `flip` · `shift`가 없으면 고른 자리에 그대로 둡니다. |

### 화면 가장자리와 긴 내용

- 뒤집기와 밀기는 화면 가장자리에서 8 안쪽을 기준으로 합니다. 이 거리는 `popoverStyle`의 `viewportPadding`으로 바꾸고, 밀도를 바꾸면 함께 움직입니다.
- 위에 고정된 헤더 자리를 비우려면 `CoreEdgeInsets.only(top: 64, left: 8, right: 8, bottom: 8)`처럼 네 변을 모두 적습니다. `only`에서 적지 않은 변은 0이 됩니다.
- 화면 키보드가 올라오면 Flutter는 키보드가 가린 만큼을 여백에 더해 패널을 키보드 위에 둡니다. Web은 키보드 높이를 따로 읽지 않습니다.
- 패널은 긴 내용을 스스로 스크롤하지 않습니다. 화면보다 긴 내용은 넘치거나 잘릴 수 있으니, 내용이 길어질 수 있으면 `content` 안에 최대 높이를 가진 스크롤 영역을 둡니다.

<a id="constraint-anchor-relative-사이징"></a>

### 폭과 높이 맞추기

`widthConstraint`와 `heightConstraint`(`CorePopoverConstraint`)는 패널의 폭 · 높이를 트리거의 크기에 맞춥니다. 아래 그림은 폭이 200인 트리거에 짧은 문장(위)과 긴 문장(아래)을 네 가지 폭 제약으로 담은 것입니다.

<Preview demo="popover/constraints" height="hug" />

| 값 | 패널의 크기 |
| --- | --- |
| `flexible` (적지 않았을 때) | 트리거와 상관없이 내용을 따릅니다. |
| `anchorFixedSize` | 트리거와 같습니다. `Select`의 목록 폭이 기본으로 쓰는 값입니다. |
| `anchorMaxSize` | 트리거보다 커지지 않습니다. |
| `anchorMinSize` | 트리거보다 작아지지 않습니다. Flutter에서는 내용이 아주 길면 화면보다 커질 수 있습니다. |
| `intrinsic` | 트리거와 상관없이 내용을 따릅니다. 보통은 `flexible`과 같게 보이지만, Flutter에서는 내용이 아주 길면 화면보다 커질 수 있습니다. |

Web에서는 `heightConstraint`가 보이는 패널 상자의 높이를 바꾸지 않을 수 있습니다. 값이 패널을 감싸 자리를 잡는 상자에만 적용되기 때문이고, 배치에 따라 패널의 자리가 어긋날 수도 있습니다. 두 플랫폼에서 같게 보여야 하면 폭 제약만 씁니다.

### 트리거의 폭

트리거를 감싼 상자의 폭은 `popoverStyle`의 `triggerSizing`(`CorePopoverTriggerSizing`)이 정합니다. 위의 폭 제약도 이 상자의 폭을 기준으로 합니다.

- `intrinsic`(기본)은 트리거의 폭을 따릅니다. 아이콘 버튼이나 색 견본처럼 작은 트리거에 맞습니다. Flutter는 이때 트리거의 폭을 먼저 물으므로, `LayoutBuilder`처럼 그 질문에 답하지 못하는 위젯을 트리거에 넣으면 `expand`를 씁니다.
- `expand`는 부모의 폭을 채웁니다. 입력 모양의 트리거에 맞고, `Select` · `Autocomplete` · `DatePicker` · `TimePicker` · `PhoneInput`이 이 값을 씁니다. Flutter에서 `Row`처럼 폭이 정해지지 않은 부모 안에서는 트리거의 폭이 됩니다.

### 트리거와의 간격

트리거와 패널 사이는 `placementOffset`(기본 `CorePopoverStyle.defaultPlacementOffset`, 4)입니다. `DatePicker` · `TimePicker` · `ColorPicker` · `PhoneInput`은 기본이 같은 4이고, `Select` · `Autocomplete`는 4를 스스로 적습니다. `Fab`의 메뉴는 `Fab`의 `spacing`(기본 16)을 이 간격으로 넘깁니다.

### 접히는 화면

접힘선이 화면을 나누면 패널이 머무는 범위는 화면 전체가 아니라 **트리거의 가운데가 놓인 조각**입니다. 뒤집기와 밀기가 그 조각 안에서 일어나므로, 접힘선 옆의 트리거에서 연 패널도 접힘선을 넘지 않습니다. Popover를 안에 쓰는 컴포넌트와 메뉴 · Tooltip · HoverCard도 같이 따릅니다. 화면이 언제 나뉘는지는 [접히는 화면](/guides/layout#접히는-화면)을 보세요.

<a id="스타일-시스템-popoverstyle"></a>
<a id="스타일-시스템-style-system"></a>
<a id="popoverstyle-슬롯"></a>

## 테마와 스타일

패널의 겉모습, 트리거와의 간격, 화면 가장자리 여백, 트리거의 폭, 전환 시간은 `popoverStyle`(`CorePopoverStyle`) 하나로 바꿉니다. 어디에 놓고 언제 여닫는지(`placement` · `openTrigger` · `modal` · `dismiss…` · `collision` · `…Constraint`)는 위젯 파라미터로 줍니다. 패널의 겉모습은 `panelStyle`(`CorePopupStyle`)에 `Popup`의 스타일 그대로 적습니다. 두 플랫폼이 같은 코드를 씁니다.

<a id="테마-커스터마이징"></a>
<a id="테마-커스터마이징-theme-customization"></a>

<Split>

<Code language="dart" title="Popover 하나만 바꾸기">
Popover(
  trigger: Button(
    variant: CoreButtonVariant.outline,
    onPressed: () {},
    child: Text('열기'),
  ),
  content: Text('내용'),
  popoverStyle: CorePopoverStyle(
    placementOffset: CoreSpace.space8,
    panelStyle: CorePopupStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space20),
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
    popover: CorePopoverTheme(
      style: CorePopoverStyle(
        placementOffset: CoreSpace.space8,
        panelStyle: CorePopupStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space12),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

<a id="aschild-패턴-trigger-variant-변경"></a>

### 트리거의 종류 바꾸기

트리거의 종류와 모양은 `trigger`에 넣는 위젯이 정합니다. `Popover(trigger: Button(variant: CoreButtonVariant.outline, …))`처럼 원하는 버튼을 그대로 넣습니다. `popoverStyle.triggerStyle`은 `Popover`가 트리거에 입히지 않으므로, 트리거의 여백이나 글자는 그 `Button`의 `buttonStyle`로 바꿉니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CorePopupStyle 기본값             // 패널 상자(Popup)의 디자인 시스템 값
  → CorePopupTheme.style          // 앱의 모든 Popup
  → CorePopoverStyle 기본값       // 패널의 안쪽 여백 16 · 최소 폭 0, 간격 4 …
  → CorePopoverTheme.style        // 앱의 모든 Popover
  → popoverStyle                  // Popover 하나
```

뒤로 갈수록 우선하고, 필드마다 따로 합쳐집니다. `panelStyle`도 안의 필드끼리 합쳐집니다. 패널의 안쪽 여백과 최소 폭은 `Popover`의 기본값이 `Popup` 테마보다 뒤에 있으므로, 앱 전체에서 바꾸려면 `CorePopoverTheme`에 적습니다. `Select`처럼 Popover를 안에 쓰는 컴포넌트는 자기 스타일에 든 Popover 값을 `popoverStyle` 자리로 넘깁니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Popover` 인스턴스에 스타일을 덧붙일 때는 `withStyle`을 이어 씁니다. 생성자의 `popoverStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class PopoverChainExample extends StatefulWidget {
  const PopoverChainExample({super.key});

  @override
  State<PopoverChainExample> createState() => _PopoverChainExampleState();
}

class _PopoverChainExampleState extends State<PopoverChainExample> {
  final _controller = PopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Popover(
      controller: _controller,
      openTrigger: CorePopoverTrigger.manual,
      trigger: Button(
        onPressed: _controller.toggle,
        variant: CoreButtonVariant.outline,
        child: Text('팝오버 열기').labelLarge,
      ),
      content: Text('팝오버 내용이에요.').bodyMedium,
    ).withStyle(
      const CorePopoverStyle(
        placementOffset: CoreSpace.space24,
        openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
        panelStyle: CorePopupStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space20),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          borderWidth: CoreStrokeWidth.stroke2,
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class PopoverChainExample extends StatefulComponent {
  const PopoverChainExample({super.key});

  @override
  State<PopoverChainExample> createState() => _PopoverChainExampleState();
}

class _PopoverChainExampleState extends State<PopoverChainExample> {
  final _controller = PopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Popover(
      controller: _controller,
      openTrigger: CorePopoverTrigger.manual,
      trigger: Button(
        onPressed: _controller.toggle,
        variant: CoreButtonVariant.outline,
        child: Text('팝오버 열기').labelLarge,
      ),
      content: Text('팝오버 내용이에요.').bodyMedium,
    ).withStyle(
      const CorePopoverStyle(
        placementOffset: CoreSpace.space24,
        openAnimationDuration: Duration(milliseconds: CoreDuration.moderate),
        panelStyle: CorePopupStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space20),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
          borderWidth: CoreStrokeWidth.stroke2,
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

Web은 트리거와 패널에 팝업 대화상자의 ARIA를 붙이고, Flutter는 트리거의 펼침 상태만 알립니다. 두 플랫폼 모두 패널에 이름을 주지 않습니다.

### 역할

| 자리 | Flutter | Jaspr Web |
| --- | --- | --- |
| 트리거 | `Semantics(container: true, expanded: …)` — 열림 상태만 있고 역할과 팝업 힌트는 없습니다. | 트리거를 감싼 `<div>`에 `aria-haspopup="dialog"`와 `aria-expanded`, 열린 동안에만 `aria-controls`(패널의 id) |
| 패널 | `Popup`의 `Semantics(container: true)` — dialog 역할이 없습니다. | `role="dialog"`와 놓인 쪽을 적은 `data-placement` |
| `modal` 배경 | 배경막이 뒤 화면을 접근성 트리에서 뺍니다. | 오버레이 호스트가 앱 콘텐츠에 `inert`를 걸고, 배경막은 `aria-hidden="true"`입니다. |

트리거와 패널에는 `aria-modal` · `aria-label` · `aria-labelledby` · `aria-describedby`를 붙이지 않습니다. `modal`이면서 `dismissOnOutsideTap: true`인 Web 패널 곁의 [보이지 않는 닫기 버튼](#스크린-리더)만 닫기 문구를 `aria-label`로 갖습니다. Flutter의 패널에도 이름이 없습니다. Web은 패널이 열려 있을 때만 `aria-controls`를 적어, 문서에 없는 id를 가리키지 않습니다. Flutter의 트리거 상태는 controller · 바깥 누름 · `Escape` 어느 쪽으로 여닫아도 따라옵니다.

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Enter` · `Space` (`manual` + `controller.toggle` 버튼) | 여닫습니다. | 여닫습니다. |
| `Enter` · `Space` (`click` 트리거) | 열리지 않습니다. | 안쪽 버튼의 클릭으로 여닫힙니다. |
| `Escape` | `modal: true`이고 `dismissOnOutsideTap: true`일 때만 닫습니다. | `dismissOnEscape: true`(기본)면 포커스가 어디 있든 닫습니다. |

패널 안의 화살표 · `Home` · `End` 이동은 두 플랫폼 모두 처리하지 않습니다. `hover`는 키보드로 열리지 않습니다.

### 스크린 리더

- **Web** — 트리거의 팝업 · 펼침 속성은 감싼 `<div>`에 있어, 안쪽 버튼에 포커스한 스크린 리더는 읽지 않을 수 있습니다. 패널에는 `role="dialog"`가 있지만 이름이 없고, 이름을 줄 방법도 없습니다. `content` 맨 위에 제목 글자를 두면 안을 읽을 때 무엇인지 알 수 있지만, 대화상자의 이름이 되지는 않습니다. 이름이 꼭 필요하면 [Dialog](/components/dialog)를 씁니다.
- **Web, `modal`** — 오버레이 호스트 아래에서는 앱 콘텐츠가 `inert`가 됩니다. `dismissOnOutsideTap: true`까지면 화면에 보이지 않는 `role="button"` 노드가 로케일의 닫기 문구(한국어 "닫기")를 이름으로 갖고, 활성화하면 닫힙니다. 이 노드는 탭 순서에 들지 않습니다.
- **Flutter** — 트리거는 펼침 · 접힘만 읽히고, 패널은 이름과 역할이 없는 묶음입니다.
- **Flutter, `modal`** — 뒤 화면이 접근성 트리에서 빠집니다. `dismissOnOutsideTap: true`까지면 패널이 닫기 동작(로케일의 닫기 문구)을 내어, 스크린 리더의 닫기 제스처나 그 항목의 활성화로 닫힙니다. 이 이름은 닫기 동작의 이름이지 패널의 이름이 아닙니다.
- **`modal: false`(기본)** — 두 플랫폼 모두 뒤 화면이 그대로 읽히고, 스크린 리더용 닫기 동작(Flutter)이나 보이지 않는 닫기 버튼(Web)이 없습니다. Web은 오버레이 호스트가 없는 곳에서도 뒤 화면이 그대로 읽힙니다.
- 열림과 닫힘은 따로 알리지 않습니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 (`modal: true`) | 패널의 포커스 범위로 포커스를 옮깁니다. | 포커스를 옮기지 않습니다. |
| 열 때 (`modal: false`) | 포커스를 옮기지 않습니다. | 포커스를 옮기지 않습니다. |
| 가두기 (`modal: true`) | `Tab`이 패널의 포커스 범위 안에서 돕니다. | 오버레이 호스트의 `inert`로 배경이 탭 순서에서 빠집니다. 패널 안에서 순환시키지는 않습니다. |
| 닫을 때 | 포커스가 패널 안에 있었다면 직전에 포커스가 있던 곳(키보드로 트리거 버튼에서 `modal` 패널을 열었다면 그 버튼)으로 돌아갑니다. 트리거를 골라 옮기는 동작은 따로 없습니다. | 트리거로 포커스를 되돌리지 않습니다. |

Web에서 닫은 뒤 포커스를 트리거에 두어야 하면 앱이 옮깁니다. `modal: false`면 `onClose`에서 옮겨도 됩니다. `modal: true`면 `onClose`가 불릴 때 앱 콘텐츠가 아직 `inert`라 그 자리에서는 옮길 수 없으므로, 닫는 시간(`closeAnimationDuration`, 기본 100ms)이 지나 패널이 사라진 뒤에 옮깁니다. `CoUIWeb` · `OverlayHost` 밖에서는 `inert`가 걸리지 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | `dismissOnOutsideTap: false`여도 바깥을 누르면 닫힐 수 있습니다. 특히 `modal: true`와 함께 쓰면 누르는 순간 닫히고, 같은 누름이 뒤 화면의 버튼에도 전해질 수 있습니다. |
| Flutter | `dismissOnEscape`는 `Escape`를 켜지도 끄지도 않습니다. `Escape`로 닫히는지는 `modal`과 `dismissOnOutsideTap`이 정합니다. |
| Flutter | 기본 `click` 트리거는 키보드로 열 수 없습니다. `manual`과 `controller.toggle`을 씁니다. |
| Flutter | `modal: false` 패널은 포커스를 받지 않아, 트리거에서 `Tab`으로 패널 안에 들어가지 못할 수 있습니다. |
| Flutter | `modal: true`여도 배경의 스크롤 · 마우스 올리기는 막지 못할 수 있습니다. |
| Flutter | `openTrigger: focus`에 `modal: true`를 함께 쓰면, 패널이 포커스를 가져가면서 닫혔다가 다시 열리기를 반복할 수 있습니다. |
| Flutter | 패널에 dialog 역할이, 트리거에 팝업 힌트가 없습니다. |
| Web | `openTrigger: focus`는 열리지 않을 수 있습니다. 포커스를 받지 않는 감싼 `<div>`에서 포커스를 기다리는데, 안쪽 버튼의 포커스 이벤트는 그곳까지 올라오지 않습니다. |
| Web | `openTrigger: hover`에 `modal: true`를 함께 쓰면, 배경막이 트리거를 덮어 패널이 열리자마자 닫히거나 깜빡일 수 있습니다. |
| Web | `heightConstraint`는 보이는 패널 상자의 높이를 바꾸지 않을 수 있고, 배치에 따라 패널의 자리가 어긋날 수 있습니다. |
| Web | 닫히는 전환(기본 100ms) 동안에는 다시 열리지 않을 수 있고, 그 사이 `click` 트리거를 다시 누르면 `onClose`가 한 번 더 불릴 수 있습니다. |
| Web | 열려 있는 Popover마다 `Escape`를 따로 들어, 한 번의 `Escape`로 `dismissOnEscape`가 켜진 Popover가 모두 닫힐 수 있습니다. |
| Web | 다른 패널(Popover · Tooltip · HoverCard · 메뉴 류)이 열리면, 먼저 열려 있던 Popover의 위치 추적이 멈출 수 있습니다. 그 패널은 스크롤을 따라가지 않고 `closeOnScroll`도 동작하지 않을 수 있습니다. |
| Web | 창 크기만 바뀌거나 스크롤 없이 트리거가 움직이면, 패널을 다시 놓지 않을 수 있습니다. |
| 공통 | 패널 안에서 `Select`처럼 자기 패널을 따로 띄우는 컴포넌트를 쓰면, 그 안쪽 패널을 누를 때 바깥 Popover가 닫힐 수 있습니다. |
| 공통 | 열린 `Popover`가 트리에서 빠지면 앱이 준 controller의 `isOpen`이 `true`로 남을 수 있습니다. 그 controller는 새 `Popover`에 붙여도 열지 못하니 새로 만듭니다. |
| 공통 | 패널에 접근 가능한 이름을 줄 파라미터가 없고, `aria-modal`을 설정하지 않습니다. 이름과 포커스 이동이 꼭 필요한 확인에는 [Dialog](/components/dialog)를 씁니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 등)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-패리티"></a>
<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같고, 그리는 방법과 이벤트는 각 플랫폼의 방식을 따릅니다. Web의 위젯 타입은 `Widget` 대신 `Component`입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 패널이 그려지는 곳 | 앱의 루트 오버레이 | `CoUIWeb` · `OverlayHost`의 팝오버 층에 올리고 브라우저의 top layer로 올립니다. 호스트가 없으면 트리거 옆에 화면 고정으로 그립니다. |
| 트리거 이벤트 | 트리거 위의 포인터를 직접 들어, 트리거가 버튼이어도 열립니다. `hover` · `focus`는 감싼 위젯이 듣습니다. | 감싼 `<div>`의 `click` · `mouseenter` · `mouseleave` · `focus` · `blur` |
| `focus` 트리거 | 포커스를 따라 여닫습니다. | 열리지 않을 수 있습니다. |
| 바깥 누르기 | 오버레이의 바깥 누름 감지(`modal`이면 배경막). `modal: false`면 누르는 순간 닫혀, 터치로 바깥을 끌어 스크롤해도 닫힐 수 있습니다. `dismissOnOutsideTap: false`여도 닫힐 수 있습니다. | 문서의 클릭 리스너(`modal`이면 배경막 클릭). 클릭할 때만 닫고, `dismissOnOutsideTap` 값을 따릅니다. |
| `Escape` | `modal` + `dismissOnOutsideTap` | `dismissOnEscape` |
| 충돌 처리 | 넘친 축을 뒤집고, 밀기는 늘 합니다. | 놓인 쪽만, 덜 넘칠 때 뒤집고, 밀기는 `collision`을 따릅니다. |
| 위치 갱신 | 매 프레임 트리거의 자리를 다시 잽니다. | 스크롤과 패널 크기 변화 때 다시 잽니다. |
| 크기 계산 | 패널은 내용의 폭을 먼저 묻습니다. `ListView` · `LayoutBuilder`처럼 답하지 못하는 위젯은 `SizedBox(width:)`로 폭을 정해 넣습니다. | 브라우저의 레이아웃 |
| `heightConstraint` | 패널의 높이에 적용합니다. | 보이는 패널 상자의 높이에는 닿지 않을 수 있습니다. |
| 패널의 글자 | 트리거가 놓인 자리의 글자 크기 · 굵기를 이어받습니다. | 패널이 올라가는 오버레이 호스트 자리의 글자를 따릅니다. |
| 화면 키보드 | 가려진 만큼을 가장자리 여백에 더합니다. | 따로 읽지 않습니다. |
| 전환 곡선 | 열 때 일정한 속도, 닫을 때 앞 3분의 2 | `CoreEasing.enter` · `CoreEasing.exit` |
| 닫히는 중 다시 열기 | 새 패널을 바로 엽니다. | 닫히는 전환이 끝나기 전에는 열리지 않을 수 있습니다. |
| 추가 속성 | 없습니다. | `id` · `classes` · `css` · `attributes`와 이벤트 처리기를 받아 트리거를 감싼 바깥 상자에 붙입니다. 패널에는 붙지 않습니다. |

<a id="props-parameters"></a>

## API

`Popover`는 두 플랫폼이 같은 파라미터를 씁니다. Web의 위젯 타입은 `Component`이고 `onClose`의 타입은 `CoreVoidCallback?`입니다. 추가 Web 속성은 [플랫폼 차이](#플랫폼-차이)를 보세요.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `trigger` | `Widget` | 필수 | 패널을 여는 트리거. 패널의 자리 기준입니다. |
| `content` | `Widget` | 필수 | 패널 안에 그릴 위젯 |
| `placement` | `CorePopoverPlacement` | `bottom` | 열두 방향 배치 |
| `controller` | `PopoverController?` | `null` | 밖에서 여닫고 열림을 읽습니다. |
| `openTrigger` | `CorePopoverTrigger` | `click` | `click` · `hover` · `focus` · `manual` |
| `modal` | `bool` | `false` | 투명한 배경막으로 뒤 화면을 막습니다. Flutter의 예외는 [알려진 제약](#알려진-제약)에 있습니다. |
| `dismissOnOutsideTap` | `bool` | `true` | 바깥을 누르면 닫습니다. Flutter는 `false`여도 닫힐 수 있습니다. |
| `dismissOnEscape` | `bool` | `true` | Web에서 `Escape`로 닫습니다. Flutter의 `Escape` 동작은 바꾸지 않습니다. |
| `closeOnScroll` | `bool` | `false` | 트리거를 담은 스크롤 영역이 움직이면 닫습니다. |
| `collision` | `Set<CorePopoverCollision>?` | `null` | 화면을 넘을 때의 처리. `null`이면 `flip`과 `shift` |
| `widthConstraint` | `CorePopoverConstraint?` | `null` | 패널 폭의 기준. `null`이면 `flexible` |
| `heightConstraint` | `CorePopoverConstraint?` | `null` | 패널 높이의 기준. `null`이면 `flexible`. Web의 예외는 [알려진 제약](#알려진-제약)에 있습니다. |
| `popoverStyle` | `CorePopoverStyle?` | `null` | 패널의 겉모습 · 간격 · 전환 시간 덮어쓰기 |
| `onClose` | `VoidCallback?` | `null` | 닫기가 시작될 때 부릅니다. |

두 플랫폼 모두 `withStyle(CorePopoverStyle patch)`로 `popoverStyle`에 값을 덧붙인 복사본을 만듭니다. controller의 멤버는 [컨트롤러로 여닫기](#컨트롤러로-여닫기)에 있습니다.

### 테마 — `CorePopoverTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CorePopoverStyle?` | `null` | 앱의 모든 Popover에 깔리는 값. Popover에는 variant가 없어 variant별 값은 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CorePopoverStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelStyle` | `CorePopupStyle?` | Look of the panel — background, border, radius, shadow, padding, min-width, content colour. The panel is a `Popup`, which gets this style as is. `null` → [defaultPanelStyle] (which itself defers most fields to `CorePopupStyle`'s defaults). |
| `placementOffset` | `double?` | Trigger-to-panel placement offset (logical px) — applied along the placement axis (top/bottom or left/right depending on `CorePopoverPlacement`) to push the floating panel away from the trigger edge. Maps to a Flutter `Offset` via `placement_ext.toPopoverOffset` and to the Web floating-controller placement-axis distance. |
| `viewportPadding` | `CoreEdgeInsets?` | Viewport-edge padding enforced when applying [CorePopoverCollision.shift] — the panel won't paint within this much of the visible viewport edge regardless of placement. Per CLAUDE.md rule 2 (multi-side padding/margin → [CoreEdgeInsets]), each side accepts its own value so popovers can avoid colliding with fixed headers, banners, or safe-area insets (e.g. `CoreEdgeInsets.only(top: 64)` reserves a 64-px sticky-header strip). `null` → token default ([defaultViewportPadding]). |
| `triggerSizing` | `CorePopoverTriggerSizing?` | How the trigger wrapper is sized: `intrinsic` (fits the trigger's content) or `expand` (fills the parent's width). |
| `openAnimationDuration` | `Duration?` | Open animation duration override. |
| `closeAnimationDuration` | `Duration?` | Close animation duration override. |
| `triggerStyle` | `CoreButtonStyle?` | Trigger button style override, as a `CoreButtonStyle`: change any part of the button's look — colours, size and spacing, the styles of its icons, label and focus ring — without touching the panel's look. |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 다른 지금 동작입니다.

- `triggerStyle`은 `Popover`가 트리거에 입히지 않습니다. 트리거의 겉모습은 `trigger`로 넣는 위젯에서 바꿉니다.
- `panelStyle` 안의 `openAnimationDuration` · `closeAnimationDuration`은 `Popover`가 읽지 않습니다. 전환 시간은 `popoverStyle`의 두 필드로 바꿉니다.
- `viewportPadding`은 `shift`뿐 아니라 뒤집을지 판단할 때도 씁니다. Flutter는 `collision`에 `shift`가 없어도 밀기를 합니다.

</Note>

<a id="레거시-vs-통일-비교-migration-notes"></a>

## 이전 방식에서 옮기기

Flutter의 `Popover` · `Tooltip` · `HoverCard` · 메뉴 류처럼 트리거에 붙어 뜨는 컴포넌트는 같은 위치 엔진 `PopoverOverlayHandler`를 씁니다. `ObjectFormField`의 팝업도 같습니다. 예전 CoUI의 명령형 API를 쓰던 코드는 다음처럼 옮깁니다.

| 예전 코드 | 지금 |
| --- | --- |
| `showPopover<T>(…)` | `const PopoverOverlayHandler().show<T>(…)` — `PopoverEntryHandle<T>`를 돌려줍니다. |
| `PopoverController().show(context: …, alignment: …, builder: …)` | 위젯이면 `Popover(controller: controller, …)`를 두고 `controller.show()`를 부릅니다. `show()`는 인자를 받지 않습니다. 위젯 없이 패널만 띄우면 `PopoverOverlayHandler`를 씁니다. |
| `CoUIApp`의 `popoverHandler` · `menuHandler` · `tooltipHandler` | 없습니다. |
| `PopoverConstraint` | `CorePopoverConstraint` |

## 관련 컴포넌트

<Cards columns="3">
<Card title="Popup" href="/components/popup" more="Popup 보기">

Popover 패널의 상자입니다. 위치와 열림을 직접 관리하는 패널에 씁니다.

</Card>
<Card title="Tooltip" href="/components/tooltip" more="Tooltip 보기">

트리거의 짧은 도움말입니다.

</Card>
<Card title="HoverCard" href="/components/hover-card" more="HoverCard 보기">

호버로 여는 정보 카드입니다. 포인터를 패널로 옮길 수 있습니다.

</Card>
<Card title="Dialog" href="/components/dialog" more="Dialog 보기">

응답을 받아야 할 때 쓰는 모달 패널입니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼에서 여는 명령 목록입니다.

</Card>
<Card title="Select" href="/components/select" more="Select 보기">

정해진 선택지 하나를 고르는 입력입니다.

</Card>
</Cards>
