---
title: Tag
description: 항목이 어느 분류에 속하는지 분류색으로 보여 주는 짧은 라벨입니다. 누를 수 없는 표시 전용입니다.
category: display
platforms: [flutter, web]
related: [badge, chip]
tags: [display, label, category, tag]
template: v2
source: display/tag
---

# Tag

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`Tag` 는 항목을 어느 분류에 넣는지 말하는 짧은 라벨입니다. 색은 분류색(`CoreCategoryColor`) 아홉 가지 중 하나이고, 세기는 옅은 `subtle` 과 채운 `bold` 두 가지입니다. 표시 전용이라 누를 수 없고 상태와 포커스가 없습니다. 속성을 바꿔 보며 확인하고, 만들어진 코드를 그대로 복사하세요. `알약 모양` 은 `tagStyle` 로 모서리를 끝까지 둥글립니다.

<Playground component="tag" />

```dart
Tag(color: CoreCategoryColor.blue, child: Text('디자인'))

Tag(
  color: CoreCategoryColor.green,
  emphasis: CoreTagEmphasis.bold,
  size: CoreTagSize.sm,
  child: Text('새 글'),
)
```

Flutter와 Web 코드가 같습니다. 글자 역할이나 색을 붙이지 않은 `Text` 를 `child` 에 넘기면 크기 단계의 글자 역할(`md` 는 `labelSmall`, `sm` 은 `labelXs`)과 분류색의 글자색으로 그려지고 한 줄로 놓입니다. 색을 정하지 않은 태그는 `gray` 입니다. 분류를 정하지 않은 태그가 특정 분류의 색을 띠지 않게 하려는 기본값입니다.

<a id="구조-anatomy"></a>

## 구조

태그는 상자 하나와 그 안의 라벨로 이루어집니다. Figma에서는 [`❖ Tag`](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0) 페이지에 해당합니다.

<Anatomy demo="tag/anatomy">
<AnatomyItem part="container" name="Container">

크기 단계의 높이(`md` 24 · `sm` 20)를 바닥으로 두는 상자입니다. `subtle` 은 분류색의 컨테이너 바탕에 안쪽 1px 선을 두르고, `bold` 는 분류색으로 채웁니다.

</AnatomyItem>
<AnatomyItem part="label" name="child">

상자 가운데에 한 줄로 놓이는 라벨입니다. 크기 단계의 글자 역할과 분류색의 글자색으로 그립니다. 보통 `Text` 를 넣습니다.

</AnatomyItem>
</Anatomy>

### Figma 속성 대응

| Figma | 코드 | 비고 |
| --- | --- | --- |
| `Color` (`red` … `gray`) | `color` | `CoreCategoryColor` 와 같은 순서 · 이름 |
| `Emphasis` (`subtle` · `bold`) | `emphasis` | |
| `Size` (`md` · `sm`) | `size` | |
| `Child` (텍스트) | `child` | 코드는 텍스트가 아니라 위젯을 받습니다 |

<a id="변형-variants"></a>

## Variant

태그는 색(`color`)과 세기(`emphasis`)를 따로 고릅니다. 아홉 가지 색 모두에 두 세기가 있습니다.

<a id="emphasis-bold"></a>

### 세기

<VariantRow name="subtle" component="tag" props="color=blue" label="디자인">

분류색의 컨테이너 바탕에 컨테이너 글자색을 쓰고, 분류색의 `outline` 색으로 선을 두릅니다. 라벨 굵기는 글자 역할 그대로(500)입니다. 기본값입니다.

</VariantRow>

<VariantRow name="bold" component="tag" props="color=blue;emphasis=bold" label="디자인">

분류색 채움 위에 `on` 색 글자를 씁니다. 선이 없고 라벨 굵기는 600입니다. 한 줄에 놓인 태그 중 하나만 눈에 띄어야 할 때 씁니다. 라이트 모드의 글자 대비는 접근성 섹션을 확인하세요.

</VariantRow>

```dart
Tag(
  color: CoreCategoryColor.red,
  emphasis: CoreTagEmphasis.bold,
  child: Text('긴급'),
)
```

### 분류색

<Preview demo="tag/palette" />

`red` · `orange` · `yellow` · `green` · `blue` · `purple` · `pink` · `brown` · `gray` 아홉 가지입니다. 위쪽 묶음이 `subtle`, 아래쪽 묶음이 `bold` 입니다. 분류색에는 성공 · 오류 같은 상태의 뜻도, 브랜드의 뜻도 없습니다. 분류색 토큰(`category-*`)은 상태 색 토큰(`success` · `error` 등)과 따로 있어, 상태 색을 바꿔도 태그 색은 따라 바뀌지 않습니다. 같은 분류에는 화면 어디서나 같은 색을 씁니다.

