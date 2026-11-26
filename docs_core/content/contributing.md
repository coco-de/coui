---
title: 기여 가이드
description: CoUI에 변경을 제안하고 반영하는 절차입니다. 저장소는 현재 비공개라 clone과 소스 열람에는 권한이 필요합니다.
design: true
---

# 기여 가이드

## 처음부터 따라가기

여섯 단계로 나눠 진행합니다.

| 순서 | 단계 | 목표 |
|---|---|---|
| 1 | [환경 설정과 첫 실행](https://github.com/coco-de/coui/blob/main/docs/contributing/getting-started.md) | 로컬 Web, Flutter 프리뷰 띄우기 |
| 2 | [구조와 용어](https://github.com/coco-de/coui/blob/main/docs/contributing/architecture.md) | Core, resolver, widget, builder의 역할 익히기 |
| 3 | [첫 변경: Badge](https://github.com/coco-de/coui/blob/main/docs/contributing/first-change.md) | 기본값 하나를 두 플랫폼과 Figma까지 따라가기 |
| 4 | [검증과 문제 해결](https://github.com/coco-de/coui/blob/main/docs/contributing/verification.md) | 변경마다 검사를 수행하고 결과 남기기 |
| 5 | [Figma 플러그인](https://github.com/coco-de/coui/blob/main/docs/contributing/figma.md) | export, build, Import, Generate 수행 |
| 6 | [호환성과 업그레이드](https://github.com/coco-de/coui/blob/main/docs/contributing/upgrading.md) | API 변경 예고, 릴리스, 소비 프로젝트 갱신 |

<a id="구조-한눈에-보기"></a>

## 구조

<Code language="text" title="Repository">
packages/coui_core     공통 토큰 · Contract · Style · Theme
    ├── coui_flutter  resolver → Flutter widget
    ├── coui_web      resolver → Jaspr / DOM
    └── exporter      JSON → tools/figma-token-sync → Figma
docs_core             공유 문서 · 예제 · 스니펫 · 카탈로그
    ├── docs_site     Jaspr 문서 사이트
    └── app/docs_app  네이티브 Flutter 문서 앱
app/coui_widgetbook   Flutter 컴포넌트 실험실
</Code>

| 용어 | 역할 |
|---|---|
| `Contract` | 사용할 수 있는 입력 |
| `Style` | 외형과 기본값 |
| `Theme` | 공통 override |
| `Resolver` | 위 값을 플랫폼 값으로 변환 |
| `Widget` | 변환된 결과를 렌더링 |

<DesignNote>
기본값을 고쳐도 Figma 문서는 자동으로 갱신되지 않습니다. export 데이터를 builder가 읽어 생성합니다.
</DesignNote>

<a id="기여의-기본-순서"></a>

## 기여 절차

<Steps>
<Step title="이슈 작성">

현재 동작, 기대 동작, 영향받는 플랫폼을 적습니다.

</Step>
<Step title="브랜치 만들기">

공유 원본과 두 플랫폼의 처리 경로를 확인합니다.

</Step>
<Step title="코드와 테스트 수정">

실행 예제와 복사용 스니펫도 함께 갱신합니다.

</Step>
<Step title="Figma 확인">

디자인 표현이 바뀌면 export, build 후 Import, Generate 결과를 확인합니다.

</Step>
<Step title="PR 올리기">

검사 결과, 시각과 동작 증거, 필요한 마이그레이션을 남깁니다.

</Step>
</Steps>

## 규칙

브랜치, 네이밍, 토큰, API 대칭, 검증, deprecation 안내는
[CoUI 기여 가이드](https://github.com/coco-de/coui/blob/main/CONTRIBUTING.md)에 있습니다.

<a id="접근과-제안"></a>

## 제안과 제보

| | |
|---|---|
| 공개 전 제안 | <cody@cocode.im> |
| 버그 제보에 넣을 것 | 사용 중인 태그나 커밋, 플랫폼, 재현 단계, 기대 결과 |
