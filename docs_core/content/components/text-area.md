---
title: TextArea
description: 여러 줄의 글을 입력받는 텍스트 영역입니다.
category: form
platforms: [flutter, web]
related: [text-field, form]
tags: [multiline, textarea, text, form, resize]
template: v2
source: form/text_area
---

# TextArea

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

속성을 바꿔 보며 TextArea 를 확인하고, 만들어진 코드를 그대로 복사하세요.

<Playground component="text-area" />

TextArea 는 여러 줄의 글을 입력받습니다. 한 줄 입력과 지우기 · 비밀번호 보기 버튼은 [TextField](/components/text-field) 가 맡습니다. 두 컴포넌트는 같은 크기 단계 · 같은 테두리 · 같은 글자 단계를 쓰므로 한 폼 안에 나란히 놓아도 어긋나지 않습니다.

```dart
TextArea(
  label: '문의 내용',
  placeholder: '궁금한 점을 적어 주세요',
  rows: 4,
  onChanged: setMessage,
)
```

<a id="구조-anatomy"></a>

## 구조

TextArea 는 라벨, 박스, 도움말, 글자 수로 이루어집니다. 박스 안에는 글자 칸이 있고, 그 아래에 `footer` 줄을 둘 수 있습니다.

<Anatomy demo="text-area/anatomy">
<AnatomyItem select="label > span" side="left" name="label">

박스 위의 필드 라벨. `required: true` 면 끝에 `*` 가 붙습니다.

</AnatomyItem>
<AnatomyItem select="textarea" side="left" name="text">

글을 입력하는 칸. 비어 있으면 `placeholder` 를 보여 줍니다.

</AnatomyItem>
<AnatomyItem select="p" side="left" name="description">

박스 아래 도움말. `errorText` 가 있으면 그 자리에 오류 문구가 나옵니다.

</AnatomyItem>
<AnatomyItem select="p ~ span" side="right" name="counter">

글자 수. `showCounter: true` 일 때 도움말 줄 끝에 `n / maxLength`(`maxLength` 가 없으면 `n`)로 보입니다.

</AnatomyItem>
</Anatomy>

`prefix` · `suffix` 는 글자 칸의 앞 · 뒤에, `footer` 는 글자 아래 박스 안에 놓입니다. 앞 · 뒤 아이콘의 색은 `affixColor` 가 정합니다.

<a id="변형-variants"></a>

## Variant

배경이 있는 화면에서는 filled 를, 그 밖에는 기본(defaultVariant)을 씁니다.

<VariantRow name="defaultVariant" component="text-area" props="variant=defaultVariant;placeholder=내용을 입력해 주세요;rows=2">

테두리가 있는 기본 영역입니다.

</VariantRow>

<VariantRow name="filled" component="text-area" props="variant=filled;placeholder=내용을 입력해 주세요;rows=2">

테두리 대신 채움으로 경계를 나타냅니다. 카드나 시트처럼 이미 틀이 있는 면 위에 씁니다.

</VariantRow>

<Note>

error 는 보통 직접 고르지 않습니다. 활성 영역에 `errorText` 를 주면 넘긴 변형보다 error 가 이기고, 비활성일 때는 꺼집니다. `variant: CoreTextAreaVariant.error` 를 직접 넘기면 `errorText` 없이도 오류 모양이 됩니다.

</Note>

<a id="크기-토큰"></a>

## 크기

`sm` 부터 `xl2` 까지 다섯 단계입니다. 단계가 오르면 처음 높이 · 안쪽 여백 · 모서리가 함께 커지고, 모서리는 같은 크기의 TextField 와 같습니다.

<SizeSpec component="text-area" props="placeholder=내용" />

<Note>

처음 높이는 값 글자 4줄과 위아래 여백을 더한 값입니다. 안쪽 여백은 네 변이 같습니다. Jaspr Web 은 지금 처음 높이를 따르지 않고 모든 크기를 `minHeight`(기본 100) 높이로 그립니다(→ 알려진 제약). `xs` 는 사라질 예정이라 표에서 뺐습니다(`CoreTextAreaContract.retiringSizes`) — 지금은 자기 값으로 그려지고 assert 가 켜진 실행에서 경고가 한 번 나옵니다. 행이 지워지면 `sm` 으로 그려지므로 새 코드는 `sm` 을 씁니다.

</Note>

<a id="동작-스펙-behavior"></a>
<a id="시각적-토큰-통일"></a>

## 상태

TextArea 는 TextField 와 같은 상태 색을 씁니다.

<Preview demo="text-area/states" />

| 항목 | 동작 |
| --- | --- |
| 쉴 때 | 테두리 `outlineVariant`, 채움 `surface`, 값 `onSurface`, 안내 글자 `placeholder`. filled 는 채움 `surfaceContainer` |
| Hover | 테두리가 `outline` 으로 한 단 진해집니다. 오류 영역은 `error` 그대로입니다. filled 는 채움 · 테두리가 `surfaceContainerHigh` 가 됩니다. Web 의 filled 는 포인터가 글자 칸 위에 있을 때 글자 칸만 물들고, footer 가 있으면 테두리만 바뀝니다. |
| Focus | 테두리가 `primary`(오류 영역은 `error`)로 바뀝니다. 바깥 링은 키보드로 포커스했을 때만 그립니다 — 마우스 · 터치로 누른 포커스는 테두리 색이 이미 말합니다. 테두리 굵기는 1 그대로라 박스 크기가 변하지 않습니다. |
| 오류 | `errorText` 가 있고 활성일 때. 테두리와 링이 `error` 이고, 도움말 대신 오류 문구가 나옵니다. |
| 비활성 | 채움 `disabledContainer`(filled 는 `surfaceContainerLow`), 테두리 `disabledOutline`(filled 는 `surfaceContainerLow`), 값과 안내 글자 `disabledContent`. 비활성이 오류보다 우선하지만, 오류 문구는 비활성이어도 보입니다. Web 에서 footer 가 없는 영역은 테두리가 쉬는 색(`outlineVariant`, filled 는 `surfaceContainer`)에 머물고, 포인터를 올리면 hover 색으로 바뀝니다. |
| 읽기 전용 | 고치지 못하지만 선택 · 복사는 됩니다. |
| 전환 시간 | 테두리 색은 바로 바뀝니다. `transitionDuration`(150ms)은 Web 에서 글자 칸의 색 전환에만 쓰입니다. |

