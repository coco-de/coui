---
title: EmptyState
description: 보여 줄 데이터가 없는 자리에 그 이유와 다음 행동을 알려 주는 컴포넌트입니다. 자리에 맞는 밀도(variant)와 비어 있는 이유(tone)를 따로 고릅니다.
category: display
platforms: [flutter, web]
related: [alert, skeleton, loading, banner]
tags: [feedback, empty, placeholder]
template: v2
source: display/empty_state
---

# EmptyState

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

목록이나 콘텐츠 영역이 비었을 때 그 자리에 아이콘 · 제목 · 설명 · 행동을 세로로 쌓아 가운데에 보여 줍니다. 필수는 `title` 하나입니다. 속성을 바꿔 보고 만들어진 코드를 복사하세요.

`tone` 은 아이콘이나 글을 골라 주지 않습니다. 플레이그라운드는 톤에 맞는 예시 아이콘과 글을 함께 바꿔 보여 줍니다. 코드의 `resetFilters` · `retry` · `showHistory` 는 앱의 함수가 들어갈 자리입니다.

<Playground component="empty-state" />

## 구조

EmptyState 는 자기 상자를 그리지 않습니다. 테두리 · 모서리 · 배경 없이, 놓인 면 위에 내용만 가운데에 쌓습니다.

<Anatomy demo="empty-state/anatomy">
<AnatomyItem part="container" name="Container">

내용을 세로로 가운데 맞추는 바깥 영역입니다. 안쪽 여백과 최소 높이는 `variant` 가 정합니다.

</AnatomyItem>
<AnatomyItem select="div:first-child" side="left" name="icon box">

아이콘이 가운데에 놓이는 원입니다. 크기는 `variant`, 채우는 색은 `tone` 이 정합니다. 아이콘을 그릴 때만 생깁니다.

</AnatomyItem>
<AnatomyItem part="leading" side="right" name="icon">

`icon` 에 넘긴 위젯입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem part="label" side="left" name="title">

비어 있다는 사실을 알리는 제목입니다. 필수입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=description]" side="right" name="description">

제목 아래 보조 설명입니다. 선택 사항입니다.

</AnatomyItem>
<AnatomyItem select="button" side="right" name="action">

빈 상태를 푸는 행동입니다. 보통 Button 을 넣습니다. 선택 사항입니다.

</AnatomyItem>
</Anatomy>

- `icon` 을 주지 않거나 `showIcon: false` 이면 아이콘 상자와 그 아래 간격이 함께 빠집니다.
- `description` 을 주지 않거나 `showDescription: false` 이면 설명과 그 위 간격이 함께 빠집니다.
- 실제로 그리는 조건은 `showIcon && icon != null`, `showDescription && description != null` 입니다. 아이콘이나 설명 위젯을 늘 만드는 코드라면 구조를 바꾸지 않고 두 값만 끄면 됩니다.
- `action` 은 `null` 이 아니면 그립니다. 설명이 없으면 제목 아래에 놓입니다.

<Code language="dart" title="가장 많이 쓰는 모양">
EmptyState(
  icon: Icon(LucideIcons.inbox),
  title: Text('받은 메시지가 없어요'),
  description: Text('새 메시지가 도착하면 여기에 표시됩니다.'),
)
</Code>

두 플랫폼이 함께 갖는 속성은 이름이 같고, Web 에는 루트의 HTML 속성을 넘기는 파라미터가 더 있습니다. Flutter 에서는 안의 값이 모두 상수면 `const` 를 붙일 수 있고, Web 의 `EmptyState` 에는 `const` 생성자가 없습니다.

## Variant

두 축을 따로 고릅니다. 두 축은 서로 독립입니다.

| 축 | 값 (굵게 = 기본) | 답하는 질문 |
| --- | --- | --- |
| `variant` | **`normal`** · `compact` · `large` | 얼마나 넓은 자리인가 |
| `tone` | **`neutral`** · `failure` · `success` | 왜 비어 있는가 |

### 밀도

`normal` 은 페이지의 본문처럼 빈 상태가 그 화면의 주인공일 때 씁니다. 최소 높이 240 을 둬서 결과가 사라져도 영역이 주저앉지 않습니다.

<Preview component="empty-state" props="variant=normal;icon=true;description=true;action=true" />

`compact` 는 사이드바 · 패널 · 목록 미리보기처럼 좁은 자리에 씁니다. 최소 높이를 두지 않아, 높이의 한계가 없는 자리에서는 내용과 안쪽 여백만큼만 차지합니다.

<Preview component="empty-state" props="variant=compact;icon=true;description=true;action=true" />

`large` 는 넓은 첫 화면처럼 여유 있는 자리에 씁니다. 아이콘 상자 · 글 · 여백이 더 큽니다.

