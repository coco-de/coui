---
title: Skeleton
description: 내용이 도착하기 전에 그 자리의 모양을 잡아 두는 자리표시입니다. 상자 · 원 · 글줄 모양이 있고, 채움이 천천히 옅어졌다 짙어집니다.
category: display
platforms: [flutter, web]
related: [loading-region, loading, empty-state, avatar]
tags: [loading, placeholder, feedback]
template: v2
source: display/skeleton
---

# Skeleton

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

데이터를 기다리는 동안 도착할 내용의 모양을 미리 보여 줍니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 복사하세요.

<Playground component="skeleton" />

- 크기를 받는 타입이 다릅니다. Flutter는 숫자(논리 픽셀), Jaspr Web은 CSS 문자열(`'240px'`)이라 코드가 플랫폼마다 따로 나옵니다.
- `lines`와 `fromOpacity`는 `skeletonStyle`의 값입니다. `lines`는 `text`에만 닿습니다.
- `Skeleton.text`에는 폭 파라미터가 없어 부모의 폭을 씁니다. 미리보기는 폭 240인 상자 안에 그립니다.

`Skeleton` 하나는 자리표시 하나입니다. `child` 슬롯이 없고, 데이터를 요청하거나 실제 값을 대신 채우지 않습니다. 화면의 모양은 `Skeleton` 여러 개를 조합해 만듭니다.

<a id="변형-variants"></a>

## Variant

`variant`가 모양을 고릅니다. 기본값은 `rectangular`이고, `circular`와 `text`에는 이름 있는 생성자가 있습니다.

<a id="rectangular"></a>

<VariantRow name="rectangular" component="skeleton" props="variant=rectangular">

상자 하나입니다. 기본 모서리는 8입니다. 이미지 · 버튼 · 한 줄 막대처럼 `width`와 `height`로 크기를 정하는 자리에 씁니다.

</VariantRow>

<a id="circular"></a>

<VariantRow name="circular" component="skeleton" props="variant=circular">

아바타나 둥근 아이콘의 자리입니다. `Skeleton.circle`은 `size` 하나로 폭과 높이를 같게 둡니다.

</VariantRow>

<a id="text"></a>

<VariantRow name="text" component="skeleton" props="variant=text">

글줄 여러 개입니다. 기본은 3줄이고 줄 높이 12, 줄 간격 12, 모서리 4이며 마지막 줄은 폭의 60%입니다. 줄 수와 마지막 줄 폭은 `skeletonStyle`로 정합니다.

</VariantRow>

<Split>

<Code language="dart" title="Flutter">
Skeleton(width: 300, height: 150)

Skeleton.circle(size: 56)

Skeleton.text(
  skeletonStyle: CoreSkeletonStyle(lines: 4, lastLineWidth: 0.6),
)
</Code>

<Code language="dart" title="Jaspr Web">
Skeleton(width: '300px', height: '150px')

Skeleton.circle(size: '56px')

Skeleton.text(
  skeletonStyle: CoreSkeletonStyle(lines: 4, lastLineWidth: 0.6),
)
</Code>

</Split>

기본 생성자에 `variant`를 직접 줄 수도 있습니다.

- `variant: CoreSkeletonVariant.text`이면 `width`와 `height`를 줘도 쓰지 않습니다.
- `variant: CoreSkeletonVariant.circular`에 폭과 높이를 다르게 주면 원이 아니라 양 끝이 둥근 알약 모양이 됩니다.

## 크기

`size`로 고르는 크기 단계가 없습니다. `rectangular`는 `width`와 `height`, `circular`는 `Skeleton.circle`의 `size`로 정합니다.

<Preview demo="skeleton/sizing" />

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 값 | 숫자(논리 픽셀). 테마의 크기 배율(`theme.scaling`)을 곱합니다. | CSS 문자열. 테마의 크기 배율은 곱하지 않습니다. |
| 부모 폭 채우기 | `width: double.infinity`. 폭에 한계가 있는 부모에서만 씁니다. | `width: '100%'` |
| 부모보다 넓은 폭 | 부모에 한계가 있으면 그 안으로 줄어듭니다. `Row`처럼 한계가 없으면 정한 폭 그대로라 넘칠 수 있습니다. | `width`를 주면 `max-width: 100%`가 함께 붙어 부모보다 넓어지지 않습니다. |

### 값을 비운 축

| 플랫폼 | `width`나 `height`를 비우면 |
| --- | --- |
| Flutter | 그 축은 부모가 허락하는 최대 크기를 채웁니다. 부모가 그 축에 한계를 두지 않으면 0이 됩니다. `Column` 안의 `Skeleton(height: 16)`은 폭을 채우지만 `Row` 안에서는 폭이 0이고, `Column` 안의 `Skeleton(width: 200)`은 높이가 0입니다. |
| Jaspr Web | CSS의 `auto`를 따릅니다. 블록 부모나 자식을 늘이는 세로 flex 부모에서는 폭이 부모를 채우고, 비운 높이는 0입니다. 가로 flex 부모에서는 비운 폭이 0이고, 비운 높이는 기본 정렬에서 행의 높이까지 늘어납니다. |