글자 색은 TextField 와 같은 세 단계입니다 — 값 `onSurface`, 라벨 `onSurfaceVariant`, 도움말과 앞 · 뒤 아이콘 `onSurfaceSubtle`. 비활성 라벨도 `onSurfaceSubtle` 이라 활성 라벨과 구분되면서 읽을 수 있습니다.

### 높이와 줄 수

- `rows` 를 주면 그 줄 수만큼의 높이로 그리고, 글이 넘치면 박스 안에서 스크롤합니다.
- `rows` 도 높이도 주지 않으면 Flutter 는 크기 단계의 처음 높이(`initialHeight`, `md` 108)로 엽니다. 높이는 `textAreaStyle` 의 `initialHeight` 로 바꿉니다. Jaspr Web 은 지금 이 높이를 따르지 않고 `minHeight`(기본 100) 높이로 그립니다.
- TextArea 는 글에 따라 저절로 자라지 않습니다. `minHeight` · `maxHeight` 는 끌어서 크기를 바꿀 때의 하한 · 상한이고, Web 에서는 박스의 최소 · 최대 높이로도 걸립니다 — `minHeight` 기본 100 이 Web 박스의 바닥입니다.
- Flutter 에서 `rows: 1` 이면 한 줄 필드가 됩니다. `Enter` 가 줄바꿈 대신 편집을 끝내고, 붙여 넣은 줄바꿈은 지워집니다.

<a id="인터랙션"></a>

### 크기 조절

`expandableHeight` · `expandableWidth` 를 켜면 오른쪽 아래 모서리를 끌어 크기를 바꿀 수 있습니다. Flutter 에서 가로 끌기는 `textAreaStyle` 의 `initialWidth` 로 처음 폭을 정해 둔 영역에서만 폭을 바꿉니다 — 기본값(사용할 수 있는 폭을 모두 채움)에서는 가로로 끌어도 폭이 그대로이고 `onWidthChanged` 도 불리지 않습니다.

<Preview demo="text-area/resizable" />

```dart
TextArea(
  expandableHeight: true,
  placeholder: '오른쪽 아래 모서리를 끌어 높이를 바꿔 보세요',
  onChanged: setMessage,
  textAreaStyle: const CoreTextAreaStyle(minHeight: 96, maxHeight: 240),
)
```

- Flutter 는 모서리에 끌기 손잡이를 그리고, 끄는 동안 크기를 `minHeight` ~ `maxHeight`(가로는 `minWidth` ~ `maxWidth`) 안에 둡니다. `textAreaStyle` 이 바뀌면 끌어서 바꾼 크기는 처음으로 돌아갑니다.
- Web 은 브라우저의 크기 조절 손잡이를 보여 줍니다 — 허용한 축에 따라 손잡이가 생기고, 끄면 사라집니다. 모서리의 표시는 장식입니다. 다만 지금은 글자 칸의 높이가 내용으로 고정돼 있어 세로로 끌어도 박스 높이가 바뀌지 않고, `onHeightChanged` 도 불리지 않습니다(→ 알려진 제약).
- `onHeightChanged` · `onWidthChanged` 는 끌 수 있는 축에서 크기가 실제로 바뀔 때만 불립니다. Web 은 처음 마운트된 크기는 바뀐 것으로 보지 않아 알리지 않습니다.

### footer

`footer` 는 글자 아래, 박스 안에 놓이는 한 줄입니다 — 보내기 · 첨부처럼 입력한 글에 대해 하는 동작을 둡니다.