태그의 색은 분류색 하나가 가진 다섯 슬롯에서 옵니다. 세기마다 읽는 슬롯이 다릅니다. `{c}` 는 색 이름입니다.

| 세기 | 채움 | 글자 | 선 | 라벨 굵기 |
| --- | --- | --- | --- | --- |
| `subtle` | `category-{c}-container` | `on-category-{c}-container` | `category-{c}-outline` | 역할 그대로(500) |
| `bold` | `category-{c}` | `on-category-{c}` | 없음 | 600 |

CoUI 기본 색의 라이트 모드에서는 `outline` 슬롯이 컨테이너와 같은 색이라 `subtle` 의 선이 보이지 않고, 다크 · 고대비 모드에서 드러납니다. 분류색 팔레트가 정한 값이며, 태그가 모드를 따로 가려 처리하지는 않습니다.

<a id="size-sm"></a>

## 크기

크기는 `sm` 과 `md` 두 단계입니다. `CoreTagSize` 는 이 두 값만 가집니다. 기본값은 `md` 입니다.

<SizeSpec component="tag" props="color=blue" label="디자인" />

- **`md`** — 기본 크기입니다. 기본 크기의 `Badge` 와 같은 높이(24)입니다.
- **`sm`** — 표의 칸이나 목록의 한 줄처럼 촘촘한 자리에 씁니다.
- 세로 여백은 없습니다. 최소 높이를 바닥으로 두고 라벨을 가운데에 둡니다.
- 모서리는 높이의 1/4 을 반경 단계로 내린 값입니다.
- 표의 라벨 굵기는 `subtle` 기준입니다. `bold` 는 두 크기 모두 600입니다.

```dart
Tag(color: CoreCategoryColor.blue, size: CoreTagSize.sm, child: Text('디자인'))
```

<a id="동작-스펙-behavior"></a>

## 상태

태그에는 상태가 없습니다.

<a id="인터랙션"></a>
<a id="상태-전환"></a>
<a id="애니메이션"></a>

