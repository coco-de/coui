---
title: DefinitionList
description: 용어와 설명을 한 쌍씩 묶어 보여 주는 정의 목록입니다. 위아래 · 두 열 · 한 줄 흐름 가운데 하나로 놓습니다.
category: display
platforms: [flutter, web]
related: [text-block, table, description-card]
tags: [text, semantic, accessibility, metadata]
template: v2
source: text/definition_list
---

# DefinitionList

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

용어(term)와 설명(description)을 한 쌍씩 묶어 나열합니다. 사업자등록번호 · 주문번호 · 날짜 · 금액처럼 값만 놓고는 뜻이 서지 않는 정보에 씁니다. 속성을 바꿔 보고 만들어진 코드를 복사하세요. 코드는 Flutter와 Web이 같습니다.

<Playground component="definition-list" />

아무 값도 주지 않으면 `layout` 은 `stacked` 이고 `numeric` · `mono` 는 꺼져 있습니다.

## 구조

목록은 용어와 설명의 쌍을 차례로 놓습니다. 목록 자체는 배경 · 테두리 · 안쪽 여백을 그리지 않습니다.

<Anatomy demo="definition-list/anatomy">
<AnatomyItem part="container" name="list">

목록 전체입니다. `layout` 이 쌍을 놓는 방식을 정합니다. Web에서는 `<dl>` 입니다.

</AnatomyItem>
<AnatomyItem select="dt" side="top" name="term">

값의 이름(`term`)입니다. 흐린 글자색(`onSurfaceSubtle`)으로 그립니다. Web에서는 `<dt>` 입니다.

</AnatomyItem>
<AnatomyItem select="dd" side="top" name="description">

용어에 답하는 값입니다. 문자열 설명은 기본 글자색(`onSurface`)으로 그립니다. Web에서는 `<dd>` 입니다.

</AnatomyItem>
</Anatomy>

### 항목 타입 — `CoreDefinitionEntry`

`items` 의 항목 하나가 용어와 설명 한 쌍입니다. `term` 은 언제나 `String` 이라 위젯이나 아이콘은 용어 자리에 넣을 수 없습니다. 빈 문자열까지 막지는 않습니다. 설명의 모양은 생성자로 고릅니다. 어느 생성자를 써도 설명은 하나입니다.

| 생성자 | 설명(`description`)의 타입 |
| --- | --- |
| `CoreDefinitionEntry` | `String`. 대부분 이쪽입니다. |
| `CoreDefinitionEntry.rich` | Flutter `Widget`, Web `Component`. 링크 · 여러 줄 주소처럼 글자 한 줄이 아닌 값에 씁니다. |

```dart
const CoreDefinitionEntry(term: '상호', description: '예시상사')
```

<a id="변형-variants"></a>

## 레이아웃

`layout`(`CoreDefinitionLayout`)은 용어를 설명의 어디에 놓을지 정합니다. 세 값은 같은 항목을 같은 순서로 그립니다. 놓는 자리와 기본 간격 · 글자 역할이 달라집니다.

| 값 | 놓는 방식 | 쌍 안 | 쌍 사이 |
| --- | --- | --- | --- |
| `stacked` (기본) | 용어 위, 설명 아래 | 2 | 14 |
| `columns` | 용어 열과 설명 열 | 8 | 24 |
| `inline` | 한 줄에 이어 놓기 | 8 | 16 |

- **쌍 안**(`pairSpacing`)은 용어와 자기 설명 사이, **쌍 사이**(`entrySpacing`)는 한 쌍과 다음 쌍 사이입니다. 두 간격이 가로인지 세로인지는 배치마다 달라서 이름이 관계를 가리킵니다. `stacked` 에서는 두 거리가 모두 세로입니다.
- `inline` 의 쌍 사이 값은 줄이 넘어갔을 때의 줄 간격에도 쓰입니다.
- 첫 쌍 앞에는 쌍 사이 간격이 붙지 않습니다.
- 기본값은 세 배치 모두 쌍 안이 더 좁아 용어가 자기 설명에 붙어 보입니다. 값을 바꿀 때도 이 순서를 지키세요. 코드가 강제하지는 않습니다.

<a id="default-stacked"></a>

### 위아래 (`stacked`)

<Preview demo="definition-list/stacked" />

기본값입니다. 용어와 설명을 위아래로 놓아 긴 용어가 설명의 폭을 빼앗지 않습니다. 한글 문장처럼 줄을 나눌 수 있는 긴 용어는 목록 폭 안에서 줄바꿈합니다. 용어가 길거나 화면 폭을 미리 알 수 없으면 이 배치를 고릅니다.

