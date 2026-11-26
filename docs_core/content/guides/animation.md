---
title: 모션
description: 전환 시간과 이징은 CoreDuration, CoreEasing alias만 씁니다. 동작 줄이기 설정은 이 토큰을 거친 모든 전환에 닿습니다.
design: true
---

# 모션

## 지속 시간

컴포넌트는 시맨틱 alias를 참조합니다. 동작 줄이기는 이름이 아니라 값으로 판단해 raw 값(ms150 등)도 똑같이 줄이지만, alias는 그 길이를 고른 이유를 말하므로 기본값에는 alias를 씁니다.

<FoundationVisual kind="duration" />

| alias | 값 | 용도 |
| --- | --- | --- |
| `CoreDuration.instant` | 100ms | 체크, 토글 |
| `CoreDuration.fast` | 150ms | 툴팁, hover, 입력 포커스 |
| `CoreDuration.normal` | 200ms | 드롭다운, 아코디언, 카드 hover |
| `CoreDuration.moderate` | 300ms | 모달 진입, 패널 슬라이드 |
| `CoreDuration.slow` | 500ms | 페이지 전환 |

| 단계 | 값 | 동작 줄이기를 켜면 |
| --- | --- | --- |
| 전환 | `0 ~ 500ms (50ms 단위)` | 0ms로 줄어듭니다 |
| 표시 | `1000 ~ 5000ms, indeterminate 1500ms` | 그대로 유지됩니다 |

## 이징

CoreEasing.linear는 alias가 아니며 스피너나 shimmer 같은 루프 전용입니다.

<FoundationVisual kind="easing" />

| alias | 곡선 | cubic-bezier |
| --- | --- | --- |
| `CoreEasing.move` | ease-in-out | `0.42, 0, 0.58, 1` |
| `CoreEasing.enter` | ease-out | `0, 0, 0.58, 1` |
| `CoreEasing.exit` | ease-in | `0.42, 0, 1, 1` |
| `CoreEasing.feedback` | ease-out-back | `0.175, 0.885, 0.32, 1.275` |

Flutter에서는 `CoreEasing.move.toValue()`가 `Curve`를 돌려줍니다.

## 규칙

1. raw Duration 숫자를 쓰지 않고 Duration(milliseconds: CoreDuration.*)를 참조합니다.
2. 표시 시간(ms1000 이상, indeterminate)은 전환이 아니라 alias가 없고 raw 값을 씁니다.
3. 순차 등장은 항목 간격이 아니라 전체 합계를 500ms 이내로 정합니다.
4. 스피너, 로딩 점, shimmer 같은 순환 애니메이션은 이 상한의 대상이 아니지만 두 플랫폼이 같은 값을 읽어야 합니다.
5. 한 묶음은 하나의 duration과 하나의 이징 alias를 함께 씁니다. 컨테이너와 배경은 움직이지 않고 들어오는 콘텐츠만 움직입니다.

## Spring 프리셋

coui_core의 CoreSpringConfig입니다. 다섯 프리셋 모두 mass는 1입니다.

| 프리셋 | damping | stiffness | 용도 |
| --- | --- | --- | --- |
| `gentle` | 0.8 | 200 | 부드러운 전환 |
| `standard` | 0.7 | 300 | 기본 |
| `bouncy` | 0.5 | 400 | 탄성 효과 |
| `snappy` | 0.9 | 500 | 빠른 반응 |
| `stiff` | 1.0 | 600 | 즉각 반응 |

## 동작 줄이기

설정이 켜지면 등장 콘텐츠가 애니메이션 없이 제자리에 바로 나타납니다.

| 플랫폼 | 처리 |
| --- | --- |
| Flutter | `resolveMotionDuration` |
| Web | `--coui-duration-* 변수` |

스켈레톤의 맥동은 표시 단계지만 함께 멈춥니다.

## 화면 전환

새 화면은 데스크톱과 웹(Flutter)에서 살짝 올라오며 나타나고, iOS와 Android에서는 뒤로 가기 제스처가 묶인 플랫폼의 전환을 씁니다. 동작 줄이기가 켜지면 어디서나 바로 바뀝니다.

go_router에서는 `pageBuilder`로 `RoutePage`를 돌려줘야 전환이 붙습니다. 예제는 [IndexedSwitcher](/components/indexed-switcher)에 있습니다. 시간, 곡선, 거리는 테마의 `CoreComponentTheme.pageTransition`에 `CorePageTransitionTheme(style: CorePageTransitionStyle(...))`을 넣어 바꾸고, 같은 테마를 받은 `CoUIApp`과 `CoUIWeb`이 같은 값으로 움직입니다. iOS와 Android의 플랫폼 전환에는 이 값이 닿지 않습니다.

Web의 `CoUIWeb`은 브라우저의 문서 간 전환을 씁니다. 서버에서 그리거나 미리 구운 페이지에서 문서가 바뀌는 이동(링크, 뒤로 · 앞으로 가기)에만 닿고, 이 전환을 지원하지 않는 브라우저에서는 바로 바뀝니다. Chrome에서는 전환이 도는 동안 페이지가 클릭을 받지 않습니다.
