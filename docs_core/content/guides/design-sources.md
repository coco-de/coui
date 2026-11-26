---
title: 설계 문서 기준
description: 값은 coui_core 한 곳에서 정합니다. coco-de/docs의 문서는 값의 출처가 아니라 결정 기록이며, 이 페이지는 어느 문서가 정본인지 판정합니다.
design: true
---

# 설계 문서 기준

<a id="ssot-정의"></a>

## 코드와 문서가 다를 때

| 상황 | 처리 |
|---|---|
| 코드에 근거 주석이나 테스트가 있음 | 문서를 갱신합니다 |
| 코드에 근거가 없음 | 코드를 문서에 맞춥니다 |
| 문서끼리 다름 | 우선순위 규칙으로 판정하고, 그래도 안 되면 별도 결정 이슈로 보냅니다 |

<a id="문서-73종의-두-종류"></a>

## 문서 73종

값을 정의하는 것은 명세뿐입니다. 코드가 참조해야 할 후보도 이 34개입니다.

<Cards variant="outlined">
<Card value="34" title="명세">

값을 정의합니다. *_Specification.md 33개와 색상 문서 1개

</Card>
<Card value="36" title="결정 기록">

결정 이유를 서술합니다. 값의 출처가 아닙니다.

</Card>
<Card value="3" title="안내">

README. 폴더 색인이라 판정 대상이 아닙니다.

</Card>
</Cards>

<a id="전체-카탈로그-73종"></a>
<a id="색상"></a>
<a id="타이포그래피"></a>
<a id="컴포넌트-분류-taxonomy"></a>
<a id="디자인-토큰-프리미티브"></a>
<a id="디자인-토큰-컴포넌트-치수"></a>

문서는 `coco-de/docs` 레포의 `design/` 아래에 있습니다. 결정 기록은 파일명이 `_Rationale.md`로 끝납니다.

## 우선순위 규칙

위에서부터 차례로 적용합니다.

<Steps>
<Step title="문서 종류">

결정 기록에 우연히 나온 숫자는 값의 출처가 아닙니다. 명세만 값을 규정합니다.

</Step>
<Step title="프리미티브가 컴포넌트를 지배">

컴포넌트 명세가 프리미티브 스케일 밖의 값을 쓰면 프리미티브 명세가 이깁니다.

</Step>
<Step title="버전 타이브레이커">

같은 축의 두 문서(명세나 결정 기록)끼리 날짜가 같으면 버전이 높은 쪽이 이깁니다. 둘 다 같으면 별도 결정 이슈로 보냅니다.

</Step>
<Step title="코드 우선 (D-9)">

문서 쪽 승자가 정해졌는데 코드가 다르면, 코드에 근거(CI 가드, 핀 테스트, 근거 주석)가 있을 때만 문서를 갱신합니다.

</Step>
</Steps>

<a id="확인된-충돌-3건과-판정"></a>

## 확인된 충돌 3건

<a id="2-sizeicon-space-primitive-참조-font-size-참조"></a>
<a id="3-프리미티브-컴포넌트-stroke-width-15px"></a>

| 충돌 | 적용 규칙 | 정본 |
|---|---|---|
| Badge, Tag, Chip 분류 (v1.0 ↔ v2.1) | 3. 버전 타이브레이커 | v2.1 문서. Tag 계열로 재편 |
| Size ↔ Icon 참조 축 | 4. 코드 우선 | 코드 CoreIconSize (10단계, 기본 size24). 고정 커밋의 Icon Spec 1.1(9단계)에 size48 추가 |
| stroke-width 1.5px | 2. 프리미티브 지배 | 프리미티브 명세. v2에서 stroke1_5 신설. Checkbox 상자와 Radio 쉬는 고리는 stroke1 |

<DesignNote>
컴포넌트 리네임이나 아이콘 사다리 이식처럼 판정의 내용을 실행하는 일은 별도 Epic과 coco-de/docs 쪽 작업입니다.
</DesignNote>

<a id="1-taxonomy-v10-v21-badgetagchip-분류"></a>

v2.1 문서의 Tag 계열 중 코드에 있는 것은 `Tag`(누르지 않는 표시 전용 라벨)뿐입니다. `DismissibleTag` · `SelectableTag` · `EditableTag`는 없고, 사람이 누르는 라벨은 `Chip`입니다.

## 커밋 고정

coco-de/docs가 실질적으로 바뀌면 이력에 행을 추가하고 고정 커밋을 옮깁니다.

| | |
|---|---|
| 레포 | coco-de/docs |
| 고정 커밋 | 2def5ab3 (2026-08-05) |
| 근거 | Epic G (#3727) |

<a id="갱신-이력"></a>

| 날짜 | 커밋 | 변경 |
|---|---|---|
| 2026-08-05 | `2def5ab3` | Epic G 실행. 색 체계, 모션과 형태 토큰, Icon Spec과 Size Rationale 갱신, 문서 간 충돌 3건 결정 |
| 2026-08-04 | `05fc63f6` | 최초 고정. 73종 분류, 우선순위 규칙, 충돌 3건 판정 |

coco-de/docs main은 고정 커밋 뒤에 2026-08-05의 갱신을 되돌렸습니다(2026-11-23 확인). 그래서 main의 Icon Spec은 1.0(Font-size 참조, 14단계)이라 코드와 다르고, Content-Padding Spec은 킷에 없는 content-padding 토큰을 규정합니다. 킷의 간격은 `CoreSpace` 하나가 정합니다. Duration · Shadow · Divider Spec도 main에서는 1.0입니다(고정 커밋은 1.1). 판정의 근거는 main이 아니라 고정 커밋의 판입니다.

<a id="이-페이지가-하는-것과-안-하는-것"></a>

## 이 페이지가 하는 것

<Cards variant="outlined">
<Card title="하는 것">

- 어느 문서가 정본인지 판정
- 판정 근거인 우선순위 규칙 기록
- 판정 시점의 문서를 커밋으로 고정

</Card>
<Card title="하지 않는 것">

- 충돌 3건의 내용 결정
- 규칙으로 풀리지 않는 새 충돌 판정 (별도 결정 이슈로)

</Card>
</Cards>