<Preview demo="text-area/footer" />

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
TextArea(
  rows: 1,
  placeholder: '메시지를 입력해 주세요',
  onChanged: setMessage,
  footer: Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Button(size: .sm, onPressed: send, child: const Text('보내기')),
    ],
  ),
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
TextArea(
  rows: 1,
  placeholder: '메시지를 입력해 주세요',
  onChanged: setMessage,
  footer: div(
    [Button(size: .sm, onPressed: send, child: const Text('보내기'))],
    classes: 'flex flex-row justify-end',
  ),
)
```

  </TabItem>
</Tabs>

- footer 는 박스의 내용 폭을 받고 시작 쪽에 놓입니다. 동작을 끝 쪽에 두려면 `Row` · `flex` 로 줄을 채웁니다. 글자와의 간격은 `footerGapStyle`(기본 12)입니다.
- 글을 입력하는 곳은 글자 칸뿐입니다. footer 를 누르면 그 안의 내용만 반응하고, 커서를 놓거나 영역에 포커스를 주지 않습니다.
- 박스의 포커스 테두리는 글자 칸의 포커스만 따릅니다 — `Tab` 으로 footer 의 버튼에 가면 박스는 쉬는 모양으로 돌아갑니다.
- `rows` 를 주면 그 줄 수와 footer 를 담을 만큼 박스가 자랍니다. 주지 않으면 Flutter 는 처음 높이의 박스에서 footer 가 남긴 몫을 글자 칸이 쓰고, Web 은 내용과 footer 의 높이로 그립니다. Web 은 `minHeight`(기본 100)가 바닥이라, 내용이 그보다 낮은 박스(`rows: 1` + footer)는 Flutter 보다 높게 그립니다.
- 크기 조절 손잡이는 글자 칸의 모서리(footer 위)에 놓여 footer 의 동작과 겹치지 않습니다. 끌면 footer 를 포함한 박스 전체 크기가 바뀌고, 알리는 높이도 footer 를 포함합니다.
- 영역을 비활성으로 해도 footer 안의 내용은 꺼지지 않습니다. footer 의 버튼은 부르는 쪽이 함께 끕니다(`onPressed: null`).

<a id="유효성"></a>

### 글자 수와 오류

- `maxLength` 를 주면 그 글자 수에서 입력이 멈춥니다. Flutter 는 사람이 보는 글자 단위(그래핌)로 세고, Web 은 브라우저의 `maxlength` 라 UTF-16 단위로 셉니다 — 이모지처럼 두 단위인 글자는 Web 에서 더 일찍 멈춥니다. `showCounter: true` 면 도움말 줄 끝에 글자 수가 나오고, 도움말과는 12 떨어집니다(`counterGapStyle`). 이 글자 수는 두 플랫폼 모두 그래핌으로 셉니다.
- `errorText` 가 있으면 그 줄에 도움말 대신 오류 문구가 나옵니다. 영역이 활성일 때만 오류 모양으로 바뀝니다.
- `required: true` 면 라벨 끝에 `*` 가 붙습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 한 줄이면 충분한 값(이름 · 제목 · 이메일) | [TextField](/components/text-field) |
| 정해진 선택지에서 고를 때 | [Select](/components/select) |
| 편집하지 않고 선택 · 복사만 하게 할 때 | [SelectableText](/components/selectable-text) |
| 여러 필드를 묶어 함께 검증할 때 | [Form](/components/form) |

### 안내와 오류

<Cards columns="2">
<Card component="text-area" props="label=문의 내용;description=답변은 이메일로 보내 드립니다.;placeholder=궁금한 점을 적어 주세요;rows=2" tone="do" eyebrow="이렇게 하세요">

라벨로 무엇을 쓸지 알리고, 도움말로 조건을 적습니다.

</Card>
<Card component="text-area" props="label=문의 내용;description=최소 10자 이상 입력하세요;errorText=필수 입력입니다;rows=2" tone="dont" eyebrow="이렇게 하지 마세요">

늘 봐야 하는 조건을 도움말에만 두지 않습니다. 오류가 나면 그 자리에 오류 문구가 나와 조건이 사라집니다.

</Card>
<Card tone="do" eyebrow="이렇게 하세요">

끌어서 키울 수 있게 할 때는 `maxHeight` 로 상한을 줍니다. 기본 상한이 없어 화면 끝까지 늘어날 수 있습니다.

</Card>
<Card tone="dont" eyebrow="이렇게 하지 마세요">

한 줄이면 충분한 값에 TextArea 를 쓰지 않습니다. TextField 를 씁니다.

</Card>
</Cards>

<a id="스타일-시스템-style-system"></a>
<a id="스타일-시스템-textareastyle"></a>

## 테마와 스타일

variant · 크기 · 줄 수 · 크기 조절은 위젯 속성으로 고르고, 보이는 값은 `textAreaStyle`(`CoreTextAreaStyle`) 하나로 덮어씁니다. 글자 정렬(`textAlign` · `textAlignVertical`), 처음 높이와 최소 · 최대 크기, 커서의 색 · 굵기 · 모서리도 이 안에 있습니다. 브라우저는 커서의 색만 바꿀 수 있어서, 커서의 굵기 · 모서리와 `backgroundCursorColor` 는 Flutter 에서만 그려집니다.

<Split>

<Code language="dart" title="TextArea 하나만 바꾸기">
TextArea(
  rows: 4,
  onChanged: setMessage,
  textAreaStyle: CoreTextAreaStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    padding: CoreEdgeInsets.symmetric(
      horizontal: CoreSpace.space16,
      vertical: CoreSpace.space12,
    ),
    maxHeight: 240,
    valueStyle: CoreTextStyle.token(CoreTextStyles.bodyMedium),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    textArea: CoreTextAreaTheme(
      style: CoreTextAreaStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
      variantStyles: {
        true: CoreTextAreaStyle(
          backgroundColor: CoreColor.token(CoreColors.errorContainer),
        ),
      },
    ),
  ),
)
</Code>

</Split>

<a id="textareastyle-슬롯"></a>
<a id="테마-커스터마이징-theme"></a>

`CoreTextAreaTheme` 의 `variantStyles` 는 variant 가 아니라 **오류 여부**(`bool`)로 찾습니다 — `true` 는 `errorText` 가 있고 영역이 활성일 때입니다. 그래서 앱 전체에서 filled 영역만 따로 바꾸는 자리는 없습니다. `enableSuggestions` · `selectAllOnFocus` · `cursorOpacityAnimates` 같은 입력 동작의 기본값은 테마가 아니라 `CoreTextAreaContract` 의 `default*` 상수에서 옵니다.

### 빠른 오버라이드 (Chain)

이미 만든 `TextArea` 에 스타일을 덧붙이고 싶다면 `withStyle` 체인을 쓸 수 있습니다. 생성자의 `textAreaStyle` 인자와 같게 동작합니다. `.radius16` 처럼 Core 토큰 상수와 같은 이름의 getter 도 있습니다 — 이름이 곧 값이라 어느 컴포넌트에서 써도 뜻이 같습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class TextAreaChainExample extends StatefulWidget {
  const TextAreaChainExample({super.key});

  @override
  State<TextAreaChainExample> createState() => _TextAreaChainExampleState();
}

class _TextAreaChainExampleState extends State<TextAreaChainExample> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).withStyle(
          const CoreTextAreaStyle(
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
class TextAreaChainExample extends StatefulComponent {
  const TextAreaChainExample({super.key});

  @override
  State<TextAreaChainExample> createState() => _TextAreaChainExampleState();
}

class _TextAreaChainExampleState extends State<TextAreaChainExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderWidth)까지 한 번에.
        TextArea(placeholder: '내용을 입력해 주세요', rows: 4).withStyle(
          const CoreTextAreaStyle(
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

<a id="resolve-chain"></a>

### 값이 정해지는 순서

```text
기본값 (default* · defaultsBySize[size] · defaultsByVariant[변형])
  → CoreComponentTheme.textArea.style                        // 앱 전체
  → CoreComponentTheme.textArea.variantStyles[오류이고 활성]  // 앱 전체, 오류 여부별
  → textAreaStyle                                            // 인스턴스
