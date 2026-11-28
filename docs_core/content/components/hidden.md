---
title: Hidden
description: hidden 값 하나로 자식을 흐리게 지우면서 한 축으로 접거나, 다시 펼치는 감싸는 컴포넌트입니다.
category: layout
platforms: [flutter, web]
related: [collapsible, swap]
tags: [hidden, toggle, collapse, animation]
template: v2
source: layout/hidden
---

# Hidden

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`hidden`을 켜고 끄며 전환을 보고, 만들어진 코드를 그대로 복사하세요.

<Playground component="hidden" />

## 상태

`hidden: true`면 불투명도가 0이 되고, 접는 축의 크기가 0으로 줄어듭니다. 아래 장면에서 숨긴 쪽은 앞뒤 내용만 남습니다.

<Preview demo="hidden/states" />

| `hidden` | 화면 | 누르기 |
| --- | --- | --- |
| `false` | 자식이 그대로 보입니다. | 자식이 받습니다. |
| `true` | 자식이 보이지 않고, `keepSpace`가 아니면 접는 축의 크기가 0이 됩니다. | 값을 바꾸는 순간부터 자식이 받지 않습니다. 흐려지며 아직 보이는 동안에도 같습니다. |

자식은 숨긴 동안에도 트리에 남습니다. 그래서 입력한 값 같은 자식의 상태는 그대로입니다.

## 접는 축과 자리

`direction`은 접는 축입니다. `vertical`(기본)은 높이를, `horizontal`은 폭을 줄입니다. 부모가 접는 축의 크기를 정해 둔 자리(늘려 맞추는 `Column`에서의 `horizontal`, 크기가 고정된 상자 등)에서는 Flutter의 크기가 줄지 않습니다.

Web에서 `horizontal`로 접으면 좁아지는 폭에 맞춰 자식의 글자가 줄 바꿈해 높이가 늘어납니다. 글자 배지 하나가 몇 줄 높이가 됩니다. Web의 가로 접기는 아이콘처럼 줄 바꿈이 없는 자식에 쓰세요.

<Preview demo="hidden/direction" />

`keepSpace: true`면 크기를 줄이지 않고 불투명도만 바꿉니다. 주변이 움직이면 안 되는 자리에 씁니다.

<Preview demo="hidden/keep-space" />

`reverse: true`는 접히면서 남는 쪽을 뒤쪽 가장자리(세로는 아래, 가로는 오른쪽)로 바꾸려는 값입니다. Flutter에서만 화면에 나타납니다. Web은 이 값을 받지만 접히는 모양이 바뀌지 않습니다.

<a id="동작-스펙-behavior"></a>

## 전환

전환 시간은 200ms, 곡선은 `CoreEasing.move`입니다. `duration`과 `curve`로 하나만 바꾸고, 앱 전체는 `CoreHiddenTheme`으로 바꿉니다.

`curve`는 cubic-bezier 제어점 네 개(`CoreCubicBezier`, 예: `CoreEasing.*`)를 받습니다. Flutter는 이 값을 `Curve`로, Web은 같은 제어점의 `cubic-bezier(…)`로 바꾸므로 값 하나가 두 플랫폼의 곡선을 정합니다. Flutter의 `Curves.*`는 넘길 수 없습니다.

| 플랫폼 | 크기가 바뀌는 방식 |
| --- | --- |
| Flutter | 자식 크기에서 0까지 시간에 따라 줄어듭니다. 줄어드는 동안 자식을 자르지 않아, 흐려지는 자식이 이웃 위에 겹쳐 보일 수 있습니다. |
| Jaspr Web | `max-height`(가로는 `max-width`)를 아주 큰 상한과 0 사이에서 바꿉니다. 그래서 내용이 낮을수록 크기 변화가 접을 때는 전환의 끝에, 펼칠 때는 처음에 몰립니다. |

동작 줄이기를 켰을 때는 두 플랫폼이 다릅니다.

| 플랫폼 | 동작 줄이기 |
| --- | --- |
| Flutter | 500ms 이하의 크기 전환은 바로 바뀝니다. 흐려지는 전환은 Flutter 프레임워크의 애니메이션 끄기 설정에서만 짧아집니다. |
| Jaspr Web | 크기와 흐림 전환 모두 설정과 관계없이 같은 시간이 걸립니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

머리 줄 없이 한 영역을 부드럽게 숨기거나 보여야 할 때 씁니다. 저장 결과처럼 잠깐 나타나는 안내가 그런 경우입니다. 여닫는 트리거 · 상태 콜백 · 타이머는 없으니 코드에서 `hidden`을 바꿉니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 누르는 머리 줄까지 필요할 때 | [Collapsible](/components/collapsible) |
| 두 내용을 바꿔 보여 줄 때 | [Swap](/components/swap) |
| 숨긴 동안 자식이 아예 없어야 할 때 | 조건에 따라 위젯 · 컴포넌트를 만들지 않습니다. |

### 누를 수 있는 것은 조건으로 빼기

<Split>

<Code language="dart" title="이렇게 하세요">
// 누를 수 있는 것은 숨길 때 아예 만들지 않습니다.
if (canSubmit) Button(onPressed: submit, child: Text('제출'))
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 숨긴 버튼에 Tab으로 포커스가 갑니다.
Hidden(
  hidden: !canSubmit,
  child: Button(onPressed: submit, child: Text('제출')),
)
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

Hidden에는 인스턴스에 주는 스타일 파라미터가 없습니다. 앱 전체의 값은 `CoreComponentTheme.hidden`(`CoreHiddenTheme`)에 둡니다.

