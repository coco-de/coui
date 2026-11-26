---
title: Dialog
description: 확인, 입력, 알림처럼 사용자의 응답이 필요한 순간에 화면 위에 띄우는 모달 패널입니다. 응답하기 전까지 뒤의 화면은 막힙니다.
category: overlay
platforms: [flutter, web]
related: [drawer, toast, popover]
tags: [modal, confirmation, interactive]
template: v2
source: overlay/dialog
---

# Dialog

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꿔 보며 패널을 확인하고, **열어 보기**로 같은 속성의 대화상자를 실제로 열어 보세요. 만들어진 코드는 그대로 복사할 수 있습니다.

<Playground component="dialog" />

<Note>

무대의 패널은 페이지 안에 그린 그림입니다. 실제 `Dialog`는 열리면 화면 전체를 덮기 때문에 그 자리에 둘 수 없습니다. 이 페이지의 다른 미리보기도 같은 그림입니다. 웹 팬에서 연 대화상자는 페이지 전체를, Flutter 팬에서 연 대화상자는 그 팬 안을 덮고, 스크림 · `Escape` · 행동 버튼으로 닫습니다.

</Note>

<a id="구조-anatomy"></a>

## 구조

대화상자는 패널 하나와 다섯 개의 슬롯으로 이루어집니다. 슬롯은 모두 선택이며, 비어 있는 슬롯은 자리를 차지하지 않습니다.

<Anatomy demo="dialog/anatomy">
<AnatomyItem part="container" name="Container">

패널. 배경은 `surfaceBright`, 테두리는 1px `outlineSubtle`, 모서리는 20(모달 역할), 그림자는 `xl` 단계입니다. 안쪽 여백은 위와 양옆 24, 아래 20입니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

제목 앞의 아이콘 자리입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=title]" name="title">

제목. 대화상자의 이름이 되어 스크린 리더가 열릴 때 읽습니다. 기본 글자는 `titleLarge`입니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="trailing">

제목 뒤의 자리. 닫기 버튼을 둡니다. 닫기 버튼은 저절로 생기지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="left" name="content">

본문. 기본 글자는 `bodyMedium`, 색은 `onSurfaceVariant`입니다. 패널보다 길면 본문만 스크롤됩니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=actions]" side="left" name="actions">

아래 행동 줄. 넣은 순서대로 놓이고, 버튼의 종류는 넣는 `Button`이 정합니다.

</AnatomyItem>
</Anatomy>

머리 줄과 본문 사이는 14(`sectionGapStyle`, 머리 줄 안의 leading · title · trailing 사이도 같은 값), 본문과 행동 줄 사이는 20(`actionsGapStyle`), 행동 사이는 8(`actionSpacing`)입니다. 본문이 없으면 머리 줄과 행동 줄 사이가 20입니다.

<a id="변형-variants"></a>

## 구성

