# CoUI 문서 사이트 벤치마크 — Astryx · Seed Design · daisyUI

- 일자: 2026-08-01
- 범위: `docs_core`(콘텐츠 단일소스) · `docs_site`(Jaspr 웹 문서) · `app/docs_app`(네이티브 Flutter 문서 앱)
- 방법: 외부 3개 사이트는 WebFetch(+ Astryx 는 컴포넌트 상세가 순수 SPA 라 `@astryxdesign/cli` 로 우회) 로 실제 방문. CoUI 내부는 파일을 직접 Read/Grep 해 확인 — 추정·인상 판단 없음.
- 관련 선행 감사: `docs/design-audit-coui-2026-07-25.md`(Project #3294, 디자인 시스템 전역), 그 후속 Project #3445(문서 사이트 139개 컴포넌트 페이지 전수 크롤 → 40건). 이번 감사가 잡은 P0 전부는 **그 두 감사 범위 밖**(최상위 온보딩/가이드 페이지 — `getting-started.md`/`index.md`/`guides/*.md`)에서 나왔다. #3445 는 `content/components/*.md` 139개만 크롤했다.

## 요약

세 줄:
1. **온보딩 문서 5개 파일이 컴파일 안 되는 코드를 가르친다.** `getting-started.md`/`index.md`/`guides/installation.md`/`guides/theming.md`/`guides/cross-platform.md`/`contributing.md`가 pub.dev 에 없는 패키지를 pub.dev 명령으로 설치하라 하고, 존재하지 않는 `Button.primary`/`ButtonVariant`/`ComponentThemeData`/`AnimationConstants` API 를 예제화한다 — 같은 저장소의 `components/button.md`/`guides/theming.md`(테마 부분)는 정확한데, 나머지가 거짓이다.
2. **`docs_core` 단일소스 아키텍처와 `docs_api_sync_test.dart` 게이트는 Astryx·Seed·daisyUI 중 누구도 가진 적 없는 CoUI 의 실질적 강점**이지만, 그 게이트의 검증 범위가 `content/components/*.md` 로 하드코딩돼 있어 정작 이번 드리프트가 몰린 최상위 페이지는 못 본다 — 구조적 사각지대.
3. **CoUI 만이 가진 "Flutter+Web 완전 동일 렌더링" 서사를 정작 그것을 설명해야 할 `cross-platform.md` 가 틀린 API 로 반대 얘기를 하고 있다.** 세 벤치마크 어디에도 이 문제(진짜 이중 렌더 엔진 파리티) 자체가 없다 — CoUI 가 훔쳐올 게 아니라 스스로 증명해야 하는 유일한 지점인데, 그 증명 문서가 지금 거짓말을 하고 있다.

---

## 1. 한눈에 보는 비교

| 축 | Astryx (Meta) | Seed Design (당근) | daisyUI | CoUI (현재) |
|---|---|---|---|---|
| 정보 구조 | Docs(19토픽)/Components(11카테고리)/**Templates**(50+ 전체화면 조합)/AI 3중 계층(llms.txt+CLI+MCP, 사이트와 동일 소스) | Get Started/Foundations(15)/Components(디자인스펙)/**AI&Tools**(1급nav)/Updates + React·Lynx·Breeze 별도 최상위 | Docs/Components(68, new·updated 배지)/Templates/MCP/More, 구버전 메이저 서브도메인 영구보존 | docs_core 6페이지+가이드 9개(하드코딩)+컴포넌트 139개(카탈로그 자동파생) — 설치·API 안내가 4개 파일에 중복 서술 |
| 컴포넌트 페이지 | Anatomy→Best Practices(a11y 내재)→Props→**Theming(class/attr/CSS var 3단)**→연관 템플릿 역참조 | **디자인 스펙(Figma, 코드 0)과 코드 문서가 완전히 분리된 별도 URL** | AI 툴바→소개 1문장→CSS 클래스 레퍼런스 표→variant 예제 반복 | Props/Style표 분리는 좋으나 섹션 존재 여부가 컴포넌트마다 들쭉날쭉(table/tree 는 "사용 가이드라인" 없음) |
| 코드 예제 UX | 탭 없음(React 단일), CLI `--dense/--json/--lang` 공통 | 정적 블록만, variant별 별개 블록, 라이브 편집기 없음 | 순수 HTML+클래스, Theme Generator 로 편집 분리, AI 딥링크 전면 배치 | Flutter/Web 탭 병렬은 좋으나 **4개 문서가 실재하지 않는 API 예제화** |
| 디자인 토큰 문서 | tokens/color/typography/spacing/shape/elevation/motion 개별 토픽, `light-dark()` 자동전환 | 2단(Scale→Semantic), APCA 대비 검증 | 시맨틱 색 롤 + `--radius-*`, **Theme Generator(슬라이더+실시간 프리뷰+export)**가 토큰 편집 UI | 내부 규칙은 정교(alias tier 등)하나 **theming.md vs cross-platform.md 가 서로 다른 토큰 존재를 주장**, "35+ 테마"는 실제 4개뿐인 허위 |
| 접근성 문서 | 독립 페이지 없음, Best Practice/훅에 분산 | 전용 페이지 있으나 컴포넌트별 편차 큼(Select 는 언급 0) | 독립 페이지 없음, 네이티브 HTML 이 대신함 전제 | **셋 중 가장 강함** — 전역축 1페이지 집중 |
| 검색/내비 | component/hook/docs/template 통합 랭킹, CLI=MCP=웹 동일 인덱스 | 조사 실패(미확인) | ⌘K 존재(품질 미확인) | **주 표면(docs_site)에 검색이 없음** — docs_app(네이티브)에만 있음 |
| 버전관리 | Breaking 마다 **codemod 자동 첨부**(`astryx upgrade`) | semver 아님, 의사결정 서사 블로그 | semver+날짜, **구버전 서브도메인 영구보존** | CHANGELOG(4224줄)가 사이트에 안 걸림, 문서 속 버전(`^0.0.1`)이 실제(0.12x.x)와 다름 |
| 크로스플랫폼 서사 | 없음(React 웹전용) | 플랫폼마다 별개 재구현(단일 API 아님) | 없음(결국 CSS 클래스) | **CoUI 고유 최대 강점** — 그런데 그걸 설명하는 문서가 틀린 API 로 반대 얘기를 함 |

## 2. CoUI 가 이미 잘하고 있는 것 (지우지 말 것)

- `docs_core` 단일소스가 실제로 동작 — 카탈로그 하나 고치면 사이드바·그리드·검색인덱스·네이티브앱이 동기화되고 CI(`catalog_single_source_test.dart`)가 강제. Seed Design 은 정확히 이 지점에서 실패한다(디자인스펙/코드 문서가 별도 시스템, 동기화 보증 없음).
- `accessibility.md` 가 세 벤치마크 통틀어 가장 체계적 — Astryx·daisyUI 는 전용 페이지 자체가 없고 Seed 는 있으나 컴포넌트별 통합이 얕다.
- `app/docs_app`(네이티브 Flutter 문서 앱) — "docs_site 의 Flutter 프리뷰는 사실 Flutter Web(canvaskit) 이라 네이티브 파리티가 아니다" 라는 자기 한계 인식과 실제 발산 버그를 잡은 실적. 세 벤치마크 어디도 이 수준의 네이티브 검증 표면이 없음.
- `docs_api_sync_test.dart` — 규율이 아니라 게이트로 실제 동작 (단, 3장 참조 — 범위가 좁다).
- 139개 컴포넌트 전부에 Web(SSG)+Flutter 듀얼 라이브 프리뷰가 이미 배선 — Seed/daisyUI 의 "정적 코드블록만"보다 앞섬.

## 3. P0 — 지금 바로 고쳐야 하는 것 (그대로 따라하면 깨짐)

| # | 문제 | 파일 | 근거 |
|---|---|---|---|
| P0-1 | pub.dev 에 없는 패키지를 pub.dev 명령으로 설치하라고 함 | `getting-started.md:16-40`, `index.md:40-64`, `guides/installation.md:16-63`, `_data/links.yaml` | 각 pubspec `publish_to: none`, 실제 버전 0.12x대. `links.yaml` 의 pub.dev 링크는 렌더되면 404 |
| P0-2 | 실재하지 않는 Web Button API(`style:[Button.primary,...]`, `onClick`, raw `text()`) | `getting-started.md:107-118`, `index.md:66-74`, `guides/theming.md:89-98`, `guides/cross-platform.md:48-57,143-171` | 실제 생성자는 `Button(variant: CoreButtonVariant.primary, onPressed:, child: Text(...))`. `components/button.md` 는 정확 |
| P0-3 | 존재하지 않는 Flutter `ButtonVariant`/`ButtonSize` | `getting-started.md:97-104`, `guides/cross-platform.md:37-45` | 실제 타입은 `CoreButtonVariant`/`CoreComponentSize` |
| P0-4 | 존재하지 않는 `ComponentThemeData`/`ButtonTheme`, 같은 저장소의 진짜 API(`theming.md`)와 충돌 | `getting-started.md:49-61`, `guides/installation.md:33-48`, `contributing.md:46` | 실제 패턴은 `ThemeData.fromCore(CoreThemeData(...), coreComponentTheme: const CoreComponentTheme(...))` |
| P0-5 | 이미 제거된 `AnimationConstants` 참조 | `guides/theming.md:159-166`, `guides/cross-platform.md:146-157,271`, `components/tree.md:108` | 실제 패턴은 `Duration(milliseconds: CoreDuration.msN)` |
| P0-6 | deprecated 단방향 legacy alias(`--p`,`--s`,`--a`,`--n`,`--b1`)를 커스텀 테마 진입점처럼 안내 | `guides/theming.md:100-112` | 실제 데이터 흐름은 `--coui-primary → --p`(반대 방향), 값 형식도 HSL vs 실제 bare RGB triplet |
| P0-7 | 이미 폐기된 옛 컴포넌트 작성 패턴(`{Name}Theme`/`styleValue()`/Web `Styling` marker) | `contributing.md:38-53` | 현재 표준은 단일 `resolveXxx`/`ResolvedXxx` + `CoreXxxStyle` — 이대로 만들면 CI 가드에서 반려됨 |

## 4. 가져올 패턴 (우선순위별)

**Quick win**
- 컴포넌트 문서에 raw `.md` 직링크 + "Open in Claude" 딥링크 (daisyUI/Astryx)
- `component_catalog.dart` 에 Active/Deprecated 명시 분리, `@Deprecated` 어노테이션에서 자동 파생 (Seed)
- 레거시 vs 통일 컴포넌트 트레이드오프 비교표 (daisyUI Modal 패턴 — `Separator→Divider` 등)
- `docs_api_sync_test.dart` 검증 범위를 `components/*.md` 밖 최상위 페이지·가이드까지 확장 — 3장 P0 전부가 이 사각지대에서 나왔다

**구조 개선**
- `docs_site`(주 표면)에 검색 연결 — `docs_app` 의 `Command` 기반 인덱스(`component_catalog.dart` 파생)를 끌어올리기만 하면 됨
- Seed 의 "State×Slot×Property×Token" 4열 표를 `CoreXxxStyle.defaultsByVariant` 에서 자동 생성
- md 에 "Guidelines"(언제 이 variant 를 쓰나) 섹션 명시 필수화 — `failure-surfaces.md`/`loading-states.md` 판정 로직을 사용자 문서로 재서술
- 버전 스위처 + 과거 릴리스 스냅샷 보존 (daisyUI v1~v4) — CoUI 는 git 태그 참조라 daisyUI 보다 더 절실. 단 먼저 "현재 버전을 정확히 보여주기"(3장 P0-1)부터

**장기 비전**
- llms.txt + Dart CLI + MCP 서버 3중 AI 문서 계층 (Astryx/Seed)
- Web+Flutter 듀얼 프리뷰를 실시간 토큰 편집 도구로 확장 (daisyUI Theme Generator, Astryx `defineTheme`)
- Breaking change 마다 Dart codemod 첨부 (Astryx `astryx upgrade`)

## 5. P1/P2 — 나머지

| 심각도 | 이슈 | 위치 |
|---|---|---|
| P1 | "35+ 내장 테마" 주장이 실제 `CoreThemePresets`(4개)와 불일치 — daisyUI 마케팅 카피 잔존 추정 | `index.md:16`, `guides/theming.md:81` |
| P1 | `contributing.md` 구조도가 `docs_core`/`app/docs_app` 을 빠뜨림 | `contributing.md:8-18` |
| P1 | `form.md` 에서 Flutter 는 Text chain, Web 은 raw jaspr `text()` 를 섞어 씀 | `form.md:36,58-77` |
| P1 | `docs_site`(주 표면)에 전역 검색 없음, `docs_app` 에만 있음 | `docs_site/lib/main.server.dart`, `app/docs_app/lib/src/search/docs_search.dart` |
| P1 | 북극성/설계 원칙을 사용자 대상으로 설명하는 페이지 없음 — `accessibility.md` 가 성공적으로 적용한 방식이 미적용 | `docs_core/content/` 전체 |
| P1 | `LivePreview` 는 고정 variant 쇼케이스일 뿐 편집 가능한 플레이그라운드가 아님 | `docs_site/lib/components/live_preview.dart` |
| P2 | 루트 `CHANGELOG.md`(4224줄, 활발)가 `docs_core` 어디서도 안 걸림 | `CHANGELOG.md` |
| P2 | 컴포넌트 문서 템플릿 섹션 순서가 문서마다 들쭉날쭉 | `_templates/component.md` vs 개별 md |
| P2 | `_data/site.yaml` 의 GitHub 소셜 링크가 실제로 어디에도 안 렌더됨 | `site.yaml`, `main.server.dart:362-369` |

## 부록 — 방문한 소스

- **Astryx**: `/`, `/components`, `/components/Button`(SPA 라 콘텐츠 미노출 → `@astryxdesign/cli` 로 우회), `/sitemap.xml`, `/llms.txt`, `/changelog`, CLI `docs {getting-started,working-with-ai,tokens,color,styling,principles,internationalization,theme}`, CLI `component {Button,Dialog,Table}`, CLI `hook useFocusTrap`
- **Seed Design**: `/`, `/components`, `/foundations`, `/get-started`, `/ai-integration{,/figma-mcp,/docs-mcp,/skill}`, `/updates`, `/components/{action-button,bottom-sheet,select}`, `/foundations/{design-token,color,inclusive-design,motion,state}`, `/patterns`, `/react`, `/react/components/action-button`, `/lynx`, `/breeze`
- **daisyUI**: `/`, `/components/`, `/components/{button,modal,table,validator}/`, `/docs/{colors,themes,install,faq,changelog,editor}/`, `/skills/`, `/theme-generator/`, `/llms.txt`

방법론 한계: Astryx 컴포넌트 상세는 순수 SPA 라 WebFetch 로 콘텐츠를 못 읽어 공식 CLI(`@astryxdesign/cli`, 사이트와 "동일 소스"로 명시됨)로 우회 확인. Seed Design 의 검색 기능 유무는 확인하지 못함. daisyUI 의 클라이언트 사이드 인터랙션(⌘K 모달, Theme Generator 슬라이더의 실제 동작感)은 정적 fetch 로 관찰 불가.
