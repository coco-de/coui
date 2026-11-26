---
title: 타이포그래피
description: 본문은 Pretendard, 코드는 Geist Mono를 씁니다. 크기와 굵기를 위젯에 직접 지정하지 않고 22개 역할 중에서 고릅니다.
design: true
---

# 타이포그래피

## 서체

Geist Mono에는 한글이 없어 코드 안의 한글은 Pretendard로 그려집니다. Flutter는 GeistMono를 번들하고, Web은 앱이 직접 불러옵니다.

<FoundationVisual kind="fonts" />

Web에서 서체를 불러오는 법은 [빠른 시작](/getting-started#글꼴)에 있습니다.

## 역할 고르기

색은 chain으로 붙입니다. 예: `Text('저장').labelMedium.onPrimary`

| 쓰임 | 역할 |
| --- | --- |
| 화면 제목 | `headline, title` |
| 본문과 설명 | `body` |
| 버튼, 칩, 탭, 필드 라벨 | `label` |
| 코드, 줄 번호, 경로, 로그 | `code` |

<DesignNote>

같은 14px이라도 body는 400에 행간 1.5, label은 500에 행간 1.4입니다. 버튼 글자에 body를 쓰면 누르는 것으로 읽히지 않습니다.

</DesignNote>

화면을 나누는 제목은 headline, 본문 바로 위 소제목은 title입니다. display는 큰 숫자 하나나 긴 문서의 제목에 씁니다.

## 스케일

숫자는 Desktop 기준이고, 예시는 지금 화면 폭의 단계로 그려집니다. code 역할은 줄 격자를 맞추려고 행간을 21px로 고정합니다.

<FoundationVisual kind="typography" />

## 화면 폭에 따른 단계

display와 headline 여섯 역할만 화면 폭에 따라 줄어듭니다. title, body, label, code는 모든 폭에서 같습니다.

| 역할 | Mobile (<768) | Tablet (768–1023) | Desktop (≥1024) |
| --- | --- | --- | --- |
| `displayLarge` | 36 | 44 | 52 |
| `displayMedium` | 32 | 40 | 48 |
| `displaySmall` | 28 | 36 | 44 |
| `headlineLarge` | 24 | 28 | 32 |
| `headlineMedium` | 20 | 24 | 28 |
| `headlineSmall` | 16 | 20 | 24 |

앱 전체나 화면 한 부분을 한 단계로 고정할 수 있습니다.

<Code language="dart" title="Flutter · Web">
// 앱 전체 — null(기본)이면 화면 폭을 따릅니다
CoUIApp(theme: theme, typographyTier: CoreBreakpointTier.desktop, home: home)
CoUIWeb(theme: theme, typographyTier: CoreBreakpointTier.desktop, child: app)
// 화면의 한 부분
TypographyTierScope(tier: CoreBreakpointTier.desktop, child: hero)
</Code>

- 범위 안에서 연 팝오버 · 메뉴 · 대화상자도 범위를 따르지만, 서랍은 기본적으로 앱의 단계를 따릅니다.
- `Avatar` 이니셜처럼 크기가 정해진 상자를 채우는 글자는 Desktop으로 고정돼 있습니다. 직접 만든 같은 상자도 `TypographyTierScope`로 고정합니다.
- 크기를 직접 적은 글자(`fontSize:`, `.s24`)는 단계를 따르지 않습니다. 레이아웃 컴포넌트는 글자 단계와 따로 자기 기준의 폭에서 바뀌므로, 글자 단계를 고정해도 레이아웃은 고정되지 않습니다.
- 다른 화면 안에 끼운 뷰(임베드 · 미리보기 · iframe)는 그 뷰의 폭으로 단계를 고르므로 좁으면 Mobile 이 됩니다. 그런 뷰는 호스트가 단계를 고정합니다.

## 쓰는 법

line-height와 letter-spacing은 비율이라 크기를 바꿔도 따라옵니다(code 역할의 21px 줄은 고정). 손으로 다시 지정하지 않습니다.

<Code language="dart" title="Flutter · Web">
Text('Heading').headlineLarge
Text('Body').bodyMedium.onSurface
// display, headline 서체만 바꾸기
CoreTypography.coui.withFamily('Hahmlet')
</Code>

역할은 앞에 적은 크기 · 굵기 · 행간 · 서체를 덮으므로(`Text('…').s20.codeSm`은 12px) 역할을 먼저 적습니다.

`withFamily`로 만든 스케일은 `ThemeData.fromCore(coreTheme.copyWith(typography: …))`(Flutter), `ThemeConfig.from(CouiColorPresets.source, typography: …)`(Web)로 넘깁니다. 서체 파일은 앱이 공급하고, 그 서체에 없는 글자는 Pretendard로 그려집니다. Figma 라이브러리에는 제품의 제목 서체가 없습니다.
