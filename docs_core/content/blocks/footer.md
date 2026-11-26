---
title: Footer
description: 페이지 하단에 최대 세 블록을 세로로 쌓는 푸터입니다. 상단 구분선, 브랜딩과 내비게이션 밴드, 법적 고지로 이루어지며, 비어 있는 슬롯은 통째로 생략됩니다.
design: true
---

# Footer

<a id="live-preview"></a>
<a id="개요"></a>
<a id="사용-시기-when-to-use"></a>
<a id="관련-컴포넌트-related-components"></a>

## 구조

Footer는 아래 컴포넌트를 조합합니다.

<BlockCatalogVisual kind="footer-structure" />

| 자리 | 컴포넌트 |
|---|---|
| 섹션 제목 | [Text](/components/text) (sections의 title 문자열을 Footer가 그림) |
| 섹션 본문, aside, 회사명, 저작권 | [Text](/components/text) (호출자가 넣는 위젯) |
| 법적 링크 줄 | [Link](/components/link) |
| 섹션 제목과 본문 사이 | [Gap](/components/gap) (sectionTitleGapStyle) |
| 상단 규칙, 행 안 눈금 | [Divider](/components/divider) |
| 사업자 정보 디스클로저 | [Collapsible](/components/collapsible) |

<a id="사용-가이드라인-usage-guidelines"></a>
<a id="do"></a>

## 레이아웃

layout은 내비게이션 밴드의 배치를 정하고, center는 법적 고지의 행과 글 정렬도 가운데로 맞춥니다. 상단 구분선과 법적 고지는 항상 밴드 위아래로 쌓입니다.

<BlockCatalogVisual kind="footer-layouts" />

| 값 | 설명 |
|---|---|
| `horizontal` | 기본. aside와 섹션이 한 줄에 놓이고, 좁으면 다음 줄로 넘어감 |
| `vertical` | 위에서 아래로 쌓고 앞쪽 정렬 |
| `center` | 위에서 아래로 쌓고 가운데 정렬. 법적 고지와 글 정렬도 가운데 |

`layout` 속성을 주면 스타일(`footerStyle` · 테마)의 `layout` 보다 우선합니다.

<a id="상단-구분선"></a>

`showDivider` 로 켜는 상단 구분선은 콘텐츠 여백 밖에 있어 푸터의 양 끝까지 닿습니다.

<a id="이-블록에-없는-것"></a>

메가 푸터, 뉴스레터, 큰 글자, 배경 이미지를 위한 속성은 없습니다. 이런 모양은 세 레이아웃과 슬롯에 넣는 위젯으로 조합합니다.

<a id="예제"></a>
<a id="기본-사용법-basic-usage"></a>

## 기본 사용법

<Code language="dart" title="Flutter · Web">
Footer(
  aside: const Text('© 2026 CoUI — Industrial Ltd.'),
  sections: const [
    CoreFooterNavData(
      title: 'Services',
      children: [Text('Branding'), Text('Design')],
    ),
  ],
)
</Code>

<a id="레시피"></a>
<a id="법적-고지"></a>
<a id="동작-스펙-behavior"></a>

법적 고지는 별도 레이아웃이 아니라 같은 `Footer` 의 슬롯입니다.

<Code language="dart" title="Flutter · Web">
Footer(
  company: const Text('Cocode Inc.'),
  businessInfoLabel: const Text('Business info'),
  businessInfo: const Text('CEO Jane Doe · Business registration no. 123-45-67890'),
  links: const [
    Link(href: '/terms', child: Text('Terms of service')),
    Link(href: '/privacy', child: Text('Privacy policy')),
  ],
  copyright: const Text('© 2026 Cocode Inc. All rights reserved.'),
  sections: const [],
)
</Code>

- `businessInfo` 가 없으면 트리거를 그리지 않으므로, `businessInfoLabel` 만 넘기면 라벨이 나타나지 않습니다. 반대로 `businessInfoLabel` 없이 `businessInfo` 만 넘기면 기본 라벨 없이 셰브론만 그립니다.
- `onBusinessInfoExpandedChanged` 를 넘기면 푸터는 스스로 펼치지 않습니다. 받은 값을 `businessInfoExpanded` 로 다시 넘겨야 화면이 바뀝니다.

<a id="props-parameters"></a>

## 속성

| 속성 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `sections` | `List<CoreFooterNavData<W>>` | `필수` | 내비게이션 섹션 목록 |
| `aside` | `W?` | `null` | 로고나 짧은 카피 등 브랜딩 |
| `layout` | `CoreFooterLayout?` | `horizontal` | 내비게이션 밴드 배치 |
| `company` | `W?` | `null` | 법적 고지 첫 줄의 회사명 |
| `businessInfoLabel` | `W?` | `null` | 사업자 정보 트리거 라벨 |
| `businessInfo` | `W?` | `null` | 펼쳐지는 사업자 정보 |
| `businessInfoExpanded` | `bool` | `false` | 디스클로저 초기 펼침 |
| `onBusinessInfoExpandedChanged` | `void Function(bool)?` | `null` | 주면 펼침 상태를 호출자가 관리 |
| `links` | `List<W>` | `[]` | 법적 링크 줄. 비면 생략 |
| `copyright` | `W?` | `null` | 저작권 줄 |
| `showDivider` | `bool` | `false` | 밴드 위 전체 폭 구분선 |
| `semanticLabel` | `String?` | `null` | 랜드마크 이름 |
| `footerStyle` | `CoreFooterStyle?` | `null` | 모든 스타일을 받는 한 곳 |

