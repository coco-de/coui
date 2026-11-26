---
title: BottomActionBar
description: 하단 행동 바 — 화면 아래에 붙는 주 행동과 보조 행동, 그 위의 짧은 안내
category: layout
platforms: [flutter, web]
related: [scaffold, button, dock, app-bar, page-header]
tags: [layout, action, bottom, footer]
---

# BottomActionBar

`BottomActionBar` 는 화면 아래에 붙는 행동 영역입니다. 등록 · 결제 · 확인처럼 흐름을 끝내는
`Button` 하나 또는 둘과, 그 위의 짧은 안내 한 줄을 채워진 면 위에 놓습니다. 바가 맡는 것은
배치 · 여백 · 위쪽 헤어라인 · 면이고, 버튼은 호출자의 `Button` 그대로 자기 크기와 모양을 가집니다.
바는 각 행동에 자기 칸의 전체 폭을 주므로 `Button` 에 `expanded` 를 따로 줄 필요가 없습니다.

## Live Preview

<LivePreview component="bottom-action-bar" variants="default,horizontal,summary-compact,scaffold" />

## 구조 (Anatomy)

위에서 아래로 헤어라인, 안내, 행동 순서이고, 바의 면은 기기의 아래 안전 영역 밑까지 칠해집니다.

```text
 ----------------------------------------------   hairline
 |  note                                      |   description
 |  [             primary action            ] |   primaryAction
 |  [            secondary action           ] |   secondaryAction
 |  ░░░░░░░ bottom safe area (home bar) ░░░░░ |
 ----------------------------------------------
```

| 부분 | 역할 | 슬롯 |
|------|------|------|
| 헤어라인 | 바 위쪽 가장자리의 한 줄 — 본문과 바를 가릅니다. `showDivider: false` 면 그리지 않습니다 | |
| 안내 | 행동 위의 짧은 한 줄 — 동의 문구나 수수료 안내 | `description` |
| 주 행동 | 흐름을 끝내는 `Button`. 세로에서는 맨 위, 가로에서는 맨 끝에 놓입니다 | `primaryAction` |
| 보조 행동 | 주 행동의 조용한 대안 — 관례로 `ghost` `Button`. 세로에서는 주 행동 아래, 가로에서는 맨 앞에 놓입니다 | `secondaryAction` |
| 안전 영역 | 기기 아래 가장자리(홈 인디케이터)의 몫. 바의 면이 그 밑까지 칠해지고 행동은 그 위에 놓입니다 | |

Figma: [`❖ BottomActionBar`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0)

### Figma 속성 대응

Figma 세트의 축과 속성이 코드의 어느 값인지입니다. 이름이 다른 곳은 그대로 적어 둡니다 — Figma
쪽 이름은 디자이너가 정한 이름이라 코드가 바꾸지 않습니다.

| Figma | 코드 | 비고 |
|-------|------|------|
| `Layout` (`vertical` · `horizontal` · `weighted` · `icon` · `summary` · `summaryCompact`) | `layout` | 세로는 한 열, 가로는 같은 폭의 칸 한 줄, `weighted` · `icon` 은 보조 행동이 제 폭이고 주 행동이 나머지, `summary` 는 요약이 제 폭이고 주 행동이 나머지, `summaryCompact` 는 요약이 나머지이고 주 행동이 제 폭으로 끝에 놓임 |
| `Show secondary` | `secondaryAction != null` | 끄면 보조 행동 칸이 없습니다 |
| `Show description` | `description != null` | 끄면 안내 줄이 없습니다 |
| `Show divider` | `showDivider` | |
| `Primary action` (인스턴스 교체) | `primaryAction` | 안의 `Button` 은 호출자의 것 — 바는 버튼의 크기를 정하지 않습니다 |
| `Secondary action` (인스턴스 교체) | `secondaryAction` | 가로 · `weighted` 배치의 보조 버튼(`secondary` `xl`)이 기본값입니다. 세로의 `ghost` `lg` 와 `icon` 의 정사각 버튼은 인스턴스에서 직접 바꿉니다 — 한 속성의 기본값은 하나뿐입니다 |
| `Description` (텍스트) | `description` | 코드는 텍스트가 아니라 위젯을 받습니다 |
| `Summary label` · `Summary value` (텍스트) | `summaryLabel` · `summaryValue` | `summary` · `summaryCompact` 배치에서만 그립니다. 코드는 위젯을 받습니다 |

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- 등록 · 결제 · 확인처럼 한 흐름을 끝내는 행동을 화면 아래에 붙여 둘 때
- 행동 위에 동의 문구나 수수료 안내 같은 짧은 한 줄을 함께 둘 때
- 휴대폰 화면의 아래 안전 영역(홈 인디케이터) 위에 행동을 놓아야 할 때

