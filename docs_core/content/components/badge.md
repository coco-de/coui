---
title: Badge
description: 상태 · 개수 · 분류를 짧게 표시하는 작은 라벨입니다. 색의 뜻(tone), 세기(variant), 담는 것(form)을 따로 골라 만듭니다.
category: display
platforms: [flutter, web]
related: [avatar, icon, chip]
tags: [indicator, count, status, tag]
template: v2
source: display/badge
---

# Badge

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 배지를 확인하고, 만들어진 코드를 그대로 복사하세요. 아무 값도 주지 않은 `Badge` 는 분류 태그(`neutral` · `tonal` · `label` · `md`)입니다.

<Playground component="badge" />

<a id="구조-anatomy"></a>

## 구조

배지는 상자 하나와 네 부분으로 이루어집니다. 부분 이름은 위젯 슬롯과 같고, Figma [`❖ Badge`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0?node-id=2467-123907) 레이어와도 맞습니다.

<Anatomy demo="badge/anatomy">
<AnatomyItem part="container" name="Container">

배경, 테두리, 모서리. 높이는 크기마다 정해져 있고 내용을 가운데에 둡니다.

</AnatomyItem>
<AnatomyItem select="span[aria-hidden]" side="top" name="leading dot">

글 앞의 상태 점(`showDot`). 글자색으로 칠합니다. `outlined` 의 상태 톤에서는 선 색입니다.

</AnatomyItem>
<AnatomyItem part="leading" name="leading">

글 앞 아이콘 슬롯. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" name="child">

레이블 — 낱말(`label`) 또는 숫자(`count`). 접근 가능한 이름이 됩니다.

</AnatomyItem>
<AnatomyItem part="trailing" name="trailing">

글 뒤 아이콘 슬롯. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

`form: CoreBadgeForm.dot` 은 이 부분을 하나도 그리지 않고 원 하나만 그립니다.

<a id="변형-variants"></a>

## Variant

배지는 세 축을 따로 고릅니다. 세 축은 서로 독립입니다 — 성공 배지는 채움 · 옅은 채움 · 선 어느 세기로도 쓸 수 있고, 점도 톤을 가집니다. 뜻과 세기를 한 축에 섞으면 "옅은 빨간 라벨" 이나 "빨간 점" 을 말할 수 없습니다.

| 축 | 값 (굵게 = 기본) | 답하는 질문 |
| --- | --- | --- |
| `tone` | **`neutral`** · `primary` · `info` · `success` · `warning` · `destructive` | 무슨 뜻의 색인가 |
| `variant` | `filled` · **`tonal`** · `outlined` | 얼마나 센가 |
| `form` | **`label`** · `count` · `dot` | 무엇을 담나 — 낱말 · 숫자 · 없음 (형태 섹션) |

### tone — 색의 뜻

색이 무슨 뜻인지 고릅니다. 이름은 Alert 가 같은 뜻에 쓰는 이름과 같아, 상태가 어느 컴포넌트에서나 같은 낱말로 읽힙니다.

<VariantRow name="neutral" component="badge" props="tone=neutral" label="중립">

상태가 없는 분류 태그나 중립적인 개수에 씁니다. 기본값입니다.

</VariantRow>

<VariantRow name="primary" component="badge" props="tone=primary" label="주요">

브랜드 강조색입니다.

</VariantRow>

<VariantRow name="info" component="badge" props="tone=info" label="정보">

정보나 새로 생긴 것에 씁니다.

</VariantRow>

<VariantRow name="success" component="badge" props="tone=success" label="성공">

완료 · 정상 · 승인에 씁니다.

</VariantRow>

<VariantRow name="warning" component="badge" props="tone=warning" label="경고">

곧 주의가 필요한 것에 씁니다.

</VariantRow>

<VariantRow name="destructive" component="badge" props="tone=destructive" label="위험">

실패 · 막힘 · 삭제에 씁니다.

</VariantRow>

### variant — 세기

같은 톤을 얼마나 세게 칠할지 고릅니다. 이름은 Card · Chip 의 세기 이름(`filled` · `outlined`)과 같습니다.

<VariantRow name="filled" component="badge" props="tone=primary;variant=filled" label="채움">

톤 색으로 꽉 채웁니다. 가장 셉니다. 읽지 않은 수처럼 놓치면 안 되는 개수에 씁니다.

</VariantRow>

<VariantRow name="tonal" component="badge" props="tone=primary;variant=tonal" label="톤">

톤의 컨테이너 색 위에 컨테이너 글자색을 칠합니다. 소리치지 않고 상태를 읽히게 합니다. 기본값입니다.

</VariantRow>

<VariantRow name="outlined" component="badge" props="tone=primary;variant=outlined" label="외곽선">

투명한 바탕에 톤 색 선을 두릅니다. 색을 말하는 가장 조용한 세기입니다.

</VariantRow>

### 톤 × 세기 색

<Preview demo="badge/tone-strength" />

톤마다 세 세기와 점의 색이 `CoreBadgeStyle.defaultsByTone` 의 `CoreBadgeToneStyle` 한 행에 있습니다. 값은 API 의 "`CoreBadgeStyle` 톤별 기본값" 표에 있습니다 — `filled*` · `tonal*` 은 면과 글자, `outlined*` 는 선과 글자, `dotColor` 는 점의 색입니다.

