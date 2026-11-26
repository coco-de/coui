---
title: StarRating
description: 별점으로 평가를 입력하거나 표시하는 컴포넌트
category: form
platforms: [flutter, web]
related: [slider, text-field]
tags: [interactive, form-control, rating]
template: v2
source: form/star_rating
---

# StarRating

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

값과 크기를 바꿔 보며 별점을 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="star-rating" />

별점은 값을 스스로 바꾸지 않습니다. 누르면 새 값으로 `onChanged` 를 부르므로, 호출자가 그 값을 `value` 로 다시 넘겨야 별이 바뀝니다. 별은 반 단위로만 그려집니다 — 기본 `step`(0.5)에서 `3.3` 은 별 세 개 반으로 보입니다. Flutter 는 반 단위로 맞추기 전에 먼저 `step` 으로 맞춥니다(플랫폼 차이 참고).

## 구조

별점은 별 묶음과, 켰을 때 그 뒤에 놓이는 값 · 개수 글자로 이루어집니다. 별 하나하나는 `Star` 위젯이 그립니다.

<Anatomy demo="star-rating/anatomy">
<AnatomyItem part="container" name="Container">

별 묶음과 값 · 개수 글자를 함께 감싸는 바깥 상자. 키보드 포커스 링이 이 상자 둘레에 그려집니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-star-state=filled]" side="top" name="filled">

다 채운 별. `primary` 로 칠합니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-star-state=half]" side="top" name="half">

반만 채운 별. 왼쪽 절반이 `primary`, 나머지가 `outlineVariant` 입니다.

</AnatomyItem>
<AnatomyItem select="[data-coui-star-state=empty]" side="top" name="empty">

빈 별. 선이 아니라 `outlineVariant` 로 면을 채웁니다.

</AnatomyItem>
<AnatomyItem select="[role=slider] > div + span" side="top" name="value">

값 글자(`showValue`). `value` 를 소수 한 자리로 그립니다.

</AnatomyItem>
<AnatomyItem select="[role=slider] > span:last-child" side="right" name="count">

개수 글자(`showCount` · `count`). 괄호로 감싸 그립니다.

</AnatomyItem>
</Anatomy>

누르고 포인터를 올리는 자리는 별 묶음뿐입니다. 값 · 개수 글자 위에서는 반응하지 않습니다.

## 크기

별은 16부터 32까지 4단계이고 기본은 `lg`(24)입니다. 별 사이 간격과 값 · 개수 글자의 역할(`labelSmall` · `labelLarge` · `labelXl` · `labelXl2`)도 크기를 따라 바뀝니다.

<SizeSpec component="star-rating" props="value=3.5;showValue=true" />

<Note>

`xs` 와 `xl2` 는 크기 행이 없어 각각 `sm` 과 `xl` 로 그려지고, assert 가 켜진 실행(디버그 빌드)에서는 assert 가 실패합니다. 표의 네 단계 중에서 고르세요.

</Note>

사용자가 누르는 별점은 `lg` 이상으로 둡니다. 별점은 누르는 영역을 따로 넓히지 않아서, `sm` · `md` 에서는 누를 수 있는 높이가 별 크기와 같은 16 · 20 입니다(접근성의 알려진 제약 참고).

## 형태

### 별 모양

별 하나의 모양은 여섯 속성으로 바꿉니다 — 꼭짓점 수(`starPoints`), 안쪽 반지름 비율(`starInnerRadiusRatio`), 꼭짓점과 골짜기의 둥글기(`starPointRounding` · `starValleyRounding`), 세로 압축(`starSquash`), 회전(`starRotation`, 라디안). 비워 두면 꼭짓점 5개 · 안쪽 반지름 0.4 · 꼭짓점 둥글기 0.15 의 별입니다.

<Preview demo="star-rating/shapes" />

```dart
StarRating(
  value: rating,
  starPoints: 6,
  starInnerRadiusRatio: 0.5,
  onChanged: setRating,
)
```

<Note>

두 플랫폼이 별을 다른 방법으로 그려서, 같은 값도 끝 모양이 조금 다를 수 있습니다. 특히 `starSquash` 는 Jaspr Web 에서만 별을 세로로 납작하게 만들고 Flutter 에서는 아무 일도 하지 않습니다. 소수 `starPoints` 와 큰 둥글기 값도 두 플랫폼이 다르게 다룹니다(플랫폼 차이 참고).

</Note>

## 값 · 개수 표시