**대신 다른 컴포넌트를 사용하세요:**
- **[Dock](/components/dock)**: 화면 사이를 오가는 아래 내비게이션 — 행동이 아니라 목적지를 놓습니다
- **[AppBar](/components/app-bar)**: 화면 위의 바 — 제목과 뒤로 가기 같은 탐색을 놓습니다
- **[PageHeader](/components/page-header)**: 페이지 본문 맨 위의 제목과 그 페이지의 행동

## 기본 사용법 (Basic Usage)

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
BottomActionBar(
  description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
  primaryAction: Button(
    variant: .primary,
    size: .xl,
    onPressed: register,
    child: const Text('등록하기'),
  ),
  secondaryAction: Button(
    variant: .ghost,
    size: .lg,
    onPressed: later,
    child: const Text('나중에 하기'),
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
BottomActionBar(
  description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
  primaryAction: Button(
    variant: .primary,
    size: .xl,
    onPressed: register,
    child: const Text('등록하기'),
  ),
  secondaryAction: Button(
    variant: .ghost,
    size: .lg,
    onPressed: later,
    child: const Text('나중에 하기'),
  ),
)
```

  </TabItem>
</Tabs>

`description` 에 넘긴 `Text` 는 바가 정한 글자 스타일 · 정렬로 그려집니다 — `bodySmall` · `onSurfaceVariant` ·
가운데 정렬이고, 따로 적지 않습니다. 행동은 호출자가 넘기는 위젯 슬롯이라 바가 `Button` 의 크기를 정하지
않습니다. 폭은 부모가 정합니다 — 바는 받은 폭을 채우고, 높이는 내용이 정합니다.

### Scaffold 의 푸터로

화면 구조 안에서는 `Scaffold` 의 `footers` 에 넘깁니다. 위 미리보기의 `scaffold` 변형이 이 모양입니다.

```dart
Scaffold(
  headers: [AppBar(title: const Text('새 항목 등록').titleMedium)],
  footers: [
    BottomActionBar(
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: register,
        child: const Text('등록하기'),
      ),
    ),
  ],
  child: body,
)
```

`Scaffold` 는 푸터에 아래 안전 영역을 따로 더하지 않으므로, 안전 영역은 바가 한 번만 더합니다.

## Props / Parameters

`W` 는 Flutter의 Widget / Web의 Jaspr Component입니다.

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `primaryAction` | `W` | 필수 | 흐름을 끝내는 행동 — 보통 `Button`. 세로에서는 맨 위, 가로에서는 맨 끝에 놓입니다 |
| `secondaryAction` | `W?` | `null` | 주 행동의 조용한 대안 — 관례로 `ghost` `Button`. 없으면 그 칸을 그리지 않고, 가로에서는 주 행동이 줄 전체를 채웁니다 |
| `description` | `W?` | `null` | 행동 위의 짧은 안내. 없으면 그 줄을 그리지 않습니다 |
| `summaryLabel` | `W?` | `null` | 요약의 이름(총 금액). `summary` · `summaryCompact` 배치에서만 그리며 요약 값 위에 놓입니다 |
| `summaryValue` | `W?` | `null` | 요약의 값(합계). `summary` · `summaryCompact` 배치에서만 그리며 요약 이름 아래에 놓입니다 |
| `layout` | `CoreBottomActionBarLayout` | `CoreBottomActionBarLayout.defaultLayout`(`vertical`) | 행동의 배치 — `vertical` 은 한 열, `horizontal` 은 같은 폭의 칸 한 줄, `weighted` · `icon` 은 보조 행동이 제 폭이고 주 행동이 나머지(`icon` 은 정사각 보조 버튼용), `summary` 는 요약(`summaryLabel` 위 · `summaryValue` 아래)이 제 폭이고 주 행동이 나머지이며 보조 행동은 그리지 않습니다, `summaryCompact` 는 요약이 나머지이고 주 행동이 제 폭으로 끝에 놓입니다(보조 행동은 그리지 않음) |
| `showDivider` | `bool` | `CoreBottomActionBarContract.defaultShowDivider`(`true`) | 바 위쪽의 헤어라인을 그릴지 |
| `bottomActionBarStyle` | `CoreBottomActionBarStyle?` | `null` | 겉모습을 바꾸는 값 묶음 (아래 표 참고) |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreBottomActionBarStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Surface fill colour. `null` → [defaultBackgroundColor]. |
| `padding` | `CoreEdgeInsets?` | Inset around the actions (pre-scaling), before the bottom safe area is added to its bottom edge. `null` → [defaultPadding]. |
| `spacing` | `double?` | Space between the note and the actions, and between the actions (logical px, pre-scaling). `null` → [defaultSpacing]. |
| `dividerColor` | `CoreColor?` | Colour of the hairline above the bar. `null` → [defaultDividerColor]. |
| `dividerWidth` | `double?` | Thickness of the hairline above the bar (logical px, pre-scaling). `null` → [defaultDividerWidth]. |
| `descriptionTextStyle` | `CoreTextStyle?` | Text style the note slot inherits, merged on top of [defaultDescriptionTextStyle]. |
| `descriptionTextAlign` | `CoreTextAlign?` | Horizontal alignment of the note's text. `null` → [defaultDescriptionTextAlign]. |
| `summaryLabelTextStyle` | `CoreTextStyle?` | Text style the summary's caption inherits, merged on top of [defaultSummaryLabelTextStyle]. |
| `summaryValueTextStyle` | `CoreTextStyle?` | Text style the summary's figure inherits, merged on top of [defaultSummaryValueTextStyle]. |

<!-- STYLE_TABLE:END -->

## 스타일 시스템 (Style System)

### `bottomActionBarStyle`

- **종류 · 내용 · 동작**: 위젯 파라미터로 직접 (`layout` · `showDivider`)
- **겉모습 (색 · 크기 · 간격)**: `CoreBottomActionBarStyle` 한 곳으로 (면 · 여백 · 간격 · 헤어라인 · 안내의 글자)

| 부분 | 필드 | 기본값 |
|------|------|--------|
| 면 | `backgroundColor` | `surface` |
| 여백 | `padding` | 좌우 20 · 위아래 12 — 아래 12 위에 기기의 아래 안전 영역이 더해집니다 |
| 간격 | `spacing` | 8 — 안내와 행동 사이, 행동 사이 |
| 헤어라인 | `dividerColor` · `dividerWidth` | `outlineVariant`(없으면 `outline`) · 1 |
| 안내 | `descriptionTextStyle` · `descriptionTextAlign` | `bodySmall` · `onSurfaceVariant` · 가운데 |
| 요약 | `summaryLabelTextStyle` · `summaryValueTextStyle` | 이름 `bodySmall` · `onSurfaceVariant`, 값 `titleMedium` · `onSurface` |

여백과 간격은 간격 사다리 위의 값이라 밀도(`CoreDensity`)가 한 칸 옮깁니다. 안전 영역은 필드가 아닙니다 — 기기가
정하는 값이라 토큰이 될 수 없고, 호스트가 알려 주는 대로 아래 여백에 더해집니다.

<a id="resolve-chain"></a>

#### 값이 정해지는 순서

```text
CoreBottomActionBarStyle.defaultX            // 기본값
  → CoreBottomActionBarTheme.style           // 프로젝트 공통
  → widget.bottomActionBarStyle              // 인스턴스별
```

#### 사용 예

```dart
CoreComponentTheme(
  bottomActionBar: CoreBottomActionBarTheme(
    style: CoreBottomActionBarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  ),
)
```

#### 빠른 오버라이드 (Chain)

이미 만든 `BottomActionBar` 인스턴스에 스타일을 빠르게 덧붙이고 싶다면 `withStyle`
체인을 쓸 수 있습니다. 생성자의 style 슬롯 인자와 동일하게 동작하지만,
이미 구성된 위젯 위에서 바로 이어 쓸 수 있습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class BottomActionBarChainExample extends StatelessWidget {
  const BottomActionBarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
    ).withStyle(
      const CoreBottomActionBarStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        descriptionTextAlign: .start,
        spacing: CoreSpace.space12,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class BottomActionBarChainExample extends StatelessComponent {
  const BottomActionBarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return BottomActionBar(
      description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
      primaryAction: Button(
        variant: .primary,
        size: .xl,
        onPressed: () {},
        child: const Text('등록하기'),
      ),
    ).withStyle(
      const CoreBottomActionBarStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        descriptionTextAlign: .start,
        spacing: CoreSpace.space12,
      ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

## 변형 (Variants)

### `layout: vertical`

기본입니다. 한 열 — 위에서 아래로 안내(있으면), 주 행동, 보조 행동(있으면). 각 행동이 좌우 `padding` 을 뺀
바의 폭을 모두 차지합니다.

```dart
BottomActionBar(
  description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
  primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
  secondaryAction: Button(variant: .ghost, size: .lg, onPressed: later, child: const Text('나중에 하기')),
)
```

### `layout: horizontal`

안내(있으면) 아래에 같은 폭의 칸 한 줄 — 보조 행동이 앞, 주 행동이 끝입니다. 보조 행동이 없으면 주 행동이
줄 전체를 채웁니다.

```dart
BottomActionBar(
  layout: .horizontal,
  primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
  secondaryAction: Button(variant: .ghost, size: .xl, onPressed: later, child: const Text('나중에 하기')),
)
```

### `layout: summaryCompact`

요약(총 금액)이 앞에서 나머지 폭을 받고, 주 행동은 제 라벨 폭으로 줄 끝에 놓입니다. 주 행동이 남은 폭을 다 채우면
바 대부분이 버튼이 되어 무겁게 보일 때 씁니다. 주 행동의 폭은 라벨이 정하므로 버튼 크기는 호출하는 쪽이 고릅니다.
요약이 없어도 주 행동은 끝에 놓입니다. 보조 행동은 그리지 않습니다.

```dart
BottomActionBar(
  layout: .summaryCompact,
  summaryLabel: const Text('총 금액'),
  summaryValue: const Text('64,000원'),
  primaryAction: Button(size: .lg, onPressed: pay, child: const Text('결제하기')),
)
```

## 동작 스펙 (Behavior)

### 배치

- **세로**: 안내(있으면), 주 행동, 보조 행동(있으면)이 한 열로 쌓이고, 사이는 `spacing` 입니다. 행동은 좌우 `padding` 을 뺀
  바의 폭 전체를 받습니다
- **가로**: 안내(있으면) 아래 같은 폭의 칸 한 줄입니다. 보조 행동이 앞, 주 행동이 끝이고, 칸 사이는 `spacing`
  입니다. 두 행동의 높이가 달라도 세로 가운데 선에 맞춥니다 — 두 플랫폼 모두 명시한 값입니다
- **헤어라인**: 바 위쪽 가장자리에 한 줄이고, `showDivider` 가 켜져 있을 때만 그립니다. 테두리로 그려서 굵기만큼
  높이를 차지합니다 — 켜고 끌 때 바의 높이가 그 굵기만큼 바뀝니다
- **여백과 안전 영역**: 아래 여백은 `padding` 의 아래 값에 기기의 아래 안전 영역을 더한 값입니다. 바의 면은
  안전 영역 밑까지 칠해지고, 행동은 그 위에 놓입니다. 안전 영역이 없는 곳(데스크톱 등)에서는 더해지는 것이
  없습니다. 위 · 좌 · 우 안전 영역은 바가 반영하지 않습니다 — 좌우 여백은 `padding` 의 몫입니다
- **폭과 높이**: 받은 폭을 채우고, 높이는 내용(안내 · 행동 · 여백 · 헤어라인 · 안전 영역)이 정합니다

### 재질

활성 테마의 서피스 스타일이 재질(반투명한 채움 · 뒤를 흐리는 블러)을 가지면 바의 채움이 그 재질을 입습니다.
바는 기능 표면(`functional`)이고, 본문이 바 밑으로 지나가는 도킹된 바로 선언되어 있습니다. 채움이 투명한 바는
재질을 받지 않으므로 헤어라인도 자기 색을 그대로 둡니다. 재질이 자기 가장자리를 그리는 스타일에서는
헤어라인의 색이 투명이 되고 자리(굵기)는 그대로 남습니다. 재질이 없는 기본 상태에서는 불투명한 채움 하나와
헤어라인뿐입니다. Flutter 에서는 `SurfaceBlur` 래퍼가 더해지지 않고, Web 의 표면 표시 클래스
(`coui-surface` · `coui-surface-functional`)는 루트에 붙어 있어도 재질 규칙이 없으면 아무것도 그리지 않습니다.

`Scaffold` 는 `footers` 의 각 항목을 `footerBackgroundColor`(기본 `surface`)로 채운 구획에 담습니다. 바 밑이
그 평평한 채움이면 재질이 비출 것이 구획의 색뿐이므로, 본문이 바 밑으로 지나가게 하려면 `floatingFooter: true` 와
함께 `scaffoldStyle: CoreScaffoldStyle(footerBackgroundColor: CoreColor.transparent)` 를 줍니다. 기본 렌더에서는
구획의 채움과 바의 채움이 같은 `surface` 라 눈에 띄는 차이가 없습니다.

### 인터랙션

- 바 자체는 입력을 받지 않습니다 — 행동의 동작은 각 행동(`Button`)이 가집니다
- 탭 순서는 화면에 놓인 순서입니다 — 세로는 주 행동 다음 보조 행동, 가로는 보조 행동 다음 주 행동

### 상태 전환

- 상태가 없습니다. 같은 슬롯 · 같은 `layout` · 같은 폭이면 같은 배치입니다
- `secondaryAction` · `description` 이 `null` 과 값 사이를 오가면 그 칸이 생기거나 사라집니다

### 애니메이션

- 없습니다. 칸이 생기거나 사라질 때도 즉시 바뀝니다

## 사용 가이드라인 (Usage Guidelines)

### Do

<Callout type="tip">

**주 행동은 크게, 보조 행동은 `ghost` 로**

```dart
BottomActionBar(
  primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
  secondaryAction: Button(variant: .ghost, size: .lg, onPressed: later, child: const Text('나중에 하기')),
)
```

이유: 두 행동이 같은 무게로 읽히지 않아 어느 쪽이 흐름을 끝내는지 한눈에 보입니다. 크기는 `Button` 의 사다리
단(56 · 48)을 그대로 씁니다.

</Callout>

### Don't

<Callout type="warning">

**안내를 문단으로 쓰지 않는다**

```dart
// ❌ 바가 화면 아래를 길게 차지하고, 행동이 본문 위로 올라온다
BottomActionBar(
  description: const Text('계속하면 이용약관과 개인정보 처리방침, 운영 정책에 모두 동의한 것으로 보며 …'),
  primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
)

// ✅ 한 줄 안내 — 긴 설명은 본문에
BottomActionBar(
  description: const Text('계속하면 이용약관에 동의한 것으로 봐요'),
  primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
)
```

이유: 바는 화면 아래에 계속 붙어 있어서, 안내가 길어질수록 본문이 쓸 수 있는 높이가 줄어듭니다.

</Callout>

## 접근성 (Accessibility)

### 역할

- **Flutter**: `CoUISemantics(role: .group, container: true)` 로 바 전체를 하나의 그룹으로 묶습니다
- **Web**: 루트 `<div>` 에 `role="group"` 을 내보냅니다. `<footer>` 나 `<section>` 이 아니라 `div` 입니다 — 랜드마크가
  아니라 컨트롤을 묶는 영역이기 때문입니다

그룹에는 접근 가능한 이름이 없습니다. 안내 문구와 버튼 이름이 곧 내용입니다.

### 키보드

| 키 | Flutter | Web |
|----|---------|-----|
| `Tab` | 행동 사이를 화면 순서로 이동 | 행동 사이를 화면 순서로 이동 |
| `Enter` / `Space` | 포커스를 가진 `Button` 이 처리 | 포커스를 가진 `Button` 이 처리 |

바 자체는 포커스를 받지 않습니다.

### 스크린 리더

그룹 안에서 안내, 행동 순서로 읽힙니다 — 세로는 안내 → 주 행동 → 보조 행동, 가로는 안내 → 보조 행동 → 주 행동.
상태 통보(live region)는 없습니다.

### 포커스 관리

- **진입 · 이탈 · 트랩**: 없음 — 바는 오버레이가 아닙니다

### 알려진 제약

- 그룹에 이름이 없습니다. 이름이 필요하면 호출자가 붙입니다 — Web 은 `attributes: {'aria-label': '…'}`, Flutter 는
  바를 `Semantics(label:)` 로 감쌉니다
- 헤어라인은 Web 에서 `border-top` 이라, 색 강제 모드에서도 시스템 색의 선으로 남습니다

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은
> [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 클래스명 | `BottomActionBar` | `BottomActionBar` |
| 루트 | `Container`(채움 + 위쪽 테두리) → `SafeArea` → `Padding` → `Column` | `<div role="group">`(채움 + 위쪽 테두리 + 안쪽 여백) |
| 안전 영역 | `SafeArea(top·left·right: false)` 가 채움 상자 안쪽에서 아래 여백을 더합니다 | `padding-bottom: calc(<padding 아래 값> + env(safe-area-inset-bottom))` — 페이지가 `viewport-fit=cover` 를 선언해야 `env()` 가 0 이 아닙니다 |
| 헤어라인 | 상자의 위쪽 테두리 — 굵기만큼 높이를 차지합니다 | `border-top` — 굵기만큼 높이를 차지합니다 |
| 가로 배치 | `Row` 의 `Expanded` 칸, 세로 가운데 맞춤 | flex 행의 같은 폭 칸(`flex: 1`, 최소 폭 0), `align-items: center` |
| 안내의 글자 | 기본 글자 스타일(`DefaultTextStyle`)에 스타일 · 정렬을 설치합니다 | 안내를 감싸는 `<div>` 에 글자 역할 클래스와 `text-align` 을 줍니다 |
| 재질 | 재질이 있을 때만 `SurfaceBlur` 로 감쌉니다 | 표면 표시 클래스와 채움 변수를 루트에 붙입니다 |
| Web 전용 HTML 표면 | — | `attributes` · `classes` · `css` · `eventHandlers` · `id` 통과 |

안전 영역이 실제로 더해진 모습은 이 문서의 미리보기에서 볼 수 없습니다. 이 사이트는 `viewport-fit=cover` 를
선언하지 않아 Web 의 `env(safe-area-inset-bottom)` 이 0 이고, Flutter 미리보기도 기기 프레임이 없어
`MediaQuery.padding` 이 0 입니다. 실제 기기에서 확인합니다.

위 차이 밖에는 없습니다 — 이름 · 순서 · 기본값을 두 위젯 생성자에서 대조했습니다.

## 관련 컴포넌트 (Related Components)

- **[Scaffold](/components/scaffold)**: 바가 놓이는 화면 구조 — `footers` 에 넘깁니다
- **[Button](/components/button)**: `primaryAction` · `secondaryAction` 에 놓는 행동
- **[Dock](/components/dock)**: 화면 아래의 내비게이션 바
- **[AppBar](/components/app-bar)**: 화면 위의 고정 바
- **[PageHeader](/components/page-header)**: 페이지 맨 위의 제목과 행동

### 조합 예제

```dart
Scaffold(
  headers: [AppBar(title: const Text('새 항목 등록').titleMedium)],
  footers: [
    BottomActionBar(
      layout: .horizontal,
      primaryAction: Button(size: .xl, onPressed: register, child: const Text('등록하기')),
      secondaryAction: Button(variant: .ghost, size: .xl, onPressed: later, child: const Text('나중에 하기')),
    ),
  ],
  child: Column(
    crossAxisAlignment: .stretch,
    spacing: CoreSpace.space24,
    children: [
      PageHeader(title: const Text('새 항목 등록')),
      Card(body: const Text('입력한 내용을 확인해 주세요')),
    ],
  ),
)
```