<Preview component="empty-state" example="large" />

아래는 값을 덮어쓰지 않고, 앱의 밀도와 크기 배율이 기본일 때의 값입니다(논리 픽셀).

| 값 | `normal` | `compact` | `large` |
| --- | --- | --- | --- |
| 안쪽 여백 | 네 방향 32 | 네 방향 24 | 좌우 32 · 위아래 40 |
| 최소 높이 (여백 포함) | 240 | 없음 | 240 |
| 아이콘 상자 지름 | 64 | 48 | 72 |
| 아이콘 크기 | 28 | 20 | 32 |
| 아이콘 → 제목 간격 | 16 | 12 | 20 |
| 제목 → 설명 간격 | 8 | 6 | 8 |
| 설명 → 행동 간격 | 24 | 16 | 24 |
| 제목 글자 | `titleMedium` | `titleSmall` | `titleLarge` |
| 설명 글자 | `bodyMedium` | `bodySmall` | `bodyLarge` |

제목은 `onSurface`, 설명은 `onSurfaceVariant` 색이며 둘 다 가운데 정렬합니다. 제목과 설명 묶음의 최대 폭은 세 밀도 모두 400 입니다.

<Note>

아이콘 크기는 지금 Flutter 에서만 아이콘에 적용됩니다. Web 은 아이콘이 놓이는 칸만 표의 크기로 잡고, 안에 넣은 CoUI `Icon` 의 크기는 바꾸지 않습니다. 그래서 `CoUIWeb` 앱에서 `Icon` 에 크기를 주지 않으면 세 밀도 모두 20 으로 그립니다. 두 플랫폼에서 크기를 맞추려면 아래처럼 `Icon` 에 직접 크기를 줍니다.

</Note>

<Code language="dart" title="아이콘에 직접 크기 주기">
EmptyState(
  icon: Icon(
    LucideIcons.inbox,
    iconStyle: CoreIconStyle(size: CoreIconSize.size28),
  ),
  title: Text('받은 메시지가 없어요'),
)
</Code>

`EmptyState.compact(...)` 는 `variant: CoreEmptyStateVariant.compact` 를 줄여 쓰는 생성자이며 두 플랫폼에 있습니다.

<a id="tone-밀도와-직교하는-축"></a>

### 톤

`variant` 는 얼마나 좁은 자리인지를, `tone` 은 비어 있는 이유를 말합니다. 둘을 한 enum 으로 합치면 `compact` 와 `failure` 를 함께 고를 수 없으므로 축을 나눴습니다.

| `tone` | 쓰는 때 | 아이콘 색 | 아이콘 상자 색 | 보조 기술 알림 |
| --- | --- | --- | --- | --- |
| `neutral` | 아직 아무것도 없을 때 — 빈 목록, 맞는 결과가 없는 검색, 새 폴더 | `onSurfaceVariant` | `surfaceContainerHigh` | 없음 |
| `failure` | 무언가 실패해서 보여 줄 것이 없을 때 | `error` | `errorContainer` | 있음 |
| `success` | 할 일을 끝내서 보여 줄 것이 없을 때 | `success` | `successContainer` | 없음 |

"주문이 아직 없습니다" 와 "주문을 불러오지 못했습니다" 는 톤을 정하지 않으면 글만 다른 같은 모양이고, 그중 하나만 사용자가 알아야 할 실패입니다. `failure` 는 보조 기술에 보내는 알림 표시와 눈에 보이는 색을 함께 바꿉니다. 알림 표시의 내용은 [접근성](#스크린-리더)을 보세요.

<Preview demo="empty-state/tones" />

같은 아이콘을 넣으면 톤에 따라 달라 보이는 것은 아이콘 색과 아이콘 상자 색뿐입니다. 제목과 설명의 색은 그대로입니다. 그래서 톤마다 아이콘과 글도 함께 고릅니다.

<Preview component="empty-state" example="success" />

<Code language="dart" title="끝나서 보여 줄 것이 없을 때">
EmptyState(
  tone: CoreEmptyStateTone.success,
  icon: Icon(LucideIcons.circleCheck),
  title: Text('모두 끝났어요'),
  description: Text('모든 항목을 처리했어요.'),
)
</Code>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 상태

EmptyState 는 누르는 컴포넌트가 아니라서 hover · 포커스 · 비활성 상태가 없고, 비활성 속성도 없습니다. 사용자의 행동은 `action` 에 넣은 위젯이 받습니다. 콜백과 비활성 여부도 그 위젯에 정합니다.

비어 있는지, 불러오기에 실패했는지는 EmptyState 가 판단하지 않습니다. 언제 그릴지와 `tone` 은 부모가 고릅니다.

<a id="애니메이션"></a>

나타나거나 사라지는 애니메이션은 없습니다. 빈 상태와 콘텐츠를 부드럽게 바꾸려면 부모가 전환을 맡습니다. Flutter 라면 부모에서 `AnimatedSwitcher` 를 쓸 수 있습니다.

### 조합 예제

로딩, 실패, 빈 목록, 콘텐츠 순서로 가립니다. 로딩을 가장 먼저 확인합니다. 그러지 않으면 데이터가 오기 전의 빈 목록 때문에 빈 상태가 잠깐 보였다가 콘텐츠로 바뀝니다.

<Code language="dart" title="로딩 → 실패 → 빈 상태 → 콘텐츠 (Flutter)">
Widget buildContent() {
  if (isLoading) {
    return const Skeleton.text();
  }

  if (hasError) {
    return EmptyState(
      tone: CoreEmptyStateTone.failure,
      icon: Icon(LucideIcons.circleAlert),
      title: Text('항목을 불러오지 못했습니다'),
      action: Button(
        variant: CoreButtonVariant.outline,
        onPressed: handleRetry,
        child: Text('다시 시도'),
      ),
    );
  }

  if (items.isEmpty) {
    return EmptyState(
      icon: Icon(LucideIcons.inbox),
      title: Text('항목이 없습니다'),
      description: Text('새 항목을 추가하여 시작해 보세요.'),
      action: Button(
        variant: CoreButtonVariant.primary,
        onPressed: handleAdd,
        child: Text('추가하기'),
      ),
    );
  }

  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemTile(item: items[index]),
  );
}
</Code>

