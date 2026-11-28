---
title: Disclosure
description: 제목을 누르면 본문이 열리고 닫히는 영역입니다. 웹에서는 브라우저의 <details>로 그려, 스크립트 없이도 열립니다.
category: layout
platforms: [flutter, web]
related: [collapsible, accordion]
tags: [disclosure, details, summary, static, no-js, layout]
template: v2
source: layout/disclosure
---

# Disclosure

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 영역을 여닫고, 만들어진 코드를 그대로 복사하세요.

<Playground component="disclosure" />

## 구조

머리 줄(`title` 또는 `trigger`)과 본문(`content`)으로 이루어집니다. 화살표는 컴포넌트가 그립니다. 웹에서 머리 줄은 `<summary>`입니다.

<Anatomy demo="disclosure/anatomy">
<AnatomyItem part="container" name="Container">

머리 줄과 본문을 세로로 놓습니다. 채움 · 테두리는 없습니다.

</AnatomyItem>
<AnatomyItem select="summary" name="header">

누르는 줄. 사방 여백이 16입니다.

</AnatomyItem>
<AnatomyItem part="label" name="title">

`title` 글자 또는 `trigger` 슬롯. 기본 글자는 `bodyMedium` · 500 · `onSurface`입니다.

</AnatomyItem>
<AnatomyItem part="leading" name="chevron" side="right">

열림 표시. 16 크기, `onSurface`이고 열리면 180° 돌아갑니다. 머리 글자와의 사이는 16입니다.

</AnatomyItem>
<AnatomyItem select="summary + div" name="content" side="right">

`content` 슬롯. 위 여백만 16이고, 기본 글자는 `bodyMedium` · `onSurface`입니다.

</AnatomyItem>
</Anatomy>

## 상태

<Preview demo="disclosure/states" />

| 상태 | 화면 |
| --- | --- |
| 닫힘 | 머리 줄만 보이고 화살표는 아래를 봅니다. |
| 열림 | 본문이 보이고 화살표가 180° 돌아갑니다. |
| 마우스를 올림 | Flutter는 머리 글자에 밑줄을 긋습니다. Web은 모양이 바뀌지 않습니다. |
| 키보드 포커스 | Flutter는 포커스 링을 그립니다. Web은 브라우저의 기본 포커스 표시를 씁니다. |

<a id="동작-스펙-behavior"></a>

### 열림 상태는 누구 것인가

`open`은 처음 상태입니다. 그 뒤로는 Web에서는 브라우저가, Flutter에서는 위젯이 열림을 기억합니다. 열림을 코드에서 정해야 하면 [Collapsible](/components/collapsible)을 쓰세요.

코드에서 `open`에 **다른 값**을 넘기면 그 값으로 다시 맞춥니다.

<Note>

