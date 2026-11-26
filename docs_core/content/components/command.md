---
title: Command
description: 검색 가능한 커맨드 팔레트 컴포넌트
category: control
platforms: [flutter, web]
related: [kbd, dialog, text-field]
tags: [interactive, search, keyboard, command-palette]
template: v2
source: control/command
---

# Command

`Command`는 검색어로 명령을 거르고 키보드로 골라 실행하는 커맨드 팔레트입니다. 검색 줄, 그룹으로 묶은 항목 목록, 선택할 수 있는 범위 칩과 키보드 힌트 푸터로 이루어집니다. 놓인 자리에 상자 하나를 그리며, 대화상자나 화면 전체로 띄우는 일은 앱이 맡습니다.

<a id="live-preview"></a>

## 플레이그라운드

속성을 바꾸고 검색어를 입력해 보세요. 만들어진 코드는 그대로 복사할 수 있습니다.

<Playground component="command" />

<Note>

무대의 팔레트는 실제 `Command`라서 입력하면 항목이 걸러집니다. `Command`는 항목을 골라도 스스로 닫히지 않으므로, 이 팔레트에서는 골라도 화면이 바뀌지 않습니다. 문서의 포커스를 가져가지 않게 `autofocus`는 꺼 두었습니다. `presentation`을 `dialog`로 고르면 팔레트 아래에 **열어 보기**가 생기고, 같은 속성의 팔레트를 실제 `Dialog` 안에 엽니다. 항목 선택 · 스크림 · `Escape`로 닫습니다. `fullscreen`은 화면 대신 높이 400의 자리에 그립니다. Flutter 팬은 칸이 좁거나 낮으면 팔레트를 줄여 그립니다.

</Note>

## 구조

팔레트는 검색 줄, 범위 칩 줄, 항목 목록, 푸터를 위에서 아래로 놓습니다. 그림은 `dialog` 형태에 `scopes`와 `onDismiss`를 준 모습입니다.

<Anatomy demo="command/anatomy">
<AnatomyItem select="[role=combobox]" name="Container">

팔레트 상자. 채움은 `surfaceBright`이고, 모서리 · 테두리 · 그림자는 [형태](#형태)가 정합니다.

</AnatomyItem>
<AnatomyItem part="leading" name="search icon">

검색 아이콘. 색은 `onSurfaceVariant`라서 옆의 안내 글보다 한 단계 진합니다. `fullscreen`에서 `onDismiss`를 주면 이 자리에 뒤로 버튼이 놓입니다.

</AnatomyItem>
<AnatomyItem select="input" side="left" name="search field">

테두리 없는 `TextField`(`plain`). 포커스를 받아도 테두리를 그리지 않고, 입력 커서와 강조된 행이 위치를 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="[role=img][aria-label=esc]" side="right" name="esc">

`dialog` 형태에 `onDismiss`가 있을 때만 붙는 `Kbd` 키캡. 닫는 방법을 알려 줄 뿐 누르는 버튼은 아닙니다.

</AnatomyItem>
<AnatomyItem select="[role=group]" side="left" name="scopes">

범위 칩 줄. `scopes`가 있을 때만 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=presentation]" side="left" name="heading">

그룹 제목. 글자는 `labelXs`(11 Medium), 색은 `onSurfaceSubtle`입니다.

</AnatomyItem>
<AnatomyItem select="[role=option]" side="left" name="item">

항목 한 행. 아이콘, 라벨(윗줄이 있으면 두 줄), 단축키 순서입니다. 키보드 커서가 있는 행은 `surfaceContainer`로 채웁니다.

</AnatomyItem>
<AnatomyItem select="[role=combobox] > div:last-child" side="left" name="footer">

키보드 힌트 푸터. `↑` `↓` 키캡과 "이동", `scopes`가 있으면 `←` `→` 키캡과 "범위", `⏎` 키캡과 "선택"이 차례로 놓입니다. `onDismiss`가 있고 `dialog` 형태가 아니면 `esc` 키캡과 "닫기"가 더 붙습니다. `dialog` 형태는 기본으로 보이고 나머지는 기본으로 숨깁니다.

</AnatomyItem>
</Anatomy>

검색 줄(범위 칩이 있으면 그 아래)과 목록 사이, 목록과 푸터 사이에는 `Divider`가 놓입니다.

<a id="기본-사용법-basic-usage"></a>

## 항목과 그룹

`groups`에 그룹과 항목을 선언하고, 검색어는 `query`와 `onQueryChanged`로 부모가 들고 있습니다. Flutter와 Web에서 같은 코드를 씁니다.

```dart
Command(
  query: query,
  onQueryChanged: (value) => setState(() => query = value),
  onSelect: runCommand,
  groups: const [
    CoreCommandGroup(
      heading: '추천',
      items: [
        CoreCommandItem(value: 'calendar', label: '캘린더'),
        CoreCommandItem(value: 'upload', label: '파일 올리기'),
      ],
    ),
    CoreCommandGroup(
      heading: '설정',
      items: [
        CoreCommandItem(value: 'profile', label: '프로필', shortcut: '⌘P'),
        CoreCommandItem(value: 'billing', label: '결제', shortcut: '⌘B'),
      ],
    ),
  ],
)
```

<Preview demo="command/items" />

위 그림은 첫 행이 강조된 상태이고, 아래로 단축키 행, 윗줄이 있는 두 줄 행, 비활성 행입니다.

