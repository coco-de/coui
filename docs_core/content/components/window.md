---
title: Window
description: 드래그 · 리사이즈 · 스냅을 지원하는 다중 창 매니저
template: v2
source: layout/window
---

# Window

`WindowNavigator` 는 정해진 영역 안에 여러 창을 겹쳐 놓고, `Window` 는 그 안의 창 하나를 설정합니다. 창은 타이틀 바를 끌어 옮기고, 네 변과 네 모서리를 끌어 크기를 바꾸며, 버튼으로 최소화 · 최대화 · 닫기를 합니다. 운영체제의 창을 새로 만들지 않고 앱 화면 안에 그립니다.

<a id="live-preview"></a>

## 플레이그라운드

타이틀 바를 끌어 옮기고, 변과 모서리를 끌어 크기를 바꾸고, 타이틀 바를 두 번 눌러 최대화해 보세요. 스위치를 바꾸면 창이 처음 상태로 다시 놓입니다. 닫은 창은 `창 다시 놓기` 버튼으로 되돌립니다.

<Playground component="window" />

<Note>

이 플레이그라운드는 낮은 영역이라 `showTopSnapBar: false` 로 위쪽 스냅 바를 껐고, 가장자리 스냅은 남아 있습니다. Flutter 에서는 영역 위 끝에서 124px 안에서 끌기 시작하면, 그 범위를 한 번 벗어난 뒤에 스냅이 켜집니다. `창 다시 놓기` 버튼은 미리보기에만 있어 코드에는 없습니다.

</Note>

## 구조

창 하나의 틀은 안쪽 부품인 `WindowPanel` 이 그립니다.

<Anatomy demo="window/anatomy">
<AnatomyItem select="[role=dialog]" side="left" name="window">

창 틀. 테두리 · 모서리 · 그림자를 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=dialog] > div:first-child" side="left" name="title bar">

타이틀 바. 끌어서 창을 옮기고, 두 번 눌러 최대화하거나 되돌립니다. 기본 높이는 32 입니다.

</AnatomyItem>
<AnatomyItem select="[role=dialog] > div:first-child > div:first-child > div" side="top" name="title">

제목 슬롯. 한 줄만 보이고 넘치면 말줄임표로 자릅니다. 두 플랫폼에서 뒤 창의 흐린 색을 받으려면 체인을 붙이지 않은 `Text` 를 넣습니다. 색을 정하는 체인은 그 색이 앞섭니다. `.bodyMedium` 같은 글자 역할 체인은 Flutter 에서 글자색까지 `onSurface` 로 정해 뒤 창에서도 흐려지지 않고, Web 에서는 흐린 색을 그대로 받습니다.

</AnatomyItem>
<AnatomyItem select="[role=dialog] > div:first-child > button" side="top" name="actions">

선택 슬롯. 창 컨트롤 앞에 추가 동작을 놓습니다. 컨트롤을 대신하지 않고 더해집니다.

</AnatomyItem>
<AnatomyItem select="[role=dialog] > div:first-child > div:last-child" side="top" name="controls">

최소화 · 최대화 · 닫기 버튼. `minimizable` · `maximizable` · `closable` 로 하나씩 끕니다.

</AnatomyItem>
<AnatomyItem select="[role=dialog] > div:last-child" side="right" name="content">

본문 슬롯. 창 높이보다 길면 이 안에서 스크롤합니다.

</AnatomyItem>
</Anatomy>

그림에 번호가 없는 부분도 있습니다.

- 크기 조절 영역 여덟 곳(네 변과 네 모서리)은 아무것도 그리지 않습니다.
- 위쪽 스냅 바와 스냅 미리보기는 창을 끄는 동안에 씁니다.
- `WindowNavigator` 의 `child` 는 모든 창 뒤에 놓이는 바탕입니다.

## 상태

<Preview demo="window/states" />

| 상태 | 정하는 것 | 모습 |
| --- | --- | --- |
| 떠 있음 | `bounds` | 정한 위치와 크기를 씁니다. |
| 최소화 | `minimized: true` | 위치와 폭은 그대로 두고 타이틀 바만 남깁니다. 최소화한 창을 모아 두는 작업 표시줄은 없습니다. |
| 최대화 | `maximized` 가 전체 영역 | 창 매니저를 가득 채우고 모서리를 각지게 그립니다. |
| 스냅 | `maximized` 가 일부 영역 | 그 비율의 영역을 차지하고 둥근 모서리는 남습니다. |
| 뒤 창 | 창 순서 | 제목을 흐린 색(`onSurfaceVariant`)으로 그립니다. |

전체 영역은 `CoreWindowContract.fullMaximizeRect` 입니다. 최소화 · 최대화 · 스냅한 동안에는 크기 조절 영역이 없습니다. 맨 앞 창과 뒤 창은 기본 모습에서 제목 색으로 구분합니다.

<a id="동작-스펙-behavior"></a>

## 창 조작

### 이동

- 타이틀 바를 끌어 옮깁니다. `draggable: false` 면 끌 수 없습니다.
- 창의 위치는 창 매니저 안으로 제한되지 않습니다. 밖으로 나간 부분은 잘립니다. 타이틀 바가 모두 밖에 놓인 창은 포인터로 다시 잡을 수 없습니다.
- 최대화하거나 스냅한 창은 18px 이상 끌어야 풀립니다. 전체 최대화한 창은 원래 크기로 돌아오며 타이틀 바 가운데가 포인터 아래에 놓입니다. 일부 영역에 스냅한 창은 그 크기를 유지한 채 따라옵니다.

### 크기 조절

- 네 변과 네 모서리를 끕니다. `resizable: false` 면 영역이 없습니다. 영역의 두께는 `resizeThickness`(기본 8)입니다.
- `constraints` 는 포인터로 크기를 조절할 때만 적용합니다. 기본값은 최소 200×200 이고 최대 제한이 없습니다.
- `bounds` 로 준 처음 크기와 컨트롤러로 넣는 크기는 제한하지 않습니다. 최소보다 작게 만든 창은 크기를 조절하는 순간 최소 크기로 커지므로, 작은 창에는 `constraints` 도 작게 줍니다. 이때 Flutter 는 끌고 있는 방향의 크기를, Web 은 폭과 높이를 모두 맞춥니다.
- 크기 조절도 창 매니저 안으로 제한되지 않습니다.