`showValue` 는 `value` 를 소수 한 자리("4.5")로, `showCount` 는 `count` 를 "(128)" 로 별 뒤에 그립니다. 개수는 `count` 가 있을 때만 그립니다.

<Preview demo="star-rating/display-only" />

- 글자 역할은 `size` 가 정하고, 값은 `onSurface`, 개수는 `onSurfaceSubtle` 입니다. `starRatingStyle` 의 `valueStyle` · `countStyle` 로 덮습니다.
- 별과 글자 사이, 값과 개수 사이는 `valueGapStyle`(기본 8)입니다.
- 비활성이면 두 글자 모두 `disabledContent` 입니다.
- Flutter 는 확정된 `value` 를 그리고, Jaspr Web 은 포인터를 올린 동안 미리보기 값을 그립니다.

평균 평점처럼 보여 주기만 하는 별점은 `onChanged` 를 넘기지 않습니다. 별이 포인터에 반응하지 않습니다.

```dart
StarRating(
  value: 4.5,
  showValue: true,
  showCount: true,
  count: 128,
)
```

이렇게 둔 별점도 Flutter 에서는 Tab 정지점이 되고 누를 수 있는 커서가 나옵니다(알려진 제약 참고).

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="포커스-링"></a>

## 상태

별점에는 variant 가 없습니다. `enabled` 와 `onChanged` 가 별점이 반응하는지를 정합니다.

<Preview demo="star-rating/states" />

| 항목 | 동작 |
| --- | --- |
| 누를 때 | 누른 자리의 값으로 `onChanged` 를 부릅니다. Jaspr Web 은 `step` 에 맞춘 값을, Flutter 는 누르는 순간 `step` 에 맞추지 않은 값을 넘깁니다(알려진 제약 참고). |
| 포인터를 올릴 때 | 포인터 자리의 값을 미리 그리고, 포인터가 나가면 `value` 로 돌아옵니다. 값은 바꾸지 않습니다. |
| 끌 때 | Flutter 만 받습니다. 끄는 동안 미리 그리고, 손을 떼면 그 값으로 `onChanged` 를 부릅니다. |
| 키보드 | Flutter 만 `←` · `→` 로 `step` 만큼 바꿉니다(`0` ~ `max`). |
| 채움 | 값을 가장 가까운 반 단위로 맞춰 별마다 `filled` · `half` · `empty` 중 하나로 그립니다(기본 `step` 0.5 일 때 — Flutter 는 먼저 `step` 으로 맞춥니다, 플랫폼 차이 참고). 채운 쪽은 `primary`, 빈 쪽은 `outlineVariant` 입니다. |
| Focus | 키보드로 포커스했을 때만 별 묶음 전체(값 · 개수 글자 포함) 둘레에 링 하나를 그립니다. 링 색은 `primary` 입니다. |
| 비활성 | 채운 별 `disabledContent`, 빈 별 `disabledContainer`, 값 · 개수 글자 `disabledContent`. 포인터와 키보드에 반응하지 않고 포커스를 받지 않습니다. 단 Flutter 는 `onChanged` 가 있고 `value` 가 `step` 의 배수가 아니면, 누를 때 `step` 으로 반올림한 값으로 `onChanged` 를 한 번 부릅니다(알려진 제약 참고). |
| 표시 전용 (`onChanged` 없음) | 활성과 같은 색이고 포인터에 반응하지 않습니다. Flutter 는 포커스를 받고 누를 수 있는 커서가 그대로 나오며, Jaspr Web 은 기본 커서입니다(알려진 제약 참고). |
| 전환 시간 | 값이 바뀌면 채움이 150ms(`CoreDuration.fast`) 동안 바뀝니다. Flutter 는 동작 줄이기를 켜면 바로 바뀌고, Jaspr Web 은 그대로 150ms 입니다. |
| 커서 | Flutter 는 `enabled` 이면 `onChanged` 가 없어도 누를 수 있는 커서, 비활성이면 금지 커서입니다. Jaspr Web 은 누를 수 있을 때(`enabled` 이면서 `onChanged` 있음)만 누를 수 있는 커서이고, 아니면 기본 커서입니다. |
| 활성 여부 | `enabled` 의 기본값은 `true` 입니다. `onChanged` 유무로 정하지 않습니다. |

## 별 하나 (`Star`)

