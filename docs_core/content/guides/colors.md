---
title: 색상
description: CoUI의 기본 색은 15단계 뉴트럴입니다. 색은 상태를 알리거나 항목을 구분할 때만 쓰고, 브랜드 색은 primary 자리에 넣어 바꿉니다.
design: true
---

# 색상

## 원칙

<FoundationVisual kind="color-principles" />

## Neutral

15단계 뉴트럴이 글자, 배경, 테두리, 버튼을 모두 만듭니다. 단계 번호가 같으면 흰 바탕 대비 기준도 같습니다. 500은 3:1, 600은 4.5:1을 넘깁니다.

<FoundationVisual kind="neutral" />

## 상태 색

오류, 성공, 경고, 정보를 알릴 때만 씁니다. 라이트 모드에서 채움은 600 단계를 쓰고, 상태를 알리는 글자는 상태 색 대신 컨테이너 위 글자 토큰(700)을 씁니다.

<FoundationVisual kind="status" />

아이콘, 상태 점, 진행 막대는 `errorIcon` · `successIcon` · `warningIcon` · `infoIcon` 을 씁니다. 이 색은 라이트 모드의 회색 컨테이너 위에서 3:1 에 못 미쳐, 그 위에서는 상태 채움을 씁니다.

## 분류 색

순서나 좋고 나쁨이 없는 항목을 구분할 때 씁니다. 태그, 라벨, 차트 계열처럼 여러 항목을 나눌 때 쓰고, 상태 표시에는 쓰지 않습니다.

<FoundationVisual kind="category" />

색 글자는 `onCategoryXContainer` 로 쓰고, 채움(`categoryX`)은 글자에 쓰지 않습니다. 진한 칩의 흰 글자는 라이트 모드에서 3.5:1 까지 내려가므로 SemiBold 12px 이상의 짧은 라벨에만 씁니다.

## Semantic 토큰

컴포넌트는 원시 색 대신 용도 이름으로 색을 씁니다. 라이트와 다크는 같은 토큰을 공유합니다.

<FoundationVisual kind="semantic" />

`onX` 는 짝인 `X` 위에서만 대비가 보장됩니다. 역할 색 글자는 `onXContainer` 나 `primaryText`, 링크는 `link` 를 씁니다. `onSurfaceSubtle` 은 라이트 모드의 회색 컨테이너 위에서 4.5:1 에 못 미쳐, 그 위에서는 `onSurfaceVariant` 를 씁니다. 컨테이너 톤(`surfaceContainerLowest` … `Highest`)은 라이트에서 단계가 오를수록 어두워지고 다크에서는 밝아집니다.

<Code language="dart" title="Flutter · Web">
CoreColor.token(CoreColors.onSurface) // 컴포넌트 스타일
theme.colorScheme.onSurface.toValue() // Flutter
'rgb(var(--coui-on-surface))' // Web
</Code>

## 브랜드 컬러 적용

primary는 브랜드가 덮어쓰는 자리입니다. 기본 테마에서는 뉴트럴과 같은 회색(주 버튼 neutral/900)이고, 브랜드 색 하나로 만든 색 소스를 테마에 넣으면 onPrimary와 hover, pressed 색까지 함께 만들어져 primary를 쓰는 모든 컴포넌트에 고객사 브랜드가 적용됩니다.

<FoundationVisual kind="brand" />

다크 · 고대비 테마와 Web 에 같은 색 소스를 넘기는 법은 [테마](/guides/theming#브랜드-색)에 있습니다. `accent` 는 기본 테마와 색 하나로 만든 브랜드에서 primary 와 같은 색입니다.
