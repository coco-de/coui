---
title: 레이아웃
description: padding, gap, margin은 CoreSpace 사다리만 씁니다. 배치는 Flutter와 Web에서 같게 그려지는 레이아웃 컴포넌트로 조합합니다.
design: true
---

# 레이아웃

## 간격 사다리

값은 logical px입니다. Web에서는 CoreSpace.scale.spaceN 키(예: p-space16)로 같은 단계를 참조합니다.

<FoundationVisual kind="spacing" />

| 구간 | 토큰 | 단위 |
| --- | --- | --- |
| Small | `space0 ~ space18` | 2px |
| Medium | `space20 ~ space32` | 4px |
| Large | `space36 ~ space64` | 4px |
| Extra large | `space72 ~ space256` | 8px |

<DesignNote>

밀도는 4px보다 큰 간격을 4px 격자에서 한 칸씩 옮깁니다(compact는 아래, spacious는 위). 격자 밖 단계(6, 10, 14, 18)는 같은 방향의 다음 칸으로 가서 space18은 compact에서 16, spacious에서 20입니다. 목록에 없는 값은 가장 가까운 단계를 고르거나 토큰 확장을 요청합니다.

</DesignNote>

<DesignNote title="간격은 부모가 정합니다">

자식이 margin으로 자기 바깥 여백을 정하지 않고, 부모의 gap과 padding으로 해결합니다. 간격이면 space, 요소의 높이, 너비, 아이콘 치수면 size(4~128px, 24단계)를 씁니다.

</DesignNote>

## Gap과 spacing

두 형제 사이 한 번은 Gap, 여러 자식 사이 균등 간격은 spacing을 씁니다. Web에는 Column이 없어 flex 컨테이너 안에 Gap을 넣고, 균등 간격은 컨테이너의 gap-space12 클래스로 씁니다.

<Code language="dart" title="Flutter">
// 두 형제 사이 한 번
Column(children: [Header(), const Gap.space16(), Body()])
// 여러 자식 균등
Column(spacing: CoreSpace.space12, children: [...])
</Code>

## 레이아웃 컴포넌트

raw Stack, Positioned나 네이티브 HTML 대신 이 컴포넌트를 조합합니다.

| 컴포넌트 | 용도 |
| --- | --- |
| [`Stacks / Position`](/components/stack-layout) | 겹침과 절대 좌표 배치 |
| [`Gap`](/components/gap) | 두 형제 사이의 1회성 간격 |
| [`ResponsiveGrid`](/components/responsive-grid) | 열 수가 자동으로 조절되는 그리드 |
| [`ResponsiveContainer`](/components/responsive-container) | breakpoint 기반 반응형 컨테이너 |
| [`Resizable`](/components/resizable) | 드래그로 크기를 조절하는 패널 |
| [`Basic`](/components/basic) | leading, title, subtitle, trailing 정형 행 |

## 브레이크포인트

5단계입니다. 타이포그래피 단계는 이 중 768(Tablet)과 1024(Desktop)에서 바뀝니다.

| 이름 | 최소 폭 |
| --- | --- |
| `sm` | `640px` |
| `md` | `768px` |
| `lg` | `1024px` |
| `xl` | `1280px` |
| `2xl` | `1536px` |

<DesignNote title="열 수와 최대 너비" variant="outlined">

기본 ResponsiveGrid는 md 미만에서 1열, lg 미만에서 2열, lg부터 지정한 열 수를 사용합니다. ResponsiveContainer의 기본 최대 너비는 xl(1280px)이며 화면 폭에 따라 다른 값을 지정할 수 있습니다.

</DesignNote>

## 컨트롤 높이

버튼, 입력 같은 행 정렬 컨트롤의 높이입니다. 밀도에 따라 값이 바뀌고, 기본은 md입니다.

| 토큰 | standard | compact | spacious |
| --- | --- | --- | --- |
| `control-size/xs` | `24` | `24` | `32` |
| `control-size/sm` | `32` | `32` | `40` |
| `control-size/md` | `40` | `32` | `48` |
| `control-size/lg` | `48` | `40` | `56` |
| `control-size/xl` | `56` | `48` | `64` |
| `control-size/xl2` | `64` | `56` | `64` |

<DesignNote>

터치가 주된 화면에서는 그리는 크기로 a11y/touch-target(48)을 권장하고, 포인터로 누르는 영역은 최소 24×24(a11y/pointer-target-min)를 보장합니다.

</DesignNote>

## 접히는 화면