별 하나는 `Star` 위젯이 그립니다 — `state` 로 `CoreStarState.filled` · `half` · `empty` 중 하나를 받습니다. `StarRating` 은 그리는 값을 가장 가까운 반 단위로 맞춰(3.3 → 3.5) 별마다 상태를 고릅니다 — Flutter 는 그 전에 `step` 으로 맞춥니다. `Star` 는 단독으로도 씁니다(읽기 전용 표시, 범례). 크기와 색은 `StarRating` 과 같은 코드가 `size` · `enabled` · `starRatingStyle` 과 앱 테마에서 계산하므로, 같은 값을 넘기면 둘이 갈라지지 않습니다.

<Preview demo="star-rating/star" />

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

상품 · 서비스 · 콘텐츠의 만족도를 받거나, 리뷰의 평균 평점을 보여 줄 때 씁니다. 별점과 `step` 은 점수 단위, 별 크기와 간격은 논리 픽셀입니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 별의 뜻이 없는 값을 범위 안에서 고를 때 (음량 · 밝기) | [Slider](/components/slider) |
| 두 끝 값을 함께 고를 때 | [Range](/components/range) |
| 정확한 숫자를 직접 입력받을 때 | [TextField](/components/text-field) · [NumberInput](/components/number-input) |

<Note>

Jaspr Web 의 별점은 키보드로 값을 바꾸지 못하고, Flutter 도 `←` · `→` 두 키만 받습니다. 키보드로도 골라야 하는 자리에는 Web 에서 `onKeyDown` 으로 화살표를 직접 처리하거나, NumberInput 같은 입력을 함께 둡니다(접근성의 알려진 제약 참고).

</Note>

<a id="do"></a>
<a id="dont"></a>

### 평점 보이기와 고르기

<Cards columns="2">
<Card demo="star-rating/display-only" tone="do" eyebrow="이렇게 하세요">

평균 평점에는 값과 개수를 함께 보입니다. 몇 점인지, 몇 명이 매겼는지 바로 읽힙니다.

</Card>
<Card component="star-rating" props="value=4.5" tone="dont" eyebrow="이렇게 하지 마세요">

별은 반 단위로만 그려져 4.3 과 4.6 이 똑같이 보이고, 몇 명이 매겼는지도 알 수 없습니다.

</Card>
<Card component="star-rating" props="value=3;size=lg" tone="do" eyebrow="이렇게 하세요">

사용자가 누르는 별점은 `lg`(24) 이상으로 둡니다.

</Card>
<Card component="star-rating" props="value=3;size=sm" tone="dont" eyebrow="이렇게 하지 마세요">

`sm`(16) 별은 누를 자리가 작아 고르기 어렵습니다. 별점은 누르는 영역을 넓히지 않습니다.

</Card>
<Card demo="star-rating/related-slider" tone="do" eyebrow="이렇게 하세요">

음량 · 진행률처럼 평가가 아닌 값은 슬라이더로 고릅니다.

</Card>
<Card component="star-rating" props="value=3" tone="dont" eyebrow="이렇게 하지 마세요">

평가가 아닌 값을 별로 보이지 않습니다. 별은 "좋고 나쁨" 으로 읽힙니다.

</Card>
</Cards>

## 배치

### 축 (`direction`)

`direction` 은 별이 놓이는 축과 별 하나가 채워지는 방향을 함께 정합니다.

- `CoreAxis.horizontal`(기본): 별이 가로로 놓이고, 반별은 왼쪽 절반이 채워집니다.
- `CoreAxis.vertical`: 별이 세로로 쌓이고 첫 별이 맨 위에 놓입니다. 반별은 **아래쪽 절반**이 채워집니다 — 부분 채움이 옆으로 쓸리는 게 아니라 수위처럼 읽히도록.

<Preview component="star-rating" props="direction=vertical" />

세로 별점에서 포인터 자리를 값으로 읽는 방향은 플랫폼마다 다릅니다. Flutter 는 별이 놓인 축을 따라 위에서 아래로 읽고, Jaspr Web 은 별 묶음의 가로 폭(별 하나의 폭)을 왼쪽에서 오른쪽으로 읽습니다. Flutter 의 키보드는 세로에서도 `←` · `→` 입니다. 세로로 놓아도 두 플랫폼 모두 보조 기술에 그 방향을 알리지 않습니다(알려진 제약 참고).

## 테마와 스타일

