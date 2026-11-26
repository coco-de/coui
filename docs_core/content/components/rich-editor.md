---
title: RichEditor
description: 서식 툴바가 붙은 WYSIWYG Markdown 작성기입니다. 댓글이나 리뷰처럼 가벼운 서식이 필요한 글을 받을 때 씁니다.
category: form
platforms: [flutter, web]
related: [text-area, kbd, tooltip, alert, popup]
tags: [markdown, wysiwyg, editor, comment, toolbar, form]
template: v2
source: form/rich_editor
---

# RichEditor

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 RichEditor 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="rich-editor" />

RichEditor 는 글이나 댓글을 쓰는 WYSIWYG Markdown 작성기입니다. 사용자는 Markdown 기호 대신 서식이 적용된 결과를 보며 편집하고, 값은 Markdown(체크리스트 · 취소선 같은 GitHub 확장 문법 포함)으로 들어가고 나옵니다.

```dart
RichEditor(
  placeholder: '댓글을 입력해 주세요',
  maxLength: 2000,
  onChanged: saveDraft,
  onSubmit: post, // ⌘↩ / Ctrl+Enter
)
```

## 구조

상자 하나 안에 툴바와 편집 영역이 있습니다. 상자의 테두리와 포커스 링이 툴바까지 감쌉니다. 이미지를 올리는 줄은 상자 위에, 글자 수는 상자 아래에 필요할 때만 나타납니다.

<Anatomy demo="rich-editor/anatomy">
<AnatomyItem part="container" side="left" name="container">

상자. 테두리 · 채움 · 포커스 경계는 `TextArea` 의 것입니다.

</AnatomyItem>
<AnatomyItem select="[role='toolbar']" side="right" name="toolbar">

상자 안쪽 위의 툴바 띠. 아래의 가는 선이 편집 영역과 나누고, 버튼 그룹 사이에는 간격과 세로 선이 들어갑니다.

</AnatomyItem>
<AnatomyItem select="[aria-haspopup]" side="left" name="block-type">

블록 형식 버튼. 캐럿이 있는 블록의 형식 이름을 보여 주고 메뉴를 엽니다.

</AnatomyItem>
<AnatomyItem select="[aria-keyshortcuts]" side="right" name="format-button">

서식 버튼. 32 정사각 아이콘 버튼이고, 마우스를 올리면 서식 이름과 단축키가 보입니다.

</AnatomyItem>
<AnatomyItem select="[role='textbox']" side="left" name="text">

편집 영역. 글을 입력하면 높이가 자랍니다.

</AnatomyItem>
</Anatomy>

