---
title: RefreshTrigger
description: 스크롤을 당겨서 콘텐츠를 새로고침하는 Pull-to-Refresh 컴포넌트
category: overlay
platforms: [flutter, web]
related: [loading, progress]
tags: [refresh, pull-to-refresh, loading, gesture]
template: v2
source: overlay/refresh_trigger
---

# RefreshTrigger

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>
<a id="변형-variants"></a>
<a id="기본-default"></a>

## 플레이그라운드

속성을 바꿔 보며 새로고침을 확인하고, 만들어진 코드를 그대로 복사하세요. `stage`가 `idle`이면 목록을 맨 위에서 아래로 끌거나(마우스로도 됩니다) 위의 버튼을 눌러 새로고침을 시작합니다. 버튼은 `refresh()`를 부르며, 'refresh() 버튼' 컨트롤로 숨길 수 있습니다.

<Playground component="refresh-trigger" />

`RefreshTrigger`는 스크롤하는 `child`를 감싸 당겨서 새로고침을 붙입니다. 당긴 거리가 `minExtent`(기본 75) 이상일 때 놓으면 `onRefresh`를 부르고, 끝나면 완료 표시를 잠깐 보인 뒤 접습니다. 마우스 휠 스크롤은 당기기가 아닙니다.

<Note>

`stage` 선택지에는 `pulling`이 없습니다. 직접 지정한 `pulling`은 당긴 거리가 0이라 표시가 영역 밖에 남아 보이지 않습니다.

</Note>

## 구조

표시는 감싼 영역에서 당기는 쪽 가장자리에 겹쳐 놓이고, 평소에는 영역 밖으로 밀려 보이지 않습니다. 아래 그림은 `stage`를 `refreshing`으로 고정한 실제 컴포넌트입니다.

<Anatomy demo="refresh-trigger/anatomy">
<AnatomyItem part="container" name="Container">

감싼 영역. 표시는 이 영역 밖에서는 보이지 않습니다. 컴포넌트는 스스로 높이를 정하지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=content]" side="right" name="child">

스크롤하는 내용. 당기는 동안에는 표시와 함께 밀리고, 놓으면 제자리로 돌아갑니다. 새로고침 중에는 제자리에 있고 표시가 그 위에 겹칩니다.

</AnatomyItem>
<AnatomyItem select="[aria-live=polite]" side="left" name="indicator">

표시 상자. 바탕 `surface`, 모서리 16, 안쪽 여백 위아래 4 · 좌우 12(`pulling`은 사방 4)입니다. 컴포넌트의 기본값에는 테두리와 그림자가 없습니다.

</AnatomyItem>
<AnatomyItem select="[aria-live=polite] span" side="top" name="label">

단계마다 바뀌는 글. `labelLarge`이고 색은 단계가 정합니다.

</AnatomyItem>
<AnatomyItem select="[aria-live=polite] [role=status]" side="right" name="Loading">

단계를 알리는 모양 자리. `refreshing`은 `Loading` 스피너, `completed`는 체크 아이콘, `pulling`은 라벨 양옆의 화살표입니다. 라벨과의 간격은 8입니다.

</AnatomyItem>
</Anatomy>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>
<a id="넓은-당김-거리"></a>

## 당김 거리

`minExtent`는 새로고침이 시작되는 거리이고, `refreshing` · `completed` 동안 표시가 머무는 위치이기도 합니다. `maxExtent`는 표시와 내용이 가장 멀리 밀리는 거리입니다.

| 끈 거리 | 일어나는 일 |
| --- | --- |
| 0부터 `minExtent`까지 | 끈 만큼 표시와 내용이 밀립니다. 라벨은 `pullText`이고 화살표가 끈 거리에 비례해 돕니다. |
| `minExtent` 이상 | 라벨이 `releaseText`로 바뀝니다. 여기서 놓으면 `onRefresh`를 부릅니다. |
| `minExtent`를 넘어서 | 처음에는 끈 거리보다 조금 앞서 밀리다가(기본값에서 100을 끌면 약 106) `maxExtent`에 가까워지며 느려지고, 끈 거리가 `maxExtent`에 닿으면 표시와 내용도 그 위치에서 멈춥니다. |
| `minExtent`에 닿기 전에 놓음 | 취소하고 접습니다. `onRefresh`를 부르지 않습니다. |

<Code language="dart" title="더 길게 당겨야 시작하게">
RefreshTrigger(
  onRefresh: reload,
  minExtent: 120,
  maxExtent: 200,
  child: list,
)
</Code>

두 값은 논리 픽셀이고, `maxExtent`는 `minExtent`보다 크게 둡니다. 테마의 크기 배율과 밀도는 이 거리를 바꾸지 않습니다. Flutter는 당기기를 알아챈 첫 스크롤 신호의 이동량을 세지 않아, 손가락이 실제로 움직여야 하는 거리는 `minExtent`보다 조금 깁니다.

<a id="상태-전환-corerefreshstage"></a>

## 상태

단계(`CoreRefreshStage`)는 네 가지입니다.

| 단계 | 언제 | 라벨 | 모양 |
| --- | --- | --- | --- |
| `idle` | 대기 | `pullText` | 영역 밖에 있어 보이지 않습니다. |
| `pulling` | 당기는 동안 | `pullText`, `minExtent` 이상이면 `releaseText` | 라벨 양옆에 화살표, 안쪽 여백 사방 4 |
| `refreshing` | `onRefresh`가 도는 동안 | `refreshingText` | 라벨 뒤에 `Loading` 스피너, `minExtent` 위치 |
| `completed` | `onRefresh`가 끝난 뒤 500ms | `completedText` | 라벨 뒤에 체크 아이콘, `minExtent` 위치 |

