---
title: Frame
description: Figma Frame 1:1 매핑 — Auto Layout · Sizing · Fill · Stroke · Effects 를 한 컴포넌트에서 표현하는 통합 레이아웃 프리미티브
category: layout
platforms: [flutter, web]
related: [card, group, stacks]
tags: [container, layout, primitive, figma]
---

# Frame

`Frame` 은 CoUI 의 통합 레이아웃 프리미티브입니다. Flutter 의 `Container` / `Row` / `Column` / `Wrap` / `Padding` / `Center` / `Align` / `SizedBox` / `Expanded` / `DecoratedBox` / `Opacity` / `Transform` / `ClipRRect` / `Visibility` 와 Web 의 `<div>` 를 한 컴포넌트로 흡수하여, **Figma Frame 의 모든 "Inspect" 슬롯이 1:1 로 코드 prop 에 대응**합니다.

## Live Preview

<LivePreview component="frame" variants="default,column,dashed,elevated" />

## 사용 시기 (When to Use)

**이 컴포넌트를 사용하세요:**
- Figma 디자인을 Flutter / Web 어느 쪽으로든 코드로 옮길 때 — 디자인의 한 Frame 이 그대로 한 `Frame` 으로 매핑됩니다.
- Auto Layout (direction · gap · alignment) 과 Sizing · Fill · Stroke · Effects 를 같이 다뤄야 할 때.
- 단순 `<div>` / `Container` 를 raw 위젯으로 박지 않고 디자인 토큰 경유로 통일하고 싶을 때.

**대신 다른 컴포넌트를 사용하세요:**
- **[Scaffold](/components/scaffold)**: 흐름 레이아웃 한 영역 대신 헤더·푸터·사이드바를 가진 화면 셸이 필요할 때
- **[Card](/components/card)**: 사용자 의미 있는 콘텐츠 슬롯·표면 단위가 필요할 때.
- **[Stacks](/components/stacks)** / Position: 자식들이 z 축으로 겹치거나 절대 좌표로 배치돼야 할 때.

## 기본 사용법 (Basic Usage)

```dart
// 단일 자식 + 겉모습
Frame(
  padding: CoreEdgeInsets.all(CoreSpace.space16),
  backgroundColor: theme.colorScheme.surface,
  borderRadius: CoreBorderRadius.all(CoreRadiusRole.surface),
  child: Text('프레임 안'),
)

// Auto Layout (Row)
Frame(
  direction: CoreFrameDirection.row,
  gap: CoreSpace.space12,
  crossAxisAlignment: CoreCrossAxisAlignment.center,
  children: [icon, label],
)

// Sizing + flex (이 frame 자체가 부모 flex 의 자식)
Frame(
  flex: 1,
  fit: CoreFlexFit.tight,
  child: child,
)

// 효과 (elevation + dashed border)
Frame(
  elevation: CoreFrameElevation.medium,
  borderColor: theme.colorScheme.outline,
  borderWidth: CoreStrokeWidth.stroke2,
  borderStyle: CoreFrameBorderStyle.dashed,
  child: Text('점선 + 그림자'),
)

// SEO 시맨틱 태그 (Web). Flutter 는 Semantics role 로 매핑.
Frame(
  tag: 'main',
  child: pageBody,
)
```

## Props / Parameters

`W` 는 Flutter의 Widget / Web의 Jaspr Component입니다. child / children은 같은 플랫폼 콘텐츠를 조립하는 슬롯입니다.

여기에는 **위젯 생성자 파라미터만** 적습니다. 겉모습의 일부는 `frameStyle`
(`CoreFrameStyle`) 슬롯으로도 들어갑니다 — 아래 레이어 표와 Style 표를 같이 보세요.

### 레이어 1 — 시각 / Figma

