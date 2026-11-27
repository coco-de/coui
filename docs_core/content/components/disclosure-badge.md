---
title: DisclosureBadge
description: 근거 자료를 지금 열 수 있는지, 열 수 없다면 어떤 조건인지를 글 · 외곽선 · 마커 점으로 알리는 표시 전용 배지입니다.
category: display
platforms: [flutter, web]
related: [link, badge, chip, validation-badge, status]
tags: [display, disclosure, evidence, accessibility]
template: v2
source: display/disclosure_badge
---

# DisclosureBadge

<a id="live-preview"></a>
<a id="기본-사용법-basic-usage"></a>

## 플레이그라운드

`kind` 와 모양을 바꿔 보며 배지를 확인하고, 만들어진 코드를 복사하세요. 근거 자료 하나를 **지금 열 수 있는지**를 짧은 글로 알리는 배지입니다. 채움 없이 외곽선과 글(`commitment` 는 마커 점도)만 그리며, 누르는 컨트롤이 아닙니다.

<Playground component="disclosure-badge" />

플레이그라운드에서 `kind` 를 바꾸면 문구도 함께 바뀌는데, 이는 `kind` 마다 정해 둔 예시 문구입니다. 컴포넌트는 `kind` 에 맞는 문구를 만들어 주지 않으므로, 실제 코드에서는 `label` 을 직접 넘깁니다.

자주 쓰는 모양은 아래와 같습니다. Flutter와 Web 코드가 같습니다.

```dart
// 지금 열 수 있는 근거
DisclosureBadge(
  kind: CoreDisclosureKind.open,
  label: '근거 공개',
)

// 아직 못 열지만 계약 시점에 넘기기로 한 근거
DisclosureBadge(
  kind: CoreDisclosureKind.commitment,
  label: '계약 시 제공',
)

// 열 수 없고 앞으로도 열리지 않는 근거. 라벨에 사유를 적습니다.
DisclosureBadge(
  kind: CoreDisclosureKind.private,
  label: '비공개 · NDA',
)
```

## 구조

외곽선 상자 하나 안에 마커 점과 라벨을 가로로 놓습니다. 마커 점은 `commitment` 에만 있습니다. 아래 그림은 세 부분이 모두 보이는 `commitment` 입니다.

<Anatomy demo="disclosure-badge/anatomy">
<AnatomyItem part="container" name="Container">

외곽선, 모서리, 안쪽 여백입니다. 배경은 채우지 않습니다. 기본값은 선 1px, 모서리 4, 여백 좌우 6 · 상하 2입니다.

</AnatomyItem>
<AnatomyItem select="span[aria-hidden]" side="top" name="marker">

`commitment` 에만 그리는 점입니다. 기본 지름 4의 원이고 라벨과 4만큼 떨어집니다. 색은 `foregroundColor` 를 따릅니다.

</AnatomyItem>
<AnatomyItem part="label" side="right" name="label">

공개 상태를 적는 글입니다. 필수이며 기본 글자 역할은 `labelSmall` 입니다.

</AnatomyItem>
</Anatomy>

<a id="변형-variants"></a>

## Variant

`kind`(`CoreDisclosureKind`)는 "지금 열 수 있는가" 라는 한 질문에 세 가지로 답합니다. 필수 값이라 기본값이 없습니다.

| `kind` | 지금 열 수 있나 | 외곽선 | 마커 점 | 기본 글자 · 점 색 | 기본 외곽선 색 |
| --- | --- | --- | --- | --- | --- |
| `open` | 열 수 있다 | 실선 | 없음 | `primary` | `primary` |
| `commitment` | 지금은 못 열고, 나중에 주기로 약속했다 | 실선 | 있음 | `onSurface` | `outline` |
| `private` | 열 수 없고, 앞으로도 열리지 않는다 | 점선 | 없음 | `onSurfaceVariant` | `outline` |