라벨을 넘기지 않으면 지금 언어의 기본 문구를 씁니다. 문구는 Flutter의 `CoUILocalizations`, 웹의 `CouiLocalizations`에서 옵니다. 한국어는 '당겨서 새로고침' · '놓으면 새로고침' · '새로고침 중' · '새로고침 완료'입니다.

<Cards columns="2">
<Card demo="refresh-trigger/stage-pulling" title="pulling · 놓기 전">

화살표가 아래를 가리킵니다.

</Card>
<Card demo="refresh-trigger/stage-release" title="pulling · 놓으면 시작">

`minExtent`까지 끌면 화살표가 반 바퀴 돌고 라벨이 바뀝니다.

</Card>
<Card demo="refresh-trigger/stage-refreshing" title="refreshing">

`onRefresh`가 끝날 때까지 스피너가 돕니다.

</Card>
<Card demo="refresh-trigger/stage-completed" title="completed">

500ms 동안 보인 뒤 접힙니다.

</Card>
</Cards>

<Note>

`pulling` 두 장은 그림입니다. 당긴 거리는 포인터를 끌 때만 생겨 `stage`로는 보일 수 없습니다. 그림은 실제 `OutlinedContainer`에 표시의 기본 바탕 · 모서리 · `pulling` 여백을 넘겨 그려, 색 테마와 밝기는 따릅니다. `refreshTriggerStyle`과 `CoreRefreshTriggerTheme`으로 바꾼 값은 반영하지 않고, 서페이스 스타일 아래의 모습은 실제 표시와 다를 수 있습니다. `refreshing` · `completed` 두 장은 실제 컴포넌트를 `stage`로 고정한 것이고, 웹 문서의 이 카드는 서버가 그린 화면이라 끌어도 움직이지 않습니다.

</Note>

### 단계 직접 지정

`stage`가 `idle`(기본)이면 당기기가 단계를 정합니다. `idle`이 아닌 값을 넘기면 그 값이 당기기보다 앞섭니다. 앱의 다른 상태에 맞춰 표시를 켤 때 씁니다.

<Code language="dart" title="앱 상태로 표시 켜기">
RefreshTrigger(
  stage: isSyncing ? CoreRefreshStage.refreshing : CoreRefreshStage.idle,
  onRefresh: reload,
  child: list,
)
</Code>

| 항목 | 동작 |
| --- | --- |
| 작업 | `stage`를 바꾸는 것만으로는 `onRefresh`를 부르지 않습니다. 작업은 앱이 시작합니다. |
| 위치 | `refreshing` · `completed`는 `minExtent` 위치에 표시를 둡니다. 내용은 밀지 않습니다. |
| `pulling` | 당긴 거리가 0이라 표시가 보이지 않습니다. |
| `idle` | '지정하지 않음'과 같습니다. 당겨서 시작한 새로고침을 숨기지 못합니다. |
| 지정한 동안의 당기기 | 웹은 지정한 단계가 `refreshing` · `completed`면 당기기를 시작하지 않습니다. Flutter는 지정한 단계와 상관없이 당기기를 처리해, 충분히 당겼다 놓으면 `onRefresh`를 부를 수 있습니다. |

### 새로고침이 끝나면

