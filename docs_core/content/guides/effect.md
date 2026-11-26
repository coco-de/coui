---
title: 그림자와 효과
description: 높이를 나타내는 그림자, 상태를 나타내는 투명도, 키보드 위치를 알리는 포커스 링을 다룹니다. 값은 모두 coui_core에 있습니다.
design: true
---

# 그림자와 효과

## 그림자

CoreShadow는 none을 빼고 바깥 그림자 7단계와 inset 1개입니다. Dart 이름 제약 때문에 2xl, 3xl은 xl2, xl3으로 씁니다.

<FoundationVisual kind="shadows" />

| 토큰 | 쓰는 곳 |
| --- | --- |
| `none` | 그림자 없음 (카드, 서랍의 기본) |
| `xs` | 슬라이더 손잡이, 선택된 토글 세그먼트 |
| `sm` | 토스트, AppBar elevated, 카드 soft |
| `md` | 카드 hover, 독 |
| `lg` | 메뉴, 팝오버, 셀렉트 판, 명령 팔레트, Fab |
| `xl` | 모달, 다이얼로그 |
| `xl2` | 기본값으로 쓰는 컴포넌트 없음 |
| `xl3` | 기본값으로 쓰는 컴포넌트 없음 |
| `inset` | 안쪽 그림자, 기본값으로 쓰는 컴포넌트 없음 |

<DesignNote title="다크 테마">

같은 모양에 알파만 CoreShadow.darkStrength(4)배를 곱해 최대 1까지 올립니다. 이 곱셈은 컴포넌트가 아니라 테마가 처리합니다. 위 예시는 xs부터 xl까지 실제 토큰 값을 그립니다.

</DesignNote>

Web의 클래스와 CSS 변수는 다시 `2xl`, `3xl`로 씁니다(`shadow-2xl`, `--shadow-2xl`). Web의 [색 강제 모드](/accessibility#고대비와-색-강제-모드)에서는 그림자가 사라지므로, 경계가 필요한 면은 [모양](/guides/shape)의 테두리로 그립니다.

## 투명도

상태는 대개 새 색을 만들지 않고 같은 전경색을 투명도로 겹칩니다. 순서는 hover ≤ focus ≤ pressed여야 합니다.

<FoundationVisual kind="opacity" />

| 시맨틱 | 값 | primitive |
| --- | --- | --- |
| `hover` | 0.03 | `opacity3` |
| `focus` | 0.08 | `opacity8` |
| `pressed` | 0.12 | `opacity12` |
| `disabled` | 0.4 | `opacity40` |
| `scrim` | 0.6 | `opacity60` |

<DesignNote>

위 예시는 CoreStateLayer.subtle 값을 primary 면에 겹쳐 보인 것입니다. 체크박스, 토글은 CoreStateLayer.standard(8%, 8%, 16%)를 쓰고, 채운 버튼은 투명도 대신 hover, pressed 색으로 바꿉니다.

</DesignNote>

어둡거나 채도 높은 면을 위한 `CoreStateLayer.strong`(8%, 12%, 16%)도 있지만, 지금 기본값으로 이 램프를 쓰는 컴포넌트는 없습니다.

## 포커스 링

폭, 오프셋, 색 세 값이 하나의 계약입니다. 폭만 바꾸고 나머지를 그대로 두지 않습니다.

<FoundationVisual kind="focus-ring" />

| 슬롯 | 값 |
| --- | --- |
| `ringWidth` | 2px |
| `ringOffset` | 폭과 같음 (2px) |
| `ringOpacity` | 1 |
| `ringColor` | CoreColors.focusRing (primary 아님) |
| `ringOffsetColor` | 투명. 간격으로 컨트롤 뒤 배경이 보임 |
| `opaqueOffsetColor` | CoreColors.surface. 배경을 알 수 없는 컴포넌트만 사용 |

<DesignNote title="링 색을 primary에 묶지 않는 이유">

브랜드 색이 중성으로 정해지면 링이 본문 글자와 같은 색이 되어 키보드 위치가 보이지 않습니다.

</DesignNote>

위 값은 모두 `CoreFocusRing`에 있습니다(`CoreFocusRing.ringWidth` 등).

## 피할 것

캔버스 설명과 코드의 숫자가 다르면 코드를 따릅니다.

1. BoxShadow나 shadow-[…] 같은 그림자 리터럴. 다크 테마 세기와 서페이스 스타일이 어긋납니다.
2. hover에 opacity10을 직접 쓰는 것. 시맨틱 hover는 3%입니다.
3. 포커스 링의 폭만 바꾸고 오프셋과 색을 그대로 두는 것.

<Code language="dart" title="Flutter · Web">
CoreCardStyle(
  boxShadow: CoreShadow.sm,
)
CoreStateLayer.subtle.hover   // 0.03
CoreOpacity.disabled          // 0.4
</Code>