- 상태 톤 넷(`info` · `success` · `warning` · `destructive`)과 `primary` 는 그 톤의 시맨틱 색을 읽습니다 — `filled` 는 톤 색 위의 `on` 색, `tonal` 은 컨테이너 위의 컨테이너 글자색입니다. `destructive` 의 색 이름은 `error` 입니다.
- `neutral` 에는 상태 색이 없어 표면 단계를 읽습니다. `filled` 가 가장 높은 단(`surfaceContainerHighest`), `tonal` 이 한 단 아래(`surfaceContainerHigh`)이고 글자는 둘 다 `onSurfaceVariant` 입니다.
- `outlined` 의 면은 표에 없습니다 — 모든 톤이 `CoreBadgeStyle.defaultOutlinedBackgroundColor`(`surface` 0%, 투명)를 쓰고, 선은 1px(`stroke1`)입니다. 테두리는 선 색이 있을 때만 그려지므로 기본적으로 `outlined` 에만 있습니다.
- 앞 점(`showDot`)과 아이콘은 글자색을 따릅니다. 그래서 `tonal` 의 앞 점은 `onXContainer` 입니다. 예외는 상태 톤 넷의 `outlined` 로, 앞 점과 아이콘이 선과 같은 톤 색(`outlinedMarkColor`)이고 글자는 컨테이너 글자색 그대로입니다 — 글자는 어느 바탕에서도 4.5 : 1 을 지켜야 하는데 톤 색은 회색 바탕에서 그 선에 못 미칩니다.
- 점(`dot`)은 세기와 무관하게 그 톤의 `dotColor` 하나로 칠합니다 — 지켜야 할 글자가 없으니 세 세기가 다를 까닭이 없습니다.

### 의미 체인

배지의 `.primary`, `.info`, `.success`, `.warning`은 `tone`을 선택하고 `.outline`은 `variant: .outlined`를 선택합니다. `Badge(child: const Text('완료')).success.outline`은 성공 톤의 윤곽 배지입니다.

라벨·숫자 배지에서는 안쪽 여백과 전경색을 지정할 수 있습니다. 점 배지의 지름은 기존 `dotSize`가 정합니다.

```dart
Badge(child: const Text('완료')).success.outline
    .contentPadding(.symmetric(horizontal: CoreSpace.space8))
    .borderWidth(CoreStrokeWidth.stroke2)
```

## 크기

높이 18부터 36까지 6단계입니다. 세로 여백은 없습니다 — 그 높이(`minHeight`)를 바닥으로 두고 내용을 가로 · 세로 가운데에 둡니다. 글자 역할, 아이콘, 점 지름이 높이에 맞춰 함께 바뀝니다.

<SizeSpec component="badge" props="tone=primary" label="신규" />

- 글자 굵기는 담는 것이 정합니다. 낱말(`label`)은 글자 역할의 굵기(Medium, 500), 숫자(`count`)는 SemiBold(600)입니다. 작은 크기의 숫자 하나는 낱말보다 가늘어 보이기 때문입니다.
- 표의 모서리는 `label` 의 것으로, 높이의 1/4 을 반경 사다리로 내린 값입니다. `count` 와 `dot` 은 크기와 무관하게 알약(`9999`)입니다.
- 점 지름은 `form: dot` 의 원, 앞 점 지름은 `showDot` 의 점입니다.

<Note>

기본값은 `md`(24)입니다. 상태 라벨과 태그가 함께 쓰는 높이입니다.

</Note>

## 형태

모양은 담는 것(`form`)을 따릅니다. 기본값은 `label` 입니다.

<Cards columns="3">
<Card component="badge" props="tone=primary" label="신규" title="label">

낱말 — 상태, 분류, 태그. 크기의 높이에 맞춘 둥근 사각입니다.

</Card>
<Card component="badge" props="tone=info;variant=filled;form=count" label="12" title="count">

숫자 — 읽지 않은 수, 합계. 같은 높이의 알약이고, 폭이 높이보다 좁아지지 않아 한 자리 숫자도 원으로 남습니다.

</Card>
<Card component="badge" props="tone=destructive;form=dot" title="dot">

내용 없이 "여기에 무언가 있다" 만 알립니다. `dotSize` 지름의 원입니다.

</Card>
</Cards>

```dart
// 분류 태그 — 모든 기본값 (neutral · tonal · label · md)
Badge(child: Text('디자인'))

// 개수 — 채운 숫자 알약
Badge(
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text('3'),
)

// 점 — 내용 없이 톤만
Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot)
```

Flutter와 Web 코드가 같습니다.

- **`label`** — 크기의 높이를 바닥으로 둔 둥근 사각입니다. 부모가 너비를 제한하면 긴 낱말이 줄바꿈되어 높이가 늘어납니다(배치 섹션).
- **`count`** — 같은 높이의 알약입니다. 한 줄을 지키고, 제한된 너비에 들어가지 않으면 말줄임으로 줄입니다.
- **`dot`** — `child` · `leading` · `trailing` · 앞 점을 그리지 않고 여백도 쓰지 않습니다. 비어 있는 내용 줄이라도 여백을 쓰면 상자가 크기 단계가 아니라 여백의 크기가 되는데, 이 형태가 막으려는 것이 바로 그것입니다.

## 상태 점과 아이콘

### 상태 라벨 — 앞 점

