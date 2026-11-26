---
title: 모양
description: 모서리 반경과 선 굵기를 정합니다. 숫자를 직접 쓰지 않고 역할이나 primitive 토큰을 고릅니다.
design: true
---

# 모양

## 반경 역할

CoreRadiusRole은 primitive의 이름 별칭입니다. 역할로 표현할 수 없는 값만 primitive를 직접 고릅니다.

<FoundationVisual kind="radii" />

| 역할 | px | 용도 |
| --- | --- | --- |
| `part` | 4 | 컨트롤 안이나 옆의 작은 요소 (체크박스 상자, 키 캡) |
| `control` | 8 | 누르거나 입력하는 요소, 목록 행 |
| `panel` | 12 | 떠서 목록과 선택지를 담는 면 (메뉴, 팝오버) |
| `surface` | 16 | 화면에 놓이는 카드, 큰 컨테이너 |
| `modal` | 20 | 열린 동안 가장 바깥에서 아래를 막는 면 (대화상자) |

## 크기별 반경

크기가 있는 컨트롤(버튼, 입력)은 높이의 25%를 반경으로 씁니다.

| 크기 | 토큰 |
| --- | --- |
| `xs` | `radius6` |
| `sm` | `radius8` |
| `md` | `radius10` |
| `lg` | `radius12` |
| `xl` | `radius14` |
| `xl2` | `radius16` |

컴포넌트가 크기마다 이 값을 이미 쓰므로, 반경을 직접 적는 것은 덮어쓸 때뿐입니다.

## 반경 primitive

radius0과 radius9999는 크기가 아니라 의도를 나타내며, 서페이스 프리셋이 값을 바꿔도 그대로입니다.

| 구간 | 토큰 | 간격 |
| --- | --- | --- |
| Small | `radius0 ~ radius16` | 2px |
| Medium | `radius20 ~ radius36` | 4px |
| Large | `radius40 ~ radius64` | 8px |
| Full | `radius9999` | 알약, 원 |

<DesignNote>

바깥 모서리는 안쪽보다 커야 합니다. 패널 안의 행은 패널 반경에서 패딩을 뺀 값을 씁니다. 예: 12 − 6 = radius6

</DesignNote>

## 선 굵기

대부분 stroke1과 stroke2를 씁니다. 포커스 링은 그림자와 효과의 CoreFocusRing을 씁니다.

| 토큰 | px | 용도 |
| --- | --- | --- |
| `stroke0` | 0 | 선 없음 |
| `stroke0_5` | 0.5 | 헤어라인, 글줄 안 키 캡 |
| `stroke1` | 1 | 기본 보더, 디바이더, 테이블 |
| `stroke1_5` | 1.5 | 선택된 옵션 행 테두리, 내비게이션 바 알림 점의 고리, 입력에 더 굵은 활성 경계를 직접 적을 때 |
| `stroke2` | 2 | 선택 카드, 활성 탭 밑줄 |
| `stroke3` | 3 | 강한 강조 |
| `stroke4` | 4 | 장식, 섹션 디바이더 |
| `stroke5` | 5 | 라디오 lg, xl의 켜진 고리 |
| `stroke6` | 6 | 강한 섹션 강조 |
| `stroke8` | 8 | 최대치, 특수 장식 |

`stroke0_5`와 `stroke1_5`는 화면에 따라 그리는 폭이 다릅니다. 2배 미만 화면에서는 둘 다 1px로, 2배 이상 화면에서는 제 굵기로 그립니다. Web은 CSS 변수가, Flutter는 `CoUIApp`이 화면 배율을 읽어 같은 기준을 따릅니다. 서페이스 프리셋의 선 굵기 하한도 이 두 단계에 적용됩니다.

## 쓰는 법

BorderRadius.circular(12)나 rounded-[12px]처럼 토큰을 거치지 않은 숫자를 쓰면 서페이스 프리셋이 그 컴포넌트를 비껴갑니다.

<Code language="dart" title="Flutter · Web">
CoreButtonStyle(
  borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
  borderWidth: CoreStrokeWidth.stroke1,
)
// Chip은 반경 대신 모양을 고릅니다
Chip(shape: CoreChipShape.pill)
</Code>

모서리마다 다른 반경은 `CoreBorderRadius.only(topLeft: …, topRight: …)`로 적습니다.
