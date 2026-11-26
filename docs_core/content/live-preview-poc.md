---
title: Live Preview PoC
description: Web/Flutter 듀얼 라이브 프리뷰 기능의 PoC 페이지입니다.
---

# Live Preview PoC

<Info>
  소비자용 가이드가 아닙니다. 사이드바에서 뺐고, 컴포넌트 문서의
  LivePreview 가 의존하는 듀얼 프리뷰·chain 채널 격리를 검증하는 내부
  하네스입니다. URL 은 그대로 살아 있습니다.
</Info>

Web과 Flutter 프리뷰를 나란히 보여주는 듀얼 라이브 프리뷰 기능입니다.

## Single Variant Mode

### Button — Primary

<LivePreview component="button" variant="primary" chain="off" />

### Button — Outline

<LivePreview component="button" variant="outline" chain="off" />

## Variant Gallery Mode

모든 Button variant를 한번에 확인합니다.

<LivePreview component="button" variants="primary,secondary,outline,ghost,link,destructive" chain="off" />

## Chain Transport PoC

같은 컴포넌트의 chain 패널 2개 — 셔플 버튼 클릭이 자기 패널의 세 표면(Web 팬·Flutter 팬·코드 패널)만 갱신하고 다른 패널에는 닿지 않는지(per-panel 채널 격리) 검증하는 페이지입니다.

<LivePreview component="button" variants="chain,chain" />