<Code language="dart" title="이렇게 하지 마세요 — 로딩 확인 없음">
// 데이터를 불러오는 중에도 빈 상태가 먼저 보입니다.
if (items.isEmpty) {
  return EmptyState(title: Text('항목이 없습니다'));
}
</Code>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

이럴 때 EmptyState 를 씁니다.

- 목록이나 표에 보여 줄 데이터가 없을 때
- 검색 결과가 없을 때
- 불러오기에 실패해 보여 줄 내용이 없고, 다시 시도할 길을 줄 때
- 사용자가 아직 아무것도 만들지 않은 처음 상태에서 시작을 이끌 때

이럴 때는 다른 컴포넌트가 맞습니다.

- [Alert](/components/alert) — 보여 줄 내용이 남아 있고 그 옆에서 실패 하나를 알려야 할 때. EmptyState 는 보여 줄 내용이 없는 영역 자체를 대신합니다.
- [Skeleton](/components/skeleton) — 데이터가 아직 오지 않아, 최종 콘텐츠 모양의 대역이 필요할 때
- [Loading](/components/loading) — 콘텐츠 대역 없이 작업이 진행 중임을 보일 때
- [Banner](/components/banner) — 비어 있는 콘텐츠 자리를 대신하지 않고, 화면 위쪽에 공지 띠가 필요할 때

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="empty-state/do-specific" tone="do" eyebrow="이렇게 하세요">

무엇이 없는지, 무엇을 하면 되는지 그 상황의 말로 쓰고, 상황에 맞는 아이콘과 푸는 행동을 함께 둡니다.

</Card>
<Card demo="empty-state/dont-vague" tone="dont" eyebrow="이렇게 하지 마세요">

"데이터 없음" 만 적으면 왜 비었는지, 다음에 무엇을 할지 알 수 없습니다.

</Card>
<Card demo="empty-state/do-failure-tone" tone="do" eyebrow="이렇게 하세요">

실패는 `tone: CoreEmptyStateTone.failure` 로 알리고, 문구와 아이콘에도 실패를 드러냅니다.

</Card>
<Card demo="empty-state/dont-failure-as-empty" tone="dont" eyebrow="이렇게 하지 마세요">

불러오지 못한 것을 "없어요" 라고 쓰지 않습니다. 사용자는 주문이 정말 없다고 읽습니다.

</Card>
</Cards>