| 항목 | 동작 |
| --- | --- |
| 인터랙션 | 누름 · hover · pressed 가 없고 포커스를 받지 않습니다. `onPressed` 같은 파라미터도 없습니다. |
| 상태 전환 | 선택 · 비활성 상태가 없습니다. 겉모습은 `color` · `emphasis` · `size` · `tagStyle` 과 적용 중인 테마로 정해집니다. |
| 애니메이션 | 태그 자체에는 전환 효과가 없습니다. |

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 글 · 일정 · 상품 같은 항목이 어느 분류에 속하는지 색으로 구별해 보여 줄 때
- 표의 칸이나 목록의 한 줄 안에서 분류를 색으로 구별할 때 (`size: CoreTagSize.sm`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 진행 중 · 완료 · 오류처럼 상태를 말할 때 | [Badge](/components/badge) — `tone` 이 뜻(성공 · 경고 · 위험 등)을 가진 색입니다 |
| 읽지 않은 개수나 알림 점을 보일 때 | [Badge](/components/badge)의 `count` · `dot` 형태 |
| 라벨에 아이콘이나 상태 점을 붙일 때 | [Badge](/components/badge)의 `leading` · `trailing` · `showDot` |
| 분류색 없이 중립 라벨만 붙일 때 | [Badge](/components/badge)의 기본값(`neutral` · `tonal`). 분류색 태그와 함께 놓는 미분류 라벨은 `gray` 태그로 모양을 맞춥니다 |
| 사람이 누르거나, 고르거나, 지우는 라벨 | [Chip](/components/chip) |
| 글자를 입력해 항목을 만들 때 | [ChipInput](/components/chip-input) |

<a id="do"></a>
<a id="dont"></a>

### 색과 상태

<Cards columns="2">
<Card demo="tag/do-same-color" tone="do" eyebrow="이렇게 하세요">

한 분류에는 한 색을 씁니다. 같은 분류가 어디서나 같은 색이어야 색이 분류의 이름표 역할을 합니다.

</Card>
<Card demo="tag/dont-mixed-color" tone="dont" eyebrow="이렇게 하지 마세요">

같은 분류에 색을 섞으면 서로 다른 분류처럼 읽힙니다.

</Card>
<Card demo="tag/do-status-badge" tone="do" eyebrow="이렇게 하세요">

상태는 `Badge` 의 `tone` 으로 말합니다. `Badge` 는 상태 색 토큰을 씁니다.

</Card>
<Card demo="tag/dont-status-tag" tone="dont" eyebrow="이렇게 하지 마세요">

상태를 태그로 말하지 않습니다. 분류색에는 성공 · 오류의 뜻이 없고, 상태 색 토큰을 따르지도 않습니다.

</Card>
</Cards>

```dart
// 분류: 같은 분류에는 같은 색
Tag(color: CoreCategoryColor.blue, child: Text('디자인'))
Tag(color: CoreCategoryColor.green, child: Text('개발'))

// 상태: Badge
Badge(tone: CoreBadgeTone.destructive, child: Text('실패'))
```

## 배치

- 상자는 크기 단계의 높이 이상이고, 라벨은 상자의 가로 · 세로 가운데에 한 줄로 놓입니다.
- 따로 폭을 정하지 않으면 폭은 라벨 폭에 좌우 여백을 더한 값입니다. `subtle` 의 선(기본 1px)은 크기 단계의 높이를 늘리지 않지만, 폭에는 좌우에 선 굵기만큼 더해집니다.
- 부모가 폭을 늘리면(Flutter의 `CrossAxisAlignment.stretch`, 웹의 세로 flex 기본 정렬) 상자가 함께 늘어나고 라벨은 가운데에 남습니다. 웹의 세로 flex 안에서 내용 폭을 지키려면 부모에 `items-start` 처럼 정렬을 지정합니다.

### 여러 태그

<Preview demo="tag/wrap" />

태그가 여러 개면 Flutter는 `Wrap`, 웹은 줄바꿈을 허용한 flex 상자에 담습니다. 자리가 모자라면 태그가 통째로 다음 줄로 넘어갑니다.

<Split>

<Code language="dart" title="Flutter">
Wrap(
  spacing: CoreSpace.space8,
  runSpacing: CoreSpace.space8,
  children: [
    Tag(color: CoreCategoryColor.blue, child: Text('디자인')),
    Tag(color: CoreCategoryColor.green, child: Text('개발')),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  [
    Tag(color: CoreCategoryColor.blue, child: Text('디자인')),
    Tag(color: CoreCategoryColor.green, child: Text('개발')),
  ],
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': spaceCss(CoreSpace.space8),
    },
  ),
)
</Code>

</Split>

### 긴 라벨

태그는 긴 라벨을 줄바꿈하거나 말줄임해 주지 않습니다. 놓일 자리가 라벨보다 좁으면 Flutter는 레이아웃 넘침 오류를 내고, 웹은 글자가 상자나 부모 밖으로 넘칩니다. 태그에는 짧은 분류 이름을 넣고, 길이를 알 수 없는 문자열은 넘기기 전에 줄이거나 태그 밖의 본문에 둡니다.

<a id="조합-예제"></a>

### 목록 행에 넣기

<Preview demo="tag/in-row" />

<Split>

<Code language="dart" title="Flutter">
Row(
  spacing: CoreSpace.space8,
  children: [
    Text('디자인 시스템 개편').titleSmall,
    Tag(
      color: CoreCategoryColor.blue,
      size: CoreTagSize.sm,
      child: Text('디자인'),
    ),
    Tag(
      color: CoreCategoryColor.green,
      size: CoreTagSize.sm,
      child: Text('개발'),
    ),
  ],
)
</Code>

<Code language="dart" title="Jaspr Web">
div(
  [
    Text('디자인 시스템 개편').titleSmall,
    const Gap.space8(),
    Tag(
      color: CoreCategoryColor.blue,
      size: CoreTagSize.sm,
      child: Text('디자인'),
    ),
    const Gap.space8(),
    Tag(
      color: CoreCategoryColor.green,
      size: CoreTagSize.sm,
      child: Text('개발'),
    ),
  ],
  classes: 'flex flex-row items-center',
)
</Code>

</Split>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

<a id="tagstyle"></a>

### 파라미터와 스타일

