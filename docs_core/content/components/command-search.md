---
title: CommandSearch
description: 커맨드 팔레트를 여는 트리거 — 검색처럼 생긴 버튼
category: control
platforms: [flutter, web]
related: [command, kbd, app-bar, navigation-bar]
tags: [interactive, control]
template: v2
source: control/command_search
---

# CommandSearch

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 CommandSearch 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="command-search" />

CommandSearch 는 검색 필드처럼 생긴 **버튼**입니다. 글자를 입력받지 않고, 누르면 `onPressed` 를 부를 뿐 스스로는 아무것도 열지 않습니다. 검색 입력과 결과 목록은 앱이 `onPressed` 에서 여는 [Command](/components/command) 가 맡습니다([팔레트 열기](#팔레트-열기)). 폭은 스스로 정하지 않고 부모의 폭을 채웁니다([배치](#배치)).

<Note>

CommandSearch 의 채움은 `surfaceContainer` 색이고 테두리가 없어, 같은 색 바탕에서는 상자가 보이지 않습니다. 플레이그라운드의 트리거를 눌러도 팔레트는 열리지 않습니다.

</Note>

<a id="구조-anatomy"></a>

## 구조

시작 쪽부터 앞 아이콘, 안내 글, 단축키를 차례로 놓습니다. 칸 사이는 같은 간격(`contentGapStyle`)입니다. 안내 글이 남은 폭을 모두 차지하고, 넘치면 말줄임합니다. 오른쪽에서 왼쪽으로 쓰는 로케일에서는 순서와 좌우 여백이 함께 뒤집힙니다.

<Anatomy demo="command-search/anatomy">
<AnatomyItem select="[role=button]" side="left" name="container">

누를 수 있는 둥근 상자 전체입니다. 높이는 크기에 따라 32 · 40 · 48 이고, 채움만 있고 테두리는 없습니다. 입력 칸이 아니라 버튼이라 입력 칸 같은 테두리를 두지 않습니다. 검색 · 명령으로 들어가는 입구라는 것은 앞 아이콘 · 안내 글 · 단축키가 알려 줍니다.

</AnatomyItem>
<AnatomyItem part="leading" side="top" name="leading">

앞 아이콘. 넘기지 않으면 검색 아이콘입니다.

</AnatomyItem>
<AnatomyItem part="label" side="top" name="hint">

안내 글. 넘기지 않으면 활성 로케일의 명령 검색 안내 문구입니다.

</AnatomyItem>
<AnatomyItem select="[role=img]" side="right" name="shortcut">

단축키 표시. 보통 [Kbd](/components/kbd) 를 넣고, 넘기지 않으면 이 칸이 없습니다.

</AnatomyItem>
</Anatomy>

Figma: [`❖ CommandSearch`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)

## 팔레트 열기

CommandSearch 는 눌렸다는 것만 알립니다. 팔레트는 앱이 엽니다. 보통 [Dialog](/components/dialog) 안에 `presentation: CoreCommandPresentation.dialog` 인 `Command` 를 둡니다. 두 곳에 같은 `size` 를 넘기면 트리거와 팔레트가 같은 크기 단계를 씁니다. `commandGroups` 는 앱이 만드는 `List<CoreCommandGroup<Widget>>`(Web 은 `List<CoreCommandGroup<Component>>`)입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// State 의 필드: bool _open = false; String _query = '';
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    CommandSearch(
      shortcut: const Kbd(keys: ['⌘K']),
      onPressed: () => setState(() => _open = true),
    ),
    Dialog(
      open: _open,
      onClose: () => setState(() => _open = false),
      dialogStyle: const CoreDialogStyle(
        panelPadding: CoreEdgeInsets.all(CoreSpace.space0),
        panelMaxWidth: CoreLayout.layout640,
      ),
      content: Command(
        presentation: CoreCommandPresentation.dialog,
        query: _query,
        onQueryChanged: (query) => setState(() => _query = query),
        onSelect: (value) => setState(() => _open = false),
        onDismiss: () => setState(() => _open = false),
        groups: commandGroups,
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// State 의 필드: bool _open = false; String _query = '';
div([
  CommandSearch(
    shortcut: const Kbd(keys: ['⌘K']),
    onPressed: () => setState(() => _open = true),
  ),
  Dialog(
    open: _open,
    onClose: () => setState(() => _open = false),
    dialogStyle: const CoreDialogStyle(
      panelPadding: CoreEdgeInsets.all(CoreSpace.space0),
      panelMaxWidth: CoreLayout.layout640,
    ),
    content: Command(
      presentation: CoreCommandPresentation.dialog,
      query: _query,
      onQueryChanged: (query) => setState(() => _query = query),
      onSelect: (value) => setState(() => _open = false),
      onDismiss: () => setState(() => _open = false),
      groups: commandGroups,
    ),
  ),
])
```

  </TabItem>
</Tabs>

`shortcut` 은 화면에 키를 보여 줄 뿐 키를 등록하지 않습니다. `⌘K` 를 누르면 팔레트가 열리게 하려면, 앱이 키 입력을 직접 듣고 `onPressed` 와 같은 동작을 부릅니다.

<a id="변형-variants"></a>
<a id="안내-글-앞-글리프-바꾸기"></a>

## 안내 글 · 아이콘 · 단축키

<Preview demo="command-search/content" />

| 칸 | 넘기지 않으면 | 넘기면 |
| --- | --- | --- |
| `hint` | 활성 로케일의 명령 검색 안내 문구(한국어는 "명령어나 검색어를 입력해 주세요")입니다. `placeholder` 를 주지 않은 `Command` 의 검색 입력에 보이는 문구와 같습니다 | 그 글을 한 줄로 보이고, 넘치면 말줄임합니다 |
| `leading` | 검색 아이콘 | 넘긴 위젯을 그립니다. `Icon` 이면 트리거의 아이콘 크기와 색을 받습니다. `iconStyle` 에 크기나 색을 직접 정한 아이콘은 그 값을 씁니다 |
| `shortcut` | 칸이 없습니다 | 끝에 그립니다. 트리거는 이 위젯의 모양과 색을 바꾸지 않습니다 |

`leading` 에 넣은 이미지처럼 아이콘이 아닌 위젯은 크기와 색을 받지 않을 수 있습니다. 트리거가 이미 버튼이므로 `leading` 과 `shortcut` 에는 버튼처럼 누르거나 포커스를 받는 요소를 넣지 않습니다.

```dart
CommandSearch(
  hint: '일정 검색',
  leading: const Icon(LucideIcons.calendar),
  onPressed: openCommandPalette,
)
```

## 크기

`size` 는 `Command` 와 같은 `CoreCommandSize`(`sm` · `md` · `lg`)이고, 기본은 `md` 입니다.

<SizeSpec component="command-search" props="hint=검색;shortcut=⌘K;width=200;backdrop=surface" />

- 높이는 앱의 밀도(`CoreDensity`)를 따릅니다. `spacious` 는 한 단 높이고, `compact` 는 한 단 낮추되 32 아래로는 내리지 않습니다. 모서리(높이의 1/4), 좌우 여백, 칸 사이 간격도 밀도에 따라 움직입니다. 아이콘 크기와 글자 크기는 그대로입니다. `commandSearchStyle.height` 로 직접 정한 높이는 밀도가 바꾸지 않습니다.
- 좌우 여백은 시작 쪽과 끝 쪽으로 정해져 글 방향에 따라 뒤집힙니다. 끝 여백이 더 작은 것은 끝에 놓는 `Kbd` 가 자기 여백을 갖기 때문입니다.
- 안내 글의 글자 역할은 `sm` 이 `bodySmall`, `md` 가 `bodyMedium`, `lg` 가 `bodyLarge` 입니다. 표의 글자 크기와 굵기는 기본 글자 스케일의 값입니다.

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>

## 상태

<Preview demo="command-search/states" />

hover · 포커스 · 눌림은 위 플레이그라운드에서 확인하세요. 세 상태는 채움을 바꾸지 않고, 채움 위에 `onSurface` 덮개를 씌워 보여 줍니다.

| 상태 | 모양 |
| --- | --- |
| 기본 | 채움 `surfaceContainer`, 앞 아이콘 · 안내 글 `onSurfaceVariant`, 테두리 없음. 커서는 손 모양입니다 |
| Hover | `onSurface` 8% 덮개 |
| 키보드 포커스 | `onSurface` 8% 덮개와, 상자에서 2 떨어진 굵기 2 의 `focusRing` 색 링 |
| 눌림 | `onSurface` 12% 덮개. 상자가 97% 크기로 줄었다가 돌아옵니다 |
| 비활성 | 채움 `disabledContainer`, 앞 아이콘 · 안내 글 `disabledContent`. 덮개 · 링 · 줄어드는 반응이 없고 커서는 금지 모양입니다 |

- 상태가 겹치면 덮개는 하나만 칠합니다. 눌림이 포커스보다, 포커스가 hover 보다 우선합니다.
- 포커스 덮개가 hover 와 같은 8% 인 것은, 포커스는 주로 링으로 알리고 덮개는 거드는 표시이기 때문입니다.
- 앞 아이콘 · 안내 글에 `onSurfaceVariant` 를 쓰는 것은, 덮개가 채움 위에 씌워진 상태에서도 글이 읽히게 하려는 것입니다.
- 클릭 · 탭이나 `Enter` · `Space` 로 누르면 `onPressed` 를 부릅니다.
- `enabled` 를 넘기지 않으면 `onPressed` 가 있을 때 활성입니다. 비활성 상태는 위의 비활성 색으로 보입니다. 이 색이 이미 비활성임을 보여 주므로 상자를 따로 흐리게 하지 않습니다.
- 덮개는 Flutter 에서 전환 없이 바로 바뀝니다. Web 에서는 `CoUIWeb` 의 테마 전환(`enableThemeAnimation`, 기본으로 켜짐)이 덮개 색에도 걸려 150ms 동안 바뀝니다(동작 줄이기를 켜면 바로 바뀝니다).
- Flutter 에서 `size` 나 `commandSearchStyle` 을 바꿔 상자의 높이 · 채움 · 모서리가 달라지면 150ms 동안 이어지며 바뀝니다(동작 줄이기를 켜면 바로 바뀝니다). 활성과 비활성을 오갈 때는 전환 없이 바로 바뀝니다.
- 상자가 줄어드는 반응은 100ms 이고, 포커스 링은 Flutter 150ms, Web 100ms 동안 나타나고 사라집니다. 동작 줄이기를 켜면 이 전환들은 바로 끝납니다.
- 줄어드는 반응을 끄려면 `commandSearchStyle` 의 `clickableStyle` 에 `CoreClickableStyle(pressedScale: 1)` 을 줍니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

앱 바 가운데 칸이나 사이드바 위처럼, 검색 · 명령으로 들어가는 입구를 하나 두고 누르면 `Command` 를 대화상자로 열 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 검색 입력과 결과 목록을 화면에 바로 펼쳐 둘 때 | [Command](/components/command) |
| 그 자리에서 바로 글자를 입력받을 때 | [TextField](/components/text-field) |

<a id="do"></a>
<a id="dont"></a>

### 놓는 바탕과 입구

<Cards columns="2">
<Card demo="command-search/do-on-surface" tone="do" eyebrow="이렇게 하세요">

앱 바나 사이드바의 바탕처럼 `surface` · `surfaceContainerLow` 인 면에 놓습니다. 트리거의 채움과 색이 달라 누를 수 있는 상자가 보입니다.

</Card>
<Card demo="command-search/dont-on-container" tone="dont" eyebrow="이렇게 하지 마세요">

`surfaceContainer` 면 위에는 놓지 않습니다. 채움이 같고 테두리가 없어 상자가 사라집니다.

</Card>
<Card demo="command-search/do-same-size" tone="do" eyebrow="이렇게 하세요">

트리거와 여는 `Command` 에 같은 `size` 를 넘깁니다. 트리거의 높이와 팔레트의 검색 입력 · 한 줄 항목 행의 높이가 같은 단계(32 · 40 · 48)가 되어, 누른 자리와 열린 팔레트가 같은 크기로 읽힙니다. 그림은 `sm` 입니다.

</Card>
<Card demo="command-search/dont-readonly-field" tone="dont" eyebrow="이렇게 하지 마세요">

읽기 전용 `TextField` 를 트리거로 쓰지 않습니다. 버튼이 아니라 읽기 전용 입력 칸으로 읽혀, 누르면 무언가 열린다는 것이 전해지지 않습니다. `CommandSearch` 는 버튼으로 알려지고 탭 정지 하나만 차지합니다.

</Card>
</Cards>

트리거와 팔레트에 같은 `size` 를 넘기는 코드는 다음과 같습니다. `openPalette` 는 팔레트를 여는 앱의 함수입니다.

```dart
CommandSearch(
  size: CoreCommandSize.sm,
  onPressed: () => openPalette(
    size: CoreCommandSize.sm,
  ),
)
```

<a id="조합-예제"></a>

## 배치

폭은 부모가 정합니다. 폭을 정하는 속성은 없습니다. Flutter 에서는 폭이 정해진 자리(`Expanded`, `SizedBox`, 앱 바의 가운데 칸)에 놓습니다. `Row` 에 그대로 넣으면 폭이 정해지지 않아 레이아웃 오류가 납니다. Web 에서는 부모 폭을 채웁니다.

<Preview demo="command-search/narrow" />

폭이 좁으면 안내 글이 말줄임되고, 앞 아이콘과 단축키는 그대로 남습니다.

### 앱 바에 놓기

<Preview demo="command-search/in-app-bar" />

[AppBar](/components/app-bar) 의 `child` 에 넣으면 제목 자리를 대신하고, 앞뒤 버튼을 뺀 남은 폭을 채웁니다.

```dart
AppBar(
  leading: [menuButton],
  child: CommandSearch(
    shortcut: const Kbd(keys: ['⌘K']),
    onPressed: openCommandPalette,
  ),
)
```

`centerTitle: true` 를 함께 주면 두 플랫폼의 폭이 달라질 수 있습니다. Flutter 는 앞뒤 버튼 묶음 가운데 넓은 쪽의 폭을 양쪽에서 똑같이 뺀 폭을 채우고, Web 은 안쪽 내용이 차지하는 만큼의 폭이 될 수 있습니다. 가운데에 같은 폭으로 놓으려면 폭을 정한 `SizedBox`(Web 은 폭을 정한 `div`)로 감쌉니다.

<a id="스타일-시스템-style-system"></a>
<a id="commandsearchstyle"></a>
<a id="사용-예"></a>

## 테마와 스타일

크기 · 내용 · 활성 여부 · 눌렀을 때의 동작은 위젯 속성(`size` · `hint` · `leading` · `shortcut` · `enabled` · `onPressed`)으로 정하고, 색 · 높이 · 여백 · 칸 사이 간격 · 모서리 · 앞 아이콘 · 안내 글 · 상태 덮개 · 포커스 링은 `commandSearchStyle`(`CoreCommandSearchStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="트리거 하나만 바꾸기">
CommandSearch(
  onPressed: openCommandPalette,
  commandSearchStyle: const CoreCommandSearchStyle(
    backgroundColor: CoreColor.token(
      CoreColors.surfaceContainerHigh,
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    commandSearch: CoreCommandSearchTheme(
      style: CoreCommandSearchStyle(
        borderRadius: CoreBorderRadius.all(
          CoreRadius.radius9999,
        ),
      ),
    ),
  ),
)
</Code>

</Split>

- `leadingIconStyle` · `hintTextStyle` · `contentGapStyle` 은 크기별 기본값 위에 적은 항목만 바꿉니다. `height` · `padding` · `borderRadius` 처럼 값 하나인 필드는 통째로 바꾸고, 정한 값은 모든 `size` 에 그대로 쓰입니다.
- `leadingIconStyle` 과 `hintTextStyle` 의 색은 `foregroundColor` 보다 우선합니다. 비활성일 때는 두 색과 상관없이 `disabledForegroundColor` 를 씁니다.
- `borderRadius` 는 상자, 덮개, 포커스 링의 모서리를 함께 바꿉니다.

### 빠른 오버라이드 (Chain)

이미 만든 `CommandSearch` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `commandSearchStyle` 인자와 같게 동작합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CommandSearchChainExample extends StatelessWidget {
  const CommandSearchChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout320,
      child:
          CommandSearch(
            hint: '문서 검색',
            shortcut: const Kbd(keys: ['⌘K']),
            onPressed: () {},
          ).withStyle(
            const CoreCommandSearchStyle(
              backgroundColor: CoreColor.token(
                CoreColors.surfaceContainerHigh,
              ),
              contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
            ),
          ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class CommandSearchChainExample extends StatelessComponent {
  const CommandSearchChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        CommandSearch(
          hint: '문서 검색',
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ).withStyle(
          const CoreCommandSearchStyle(
            backgroundColor: CoreColor.token(
              CoreColors.surfaceContainerHigh,
            ),
            contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
          ),
        ),
      ],
      classes: 'w-${CoreLayout.scale.layout320}',
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (defaultsBySize[size] · default*)
  → CoreComponentTheme.commandSearch.style   // 앱 전체
  → commandSearchStyle                       // 트리거 하나
```

뒤로 갈수록 우선합니다. 트리거를 누르게 하는 안쪽 `Clickable` 은 앱의 `CoreClickableTheme` 을 먼저 받고, 그 위에 트리거의 모서리, 비활성 불투명도 1, `clickableStyle` 이 얹힙니다. 그래서 `CoreClickableTheme` 에서 바꾼 눌림 크기는 트리거에도 적용되지만, 비활성 불투명도는 적용되지 않습니다. 앞 아이콘은 `Icon` 의 규칙도 따라서, 앱의 `CoreIconTheme` 에 크기나 색을 정해 두면 그 값이 트리거의 값보다 우선합니다. 색을 정해 두었다면 비활성일 때의 앞 아이콘도 그 색으로 보입니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 버튼(`Semantics` 의 `button`)과 활성 여부를 알립니다. 입력 칸으로 알리지 않습니다. |
| Jaspr Web | `role="button"` 입니다. 활성이면 `tabindex="0"`, 비활성이면 `tabindex` 없이 `aria-disabled="true"` 입니다. |

두 플랫폼 모두 누르면 무엇이 열리는지는 알리지 않습니다. Web 에서는 `attributes` 로 `'aria-haspopup': 'dialog'` 나 `'aria-keyshortcuts': 'Meta+K'` 를 더할 수 있습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 트리거는 탭 정지 하나입니다. 비활성이면 건너뜁니다. |
| `Enter` · `Space` | `onPressed` 를 부릅니다. |
| `⌘K` 같은 단축키 | 트리거는 처리하지 않습니다. 앱이 듣습니다. |

### 스크린 리더

접근 가능한 이름은 트리거 안의 글자에서 옵니다. 안내 글과 `shortcut` 에 넣은 `Kbd` 의 키 이름이 함께 이름이 됩니다. `Kbd(keys: ['Ctrl', 'K'])` 는 "Ctrl K" 로 묶어 알립니다. 앞 아이콘에는 이름이 없습니다. Web 에서는 `attributes` 의 `aria-label` 로 이름을 바꿀 수 있습니다. 상태가 바뀐 것을 알리는 라이브 리전은 없습니다.

### 포커스 관리

- 트리거는 포커스를 옮기거나 가두지 않습니다.
- 포커스 링과 포커스 덮개는 키보드로 포커스했을 때 나타납니다. Web 은 브라우저의 `:focus-visible` 을 따르고, Flutter 는 프레임워크가 포커스 강조를 보이는 입력 방식일 때만 보입니다(터치 방식에서는 보이지 않습니다).
- 팔레트를 닫은 뒤의 포커스는 팔레트를 연 쪽이 정합니다. Flutter 의 `Dialog` 는 닫히면 포커스가 열기 전 자리로 돌아갑니다. Web 의 `Dialog` 는 연 요소로 포커스를 되돌리지 않으므로, 필요하면 앱이 트리거로 옮깁니다. `CommandSearch` 의 `id` 는 버튼 요소에 붙습니다.
- `Command` 는 기본값(`autofocus: true`)이면 열릴 때 검색 입력에 포커스를 둡니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 비활성이어도 `shortcut` 의 `Kbd` 는 자기 채움과 글자색을 그대로 씁니다. |
| 공통 | `shortcut` 은 표시만 하고 단축키를 등록하지 않습니다. |
| 공통 | 채움이 `surfaceContainer` 이고 테두리가 없어, 같은 색 바탕 위에서는 상자의 경계가 보이지 않습니다. |
| 공통 | 서페이스 스타일의 재질(반투명 · 흐림 · 재질의 테두리와 그림자)은 트리거의 면에 적용되지 않습니다. 모서리 같은 모양 값은 따릅니다. |
| Jaspr Web | 색 강제 모드에서는 테두리가 없어 상자의 경계가 보이지 않습니다. |
| Jaspr Web | `eventHandlers` 에 넣은 `click` · `keydown` · `keyup` · `mousedown` · `mouseup` · `mouseenter` · `mouseleave` · `focusout` 은 버튼 동작이 같은 이름을 써서 불리지 않습니다. 누름은 `onPressed` 로 받습니다. |
| Jaspr Web | `Enter` · `Space` 로 눌러도 상자는 줄어들지만(`Enter` 는 잠깐), 덮개는 눌림 값(12%)이 되지 않고 포커스 값(8%)에 머뭅니다. |
| Jaspr Web | 기본 스타일에서는 상태 덮개가 안의 아이콘 · 안내 글 · 단축키 위에 겹쳐, 그 색에도 덮개 색이 옅게 섞입니다. 가장자리 빛을 그리는 서페이스 스타일(`liquidGlass` 류)에서는 `Kbd` 키가 덮개 위에 그려질 수 있습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

속성의 이름 · 순서 · 기본값은 두 플랫폼이 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `leading` · `shortcut` 타입 | `Widget?` | `Component?` |
| 폭 | 폭이 정해지지 않은 부모(`Row` 등)에 놓으면 레이아웃 오류 | 부모 폭을 채웁니다 |
| 상태 덮개 | 위젯이 hover · 포커스 · 눌림을 감지해 덮개를 그립니다 | CSS `:hover` · `:focus-visible` · `:active` 가 덮개를 칠합니다 |
| 덮개가 놓이는 층 | 아이콘 · 안내 글 · 단축키 아래에 칠합니다 | 덮개 요소가 위에 놓여, 기본 스타일에서는 아이콘 · 안내 글 · 단축키에도 옅게 겹칩니다 |
| 덮개 전환 | 바로 바뀝니다 | `CoUIWeb` 의 테마 전환이 켜져 있으면 150ms 동안 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다 |
| 키보드로 누를 때 | 덮개가 잠깐 눌림 값(12%)이 되고 상자가 줄어듭니다 | 상자는 줄지만(`Enter` 는 잠깐, `Space` 는 누르는 동안) 덮개는 눌림 값이 되지 않습니다 |
| 포커스 링 전환 | 150ms | 100ms |
| `clickableStyle.borderRadius` 만 줄 때 | 포커스 링의 모서리만 바뀝니다 | 상자 · 덮개 · 링의 모서리가 함께 바뀝니다 |
| `borderRadius` 와 함께 줄 때 | 상자는 `borderRadius`, 링은 `clickableStyle.borderRadius` | 모두 `borderRadius` |
| 알파가 있는 `stateLayerColor` | 색의 알파를 버리고 `stateLayer` 값을 알파로 씁니다 | 색의 알파에 `stateLayer` 값을 곱합니다 |
| 앱 바의 `centerTitle` | 남은 폭을 채웁니다 | 안쪽 내용만큼의 폭이 될 수 있습니다 |
| HTML 속성 · DOM 이벤트 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter 와 Jaspr Web 이 같은 속성을 씁니다. `Widget?` 은 Web 에서 `Component?` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `size` | `CoreCommandSize` | `md` | sm · md · lg (높이 32 · 40 · 48) |
| `hint` | `String?` | `null` | 안내 글. 없으면 활성 로케일의 명령 검색 안내 문구 |
| `leading` | `Widget?` | `null` | 앞 아이콘. 없으면 검색 아이콘 |
| `shortcut` | `Widget?` | `null` | 끝의 단축키 표시. 보통 `Kbd`. 키는 등록하지 않습니다 |
| `enabled` | `bool?` | `null` | 누를 수 있는지. 없으면 `onPressed != null` |
| `onPressed` | `void Function()?` | `null` | 눌렀을 때. 앱이 여기서 팔레트를 엽니다 |
| `commandSearchStyle` | `CoreCommandSearchStyle?` | `null` | 겉모습 덮어쓰기 |

Web 은 여기에 `id` · `classes` · `css` · `attributes` · `eventHandlers` 를 더 받고, 버튼 요소에 붙입니다. `attributes` 에 준 값은 트리거가 정한 `role` · `tabindex` 보다 우선합니다. 두 플랫폼 모두 `copyWith` 와 `withStyle(CoreCommandSearchStyle patch)` 가 있고, `withStyle` 을 이어 부르면 같은 필드는 나중 값이 이깁니다.

### 테마 — `CoreCommandSearchTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreCommandSearchStyle?` | `null` | 앱의 모든 CommandSearch 에 깔리는 값. variant 가 없어 variant 별 값은 없습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCommandSearchStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `height` | `double?` | Trigger height (logical px). `null` → the size ladder, which a theme density moves one rung; a height stated here stays as stated. |
| `padding` | `CoreEdgeInsets?` | Content insets — directional, start and end. `null` → the size ladder. |
| `contentGapStyle` | `CoreGapStyle?` | Gap between the leading glyph, the hint and the shortcut. `null` → the size ladder. |
| `borderRadius` | `CoreBorderRadius?` | Corner radius — also the focus ring's corner. `null` → the size row's corner (the height × 0.25). |
| `leadingIconStyle` | `CoreIconStyle?` | Look of the leading glyph — its size, and a colour that wins over [foregroundColor] at rest. `null` → the size ladder. |
| `hintTextStyle` | `CoreTextStyle?` | Hint typography — role, and a colour that wins over [foregroundColor] at rest. `null` → the size ladder. |
| `backgroundColor` | `CoreColor?` | Resting face. `null` → [defaultBackgroundColor]. |
| `foregroundColor` | `CoreColor?` | Ink of the leading glyph and the hint. `null` → [defaultForegroundColor]. |
| `disabledBackgroundColor` | `CoreColor?` | Face while disabled. `null` → [defaultDisabledBackgroundColor]. |
| `disabledForegroundColor` | `CoreColor?` | Ink while disabled — the glyph and the hint. `null` → [defaultDisabledForegroundColor]. |
| `stateLayerColor` | `CoreColor?` | Colour washed over the face on hover / focus / press. `null` → [defaultStateLayerColor]. |
| `stateLayer` | `CoreStateLayer?` | How strongly [stateLayerColor] is washed over the face per state. `null` → [defaultStateLayer]. A disabled trigger takes no wash. |
| `clickableStyle` | `CoreClickableStyle?` | Style of the trigger's `Clickable` — focus ring, press feedback. `null` → [defaultClickableStyle]. Passed to the `Clickable` as is; the focus ring takes the trigger's corner unless this sets one. |

<!-- STYLE_TABLE:END -->

<Note>

표의 기본값 가운데 크기에 따라 달라지는 값은 [크기](#크기)의 표에 있습니다. 나머지 기본값은 채움 `surfaceContainer`, 앞 아이콘 · 안내 글 `onSurfaceVariant`, 비활성 `disabledContainer` · `disabledContent`, 덮개 색 `onSurface`, 덮개 세기 hover 8% · 포커스 8% · 눌림 12% 이고, `clickableStyle` 의 기본값은 비활성 불투명도 1(흐리지 않음)입니다. 지금 Web 은 `borderRadius` 를 적으면 `clickableStyle.borderRadius` 보다 그 값을 우선해 링을 그리고, Flutter 는 `stateLayerColor` 의 알파를 쓰지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Command" href="/components/command" more="Command 보기">

이 트리거가 여는 검색 입력과 명령 목록입니다.

</Card>
<Card title="Kbd" href="/components/kbd" more="Kbd 보기">

`shortcut` 칸에 놓는 단축키 표시입니다.

</Card>
<Card title="AppBar" href="/components/app-bar" more="AppBar 보기">

`child` 자리에 트리거를 놓는 상단 바입니다.

</Card>
</Cards>