외곽선 모양과 마커 점의 유무는 `kind` 에 정해져 있습니다. 스타일 슬롯과 테마에는 이 둘을 고르는 필드가 없습니다. 색은 기본값이라 `disclosureBadgeStyle` 이나 테마로 바꿀 수 있습니다.

<a id="open-기본"></a>

<VariantRow name="open" component="disclosure-badge" props="kind=open" label="근거 공개">

근거를 지금 열어 볼 수 있는 상태입니다. 실선 외곽선에, 글자와 선 모두 `primary` 색을 씁니다. 세 `kind` 가운데 기본 색으로 `primary` 를 쓰는 것은 이것뿐입니다. 배지 자체는 링크가 아니므로 근거를 여는 동작은 [Link](/components/link)로 따로 둡니다.

</VariantRow>

<a id="commitment"></a>

<VariantRow name="commitment" component="disclosure-badge" props="kind=commitment" label="계약 시 제공">

아직 열 수 없지만 계약 체결이나 킥오프처럼 정해진 시점에 넘기기로 약속한 상태입니다. `open` 과 같은 실선이고, 글 앞의 마커 점이 색이 아닌 모양으로 둘을 가릅니다. 실선은 약속이 정해졌다는 뜻이고, 점은 자료가 아직 오지 않았다는 뜻입니다.

</VariantRow>

<a id="private"></a>

<VariantRow name="private" component="disclosure-badge" props="kind=private" label="비공개 · NDA">

열 수 없고 앞으로도 열리지 않는 상태입니다. 점선 외곽선을 쓰며, 끊긴 선의 틈은 색을 보지 않아도 읽히는 신호입니다. 기본 색은 `primary` 를 쓰지 않아, 열 수 있는 항목과 색으로도 갈립니다.

</VariantRow>

<a id="동작-스펙-behavior"></a>

## 상태

비활성이나 선택 같은 상태 값은 없습니다.

### 인터랙션

배지가 스스로 처리하는 누르기 · 호버 · 포커스는 없고, 마우스 커서도 바꾸지 않습니다.

- **Flutter** 는 상태와 제스처 처리가 없는 `StatelessWidget` 입니다. `Clickable` 을 쓰지 않습니다.
- **Web** 은 상태가 없는 `<span>` 입니다. 배지가 붙이는 `role` · `tabindex` 와 hover · active · focus 스타일이 없습니다.

### 상태 전환

- `kind` 를 바꾸면 그 `kind` 의 외곽선 모양, 마커 점 유무, 기본 색이 적용됩니다. `disclosureBadgeStyle` 에 직접 준 색은 `kind` 를 바꿔도 그대로입니다.
- `label` 은 `kind` 와 따로 넘기는 값입니다. `kind` 를 바꿀 때 문구도 함께 고칩니다.

### 애니메이션

배지가 따로 두는 전환 효과나 애니메이션은 없습니다.

<a id="사용-시기-when-to-use"></a>
<a id="사용-가이드라인-usage-guidelines"></a>

## 사용 가이드

### 이럴 때 씁니다

- 실적 · 레퍼런스 목록에서 항목마다 근거 자료를 지금 열 수 있는지 표시할 때
- 근거를 아직 열 수 없지만 계약이나 킥오프 시점에 주기로 약속할 때
- NDA · 보안 같은 이유로 비공개인 항목을 그 사유와 함께 밝힐 때
- 흑백으로 보아도 세 공개 상태가 모양으로 갈려야 할 때 (인쇄할 때는 접근성의 알려진 제약을 확인합니다)

### 다른 컴포넌트가 더 맞는 경우

| 이런 경우에는 | 대신 쓸 컴포넌트 |
| --- | --- |
| 근거를 실제로 여는 동작 | [Link](/components/link) |
| 선택하거나 제거하는 필터 · 태그 | [Chip](/components/chip) |
| 공개 여부가 아닌 상태 문구 · 개수 · 점 | [Badge](/components/badge) |
| 입력값의 검증 결과 | [ValidationBadge](/components/validation-badge) |
| 사용자나 시스템의 현재 상태를 점으로 표시 | [Status](/components/status) |