### 최소화 · 최대화 · 닫기

- 최소화 버튼은 최소화와 복원을 번갈아 합니다. 최소화한 동안에는 본문을 화면에서 빼고, 복원하면 새로 만듭니다. 본문 안에만 둔 입력값이나 스크롤 위치는 남지 않으므로, 유지할 값은 창 밖에서 보관합니다.
- 최대화 버튼과 타이틀 바 두 번 누르기는 전체 최대화와 떠 있는 상태를 번갈아 합니다. 스냅한 창은 떠 있는 상태로 돌아옵니다. 끌어서 스냅한 창의 떠 있는 위치는 끌어 놓은 자리입니다.
- 닫기 버튼을 누르면 창이 작아지며 흐려진 뒤 목록에서 지워집니다. `Window` 에는 닫힘을 알리는 콜백 파라미터가 없습니다.
- `closable` · `maximizable` · `minimizable` 은 화면의 컨트롤을 끕니다. 코드로 상태를 바꾸는 것까지 막지는 않습니다. `maximizable: false` 인 창도 스냅하면 최대화됩니다.

### 스냅

창을 끌다가 아래 위치에서 놓으면 `maximized` 가 그 영역으로 바뀝니다. 놓기 전에는 반투명 미리보기가 결과 영역을 보여 줍니다.

| 놓는 곳 | 결과 |
| --- | --- |
| 창 매니저 위쪽 띠 | 전체 최대화 |
| 위쪽 띠 아래의 왼쪽 · 오른쪽 띠 | 왼쪽 · 오른쪽 절반 |
| 위쪽 스냅 바의 칸 | 칸이 나타내는 영역 |

- 띠의 두께는 기본 32 입니다. 아래쪽 가장자리에는 스냅이 없습니다.
- 스냅이 켜지는 범위 안에서 끌기 시작하면, 포인터가 그 범위를 한 번 벗어난 뒤에 스냅이 켜집니다.
- 스냅 바(`showTopSnapBar`, 기본 `true`)는 창을 끄는 동안 위에 일부만 내려오고, 포인터가 가까이 가면 펼쳐집니다. Flutter 에서는 마우스나 스타일러스로 끌 때 펼쳐지고, 터치로 끌면 펼쳐지지 않습니다. 프리셋은 여섯 묶음입니다. 좌우 1/2 씩, 7:3, 절반과 4분의 1 두 칸, 4분할, 3등분, 2:3:2 입니다. 칸 위에서는 끌던 창이 작아집니다.
- 스냅 바 위에서는 칸이 반응합니다. 칸 사이라도 위쪽 띠 높이면 전체 최대화가 됩니다.
- `enableSnapping: false` 는 Web 에서만 스냅을 끕니다. Flutter 에서는 이 값과 관계없이 스냅됩니다.

<Note>

Flutter 의 스냅 바는 프리셋 묶음마다 창 매니저의 가로세로 비율을 따릅니다. 기본 스타일과 테마 크기 배율 1 에서 스냅 바에 필요한 폭은 `492 × 매니저 폭 ÷ 매니저 높이 + 58`px 입니다. 높이가 492px 이하면 폭과 관계없이 프리셋 줄이 넘치고, 더 높아도 이 값이 매니저 폭보다 크면 넘칩니다. 800×600 에는 들어갑니다. 낮거나 좁은 영역에서는 `showTopSnapBar: false` 를 씁니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

**이럴 때 씁니다**

- 편집 도구 · 대시보드 · 도구 팔레트처럼 여러 창을 함께 띄우고 옮길 때
- 창마다 끌어 옮기기 · 크기 조절 · 가장자리 스냅이 필요할 때
- 최소화 · 최대화 · 항상 위 층이 필요할 때

**다른 컴포넌트가 맞을 때**

- 타이틀 바가 있는 창 틀만 필요하고 상태를 직접 관리하면 [WindowPanel](/components/window-panel)
- 한 번의 확인을 받는 모달이면 [Dialog](/components/dialog)
- 화면 가장자리에서 밀어 여는 패널이면 [Drawer](/components/drawer)
- 문서 흐름 안의 콘텐츠 묶음이면 [Card](/components/card)

<a id="do"></a>
<a id="dont"></a>

<Cards columns="1">
<Card demo="window/do-extra-action" tone="do" eyebrow="이렇게 하세요" title="actions 에는 추가 동작">

최소화 · 최대화 · 닫기는 `Window` 가 이미 그립니다. `actions` 에는 저장처럼 창에 더할 동작을 넣습니다.

</Card>
<Card demo="window/dont-window-actions" tone="dont" eyebrow="이렇게 하지 마세요" title="actions 에 WindowActions 넣기">

`WindowActions` 는 창 컨트롤을 한 벌 더 그립니다. 타이틀 바에 같은 일을 하는 버튼이 두 개씩 생깁니다.

</Card>
<Card demo="window/do-move-buttons" tone="do" eyebrow="이렇게 하세요" title="끌기 말고도 옮길 길 두기">

이동 · 크기 조절 · 스냅은 포인터로 합니다. 키보드로도 필요한 위치와 크기는 `CoreWindowController` 를 바꾸는 버튼으로 함께 제공합니다.

</Card>
</Cards>

<a id="import"></a>
<a id="기본-사용법-basic-usage"></a>

### 가져오기와 기본 사용

<Code language="dart" title="Flutter">
import 'package:coui_flutter/coui_flutter.dart';

SizedBox(
  height: 600,
  child: WindowNavigator(
    initialWindows: [
      Window(
        bounds: const CoreWindowRect.fromLTWH(24, 24, 320, 240),
        title: const Text('창 1'),
        content: const Text('내용'),
      ),
    ],
    child: const Text('바탕'),
  ),
)
</Code>

<Code language="dart" title="Jaspr Web">
import 'package:coui_web/coui_web.dart';

div(
  styles: Styles(raw: {'height': '37.5rem'}),
  [
    WindowNavigator(
      initialWindows: [
        Window(
          bounds: const CoreWindowRect.fromLTWH(24, 24, 320, 240),
          title: const Text('창 1'),
          content: const Text('내용'),
        ),
      ],
      child: const Text('바탕'),
    ),
  ],
)
</Code>