<a id="columns"></a>

### 두 열 (`columns`)

<Preview component="definition-list" example="columns" />

설명이 모두 같은 가로 위치에서 시작합니다. 용어가 한 줄에 들어가는 폭에서는 용어 열이 가장 긴 용어에 맞춰지고, 설명 열이 남은 폭을 씁니다. `termWidth` 를 주면 용어 열을 그 폭으로 정합니다.

용어와 설명은 글자 기준선을 맞춥니다. 그래서 21px 줄을 쓰는 `mono` 설명처럼 용어와 줄 높이가 달라도 글자의 밑선이 맞습니다.

<a id="inline"></a>

### 한 줄 흐름 (`inline`)

<Preview demo="definition-list/inline" />

용어와 설명을 한 줄에 이어 놓고, 폭이 모자라면 다음 줄로 넘깁니다. 푸터처럼 짧은 값이 이어지는 곳에 씁니다.

<Note>

줄이 넘어가는 단위가 플랫폼마다 다릅니다. Flutter는 용어와 설명 한 쌍이 한 덩어리로 넘어갑니다. Web은 용어와 설명이 따로 넘어가므로, 용어가 줄 끝에 남고 설명이 다음 줄에서 시작할 수 있습니다. Web에서 넘어간 줄의 첫머리에는 앞 간격이 남아 들여 쓴 것처럼 보입니다. 용어로 시작하는 줄은 쌍 사이 간격만큼, 설명으로 시작하는 줄은 쌍 안 간격만큼입니다. 한 쌍이 갈라지면 안 되는 Web 화면에서는 `stacked` 나 `columns` 를 쓰세요.

</Note>

## 타이포그래피

용어는 흐린 글자색(`onSurfaceSubtle`), 문자열 설명은 기본 글자색(`onSurface`)입니다. 글자 역할은 배치를 따릅니다. 표의 숫자는 CoUI 기본 타이포그래피의 크기(px)와 굵기입니다.

| 배치 | 용어 | 설명 |
| --- | --- | --- |
| `stacked` | `label-small` 12 / 500 | `label-medium` 13 / 500 |
| `columns` · `inline` | `label-medium` 13 / 500 | `label-medium` 13 / 500 |

`mono: true` 면 배치와 상관없이 설명이 `code-sm`(12 / 400, 21px 줄)이 됩니다. 용어는 그대로입니다.

<Preview demo="definition-list/typography" />

### 고정폭 숫자 (`numeric`)

`numeric: true` 는 설명에 글꼴의 고정폭 숫자(tabular figures)를 켭니다. 글꼴이 이 기능을 지원하면 숫자마다 폭이 같아져, 날짜처럼 글자 수와 구두점 위치가 같은 값이 세로로 맞습니다. 글자와 접근성 정보는 바꾸지 않고, 용어에는 적용하지 않습니다.

목록에는 설명의 정렬을 바꾸는 속성이 없고, 기본 정렬에서 설명은 줄의 시작 쪽에 붙습니다. 그래서 `1,111,000원` 과 `8,000원` 처럼 길이가 다른 금액은 `numeric` 을 켜도 일 · 십 · 백의 자리가 서로 맞지 않습니다.

### 코드 값 (`mono`)

`mono: true` 는 식별자 · 해시 · 코드 값에 쓰는 코드 글자 역할로 설명을 그립니다. 서체는 Geist Mono입니다. Geist Mono에 없는 한글은 글꼴 목록에서 그다음인 Pretendard로 그리며, Pretendard는 앱이나 페이지에서 쓸 수 있어야 합니다. `numeric` 과 함께 켤 수 있습니다.

<Note>

Flutter는 `coui_flutter` 에 Geist Mono가 들어 있어 따로 설정하지 않아도 됩니다. `coui_web` 에는 글꼴 파일이 없습니다. 페이지에서 Geist Mono를 쓸 수 없으면 Pretendard, 그것도 없으면 브라우저의 `monospace` 글꼴로 그립니다. Pretendard로 그려지면 고정폭으로 보이지 않으므로, Web 앱에서는 Geist Mono를 함께 불러오세요.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="인터랙션"></a>

## 링크가 든 설명

목록 자체는 표시 전용입니다. 누르기 · hover · 포커스 상태도, 애니메이션도 없습니다. Web에서는 서버가 그린 마크업에 내용이 그대로 담깁니다. 링크나 버튼처럼 동작이 필요한 값은 `CoreDefinitionEntry.rich` 로 넣습니다. 넣은 위젯은 자기 동작을 그대로 가집니다.