<a id="do"></a>
<a id="dont"></a>

### 공개 상태와 문구

<Cards columns="2">
<Card demo="disclosure-badge/do-reason" tone="do" eyebrow="이렇게 하세요">

`private` 라벨에는 왜 열 수 없는지를 함께 적습니다. 사유가 있어야 읽는 사람이 그 판단을 확인할 수 있습니다.

</Card>
<Card demo="disclosure-badge/dont-bare-private" tone="dont" eyebrow="이렇게 하지 마세요">

"비공개" 만 적으면 무언가를 숨기는 것처럼 읽힙니다. 코드는 사유가 있는지 검사하지 않으므로 문구를 쓸 때 챙깁니다.

</Card>
<Card demo="disclosure-badge/do-commitment" tone="do" eyebrow="이렇게 하세요">

나중에 주기로 한 자료는 `commitment` 로 표시하고, 언제 주는지를 라벨에 적습니다.

</Card>
<Card demo="disclosure-badge/dont-false-open" tone="dont" eyebrow="이렇게 하지 마세요">

지금 열 수 없는 자료를 `open` 으로 표시하지 않습니다. 문구는 나중에 준다고 말하는데 모양과 색은 지금 열린다고 말합니다.

</Card>
<Card demo="disclosure-badge/do-link" tone="do" eyebrow="이렇게 하세요">

근거를 여는 동작은 배지 옆에 `Link` 로 둡니다. 배지는 상태를 말하고 링크가 근거를 엽니다.

</Card>
<Card demo="disclosure-badge/dont-one-color" tone="dont" eyebrow="이렇게 하지 마세요">

세 `kind` 의 색을 하나로 맞추지 않습니다. 선 모양과 점은 남지만, 색으로 먼저 알아보던 구분이 사라집니다.

</Card>
</Cards>

```dart
// 사유를 함께 적습니다
DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · NDA')
DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · 고객사 요청')

// 약속한 제공 시점을 적습니다
DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '계약 시 제공')
DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '킥오프 시 제공')

// 하지 마세요: 사유 없는 "비공개"
DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개')

// 하지 마세요: 지금 열 수 없는 자료에 open 을 씁니다. 배지를 눌러도 열리는 것이 없습니다
DisclosureBadge(kind: CoreDisclosureKind.open, label: '근거 공개')

// 하지 마세요: 테마의 공통 style 로 색을 정하면 세 kind 가 한 색이 됩니다
CoreDisclosureBadgeTheme(
  style: CoreDisclosureBadgeStyle(
    foregroundColor: CoreColor.token(CoreColors.onSurface),
    borderColor: CoreColor.token(CoreColors.outline),
  ),
)
```

<a id="조합-예제"></a>

## 배치

### 제목 · 배지 · 링크

배지는 항목 이름 옆에 놓고, 지금 열 수 있는 항목에는 링크를 함께 둡니다.

<Preview demo="disclosure-badge/rows" />

Flutter 의 `Link` 는 눌렀을 때 할 일을 `onPressed` 로 받습니다. Web 의 `Link` 는 `onPressed` 를 주지 않으면 `href` 로 이동하는 `<a>` 를 그립니다. 그래서 두 플랫폼의 코드가 다릅니다.