| 속성 | 타입 | 설명 |
|------|------|------|
| `direction` | `CoreFrameDirection?` | `row` / `column` / `rowReverse` / `columnReverse` / `wrap`. `null`이면 flex가 아님 (block). row·column 에서 `flex` 를 주지 않은 자식은 줄어들지 않는다 — 좁은 부모에서는 overflow(Flutter 와 동일). `wrap` 은 예외(한 줄 폭 안에서 텍스트가 줄바꿈). |
| `gap` | `double?` | flex 자식 사이 간격 (logical px). |
| `mainAxisAlignment` | `CoreMainAxisAlignment?` | `direction`이 있을 때 주축 정렬. |
| `crossAxisAlignment` | `CoreCrossAxisAlignment?` | 교차축 정렬. |
| `alignment` | `CoreAlignment?` | `direction`이 `null`일 때 9칸 그리드 정렬. |
| `width` / `height` | `double?` | 고정 크기. |
| `minWidth` / `minHeight` / `maxWidth` / `maxHeight` | `double?` | 최소/최대 제약. |
| `flex` | `int?` | 부모 flex 안에서의 grow 가중치. `null` 이면 grow 도 shrink 도 하지 않는다 — 고유 크기를 유지한다. |
| `fit` | `CoreFlexFit?` | `tight` (`flex-basis: 0`) / `loose` (고유 크기). |
| `padding` / `margin` | 플랫폼 타입 | 안쪽 / 바깥 간격. |
| `backgroundColor` | `CoreColor?` | 단색 배경. |
| `gradient` | `CoreGradient?` | 선형/방사형 그라디언트. |
| `backgroundImage` | `CoreImageSource?` | 배경 이미지 (URL / asset). |
| `borderColor` / `borderWidth` / `borderStyle` / `borderRadius` | `CoreColor?` / `double?` / `CoreFrameBorderStyle?` / `CoreBorderRadius?` | 스트로크. `dashed` / `dotted` 지원. |
| `boxShadow` / `innerShadow` | 플랫폼 타입 | 임의 그림자. `boxShadow`가 `elevation`보다 우선. |
| `layerBlur` / `backdropBlur` | `double?` | 자체 / 배경 블러 sigma. |
| `elevation` | `CoreFrameElevation?` | `none` / `soft` / `medium` / `strong` 프리셋. |
| `clipBehavior` | `CoreClipBehavior` | overflow 클립 정책. 기본 `hardEdge`. |
| `opacity` | `double?` | `0..1`. |
| `transform` / `transformAlignment` | 플랫폼 타입 / `CoreAlignment?` | 2D / 3D 변환 + 변환 원점. |
| `visible` | `bool` | `false`면 레이아웃에서 제거. 기본 `true`. |
| `frameStyle` | `CoreFrameStyle?` | 겉모습 · 크기를 바꾸는 값 묶음 (아래 Style 표 참고). |

### 레이어 2 — 동작

| 속성 | 타입 | 설명 |
|------|------|------|
| `onTap` | `void Function()?` | 클릭 / 탭. |
| `onHover` | `CoreValueChanged<bool>?` | 마우스 호버 enter/leave. |
| `onFocus` | `CoreValueChanged<bool>?` | 포커스 진입/이탈. |
| `cursor` | `CoreCursor?` | `pointer` / `text` / `grab` / … 마우스 커서. |

### 레이어 3 — HTML / SEO (Web 우선, Flutter는 Semantics 매핑)

| 속성 | 타입 | 설명 |
|------|------|------|
| `tag` | `String` | Web 에서 쓰는 HTML 태그. 기본 `'div'`. `'main'` / `'nav'` / `'section'` / `'article'` / `'header'` / `'footer'` / `'aside'`로 SEO 구조를 명시합니다. Flutter에서는 가장 가까운 `Semantics` role로 매핑됩니다. |

### 레이어 4 — 접근성 / DOM 메타데이터

| 속성 | 타입 | 설명 |
|------|------|------|
| `a11y` | `CoreFrameA11y?` | `role` (ARIA), `label` (`aria-label` / `Semantics.label`), `id` (Web DOM id), `attributes` (`aria-*` / `data-*`). 일반 케이스는 `null`. |

### 자식

