---
title: 디자인 토큰
description: CoUI의 값은 모두 coui_core 토큰으로 정의합니다. 파운데이션 페이지마다 한 종류의 토큰을 다룹니다.
design: true
---

# 디자인 토큰

## 파운데이션 한눈에 보기

항목을 누르면 해당 파운데이션 페이지로 이동합니다.

<FoundationVisual kind="topics" />

## 값의 기준

<DesignNote title="값의 기준은 coui_core 코드입니다">

문서와 코드가 다르면 코드를 따릅니다. 문서 사이의 우선순위는 Resources 탭의 [설계 문서 기준](/guides/design-sources)에서 확인하세요.

</DesignNote>

값은 coui_core가 정하고 단위는 플랫폼이 정합니다. Flutter는 `CoreSpace.space16` 같은 숫자를, Web은 `p-space16` 같은 Tailwind 클래스나 `rgb(var(--coui-on-surface))` 같은 CSS 변수를 씁니다.