<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text('브랜드 개편 사례').bodyMedium.onSurface,
    const Gap.space8(),
    const DisclosureBadge(
      kind: CoreDisclosureKind.open,
      label: '근거 공개',
    ),
    const Gap.space8(),
    Link(
      href: evidenceUrl,
      onPressed: openEvidence,
      child: const Text('근거 열기'),
    ),
  ],
)
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
div(classes: 'flex items-center', [
  Text('브랜드 개편 사례').bodyMedium.onSurface,
  const Gap.space8(),
  const DisclosureBadge(
    kind: CoreDisclosureKind.open,
    label: '근거 공개',
  ),
  const Gap.space8(),
  Link(href: evidenceUrl, child: const Text('근거 열기')),
])
```

  </TabItem>
</Tabs>

### 긴 라벨과 좁은 너비

- **Flutter** 는 `labelMaxLines` · `labelOverflow` 를 주지 않으면, 배지에 전달된 너비가 모자랄 때 라벨을 줄바꿈합니다. `Row` 에 바로 넣으면 너비 제한이 전달되지 않아 한 줄로 남습니다. 줄바꿈이 필요하면 `Flexible(child: DisclosureBadge(...))` 로 감쌉니다. 마커 점은 줄어들지 않고 지름을 지키며, 라벨이 남은 너비를 씁니다.
- **Web** 은 배지 루트에 `whitespace-nowrap` 이 있어 라벨을 줄바꿈하지 않습니다. `labelMaxLines` 에 2 이상을 줘도 한 줄입니다.

두 플랫폼에서 같게 보이려면 라벨을 짧게 쓰고, 긴 설명은 배지 밖의 본문에 둡니다.

<a id="스타일-시스템-style-system"></a>

## 테마와 스타일

`kind` · `label` · `labelMaxLines` · `labelOverflow` 는 위젯 파라미터로 넘기고, 색 · 선 · 모서리 · 여백 · 글자 · 마커 점의 값은 `disclosureBadgeStyle`(`CoreDisclosureBadgeStyle`)로 덮어씁니다. 필드는 API 섹션의 표에 있습니다.

### 이 슬롯이 일부러 제공하지 않는 것

- **배경색 필드가 없습니다.** 이 배지는 외곽선과 글로 된 표시이고, 채운 모양은 누를 수 있는 태그처럼 읽힐 수 있습니다.
- **hover · pressed · focus 필드가 없습니다.** 누르는 컨트롤이 아니라 꾸밀 상태가 없습니다.
- **외곽선 모양과 마커 점 유무를 정하는 필드가 없습니다.** 두 값은 `CoreDisclosureKind` 의 `stroke` 와 `hasMarker` 가 정합니다.
- **모든 `kind` 에 쓰는 기본 글자색 상수가 없습니다.** 기본 색은 `kind` 별 표인 `CoreDisclosureBadgeStyle.defaultsByKind` 에 있습니다.

<Note>

필드가 없다고 해서 외곽선과 점이 늘 보이는 것은 아닙니다. `borderColor` 를 투명하게 하면 선 모양이, `markerSize` 를 `0` 으로 두면 점이 보이지 않습니다. `borderWidth` 를 `0` 으로 두면 Web 은 선이 없어지고 Flutter 는 `private` 의 점선이 없어집니다(플랫폼 차이 섹션). 세 상태가 색 없이도 갈리도록 이 값들은 눈에 보이는 크기와 색으로 둡니다.

</Note>

### 값이 정해지는 순서

```text
디자인 시스템 기본값 (색은 defaultsByKind[kind], 나머지는 CoreDisclosureBadgeStyle.default*)
  → CoreDisclosureBadgeTheme.style               // 모든 배지
  → CoreDisclosureBadgeTheme.kindStyles[kind]    // 그 kind 의 배지
  → disclosureBadgeStyle                         // 인스턴스별