| 상황 | 동작 |
| --- | --- |
| `onRefresh`의 `Future`가 끝남 | `completed`를 500ms 보인 뒤 `idle`로 돌아갑니다. 이 시간은 바꿀 수 없습니다. 접히는 동안에는 `pullText`가 보입니다. |
| `Future`가 오류로 끝남 | 성공과 구분하지 않고 `completed`를 지납니다. 겹쳐 부른 뒤의 호출이 이 `Future`를 기다리고 있으면 다릅니다([알려진 제약](#알려진-제약)). |
| `Future`가 끝나지 않음 | `refreshing`에 머뭅니다. |
| `onRefresh`가 없음 | 당기면 `refreshing`을 지나 곧바로 `completed`가 됩니다. |
| `refresh()` 호출 | 당겨서 놓은 것과 같이 `refreshing` → `completed` → `idle`로 진행합니다. |
| 도는 중에 `refresh()`를 다시 호출 | 앞의 작업이 성공으로 끝난 뒤 `onRefresh`를 다시 부릅니다. 오류로 끝나면 부르지 않습니다([알려진 제약](#알려진-제약)). 기다리는 호출이 둘 이상이면 앞의 작업이 끝난 직후 그 호출들의 `onRefresh`가 함께 실행됩니다. |
| `completed`를 보이는 500ms 안에 `refresh()` 호출 | 앞서 잡아 둔 접기가 남아, 새 작업이 끝나기 전에 표시가 접힐 수 있습니다. |

`refresh()`는 `RefreshTriggerState`의 함수입니다. Flutter는 `GlobalKey<RefreshTriggerState>`, 웹은 `GlobalStateKey<RefreshTriggerState>`를 `key`로 넘긴 뒤 부릅니다.

### 애니메이션

| 대상 | 동작 |
| --- | --- |
| 당기는 동안 | 내용은 전환 없이 끄는 거리를 따라갑니다. 표시도 Flutter에서는 바로 따라갑니다. 웹의 표시에는 `CoUIWeb`의 테마 전환(`enableThemeAnimation`, 기본 켜짐)이 150ms 전환을 걸어, 내용보다 조금 늦게 따라옵니다(동작 줄이기를 켜지 않았을 때, Chrome에서 확인). |
| 새로고침이 시작될 때와 `completed` 뒤에 접힐 때 | 표시와 내용이 `animationDuration`(기본 300ms), `easeOutSine`으로 움직입니다. |
| `minExtent`에 닿기 전에 놓아 취소할 때 | 웹은 같은 전환으로 접힙니다. Flutter는 전환 없이 바로 접힐 수 있습니다. |
| 화살표 | `minExtent`까지 끄는 동안 반 바퀴 돕니다. 세로는 아래를 가리키며 시작하고, 가로는 오른쪽을 가리키며 시작합니다. |
| `refreshing` | `Loading` 스피너(16, `primary`)가 돕니다. |

## 방향

`direction`은 당기는 축을, `reverse`는 반대쪽 가장자리를 고릅니다. Flutter에서는 `child`가 같은 축으로 스크롤해야 합니다.

| `direction` | `reverse` | 당기는 법 | 표시가 나오는 곳 |
| --- | --- | --- | --- |
| `vertical` | `false` | 맨 위에서 아래로 | 위 |
| `vertical` | `true` | 맨 아래에서 위로 | 아래 |
| `horizontal` | `false` | 왼쪽 끝에서 오른쪽으로 | 왼쪽 |
| `horizontal` | `true` | 오른쪽 끝에서 왼쪽으로 | 오른쪽 |

<Note>

쓰기 전에 세 가지를 확인하세요. Flutter의 `reverse: true`는 맨 아래에서 더 당겨도 새로고침이 시작되지 않을 수 있고, 반대로 맨 아래에 닿은 뒤 손을 떼지 않고 되돌려 끌면 새로고침이 시작될 수 있습니다(`refresh()`와 `stage`로는 표시됩니다). `reverse`에서는 화살표가 뒤집히지 않아 당기는 방향의 반대를 가리키며 시작합니다. `horizontal`에서 표시는 당긴 거리만큼만 밀려 들어와, 표시가 `minExtent`보다 넓으면 가장자리 쪽 일부가 잘릴 수 있습니다.

</Note>

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

사용자가 직접 당겨 최신 내용을 불러오는 목록(피드 · 알림 · 메일함)에 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 눌러서 새로고침하기만 하면 될 때 | [Button](/components/button) |
| 화면이 스스로 불러오는 동안 진행 표시만 필요할 때 | [Loading](/components/loading) |
| 작업이 얼마나 됐는지 비율로 알릴 때 | [Progress](/components/progress) |
| 보여 줄 내용이 아직 없을 때 | 도착할 모양대로 만든 [Skeleton](/components/skeleton) |
| 새로고침은 실패했지만 이전 내용이 남아 있을 때 | [Alert](/components/alert) |
| 실패해서 보여 줄 내용이 하나도 없을 때 | [EmptyState](/components/empty-state) |

### 새로고침 함수

`onRefresh`는 새 데이터를 받아 화면에 반영한 뒤 끝나는 `Future`를 돌려줍니다. 예외는 함수 안에서 처리합니다.

<Code language="dart" title="onRefresh">
Future<void> reload() async {
  try {
    final latest = await repository.fetchMessages();
    if (!mounted) return;
    setState(() {
      messages = latest;
      loadError = null;
    });
  } on Exception catch (_) {
    if (!mounted) return;
    setState(() => loadError = '목록을 새로 못 불러왔어요');
  }
}
</Code>

처리하지 않은 예외는 `refresh()`가 돌려주는 `Future`로 나오고, 당겨서 시작한 새로고침에서는 처리되지 않은 오류가 됩니다. `refresh()`를 겹쳐 불러 뒤의 호출이 기다리고 있는 `onRefresh`가 예외로 끝나면 표시가 `refreshing`에 멈춥니다([알려진 제약](#알려진-제약)). 함수 안에서 예외를 처리해도 표시는 `completed`를 지나므로, 실패는 Alert로 알립니다. 완료 라벨도 바꾸려면 `completedText: loadError == null ? null : '새로고침 실패'`처럼 결과에 따라 넘깁니다. 이때도 체크 아이콘과 `success` 색은 그대로입니다.

<a id="do"></a>
<a id="dont"></a>

<Cards columns="2">
<Card demo="refresh-trigger/do-report-failure" tone="do" eyebrow="이렇게 하세요">

실패는 `onRefresh` 안에서 처리하고, 남아 있는 목록 위에 Alert로 알리며 다시 할 일을 함께 적습니다.

</Card>
<Card demo="refresh-trigger/stage-completed" tone="dont" eyebrow="이렇게 하지 마세요">

실패를 완료 표시로 끝내지 않습니다. `completed`는 성공과 실패를 구분하지 않아 새 내용이라고 믿게 됩니다.

</Card>
<Card demo="refresh-trigger/do-button" tone="do" eyebrow="이렇게 하세요">

당기기와 같은 일을 하는 버튼을 함께 둬, 키보드로도 새로고침할 수 있게 합니다.

</Card>
<Card demo="refresh-trigger/dont-gesture-only" tone="dont" eyebrow="이렇게 하지 마세요">

당기기만 두면 키보드를 쓰는 사람은 새로고침할 방법이 없습니다.

</Card>
</Cards>

| 지킬 것 | 이유 |
| --- | --- |
| 새로고침 중에 화면 전체를 덮는 로딩을 따로 띄우지 않습니다. | 표시가 이미 진행을 알립니다. |
| 같은 목록을 바꾸는 요청(다시 불러오기 · 더 보기)을 하는 버튼은 그동안 앱이 꺼 둡니다. | 새로고침 중에도 `child`는 눌려 요청이 겹칠 수 있습니다. |
| 무엇이 바뀌었는지는 갱신 시각이나 새 항목 표시로 남깁니다. | 완료 표시는 잠깐 보이고 접힙니다. |

## 배치

RefreshTrigger는 스스로 높이를 정하지 않고, 두 플랫폼은 스크롤하는 곳이 다릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 스크롤하는 곳 | `child` 안의 스크롤 위젯(`ListView` · `GridView` · `CustomScrollView` · `ScrollArea` 등). 가장 가까운 스크롤 위젯의 신호만 읽고, 그 안에 또 있는 스크롤은 보지 않습니다. | RefreshTrigger가 `child`를 담는 안쪽 상자. `child`는 자기 스크롤이 없는 요소로 둡니다. |
| 높이 | 스크롤 위젯이 높이를 받는 자리(`Expanded` · `SizedBox` 등)에 둡니다. | `css`나 `classes`로 RefreshTrigger에 높이를 줍니다. 주지 않으면 내용만큼 늘어나 안쪽 상자가 스크롤하지 않고, 페이지를 아래로 스크롤한 상태에서도 아래로 끌면 당겨집니다. |
| 내용이 영역보다 짧을 때 | `controller`를 주지 않고 `primary: false`도 아닌 세로 `ListView` · `GridView` · `CustomScrollView`는 당길 수 있습니다. `ScrollArea`는 당겨지지 않습니다. `SingleChildScrollView`, `controller`를 주었거나 `primary: false`인 목록, 가로 목록은 `physics: const AlwaysScrollableScrollPhysics()`를 줘야 당겨집니다. | 당길 수 있습니다. |
| 스크롤하지 않는 `child` | 당겨지지 않습니다. 스크롤 위젯의 신호가 있어야 합니다. | 당길 수 있습니다. |

웹은 대기 중에도 안쪽 상자에 `transform`을 두므로, `child` 안의 `position: fixed` 요소는 이 상자를 기준으로 놓입니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  children: [
    Expanded(
      child: RefreshTrigger(
        onRefresh: reload,
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) => Text(messages[index]),
        ),
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
RefreshTrigger(
  css: const Styles(raw: {'height': '24rem'}),
  onRefresh: reload,
  child: div([
    for (final message in messages) div([Text(message)]),
  ]),
)
```

  </TabItem>
</Tabs>

<a id="조합-예제"></a>

### 버튼과 함께 두기

당기기 옆에 버튼을 두고, 버튼에서 `RefreshTriggerState`의 `refresh()`를 부릅니다. 당긴 것과 같은 표시가 나오고 같은 `onRefresh`가 불립니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
// State에 둡니다: final refreshKey = GlobalKey<RefreshTriggerState>();
Column(
  children: [
    Button(
      variant: CoreButtonVariant.outline,
      onPressed: () => refreshKey.currentState?.refresh(),
      child: const Text('새로고침'),
    ),
    Expanded(
      child: RefreshTrigger(
        key: refreshKey,
        onRefresh: reload,
        child: ListView(children: rows),
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
// State에 둡니다: final refreshKey = GlobalStateKey<RefreshTriggerState>();
div([
  Button(
    variant: CoreButtonVariant.outline,
    onPressed: () => refreshKey.currentState?.refresh(),
    child: const Text('새로고침'),
  ),
  RefreshTrigger(
    key: refreshKey,
    css: const Styles(raw: {'height': '24rem'}),
    onRefresh: reload,
    child: div(rows),
  ),
])
```

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-refreshtriggerstyle"></a>
<a id="refreshtriggerstyle-슬롯"></a>
<a id="커스텀-인디케이터-스타일"></a>

## 테마와 스타일

라벨 · 당김 거리 · 방향 · 단계는 위젯 속성으로 정하고, 표시의 겉모습(바탕 · 모서리 · 여백 · 간격 · 글자 · 이동 시간)은 `refreshTriggerStyle`(`CoreRefreshTriggerStyle`) 하나로 바꿉니다.

<Preview demo="refresh-trigger/custom-style" />

<Split>

<Code language="dart" title="RefreshTrigger 하나만 바꾸기">
RefreshTrigger(
  onRefresh: reload,
  refreshTriggerStyle: const CoreRefreshTriggerStyle(
    indicatorBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    indicatorBorderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    indicatorPadding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space16,
      vertical: CoreSpace.space8,
    ),
  ),
  child: list,
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    refreshTrigger: CoreRefreshTriggerTheme(
      style: CoreRefreshTriggerStyle(
        indicatorBackgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
  ),
)
</Code>

</Split>

표시 바탕의 기본값은 `surface`라 같은 색 면 위에서는 상자 경계가 보이지 않습니다. 목록 위에서 상자로 보이게 하려면 위처럼 바탕을 바꿉니다. 테두리와 그림자를 정하는 필드는 없습니다.

### 단계별 글자

| 단계 | 글자 필드 | 기본 글자와 색 | 같은 색을 따르는 것 |
| --- | --- | --- | --- |
| `idle` · `pulling` | `idleTextStyle` | `labelLarge` · `onSurfaceVariant` | 화살표 |
| `refreshing` | `refreshingTextStyle` | `labelLarge` · `primary` | 없음. 스피너는 `Loading`의 기본 색입니다. |
| `completed` | `completedTextStyle` | `labelLarge` · `success` | 체크 아이콘 |

`labelStyle`은 세 필드 위에 겹쳐 모든 단계의 글자를 바꿉니다. 글자 색은 `labelStyle`이 아니라 단계별 필드의 `color`로 정합니다. Flutter는 `labelStyle`의 색을 쓰지 않고 웹은 씁니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `RefreshTrigger`에 `withStyle`로 스타일을 덧붙일 수 있습니다. `refreshTriggerStyle` 위에 합쳐지고, 겹치는 필드는 뒤에 붙인 값이 이깁니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class RefreshTriggerChainExample extends StatefulWidget {
  const RefreshTriggerChainExample({super.key});

  @override
  State<RefreshTriggerChainExample> createState() => _RefreshTriggerChainExampleState();
}

class _RefreshTriggerChainExampleState extends State<RefreshTriggerChainExample> {
  // A GlobalKey lets us access the RefreshTrigger's state so we can
  // trigger a programmatic refresh (via the button) in addition to the
  // pull gesture.
  final _refreshTriggerKey = GlobalKey<RefreshTriggerState>();

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      child: SizedBox(
        height: CoreSpace.space256,
        child:
            RefreshTrigger(
              key: _refreshTriggerKey,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(seconds: 1));
              },
              child: ScrollArea(
                child: Container(
                  height: CoreSpace.space256 * 2,
                  padding: const CoreEdgeInsets.only(
                    top: CoreSpace.space32,
                  ).toValue(geometry: Theme.of(context).geometry),
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      const Text('당겨 보세요'),
                      const Gap.space16(),
                      Button(
                        onPressed: () => _refreshTriggerKey.currentState?.refresh(),
                        variant: .primary,
                        child: const Text('새로고침'),
                      ),
                    ],
                  ),
                ),
              ),
            ).withStyle(
              const CoreRefreshTriggerStyle(
                indicatorBackgroundColor: CoreColor.token(CoreColors.secondaryContainer),
                indicatorBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                indicatorPadding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space20,
                  vertical: CoreSpace.space12,
                ),
                indicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
              ),
            ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class RefreshTriggerChainExample extends StatefulComponent {
  const RefreshTriggerChainExample({super.key});

  @override
  State<RefreshTriggerChainExample> createState() => _RefreshTriggerChainExampleState();
}

class _RefreshTriggerChainExampleState extends State<RefreshTriggerChainExample> {
  // A GlobalStateKey lets us access the RefreshTrigger's state so we
  // can trigger a programmatic refresh (via the button) in addition to
  // the pull gesture.
  final _refreshTriggerKey = GlobalStateKey<RefreshTriggerState>();

  @override
  Component build(BuildContext context) {
    return OutlinedContainer(
      classes: 'w-full',
      child:
          RefreshTrigger(
            key: _refreshTriggerKey,
            css: const Styles(raw: {'height': 'var(--coui-space-256)'}),
            onRefresh: () async {
              await Future<void>.delayed(const Duration(seconds: 1));
            },
            child: div(
              [
                const Text('당겨 보세요'),
                const Gap.space16(),
                Button(
                  onPressed: () => _refreshTriggerKey.currentState?.refresh(),
                  variant: .primary,
                  child: const Text('새로고침'),
                ),
              ],
              classes: 'flex w-full flex-col items-center',
              styles: const Styles(
                raw: {
                  'height': 'calc(var(--coui-space-256) * 2)',
                  'padding-top': 'var(--coui-space-32)',
                },
              ),
            ),
          ).withStyle(
            const CoreRefreshTriggerStyle(
              indicatorBackgroundColor: CoreColor.token(CoreColors.secondaryContainer),
              indicatorBorderRadius: CoreBorderRadius.all(CoreRadius.radius24),
              indicatorPadding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space20,
                vertical: CoreSpace.space12,
              ),
              indicatorGapStyle: CoreGapStyle(size: CoreSpace.space12),
            ),
          ),
    );
  }
}
```

  </TabItem>
</Tabs>
<!-- CHAIN_SNIPPET:END -->

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
CoreRefreshTriggerStyle.default*              // 디자인 시스템 기본값
  → CoreComponentTheme.refreshTrigger.style   // 앱 전체
  → refreshTriggerStyle                       // RefreshTrigger 하나
```

뒤로 갈수록 우선합니다. 글자 필드와 `indicatorGapStyle`은 필드 안의 값마다 합쳐지므로, 색만 바꾸면 글자 크기와 굵기는 앞의 값이 남습니다.

<a id="접근성-accessibility"></a>

## 접근성

당겨서 새로고침은 포인터를 끄는 동작이라, 컴포넌트만으로는 키보드로 새로고침할 수 없습니다.

### 역할

| 플랫폼 | 붙는 것 |
| --- | --- |
| Flutter | 컴포넌트 전체를 `Semantics(liveRegion: true)`로 감쌉니다. 역할도 이름도 정하지 않습니다. |
| Jaspr Web | 표시 상자에 `role="status"` · `aria-live="polite"` · `data-refresh-stage`가 붙습니다. 루트는 역할 없이 `data-refresh-direction`과 넘긴 `attributes`를 받고, 스크롤하는 안쪽 상자에도 역할이 없습니다. |

`refreshing`의 `Loading`은 두 플랫폼 모두 자기 라이브 영역과 이름(한국어 '로딩 중')을 가져, 표시의 라이브 영역 안에 하나가 더 들어갑니다.

### 키보드

| 키 | 동작 |
| --- | --- |
| 없음 | 두 플랫폼 모두 키를 듣지 않습니다. |

Flutter는 스크롤 신호만, 웹은 `pointerdown` · `pointermove` · `pointerup` · `pointercancel`만 듣습니다. `child` 안의 키 처리는 그대로 동작합니다. 키보드 사용자에게는 [버튼과 함께 두기](#버튼과-함께-두기)처럼 `refresh()`를 부르는 버튼을 줍니다.

### 스크린 리더

| 항목 | 동작 |
| --- | --- |
| 읽히는 글 | 단계별 라벨입니다. `pullText` · `releaseText` · `refreshingText` · `completedText`로 바꾸고, 넘기지 않으면 지금 언어의 기본 문구입니다. 웹 표시의 `role` · `aria-live`는 `attributes`로 덮을 수 없습니다. |
| 알림 | 웹은 polite 라이브 영역이라 라벨이 바뀔 때마다 알릴 수 있습니다. 접히며 돌아오는 `pullText`도 포함됩니다. |
| 대기 중 | 웹은 표시가 문서에 남아 영역 밖으로 밀려 가려질 뿐이라, 화면에 없는 `pullText`가 읽힐 수 있습니다. |
| 라이브 영역의 범위 | 웹은 표시 상자 하나, Flutter는 감싼 스크롤 내용 전체입니다. |

### 포커스 관리

컴포넌트는 포커스를 받을 대상을 만들지 않습니다. Flutter에는 `Focus`가 없고 웹에는 `tabindex`가 없습니다. 새로고침이 시작되거나 끝나도 포커스를 옮기지 않으며, 오버레이가 아니라 포커스를 가두지도 않습니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | 키보드만으로는 당길 수 없습니다(WCAG 2.1.1). `refresh()`를 부르는 버튼을 함께 두거나, 버튼에서 직접 작업을 하고 `stage`로 표시만 켭니다. |
| 공통 | 겹쳐 부른 뒤의 `refresh()`가 기다리고 있는 `onRefresh`가 예외로 끝나면, 표시가 `refreshing`에 멈추고 이후의 `refresh()`도 `onRefresh`를 부르지 않고 같은 예외를 던집니다. 예외는 `onRefresh` 안에서 처리합니다. |
| 공통 | `completed`를 보이는 500ms 안에 `refresh()`를 다시 부르면, 앞서 잡아 둔 접기가 남아 새 작업이 끝나기 전에 표시가 접힐 수 있습니다. 끝날 때까지 표시를 남겨야 하면 앱이 진행 상태를 들고 `stage`로 지정합니다. |
| 공통 | 새로고침이 도는 중에 `refresh()`를 두 번 이상 겹쳐 부르면 기다리던 `onRefresh`가 함께 실행될 수 있고, 완료 표시는 마지막 호출만 따라 다른 작업이 도는 중에 `completed`가 될 수 있습니다. 새로고침 버튼은 도는 동안 앱이 꺼 둡니다. |
| 공통 | `async`가 아닌 `onRefresh`가 `Future`를 돌려주기 전에 예외를 던지면 표시가 `refreshing`에 남을 수 있습니다. `onRefresh`는 `async` 함수로 씁니다. |
| 공통 | 실패를 보이는 단계가 없어, 실패해도 체크 아이콘이 있는 `completed`를 지납니다. |
| 공통 | `reverse`에서도 화살표가 뒤집히지 않습니다. |
| 공통 | `horizontal`에서 표시가 `minExtent`보다 넓으면 당기는 가장자리 쪽이 잘릴 수 있습니다. 짧은 라벨을 넘기거나 `minExtent`를 키웁니다. `minExtent`를 키우면 시작 거리도 함께 늘고, `maxExtent`는 그보다 커야 합니다. |
| 공통 | 표시 바탕이 `surface`이고 테두리 · 그림자 필드가 없어 같은 색 면 위에서는 경계가 보이지 않습니다. |
| Jaspr Web | 색 강제(forced-colors) 모드에서 `liquidGlass` · `neumorphism`이 아닌 서페이스 스타일(기본 포함)은 테두리를 더하지 않아 표시의 경계가 보이지 않습니다. |
| Flutter | `reverse: true`는 맨 아래에서 더 당긴 거리가 쌓이지 않아 당겨서는 시작되지 않을 수 있습니다. 반대로 맨 아래에 닿은 뒤 같은 끌기로 되돌려 스크롤하면 그 거리가 당긴 거리로 쌓여, 표시가 보이지 않는 채로 있다가 놓을 때 뜻하지 않게 `onRefresh`를 부를 수 있습니다. `refresh()`를 부르는 버튼을 씁니다. |
| Flutter | 당기다가 되돌릴 때, 목록이 짧거나 반대쪽 끝에 닿으면 당긴 거리가 줄지 않을 수 있습니다. 당기는 쪽으로 끈 거리만 쌓여, 손가락을 처음 위치로 되돌린 뒤 놓아도 `onRefresh`를 부를 수 있습니다. |
| Flutter | 당기다가 되돌릴 때 목록이 스크롤할 수 있으면, 줄어드는 당긴 거리와 목록 스크롤이 겹쳐 내용이 손가락보다 빠르게 움직일 수 있습니다. 처음 위치를 지나 계속 끌면 내용이 그만큼 더 밀렸다가, 놓을 때 한 번에 튈 수 있습니다. |
| Flutter | `minExtent`에 닿기 전에 놓아 취소하면 전환 없이 바로 접힐 수 있습니다. 그 뒤 당기기나 `refresh()`로 새로고침이 시작되기 전까지는 앱이 `stage`를 바꿔도 표시가 전환 없이 바뀔 수 있습니다. |
| Flutter | `stage`를 `refreshing` · `completed`로 지정한 동안에도 당겼다 놓으면 `onRefresh`를 부를 수 있습니다. `onRefresh`에서 이미 불러오는 중인지 확인합니다. |
| Jaspr Web | 터치 화면에서는 브라우저가 끌기를 스크롤로 가져가 당기기가 중간에 끊길 수 있습니다. 끊기는 순간(`pointercancel`) 이미 `minExtent`를 넘었으면 놓은 것과 같이 `onRefresh`를 부릅니다. 컴포넌트는 `touch-action`을 정하지 않습니다. |
| Jaspr Web | 맨 위에서 누른 채 아래로 조금만 움직여도 당기기가 시작됩니다. 안의 버튼을 누르다 포인터가 밀리면 클릭이 전달되지 않을 수 있고, 아래로 끄는 글자 선택도 당기기가 될 수 있습니다. |
| Jaspr Web | 누른 마우스 버튼을 가리지 않아, 오른쪽이나 가운데 버튼으로 끌어도 당기기가 시작될 수 있습니다. |
| Jaspr Web | 당기기가 시작되기 전에 마우스를 누른 채 영역 밖으로 나가 놓으면, 나중에 영역 위에서 마우스를 움직이기만 해도 당기기가 시작될 수 있습니다. |
| Jaspr Web | 맨 위인지는 RefreshTrigger의 안쪽 상자로만 판단합니다. `child` 안에 따로 스크롤하는 영역을 두면, 그 영역을 아래로 스크롤한 상태에서도 아래로 끌면 당겨질 수 있습니다. |
| Jaspr Web | 표시 이동과 화살표 회전은 '동작 줄이기' 설정을 따르지 않습니다. 그 설정을 따라야 하면 앱이 설정을 읽어 `CoreRefreshTriggerStyle(animationDuration: Duration.zero)`를 넘깁니다. |
| Jaspr Web | 스크롤하는 안쪽 상자에 `tabindex`가 없고 속성을 넘길 자리도 없습니다. 안에 포커스할 수 있는 요소가 없으면, 브라우저에 따라 키보드로 이 영역을 스크롤하지 못할 수 있습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

생성자 이름은 같고, 당기기를 알아채는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `child` 타입 | `Widget` | `Component` |
| 당기기를 알아채는 것 | 가장 가까운 스크롤 위젯의 스크롤 신호 | 포인터 이벤트와 안쪽 상자의 스크롤 위치 |
| 스크롤하는 곳 | `child`의 스크롤 위젯 | RefreshTrigger의 안쪽 상자. 높이를 줘야 합니다. |
| 짧거나 스크롤하지 않는 내용 | 조건에 따라 당겨지지 않습니다([배치](#배치)). | 당길 수 있습니다. |
| 당기는 동안의 표시 | 끈 거리를 바로 따라갑니다. | `CoUIWeb`의 테마 전환이 켜져 있으면 150ms 전환이 걸려 늦게 따라옵니다(동작 줄이기를 켜지 않았을 때). |
| 당기다가 되돌리기 | 목록이 반대쪽으로 더 스크롤할 수 있는 동안에만 당긴 거리가 줄고 목록도 함께 스크롤합니다([알려진 제약](#알려진-제약)). | 처음 위치까지 되밀면 당기기를 취소합니다. |
| 놓아서 취소할 때 | 전환 없이 바로 접힐 수 있습니다. | `animationDuration` 동안 접힙니다. |
| `reverse` 당기기 | 맨 아래에서 더 당겨서는 시작되지 않을 수 있고, 되돌려 끌 때 시작될 수 있습니다. | 맨 아래에서 위로(가로는 오른쪽 끝에서 왼쪽으로) 당기면 시작합니다. |
| `stage`를 지정한 동안의 당기기 | 계속 처리합니다. | `refreshing` · `completed`면 시작하지 않습니다. |
| 단계가 바뀔 때 | 150ms 교차 전환 | 라벨과 아이콘은 바로 바뀝니다. 색은 `CoUIWeb`의 색 전환(150ms)을 따릅니다. |
| 같은 단계에서 라벨 · 글자 스타일 · 테마 색을 바꿀 때 | 그 단계에 들어올 때의 글과 글자 색이 남아, 다음 단계부터 반영됩니다. 라이트에서 다크로 바꾸면 라벨이 어두운 색으로 남아 읽기 어렵습니다(이 사이트의 Flutter 미리보기에서 확인). 바탕 · 모서리 · 안쪽 여백은 바로 바뀝니다. 당기는 중에 끈 거리에 따라 `pullText`와 `releaseText`가 바뀌는 것은 바로 보입니다. | 바로 반영됩니다. |
| 표시 상자에 닿는 값 | 표시를 `OutlinedContainer`로 그려, 앱 테마의 `CoreComponentTheme.outlinedContainer` 값과 컨트롤에 그림자를 더하는 [서페이스 스타일](/guides/surface-styles)(`neoBrutalism`)의 그림자가 닿습니다. 이 스타일에서는 대기 중에도 당기는 가장자리에 그림자 끝이 보일 수 있습니다. | 두 가지 모두 닿지 않습니다. |
| 화살표 회전 | 끈 거리를 바로 따릅니다. | 당기는 중에도 `animationDuration`만큼 부드럽게 따라갑니다. |
| `labelStyle`의 색 | 쓰지 않습니다. | 씁니다. |
| '동작 줄이기' | 표시 이동이 바로 끝납니다. | 그대로 재생합니다. |
| 당기기를 위해 바꾸는 것 | 감싼 영역의 모든 스크롤에 마우스 끌기를 더하고 `ClampingScrollPhysics`를 씁니다(바운스 없음). | 안쪽 상자에 `overscroll-behavior: contain`을 두고, 당기는 동안 글자 선택을 막습니다. |
| 표시를 옮기는 단위 | 논리 픽셀 | 거리는 px로 재고 위치는 `rem`으로 그려, 브라우저 글자 크기를 키우면 표시가 더 멀리 밀립니다. |
| `refresh()`용 키 | `GlobalKey<RefreshTriggerState>` | `GlobalStateKey<RefreshTriggerState>` |
| HTML 속성 | 없음 | 루트에 `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W`는 Flutter의 `Widget`, 웹의 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 감싸는 스크롤 내용 |
| `onRefresh` | `Future<void> Function()?` | `null` | 새로고침이 시작되면 부르는 함수. 돌려준 `Future`가 끝나면 완료입니다. |
| `stage` | `CoreRefreshStage` | `idle` | `idle` · `pulling` · `refreshing` · `completed`. `idle`이 아닌 값은 당기기보다 앞섭니다([단계 직접 지정](#단계-직접-지정)). |
| `direction` | `CoreRefreshDirection` | `vertical` | 당기는 축: `vertical` · `horizontal` |
| `reverse` | `bool` | `false` | 아래(가로는 오른쪽) 끝에서 당깁니다. |
| `minExtent` | `double` | `75` | 새로고침이 시작되는 거리이자 표시가 머무는 위치(논리 픽셀). 기본값은 `CoreRefreshTriggerStyle.defaultMinExtent` |
| `maxExtent` | `double` | `150` | 가장 멀리 밀리는 거리(논리 픽셀). 기본값은 `CoreRefreshTriggerStyle.defaultMaxExtent` |
| `pullText` | `String?` | `null` | `idle`과 `minExtent`에 닿기 전 `pulling`의 라벨. `null`이면 지금 언어의 문구 |
| `releaseText` | `String?` | `null` | `minExtent` 이상 당긴 `pulling`의 라벨. `null`이면 지금 언어의 문구 |
| `refreshingText` | `String?` | `null` | `refreshing`의 라벨. `null`이면 지금 언어의 문구 |
| `completedText` | `String?` | `null` | `completed`의 라벨. `null`이면 지금 언어의 문구 |
| `refreshTriggerStyle` | `CoreRefreshTriggerStyle?` | `null` | 표시의 겉모습과 이동 시간 |
| `key` | `Key?` | `null` | `refresh()`를 부르려면 `RefreshTriggerState`의 키를 넘깁니다. |

웹의 `RefreshTrigger`는 루트에 붙는 `id` · `classes` · `css` · `attributes` · `eventHandlers`도 받습니다.

### 그 밖의 멤버

| 이름 | 설명 |
| --- | --- |
| `RefreshTriggerState.refresh()` | `Future<void>`를 돌려줍니다. `onRefresh`를 부르고 `refreshing` → `completed` → `idle`로 진행합니다. `onRefresh`의 오류는 이 `Future`로 나옵니다. |
| `withStyle(CoreRefreshTriggerStyle patch)` | `refreshTriggerStyle`에 `patch`를 합친 사본을 돌려줍니다. 겹치는 필드는 `patch`가 이깁니다. |
| `copyWith(...)` | 넘긴 값만 바꾼 사본을 만듭니다. `null`을 넘겨 값을 비울 수는 없습니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.refreshTrigger` | `CoreRefreshTriggerTheme?` | `style: CoreRefreshTriggerStyle?` 하나로 앱 전체 기본값을 정합니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreRefreshTriggerStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `indicatorBackgroundColor` | `CoreColor?` | Indicator surface fill colour override. |
| `indicatorBorderRadius` | `CoreBorderRadius?` | Indicator corner radius override. |
| `indicatorPadding` | `CoreEdgeInsets?` | Indicator content padding override for the resting state. |
| `pullingPadding` | `CoreEdgeInsets?` | Indicator content padding override for the compact `pulling` state. |
| `indicatorGapStyle` | `CoreGapStyle?` | Style of the `Gap`s between the indicator's elements (icon and label). Merged on top of [defaultIndicatorGapStyle]. |
| `idleTextStyle` | `CoreTextStyle?` | Per-stage text style override for the `idle` / `pulling` stages. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `idleTextColor` field removed). Defaults to [defaultIdleTextStyle]. |
| `refreshingTextStyle` | `CoreTextStyle?` | Per-stage text style override for the `refreshing` stage. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `refreshingTextColor` field removed). Defaults to [defaultRefreshingTextStyle]. |
| `completedTextStyle` | `CoreTextStyle?` | Per-stage text style override for the `completed` stage. Text colour is carried via [CoreTextStyle.color] inside this slot (sb8 — raw `completedTextColor` field removed). Defaults to [defaultCompletedTextStyle]. |
| `animationDuration` | `Duration?` | Slide / cross-fade animation duration override. |
| `labelStyle` | `CoreTextStyle?` | Indicator label text style override. |

<!-- STYLE_TABLE:END -->

<Note>

표를 보충합니다. `animationDuration`은 표시와 내용이 밀리고 돌아오는 시간이고 웹에서는 화살표 회전에도 쓰입니다. 표의 설명과 달리 Flutter의 150ms 라벨 교차 전환에는 쓰이지 않고, `completed`를 보이는 500ms도 바꾸지 않습니다. `labelStyle`의 색은 Flutter에서 쓰이지 않습니다. `refreshingTextStyle`의 색은 스피너에 닿지 않습니다. `indicatorPadding`은 `pulling`이 아닌 단계에, `pullingPadding`은 `pulling` 단계에 쓰입니다. `indicatorGapStyle`은 화살표 · 라벨 · 스피너 · 체크 사이의 간격이고 기본값은 8입니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card demo="refresh-trigger/related-loading" title="Loading">

당기는 동작 없이 진행 중이라는 것만 알립니다. [Loading 문서](/components/loading)

</Card>
<Card demo="refresh-trigger/related-progress" title="Progress">

작업이 얼마나 됐는지 비율로 보여 줍니다. [Progress 문서](/components/progress)

</Card>
<Card demo="refresh-trigger/related-alert" title="Alert">

내용이 남아 있는데 한 가지가 실패했을 때 알립니다. [Alert 문서](/components/alert)

</Card>
</Cards>