크기는 위젯 속성 `size` 로 고르고, 별 색 · 별 크기 · 간격 · 값과 개수 글자 · 포커스 링 · 채움 전환 시간처럼 보이는 값은 `starRatingStyle`(`CoreStarRatingStyle`) 하나로 덮어씁니다. 이 값은 앱 테마와 같은 순서로 합쳐져 Flutter 와 Jaspr Web 에 똑같이 반영됩니다.

<Split>

<Code language="dart" title="별점 하나만 바꾸기">
StarRating(
  value: rating,
  onChanged: setRating,
  starRatingStyle: CoreStarRatingStyle(
    activeColor: CoreColor.token(CoreColors.warning),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    starRating: CoreStarRatingTheme(
      style: CoreStarRatingStyle(
        activeColor: CoreColor.token(CoreColors.warning),
      ),
    ),
  ),
)
</Code>

</Split>

<Note>

비활성일 때는 `activeColor` · `backgroundColor` 대신 `disabledActiveColor` · `disabledBackgroundColor` 를 씁니다. 비활성 값 · 개수 글자의 색은 바꿀 수 없습니다 — `valueStyle` · `countStyle` 에 준 색도 비활성에서는 `disabledContent` 로 바뀝니다.

</Note>

### 빠른 오버라이드 (Chain)

이미 만든 `StarRating` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `starRatingStyle` 인자와 같게 동작하고, 뒤에 붙인 값이 이깁니다. `.primary` 처럼 색 토큰 이름을 딴 getter 는 **빈 별 색**(`backgroundColor`)을 바꿉니다 — 채운 별의 기본 색도 `primary` 라서, 기본 별점에 `.primary` 만 붙이면 모든 별이 같은 색이 되어 값이 보이지 않습니다. 채운 별 색은 `withStyle` 로 `activeColor` 를 줍니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class StarRatingChainExample extends StatefulWidget {
  const StarRatingChainExample({super.key});

  @override
  State<StarRatingChainExample> createState() => _StarRatingChainExampleState();
}

class _StarRatingChainExampleState extends State<StarRatingChainExample> {
  double _value = 3;