<a id="corefooternavdataw"></a>

`W` 는 Flutter 에서 `Widget`, Web 에서 `Component` 입니다. `CoreFooterNavData` 의 `title` 은 위젯이 아니라 문자열이고, 없거나 비면 제목과 그 아래 간격을 함께 생략합니다.

<a id="스타일-시스템-style-system"></a>
<a id="resolve-chain"></a>
<a id="값이-정해지는-순서"></a>

## 스타일

적용 순서는 디자인 시스템 기본값, 프로젝트 테마, 부모의 슬롯 재정의, 인스턴스의 footerStyle입니다. 뒤에 오는 값이 우선합니다.

<a id="corefooterstyle-필드"></a>

| 필드 | 설명 |
|---|---|
| `layout` | 레이아웃 재정의 |
| `padding` | 콘텐츠 상자의 여백 |
| `blockSpacing` | 내비게이션 밴드와 법적 고지 사이 간격 |
| `sectionSpacing` | 섹션 사이 간격 |
| `legalSpacing` | 법적 고지 행 사이 간격 |
| `companyRowSpacing` | 회사명, 눈금, 트리거 사이 간격 |
| `linkRowSpacing` | 법적 링크와 눈금 간격 |
| `inlineDividerLength` | 인라인 눈금 길이 |
| `sectionTitleGapStyle` | 섹션 제목과 본문 사이 Gap |
| `backgroundColor` | 배경색 |
| `titleTextStyle` | 섹션 제목 텍스트 |
| `bodyTextStyle` | 본문과 링크 텍스트 |
| `companyTextStyle` | 회사명 텍스트 |
| `copyrightTextStyle` | 저작권 텍스트 |
| `dividerStyle` | 상단 구분선 (CoreDividerStyle) |
| `inlineDividerStyle` | 인라인 눈금 (CoreDividerStyle) |
| `collapsibleStyle` | 디스클로저 (CoreCollapsibleStyle) |

<a id="빠른-오버라이드-chain"></a>

만든 `Footer` 에 `withStyle(...)` 를 이어 붙이면 `footerStyle` 에 합쳐지고(뒤에 붙인 값이 이김), `.surfaceContainer` 같은 색 토큰 이름의 getter 는 `backgroundColor` 를 바꿉니다.

<a id="접근성-accessibility"></a>
<a id="역할"></a>
<a id="키보드"></a>
<a id="포커스-관리"></a>
<a id="스크린-리더"></a>

## 접근성

| 항목 | 동작 |
|---|---|
| 역할 | 두 플랫폼 모두 contentinfo 랜드마크 |
| 이름 | semanticLabel, 없으면 로케일 기본값 (Footer, 바닥글) |
| 키보드 | Footer는 키를 처리하지 않습니다. 링크, 버튼, Collapsible 트리거가 각자 처리합니다. |
| 스크린 리더 | 디스클로저의 펼침 상태는 Collapsible이 알립니다. |

<a id="알려진-제약"></a>

<DesignNote title="알려진 제약">
섹션 제목에 헤딩 레벨이 없어 제목 단위로 건너뛸 수 없고, 링크 그룹은 리스트도 내비게이션 랜드마크(nav)도 아니어서 항목 수가 안내되지 않고 랜드마크로 건너갈 수도 없습니다. 회사명 옆과 링크 사이의 눈금은 장식이라 스크린 리더가 읽지 않습니다. businessInfoLabel에는 무엇을 여는지 설명하는 문구가 있어야 합니다.
</DesignNote>

<a id="dont"></a>

`semanticLabel` 에 빈 문자열을 넘기지 않습니다. Flutter 는 이름 없는 랜드마크의 역할을 떨어뜨려 푸터가 랜드마크 목록에서 사라지고, Web 은 이름이 빈 contentinfo 를 남깁니다. 생략하면 로케일 기본값이 쓰입니다.

<a id="크로스-플랫폼-차이점-platform-differences"></a>

## 플랫폼 차이

| 항목 | Flutter | Web |
|---|---|---|
| 루트 요소 | OutlinedContainer와 contentinfo 시맨틱 | footer 요소. tag는 요소 이름만 바꾸고 role="contentinfo"는 남음 |
| 레이아웃 | Wrap, Column | flex (flex-wrap, flex-col) |
| 회사명 · 저작권 글자 | DefaultTextStyle로 상속 | 슬롯을 감싼 요소의 글자 클래스 |
| 링크 줄 줄바꿈 | Wrap (linkRowSpacing을 가로세로에 씀) | flex와 gap |
| 회사명 줄 | 다음 줄로 넘어가지 않음. 긴 사업자 정보는 남은 폭 안에서 줄바꿈 | 좁으면 항목이 다음 줄로 넘어감 |
| 섹션 제목 · 본문 글자색 | 한 색 (bodyTextStyle의 색, 없으면 titleTextStyle의 색) | 제목과 본문에 각자의 색 |
| aside의 글자 | 본문 글자 스타일 전체를 물려받음 | 글자색만 물려받음 |