`FoldScope.of(context)`가 접힘선이 나눈 화면을 읽습니다. Flutter와 Web이 같은 규칙으로 판정합니다.

| 값 | 뜻 |
| --- | --- |
| `segments` | 왼쪽부터, 위부터 놓인 화면 조각. 나뉘지 않으면 화면 전체 하나, 재지 못했으면 비어 있습니다. 둘 이상이면 `isSplit`이 참입니다 |
| `kind` | `CoreFoldableKind`의 `flip`(Galaxy Z Flip 류) 또는 `fold`(Galaxy Z Fold 류). 기기를 돌려도 같고, 접힘이 없으면 `null` |
| `posture` | `flat`(펼침), `tabletop`(가로 접힘선으로 반쯤 접힘), `book`(세로 접힘선으로 반쯤 접힘). 알 수 없으면 `null` |

화면은 힌지가 가리거나 반쯤 접혔을 때만 나뉘고, 이음매 없는 화면을 펴 두면 한 장입니다. 나뉜 화면에서 패널은 한 조각 안에 열립니다.

| 패널 | 열리는 조각 |
| --- | --- |
| `Dialog` | 글이 시작하는 쪽 위 조각 |
| `Drawer`, 토스트 스택 | 붙는 가장자리나 모서리가 놓인 조각. 그 자리가 접힘선이면 위쪽, 그다음 글이 시작하는 쪽 |
| Popover, 메뉴, Tooltip, HoverCard | 트리거의 가운데가 놓인 조각 |

앱 틀 안쪽에 둔 `ToastLayer`나 한 구획을 채운 내비게이터처럼 화면 일부만 덮는 층에서도 같습니다. 자리는 그 층의 것이고, 패널은 조각 가운데 그 층이 덮는 부분에 머뭅니다. 앱이 직접 놓는 패널은 Flutter에서 `FoldSegment`로 감싸 같은 조각에 둡니다.

페이지 본문은 좁히지 않습니다. 스크롤하며 읽는 본문은 접힘선을 지나가도 됩니다. 다만 본문을 두 열(짝수 열)로 나눈 화면은 열 사이의 간격이 접힘선에 오게 합니다. 접히는 iPhone은 컨트롤을 화면 한쪽 끝에만 세워서 그 자리를 비운 앱 틀의 가운데가 접힘선에서 밀려 있고, 그 안에 같은 폭의 두 열을 놓으면 둘째 열의 첫머리가 접힘선 위에 놓입니다. Flutter에서는 `FoldSpread`로 감싸면 접힘선 양쪽이 같은 폭이 되도록 긴 쪽에서만 덜어 냅니다. 안의 열과 간격은 그대로입니다.

```dart
FoldSpread(
  child: Row(
    spacing: 24,
    children: [
      Expanded(child: primary),
      Expanded(child: secondary),
    ],
  ),
)
```

화면을 나누는 접힘선이 그 상자를 지나갈 때만 움직입니다. 접힘선이 없거나, 평평하게 편 화면이거나, 접힘선이 상자 밖이면 그대로입니다. 세로로 쌓은 구획은 `axis: Axis.vertical`로 가로 접힘선에 맞춥니다.

<DesignNote title="어디까지 되나" variant="outlined">

Android는 창이 접힘선 위에 있으면 펼침과 반접힘을 모두 알립니다. 접히는 iPhone의 접힘은 CoUI가 직접 재므로 `CoUIApp`이나 `CoUILayer` 아래에서는 앱이 할 일이 없습니다. iOS 27.1 SDK로 빌드한 앱이 iOS 27.1 이상에서 돌 때 읽고, 그 밖에서는 접힘이 없는 화면으로 읽습니다. `CoUIApp` 없이 위젯만 쓰는 앱은 내비게이터 위에 `FoldScopeHost`를 둡니다. Web은 Chromium 계열 브라우저에서 화면이 나뉠 때만 접힘을 알아, 펴 둔 이음매 없는 화면은 모릅니다. 서버 렌더와 Safari, Firefox에서는 조각이 비고 `kind`와 `posture`가 `null`입니다. Web에는 토스트를 놓는 계층이 없어 앱이 놓습니다. `FoldSpread`는 Flutter에만 있습니다. Web에서 화면 폭을 채운 컨테이너는 `env(viewport-segment-*)`로 열을 직접 나눕니다. 같은 방향의 접힘선이 둘 이상이면 두 플랫폼이 대화상자를 다른 조각에 열 수 있습니다.

</DesignNote>