글자를 선택하면 상자와 따로, 선택 영역 위에 서식 툴바가 하나 더 뜹니다(→ [선택 영역 툴바](#선택-영역-툴바)).

<a id="동작-스펙-behavior"></a>
<a id="상태-전환"></a>

## 상태

<Preview demo="rich-editor/states" />

| 상태 | 모습 · 동작 |
| --- | --- |
| 쉴 때 | 상자는 `TextArea` 와 같습니다 — 채움 `surface`, 테두리 `outlineVariant`. 툴바 띠는 `surfaceContainer` 입니다. |
| Hover | 상자 테두리가 `outline` 으로 한 단 진해집니다. |
| Focus | 상자 테두리가 `primary` 가 됩니다. 바깥 링은 키보드로 포커스했을 때만 그립니다. 위 장면의 "포커스 테두리" 칸은 테두리 색만 흉내 낸 것입니다. |
| 켜진 서식 | 캐럿 위치에서 켜진 서식의 버튼은 바탕 `surfaceContainerHigh`, 아이콘 `onSurface` 가 됩니다. |
| 비활성 | `enabled: false` 면 입력 · 툴바 · 서식 단축키가 꺼집니다(Flutter 의 `Mod+Enter` 는 [알려진 제약](#알려진-제약) 참고). 상자는 `disabledContainer` 채움 · `disabledOutline` 테두리이고, 글과 툴바의 아이콘 · 블록 형식 글자는 `disabledContent` 입니다. 툴바 띠는 바탕을 칠하지 않고, 툴바 아래 선은 `disabledOutline` 이 됩니다. 그룹 사이 세로 선은 그대로입니다. |
| 읽기 전용 | `readOnly: true` 면 선택 · 복사는 되지만 입력과 서식 적용이 막히고 툴바 버튼이 꺼집니다. 선택 영역 툴바는 뜨지 않습니다. |

<Note>

네이티브 문서 앱의 무대는 `surfaceContainer` 라 툴바 띠와 같은 색입니다. 띠는 상자 테두리로만 무대와 구분됩니다. 웹 문서의 미리보기 바탕은 `surface` 라 편집 영역의 채움과 같습니다.

</Note>

### 높이

편집 영역은 내용이 적을 때 `minHeight`(기본 80, 약 세 줄)에서 시작해 `maxHeight`(기본 240)까지 자라고, 그 뒤로는 안에서 스크롤합니다. 빈 편집기의 안내(`placeholder`)는 입력한 글과 같은 폭에서 여러 줄로 이어지고 말줄임(…)으로 자르지 않습니다.

### 글자 수

`maxLength` 를 주면 길이가 한도의 80% 에 닿을 때부터 상자 아래 끝에 `길이 / 한도` 가 나타나고, 한도에 닿으면 에러 색이 됩니다. 길이는 화면에 보이는 글자가 아니라 **Markdown 문자열의 길이**라 `**` 같은 기호도 셉니다.

<Preview demo="rich-editor/counter" />

한도에서의 동작은 두 플랫폼이 다릅니다. Flutter 는 줄바꿈(`Enter`)까지 입력을 막고, 한도를 넘는 붙여넣기는 통째로 받지 않습니다. Web 은 글자 입력을 막지만 `Enter` 의 줄바꿈은 들어가고, 붙여넣기는 한도까지만 잘라 넣습니다. Web 은 브라우저의 입력 직전 이벤트를 취소해 막으므로, 한글처럼 조합해서 입력하는 글자는 한도를 넘을 수 있습니다(브라우저에서 확인하지 않았습니다).

### 애니메이션

RichEditor 가 따로 정한 애니메이션은 없습니다. 상자의 테두리 색은 Web 에서는 `TextArea` 처럼 서서히 바뀌고, Flutter 에서는 바로 바뀝니다. 툴팁 · 대화상자 · 버튼 hover 는 각 컴포넌트의 모션을 따릅니다. 선택 영역 툴바가 나타나고 사라지는 모션은 그 판인 `Popup` 의 것입니다(여는 데 150ms, 닫는 데 100ms, 동작 줄이기에서는 바로).

<a id="인터랙션"></a>

## 툴바

기본 툴바(`CoreRichEditorFormat.defaultToolbar`)는 네 그룹입니다 — 블록 형식 | 굵게 · 기울임꼴 · 취소선 · 코드 · 링크 | 글머리 기호 목록 · 번호 목록 · 체크리스트 | 인용 · 이미지. 이미지 버튼은 `onImageUpload` 와 `onImageDelete` 를 **둘 다** 넘겼을 때만 나타납니다.

구성은 `toolbar` 로 바꿉니다. 바깥 목록이 그룹이고, 목록에서 뺀 서식은 상자 툴바의 버튼만 사라지고 단축키는 남습니다. 이미지 버튼을 숨기고 나서 빈 그룹이 되면 간격도 남지 않습니다.

```dart
RichEditor(
  placeholder: '댓글을 입력해 주세요',
  toolbar: const [
    [.bold, .italic, .link],
    [.bulletedList],
  ],
)
```

- **서식 버튼** — 누르면 캐럿 · 선택 영역에 서식을 적용하거나 해제합니다. 버튼에 마우스를 올리면 서식 이름(활성 로케일의 말)과 단축키 키캡(`⌘ E`, Windows · Linux 는 `Ctrl E`)이 `Tooltip` 으로 보입니다. Flutter 는 꺼진 버튼의 툴팁에서 키캡을 뺍니다.
- **블록 형식 버튼**(`blockType`) — 캐럿이 있는 블록의 형식 이름(본문 · 제목 1 · 2 · 3)과 아래 화살표를 보여 주고, 누르면 버튼 4 아래에 메뉴가 열립니다. 지금 형식에는 체크가, 제목 항목 끝에는 그 제목을 만드는 Markdown(`#` · `##` · `###`)이 보입니다. 본문을 고르면 제목이 문단으로 돌아갑니다. 지금 형식을 다시 골라도 아무것도 바뀌지 않습니다. 목록 항목 · 인용 줄은 본문으로 읽히고, 거기서 제목을 고르면 그 블록이 제목이 됩니다.
- **링크** — 링크 버튼이나 `Mod+K` 에서 `onLinkRequest` 를 부르고, 없으면 편집기의 작은 대화상자(주소 · 취소 · 확인, 고치는 링크면 제거)를 엽니다. 선택한 글이 있으면 그 글이 링크가 되고, 링크가 아닌 곳에 캐럿만 있으면 주소가 링크 글로 들어갑니다. 대화상자는 안전하지 않은 주소를 거절하고 오류를 보여 줍니다. `onLinkRequest` 가 돌려준 안전하지 않은 주소는 아무것도 바꾸지 않습니다.

### 제목 버튼

제목을 메뉴 대신 버튼으로 두려면 `heading1` · `heading2` · `heading3` 를 목록에 넣습니다. 누르면 캐럿의 블록이 그 제목이 되고, 이미 그 제목이면 문단으로 돌아갑니다. 제목 4–6(`####` …)이 든 Markdown 은 단계를 그대로 보존하고 제목 3 의 모양으로 그립니다.

<Preview demo="rich-editor/custom-toolbar" />

### 툴바 오른쪽 끝에 앱의 컨트롤 두기

`toolbarTrailing` 에 넘긴 위젯(Web 은 컴포넌트)은 툴바의 오른쪽 끝에 놓입니다. 버튼 옆에 자리가 있으면 같은 줄에, 없으면 버튼 아래 줄의 왼쪽에 놓이고, 두 줄 사이는 `toolbarRowSpacing`(기본 4)입니다. `showToolbar: false` 면 함께 사라집니다.

<Preview demo="rich-editor/trailing" />

```dart
RichEditor(
  placeholder: '댓글을 입력해 주세요',
  toolbarTrailing: Checkbox(
    label: '바뀐 부분 표시',
    checked: showChanges,
    onChanged: setShowChanges,
  ),
)
```

체크박스 · 버튼처럼 **누르는** 컨트롤에 씁니다. `toolbarTrailing` 에 둔 컨트롤을 눌러도 편집기가 포커스를 받지 않습니다. Web 은 편집 영역의 포커스를 지키려고 툴바 띠 전체에서 `mousedown` 을 막으므로, 그 안의 글자 입력 칸은 마우스로 포커스를 받을 수 없습니다.

<a id="선택-영역-위의-툴바-끄기"></a>

### 선택 영역 툴바

글자를 끌어서든 `Shift`+방향키로든 선택하면 서식 툴바가 선택 영역 위에 뜹니다. 긴 글에서 상자 맨 위까지 오가지 않고 서식을 바꾸기 위한 것입니다. 필요 없으면 `showSelectionToolbar: false` 로 끕니다. `showToolbar` 와는 따로라, 상자의 툴바를 끄고 이 툴바만 남길 수도 있습니다.

```dart
RichEditor(
  placeholder: '댓글을 입력해 주세요',
  showSelectionToolbar: false,
)
```

- **구성** — `toolbar` 와 무관하게 늘 `CoreRichEditorFormat.selectionToolbar` 입니다. 기본 툴바에서 이미지 버튼만 뺀 구성입니다. 이미지는 선택한 글의 서식이 아니라 새 블록이라서 빠집니다.
- **자리** — 선택 영역의 가로 가운데, 8(`selectionToolbarOffset`) 위에 뜹니다. 위에 자리가 없으면 아래에 뜨고, 화면 끝에서는 안쪽으로 밀려 들어옵니다. 상자의 툴바가 켜져 있으면 "위의 자리" 는 편집 영역 안에서만 재므로, 첫 줄을 선택해도 상자의 툴바를 덮지 않습니다.
- **뜨는 때** — 끄는 동안에는 뜨지 않고 포인터를 뗀 뒤에 뜹니다. 키보드로 넓히는 선택은 300ms(`selectionToolbarKeyboardDelay`) 동안 멈춘 뒤에 뜹니다. 캐럿만 있거나 이미지만 선택했을 때는 뜨지 않습니다. 선택이 바뀌거나 스크롤 · 창 크기가 바뀌면 따라가고, 선택한 글이 편집 영역 밖으로 스크롤되면 사라졌다가 다시 보이면 다시 뜹니다.
- **닫히는 때** — 선택이 캐럿으로 접힐 때, `Esc`(같은 선택에서는 다시 뜨지 않습니다), 포커스가 편집기를 떠날 때. 이 툴바와 그 메뉴로 옮겨 간 포커스는 떠난 것이 아닙니다.
- **누를 때** — 버튼을 눌러도 선택은 그대로이고 서식을 적용한 뒤에도 툴바가 열려 있습니다. 켜진 서식은 두 툴바에서 함께 눌린 상태로 보입니다. 링크 대화상자가 닫히면 다시 뜹니다.
- **좁은 화면** — 줄을 바꾸지 않고, 화면 가장자리 8 안에 다 들어가지 않으면 버튼을 "더보기"(⋯) 메뉴로 접습니다. 인용, 목록 묶음, 그다음 링크부터 굵게까지 거꾸로 접고, 블록 형식 버튼은 늘 남습니다. ⋯ 메뉴의 항목은 체크박스라 켜진 서식이 보입니다.
- 비활성 · 읽기 전용 편집기에서는 뜨지 않습니다.

### 툴바 숨기기

`showToolbar: false` 면 상자는 `TextArea` 모양이 됩니다. 단축키와 Markdown 자동 서식은 그대로 동작합니다.

<Preview demo="rich-editor/no-toolbar" />

### 툴바를 편집기 밖에서 쓰기 (Flutter 전용)

편집기의 툴바는 `showToolbar: false` 로 끄고, 같은 버튼을 `RichEditorToolbar` 로 원하는 자리에 둘 수 있습니다. 컨트롤러에 묶여 캐럿을 따라 켜지고 꺼집니다. 바탕 · 안쪽 여백 · 선은 그리지 않으므로 앱이 감쌉니다. 그룹 사이의 세로 선도 그리지 않습니다.

```dart
final controller = RichEditorController(markdown: '# 약관');
final editorKey = GlobalKey<RichEditorState>();

Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow.toValue(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: CoreSpace.space8,
          horizontal: CoreSpace.space12,
        ),
        child: RichEditorToolbar(
          controller: controller,
          editorKey: editorKey,
        ),
      ),
    ),
    RichEditor(key: editorKey, controller: controller, showToolbar: false),
  ],
)
```

| 옵션 | 하는 일 |
| --- | --- |
| `controller` (필수) | 서식을 걸 `RichEditorController`. 툴바가 이 컨트롤러를 듣고 켜진 버튼을 바꿉니다. |
| `editorKey` | 화면에 있는 편집기의 `GlobalKey<RichEditorState>`. 누른 뒤 포커스를 편집기로 돌리고, 링크 버튼이 편집기의 링크 창을 열고, 편집기가 이미지를 받을 수 있을 때 이미지 버튼이 나타납니다. 편집기가 툴바보다 늦게 그려져도 다음 프레임에 이어집니다. |
| `toolbar` · `enabled` | 버튼 구성(`RichEditor.toolbar` 와 같은 모양)과 전체 끄기. 컨트롤러가 `readOnly` 여도 꺼집니다. |
| `onFormat` | 누를 때마다 가장 먼저 불립니다. `true` 를 돌려주면 툴바의 기본 동작을 건너뜁니다. 편집기가 아닌 보기 화면에서 버튼을 누르면 편집으로 바꾸고 싶을 때 씁니다. |
| `trailing` | 툴바 오른쪽 끝에 놓을 위젯. 자리가 없으면 버튼 아래 줄 왼쪽으로 내려갑니다. |
| `richEditorStyle` | 툴바의 스타일(버튼 · 켜진 버튼 · 아이콘 · 버튼 간격 · 그룹 사이 간격 · 줄 간격 · 블록 형식 버튼과 메뉴 · 툴팁 · 키캡). |

- 링크 버튼은 `editorKey` 도 `onFormat` 도 없으면 꺼져 있습니다. 링크 창은 편집기의 것입니다.
- 툴바 하나가 편집기 둘을 맡을 수 있습니다. 마지막으로 포커스를 받은 편집기의 컨트롤러와 키를 넘기면 됩니다.
- 좁으면 그룹 단위로 줄을 바꿉니다.

## 단축키와 자동 서식

### 단축키

`Mod` 는 Apple 플랫폼에서 ⌘, 그 밖에서는 Ctrl 입니다. 두 플랫폼이 같은 단축키 표를 읽고, 툴바에서 뺀 서식도 단축키는 남습니다.

| 서식 | Apple | 그 밖 | Markdown |
| --- | --- | --- | --- |
| 굵게 (`bold`) | ⌘ B | Ctrl B | `**bold**` |
| 기울임꼴 (`italic`) | ⌘ I | Ctrl I | `*italic*` |
| 취소선 (`strikethrough`) | ⇧ ⌘ X | Ctrl Shift X | `~~strike~~` |
| 코드 (`code`) | ⌘ E | Ctrl E | `` `code` `` |
| 링크 (`link`) | ⌘ K | Ctrl K | `[text](url)` |
| 글머리 기호 목록 (`bulletedList`) | ⇧ ⌘ 8 | Ctrl Shift 8 | `- item` |
| 번호 목록 (`numberedList`) | ⇧ ⌘ 7 | Ctrl Shift 7 | `1. item` |
| 체크리스트 (`taskList`) | ⇧ ⌘ 9 | Ctrl Shift 9 | `- [ ] item` |
| 인용 (`quote`) | ⇧ ⌘ . | Ctrl Shift . | `> quote` |
| 제목 1 (`heading1`) | ⌥ ⌘ 1 | Ctrl Alt 1 | `# Heading` |
| 제목 2 (`heading2`) | ⌥ ⌘ 2 | Ctrl Alt 2 | `## Heading` |
| 제목 3 (`heading3`) | ⌥ ⌘ 3 | Ctrl Alt 3 | `### Heading` |
| 이미지 (`image`) | 없음 (버튼만) | 없음 (버튼만) | `![alt](url)` |
| 제출 (`onSubmit`) | ⌘ ↩ | Ctrl Enter | — |

단축키는 `Shift` 를 누르지 않은 키로 판정합니다 — 대부분의 자판에서 `Shift+8` 은 `*` 를 치지만 `8` 로 읽습니다. Web 은 모든 단축키를 눌린 **물리 키**(QWERTY 자리)로 판정합니다. Flutter 는 자판이 만드는 키로 판정하고, `Alt`(Option)를 함께 쓰는 제목 단축키만 물리 키로 판정합니다 — Mac 의 `Option+1` 은 `¡` 를 치기 때문입니다. 그래서 QWERTY 가 아닌 자판에서는 두 플랫폼의 글자 단축키가 다른 키에 걸릴 수 있습니다. Windows · Linux 의 `AltGr` 로 치는 조합은 문자 입력이라 단축키로 읽지 않습니다. 그 자판에서는 툴바의 블록 형식 메뉴나 줄 머리의 `# ` 자동 서식으로 제목을 만드세요.

### Markdown 자동 서식

입력하는 동안 Markdown 이 인식되면 서식으로 바뀝니다. 블록 머리 표시 · 구분선 · `_` 로 감싸는 형태는 Flutter 가 더 많이 인식하고, 글자 서식은 Web 이 단어 중간에서도 바꿉니다.

| 입력 | 결과 | Flutter | Web |
| --- | --- | --- | --- |
| `**굵게**` · `*기울임*` · `~~취소선~~` · `` `코드` `` | 닫는 기호를 치면 해당 서식 | O | O |
| `[텍스트](주소)` | 링크 | O | O |
| 주소 · 이메일을 그대로 친 뒤 공백이나 `Enter` | 링크 | O | — |
| `__굵게__` · `_기울임_` · `~취소선~` | 해당 서식 | O | — |
| 줄 머리의 `# ` · `## ` · `### ` | 제목 1–3 | O | O |
| 줄 머리의 `#### ` – `###### ` | 제목 4–6 (제목 3 모양) | O | — |
| 줄 머리의 `- ` · `* ` | 글머리 기호 목록 | O | O |
| 줄 머리의 `+ ` | 글머리 기호 목록 | O | — |
| 줄 머리의 `1. ` | 번호 목록 | O | O |
| 줄 머리의 `1) ` 이나 다른 숫자(`3. `) | 번호 목록 | O | — |
| 줄 머리의 `[] ` · `[ ] ` · `- [ ] ` | 체크리스트 | O | O |
| 줄 머리의 `[x] ` | 체크된 항목 | O | — |
| 줄 머리의 `> ` | 인용 | O | O |
| `---` 다음 `Enter` | 구분선 | O | O |
| `***` · `___` 다음 `Enter`, 또는 `---` · `***` · `___` 다음 공백 | 구분선 | O | — |

Flutter 는 굵게 · 기울임 · 취소선 · 코드를 여는 기호가 줄 처음, 공백, `(` 뒤에 있을 때만 바꿉니다. Web 에는 이 조건이 없어 `정말**좋아**` 처럼 단어 중간에서도 바꿉니다. `[텍스트](주소)` 링크는 두 플랫폼 모두 단어 중간에서도 바뀝니다. 두 플랫폼 모두 빈 목록 항목에서 `Enter` 를 누르면 목록에서 빠져나옵니다(Web 의 중첩 목록은 한 단계 내어쓰기). 빈 인용 줄에서 `Enter` 를 누르면 Web 은 그 줄이 문단이 되고, Flutter 는 아래에 일반 문단이 생기고 빈 인용 줄은 남습니다.

### 편집기가 다루지 못하는 Markdown

표 · HTML · 코드 블록처럼 편집 화면에 서식으로 보여 줄 수 없는 Markdown 은 두 플랫폼이 다르게 다룹니다.

- **Flutter** — 표 · HTML · 코드 블록 · 링크 참조 정의 · 문장 안에 섞인 이미지 · 편집기가 받지 않는 주소의 이미지 · 제목이 붙었거나 받지 않는 스킴을 쓰는 링크가 든 블록은 글자 그대로의 **리터럴 블록**이 됩니다. 안의 글자는 평문으로 고칠 수 있고, 건드리지 않은 블록은 원문 그대로 내보냅니다.
- **Web** — 이 가운데 코드 블록과 문장 안의 안전한 이미지만 보존합니다(들여쓴 코드 블록은 펜스 코드 블록으로 바뀝니다). 편집기는 `initialValue` 를 읽을 때 문서 전체를 다시 쓰므로, 나머지는 원문이 바뀝니다(→ [알려진 제약](#알려진-제약)).

## 이미지

`onImageUpload` 와 `onImageDelete` 가 **둘 다** 있어야 이미지 버튼이 나타납니다. 편집기는 파일을 어디에 두고 어떻게 지우는지 모르므로, 두 함수가 없으면 버튼도 없고 네트워크에 손대지 않습니다. 업로드만 넘기면 사용자가 문서에서 뺀 이미지가 서버에 남기 때문에, 디버그 빌드에서는 assert 로 알립니다. 서버가 파일을 스스로 정리하는 앱은 아무것도 하지 않는 `onImageDelete` 를 넘깁니다. Markdown 에 이미 있는 안전한 주소의 이미지는 버튼과 상관없이 그립니다.

<Preview demo="rich-editor/image" />

이 장면과 플레이그라운드의 업로드는 서버 대신 파일을 `data:` 주소로 바꿔 Markdown 안에 담으므로 1 MiB 까지만 받고, 삭제 함수는 아무것도 하지 않습니다. 파일 선택은 플레이그라운드에서 "이미지 버튼" 을 켜고 해 볼 수 있습니다.

1. **고르기** — 버튼이 파일 선택창을 엽니다(PNG · JPEG · GIF · WebP). 다른 형식이나 `maxImageBytes` 를 넘는 파일은 읽기 전에 거절하고 상자 위에 실패 줄을 보여 줍니다. 이때 업로드 함수는 부르지 않습니다.
2. **올리기** — `onImageUpload(file)` 이 도는 동안 상자 위에 "이미지 올리는 중" 줄이 있습니다. 함수는 파일을 저장하고 이미지를 보여 줄 **주소**를 돌려줍니다. 함수가 던지거나 편집기가 거절하는 주소를 돌려주면 줄이 실패로 바뀌고 닫을 수 있습니다. 받는 주소는 `http` · `https` · 이미지 `data:`(base64) · 스킴이 없는 상대 주소이고, `javascript:` · `file:` · `blob:` 는 거절합니다.
3. **넣기** — 버튼을 누른 때 캐럿이 있던 블록 **아래**에 이미지가 들어갑니다(그 블록이 빈 문단이면 그 자리를 대신합니다). Web 에서는 캐럿이 목록이나 인용 안에 있으면 그 목록 · 인용 전체 아래에 들어갑니다. 캐럿은 그 아래 문단으로 옮겨 가고, Markdown 에는 `![파일 이름](주소)` 가 쓰입니다. 대체 텍스트는 확장자를 뺀 파일 이름입니다(`photo.png` 는 `photo`). 올리는 동안 계속 글을 써도 됩니다.
4. **지우기** — 이미지를 선택하고 `Backspace` · `Delete` 로 지우거나 잘라냅니다.

`imageMaxHeight`(기본 192)보다 큰 이미지는 비율을 지키며 줄어듭니다. 불러오지 못한 이미지는 Flutter 에서는 그 자리의 `Alert` 가 되고, 제목은 "이미지를 불러올 수 없어요" 이며 대체 텍스트가 있으면 함께 보여 줍니다. Web 에서는 브라우저의 깨진 이미지 상자로 보이고, 툴팁은 "이미지를 불러올 수 없어요" 입니다. 두 경우 모두 Markdown 은 그대로입니다.

### 서버에서 지우기

`onImageDelete` 는 다음 규칙으로만 불립니다. 파일을 잃지 않기 위한 규칙입니다.

- **편집기가 올린 이미지만** — 처음 Markdown 에 있던 이미지는 부르지 않습니다. 그 편집을 저장할지 편집기가 알 수 없고, 취소한 편집이 원래 글의 파일을 지우면 안 되기 때문입니다.
- **빠진 지 10초 뒤, 한 번만** — 그 전에 실행 취소로 돌아온 이미지는 지우지 않습니다. Flutter 에서는 잘라내기 · 붙여넣기로 옮긴 이미지도 지우지 않습니다. Web 은 붙여넣기가 평문만 넣어 잘라낸 이미지가 붙여넣기로 돌아오지 않으므로, 편집기가 올린 이미지였다면 10초 뒤에 부릅니다. 같은 주소가 문서에 하나라도 남아 있으면 지우지 않습니다.
- **편집기가 사라질 때** — 기다리던 이미지는 그때 바로 보고하고, 편집기가 사라진 뒤에 끝난 업로드의 파일도 바로 지웁니다.
- **보여 줄 수 없는 주소가 돌아왔을 때** — 업로드 줄은 실패가 되고, 서버에는 파일이 이미 있으므로 그 주소로 바로 부릅니다.
- **바깥에서 내용을 바꾸면 부르지 않습니다** — 글을 보낸 뒤 Flutter 에서 `controller.markdown = ''` 로 비워도, Web 에서 새 `key` 로 편집기를 다시 만들어도 보낸 글에 남아 있던 이미지의 파일은 남습니다.
- **기다리지 않고 오류도 잡지 않습니다** — 서버 호출의 오류는 앱의 오류 처리로 갑니다.

> 실행 취소로 이미 지운 이미지가 돌아오면 서버에 파일이 없어 불러올 수 없는 이미지가 됩니다. 되돌릴 수 있는 삭제가 필요하면 `onImageDelete` 에서는 표시만 하고 글을 저장할 때 지우세요.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

댓글 · 게시글 · 리뷰 답글처럼 가벼운 서식이 필요한 글을 받고, Markdown 으로 저장하면서 쓰는 사람에게는 서식이 적용된 결과를 보여 줄 때 씁니다. `⌘↩` · `Ctrl+Enter` 로 바로 보내는 흐름(`onSubmit`)이나, 파일을 앱의 서버에 올리고 지우는 코드가 있는 앱의 사진 첨부에도 맞습니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 서식 없는 여러 줄 글 — 라벨 · 도움말 · 오류 · 크기 조절이 필요할 때 | [TextArea](/components/text-area) |
| 한 줄 입력 | [TextField](/components/text-field) |
| 단축키를 입력받지 않고 보여 주기만 할 때 | [Kbd](/components/kbd) |

### 서식과 값

<Cards columns="2">
<Card demo="rich-editor/do-few-formats" tone="do" eyebrow="이렇게 하세요">

필요한 서식만 `toolbar` 에 둡니다. 뺀 서식도 단축키는 남습니다.

</Card>
<Card demo="rich-editor/dont-plain-field" tone="dont" eyebrow="이렇게 하지 마세요">

이름 · 주소처럼 서식이 뜻 없는 칸에 쓰지 않습니다. 값에 `**` 같은 기호가 섞여 들어옵니다. TextField 나 TextArea 를 씁니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

값은 이미 Markdown 이라 그대로 저장하고, 보여 줄 때는 Markdown 렌더러에 넘깁니다. 보내기를 `onSubmit` 에 연결하면 `⌘↩` · `Ctrl+Enter` 로 키보드만 써서 작성을 끝낼 수 있습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

서버가 파일을 스스로 정리하지 않는데 아무것도 하지 않는 `onImageDelete` 를 넘기지 않습니다. 사용자가 뺀 이미지가 서버에 남습니다.

</Card>
</Cards>

<a id="richeditorstyle-슬롯"></a>
<a id="스타일-시스템-style-system"></a>
<a id="테마-커스터마이징-theme"></a>

## 테마와 스타일

겉모습은 `richEditorStyle`(`CoreRichEditorStyle`) 하나로 덮어씁니다.

<Split>

<Code language="dart" title="RichEditor 하나만 바꾸기">
RichEditor(
  placeholder: '댓글을 입력해 주세요',
  richEditorStyle: CoreRichEditorStyle(
    textAreaStyle: CoreTextAreaStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
    maxHeight: CoreSize.size80 * 4,
    quoteBarColor: CoreColor.token(CoreColors.primary),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    richEditor: CoreRichEditorTheme(
      style: CoreRichEditorStyle(
        linkColor: CoreColor.token(CoreColors.primary),
        codeBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  ),
)
</Code>

</Split>

RichEditor 는 다른 컴포넌트를 조립해 그리고, 각 부품의 모습은 `richEditorStyle` 안의 그 부품 스타일로 바꿉니다.

- **상자** — `textAreaStyle`(`TextArea` 의 상자). 편집 영역의 높이는 `minHeight` · `maxHeight` 입니다.
- **툴바 띠** — `toolbarBackgroundColor` · `toolbarPadding`. 안쪽 여백의 기본값은 위아래 4, 글이 시작하는 쪽 12, 반대쪽 8 이라 오른쪽에서 왼쪽으로 쓰는 로케일에서는 12 가 오른쪽에 옵니다.
- **선** — `toolbarDividerStyle`, 그룹 사이 세로 선의 길이 `toolbarGroupDividerHeight`(20, 0 이면 선 없음).
- **버튼** — `toolbarButtonStyle`(32 정사각), 켜진 버튼은 그 위에 `activeToolbarButtonStyle` 을 합칩니다. 아이콘은 `toolbarIconStyle`(16).
- **간격** — `toolbarItemSpacing`(2, 업로드 줄 사이에도) · `toolbarGroupGapStyle`(8) · `toolbarRowSpacing`(4), 상자와 위의 업로드 줄 사이 `toolbarGapStyle`.
- **블록 형식** — `blockTypeButtonStyle`(글자와 화살표 사이 4) · `blockTypeMenuStyle`(선택 영역 툴바의 "더보기" 메뉴에도).
- **툴팁** — `tooltipStyle` · `kbdStyle`.
- **선택 영역 툴바** — 판은 `selectionToolbarPanelStyle`(`Popup`; 바탕 `surfaceBright` · 테두리 `outlineVariant` 1 · 그림자 `CoreShadow.lg` 는 `Popup` 의 기본값이고, 모서리 10 과 안쪽 여백(위 · 아래 · 끝 4, 글이 시작하는 쪽 12)만 다릅니다), 거리는 `selectionToolbarOffset`(8). 판 안의 버튼은 상자 툴바의 스타일을 그대로 읽어 두 툴바가 같은 모습입니다.
- **업로드 줄** — `uploadAlertStyle`.
- **문서** — 제목은 `heading1TextStyle` · `heading2TextStyle` · `heading3TextStyle`(기본은 `titleLarge` · `titleMedium` · `titleSmall` 역할이고, 제목 4–6 은 제목 3 을 따름). 코드 · 인용 · 링크 · 구분선 · 체크한 항목 · 이미지 · 블록 간격 · 목록 들여쓰기는 낱개 필드입니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (CoreRichEditorStyle.default*)
  → CoreComponentTheme.richEditor.style    // 앱 전체
  → richEditorStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. 부품의 스타일은 이 순서로 합친 뒤 `TextArea` · `Button` · `Icon` · `Gap` · `Divider` · `DropdownMenu` · `Tooltip` · `Kbd` · `Popup` · `Alert` 에 넘깁니다.

<a id="접근성-accessibility"></a>

## 접근성

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 편집 영역은 여러 줄 텍스트 필드이고 읽기 전용 · 활성 여부를 함께 알립니다. 툴바는 이름이 "서식" 인 그룹이고, 서식 버튼은 서식 이름과 켜짐 여부를 냅니다. 블록 형식 버튼은 메뉴가 열렸는지를 알리고, 그 메뉴의 항목은 하나만 고르는 라디오 항목입니다. "더보기" 메뉴의 항목은 체크박스 항목입니다. 문서의 제목은 단계가 있는 머리글이고, 이미지는 대체 텍스트를 이름으로 냅니다. |
| Jaspr Web | 편집 영역은 `contenteditable` 요소에 `role="textbox"` · `aria-multiline="true"` 를 달고, 필요하면 `aria-disabled` · `aria-readonly` · `aria-placeholder` 를 붙입니다. 툴바는 `role="toolbar"` + `aria-label` + `aria-controls`, 그룹마다 `role="group"` 입니다. 서식 버튼은 `aria-label` · `aria-pressed` · `aria-keyshortcuts` · `aria-controls` 를 갖습니다(이미지 버튼에는 `aria-pressed` · `aria-keyshortcuts` 가 없습니다). 블록 형식 버튼과 "더보기" 버튼은 `aria-label` · `aria-controls` 를 갖습니다. 블록 형식 메뉴의 항목은 `menuitemradio`, "더보기" 메뉴의 항목은 `menuitemcheckbox` 이고 둘 다 `aria-checked` 를 갖습니다. |

선택 영역 툴바는 상자의 툴바와 구별되는 이름 "선택 영역 서식"(영어 "Selection formatting")을 갖습니다. Flutter 는 그룹의 라벨, Web 은 `role="toolbar"` 의 `aria-label` 입니다. 버튼의 이름 · 눌림 상태 · 단축키는 상자 툴바의 버튼과 같습니다.

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| 서식 단축키 | 적용 · 해제 | 적용 · 해제 |
| `Mod+Enter` | `onSubmit` (읽기 전용에서도. 비활성 편집기도 눌러 포커스를 준 뒤에는 부를 수 있음) | `onSubmit` (읽기 전용 · 비활성에서는 부르지 않음) |
| `Tab` · `Shift+Tab` | 목록 · 체크리스트에서는 들여쓰기 · 내어쓰기(0 단계에서 `Shift+Tab` 은 글머리 · 번호 항목을 문단으로 바꾸고, 체크리스트 항목에서는 아무 일도 없음). 리터럴 블록에서는 `Tab` 이 공백 두 칸(`Shift+Tab` 은 아무 일도 없음). 그 밖에서는 포커스 이동. 읽기 전용이면 목록에서도 포커스 이동 | 포커스 이동 (브라우저 기본) |
| `Mod+Z` · `Mod+Shift+Z` | 편집기의 실행 취소 · 다시 실행(Windows · Linux 는 `Ctrl+Y` 도) | 브라우저의 `contenteditable` 실행 취소 |
| `Mod+C` · `Mod+X` | 선택을 Markdown 으로 복사 · 잘라내기 | 브라우저 기본 |
| `Mod+V` · `Mod+Shift+V` | Markdown 을 서식으로 붙여넣기 · 평문 붙여넣기 | 항상 평문 |
| `Enter` · `Space` (툴바 버튼) | 버튼 실행 | 버튼 실행 |
| `Enter` (블록 형식 버튼) | 메뉴 열기. 항목 사이는 메뉴의 키보드 동작 | 메뉴는 열리지만 포커스가 항목이 아니라 페이지 본문으로 옮겨 감. `Tab` 을 한 번 누르면 첫 항목에 닿음([알려진 제약](#알려진-제약)) |
| `Alt+F10` (선택 영역 툴바가 떠 있을 때) | 그 툴바의 첫 버튼으로 포커스. 버튼 사이는 `Tab` | 같음 |
| `Esc` (선택 영역 툴바가 떠 있을 때) | 툴바 닫기. 포커스가 툴바에 있었으면 선택을 그대로 둔 채 글로 돌아옴 | 같음 |
| `Shift`+방향키 · `Home` · `End` · `PageUp` · `PageDown` | 선택 넓히기. 선택 영역 툴바는 300ms 멈춘 뒤 뜸 | 같음 |

툴바는 방향키로 버튼을 옮겨 다니는 방식(roving 포커스)을 쓰지 않아, 버튼마다 `Tab` 정지점이 있습니다.

### 스크린 리더

- **편집 영역의 이름** — Flutter 는 `placeholder` 를 라벨로 냅니다. Web 은 접근성 이름이 없고 `placeholder` 는 `aria-placeholder` 로만 나갑니다.
- **툴바 버튼** — 번역된 서식 이름(예: "굵게", "체크리스트")과 켜짐 상태를 읽습니다.
- **블록 형식 버튼** — 이름이 무엇을 고르는 버튼인지와 지금 형식을 함께 말합니다. "블록 형식: 제목 2"(영어 "Block type: Heading 2") 처럼 읽히고 캐럿을 옮기면 바뀝니다. 버튼 글자가 곧 형식 이름이라 툴팁은 없습니다.
- **업로드 줄** — 실패 줄은 바로 알립니다(Web `role="alert"`, Flutter 라이브 영역). 올리는 중 줄 자체는 알리지 않고, 그 안의 `Loading` 이 상태를 냅니다(Flutter 라이브 영역, Web `role="status"` 와 `aria-label`).
- 글자 수와 서식 적용 결과는 알리지 않습니다.

### 포커스 관리

- **진입** — `autofocus: true` 면 처음 나타날 때 편집 영역이 포커스를 받습니다. Flutter 는 활성 편집기면(읽기 전용 포함), Web 은 활성이고 읽기 전용이 아닐 때만 받습니다. 상자 안 글 아래의 빈 곳을 눌러도 포커스됩니다.
- **이탈** — 상자와 툴바 바깥을 누르면 포커스가 풀립니다. 툴바 버튼을 눌러도 선택이 유지되어 서식이 그 선택에 적용됩니다.
- **선택 영역 툴바** — 스스로 포커스를 가져가지 않습니다. 마우스로 버튼을 눌러도 선택은 글에 남고, Web 에서는 포커스도 글에 남습니다. 키보드로는 `Alt+F10` 으로 들어가고 `Esc` 로 글에 돌아옵니다. 블록 형식 메뉴를 고르지 않고 닫아도 포커스는 글로 돌아와 툴바가 남습니다.
- **트랩** — 포커스를 일부러 가두지는 않습니다. 다만 Flutter 는 리터럴 블록 안(읽기 전용 포함)과, 편집할 수 있는 편집기의 체크리스트 항목에서 `Tab` · `Shift+Tab` 으로 편집기를 벗어날 수 없습니다. 글머리 기호 · 번호 목록에서는 `Shift+Tab` 으로 항목이 문단이 된 뒤에야 벗어납니다. 커서를 일반 문단으로 옮긴 뒤 `Tab` 을 누르거나 편집기 밖을 눌러야 합니다. 링크 대화상자는 `Dialog` 의 포커스 규칙을 따르고, 닫히면 편집기로 돌아옵니다.
- **포커스 링** — 키보드로 들어왔을 때만 바깥 링을 그립니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 편집기가 다루지 못하는 Markdown 이 바뀝니다. 문서 전체를 다시 써서, 표는 칸을 나누는 세로 막대가 남은 한 줄 문단이 되고, HTML 은 `<` 앞에 `\` 가 붙은 글자가 되고, 안전하지 않은 주소의 이미지는 대체 텍스트만 남습니다. 그대로 저장하면 원문을 잃습니다. 표나 HTML 이 든 글은 Web 편집기로 고치지 마세요. |
| Jaspr Web | 목록 항목 맨 앞에서 `# ` · `- ` · `* ` · `1. ` 를 치면 친 기호만 지워지고 블록은 바뀌지 않습니다. |
| Jaspr Web | 편집 영역에 접근성 이름이 없습니다. 생성자의 `id` · `attributes` 는 바깥 `<div>` 에 붙어 편집 영역에 이름을 줄 수 없습니다. |
| Jaspr Web | 블록 형식 버튼의 `aria-haspopup` · `aria-expanded` 가 포커스를 받는 버튼이 아니라 그것을 감싼 `role="button"` 요소에 붙습니다. |
| Jaspr Web | 블록 형식 버튼에서 `Enter` 로 메뉴를 열면 포커스가 페이지 본문으로 빠집니다. `↓` 를 눌러도 항목에 닿지 않고, `Tab` 을 한 번 누르면 첫 항목에 닿습니다. 항목에서 `Tab` 을 다시 누르면 메뉴를 연 채 메뉴 밖으로 나갑니다. |
| Jaspr Web | 블록 형식 메뉴와 "더보기" 메뉴의 항목에는 비활성 상태가 없습니다. |
| Jaspr Web | 붙여넣기가 평문만 넣으므로 이미지를 잘라내기 · 붙여넣기로 옮길 수 없습니다. 편집기가 올린 이미지를 잘라내면 10초 뒤 `onImageDelete` 가 불립니다. |
| Flutter | 읽기 전용 편집기에서도 `Mod+Enter` 가 `onSubmit` 을 부릅니다. 비활성 편집기도 눌러 포커스를 준 뒤에는 부를 수 있습니다. Web 은 두 경우 모두 부르지 않습니다. |
| Flutter | 리터럴 블록 안과 체크리스트 항목에서는 `Tab` 키로 편집기를 벗어날 수 없습니다(→ 포커스 관리의 "트랩"). |
| Flutter | 모든 플랫폼에서 마우스용 선택 방식으로 편집합니다. 터치 기기에서의 동작은 확인하지 않았습니다. |
| Flutter | `RichEditorController(features:)` 의 타입 `MarkdownBlockFeatures` 는 패키지에서 내보내지 않아 값을 만들 수 없습니다. |
| 공통 | 라벨 · 도움말 · 오류 문구를 받는 속성이 없습니다. 라벨은 앱이 상자 밖에 둡니다. |
| 공통 | 툴바 버튼의 hover 채움(`surfaceContainer`)이 툴바 띠와 같은 색이라, 상자 툴바에서는 아이콘 색만 바뀝니다. 켜진 버튼에 올리면 켜짐 채움이 hover 채움으로 바뀌어 꺼진 것처럼 보입니다. |
| 공통 | 선택 영역 툴바는 `toolbar` 를 따르지 않아, 상자 툴바에서 뺀 서식도 보입니다. |
| 공통 | 선택 영역 툴바는 `Tab` 순서에 없고 `Alt+F10` 으로만 들어갑니다. 서식마다 단축키가 있어 툴바 없이도 같은 일을 할 수 있습니다. |
| 공통 | 터치 기기에서 OS 의 선택 메뉴와 선택 영역 툴바가 겹칠 수 있습니다. 이 조합은 확인하지 않았습니다. |
| 공통 | 툴바 버튼은 32 × 32 로 전역 최소 24 × 24 는 넘지만, 버튼이 많으면 `Tab` 이동이 길어집니다. 필요한 서식만 `toolbar` 에 둡니다. |
| 공통 | 새 이미지는 파일 선택창으로만 넣습니다. 클립보드의 그림 붙여넣기 · 파일 끌어다 놓기는 지원하지 않습니다(Flutter 에 클립보드 이미지를 읽는 의존성이 없어 두 플랫폼을 같게 두었습니다). 이미지에 삭제 버튼이 없고, 대체 텍스트를 고치는 화면도 없습니다. |
| 공통 | `initialValue` 는 처음 한 번만 읽습니다. 내용을 바꿔 끼우려면 Flutter 는 `controller.markdown` 을, Web 은 새 `key` 로 다시 만듭니다. |

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

두 플랫폼은 속성 이름과 기본값이 같고, 편집 엔진이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 편집하는 곳 | `super_editor` 문서 편집기 | `contenteditable` 요소. 서버가 `initialValue` 로 첫 화면을 그리고 브라우저가 이어받음 |
| 바깥에서 값 · 포커스 다루기 | `controller` · `focusNode` | 없음 (`controller` · `focusNode` 는 `Null`) |
| 다루지 못하는 Markdown | 리터럴 블록으로 보존, 건드리지 않은 블록은 원문 그대로 | 코드 블록 · 문장 안의 이미지만 보존, 문서 전체를 다시 씀 |
| Markdown 자동 서식 | 블록 머리 표시 · 구분선 · `_` 형태를 더 많이 인식, 그대로 친 주소도 링크 | 글자 서식을 단어 중간에서도 바꿈([자동 서식 표](#markdown-자동-서식)) |
| 단축키 판정 | 자판이 만드는 키 (`Alt` 조합은 물리 키) | 모든 단축키를 물리 키로 |
| 글자 수 한도 | 줄바꿈까지 막고, 넘는 붙여넣기는 통째로 거절 | 줄바꿈은 들어가고, 붙여넣기는 잘라 넣음 |
| 읽기 전용의 `onSubmit` · `autofocus` | 부름 · 받음 | 부르지 않음 · 받지 않음 |
| 빈 인용 줄의 `Enter` | 아래에 일반 문단, 빈 인용 줄은 남음 | 그 줄이 문단이 됨 |
| 링크 대화상자 | 빈 주소로 확인하면 오류. 제거는 outline 버튼. 주소 칸에 `https://` 안내 | 빈 주소로 확인하면 닫히고 고치던 링크는 제거. 제거는 ghost 버튼. 안내 글자 없음 |
| 상자 테두리 색의 포커스 기준 | 편집 영역의 포커스 | `:focus-within` — 툴바 버튼의 키보드 포커스에도 테두리가 물듦. 링은 편집 영역만 따름 |
| `minHeight` 를 넘는 안내 글자 | 안내를 담도록 `maxHeight` 까지 자람 | 높이는 그대로, 안에서 스크롤 |
| 굵은 글자의 굵기 | 600 | `bold`(700) |
| 리터럴 블록 상자의 모서리(Web 은 코드 블록과 인라인 코드 배경 포함) | 6. 인라인 코드 배경에는 모서리 없음 | 4 |
| 툴팁 이름과 키캡 사이 | 8 | 4 |
| 꺼진 버튼의 툴팁 키캡 | 뺌 | 빼지 않음(꺼진 버튼에서 툴팁이 뜨는지는 확인하지 않음) |
| 상자 테두리 색의 전환 | 바로 바뀜 | `TextArea` 처럼 서서히 바뀜 |
| 잘라내기 · 붙여넣기로 이미지 옮기기 | 가능 | 불가(붙여넣기가 평문만 넣음) |
| 선택 영역 툴바의 접기 측정 | 레이아웃에서 재어 같은 프레임에 접음 | 판이 놓일 때 DOM 에서 재어 다음 프레임에 접음 |
| 선택 영역 툴바가 따라가는 것 | 프레임마다 선택 영역을 다시 잼 | `selectionchange` · 스크롤 · 창 크기 변경에서 다시 잼 |
| 선택 영역 툴바의 방향 | 편집기의 `Directionality` | 편집 영역의 계산된 `direction` |
| 블록 형식 메뉴의 적용 시점 | 고르는 즉시 | 메뉴가 사라진 뒤 |
| 툴바를 편집기 밖에서 쓰기 | `RichEditorToolbar` | 없음 |
| `toolbarTrailing` 의 입력 칸 | 가능 | 마우스로 포커스를 받지 못함 |
| `Tab` | 목록 들여쓰기, 리터럴 블록에서는 공백 두 칸. 리터럴 블록 · 체크리스트에서는 편집기를 벗어나지 않음 | 포커스 이동 |
| 실행 취소 · 붙여넣기 | 편집기의 기록, Markdown 서식 붙여넣기 | 브라우저 기본, 평문 붙여넣기 |
| 이미지 파일 고르기 | `file_picker` (OS 선택창, 웹에서는 브라우저 선택창) | 숨은 `<input type="file">` |
| 이미지 | 선택할 수 있는 블록. 문장 안의 이미지는 리터럴 블록 | 문단 안의 `<img>`. 선택은 브라우저의 `contenteditable` 을 따르고, 누르면 이미지가 선택됨. 문장 안에서도 이미지로 보임 |
| 상대 주소(`/uploads/a.png`)의 이미지 | 웹에서만 불러옴 | 불러옴 |
| 불러오지 못한 이미지 | 그 자리의 `Alert`(대체 텍스트도 보임) | 브라우저의 깨진 이미지 상자와 툴팁. 상자는 폭이 `imageMaxHeight`, 높이가 그 절반보다 작아지지 않음 |
| 파일 끌어다 놓기 | 지원하지 않음 | 막음 (브라우저가 `blob:` · `file:` 이미지를 넣지 못하게) |
| HTML 전용 속성 | — | `id` · `classes` · `css` · `attributes` |

<a id="props-parameters"></a>

## API

두 플랫폼의 속성 이름과 기본값이 같습니다. `W` 는 Flutter 의 `Widget`, Web 의 `Component` 입니다.

### 값과 콜백

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `initialValue` | `String?` | `null` | 처음 보여 줄 Markdown. 처음 한 번만 읽고, `controller` 가 있으면 무시합니다. |
| `onChanged` | Flutter `ValueChanged<String>?` · Web `CoreValueChanged<String>?` | `null` | 바뀔 때마다 편집기의 Markdown 으로 호출합니다. |
| `onSubmit` | Flutter `ValueChanged<String>?` · Web `CoreValueChanged<String>?` | `null` | `Mod+Enter` 에서 Markdown 으로 호출합니다. `null` 이면 이 조합을 가로채지 않습니다. |
| `placeholder` | `String?` | `null` | 빈 편집기에 보이는 안내입니다. |
| `onLinkRequest` | `CoreRichEditorLinkRequest?` | `null` | 링크 버튼 · `Mod+K` 에서 링크 주소를 묻는 함수. `null` 이면 편집기의 대화상자를 엽니다. |

`CoreRichEditorLinkRequest` 는 `Future<String?> Function(String? current)` 입니다. `current` 는 고치는 링크(새 링크면 `null`)이고, 새 주소 · 링크 제거(`''`) · 취소(`null`) 중 하나로 완료합니다. 주소는 `CoreRichEditorContract.normalizeLink` 를 거쳐 `http` · `https` · `mailto` 만 받습니다. 스킴이 없는 도메인에는 `https://` 를, `@` 가 있고 `/` 가 없는 주소에는 `mailto:` 를 붙입니다.

### 상태와 제한

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | 끄면 흐려지고 입력 · 툴바 · 서식 단축키가 꺼집니다. Flutter 의 `Mod+Enter` 는 [알려진 제약](#알려진-제약) 참고. |
| `readOnly` | `bool` | `false` | 선택 · 복사는 되지만 바꿀 수 없습니다. |
| `autofocus` | `bool` | `false` | 처음 나타날 때 포커스를 받습니다. |
| `maxLength` | `int?` | `null` | 받을 수 있는 Markdown 최대 글자 수. 80% 부터 글자 수를 보여 줍니다. |

### 툴바 설정

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `showToolbar` | `bool` | `true` | 상자 안 툴바 표시. 단축키는 툴바와 상관없이 동작합니다. |
| `toolbar` | `List<List<CoreRichEditorFormat>>` | `CoreRichEditorFormat.defaultToolbar` | 상자 툴바의 버튼 그룹입니다. |
| `toolbarTrailing` | `W?` | `null` | 툴바 오른쪽 끝의 앱 컨트롤입니다. |
| `showSelectionToolbar` | `bool` | `true` | 선택 영역 위의 툴바. 비활성 · 읽기 전용에서는 켜 두어도 뜨지 않습니다. |

### 이미지 업로드

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `onImageUpload` | `CoreRichEditorImageUpload?` | `null` | 고른 이미지를 올리고 보여 줄 주소를 돌려줍니다. `onImageDelete` 와 함께 있어야 이미지 버튼이 나타납니다. |
| `onImageDelete` | `CoreRichEditorImageDelete?` | `null` | 사용자가 문서에서 뺀 이미지를 서버에서 지웁니다. |
| `maxImageBytes` | `int?` | `10 * 1024 * 1024` | 읽고 올릴 이미지의 최대 바이트. `null` 이면 제한이 없습니다. |

`CoreRichEditorImageUpload` 는 `Future<String> Function(CoreRichEditorImageFile file)`, `CoreRichEditorImageDelete` 는 `Future<void> Function(String url)` 입니다. `CoreRichEditorImageFile` 은 고른 파일의 `name` · `mimeType` · `bytes`(와 `size`)를 담습니다.

### 스타일

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `richEditorStyle` | `CoreRichEditorStyle?` | `null` | 겉모습을 바꾸는 값 묶음입니다(→ [테마와 스타일](#테마와-스타일)). |

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` | `RichEditorController?` | `null` | 문서를 들고 Markdown 을 읽고 씁니다. Web 의 타입은 `Null` 입니다. |
| `focusNode` | `FocusNode?` | `null` | 포커스를 다룹니다. Web 의 타입은 `Null` 입니다. |

```dart
final controller = RichEditorController(markdown: '**안녕하세요**');

RichEditor(controller: controller)

controller.markdown = '- 하나\n- 둘';
```

- `RichEditorController` 는 `markdown` 읽기 · 쓰기, `length`(Markdown 글자 수), `undo()` · `redo()`, `selectAll()` · `moveCaretToEnd()` 를 제공합니다. `markdown` 에 값을 쓰면 `onChanged` 가 불립니다.
- 편집기에 붙은 컨트롤러의 `readOnly` · `maxLength` 는 위젯의 값으로 덮어씁니다.
- `GlobalKey<RichEditorState>` 로는 `focus()`, 링크 창을 여는 `editLink()`, 이미지를 고르는 `insertImage()` 와 `canInsertImage` 를 씁니다.

### Jaspr Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` · `classes` · `css` · `attributes` | HTML 속성 | `null` | 바깥 `<div>` 에 붙습니다. 편집 영역에는 닿지 않습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreRichEditorStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `textAreaStyle` | `CoreTextAreaStyle?` | The box — border, radius, fill, padding, focus ring, text, placeholder, selection and caret colour — handed to the `TextArea` as is. |
| `minHeight` | `double?` | Height of the editing area when it holds little text. |
| `maxHeight` | `double?` | Height the editing area grows to before it scrolls. |
| `toolbarButtonStyle` | `CoreButtonStyle?` | Each toolbar button, forwarded to its plain `Button`. |
| `activeToolbarButtonStyle` | `CoreButtonStyle?` | Merged over [toolbarButtonStyle] while the button's format is on. |
| `toolbarIconStyle` | `CoreIconStyle?` | Each toolbar button's icon, forwarded to its `Icon`. |
| `toolbarItemSpacing` | `double?` | Space between the buttons of one group. |
| `toolbarGroupGapStyle` | `CoreGapStyle?` | Gap between toolbar groups. |
| `toolbarGapStyle` | `CoreGapStyle?` | Gap between the box and the rows above it — the upload rows. |
| `toolbarBackgroundColor` | `CoreColor?` | Fill of the toolbar strip at the top of the box. Not painted while the editor is disabled. |
| `toolbarPadding` | `CoreEdgeInsets?` | Inset of the toolbar's buttons inside its strip. |
| `toolbarDividerStyle` | `CoreDividerStyle?` | The toolbar's rules, forwarded to their `Divider`s: the horizontal line under the strip and the vertical line between groups. A disabled editor draws the line under the strip in `disabled-outline` unless this states a colour; the lines between groups keep the `Divider`'s own colour — as in the designer's disabled frame (#5951), where only the line under the strip changes. |
| `toolbarGroupDividerHeight` | `double?` | Length of the vertical line between two groups; 0 draws none, and the groups sit a gap apart. |
| `toolbarRowSpacing` | `double?` | Space between the rows of a toolbar that wraps. |
| `blockTypeButtonStyle` | `CoreButtonStyle?` | The block-type button (`CoreRichEditorFormat.blockType`), forwarded to its plain `Button` — the one toolbar button with a label. |
| `blockTypeMenuStyle` | `CoreDropdownMenuStyle?` | The menu the block-type button opens, forwarded to its `DropdownMenu`. |
| `selectionToolbarPanelStyle` | `CorePopupStyle?` | The panel of the toolbar that floats over a selection (`RichEditorSelectionToolbar`), passed to its `Popup`. The buttons inside it use the main toolbar's styles — [toolbarButtonStyle], [toolbarIconStyle], [blockTypeButtonStyle], the group gap and line — so the two toolbars always look the same. |
| `selectionToolbarOffset` | `double?` | Distance between the selection and the toolbar floating over it — above it, or below when there is no room above. |
| `tooltipStyle` | `CoreTooltipStyle?` | The toolbar buttons' tooltip, forwarded to `Tooltip`. |
| `kbdStyle` | `CoreKbdStyle?` | The shortcut keys inside the tooltip, forwarded to `Kbd`. |
| `blockSpacing` | `double?` | Space below each block of the document. |
| `listIndent` | `double?` | Inset of a list from the text's start, per level — a list inside a list is set in by one more of it. |
| `linkColor` | `CoreColor?` | Colour of link text and its underline. |
| `codeTextStyle` | `CoreTextStyle?` | Text of inline code and literal blocks. Its size, weight and family apply; the colour stays the text's own. |
| `codeBackgroundColor` | `CoreColor?` | Fill behind inline code and literal blocks. |
| `codePadding` | `CoreEdgeInsets?` | Inset of a literal block's text inside its box. |
| `quoteBarColor` | `CoreColor?` | Colour of the bar beside a quote. |
| `quoteBarWidth` | `double?` | Width of the bar beside a quote. |
| `quoteSpacing` | `double?` | Space between the quote bar and the quoted text. |
| `quoteTextColor` | `CoreColor?` | Colour of quoted text. |
| `ruleColor` | `CoreColor?` | Colour of a horizontal rule. |
| `completedTaskColor` | `CoreColor?` | Colour of a checked task's text. |
| `heading1TextStyle` | `CoreTextStyle?` | Text of a level-1 heading. Its size, weight and family apply; the colour stays the text's own. |
| `heading2TextStyle` | `CoreTextStyle?` | Text of a level-2 heading. Its size, weight and family apply; the colour stays the text's own. |
| `heading3TextStyle` | `CoreTextStyle?` | Text of a level-3 heading. Its size, weight and family apply; the colour stays the text's own. |
| `imageBorderRadius` | `CoreBorderRadius?` | Corner of an image. |
| `imageMaxHeight` | `double?` | Height an image is scaled down to when it is taller; a smaller image keeps its size. |
| `imageBackgroundColor` | `CoreColor?` | Fill behind an image: what shows while it loads, and through its transparent parts. |
| `uploadAlertStyle` | `CoreAlertStyle?` | The row above the box that reports an image upload under way or failed, and the note that stands in for an image that cannot be shown (Flutter), forwarded to their `Alert`. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 소스 주석에서 만들어집니다. `toolbarGapStyle` 은 상자와 업로드 줄 사이 말고도 Web 에서는 툴팁의 이름과 키캡 사이에 쓰입니다. Flutter 의 그 간격은 8 로 고정입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="rich-editor/related-text-area" title="TextArea">

서식 없는 여러 줄 입력입니다. RichEditor 의 상자 모양이 여기서 옵니다. [TextArea 보기](/components/text-area)

</Card>
<Card demo="rich-editor/related-kbd" title="Kbd">

툴팁 안의 단축키 키캡입니다. [Kbd 보기](/components/kbd)

</Card>
<Card demo="rich-editor/related-tooltip" title="Tooltip">

툴바 버튼의 이름과 단축키를 알립니다. [Tooltip 보기](/components/tooltip)

</Card>
<Card demo="rich-editor/related-alert" title="Alert">

이미지를 올리는 중이거나 실패했음을 알리는 줄입니다. [Alert 보기](/components/alert)

</Card>
<Card demo="rich-editor/related-popup" title="Popup">

선택 영역 위에 뜨는 툴바의 판입니다. [Popup 보기](/components/popup)

</Card>
</Cards>
