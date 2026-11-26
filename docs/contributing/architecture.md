# 구조와 용어 — 어디를 고쳐야 하나요?

[가이드 목차](README.md) · 이전: [첫 실행](getting-started.md) · 다음: [첫 변경](first-change.md)

## 큰 그림

```text
packages/coui_core
  tokens + CoreXxxContract + CoreXxxStyle + CoreXxxTheme
       ├── packages/coui_flutter: resolveXxx → ResolvedXxx → Widget
       ├── packages/coui_web:     resolveXxx → ResolvedXxx → Jaspr / DOM
       └── bin/export_figma_*.dart
                ├── build/tokens.figma.json        → Figma Variables Import
                └── src/data/components.json       → TS builder → Generate
                    (tools/figma-token-sync 안)

docs_core/content + docs_core/lib/previews
       ├── docs_site       (Jaspr 웹 문서, Flutter 임베드 포함)
       └── app/docs_app   (네이티브 Flutter 문서)
app/coui_widgetbook       (별도의 Flutter 컴포넌트 실험실)
```

**Web은 Flutter Web의 다른 이름이 아닙니다.** `coui_web`은 Jaspr가 HTML/DOM을
그리는 구현입니다. `coui_flutter`는 Flutter 엔진이 그리며 모바일·데스크톱·
Flutter Web에서 사용할 수 있습니다. 문서 사이트의 나란한 프리뷰는 두 구현을
비교하는 자리입니다.

## 일상 언어로 보는 레이어

| 용어 | 쉬운 뜻 | Badge 예시 |
|---|---|---|
| Token | 반복되는 디자인 값에 붙인 이름 | 선 두께 `CoreStrokeWidth.stroke1` |
| Contract | 컴포넌트 사용자가 줄 수 있는 입력의 약속 | `CoreBadgeContract`: variant, child, badgeStyle 등 |
| Style | 색·간격·글자·테두리 같은 외형 설명 | `CoreBadgeStyle.borderWidth` |
| Theme | 앱/영역에서 공통으로 적용하는 스타일 묶음 | `CoreBadgeTheme.style` |
| Resolver | 공통 설명을 플랫폼이 그릴 수 있는 값으로 번역 | `resolveBadge` |
| Resolved | 번역이 끝난 출력값 | Flutter 색/치수, Web CSS chrome 슬롯 |
| Widget / Component | 입력과 런타임 상태에 따라 실제로 그리는 코드 | `Badge` |
| Chrome | 컴포넌트의 외형 | 배경, 테두리, 그림자, padding |
| Slot | 자식이나 스타일을 끼워 넣는 자리 | child, leading, badgeStyle |
| Barrel | 공개 import를 한 곳으로 모은 파일 | `coui_core.dart` |
| Parity | 같은 입력으로 같은 모양·동작을 얻는지 비교 | Web ↔ Flutter |
| Builder | Figma 노드·레이아웃을 만드는 TypeScript 함수 | `buildBadge` |

공유 레이어에는 Flutter의 `Color`나 Jaspr의 `Component` 대신 Core 타입을
둡니다. 기본값·병합·토큰 해석은 resolver가 담당하고, widget은 결과를 읽습니다.

## 실제 Badge 파일로 연결하기

| 역할 | 파일/디렉터리 |
|---|---|
| 공통 입력 | [badge_contract.dart](../../packages/coui_core/lib/src/component/contracts/badge/badge_contract.dart) |
| 외형·기본값·merge/copyWith/동등성 | [badge_style.dart](../../packages/coui_core/lib/src/component/contracts/badge/badge_style.dart) |
| 테마 슬롯 | [badge_theme.dart](../../packages/coui_core/lib/src/component/contracts/badge/badge_theme.dart) |
| Flutter | [badge/](../../packages/coui_flutter/lib/src/components/display/badge/)의 `badge.dart` + `badge_style.dart` |
| Web | [badge/](../../packages/coui_web/lib/src/components/display/badge/)의 `badge.dart` + `badge_style.dart` |
| Figma 데이터 추출 | [export_figma_components.dart](../../packages/coui_core/bin/export_figma_components.dart)와 [figma_reader/](../../packages/coui_core/bin/figma_reader/) |
| Figma 그리기 | [display.ts](../../tools/figma-token-sync/src/components/display.ts)의 `buildBadge` |
| 사용자 문서 | [badge.md](../../docs_core/content/components/badge.md) |
| 실행 예제 | [Flutter 예제](../../docs_core/lib/previews/examples/flutter/badge/) · [Web 예제](../../docs_core/lib/previews/examples/web/badge/) |