Dialog에는 variant가 없습니다. 어떤 대화상자가 될지는 슬롯에 무엇을 넣는지가 정합니다. 휴대폰 확인창처럼 행동이 줄을 채우는 배치는 [배치](#배치)의 모바일 확인창을 보세요.

### 알림 다이얼로그

<Preview demo="dialog/alert" />

확인 버튼 하나로 알리고 닫습니다.

```dart
Dialog(
  open: isAlertOpen,
  title: Text('저장하지 못했어요'),
  content: Text('네트워크 연결이 끊겼어요. 잠시 뒤 다시 시도해 주세요.'),
  actions: [
    Button(onPressed: close, child: Text('확인')),
  ],
  onClose: close,
)
```

### 아이콘 포함

<Preview demo="dialog/with-icon" />

`leading`에 아이콘을, `trailing`에 닫기 버튼을 둡니다. 행동이 없는 대화상자는 닫기 버튼과 `onClose`가 닫는 길입니다.

```dart
Dialog(
  open: isOpen,
  leading: Icon(LucideIcons.triangleAlert),
  title: Text('경고'),
  trailing: Button(
    variant: CoreButtonVariant.plain,
    size: CoreComponentSize.sm,
    shape: CoreButtonShape.square,
    onPressed: close,
    child: Icon(LucideIcons.x),
  ),
  content: Text('이 작업은 되돌릴 수 없어요.'),
  onClose: close,
)
```

### 입력 다이얼로그

`content`에 입력창을 넣어 짧은 값을 받습니다. 본문 가장자리에 붙은 입력창도 포커스 링이 잘리지 않습니다(`contentClipMargin`). 화면 키보드가 올라올 때의 자리는 [배치](#배치)의 화면 키보드를 보세요.

```dart
Dialog(
  open: isRenameOpen,
  title: Text('이름 바꾸기'),
  content: TextField(label: '새 이름', onChanged: setName),
  actions: [
    Button(
      variant: CoreButtonVariant.outline,
      onPressed: close,
      child: Text('취소'),
    ),
    Button(onPressed: save, child: Text('저장')),
  ],
  onClose: close,
)
```

입력창이 둘 이상이면 Flutter는 `Column`, 웹은 `div`로 묶어 `content`에 넣습니다.

<a id="동작-스펙-behavior"></a>

## 상태

대화상자는 열림과 닫힘 두 상태를 가집니다. 보일지는 `open` 하나가 정하고, 사용자가 닫으려 하면 `onClose`로 알립니다.

| 항목 | 동작 |
| --- | --- |
| `open`의 기본값 | `true`입니다. `open`을 적지 않은 `Dialog`는 트리에 놓이는 순간 열립니다. |
| 사용자가 닫을 때 | 스크림이나 `Escape`(Flutter는 뒤로 가기도)가 `onClose`를 부릅니다. `onClose`에서 `open`을 `false`로 바꿔 상태를 맞춥니다. |
| `onClose`가 없을 때 | 스크림도 `Escape`도 닫지 않습니다. 행동 버튼이나 닫기 버튼이 `open`을 `false`로 바꿔 닫습니다. Flutter의 시스템 뒤로 가기(Android)는 그래도 대화상자를 닫는데, 알릴 `onClose`가 없어 `open`은 `true`로 남습니다 — 다시 열려면 `open`을 한 번 `false`로 바꿨다가 `true`로 돌려야 합니다. |
| 열린 동안 내용 바꾸기 | 슬롯(제목 · 본문 · leading · trailing · 행동)을 바꾸면 열린 패널이 따라갑니다. `dialogStyle`과 `onClose`의 유무는 플랫폼마다 다릅니다(플랫폼 차이). |
| 모션 줄이기 | 전환 시간이 0이 되어 바로 열리고 닫힙니다. |

<a id="기본-사용법-basic-usage"></a>
<a id="조합-예제"></a>

### 열기/닫기

상태 하나로 열고 닫습니다. 트리거 버튼은 `open`을 `true`로, `onClose`와 행동 버튼은 `false`로 바꿉니다.

```dart
// 삭제를 확인받는 흔한 모양
Button(
  variant: CoreButtonVariant.destructive,
  onPressed: () => setState(() => isDeleteOpen = true),
  child: Text('삭제'),
)

Dialog(
  open: isDeleteOpen,
  title: Text('항목 3개를 삭제할까요?'),
  content: Text('삭제한 항목은 되돌릴 수 없어요.'),
  actions: [
    Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => setState(() => isDeleteOpen = false),
      child: Text('취소'),
    ),
    Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {
        deleteItems();
        setState(() => isDeleteOpen = false);
      },
      child: Text('3개 삭제'),
    ),
  ],
  onClose: () => setState(() => isDeleteOpen = false),
)
```

- **Flutter**: `open`이 `true`가 되면 다음 프레임에 루트 내비게이터에 대화상자 라우트를 올리고, `false`가 되면 **자기가 올린 라우트를** 닫습니다. 그 위에 다른 페이지나 대화상자가 열려 있어도 그것은 그대로 두고 이 대화상자만 빠집니다. `Dialog`를 그리던 위젯이 트리에서 사라질 때도 같습니다. 트리에 놓인 `Dialog`의 자리는 크기가 0입니다.
- **Web**: `open`이 `true`인 동안 스크림과 패널을 오버레이 호스트의 대화상자 층에 올립니다. `false`가 되면 닫히는 애니메이션이 끝난 뒤 내리고, 그 사이에 다시 열면 내리지 않고 이어서 엽니다. 트리에 놓인 자리에는 숨은 빈 요소만 남습니다.
- Flutter는 `showDialog` 함수로도 엽니다. API의 `showDialog`를 보세요.

### 스크림 (배경 오버레이)

- 열리면 패널 뒤에 반투명한 스크림이 화면 전체를 덮어 뒤의 화면과 나눕니다. 기본 색은 `scrim`, 불투명도는 30%(`CoreOpacity.scrim`)입니다.
- 색과 불투명도는 `dialogStyle`의 `barrierColor` · `barrierOpacity`로 바꿉니다.
- **스크림을 눌러 닫는 것은 `onClose`가 있을 때만입니다.** 두 플랫폼 모두 스크림에서 누르기 시작한 누름만 닫습니다 — 패널 안에서 글자를 고르다 스크림 위에서 놓아도 닫히지 않습니다.

### 애니메이션

- 두 플랫폼 모두 `transitionDuration`(기본 200ms) 동안 0.9배(`scaleAnimationStart`)에서 1배(`scaleAnimationEnd`)로 커지며 나타납니다. 열릴 때는 `CoreEasing.enter`, 닫힐 때는 `CoreEasing.exit` 곡선입니다. Flutter는 커지는 배율 둘을 테마에서만 읽습니다 — 대화상자 하나의 `dialogStyle`에 준 배율은 닿지 않습니다(플랫폼 차이).
- **Flutter**: `ScaleTransition`과 `FadeTransition`. 뒤를 흐리는 유리 스타일에서는 패널에 불투명도를 걸지 않고 표면이 자기 흐림 · 채도 · 굴절을 진행도에 맞춰 줄이므로, 열고 닫는 동안에도 뒤가 흐립니다. 뒤를 흐리지 않는 스타일과 전체 화면 대화상자는 패널 전체를 불투명도로 페이드합니다. 자세한 규칙은 [서페이스 스타일](/guides/surface-styles#유리-패널이-나타나고-사라질-때)의 "유리 패널이 나타나고 사라질 때"를 보세요.
- **Web**: CSS 키프레임. 패널이 자기 요소에서 진행도를 걷고, 뒤를 흐리는 유리 스타일에서는 패널에 불투명도를 걸지 않고 스타일시트가 흐림 · 채도 · 밝기를 진행도에 맞춰 줄입니다. 그림자 · 내용 · 가장자리에 그리는 층도 같이 페이드합니다. 뒤를 흐리지 않는 스타일과 투명도 줄이기 · 낮은 품질 단계 · 강제 색상에서는 패널 요소를 불투명도로 페이드합니다. 서리 · 몸체 음영 · 굴절은 SVG 필터라 줄지 않고 정한 값으로 남습니다.

### Overlay 마운트

- **Flutter**: 루트 내비게이터에 라우트로 올라가므로 조상의 `ClipRect` · `Transform`에 잘리지 않습니다. `showDialog`는 `useRootNavigator: false`로 가장 가까운 내비게이터에 올릴 수 있습니다.
- **Web**: `CoUIWeb`의 오버레이 호스트에서 대화상자 층(`.dialog`)에 그리고, 브라우저의 top layer로 올립니다. 그래서 `overflow: hidden`이나 `transform`이 걸린 상자 안에 `Dialog`를 두어도 잘리거나 어긋나지 않습니다. 같은 페이지에 열린 팝오버 · 메뉴 · 툴팁과는 연 순서대로 쌓입니다 — 나중에 연 것이 위입니다.
- 오버레이 호스트가 없는 웹 트리(`CoUIWeb` · `OverlayHost` 밖 — 서버 렌더 · 테스트)에서는 스크림과 패널을 `Dialog`가 놓인 자리의 DOM에 그대로 넣습니다. 화면에서는 여전히 가운데에 고정되어 뜨지만, top layer로 올라가지 않아 조상의 `transform` · `overflow`에 갇힐 수 있고, 뒤를 막는 `inert`도 걸리지 않습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

대화상자는 사용자가 응답할 때까지 하던 일을 멈추게 합니다. 응답이 꼭 필요한 순간에만 씁니다.

- 삭제나 저장하지 않고 나가기처럼 되돌리기 어려운 행동을 확인받을 때
- 이름 바꾸기처럼 한두 칸의 짧은 입력을 받을 때
- 지금 알아야 하는 알림이나 경고를 보여 줄 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 응답을 기다리지 않는 짧은 알림 | [Toast](/components/toast) |
| 화면 가장자리에서 여는 패널, 긴 폼 | [Drawer](/components/drawer) |
| 특정 요소 옆에 붙는 작은 패널 | [Popover](/components/popover) |
| 행동 없이 짧은 도움말만 | [Tooltip](/components/tooltip) |
| 옮기고 크기를 바꾸는 비모달 창, 여러 창 | [Window](/components/window) (창 틀만 필요하면 [WindowPanel](/components/window-panel)) |

### 내용과 닫기

<Cards columns="2">
<Card demo="dialog/do-clear-result" tone="do" eyebrow="이렇게 하세요">

위험한 행동은 결과를 분명히 적습니다. 행동 버튼에도 무엇이 일어나는지 씁니다.

</Card>
<Card demo="dialog/dont-vague" tone="dont" eyebrow="이렇게 하지 마세요">

'확인'과 '진행할까요?'만으로는 무엇이 일어나는지 알 수 없어, 실수로 위험한 행동을 실행합니다.

</Card>
<Card demo="dialog/do-one-decision" tone="do" eyebrow="이렇게 하세요" height="340">

결정 하나에 집중하면 빠르게 판단할 수 있습니다.

</Card>
<Card demo="dialog/dont-too-much" tone="dont" eyebrow="이렇게 하지 마세요" height="340">

긴 폼이나 여러 단계는 별도 페이지나 Drawer에 둡니다. 대화상자는 짧은 확인과 입력에 맞습니다.

</Card>
<Card demo="dialog/do-close-path" tone="do" eyebrow="이렇게 하세요">

닫는 길을 하나 이상 둡니다 — 행동 버튼, 닫기 버튼, `onClose`(스크림 · `Escape`).

</Card>
<Card demo="dialog/dont-no-close" tone="dont" eyebrow="이렇게 하지 마세요">

행동도 `onClose`도 없으면 사용자가 대화상자에 갇혀 앱을 쓸 수 없습니다.

</Card>
</Cards>

## 배치

행동 줄은 `actionsLayout`이 정하는 두 방식 중 하나로 놓입니다. 순서는 늘 넣은 순서입니다 — 보조 행동을 먼저, 주요 행동을 나중에 넣으면 주요 행동이 줄의 끝(쌓이면 아래)에 옵니다.

<Cards columns="2">
<Card component="dialog" props="actionsLayout=end;content" title="end (기본)">

각 행동이 자기 폭으로 패널의 끝 쪽에 붙습니다. 데스크톱 대화상자의 배치입니다.

</Card>
<Card component="dialog" props="actionsLayout=stretch;content" title="stretch">

행동이 줄의 폭을 나눠 채웁니다. 하나면 줄 전체, 둘이면 반씩입니다. 휴대폰 확인창의 배치입니다.

</Card>
</Cards>

### 모바일 확인창

휴대폰 확인창처럼 행동 버튼이 줄의 폭을 채우게 하려면 `dialogStyle`에 `actionsLayout: CoreDialogActionsLayout.stretch`를 줍니다. 기본값 `CoreDialogActionsLayout.end`는 각 행동을 자기 폭으로 패널 끝에 붙입니다. 두 플랫폼이 같은 코드를 씁니다.

```dart
Dialog(
  open: isRetryOpen,
  title: Text('연결이 끊겼어요'),
  content: Text('네트워크를 확인한 뒤 다시 시도해 주세요.'),
  actions: [
    Button(
      variant: CoreButtonVariant.outline,
      onPressed: close,
      child: Text('취소'),
    ),
    Button(onPressed: retry, child: Text('다시 시도')),
  ],
  onClose: close,
  dialogStyle: CoreDialogStyle(
    actionsLayout: CoreDialogActionsLayout.stretch,
  ),
)
```

- 넓은 화면에서도 휴대폰 확인창으로 보이게 하려면 `panelMaxWidth: CoreLayout.layout320`을 함께 줍니다. 휴대폰에서는 화면 폭이 패널 폭을 정하므로 따로 줄 필요가 없습니다.
- 앱의 모든 대화상자에 켜려면 테마에서 `CoreDialogTheme(style: CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.stretch))`로 한 번 지정합니다. 대화상자 하나만이면 위처럼 `dialogStyle`로 지정합니다.

<Preview demo="dialog/placement-stacked" />

둘 중 하나라도 반에 들어가지 않으면 두 행동 모두 줄 전체 폭으로 세로로 쌓입니다. 먼저 넣은 행동이 위에 옵니다.

### 긴 본문과 행동 배치

- **본문이 화면보다 길면 본문만 스크롤됩니다.** 제목 줄과 행동 줄은 제자리에 있고, 패널은 화면에서 네 변을 `routePadding`만큼 띄운 높이에서 멈춥니다. 짧은 본문은 스크롤 영역이 되어도 같은 자리와 크기로 그려집니다.
- 스크롤 영역은 본문 상자 밖으로 `contentClipMargin`(기본 4)까지 그린 것을 남기고 잘라 냅니다 — 본문 가장자리에 붙은 입력창이 포커스되어도 포커스 링(입력창 밖 2 + 굵기 2)이 잘리지 않는 거리입니다. 두 플랫폼이 스크롤 여부와 상관없이 같은 자리에서 자릅니다.
- **end에서 행동이 한 줄에 들어가지 않으면 다음 줄로 넘어갑니다.** 줄마다 끝에 붙고 세로로는 가운데에 맞추며, 줄 사이는 `actionRunSpacing`(기본 8, `actionSpacing`과 같은 길이)입니다.
- **stretch에서는 모든 행동이 같은 몫에서 시작합니다** — 줄 폭에서 행동 사이 간격을 뺀 길이를 행동 수로 나눈 폭입니다. 셋 이상이면 한 줄에 들어가는 만큼 담고 나머지는 다음 줄로 넘어가며, 줄마다 그 줄의 폭을 채웁니다. 그 줄에서 자기 몫보다 넓은 행동은 자기 폭을 지키고, 남은 폭을 나머지가 나눕니다. 행동 사이 간격은 두 방식 모두 `actionSpacing`입니다.
- Flutter에서 행동 목록에 `Flexible`이나 `Spacer`가 있으면 그 목록이 배분을 스스로 정하므로, `actionsLayout`과 상관없이 한 줄 `Row`로 그립니다.

### 패널 폭과 화면 가장자리

- 패널의 폭과 높이 한계는 안쪽 여백과 테두리를 포함한 상자 전체의 값입니다.
- 넓은 화면에서 패널은 `panelMaxWidth`(기본 560) 폭으로 열리고, 좁은 화면에서는 화면에서 좌우로 `routePadding`(기본 16)만큼 띄운 폭이 됩니다. 패널은 `panelMinWidth`(기본 280)보다 좁아지지 않지만, 화면이 그보다 좁으면 화면에서 `routePadding` 만큼 띄운 폭까지 줄어듭니다. 두 플랫폼이 같은 폭으로 그립니다.
- 밀도를 바꾸면 `routePadding`이 compact 12 · standard 16 · spacious 20으로 움직입니다.

### 화면 키보드

화면 키보드가 올라오면 패널은 키보드 위에 남은 자리의 가운데로 옮겨 가고, 행동 줄은 키보드 위에 있습니다.

- **Flutter**: 대화상자를 가운데에 놓기 전에 키보드가 가린 높이만큼 놓을 영역을 줄입니다(전체 화면 대화상자는 제외). 줄어든 영역 안에서 본문이 길면 위의 규칙대로 본문만 스크롤됩니다. 안쪽 위젯은 키보드 높이를 다시 읽지 않습니다 — 같은 자리를 두 번 비우지 않도록 이 높이는 여기서 다 쓴 것으로 칩니다.
- **Web**: 키보드를 브라우저에 맡깁니다. 키보드 높이를 따로 읽거나 보정하지 않으므로, 패널이 어디에 놓이는지는 브라우저가 키보드에 맞춰 줄이는 영역(뷰포트 설정에 따라 다릅니다)을 따릅니다.

### 접히는 화면

- **화면이 접힘으로 나뉘어 있으면 패널은 한 조각 안에 열립니다** — 글이 시작하는 쪽 위의 조각(왼쪽에서 오른쪽으로 읽으면 왼쪽, 가로로 접혔으면 위쪽, 오른쪽에서 왼쪽으로 읽으면 오른쪽)의 가운데에, 그 조각에서 네 변을 `routePadding`만큼 띄운 크기 안에서 엽니다. 스크림은 화면 전체를 덮습니다.
- Flutter는 대화상자 라우트가, 웹은 브라우저가 알려 주는 조각(`env(viewport-segment-*)`)으로 같은 조각을 고릅니다. Flutter의 `showDialog`에 `anchorPoint`를 주면 그 점에 가까운 조각에 엽니다.
- Flutter 대화상자는 라우트의 페이지가 화면 전체일 때만 조각을 정확히 고릅니다. 화면의 일부를 채운 내비게이터에 올린 대화상자(`useRootNavigator: false`)는 그만큼 어긋납니다.
- 화면이 언제 나뉘는지와 어디까지 되는지는 [레이아웃](/guides/layout)의 "접히는 화면"을 보세요.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-dialogstyle"></a>

## 테마와 스타일

패널의 겉모습과 안쪽 부품(제목과 본문의 글자, 행동 버튼, 간격)은 모두 `dialogStyle`(`CoreDialogStyle`) 하나로 바꿉니다. 무엇을 보여 줄지(슬롯)와 언제 열지(`open` · `onClose`)는 위젯 파라미터로 줍니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="대화상자 하나만 바꾸기">
Dialog(
  open: isOpen,
  title: Text('확인'),
  content: Text('정말 삭제할까요?'),
  onClose: close,
  dialogStyle: CoreDialogStyle(
    panelBorderRadius: CoreBorderRadius.all(
      CoreRadius.radius16,
    ),
    panelPadding: CoreEdgeInsets.all(CoreSpace.space24),
    barrierOpacity: CoreOpacity.opacity40,
    titleStyle: CoreTextStyle.token(
      CoreTextStyles.titleMedium,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    dialog: CoreDialogTheme(
      style: CoreDialogStyle(
        actionsLayout: CoreDialogActionsLayout.stretch,
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

`CoreDialogStyle`에는 패널 · 스크림 · 간격 · 행동 줄 · 애니메이션 · 글자의 필드가 있습니다. 전체 목록은 API에서 확인하세요.

</Note>

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreDialogStyle 기본값        // 디자인 시스템
  → CoreDialogTheme.style      // 앱 전체
  → dialogStyle                // 대화상자 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지므로 앞에서 정한 다른 필드는 그대로 남고, `titleStyle` · `contentStyle` · `actionButtonStyle` · 간격 슬롯도 그 안의 필드끼리 합쳐집니다. 날짜 선택처럼 대화상자를 여는 컴포넌트는 자기 스타일에 든 대화상자 값을 `dialogStyle` 자리로 넘깁니다.

### asChild 패턴 — action 버튼 변경

행동 버튼의 **종류(variant)** 는 `actions`에 넣는 `Button`이 정합니다.

```dart
Dialog(
  actions: [
    Button(variant: CoreButtonVariant.outline, onPressed: close, child: Text('취소')),
    Button(variant: CoreButtonVariant.destructive, onPressed: delete, child: Text('삭제')),
  ],
)
```

`dialogStyle.actionButtonStyle`은 여백이나 글자 같은 겉모습만 조정합니다. 대화상자는 `actions` 안의 `Button`마다 이 값을 그 버튼의 `buttonStyle` 아래에 깔고, 버튼 자신의 `buttonStyle`이 이깁니다. `Button`이 아닌 행동은 그대로 둡니다. 지정하지 않으면 행동은 넣은 그대로 그려집니다.

### 빠른 오버라이드 (Chain)

이미 만든 `Dialog`에 스타일을 덧붙일 때는 `withStyle`을 이어 씁니다. `dialogStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DialogChainExample extends StatefulWidget {
  const DialogChainExample({super.key});

  @override
  State<DialogChainExample> createState() => _DialogChainExampleState();
}

class _DialogChainExampleState extends State<DialogChainExample> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () => setState(() => _open = true),
          child: const Text('대화상자 열기'),
        ),
        Dialog(
          open: _open,
          onClose: () => setState(() => _open = false),
          title: const Text('계속할까요?'),
          content: const Text('이 작업은 되돌릴 수 없어요.'),
          actions: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () => setState(() => _open = false),
              child: const Text('취소'),
            ),
            Button(
              variant: CoreButtonVariant.primary,
              onPressed: () => setState(() => _open = false),
              child: const Text('계속'),
            ),
          ],
        ).withStyle(
          const CoreDialogStyle(
            panelBackgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHigh,
            ),
            panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            panelPadding: CoreEdgeInsets.all(CoreSpace.space24),
            sectionGapStyle: CoreGapStyle(size: CoreSpace.space12),
            actionSpacing: CoreSpace.space12,
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
class DialogChainExample extends StatefulComponent {
  const DialogChainExample({super.key});

  @override
  State<DialogChainExample> createState() => _DialogChainExampleState();
}

class _DialogChainExampleState extends State<DialogChainExample> {
  bool _open = false;

  @override
  Component build(BuildContext context) {
    return div([
      Button(
        variant: CoreButtonVariant.primary,
        onPressed: () => setState(() => _open = true),
        child: Text('대화상자 열기'),
      ),
      Dialog(
        open: _open,
        onClose: () => setState(() => _open = false),
        title: Text('계속할까요?'),
        content: Text('이 작업은 되돌릴 수 없어요.'),
        actions: [
          Button(
            variant: CoreButtonVariant.outline,
            onPressed: () => setState(() => _open = false),
            child: Text('취소'),
          ),
          Button(
            variant: CoreButtonVariant.primary,
            onPressed: () => setState(() => _open = false),
            child: Text('계속'),
          ),
        ],
      ).withStyle(
        const CoreDialogStyle(
          panelBackgroundColor: CoreColor.token(
            CoreColors.surfaceContainerHigh,
          ),
          panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
          panelPadding: CoreEdgeInsets.all(CoreSpace.space24),
          sectionGapStyle: CoreGapStyle(size: CoreSpace.space12),
          actionSpacing: CoreSpace.space12,
        ),
      ),
    ]);
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="접근성-accessibility"></a>

## 접근성

Flutter는 패널의 `dialog` 역할과 모달 라우트로, 웹은 `role="dialog"`와 `aria-modal="true"`로 대화상자임을 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 패널이 `dialog` 역할을 말하고(안의 컨트롤은 각자 포커스 대상으로 남습니다), 모달 라우트(`DialogRoute`)가 범위를 엽니다. 스크림의 이름은 로케일의 닫기 문구(한국어 "닫기")입니다. |
| Jaspr Web | 패널에 `role="dialog"`와 `aria-modal="true"`를 붙입니다. 이 둘은 `attributes`보다 뒤에 놓여 바꿀 수 없고, 다른 `aria-*`는 그대로 붙습니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Escape` | 대화상자를 닫습니다 — `onClose`가 있을 때만. `showDialog`로 연 Flutter 대화상자는 `barrierDismissible`(기본 `true`)을 따릅니다. |
| `Tab` · `Shift+Tab` | 대화상자 안의 요소 사이를 옮깁니다. |
| `Enter` · `Space` | 포커스된 버튼을 실행합니다. |

<Note>

화살표 키는 처리하지 않습니다 — 행동 버튼 사이는 `Tab`으로만 옮깁니다. Flutter 네이티브는 프레임워크 기본 단축키가 화살표를 방향 포커스 이동에 쓰지만 Flutter Web에서는 스크롤로 가므로, 화살표에 기대지 마세요.

</Note>

### 스크린 리더

- **대화상자의 이름은 `title`입니다.** 따로 문구를 받지 않고 제목이 그대로 이름이 됩니다 — Flutter는 제목을 라우트의 이름으로 표시해 열릴 때 읽고, 웹은 패널의 `aria-labelledby`가 제목 요소를 가리킵니다. `title`이 없으면 이름도 없습니다. 웹에서 `attributes`로 `aria-label`이나 `aria-labelledby`를 직접 주면 그 값이 우선합니다.
- `content`는 설명으로 연결되지 않습니다. 웹에는 `aria-describedby`가 없습니다.
- **뒤의 화면은 두 플랫폼 모두 가려집니다.** Flutter는 모달 라우트의 스크림이 배경을 접근성 트리에서 빼고, 웹은 열린 동안 앱 콘텐츠에 `inert`가 붙어 접근성 트리 · 탭 순서 · 포인터에서 함께 빠집니다.
- 열림과 닫힘은 따로 알리지 않습니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열 때 | 라우트가 자기 포커스 범위를 세워 포커스가 대화상자 안으로 들어갑니다. | 포커스를 옮기지 않습니다. 배경이 `inert`가 되어 직전에 포커스된 요소는 탭 순서에서 빠집니다. |
| 닫을 때 | 라우트가 닫히며 포커스가 이전 범위로 돌아갑니다. | 연 요소로 포커스를 되돌리지 않습니다. |
| 가두기 | `Tab`이 대화상자 안에서 순환합니다(`traversalEdgeBehavior`의 기본 `closedLoop`). | 배경으로는 나가지 않지만 안에서 순환하지도 않습니다 — 마지막 요소에서 `Tab`은 브라우저 UI로 나갔다가 패널로 돌아옵니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `title` 없이 이름을 줄 파라미터가 없습니다. 웹은 `attributes`의 `aria-label`로 줄 수 있습니다. |
| 공통 | `onClose`를 주지 않으면 `Escape`도 스크림도 닫지 않습니다. 닫기 버튼을 `trailing`이나 `actions`에 꼭 둡니다. |
| Flutter | `onClose`가 없어도 시스템 뒤로 가기(Android)는 대화상자를 닫습니다. 이때 `open`은 `true`로 남아, 다시 열려면 `open`을 `false`로 바꿨다가 `true`로 돌려야 합니다. |
| Flutter | `Button` · `Icon`에 이름을 받는 파라미터가 없어, 아이콘만 있는 닫기 버튼의 이름은 앱이 따로 붙여야 합니다. 웹은 `attributes`의 `aria-label`을 씁니다. |
| Jaspr Web | 열 때 포커스를 옮기지 않고, 닫을 때 되돌리지 않습니다. 첫 요소에 포커스가 필요하면 앱이 직접 옮깁니다. |
| Jaspr Web | `Escape`를 받을지는 처음 그릴 때의 `onClose`가 정합니다. 나중에 `onClose`를 주어도 `Escape`로 닫히지 않습니다. |
| Jaspr Web | 오버레이 호스트(`CoUIWeb` · `OverlayHost`) 밖에서는 배경을 막는 `inert`가 걸리지 않습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같고, 렌더링은 각 플랫폼의 방식을 따릅니다. 웹의 슬롯 타입은 `Widget` 대신 `Component`입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 여는 방법 | `open` 또는 `showDialog` | `open` — `showDialog`에 해당하는 함수가 없습니다 |
| 스크림 · `Escape`로 닫을 때 | 라우트를 먼저 닫고 `onClose`를 부릅니다 | `onClose`만 부릅니다. `open`을 `false`로 바꾸기 전까지 열려 있습니다 |
| 겹친 대화상자에서 `Escape` | 맨 위 대화상자 하나만 닫힙니다 | `onClose`가 있는 열린 대화상자 모두에 `onClose`를 부릅니다 |
| 열린 동안 `dialogStyle` 바꾸기 | 열린 패널은 따라가지 않고 다음에 열 때 반영됩니다 | 열린 패널이 바로 따라갑니다 |
| 열린 동안 `onClose`를 새로 주기 | 그 열림에서는 스크림 · `Escape`가 닫지 않고, 다음에 열 때부터 닫습니다 | 스크림은 바로 닫습니다. `Escape`는 처음 그릴 때 `onClose`가 있었을 때만 닫습니다 |
| 대화상자 하나에 준 `scaleAnimationStart` · `scaleAnimationEnd` | 닿지 않습니다 — 커지는 배율은 테마(`CoreDialogTheme.style`)의 값만 읽습니다. `transitionDuration`은 닿습니다 | 닿습니다 |
| 스크림 | 모달 라우트의 배리어 | 배경 `<div>`와 클릭 처리 |
| 포커스 | `FocusScope`의 순환 | 호스트가 배경에 `inert`를 붙입니다. 안에서의 순환과 복원은 없습니다 |
| 애니메이션 | `ScaleTransition` + `FadeTransition` — 유리 패널은 불투명도 대신 표면이 자기 재질을 줄입니다 | CSS 키프레임 — 유리 패널은 불투명도 대신 진행도(`--coui-fade`)를 걷고 스타일시트가 재질을 줄입니다. 서리 · 몸체 음영 · 굴절은 줄지 않습니다 |
| 긴 본문 | `Flexible` 안의 `SingleChildScrollView` — 본문 상자에서 `contentClipMargin`만큼 부풀린 `ClipRect`가 자릅니다 | `overflow-y: auto` 스크롤 영역 — 음수 `margin`과 같은 길이의 `padding`으로 자르는 경계를 `contentClipMargin`만큼 넓힙니다 |
| 패널 최대 높이 | 라우트가 안전 영역 안에서 네 변을 `routePadding`만큼 띄웁니다 | `max-height: calc(100% - 2 × routePadding)` |
| 화면 키보드 | 라우트가 놓을 영역을 키보드 높이만큼 줄인 뒤 패널을 가운데에 놓습니다 | 브라우저에 맡깁니다. 키보드 높이를 따로 읽지 않습니다 |
| 행동 줄바꿈 | `Wrap(alignment: .end, crossAxisAlignment: .center)` — 행동에 `Flexible` · `Spacer`가 있으면 한 줄 `Row` | `flex-wrap` + `justify-content: flex-end` + `align-items: center` |
| 줄을 채우는 행동(`stretch`) | 행동을 놓는 레이아웃이 Core의 공유 규칙 `CoreDialogActionsStretch`로 행동마다 줄 · 위치 · 폭을 정합니다. 행동에 `Flexible` · `Spacer`가 있으면 한 줄 `Row`(웹의 행동에는 배분 계수가 없어 Flutter에만 있는 경로) | 같은 `flex-wrap` 행동 줄 안에서 행동마다 칸 하나 — `flex-basis`는 같은 몫, `min-width: fit-content`, `flex-grow: 1` — 줄 · 위치 · 폭은 브라우저가 정합니다 |
| 스크롤바 | 앱의 `ScrollBehavior`가 그리는 스크롤바(본문 위에 겹침) | 브라우저 스크롤바(넘칠 때 자리를 차지) |
| 오버레이 마운트 | 루트 내비게이터의 대화상자 라우트 | 오버레이 호스트의 대화상자 층 + top layer — 연 순서대로 쌓입니다 |
| 접히는 화면 | 대화상자 라우트가 조각을 고릅니다 | `env(viewport-segment-*)`로 조각을 고릅니다 |
| ARIA | 모달 라우트, 패널의 `dialog` 역할, 제목이 라우트의 이름 | `role="dialog"`, `aria-modal="true"`, `aria-labelledby` → 제목 요소 |

`stretch`는 두 플랫폼이 서로 다른 방법으로 배치하므로, 입력과 기대 배치를 적은 표 하나를 Core 테스트 · Flutter 테스트 · 실제 Chrome 측정이 함께 읽어 같은 자리에 놓이는지 대조합니다. 두 플랫폼이 다르게 그리는 자리는 다음과 같습니다.

- **줄보다 좁아질 수 없는 행동.** 웹은 CSS대로 그 행동을 줄보다 넓게 두어 시작 쪽으로 넘치게 하고, Flutter는 자식을 부모보다 넓게 놓지 않으므로 줄 폭에 맞춰 줄입니다. 표가 이 차이를 Flutter 기대값(`flutterCells`)으로 따로 적어 둡니다. 글자가 줄바꿈되는 보통의 버튼은 두 플랫폼 모두 줄 안에서 줄바꿈되므로 이 차이가 나지 않습니다.
- **Flutter의 행동은 크기를 물어볼 수 있어야 합니다.** 행동마다 자연 폭과 가장 좁은 폭을 재서 놓기 때문에, 크기 질의에 답하지 않는 위젯(`LayoutBuilder` 등)을 행동으로 넣으면 디버그 빌드에서 assert가 납니다. `end`는 재지 않으므로 그대로 그립니다.
- **트리거로 감싼 행동 (웹).** `Tooltip` · `Popover` · `HoverCard`로 감싼 버튼은 웹에서 칸 폭을 다 채우지 못하고 자기 폭으로 남습니다 — 칸은 바로 아래 자식만 늘리는데, 트리거가 내용 폭의 `inline-flex`로 버튼을 한 번 더 감싸기 때문입니다. Flutter는 폭 제약이 트리거를 지나 버튼까지 내려가 칸을 채웁니다.
- **아이콘이 있는 버튼.** `leading`이나 `trailing`이 있는 버튼을 넓게 늘리면 Flutter는 내용을 시작 쪽에, 웹은 가운데에 둡니다. `stretch`가 만든 차이가 아니라 넓은 Button의 차이이며, `BottomActionBar`의 가로 배치에서도 같습니다.

<a id="props-parameters"></a>

## API

`Dialog`는 두 플랫폼이 같은 파라미터를 씁니다. 웹의 슬롯 타입은 `Component`이고 `onClose`의 타입은 `CoreVoidCallback?`입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `open` | `bool` | `true` | 열려 있는가. 적지 않으면 놓이는 순간 열립니다. |
| `title` | `Widget?` | `null` | 제목. 대화상자의 이름이 됩니다. |
| `content` | `Widget?` | `null` | 본문. 길면 본문만 스크롤됩니다. |
| `leading` | `Widget?` | `null` | 제목 앞(아이콘) |
| `trailing` | `Widget?` | `null` | 제목 뒤(닫기 버튼) |
| `actions` | `List<Widget>?` | `null` | 아래 행동. 넣은 순서대로 놓입니다. |
| `onClose` | `VoidCallback?` | `null` | 스크림 · `Escape`(Flutter는 뒤로 가기도)로 닫으려 할 때. 없으면 스크림 · `Escape`로는 닫히지 않습니다(Flutter의 뒤로 가기는 그래도 닫습니다 — 상태 참고). |
| `dialogStyle` | `CoreDialogStyle?` | `null` | 패널과 안쪽 부품의 겉모습 덮어쓰기 |

웹은 여기에 `id` · `classes` · `css` · `attributes`와 이벤트 처리기를 더 받고, 모두 패널 요소에 붙습니다. 두 플랫폼 모두 `withStyle(CoreDialogStyle patch)`로 `dialogStyle`에 값을 덧붙인 복사본을 만듭니다.

### 여는 함수 — `showDialog` (Flutter)

`showDialog`는 `builder`가 만든 위젯을 대화상자 라우트로 올리고, 닫힐 때 `Navigator.pop`에 넘긴 값을 돌려줍니다(`Future<T?>`). `builder` 안의 `Dialog`는 라우트를 하나 더 열지 않고 패널만 그립니다. 이때 닫기는 `Navigator.pop(context, 값)`으로 하고, 스크림 · `Escape`는 `barrierDismissible`이 정합니다 — 안쪽 `Dialog`에 준 `onClose`는 불리지 않습니다. 웹에는 이 함수가 없습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `context` | `BuildContext` | 필수 | 여는 자리. 테마를 이 자리에서 가져갑니다. |
| `builder` | `WidgetBuilder` | 필수 | 대화상자 안에 그릴 위젯 |
| `barrierDismissible` | `bool` | `true` | 스크림 · `Escape`로 닫을지 |
| `barrierColor` | `Color?` | `null` | 스크림 색. 없으면 `dialogStyle`과 테마의 값 |
| `barrierColorBuilder` | `Color? Function(BuildContext)?` | `null` | 내비게이터의 자리에서 스크림 색을 정할 때 |
| `barrierLabel` | `String?` | `null` | 스크림의 이름. 없으면 로케일의 닫기 문구 |
| `dialogStyle` | `CoreDialogStyle?` | `null` | 라우트가 읽는 값 — 패널 둘레의 여백, 스크림, 전환 시간 |
| `fullScreen` | `bool` | `false` | 화면 전체를 쓰는 대화상자. `routePadding`을 쓰지 않습니다. |
| `alignment` | `AlignmentGeometry?` | `null` | 패널의 자리. 없으면 가운데 |
| `anchorPoint` | `Offset?` | `null` | 접히는 화면에서 이 점에 가까운 조각에 엽니다. |
| `useRootNavigator` | `bool` | `true` | 루트 내비게이터에 올릴지 |
| `useSafeArea` | `bool` | `true` | 안전 영역 안에 둘지 |
| `traversalEdgeBehavior` | `TraversalEdgeBehavior?` | `null` | 끝에서 포커스가 갈 곳. 없으면 `closedLoop` |
| `routeSettings` | `RouteSettings?` | `null` | 라우트 설정 |

### 테마 — `CoreDialogTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreDialogStyle?` | `null` | 앱의 모든 대화상자에 깔리는 값. Dialog에는 variant가 없어 variant별 값은 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDialogStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelBackgroundColor` | `CoreColor?` | Panel background fill colour override. When null, defers to [defaultsByVariant] `background` (`surfaceBright` token). |
| `panelBorderColor` | `CoreColor?` | Panel border stroke colour override. When null, defers to [defaultPanelBorderColor] (`outlineSubtle` token). |
| `panelBorderWidth` | `double?` | Panel border width override (logical pixels). When null, defers to [defaultPanelBorderWidth] (1 logical px). |
| `panelBorderRadius` | `CoreBorderRadius?` | Panel border radius override. When null, defers to [defaultPanelBorderRadius] (20 logical px uniform). |
| `panelPadding` | `CoreEdgeInsets?` | Panel content padding override. When null, defers to [defaultPanelPadding] (24 above and on both sides, 20 below). |
| `panelMinWidth` | `double?` | Panel minimum width override (logical pixels). When null, defers to [defaultPanelMinWidth] (`CoreLayout.layout280`, 280). A viewport that leaves less room than this narrows the panel to that room. |
| `panelMaxWidth` | `double?` | Panel maximum width override (logical pixels). When null, defers to [defaultPanelMaxWidth] (`CoreLayout.layout560`, 560). |
| `surfaceBlur` | `double?` | Backdrop blur sigma applied behind the panel. |
| `surfaceOpacity` | `double?` | Panel surface opacity multiplier (0.0 – 1.0). |
| `panelBoxShadow` | `List<CoreShadowLayer>?` | Elevation shadow of the dialog panel. When null, defers to [defaultPanelBoxShadow] (`CoreShadow.xl`, the Modal/Dialog rung). |
| `shadowBaseColor` | `CoreColor?` | Base colour the [panelBoxShadow] layers tint against. When null, defers to [defaultShadowBaseColor] (`shadow` token). |
| `barrierColor` | `CoreColor?` | Backdrop barrier overlay colour override. When null, defers to [defaultsByVariant] `overlayColor` (`scrim` token). |
| `barrierOpacity` | `double?` | Backdrop (scrim) opacity multiplier override (0.0 – 1.0). When null, defers to [defaultBarrierOpacity] (0.3). |
| `sectionGapStyle` | `CoreGapStyle?` | Gap slot between the dialog's head and body — header row / content — and inside the header row between leading / title / trailing. Forwarded straight to `Gap(gapStyle: …)` (Flutter) and to the inter-slot inline `gap` CSS (Web). `null` defers to [defaultSectionGapStyle] (14 logical px). |
| `actionsGapStyle` | `CoreGapStyle?` | Gap slot between the dialog's body and its actions row. Forwarded straight to `Gap(gapStyle: …)` (Flutter) and to the inline `gap` CSS above the footer (Web). `null` defers to [defaultActionsGapStyle] (20 logical px). |
| `actionSpacing` | `double?` | Gap between adjacent action buttons inside the actions row (logical pixels), in either [actionsLayout]. Rendered as the spacing of the actions row (Flutter — the `Wrap` at the end, the stretched row when stretched) / inline `column-gap` CSS on the footer row (Web, where the stretched share subtracts it too). `null` defers to [defaultActionSpacing] (8 logical px). |
| `actionRunSpacing` | `double?` | Gap between the rows the actions wrap onto once they no longer fit on one line (logical pixels), in either [actionsLayout] — the run spacing of the actions row (Flutter) / inline `row-gap` CSS on the wrapping footer (Web); two stretched actions that stack sit this far apart. One line of actions never reads it. `null` defers to [defaultActionRunSpacing] (8 logical px). |
| `actionsLayout` | `CoreDialogActionsLayout?` | How the actions row spreads its actions. [CoreDialogActionsLayout.end] keeps each action its own width at the panel's end; [CoreDialogActionsLayout.stretch] starts every action at the same share of the row so together they fill it — one action the whole row, two half each, and, when either does not fit its half, both stacked at the full width with [actionRunSpacing] between them (three or more: see [CoreDialogActionsLayout.stretch]). The order is always the order the actions were handed in. `null` defers to [defaultActionsLayout] ([CoreDialogActionsLayout.end]). |
| `contentClipMargin` | `double?` | How far past its own box the body keeps painting before the dialog clips it (logical pixels), on every side. `null` defers to [defaultContentClipMargin] (4 logical px, the focus outline's reach). |
| `routePadding` | `double?` | The room the dialog route leaves between the panel and the edges of the screen, in logical pixels — one length on every side. `null` defers to [defaultRoutePadding] (16 logical px). |
| `transitionDuration` | `Duration?` | Open/close transition duration override. When null, defers to [defaultTransitionDuration] (200 ms). |
| `scaleAnimationStart` | `double?` | Panel open-animation start scale override. When null, defers to [defaultScaleAnimationStart] (0.9). |
| `scaleAnimationEnd` | `double?` | Panel open-animation end scale override. When null, defers to [defaultScaleAnimationEnd] (1.0). |
| `titleStyle` | `CoreTextStyle?` | Title text style override. |
| `contentStyle` | `CoreTextStyle?` | Content (body) text style override. |
| `actionButtonStyle` | `CoreButtonStyle?` | Action button style override. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Drawer" href="/components/drawer" more="Drawer 보기">

화면 가장자리에서 여는 패널입니다. 긴 폼이나 복잡한 내용에 씁니다.

</Card>
<Card title="Toast" href="/components/toast" more="Toast 보기">

응답을 기다리지 않는 짧은 알림입니다.

</Card>
<Card title="Popover" href="/components/popover" more="Popover 보기">

특정 요소 옆에 붙는 작은 패널입니다.

</Card>
</Cards>
