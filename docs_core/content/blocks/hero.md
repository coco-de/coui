---
title: Hero
description: 페이지 흐름 안에 놓이는 히어로 블록입니다. 배경색, 선택적 배경 이미지와 오버레이, 전경 콘텐츠를 그리며 위에 떠 있는 오버레이는 아닙니다. 이전 이름은 HeroSection입니다.
design: true
---

# Hero

<a id="live-preview"></a>

## 레이아웃

배경 imageUrl과 오버레이는 두 레이아웃 모두에서 전경 뒤에 놓입니다.

<BlockCatalogVisual kind="hero-layouts" />

| 값 | 설명 |
|---|---|
| `center` | child를 가운데에 둡니다. media는 그리지 않습니다. |
| `split` | child(카피)와 media를 나란히 둡니다. media가 없을 때 Flutter는 카피를 가운데에, Web은 앞쪽 위에 둡니다. |

<a id="반응형"></a>

<DesignNote title="반응형">
태블릿 브레이크포인트 768px이 기준입니다. 768px 미만에서는 카피 위, 미디어 아래로 세로 배치하고, 이상에서는 카피 앞, 미디어 뒤로 가로 배치합니다.
</DesignNote>

기준은 Hero가 놓인 칸이 아니라 화면의 폭이라, 좁은 칸 안의 Hero도 창이 768px 이상이면 가로로 놓입니다. 기준을 바꾸는 필드는 없습니다. Web의 서버 렌더는 폭을 0으로 읽어 split을 세로로 내보내고, 브라우저에서 [깨어난](/guides/glossary) 뒤 실제 폭으로 다시 맞춥니다. 깨어나지 않는 Hero는 계속 세로입니다.

<a id="기본-사용법-basic-usage"></a>

## 기본 사용법

<Split>

<Code language="dart" title="center">
Hero(
  child: Text('Welcome')
      .headlineSmall.onSurface,
)
</Code>

<Code language="dart" title="split">
Hero(
  layout: CoreHeroLayout.split,
  media: Text('Media')
      .titleMedium.onSurface,
  child: Text('Ship the product')
      .headlineSmall.onSurface,
)
</Code>

</Split>

<a id="props"></a>
<a id="props-parameters"></a>

## 속성

W는 Flutter에서 Widget, Web에서 Component입니다.

| 속성 | 타입 | 설명 |
|---|---|---|
| `layout` | `CoreHeroLayout?` | center(기본) 또는 split |
| `media` | `W?` | split의 뒤쪽 영역. center에서는 무시 |
| `child` | `W` | 필수 카피 영역 |
| `imageUrl` | `String?` | cover로 맞추는 배경 이미지. 전경 미디어가 아님 |
| `semanticLabel` | `String?` | 히어로 영역의 접근성 이름 |
| `appear` | `bool` | 등장 애니메이션 사용 여부. 기본 false |
| `heroStyle` | `CoreHeroStyle?` | 배경, 오버레이, 높이, 여백, 간격, 등장 모션 |

<a id="스타일-시스템-style-system"></a>

## 스타일

heroSectionStyle은 heroStyle의 이전 이름이며 deprecated입니다. HeroSection · CoreHeroSectionStyle · CoreHeroSectionTheme도 deprecated인 이전 이름이며, Hero · CoreHeroStyle · CoreHeroTheme으로 바꾸면 같은 모양을 그립니다.

| 필드 | 기본값 | 설명 |
|---|---|---|
| `backgroundColor` | `surfaceContainer` | 배경 채움 |
| `overlayColor` | 없음 | 배경 이미지 위의 스크림 |
| `minHeight` | `400` | 최소 높이. 콘텐츠가 크면 늘어남 |
| `padding` | `space32` | 바깥 여백 |
| `layout` | `center` | 위젯 layout이 null일 때의 기본 배치 |
| `splitGapStyle` | `Gap` `space32` | 카피와 미디어 사이 간격 |
| `appearDuration` | `moderate` | appear: true일 때만 적용 |
| `appearOffset` | `space16` | 전경이 올라오는 거리 |
| `appearCurve` | `enter` | 등장 이징 |

프로젝트 전체 값은 CoreComponentTheme의 heroSection 필드(CoreHeroTheme)에 style로 주고, 인스턴스의 heroStyle이 그보다 앞섭니다. overlayColor는 imageUrl이 없어도 배경색 위, 전경 아래에 칠해집니다.

<a id="남은-갭"></a>

첫 화면 높이를 채우는 옵션(fillViewport)은 아직 없고, 높이는 minHeight 하한으로만 정합니다. 블록에 아직 없는 기능은 [블록 전체 보기](/blocks#남은-항목)에 있습니다.

<a id="동작-스펙-behavior"></a>

## 등장 애니메이션

appear: true이면 전경이 뷰포트에 처음 들어올 때 한 번 올라오며 나타납니다.

1. 배경과 오버레이는 움직이지 않고, 한 번 나타난 뒤에는 되감기지 않습니다.
2. 동작 줄이기 설정이 켜지면 전환 시간이 0이 됩니다.
3. Web은 서버 렌더링만으로는 등장 감지가 실행되지 않습니다. 그래서 깨어나지 않는 Hero는 스크립트가 켜진 브라우저에서 전경이 투명한 채 남고, 스크립트가 꺼진 브라우저에서는 바로 보입니다.
4. 나타나기 전의 전경은 탭과 클릭을 받지 않지만 키보드 포커스는 막지 않아, 아직 보이지 않는 버튼에도 Tab이 닿습니다.

<a id="접근성-accessibility"></a>
<a id="역할"></a>
<a id="키보드"></a>
<a id="스크린-리더"></a>
<a id="포커스-관리"></a>
<a id="알려진-제약"></a>

## 접근성

| 항목 | 동작 |
|---|---|
| 역할 | Flutter는 semanticLabel이 있을 때만 region 랜드마크를 만들고, Web은 항상 role="region"을 냅니다. |
| 키보드 | Hero가 처리하는 키는 없습니다. 자식 버튼과 링크가 각자 동작합니다. |
| 읽기 순서 | split에서 카피 다음 미디어입니다. |
| 포커스 | 진입이나 이탈 때 포커스를 옮기거나 가두지 않습니다. |

<DesignNote title="알려진 제약">
imageUrl은 장식이라 대체 텍스트가 없습니다. 정보를 담은 이미지는 media에 둡니다. Web에서 semanticLabel을 생략하면 이름 없는 region이 남습니다.
</DesignNote>

<a id="사용-가이드라인"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

1. 페이지의 첫 구간에 쓰고, 카드나 다이얼로그 안에서는 쓰지 않습니다.
2. 카피와 이미지를 나란히 둘 때는 split을 쓰고, 카피 안에 Row를 직접 만들지 않습니다.
3. 배경 사진은 imageUrl, 읽혀야 하는 그림은 media로 둡니다.

<a id="크로스-플랫폼"></a>
<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Web |
|---|---|---|
| 폭 변경 감지 | MediaQuery가 바뀌면 다시 계산 | 뷰포트 크기 변경을 듣고 다시 계산 |
| 등장 감지 | 렌더 위치를 읽는 전경 위젯 | DOM 관찰과 CSS 전환. 서버 렌더링만으로는 실행되지 않음 |
| 영역 역할 | 라벨이 있을 때만 region | 항상 role="region", 라벨이 있으면 aria-label |
| 배경 이미지 | NetworkImage와 cover | CSS 배경 이미지와 cover |
| split에서 media가 없을 때 | 카피를 가운데에 | 카피를 앞쪽 위에 |