```

뒤로 갈수록 우선합니다. 변형은 활성 영역에 `errorText` 가 있으면 error, 아니면 넘긴 `variant` 입니다. 비활성 영역은 오류가 있어도 박스 모양에 `false` 행을 쓰고, 오류 문구의 스타일(`errorStyle` · `errorTextColor`)만 계속 `true` 행에서 읽습니다.

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreTextAreaStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `backgroundColor` | `CoreColor?` | Background fill colour override. |
| `borderColor` | `CoreColor?` | Border stroke colour override (idle state). |
| `focusBorderColor` | `CoreColor?` | Border stroke colour when focused. |
| `hoverBorderColor` | `CoreColor?` | Border stroke colour while the pointer is over the field. `null` → the variant's own `hoverBorderColor` (`on-surface` on the ordinary area, `error` on the error one), else the resting `borderColor` for a variant that states none. |
| `errorBorderColor` | `CoreColor?` | Border stroke colour when in error state. |
| `borderWidth` | `double?` | Border stroke width override (logical px, pre-scaling) — the resting boundary, which stays in the layout. `null` → [defaultBorderWidth]. |
| `activeBorderWidth` | `double?` | Width of the active boundary (logical px, pre-scaling) — a focused area, or one wearing the error variant while enabled (`disabled > error`). `null` → [defaultActiveBorderWidth]. |
| `borderRadius` | `CoreBorderRadius?` | Border radius override (pre-scaling). `null` → the size row's corner (`defaultsBySize[size].borderRadius`, the TextField's for that size). |
| `initialHeight` | `double?` | Initial textarea height (logical px). `null` defers to [defaultInitialHeight]. |
| `initialWidth` | `double?` | Initial textarea width (logical px). `null` defers to [defaultInitialWidth] — i.e. fill the available width. |
| `minHeight` | `double?` | Minimum height constraint when resizable (logical px). `null` defers to [defaultMinHeight]. |
| `minWidth` | `double?` | Minimum width constraint when resizable (logical px). `null` defers to [defaultMinWidth]. |
| `maxHeight` | `double?` | Maximum height constraint (logical px). `null` defers to [defaultMaxHeight] — i.e. unbounded. |
| `maxWidth` | `double?` | Maximum width constraint (logical px). `null` defers to [defaultMaxWidth] — i.e. unbounded. |
| `padding` | `CoreEdgeInsets?` | Padding override (logical px). |
| `labelGapStyle` | `CoreGapStyle?` | Space between the label and the field. Laid over [defaultLabelGapStyle] (`lg` and up widen it, see [defaultsBySize]) and passed as is to `Gap(gapStyle:)`, which applies scaling. |
| `descriptionGapStyle` | `CoreGapStyle?` | Space between the field and the description / error text below it. Laid over [defaultDescriptionGapStyle] (`lg` and up widen it, see [defaultsBySize]) and passed as is to `Gap(gapStyle:)`, which applies scaling. |
| `footerGapStyle` | `CoreGapStyle?` | Space between the text row and the footer, inside the box; read only when the area has a footer. Laid over [defaultFooterGapStyle] and passed as is to `Gap(gapStyle:)`, which applies scaling. |
| `counterGapStyle` | `CoreGapStyle?` | 1-off spacer slot between the helper line (sibling 1) and the character count (sibling 2). Forwarded raw to `Gap(gapStyle:)`. Read only when the area shows a counter. |
| `rowSpacing` | `double?` | Spacing between the prefix / input / suffix row children (mirrors Flutter `Row.spacing`). |
| `dragHandlePadding` | `CoreEdgeInsets?` | Padding inside the resize drag-handle hit area. |
| `dragHandleOffset` | `double?` | Offset of the resize drag handle from the bottom-right corner. |
| `dragHandleSize` | `double?` | Size of the square resize drag-handle hit area. |
| `iconStyle` | `CoreIconStyle?` | Icon style shared by the leading / trailing icons (prefix / suffix), passed as is to `Icon`, which applies scaling. `null` uses the size row's icon style, `CoreTextAreaStyle.defaultsBySize[size]!.iconStyle!`. |
| `transitionDuration` | `Duration?` | Colour-transition duration override for border / focus states. |
| `textAlign` | `CoreTextAlign?` | Horizontal text alignment override. |
| `textAlignVertical` | `CoreVerticalAlign?` | Vertical text alignment override. |
| `cursorColor` | `CoreColor?` | Cursor colour override. |
| `cursorWidth` | `double?` | Cursor width override (logical px, pre-scaling). |
| `labelDisabledColor` | `CoreColor?` | Disabled-state label colour override, forwarded to the composed `FormLabel` as its `disabledColor`. `null` → [defaultLabelDisabledColor]. |
| `helperTextColor` | `CoreColor?` | Helper text colour override. `null` → [defaultHelperTextColor]. |
| `affixColor` | `CoreColor?` | Prefix / suffix affix colour override — the glyphs and any affix text, in every state. `null` → [defaultAffixColor]. |
| `errorTextColor` | `CoreColor?` | Error text colour override. `null` → [defaultErrorTextColor]. |
| `requiredMarkColor` | `CoreColor?` | Required-mark (`*`) colour override. `null` → [defaultRequiredMarkColor]. |
| `dragHandleColor` | `CoreColor?` | Resize drag-handle glyph colour override. `null` → [defaultDragHandleColor]. |
| `selectionColor` | `CoreColor?` | Text-selection tint colour override. `null` → [defaultSelectionColor]. |
| `backgroundCursorColor` | `CoreColor?` | Background-cursor (composition/IME) colour override. `null` → [defaultBackgroundCursorColor]. |
| `cursorRadius` | `CoreBorderRadius?` | Cursor corner radius override. |
| `focusOutlineStyle` | `CoreFocusOutlineStyle?` | Focus ring of the text area — ring colour, radius, width, offset and gap colour. `null`, or any field left unset, uses [defaultFocusOutlineStyle]. A `borderColor` set here wins over [focusBorderColor] and the variant's focus-ring tone; a `borderRadius` set here wins over the area's own [borderRadius]. |
| `baseTextStyle` | `CoreTextStyle?` | Base text style applied to the editable text content. |
| `labelStyle` | `CoreTextStyle?` | Label text style override — forwarded into the composed `FormLabel`. |
| `placeholderStyle` | `CoreTextStyle?` | Placeholder text style override. |
| `valueStyle` | `CoreTextStyle?` | Selected/typed value text style override. |
| `descriptionStyle` | `CoreTextStyle?` | Description / helper text style override. |
| `counterStyle` | `CoreTextStyle?` | Character-count text style override (#5747) — the `n / max` line at the helper row's end while `showCounter` is on. Merges onto [defaultCounterStyle]. |
| `errorStyle` | `CoreTextStyle?` | Text style of the error message — the helper text under the box. The box's own error look (border, focus ring) comes from [defaultErrorVariant], not from here. |

<!-- STYLE_TABLE:END -->

<Note>

위 표의 설명은 소스 주석에서 만들어지며, 몇 필드는 지금 동작과 다릅니다.

- `hoverBorderColor` — 기본 영역의 hover 테두리는 `outline` 입니다(오류 영역은 `error`, filled 는 `surfaceContainerHigh`).
- `activeBorderWidth` — 포커스된 영역에서만 쓰입니다. 쉬는 오류 영역은 `borderWidth` 그대로입니다.
- `errorBorderColor` — Web 에서만 오류 테두리 색을 바꿉니다. Flutter 에서는 효과가 없습니다.
- `iconStyle` — 앞 · 뒤 아이콘 칸의 크기만 정합니다. 색은 `affixColor` 가 정하고 `iconStyle` 의 `color` 는 쓰이지 않습니다.
- `transitionDuration` — Web 의 글자 칸 색 전환에만 쓰입니다. 테두리 색은 두 플랫폼 모두 바로 바뀝니다.
- `placeholderStyle` — Flutter 는 글자 스타일 전체를, Web 은 색만 반영합니다.

</Note>

<a id="접근성-accessibility"></a>

## 접근성

Jaspr Web 은 네이티브 `<textarea>` 를 그대로 쓰고, Flutter 는 편집기의 텍스트 필드 노드를 씁니다. 두 플랫폼 모두 라벨이 필드의 이름으로 연결되지 않습니다(→ 알려진 제약).

### 역할

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 편집기가 만드는 텍스트 필드 노드입니다. 여러 줄(`rows: 1` 이면 한 줄), 활성 여부, 읽기 전용(비활성도 읽기 전용으로 읽힘), 마스킹, 포커스 상태를 알리고, 활성일 때만 포커스 동작을 내놓습니다. 라벨 · 도움말 · 오류 · 글자 수 · 안내 글자는 이 노드와 따로 있는 글자입니다. 끌기 손잡이는 역할과 이름이 없지만, 이름 없는 스크롤 동작을 내놓을 수 있습니다(테스트로 고정되지 않음). |
| Jaspr Web | 네이티브 `<textarea>`(여러 줄 `textbox`)입니다. 필드에는 `aria-*` 가 없고, 출력 전체에서 유일한 것은 `required` 일 때 라벨의 `*` 에 붙는 `aria-hidden="true"` 입니다. 접근성 상태로 읽히는 것은 `disabled` · `readonly` · `required` 와, 이름 대신 쓰일 수 있는 `placeholder` 입니다. 모서리의 크기 조절 표시는 장식 `<div>` 입니다. |

### 키보드

컴포넌트에는 따로 키 처리가 없습니다. 키 동작은 Flutter 편집기와 브라우저 `<textarea>` 의 기본 동작입니다.

| 키 | Flutter | Jaspr Web |
| --- | --- | --- |
| `Tab` · `Shift` · `Tab` | 필드로 · 필드에서 포커스를 옮깁니다. 비활성 영역도 정지점으로 남습니다. | 같습니다. 비활성 영역은 건너뜁니다. |
| `Enter` | 줄바꿈. `rows: 1` 이면 편집을 끝내 `onEditingComplete` → `onSubmitted` 를 부르고, `onEditingComplete` 가 없으면 포커스를 놓습니다. | 언제나 줄바꿈. `textInputAction` 은 가상 키보드의 키 이름만 바꿉니다(`enterkeyhint`). |
| 화살표 · `Home` · `End` · `Shift` 선택 · 복사 · 붙여넣기 | 편집기의 기본 편집 단축키 | 브라우저 기본 |
| `Escape` | 처리하지 않습니다. 선택 툴바가 떠 있으면 편집기가 닫습니다. | 처리하지 않습니다. |

여러 줄 영역에서 `Enter` 는 줄바꿈이라 `onSubmitted` 를 부르지 않습니다. Flutter 는 `textInputAction` 의 키보드 동작에서, Web 은 값을 바꾼 채 포커스를 잃을 때(`change`) 부릅니다. 크기를 바꾸는 키는 없습니다.

### 스크린 리더

- **Jaspr Web** — `label` 은 이름이 되지 않습니다. `placeholder` 를 주면 브라우저가 그 문구를 이름 대신 쓸 수 있고, 둘 다 없으면 이름이 비어 있습니다. 도움말 · 오류 문구는 필드에 연결되지 않습니다.
- **Flutter** — 필드 노드에 이름을 주는 연결이 없어, `label` · `errorText` 가 노드의 이름 · 상태로 전달되지 않고 따로 있는 글자로 읽힙니다. 접근성이 켜진 웹 엔진은 이 노드의 포커스 동작으로 편집을 엽니다.

두 플랫폼 모두 값 변경, 오류 등장, 글자 수 변화, 크기 변화를 알리지 않습니다 — 라이브 리전이 없습니다.

### 포커스 관리

- **진입** — 오버레이가 아니라 열림에 따른 포커스 이동이 없습니다. `autofocus: true`(기본 `false`)면 처음 그릴 때 포커스를 가져갑니다. 글자 칸을 누르면 포커스가 들어오고, footer 가 있으면 글자 칸만 포커스를 줍니다. 라벨을 눌러도 두 플랫폼 모두 포커스가 옮겨지지 않습니다.
- **이탈** — 포커스를 되돌리는 코드가 없습니다. Flutter `rows: 1` 의 `Enter` 만 예외입니다(위 키보드 표).
- **트랩** — 없습니다. 끌기 손잡이와 브라우저의 크기 조절 손잡이는 정지점이 아니고, footer 안의 컨트롤은 글자 칸 다음 정지점입니다.
- **포커스 링** — 키보드로 포커스했을 때만 바깥 링을 그립니다. 키보드로 받은 뒤 마우스로 눌러도 링은 남습니다.
- `selectAllOnFocus: true`(기본 `false`)면 포커스가 들어오는 순간 값 전체가 선택됩니다.

### 알려진 제약

| 플랫폼 | 내용 |
| --- | --- |
| Jaspr Web | `label` 이 `<textarea>` 에 연결되지 않아 필드의 이름이 되지 않고, 라벨을 눌러도 포커스가 옮겨지지 않습니다. |
| Jaspr Web | 도움말 · 오류 · 글자 수가 필드의 설명으로 연결되지 않고, 오류 때 `aria-invalid` 도 붙지 않습니다. 같은 킷의 Web TextField 는 오류 때 `aria-invalid` 를 냅니다. |
| Jaspr Web | 생성자의 `id` · `attributes` 는 바깥 `<div>` 에 붙어, `<textarea>` 에 이름을 붙이거나 바깥 `<label for>` 로 가리킬 수 없습니다. |
| Jaspr Web | 글자 칸의 높이가 언제나 내용 높이로 고정되어, 크기 단계의 처음 높이(`initialHeight`)와 끌어서 바꾼 높이가 그려지지 않습니다. 박스는 모든 크기에서 `minHeight`(기본 100) 높이이고, 세로 크기 조절 손잡이를 끌어도 높이가 그대로입니다. |
| Jaspr Web | footer 가 없는 비활성 영역의 테두리는 쉬는 색(`outlineVariant`)으로 남습니다. Flutter 는 `disabledOutline` 입니다. |
| Flutter | 필드 노드에 이름 · 필수 · 오류 상태가 없습니다. 라벨의 `*` 도 읽히지 않아 필수 여부가 전달되지 않습니다. |
| Flutter | 비활성 영역도 `Tab` · `autofocus` 로 포커스를 받고, 끌기 손잡이도 그려지고 끌립니다. Web 은 비활성이면 포커스도 크기 조절도 되지 않습니다. |
| Flutter | 끌기 손잡이의 누르는 영역이 16 × 16 으로 [접근성](/accessibility) 페이지의 최소 24 × 24 에 못 미칩니다. `dragHandleSize` 로 키우면 그리는 표시도 함께 커집니다. Web 에서 이 값은 장식 표시의 크기만 바꿉니다. |
| Flutter | `rows` 를 준 영역은 세로로 끌어도 높이가 바뀌지 않고 `onHeightChanged` 만 불립니다. |
| 공통 | 크기 조절은 포인터로만 됩니다. 키보드로 크기를 바꿀 길이 없으니, 크기를 고정해야 하면 `expandable*` 을 끄고 `rows` 를 줍니다. |
| 공통 | 값 · 오류 · 글자 수 · 크기의 변화를 알리지 않습니다. |

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

API는 같지만, 렌더링 결과는 각 플랫폼의 기본 방식을 따릅니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 편집하는 곳 | 편집기의 여러 줄 입력. `rows: 1` 이면 한 줄 | 네이티브 `<textarea>`(언제나 여러 줄) |
| 바깥에서 글 · 포커스 다루기 | `controller` · `focusNode` | 없음 — `initialValue` 와 `onChanged` |
| 편집 끝 알림(`onSubmitted`) | 키보드 동작, `rows: 1` 이면 `Enter` | 값을 바꾼 채 포커스를 잃을 때(`change`) |
| 처음 높이 | 크기 단계마다 다름(`md` 108) | 지금은 모든 크기가 `minHeight`(100) |
| 크기 조절 | 위젯이 그리는 끌기 손잡이 | 브라우저 손잡이, 크기는 `ResizeObserver` 로 알림. 지금 세로 조절은 높이를 바꾸지 못함 |
| `rows` 를 준 박스의 높이 | 내용(줄 수 + footer)이 정함 — `minHeight` 는 끌 때의 하한 | 내용이 정하되 `minHeight`(기본 100)가 바닥 |
| 비활성 영역 | `Tab` · `autofocus` 로 포커스 가능, 손잡이도 끌림 | 포커스 · 크기 조절 불가 |
| 필수 알림 | 없음 | 네이티브 `required` |
| 안내 글자 | 편집기 뒤에 겹친 글자 | 네이티브 `placeholder` — 이름 대신 쓰일 수 있음 |
| `onTap` | 글자 칸을 누를 때, 읽기 전용이면 부르지 않음 | 누를 때마다(읽기 전용이어도) |
| `onTapOutside` | 포커스가 있는 동안 바깥을 누를 때 | 마운트된 동안 바깥을 누를 때마다(포커스와 무관) |
| 폼 값(`name`) | 쓰이지 않음 | `<textarea name>` 으로 폼과 함께 제출 |
| `maxLength` 로 입력을 멈추는 기준 | 그래핌 | UTF-16 단위(브라우저 `maxlength`) |
| 커서의 굵기 · 모서리 | `cursorWidth` · `cursorRadius` 대로 | 브라우저 커서 — 색만 바뀜 |
| 입력 포매터 | `TextInputFormatter` | `CoreInputFormatter` |
| 마스킹 | 편집기의 `obscureText` | CSS `-webkit-text-security` 의 세 모양 |
| 고급 편집 UI | 선택 손잡이 · 확대경 · 되돌리기 등 | 브라우저 기본 텍스트 서비스 |

<a id="props-parameters"></a>

## API

Flutter와 Jaspr Web이 같은 속성을 씁니다. `W` 는 Flutter 의 `Widget`, Web 의 `Component` 입니다.

### 값과 내용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `initialValue` | `String?` | `null` | 처음 값. 처음 그릴 때만 읽습니다. |
| `placeholder` | `String?` | `null` | 비어 있을 때 보이는 안내 |
| `label` | `String?` | `null` | 박스 위 필드 라벨 |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. 지정하지 않으면 제한하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 최대 줄 수를 넘긴 라벨의 처리 |
| `description` | `String?` | `null` | 박스 아래 도움말. `errorText` 가 있으면 숨깁니다. |
| `errorText` | `String?` | `null` | 지정하면 오류 상태가 됩니다. |
| `required` | `bool` | `false` | 라벨에 필수 표시를 붙입니다. |
| `maxLength` | `int?` | `null` | 최대 글자 수 |
| `showCounter` | `bool` | `false` | 도움말 줄 끝에 글자 수를 보여 줍니다. |
| `prefix` · `suffix` | `W?` | `null` | 글자 칸 앞 · 뒤의 내용 |
| `footer` | `W?` | `null` | 글자 아래 박스 안의 한 줄 |
| `name` | `String?` | `null` | 폼 제출에 쓰는 이름. Web 만 씁니다. |

### 상태와 형태

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `variant` | `CoreTextAreaVariant` | `defaultTextAreaVariant`(`defaultVariant`) | defaultVariant, error, filled |
| `size` | `CoreComponentSize` | `md` | sm ~ xl2. `xs` 는 사라질 예정입니다. |
| `enabled` | `bool` | `true` | false 면 비활성 |
| `readOnly` | `bool` | `false` | 고치지 못하게 합니다. |
| `autofocus` | `bool` | `false` | 처음 그릴 때 포커스를 가져갑니다. |
| `selectAllOnFocus` | `bool` | `false` | 포커스가 들어오면 값 전체를 선택합니다. |
| `rows` | `int?` | `null` | 보이는 줄 수 |
| `expandableHeight` · `expandableWidth` | `bool` | `false` | 끌어서 높이 · 폭을 바꾸게 합니다(→ 크기 조절). |
| `scrollPadding` | `CoreEdgeInsets` | `CoreTextAreaContract.defaultScrollPadding`(네 변 20) | 필드를 화면 안으로 스크롤할 때 둘레에 남기는 여백. Flutter 에서만 이 뜻입니다 — Web 은 `<textarea>` 자신의 `scroll-padding` 으로 내보내므로, 페이지가 필드를 화면 안으로 옮길 때의 여백에는 닿지 않습니다. |
| `textAreaStyle` | `CoreTextAreaStyle?` | `null` | 보이는 값 덮어쓰기 |

### 콜백

| 이름 | Flutter 타입 | Web 타입 | 설명 |
| --- | --- | --- | --- |
| `onChanged` | `CoreValueChanged<String>?` | 같음 | 입력할 때마다 값을 받습니다. |
| `onSubmitted` | `CoreValueChanged<String>?` | 같음 | 편집을 끝낼 때(→ 키보드) |
| `onEditingComplete` | `VoidCallback?` | `CoreVoidCallback?` | `onSubmitted` 바로 앞에 불립니다. |
| `onTap` | `VoidCallback?` | `CoreVoidCallback?` | 글자 칸을 누를 때(→ 플랫폼 차이) |
| `onTapOutside` | `TapRegionCallback?` | `void Function()?` | 바깥을 누를 때(→ 플랫폼 차이) |
| `onHeightChanged` · `onWidthChanged` | `ValueChanged<double>?` | `CoreValueChanged<double>?` | 끌어서 크기를 바꿀 때. 끌 수 있는 축에서만 불립니다. |

<a id="입력-동작-폼-양-플랫폼"></a>

### 입력 동작

| 이름 | Flutter 타입 | Web 타입 | 기본값 | 설명 |
| --- | --- | --- | --- | --- |
| `autocorrect` | `bool?` | `bool?` | `null` | 자동 교정. `null` 이면 플랫폼이 정합니다. |
| `obscureText` | `bool` | `bool` | `false` | 글자를 가립니다. |
| `obscuringCharacter` | `String` | `String` | `'•'` | 가리는 문자. Web 은 `•` · `○` · `■` 세 모양 중 가까운 것으로 그립니다. |
| `showCursor` | `bool?` | `bool?` | `null` | 커서 표시 |
| `keyboardType` | `TextInputType?` | `String?` | `null` | 가상 키보드 종류(Web 은 `inputmode`) |
| `textInputAction` | `TextInputAction?` | `String?` | `null` | 가상 키보드의 동작 키(Web 은 `enterkeyhint`) |
| `textCapitalization` | `TextCapitalization` | `String?` | `none` · `null` | 자동 대문자(Web 은 `autocapitalize`) |
| `inputFormatters` | `List<TextInputFormatter>?` | `List<CoreInputFormatter>?` | `null` | 입력하는 동안 글을 바꾸는 포매터 |

가린 영역은 두 플랫폼 모두 자동 교정 · 제안 · 자동 대문자 · 맞춤법 검사에서 빠집니다. `textCapitalization` 을 지정해도 가리기가 이깁니다.

<a id="flutter-전용-확장"></a>

### Flutter 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `controller` · `focusNode` | `TextEditingController?` · `FocusNode?` | `null` | 바깥에서 글 · 포커스를 다룹니다. |
| `textDirection` | `TextDirection?` | `null` | 읽기 방향 |
| `cursorOpacityAnimates` | `bool` | `true` | 커서가 서서히 깜빡입니다. |
| `maxLengthEnforcement` | `MaxLengthEnforcement?` | `null` | 글자 수 제한을 적용하는 방식 |
| `enableSuggestions` | `bool` | `true` | 입력 제안 |
| `enableInteractiveSelection` | `bool` | `!readOnly \|\| !obscureText` | 선택 제스처를 허용합니다. |
| `enableIMEPersonalizedLearning` | `bool` | `true` | 입력기의 개인화 학습 |
| `stylusHandwritingEnabled` | `bool` | `true` | 스타일러스 필기 입력 |
| `spellCheckConfiguration` | `SpellCheckConfiguration?` | `null` | 맞춤법 검사. `null` 이면 꺼 둡니다. |
| `autofillHints` | `Iterable<String>?` | `null` | 자동 채우기 힌트 |
| `magnifierConfiguration` | `TextMagnifierConfiguration?` | `null` | 터치로 선택을 끌 때 보이는 확대경 |
| `scrollController` · `scrollPhysics` | `ScrollController?` · `ScrollPhysics?` | `null` | 글자 칸의 스크롤 |
| `selectionControls` · `contextMenuBuilder` · `undoController` | | `null` | 선택 손잡이 · 메뉴 · 되돌리기 |
| `selectionHeightStyle` · `selectionWidthStyle` | `BoxHeightStyle` · `BoxWidthStyle` | `tight` | 선택 영역의 모양 |
| `keyboardAppearance` · `dragStartBehavior` · `clipBehavior` · `restorationId` | | | Flutter 의 편집기에 그대로 넘깁니다. |

Web 은 이 기능을 브라우저의 `<textarea>` · 포커스 · 스크롤 · 메뉴로 제공합니다.

<a id="web-전용-확장"></a>

### Jaspr Web 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `cols` | `int?` | `null` | HTML `cols` 속성(한 줄의 글자 수 어림) |
| `id` · `classes` · `css` · `attributes` · DOM 이벤트 | | | 바깥 `<div>` 에 붙습니다(→ 알려진 제약). |

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="3">
<Card component="text-field" props="placeholder=제목" title="TextField">

한 줄 입력과 지우기 · 비밀번호 보기 버튼을 씁니다.

</Card>
<Card demo="text-area/related-form" title="Form">

여러 필드를 묶어 함께 검증하고 제출합니다.

</Card>
<Card component="select" props="placeholder=카테고리" title="Select">

정해진 선택지에서 하나를 고릅니다.

</Card>
</Cards>