- 모든 빈 상태에 같은 문구를 돌려 쓰지 않습니다. 빈 이유와 해결 방법을 상황마다 적습니다.
- 빈 상태를 막다른 곳으로 두지 않습니다. 이어서 할 일이 있으면 `action` 에 분명한 행동 하나를 둡니다.
- 데이터를 불러오는 동안에는 EmptyState 를 보이지 않습니다. 로딩인지 먼저 확인합니다([조합 예제](#조합-예제)).

## 사용 시나리오

### 목록이 비어 있는 경우

그 화면에서 빈 상태를 푸는 행동을 둡니다. 장바구니라면 "쇼핑 시작하기", 프로젝트 목록이라면 "프로젝트 만들기" 같은 버튼입니다.

<Code language="dart" title="빈 목록">
if (items.isEmpty)
  EmptyState(
    icon: Icon(LucideIcons.listChecks),
    title: Text('항목이 없습니다'),
    description: Text('새 항목을 추가하여 시작해 보세요.'),
    action: Button(
      variant: CoreButtonVariant.primary,
      onPressed: handleAdd,
      child: Text('추가하기'),
    ),
  )
</Code>

### 검색 결과 없음

검색어를 제목에 담으면 무엇을 찾지 못했는지 바로 보입니다. 검색을 되돌리는 버튼을 함께 둘 수 있습니다.

<Code language="dart" title="검색 결과 없음">
EmptyState(
  icon: Icon(LucideIcons.searchX),
  title: Text('"$searchQuery"에 대한 결과가 없습니다'),
  description: Text('철자를 확인하거나 다른 검색어를 시도해 보세요.'),
  action: Button(
    variant: CoreButtonVariant.outline,
    onPressed: handleResetSearch,
    child: Text('검색 초기화'),
  ),
)
</Code>

### 오류 상태

`tone` 을 `failure` 로 두고 다시 시도할 길을 줍니다.

<Preview component="empty-state" example="failure" />

<Code language="dart" title="불러오기 실패">
EmptyState(
  tone: CoreEmptyStateTone.failure,
  icon: Icon(LucideIcons.circleAlert),
  title: Text('결과를 불러오지 못했어요'),
  description: Text('연결을 확인하고 다시 시도해 주세요.'),
  action: Button(
    variant: CoreButtonVariant.outline,
    onPressed: handleRetry,
    child: Text('다시 시도'),
  ),
)
</Code>

<a id="레이아웃"></a>

## 배치

아이콘 · 제목 · 설명 · 행동은 세로로 쌓여 가운데에 놓입니다. 안쪽 여백과 최소 높이의 기본값은 `variant` 가 정하고, 글의 최대 폭은 세 밀도 모두 400 입니다. 셋 다 테마나 `emptyStateStyle` 로 바꿀 수 있습니다. 화면의 어느 영역을 대신할지와 부모의 크기는 쓰는 화면이 정합니다.

아래 두 그림의 선은 자리를 보이려고 문서에서 두른 것입니다.

### 패널 안

카드 · 패널 · 사이드바처럼 좁은 자리에는 `compact` 를 씁니다.

<Preview demo="empty-state/in-panel" />

### 정해진 영역 채우기

<Preview demo="empty-state/fill-area" />

Flutter 에서는 높이를 정한 `SizedBox` 나 `Expanded` 처럼 높이의 한계가 있는 부모에 직접 놓으면, 밀도와 상관없이 그 높이를 채우고 내용을 가운데에 놓습니다. `Column` 의 늘리지 않는 자식이나 스크롤 목록 안처럼 높이의 한계가 없는 자리에서는 내용 높이가 되고, `normal` · `large` 는 최소 240 입니다.

Web 의 높이는 블록 부모에서 내용 높이입니다(`normal` · `large` 는 최소 240). 정해진 영역을 채우려면 `classes` 를 적습니다. 형제가 없으면 `h-full`, 세로 flex 안에서 남은 높이를 차지하려면 `flex-1` 입니다. `height: 100%` 는 같은 부모의 형제를 고려하지 않는 값이라 컴포넌트가 스스로 적지 않습니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
SizedBox(
  height: CoreLayout.layout320,
  child: EmptyState(title: Text('검색 결과가 없어요')),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(styles: Styles(raw: {'height': '20rem'}), [
  EmptyState(classes: 'h-full', title: Text('검색 결과가 없어요')),
])
```

  </TabItem>
</Tabs>

### 폭

- **Flutter** — 부모가 폭의 한계를 정해 주면 그 폭을 채웁니다. `Row` 의 늘리지 않는 자식처럼 폭의 한계가 없는 자리에서는 내용 폭이 됩니다.
- **Web** — 루트가 `<div>` 라서 블록 부모, 그리고 자식을 늘리는 세로 flex(`align-items: stretch`)에서는 폭을 채웁니다. 가로 flex 나 `align-items: center` 인 세로 flex 에서는 내용 폭이 됩니다. 폭을 채우려면 `classes: 'w-full'` 을 적고, 가로 flex 에서 형제 옆의 남은 폭만 차지하려면 `flex-1` 을 적습니다.

### 자리가 낮을 때

EmptyState 는 스크롤 영역을 만들지 않습니다.

- **Flutter** — 최소 높이는 부모가 정한 최대 높이를 넘지 않습니다. 내용이 그 최대 높이보다 크면 스크롤 없이 넘칩니다.
- **Web** — `normal` · `large` 는 부모가 240 보다 낮아도 최소 높이 240 을 지켜 부모보다 커집니다.

낮은 자리에는 `compact` 를 쓰고, 그래도 모자라면 부모에서 스크롤을 맡깁니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

겉모습은 `emptyStateStyle`(`CoreEmptyStateStyle`) 하나로 바꿉니다. 안쪽 여백, 최소 높이, 글의 최대 폭, 세 간격, 아이콘의 크기와 색, 아이콘 상자의 크기 · 색 · 모서리, 제목과 설명의 글자 스타일을 담습니다. 필드 목록은 [API](#api) 끝의 표에 있습니다.

<Split>

<Code language="dart" title="하나만 바꾸기">
EmptyState(
  icon: Icon(LucideIcons.folderOpen),
  title: Text('저장한 필터가 없어요'),
  description: Text('자주 쓰는 조건을 저장해 보세요.'),
  emptyStateStyle: CoreEmptyStateStyle(
    minHeight: 0,
    iconBoxBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    iconBoxColor: CoreColor.token(CoreColors.primaryContainer),
    iconStyle: CoreIconStyle(
      color: CoreColor.token(CoreColors.onPrimaryContainer),
    ),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    emptyState: CoreEmptyStateTheme(
      style: CoreEmptyStateStyle(maxTextWidth: CoreLayout.layout320),
      variantStyles: {
        CoreEmptyStateVariant.compact: CoreEmptyStateStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space16),
        ),
      },
    ),
  ),
)
</Code>

</Split>

<Preview demo="empty-state/custom-style" />

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
기본값
  CoreEmptyStateStyle.defaultsByVariant[variant]       // 여백 · 최소 높이 · 간격 · 크기 · 글자 역할
  CoreEmptyStateStyle.defaultsByTone[tone]             // 아이콘 색 · 아이콘 상자 색
  → CoreComponentTheme.emptyState.style                // 앱 전체
  → CoreComponentTheme.emptyState.variantStyles[variant]  // 밀도별
  → emptyStateStyle                                    // 인스턴스 하나
```

글의 최대 폭(400)과 아이콘 상자의 모서리(원)는 모든 밀도가 같은 기본값을 씁니다. 간격 · 아이콘 · 글자 스타일은 안의 값 단위로 합칩니다. 예를 들어 테마가 제목 색만 정하고 인스턴스가 제목 굵기만 정하면 둘 다 남습니다.

<Note>

테마에는 톤별로 값을 나누는 자리가 없습니다. `iconBoxColor` 나 `iconStyle` 의 `color` 를 테마나 인스턴스에 정하면 톤의 기본 색보다 우선합니다. 두 값을 앱 전체에 정하면 `neutral` · `failure` · `success` 가 모두 같은 색이 됩니다.

`icon` 에 넣은 `Icon` 자신의 값은 위의 어느 값보다 우선합니다. `Icon` 에 직접 준 크기 · 색이나, 앱 전체 `Icon` 테마인 `CoreComponentTheme.icon.style` 의 크기 · 색이 있으면 그 값으로 그립니다. 앱 전체 `Icon` 색을 정해 두면 톤의 아이콘 색은 보이지 않고 아이콘 상자 색만 남습니다.

</Note>

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `EmptyState` 에는 `withStyle` 로 스타일을 덧붙입니다. `withStyle` 은 넘긴 값을 `emptyStateStyle` 에 합친 새 `EmptyState` 를 돌려주고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. `EmptyState` 에는 값마다 따로 있는 짧은 체인 getter 가 없습니다. 이전의 `.radius4` · `.primary` 같은 getter 는, 컴포넌트에서 테두리 · 모서리 · 배경이 빠지면서 함께 없어졌습니다. 지금은 `withStyle` 을 씁니다.

<Preview component="empty-state" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class EmptyStateChainExample extends StatefulWidget {
  const EmptyStateChainExample({super.key});

  @override
  State<EmptyStateChainExample> createState() => _EmptyStateChainExampleState();
}

class _EmptyStateChainExampleState extends State<EmptyStateChainExample> {
  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    ).withStyle(
      const CoreEmptyStateStyle(
        minHeight: 200,
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space8,
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class EmptyStateChainExample extends StatefulComponent {
  const EmptyStateChainExample({super.key});

  @override
  State<EmptyStateChainExample> createState() => _EmptyStateChainExampleState();
}

class _EmptyStateChainExampleState extends State<EmptyStateChainExample> {
  @override
  Component build(BuildContext context) {
    return EmptyState(
      title: Text('결과가 없어요'),
      description: Text('검색어나 필터를 바꿔 보세요.'),
    ).withStyle(
      const CoreEmptyStateStyle(
        minHeight: 200,
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space24,
          vertical: CoreSpace.space8,
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

| `tone` | Web | Flutter |
| --- | --- | --- |
| `neutral` · `success` | 루트에 역할을 붙이지 않습니다. | 알림용 `Semantics` 를 두르지 않습니다. |
| `failure` | 루트 `<div>` 에 `role="alert"` 를 붙입니다. | `Semantics(container: true, liveRegion: true)` 로 감쌉니다. `alert` 에 해당하는 네이티브 역할은 지정하지 않습니다. |

- **제목은 heading 이 아닙니다.** Web 은 제목과 설명을 `<div>` 에 담으며 `<h1>` ~ `<h6>` 이나 heading 역할을 붙이지 않습니다. Flutter 도 글자 스타일만 입히고 header 표시를 하지 않습니다. 빈 상태가 섹션 제목 노릇을 해야 하면 바깥에 heading 을 둡니다. Flutter 에서는 `title: Semantics(header: true, child: Text('…'))` 처럼 제목을 감쌀 수도 있습니다.
- Web 은 `attributes` 로 넘긴 값이 컴포넌트가 붙인 속성보다 우선합니다. `attributes: {'role': 'status'}` 를 주면 `failure` 의 역할이 `status` 로 바뀝니다. Flutter 에는 역할을 바꾸는 속성이 없습니다.

### 키보드

EmptyState 자신은 포커스를 받지 않고 키를 처리하지 않습니다. 아래는 `action` 에 `Button` 을 넣었을 때 그 버튼의 동작입니다.

| 키 | 동작 |
| --- | --- |
| `Tab` | 행동 버튼으로 포커스를 옮깁니다. |
| `Enter` · `Space` | 버튼을 누릅니다. |

Web 에서 `href` 를 준 `Button` 은 링크(`<a>`)로 그려지므로 브라우저의 링크 키를 따릅니다.

### 스크린 리더

- 읽을 내용은 `title` · `description` · `action` 에 넣은 위젯에서 옵니다. EmptyState 는 따로 이름을 만들지 않습니다.
- 아이콘 자리에는 EmptyState 가 이름이나 숨김 속성을 붙이지 않습니다. 아이콘이 뜻하는 것은 제목이나 설명에 글로 적습니다.
- 알림 표시는 `failure` 에만 붙습니다. Web 의 `role="alert"` 는 ARIA 명세에서 긴급(assertive) 라이브 영역입니다. Flutter 는 live region 표시만 하며 긴급도를 따로 정하지 않습니다.
- `neutral` 과 `success` 에는 알림 표시가 없습니다.
- 빈 상태가 나타나는 순간 실제로 읽히는지, 어떻게 읽히는지는 플랫폼과 보조 기술에 따라 다를 수 있습니다. 지원할 환경에서 확인하세요.

### 포커스 관리

- EmptyState 가 나타나거나 사라질 때 포커스를 옮기지 않습니다.
- 포커스를 가두지 않습니다.
- 목록이 빈 상태로 바뀔 때 사라진 항목에 포커스가 있었더라도 EmptyState 가 이어받지 않습니다. 필요하면 앱에서 행동 버튼이나 영역 제목 같은 곳으로 옮기세요.

### 알려진 제약

- **톤의 시각 차이는 색뿐입니다.** `tone` 은 아이콘 색과 아이콘 상자 색만 바꿉니다. 색을 가려 보기 어려운 환경에서는 이 차이가 전해지지 않을 수 있습니다. Web 의 강제 색 모드처럼 브라우저가 색을 시스템 색으로 바꾸는 환경에서도 톤끼리 같아 보일 수 있으며, EmptyState 에는 이를 막는 설정이 없습니다. 실패라는 사실을 `title` · `description` 에도 적고, 실패에는 다른 모양의 아이콘을 넘기세요.
- **아이콘이 없으면 톤이 화면에 드러나지 않습니다.** `icon` 을 주지 않거나 `showIcon: false` 이면, 글이 같은 세 톤은 같은 화면이 됩니다. `failure` 의 알림 표시는 그대로라서 화면과 보조 기술이 받는 정보가 달라집니다.
- **색을 덮어쓰면 톤의 색이 사라집니다.** 테마나 인스턴스에 정한 아이콘 색 · 아이콘 상자 색은 톤의 색보다 우선합니다. `Icon` 에 직접 준 색과 앱 전체 `Icon` 테마의 색도 톤의 아이콘 색보다 우선합니다([값이 정해지는 순서](#값이-정해지는-순서)).

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`title` · `variant` · `tone` · `icon` · `showIcon` · `description` · `showDescription` · `action` · `emptyStateStyle` 은 두 플랫폼에서 같은 속성입니다. 클래스 이름도 `EmptyState` 로 같습니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 슬롯 타입 | `Widget` / `Widget?` | `Component` / `Component?` |
| `const` 생성 | `EmptyState` · `EmptyState.compact` 모두 가능 | `const` 생성자가 없습니다. |
| 배치 구조 | `Center` 안의 `Column` | 세로 flex `<div>` |
| 아이콘 크기 | 밀도별 크기를 `IconTheme` 으로 아이콘에 전달합니다. `theme.scaling` 이 1 이 아니면 아이콘에는 배율이 두 번 곱해집니다(아이콘 상자에는 한 번). `Icon` 에 크기를 직접 주면 한 번만 곱해집니다. | 아이콘이 놓이는 칸의 크기만 정합니다. 안의 `Icon` 크기는 바꾸지 않습니다. |
| 아이콘 색 | `IconTheme` 으로 전달합니다. | 아이콘 칸의 글자색을 `Icon` 이 물려받습니다. |
| 실패 알림 | `Semantics` 의 live region | `role="alert"` |
| 폭 | 폭의 한계가 있으면 채웁니다. | 블록 부모에서는 채우고, 가로 flex 에서는 내용 폭입니다([폭](#폭)). |
| 높이 | 높이의 한계가 있는 부모에 직접 놓으면 채우고, 한계가 없으면 내용 높이입니다(`normal` · `large` 는 최소 240). | 블록 부모에서는 내용 높이입니다(`normal` · `large` 는 최소 240). 정해진 영역을 채우려면 `classes` 를 적습니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<div>` 에 닿습니다. |

`Icon` 에 직접 준 크기나 색은 두 플랫폼 모두 EmptyState 가 정한 값(기본값 · 테마 · `emptyStateStyle`)보다 우선합니다. `CoreComponentTheme.icon.style` 의 크기와 색도 마찬가지입니다.

<a id="props-parameters"></a>

## API

표의 `W` 는 Flutter 의 `Widget`, Web 의 Jaspr `Component` 입니다. `W?` 는 선택 슬롯입니다.

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `title` | `W` | 필수 | 빈 상태의 제목 |
| `variant` | `CoreEmptyStateVariant` | `normal` | 밀도 — `normal` · `compact` · `large` |
| `tone` | `CoreEmptyStateTone` | `neutral` | 비어 있는 이유 — `neutral` · `failure` · `success`. 아이콘 색과 아이콘 상자 색을 정하고, `failure` 는 알림 표시를 붙입니다. |
| `icon` | `W?` | `null` | 아이콘 상자 안에 그리는 위젯 |
| `showIcon` | `bool` | `true` | `false` 면 `icon` 이 있어도 그리지 않습니다. |
| `description` | `W?` | `null` | 제목 아래 보조 설명 |
| `showDescription` | `bool` | `true` | `false` 면 `description` 이 있어도 그리지 않습니다. |
| `action` | `W?` | `null` | 글 아래에 놓는 행동. 보통 Button 입니다. 글의 최대 폭 제한을 받지 않습니다. |
| `emptyStateStyle` | `CoreEmptyStateStyle?` | `null` | 보이는 값 덮어쓰기 |

`EmptyState.compact(...)` 는 `variant` 를 받지 않고 `compact` 로 정합니다. 나머지 파라미터는 같습니다. 두 플랫폼 모두 `copyWith` 와 `withStyle` 로 일부 값을 바꾼 새 인스턴스를 만들 수 있습니다. `copyWith` 에 넘기지 않았거나 `null` 로 넘긴 값은 원래 값을 유지합니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트의 id 와 배치용 클래스 · 스타일 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성. 컴포넌트가 붙인 속성과 이름이 같으면 이 값이 우선합니다. |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 DOM 이벤트 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreEmptyStateStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `padding` | `CoreEdgeInsets?` | Inner padding around the empty-state content (pre-scaling). |
| `minHeight` | `double?` | Minimum height of the empty-state stack (logical px, pre-scaling) — keeps a region from collapsing when its results vanish. `null` → the variant's [CoreEmptyStateVariantStyle.minHeight]. |
| `maxTextWidth` | `double?` | Maximum width of the title + description text block (logical px, pre-scaling). The stack itself fills whatever width its host gives it; only the text is capped so long labels wrap instead of stretching edge to edge. |
| `iconTitleGapStyle` | `CoreGapStyle?` | Space between the icon and the title, passed as is to `Gap(gapStyle: …)`. Laid over the variant's default (see [defaultsByVariant]). |
| `titleDescriptionGapStyle` | `CoreGapStyle?` | Space between the title and the description, passed as is to `Gap(gapStyle: …)`. Laid over the variant's default (see [defaultsByVariant]). |
| `descriptionActionGapStyle` | `CoreGapStyle?` | Space above the action — below the description, or below the title when the description is hidden. Passed as is to `Gap(gapStyle: …)` and laid over the variant's default (see [defaultsByVariant]). |
| `iconStyle` | `CoreIconStyle?` | Size and colour of the icon, applied to the icon widget you pass the same way `Button` styles its leading / trailing icon. The icon sits centred in the icon box ([iconBoxSize]). `null` size uses the variant's entry in [defaultsByVariant]; `null` colour uses the tone's entry in [defaultsByTone] ([defaultIconColor] for `neutral`). |
| `iconBoxSize` | `double?` | Edge length of the circular icon box the icon sits in (logical px, pre-scaling). `null` → the variant's [CoreEmptyStateVariantStyle.iconBoxSize]. |
| `iconBoxColor` | `CoreColor?` | Fill of the icon box. `null` → the tone's entry in [defaultsByTone]. |
| `iconBoxBorderRadius` | `CoreBorderRadius?` | Corner radius of the icon box. `null` → [defaultIconBoxBorderRadius] (fully rounded — a circle). |
| `titleTextStyle` | `CoreTextStyle?` | Title text style override, merged on top of the variant's title role (`titleMedium` normal / `titleSmall` compact). The role sets the weight; a weight stated here replaces it. |
| `descriptionTextStyle` | `CoreTextStyle?` | Description text style override. |

### `CoreEmptyStateStyle` 변형별 기본값 (`CoreEmptyStateVariantStyle`)

| 필드 | `normal` | `compact` | `large` |
|------|------|------|------|
| `padding` | CoreEdgeInsets.all(CoreSpace.space32) | CoreEdgeInsets.all(CoreSpace.space24) | CoreEdgeInsets.symmetric(horizontal: CoreSpace.space32, verti… |
| `minHeight` | layout240 | space0 | layout240 |
| `iconSize` | space28 | space20 | space32 |
| `iconBoxSize` | space64 | space48 | space72 |
| `iconTitleGapStyle` | CoreGapStyle(size: CoreSpace.space16) | CoreGapStyle(size: CoreSpace.space12) | CoreGapStyle(size: CoreSpace.space20) |
| `titleDescriptionGapStyle` | CoreGapStyle(size: CoreSpace.space8) | CoreGapStyle(size: CoreSpace.space6) | CoreGapStyle(size: CoreSpace.space8) |
| `descriptionActionGapStyle` | CoreGapStyle(size: CoreSpace.space24) | CoreGapStyle(size: CoreSpace.space16) | CoreGapStyle(size: CoreSpace.space24) |
| `titleTextStyle` | CoreTextStyle.token(CoreTextStyles.titleMedium) | CoreTextStyle.token(CoreTextStyles.titleSmall) | CoreTextStyle.token(CoreTextStyles.titleLarge) |
| `descriptionTextStyle` | — | CoreTextStyle.token(CoreTextStyles.bodySmall) | CoreTextStyle.token(CoreTextStyles.bodyLarge) |

<!-- STYLE_TABLE:END -->

<Note>

- 표의 `titleTextStyle` 설명에는 `normal` · `compact` 의 글자 역할만 적혀 있습니다. `large` 의 제목은 `titleLarge` 위에 덮어씁니다.
- 표의 `maxTextWidth` 설명에는 바깥 영역이 놓인 자리의 폭을 모두 채운다고 적혀 있습니다. Web 의 가로 flex 와 `align-items: center` 인 세로 flex 에서는 내용 폭입니다([폭](#폭)).
- 기본값 표에서 `normal` 의 `descriptionTextStyle` 칸 `—` 는 기본 설명 스타일(`bodyMedium` · `onSurfaceVariant`)을 그대로 쓴다는 뜻입니다.
- `iconStyle` 의 `size` 는 지금 Flutter 에서만 아이콘에 닿습니다. Web 은 아이콘이 놓이는 칸의 크기만 바꾸고, 안의 CoUI `Icon` 크기는 그대로입니다. `color` 는 두 플랫폼에 적용됩니다.
- `padding` 에 `CoreEdgeInsets.directional(…)` 을 주면 두 플랫폼 모두 그릴 때 `ArgumentError` 가 납니다. `all` · `symmetric` · `fromLTRB` · `only` 로 만드세요.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="empty-state/related-alert" title="Alert">

보여 줄 내용이 남아 있는 화면에서 실패나 경고를 알리는 상자입니다.

</Card>
<Card demo="empty-state/related-skeleton" title="Skeleton">

데이터를 불러오는 동안 콘텐츠 모양의 자리를 보여 줍니다.

</Card>
<Card demo="empty-state/related-loading" title="Loading">

콘텐츠 대역 없이 작업이 진행 중임을 보여 줍니다.

</Card>
<Card demo="empty-state/related-banner" title="Banner">

화면 전체에 걸친 소식을 띠로 알립니다.

</Card>
</Cards>