```dart
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    hidden: CoreHiddenTheme(
      style: CoreHiddenStyle(
        transitionDuration: Duration(milliseconds: CoreDuration.moderate),
      ),
    ),
  ),
)
```

`CoreHiddenTheme`은 `direction` · `duration` · `curve` · `keepSpace` · `reverse`도 직접 받습니다. 값은 위젯 파라미터, 테마의 직접 필드, 테마의 `style`, 디자인 시스템 기본값 순서로 먼저 있는 것을 씁니다. `style`에는 전환 시간과 곡선만 있습니다.

<a id="접근성-accessibility"></a>

## 접근성

`Hidden`은 보이는 모습과 누르기를 다루는 컴포넌트입니다. 보조 기술과 키보드에서의 숨김은 두 플랫폼이 다르고, 어느 쪽도 완전하지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 없습니다. `semanticLabel`을 주면 그 이름의 컨테이너 노드가 하나 생깁니다. |
| Jaspr Web | 없습니다. 바깥 `<div>`에 `aria-hidden`이 `hidden` 값 그대로(`"true"` · `"false"`) 붙고 `data-state`(`hidden` · `visible`)도 함께 붙습니다. `semanticLabel`은 `aria-label`이 됩니다. 역할이 없는 `<div>`의 이름은 스크린 리더가 읽지 않을 수 있습니다. |

### 키보드

처리하는 키가 없습니다.

### 스크린 리더

| 플랫폼 | 숨긴 동안 |
| --- | --- |
| Flutter | 전환이 끝나 불투명도가 0이 되면 자식이 접근성 트리에서 빠집니다. `semanticLabel`의 노드는 `keepSpace: true`로 자리를 남긴 때에만 남고, 크기가 0으로 접히면 함께 빠집니다. |
| Jaspr Web | 전환을 시작하는 순간 `aria-hidden="true"`로 자식이 접근성 트리에서 빠집니다. |

### 포커스 관리

두 플랫폼 모두 포커스를 관리하지 않습니다. 숨긴 자식 안의 버튼 · 입력은 Tab 순서에 남아 있어, 보이지 않는 곳에 포커스가 갈 수 있습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 숨긴 동안에도 자식에 Tab으로 포커스를 줄 수 있고, 포커스를 받은 버튼은 키보드로 눌립니다. 누를 수 있는 것이 있으면 숨길 때 아예 만들지 않거나, 감싸는 쪽에서 포커스와 보조 기술에서 함께 빼야 합니다. |
| Jaspr Web | 포커스를 받을 수 있는 자식이 `aria-hidden="true"` 안에 남습니다. |
| Jaspr Web | 동작 줄이기 설정이 전환에 닿지 않습니다. |
| Jaspr Web | `horizontal`로 접으면 자식의 글자가 줄 바꿈해 높이가 늘어납니다. |

> 동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 영역처럼 모든 컴포넌트에 걸리는 내용은 [접근성](/accessibility) 페이지가 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 크기 전환 | 자식 크기에 비례해 줄어듭니다. | `max-height` · `max-width` 전환 |
| 줄어드는 동안 | 자식을 자르지 않습니다. | 숨기는 쪽으로 바꾸는 순간부터 자릅니다. |
| `reverse` | 뒤쪽 가장자리를 남기며 접습니다. | 화면에 나타나지 않습니다. |
| 누르기 막기 | `IgnorePointer` | `pointer-events: none` |
| 숨긴 자식과 보조 기술 | 전환이 끝나면 빠집니다. | 바로 빠집니다. |
| 동작 줄이기 | 500ms 이하의 크기 전환은 따르고, 흐려지는 전환은 Flutter의 애니메이션 끄기 설정만 따릅니다. | 따르지 않습니다. |
| 가로로 접을 때 | 자식의 높이를 유지합니다. | 글자가 줄 바꿈해 높이가 늘 수 있습니다. |
| 부모가 접는 축 크기를 정한 자리 | 크기가 줄지 않습니다. | `max-height` · `max-width`를 0으로 정합니다. |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

`W`는 Flutter에서는 `Widget`, Jaspr Web에서는 `Component`입니다.

### Hidden

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 숨기거나 보일 내용 |
| `hidden` | `bool` | 필수 | `true`면 숨깁니다. |
| `direction` | `CoreHiddenDirection?` | `vertical` | 접는 축(`vertical` · `horizontal`) |
| `keepSpace` | `bool?` | `false` | 자리를 남기고 불투명도만 바꿉니다. |
| `reverse` | `bool?` | `false` | 뒤쪽 가장자리를 남기며 접습니다(Flutter). |
| `duration` | `Duration?` | 200ms | 전환 시간 |
| `curve` | `CoreCubicBezier?` | `CoreEasing.move` | 전환 곡선 |
| `semanticLabel` | `String?` | `null` | 보조 기술에 알릴 이름 |

`direction` · `keepSpace` · `reverse` · `duration` · `curve`를 비우면 테마 값을, 테마에도 없으면 표의 기본값을 씁니다.

### 그 밖의 멤버

- Web은 `copyWith(…)`와 `id`(HTML id) · `classes` · `css` · `attributes` · `eventHandlers` 같은 HTML 속성도 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreHiddenStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `transitionDuration` | `Duration?` | Collapse / expand transition duration override. `null` → [defaultTransitionDuration]. |
| `transitionCurve` | `CoreCubicBezier?` | Collapse / expand transition easing override. `null` → [defaultTransitionCurve]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="hidden/related-collapsible" title="Collapsible">

누르는 머리 줄이 있는 접기 · 펼치기입니다.

</Card>
<Card demo="hidden/related-swap" title="Swap">

두 내용 가운데 하나를 바꿔 보여 줍니다.

</Card>
</Cards>