`showDot: true` 는 글 앞에 작은 점을 그립니다. 점은 글자색으로 칠해 라벨의 일부로 읽히고, `leading` 보다 앞에 같은 간격(`iconLabelGapStyle`)을 두고 놓입니다. `label` · `count` 에만 그리고 `dot` 에는 그리지 않습니다.

<Preview demo="badge/status-dot" />

```dart
Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중'))
Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨'))
Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('반려됨'))
```

### Leading / Trailing 아이콘

아이콘은 크기 단계의 아이콘 크기와 배지의 글자색을 받습니다(`outlined` 의 상태 톤에서는 선 색). `dot` 에는 그리지 않습니다.

<Cards columns="2">
<Card component="badge" props="tone=primary;leading=star" label="추천" title="leading">

글 앞에 놓는 아이콘입니다.

</Card>
<Card component="badge" props="trailing=arrow-right" label="다음" title="trailing">

글 뒤에 놓는 아이콘입니다.

</Card>
</Cards>

```dart
Badge(
  tone: CoreBadgeTone.primary,
  leading: Icon(LucideIcons.star),
  child: Text('추천'),
)

Badge(
  trailing: Icon(LucideIcons.arrowRight),
  child: Text('다음'),
)
```

<a id="동작-스펙-behavior"></a>

## 상태

배지는 기본적으로 표시 전용입니다. `onPressed` 를 주면 누를 수 있는 배지가 되고, 그때만 상태를 그립니다. 아래 미리보기의 누를 수 있는 배지는 마우스를 올리거나 누르면 실제로 그 상태를 그립니다.

<Preview demo="badge/states" />