| 속성 | 타입 | 설명 |
|------|------|------|
| `child` | `W?` | 단일 자식. |
| `children` | `List<W>?` | 다중 자식. `child`와 동시에 지정할 수 없습니다. |

## 스타일 시스템 (Style System)

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreFrameStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background colour override. |
| `borderColor` | `CoreColor?` | Border colour override — and the opt-in gate for the border itself. |
| `borderWidth` | `double?` | Border width (logical px), used once [borderColor] turns the border on. `null` means the platform's own thinnest stroke — a hairline on Flutter, the `border` utility's width on the Web. |
| `dashLength` | `double?` | Dash segment length when `borderStyle` is dashed (logical px). `null` → [defaultDashLength]. |
| `dashSpacing` | `double?` | Gap between dash segments (logical px). `null` → [defaultDashSpacing]. |
| `borderStyle` | `CoreFrameBorderStyle?` | Border style — solid / dashed / dotted / none. |
| `borderRadius` | `CoreBorderRadius?` | Border radius. |
| `elevation` | `CoreFrameElevation?` | Shadow elevation preset. |
| `padding` | `CoreEdgeInsets?` | Inner padding. `null` adds no padding at all. |
| `clipBehavior` | `CoreClipBehavior?` | Clip behaviour. |
| `duration` | `Duration?` | Animation duration for changes to the frame's look — its fill, border, corners and shadow. |
| `shadowBaseColor` | `CoreColor?` | Shadow base tint override. `null` defers to [defaultShadowBaseColor]. |

<!-- STYLE_TABLE:END -->

## Figma 매핑

| Figma 슬롯 | Frame prop |
|-----------|--------------|
| Auto Layout direction (Horizontal / Vertical / Wrap) | `direction` |
| Auto Layout spacing | `gap` |
| Auto Layout 정렬 (9-grid) | `mainAxisAlignment` + `crossAxisAlignment` |
| Sizing (Fixed / Hug / Fill) | `width` + `height` + `flex` (Fill 은 `flex: 1, fit: tight`) |
| Padding | `padding` |
| Fill — Solid | `backgroundColor` |
| Fill — Linear / Radial gradient | `gradient` |
| Fill — Image | `backgroundImage` |
| Stroke (color / weight / style / radius) | `borderColor` / `borderWidth` / `borderStyle` / `borderRadius` |
| Effects — Drop shadow | `boxShadow` 또는 `elevation` 프리셋 |
| Effects — Inner shadow | `innerShadow` |
| Effects — Layer blur | `layerBlur` |
| Effects — Background blur | `backdropBlur` |
| Layer opacity | `opacity` |
| Transform (rotate / skew / scale) | `transform` |
| Clip content | `clipBehavior` |

## 동작 스펙 (Behavior)

- visible이 거짓이면 콘텐츠를 렌더하지 않고 레이아웃에서 제거합니다. child와 children은 동시에 지정하지 않으며, direction에 따라 행·열·wrap 또는 단일 콘텐츠를 구성합니다.
- width / height / gap / blur 치수는 논리 px, opacity는 0~1 배율, flex는 grow 가중치입니다. 부모 제약과 자식의 flex 설정이 최종 레이아웃을 정합니다.
- onTap은 포인터 클릭·탭, onHover는 진입·이탈, onFocus는 포커스 변화를 알립니다. Frame이 버튼의 Enter/Space 활성화나 포커스 링을 자동 제공하지는 않습니다. 사용자 액션이면 **[Button](/components/button)** / **[Clickable](/components/clickable)** 을 합성합니다.

## 사용 가이드라인 (Usage Guidelines)

### ✅ Do

<Callout type="tip">

**보더를 그리려면 `borderColor`를 명시적으로 지정**

```dart
Frame(
  borderColor: theme.colorScheme.outline,
  borderWidth: CoreStrokeWidth.stroke1,
  borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  child: content,
)
```

