---
title: Figma 라이브러리
description: CoUI 컴포넌트를 Figma에서 만들고 쓰는 방법, 그리고 기준 파일을 안내합니다.
design: true
---

# Figma 라이브러리

<a id="정본"></a>

## 라이브러리 정보

| | |
|---|---|
| 식별자 | coui-component-library |
| 표시 이름 | CoUI Component Library |
| 생성 도구 | tools/figma-token-sync 플러그인의 Generate Components |
| Figma 링크 | [CoUI — Cocode Design System v1.0](https://www.figma.com/design/9FgsLhiWz0aLsVqcoI6nYJ/CoUI---Cocode-Design-System-v1.0) |

<a id="foundation-문서"></a>
<a id="매핑의-근거와-낡음-검사"></a>

Foundation 페이지와 짝인 문서는 [디자인 토큰](/tokens/overview#coui_core-맵)에 있습니다.

## 컴포넌트 만들기

플러그인은 매니페스트에 묶인 파일이 아니라 지금 열린 문서에서 동작합니다.

<a id="대조는-경고이지-차단이-아니다"></a>

<Steps>
<Step title="기준 문서를 엽니다">

다른 문서에서 실행하면 컴포넌트 세트가 따로 하나 더 생깁니다.

</Step>
<Step title="Generate Components를 실행합니다">

플러그인이 문서의 표시(pluginData)를 확인합니다. 표시가 없으면 이 문서에 새로 적고, 다른 라이브러리의 표시면 실행 로그에 경고를 남기고 그대로 계속합니다.

</Step>
<Step title="결과를 확인합니다">

값은 빌드할 때 플러그인에 묶여 들어가고, 실행 중에는 네트워크 요청이 없습니다.

</Step>
</Steps>

<a id="구조-스냅샷-캔버스가-무엇을-바꿨는지-코드가-알게-하는-법"></a>

값은 `coui_core` 가 정합니다. 캔버스에서 고친 값은 다음 반영에서 코드의 값으로 돌아가므로, 바꿀 값은 코드에서 고칩니다.

## 기준 파일 바꾸기

기준 문서가 바뀌면 이 파일 하나만 고칩니다. 플러그인과 내보내기 코드는 고치지 않습니다.

<Code language="text" title="기준 파일">
docs_core/content/_data/figma_library.json
</Code>

<a id="a-5-미결-private-org-plugin-배포"></a>

## 남은 항목

<DesignNote title="A-5 파일 확인 방식">
figma.fileKey로 파일을 정확히 확인하려면 플러그인을 조직 비공개 플러그인으로 배포해야 합니다. 플랜이 정해지기 전까지는 표시(pluginData)만 확인할 수 있어서, 기준 파일인지는 사람이 확인합니다.
</DesignNote>

## 캔버스에서 쓰기

밝기 · 글자 단계 · 서페이스 스타일 · 밀도는 프레임에 컬렉션의 모드를 고정해 고릅니다. 다크 모드의 재질 투명도 · 배경 채도 · 가장자리 광택은 캔버스에 없고, 그림자는 색 모드와 무관하게 라이트 값으로 그려집니다.

<a id="타이포는-스타일로-적용한다"></a>
<a id="스타일-자체는-코드에서-온다-손으로-고치지-않는다"></a>
<a id="고정폭-서체-geist-mono-를-설치한다"></a>

글자에는 텍스트 스타일(`Body/Medium` 등)을 붙입니다. `font-size/*` 같은 변수를 노드에 직접 걸면 굵기 · 행간이 따라오지 않습니다. 서체 설치, 플러그인 실행, 소비 파일 점검은 [Figma 플러그인 안내](https://github.com/coco-de/coui/blob/main/docs/contributing/figma.md)에 있습니다.