Web에서는 `Disclosure`가 다시 그려지면 사용자가 여닫은 상태가 `open` 값으로 돌아갑니다. 예를 들어 `onToggle` 안에서 부모의 상태를 바꾸는 경우입니다. 서버가 그린 페이지에 스크립트가 붙으면서 다시 그릴 때도 같습니다. [알려진 제약](#알려진-제약)을 보세요.

</Note>

### 상호배타 열림은 일부러 넣지 않았습니다

하나를 열어도 다른 `Disclosure`는 닫히지 않습니다. 하나를 열면 나머지가 닫혀야 하면 [Accordion](/components/accordion)을 쓰세요.

### 애니메이션

화살표 회전만 200ms(`CoreDuration.normal`), `CoreEasing.move`로 움직입니다. 본문은 전환 없이 나타나고 사라집니다. 동작 줄이기를 켜면 회전도 바로 바뀝니다. Web의 화살표는 CSS가 `<details open>`을 보고 돌리므로, 컴포넌트의 스크립트가 붙기 전에도 열림에 맞춰 돕니다.

## 묶어서 쓰기

`DisclosureGroup`은 여러 `Disclosure`를 같은 간격(기본 8)으로 세로로 쌓습니다. 항목은 서로 상관없이 열립니다. `DisclosureItem` 같은 별도 항목 타입은 없고, 항목이 곧 `Disclosure`입니다.

<Preview demo="disclosure/group" />

```dart
DisclosureGroup(
  items: [
    Disclosure(title: '배송은 얼마나 걸리나요?', content: Text('보통 2~3일 안에 도착합니다.'), open: true),
    Disclosure(title: '교환할 수 있나요?', content: Text('받은 날부터 7일 안에 신청할 수 있습니다.')),
  ],
)
```

그룹은 `disclosureStyle`에서 `itemSpacing` 하나만 읽고, 항목의 스타일은 바꾸지 않습니다. 모든 항목의 겉모습을 한 번에 바꾸려면 `CoreDisclosureTheme.style`을 쓰세요. 항목에 직접 준 `disclosureStyle`이 테마보다 우선합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

정적으로 만든 웹 페이지의 자주 묻는 질문처럼, 항목이 서로 상관없이 열리고 스크립트가 없어도 열려야 할 때 씁니다. 처음 화면에 답이 보여야 하는 항목은 `open: true`로 두면 서버가 만든 HTML에 열린 채로 담깁니다.

### 왜 `Collapsible` 로는 안 되는가

`Collapsible`은 열림을 컴포넌트의 상태로 두고 누름을 스크립트가 처리합니다. 정적으로 만든 페이지는 스크립트가 붙기 전에는 눌러도 열리지 않고, 스크립트를 끈 브라우저에서는 끝까지 열리지 않습니다. `Disclosure`는 본문 전환 애니메이션을 두지 않는 대신 여닫기를 브라우저에 맡깁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 열림을 코드에서 정하거나 본문이 부드럽게 펼쳐져야 할 때 | [Collapsible](/components/collapsible) |
| 하나를 열면 나머지가 닫혀야 할 때 | [Accordion](/components/accordion) |

<Split>

<Code language="dart" title="이렇게 하세요">
// 토글은 지켜보기만 합니다.
Disclosure(
  title: '상세',
  onToggle: (isOpen) => analytics.log('faq_toggle', {'open': isOpen}),
  content: Text('…'),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// open은 코드가 열림을 계속 쥐는 값이 아닙니다. 같은 값을 다시 넘기면
// Flutter는 닫지 않고, Web은 다시 그릴 때 open 값으로 돌려 두 플랫폼이 달라집니다.
Disclosure(
  title: '상세',
  open: myState,
  onToggle: (_) => setState(() => myState = false),
  content: Text('…'),
)
</Code>

</Split>

제목과 본문을 한 슬롯에 몰아넣지 마세요. 누르는 줄은 `title`이나 `trigger`여야 합니다.

## 배치

| 플랫폼 | 폭 |
| --- | --- |
| Flutter | 받은 폭을 채웁니다. 폭의 한계가 없는 자리(`Row`의 자식 등)에서는 `Expanded`나 `SizedBox`로 폭을 정해야 합니다. |
| Jaspr Web | 루트가 블록 요소라 블록 부모와 늘려 맞추는 세로 flex(`DisclosureGroup` 포함)에서는 폭을 채웁니다. 가로 flex나 가운데 정렬 열에서는 내용 폭입니다. 채우려면 `classes: 'w-full'`을 둡니다. |

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `disclosureStyle`(`CoreDisclosureStyle`) 하나로 정합니다.

| 바꾸는 곳 | 필드 | 기본값 |
| --- | --- | --- |
| 여백 | `contentInset` | 사방 16 |
| 머리 글자 | `triggerTextStyle` | `bodyMedium` · 500 · `onSurface` |
| 본문 글자 | `contentTextStyle` | `bodyMedium` · `onSurface` |
| 화살표 | `iconStyle` · `iconLabelGapStyle` · `duration` | 16 · `onSurface` · 간격 16 · 200ms |
| 그룹 간격 | `itemSpacing` | 8 |
| 포커스 | `clickableStyle` | 위 상태 표 참고 |

- `contentInset`은 머리 줄에는 사방에, 본문에는 `top`만 적용됩니다. 그래서 기본값에서는 본문이 머리 글자보다 16 왼쪽에서 시작합니다. 같은 선에 맞추려면 `content`에 좌우 여백을 직접 둡니다.
- `clickableStyle.focusOutlineStyle`을 정하면 Web도 브라우저의 기본 표시 대신 그 값의 링을 그립니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
디자인 시스템 기본값
  → CoreComponentTheme.disclosure.style   // 앱 전체
  → disclosureStyle                       // 하나
```

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

`Disclosure`와 `DisclosureGroup`에 `withStyle`로 스타일을 이어 붙입니다. 겹치는 필드는 뒤에 붙인 값이 이깁니다. 이 컴포넌트에는 `withStyle` 말고 다른 체인이 없습니다.

<Preview component="disclosure" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DisclosureChainExample extends StatelessWidget {
  const DisclosureChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    ).withStyle(
      const CoreDisclosureStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DisclosureChainExample extends StatelessComponent {
  const DisclosureChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Disclosure(
      title: 'CoUI는 무엇인가요?',
      open: true,
      content: Text(
        'Flutter와 웹에서 똑같이 보이는 디자인 시스템이에요.',
      ),
    ).withStyle(
      const CoreDisclosureStyle(
        contentInset: CoreEdgeInsets.all(CoreSpace.space24),
        triggerTextStyle: CoreTextStyle.token(
          CoreTextStyles.titleSmall,
          color: CoreColor.token(CoreColors.primary),
        ),
        iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space12),
        iconStyle: CoreIconStyle(
          size: CoreSize.size20,
          color: CoreColor.token(CoreColors.primary),
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

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Jaspr Web | `<details>` · `<summary>` 자체가 브라우저의 여닫기 요소입니다. `role`이나 `aria-expanded`를 덧붙이지 않습니다. 스크립트가 없는 페이지에서는 그 값을 갱신할 수 없어, 덧붙이면 실제 상태와 어긋납니다. |
| Flutter | 머리 줄은 버튼이고 펼침 상태(`Semantics(expanded:)`)를 함께 알립니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` · `Shift+Tab` | 머리 줄에 멈춥니다. 열려 있으면 본문의 요소가 이어집니다. |
| `Enter` · `Space` | 여닫습니다. Web은 브라우저의 기본 동작이고, Flutter는 같은 키를 처리합니다. |

### 스크린 리더

- 머리 줄의 이름은 `title`이나 `trigger`의 내용입니다.
- 펼침 상태는 Web에서는 `<summary>`가, Flutter에서는 머리 줄이 알립니다.
- 닫힌 본문은 읽히지 않습니다.

### 포커스 관리

여닫을 때 포커스를 본문으로 옮기거나 가두지 않습니다. 머리 줄에서 여닫으면 포커스는 그대로 머리 줄에 있습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 스크립트가 붙은 앱에서 `Disclosure`가 다시 그려지면, 사용자가 여닫은 상태가 `open` 값으로 돌아갑니다. 서버가 그린 페이지에 스크립트가 처음 붙을 때도 같습니다. 스크립트가 붙지 않는 정적 페이지에는 해당하지 않습니다. |
| Jaspr Web | 열린 `Disclosure` 안에 넣은 `Disclosure`는 닫혀 있어도 화살표가 위를 봅니다. |
| 공통 | 이름이 없는 `trigger`나 빈 `title`을 넣어도 컴포넌트가 이름을 대신 붙이지 않습니다. |

> 동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 영역처럼 모든 컴포넌트에 걸리는 내용은 [접근성](/accessibility) 페이지가 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 열림을 기억하는 곳 | 위젯 상태 | `<details open>` |
| 닫은 본문 | 위젯 트리에서 빠집니다. 본문 안에 쌓인 상태(입력한 글자, 스크롤 위치 등)는 따로 보관하지 않으면 사라집니다. | 요소가 문서에 남고 브라우저가 보이지 않게 합니다. |
| 스크립트가 필요한가 | 해당 없음 | 여닫기에는 필요 없습니다. `onToggle`은 스크립트가 붙은 뒤에만 불립니다. |
| `onToggle`이 불리는 때 | 사용자가 머리 줄로 여닫을 때 | 열림이 바뀔 때마다(코드가 바꾼 경우도 포함) |
| 다시 그릴 때의 열림 | 사용자가 바꾼 상태를 유지합니다. `open` 값이 바뀔 때만 다시 맞춥니다. | `open` 값으로 돌아갑니다. |
| 마우스를 올림 | 머리 글자에 밑줄 | 변화 없음 |
| 포커스 표시(기본) | CoUI 포커스 링 | 브라우저 기본 표시 |
| 폭 | 받은 폭을 채웁니다. | 블록 부모와 늘려 맞추는 세로 flex에서는 가득, 가로 flex와 가운데 정렬 열에서는 내용 폭 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers`와 `onClick` 같은 이벤트 파라미터 |

<a id="props-parameters"></a>

## API

`W`는 Flutter에서는 `Widget`, Jaspr Web에서는 `Component`입니다.

### Disclosure

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `content` | `W` | 필수 | 열었을 때의 본문 |
| `title` | `String?` | `null` | 머리 줄의 글자. `title`과 `trigger` 중 하나는 있어야 합니다. |
| `trigger` | `W?` | `null` | 직접 만든 머리 줄. 둘 다 주면 이쪽을 씁니다. |
| `open` | `bool` | `false` | 처음 상태. 코드에서 다른 값을 넘기면 그 값으로 맞춥니다. Web은 다시 그릴 때마다 이 값으로 돌아갑니다. |
| `onToggle` | `void Function(bool)?` | `null` | 여닫힌 뒤 새 상태를 알립니다. |
| `disclosureStyle` | `CoreDisclosureStyle?` | `null` | 겉모습 |

### DisclosureGroup

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<W>` | 필수 | 쌓을 `Disclosure` 목록 |
| `disclosureStyle` | `CoreDisclosureStyle?` | `null` | `itemSpacing`만 읽습니다. |

### 그 밖의 멤버

- `withStyle(CoreDisclosureStyle patch)` — `Disclosure`와 `DisclosureGroup` 둘 다에 있습니다.
- `copyWith(…)` — 바꾼 값으로 사본을 만듭니다.
- Web은 `id`(HTML id) · `classes` · `css` · `attributes` · `eventHandlers` 같은 HTML 속성과 `onClick` 같은 이벤트 파라미터도 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDisclosureStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `contentInset` | `CoreEdgeInsets?` | Inner inset around the header row and the body (pre-scaling). |
| `itemSpacing` | `double?` | Vertical distance between siblings in a `DisclosureGroup`. Read by the group; a lone `Disclosure` has no sibling to space against. |
| `duration` | `Duration?` | Chevron rotation duration. |
| `triggerTextStyle` | `CoreTextStyle?` | Header text style override. |
| `contentTextStyle` | `CoreTextStyle?` | Body text style override. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Horizontal gap slot between the header text and the chevron. |
| `iconStyle` | `CoreIconStyle?` | Chevron icon style. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the header's focus ring and press feedback. Flutter passes it to the header's `Clickable`; Web uses its `focusOutlineStyle` for the `<summary>`'s ring, so the same override changes both platforms. |

<!-- STYLE_TABLE:END -->

<Note>

`contentInset`은 머리 줄에는 사방에, 본문에는 `top`만 적용됩니다. `clickableStyle` 가운데 Web이 쓰는 것은 `focusOutlineStyle`뿐입니다. 누름 반응(`pressedScale` · `pressedTranslate` · `pressedBoxShadow` · `pressDuration`)은 Flutter에만 적용됩니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="disclosure/related-collapsible" title="Collapsible">

열림을 코드에서 정할 수 있고, 본문이 부드럽게 펼쳐집니다.

</Card>
<Card demo="disclosure/related-accordion" title="Accordion">

하나를 열면 나머지가 닫히는 목록입니다.

</Card>
</Cards>