| 항목 | 동작 |
| --- | --- |
| Hover | 글자색을 8% 로 면 위에 덮습니다(`CoreStateLayer.standard`). |
| Pressed | 글자색을 16% 로 덮습니다. 키보드로 `Enter` · `Space` 를 눌러도 그립니다 — 웹은 키를 누르고 있는 동안, Flutter 는 한 번 누를 때 잠깐(100ms, `CoreDuration.instant`) 그립니다. |
| 키보드 포커스 | 포커스 링(`focusOutlineStyle`)을 그립니다. 상태층은 덮지 않습니다. |
| 전환 | 색과 선이 150ms(`CoreDuration.fast`) 동안 `move` 곡선으로 바뀝니다. 표시 전용 배지도 톤이 바뀌면 같은 시간으로 바뀝니다. 동작 줄이기를 켜면 바로 바뀝니다. |
| 표시 전용 | `onPressed: null` 이면 어떤 상태도 칠하지 않습니다. 선택 · 제거 · 비활성 플래그는 없습니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 항목의 상태를 라벨로 표시할 때 — 진행 중, 완료, 오류 (`tone` + `showDot`)
- 읽지 않은 개수 같은 숫자를 붙일 때 (`form: CoreBadgeForm.count`)
- 카테고리나 태그를 짧게 붙일 때 — 누를 수 없는 분류 표시는 Chip 이 아니라 Badge 입니다
- 내용 없이 "여기에 무언가 있다" 만 알릴 때 (`form: CoreBadgeForm.dot`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 사람이나 기기의 접속 상태(online · away · busy · offline) | [Status](/components/status) |
| 검증 규칙의 valid · invalid · pending 상태 | [ValidationBadge](/components/validation-badge) |
| 선택 상태나 제거 동작이 필요한 태그 | [Chip](/components/chip) |
| 제목 · 설명 · 복구 행동을 가진 오래 남는 메시지 | [Alert](/components/alert) |
| 잠시 나타났다 사라지는 알림 | [Toast](/components/toast) |
| 다른 요소의 모서리에 배지를 얹을 때 | [Indicator](/components/indicator)에 배지를 넣습니다 |

### 뜻과 길이

<Cards columns="2">
<Card demo="badge/do-tone" tone="do" eyebrow="이렇게 하세요">

뜻은 `tone` 으로 고릅니다. 톤 하나가 면 · 글자 · 선 · 점 · 상태층 색을 함께 정합니다.

</Card>
<Card demo="badge/dont-style-color" tone="dont" eyebrow="이렇게 하지 마세요">

`badgeStyle` 로 면만 칠해 뜻을 만들면 글자 · 앞 점 · 아이콘 색은 `neutral` 에 남아 대비가 보장되지 않습니다.

</Card>
<Card demo="badge/do-short" tone="do" eyebrow="이렇게 하세요">

배지에는 한두 낱말이나 숫자를 넣고, 숫자는 `count` 로 씁니다.

</Card>
<Card demo="badge/dont-long" tone="dont" eyebrow="이렇게 하지 마세요">

문장을 넣으면 좁은 자리에서 줄이 바뀌어 배지가 커지고 읽기 어렵습니다. 문장이 필요하면 Alert 를 씁니다.

</Card>
</Cards>

## 배치

배지는 글줄, 목록 행, 카드 안에 다른 내용과 나란히 놓입니다. 다른 요소의 모서리에 얹으려면 [Indicator](/components/indicator)에 넣고, 프로필 사진에 붙이려면 Avatar 의 `badge` 슬롯에 넣습니다.

### 긴 레이블과 좁은 너비

<Preview demo="badge/long-label" />

Flutter와 Web 모두 `label` 형태에서 부모가 너비를 제한하면 긴 레이블이 줄바꿈되고 배지 높이가 늘어납니다. 문구를 저절로 줄이지 않고, 너비 제한이 없으면 내용 크기를 따릅니다. `count` 형태는 한 줄을 지키며 제한된 너비에 들어가지 않으면 말줄임으로 표시하고, 전체 숫자는 접근성 정보에 남습니다. 짧은 레이블의 기본 크기와 스타일은 그대로입니다. 상태 점과 앞뒤 아이콘은 크기를 지키고, 남은 너비를 레이블이 씁니다.

Flutter의 `Row`처럼 자식에게 너비를 무제한으로 주는 부모에서는 `Flexible(child: Badge(...))`, `ConstrainedBox` 나 `SizedBox(width: ..., child: Badge(...))`로 배지에 쓸 수 있는 너비를 넘기세요. Web에서는 너비가 제한된 컨테이너 안에 두면 됩니다. `child`에 직접 지정한 줄 수 제한이나 말줄임 설정은 그대로 적용됩니다. 아이콘과 여백보다 좁은 너비까지 배지를 줄이는 것은 지원하지 않습니다.

줄바꿈은 번역이나 글자 확대 때의 넘침을 막기 위한 동작입니다. 배지에는 짧은 상태 · 분류 문구를 쓰세요. 아주 좁은 너비에 점과 여러 아이콘을 함께 넣으면 글자가 한두 개씩 줄바꿈되어 읽기 어려울 수 있습니다. 실제 화면의 너비와 큰 글자 설정에서 확인하고, 긴 설명은 배지 밖의 본문에 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

종류를 고르는 값과 내용 · 동작은 위젯 파라미터로 넘기고, 색 · 크기 · 간격처럼 보이는 값과 안쪽 부품의 스타일은 `badgeStyle`(`CoreBadgeStyle`) 하나로 덮어씁니다.

<a id="시맨틱-vs-스타일"></a>

### 파라미터와 스타일

- **종류 · 내용 · 동작** — 위젯 파라미터로 직접 넘깁니다: `tone`, `variant`, `form`, `size`, `showDot`, `child`, `leading`, `trailing`, `onPressed`.
- **겉모습(색 · 크기 · 간격)과 안쪽 부품의 스타일** — `CoreBadgeStyle` 한 곳으로 넘깁니다: `backgroundColor` · `foregroundColor` · `borderColor` · `borderWidth` · `borderRadius` · `padding` · `minHeight` · `iconLabelGapStyle` · `transitionDuration` · `labelStyle` · `iconStyle` · `dotSize` · `leadingDotSize` · `leadingDotColor` · `focusOutlineStyle` · `stateLayer`.

<a id="resolve-chain"></a>

### 값이 정해지는 순서

<Preview demo="badge/theme-order" />

```text
defaultsBySize[size] → defaultsByForm[form] → defaultsByTone[tone] × variant   // 디자인 시스템 기본값
  → CoreBadgeTheme.style                    // 프로젝트 공통
  → CoreBadgeTheme.toneStyles[tone]
  → CoreBadgeTheme.variantStyles[variant]
  → badgeStyle                              // 인스턴스별
```

- 같은 필드를 테마의 두 표가 함께 덮으면 `variantStyles` 가 `toneStyles` 를 이깁니다.
- 다른 컴포넌트가 안에 그리는 Badge(NavigationBar 의 알림 점처럼)는 그 컴포넌트의 스타일 슬롯 값이 마지막 자리의 `badgeStyle` 로 들어옵니다.
- 안쪽 부품의 스타일(`labelStyle` · `iconStyle` · `iconLabelGapStyle` · `focusOutlineStyle`)은 그 부품 자신의 기본값과 같은 순서로 한 번 더 합쳐집니다. 크기 표의 글자 역할 위에 `count` 의 굵기(600)가 얹히므로, `labelStyle` 로 역할을 바꿔도 숫자의 굵기는 `count` 의 것이 남습니다.

### 사용 예

<Split>

<Code language="dart" title="배지 하나만 바꾸기">
Badge(
  tone: CoreBadgeTone.primary,
  leading: Icon(LucideIcons.star),
  badgeStyle: CoreBadgeStyle(
    padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
    iconStyle: CoreIconStyle(size: CoreIconSize.size16),
  ),
  child: Text('추천'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    badge: CoreBadgeTheme(
      toneStyles: {
        CoreBadgeTone.success: CoreBadgeStyle(
          foregroundColor: CoreColor.token(CoreColors.onSuccessContainer),
        ),
      },
      variantStyles: {
        CoreBadgeVariant.outlined: CoreBadgeStyle(
          borderWidth: CoreStrokeWidth.stroke2,
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다. 앱 전체 예제의 `toneStyles` 는 모든 `success` 배지를, `variantStyles` 는 모든 `outlined` 배지를 바꿉니다.

<a id="테두리-없는-마케팅-크롬"></a>

### 테두리 없는 마케팅용 모양

웹에서 배지의 모서리는 늘 인라인 스타일로 나가고, 테두리 굵기는 선 색이 정해질 때(기본적으로 `outlined` 이거나 `borderColor` 를 줄 때) 인라인 스타일로 나갑니다. 그래서 제품 CSS 로 이 값을 덮으려면 `!important` 가 필요합니다. 대신 `badgeStyle` 로 그 값을 직접 바꿉니다.

<Preview demo="badge/borderless" />

```dart
Badge(
  badgeStyle: const CoreBadgeStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
  ),
  child: const Text('베타'),
)
```

선 색이 없는 `filled` · `tonal` 에는 처음부터 테두리가 없어, 면과 모서리만 바꾸면 됩니다. `borderWidth` 는 선 색이 있을 때(`outlined` 이거나 `borderColor` 를 줄 때)만 뜻이 있습니다. 그런 배지에 `borderWidth: CoreStrokeWidth.stroke0` 을 주면 웹은 선을 그리지 않지만 Flutter 는 너비 0 의 선을 1 물리 픽셀 선(헤어라인)으로 그립니다 — 선이 없어야 하면 `outlined` 대신 `filled` · `tonal` 을 고릅니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Badge` 에 `withStyle` 을 이어 `badgeStyle` 을 덧붙일 수 있습니다. `badgeStyle: CoreBadgeStyle(...)` 생성자 인자와 같게 동작하고, 나중에 이은 `withStyle` 이 같은 필드에서 이깁니다. `.radius4` 처럼 Core 토큰 상수와 이름이 같은 getter 도 있습니다 — `withStyle` 을 한 번 더 줄인 것으로, 이름이 곧 값이라(`radius4` 는 `CoreRadius.radius4`) 어느 컴포넌트에서 써도 뜻이 같습니다. 배경색만 따로 지정하려면 `CoreBadgeStyle.backgroundColor`를 사용합니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class BadgeChainExample extends StatelessWidget {
  const BadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: const Text('주요'),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Badge(
          child: const Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
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
class BadgeChainExample extends StatelessComponent {
  const BadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Badge(
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
          child: Text('주요'),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Badge(
          child: Text('직접 지정'),
        ).withStyle(
          const CoreBadgeStyle(
            backgroundColor: .tertiaryContainer,
            foregroundColor: .onTertiaryContainer,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
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

<a id="토큰-기반-스타일링"></a>

### 기본값이 있는 곳

배지의 기본값은 전부 `coui_core` 의 `CoreBadgeStyle` 에 있고, Flutter와 Web이 같은 표를 읽습니다.

| 이름 | 값 | 설명 |
| --- | --- | --- |
| `CoreBadgeStyle.defaultsBySize[size]` | 크기마다 `minHeight` · 좌우 `padding` · `iconLabelGapStyle` · `label` 의 `borderRadius` · `labelStyle` 역할 · `iconStyle` · `dotSize` · `leadingDotSize` | 크기 섹션의 표 |
| `CoreBadgeStyle.defaultsByForm[form]` | `label` 은 그대로 · `count` 는 600 과 알약 · `dot` 은 알약 | 형태가 크기 행 위에 얹는 것 |
| `CoreBadgeStyle.defaultsByTone[tone]` | `CoreBadgeToneStyle` — 세 세기의 면 · 글자 · 선과 점 색 | Variant 섹션의 톤 × 세기 |
| `CoreBadgeStyle.defaultBorderRadius` | `CoreRadius.radius9999` | `count` · `dot` 의 알약 |
| `CoreBadgeStyle.defaultBorderWidth` | `CoreStrokeWidth.stroke1` (1px) | 선 색이 있을 때의 테두리 |
| `CoreBadgeStyle.defaultOutlinedBackgroundColor` | `surface` 0% | `outlined` 의 투명한 면 |
| `CoreBadgeStyle.defaultStateLayer` | `CoreStateLayer.standard` (8 / 8 / 16) | 누를 수 있는 배지의 hover · pressed 상태층 |
| `CoreBadgeStyle.defaultTransitionDuration` | `CoreDuration.fast` (150ms) | 색과 선이 바뀌는 시간 (모든 배지) |
| `CoreBadgeStyle.defaultFocusOutlineStyle` | `CoreFocusOutlineStyle` | 누를 수 있는 배지의 포커스 링 |

<a id="접근성-accessibility"></a>

## 접근성

표시 전용 배지는 글로만 읽힙니다. `onPressed` 를 주면 Flutter 는 `Semantics(button: true)` 로, 웹은 `role="button"` 으로 버튼임을 알립니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | `onPressed` 가 있을 때만 `Clickable` 이 `Semantics(button: true, enabled: …)` 를 붙입니다. 표시 전용 배지에는 따로 붙는 시맨틱이 없습니다. |
| Jaspr Web | `onPressed` 가 있으면 루트 `<span>` 에 `role="button"` 과 `tabindex="0"` 이 직접 붙습니다(`Clickable` 을 거치지 않습니다). 표시 전용 배지는 역할이 없는 `<span>` 입니다. |

### 키보드

| 키 | 동작 |
| --- | --- |
| `Tab` | 누를 수 있는 배지는 탭 순서의 한 자리입니다. 표시 전용 배지는 포커스를 받지 않습니다. |
| `Enter` · `Space` | `onPressed` 를 실행합니다. |

<Note>

웹 배지의 루트는 `<span>` 이라 브라우저가 키를 누름으로 바꿔 주지 않습니다. 그래서 배지가 직접 `keydown` 에서 `Enter` 와 `Space` 를 받아 `onPressed` 를 부르고(`Space` 의 페이지 스크롤은 막습니다), 키가 눌린 동안 pressed 상태층을 그립니다 — Flutter 의 `Clickable` 이 같은 키에 누름을 보여 주는 것과 같습니다. `eventHandlers` 로 건 `click` · 키 핸들러는 배지의 처리보다 먼저 돌고, 대체되지 않습니다.

</Note>

### 스크린 리더

이름은 `child` 로 넘긴 글에서 나옵니다 — 이름을 따로 받는 파라미터는 없습니다. 아이콘만 넣은 배지와 점(`dot`)은 이름이 비어, 누를 수 있다면 "버튼" 으로만 읽힙니다.

<Preview demo="badge/a11y-name" />

웹에서는 `attributes` 로 이름을 붙입니다. 누를 수 있는 배지는 `aria-label` 을 주고, 표시 전용 배지는 역할이 없는 `<span>` 이라 `role="img"` 와 `aria-label` 을 함께 줍니다. Flutter 는 `Semantics(label: ...)` 로 감쌉니다.

앞 점(`showDot`)은 장식입니다 — 옆의 레이블이 뜻을 담으므로 이름에 들어가지 않습니다(웹 `aria-hidden`). 상태를 색과 점으로만 말하지 말고 레이블 낱말이 그 상태를 말하게 합니다. `count` 가 좁은 자리에서 말줄임되어도 전체 숫자는 보조 기술에 남습니다. 상태가 바뀐 사실을 알리는 라이브 영역은 두 플랫폼 모두 없습니다.

### 포커스 관리

마운트될 때 포커스를 옮기지 않고, 포커스를 가두지도 않습니다. 포커스는 배지 밖으로 그대로 빠져나갑니다.

포커스 링은 키보드로 도달했을 때만 보입니다. Flutter 는 `Clickable` 의 포커스 하이라이트를, 웹은 `:focus-visible` 을 따르므로 마우스로 누른 배지에는 두 플랫폼 모두 링이 없습니다. 링은 배지 모양(둥근 사각 · 알약 · 원)을 따르고, 링과 배지 사이 2px 간격은 투명입니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Flutter | 아이콘 · 점 배지에 이름을 지정하는 슬롯이 없습니다. `Semantics(label: ...)` 로 감쌉니다. |
| Jaspr Web | 표시 전용 배지는 역할이 없는 `<span>` 이라 `aria-label` 만으로는 이름이 읽히지 않을 수 있습니다. `role="img"` 를 함께 줍니다. |
| 공통 | 누를 수 있는 배지는 그린 크기와 누르는 영역을 나눕니다. 점은 4px 까지 작아지므로 Flutter 는 `TouchTarget`, 웹은 `coui-touch-target` 표시로 누르는 영역만 넓힙니다. 표시 전용 배지에는 넓히지 않습니다. |

#### 색상 대비

톤 × 세기의 채움과 글자는 전부 시맨틱 색 쌍이고, 대비 검사(`check_contrast.dart`)가 `defaultsByTone` 을 직접 읽어 18짝(6 톤 × 3 세기)을 라이트 · 다크 · 고대비 네 모드에서 잽니다. 채움이 없는 `outlined` 의 글자는 배지가 놓이는 바탕(`surface` · `surfaceContainerLow` · `surfaceContainer` · `surfaceBright`) 위에서, 선과 점은 같은 바탕 위에서 비텍스트 기준(3:1)으로 잽니다. 검사는 CoUI 팔레트와 브랜드 표준 매핑(`CoreSemanticMappingSet.standard`) 둘 다에서 돕니다.

알려진 결손이 둘 있습니다.

- **표준 매핑의 라이트 `warning` 선 · 점.** 표준 매핑의 라이트 `warning` 은 밝은 채움이라, `outlined` 의 선과 점이 네 바탕 위에서 3:1 에 못 미칩니다(1.48–1.82:1). CoUI 팔레트의 `warning` 은 통과합니다(가장 낮은 값 4.30:1). 표준 매핑의 `warning` 을 어둡게 할지, 상태 표시용 선 · 점 색을 따로 둘지는 아직 정하지 않았습니다.
- **hover · pressed 상태층.** 상태층은 이 검사 밖입니다. 글자색을 면 위에 덮으므로 쉬는 상태보다 면과 글자 사이 대비가 낮아지고, 기본 상태층(`CoreStateLayer.standard`)에서는 라이트의 `filled` info · success · warning · destructive 와 다크의 `filled` neutral 이 hover · pressed 동안, 다크의 `tonal` neutral 이 pressed 동안 글자 대비 4.5:1 아래로 내려갑니다(가장 낮은 값은 pressed 에서 3.5:1 근처). 더 옅은 상태층이 필요하면 `stateLayer` 로 바꿉니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`tone` · `variant` · `form` · `size` · `showDot` · `child` · `leading` · `trailing` · `onPressed` · `badgeStyle` 은 두 플랫폼이 같은 API 입니다. 렌더링은 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` / `Widget?` | `Component` / `Component?` |
| 누르기 | 통합 `Clickable` 이 hover · 포커스 · 커서 · 키보드를 맡습니다. | `click` 이벤트 + `role="button"` |
| 키보드로 누르기 | `Clickable` 의 `Enter` · `Space` 단축키. 누를 때마다 pressed 상태층을 100ms 동안 보입니다. | 루트의 `keydown` 에서 `Enter` · `Space`. 키를 누르고 있는 동안 pressed 상태층을 그립니다. |
| hover · pressed 상태층 | 면 위에 섞은 색을 미리 계산해 두고 그중에서 고릅니다. | 범위 지정 `<style>` 규칙의 `:hover` · `:active` · 키 눌림 (`color-mix`). 반투명한 서페이스 스타일 아래에서도 섞은 색이 같은 투명도로 칠해집니다. |
| 아이콘 슬롯 | `IconTheme(size, color)` | `IconTheme(iconStyle)` — `Icon` 이 크기 · 색을 냅니다. |
| 겉모습을 내보내는 방식 | 바로 그릴 수 있는 `BoxDecoration` / `TextStyle` | Tailwind 클래스 + 인라인 CSS |
| 크기 배율 | 스타일을 계산할 때 `theme.scaling` 을 곱합니다. | `rem` 이 브라우저 글자 배율에 반응합니다. |
| 너비 0 의 선 | 선 색이 있는 배지에 `borderWidth: 0` 을 주면 1 물리 픽셀 선(헤어라인)을 그립니다. | 선을 그리지 않습니다. |
| HTML 속성 | 없음 — 이름은 `Semantics` 로 감쌉니다. | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<span>` 에 닿습니다. |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. 표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다.

### 종류

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `tone` | `CoreBadgeTone` | `neutral` | 색이 뜻하는 것 — neutral, primary, info, success, warning, destructive |
| `variant` | `CoreBadgeVariant` | `tonal` | 세기 — filled, tonal, outlined. `dot` 은 세기와 무관한 톤의 점 색 하나로 칠합니다. |
| `form` | `CoreBadgeForm` | `label` | 담는 것 — label(둥근 사각), count(알약), dot(원) |
| `size` | `CoreComponentSize` | `md` | 높이, 여백, 글자, 아이콘, 점 크기 — xs, sm, md, lg, xl, xl2 |
| `showDot` | `bool` | `false` | 글 앞에 상태 점을 그립니다. `label` · `count` 만 |

### 내용과 동작

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W?` | `null` | 레이블 — `label` 은 낱말, `count` 는 숫자. `dot` 은 그리지 않습니다. |
| `leading` | `W?` | `null` | 글 앞 아이콘. `dot` 은 그리지 않습니다. |
| `trailing` | `W?` | `null` | 글 뒤 아이콘. `dot` 은 그리지 않습니다. |
| `onPressed` | `VoidCallback?` (Flutter) · `CoreVoidCallback?` (Web) | `null` | 지정하면 누를 수 있는 배지가 됩니다. |
| `badgeStyle` | `CoreBadgeStyle?` | `null` | 보이는 값 덮어쓰기 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `attributes` | `Map<String, String>?` | `null` | 루트 `<span>` 의 HTML 속성 — `aria-label`, `role`, `data-*`, 테스트 id |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 이벤트. `click` · 키 핸들러는 배지의 누름 처리보다 먼저 돕니다. |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트의 id 와 배치용 클래스 · 스타일. 색 같은 겉모습은 `badgeStyle` 로 바꿉니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreBadgeStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Fill colour override. For [CoreBadgeForm.dot] this is the dot's colour. `null` defers to the tone row's colour for the variant ([CoreBadgeToneStyle.restingStyleFor]). |
| `foregroundColor` | `CoreColor?` | Foreground (label / icon / leading dot) colour override. `null` defers to the tone row's colour for the variant. |
| `borderColor` | `CoreColor?` | Border stroke colour. `null` defers to the tone row, which states one only for [CoreBadgeVariant.outlined]; with no colour no border is drawn. |
| `borderWidth` | `double?` | Border stroke width (logical px). `null` defers to [defaultBorderWidth]. |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` defers to the form's corner — the step's in [defaultsBySize] for a label, the pill in [defaultsByForm] for a number and a dot. |
| `padding` | `CoreEdgeInsets?` | Padding applied to the content row. `null` defers to `CoreBadgeStyle.defaultsBySize[size]!.padding!`. Horizontal only by default — the height is [minHeight]. |
| `minHeight` | `double?` | Height of the label and count forms (logical px); the content is centred in it. A count is never narrower than this, so a single digit stays a circle. `null` defers to `CoreBadgeStyle.defaultsBySize[size]!.minHeight!`. Unused by [CoreBadgeForm.dot], which is [dotSize] across. |
| `iconLabelGapStyle` | `CoreGapStyle?` | Gap between the badge's parts — leading dot, leading slot, label, trailing slot. `null` defers to `CoreBadgeStyle.defaultsBySize[size]!.iconLabelGapStyle!`. |
| `transitionDuration` | `Duration?` | How long changes to the badge's look (colours, border) animate. `null` defers to [defaultTransitionDuration]. |
| `labelStyle` | `CoreTextStyle?` | Label text style override. `null` defers to the step's role in [defaultsBySize] with the form's weight from [defaultsByForm] laid over it. |
| `iconStyle` | `CoreIconStyle?` | Leading / trailing icon style override (applied uniformly to both slots). `size` defers to `CoreBadgeStyle.defaultsBySize[size]!.iconStyle!.size!`. |
| `dotSize` | `double?` | Diameter of the dot in [CoreBadgeForm.dot] (logical px). `null` defers to `defaultsBySize[size]!.dotSize!`. Unused by the label and count forms, whose box is [minHeight] tall. |
| `leadingDotSize` | `double?` | Diameter of the status dot drawn before the content when the badge's `showDot` is on (logical px). `null` defers to `defaultsBySize[size]!.leadingDotSize!`. |
| `leadingDotColor` | `CoreColor?` | Colour of the status dot drawn before the content when `showDot` is on. `null` takes the badge's [foregroundColor], so the dot reads as part of the label; the `outlined` strength of a status tone states it (with the icon's colour) as the tone's line colour — see [CoreBadgeToneStyle.outlinedMarkColor]. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring style ([CoreFocusOutlineStyle]). `null` defers to [defaultFocusOutlineStyle]. Only used when the badge is interactive (`onPressed != null`). |
| `stateLayer` | `CoreStateLayer?` | Hover / pressed wash weights over the fill, in the label's colour. `null` defers to [defaultStateLayer]. Only consumed when the badge is interactive (`onPressed != null`); the focus rung is unused. |

### `CoreBadgeStyle` 톤별 기본값 (`CoreBadgeToneStyle`)

| 필드 | `neutral` | `primary` | `info` | `success` | `warning` | `destructive` |
|------|------|------|------|------|------|------|
| `filledBackgroundColor` | surfaceContainerHighest | primary | info | success | warning | error |
| `filledForegroundColor` | onSurfaceVariant | onPrimary | onInfo | onSuccess | onWarning | onError |
| `tonalBackgroundColor` | surfaceContainerHigh | primaryContainer | infoContainer | successContainer | warningContainer | errorContainer |
| `tonalForegroundColor` | onSurfaceVariant | onPrimaryContainer | onInfoContainer | onSuccessContainer | onWarningContainer | onErrorContainer |
| `outlinedBorderColor` | outline | primary | info | success | warning | error |
| `outlinedForegroundColor` | onSurface | primaryText | onInfoContainer | onSuccessContainer | onWarningContainer | onErrorContainer |
| `dotColor` | outline | primary | info | success | warning | error |
| `outlinedMarkColor` | — | — | info | success | warning | error |

<!-- STYLE_TABLE:END -->

<a id="이전-api-에서-옮기기-migration"></a>

## 이전 API 에서 옮기기

옛 `CoreBadgeVariant` 값 넷(`primary` · `secondary` · `outline` · `destructive`)은 색과 세기를 한 축에 섞었습니다. 지금은 둘이 `tone` 과 `variant` 로 나뉘어 있고, 옛 값은 남아 있지 않습니다. 옛 모양(알약)을 그대로 두려면 아래처럼 옮깁니다.

| 옛 | 새 |
| --- | --- |
| `variant: CoreBadgeVariant.primary` | `tone: CoreBadgeTone.primary, variant: CoreBadgeVariant.filled, form: CoreBadgeForm.count` |
| `variant: CoreBadgeVariant.secondary` | `tone: CoreBadgeTone.neutral, variant: CoreBadgeVariant.filled, form: CoreBadgeForm.count` |
| `variant: CoreBadgeVariant.outline` | `tone: CoreBadgeTone.neutral, variant: CoreBadgeVariant.outlined, form: CoreBadgeForm.count` |
| `variant: CoreBadgeVariant.destructive` | `tone: CoreBadgeTone.destructive, variant: CoreBadgeVariant.filled, form: CoreBadgeForm.count` |
| 인자 없는 `Badge(child: …)` | 지금은 `neutral` · `tonal` · `label` · `md` 로 그립니다 (옛 기본은 primary 채운 알약 · `sm`) |

- 낱말을 담은 배지라면 `form` 을 생략해 `label`(둥근 사각)로 두는 것이 지금의 기본 의도입니다. 위 표의 `form: count` 는 옛 알약 모양을 그대로 두는 길입니다.
- `primary` · `outline` · `destructive` 는 옛 색을 그대로 읽습니다. `secondary` 만 색이 바뀝니다 — 옛 값은 `secondary` · `onSecondary` 색(CoUI 팔레트에서 라이트는 짙은 회색 면에 흰 글자, 다크는 밝은 회색 면에 검은 글자)을 칠했고, `neutral` 의 `filled` 는 표면 단계(`surfaceContainerHighest`)에 `onSurfaceVariant` 글자를 칠합니다. CoUI 팔레트에서는 두 모드 모두 면의 명암이 뒤집힙니다.
- 기본 크기는 `md`, 기본 형태는 `label` 입니다(옛 기본은 `sm` · `count`).
- `CoreBadgeVariantStyle` 과 `CoreBadgeStyle.defaultsByVariant` 는 없습니다. 색은 `CoreBadgeStyle.defaultsByTone`(`CoreBadgeToneStyle`)에 있습니다.
- `CoreBadgeTheme.variantStyles` 는 새 `CoreBadgeVariant` 로 키를 잡고, 톤별 덮어쓰기는 `CoreBadgeTheme.toneStyles` 로 합니다.
- 누를 수 있는 배지의 hover 는 채움을 80% 로 옅게 하던 방식 대신 글자색 상태층(`stateLayer`)을 덮습니다.

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="badge/related-chip" title="Chip">

선택하거나 제거할 수 있는 태그입니다. 누를 수 없는 분류 표시는 Badge 를 씁니다.

</Card>
<Card demo="badge/related-avatar" title="Avatar">

사용자 프로필 이미지입니다. `badge` 슬롯에 배지를 넣어 상태를 표시합니다.

</Card>
<Card demo="badge/related-indicator" title="Indicator">

다른 요소의 모서리에 배지를 얹습니다.

</Card>
<Card demo="badge/related-icon" title="Icon">

배지의 `leading` · `trailing` 에 넣는 아이콘입니다.

</Card>
</Cards>