<Preview demo="definition-list/rich" />

설명의 글자 스타일은 `rich` 값에도 이어집니다. 글자 스타일을 따로 정하지 않은 `Text` 는 문자열 설명과 같게 보이고, `Link` 처럼 자기 글자 스타일이 있는 컴포넌트는 자기 스타일로 그립니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
DefinitionList(
  items: [
    CoreDefinitionEntry.rich(
      term: '영수증',
      description: Link(
        href: 'https://example.com/receipts/1048',
        onPressed: openReceipt,
        child: Text('영수증 보기'),
      ),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
DefinitionList(
  items: [
    CoreDefinitionEntry.rich(
      term: '영수증',
      description: Link(
        href: 'https://example.com/receipts/1048',
        child: Text('영수증 보기'),
      ),
    ),
  ],
)
```

  </TabItem>
</Tabs>

Flutter의 `Link` 는 `href` 를 스스로 열지 않으므로 `onPressed` 에서 직접 엽니다. 위 코드의 `openReceipt` 는 앱에서 만드는 함수입니다. Web의 `Link` 는 `onPressed` 가 없으면 `<a href>` 를 그려 브라우저가 이동합니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 푸터의 사업자 정보(상호 · 대표 · 사업자등록번호 · 통신판매업신고번호)처럼 라벨 없이는 읽히지 않는 값을 나열할 때
- 주문 상세 · 배송 정보 · 결제 내역처럼 "항목 이름과 값" 이 반복될 때
- 제품 사양이나 부가 정보처럼 이름과 값의 쌍이 목록을 이룰 때
- 날짜처럼 모양이 같은 값을 세로로 맞춰 보여 줄 때(`columns` + `numeric: true`)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 것 |
| --- | --- |
| 한 행이 여러 열의 값을 갖는 2차원 데이터 | [Table](/components/table). 정의 목록의 항목은 용어 하나에 설명 하나입니다. |
| 같은 이름 · 값 목록에 카드 표면 · 제목 · 행 강조 · 하단 액션이 필요할 때 | [DescriptionCard](/components/description-card). 표면 없이 용어와 설명만 나열하면 `DefinitionList` 로 충분합니다. |
| 지표 하나를 크게 보여 줄 때 | [Stat](/components/stat) |
| 라벨이 없는 문단 | [TextBlock](/components/text-block) |

<a id="do"></a>
<a id="dont"></a>

### 용어와 값

<Cards columns="2">
<Card demo="definition-list/do-term" tone="do" eyebrow="이렇게 하세요">

값마다 그 값을 설명하는 용어를 붙입니다. 번호 두 개를 라벨 없이 늘어놓으면 어느 번호가 무엇인지 알 수 없습니다.

</Card>
<Card demo="definition-list/dont-one-line" tone="dont" eyebrow="이렇게 하지 마세요">

용어와 값을 한 문자열에 이어 붙이지 않습니다. 글자 한 덩어리가 되어, 어느 값이 어느 용어의 것인지가 구조로 남지 않습니다.

</Card>
</Cards>

<Split>

<Code language="dart" title="이렇게 하세요">
DefinitionList(
  items: const [
    CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
    CoreDefinitionEntry(term: '법인등록번호', description: '000000-0000000'),
  ],
)
</Code>

<Code language="dart" title="이렇게 하지 마세요">
// 용어와 값의 관계가 남지 않는 한 줄의 글입니다.
Text('사업자등록번호 000-00-00000 · 법인등록번호 000000-0000000')
</Code>

</Split>

### 긴 용어

<Cards columns="2">
<Card demo="definition-list/do-long-term" tone="do" eyebrow="이렇게 하세요">

용어가 길거나 폭이 좁으면 `stacked` 를 씁니다.

</Card>
<Card demo="definition-list/dont-long-term" tone="dont" eyebrow="이렇게 하지 마세요">

긴 용어에 `columns` 를 쓰면 설명 열이 좁아집니다. 더 좁은 화면의 동작은 배치 섹션을 보세요.

</Card>
</Cards>

### 숫자 비교

<Cards columns="2">
<Card demo="definition-list/do-numeric" tone="do" eyebrow="이렇게 하세요">

날짜처럼 모양이 같은 값은 `columns` 와 `numeric: true` 를 함께 써서 세로로 맞춥니다.

</Card>
<Card demo="definition-list/dont-amount" tone="dont" eyebrow="이렇게 하지 마세요">

길이가 다른 금액의 자릿값을 `numeric` 으로 맞추려 하지 않습니다. 설명이 시작 쪽에 붙어 자리가 어긋납니다.

</Card>
</Cards>

```dart
DefinitionList(
  items: const [
    CoreDefinitionEntry(term: '주문일', description: '2026-11-11'),
    CoreDefinitionEntry(term: '발송일', description: '2026-11-18'),
  ],
  layout: CoreDefinitionLayout.columns,
  numeric: true,
)
```

## 배치

### 목록의 폭

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

- `columns` 는 부모가 허락하는 폭을 채우고, 용어 열을 뺀 나머지를 설명 열이 씁니다.
- `stacked` · `inline` 은 폭을 채우라는 제약이 없으면 내용만큼만 차지합니다.
- `columns` 를 폭 제한이 없는 부모(`Row` 의 직계 자식, 가로 스크롤)에 그대로 놓으면 설명 열의 폭이 0이 됩니다. `Row` 안에서는 `Expanded` 로 감싸거나 폭을 정해 주세요.

  </TabItem>
  <TabItem label="Web" value="web">

- 블록 부모와, 자식을 늘이는 세로 flex 부모(flex의 기본 정렬)에서는 `<dl>` 이 폭을 채웁니다.
- 가로 flex 부모나 `items-center` · `items-start` 처럼 자식을 늘이지 않는 부모에서는 내용 폭이 됩니다. 이때 `columns` 의 설명 열은 남는 폭 없이 글자 폭이 됩니다.
- 채워야 하면 `classes: 'w-full'` 을 줍니다.

```dart
DefinitionList(
  items: const [CoreDefinitionEntry(term: '상호', description: '예시상사')],
  layout: CoreDefinitionLayout.columns,
  classes: 'w-full',
)
```

  </TabItem>
</Tabs>

### 좁은 폭의 긴 용어

`columns` 에서 가장 긴 용어가 목록 폭에 한 줄로 들어가지 않으면 두 플랫폼이 다르게 놓습니다. `termWidth` 를 주지 않은 경우입니다.

| 플랫폼 | 결과 |
| --- | --- |
| Flutter | 줄을 나눌 수 있는 용어는 목록 폭 안에서 줄바꿈하고, 설명 열에는 폭이 남지 않습니다. |
| Web | 용어는 줄바꿈하지 않고, 열이 목록의 폭을 넘칩니다. |

`inline` 의 용어는 Flutter에서 줄바꿈하지 않아, 용어 하나가 목록 폭보다 길면 넘칩니다. 폭을 미리 알 수 없는 긴 용어에는 `stacked` 를 쓰세요.

### 여러 목록의 설명 맞추기

`columns` 목록마다 용어 길이가 다르면 설명이 시작하는 위치도 달라집니다. 목록들에 같은 `termWidth` 를 주면 설명이 같은 위치에서 시작합니다. 한글처럼 줄을 나눌 수 있는 용어가 정한 폭보다 길면 열 안에서 줄바꿈합니다. `stacked` 와 `inline` 은 `termWidth` 를 읽지 않습니다.

<Preview demo="definition-list/term-width" />

```dart
const columnStyle = CoreDefinitionListStyle(termWidth: CoreSpace.space120);

DefinitionList(
  items: const [CoreDefinitionEntry(term: '상호', description: '예시상사')],
  layout: CoreDefinitionLayout.columns,
  definitionListStyle: columnStyle,
)

DefinitionList(
  items: const [CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000')],
  layout: CoreDefinitionLayout.columns,
  definitionListStyle: columnStyle,
)
```

### 조합 예제

푸터의 사업자 정보처럼 구분선 아래에 목록 하나를 둡니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Divider(),
    const Gap.space16(),
    DefinitionList(
      items: const [
        CoreDefinitionEntry(term: '상호', description: '예시상사'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
        CoreDefinitionEntry(term: '통신판매업신고번호', description: '2026-예시-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(classes: 'flex flex-col', [
  const Divider(),
  const Gap.space16(),
  DefinitionList(
    items: const [
      CoreDefinitionEntry(term: '상호', description: '예시상사'),
      CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      CoreDefinitionEntry(term: '통신판매업신고번호', description: '2026-예시-00000'),
    ],
    layout: CoreDefinitionLayout.columns,
    numeric: true,
  ),
])
```

  </TabItem>
</Tabs>

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

간격 · 글자 · 용어 열 폭은 `definitionListStyle`(`CoreDefinitionListStyle`) 하나로 바꿉니다. 필드는 `entrySpacing` · `pairSpacing` · `termTextStyle` · `descriptionTextStyle` · `monoDescriptionTextStyle` · `termWidth` 이고, 뜻은 API의 필드 표에 있습니다. `layout` · `numeric` · `mono` 는 스타일이 아니라 위젯 파라미터입니다.

### 값이 정해지는 순서

뒤로 갈수록 우선합니다.

```text
CoreDefinitionListStyle.defaultsByLayout[layout]   // 디자인 시스템 기본값 (배치마다 한 벌)
  → CoreComponentTheme.definitionList.style        // 앱 전체
  → definitionListStyle                            // 목록 하나
```

- 비워 둔 필드는 앞 단계의 값이 남습니다. 글자 스타일도 필드 단위로 합치므로, `fontWeight` 만 주면 기본 글자 역할과 색은 그대로입니다.
- `termWidth` 는 디자인 시스템 기본값이 없습니다. 비우면 용어 길이에 맞춥니다.

`mono: true` 인 목록의 설명 글자는 다음 순서로 겹칩니다.

```text
CoreDefinitionListStyle.defaultMonoDescriptionTextStyle   // 배치의 설명 기본값을 대신합니다
  → descriptionTextStyle         // 테마와 목록의 값을 합친 것
  → monoDescriptionTextStyle     // 테마와 목록의 값을 합친 것
```

- 그래서 `mono` 목록에서는 테마의 `monoDescriptionTextStyle` 이 목록 하나에 준 `descriptionTextStyle` 보다도 뒤에 겹칩니다.
- `monoDescriptionTextStyle` 에 `code-sm` 이 아닌 글자 역할을 주고, `descriptionTextStyle` 에는 역할 없이 크기나 줄 높이를 주면 두 플랫폼의 결과가 다릅니다. Flutter는 새 역할의 크기와 줄 높이로 그리고, Web은 `descriptionTextStyle` 에 준 값을 남깁니다. 두 플랫폼을 맞추려면 `monoDescriptionTextStyle` 의 글자 역할에 `copyWith` 로 크기와 줄 높이까지 적으세요.
- `descriptionTextStyle` 에 다른 글자 역할(`CoreTextStyle.token`)을 주면 `mono` 목록에서도 그 역할이 `code-sm` 자리를 대신합니다. 크기 · 줄 높이 · 서체가 그 역할을 따르므로, 본문 역할을 주면 코드 서체가 사라집니다. 모든 설명의 색만 바꿀 때는 역할 없이 `CoreTextStyle(color: ...)` 를 주세요.
- `numeric` 의 고정폭 숫자는 글자 스타일을 모두 합친 뒤에 켜집니다.

### 간격과 밀도

- 앱의 밀도가 `compact` 나 `spacious` 면 기본 간격과 `CoreSpace` 단계로 적은 `entrySpacing` · `pairSpacing` 이 4px 격자의 다음 칸으로 움직입니다. 4 이하는 움직이지 않으므로 `stacked` 의 쌍 안 간격 2는 그대로입니다. 단계 밖의 값은 두 플랫폼이 다르게 다룹니다(플랫폼 차이).
- Flutter는 두 간격과 `termWidth` 에 테마의 크기 배율을 곱합니다.
- `termWidth` 는 밀도의 영향을 받지 않습니다.

### 사용 예

<Split>

<Code language="dart" title="목록 하나만 바꾸기">
DefinitionList(
  items: const [
    CoreDefinitionEntry(term: '상품 금액', description: '1,111,000원'),
    CoreDefinitionEntry(term: '합계', description: '1,119,000원'),
  ],
  layout: CoreDefinitionLayout.columns,
  definitionListStyle: const CoreDefinitionListStyle(
    entrySpacing: CoreSpace.space12,
    termWidth: CoreSpace.space96,
    descriptionTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    definitionList: CoreDefinitionListTheme(
      style: CoreDefinitionListStyle(
        descriptionTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      ),
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `DefinitionList` 에 `withStyle` 을 이어 `definitionListStyle` 을 덧붙일 수 있습니다. 지금 스타일에 합치며, 겹치는 값은 나중에 붙인 것이 이깁니다. 아래 예제는 `columns` 목록의 쌍 안 간격을 16으로 넓히고, 용어 색을 `primary` 로, 설명 글자를 `body-large` 로 바꿉니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DefinitionListChainExample extends StatelessWidget {
  const DefinitionListChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ).withStyle(
      const CoreDefinitionListStyle(
        entrySpacing: CoreSpace.space24,
        pairSpacing: CoreSpace.space16,
        termTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        descriptionTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.onSurface),
        ),
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DefinitionListChainExample extends StatelessComponent {
  const DefinitionListChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DefinitionList(
      items: [
        CoreDefinitionEntry(term: '상호', description: '주식회사 코코드'),
        CoreDefinitionEntry(term: '대표', description: '한동우'),
        CoreDefinitionEntry(term: '사업자등록번호', description: '000-00-00000'),
      ],
      layout: CoreDefinitionLayout.columns,
      numeric: true,
    ).withStyle(
      const CoreDefinitionListStyle(
        entrySpacing: CoreSpace.space24,
        pairSpacing: CoreSpace.space16,
        termTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.primary),
        ),
        descriptionTextStyle: CoreTextStyle.token(
          CoreTextStyles.bodyLarge,
          color: CoreColor.token(CoreColors.onSurface),
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

값마다 자기 용어가 따라붙게 하는 것이 이 컴포넌트의 목적입니다. Web은 문서 구조로, Flutter는 접근성 정보로 그 관계를 남깁니다.

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 목록이나 정의 목록 역할을 붙이지 않습니다. 문자열 설명의 쌍은 한 노드의 이름(`label`)과 값(`value`)으로 전합니다. `columns` 는 Flutter의 `Table` 로 놓기 때문에 접근성 트리에 표 · 행 · 칸 역할이 생깁니다. |
| Jaspr Web | 네이티브 `<dl>` · `<dt>` · `<dd>` 입니다. 컴포넌트가 따로 붙이는 `role` · `aria-*` 는 없습니다. |

목록과 문자열 설명은 버튼이나 선택 컨트롤이 아닙니다.

### 키보드

없음. 표시 전용이라 목록이 처리하는 키도, `Tab` 이 멈추는 자리도 없습니다. `rich` 로 넣은 링크 · 버튼은 자기 키보드 동작을 그대로 가집니다.

### 스크린 리더

- **Web** — 루트는 `<dl>` 이고 바로 아래 자식은 `<dt>` 와 `<dd>` 뿐입니다. 쌍을 감싸는 `<div>` 를 두지 않으며, 세 배치 모두 `<dl>` 자신의 grid · flex로 놓습니다. 각 `<dt>` 바로 뒤에 그 용어의 `<dd>` 가 옵니다.
- **Flutter, 문자열 설명** — 한 쌍이 접근성 트리의 한 노드가 됩니다. `label` 이 용어, `value` 가 설명입니다. 화면에 그린 용어와 설명 텍스트는 노드를 따로 만들지 않아 같은 글이 두 번 담기지 않습니다.
- **Flutter, `rich` 설명** — 넣은 위젯의 접근성 정보와 동작을 버리지 않습니다. 누를 수 있는 위젯 하나만 넣으면 용어와 그 위젯의 글이 한 노드의 이름이 되고, 누르는 동작도 남습니다. 누를 수 있는 위젯을 여럿 넣으면 용어를 이름으로 가진 상위 노드 아래에 각각 따로 남습니다.
- **Flutter, `columns`** — 항목마다 표의 행이 하나씩 생기고, 위의 노드는 그 행의 칸 안에 놓입니다. 화면의 용어 열은 따로 칸을 만들지 않습니다.

화면 낭독기가 실제로 읽는 말과 탐색 방식은 낭독기 · 브라우저 · 기기에 따라 다릅니다.

#### 읽는 순서

`layout` 을 바꿔도 읽는 순서는 같습니다. 세 값 모두 Web은 같은 `<dt>` · `<dd>` 순서를, Flutter의 문자열 설명은 같은 순서의 `label` · `value` 를 갖습니다. Flutter의 `columns` 에는 그 둘레에 표 구조가 더해집니다.

### 포커스 관리

없음. 목록은 포커스를 받거나 옮기거나 가두지 않습니다. `rich` 로 넣은 위젯은 어느 `layout` 에서도 항목을 적은 순서로 놓입니다.

### 알려진 제약

| 대상 | 내용 |
| --- | --- |
| 공통 | 라이브 영역이 아니므로 값이 바뀌어도 따로 알리지 않습니다. |
| 공통 | `rich` 설명 안의 이름 · 역할 · 동작은 넣은 위젯이 정합니다. |
| Flutter | 정의 목록 구조를 알려 주는 정보를 붙이지 않습니다. `columns` 에 생기는 표 역할은 정의 목록이 아니라 표를 뜻합니다. |
| Flutter | 글자를 키우거나 폭이 좁아지면 `inline` 의 긴 용어는 넘칠 수 있고, `columns` 는 설명 열의 폭이 남지 않을 수 있습니다. 이런 화면에는 `stacked` 를 고릅니다. |
| Jaspr Web | `columns` 의 용어는 줄바꿈하지 않아(`termWidth` 가 없을 때) 좁은 화면이나 큰 글자에서 넘칠 수 있습니다. `inline` 은 용어와 설명이 서로 다른 줄로 갈라질 수 있습니다. |

#### 대비

`columns` · `inline` 의 용어와 문자열 설명은 글자 역할이 같고(`mono` 가 아닐 때), 놓인 순서와 색으로 구분됩니다. `stacked` 는 위아래 위치에 더해 글자 크기(12와 13)가 다릅니다. `mono` 를 켠 `stacked` 는 크기가 둘 다 12라서 위치와 굵기가 구분을 맡습니다. 용어 색을 바꾸더라도 색 하나로만 구분되게 만들지 마세요(WCAG 1.4.1).

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

클래스 이름(`DefinitionList`)과 두 플랫폼이 함께 갖는 속성 이름은 같고, 설명 타입과 그리는 방식은 각 플랫폼을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 설명 타입 | `Widget` | `Component` |
| 루트 | `Column` · `Table` · `Wrap` (배치별) | 언제나 `<dl>` |
| 쌍 관계 | 용어는 `ExcludeSemantics`, 설명 노드의 `Semantics` 가 용어를 `label` 로 가짐 | `<dt>` · `<dd>` 요소 |
| 표 역할 | `columns` 에서만 `Table` 의 표 · 행 · 칸 역할이 생김 | 세 배치 모두 `<dl>` · `<dt>` · `<dd>` 마크업 |
| `stacked` | `Column` 안에 쌍마다 `Column`. 간격은 각 `spacing` | 세로 flex `<dl>`. 간격은 `<dt>` · `<dd>` 의 위 margin |
| `columns` | `Table`. 용어 열은 `IntrinsicColumnWidth`(`termWidth` 가 있으면 `FixedColumnWidth`), 설명 열은 `FlexColumnWidth`, 기준선 정렬 | grid `max-content 1fr`(`termWidth` 가 있으면 `<rem> 1fr`) + `row-gap` · `column-gap`, 기준선 정렬 |
| `inline` | `Wrap` 안에 쌍마다 `Row` 하나. 쌍이 갈라지지 않음 | `<dl>` 의 flex-wrap. `<dt>` 와 `<dd>` 가 따로 줄을 넘김 |
| 넘어간 `inline` 줄 | 줄 첫머리에 간격이 없음 | 첫 요소의 앞 간격이 남음 |
| RTL 방향 | 간격과 열이 읽기 방향을 따름 | 간격이 논리 축(`margin-inline-start`)이라 방향을 따름 |
| `columns` 의 폭 | 받은 폭을 채움. 폭 제한이 없으면 설명 열이 0 | 블록 · 늘이는 세로 flex 부모에서는 채움. 늘이지 않는 flex 부모에서는 내용 폭 |
| 긴 용어(`columns`) | `termWidth` 가 없고 한 줄에 안 들어가면 줄바꿈하고, 설명 열에 폭이 남지 않음 | `termWidth` 가 없으면 줄바꿈 없이 넘침 |
| `numeric` | `FontFeature.tabularFigures()` | `tabular-nums` 클래스(`font-variant-numeric`) |
| `mono` 글꼴 | `code-sm` 역할. 패키지에 Geist Mono가 들어 있음 | `<dd>` 의 `text-code-sm` 클래스. 페이지에서 쓸 수 있는 Geist Mono, 없으면 Pretendard, `monospace` 순서 |
| `mono` 덮어쓰기 | `code-sm` 위에 `descriptionTextStyle`, `monoDescriptionTextStyle` 을 차례로 겹침 | 두 값을 먼저 합친 뒤 `code-sm` 위에 겹침. 결과가 달라지는 경우는 [값이 정해지는 순서](#값이-정해지는-순서) 참고 |
| 단계 밖 간격 | `compact` · `spacious` 에서 4보다 크고 간격 척도 범위 안이면 다음 칸으로 옮겨짐 | 밀도와 상관없이 적은 값 그대로 |
| 크기 단위 | 간격과 `termWidth` 에 테마의 크기 배율을 곱함 | 간격과 `termWidth` 는 `rem` 단위라 루트 글자 크기를 따름 |
| 브라우저 기본값 | 해당 없음 | `<dl>` 의 위아래 margin과 `<dd>` 의 40px 시작 쪽 들여쓰기를 지움 |
| 웹 전용 속성 | — | `id` · `classes` · `css` · `attributes` · `eventHandlers` |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 이름을 씁니다. 표의 `W` 는 Flutter의 `Widget`, Web의 `Component` 입니다. 항목이 하나도 없으면 두 플랫폼 모두 빈 목록을 그립니다.

### 목록

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `items` | `List<CoreDefinitionEntry<W>>` | 필수 | 놓는 순서대로 적은 용어 · 설명 쌍 |
| `layout` | `CoreDefinitionLayout` | `stacked` | 용어와 설명을 놓는 방식 — `inline` · `stacked` · `columns` |
| `numeric` | `bool` | `false` | 설명에 고정폭 숫자를 켭니다. |
| `mono` | `bool` | `false` | 설명을 코드 글자 역할(`code-sm`, Geist Mono)로 그립니다. `numeric` 과 함께 쓸 수 있습니다. |
| `definitionListStyle` | `CoreDefinitionListStyle?` | `null` | 간격 · 글자 · 용어 열 폭 덮어쓰기 |
| `key` | `Key?` | `null` | 위젯 · 컴포넌트의 키 |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` · `classes` · `css` | `String?` · `String?` · `Styles?` | `null` | 루트 `<dl>` 의 id, 더할 클래스, 인라인 스타일. 목록의 인라인 값과 겹치는 CSS 속성은 `css` 가 이깁니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트 `<dl>` 의 HTML 속성 |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 DOM 이벤트 |

### 항목 필드

`CoreDefinitionEntry<W>` 가 갖는 필드입니다. 두 생성자 모두 `description` 이라는 이름으로 값을 받고, 생성자에 따라 담기는 필드가 다릅니다.

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `term` | `String` | 값의 이름. 두 생성자 모두 필수입니다. |
| `descriptionText` | `String?` | 기본 생성자에 넘긴 문자열. `.rich` 항목은 `null` 입니다. |
| `description` | `W?` | `.rich` 에 넘긴 위젯 · 컴포넌트. 문자열 항목은 `null` 입니다. |

### 멤버

| 이름 | 설명 |
| --- | --- |
| `withStyle(CoreDefinitionListStyle patch)` | `definitionListStyle` 에 `patch` 를 합친 사본을 돌려줍니다. |
| `copyWith({...})` | 바꾼 값으로 사본을 만듭니다. `null` 이나 생략한 값은 지금 값이 남습니다. 웹은 웹 전용 속성도 받고, `classes` 는 지금 클래스에 더합니다. |

### 테마

| 이름 | 타입 | 설명 |
| --- | --- | --- |
| `CoreComponentTheme.definitionList` | `CoreDefinitionListTheme?` | 앱 전체의 DefinitionList 설정 |
| `CoreDefinitionListTheme.style` | `CoreDefinitionListStyle?` | 모든 목록에 적용할 스타일 |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDefinitionListStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `entrySpacing` | `double?` | Distance between one term / description pair and the next, in logical pixels. |
| `pairSpacing` | `double?` | Distance between a term and its own description, in logical pixels. |
| `termTextStyle` | `CoreTextStyle?` | `<dt>` typography override. Layered over the layout row of [defaultsByLayout] — a caller who sets only `fontWeight` keeps the default role and colour. The default differs per layout (`label-small` stacked, `label-medium` in columns and inline), so there is no single scalar default. |
| `descriptionTextStyle` | `CoreTextStyle?` | `<dd>` typography override. Layered over the layout row of [defaultsByLayout] (or [defaultMonoDescriptionTextStyle] when the list is `mono`) on the same terms as [termTextStyle]. |
| `monoDescriptionTextStyle` | `CoreTextStyle?` | `<dd>` typography override that applies only when the list is `mono`. Layered over [defaultMonoDescriptionTextStyle] and then over any [descriptionTextStyle], so a theme can recolour every description while a mono list alone changes its code weight. |
| `termWidth` | `double?` | Fixed width of the term column, in logical pixels — only `CoreDefinitionLayout.columns` reads it; `stacked` and `inline` ignore it. |

<!-- STYLE_TABLE:END -->

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="definition-list/related-table" title="Table">

한 행이 여러 열의 값을 갖는 2차원 데이터를 보여 줍니다.

</Card>
<Card demo="definition-list/related-description-card" title="DescriptionCard">

이름 · 값 목록에 카드 표면, 제목, 행 강조, 하단 액션을 함께 둡니다.

</Card>
<Card demo="definition-list/related-text-block" title="TextBlock">

라벨이 없는 문단을 씁니다.

</Card>
<Card demo="definition-list/related-stat" title="Stat">

지표 하나를 크게 보여 줍니다.

</Card>
</Cards>
