---
title: 아이콘
description: Iconify의 네 가지 세트를 Flutter와 Web에서 같은 API로 씁니다. CoUI 자체 컴포넌트는 Lucide만 씁니다.
design: true
---

# 아이콘

## 아이콘 세트

앱에서는 네 세트를 자유롭게 쓸 수 있습니다. 붙어 있는 컨트롤끼리는 한 세트로 맞춥니다.

<FoundationVisual kind="icon-sets" />

<DesignNote>

세트마다 그리드와 획 두께가 달라, 같은 크기를 요청해도 시각적 무게가 다르게 보입니다.

</DesignNote>

## 이름 규칙

| 형식 | 예 |
| --- | --- |
| Figma 컴포넌트 이름 | `lucide/arrow-right` |
| 코드 참조 | `IconName('lucide', 'arrow-right')` |
| HeroIcons 스타일 (접미어) | `heroicons/academic-cap-solid, -20-solid, -16-solid` |

<DesignNote>

Figma 접두어는 Iconify prefix가 아니라 CoUI 카탈로그 id(lucide, bootstrap, radix, heroicons)를 씁니다.

</DesignNote>

## Icon 컴포넌트

Flutter와 Web에서 같은 방식으로 참조합니다. 크기 같은 세부 설정은 iconStyle에 CoreIconStyle(size: 20)처럼 넘깁니다.

<Code language="dart" title="Flutter · Web">
Icon(LucideIcons.arrowRight)
Icon(
  LucideIcons.house,
  iconStyle: CoreIconStyle(size: 20),
)
</Code>

<DesignNote>

Figma의 Icon 컴포넌트는 Size variant 하나와 아이콘 instance swap 프로퍼티로 되어 있습니다. 코드에서 아이콘은 변형이 아니라 첫 번째 인자이기 때문입니다.

</DesignNote>

`iconStyle`의 크기 · 색 토큰과 나머지 속성은 [Icon](/components/icon) 컴포넌트 페이지에 있습니다.

## 크기와 선 굵기

Size variant는 코드의 icon-size와 같은 10, 12, 14, 16, 18, 20, 24, 28, 32, 48 중에서 고르고, Figma에서 아무것도 정하지 않으면 24(icon-size/default)로 그려집니다. variant마다 선 굵기가 정해져 있어 크기를 바꾸면 굵기도 따라옵니다. 코드에서 크기를 정하지 않으면 앱의 IconTheme를 따릅니다. CoUI 앱의 기본 테마는 20이고, 테마가 없으면 24입니다.

| Size | Lucide | HeroIcons outline | Bootstrap · Radix · HeroIcons solid |
| --- | --- | --- | --- |
| `16` | `1.25` | `1.0` | fill 기반, 크기에 비례 |
| `20` | `1.25` | `1.25` | fill 기반, 크기에 비례 |
| `24` | `1.5` | `1.5` | fill 기반, 크기에 비례 |
| `32` | `2.0` | `2.0` | fill 기반, 크기에 비례 |

<DesignNote title="W, H를 직접 입력해 크기를 바꾸지 않습니다">

직접 리사이즈하면 선 굵기가 그 크기에 맞지 않습니다. 크기는 Size variant로 바꿉니다. 코드에서 쓸 수 있는 크기는 icon-size 10, 12, 14, 16, 18, 20, 24, 28, 32, 48입니다.

</DesignNote>

## 색

아이콘은 놓인 자리의 색을 따릅니다. Flutter는 컴포넌트가 정한 IconTheme 색을, Web은 글자색(currentColor)을 아이콘이 이어받고, Figma에서는 Lucide 아이콘 선이 content/current 변수 하나에 묶여 있어 아이콘을 담은 슬롯이 고른 색으로 그려집니다. 그래서 라이트, 다크, 고대비 모드와 컴포넌트의 상태에 자동으로 대응합니다. 아이콘 선에 색을 직접 덮어쓰지 않습니다. 아이콘을 교체하면 직접 덮어쓴 색은 사라집니다.