- **종류와 내용** — 위젯 파라미터로 직접 넘깁니다: `color`, `emphasis`, `size`, `child`. 테마는 이 값을 바꾸지 않습니다.
- **겉모습(색 · 크기 · 간격)과 라벨 글자** — `tagStyle`(`CoreTagStyle`) 하나로 덮어씁니다: `backgroundColor`, `foregroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `padding`, `minHeight`, `labelStyle`.
- **라벨의 글자 역할** — `child` 의 `Text` 에 `.labelMedium` 같은 글자 역할 체인을 붙이지 말고 `tagStyle` 의 `labelStyle` 로 바꿉니다. 체인으로 붙이면 `bold` 의 굵기(600)가 그 역할의 굵기로 바뀌고, Flutter에서는 글자색도 `onSurface` 가 됩니다(플랫폼 차이 섹션).

<a id="resolve-chain"></a>

### 값이 정해지는 순서

뒤에 있는 값이 우선합니다. 비워 둔 필드는 앞 단계의 값을 그대로 씁니다.

```text
CoreTagStyle.defaultsBySize[size]             // 크기 단계
  → CoreTagStyle.defaultsByEmphasis[emphasis] // 세기가 더하는 값
  → CoreTagStyle.resting(color, emphasis)     // 분류색 × 세기의 색
  → CoreTagTheme.style                        // 프로젝트 공통
  → CoreTagTheme.colorStyles[color]
  → CoreTagTheme.emphasisStyles[emphasis]
  → tagStyle                                  // 인스턴스별
```

- `labelStyle` 은 안의 항목끼리 합칩니다. 색만 적으면 크기 단계의 글자 역할은 그대로이고, 다른 글자 역할을 적어도 `bold` 의 굵기(600)는 남습니다. `labelStyle` 에 적은 색은 `foregroundColor` 보다 우선합니다.
- `CoreTagTheme.style` 에 색을 적으면 모든 분류색의 태그가 그 색이 됩니다. 특정 분류색만 바꾸려면 `colorStyles` 를 씁니다.
- `colorStyles` 에 적은 색은 그 분류색의 두 세기에, `emphasisStyles` 에 적은 색은 그 세기의 모든 분류색에 닿습니다. 같은 필드를 둘 다 적으면 `emphasisStyles` 가 이깁니다. 분류색과 세기의 한 조합만 고르는 테마 칸은 없으므로 `tagStyle` 로 넘깁니다.
- 선은 선 색이 있을 때만 그립니다. `bold` 에 선을 두르려면 `borderColor` 를 적습니다. `subtle` 의 선을 두 플랫폼에서 모두 안 보이게 하려면 `borderColor: CoreColor.transparent` 를 씁니다(선의 폭은 남습니다).
- 색을 덮어쓸 때는 채움(`backgroundColor`)과 글자(`foregroundColor`)를 함께 정하고 대비를 확인합니다. 하나만 바꾸면 나머지는 분류색의 값으로 남습니다.

### 테마로 덮어쓰기

<Split>

<Code language="dart" title="태그 하나만 바꾸기">
Tag(
  color: CoreCategoryColor.purple,
  tagStyle: CoreTagStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
  ),
  child: Text('둥근 모양'),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    tag: CoreTagTheme(
      style: CoreTagStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
      ),
      emphasisStyles: {
        CoreTagEmphasis.bold: CoreTagStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space10),
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

### 기본값이 있는 곳

태그의 기본값은 `coui_core` 에 있고 Flutter와 Web이 같은 값을 읽습니다.

| 이름 | 내용 |
| --- | --- |
| `CoreTagStyle.defaultsBySize[size]` | 크기마다 `minHeight` · 좌우 `padding` · `borderRadius` · `labelStyle` 역할 (크기 섹션의 표) |
| `CoreTagStyle.defaultsByEmphasis[emphasis]` | `subtle` 은 바꾸는 값이 없고, `bold` 는 라벨 굵기 600 |
| `CoreTagStyle.resting(color, emphasis)` | 분류색 × 세기의 채움 · 글자 · 선 색 |
| `CoreTagStyle.defaultBorderWidth` | `CoreStrokeWidth.stroke1`(1px). 선 색이 있을 때의 선 굵기 |
| `CoreTagContract.defaultColor` | `gray` |
| `CoreTagEmphasis.defaultEmphasis` | `subtle` |
| `CoreTagSize.defaultSize` | `md` |

### 재질

적용 중인 서피스 스타일이 재질을 가지면, 채움을 칠하는 태그는 내용 표면(`content`)의 재질을 입습니다. 채움을 투명하게 덮어쓴 태그에는 재질이 붙지 않습니다. 재질이 없는 기본 상태에서는 채움 하나로 그립니다. 태그는 자체 그림자를 정하지 않지만, 상자에 그림자를 더하는 서피스 스타일에서는 태그에도 그 그림자가 생깁니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기 (체인)

이미 만든 `Tag` 에 `withStyle` 을 이어 `tagStyle` 을 덧붙일 수 있습니다. 생성자의 `tagStyle` 로 넘긴 것과 같게 동작하고, 같은 필드는 나중에 이은 값이 이깁니다. `Tag` 전용 체인은 `withStyle` 하나입니다. `.radius8` 같은 토큰 이름의 짧은 getter 는 `Tag` 에 없습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TagChainExample extends StatelessWidget {
  const TagChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a tweak laid over the hue's colours.
    return const Tag(
      color: CoreCategoryColor.purple,
      child: Text('둥근 모양'),
    ).withStyle(
      const CoreTagStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class TagChainExample extends StatelessComponent {
  const TagChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // withStyle full-control — a tweak laid over the hue's colours.
    return Tag(
      color: CoreCategoryColor.purple,
      child: Text('둥근 모양'),
    ).withStyle(
      const CoreTagStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        padding: CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
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

태그는 글자로만 읽히는 표시 전용 라벨입니다. 모든 컴포넌트에 공통인 축(동작 줄이기 · 고대비 · 색 강제 모드 · 시맨틱 역할 · 최소 터치 타겟)은 [접근성](/accessibility) 페이지가 한 곳에서 다룹니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 태그가 따로 붙이는 `Semantics` 가 없습니다. 라벨 `Text` 가 그대로 읽힙니다. |
| Jaspr Web | 역할이 없는 `<span>` 입니다. |

### 키보드

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` | 태그는 탭 순서에 들어가지 않습니다 | 태그는 탭 순서에 들어가지 않습니다 |