`borderColor`가 `null`이면 `borderWidth`/`borderStyle`을 지정해도 보더가 그려지지 않습니다 — 보더 렌더링은 `borderColor` 존재 여부로 게이트되는 양 플랫폼 공통 opt-in 방식입니다.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`child`와 `children`을 동시에 지정하지 않기**

```dart
// ❌ child 와 children 동시 지정
Frame(
  child: Text('A'),
  children: [Text('A'), Text('B')],
)
```

contract 상 `child`를 지정하면 `children`은 반드시 `null`이어야 합니다(반대도 동일) — 둘 다 지정하면 어느 쪽이 렌더링될지 정의되지 않습니다.

</Callout>

### ✅ Do

<Callout type="tip">

**커스텀 그림자가 필요할 때만 `boxShadow`, 그 외엔 `elevation` 프리셋**

```dart
Frame(
  elevation: CoreFrameElevation.medium,
  child: content,
)
```

`elevation` 프리셋은 4단계(`none`/`soft`/`medium`/`strong`)로 충분한 대부분의 경우에 토큰 경유로 일관된 그림자를 줍니다. 커스텀 그림자가 필요할 때만 `boxShadow`로 넘어가세요.

</Callout>

---

### ❌ Don't

<Callout type="warning">

**`elevation`과 `boxShadow`를 함께 지정해 둘 다 반영될 거라 기대하지 않기**

```dart
// ❌ boxShadow 가 있으면 elevation 은 조용히 무시됨
Frame(
  elevation: CoreFrameElevation.strong,
  boxShadow: CoreShadow.lg,
  child: content,
)
```

`boxShadow`가 non-null이면 `elevation`은 아예 평가되지 않습니다 — 둘 중 하나만 선택해서 사용하세요.

</Callout>

### ✅ Do

<Callout type="tip">

**좁아질 수 있는 자식에는 `flex` 를 준다**

```dart
Frame(
  direction: CoreFrameDirection.row,
  gap: CoreSpace.space8,
  children: [
    Icon(LucideIcons.house),
    Frame(flex: 1, child: Text('길어질 수 있는 라벨')),
  ],
)
```

row·column 에서 `flex` 를 주지 않은 자식은 줄어들지 않습니다 — 부모가 좁으면 줄바꿈되지 않고 overflow 되며, 기본 `clipBehavior` 가 `hardEdge` 라 잘립니다. Flutter `Row` / `Column` 과 같은 동작이고, Web 도 같습니다. 줄어들어야 하는 자식에만 `flex`(기본 `fit: loose`)를 주면 그 자식이 남은 폭 안에서 줄바꿈됩니다.

</Callout>