`coui_web` 은 Jaspr 의 `Text` 를 뺀 나머지를 다시 내보냅니다. `package:jaspr/jaspr.dart` 를 접두어 없이 함께 가져오면 `Text` 이름이 겹칩니다.

### 컨트롤러를 직접 가질 때

저장해 둔 배치를 복원하거나 바깥 버튼으로 창을 옮길 때는 `Window.controlled` 에 `CoreWindowController` 를 넘깁니다. 처음 위치는 컨트롤러를 만들 때 정합니다.

### `bounds` 와 `controller` 를 함께 넘기지 않기

기본 `Window(...)` 생성자에 `controller` 를 넘기면 `bounds` · `maximized` · `minimized` · `closable` · `draggable` · `resizable` · `maximizable` · `minimizable` · `enableSnapping` · `constraints` 는 쓰이지 않고 컨트롤러의 값이 쓰입니다. `alwaysOnTop` 은 컨트롤러가 아니라 생성자의 값(기본 `false`)을 따르고, `resizeThickness` 도 생성자의 값입니다. `Window.controlled` 를 쓰면 상태가 한곳에 모입니다.

## 배치

### 창 매니저의 크기

`WindowNavigator` 는 부모의 크기를 채우므로 폭과 높이가 정해진 곳에 둡니다.

- Flutter: `Column` 의 직접 자식이나 세로 스크롤 안처럼 높이가 정해지지 않은 곳에 두면 레이아웃 오류가 납니다. `SizedBox` 나 `Expanded` 로 크기를 정합니다.
- Web: 루트가 부모의 100% 높이를 씁니다. 부모에 높이가 없으면 높이가 생기지 않아 창이 보이지 않을 수 있습니다.

### 위치와 크기

| 값 | 기준 |
| --- | --- |
| `bounds` | 창 매니저 왼쪽 위에서 잰 logical px(Web 은 CSS px) |
| `maximized` | 창 매니저 크기에 대한 0–1 비율 |
| 최소화한 창의 높이 | 타이틀 바 높이와 위아래 테두리 |

`bounds` 는 Flutter 의 테마 크기 배율이나 브라우저의 기본 글자 크기를 따라 커지지 않습니다. 매니저보다 큰 부분은 잘리므로, 좁은 화면에서는 처음 위치와 크기를 화면에 맞춰 정합니다.

### 창 순서

<Preview demo="window/layers" />