## 변경 위치 지도

| 바꾸려는 것 | 먼저 찾을 곳 | 함께 확인할 곳 |
|---|---|---|
| 특정 화면만의 색/여백 | 소비 앱의 `xxxStyle` / Theme | 공통 기본값 변경이 필요한지 |
| 기존 컴포넌트의 공통 기본값 | `CoreXxxStyle.default*`, `defaultsBySize/Variant` | 양쪽 resolver, Figma export와 builder, 회귀 화면 |
| 새 외형 옵션 | Core Style 필드와 값 연산 | 양쪽 resolver/Resolved/widget, Theme 전달, 예제, Figma 표현 |
| 새 입력·콜백·상태 동작 | Core Contract와 관련 타입 | 양 플랫폼 생성자·상태 처리·접근성·테스트 |
| 토큰 스케일/시맨틱 의미 | `coui_core/lib/src/`의 해당 토큰 | 모든 사용처, Web CSS 변환/테마 설정, exporter, 소비자 |
| Web CSS만 잘못 적용 | `coui_web`의 resolver/출력 | 실제 브라우저 computed style, Flutter 기준 결과 |
| Figma만 크기/배치가 틀림 | `src/components/*.ts`와 `src/helpers.ts` | 인스턴스 FILL/HUG/FIXED, 자식 constraints, 실제 리사이즈 |
| 문구·설명·예제 | `docs_core/content/`, `lib/previews/` | 사이트/네이티브 문서, snippet과 example 동기화 |

기본값이 안 바뀌어 보이면 더 높은 우선순위의 Theme·인스턴스 override가
있는지 먼저 확인합니다. 이미 처리되는 필드를 양쪽 파일에 다시 하드코딩하지
않습니다. 반대로 **필드 선언만 추가하고 소비하는 코드를 빼먹으면** 아무 효과도
없습니다. 양쪽 resolver와 widget에서 필드가 실제로 소비되는지 확인합니다.

## 원본과 생성 파일

| 파일 | 편집 방법 |
|---|---|
| Core 소스, 양 플랫폼 소스, exporter, TS builder | 의도를 가진 원본으로 편집 |
| `tools/figma-token-sync/src/data/components.json` | exporter로 재생성하고 변경분 검토·커밋. 손 수정 금지 |
| `build/tokens.figma.json` | token exporter 산출물. Figma Import에 사용 |
| `tools/figma-token-sync/code.js` | esbuild 산출물. `code.ts`/`src/`를 고쳐 다시 빌드 |
| `*.g.dart`, locale 생성 코드 | 소유 생성기로 재생성. 모든 생성 파일의 추적 정책이 같은 것은 아님 |
| Figma의 생성 ComponentSet | Generate로 갱신. canvas 수정이 Dart 소스에 자동 반영되는 것은 아님 |

어떤 파일을 커밋할지는 [`.gitignore`](../../.gitignore), 기존 추적 상태,
해당 생성기의 안내를 확인합니다. `git add .`로 빌드 파일까지 한꺼번에 넣지 않습니다.

Figma에는 별도로 **리디자인 대조/구조·충실도 리포트**와 **소비자용 dimension
토큰 내보내기**가 있습니다. 이것을 위 code→Figma 생성과 혼동하지 않도록
[Figma의 역방향 경로](figma.md)를 읽으세요.