  @override
  Widget build(BuildContext context) {
    return StarRating(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreStarRatingStyle(
            starSize: CoreSpace.space32,
            starSpacing: CoreSpace.space12,
            activeColor: CoreColor.token(CoreColors.warning),
          ),
        )
        .primary;
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class StarRatingChainExample extends StatefulComponent {
  const StarRatingChainExample({super.key});

  @override
  State<StarRatingChainExample> createState() => _StarRatingChainExampleState();
}

class _StarRatingChainExampleState extends State<StarRatingChainExample> {
  double _value = 3;

  @override
  Component build(BuildContext context) {
    return StarRating(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreStarRatingStyle(
            starSize: CoreSpace.space32,
            starSpacing: CoreSpace.space12,
            activeColor: CoreColor.token(CoreColors.warning),
          ),
        )
        .primary;
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

### 값이 정해지는 순서

```text
기본값 (defaultsBySize[size] · default*)
  → CoreComponentTheme.starRating.style   // 앱 전체
  → starRatingStyle                        // 인스턴스
```

뒤로 갈수록 우선합니다. 값 · 개수 글자는 크기 행의 역할 위에 `valueStyle` · `countStyle` 이 얹힙니다. 포커스 링은 `defaultFocusOutlineStyle`(색 `primary`) 위에 deprecated 인 `focusBorderColor` · `focusBorderWidth` 가, 그 위에 `focusOutlineStyle` 이 얹히고, 비운 필드는 `FocusOutline` 의 기본값을 따릅니다.

<a id="접근성-accessibility"></a>

## 접근성

별 하나하나가 아니라 별점 전체가 슬라이더 하나입니다. Flutter 는 `Semantics(slider: true)` 로, Jaspr Web 은 `role="slider"` 와 `aria-value*` 속성으로 알립니다. 별 하나하나에는 스크린 리더가 읽는 정보가 붙지 않습니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `Semantics(slider: true, label:, value:)` 로 알립니다. 이름은 활성 로케일의 `ratingLabel`(한국어 "평점"), 값은 `'<value> / <max>'` 한 문자열입니다. 최소 · 최댓값과 비활성은 싣지 않습니다. |
| Jaspr Web | 별 묶음과 글자를 담은 `<div>` 에 `role="slider"` · `aria-label`(같은 `ratingLabel`) · `aria-valuenow` · `aria-valuemin`(`0`) · `aria-valuemax`(`max`) 가 붙습니다. `enabled: true` 이면서 `onChanged` 가 있을 때만 `tabindex="0"` 이 붙고, `aria-disabled` 는 붙지 않습니다. |

Jaspr Web 은 이 속성들을 호출자가 넘긴 `attributes` **뒤에** 합칩니다. 그래서 `role` · `aria-label` · `aria-valuenow` · `aria-valuemin` · `aria-valuemax` 는 밖에서 덮어쓸 수 없습니다. `tabindex` 는 누를 수 있는 동안(`enabled` 이면서 `onChanged` 있음)에만 컴포넌트의 `0` 이 이기고, 누를 수 없으면 호출자가 넘긴 값이 남습니다. 그 밖의 속성(`aria-describedby` · `aria-labelledby` · `aria-disabled` · `aria-orientation` 등)은 그대로 붙습니다.

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `→` | `step` 만큼 올립니다 (`max` 에서 멈춤) | 없음 |
| `←` | `step` 만큼 내립니다 (`0` 에서 멈춤) | 없음 |
| `↑` · `↓` | 없음 | 없음 |
| `Home` · `End` | 없음 | 없음 |
| `PageUp` · `PageDown` | 없음 | 없음 |
| `Tab` · `Shift+Tab` | 포커스를 옮깁니다 | 포커스를 옮깁니다 |

Flutter 는 `FocusableActionDetector` 가 `←` · `→` 두 키만 받고, `direction: CoreAxis.vertical` 로 세로 배치해도 같은 두 키입니다. 키는 `enabled: true` 일 때 받고, `onChanged` 가 없으면 아무 일도 하지 않습니다.

Jaspr Web 은 `keydown` 을 처리하지 않습니다. 컴포넌트가 붙이는 이벤트는 별 묶음의 `mousemove` · `mouseleave` · `click` 과, 포커스 링을 위한 `role="slider"` 상자의 `focus` · `blur` 뿐입니다.

### 스크린 리더

- **이름**: 두 플랫폼 모두 활성 로케일의 `ratingLabel` 입니다. 무엇에 대한 별점인지 이름을 바꾸는 속성은 없습니다.
- **값**: Flutter 는 `'<value> / <max>'` 한 문자열로, Jaspr Web 은 `aria-valuenow` 숫자와 `aria-valuemin` · `aria-valuemax` 로 나눠 알립니다 — 같은 별점이 플랫폼마다 다른 모양으로 읽힙니다. Web 의 숫자는 `value` · `max` 를 `toString()` 한 글자 그대로입니다.
- **미리보기는 알리지 않습니다.** 포인터를 별 위로 지나가면 화면의 채움만 바뀌고, 알리는 값은 두 플랫폼 모두 확정된 `value` 입니다.
- **알림**: 라이브 리전이 아닙니다.

### 포커스 관리

오버레이가 아니므로 마운트될 때 포커스를 옮기지 않고 가두지도 않습니다. 별점 전체가 Tab 정지점 하나입니다.

포커스를 받는 조건이 플랫폼마다 다릅니다 — Jaspr Web 은 `enabled: true` **이면서** `onChanged` 가 있을 때만 `tabindex="0"` 을 붙이고, Flutter 는 `enabled` 만 보고 포커스를 받습니다.

포커스 링은 키보드로 포커스했을 때만 나타납니다 — Flutter 는 `FocusableActionDetector` 가 알리는 포커스 표시를, Jaspr Web 은 포커스를 받을 때 `:focus-visible` 이 맞는지를 읽습니다. 두 플랫폼 모두 별 묶음 전체를 감싼 `FocusOutline` 하나가 그리고, `starRatingStyle` 의 `focusOutlineStyle` 로 바꿉니다(`focusBorderColor` · `focusBorderWidth` 는 deprecated 이며 그 아래 층으로 계속 읽힙니다).

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | 키보드만으로 별점을 바꿀 수 없습니다(WCAG 2.1.1). 포커스는 받지만 어떤 키도 처리하지 않습니다. 대안: `StarRating(onKeyDown: ...)` 로 화살표 처리를 직접 넘깁니다 — 그 핸들러는 포커스를 받는 `role="slider"` 상자에 그대로 붙습니다. |
| Flutter | 화살표 두 개뿐입니다. `Home` · `End` 로 `0` 이나 `max` 로 가지 못하고, 세로 배치에서도 `↑` · `↓` 가 동작하지 않습니다. 키를 바꿀 자리가 없습니다. |
| 공통 | 비활성을 알리지 않습니다(포커스는 두 플랫폼 모두 받지 않습니다). Jaspr Web 은 `attributes: {'aria-disabled': 'true'}` 로 넣을 수 있고, Flutter 는 방법이 없습니다. |
| Flutter | 스크린 리더의 올리기 · 내리기 동작(`onIncrease` · `onDecrease`)이 없어 VoiceOver · TalkBack 의 조정 제스처로 값을 바꾸지 못합니다. |
| Flutter | `onChanged` 없이 두면(`enabled` 기본값 `true`) 포커스는 받지만 화살표가 아무 일도 하지 않는 빈 Tab 정지점이 되고, 별 위에는 누를 수 있는 커서가 나옵니다. `enabled: false` 를 주면 정지점은 빠지지만 별이 비활성 색으로 바뀝니다 — 색을 그대로 두려면 `ExcludeFocus` 로 감쌉니다. |
| 공통 | 별점의 이름은 `ratingLabel` 로 고정입니다. Jaspr Web 은 `attributes` 로 `aria-labelledby` 를 넘기면 가리킨 요소의 글자가 이름이 됩니다. Flutter 는 바꿀 속성이 없습니다. |
| 공통 | `size: sm` · `md`(16 · 20)이거나 `starSize` 를 24 아래로 내리면 누르는 영역이 WCAG 2.2 최소치(24) 아래로 갑니다. `Slider` · `Range` · `Toggle` 과 달리 별점은 누르는 영역을 넓히지 않습니다(Flutter `TouchTarget` · Web `coui-touch-target` 을 쓰지 않습니다). `lg` 이상을 씁니다. |
| Flutter | 누르는 순간 누른 자리의 값을 `step` 에 맞추지 않은 채 `onChanged` 로 넘기고, 손을 뗄 때 그 순간 그려진 값이 `value` 와 다르면 그 값으로 한 번 더 넘깁니다. 끌기를 마칠 때도 `step` 에 맞추지 않은 값을 넘깁니다. 별은 `step` 으로 반올림해 그리지만, 받은 값을 그대로 저장하면 `step` 의 배수가 아닐 수 있습니다. Jaspr Web 은 `step` 에 맞춘 값을 넘깁니다. |
| Flutter | 손을 뗄 때 그려진 값으로 다시 넘기는 호출은 `enabled: false` 여도 일어납니다. `onChanged` 가 있고 `value` 가 `step` 의 배수가 아니면(예: `step` 0.5 에 `value` 3.3), 비활성 별점을 눌러도 반올림한 값(3.5)으로 `onChanged` 가 불립니다. Jaspr Web 은 비활성이면 반응하지 않습니다. |
| Jaspr Web | 채움 전환(150ms)이 동작 줄이기 설정을 따르지 않습니다. Flutter 는 바로 바뀝니다. |
| Jaspr Web | 포인터를 올린 동안 값 글자가 미리보기 값으로 바뀝니다. 스크린 리더가 읽는 `aria-valuenow` 는 확정된 `value` 그대로라 화면 글자와 다를 수 있습니다. |
| Flutter | `starSquash` 는 효과가 없습니다 — Flutter 의 `StarBorder` 는 정사각형 상자에서 `squash` 를 쓰지 않습니다. Jaspr Web 은 별을 세로로 납작하게 만듭니다. |
| 공통 | 세로 배치를 알리지 않습니다. Jaspr Web 은 `aria-orientation` 을 붙이지 않아 가로 슬라이더로 읽히고(`attributes: {'aria-orientation': 'vertical'}` 로 넣을 수 있습니다), Flutter 의 `Semantics` 에는 방향을 싣는 속성이 없습니다. |
| Jaspr Web | 숨은 폼 입력에 `disabled` 가 없어 비활성 별점도 폼 제출에 `value` 가 실립니다. |
| 공통 | 오른쪽에서 왼쪽으로 쓰는 언어를 따로 다루지 않습니다. 별은 글 방향을 따라 오른쪽부터 놓이지만, 포인터 자리는 두 플랫폼 모두 왼쪽부터 값으로 읽고 반별도 왼쪽 절반이 채워집니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 별 그리기 | `StarBorder` 모양의 상자, 반별은 `ShaderMask` | SVG path(`CoreStarPath`), 채움은 잘라 내는 폭 0 · 0.5 · 1 |
| 세로 축 채움 | `LinearGradient` 를 아래에서 위로 | 잘라 내는 사각형을 아래 기준 `scaleY` 로 |
| 값이 바뀔 때 | 값이 150ms 동안 옮겨 가며 별이 반 단위로 차례로 바뀝니다 | 바뀐 별마다 채움(가로는 폭, 세로는 아래에서부터의 높이)이 150ms 동안 함께 움직입니다 |
| 동작 줄이기 | 바로 바뀝니다 | 150ms 그대로입니다 |
| 포인터 | 누르기 · 올리기 · 끌기 | 누르기 · 올리기 |
| 누를 때 넘기는 값 | `step` 에 맞추지 않은 값 | `step` 에 맞춘 값 |
| `value` 가 `step` 의 배수가 아닐 때 | `step` 으로 반올림해 그립니다 | 반 단위로만 맞춰 그립니다 |
| 값 글자 | 확정된 `value` | 포인터를 올린 동안 미리보기 값 |
| 세로 배치의 포인터 | 위에서 아래로 읽습니다 | 별 하나의 폭을 왼쪽에서 오른쪽으로 읽습니다 |
| 포인터를 받는 자리 | 별 `Flex` 위에서만 | 별 상자 위에서만 — 값 · 개수 글자는 제외 |
| 키보드 | `←` · `→` 로 `step` 만큼 | 없음 |
| 포커스를 받는 조건 | `enabled` | `enabled` 이면서 `onChanged` 있음 |
| 커서 | `enabled`: 누를 수 있는 커서(`onChanged` 가 없어도) · 비활성: 금지 커서 | `enabled` 이면서 `onChanged` 가 있을 때만 누를 수 있는 커서, 아니면 기본 커서 |
| 별 크기 단위 | 화면 배율(`scaling`)을 곱한 논리 픽셀 | rem — 브라우저 글자 크기를 따릅니다 |
| `starSquash` | 효과 없음 | 별을 세로로 납작하게 만듭니다 |
| 소수 `starPoints` | 짧은 꼭짓점 하나를 더해 그립니다 | 가장 가까운 정수로 반올림합니다 |
| 둥글기 | `starPointRounding` 과 `starValleyRounding` 의 합이 1 을 넘으면 assert 가 실패합니다 | 각각 0.5 까지로 자릅니다 |
| 값 · 개수 글자 | `Row` 안의 `Text` | `role="slider"` 상자 안의 `<span>` |
| 포커스 링 | 묶음 전체를 감싼 `FocusOutline` | 묶음 전체를 감싼 `FocusOutline` |
| 폼 값 | 없음 | `name` 이 있으면 `value` 를 담은 숨은 `<input type="hidden">` |
| 값을 스스로 들고 있는 별점 | `ControlledStarRating` · `StarRatingController` | 없음 |
| 스크린 리더 값 | `'<value> / <max>'` | `aria-valuenow` · `aria-valuemin` · `aria-valuemax` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 한쪽에만 있는 것은 아래 '전용' 절에, 타입이 다른 것은 그 행에 적습니다.

### 값과 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `value` | `double` | 필수 | 지금 별점. 별은 반 단위로 그립니다. |
| `onChanged` | `ValueChanged<double>?` | `null` | 새 값을 받습니다. 값은 호출자가 반영합니다. Web 의 타입은 `CoreValueChanged<double>?` 입니다. |
| `max` | `double` | `5` | 최대 별점. 별의 개수는 `max` 를 올림한 수입니다. |
| `step` | `double` | `0.5` | 값을 맞추는 단위. Flutter 의 키보드는 이만큼 움직이고, 포인터 미리보기도 이 단위로 맞춥니다. |
| `enabled` | `bool` | `true` | `false` 면 비활성 색으로 그리고 반응하지 않습니다. |
| `direction` | `CoreAxis` | `CoreAxis.horizontal` | 별이 놓이는 축. 반별이 채워지는 방향도 함께 정합니다. |

### 크기와 표시

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `size` | `CoreComponentSize` | `CoreComponentSize.lg` | 별 크기 — `sm` 16 · `md` 20 · `lg` 24 · `xl` 32 |
| `showValue` | `bool` | `false` | 별 뒤에 값("4.5")을 그립니다. |
| `showCount` | `bool` | `false` | 별 뒤에 개수("(128)")를 그립니다 — `count` 가 있을 때만 |
| `count` | `int?` | `null` | 평가 개수 |
| `starRatingStyle` | `CoreStarRatingStyle?` | `null` | 보이는 값 덮어쓰기 |

### 모양

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `starPoints` | `double?` | `null` (→ `5`) | 꼭짓점 수 |
| `starInnerRadiusRatio` | `double?` | `null` (→ `0.4`) | 안쪽 / 바깥 반지름 비율 |
| `starPointRounding` | `double?` | `null` (→ `0.15`) | 꼭짓점 둥글기 |
| `starValleyRounding` | `double?` | `null` (→ `0`) | 골짜기 둥글기 |
| `starSquash` | `double?` | `null` (→ `0`) | 세로 압축 — Jaspr Web 에서만 효과가 있습니다 |
| `starRotation` | `double?` | `null` (→ `0`) | 회전 (라디안) |

### Jaspr Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `name` | `String?` | `null` | 폼 제출용 숨은 입력의 이름 |

Web 은 이 밖에 `id` · `classes` · `css` · `attributes` 와 DOM 이벤트 슬롯(`onClick` · `onKeyDown` 등)을 받아 `role="slider"` 상자에 붙입니다.

### `Star`

별 하나를 그리는 위젯입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `state` | `CoreStarState` | `CoreStarState.empty` | `filled` · `half` · `empty` |
| `size` | `CoreComponentSize` | `CoreComponentSize.lg` | 별 크기 |
| `enabled` | `bool` | `true` | `false` 면 비활성 색으로 그립니다. |
| `direction` | `CoreAxis` | `CoreAxis.horizontal` | 반별이 채워지는 쪽 — 가로는 왼쪽, 세로는 아래쪽 절반 |

모양 속성(`starPoints` 등)과 `starRatingStyle` 은 `StarRating` 과 같습니다. Jaspr Web 의 `Star` 는 `id` · `classes` · `css` 도 받습니다.

### Flutter 전용 — `ControlledStarRating`

값을 위젯이 들고 있는 별점입니다. 바뀐 값은 `onChanged` 로 알려 줍니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `initialValue` | `double` | `0` | 처음 값 |
| `controller` | `StarRatingController?` | `null` | 값을 밖에서 읽고 바꿀 때 |

나머지 속성은 `StarRating` 과 같습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreStarRatingStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `animationDuration` | `Duration?` | Fill-transition duration — how long the star fill sweeps when the rating value changes (Flutter value lerp / Web CSS width transition, same token on both platforms). |
| `starSize` | `double?` | Star icon size (logical px). |
| `starSpacing` | `double?` | Horizontal spacing between stars (logical px). |
| `activeColor` | `CoreColor?` | Active (filled) star colour override. |
| `backgroundColor` | `CoreColor?` | Inactive (empty) star background colour override. |
| `disabledActiveColor` | `CoreColor?` | Active star colour override when disabled. `null` defers to [defaultDisabledActiveColor]. |
| `disabledBackgroundColor` | `CoreColor?` | Empty star colour override when disabled. `null` defers to [defaultDisabledBackgroundColor]. |
| `valueStyle` | `CoreTextStyle?` | Value text style ("4.5"). `null` defers to the size row of [defaultsBySize]. |
| `countStyle` | `CoreTextStyle?` | Count text style ("(128)"). `null` defers to the size row of [defaultsBySize]. |
| `valueGapStyle` | `CoreGapStyle?` | Gap between the stars and the value / count text. `null` defers to [defaultValueGapStyle]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Keyboard focus ring drawn around the whole group, forwarded to the composed `FocusOutline`. `null` defers to [defaultFocusOutlineStyle]. |
| `focusBorderColor` | `CoreColor?` | **Deprecated (since 0.173)** — Use focusOutlineStyle — the ring is one FocusOutline around the whole group now; its colour is FocusOutline's borderColor. Keyboard focus ring colour override. `null` defers to [defaultFocusBorderColor]. Still read, as the lowest layer of [focusRingStyle]. |
| `focusBorderWidth` | `double?` | **Deprecated (since 0.173)** — Use focusOutlineStyle — the ring width is FocusOutline's borderWidth. Keyboard focus ring width override (logical px, pre-scaling). `null` defers to [defaultFocusBorderWidth]. Still read, as the lowest layer of [focusRingStyle]. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="star-rating/related-slider" title="Slider">

별의 뜻이 없는 값을 범위 안에서 고릅니다.

</Card>
<Card demo="star-rating/related-range" title="Range">

두 끝 값을 함께 고릅니다.

</Card>
<Card demo="star-rating/related-text-field" title="TextField">

정확한 숫자를 직접 입력받습니다.

</Card>
</Cards>