크기가 0인 `Skeleton`은 보이지 않습니다. `rectangular`는 두 값을 함께 정하면 부모에 덜 좌우됩니다.

### 부모가 크기를 정할 때

Flutter에서는 부모가 폭이나 높이를 고정하면 `Skeleton`에 준 값 대신 부모의 크기가 됩니다. 세로 `ListView`의 항목, `crossAxisAlignment: CrossAxisAlignment.stretch`인 `Column`, 폭을 정한 `SizedBox`의 바로 아래, `Expanded`가 그런 자리입니다. 원도 길게 늘어납니다. `Align`으로 감싸면 정한 크기로 그립니다.

<Code language="dart" title="Flutter">
ListView(
  children: const [
    Align(
      alignment: Alignment.centerLeft,
      child: Skeleton.circle(size: 48),
    ),
  ],
)
</Code>

Web에서 정한 `width`는 flex의 늘이기(`stretch`)보다 우선합니다. 다만 가로 flex 행에서 자리가 모자라면 `Skeleton`도 다른 flex 항목처럼 폭이 줄어듭니다. 높이는 그대로라 원은 좁아진 모양이 됩니다. 원 옆에 글줄을 둘 때는 [배치](#배치)의 방법을 씁니다.

### 글줄의 크기

- 높이는 `줄 수 × 줄 높이 + (줄 수 − 1) × 줄 간격`입니다. 기본값은 3 × 12 + 2 × 12 = 60입니다. Flutter에서는 여기에 테마의 크기 배율이 곱해집니다.
- 폭은 부모를 따릅니다. Flutter의 `Skeleton.text`는 폭에 한계가 있는 부모가 필요합니다. `Row` 안에 `Expanded`나 폭을 정한 상자 없이 두면 레이아웃 오류가 납니다. Web의 글줄 묶음은 폭이 `100%`입니다.

<a id="동작-스펙-behavior"></a>

## 상태

Skeleton에는 hover · pressed · focus · disabled 상태와 켜고 끄는 파라미터가 없습니다.

| 상태 | 언제 | 보이는 모습 |
| --- | --- | --- |
| 맥동 | 기본 | 채움의 불투명도가 70%와 100% 사이를 천천히 오갑니다. |
| 멈춤 | 동작 줄이기를 켰을 때 | 쉼 끝(기본 70%)에 멈춥니다. |
| 없음 | 렌더하지 않을 때 | 아무것도 그리지 않고 자리도 남기지 않습니다. |

<Preview demo="skeleton/pulse-ends" />

앞의 두 막대는 맥동의 양 끝을 보이려고 `fromOpacity`와 `toOpacity`를 같게 둔 것입니다. 마지막 막대가 기본 설정입니다.

### 인터랙션

Skeleton은 누르거나 입력하는 요소가 아닙니다. 콜백 파라미터가 없습니다.

### 상태 전환

- **로딩 시작**: 조건이 참일 때 렌더하면 맥동이 시작됩니다.
- **로딩 완료**: 조건에서 빼고 실제 콘텐츠로 바꿉니다. Skeleton은 사라질 때의 전환 효과를 따로 넣지 않습니다. Flutter에서 교체를 부드럽게 하려면 `AnimatedSwitcher`로 감쌉니다.

### 애니메이션

- 맥동은 채움 색의 알파만 바꿉니다. 서페이스 스타일이 넣는 테두리는 함께 옅어지지 않습니다.
- `fromOpacity`(기본 0.7)에서 `toOpacity`(기본 1.0)까지 갔다가 돌아오기를 계속 반복합니다.
- 두 값은 채움 색이 가진 알파에 곱합니다. 투명한 채움(`.transparent`)은 내내 투명하고, 알파가 0.4인 채움은 기본값에서 0.28과 0.4 사이를 오갑니다.
- `duration`(기본 2000ms)은 왕복 한 번의 길이입니다. 올라가는 절반과 내려오는 절반에 각각 `curve`(기본 `CoreEasing.move`)를 앞 방향으로 적용합니다.
- 두 플랫폼이 `duration`과 `curve`를 같은 뜻으로 읽으므로, 같은 값을 주면 같은 속도로 맥동합니다. Flutter는 `AnimationController` 한 주기를 두 절반으로 나눠 알파를 바꾸고, Web은 `0%` · `100%`(쉼)와 `50%`(정점) CSS 키프레임으로 `background-color`를 바꿉니다.

### 동작 줄이기

동작 줄이기를 켜면 맥동이 멈추고 쉼 끝(`fromOpacity`)의 채움이 남습니다. 로딩 알림은 그대로입니다. 스피너처럼 표시를 위한 반복은 보통 동작 줄이기에서도 이어지지만, 자리표시는 멈춥니다. 멈춘 스피너와 달리 멈춘 블록은 여전히 자리표시로 읽히기 때문입니다. `duration` 값은 줄이지 않고 반복만 멈춥니다. 두 플랫폼의 이 규칙은 `CoreReducedMotion.runsPlaceholderPulse`가 정합니다.

| 플랫폼 | 따르는 설정 |
| --- | --- |
| Flutter | `MediaQuery.disableAnimations`(Android의 애니메이션 제거) 또는 `AccessibilityFeatures.reduceMotion`(iOS의 동작 줄이기). 설정을 끄면 다시 맥동합니다. 실행 중에 바꾼 iOS 설정이 이미 그려진 화면에 바로 반영되는 것은 `CoUIApp`(또는 직접 둔 `ReducedMotionScope`) 아래에서입니다. |
| Jaspr Web | `prefers-reduced-motion: reduce`. CSS 변수 `--coui-skeleton-pulse`를 바꿔, 맥동 대신 쉼 끝을 붙드는 키프레임을 씁니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- API 요청이나 비동기 데이터 로딩 중에 콘텐츠의 대략적인 형태를 미리 보여 줄 때
- 목록 항목 · 카드 · 글 블록처럼 도착할 콘텐츠의 레이아웃을 예측할 수 있을 때
- 콘텐츠가 들어올 자리를 미리 잡아 화면이 밀리는 현상(layout shift)을 줄이고 싶을 때

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 콘텐츠의 모양을 예측할 수 없거나, 작업 중이라는 것만 알리면 될 때 | [Loading](/components/loading) |
| 완료 비율을 아는 작업 | [Progress](/components/progress) |
| 로딩이 끝났는데 보여 줄 내용이 없을 때 | [EmptyState](/components/empty-state) |
| 콘텐츠는 그대로 두고 한 작업이 실패했음을 알릴 때 | [Alert](/components/alert) |

### 표시 여부는 호출하는 쪽 조건으로

`Skeleton`에는 켜고 끄는 파라미터가 없습니다. 로딩 중인지는 호출하는 쪽이 이미 알고 있으므로, 그 조건으로 렌더하거나 렌더하지 않습니다. 렌더하지 않으면 자리도 남지 않습니다.

<Split>

<Code language="dart" title="Flutter">
Column(
  children: [
    if (isLoading)
      Skeleton(width: 200, height: 20)
    else
      Text(title).bodyMedium,
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div([
  if (isLoading)
    Skeleton(width: '200px', height: '20px')
  else
    Text(title).bodyMedium,
])
</Code>

</Split>

`Skeleton` 여러 개가 한 영역을 채우면 자리마다 `Skeleton`을 두고 영역을 [LoadingRegion](/components/loading-region)으로 감쌉니다. 로딩 알림이 영역에 한 번만 생깁니다. `enabled`나 `asSkeleton`을 쓰던 코드는 [이전 API에서 옮기기](#이전-api에서-옮기기)를 보세요.

<a id="do"></a>
<a id="dont"></a>

### 모양과 개수

<Cards columns="2">
<Card demo="skeleton/do-match-layout" tone="do" eyebrow="이렇게 하세요">

도착할 콘텐츠와 같은 구조로 놓습니다. 모양이 비슷할수록 화면이 덜 밀리고, 바뀌는 순간이 덜 낯섭니다.

</Card>
<Card demo="skeleton/dont-single-block" tone="dont" eyebrow="이렇게 하지 마세요">

여러 부분으로 된 콘텐츠를 큰 상자 하나로 대신하면 무엇이 어디에 올지 알 수 없고, 바뀔 때 화면이 크게 달라집니다.

</Card>
<Card demo="skeleton/do-list" tone="do" eyebrow="이렇게 하세요">

목록의 자리표시는 3~5개 항목으로 두고, 목록 전체를 `LoadingRegion`으로 감쌉니다. 실제 개수를 모를 때 너무 많이 두면 오히려 어색합니다.

</Card>
<Card demo="skeleton/dont-spinner" tone="dont" eyebrow="이렇게 하지 마세요">

`Loading` 스피너를 함께 두지 않습니다. Skeleton이 이미 로딩 중임을 보여 주고, 둘 다 따로 알리면 라이브 영역도 둘이 됩니다.

</Card>
</Cards>

### 로딩이 끝나면 바로 바꾸기

Skeleton은 데이터를 기다리는 동안에만 둡니다. 오류가 났는데 남아 있으면 사용자는 끝없이 기다리게 됩니다. 오류와 빈 결과는 [EmptyState](/components/empty-state)로 보여 주고, 로딩이 끝나면 실제 콘텐츠로 바꿉니다. 아래의 `orderSkeletons`는 `Skeleton`을 담은 묶음이고, `OrderList`는 앱의 목록입니다.

<Split>

<Code language="dart" title="이렇게 하세요">
if (hasError) {
  return EmptyState(
    tone: CoreEmptyStateTone.failure,
    title: Text('주문을 불러오지 못했습니다'),
  );
}
if (isLoading) {
  return LoadingRegion(child: orderSkeletons);
}
return OrderList(orders: orders);
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 오류가 나도 Skeleton이 남아 계속 기다리게 됩니다.
if (isLoading || hasError) {
  return Skeleton.text(
    skeletonStyle: CoreSkeletonStyle(lines: 5),
  );
}
// 로딩이 끝나도 Skeleton이 남습니다.
// Flutter 예제입니다. Web에서는 Column 자리에 div를 씁니다.
return Column(
  children: [
    Skeleton.text(),
    OrderList(orders: orders),
  ],
);
</Code>

</Split>

### 회색 면 위에서는

기본 채움은 `surfaceContainerHighest`입니다. `surfaceContainerHigh` 이상의 회색 면 위에서는 바탕과 거의 구분되지 않으므로, Skeleton 대신 간격이나 면의 차이로 자리를 나눕니다.

## 배치

`Skeleton`은 한 칸씩만 그리므로 배치는 레이아웃이 정합니다. 아바타 옆에 글줄 두 줄을 두는 행은 다음처럼 만듭니다.

<Preview demo="skeleton/avatar-row" />

<Split>

<Code language="dart" title="Flutter">
Row(
  children: [
    const Skeleton.circle(size: 40),
    const Gap.space12(),
    const Expanded(
      child: Skeleton.text(
        skeletonStyle: CoreSkeletonStyle(lines: 2),
      ),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  [
    Skeleton.circle(size: '40px'),
    const Gap.space12(),
    div(
      [
        Skeleton.text(
          skeletonStyle: CoreSkeletonStyle(lines: 2),
        ),
      ],
      classes: 'flex-1',
    ),
  ],
  classes: 'flex items-center',
)
</Code>

</Split>

- Flutter는 `Expanded`가 글줄에 남은 폭을 줍니다. 없으면 레이아웃 오류가 납니다.
- Web은 남은 폭을 받는 래퍼(`flex-1`)에 글줄을 넣습니다. 폭이 `100%`인 글줄 묶음을 원 옆에 바로 두면 원의 폭이 줄어듭니다.
- Web의 Skeleton은 `<div>`를 그립니다. `<p>`나 `<span>` 안에는 두지 않습니다.

### 조합 예제

이미지, 아바타 행, 짧은 줄로 이루어진 카드의 자리표시입니다.

<Split>

<Code language="dart" title="Flutter">
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Skeleton(width: double.infinity, height: 180),
    const Gap.space12(),
    Row(
      children: [
        const Skeleton.circle(size: 40),
        const Gap.space8(),
        const Expanded(
          child: Skeleton.text(
            skeletonStyle: CoreSkeletonStyle(lines: 2),
          ),
        ),
      ],
    ),
    const Gap.space8(),
    const Skeleton(width: 80, height: 14),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  [
    Skeleton(width: '100%', height: '180px'),
    const Gap.space12(),
    div(
      [
        Skeleton.circle(size: '40px'),
        const Gap.space8(),
        div(
          [
            Skeleton.text(
              skeletonStyle: CoreSkeletonStyle(lines: 2),
            ),
          ],
          classes: 'flex-1',
        ),
      ],
      classes: 'flex items-center',
    ),
    const Gap.space8(),
    Skeleton(width: '80px', height: '14px'),
  ],
  classes: 'flex flex-col',
)
</Code>

</Split>

목록 하나의 로딩 · 빈 결과 · 콘텐츠를 이어 쓰면 다음과 같습니다. `users`와 `UserListTile`(Web 예제의 `userList`)은 앱의 것입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Widget buildUserList() {
  if (isLoading) {
    return LoadingRegion(
      semanticLabel: '사용자 목록 불러오는 중',
      child: Column(
        spacing: CoreSpace.space12,
        children: List.generate(
          4,
          (_) => const Row(
            children: [
              Skeleton.circle(size: 48),
              Gap.space12(),
              Expanded(
                child: Skeleton.text(
                  skeletonStyle: CoreSkeletonStyle(lines: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  if (users.isEmpty) {
    return EmptyState(
      icon: Icon(LucideIcons.users),
      title: Text('사용자가 없습니다'),
    );
  }

  return ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) => UserListTile(user: users[index]),
  );
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
Component buildUserList() {
  if (isLoading) {
    return LoadingRegion(
      semanticLabel: '사용자 목록 불러오는 중',
      child: div(
        [
          for (var i = 0; i < 4; i++)
            div(
              [
                Skeleton.circle(size: '48px'),
                const Gap.space12(),
                div(
                  [
                    Skeleton.text(
                      skeletonStyle: const CoreSkeletonStyle(lines: 2),
                    ),
                  ],
                  classes: 'flex-1',
                ),
              ],
              classes: 'flex items-center',
            ),
        ],
        classes: 'flex flex-col gap-space12',
      ),
    );
  }

  if (users.isEmpty) {
    return EmptyState(
      icon: Icon(LucideIcons.users),
      title: Text('사용자가 없습니다'),
    );
  }

  return userList(users);
}
```

  </TabItem>
</Tabs>

## 테마와 스타일

### 파라미터와 스타일

- **모양과 크기**는 위젯 파라미터입니다: `variant`, `width`, `height`.
- **겉모습(색 · 모서리 · 줄)과 맥동**은 `skeletonStyle` 하나로 넘깁니다: `backgroundColor`, `borderRadius`, `lines`, `lineHeight`, `lineSpacing`, `lastLineWidth`, `duration`, `curve`, `fromOpacity`, `toOpacity`.
- `lines` · `lineHeight` · `lineSpacing` · `lastLineWidth`는 `text`에만 닿습니다.

<Preview demo="skeleton/styles" />

### 값이 정해지는 순서

뒤로 갈수록 우선하고, 필드마다 따로 합칩니다. 어떤 단계에서 비운 필드는 앞 단계의 값이 남습니다.

```text
CoreSkeletonStyle 의 기본값 상수 · defaultsByVariant[variant]   // 디자인 시스템 기본값
  → CoreComponentTheme.skeleton.style                            // 앱 전체
  → CoreComponentTheme.skeleton.variantStyles[variant]           // 앱 전체, variant 별
  → skeletonStyle                                                // Skeleton 하나
```

테마는 `variant` 자체를 바꾸지 않습니다. 모양은 위젯 파라미터가 정합니다.

### 사용 예

<Split>

<Code language="dart" title="Skeleton 하나만 바꾸기">
Skeleton.text(
  skeletonStyle: CoreSkeletonStyle(
    lines: 4,
    lastLineWidth: 0.4,
    lineHeight: CoreSize.size16,
    lineSpacing: CoreSpace.space8,
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    skeleton: CoreSkeletonTheme(
      style: CoreSkeletonStyle(
        duration: Duration(milliseconds: CoreDuration.ms3000),
      ),
      variantStyles: {
        CoreSkeletonVariant.text: CoreSkeletonStyle(lines: 2),
      },
    ),
  ),
)
</Code>

</Split>

- 서페이스 스타일은 모서리를 바꿀 수 있습니다. 기본값뿐 아니라 `skeletonStyle`로 준 `CoreRadius` 값도 스타일의 범위로 옮겨질 수 있습니다. 컨트롤에 테두리를 넣는 스타일에서는 Skeleton(글줄은 줄마다)에도 `outline` 색 테두리가 생깁니다.
- 맥동을 없애려고 `duration`에 `Duration.zero`를 주지 않습니다. Flutter는 길이가 0인 반복을 시작할 수 없어 디버그 빌드에서 단언 오류가 납니다. 한 밝기에 세워 두려면 `fromOpacity`와 `toOpacity`를 같게 둡니다.

<a id="토큰-기반-스타일링"></a>

### 기본값이 있는 곳

기본값은 `coui_core`의 `CoreSkeletonStyle`에 있고, Flutter와 Web이 같은 값을 읽습니다.

| 상수 | 값 | 뜻 |
| --- | --- | --- |
| `defaultsByVariant[variant]` | 채움 `surfaceContainerHighest`. 모서리 8(`rectangular`) · 9999(`circular`) · 4(`text`) | variant별 겉모습 |
| `defaultLines` | 3 | 글줄 수 |
| `defaultLineHeight` | `CoreSize.size12` | 줄 높이 |
| `defaultLineSpacing` | `CoreSpace.space12` | 줄 간격 |
| `defaultLastLineWidth` | 0.6 | 마지막 줄의 폭 비율 |
| `defaultDuration` | `CoreDuration.ms2000` | 맥동 왕복 한 번 |
| `defaultCurve` | `CoreEasing.move` | 맥동의 각 절반에 적용하는 곡선 |
| `defaultFromOpacity` | `CoreOpacity.opacity70` | 쉼 끝의 불투명도 |
| `defaultToOpacity` | 1.0 | 정점의 불투명도 |

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Skeleton` 위에 `withStyle`로 스타일을 덧붙일 수 있습니다. 생성자의 `skeletonStyle`과 같게 동작하고, 겹치는 필드는 뒤에 붙인 값이 이깁니다. 이름이 곧 토큰인 getter도 있습니다.

- `.radius0`부터 `.radius9999`까지: `borderRadius`를 같은 이름의 `CoreRadius` 값으로 둡니다. 예를 들어 `.radius24`는 `CoreRadius.radius24`입니다.
- `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.outline` · `.transparent`: `backgroundColor`를 정합니다.

getter 이름이 곧 값이라, 같은 이름은 어느 컴포넌트에서 써도 같은 토큰을 가리킵니다.

<Preview component="skeleton" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class SkeletonChainExample extends StatefulWidget {
  const SkeletonChainExample({super.key});

  @override
  State<SkeletonChainExample> createState() => _SkeletonChainExampleState();
}

class _SkeletonChainExampleState extends State<SkeletonChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        const Skeleton(width: 200, height: 20).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(fromOpacity)까지 한 번에.
        const Skeleton(width: 200, height: 20).withStyle(
          const CoreSkeletonStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            fromOpacity: CoreOpacity.opacity20,
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
class SkeletonChainExample extends StatefulComponent {
  const SkeletonChainExample({super.key});

  @override
  State<SkeletonChainExample> createState() => _SkeletonChainExampleState();
}

class _SkeletonChainExampleState extends State<SkeletonChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Skeleton(width: '200px', height: '20px').radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(fromOpacity)까지 한 번에.
        Skeleton(width: '200px', height: '20px').withStyle(
          const CoreSkeletonStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            fromOpacity: CoreOpacity.opacity20,
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

<a id="접근성-accessibility"></a>

## 접근성

> 전역 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 따로 둔 Skeleton | `LoadingRegion` 안 |
| --- | --- | --- |
| Flutter | `Semantics(liveRegion: true, label: …)`. 시맨틱 역할(`SemanticsRole`)은 지정하지 않고 라이브 영역 표시와 이름만 붙입니다. | 아무것도 붙이지 않습니다. |
| Jaspr Web | 루트 `<div>`에 `role="status"`와 `aria-label`을 붙이고, 눈에 보이지 않게 숨긴 같은 문구의 글자를 안에 둡니다. `progressbar` 역할은 라이브 영역이 아니어서 쓰지 않으며, [Loading](/components/loading)과 같은 `status`입니다. | `role` · `aria-label` · 숨긴 글자가 없는 `<div>`입니다. |

### 키보드

없음. 두 플랫폼 모두 포커스를 받지 않고 처리하는 키가 없어 `Tab`은 Skeleton을 지나갑니다. Web 생성자에는 `onClick` · `onKeyDown` 같은 이벤트 파라미터가 없습니다.

### 스크린 리더

- 이름은 두 플랫폼 모두 지금 로케일의 로딩 문구(`loadingLabel`)입니다. 영어는 `Loading`, 한국어는 `로딩 중`입니다. 화면을 그리는 시점에 읽으므로 로케일을 바꾸면 따라 바뀝니다.
- 따로 둔 Skeleton은 두 플랫폼 모두 라이브 영역입니다. Web의 `status`는 정중한(polite) 알림이 기본입니다. 실제로 언제 어떻게 읽는지는 스크린 리더와 브라우저 · 운영체제에 따라 다릅니다.
- 그림 자체에는 읽을 콘텐츠가 없습니다. Web은 문구를 `aria-label`뿐 아니라 글자로도 담습니다. 라이브 영역은 이름이 아니라 내용을 읽기 때문입니다.
- [LoadingRegion](/components/loading-region) 안의 Skeleton은 스스로 알리지 않고, 영역이 한 번 알립니다. 영역에서 연 오버레이처럼 영역 바깥에 만들어지는 내용의 처리는 LoadingRegion 문서를 보세요.
- 동작 줄이기를 켜도 알림은 그대로입니다.

### 포커스 관리

없음. 오버레이가 아니어서 포커스를 옮기거나 가두지 않습니다. 포커스를 받지 않으므로, 로딩이 끝나 Skeleton이 사라져도 Skeleton 때문에 잃는 포커스는 없습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | Skeleton 하나의 알림 문구는 파라미터로 바꿀 수 없습니다. Flutter에는 `semanticLabel`이 없고, Web 생성자는 `attributes` · `classes` · `css`를 받지 않습니다. 무엇이 로딩 중인지는 [LoadingRegion](/components/loading-region)의 `semanticLabel`로 말합니다. |
| 공통 | 따로 둔 Skeleton은 하나마다 라이브 영역이 하나씩 생깁니다. N개를 놓으면 같은 문구의 라이브 영역이 N개이므로, 한 영역의 것은 `LoadingRegion`으로 감쌉니다. |
| 공통 | 로딩이 끝난 것은 알리지 않습니다. 조건에서 Skeleton이 빠지면 안내도 함께 사라집니다. |
| 공통 | 기본 라이트 테마의 채움은 흰 바탕과의 대비가 3:1에 못 미칩니다. 로딩 중이라는 정보는 위의 알림 문구가 함께 전합니다. |
| Flutter | 따로 둔 Skeleton은 알림을 위한 시맨틱 노드를 따로 만들도록 지정하지 않습니다(`container`를 쓰지 않습니다). 옆의 글이나 감싼 부모의 시맨틱 노드와 합쳐질 수 있습니다. `LoadingRegion`은 노드를 따로 만듭니다. |
| Jaspr Web | 알림 요소는 문구가 이미 든 상태로 삽입됩니다. 새로 삽입된 `status`를 바로 읽는지는 스크린 리더마다 다를 수 있으므로, 이 알림이 중요하면 지원하는 스크린 리더에서 확인하세요. |
| Jaspr Web | 자리표시를 배경색으로 그리고, 색 강제 모드(`forced-colors`)를 위한 Skeleton 전용 테두리 규칙은 없습니다. 브라우저가 배경색을 시스템 색으로 바꾸면 테두리가 없는 자리표시는 보이지 않을 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

파라미터 이름과 `variant` · `skeletonStyle`은 같습니다. 크기를 받는 타입과 크기를 정하는 방식은 각 플랫폼의 레이아웃을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 크기 타입 | `double?`(논리 픽셀). `Skeleton.circle`의 `size`는 `double` | `String?`(CSS 값, 예: `'200px'` · `'100%'`). `Skeleton.circle`의 `size`는 `String` |
| 크기 배율 | `width` · `height` · 모서리 · 줄 높이 · 줄 간격에 `theme.scaling`을 곱합니다. | 적은 크기에는 배율을 곱하지 않습니다. 줄 높이는 `rem`이고, 기본 모서리와 줄 간격은 CSS 변수를 따릅니다. |
| 값을 비운 축 | 부모의 최대 크기. 한계가 없으면 0 | CSS `auto` |
| 부모가 폭을 고정할 때 | 정한 `width` 대신 부모 폭 | 정한 `width`가 `stretch`보다 우선합니다. 가로 flex 행에서는 줄어들 수 있습니다. |
| 글줄의 폭 | 폭에 한계가 있는 부모가 필요합니다. | 글줄 묶음의 폭이 `100%` |
| `lastLineWidth` | 비율 그대로 | 백분율의 소수점 아래를 버립니다. |
| 그리는 방식 | `Container`와 `BoxDecoration` | `<div>`와 클래스 · 인라인 CSS |
| 맥동 | `AnimationController`로 채움 알파를 바꿉니다. | CSS 키프레임으로 `background-color`를 바꿉니다. |
| 동작 줄이기 | `MediaQuery.disableAnimations` · `AccessibilityFeatures.reduceMotion` | `prefers-reduced-motion` |
| 알림 | `Semantics(liveRegion: true)` | `role="status"`와 숨긴 글자 |
| 생성자 | `const`를 쓸 수 있습니다. | `const` 생성자가 아닙니다. |
| HTML 속성 | 없음 | `id` |

<a id="props-parameters"></a>

## API

<a id="skeleton-flutter-skeleton-web"></a>

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `width` | `double?` (Flutter) · `String?` (Web) | `null` | 자리표시의 폭. `text`에서는 쓰지 않습니다. |
| `height` | `double?` (Flutter) · `String?` (Web) | `null` | 자리표시의 높이. `text`에서는 쓰지 않습니다. |
| `variant` | `CoreSkeletonVariant` | `CoreSkeletonVariant.defaultVariant` (`rectangular`) | 모양. `rectangular` · `circular` · `text` |
| `skeletonStyle` | `CoreSkeletonStyle?` | `null` | 색 · 모서리 · 글줄 · 맥동을 바꾸는 값 묶음 |

두 플랫폼 모두 `key`를 받습니다.

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<div>`의 id. 세 생성자가 모두 받습니다. |

<a id="팩토리-생성자"></a>

### 이름 있는 생성자

| 생성자 | 파라미터 | 설명 |
| --- | --- | --- |
| `Skeleton.circle` | `size`(필수, Flutter `double` · Web `String`), `skeletonStyle` | 폭과 높이가 `size`이고 `variant`는 `circular`입니다. |
| `Skeleton.text` | `skeletonStyle` | `width` · `height`가 없고 `variant`는 `text`입니다. 줄 수와 줄 높이는 `skeletonStyle`로 정합니다. |

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreSkeletonStyle patch)` | `skeletonStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith({width, height, variant, skeletonStyle, key})` | 넘긴 값만 바꾼 사본을 만듭니다. `null`을 넘기면 기존 값이 남습니다. Web의 `copyWith`는 `id`도 받습니다. `attributes` · `classes` · `css` 인자도 있지만 사본에 반영하지 않습니다. |

### 테마

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `CoreComponentTheme.skeleton` | `CoreSkeletonTheme?` | `null` | 앱 전체의 Skeleton 테마 |
| `style` | `CoreSkeletonStyle?` | `null` | `CoreSkeletonTheme`의 값. 모든 Skeleton에 적용합니다. |
| `variantStyles` | `Map<CoreSkeletonVariant, CoreSkeletonStyle>?` | `null` | `CoreSkeletonTheme`의 값. variant마다 `style` 위에 덮습니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreSkeletonStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Skeleton fill (background) colour override. |
| `borderRadius` | `CoreBorderRadius?` | Border radius override. |
| `lineSpacing` | `double?` | Gap between text-variant lines (logical px) — applied to the native `Column.spacing` paint-API on Flutter and to the flex `row-gap` inline CSS on Web. `null` defers to [defaultLineSpacing]. |
| `lineHeight` | `double?` | Per-line height for the text variant (logical px). `null` defers to [defaultLineHeight]. Applied as `Container.height` on Flutter and inline `height` CSS on Web. |
| `lastLineWidth` | `double?` | Width fraction of the last line in text variant (0.0–1.0). |
| `lines` | `int?` | Default number of lines for text variant. |
| `duration` | `Duration?` | Length of one full pulse — rest → peak → rest — on both platforms. `null` → [defaultDuration]. |
| `curve` | `CoreCubicBezier?` | Easing of each half of the pulse, as cubic-bezier control points — applied forward to rest → peak and again to peak → rest, the way a CSS timing function applies per keyframe interval. `null` → [defaultCurve]. |
| `fromOpacity` | `double?` | Pulse animation start opacity (0.0–1.0), multiplied into the fill's own alpha at the resting end — a transparent fill stays transparent. |
| `toOpacity` | `double?` | Pulse animation end opacity (0.0–1.0), multiplied into the fill's own alpha at the peak. |

### `CoreSkeletonStyle` 변형별 기본값 (`CoreSkeletonVariantStyle`)

| 필드 | `rectangular` | `circular` | `text` |
|------|------|------|------|
| `borderRadius` | CoreBorderRadius.all(CoreRadius.radius8) | CoreBorderRadius.all(CoreRadius.radius9999) | CoreBorderRadius.all(CoreRadius.radius4) |
| `backgroundColor` | surfaceContainerHighest | surfaceContainerHighest | surfaceContainerHighest |

<!-- STYLE_TABLE:END -->

## 이전 API에서 옮기기

### enabled를 쓰던 코드

`Skeleton`의 생성자 · `Skeleton.circle` · `Skeleton.text` · `copyWith`에는 `enabled`가 없습니다. 조건부 렌더로 옮깁니다.

<Code language="dart" title="옮기기 전">
Skeleton(width: 200, height: 20, enabled: isLoading)
</Code>

<Code language="dart" title="옮긴 뒤 (Flutter의 children 안)">
if (isLoading) const Skeleton(width: 200, height: 20),
</Code>

<Note>

`enabled: false`는 자리를 완전히 비우지 않았습니다(Flutter는 크기 0인 위젯, Web은 숨긴 `<div>`). 그래서 형제를 세어 간격을 주는 레이아웃(Flutter `Column(spacing:)`, Web `space-y-*`)에서는 그 자리에 간격이 한 칸 남았습니다. 조건부 렌더는 자리를 남기지 않으므로, 옮긴 뒤 간격이 한 칸 줄어드는지 확인하세요.

</Note>

### asSkeleton을 쓰던 코드

화면의 위젯 전체를 한 번에 자리표시로 바꾸던 Flutter의 `asSkeleton(enabled:)`는 0.156부터 폐기 예고 상태입니다. 외부 패키지 `skeletonizer`가 위젯 트리를 칠하는 방식이라 색과 맥동이 `CoreSkeletonStyle`을 따르지 않고, Web에 대응하는 기능이 없으며, 로딩을 알리지 않습니다. 함께 쓰이던 `SkeletonTheme` · `CoUISkeletonizerConfigLayer` · `Bone` · `BoneMock`도 폐기 예고 상태입니다.

자리마다 `Skeleton`을 두고 영역은 [LoadingRegion](/components/loading-region)으로 감쌉니다.

<Code language="dart" title="옮기기 전 (Flutter)">
orderList.asSkeleton(enabled: isLoading)
</Code>

<Code language="dart" title="옮긴 뒤">
isLoading ? LoadingRegion(child: orderSkeletons) : orderList
</Code>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="skeleton/related-loading-region" title="LoadingRegion" href="/components/loading-region" more="LoadingRegion 보기">

Skeleton 여러 개를 감싸 영역마다 한 번 알립니다.

</Card>
<Card demo="skeleton/related-loading" title="Loading" href="/components/loading" more="Loading 보기">

콘텐츠의 모양을 예측할 수 없는 로딩에 씁니다.

</Card>
<Card demo="skeleton/related-empty-state" title="EmptyState" href="/components/empty-state" more="EmptyState 보기">

로딩이 끝났는데 보여 줄 내용이 없을 때 씁니다.

</Card>
<Card demo="skeleton/related-avatar" title="Avatar" href="/components/avatar" more="Avatar 보기">

아바타의 로딩 자리에는 `Skeleton.circle`을 씁니다. 크기는 `Skeleton.circle`의 `size`로 따로 맞춥니다.

</Card>
</Cards>