- `initialWindows` 의 첫 번째 창이 맨 앞입니다.
- 층은 일반 층과 항상 위 층 두 개입니다. `alwaysOnTop: true` 인 창은 목록에서 뒤에 적어도 일반 창 위에 놓입니다. 일반 창을 끄는 동안의 겹침 순서는 [플랫폼 차이](#플랫폼-차이)가 있습니다.
- 창 안을 누르면 그 창이 자기 층의 맨 앞으로 옵니다. `pushWindow` 로 더한 창도 자기 층의 맨 앞에 놓입니다.
- 제목은 층마다 맨 앞 창이 진합니다. 두 층에 창이 있으면 두 창의 제목이 진합니다.
- 바탕을 눌러도 창의 순서와 제목 색은 그대로입니다.
- `alwaysOnTop` 은 창을 만들 때 정합니다. [실행 중에 층 바꾸기](#실행-중에-층-바꾸기)에 지금 동작을 적었습니다.

## 프로그래밍 제어

### 창 하나의 상태

<Code language="dart" title="Flutter · Jaspr Web">
final controller = CoreWindowController(
  bounds: const CoreWindowRect.fromLTWH(0, 0, 320, 240),
);

final window = Window.controlled(
  controller: controller,
  title: const Text('편집기'),
  content: const Text('내용'),
);

// window 를 매니저에 놓은 뒤 값을 바꾸면 창에 반영됩니다.
controller.bounds = const CoreWindowRect.fromLTWH(100, 100, 320, 240);
controller.maximized = CoreWindowContract.fullMaximizeRect;
controller.maximized = null; // 원래 위치와 크기로
controller.minimized = true;
</Code>

사용자가 창을 옮기거나 크기를 바꾸고 컨트롤 버튼으로 최소화 · 최대화해도 컨트롤러의 값이 바뀝니다. `addListener` 로 바뀐 `CoreWindowState` 를 받고 `removeListener` 로 해제합니다. 닫힘은 `CoreWindowState` 에 들어 있지 않습니다.

### 창 매니저 다루기

<Code language="dart" title="Flutter">
final navigatorKey = GlobalKey<WindowNavigatorHandle>();

final host = WindowNavigator(key: navigatorKey, initialWindows: const []);

// host 가 화면에 놓인 뒤
navigatorKey.currentState?.pushWindow(
  Window(
    bounds: const CoreWindowRect.fromLTWH(24, 24, 320, 240),
    title: const Text('새 창'),
  ),
);
</Code>

<Code language="dart" title="Jaspr Web">
final navigatorKey = GlobalKey();

final host = WindowNavigator(key: navigatorKey, initialWindows: const []);

// host 가 화면에 놓인 뒤
navigatorKey.currentWindowNavigator?.pushWindow(
  Window(
    bounds: const CoreWindowRect.fromLTWH(24, 24, 320, 240),
    title: const Text('새 창'),
  ),
);
</Code>

| 하는 일 | 호출 |
| --- | --- |
| 새 창을 그 층의 맨 앞에 더하기 | `pushWindow(window)` |
| 창을 그 층의 맨 앞으로 옮기기 | `focusWindow(window)` |
| 포커스 표시 해제(창의 순서와 모습은 그대로) | `unfocusWindow(window)` |
| 포커스를 가진 창인지 확인 | `isFocused(window)` |
| 닫는 전환 없이 바로 지우기 | `removeWindow(window)` |
| 항상 위 층과 일반 층 사이에서 옮기기([제약](#실행-중에-층-바꾸기)) | `setAlwaysOnTop(window, value)` |
| 창 목록 읽기 | `windows` |

`isFocused` 는 아직 어느 창도 누르거나 `focusWindow` 를 부르지 않았으면 `false` 이고, `child` 로 놓은 바탕을 누르거나 `unfocusWindow` 를 부른 뒤에도 `false` 입니다. 그 밖에는 마지막으로 누르거나 `focusWindow` 를 부른 창이 속한 층의 맨 앞 창에서 `true` 입니다. `windows` 는 일반 층 다음에 항상 위 층이 오며, 각 층은 앞 창부터 적힌 읽기 전용 목록입니다.

### 목록은 처음 한 번 읽기

`WindowNavigator` 는 `initialWindows` 를 화면에 처음 놓을 때 읽습니다. 다시 그리면서 다른 목록을 넘겨도 창은 바뀌지 않으므로 핸들로 더하고 지웁니다. `Window` 에 넘긴 `title` · `content` 와 상태 값도 그때의 것을 계속 씁니다. 바깥 상태를 따라 바뀌는 본문은 `content` 안에 그 상태를 직접 구독하는 위젯을 넣고, 위치와 크기는 컨트롤러로 바꿉니다.

### 닫기

| 하는 일 | Flutter | Web |
| --- | --- | --- |
| 닫는 전환과 함께 닫기 | `window.handle.close()` | `window.close()` |
| 닫기 시작했는지 확인 | `window.closed` | `window.isClosed` |

Flutter 의 `window.handle` 은 창이 화면에 있을 때(`window.mounted`) 씁니다. `window.closed` 는 `ValueNotifier<bool>` 이라 리스너로 닫기 시작을 알 수 있습니다. 두 플랫폼 모두 한 번 닫은 `Window` 객체는 다시 `pushWindow` 해도 보이지 않으므로 새로 만듭니다.

Flutter 의 `window.handle` 에 있는 `focused` 는 포커스 여부를 알려 주지 않고, 창 상태의 `alwaysOnTop` 값을 돌려줍니다. 포커스는 매니저의 `isFocused` 로 확인합니다. `controller` 없이 `Window(alwaysOnTop: true)` 로 만든 창은 항상 위 층에 놓여도 이 상태값이 `false` 라서, `window.handle.alwaysOnTop` 도 `false` 입니다.

### 실행 중에 층 바꾸기

층은 창을 만들 때의 `alwaysOnTop` 으로 정하는 것이 안정적입니다. 실행 중에 `setAlwaysOnTop` 이나 `controller.alwaysOnTop` 으로 바꾸는 경로는 지금 다음처럼 동작합니다.

- `setAlwaysOnTop` 은 창의 `alwaysOnTop` 값을 바꾸지 않습니다. 층은 계속 그 값(`Window(...)` 는 생성자의 값, `Window.controlled` 는 컨트롤러의 값)으로 판단하므로, 그 값과 다른 층으로 옮긴 뒤 창을 누르면 같은 창이 두 층에 함께 들어갑니다.
- Flutter 에서는 `setAlwaysOnTop` 을 부르거나 `controller.alwaysOnTop` 을 바꿔도 창 매니저가 바로 다시 그려지지 않습니다.
- Web 에서 `controller.alwaysOnTop` 을 바꾸면 창 목록의 층은 옮겨지지 않습니다. `Window.controlled` 로 만든 창은 그 뒤 누르면 두 층에 함께 들어갑니다.

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-windowstyle"></a>
<a id="테마"></a>

## 테마와 스타일

### `windowStyle` 슬롯

동작은 `Window` 의 파라미터로, 겉모습은 창 하나의 `windowStyle` 이나 프로젝트 전체의 `CoreWindowTheme.style` 로 정합니다. 둘 다 `CoreWindowStyle` 을 받습니다.

| 바꾸는 것 | 필드 |
| --- | --- |
| 타이틀 바 · 본문 여백 · 테두리 · 모서리 · 그림자 · 컨트롤 버튼 | `panelStyle` |
| 뒤 창의 제목 | `unfocusedTitleStyle` |
| 전환 시간과 크기 | `windowTransition` · `closeAnimationScaleMin` · `closeAnimationScaleMax` |
| 스냅 바 칸 위에서 끌던 창이 작아지는 비율 | `minimizedScale` |
| 스냅 바와 스냅 미리보기(테마에서만) | 이름이 `snap` 으로 시작하는 필드 |

`panelStyle` 은 안쪽 부품 `WindowPanel` 의 스타일(`CoreWindowPanelStyle`)입니다.

<Split>

<Code language="dart" title="창 하나">
Window(
  bounds: const CoreWindowRect.fromLTWH(0, 0, 320, 240),
  title: const Text('편집기'),
  windowStyle: const CoreWindowStyle(
    panelStyle: CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      titleBarColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    ),
  ),
)
</Code>

<Code language="dart" title="프로젝트 전체">
const CoreComponentTheme(
  window: CoreWindowTheme(
    style: CoreWindowStyle(
      panelStyle: CoreWindowPanelStyle(
        titleBarHeight: CoreSpace.space36,
      ),
      snapPreviewBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  ),
)
</Code>

</Split>

`CoreComponentTheme` 은 앱 테마의 `coreComponentTheme` 에 넣습니다. `CoreWindowStyle` 의 최상위에는 창 틀의 `borderRadius` 가 없습니다. `snapPreviewBorderRadius` 는 스냅 미리보기, `snapBarBorderRadius` 는 스냅 바의 모서리입니다. 스냅 칸은 묶음 바깥쪽 모서리를 `snapTileBorderRadius` 로, 이웃한 칸과 맞닿는 모서리를 `snapTileInnerBorderRadius` 로 정합니다. 스냅 바의 그림자는 `snapBarShadow` 입니다.

### 값이 정해지는 순서

창의 값은 뒤에 적힌 것이 앞의 것을 덮습니다.

1. `CoreWindowStyle` 의 기본값
2. `CoreWindowTheme.style`
3. 창의 `windowStyle`

창 틀의 값은 `WindowPanel` 기본값, `CoreWindowPanelTheme.style`, `Window` 가 넘기는 `panelStyle` 순서로 정해집니다.

- `Window` 는 모서리 기본값을 항상 `panelStyle` 에 담아 넘깁니다. 그래서 `CoreWindowPanelTheme` 의 `borderRadius` 는 창에 닿지 않습니다. 창의 모서리는 `CoreWindowTheme` 이나 `windowStyle` 의 `panelStyle` 로 바꿉니다.
- 전체 최대화한 창의 모서리는 항상 0 입니다.
- 뒤 창에는 `panelStyle` 의 `titleStyle` 대신 `unfocusedTitleStyle` 을 넘깁니다. `panelStyle` 에 적은 제목 글꼴이나 굵기는 뒤 창에 남지 않습니다.

크기 조절 영역은 아무것도 그리지 않는 동작 값이라 스타일이 아니라 `resizeThickness` 파라미터로 정합니다.

<Code language="dart" title="Flutter · Jaspr Web">
Window(
  bounds: const CoreWindowRect.fromLTWH(0, 0, 320, 240),
  resizeThickness: CoreSpace.space10,
)
</Code>

<a id="테마-커스터마이징-theme-customization"></a>
<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

`withStyle` 은 `windowStyle` 에 값을 합친 새 `Window` 를 돌려줍니다. 창 매니저에 넘기기 전에 씁니다. `Window.controlled` 에 붙인 사본은 컨트롤러의 `alwaysOnTop` 을 따르지 않고 일반 층으로 판단합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class WindowChainExample extends StatefulWidget {
  const WindowChainExample({super.key});

  @override
  State<WindowChainExample> createState() => _WindowChainExampleState();
}

class _WindowChainExampleState extends State<WindowChainExample> {
  final GlobalKey<WindowNavigatorHandle> _navigatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(height: 600),
          child: WindowNavigator(
            key: _navigatorKey,
            initialWindows: [
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: const Text('창 1'),
                content: const Center(child: Text('창 1')),
              ).withStyle(
                const CoreWindowStyle(
                  titleBarHeight: CoreSpace.space48,
                  unfocusedTitleStyle: CoreTextStyle(
                    color: CoreColor.token(CoreColors.outline),
                  ),
                  panelStyle: CoreWindowPanelStyle(
                    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
                    borderColor: CoreColor.token(CoreColors.primary),
                    containerBorderWidth: CoreStrokeWidth.stroke2,
                  ),
                ),
              ),
              Window(
                bounds: const CoreWindowRect.fromLTWH(200, 0, 200, 200),
                title: const Text('창 2'),
                content: const Center(child: Text('창 2')),
              ),
            ],
            child: const Center(child: Text('데스크톱')),
          ),
        ),
        const Gap.space8(),
        Button(
          onPressed: () {
            final nav = _navigatorKey.currentState;
            if (nav == null) return;
            final index = nav.windows.length + 1;
            nav.pushWindow(
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: Text('창 $index'),
                content: Center(child: Text('창 $index')),
              ),
            );
          },
          child: const Text('창 추가'),
        ),
      ],
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class WindowChainExample extends StatefulComponent {
  const WindowChainExample({super.key});

  @override
  State<WindowChainExample> createState() => _WindowChainExampleState();
}

class _WindowChainExampleState extends State<WindowChainExample> {
  final GlobalKey _navigatorKey = GlobalKey();

  @override
  Component build(BuildContext context) {
    return div(
      [
        OutlinedContainer(
          containerStyle: const CoreOutlinedContainerStyle(height: 600),
          child: WindowNavigator(
            key: _navigatorKey,
            initialWindows: [
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: const Text('창 1'),
                content: div(
                  [const Text('창 1')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ).withStyle(
                const CoreWindowStyle(
                  titleBarHeight: CoreSpace.space48,
                  unfocusedTitleStyle: CoreTextStyle(
                    color: CoreColor.token(CoreColors.outline),
                  ),
                  panelStyle: CoreWindowPanelStyle(
                    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
                    borderColor: CoreColor.token(CoreColors.primary),
                    containerBorderWidth: CoreStrokeWidth.stroke2,
                  ),
                ),
              ),
              Window(
                bounds: const CoreWindowRect.fromLTWH(200, 0, 200, 200),
                title: const Text('창 2'),
                content: div(
                  [const Text('창 2')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ),
            ],
            child: div(
              [const Text('데스크톱')],
              classes: 'flex items-center justify-center w-full h-full',
            ),
          ),
        ),
        Gap.space8(),
        Button(
          onPressed: () {
            final nav = _navigatorKey.currentWindowNavigator;
            if (nav == null) return;
            final index = nav.windows.length + 1;
            nav.pushWindow(
              Window(
                bounds: const CoreWindowRect.fromLTWH(0, 0, 200, 200),
                title: Text('창 $index'),
                content: div(
                  [Text('창 $index')],
                  classes: 'flex items-center justify-center w-full h-full',
                ),
              ),
            );
          },
          child: const Text('창 추가'),
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

<Note>

위 예제의 `CoreWindowStyle` 에 적은 `titleBarHeight` 는 보이는 타이틀 바의 높이를 바꾸지 않습니다. 높이는 `panelStyle` 안의 `titleBarHeight` 로 바꿉니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

### 역할

- `Window` 의 창 틀 역할과 이름은 안쪽의 `WindowPanel` 이 붙입니다. Web 은 `role="dialog"` 이고 `aria-modal` 은 붙이지 않습니다. Flutter 는 시맨틱 컨테이너입니다. 둘 다 현재 언어의 "창" 이라는 이름을 붙입니다.
- 타이틀 바의 컨트롤은 버튼이며 현재 언어의 최소화 · 최대화 · 닫기 이름을 가집니다. `WindowActions` 의 버튼에도 같은 이름이 있습니다.
- 스냅 바 · 스냅 칸 · 크기 조절 영역에는 역할과 이름이 없습니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Enter` | 포커스한 타이틀 바 버튼을 실행합니다. |
| `Space` | 포커스한 타이틀 바 버튼을 실행합니다. |
| `Escape` | 창에는 이 키의 동작이 없습니다. |

두 키는 버튼의 동작입니다. 창을 앞으로 올리기 · 옮기기 · 크기 조절 · 스냅 · 창 사이를 건너뛰기에는 전용 키가 없습니다. 최대화와 복원은 타이틀 바 두 번 누르기 대신 최대화 버튼으로 할 수 있습니다.

### 스크린 리더

- 모든 창에 같은 "창" 라벨을 붙입니다. `title` 은 창 안의 글자로 남지만 이 라벨로 쓰지 않고, 라벨을 바꾸는 `Window` 파라미터도 없습니다. Web 의 dialog 이름은 언제나 이 라벨입니다.
- 버튼 이름은 상태에 따라 바뀌지 않습니다. 최소화한 창의 버튼은 계속 "최소화", 최대화한 창의 버튼은 계속 "최대화" 이며 눌림이나 펼침 상태 속성도 없습니다.
- 창이 열리거나 닫히거나 옮겨져도 따로 알리지 않습니다.

### 포커스 관리

- 창을 더하거나 앞으로 올리거나 최소화하거나 닫을 때 키보드 포커스를 옮기지 않습니다. `focusWindow` 는 창 순서를 바꾸는 호출이며 입력 포커스를 주지 않습니다.
- 닫은 뒤 이전 위치로 포커스를 되돌리지 않습니다.
- 포커스를 창 안에 가두지 않고, 뒤 창을 비활성으로 만들지 않습니다.
- 창 안에서 포커스를 받는 것은 타이틀 바 버튼과 `actions` · `content` 에 넣은 컨트롤입니다.
- Web 은 창을 앞으로 올리면 문서 안의 창 순서가 바뀌어 `Tab` 순서도 바뀝니다.

### 알려진 제약

- 이동 · 크기 조절 · 스냅에는 키보드 조작이 없고 `Escape` 로 닫을 수 없습니다. 필요한 조작은 `CoreWindowController` 를 바꾸는 컨트롤로 따로 제공해야 합니다.
- 뒤에 있는 창의 버튼과 콘텐츠도 키보드와 보조 기술에서 닿을 수 있는 상태로 남습니다.
- `title` 을 창의 라벨로 쓰지 않습니다. Web 에서는 여러 창의 dialog 이름이 모두 같아 이름으로 구분할 수 없습니다.
- 최소화 · 최대화 버튼의 이름과 속성은 지금 상태를 알려 주지 않습니다.
- 크기 조절 영역의 기본 두께 8px 은 최소 포인터 대상 크기 24px 보다 작습니다. 타이틀 바 버튼은 20×20 으로 그리고 누를 수 있는 범위를 24px 까지 넓힙니다.
- Web 은 닫는 전환이 끝나야 창을 지웁니다. 동작 줄이기(`prefers-reduced-motion: reduce`)를 켜면 `windowTransition` 이 500ms 이하인 창(기본값 포함)은 이 전환이 없어져, 닫은 창이 보이지 않게 된 뒤에도 문서에서 지워지지 않습니다. 남은 창은 포인터와 `Tab` 을 받을 수 있고 매니저의 `windows` 에도 남습니다. `windowTransition` 을 `Duration.zero` 로 둔 창도 닫는 전환이 없어 같은 상태로 남을 수 있습니다. 매니저의 `removeWindow` 를 부르면 지워집니다.
- Web 의 Chrome 강제 색 모드 에뮬레이션에서는 맨 앞 창과 뒤 창의 제목이 같은 색으로 보여, 제목 색으로는 둘을 구분할 수 없었습니다.

동작 줄이기 · 고대비처럼 모든 컴포넌트에 함께 적용되는 항목은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Web |
| --- | --- | --- |
| 창을 놓는 방식 | 위젯 트리의 층에 위치를 지정해 그립니다. | 매니저의 루트 요소 안에 위치를 지정한 요소를 둡니다. |
| 창 순서 | 그리는 순서 | 문서 순서와 층별 `z-index` |
| 일반 층의 창을 끄는 동안 | 끄는 창과 그때의 스냅 미리보기 · 스냅 바가 항상 위 창 아래에 그려집니다. | 끄는 창과 스냅 미리보기 · 스냅 바가 항상 위 창 위에 그려집니다. |
| 터치로 끌 때의 스냅 바 | 펼쳐지지 않습니다. 마우스나 스타일러스로 끌 때 펼쳐집니다. | 포인터 종류를 가리지 않고 끄는 위치로 펼침을 정합니다. |
| `enableSnapping: false` | 효과가 없습니다. | 스냅이 꺼집니다. 스냅 바는 일부만 내려오고 펼쳐지지 않습니다. |
| 매니저 밖의 좌우로 끌어 놓기 | 스냅하지 않습니다. | 위쪽 띠보다 아래라면 그쪽 절반으로 스냅합니다. |
| 스냅 바를 끈 매니저의 스냅 시작 | 위에서 124px 안이나 좌우 띠에서 끌기 시작하면 그 범위를 벗어난 뒤에 켜집니다. | 위쪽 띠나 좌우 띠에서 끌기 시작한 때에 그 범위를 벗어나야 합니다. |
| 한 문서에 매니저가 여러 개 | 각 매니저의 크기로 계산합니다. | 최대화 · 스냅의 크기와 위치를 문서의 첫 매니저를 기준으로 계산합니다. 한 페이지에는 하나만 둡니다. |
| 매니저 크기가 바뀔 때 | 최대화 · 스냅한 창이 새 크기를 따릅니다. | 매니저가 크기 변화를 감지하지 않아, 다음에 다시 그릴 때까지 이전 크기로 남습니다. |
| 서버 렌더 | 해당 없음 | 처음부터 최대화 · 스냅한 창은 서버가 만든 HTML 에서 크기가 0 입니다. |
| 열기와 닫기의 전환 시간 | `windowTransition` 을 쓰지 않고 150ms 입니다. | `windowTransition` 을 씁니다. |
| 동작 줄이기를 켠 상태의 닫기 | 창을 지웁니다. | `windowTransition` 이 500ms 이하면(기본값 포함) 보이지 않는 창이 남습니다. |
| `actions` 의 버튼을 빠르게 두 번 누르기 | 창은 최대화되지 않습니다. | 최대화할 수 있는 창이면 타이틀 바 두 번 누르기로도 처리되어 최대화나 복원이 일어납니다. |
| 폭을 채우지 않는 본문 | 가로 가운데에 놓입니다. | 왼쪽부터 놓입니다. |
| 본문의 높이 | 세로 스크롤 안이라 높이의 상한이 없습니다. `content` 로 둔 `Column` 의 `Expanded` 나 높이를 정하지 않은 `ListView` 는 레이아웃 오류를 냅니다. | 본문 영역 안에서 스크롤합니다. |
| 크기 조절 영역의 두께 | 테마 크기 배율을 곱합니다. | CSS px 그대로입니다. |
| 닫기와 창 핸들 | `window.handle` · `window.closed` · `window.mounted` | `window.close()` · `window.isClosed` |

크기와 최대화 같은 창 상태는 두 플랫폼이 같은 `CoreWindowController` 로 다루고, 창 틀은 각 플랫폼의 `WindowPanel` 이 그립니다.

<a id="props-parameters"></a>

## API

아래 타입의 `W` 는 Flutter 에서 `Widget`, Web 에서 `Component` 입니다.

### `Window` 생성자

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `title` | `W?` | `null` | 타이틀 바의 제목 |
| `actions` | `W?` | `null` | 창 컨트롤 앞에 더하는 동작 |
| `content` | `W?` | `null` | 본문 |
| `bounds` | `CoreWindowRect?` | 필수 | 처음 위치와 크기 |
| `controller` | `CoreWindowController?` | `null` | 창 상태를 가진 컨트롤러 |
| `maximized` | `CoreWindowRect?` | `null` | 처음 최대화 · 스냅 영역(0–1 비율) |
| `minimized` | `bool` | `false` | 최소화한 채로 시작 |
| `alwaysOnTop` | `bool` | `false` | 항상 위 층에 놓기 |
| `draggable` | `bool` | `true` | 타이틀 바를 끌어 옮기기 |
| `resizable` | `bool` | `true` | 변과 모서리로 크기 조절 |
| `resizeThickness` | `double` | `CoreWindowContract.defaultResizeThickness` (8) | 크기 조절 영역의 두께 |
| `constraints` | `CoreWindowConstraints` | `kCoreDefaultWindowConstraints` (최소 200×200) | 크기를 조절할 때의 최소 · 최대 크기 |
| `enableSnapping` | `bool` | `true` | 끌어서 스냅하기. Web 에서만 `false` 가 적용됩니다. |
| `closable` | `bool` | `true` | 닫기 버튼 |
| `maximizable` | `bool` | `true` | 최대화 버튼과 타이틀 바 두 번 누르기 |
| `minimizable` | `bool` | `true` | 최소화 버튼 |
| `windowStyle` | `CoreWindowStyle?` | `null` | 창의 겉모습과 전환 값 |

`Window.controlled` 는 `controller`(필수) · `title` · `actions` · `content` · `windowStyle` 을 받습니다. 나머지 상태는 컨트롤러가 정합니다. 이 생성자로 만든 객체의 상태 속성은 `null` 이고, `resizeThickness` 는 기본 두께로 그립니다.

### `WindowNavigator`

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `initialWindows` | `List<Window>` | 필수 | 처음 놓을 창. 첫 번째가 맨 앞입니다. |
| `child` | `W?` | `null` | 창 뒤의 바탕. 매니저를 채웁니다. |
| `showTopSnapBar` | `bool` | `true` | 창을 끄는 동안 위쪽 스냅 바 보이기 |

두 플랫폼 모두 `key` 를 받습니다. Web 은 매니저의 루트 `div` 에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers` 와 `onClick` · `onKeyDown` · `onKeyUp` · `onMouseEnter` · `onMouseLeave` 도 받습니다. `onInput` · `onChange` 는 생성자에 있지만, 넘긴 함수가 불리지 않습니다. 안의 입력에서 올라오는 `input` · `change` 이벤트는 `eventHandlers` 로 받습니다.

### `CoreWindowRect`

`CoreWindowRect.fromLTWH(left, top, width, height)` 로 만듭니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `left` | `double` | 필수 | 왼쪽 위치 |
| `top` | `double` | 필수 | 위쪽 위치 |
| `width` | `double` | 필수 | 폭 |
| `height` | `double` | 필수 | 높이 |

### `CoreWindowConstraints`

`CoreWindowConstraints.minimum(size)` 는 최소 폭과 높이를 함께 정합니다.

| 속성 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `minWidth` | `double` | `0` | 최소 폭 |
| `maxWidth` | `double` | `double.infinity` | 최대 폭 |
| `minHeight` | `double` | `0` | 최소 높이 |
| `maxHeight` | `double` | `double.infinity` | 최대 높이 |

최소 폭을 줄일 때는 타이틀 바의 버튼이 들어갈 폭을 남겨 둡니다.

### `CoreWindowController`

생성자는 `bounds`(필수)와, `Window` 와 이름 · 기본값이 같은 상태 값(`alwaysOnTop` · `closable` · `constraints` · `draggable` · `enableSnapping` · `maximizable` · `maximized` · `minimizable` · `minimized` · `resizable`)을 받습니다. 각 값은 같은 이름의 속성으로 읽고 씁니다. `value` 는 전체 상태이고 `update` 로 한 번에 바꿉니다. `value` 에 직접 대입하면 리스너에 알리지 않습니다. `addListener` · `removeListener` · `dispose` 로 리스너를 관리합니다.

### `WindowActions`

둘러싼 창의 최소화 · 최대화 · 닫기 동작을 하는 버튼 줄입니다. 창에서 꺼 둔 동작의 버튼은 그리지 않습니다. 따로 받는 설정은 없습니다. `Window` 는 타이틀 바에 컨트롤을 이미 그리므로, 본문처럼 다른 위치에 버튼 줄이 더 필요할 때 씁니다. 창 밖에 두면 세 버튼이 보이지만 눌러도 하는 일이 없습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreWindowStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `titleBarHeight` | `double?` | Title bar height in logical pixels. |
| `snapPreviewBorderRadius` | `CoreBorderRadius?` | Border radius for the floating snap-preview overlay (semi-transparent surface shown while dragging a window into a snap zone). Overrides [defaultSnapPreviewBorderRadius] when set. |
| `snapBarBorderRadius` | `CoreBorderRadius?` | Border radius for the snap-bar banner container (the rounded strip that drops down from the navigator top while a window is being dragged). Overrides [defaultSnapBarBorderRadius] when set. |
| `snapTileBorderRadius` | `CoreBorderRadius?` | Corner of a snap-bar tile on the preset's outer edge. Overrides [defaultSnapTileBorderRadius] when set. |
| `snapTileInnerBorderRadius` | `CoreBorderRadius?` | Corner of a snap-bar tile on an edge it shares with a sibling tile. Overrides [defaultSnapTileInnerBorderRadius] when set. |
| `snapBarShadow` | `List<CoreShadowLayer>?` | Drop shadow of the snap-bar banner (tinted by the `shadow` token). Overrides [defaultSnapBarShadow] when set. |
| `snapBarTileSpacing` | `double?` | Spacing between adjacent tiles in the snap-bar grid (logical px). Flutter applies it as `Row.spacing`; Web sets the same value as the flex container's CSS `gap`. Overrides [defaultSnapBarTileSpacing] when set. |
| `snapBarPadding` | `CoreEdgeInsets?` | Inner padding of the snap-bar banner / snap-preview container. Overrides [defaultSnapBarPadding] when set. |
| `snapPreviewBorderColor` | `CoreColor?` | Outline colour of the snap-preview overlay border. Overrides [defaultSnapPreviewBorderColor] when set. |
| `snapPreviewBackgroundColor` | `CoreColor?` | Semi-transparent surface fill of the snap-preview overlay. Overrides [defaultSnapPreviewBackgroundColor] when set. |
| `snapBarBorderColor` | `CoreColor?` | Outline colour of the snap-bar banner container border. Overrides [defaultSnapBarBorderColor] when set. |
| `snapBarBackgroundColor` | `CoreColor?` | Surface fill of the snap-bar banner container. Overrides [defaultSnapBarBackgroundColor] when set. |
| `snapBarBorderWidth` | `double?` | Border width of the snap-bar banner container. Overrides [defaultSnapBarBorderWidth] when set. |
| `snapBarHeight` | `double?` | Height of the snap-bar banner (logical/CSS px). Overrides [defaultSnapBarHeight] when set. |
| `snapBarTopOffset` | `double?` | Top offset of the expanded snap-bar banner (logical/CSS px). Overrides [defaultSnapBarTopOffset] when set. |
| `snapBarHiddenOffset` | `double?` | Resting "peek" pose of the hidden snap-bar as a fraction of its height (−1 = fully hidden, 0 = fully shown); also the start of the content fade-in. Overrides [defaultSnapBarHiddenOffset] when set. |
| `snapBarAnimation` | `Duration?` | Snap-bar drop-down show/hide animation duration. Overrides [defaultSnapBarAnimation] when set. |
| `snapTileSpacing` | `double?` | Inner gap between abutting snap-bar tiles (logical px). Overrides [defaultSnapTileSpacing] when set. |
| `windowTransition` | `Duration?` | Window open / close / maximize transition duration. Overrides [defaultWindowTransition] when set. |
| `minimizedScale` | `double?` | Scale of the window while minified during a drag-snap. Overrides [defaultMinimizedScale] when set. |
| `closeAnimationScaleMin` | `double?` | Lower bound of the close-animation scale tween. Overrides [defaultCloseAnimationScaleMin] when set. |
| `closeAnimationScaleMax` | `double?` | Upper bound of the close-animation scale tween. Overrides [defaultCloseAnimationScaleMax] when set. |
| `snapPreviewBlurSigma` | `double?` | Gaussian σ of the snap-preview ghost's backdrop blur. Overrides [defaultSnapPreviewBlurSigma] when set. |
| `snapTileBorderColor` | `CoreColor?` | Outline colour of each snap-bar tile border. Overrides [defaultSnapTileBorderColor] when set. |
| `snapTileBorderWidth` | `double?` | Border width of each snap-bar tile in logical/CSS px. Overrides [defaultSnapTileBorderWidth] when set. |
| `snapTileBackgroundColor` | `CoreColor?` | Fill of a snap-bar tile at rest. Overrides [defaultSnapTileBackgroundColor] when set. |
| `snapTileHoverBackgroundColor` | `CoreColor?` | Fill of a snap-bar tile while hovered. Overrides [defaultSnapTileHoverBackgroundColor] when set. |
| `unfocusedTitleStyle` | `CoreTextStyle?` | Title-text overlay merged onto the panel's `titleStyle` for every window EXCEPT the frontmost one — both platforms dim unfocused titles with it (reference behaviour: focused = onSurface, rest = muted). Overrides [defaultUnfocusedTitleStyle] when set. |
| `panelStyle` | `CoreWindowPanelStyle?` | Look of the `WindowPanel` inside the window, passed to the panel as is. Laid over [defaultPanelStyle]; while the window is fully maximized, its corner radius is forced to zero. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명과 지금 동작이 다른 필드는 다음과 같습니다.

- `titleBarHeight`: 보이는 타이틀 바 높이는 바뀌지 않습니다. 높이는 `panelStyle` 안의 같은 이름 필드로 바꿉니다. 이 값은 최대화한 창을 끌어 되돌릴 때의 위치 계산에 쓰이고, 테마에 넣은 값은 스냅 띠의 두께도 정합니다.
- 이름이 `snap` 으로 시작하는 필드: `CoreWindowTheme.style` 에서 읽습니다. 창의 `windowStyle` 에 넣으면 적용되지 않습니다.
- `snapBarAnimation`: Flutter 에서는 스냅 바가 펼쳐질 때의 시간입니다. 접히거나 숨을 때는 150ms 입니다.
- `windowTransition`: Flutter 에서는 창의 열기와 닫기에 적용되지 않습니다. 최대화 · 스냅 · 복원에 씁니다. 스냅 미리보기의 이동은 두 플랫폼 모두 테마에 넣은 값을 따릅니다.
- `closeAnimationScaleMin` 은 닫힐 때 마지막으로 줄어드는 크기이고, `closeAnimationScaleMax` 는 열릴 때 시작하는 크기입니다. 두 플랫폼 모두 두 값을 씁니다.
- `unfocusedTitleStyle`: `windowStyle` 이나 창 테마의 `panelStyle` 에 적은 `titleStyle` 과 합치지 않고 그 자리를 대신합니다.

</Note>

## 관련 컴포넌트

<Cards columns="2">
<Card title="WindowPanel" href="/components/window-panel" more="문서 보기">

타이틀 바가 있는 창 틀입니다. 이동과 크기 같은 상태는 직접 관리합니다.

</Card>
<Card title="Dialog" href="/components/dialog" more="문서 보기">

확인이나 입력을 받는 동안 흐름을 멈추는 대화상자입니다.

</Card>
<Card title="Drawer" href="/components/drawer" more="문서 보기">

화면 가장자리에서 밀어 여는 패널입니다.

</Card>
<Card title="Resizable" href="/components/resizable" more="문서 보기">

겹치지 않게 나눈 영역의 크기 비율을 끌어서 바꿉니다.

</Card>
</Cards>
