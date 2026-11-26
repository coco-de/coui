---
title: Toast
description: 토스트 알림 컴포넌트
category: overlay
platforms: [flutter, web]
related: [alert, banner, dialog]
tags: [feedback, notification, temporary]
template: v2
source: overlay/toast
---

# Toast

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 토스트 카드를 확인하고, 만들어진 코드를 복사하세요. Flutter 미리보기에서는 **띄워 보기**로 같은 속성의 토스트를 실제로 띄워 볼 수 있습니다.

<Playground component="toast" />

`Toast`는 알림 카드 하나입니다. 카드 스스로는 자리를 잡거나 시간이 지나 사라지지 않습니다. Flutter에서는 `showToast`와 `ToastLayer`가 띄우고 쌓고 닫으며, Web에는 띄우는 함수가 없어 앱이 카드를 놓고 걷어냅니다([띄우기](#띄우기)).

<Note>

무대의 카드는 놓인 자리에 그려지는 실제 `Toast`입니다. **띄워 보기**는 Flutter 미리보기에만 있습니다. 누르면 같은 속성의 토스트가 Flutter 화면의 오른쪽 아래(이 사이트에서는 Flutter 미리보기 안)에 나타나고, 5초 뒤 닫힙니다(포인터를 올려 두면 멈춥니다). 띄운 토스트는 닫기 버튼이나 행동 버튼을 눌러도 닫히며, 만들어지는 Flutter 코드에도 그 연결(`overlay.close`)이 들어 있습니다. 여러 번 누르면 쌓이는 모습도 볼 수 있습니다. 띄우는 함수가 Flutter에만 있어서, 만들어지는 코드도 Flutter는 `showToast` 호출이고 Web은 카드 하나입니다.

</Note>

## 구조

토스트는 말풍선 패널 안에 아이콘 · 글(message와 그 아래 description) · 행동 · 닫기 버튼을 놓습니다. message만 필수이고 나머지는 선택입니다.

<Anatomy demo="toast/anatomy">
<AnatomyItem part="container" name="Container">

패널. 채움은 `inverseSurface`, 글자색은 `inverseOnSurface`, 모서리는 16, 테두리는 없고, 그림자는 `shadow-sm` 단계입니다. 최소 높이는 44입니다. 안쪽 여백은 위아래 14 · 좌우 18이고, 닫기 버튼이 있으면 끝 쪽이 48입니다.

</AnatomyItem>
<AnatomyItem part="leading" name="icon">

variant가 정하는 아이콘(16)입니다. 색은 글자색과 같습니다. neutral에는 없고, `showIcon: false`면 그리지 않습니다.

</AnatomyItem>
<AnatomyItem part="label" name="message">

알림의 첫 줄이며 필수입니다. 글자는 `labelLarge`에 굵기 600입니다. 길면 줄을 바꿉니다.

</AnatomyItem>
<AnatomyItem select="[role='status'] > div > div:last-child > span" side="right" name="description">

message 아래의 보조 설명입니다. 글자는 `bodySmall`, 색은 `inverseOnSurface`의 75%입니다.

</AnatomyItem>
<AnatomyItem select="[role='status'] > button" name="action">

글 뒤에 놓는 행동입니다. 보통 `plain` `Button`을 넣습니다.

</AnatomyItem>
<AnatomyItem select="button[aria-label]" side="right" name="onDismiss">

`onDismiss`를 넘기면 생기는 닫기 버튼입니다. 기본 밀도에서 40 × 40 원(밀도를 따라 compact 32 · spacious 48) 안에 ✕(18)가 있고, 패널 끝에서 8 들어와 패널 높이의 가운데에 놓입니다. ✕는 `inverseOnSurface`의 70%이고, 포인터를 올리면 100%가 됩니다.

</AnatomyItem>
</Anatomy>

아이콘과 글 사이는 10(`iconContentGapStyle`), message와 description 사이는 2(`messageDescriptionGapStyle`), 글과 행동 사이는 16(`contentActionGapStyle`)입니다. 기본 밀도에서 행동 없이 message 한 줄이면 토스트의 높이는 48이고, description 한 줄이 붙으면 70입니다. 여백과 간격은 앱의 밀도를 따라 움직입니다.

<a id="변형-variants"></a>
<a id="neutral"></a>
<a id="success"></a>
<a id="destructive"></a>

## Variant

세 variant는 **앞의 아이콘 하나로만** 갈립니다. 채움 · 글자 · 아이콘 · 닫기 버튼의 색은 셋 다 같은 `inverseSurface` · `inverseOnSurface` 짝입니다. 토스트는 페이지와 밝기가 반대인 말풍선이라, 밝은 모드에서는 어두운 면, 어두운 모드에서는 밝은 면입니다. 그래서 variant는 색이 아니라 **무슨 일이 일어났는지**를 고릅니다. 결과는 아이콘 모양과 문구가 전합니다.

<VariantRow name="neutral" component="toast" props="variant=neutral;dismiss" label="새 버전이 나왔어요">

기본값입니다. 아이콘이 없습니다. 결과를 알리는 것이 아닌 소식에 씁니다.

</VariantRow>

<VariantRow name="success" component="toast" props="variant=success;dismiss" label="저장했어요">

`circle-check` 아이콘이 붙습니다. 무언가 성공했을 때만 씁니다.

</VariantRow>

<VariantRow name="destructive" component="toast" props="variant=destructive;dismiss" label="저장 실패">

`circle-alert` 아이콘이 붙습니다. 실패를 알릴 때 씁니다. 색과 스크린 리더에 알리는 방식은 다른 둘과 같습니다.

</VariantRow>

```dart
Toast(
  message: '저장하지 못했어요',
  description: '문제가 생겼어요. 다시 시도해 주세요.',
  variant: CoreToastVariant.destructive,
  onDismiss: handleDismiss,
)
```

<a id="아이콘-없이-showicon"></a>

### 아이콘 끄기

`showIcon: false`는 아이콘과 그 뒤 간격을 함께 뺍니다. 글은 패널 안쪽 여백에서 시작하고, description · 행동 · 닫기 버튼은 그대로입니다. variant가 고르는 것은 아이콘뿐이라 **아이콘을 끈 토스트는 어느 variant든 같은 모습**입니다. 성공 · 실패 같은 결과는 `message`에 글로 적으세요. 아이콘이 없는 `neutral`은 `showIcon`의 값과 상관없이 같게 그려집니다.

<Preview component="toast" props="variant=success;description=변경 사항을 저장했어요.;showIcon=false;dismiss" label="저장했어요" />

```dart
Toast(
  message: '저장했어요',
  description: '변경 사항을 저장했어요.',
  variant: CoreToastVariant.success,
  showIcon: false,
  onDismiss: handleDismiss,
)
```

<a id="동작-스펙-behavior"></a>

## 닫기와 행동

카드는 상태를 갖지 않습니다. 닫기와 행동은 넘긴 콜백과 위젯으로만 일어납니다.

<Preview demo="toast/with-action" />

| 항목 | 동작 |
| --- | --- |
| 닫기 버튼 | `onDismiss`를 넘기면 끝에 ✕ 버튼이 생깁니다. 누르면 콜백만 부릅니다. `showToast`로 띄웠다면 `onDismiss: overlay.close`처럼 연결합니다. |
| 행동 | `action`은 글 뒤, 닫기 버튼 앞에 놓입니다. 어떤 위젯이든 넣을 수 있습니다. 행동을 누른 뒤 토스트를 닫으려면 그 콜백에서 직접 닫습니다. |
| 없는 것 | 카드 자체의 표시 시간, `Escape`로 닫기, 비활성 상태 |

```dart
showToast(
  context: context,
  builder: (context, overlay) => Toast(
    message: '메일을 보관했어요',
    onDismiss: overlay.close,
    action: Button(
      variant: CoreButtonVariant.plain,
      size: CoreComponentSize.xs,
      onPressed: () {
        restoreMail();
        overlay.close();
      },
      child: Text('되돌리기'),
    ),
  ),
)
```

<a id="aschild-패턴-action-버튼-변경"></a>

### 행동 버튼

행동 버튼의 **종류(variant)와 크기**는 `action`에 넣는 `Button`이 정합니다. 종류는 채움이 없는 `plain`이나 `ghost`를 고릅니다. 크기를 주지 않으면 `md`(높이 40) 버튼이라 한 줄 토스트가 68까지 높아지므로, 보통 `xs`나 `sm`을 줍니다.

`action`에 `Button`을 **바로** 넣으면 토스트가 그 버튼에 다음을 더합니다.

- 글자색을 토스트의 글자색(`inverseOnSurface`)으로 바꿉니다. hover에도 같습니다.
- hover와 누름에는 쉬는 채움 위에 그 글자색을 3% · 12% 덧칠합니다.
- 키보드 포커스 링과 버튼 사이의 간격을 `surface` 색 띠로 채웁니다.
- `plain` 버튼에만 좌우 안쪽 여백 6을 줍니다. 다른 종류는 자기 크기의 여백을 그대로 씁니다.

값은 `토스트의 기본값 → toastStyle.actionButtonStyle → (plain이면) toastStyle.plainActionButtonStyle → 버튼 자신의 buttonStyle` 순서로 겹치고, 뒤의 것이 이깁니다. `plain`의 좌우 여백 6보다 `actionButtonStyle`에 준 여백이 우선합니다. `Button`을 다른 위젯으로 감싸 넣거나 다른 위젯을 넣으면 아무것도 더하지 않고 그대로 그립니다. 그때 버튼은 페이지 바탕에 맞춘 색을 그대로 써서 말풍선 위에서 읽히지 않을 수 있습니다.

<Note>

토스트는 글자색만 바꾸고 버튼의 채움은 그대로 둡니다. 그래서 CoUI 기본 색에서는 자기 채움이 있는 `outline` · `secondary` · `tonal` · `destructive`가 밝은 모드에서는 밝은 채움 위의 흰 글자, 어두운 모드에서는 어두운 채움 위의 검은 글자가 되어 **글자가 읽히지 않을 수 있습니다.** 종류를 주지 않은 `Button`은 `primary`인데, 글자는 읽히지만 채움이 말풍선과 같은 색이라 버튼의 윤곽이 보이지 않습니다.

</Note>

<a id="flutter-인프라-toastlayer"></a>

## 띄우기

`Toast`는 카드라서, 언제 어디에 보일지는 카드 밖에서 정합니다.

### Flutter에서 띄우기

알림으로 보여 줄 때는 `Toast`를 화면의 위젯 트리에 직접 두지 말고 `showToast`로 띄웁니다. 트리에 직접 두면 위치(`ToastLocation`) · 쌓임 · 나타나는 움직임 · 자동 닫힘(`showDuration`)이 하나도 적용되지 않습니다.

`CoUIApp`은 앱의 화면(내비게이터) 위에 `ToastLayer`를 이미 세웁니다. 따로 세우지 않아도 그 아래의 어느 화면에서든 `showToast`를 부를 수 있습니다. 토스트는 화면보다 위의 층에 그려지므로, 대화상자가 열려 있어도 그 위에 보입니다.

```dart
final toast = showToast(
  context: context,
  builder: (context, overlay) => Toast(
    message: '파일을 올렸어요',
    variant: CoreToastVariant.success,
    onDismiss: overlay.close,
  ),
  location: ToastLocation.bottomRight,
  showDuration: Duration(seconds: 5),
);

// 필요하면 코드에서 먼저 닫습니다.
toast.close();
```

- `showToast`는 부른 자리에서 위로 가장 가까운 `ToastLayer`에 토스트를 올리고, 그 자리의 테마를 함께 가져갑니다. 부분 테마 안에서 부르면 그 테마로 그려집니다.
- 위에 `ToastLayer`가 없는 `context`에서 부르면 디버그 빌드에서 `No ToastLayer found in context` assert가 납니다.
- 돌려받는 `ToastOverlay`의 `close()`로 닫고, `isShowing`으로 닫혔는지 확인합니다. `close()`를 여러 번 불러도 괜찮습니다. 시간이 지나거나 `close()`로 닫으면 `isShowing`은 `false`가 되지만, **밀어서 닫은 토스트는 `true`로 남습니다.** 닫힌 때를 알아야 하면 `onClosed`를 씁니다.
- `builder`는 아무 위젯이나 돌려줄 수 있습니다. `Toast`는 그 자리에 보통 넣는 카드입니다.

### 위치

`location`은 여섯 자리 중 하나이고, 기본값은 `ToastLocation.bottomRight`입니다. 토스트는 자리마다 따로 쌓입니다. 위쪽 자리에서는 아래로, 아래쪽 자리에서는 위로 쌓이며, 새 토스트가 맨 앞에 옵니다.

| 자리 | 위치 | 쌓이는 방향 |
| --- | --- | --- |
| `topLeft` · `topCenter` · `topRight` | 위 | 아래로 |
| `bottomLeft` · `bottomCenter` · `bottomRight` | 아래 | 위로 |

- 왼쪽 · 오른쪽은 화면의 실제 방향입니다. 오른쪽에서 왼쪽으로 읽는 언어에서도 뒤집히지 않습니다.
- 층은 안전 영역 안에서 화면 가장자리를 24 띄웁니다(`padding`). 밀도를 compact로 바꾸면 20, spacious는 28입니다.
- 층 안의 토스트 폭은 기본 320(테마 배율을 곱한 값)이고, 화면이 좁으면 남는 폭까지 줄어듭니다(`toastConstraints`).
- 새 토스트는 500ms 동안, 아래쪽 자리는 아래에서 · 위쪽 자리는 위에서 미끄러져 들어오며 나타납니다. 닫을 때는 거꾸로 움직입니다. 모션 줄이기를 켜면 움직임 없이 바로 바뀝니다.

### 쌓임과 펼침

- 한 자리에서 한꺼번에 보이는 토스트는 기본 3개(`maxStackedEntries`)입니다. 더 오래된 토스트는 보이지 않다가 앞의 것이 닫히면 다시 나타납니다. 보이지 않는 동안에도 자동 닫힘 시간이 흐를 수 있습니다.
- 접힌 상태에서는 뒤의 토스트를 한 단계마다 쌓이는 방향으로 12 옮기고 0.9배로 줄여(가운데 기준) 앞 토스트 뒤로 조금 비껴 보이게 합니다. 앞 토스트보다 많이 낮은 뒤 토스트는 앞 토스트에 가려 보이지 않을 수 있습니다.
- `expandMode`의 기본값 `ExpandMode.expandOnHover`는 쌓인 토스트에 포인터를 올리면 펼치고, 포인터가 벗어나면 300ms 뒤에 다시 접습니다.
- `ExpandMode.alwaysExpanded`는 늘 펼쳐 둡니다. 모드는 이 두 가지입니다.
- 펼치면 각 토스트를 쌓이는 방향으로 (**자기 높이** + `spacing`) × 앞에 놓인 토스트 수만큼 옮깁니다. `spacing`은 8이고 밀도에 따라 4 · 8 · 12입니다. 그래서 높이가 같으면 토스트 사이가 `spacing`이지만, 설명이 붙은 토스트와 한 줄 토스트처럼 높이가 다르면 겹치거나 더 벌어질 수 있습니다.
- 펼친 동안에는 맨 앞 토스트를 포함한 묶음 전체가 화면 가장자리에서 16(테마 배율을 곱합니다) 더 떨어집니다. `alwaysExpanded`에서는 늘 그렇습니다.

### 자동으로 닫힘

- `showDuration`의 기본값은 5초입니다. 타입이 `Duration`(null 불가)이라 자동 닫힘을 끌 수 없습니다. 오래 두려면 충분히 긴 값을 줍니다.
- 포인터를 올린 토스트는 시간이 멈추고, 벗어나면 **`showDuration` 전체를 처음부터** 다시 셉니다. 키보드 포커스는 시간을 멈추지 않습니다.
- `dismissible: true`(기본)면 가로로 밀어 닫을 수 있습니다. 밀고 있는 동안에는 시간이 멈춥니다. 토스트 폭의 절반을 넘게 밀면 닫히고, 덜 밀고 놓으면 제자리로 돌아와 `showDuration` 전체를 다시 셉니다. 이때는 마우스 포인터가 아직 토스트 위에 있어도 시간이 다시 흐를 수 있습니다.
- `dismissible`은 밀기만 정합니다. 닫기 버튼은 `Toast`에 `onDismiss`를 줄 때만 생깁니다.
- `onClosed`는 시간 · `close()` · 밀기 중 어느 쪽으로 닫혀도, 토스트가 사라진 뒤에 불립니다.

### 층 설정 바꾸기

`CoUIApp`에는 `ToastLayer`의 설정을 바꾸는 파라미터가 없습니다. 최대 개수 · 펼침 방식 · 여백 등을 바꾸려면 `ToastLayer`를 하나 더 세웁니다. `showToast`는 부른 자리에서 가장 가까운 층을 씁니다.

```dart
CoUIApp(
  theme: appTheme,
  builder: (context, child) => ToastLayer(
    maxStackedEntries: 5,
    expandMode: ExpandMode.alwaysExpanded,
    child: child!,
  ),
  home: HomePage(),
)
```

- `ToastLayer`는 테마를 읽으므로 `CoUIApp` 바깥(위)에 두면 안 됩니다.
- 화면의 일부만 감싸는 층(탭 막대를 피해 페이지 안에 둔 층)에서는 그 층의 모서리와 가운데가 기준입니다.
- 이렇게 세운 층은 `CoUIApp`이 세운 층보다 안쪽에 있습니다. 서랍이 뒤 화면을 줄이며 열리면 이 층의 토스트는 화면과 함께 줄고 서랍 아래에 놓입니다.

### 접히는 화면

접힘선이 화면을 나누면 토스트 묶음은 한 조각 안에 놓입니다. `location`의 모서리가 놓인 조각이고, 가운데 정렬(`topCenter` · `bottomCenter`)이 접힘선에 걸리면 글이 시작하는 쪽 조각입니다. 화면의 일부만 덮는 층은 그 층의 모서리 · 가운데가 기준이고, 묶음은 조각 가운데 층이 덮는 부분에 놓입니다. 자세한 규칙은 [접히는 화면](/guides/layout#접히는-화면)을 보세요.

### Web에서 놓기

Web에는 `showToast`나 `ToastLayer`에 해당하는 것이 없습니다. 앱이 상태를 두고 카드를 놓았다가 걷어냅니다. 카드는 부모 폭을 다 쓰므로 폭은 감싸는 상자가 정합니다.

```dart
if (isSaved)
  div(
    styles: Styles(
      raw: {
        'position': 'fixed',
        'right': spaceCss(CoreSpace.space24),
        'bottom': spaceCss(CoreSpace.space24),
        'width': 'min(20rem, calc(100% - ${spaceCss(CoreSpace.space48)}))',
      },
    ),
    [
      Toast(
        message: '저장했어요',
        variant: CoreToastVariant.success,
        onDismiss: () => setState(() => isSaved = false),
      ),
    ],
  )
```

- 시간이 지나면 닫기, 여러 개 쌓기, 밀어서 닫기, 접힌 화면의 조각 고르기(`FoldScope.of(context)`)는 모두 앱이 만듭니다.
- 카드에는 `pointer-events: auto`가 붙어 있어, 감싸는 상자에 `pointer-events: none`을 주어도 카드는 누를 수 있습니다.
- `Dialog`처럼 브라우저의 top layer에 올라가는 패널이 열려 있으면, 앱이 이렇게 놓은 토스트는 그 아래에 그려집니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

토스트는 잠깐 보였다가 사라지는 알림입니다. 하던 일을 멈추지 않게 결과를 전할 때 씁니다.

- 저장 · 삭제 · 복사처럼 방금 한 작업의 결과를 알릴 때
- 방금 한 일을 되돌릴 기회를 줄 때
- 놓쳐도 다음 일에 지장이 없는 소식을 전할 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 사용자의 응답을 받아야 할 때 | [Dialog](/components/dialog) |
| 실패 · 경고가 관련 내용 옆에 계속 남아야 할 때 | [Alert](/components/alert) |
| 보여 줄 내용이 없어 그 자리를 대신 채워야 할 때 | [EmptyState](/components/empty-state) |
| 페이지 맨 위에 거는 공지 | [Banner](/components/banner) |
| 특정 요소를 설명할 때 | [Tooltip](/components/tooltip) |

<a id="do"></a>
<a id="dont"></a>

### 문구와 행동

<Cards columns="2">
<Card demo="toast/do-short" tone="do" eyebrow="이렇게 하세요">

무슨 일이 일어났는지 짧은 한 줄로 적습니다.

</Card>
<Card demo="toast/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

긴 문장은 사라지기 전에 다 읽기 어렵습니다. 남겨야 할 설명은 화면 안에 둡니다.

</Card>
<Card demo="toast/do-quiet-action" tone="do" eyebrow="이렇게 하세요">

행동은 하나만, 채움이 없는 `plain`이나 `ghost`로 둡니다.

</Card>
<Card demo="toast/dont-filled-action" tone="dont" eyebrow="이렇게 하지 마세요">

`outline`처럼 자기 채움이 있는 버튼은 글자가 채움에 묻혀 읽히지 않을 수 있습니다.

</Card>
<Card demo="toast/do-recovery" tone="do" eyebrow="이렇게 하세요">

실패는 `destructive`로 무엇이 안 됐는지 글로 적고, 다시 해 볼 길을 함께 둡니다.

</Card>
<Card demo="toast/dont-lasting-news" tone="dont" eyebrow="이렇게 하지 마세요">

놓치면 안 되는 소식을 잠깐 뜨는 토스트에만 두면, 사라진 뒤 다시 확인할 곳이 없습니다. 화면에 남는 [Alert](/components/alert)를 씁니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-toaststyle"></a>
<a id="toaststyle-슬롯"></a>

## 테마와 스타일

무엇을 보여 줄지(`message` · `description` · `variant` · `showIcon` · `action` · `onDismiss`)는 위젯 파라미터로, 패널의 겉모습과 안쪽 부품(아이콘 · 글자 · 간격 · 행동 버튼 · 닫기 버튼)은 `toastStyle`(`CoreToastStyle`) 하나로 바꿉니다. 두 플랫폼이 같은 코드를 씁니다.

<a id="테마-커스터마이징"></a>
<a id="테마-커스터마이징-theme-customization"></a>

<Split>

<Code language="dart" title="토스트 하나만 바꾸기">
Toast(
  message: '저장했어요',
  onDismiss: handleDismiss,
  toastStyle: CoreToastStyle(
    panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    panelPaddingWithDismiss: CoreEdgeInsets.directional(
      start: CoreSpace.space16,
      top: CoreSpace.space12,
      end: CoreSpace.space48,
      bottom: CoreSpace.space12,
    ),
    messageDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space4),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    toast: CoreToastTheme(
      style: CoreToastStyle(
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius12),
      ),
      variantStyles: {
        CoreToastVariant.destructive: CoreToastStyle(
          panelBorderColor: CoreColor.token(CoreColors.error),
          panelBorderWidth: CoreStrokeWidth.stroke2,
        ),
      },
    ),
  ),
)
</Code>

</Split>

- 닫기 버튼이 있는 토스트(`onDismiss`)의 안쪽 여백은 `panelPaddingWithDismiss`가, 없는 토스트는 `panelPadding`이 정합니다. 둘을 함께 바꾸려면 둘 다 줍니다.
- 기본 테두리 굵기는 0입니다. 테두리를 그리려면 `panelBorderColor`와 `panelBorderWidth`를 함께 줍니다.
- **패널 색을 바꿔도 글자색은 따라오지 않습니다.** `panelBackgroundColor`를 밝게 바꾸면 밝은 모드의 흰 글자가 묻힙니다. `messageStyle`과 `descriptionStyle`의 색을 함께 주고, 닫기 ✕는 `closeButtonStyle`, 행동은 `actionButtonStyle`로 맞춥니다. 앞 아이콘의 색은 바꿀 수 없습니다.
- 뒤를 흐리는 유리 같은 [서페이스 스타일](/guides/surface-styles)에서는 토스트 패널도 그 재질을 받아 반투명해집니다.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreToastStyle 기본값 · variant별 색       // 디자인 시스템
  → CoreToastTheme.style                   // 앱 전체
  → CoreToastTheme.variantStyles[variant]  // 앱 전체, variant별
  → toastStyle                             // 토스트 하나
```

뒤로 갈수록 우선합니다. 필드마다 따로 합쳐지므로 앞에서 정한 다른 필드는 그대로 남고, 글자 · 간격 · 버튼처럼 안쪽 부품의 스타일은 그 안의 필드끼리 합쳐집니다. 행동 버튼의 순서는 [행동 버튼](#행동-버튼)에 있습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `Toast`에 `.withStyle(CoreToastStyle(...))`를 이어 붙이면 그 값이 `toastStyle` 위에 합쳐지고, 뒤에 붙인 것이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class ToastChainExample extends StatelessWidget {
  const ToastChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    ).withStyle(
      const CoreToastStyle(
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelBorderColor: CoreColor.token(CoreColors.primary),
        panelBorderWidth: CoreStrokeWidth.stroke2,
        panelPaddingWithDismiss: CoreEdgeInsets.directional(
          start: CoreSpace.space16,
          top: CoreSpace.space16,
          end: CoreSpace.space48,
          bottom: CoreSpace.space16,
        ),
        messageDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space8),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class ToastChainExample extends StatelessComponent {
  const ToastChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Toast(
      message: '저장했어요',
      description: '변경 사항을 저장했어요.',
      onDismiss: () {},
    ).withStyle(
      const CoreToastStyle(
        panelBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        panelBorderColor: CoreColor.token(CoreColors.primary),
        panelBorderWidth: CoreStrokeWidth.stroke2,
        panelPaddingWithDismiss: CoreEdgeInsets.directional(
          start: CoreSpace.space16,
          top: CoreSpace.space16,
          end: CoreSpace.space48,
          bottom: CoreSpace.space16,
        ),
        messageDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space8),
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

토스트는 뜰 때 포커스를 옮기지 않고, 두 플랫폼 모두 스크린 리더에 알릴 영역으로 표시합니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 카드를 `Semantics(liveRegion: true)`로 감쌉니다. 별도의 역할은 지정하지 않습니다. |
| Jaspr Web | 카드의 루트 `<div>`에 `role="status"`와 `aria-live="polite"`를 붙입니다. |

닫기 버튼의 이름은 앱 언어의 닫기 문구(한국어 "닫기")입니다. Web은 `aria-label`, Flutter는 `Semantics(label:)`로 붙입니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 포커스를 옮깁니다. 토스트 안에서 포커스를 받는 것은 `action` 안의 컨트롤과 닫기 버튼입니다. 카드 자체는 받지 않습니다. |
| `Enter` · `Space` | 포커스된 버튼을 실행합니다. |
| `Escape` | 토스트를 닫지 않습니다. 토스트를 닫는 단축키는 두 플랫폼 모두 없습니다. |

Flutter에서 띄운 토스트까지 `Tab`으로 닿는지는 [알려진 제약](#알려진-제약)을 보세요.

### 스크린 리더

- 따로 이름을 받지 않고, `message`와 `description`의 글자를 읽습니다.
- **아이콘에는 이름이 없습니다.** 성공 · 실패 같은 결과는 `message`의 글로 전해야 합니다.
- `destructive`도 알리는 방식이 같습니다. Web에서 `role="alert"`로 바뀌지 않으므로, 실패를 읽던 문장을 끊고 알려야 한다면 화면에 남는 `Alert.destructive`를 씁니다.
- Flutter 카드에 붙는 `liveRegion`은 알릴지 말지만 정합니다. 급한 정도(polite · assertive)를 고르는 값은 없습니다.

### 포커스 관리

| 항목 | 동작 |
| --- | --- |
| 진입 | 토스트가 떠도 포커스를 옮기지 않습니다. |
| 이탈 | 닫힐 때 포커스를 되돌리는 처리가 없습니다. 토스트 안의 버튼에 포커스가 있을 때 토스트가 걷히면 그 포커스는 사라집니다. |
| 가두기 | 없습니다. 토스트는 모달이 아니며 뒤의 화면을 막지 않습니다. |
| 포커스 표시 | 닫기 버튼과, `action`에 바로 넣은 `Button`의 링은 링과 버튼 사이 간격을 `surface` 색 띠로 채웁니다. 토스트는 어떤 화면 위에든 뜰 수 있어 링과 띠 두 색으로 표시합니다. |

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `onDismiss`를 주지 않으면 닫기 버튼이 없어 키보드로 닫을 길이 없습니다. Flutter의 밀어서 닫기는 포인터로만 됩니다. |
| Flutter | 자동 닫힘 시간은 포인터를 올리거나 밀 때만 멈춥니다. 키보드 포커스가 토스트 안에 있어도 시간이 흘러, 행동 버튼을 누르기 전에 사라질 수 있습니다(WCAG 2.2.1). 자동 닫힘은 끌 수 없으니 `showDuration`을 넉넉히 줍니다. |
| Flutter | 띄운 토스트는 화면(내비게이터)과 다른 층에 있어, `Tab`만으로는 토스트의 버튼에 닿지 못할 수 있습니다. 대화상자가 열려 있으면 `Tab`은 대화상자 안을 도는 것이 기본입니다. 꼭 해야 하는 행동은 토스트에만 두지 마세요. |
| Flutter | 터치 화면에는 올려 두기(hover)가 없어, 올려 두어 시간을 멈추거나 `expandOnHover`로 쌓인 토스트를 펼칠 수 없습니다. |
| Flutter | 설명이 있는 토스트와 한 줄 토스트처럼 높이가 다른 토스트가 한 자리에 쌓이면, 펼쳤을 때 서로 겹치거나 간격이 벌어질 수 있고, 접었을 때 낮은 뒤 토스트가 앞 토스트에 가려질 수 있습니다. |
| Flutter | 한 자리에 `maxStackedEntries`의 두 배(기본 6개)보다 많이 쌓였을 때 그 밖의 오래된 토스트를 `close()`하면, 바로 정리되지 않고 나중에 보일 차례가 될 때 디버그 빌드에서 오류가 날 수 있습니다. |
| 공통 | 오른쪽에서 왼쪽으로 읽는 언어에서는 닫기 버튼을 위해 비운 여백은 왼쪽으로 가는데 닫기 버튼은 오른쪽에 남아, 버튼이 아이콘 · 글자와 겹칠 수 있습니다. |
| 공통 | `outline` · `secondary` · `tonal` · `destructive`처럼 자기 채움이 있는 행동 버튼은 글자가 읽히지 않을 수 있습니다([행동 버튼](#행동-버튼)). |
| Jaspr Web | 띄우는 층 · 자동 닫힘 · 밀어서 닫기가 없어, 앱이 만든 방식이 접근성도 정합니다. |
| Jaspr Web | `Toast`는 HTML 속성 가운데 `id`만 받습니다. `classes` · `css` · `attributes`는 줄 수 없어, `copyWith`에 넘겨도 반영되지 않습니다. |

전역으로 적용되는 축(동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 타깃)은 [전역 접근성 축](/accessibility)에 있습니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

카드의 파라미터 이름과 기본값은 같고, 띄우는 기능은 Flutter에만 있습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `action` 타입 | `Widget?` | `Component?` |
| `onDismiss` 타입 | `VoidCallback?` | `CoreVoidCallback?` |
| 띄우기 | `showToast`와 `ToastLayer`(`CoUIApp`이 세웁니다) | 없음 — 앱이 카드를 놓고 걷어냅니다 |
| 위치 · 쌓임 · 자동 닫힘 · 밀어서 닫기 | `ToastLayer`가 합니다 | 없음 — 앱이 만듭니다 |
| 직접 놓을 때의 폭 | 부모 폭을 다 씁니다. 안에서 남는 폭을 나누므로 가로 폭이 정해지지 않는 부모에 두면 레이아웃 오류가 납니다. | 부모 폭을 다 씁니다 |
| 알리는 방식 | live region | `role="status"` · `aria-live="polite"` |
| `transitionDuration` | 읽지 않습니다. `toastStyle`이 바뀌면 바로 반영합니다. | 패널의 CSS 전환 시간(기본 200ms) |
| HTML 속성 | 없음 | `id`만 |
| 접히는 화면 | `ToastLayer`가 한 조각에 놓습니다 | 앱이 `FoldScope.of(context)`로 정합니다 |

<a id="props-parameters"></a>

## API

`Toast`는 두 플랫폼이 같은 파라미터를 씁니다. Web에서는 `Widget` 자리가 `Component`, `VoidCallback` 자리가 `CoreVoidCallback`입니다.

### 위젯 파라미터

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `message` | `String` | 필수 | 알림의 첫 줄 |
| `description` | `String?` | `null` | message 아래의 보조 설명 |
| `variant` | `CoreToastVariant` | `CoreToastVariant.neutral` | `neutral` · `success` · `destructive`. 앞 아이콘을 정합니다. |
| `showIcon` | `bool` | `true` | `false`면 아이콘과 그 뒤 간격을 함께 뺍니다. |
| `onDismiss` | `VoidCallback?` | `null` | 주면 닫기 버튼이 생기고, 누르면 불립니다. |
| `action` | `Widget?` | `null` | 글 뒤에 놓는 행동 |
| `toastStyle` | `CoreToastStyle?` | `null` | 패널과 안쪽 부품의 겉모습 덮어쓰기 |

두 플랫폼 모두 `key`를 받고, Web은 `id`를 더 받습니다. `withStyle(CoreToastStyle patch)`는 `toastStyle`에 값을 덧붙인 복사본을 만듭니다.

### 띄우는 함수 — `showToast` (Flutter)

`ToastOverlay`를 돌려줍니다. `ToastOverlay`는 닫는 `close()`와 닫혔는지 알려 주는 `isShowing`을 가집니다. `isShowing`은 밀어서 닫은 뒤에도 `true`로 남습니다. Web에는 이 함수가 없습니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `context` | `BuildContext` | 필수 | 위의 가장 가까운 `ToastLayer`를 찾고, 이 자리의 테마를 가져갑니다. |
| `builder` | `ToastBuilder` | 필수 | `(context, overlay)`를 받아 토스트에 그릴 위젯을 만듭니다. |
| `location` | `ToastLocation` | `ToastLocation.bottomRight` | 놓을 자리 |
| `showDuration` | `Duration` | 5초 | 이 시간이 지나면 닫힙니다. |
| `dismissible` | `bool` | `true` | 가로로 밀어 닫을 수 있는가 |
| `onClosed` | `VoidCallback?` | `null` | 토스트가 사라진 뒤에 불립니다. |
| `entryDuration` | `Duration` | 500ms | 나타나고 사라지는 시간 |
| `curve` | `Curve` | `Curves.easeOutCubic` | 나타나고 사라지는 곡선 |

### `ToastLayer` (Flutter)

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `Widget` | 필수 | 토스트를 띄울 영역의 내용 |
| `maxStackedEntries` | `int` | `3` | 한 자리에서 한꺼번에 보이는 최대 개수 |
| `expandMode` | `ExpandMode` | `ExpandMode.expandOnHover` | 쌓인 토스트를 펼치는 방식. `expandOnHover` 또는 `alwaysExpanded` |
| `padding` | `EdgeInsetsGeometry?` | `null` | 화면 가장자리와의 여백. 없으면 네 변 24이고 밀도를 따릅니다. 직접 준 값에는 밀도를 적용하지 않습니다. |
| `spacing` | `double` | `8` | 펼친 토스트 사이의 간격(높이가 같은 토스트끼리). 밀도를 따릅니다. |
| `toastConstraints` | `BoxConstraints?` | `null` | 토스트 하나의 크기. 없으면 폭 320(테마 배율을 곱합니다) |
| `collapsedOffset` | `Offset?` | `null` | 접힌 뒤 토스트를 한 단계마다 옮기는 세로 거리. 가로 값은 반영되지 않습니다. 없으면 12이고, 테마 배율은 직접 준 값에도 곱합니다. |
| `collapsedScale` | `double` | `0.9` | 접힌 뒤 토스트가 한 단계마다 작아지는 배율 |
| `collapsedOpacity` | `double` | `1` | 접힌 뒤 토스트가 한 단계마다 곱해 가는 불투명도 |
| `entryOpacity` | `double` | `0` | 나타나기 시작할 때의 불투명도 |
| `expandingCurve` | `Curve` | `Curves.easeOutCubic` | 펼치고 접는 곡선 |
| `expandingDuration` | `Duration` | 500ms | 펼치고 접는 시간 |

### 테마 — `CoreToastTheme`

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `style` | `CoreToastStyle?` | `null` | 앱의 모든 토스트에 적용하는 값 |
| `variantStyles` | `Map<CoreToastVariant, CoreToastStyle>?` | `null` | variant마다 덧붙이는 값 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreToastStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `panelBackgroundColor` | `CoreColor?` | Panel background fill colour override. |
| `panelBorderColor` | `CoreColor?` | Panel border stroke colour override. |
| `panelBorderRadius` | `CoreBorderRadius?` | Panel border radius override. |
| `panelBorderWidth` | `double?` | Panel border stroke width override (logical px). When null, defers to [defaultPanelBorderWidth] (1). |
| `panelPadding` | `CoreEdgeInsets?` | Panel content padding override (no dismiss button). When null, defers to [defaultPanelPadding]. |
| `panelPaddingWithDismiss` | `CoreEdgeInsets?` | Panel content padding override when a dismiss button is present — used instead of [panelPadding] so the trailing edge leaves room for the close button. When null, defers to [defaultPanelPaddingWithDismiss]. |
| `panelBoxShadow` | `List<CoreShadowLayer>?` | Panel elevation shadow override. When null, defers to [defaultPanelBoxShadow]. |
| `minHeight` | `double?` | Panel minimum height override (logical px). When null, defers to [defaultMinHeight]. |
| `contentActionGapStyle` | `CoreGapStyle?` | Style of the `Gap` between the message + description column and the action slot. `null` defers to [defaultContentActionGapStyle]. |
| `iconStyle` | `CoreIconStyle?` | Leading-glyph style override. `null` defers to [defaultIconStyle]. |
| `iconContentGapStyle` | `CoreGapStyle?` | Gap between the leading glyph and the content column. `null` defers to [defaultIconContentGapStyle]. |
| `messageDescriptionGapStyle` | `CoreGapStyle?` | Style of the `Gap` between the message and description rows inside the content column. `null` defers to [defaultMessageDescriptionGapStyle]. |
| `closeInset` | `CoreEdgeInsets?` | Close-button inset — the right side is the button's distance from the trailing edge, and the top and bottom sides bound the band the button is centred in vertically. Four-sided so the caller can shift the dismiss button on any axis; the button's own look is set in [closeButtonStyle]. When null, defers to [defaultCloseInset]. |
| `transitionDuration` | `Duration?` | Duration of the panel's transitions when its look changes. When null, defers to [defaultTransitionDuration]. |
| `messageStyle` | `CoreTextStyle?` | Message (primary text) style override. |
| `descriptionStyle` | `CoreTextStyle?` | Description (secondary text) style override. |
| `actionButtonStyle` | `CoreButtonStyle?` | Action button style override. |
| `plainActionButtonStyle` | `CoreButtonStyle?` | Extra styling for an action that is a `plain` `Button` — laid over [actionButtonStyle] (and its default) for that variant only, and merged onto [defaultPlainActionButtonStyle]. A caller's [actionButtonStyle] still wins over the default here, so a padding stated there reaches every variant. |
| `closeButtonStyle` | `CoreButtonStyle?` | Close (dismiss) button style override. |

### `CoreToastStyle` 변형별 기본값 (`CoreToastVariantStyle`)

| 필드 | `success` | `destructive` | `neutral` |
|------|------|------|------|
| `backgroundColor` | inverseSurface | inverseSurface | inverseSurface |
| `closeForeground` | inverseOnSurface (opacity 70%) | inverseOnSurface (opacity 70%) | inverseOnSurface (opacity 70%) |
| `closeHoverForeground` | inverseOnSurface | inverseOnSurface | inverseOnSurface |
| `foregroundColor` | inverseOnSurface | inverseOnSurface | inverseOnSurface |
| `borderColor` | inverseSurface | inverseSurface | inverseSurface |
| `descriptionForeground` | inverseOnSurface (opacity 75%) | inverseOnSurface (opacity 75%) | inverseOnSurface (opacity 75%) |
| `iconColor` | inverseOnSurface | inverseOnSurface | — |

<!-- STYLE_TABLE:END -->

<Note>

위 표 가운데 지금 동작과 다른 설명이 있습니다. `panelBorderWidth`를 주지 않으면 테두리 굵기는 **0**입니다. `iconStyle`에 준 색은 적용되지 않고 variant의 아이콘 색을 씁니다. `transitionDuration`은 Web에만 적용됩니다. `closeInset`은 위 · 오른쪽 · 아래 값을 읽으며, 오른쪽은 읽는 방향과 상관없이 화면의 오른쪽입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card title="Alert" href="/components/alert" more="Alert 보기">

화면 안에 남아 결과와 경고를 알리는 알림 상자입니다.

</Card>
<Card title="Banner" href="/components/banner" more="Banner 보기">

페이지 맨 위에 거는 공지 띠입니다.

</Card>
<Card title="Dialog" href="/components/dialog" more="Dialog 보기">

진행하기 전에 사용자의 응답을 받는 모달 패널입니다.

</Card>
</Cards>