```

- 뒤 단계일수록 우선하고, 값을 준 필드만 덮습니다. `labelStyle` 은 그 안의 글자 속성끼리도 합칩니다.
- `foregroundColor` 는 라벨과 마커 점의 색을 함께 정합니다. 다만 어느 단계에서든 `labelStyle` 에 색을 주면 라벨은 그 색을 쓰고, `foregroundColor` 는 마커 점에만 적용됩니다.
- `kind` 는 테마로 바꿀 수 없고, 테마는 `kind` 마다 겉모습만 덮습니다. 프로젝트 설정만으로 "비공개" 배지가 "공개" 로 바뀌는 일을 막기 위해서입니다.

### 프로젝트 단위 오버라이드

`CoreDisclosureBadgeTheme` 에는 모든 배지에 적용하는 `style` 과 `kind` 마다 적용하는 `kindStyles` 가 있습니다. `CoreComponentTheme.disclosureBadge` 에 넣습니다.

<Split>

<Code language="dart" title="배지 하나만 바꾸기">
DisclosureBadge(
  kind: CoreDisclosureKind.commitment,
  label: '계약 시 제공',
  disclosureBadgeStyle: CoreDisclosureBadgeStyle(
    borderWidth: CoreStrokeWidth.stroke2,
    labelStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
  ),
)
</Code>

<Code language="dart" title="앱 전체 기본값 바꾸기">
ThemeData.fromCore(
  CoreThemePresets.light,
  coreComponentTheme: CoreComponentTheme(
    disclosureBadge: CoreDisclosureBadgeTheme(
      style: CoreDisclosureBadgeStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
      ),
      kindStyles: {
        CoreDisclosureKind.private: CoreDisclosureBadgeStyle(
          borderWidth: CoreStrokeWidth.stroke2,
        ),
      },
    ),
  ),
)
</Code>

</Split>

두 예제 모두 Flutter와 Web 코드가 같습니다.

<a id="빠른-오버라이드-chain"></a>

### 빠른 덮어쓰기

이미 만든 `DisclosureBadge` 에 `withStyle` 을 이어 `disclosureBadgeStyle` 을 덧붙입니다. 앞서 준 값과 필드 단위로 합치고, 같은 필드는 나중에 이은 값이 이깁니다. 아래 예제의 `foregroundColor` 는 라벨과 마커 점에 함께 적용됩니다(`labelStyle` 에 색이 없을 때).

`Badge` 의 `.primary` · `.surface` 처럼 면을 칠하는 색 getter 는 이 컴포넌트에 없습니다. 칠할 배경이 없기 때문입니다. 색은 `withStyle` 로 바꿉니다. Flutter 에서 `.surface` 는 모든 위젯에 쓸 수 있는 글자 꾸미기 체인이라 컴파일되지만, 배지의 면을 칠하지 않습니다.

<!-- CHAIN_SNIPPET:BEGIN — auto-generated by `dart run tool/generate_chain_artifacts.dart` (write mode). Do not hand-edit between these markers; edit the chain example sources (`*_chain_example.dart` / `*_code.dart`) and regenerate. -->
<Tabs groupId="platform">
  <TabItem label="Flutter" value="flutter">

```dart
class DisclosureBadgeChainExample extends StatelessWidget {
  const DisclosureBadgeChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '킥오프 시 제공',
    ).withStyle(
      const CoreDisclosureBadgeStyle(
        foregroundColor: CoreColor.token(CoreColors.primary),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space4,
        ),
        labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
        markerSize: CoreSize.size6,
        markerSpacing: CoreSpace.space6,
      ),
    );
  }
}
```

  </TabItem>
  <TabItem label="Web" value="web">

```dart
class DisclosureBadgeChainExample extends StatelessComponent {
  const DisclosureBadgeChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const DisclosureBadge(
      kind: CoreDisclosureKind.commitment,
      label: '킥오프 시 제공',
    ).withStyle(
      const CoreDisclosureBadgeStyle(
        foregroundColor: CoreColor.token(CoreColors.primary),
        borderColor: CoreColor.token(CoreColors.primary),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        padding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space8,
          vertical: CoreSpace.space4,
        ),
        labelStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
        markerSize: CoreSize.size6,
        markerSpacing: CoreSpace.space6,
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

| 플랫폼 | 역할 |
| --- | --- |
| Flutter | 배지가 역할을 알리는 `Semantics` 를 붙이지 않습니다. 버튼이나 링크로 알리지 않습니다. |
| Jaspr Web | 배지가 `role` 을 붙이지 않는 `<span>` 입니다. |

#### 색 이외의 수단 (WCAG 1.4.1)

- 기본 모양에서 세 `kind` 는 **외곽선 모양**(실선 · 점선)과 **마커 점**(있음 · 없음)의 조합이 서로 달라, 색을 보지 않아도 갈립니다.
- `label` 이 필수라 상태를 글로도 적습니다.
- 투명한 선이나 크기 0 의 점처럼 이 모양을 가리는 스타일 값은 쓰지 않습니다(테마와 스타일 섹션).

### 키보드

| 키 | 동작 |
| --- | --- |
| 없음 | 표시 전용이라 포커스를 받지 않아 탭 순서에 들어가지 않고, 처리하는 키도 없습니다. |

근거를 여는 동작이 필요하면 배지 옆에 [Link](/components/link)를 둡니다.

### 스크린 리더

- 배지에서 글로 전달되는 것은 `label` 입니다. 두 플랫폼 모두 `kind` 이름이나 외곽선 모양을 알리는 글 · 속성을 따로 붙이지 않습니다.
- **Flutter** 는 마커 점을 `ExcludeSemantics` 로 감쌉니다.
- **Web** 은 마커 `<span>` 에 `aria-hidden="true"` 를 붙입니다.
- Web 루트에는 `select-none` 이 없습니다. 배지가 라벨의 글자 선택을 막지 않습니다.

### 포커스 관리

없음. 포커스를 받지 않으므로 처음 포커스, 포커스 가두기, 되돌리기가 없습니다. 옆에 둔 링크의 포커스는 그 링크가 맡습니다.

### 알려진 제약

- `kind` 는 보조 기술에 따로 전달되지 않습니다. `label` 만 읽어도 공개 상태를 알 수 있게 쓰고, `private` 라면 사유까지 적습니다.
- `kind` 나 `label` 이 바뀐 것을 알리는 라이브 영역은 두 플랫폼 모두 없습니다.
- 빈 `label` 은 `assert` 로만 막습니다. 릴리스 빌드에서는 `assert` 가 실행되지 않고, 공백만 있는 문자열은 디버그 빌드에서도 통과합니다.
- Web 의 마커 점은 배경색으로만 칠한 빈 `<span>` 이고, 배지에는 인쇄나 강제 색상 모드를 위한 별도 스타일이 없습니다. 그런 환경에서 `open` 과 `commitment` 를 구분해야 하면 실제 결과에서 점이 보이는지 확인하고, 라벨 문구로도 구분되게 씁니다.
- Web 은 라벨을 줄바꿈하지 않습니다(배치 섹션).

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

`kind` · `label` · `labelMaxLines` · `labelOverflow` · `disclosureBadgeStyle` 은 두 플랫폼이 같은 API 입니다.

| 항목 | Flutter | Jaspr Web |
| --- | --- | --- |
| 루트 | 실선은 `DecoratedBox`, 점선은 `CustomPaint` | `<span>` |
| 점선 외곽선 | Flutter 의 `Border` 에 점선이 없어 직접 그립니다. 선 3 · 틈 2(`CoreDashedBorder`)에 `theme.scaling` 을 곱합니다. | `border-dashed` 클래스(CSS 점선). 선과 틈의 길이를 따로 정하지 않습니다. |
| 긴 라벨 | `labelMaxLines` · `labelOverflow` 를 주지 않으면 전달된 너비 안에서 줄바꿈합니다. | 한 줄로 둡니다(`whitespace-nowrap`). |
| `labelMaxLines` | `Text` 의 `maxLines` 로 넘깁니다. | `-webkit-line-clamp` 를 붙이지만 라벨이 줄바꿈되지 않아 여러 줄이 되지 않습니다. |
| `labelOverflow` | 같은 이름의 `TextOverflow` 로 넘깁니다. `ellipsis` 를 `labelMaxLines` 없이 주면 줄바꿈하지 않고, 너비를 넘는 첫 줄에서 말줄임합니다. | `ellipsis` 는 `overflow: hidden` 과 `text-overflow: ellipsis`, `clip` 과 `fade` 는 `overflow: hidden`(흐려지는 효과 없음), `visible` 은 `overflow: visible` 입니다. `labelMaxLines` 를 함께 주면 어느 값이든 `overflow: hidden` 이고, `text-overflow: ellipsis` 는 값이 `ellipsis` 이거나 없을 때만 붙습니다. |
| `borderWidth: CoreStrokeWidth.stroke0` | `open` · `commitment` 에는 너비 0 의 선(1 물리 픽셀 헤어라인)이 남고, `private` 의 점선은 그리지 않습니다. | 선을 그리지 않습니다. 선 너비가 `--coui-stroke-width-0`(0px)이 됩니다. |
| 마커 점 숨김 | `ExcludeSemantics` | `aria-hidden="true"` |
| 색 | 토큰을 현재 색 구성표의 색으로 계산합니다. | 토큰 색은 클래스로, 직접 만든 색 값은 인라인 스타일로 적용합니다. |
| 모서리 · 여백 · 선 굵기 | 테마의 모양 · 밀도 설정(`theme.geometry`)을 반영하고 `theme.scaling` 을 곱해 계산합니다. | 기본값도 인라인 스타일입니다. 토큰 단계의 값은 `--coui-radius-*` · `--coui-space-*` · `--coui-stroke-width-*` 변수를 읽습니다. |
| HTML 속성 | 없음 | `id` · `classes` · `css` · `attributes` · `eventHandlers` 가 루트 `<span>` 에 닿습니다. |

<Note>

Web 의 모서리 · 여백 · 선 굵기는 인라인 스타일이라, `!important` 가 없는 제품 CSS 의 클래스 규칙보다 우선합니다. 이 값은 `disclosureBadgeStyle` 로 바꿉니다. `css` 와 `classes` 는 배치에 쓰고, `border-style` 처럼 `kind` 의 모양을 덮는 스타일은 넣지 않습니다.

</Note>

<a id="props-parameters"></a>

## API

### 속성

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `kind` | `CoreDisclosureKind` | 필수 | 공개 상태 — `open` · `commitment` · `private`. 외곽선 모양, 마커 점, 기본 색을 정합니다. |
| `label` | `String` | 필수 | 공개 상태를 적는 글. 빈 문자열은 `assert` 에 걸립니다. `private` 에는 사유를 함께 적습니다. |
| `labelMaxLines` | `int?` | `null` | 라벨의 최대 줄 수. `null` 이면 줄 수를 정하지 않습니다. Web 은 값과 상관없이 라벨을 줄바꿈하지 않습니다. |
| `labelOverflow` | `CoreTextOverflow?` | `null` | 넘치는 라벨의 처리 — `clip` · `fade` · `ellipsis` · `visible`. 플랫폼마다 다릅니다(플랫폼 차이). |
| `disclosureBadgeStyle` | `CoreDisclosureBadgeStyle?` | `null` | 겉모습 덮어쓰기 |

`withStyle(patch)` 은 `patch` 를 `disclosureBadgeStyle` 에 합친 복사본을 돌려줍니다. `copyWith` 는 넘긴 값만 바꾼 복사본을 만들고, `null` 을 넘긴 값은 지금 값을 유지합니다. Web 의 `copyWith` 에 넘긴 `classes` 는 기존 클래스에 합칩니다.

### `CoreDisclosureKind`

`kind` 의 각 값은 모양을 정하는 속성 둘을 가집니다. `CoreDisclosureStroke` 의 값은 `solid` 와 `dashed` 입니다.

| 이름 | 타입 | `open` | `commitment` | `private` |
| --- | --- | --- | --- | --- |
| `stroke` | `CoreDisclosureStroke` | `solid` | `solid` | `dashed` |
| `hasMarker` | `bool` | `false` | `true` | `false` |

### 웹 전용

| 이름 | 타입 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `id` | `String?` | `null` | 루트의 id |
| `classes` | `String?` | `null` | 루트에 덧붙이는 클래스 |
| `css` | `Styles?` | `null` | 루트의 인라인 스타일. 배지의 인라인 스타일 뒤에 합칩니다. |
| `attributes` | `Map<String, String>?` | `null` | 루트의 HTML 속성 — `data-*`, 테스트 id |
| `eventHandlers` | `Map<String, List<UiEventHandler>>?` | `null` | 루트의 DOM 이벤트. 핸들러를 달아도 역할이나 키보드 동작은 생기지 않습니다. 누르는 동작에는 `Link` 나 `Button` 을 씁니다. |

<!-- STYLE_TABLE:BEGIN — auto-generated by `dart run tool/generate_style_tables.dart` (write mode). Do not hand-edit between these markers; edit the CoreXxxStyle source and regenerate. -->

### `CoreDisclosureBadgeStyle` 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `foregroundColor` | `CoreColor?` | Label + marker colour override. `null` defers to `defaultsByKind[kind]!.foreground`. |
| `borderColor` | `CoreColor?` | Outline colour override. `null` defers to `defaultsByKind[kind]!.borderColor`. |
| `borderWidth` | `double?` | Outline stroke width override. `null` defers to [defaultBorderWidth]. |
| `borderRadius` | `CoreBorderRadius?` | Corner radius override. `null` defers to [defaultBorderRadius]. |
| `padding` | `CoreEdgeInsets?` | Padding around the label. `null` defers to [defaultPadding]. |
| `labelStyle` | `CoreTextStyle?` | Label typography override. `null` defers to [defaultLabelStyle]. |
| `markerSize` | `double?` | Diameter of the [CoreDisclosureKind.commitment] marker dot in logical px. `null` defers to [defaultMarkerSize]. Only consumed by the kinds whose [CoreDisclosureKind.hasMarker] is `true`. |
| `markerRadius` | `CoreBorderRadius?` | Marker corner radius override. `null` defers to [defaultMarkerRadius] — a full circle. |
| `markerSpacing` | `double?` | Gap between the marker dot and the label in logical px. `null` defers to [defaultMarkerSpacing]. |

<!-- STYLE_TABLE:END -->

<Note>

표의 `foregroundColor` 는 `labelStyle` 에 색이 없을 때 라벨에 적용됩니다. `labelStyle` 에 색을 주면 라벨은 그 색을 쓰고, `foregroundColor` 는 마커 점에만 남습니다.

`padding` 에는 좌우를 직접 정하는 `CoreEdgeInsets` 생성자(`all` · `symmetric` · `only` · `fromLTRB`)를 씁니다. `CoreEdgeInsets.directional` 을 주면 두 플랫폼 모두 배지를 그릴 때 `ArgumentError` 가 납니다.

</Note>

<a id="관련-컴포넌트-related-components"></a>

## 관련 컴포넌트

<Cards columns="2">
<Card demo="disclosure-badge/related-link" title="Link">

근거를 실제로 여는 동작입니다. `open` 배지 옆에 함께 둡니다.

</Card>
<Card demo="disclosure-badge/related-badge" title="Badge">

상태 · 개수 · 분류를 표시하는 범용 배지입니다. 톤은 공개 여부를 뜻하지 않아, 공개와 비공개를 가르는 모양이 정해져 있지 않습니다.

</Card>
<Card demo="disclosure-badge/related-chip" title="Chip">

선택하거나 제거할 수 있는 태그입니다. 누를 수 없는 공개 상태 표시에는 DisclosureBadge 를 씁니다.

</Card>
<Card demo="disclosure-badge/related-validation-badge" title="ValidationBadge">

입력값이 규칙을 통과했는지 알리는 배지입니다. 근거의 공개 상태와는 다른 일을 합니다.

</Card>
</Cards>
