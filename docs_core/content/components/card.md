---
title: Card
description: 관련 있는 정보를 하나의 면으로 묶는 컨테이너입니다. media · header · body · footer · overlay 슬롯이 있고, 전체를 누를 수 있게도 만듭니다.
category: layout
platforms: [flutter, web]
related: [accordion, badge]
tags: [container, content, surface]
template: v2
source: layout/card
---

# Card

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 카드를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="card" />

<a id="구조-anatomy"></a>

## 구조

부분 이름은 위젯 슬롯 이름과 같고, Figma [`❖ Card`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0?node-id=2467-147191) 레이어 이름과도 맞습니다. 모든 슬롯은 선택입니다.

<Anatomy demo="card/anatomy">
<AnatomyItem part="container" name="Container">

카드의 면. 모서리는 16이고, 채움과 테두리는 variant가 정합니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=media]" side="left" name="media">

위쪽의 그림 자리. 안쪽 여백 없이 카드 가장자리까지 채웁니다. `media`가 있으면 카드는 기본으로 모서리 밖을 잘라 냅니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=overlay]" side="right" name="overlay">

`media` 위에 얹는 자리. 여백 없이 붙습니다. `media`가 없으면 그리지 않습니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=header]" side="right" name="header">

머리. 기본 글자는 `titleMedium`(18 · 600) · `onSurface`입니다. 아래 본문과의 사이는 8입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=body]" side="right" name="body">

본문. 기본 글자는 `bodyMedium` · `onSurface`입니다.

</AnatomyItem>
<AnatomyItem select="[data-docs-part=footer]" side="right" name="footer">

아래 자리. 본문과의 사이는 12입니다. 글자 기본값은 본문과 같습니다.

</AnatomyItem>
</Anatomy>

`header` · `body` · `footer`는 좌우 24 · 위아래 20의 안쪽 여백 안에 놓입니다. 슬롯 대신 `child`를 주면 슬롯은 모두 그리지 않고, `child`를 같은 안쪽 여백 안에 그립니다.

### 미디어 카드 (이미지 + 콘텐츠)

<Preview demo="card/media" />

```dart
Card(
  variant: CoreCardVariant.outlined,
  cardStyle: CoreCardStyle(sizing: CoreCardSizing.expand),
  media: CoverImage(), // 그림을 그리는 내 위젯 · 컴포넌트
  overlay: Badge(
    variant: CoreBadgeVariant.filled,
    tone: CoreBadgeTone.primary,
    child: Text('NEW'),
  ),
  header: Text('프로젝트 요약'),
  body: Text('이번 주 진행 상황을 확인해 보세요.'),
)
```

`CoverImage`는 CoUI에 없는 이름입니다. 그림을 그리는 코드를 직접 넣습니다. `overlay`는 여백 없이 읽기 시작 쪽 위에 붙으므로, 모서리에서 띄우려면 여백을 둔 상자로 감쌉니다. 위 그림은 8만큼 띄운 모습입니다.

<a id="변형-variants"></a>

## Variant

`variant`는 채움과 테두리를 정합니다. 기본은 `filled`입니다.

<a id="filled-기본"></a>

<VariantRow name="filled" component="card" props="variant=filled" label="filled">

`surfaceContainer`로 채우고 테두리는 두지 않습니다. 카드의 경계는 바탕과의 색 차이뿐이라, 같은 색 면 위에서는 경계가 보이지 않습니다.

</VariantRow>

<a id="outlined"></a>

<VariantRow name="outlined" component="card" props="variant=outlined" label="outlined">

`surface`로 채우고 `outlineVariant` 테두리 1을 둡니다. 색 차이에 기대지 않고 경계가 보입니다.

</VariantRow>

### 의미 체인

`Card`의 `.outline`은 `variant: .outlined`를 선택합니다. 테마가 윤곽선과 배경을 결정합니다. 배경만 바꾸려면 `Card(body: const Text('요약')).outline.backgroundColor(.surfaceContainer)`처럼 씁니다. 상수 스타일에서는 `const CoreCardStyle(backgroundColor: .surfaceContainer)`로 같은 색을 지정합니다.

헤더·본문·푸터 또는 단일 자식의 안쪽 여백은 `.contentPadding(...)`으로 정합니다. 미디어 슬롯은 카드 가장자리까지 채웁니다.