태그가 처리하는 키는 없습니다. 웹에서 `eventHandlers` 로 클릭 처리를 붙여도 역할과 `tabindex` 가 생기지 않아, 버튼으로 알려지지 않고 `Tab` 으로 닿지 않습니다. 누르는 라벨은 [Chip](/components/chip)을 씁니다.

### 스크린 리더

이름은 `child` 의 글자에서 나옵니다. `color` 와 `emphasis` 는 읽히지 않습니다. 색만으로 분류를 구별하게 하지 말고, 라벨 낱말이 분류를 말하게 합니다.

### 포커스 관리

없음 — 태그는 포커스를 받지 않으므로 포커스를 옮기거나 가두지 않습니다.

### 알려진 제약

- CoUI 기본 색의 라이트 모드에서 `bold` 는 흰 라벨과 채움의 대비가 약 3.5~3.8:1 입니다. WCAG 2.2 AA 의 일반 크기 글자 기준(4.5:1)에 못 미칩니다.
- CoUI 기본 색의 라이트 모드에서는 `subtle` 의 선이 컨테이너와 같은 색이라 보이지 않습니다.
- 긴 라벨은 줄바꿈하거나 말줄임하지 않습니다(배치 섹션).
- 아이콘 슬롯이 없습니다. 내용은 `child` 하나입니다.

#### 색상 대비

CoUI 기본 분류색으로 계산한 라벨과 채움의 대비입니다. 색을 덮어쓰거나 채움이 비치는 서피스 스타일을 쓰면 달라집니다.

