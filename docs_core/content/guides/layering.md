---
title: 레이어
description: Web의 z-index 12단계는 CoreZIndex가 정본입니다. Flutter에는 대응 토큰이 없고, 겹침은 위젯 트리 순서와 Stacks로 정합니다.
design: true
---

# 레이어

## 스케일

기준값은 1000부터라 1–999 범위의 서드파티나 레거시 값과 충돌하지 않습니다. 단계 간격은 10입니다.

<FoundationVisual kind="layers" />

| 토큰 | 값 | 역할 |
| --- | --- | --- |
| `zAuto` | `auto` | 기본 흐름, 새 컨텍스트 없음 |
| `z0` | `1000` | 기본 콘텐츠 |
| `z10` | `1010` | 드롭다운 메뉴 |
| `z20` | `1020` | sticky, fixed 헤더 |
| `z30` | `1030` | 사이드바 |
| `z40` | `1040` | 오버레이 스크림 |
| `z50` | `1050` | 모달, 다이얼로그 |
| `z60` | `1060` | 팝오버 |
| `z70` | `1070` | 툴팁 |
| `z80` | `1080` | 토스트, 스낵바 |
| `z90` | `1090` | 긴급 알림 |
| `z100` | `1100` | 최상위 (디버그, 개발 도구) |

## 쌓임 규칙

1. 모달(z50)은 스크림(z40) 위에 놓입니다.
2. 사다리에서 토스트(z80)는 모달과 툴팁(z70) 위입니다. 이 순서를 뒤집지 않습니다.
3. CoUIWeb 아래의 모달, 팝오버, 툴팁은 브라우저 top layer에 올라가 z-index가 아니라 연 순서로 쌓입니다. 그래서 열린 모달 위로 토스트를 올리는 z-index는 없습니다.

<DesignNote>

시맨틱 별칭(예: layer/modal)은 아직 없습니다. Figma의 권장 매핑 표는 적용되지 않은 제안입니다.

</DesignNote>

메뉴, 호버 카드, 서랍도 top layer에 올라갑니다. Popover API가 없는 브라우저에서는 이 패널들도 z-index로 쌓입니다.

## 쓰는 법

<Split>

<Code language="dart" title="Jaspr Web">
'z-${CoreZIndex.scale.z50}'
// z-50 → var(--z-50) → 1050
</Code>

<Code language="dart" title="Flutter">
// 트리 순서. 마지막 자식이 위
Stacks(
  children: [
    Position.fill(child: scrim),
    dialog,
  ],
)
</Code>

</Split>

인라인 스타일에는 `'var(--z-${CoreZIndex.scale.z50})'`처럼 변수를 씁니다. `CoreZIndex.scale.z50`은 값이 아니라 키(`'50'`)입니다.

## 피할 것

1. z-[1234], zIndex: 9999 같은 리터럴. 사다리 밖 값은 다른 오버레이와 충돌합니다.
2. Flutter 위젯에 CoreZIndex 적용. 이 상수는 Web CSS 전용입니다.
3. 부모에 transform, opacity, filter가 있는 상태에서 자식 z-index로 전역 레이어를 이기려는 시도. 스택 컨텍스트는 부모가 만듭니다.