| 항목 값 | 동작 |
| --- | --- |
| `value` | `onSelect`가 받는 식별자입니다. 팔레트 전체에서 겹치지 않게 둡니다. 모든 값이 똑같은 항목이 화면에 두 번 나오면 Web은 두 행을 함께 강조하고, Flutter는 두 행의 키가 겹쳐 에러가 납니다. |
| `label` | 행에 보이는 글자이며 검색 대상입니다. |
| `icon` | 라벨 앞 아이콘입니다. 크기와 색은 팔레트가 내려 주며, 아이콘에 직접 준 값이 있으면 그 값을 씁니다. |
| `shortcut` | 행 끝에 글자 그대로 보입니다. `Kbd` 키캡이 아니고, 단축키를 등록하지도 않습니다. |
| `overline` | 라벨 위의 한 줄입니다. 결과가 어디서 왔는지처럼 먼저 읽어야 할 분류를 적습니다. 있으면 두 줄 행이 됩니다. 두 줄 모두 Regular 굵기이고, 윗줄(`bodyXs` 12 · `onSurfaceVariant`)이 아래 라벨보다 작고 옅습니다. |
| `keywords` | 보이지 않는 검색 별칭입니다. 라벨에 없는 단어로도 찾게 합니다. |
| `enabled` | `false`면 방향키가 건너뛰고 눌리지 않으며, 라벨과 아이콘이 `disabledContent`가 됩니다. 윗줄과 단축키의 색은 두 플랫폼이 다릅니다([플랫폼 차이](#플랫폼-차이)). |

<Preview demo="command/keywords" />

`date`는 라벨에는 없지만 캘린더 항목의 `keywords`에 있어 그 항목이 남습니다.

최근 항목처럼 앱 데이터에서 목록을 만들 때는 `for`로 항목을 만듭니다.

```dart
Command(
  query: query,
  onQueryChanged: setQuery,
  onSelect: runCommand,
  groups: [
    CoreCommandGroup(
      heading: '최근 항목',
      items: [
        for (final item in recentItems)
          CoreCommandItem(value: item.id, label: item.title),
      ],
    ),
  ],
)
```

## 범위 필터

`scopes`를 주면 검색 줄 아래에 칩이 생기고, 맨 앞에는 모든 그룹을 보여 주는 **전체** 칩이 자동으로 붙습니다. 그룹의 `scope`가 고른 값과 같거나 `null`인 그룹만 보입니다. `scope: null`이 전체입니다.

<Preview demo="command/scopes" />

```dart
Command(
  query: query,
  onQueryChanged: setQuery,
  scopes: const [
    CoreCommandScope(value: 'actions', label: '작업'),
    CoreCommandScope(value: 'pages', label: '페이지'),
  ],
  scope: scope, // null 은 전체
  onScopeChanged: setScope,
  onSelect: runCommand,
  groups: groups, // 각 그룹에 scope 를 적습니다.
)
```

- 고른 칩은 `primaryContainer` 채움에 `onPrimaryContainer` 글자인 낮은 강조(`emphasis: low`)로 그려 검색 입력보다 먼저 눈에 띄지 않게 합니다. 고르지 않은 칩은 채움이 없고 글자가 `onSurfaceVariant`입니다. 칩에는 테두리가 없고, 모서리는 크기와 관계없이 8입니다.
- 칩을 누르거나 `←` · `→`로 범위를 옮깁니다. 방향키는 양 끝에서 멈춥니다. 범위를 옮겨도 검색어는 그대로입니다.
- 바뀐 범위는 `onScopeChanged`로 알리며, 부모가 `scope`를 바꿔야 화면이 따라갑니다.

## 크기

<SizeSpec component="command" props="icons;items=short;width=240" />

`size`는 `CoreCommandSize`의 `sm` · `md`(기본) · `lg` 세 단계입니다. 검색 줄과 행의 높이는 폼 컨트롤과 같은 32 · 40 · 48이라, 안의 `TextField`와 `fullscreen`의 뒤로 `Button`은 같은 이름의 크기를 쓰고, 범위 칩은 `Chip`의 같은 이름 크기를 씁니다.

- 행 높이는 최소 높이입니다. 윗줄이 있는 두 줄 행이나 큰 글자는 그보다 커집니다. 검색 줄은 표의 높이로 고정됩니다.
- 크기에 따라 함께 바뀌는 여백(좌우 × 위아래)은 범위 칩 줄 8×6 · 12×8 · 16×12, 푸터 12×6 · 20×8 · 24×12이고, 그룹 제목의 끝 쪽 여백은 8 · 12 · 16입니다. 제목의 시작 쪽은 10, 위아래는 6입니다.
- 모든 크기에서 같은 것은 검색 줄의 좌우 여백 12, 아이콘 · 글자 · 단축키 사이 10, 행 모서리 8, 목록 안쪽 여백 8과 항목 · 제목 · 구분선 사이 2입니다. 윗줄 · 단축키 · 푸터 글자는 `bodyXs`(12), 그룹 제목은 `labelXs`(11)입니다. 행 사이의 간격 2 덕분에 강조 행과 hover한 행의 채움이 맞닿지 않습니다.
- 밀도를 바꾸면 검색 줄과 행 높이가 컨트롤 높이 한 단계씩 움직이고(`compact`에서도 `sm`의 32는 그대로), 여백과 간격도 밀도를 따릅니다. `commandStyle`에 직접 준 높이는 그대로입니다.

## 형태

`presentation`은 팔레트의 겉모습과 크기 한계, 푸터의 기본값, `onDismiss`를 주었을 때의 닫기 표시를 정합니다. 스크림 · 모달 · 화면 전환은 팔레트를 담는 쪽이 맡습니다. 보통 좁은 화면에서는 `fullscreen`, 넓은 화면에서는 `dialog`를 고르고, 페이지 안에 펼쳐 둘 때는 `inline`을 씁니다. 세 형태 모두 채움은 `surfaceBright`입니다.

| 항목 | `inline` (기본) | `dialog` | `fullscreen` |
| --- | --- | --- | --- |
| 쓰는 자리 | 페이지 안 | `Dialog` 안 | 화면 전체를 쓰는 라우트 |
| 모서리 | 12 | 20 | 0 |
| 테두리 | 1px `outlineVariant` | 1px `outlineSubtle` | 없음 |
| 그림자 | 없음 | `lg` | 없음 |
| 폭 | 부모 폭, 최소 240 | 부모 폭, 최대 640 | 부모 폭 |
| 목록 높이 | 240~320, 넘으면 스크롤 | 240~400, 넘으면 스크롤 | 남은 높이 (Web은 내용 높이) |
| 푸터 기본값 | 숨김 | 보임 | 숨김 |
| `onDismiss`가 있을 때의 닫기 표시 | 푸터를 켜면 푸터의 `esc` 힌트 | 검색 줄 끝의 `esc` 키캡 | 검색 줄 앞의 뒤로 버튼 (푸터를 켜면 `esc`도) |

<Preview component="command" props="presentation=dialog;icons;scopes;dismiss" />

`dialog` 형태입니다. `Dialog`의 `onClose`와 별개로 `onDismiss`를 주면 검색 줄 끝에 `esc` 키캡이 붙고, 푸터에는 `esc` 힌트를 다시 적지 않습니다.

<Preview component="command" props="presentation=fullscreen;icons;dismiss" />

`fullscreen` 형태입니다. 그림의 자리는 높이 400입니다. Web 그림은 목록이 늘어나지 않아 그 높이를 다 채우지 않습니다.

<a id="동작-스펙-behavior"></a>

## 상태

### 인터랙션

- **입력**: 앞뒤 공백을 뺀 검색어가 `label`이나 `keywords`의 일부와 맞는 항목만 남깁니다. 대소문자는 구분하지 않고, `value` · `overline` · 그룹 제목은 검색하지 않습니다. 검색어가 비어 있으면 모두 보입니다. 거르기는 `Command`가 받은 `groups` 안에서 하므로, 서버에서 검색한 결과를 넣어도 같은 규칙으로 한 번 더 걸러집니다.
- **그룹**: 남은 항목이 없는 그룹은 제목까지 사라집니다. 검색어가 있는 동안에는 그룹 사이 구분선도 숨깁니다.
- **강조(커서)**: 처음에는 첫 활성 항목을 강조합니다. 검색어를 입력하거나 범위를 바꾸면 다시 첫 활성 항목을 강조하므로, 결과가 남아 있으면 바로 `Enter`로 실행할 수 있습니다.
- **마우스**: 항목에 올리면 강조가 따라옵니다. 키보드와 마우스가 커서 하나를 함께 씁니다. 누르면 `onSelect(value)`를 부릅니다.
- **선택 뒤**: 팔레트를 닫거나 화면을 옮기는 일은 앱이 합니다.

### 행의 상태

| 상태 | 모습 |
| --- | --- |
| 기본 | 채움 없음. 라벨은 `onSurface`, 아이콘 · 단축키 · 윗줄은 `onSurfaceVariant` |
| 강조 | `surfaceContainer` 채움, 아이콘은 `onSurface`. 앞쪽 표시선은 없습니다 |
| hover | 강조가 따라온 위에 `onSurface` 3% 덧칠 |
| 누름 | `onSurface` 12% 덧칠(hover보다 우선). 행은 줄어들지 않습니다 |
| 비활성 | 라벨과 아이콘이 `disabledContent`. 윗줄과 단축키는 Flutter에서만 `disabledContent`이고, Web에서는 `onSurfaceVariant` 그대로입니다. 채움과 덧칠 없이 눌리지 않습니다 |

### 빈 결과

<Preview demo="command/empty" />

보일 항목이 하나도 없으면 목록 대신 `EmptyState`(`compact`)를 그립니다. 제목은 `emptyLabel`, 설명은 `emptyDescription`이며, 적지 않으면 로케일의 기본 문구를 씁니다. `emptyIcon`과 `emptyAction`으로 아이콘과 다음 행동을 더합니다. 빈 상태의 높이는 `fullscreen`을 포함해 최소 240이라, 결과가 사라져도 팔레트가 접혔다 펴지지 않습니다.

### 상태 전환

- `query`와 `scope`는 부모가 들고 있는 값입니다. 콜백을 받은 뒤 부모가 값을 바꾸지 않으면 입력해도 목록이 걸러지지 않습니다.
- 사용자 입력 없이 부모가 `query` · `scope` · `groups`를 바꾸면 강조 위치는 그대로입니다. 항목이 줄면 강조된 행이 없을 수 있고, 그때 `Enter`는 아무 일도 하지 않습니다.
- `Command`에는 열림과 닫힘 상태가 없습니다. 닫아 달라는 요청은 `onDismiss`로 알리고, 실제로 숨기는 것은 팔레트를 담은 쪽입니다.

### 애니메이션

강조 행의 채움은 `highlightDuration`(기본 150ms)으로 바뀝니다. Web은 hover · 누름 덧칠도 같은 시간으로 바뀝니다. 목록이 열리고 닫히는 전환이나 검색 결과의 페이드는 없습니다. 대화상자가 나타나고 사라지는 모션은 [Dialog](/components/dialog)의 것입니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

- 앱의 여러 기능이나 페이지를 한 곳에서 빠르게 찾아 실행하는 커맨드 팔레트를 만들 때
- 항목이 많아 입력으로 거른 뒤 키보드로 고르게 할 때
- 개발자 도구처럼 단축키를 자주 쓰는 사용자를 위한 화면을 만들 때
- 검색어에 따라 그룹으로 묶은 명령 목록을 보여 줄 때

`⌘K` 같은 여는 단축키는 `Command`가 듣지 않습니다. 앱이 등록해 팔레트를 엽니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 폼 값 하나를 목록에서 고를 때 | [Select](/components/select) |
| 입력하는 값에 제안 목록을 붙일 때 | [Autocomplete](/components/autocomplete) |
| 검색 · 그룹 · 범위 없이 버튼에서 여는 짧은 명령 목록 | [DropdownMenu](/components/dropdown-menu) |
| 결과 목록 없이 글자만 받을 때 | [TextField](/components/text-field) |
| 앱 바 · 사이드바에 두는 검색 진입점 | [CommandSearch](/components/command-search) |

<a id="do"></a>
<a id="dont"></a>

### 그룹과 순서

<Cards columns="2">
<Card demo="command/do-grouped" tone="do" eyebrow="이렇게 하세요">

관련 명령은 `heading`이 있는 그룹으로 묶고, 최근에 썼거나 자주 쓰는 명령을 위 그룹에 둡니다. 같은 명령을 두 그룹에 넣을 때는 `value`를 서로 다르게 적습니다.

</Card>
<Card demo="command/dont-flat" tone="dont" eyebrow="이렇게 하지 마세요">

많은 항목을 그룹 없이 한 덩어리로 늘어놓지 않습니다. 원하는 명령을 찾으려면 처음부터 훑어야 합니다.

</Card>
</Cards>

### 결과와 실행

<Cards columns="2">
<Card demo="command/do-empty-action" tone="do" eyebrow="이렇게 하세요">

빈 결과에는 `emptyAction`으로 검색어를 지우는 것 같은 다음 행동을 둡니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요" title="단축키는 적고 따로 등록하기">

자주 쓰는 명령에는 `shortcut`을 적어 익히게 하고, 그 단축키는 앱이 직접 듣고 처리합니다.

```dart
CoreCommandItem(
  value: 'save',
  label: '저장',
  shortcut: 'Ctrl+S',
)
```

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="위험한 명령을 바로 실행하기">

`onSelect`에서 곧바로 삭제하지 않습니다. 팔레트에서는 실수로 고르기 쉬우니 확인 대화상자를 거칩니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요" title="폼 입력으로 쓰기">

`Command`는 고른 값을 들고 있지 않고 폼에 알리지도 않습니다. 값을 고르는 자리에는 `Select`를, 단순한 검색 입력에는 `TextField`나 `Autocomplete`를 씁니다.

</Card>
</Cards>

<a id="조합-예제"></a>

## 배치

### 대화상자로 열기

`dialog` 형태의 팔레트를 `Dialog`의 `content`에 넣습니다. 팔레트가 자기 패널을 그리므로 대화상자의 여백 · 테두리를 없앱니다. 제목이 없어도 본문 위에 머리 간격이 남기 때문에 `sectionGapStyle`도 0으로 두고, `Dialog`의 기본 최대 폭 560을 팔레트의 640에 맞춥니다. 대화상자 자체의 채움과 그림자는 팔레트 뒤에 그대로 남습니다.

```dart
Dialog(
  open: isPaletteOpen,
  onClose: closePalette,
  content: Command(
    presentation: CoreCommandPresentation.dialog,
    query: query,
    onQueryChanged: setQuery,
    onSelect: (value) {
      closePalette();
      runCommand(value);
    },
    onDismiss: closePalette,
    groups: appCommandGroups,
  ),
  dialogStyle: CoreDialogStyle(
    panelPadding: CoreEdgeInsets.zero,
    panelBorderWidth: 0,
    sectionGapStyle: CoreGapStyle(size: 0),
    panelMaxWidth: CoreLayout.layout640,
  ),
)
```

- `onDismiss`와 `onClose`에는 같은 닫기 함수를 줍니다. Web에서는 `Escape` 한 번에 둘 다 불리므로 두 번 불려도 괜찮은 함수여야 하고, Flutter에서는 `onDismiss`가 있으면 `onDismiss`만 불립니다.
- 검색어는 부모가 들고 있으므로, 다음에 빈 검색창으로 열려면 닫는 함수에서 `query`를 비웁니다.
- 제목이 없는 대화상자에는 이름이 없습니다. Web은 `Dialog`의 `attributes`에 `{'aria-label': '명령 팔레트'}`를 주어 이름을 붙입니다.

### 화면 전체로 열기

휴대폰처럼 좁은 화면에서는 `fullscreen` 팔레트를 새 화면(라우트)으로 띄웁니다. `onDismiss`를 주어야 뒤로 버튼이 생기고, 없으면 검색 아이콘이 놓입니다. 터치 화면에서는 48 높이의 `lg`가 누르기 쉽습니다. 기기의 안전 영역은 팔레트를 담는 화면이 비워 둡니다.

```dart
Command(
  presentation: CoreCommandPresentation.fullscreen,
  size: CoreCommandSize.lg,
  query: query,
  onQueryChanged: setQuery,
  onSelect: runCommand,
  onDismiss: closeSearch,
  groups: appCommandGroups,
)
```

- **Flutter**: 남은 높이를 목록이 채우고 푸터는 아래에 붙습니다. 그래서 높이와 폭이 정해진 자리(화면의 본문)에 두어야 합니다. 세로 스크롤 안처럼 높이가 무한한 자리에서는 레이아웃 에러가 납니다.
- **Web**: 목록이 남은 높이를 채우도록 늘어나지 않습니다. 항목이 적으면 팔레트는 내용 높이만큼만 그려지고, 켠 푸터는 목록 바로 아래에 놓입니다.

### 페이지 안에 두기

`inline`은 부모의 폭을 따르며 최소 폭은 240입니다. 부모가 240보다 좁으면 Flutter는 부모 폭에 맞춰 줄고, Web은 240을 지켜 부모 밖으로 넘칩니다. 설정 화면이나 문서 본문에 펼쳐 둘 때는 `autofocus: false`로 두어, 화면이 열릴 때 포커스를 가져가지 않게 합니다. Flutter에서는 폭이 정해진 자리에 둡니다.

### 긴 목록

<Preview demo="command/long-list" />

항목 24개를 넣은 `inline` 팔레트입니다. 목록은 높이 320에서 멈추고, 넘치는 항목은 목록 안에서 스크롤됩니다.

`inline`과 `dialog`는 항목이 목록의 높이 한계를 넘으면 목록만 스크롤되고 검색 줄 · 범위 칩 · 푸터는 제자리에 있습니다. `fullscreen`은 목록의 높이 한계가 없습니다. Flutter는 남은 높이 안에서 목록을 스크롤하고, Web은 팔레트를 담은 화면에 따라 팔레트 전체가 길어질 수 있습니다. 키보드로 강조를 옮기면 그 행이 보이도록 스크롤합니다. 스크롤하는 방식은 두 플랫폼이 다릅니다([플랫폼 차이](#플랫폼-차이)).

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `commandStyle`(`CoreCommandStyle`) 하나로 바꿉니다. 크기 · 형태 · 검색어 같은 동작 값은 위젯 파라미터로 줍니다. 두 플랫폼이 같은 코드를 씁니다.

<Split>

<Code language="dart" title="팔레트 하나만 바꾸기">
Command(
  groups: groups,
  onSelect: runCommand,
  commandStyle: CoreCommandStyle(
    borderRadius: CoreBorderRadius.all(
      CoreRadius.radius16,
    ),
    listMaxHeight: CoreLayout.layout400,
    itemHighlightColor: CoreColor.token(
      CoreColors.surfaceContainerHigh,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    command: CoreCommandTheme(
      style: CoreCommandStyle(
        itemBorderRadius: CoreBorderRadius.all(
          CoreRadius.radius6,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

`CoreCommandStyle`에는 패널 · 검색 줄 · 범위 칩 · 목록 · 행 · 푸터 · 빈 상태의 필드가 있고, 안의 `Chip` · `TextField` · `EmptyState` · `Kbd`에는 각 부품의 스타일을 넣는 필드가 따로 있습니다. 전체 목록은 [API](#api)에서 확인하세요.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `Command`에는 `withStyle`로 스타일을 덧붙일 수 있습니다. `commandStyle`에 주는 것과 같고, 여러 번 이으면 뒤의 값이 이깁니다. `.radius24`처럼 토큰 이름과 같은 getter도 있습니다. 이름이 곧 값(`.radius24`는 `CoreRadius.radius24`)이라 어느 컴포넌트에서 써도 뜻이 같습니다. 모서리 getter는 패널의 `borderRadius`를, 색 getter는 `backgroundColor`를 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CommandChainExample extends StatefulWidget {
  const CommandChainExample({super.key});

  @override
  State<CommandChainExample> createState() => _CommandChainExampleState();
}

class _CommandChainExampleState extends State<CommandChainExample> {
  String _query = '';

  static const List<CoreCommandGroup<Widget>> _groups = [
    CoreCommandGroup(
      heading: '추천',
      items: [
        CoreCommandItem(
          value: 'calendar',
          label: '캘린더',
          icon: Icon(LucideIcons.calendar),
        ),
        CoreCommandItem(
          value: 'search',
          label: '이모지 검색',
          icon: Icon(LucideIcons.smile),
        ),
        CoreCommandItem(
          value: 'calculator',
          label: '계산기',
          icon: Icon(LucideIcons.calculator),
        ),
      ],
    ),
    CoreCommandGroup(
      heading: '설정',
      items: [
        CoreCommandItem(
          value: 'profile',
          label: '프로필',
          icon: Icon(LucideIcons.user),
          shortcut: '⌘P',
        ),
        CoreCommandItem(
          value: 'billing',
          label: '결제',
          icon: Icon(LucideIcons.creditCard),
          shortcut: '⌘B',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(searchPadding)까지 한 번에.
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).withStyle(
          const CoreCommandStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            searchPadding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
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
class CommandChainExample extends StatefulComponent {
  const CommandChainExample({super.key});

  @override
  State<CommandChainExample> createState() => _CommandChainExampleState();
}

class _CommandChainExampleState extends State<CommandChainExample> {
  String _query = '';

  static const List<CoreCommandGroup<Component>> _groups = [
    CoreCommandGroup(
      heading: '추천',
      items: [
        CoreCommandItem(
          value: 'calendar',
          label: '캘린더',
          icon: Icon(LucideIcons.calendar),
        ),
        CoreCommandItem(
          value: 'search',
          label: '이모지 검색',
          icon: Icon(LucideIcons.smile),
        ),
        CoreCommandItem(
          value: 'calculator',
          label: '계산기',
          icon: Icon(LucideIcons.calculator),
        ),
      ],
    ),
    CoreCommandGroup(
      heading: '설정',
      items: [
        CoreCommandItem(
          value: 'profile',
          label: '프로필',
          icon: Icon(LucideIcons.user),
          shortcut: '⌘P',
        ),
        CoreCommandItem(
          value: 'billing',
          label: '결제',
          icon: Icon(LucideIcons.creditCard),
          shortcut: '⌘B',
        ),
      ],
    ),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(searchPadding)까지 한 번에.
        Command(
          query: _query,
          onQueryChanged: (q) => setState(() => _query = q),
          onSelect: (_) {},
          groups: _groups,
        ).withStyle(
          const CoreCommandStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            itemBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            searchPadding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
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

### 값이 정해지는 순서

```text
CoreCommandStyle 의 default 값                  // 크기 · 형태 표에 없는 값
  → CoreCommandStyle.defaultsBySize[size]       // 크기가 정하는 값
  → CoreCommandStyle.defaultsByPresentation[…]  // 형태가 정하는 값
  → CoreCommandTheme.style                      // 앱 전체
  → CoreCommandTheme.variantStyles[variant]
  → commandStyle                                // 팔레트 하나
```

뒤로 갈수록 우선합니다. 글자 · 아이콘 · 간격 스타일은 그 안의 필드끼리 합쳐집니다. 테마에 정한 값은 모든 크기와 형태에 함께 적용되므로, 예를 들어 테마의 `borderRadius`는 `dialog`의 20도 덮습니다.

<a id="접근성-accessibility"></a>

## 접근성

키보드만으로 검색부터 실행까지 할 수 있습니다. 포커스는 검색 입력에 두고, 항목은 강조 행으로 옮겨 다닙니다.

### 역할

| 부분 | Flutter | Jaspr Web |
| --- | --- | --- |
| 팔레트 | 묶음 역할 없음 | 바깥 상자에 `role="combobox"` · `aria-expanded="true"` · `aria-haspopup="listbox"` |
| 검색 입력 | 텍스트 필드 | `aria-autocomplete="list"` · `aria-controls` · `aria-activedescendant` |
| 목록 | 역할 없음 | `role="listbox"` |
| 그룹 제목 | 일반 글자 | `role="presentation"` |
| 항목 | 버튼, 강조 행은 `selected` | `role="option"` · `aria-selected`(강조 행만 `true`) |
| 비활성 항목 | 일반 글자 | `role="option"` · `aria-disabled="true"` · `data-disabled` |
| 범위 칩 | 버튼 | 칩 줄은 `role="group"`, 칩은 버튼과 `aria-pressed` |

Web의 `role` · `aria-expanded` · `aria-haspopup`은 `attributes`로 바꿀 수 없습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `↑` `↓` | 강조를 이전 · 다음 항목으로 옮깁니다. 비활성 항목은 건너뜁니다. 양 끝에서 멈추고, `loopNavigation`이면 반대쪽 끝으로 넘어갑니다 |
| `←` `→` | `scopes`가 있으면 이전 · 다음 범위로 옮깁니다. 없으면 검색 글자의 커서를 옮깁니다 |
| `Home` `End` | 첫 · 마지막 항목으로 옮깁니다. 검색 글자의 커서는 움직이지 않습니다 |
| `Enter` | 강조한 항목의 `onSelect`를 부릅니다 |
| `Escape` | `onDismiss`가 있으면 부릅니다 |
| `Tab` | Web: 검색 입력 → 범위 칩 → (빈 결과의 `emptyAction`) → 팔레트 밖. `fullscreen`의 뒤로 버튼은 검색 입력 앞입니다. 항목은 Tab 순서에 없습니다. 목록이 스크롤될 때는 브라우저에 따라 목록에도 멈출 수 있습니다. Flutter: 검색 입력, 범위 칩, 뒤로 버튼과 `emptyAction`에 더해 활성 항목 하나하나에 멈춥니다 |

Web은 검색 입력에 포커스가 있을 때만 방향키 · `Home` · `End` · `Enter` · `Escape`를 처리합니다. Flutter는 팔레트 안 어디에 포커스가 있어도 방향키 · `Home` · `End` · `Escape`를 처리합니다. `Enter`는 포커스를 가진 컨트롤이 먼저 받습니다. `Tab`으로 항목에 포커스를 옮긴 상태의 `Enter` · `Space`는 강조 행이 아니라 포커스를 가진 항목을 실행합니다. 범위 칩에 포커스가 있을 때 `Enter` · `Space`는 그 범위를 고릅니다.

### 스크린 리더

- 검색 입력의 이름은 안내 글뿐입니다. `<label>` · `aria-label` · `Semantics(label:)`은 따로 붙지 않습니다. 안내 글은 `placeholder`이고, 기본값은 `CoUILocalizations`(Web은 `CouiLocalizations`)의 `commandSearch`입니다(한국어는 "명령어나 검색어를 입력해 주세요"). Flutter에서는 글자를 입력하면 안내 글이 숨어, 이름 없이 읽힐 수 있습니다.
- 항목은 `label`과 함께 `overline` · `shortcut` 글자도 읽힙니다.
- 결과 수가 바뀌거나 빈 결과가 나타나는 것은 따로 알리지 않습니다.
- 푸터는 "이동" · "범위" · "선택" · "닫기" 글자와 `esc` 키캡이 읽힙니다. 화살표와 `Enter` 키캡의 아이콘은 이름이 없습니다.
- `fullscreen`의 뒤로 버튼은 Web에서 "닫기"라는 이름을 갖고, Flutter에서는 이름이 없습니다.
- Flutter의 범위 칩은 어느 것이 선택됐는지 알리지 않고, 비활성 항목은 비활성이라는 상태 없이 글자로만 읽힙니다.

### 포커스 관리

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 처음 | `autofocus`(기본 `true`)면 검색 입력이 포커스를 받습니다 | 같습니다 |
| 키보드 이동 | 포커스는 검색 입력에 두고 강조만 옮깁니다 | 같습니다. `aria-activedescendant`가 강조 행을 가리킵니다 |
| 항목의 포커스 | 항목마다 포커스를 받을 수 있지만 포커스 링은 없습니다 | `tabindex="-1"`이라 `Tab`으로 가지 않습니다 |
| 가두기 · 되돌리기 | `Command`에는 없습니다. `Dialog`에 넣으면 `Tab`이 대화상자 안에서 돌고, 닫으면 포커스가 이전 자리로 돌아갑니다 | `Command`에는 없습니다. `Dialog`에 넣으면 `Tab`이 배경으로 나가지 않지만, 닫아도 연 요소로 포커스를 되돌리지 않습니다 |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 팔레트에는 닫힌 상태가 없습니다. Web의 `aria-expanded="true"`는 늘 그대로이므로, 닫으려면 앱이 팔레트를 화면에서 없애야 합니다. |
| 공통 | 결과 수와 빈 결과를 알리는 영역(live region)이 없습니다. |
| 공통 | 마우스로 항목이나 범위 칩을 누르면 포커스가 검색 입력을 벗어나, 검색 입력을 다시 누를 때까지 방향키가 듣지 않을 수 있습니다. |
| 공통 | `scopes`가 있으면 `←` `→`가, 항상 `Home` `End`가 목록에 쓰여 검색 글자 안에서 커서를 옮기는 데 쓸 수 없습니다. |
| Jaspr Web | 한글처럼 조합해 입력하는 중의 `Enter`에도 강조 항목이 실행될 수 있습니다. 방향키도 조합 중에 강조를 옮길 수 있습니다. |
| Jaspr Web | `combobox` 역할이 검색 입력이 아니라 바깥 상자에 있어, 스크린 리더에 따라 `aria-activedescendant`의 강조 항목을 읽지 않을 수 있습니다. |
| Jaspr Web | 빈 결과에서는 목록 요소가 없어 `aria-controls`가 가리키는 대상이 없습니다. |
| Jaspr Web | 동작 줄이기를 켜도 행의 색 전환 시간(`highlightDuration`, 기본 150ms)이 줄지 않습니다. |
| Jaspr Web | 비활성 행의 윗줄과 단축키가 `disabledContent`가 아니라 `onSurfaceVariant`로 그려져, 그 두 글자는 고를 수 있는 행처럼 보입니다. |
| Flutter | 모든 값이 똑같은 항목(예: 같은 상수 항목을 "최근" 그룹에 다시 넣은 것)이 화면에 두 번 나오면 두 행의 키가 겹쳐 에러가 납니다. `value`를 서로 다르게 적으면 피할 수 있습니다. |
| Flutter | `dialog`가 아닌 형태에서 `onDismiss`와 푸터를 함께 쓰면, 남는 폭이 있어도 푸터의 `esc` 힌트가 오른쪽 끝까지 밀리지 않습니다. 남는 폭 가운데 일부만 앞 힌트와의 사이에 들어갑니다. |
| Flutter | `Tab`이 항목 수만큼 멈추는데 어디에 있는지 보이지 않습니다(WCAG 2.4.7). 항목은 `Command`가 만들어, 앱이 바꿀 방법이 없습니다. |
| Flutter | 팔레트를 감싼 영역에도 `Tab`이 한 번 더 멈출 수 있습니다. |
| Flutter | 팔레트와 목록에는 Web의 `combobox` · `listbox` · `option`에 해당하는 역할을 붙이지 않습니다. 강조 행만 `selected`로 알립니다. |
| Flutter | 선택한 범위 칩과 비활성 항목의 상태를 스크린 리더에 알리지 않고, `fullscreen`의 뒤로 버튼에는 이름이 없습니다. |
| Flutter | 좁은 팔레트에서 범위 칩과 `esc` 힌트가 함께 있는 푸터는 힌트 글자가 여러 줄로 꺾일 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 기본값은 같고, 슬롯 타입은 Flutter의 `Widget`, Web의 `Component`입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 검색으로 거르기 | `CoreCommandItem.matchesQuery` | 같은 Dart 코드를 씁니다 |
| 키를 받는 곳 | 팔레트 안 어디에 포커스가 있어도 | 검색 입력에 포커스가 있을 때 |
| `Tab` 정지점 | 검색 입력 · 범위 칩 · 뒤로 버튼 · `emptyAction` · 활성 항목마다 | 검색 입력 · 범위 칩 · 뒤로 버튼 · `emptyAction` (항목 제외) |
| 긴 라벨과 윗줄 | 줄을 바꿉니다 | 한 줄로 두고 말줄임합니다 |
| 비활성 행의 윗줄 · 단축키 | `disabledContent` | `onSurfaceVariant` 그대로 |
| 모든 값이 같은 항목 두 개 | 키가 겹쳐 에러가 납니다 | 두 행이 함께 강조됩니다 |
| 강조 행을 따라 스크롤 | 강조 행을 위쪽에 맞춰 스크롤합니다. 바깥의 페이지 스크롤도 함께 움직일 수 있습니다 | 행이 가려졌을 때만 가장 가까운 자리까지 스크롤합니다 |
| 푸터의 `esc` 힌트 위치 (`dialog`가 아닌 형태) | 오른쪽 끝까지 밀리지 않고, 앞 힌트에서 조금 떨어진 자리 | 오른쪽 끝 |
| 240보다 좁은 부모의 `inline` | 부모 폭에 맞춰 줄어듭니다 | 240을 지켜 넘칩니다 |
| `fullscreen` 높이 | 받은 높이를 채우고 푸터가 아래에 붙습니다. 높이가 무한한 자리에서는 에러가 납니다 | 목록이 남은 높이를 채우도록 늘어나지 않습니다 |
| `Dialog` 안의 `Escape` | `onDismiss`가 있으면 `onDismiss`만, 없으면 `Dialog`의 `onClose` | `onDismiss`와 `Dialog`의 `onClose`가 함께 불립니다 |
| 동작 줄이기 | 강조 전환이 즉시 바뀝니다 | 행의 색 전환 시간이 그대로입니다 |
| 선택한 범위 칩 | 선택 상태를 알리지 않습니다 | `aria-pressed` |
| `fullscreen` 뒤로 버튼의 이름 | 없음 | `aria-label`에 로케일의 "닫기" |
| 컨테이너 역할 | 없음 | `combobox` · `listbox` · `option` |
| Web 전용 파라미터 | — | `id` · `classes` · `css` · `attributes`와 이벤트 처리기는 팔레트 바깥 상자에 붙습니다 |

<a id="props-parameters"></a>

## API

<a id="command-flutter-web-동일"></a>

### 위젯 파라미터

아래 `W`는 Flutter의 `Widget`, Web의 `Component`입니다. 두 플랫폼 모두 `copyWith`와 `withStyle(CoreCommandStyle patch)`로 바꾼 복사본을 만듭니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `groups` | `List<CoreCommandGroup<W>>` | 필수 | 표시할 그룹. 검색어와 범위로 거릅니다 |
| `variant` | `CoreCommandVariant` | `standard` | 값은 `standard` 하나입니다. 테마의 `variantStyles`를 고르는 데 씁니다 |
| `presentation` | `CoreCommandPresentation` | `inline` | `inline` · `dialog` · `fullscreen`. 겉모습 · 크기 한계 · 푸터 기본값 · 닫기 표시를 정합니다 |
| `size` | `CoreCommandSize` | `md` | `sm` · `md` · `lg` — 행 높이 32 · 40 · 48 |
| `scopes` | `List<CoreCommandScope>` | `[]` | 범위 칩. 비어 있으면 칩 줄을 그리지 않습니다 |
| `scope` | `String?` | `null` | 지금 고른 범위. `null`은 전체 |
| `placeholder` | `String?` | `null` | 검색 입력의 안내 글. `null`이면 로케일 문구 |
| `query` | `String` | `''` | 지금 검색어. 부모가 들고 있습니다 |
| `emptyLabel` | `String?` | `null` | 빈 결과의 제목. `null`이면 로케일 문구(한국어는 "검색 결과가 없어요.") |
| `emptyDescription` | `String?` | `null` | 빈 결과의 설명. `null`이면 로케일 문구(한국어는 "다른 단어로 검색하거나 범위를 전체로 넓혀 보세요.") |
| `emptyIcon` | `W?` | `null` | 빈 결과의 아이콘 |
| `emptyAction` | `W?` | `null` | 빈 결과의 행동. 보통 `Button(variant: CoreButtonVariant.plain)` |
| `autofocus` | `bool` | `true` | 처음에 검색 입력이 포커스를 받을지 |
| `showFooter` | `bool?` | `null` | 키보드 힌트 푸터. `null`이면 `dialog`에서만 보입니다 |
| `loopNavigation` | `bool` | `false` | 목록 끝에서 반대쪽 끝으로 넘어갈지 |
| `onQueryChanged` | `void Function(String)?` | `null` | 검색어를 입력할 때마다 |
| `onScopeChanged` | `void Function(String?)?` | `null` | 칩이나 `←` `→`로 범위를 바꿀 때. 전체는 `null` |
| `onSelect` | `void Function(String)?` | `null` | 항목을 고르면 그 `value`를 받습니다 |
| `onDismiss` | `void Function()?` | `null` | `Escape`와 `fullscreen`의 뒤로 버튼 |
| `commandStyle` | `CoreCommandStyle?` | `null` | 겉모습 덮어쓰기 |

### `CoreCommandGroup`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `heading` | `String?` | `null` | 그룹 제목. `null`이면 제목 줄이 없습니다 |
| `items` | `List<CoreCommandItem<W>>` | 필수 | 그리는 순서대로 놓은 항목 |
| `scope` | `String?` | `null` | 그룹이 속한 범위. `null`이면 모든 범위에서 보입니다 |

### `CoreCommandScope`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `String` | 필수 | `CoreCommandGroup.scope`와 맞추는 식별자 |
| `label` | `String` | 필수 | 칩에 보이는 글자 |

### `CoreCommandItem`

`matchesQuery(query)`는 팔레트가 항목을 거를 때와 같은 규칙으로 검색어에 맞는지(`bool`)를 돌려주는 메서드입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `String` | 필수 | `onSelect`가 받는 식별자 |
| `label` | `String` | 필수 | 행의 글자. 검색 대상 |
| `overline` | `String?` | `null` | 라벨 위의 한 줄. 검색 대상이 아닙니다 |
| `icon` | `W?` | `null` | 라벨 앞 아이콘 |
| `shortcut` | `String?` | `null` | 행 끝의 단축키 글자 |
| `keywords` | `List<String>` | `[]` | 보이지 않는 검색 별칭 |
| `enabled` | `bool` | `true` | 고를 수 있는지 |

### 테마 — `CoreCommandTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreCommandStyle?` | `null` | 앱의 모든 팔레트에 적용합니다 |
| `variantStyles` | `Map<CoreCommandVariant, CoreCommandStyle>?` | `null` | variant별 값. `style` 위에 합칩니다 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCommandStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Panel fill. |
| `borderColor` | `CoreColor?` | Panel border colour. Also the header / footer divider. |
| `borderRadius` | `CoreBorderRadius?` | Panel corner radius — a presentation value (12 · 20 · 0). |
| `borderWidth` | `double?` | Panel border width (logical px). `0` on `fullscreen`. |
| `panelShadow` | `List<CoreShadowLayer>?` | Panel cast — a presentation value (`none` · `lg` · `none`). |
| `panelMinWidth` | `double?` | Panel width floor — `inline` states 240 (`CoreLayout`); the other shapes state none (`0`). |
| `panelMaxWidth` | `double?` | Panel width ceiling — `dialog` states 640 (`CoreLayout`); the other shapes are unbounded (`double.infinity`). |
| `searchPadding` | `CoreEdgeInsets?` | Search row padding. |
| `searchGapStyle` | `CoreGapStyle?` | Gap between the search glyph and the field. |
| `searchIconStyle` | `CoreIconStyle?` | Search glyph style — forwarded to `Icon(iconStyle:)`. |
| `backIconStyle` | `CoreIconStyle?` | Back-affordance glyph in the `fullscreen` header — forwarded to `Icon(iconStyle:)`. |
| `searchInputHeight` | `double?` | Search row height — the size ladder (`CoreControlSize`). |
| `scopePadding` | `CoreEdgeInsets?` | Scope chip row padding. |
| `scopeSpacing` | `double?` | Gap between scope chips (N-sibling, `Wrap.spacing`). |
| `scopeChipStyle` | `CoreChipStyle?` | Style for the scope chips, passed to each `Chip` as is. |
| `searchFieldStyle` | `CoreTextFieldStyle?` | Style of the embedded search field. |
| `listPadding` | `CoreEdgeInsets?` | Item-list outer padding — a presentation value (8 on every shape). |
| `listSpacing` | `double?` | Gap between the list's children — headings, rows and group dividers (N-sibling, `Column.spacing` / flex `gap`). |
| `listMinHeight` | `double?` | List height floor so the panel does not jump when results vanish (`CoreLayout.layout240`; `0` on `fullscreen`). |
| `listMaxHeight` | `double?` | List scroll ceiling — a presentation value (`CoreLayout.layout320` · `layout400` · `double.infinity`). |
| `headingPadding` | `CoreEdgeInsets?` | Group-heading padding — a size value. |
| `itemPadding` | `CoreEdgeInsets?` | Row inner padding — a size value. |
| `itemMinHeight` | `double?` | Row height floor — the size ladder (`CoreControlSize`). Two-line rows grow past it. |
| `itemBorderRadius` | `CoreBorderRadius?` | Row highlight radius (8 on every size and presentation — a row the panel hosts, see [defaultItemBorderRadius]). |
| `itemGapStyle` | `CoreGapStyle?` | Gap between a row's icon and label, and between its label and shortcut. |
| `itemIconStyle` | `CoreIconStyle?` | Style of each row's icon at rest — the caller's `item.icon` inherits its size and colour. A disabled row's icon takes [itemDisabledForegroundColor]. |
| `itemActiveIconStyle` | `CoreIconStyle?` | Icon style on the active row, merged over [itemIconStyle] — only what changes on the keyboard cursor (the colour, `on-surface`). |
| `itemHighlightColor` | `CoreColor?` | Active-row fill — the keyboard cursor (`surface-container`), the only fill the active row carries. |
| `itemHoverColor` | `CoreColor?` | Hover wash over the row — `on-surface` at `opacity/hover`. |
| `itemPressedColor` | `CoreColor?` | Pressed wash over the row — `on-surface` at `opacity/pressed`. |
| `itemTextStyle` | `CoreTextStyle?` | Row label style carrying the row foreground colour. |
| `itemForegroundColor` | `CoreColor?` | Resting row foreground — the label text. The row's icon takes [itemIconStyle]'s colour. |
| `itemDisabledForegroundColor` | `CoreColor?` | Disabled row foreground — a colour token (`disabled-content`), not an alpha. |
| `itemClickableStyle` | `CoreClickableStyle?` | Style for each row's `Clickable`. |
| `highlightDuration` | `Duration?` | Active-row fill transition. |
| `footerPadding` | `CoreEdgeInsets?` | Footer padding — a size value. |
| `footerSpacing` | `double?` | Footer hint spacing. |
| `emptyPadding` | `CoreEdgeInsets?` | Padding around the composed `EmptyState`. |
| `emptyStateStyle` | `CoreEmptyStateStyle?` | Style for the `EmptyState`, passed to it as is. Its default `minHeight` is `CoreLayout.layout240`, the same floor the list has. |
| `kbdStyle` | `CoreKbdStyle?` | Style for the footer key caps, passed to each `Kbd`. |
| `footerKbdIconStyle` | `CoreIconStyle?` | Footer key-cap glyph style. |
| `labelStyle` | `CoreTextStyle?` | Row label typography role (colour-free; the colour is per state) — a size value. |
| `overlineStyle` | `CoreTextStyle?` | Row overline (category above the label) — a size value. Its colour is the field-level default (`on-surface-variant`). |
| `itemTitleStyle` | `CoreTextStyle?` | Row label when an overline is present — a body role at the same weight as the one-line label (the overline above is the quieter line) — a size value. |
| `headingStyle` | `CoreTextStyle?` | Group heading typography. |
| `shortcutStyle` | `CoreTextStyle?` | Shortcut hint typography (sans, `bodyXs`, `on-surface-variant`). |
| `footerStyle` | `CoreTextStyle?` | Footer hint typography. |
| `footerBackgroundColor` | `CoreColor?` | Footer fill. |
| `placeholderColor` | `CoreColor?` | Search glyph colour (`on-surface-variant`). The placeholder text itself is the composed `TextField`'s. |

<!-- STYLE_TABLE:END -->

<Note>

몇 필드는 지금 위 설명과 다르게 동작합니다.

- `borderColor`는 팔레트 테두리만 바꿉니다. 안의 구분선은 `Divider`의 색(기본 `outlineVariant`)을 그대로 씁니다.
- `itemTextStyle`에서 읽는 것은 `color` 하나입니다(`itemForegroundColor`를 주면 그 값이 우선합니다). 라벨의 글자 모양은 `labelStyle`과 `itemTitleStyle`로 바꿉니다.
- `searchIconStyle`의 `color`는 쓰이지 않습니다. 검색 아이콘의 색은 `placeholderColor`로 바꿉니다.
- `itemDisabledForegroundColor`는 Web에서 비활성 행의 라벨과 아이콘에만 적용됩니다. 윗줄과 단축키는 `overlineStyle` · `shortcutStyle`의 색을 그대로 씁니다.
- 항목 아이콘에는 크기와 색만 전달됩니다. 강조 행에서 `itemActiveIconStyle`의 `size`는 Web에서만 적용되고, Flutter는 `color`만 씁니다.
- `kbdStyle`은 푸터 키캡뿐 아니라 `dialog` 검색 줄의 `esc` 키캡에도 적용됩니다.
- `highlightDuration`은 Web에서 동작 줄이기를 켜도 줄지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="CommandSearch" href="/components/command-search" more="CommandSearch 보기">

검색 입력처럼 생긴 버튼입니다. 앱 바나 사이드바에 두고, 누르면 앱이 팔레트를 엽니다.

</Card>
<Card title="Dialog" href="/components/dialog" more="Dialog 보기">

팔레트를 화면 위에 모달로 띄웁니다.

</Card>
<Card title="Kbd" href="/components/kbd" more="Kbd 보기">

푸터와 `esc` 힌트를 그리는 키캡입니다.

</Card>
<Card title="Autocomplete" href="/components/autocomplete" more="Autocomplete 보기">

입력하는 값에 제안 목록을 붙입니다.

</Card>
<Card title="DropdownMenu" href="/components/dropdown-menu" more="DropdownMenu 보기">

버튼에서 여는 짧은 명령 목록입니다.

</Card>
<Card title="TextField" href="/components/text-field" more="TextField 보기">

결과 목록 없이 글자만 받을 때 씁니다.

</Card>
</Cards>