- `subtle` — 라이트 · 다크 · 고대비 모드의 아홉 색 모두 6.5:1 이상입니다.
- `bold` — 다크 모드는 5:1 이상, 고대비 모드는 7:1 이상입니다. 라이트 모드는 위 알려진 제약의 값입니다. 라이트 모드에서 4.5:1 이 필요하면 `subtle` 을 씁니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`child` · `color` · `emphasis` · `size` · `tagStyle` 은 두 플랫폼이 같은 API 입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| `child` 타입 | `Widget` | `Component` |
| 루트 | `Container`(채움 + 선) 안의 가운데 맞춘 `Row`. 서피스 스타일에 따라 바깥에 그림자 · 재질 레이어가 붙습니다 | `<span>` — `inline-flex`, 가운데 맞춤, 줄바꿈 없음 |
| 높이 | `BoxConstraints(minHeight:)` | 크기 변수를 읽는 `min-h-*` 클래스. `minHeight` 를 덮어쓰면 인라인 `min-height` |
| 선 | `Border.all` — 선 색이 있을 때만 | `border-width` — 선 색이 있을 때만 |
| `borderWidth: 0` | 선 색이 있으면 헤어라인(1 물리 픽셀)이 남습니다 | 선을 그리지 않습니다 |
| 라벨 글자 | `DefaultTextStyle.merge` 로 역할 · 굵기 · 색을 내려 줍니다 | `text-{role}` 클래스와 색 클래스. `bold` 의 굵기는 인라인 스타일 |
| `child` 의 `Text` 에 글자 역할 체인(`.labelMedium` 등)을 붙일 때 | 역할이 글자 모양을 새로 정해, 색 체인을 따로 붙이지 않으면 글자색이 `onSurface` 가 됩니다 | 태그의 글자색이 그대로 남습니다 |
| 라벨 글자 선택 | 태그가 선택을 막지 않습니다. `SelectionArea` 안에서는 선택됩니다 | 루트에 `select-none` 클래스가 있어 라벨이 선택되지 않습니다 |
| 긴 라벨이 좁은 자리에 놓일 때 | 레이아웃 넘침 오류 | 글자가 상자나 부모 밖으로 넘칩니다 |
| 크기 배율 | 높이 · 여백 · 모서리 · 선 굵기에 `theme.scaling` 을 곱합니다 | 태그가 따로 곱하는 배율은 없습니다 |
| 겉모습을 내보내는 방식 | 바로 그릴 수 있는 `BoxDecoration` / `TextStyle` | Tailwind 클래스 + 인라인 CSS |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<span>` 에 닿습니다 |

<a id="props-parameters"></a>

## API

`W` 는 Flutter의 `Widget`, Web의 Jaspr `Component` 입니다.

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `child` | `W` | 필수 | 라벨 — 보통 `Text` |
| `color` | `CoreCategoryColor` | `gray` (`CoreTagContract.defaultColor`) | 분류색 아홉 가지 중 하나 |
| `emphasis` | `CoreTagEmphasis` | `subtle` (`CoreTagEmphasis.defaultEmphasis`) | 세기 — `subtle`(옅은 바탕 + 선) · `bold`(채움) |
| `size` | `CoreTagSize` | `md` (`CoreTagSize.defaultSize`) | 크기 — `sm` · `md` |
| `tagStyle` | `CoreTagStyle?` | `null` | 겉모습을 덮어쓰는 값 (아래 필드 표) |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트 `<span>` 의 id |
| `classes` | `String?` | `null` | 루트에 더하는 CSS 클래스. 배치에 씁니다 |
| `css` | `Styles?` | `null` | 루트에 더하는 인라인 스타일. 태그가 붙이는 인라인 스타일 뒤에 합칩니다 |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성 — `data-*`, 테스트 id 등 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 DOM 이벤트 처리 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTagStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Fill colour override. `null` defers to the hue's colour for the emphasis ([CoreTagStyle.resting]). |
| `foregroundColor` | `CoreColor?` | Label colour override. `null` defers to the hue's colour for the emphasis. |
| `borderColor` | `CoreColor?` | Border stroke colour. `null` defers to the hue, which states one only for [CoreTagEmphasis.subtle]; with no colour no border is drawn. |
| `borderWidth` | `double?` | Border stroke width (logical px). `null` defers to [defaultBorderWidth]. |
| `borderRadius` | `CoreBorderRadius?` | Border radius. `null` defers to the step's corner in [defaultsBySize]. |
| `padding` | `CoreEdgeInsets?` | Padding around the label. `null` defers to `CoreTagStyle.defaultsBySize[size]!.padding!`. Horizontal only by default — the height is [minHeight]. |
| `minHeight` | `double?` | Height of the tag (logical px); the label is centred in it. `null` defers to `CoreTagStyle.defaultsBySize[size]!.minHeight!`. |
| `labelStyle` | `CoreTextStyle?` | Label text style override. `null` defers to the step's role in [defaultsBySize] with the emphasis's weight from [defaultsByEmphasis] laid over it. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `minHeight` 설명은 태그의 높이라고 적지만, 지금 태그는 이 값을 최소 높이로 씁니다. 라벨의 줄 높이에 위아래 `padding` 과 위아래 선 굵기를 더한 값이 더 크면 상자가 그만큼 커집니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="tag/related-badge" title="Badge">

상태 · 개수 · 점처럼 뜻이 있는 표시는 [Badge](/components/badge)를 씁니다.

</Card>
<Card demo="tag/related-chip" title="Chip">

누르거나, 고르거나, 지우는 라벨은 [Chip](/components/chip)을 씁니다.

</Card>
</Cards>
