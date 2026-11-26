# CoUI 문서 3-페르소나 전수 감사 — AI · 디자이너 · 개발자

- 일자: 2026-08-05
- 범위: `docs_core/content` 158개 md 전수(최상위 7 · guides 11 · components 139 · _data 5) + `docs_site` 내비게이션 + `packages/coui_mcp`
- 방법: 전 파일 기계 측정(섹션 매트릭스·길이 분포·신호 grep) + 첫 페이지부터 순차 정독. 인상 판단 없이 수치와 파일:라인으로만 진술.
- 선행 감사와의 관계: `docs/docs-benchmark-2026-08-01.md`(Project #3558) 의 P0 7건·P1 주요 항목은 **전부 CLOSED 이며 실제로 반영됨**(설치 안내 git 전환 ✓, `CoreButtonVariant` 정정 ✓, "35+ 테마" 삭제 ✓, 사이드바 검색 ✓, 가이드라인 섹션 필수화 ✓). 이번 감사는 그 위층 — **정확성이 아니라 깊이와 독자 적합성**을 본다.

## 요약

세 줄:

1. **문서 위생은 이미 좋다. 부족한 건 독자별 깊이다.** frontmatter 139/139 완비, 사용 가이드라인 139/139(중앙값 30줄, 빈 껍데기 0개), 코드블록 중앙값 7개, 고아 페이지 0개, API 동기화 게이트가 최상위 페이지까지 확장 완료. 선행 감사가 잡은 "따라하면 깨지는" 문제는 대부분 사라졌다 — 단 하나(P0-1)만 남았고 그건 API 이름이 아니라 **구조적 누락**이라 이름 기반 게이트가 못 본다.
2. **CoUI 는 이미 AI 제품(`packages/coui_mcp`, 11개 툴 + `coui://` 리소스 체계)을 출하해 사용자 설정에까지 등록해 놓고, 문서 사이트에서 단 한 번도 언급하지 않는다.** 벤치마크 3사(Astryx·Seed·daisyUI)는 전부 AI 계층을 1급 내비게이션에 둔다. 있는 걸 안 보여주는 것이라 신규 제작이 아니라 노출 문제다.
3. **디자이너용 문서는 사실상 존재하지 않는다.** Figma 매핑 1/139, Anatomy 1/139, "언제 쓰지 말아야 하나" 26/139. 파운데이션 가이드(색상 24줄·타이포 25줄)는 토큰을 *보여주지만* 어느 것을 언제 쓰는지 판단 근거를 주지 않는다. 그 판단 지식은 `.claude/rules`(29파일 6110줄)에 이미 다 있고, `accessibility.md` 가 그 번역이 성공한 **유일한** 사례다.

---

## 1. 이미 잘하고 있는 것 (건드리지 말 것)

- **`accessibility.md` 가 품질 기준선이다.** 63줄에 reduced-motion tier 구분, 고대비에서 *일부러 하지 않는 두 가지*, forced-colors 에서 그림자가 사라지는 이유, 역할 전제조건이 안 맞으면 "떨어뜨린다"는 판정, 알려진 한계까지 담겨 있다. 내부 룰(`theme-axis-composition.md`·`design-tokens.md`)을 사용자 언어로 옮긴 성공 사례 — 나머지 축에 이 작업이 안 됐을 뿐이다.
- **사용 가이드라인이 형식이 아니라 실질이다.** 139/139 보유, 중앙값 30줄, 5줄 이하 0개, 최대 117줄(`skeleton.md`). 선행 #3581 이 실제로 작동했다.
- **단일소스 아키텍처 + 게이트가 살아있다.** `docs_api_sync_test.dart` 가 `components/` 밖(최상위·guides)까지 검사하도록 확장 완료 — 선행 감사가 지목한 사각지대가 닫혔다.
- **라이브 토큰 렌더.** `<ColorTokens />`·`<TypographyScale />`·`<IconBrowser />` 가 현재 테마 값에서 직접 렌더 — 문서가 낡을 수 없는 구조.
- **내비게이션에 고아 페이지 0개.** 최상위 7 + guides 11 전부 사이드바에 연결됨.

## 2. P0 — 그대로 따라하면 깨진다 (1건)

| # | 문제 | 파일 | 근거 |
|---|---|---|---|
| **P0-1** | `getting-started.md` "기본 설정"이 **Web 앱 루트를 누락**. Flutter 는 `CoUIApp(theme: ThemeData.fromCore(...))` 를 보여주는데 Web 은 곧바로 `Button(...)` 만 보여준다 | `getting-started.md:43-85` | `CoUIWeb` 이 `packages/coui_web/lib/src/coui_web.dart:258` 에 실재하며 `theme`/`darkTheme`/`themeMode`/`locale` 등 `CoUIApp` 대응 필드를 갖는다(클래스 doc 에 "parity matrix" 명시). 이 컴포넌트가 `coui-root` 클래스를 방출하고(`:713,:720`) 테마를 하위로 흘린다 — **없으면 `--coui-*` CSS 변수가 주입되지 않아 토큰 클래스가 전부 미해석**된다. `CoUIWeb` 은 `guides/cross-platform.md:88-90` 에만 등장하고 시작 문서에는 없다 |

왜 게이트가 못 잡았나: 선행 게이트는 **문서에 적힌 API 이름이 실재하는가**를 검사한다. 여기서는 적힌 게 전부 실재한다 — 문제는 **적히지 않은 것**이라 이름 대조로는 구조적으로 검출 불가다.

부수 발견(같은 파일): Flutter/Web 탭 두 개가 **바이트 동일한 코드**를 보여준다(`:91-116`, `:118-141`). import 줄이 빠져 있어 실제 유일한 차이(`coui_flutter` vs `coui_web`)가 드러나지 않고, 탭 어포던스가 정보를 0 전달한다.

## 3. 페르소나별 격차

### 3-A. AI (에이전트가 CoUI 를 쓰려 할 때)

| # | 격차 | 측정값 |
|---|---|---|
| A-1 | **`coui_mcp` 가 문서에 0회 언급** — `search_components`·`generate_component`·`generate_screen`·`validate_component`·`analyze_accessibility` 등 11개 툴과 `coui://component/{name}/{overview,examples,api,accessibility}`·`coui://tokens/*`·`coui://category/*` 리소스 체계를 갖춘 완제품. 사용자 `~/.claude.json` 에 등록되어 실사용 중 | `docs_core/content` 전체에서 "mcp" 언급 파일 **0개** |
| A-2 | **llms.txt 없음** — 벤치마크 3사 전부 보유 | 저장소 전체 검색 0건 (spike #3589 는 Icebox) |
| A-3 | **158/158 한국어 전용, 영문 0건.** 그런데 저장소는 `README.md`(영문) + `README.ko-kr.md` 로 영문을 primary 로 두는 정책 — 문서와 README 의 언어 정책이 반대 | 한국어 158 / 영문전용 0 |
| A-4 | **섹션 제목 비일관 → 앵커 분열.** 같은 뜻에 제목이 2~4종이라 딥링크·RAG 청킹이 불안정 | Props 계열 2종(`## Props / Parameters` 114 · `## Props` 24) · Theme 계열 4종(`스타일 시스템` 89 · `테마 커스터마이징` 9 · `Theming` 3 · `Theme` 2) |

A-1 이 이 감사에서 가장 값싼 항목이다 — **만들 게 아니라 링크할 것**이다.

### 3-B. 디자이너

| # | 격차 | 측정값 |
|---|---|---|
| D-1 | **Figma 매핑 · Anatomy 사실상 부재** | Figma 언급 **1**/139 · Anatomy/구성요소 **1**/139 (`guides/figma-library.md` 52줄은 라이브러리 링크만, 컴포넌트별 매핑 없음) |
| D-2 | **"언제 쓰지 말아야 하나"가 빠져 대안으로 못 보낸다** | 26/139 (**19%**). 사용 가이드라인 자체는 139/139 실질적이나, 경쟁 컴포넌트 간 판정이 없다 |
| D-3 | **Style System 절 부재 — 토큰↔시각 대응 진입점이 없는 컴포넌트가 30%** | 98/139 보유, **41개 누락** |
| D-4 | **파운데이션 가이드가 "보여주기"에서 멈추고 "판단 근거"가 없다** | colors **24줄** · typography **25줄** · icons 27 · layout 33 · state 44 · animation 46. primary vs secondary 를 언제 쓰는지, headline vs title 경계, 대비 페어링 규칙이 전부 없음. 벤치마크: Seed 15개 foundations, Astryx 7개 개별 토픽 |
| D-5 | **설계 원칙 / 북극성 페이지 0건** — 왜 이렇게 생겼는지 설명이 사용자에게 도달하지 않음 | docs_core 전체 0건 (선행 감사 P1 에서 지적됨, 미해소) |

**D-4·D-5 의 핵심**: 필요한 지식은 이미 다 쓰여 있다. `.claude/rules` 29파일 6110줄에 모션 choreography(stagger 총합 상한·easing alias 4종), 실패 표면 판정(`Alert` vs `EmptyState` — "얼마나 나쁜가"가 아니라 "보여줄 게 남았나"), 로딩 정책(스켈레톤은 호출자가 준다), 표면 프리셋, 밀도 축이 전부 있다. 사용자 가이드는 1177줄로 그 **19%** 분량이다. `accessibility.md` 는 이 번역이 가능함을 이미 증명했다.

### 3-C. 개발자

| # | 격차 | 측정값 |
|---|---|---|
| V-1 | P0-1 (Web 앱 루트 누락) | 위 2장 |
| V-2 | **`accessibility.md` 가 한 5축 약속의 이행률이 축마다 크게 갈린다** | ① ARIA/Semantics 89% · ② 키보드 79% · ③ 스크린리더 79% · ④ 포커스 관리 **66%** · ⑤ 알려진 제약 **39%** |
| V-3 | **접근성 절이 Web ARIA 만 서술하는 문서 28개** — 크로스플랫폼 파리티 서사와 정면 충돌 | Flutter/Semantics 언급 111/139 |
| V-4 | **"크로스 플랫폼 차이점" 절 누락 49개(35%)** — CoUI 최대 차별점인데 3분의 1이 침묵 | 90/139 보유 |
| V-5 | "동작 스펙(Behavior)" 절 누락 47개 | 92/139 보유 |
| V-6 | Live Preview 누락 | `card-image.md` · `window.md` (137/139) |
| V-7 | **버전 스위처 컴포넌트는 있는데 데이터가 비어 있음** | `docs_site/lib/components/version_switcher.dart` 존재 / `_data/versions.json` = `{"versions": []}` |

**V-2 의 실제 위험**: 얇은 접근성 절은 무작위가 아니라 **키보드가 핵심인 컴포넌트에 몰려 있다**. `autocomplete.md`·`chip-input.md`·`item-picker.md`·`popup.md` 는 ARIA role 한두 줄만 있고 키보드 조작·포커스 관리·제약이 전부 없다. `accessibility.md:55-63` 는 "컴포넌트 문서의 접근성 절에 있다 … 비어 있는 문서는 없다"고 약속한다 — 절은 비어 있지 않지만 약속한 5축 중 1축만 이행한다.

## 4. 거버넌스 — 프로세스 산출물이 제품 문서에 섞여 있음

| # | 문제 | 위치 |
|---|---|---|
| G-1 | `coui_mcp` 에 프로세스 문서 8개가 제품 README 와 동급으로 커밋 | `BLUEPRINT_IMPLEMENTATION{,_EN}.md` · `IMPLEMENTATION_COMPLETE.md` · `IMPLEMENTATION_SUMMARY.md` · `LINT_IMPROVEMENTS.md` · `PHASE1_COMPLETE{,_EN}.md` · `README_OLD.md` |
| G-2 | 저장소 루트에 작업 잔해 | `color_picker_content.txt` · `color_picker_magic_numbers_summary.md` · `QUICK_FIX.md` · `review_i18n_keys.md` · `SCRIPT_IMPROVEMENTS.md` · `dcm_report.json` · `README_OLD.md` |

`process/deprecation.md`·`writing-rules.md` 가 "전이 서술 금지 / 변경 내역은 룰이 아니라 PR·CHANGELOG 영역"을 이미 규정한다 — 이 파일들은 그 규정의 반례다.

## 5. 우선순위 제안

**P0 — 따라하면 깨짐 (즉시)**
- P0-1 `getting-started.md` 에 `CoUIWeb` 앱 루트 설정 추가 + Flutter/Web 탭에 import 줄 포함
- V-2 얇은 접근성 절 중 **키보드 핵심 컴포넌트 우선**(autocomplete·chip-input·item-picker·popup·select·menu 류) 5축 보강

**P1 — 있는 걸 안 보여줌 (값싼 큰 효과)**
- A-1 `coui_mcp` 문서 페이지 신설 + 사이드바 1급 노출 (신규 제작 아님, 노출)
- V-7 `versions.json` 채우기 (스위처가 이미 있음)
- V-6 Live Preview 2건
- A-4 섹션 제목 정규화 (Props 2종→1, Theme 4종→1)

**P1 — 독자별 깊이**
- D-4 파운데이션 가이드에 판단 근거 추가 (색·타이포 우선)
- D-5 설계 원칙 / 북극성 페이지 신설 — `accessibility.md` 를 템플릿으로
- D-2/D-3 "언제 쓰지 말아야" + Style System 절 확산
- V-4 크로스 플랫폼 차이점 절 49건 보강

**P2 — 구조·거버넌스**
- A-3 영문 문서 정책 결정 (README 와 반대인 현 상태를 정합화)
- A-2 llms.txt (#3589 스파이크와 연결)
- D-1 Figma 매핑 / Anatomy
- G-1·G-2 프로세스 산출물 정리

## 부록 — 측정 방법

전 수치는 `docs_core/content` 전수 스크립트 측정. 섹션 보유 여부는 정규화 정규식(같은 뜻의 제목 변형 모두 포함)으로 판정해 제목 표기 차이로 인한 오탐을 제거했다. 접근성 5축 이행률은 각 문서의 `## 접근성` 절만 잘라내어 축별 신호어로 판정 — 절 전체가 아니라 그 절 안에서만 측정했다. 길이 분포는 공백 제외 라인 수.

측정 한계: 5축 이행률은 신호어 기반이라 축을 다루면서 다른 어휘를 쓴 문서를 놓칠 수 있다(과소 추정 방향). 반대로 다른 맥락에서 "포커스"를 언급한 문서를 과대 계상할 수 있다 — 표본 확인(`indicator`·`popup`·`autocomplete`·`chip-input`·`item-picker`)에서는 과대 계상이 관찰되지 않았다.