```dart
Card(body: const Text('요약')).outline
    .borderColor(.outlineVariant)
    .contentPadding(.all(CoreSpace.space16))
```

<a id="elevation-단계"></a>

## 그림자

`cardStyle.elevation`은 그림자의 단계입니다. 기본은 `none`이고 `soft` · `medium` · `strong`이 있습니다.

<Preview demo="card/elevation" />

```dart
Card(
  cardStyle: CoreCardStyle(elevation: CoreCardElevation.medium),
  body: Text('중간 그림자'),
)
```

단계에 없는 그림자는 `cardStyle.boxShadow`로 직접 줍니다. 빈 목록(`boxShadow: []`)은 `elevation`의 그림자와 표면 스타일이 두는 옅은 그림자까지 끕니다.

## 상태

| 상태 | `onTap` 없음 | `onTap` 있음 |
| --- | --- | --- |
| 기본 | 면만 그립니다. | 같은 모양이고 누를 수 있습니다. |
| 마우스를 올림 | 변화 없음 | `hoverElevation`(기본 `medium`) 그림자가 나타납니다. 원래 그림자가 있을 때의 모습은 [플랫폼마다 다릅니다](#플랫폼-차이). |
| 키보드 포커스 | 포커스를 받지 않습니다. | 포커스 링을 그립니다. 기본 링은 곧은 변에서 카드와 2 틈을 두며, 틈은 투명해 바탕이 보입니다. 링의 모서리는 카드의 `borderRadius`를 따르지 않아 모서리에서는 틈이 더 넓습니다. 맞추려면 `cardStyle.clickableStyle`의 `borderRadius`에 카드와 같은 값을 줍니다. |
| 누르는 중 | — | 크기가 줄지 않습니다. |

비활성이나 선택 상태를 만드는 속성은 없습니다. `onTap`이 `null`이면 보여 주기만 하는 카드이고, 안에 넣은 버튼 · 링크의 동작은 그 위젯이 맡습니다.

<a id="동작-스펙-behavior"></a>

### 인터랙션

`onTap`을 주면 카드 전체가 누르는 영역이 되고, 마우스를 올리면 커서가 손 모양으로 바뀝니다. Web에서는 카드 안의 `Button`을 눌러도 카드의 `onTap`이 함께 불립니다. 누르는 카드 안에는 버튼이나 입력칸처럼 포커스를 받는 요소를 두지 마세요.

<Preview component="card" props="variant=outlined;onTap;footer" label="누를 수 있는 카드" />

### 애니메이션

- 채움 · 테두리 · 모서리가 바뀔 때(테마를 바꾸거나 스타일을 바꿀 때) `cardStyle.chromeAnimationDuration`(기본 200ms)으로 전환합니다. 안쪽 여백은 Flutter의 `child` 카드에서만 전환합니다.
- 마우스를 올릴 때의 그림자는 `cardStyle.hoverShadowAnimationDuration`(기본 200ms)으로 전환합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>
<a id="dont"></a>

## 사용 가이드

프로필 · 상품 · 게시물처럼 하나의 대상에 관한 정보를 한 덩어리로 묶을 때 씁니다.

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 슬롯 없이 면의 겉모습만 필요할 때 | [OutlinedContainer](/components/outlined-container) |
| 지표 하나와 변화량을 보여 줄 때 | [Stat](/components/stat) |
| 페이지의 첫머리를 만들 때 | [Hero](/blocks/hero) |
| 섹션을 접고 펼 때 | [Accordion](/components/accordion) |
| 행과 열의 데이터를 보여 줄 때 | [Table](/components/table) |
| 화면 위에 띄워 응답을 받아야 할 때 | [Dialog](/components/dialog) |

### 카드 전체를 누르게 할 때

카드 전체가 눌려야 하면 안쪽 위젯에 핸들러를 붙이지 말고 `Card.onTap`을 씁니다. 누르는 영역, 커서, 포커스 링, 키보드 동작이 카드 전체에 함께 붙습니다.

<Split>

<Code language="dart" title="이렇게 하세요">
// 카드 전체가 눌리고, 마우스를 올리면 그림자가 나타납니다.
Card(
  onTap: openProject,
  header: Text('프로젝트 요약'),
  body: Text('이번 주 진행 상황'),
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 누르는 것이 겹칩니다. Web은 버튼을 눌러도 openProject가 함께 불립니다.
Card(
  onTap: openProject,
  header: Text('프로젝트 요약'),
  footer: Button(onPressed: share, child: Text('공유')),
)
</Code>

</Split>

값이 아직 없을 때를 대신 그려 주는 슬롯은 없습니다. 필요하면 슬롯에 [Skeleton](/components/skeleton)을 직접 넣습니다(`header: isLoading ? Skeleton(…) : Text(title)`).

## 배치

`cardStyle.sizing`이 카드의 크기를 정합니다.

<Preview demo="card/sizing" />

| `sizing` | 크기 |
| --- | --- |
| `intrinsic`(기본) | 내용이 차지하는 크기. 부모가 허락하는 폭은 넘지 않습니다. |
| `expand` | 부모의 폭을 채웁니다. |
| `fixed` | `width` · `height`로 정한 크기입니다. |

`width`와 `height`는 `sizing`이 `fixed`일 때만 씁니다. `sizing` 없이 `width`만 주면 무시합니다.

표와 다르게 보이는 경우가 있습니다.

- Flutter에서 부모가 폭을 강제하면(늘려 맞추는 `Column`, 세로 `ListView` 등) `intrinsic` 카드도 부모의 폭을 채웁니다.
- Flutter의 `expand`는 슬롯으로 만든 카드의 폭을 채웁니다. `child`로 만든 카드는 부모가 폭을 강제하지 않으면 `child`의 폭을 따릅니다.
- Web의 `onTap` 카드는 `expand`를 줘도 블록 부모의 폭을 채우지 않습니다. `classes: 'w-full'`을 함께 줍니다. `onTap` 카드의 `classes`는 카드를 감싸는 바깥 요소에 붙습니다.

<Note>

Flutter의 `intrinsic` 카드는 부모가 폭을 정해 주지 않으면 내용의 폭을 먼저 잽니다. 이때 슬롯에 `LayoutBuilder`처럼 자기 폭을 미리 알려 주지 못하는 위젯이 있으면 레이아웃 오류가 납니다. `expand`나 `fixed`를 쓰거나 폭을 정해 주세요.

</Note>

<a id="스타일-시스템-cardstyle"></a>
<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

색 · 크기 · 간격 같은 겉모습의 값은 `cardStyle`(`CoreCardStyle`)로 정합니다. `variant`는 기본 모양을 고릅니다. Web은 `classes` · `css`로도 겉모습을 바꿀 수 있습니다. `onTap` 카드에서는 둘 다 카드를 감싸는 바깥 요소에 붙으므로, 카드 면의 모양은 `cardStyle`로 바꿉니다.

```dart
Card(
  variant: CoreCardVariant.outlined,
  cardStyle: CoreCardStyle(
    padding: CoreEdgeInsets.all(CoreSpace.space24),
    borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    elevation: CoreCardElevation.soft,
    sizing: CoreCardSizing.fixed,
    width: CoreLayout.layout320,
  ),
  header: Text('제목'),
  body: Text('본문'),
)
```

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤로 갈수록 우선합니다. 어느 단계든 필드 일부만 채울 수 있고, `null`인 필드는 앞 단계의 값을 씁니다.

```text
디자인 시스템 기본값
  → CoreCardTheme.style                    // 앱 전체
  → CoreCardTheme.variantStyles[variant]   // variant마다
  → cardStyle                              // 카드 하나
```

### 테마 적용

```dart
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    card: CoreCardTheme(
      style: CoreCardStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        padding: CoreEdgeInsets.all(CoreSpace.space20),
      ),
      variantStyles: {
        CoreCardVariant.filled: CoreCardStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
        ),
      },
    ),
  ),
)
```

<a id="유리-테마-안의-불투명-카드-material-override"></a>

### 유리 테마 안의 불투명 카드

`liquidGlass` 프리셋에서는 모든 면이 같은 유리 재질을 받습니다. 목록 속 카드처럼 내용이 많은 면을 불투명하게 두려면 프리셋 전체가 아니라 그 카드의 재질만 `cardStyle.surfaceStyle`로 정합니다. `defaultStyle`은 불투명한 기본 재질이라 반투명 채움, 배경 흐림, 가장자리 빛띠, 굴절(앱이 켠 서리와 몸체 음영 포함)이 모두 빠지고 평소의 외곽선은 남습니다. 두 플랫폼에서 같은 코드입니다.

```dart
Card(
  variant: CoreCardVariant.outlined,
  cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
  header: Text('주문 내역'),
  body: Text('불투명한 카드'),
)
```

- 재질만 바뀝니다. 색 · 글자 · 모서리와 선 두께 · 밀도는 둘러싼 테마 그대로입니다.
- `null`(기본)은 둘러싼 재질을 씁니다. 모든 카드에 적용하려면 `CoreCardTheme.style`에 같은 값을 두고, 한 장만 바꾸려면 그 카드의 `cardStyle`을 씁니다.
- 반대로 `surfaceStyle: .liquidGlass`는 불투명한 테마에서 카드 한 장만 유리로 만듭니다.
- Flutter에서 `surfaceOpacity` · `surfaceBlur`는 정해진 재질 안에서 채움과 흐림을 조절합니다. 재질을 없애지는 않습니다.
- Web에서 유리 재질을 받는 카드는 토큰 색 채움의 투명도를 재질이 정하므로 `surfaceOpacity`가 적용되지 않습니다. 0보다 큰 `surfaceBlur`를 주면 흐림만 바뀌지 않고, 재질의 흐림 · 채도 · 밝기 조정이 그 흐림 하나로 바뀝니다.
- 유리 면 안에 놓인 유리 카드는 배경 흐림을 다시 걸지 않습니다. `surfaceBlur`를 직접 주면 그 흐림을 겁니다. Web은 안쪽 카드와 바깥 면 가운데 하나라도 `surfaceStyle`로 유리를 따로 정했으면 흐림을 다시 겁니다.
- 투명도 줄이기와 고대비 설정은 이 덮어쓰기에도 적용됩니다.
- 카드 안의 버튼 · 입력은 자기 재질을 따로 정하지 않으면 둘러싼 테마의 재질을 씁니다. 불투명 카드 안에서도 유리일 수 있습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

만든 `Card`에 스타일을 이어 붙입니다.

| 체인 | 바꾸는 값 |
| --- | --- |
| `withStyle(CoreCardStyle(…))` | 넘긴 필드. 겹치면 뒤에 붙인 값이 이깁니다. |
| `.backgroundColor(…)` · `.borderColor(…)` · `.borderWidth(…)` · `.contentPadding(…)` | `backgroundColor` · `borderColor` · `borderWidth` · `padding` |
| `.radius0` … `.radius9999` | `borderRadius`. 이름이 `CoreRadius` 상수와 같습니다. |
| `.primary` · `.secondary` · `.tertiary` · `.surface` · `.surfaceContainer` · `.error` · `.success` · `.warning` · `.info` · `.transparent` | `backgroundColor` |
| `.outline` | `variant`를 `outlined`로 바꿉니다([의미 체인](#의미-체인)). |

<Note>

`filled` 카드의 테두리 색은 투명입니다. `.borderWidth(…)`만 붙이면 테두리가 보이지 않으니 `.borderColor(…)`를 함께 정합니다.

</Note>

<Preview component="card" example="chain" />

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class CardChainExample extends StatelessWidget {
  const CardChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Card(
          header: const Text('프로젝트 요약'),
          body: const Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: const Text('자세히 보기'),
          ),
        ).withStyle(
          const CoreCardStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            backgroundColor: .surfaceContainerHighest,
            borderColor: .tertiary,
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
class CardChainExample extends StatelessComponent {
  const CardChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
          ),
        ).radius16.backgroundColor(.primary),
        const Gap.space12(),
        // 여러 속성을 한 스타일로 지정합니다.
        Card(
          header: Text('프로젝트 요약'),
          body: Text('이번 주 진행 상황을 확인해 보세요.'),
          footer: Button(
            variant: CoreButtonVariant.primary,
            onPressed: () {},
            child: Text('자세히 보기'),
          ),
        ).withStyle(
          const CoreCardStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            backgroundColor: .surfaceContainerHighest,
            borderColor: .tertiary,
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

### 역할

| `onTap` | Flutter | Jaspr Web |
| --- | --- | --- |
| 없음 | 역할이 없습니다. | 역할 없는 `<div>`입니다. |
| 있음 | 버튼(`Semantics(button: true, enabled: true)`) | `role="button"` · `tabindex="0"` |

Web은 `attributes`로 넘긴 값이 기본값보다 우선하므로 `Card(attributes: {'role': 'article'})`처럼 역할을 바꿀 수 있습니다. Flutter에서는 `Semantics`로 감싸 의미를 더합니다. 감싸도 `onTap` 카드의 버튼 역할은 없어지지 않습니다. `role` 파라미터(`CoreSurfaceRole`)는 접근성 역할이 아니라 면이 콘텐츠 층인지 기능 층인지를 정합니다.

### 키보드

`onTap`이 없는 카드는 키보드를 받지 않습니다. 아래는 `onTap`이 있을 때입니다.

| 키 | 동작 |
| --- | --- |
| `Tab` | 카드에 한 번 멈춥니다. |
| `Enter` · `Space` | `onTap`을 부릅니다. |
| 화살표 | 처리하지 않습니다. |

카드 안의 요소에 포커스가 있을 때는 요소와 플랫폼에 따라 다릅니다.

| `onTap` 카드 안에서 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Button`을 누르거나 `Enter` · `Space` | 버튼만 실행합니다. | 버튼과 카드의 `onTap`이 모두 불립니다. |
| 글 입력칸에서 `Enter` · `Space` | 카드의 `onTap`이 불립니다. | `onTap`을 부르지 않습니다. |

### 스크린 리더

- 이름을 따로 받는 파라미터는 없습니다. `onTap` 카드는 슬롯에 넣은 글자가 이어져 이름이 됩니다. `overlay`의 글자도 들어갑니다. `media`의 대체 텍스트는 Web에서는 이름에 들어가고, Flutter의 `Image(semanticLabel: …)`은 이름에 합쳐지지 않고 따로 읽힙니다. 본문이 긴 카드에 `onTap`을 주면 버튼의 이름도 그만큼 길어집니다.
- 상태가 바뀌었다고 따로 알리지 않습니다.
- `media`의 대체 텍스트는 카드가 붙이지 않습니다. 넣은 위젯 그대로입니다.

### 포커스 관리

- 카드는 포커스를 옮기거나 가두지 않습니다.
- `onTap` 카드 안에 포커스를 받는 요소가 있으면 Tab은 카드에 한 번, 요소마다 한 번씩 멈춥니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| 공통 | `onTap` 카드 안에 버튼 · 링크 · 입력칸을 두면 컨트롤이 겹칩니다. Web에서는 `role="button"` 안에 다른 컨트롤이 들어가고, 안의 버튼을 눌러도 카드의 `onTap`이 함께 불립니다. Flutter에서는 입력칸의 `Enter` · `Space`가 카드의 `onTap`을 부릅니다. 누르는 카드 안에는 포커스를 받는 요소를 두지 마세요. |
| 공통 | `borderRadius`는 네 모서리를 화면의 왼쪽 · 오른쪽으로 정합니다. 모서리마다 다른 값은 오른쪽에서 왼쪽으로 읽는 언어에서도 뒤집히지 않으니, 그런 로케일에서는 좌우를 바꾼 값을 직접 넘깁니다. 기본값은 네 모서리가 같아 해당하지 않습니다. |
| Jaspr Web | `filled` 카드는 테두리 없이 색 차이로만 구분되어, 색 강제 모드에서는 경계가 보이지 않을 수 있습니다. 문서 전체에 `liquidGlass` · `neumorphism` 스타일을 적용하면 두께 1의 테두리를 다시 그리지만, `cardStyle.surfaceStyle`을 따로 준 카드에는 그리지 않습니다. 경계가 필요하면 `outlined`를 쓰세요. |
| Jaspr Web | 포커스 링의 `ringOpacity`를 쓰지 않습니다. 투명한 링이 필요하면 `focusOutlineStyle.borderColor`의 색에 투명도를 담습니다. |

> 동작 줄이기 · 고대비 · 색 강제 모드 · 최소 터치 영역처럼 모든 컴포넌트에 걸리는 내용은 [접근성](/accessibility) 페이지가 다룹니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `overlay`의 위치 | `media`의 읽기 시작 쪽 위에 제 크기로 놓입니다. | `media` 전체를 덮는 상자 안에 놓입니다. |
| `overlayInset` | 쓰지 않습니다. | 상자를 가장자리에서 그만큼 안으로 줄입니다. |
| `elevation`과 비어 있지 않은 `boxShadow`를 함께 줄 때 | 두 그림자를 겹쳐 그립니다. | `boxShadow`만 그립니다. |
| 마우스를 올렸을 때의 그림자 | 원래 그림자 위에 겹쳐 그립니다. | 원래 그림자 대신 그립니다. `boxShadow`를 주면(`[]` 포함) 바뀌지 않습니다. |
| `onTap` 카드 안의 `Button`을 누를 때 | 버튼만 실행합니다. | 카드의 `onTap`도 부릅니다. |
| `onTap` 카드의 `expand` | 슬롯 카드는 부모의 폭을 채웁니다. `child` 카드는 부모가 폭을 강제하지 않으면 `child`의 폭을 따릅니다. | 블록 부모에서는 `classes: 'w-full'`도 필요합니다. |
| `media`가 있을 때의 `clipBehavior: .none` | 그래도 모서리 밖을 잘라 냅니다. | 자르지 않습니다. |
| 안쪽 여백의 전환 | `child` 카드만 전환합니다. | 전환하지 않습니다. |
| 서브트리 단위 재질 | `SurfaceTheme` | 없습니다. 카드마다 `surfaceStyle`을 정합니다. |
| 목록 형태의 자식 | `child` 하나 | `child` 말고 `children: List<Component>`도 받습니다. 둘 다 주면 `children`을 씁니다. |
| 웹 전용 속성 | — | `children` · `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

`W`는 Flutter에서는 `Widget`, Jaspr Web에서는 `Component`입니다.

### 생성자

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreCardVariant` | `filled` | `filled` · `outlined` |
| `media` | `W?` | `null` | 위쪽의 그림 자리 |
| `header` | `W?` | `null` | 머리 |
| `body` | `W?` | `null` | 본문 |
| `footer` | `W?` | `null` | 아래 자리 |
| `overlay` | `W?` | `null` | `media` 위에 얹는 자리 |
| `child` | `W?` | `null` | 슬롯 대신 그릴 내용 |
| `onTap` | `VoidCallback?` | `null` | 주면 카드 전체가 눌립니다. |
| `role` | `CoreSurfaceRole` | `content` | 면의 층(콘텐츠 · 기능). 접근성 역할이 아닙니다. |
| `cardStyle` | `CoreCardStyle?` | `null` | 겉모습 · 크기 |

같은 호출이 두 플랫폼에서 동작해야 하면 여러 자식은 `child` 하나로 묶으세요. `children`은 Web에만 있습니다.

### 그 밖의 멤버

- `withStyle(CoreCardStyle patch)` — `cardStyle`에 `patch`를 합친 사본을 돌려줍니다.
- `copyWith(…)` — 바꾼 값으로 사본을 만듭니다.
- Web은 `id`(HTML id) · `classes` · `css` · `attributes` · `eventHandlers` 같은 HTML 속성도 받습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreCardStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `surfaceStyle` | `CoreSurfaceStyleId?` | Material override for this card; null inherits the surrounding material. |
| `padding` | `CoreEdgeInsets?` | Content padding override. |
| `borderRadius` | `CoreBorderRadius?` | Border radius override. |
| `borderWidth` | `double?` | Border width override (logical px, pre-scaling). |
| `backgroundColor` | `CoreColor?` | Background colour override. |
| `borderColor` | `CoreColor?` | Border colour override. |
| `boxShadow` | `List<CoreShadowLayer>?` | Box shadow override. Takes precedence over [elevation]-derived shadow when set. |
| `headerBodyGapStyle` | `CoreGapStyle?` | Gap between the header and body slots, passed to the `Gap` that separates them. `null` defers to [defaultHeaderBodyGapStyle]. |
| `bodyFooterGapStyle` | `CoreGapStyle?` | Gap between the body and footer slots, passed to the `Gap` that separates them. `null` defers to [defaultBodyFooterGapStyle]. |
| `chromeAnimationDuration` | `Duration?` | Duration of the animation when the card's background, border, borderRadius or padding changes (on a theme change or a per-instance style swap). `null` defers to [defaultChromeAnimationDuration]. |
| `hoverShadowAnimationDuration` | `Duration?` | Hover-shadow animation duration override (AnimatedContainer wrapping the interactive surface). `null` defers to [defaultHoverShadowAnimationDuration]. |
| `width` | `double?` | Fixed width override (logical px). Honoured when [sizing] is [CoreCardSizing.fixed]. |
| `height` | `double?` | Fixed height override (logical px). Honoured when [sizing] is [CoreCardSizing.fixed]. |
| `sizing` | `CoreCardSizing?` | How the card is sized: `intrinsic` (its content's size), `expand` (fills the available width) or `fixed` ([width] / [height]). |
| `elevation` | `CoreCardElevation?` | Shadow elevation level (none / soft / medium / strong). When [boxShadow] is also set, [boxShadow] wins. |
| `clipBehavior` | `CoreClipMode?` | Clip behaviour override. |
| `bodyTextStyle` | `CoreTextStyle?` | Body text style override (typography role + colour + weight in one `CoreTextStyle`). `null` defers to [defaultBodyTextStyle]. |
| `headerTextStyle` | `CoreTextStyle?` | Header text style override (typography role + colour + weight). `null` defers to [defaultHeaderTextStyle]. |
| `overlayInset` | `double?` | Overlay inset (logical px) — applied to the absolutely-positioned overlay slot. `null` defers to [defaultOverlayInset]. |
| `shadowBaseColor` | `CoreColor?` | Shadow base colour override. `null` defers to [defaultShadowBaseColor]. |
| `hoverElevation` | `CoreCardElevation?` | Hover elevation override (applied when an interactive card is hovered). `null` defers to [defaultHoverElevation]. |
| `surfaceBlur` | `double?` | Backdrop blur sigma (logical px) for a glassmorphism surface — forwarded to the `OutlinedContainer` surface (Flutter `SurfaceBlur` / Web `backdrop-filter: blur`). `null`/`0` = no blur. Opt-in: the design-system default cards are opaque. |
| `surfaceOpacity` | `double?` | Surface fill opacity (0.0–1.0) for a glassmorphism surface — lets the blurred backdrop show through the fill. `null` = fully opaque fill. |
| `clickableStyle` | `CoreClickableStyle?` | Style for the `Clickable` of a tappable card (`onTap != null`) — press scale, durations, focus ring, disabled opacity. Laid over [defaultClickableStyle] (which pins `pressedScale: 1`) and passed to the `Clickable` as is; it fills the unset fields with its own defaults. |

### `CoreCardStyle` 변형별 기본값 (`CoreCardVariantStyle`)

| 필드 | `outlined` | `filled` |
|------|------|------|
| `backgroundColor` | surface (fallback: surfaceContainerLowest) | surfaceContainer (fallback: surface) |
| `borderWidth` | stroke1 | 0 |
| `borderColor` | outlineVariant (fallback: outline) | transparent |

<!-- STYLE_TABLE:END -->

<Note>

표의 설명과 지금 동작이 다른 곳이 있습니다.

- Flutter는 `overlayInset`을 쓰지 않습니다.
- 비어 있지 않은 `boxShadow`를 `elevation`과 함께 주면 Flutter는 두 그림자를 모두 그립니다.
- `surfaceBlur` · `surfaceOpacity`를 주지 않으면 흐림이나 불투명도를 새로 정하지 않고, 카드에 적용되는 재질을 따릅니다. `surfaceStyle`을 주면 그 재질이고, 주지 않으면 둘러싼 재질입니다.
- `chromeAnimationDuration`은 슬롯의 안쪽 여백을 전환하지 않습니다. Web은 어느 안쪽 여백도 전환하지 않습니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="card/related-accordion" title="Accordion">

섹션을 접고 펼쳐 보여 줍니다.

</Card>
<Card demo="card/related-badge" title="Badge">

카드 안의 상태나 갈래를 짧게 표시합니다.

</Card>
</Cards>