## 빠른 오버라이드 (Chain)

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class FrameChainExample extends StatelessWidget {
  const FrameChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: const [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('기본 프레임'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: const [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('직접 지정'),
          ],
        ).withStyle(
          const CoreFrameStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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
class FrameChainExample extends StatelessComponent {
  const FrameChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('기본 프레임'),
          ],
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        Frame(
          direction: CoreFrameDirection.row,
          gap: CoreSpace.space12,
          crossAxisAlignment: CoreCrossAxisAlignment.center,
          padding: const CoreEdgeInsets.all(CoreSpace.space16),
          children: [
            Icon(
              LucideIcons.frame,
              iconStyle: CoreIconStyle(size: CoreSpace.space24),
            ),
            Text('직접 지정'),
          ],
        ).withStyle(
          const CoreFrameStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
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

## 접근성 (Accessibility)

### 역할

`a11y` 를 주지 않으면 역할 없는 컨테이너로 자식의 시맨틱을 통과시킵니다.

- **Flutter**: `a11y` 와 `onTap` 이 없으면 시맨틱 래핑도 없습니다. `onTap` 만
  있으면 `Semantics(button: true)`, `a11y` 를 주면 `CoUISemantics` 가
  `CoreSemanticRole` 과 이름을 해석합니다. 명시한 역할은 버튼 역할로 덮이지 않습니다.
- **Web**: 루트는 `tag`(기본 `div`)이고 `a11y.role` / `a11y.label` 은 `role` /
  `aria-label` 로 붙습니다. `a11y.attributes` 는 호출자가 넘긴 속성 뒤에 병합되어
  같은 키를 덮습니다. dashed / dotted 보더의 장식 SVG 는 `aria-hidden="true"` 입니다.

`a11y.id` 와 `a11y.attributes` 는 Web 전용입니다. 랜드마크가 필요하면
`CoreFrameA11y(role: CoreSemanticRole.navigation, label: 'Sidebar')` 처럼 역할과
이름을 함께 주세요. Web 의 `tag: 'nav'` 만으로 Flutter 역할이 생기지는 않습니다.

### 키보드

| 키 | Flutter | Web |
|----|---------|-----|
| `Tab` | `onFocus` 를 준 경우에만 정지점 | `onTap` 을 준 경우에만 정지점 |
| `Enter` / `Space` | 없음 — `onTap` 이 실행되지 않음 | 없음 — `onTap` 이 실행되지 않음 |

포커스 정지점과 키보드 활성화는 별개입니다. `onTap` 만 준 프레임은 Web 에서는
도달하지만 Flutter 에서는 도달하지 않습니다. 활성화할 표면에는 `Button` 을 쓰세요.

### 스크린 리더

이름은 `a11y.label` 에서 옵니다. 생략하면 자식 콘텐츠가 읽힐 뿐 프레임 이름은
없습니다. `status` / `alert` 역할은 Flutter 의 live region 과 Web 의 해당 역할로
통보됩니다. `CoUISemantics` 는 역할의 전제 조건을 만족하지 못하면 역할을 떨어뜨립니다.

### 포커스 관리

진입·이탈 시 포커스 이동도 트랩도 없습니다. 포커스 표시를 직접 그리지 않으므로
Flutter 의 `Focus` 는 시각 표시가 없고 Web 은 브라우저 기본 표시에 의존합니다.

### 알려진 제약

- **클릭 가능한 프레임에 키보드 활성화가 없습니다.** `onTap` 은 포인터 경로만
  배선합니다. Web 은 호출부 이벤트로 보완할 수 있지만 공통 경로는 `Button` 입니다.
- **`tag` 는 Web 전용입니다.** Flutter 에서 같은 의미가 필요하면 `a11y` 도 채우세요.
- **랜드마크에는 이름을 주세요.** Flutter 에서 `.main` / `.navigation` / `.region` /
  `.contentInfo` 는 이름이 없으면 역할이 붙지 않습니다.
- **상태를 전제로 하는 역할은 전용 컴포넌트를 쓰세요.** Frame 은 `selected` /
  `checked` / `value` 를 `CoUISemantics` 에 넘기지 않아 `.tab` / `.menuItemCheckbox` /
  `.menuItemRadio` / `.progressBar` 의 전제 조건을 채우지 못합니다.
- **최소 히트 영역 보정이 없습니다.** 렌더 크기가 히트 영역이므로 `minWidth` /
  `minHeight` 로 최소 크기를 확보하거나 전용 컨트롤을 쓰세요.

## 크로스 플랫폼 차이점 (Platform Differences)

| 항목 | Flutter | Web |
|------|---------|-----|
| 배치 | Row / Column / Wrap · 부모 constraints | direction 기반 DOM flex / block |
| visible=false | SizedBox.shrink로 콘텐츠 생략 | display:none의 빈 태그 |
| blur | ImageFiltered / BackdropFilter | CSS filter / backdrop-filter |
| 메타데이터 | a11y의 CoUISemantics | tag·DOM id·role / aria 속성 |
| onTap 포커스 | 포인터 GestureDetector | click과 tabindex. Enter/Space 핸들러는 없음 |

## 관련 컴포넌트 (Related Components)

- **[Card](/components/card)**: header / body / footer 슬롯이 있는 의미 단위 카드
- **[스택 레이아웃](/components/stack-layout)**: 자식이 z축으로 겹치거나 절대 좌표로 배치돼야 할 때
