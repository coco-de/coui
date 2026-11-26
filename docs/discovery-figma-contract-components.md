# Discovery: figma-contract-components

> figma-token-sync 플러그인이 coui_core 컨트랙트를 충실히 따라 컴포넌트를 구현하도록 확장 —
> Display/Control/Form/Layout 섹션 페이지 재구성 · 컴포넌트별 프로퍼티 반영 · 슈거 체인 예시 · docs 설명 반영.
>
> 파이프라인: `.pipeline/figma-contract-components.yaml` (Level 3, 내부 도구) · 조사일 2026-08-06
> 선행: `.pipeline/figma-token-sync.yaml` (현대화 파이프라인 — breakdown 완료, Epic #3766 개발 완료)

---

## 1. 사용자 조사 (내부 도구 — 소비자 = 디자이너 · DS 엔지니어)

### 타깃 사용자
| 페르소나 | Figma 라이브러리에서 원하는 것 | 오늘 겪는 문제 |
|---|---|---|
| **제품 디자이너** | 코드와 동일한 컴포넌트를 인스턴스로 조립, variant 드롭다운·프로퍼티 패널로 상태 전환 | 101개 중 77개가 static 단일 컴포넌트라 variant 전환 불가(예: Tabs 는 pill 이 아예 없음). Size 축은 Badge 외 사실상 전무. boolean prop 0개 |
| **DS 엔지니어** | Figma ↔ 코드가 같은 어휘(variant enum·size·상태·설명)를 쓰는지 감사 가능 | components.json 에 variant enum 멤버 목록·설명·프로퍼티가 없어 대조 불가. 섹션 분류가 코드/카탈로그/플러그인 3벌로 어긋남 |
| **문서 소비자(신규 합류자)** | Figma 인스펙터에서 컴포넌트 설명·코드 사용법(슈거 체인) 확인 | Figma 컴포넌트 `description` 미설정, 코드 예시 프레임 없음 |

### 핵심 인사이트 (실사 기반 — 조사 에이전트 보고)
1. **페이지는 1개뿐** — `🧩 Components` 단일 페이지에 5개 섹션 컬럼(`Form·Display·Navigation·Overlay·Layout`, `registry.ts:16`). 페이지/프레임 계층 없음, 컴포넌트가 페이지에 직접 놓임.
2. **빌더 101개 = variant set 24 + static 77**. Figma component property(BOOLEAN/TEXT/INSTANCE_SWAP)는 **0건** — 축은 `combineAsVariants` 의 variant 드롭다운뿐.
3. **갭 패턴 3종**:
   - **Size 축 전면 부재** — `defaultsBySize` 가 JSON 에 15개 있는데 Figma 노출은 Badge(2축)·Avatar(Size 단독)뿐. 나머지는 `md` 하드코딩 (Button: 12 variant × 6 size = 72 조합이어야 하는데 12개만).
   - **static 이 variant 를 삼킴** — Tabs 는 `CoreTabVariant` pill·underline 중 underline 하드코딩(`navigation.ts:149`). Dialog/Menu/Popover 등 동일.
   - **boolean/state 축 소실·평탄화** — Checkbox 는 `enabled` 를 State 축에 접어넣음, Button `enabled`/`loading`, Tabs `expand`/`swipeable` 은 표현 없음.
4. **components.json (schema v2, 143 컴포넌트)** 은 `fields`/`variants`/`sizes` 3키뿐 — **variant enum 멤버 목록도, 설명도, 생성자 프로퍼티도 없음**. 스타일 default 를 가진 variant 만 키로 등장 → 프로퍼티 반영의 SSOT 로 쓰려면 스키마 확장 필요.
5. **docs 설명은 두 소스 모두 구조화돼 있어 반영 가능**:
   - `docs_core/lib/shared/component_catalog.dart` — 139 엔트리, **영어** 한 줄 설명 + 11그룹(Control 포함) + slug + icon.
   - `docs_core/content/components/*.md` — 139 파일, frontmatter **한국어** description + `category`/`related`/`tags`.
   - exporter 가 이미 `figma_library.json` 을 읽어 meta 에 싣는 선례가 있어 배선이 짧다. 단 slug 3벌(kebab/snake/Pascal) 대조표 필요.
6. **슈거 체인 표면 확보됨** — `withStyle` 확장이 Flutter 131 / Web 132 파일에 존재, docs 에 `*_chain_example.dart` 공식 예시(Kbd·Tabs·Badge 등)가 이미 있다. 룰상 composition slot = Text 체인 / chrome slot = withStyle·토큰 getter 로 역할이 갈리므로 Figma 코드 블록도 이 구분을 따라야 한다.
7. **identity 보존은 걱정보다 낫다** — 컴포넌트 노드는 이름으로 재활용(mint-by-name)되므로 섹션 재편·페이지 이동은 id/key 를 깨지 않는다. 이름 변경만 `SET_RENAMES` 항목 필요. 단 현행 renames/조회는 단일 페이지 스코프라 **다중 페이지 조회로 일반화** 필요.

### 가정 → 검증 방법
| # | 가정 | 리스크 | 검증 |
|---|---|---|---|
| A1 | "페이지 하나당 1 컴포넌트" = 컴포넌트마다 자기 Figma 페이지(=101+ 페이지), 섹션은 페이지 이름 접두/구분 페이지로 표현 | **높음** — 4페이지(섹션당 1)로 해석하면 범위가 완전히 다름 | 사용자 확인 (Specification 게이트) |
| A2 | 4섹션 분류의 기준은 docs 카탈로그가 아니라 사용자가 명명한 4개 — Navigation·Overlay·Menu·Infra 의 소속은 새로 정해야 함 | 높음 | 사용자 확인 + 카탈로그 11그룹 대조표 제시 |
| A3 | 페이지당 1 컴포넌트 구조는 유료 플랜 전제 (Figma Starter 플랜은 파일당 3페이지 제한) | 중간 — 선행 파이프라인 미결 A-5(organization plugin)와 연결 | 대상 파일 플랜 확인 |
| A4 | Button 72조합(12×6) 같은 variant 폭발은 Figma 가 감당하나 생성 시간 예산(NFR-007, 5분)이 위험 | 중간 | Design 단계에서 조합 수 상한/축 정책 결정 + 계측 |
| A5 | 설명 언어는 한국어(md frontmatter) 우선 | 낮음 | 사용자 확인 |

## 2. 선행 사례 / 기존 자산 (시장 조사 대체)

- **선행 파이프라인과의 경계** — 이번 요청의 "컨트랙트를 잘 따라 구현"은 선행 PRD 의 **FR-006(exporter 전수 순회) · FR-007(빌더 SSOT 소비 전환) = Epic E "빌더 SSOT 전환"(#3725, p1 31pt, 미착수)** 및 **Epic D "판독기·스키마 v2"(#3724)** 와 직접 겹친다. breakdown 에서 중복 이슈 금지 — 이번 파이프라인이 Epic D/E 를 **확장·승계**하는 형태로 정리해야 한다.
- **차별점(신규 범위)** — 선행 파이프라인에 없는 것: ① 섹션/페이지 재구성, ② Figma component property(BOOLEAN/TEXT 등) 도입, ③ variant enum 멤버·설명의 스키마 확장(사실상 schema v3), ④ 슈거 체인 코드 예시 프레임, ⑤ `ComponentNode.description`/`documentationLinks` 기록.
- **가드 자산 승계** — G1(신선도)·G3/G4(리더 census)·G6(typecheck+selftest)·G7(빌더 리터럴 ratchet 587, 성공 판정) 이 이미 CI 에 있다. **발견: G2(레지스트리 parity)는 파일·baseline 만 있고 CI 미배선** — 이번 작업이 registry 를 크게 흔들므로 G2 배선이 선행 조건 후보.
- **Figma 플랫폼 API** — `ComponentNode.description`/`documentationLinks` 쓰기 가능(인스펙터 노출), `addComponentProperty` 로 BOOLEAN/TEXT/INSTANCE_SWAP 정의 가능. 페이지 생성 무제한(유료 플랜).

## 3. 비전

**한 줄 비전**: *Figma 라이브러리가 coui_core 컨트랙트의 투영이 된다 — 디자이너가 Figma 에서 보는 축(variant·size·상태)·설명·코드 예시가 코드와 같은 SSOT 에서 나온다.*

**North Star Metric — 축 반영률(axis coverage)**: 컨트랙트가 선언한 표현 가능한 축(variant enum × defaultsBySize × 상태 enum/bool) 중 Figma variant/property 로 실제 노출된 축의 비율. G7(리터럴 ratchet)과 같은 방식의 **ratchet 가드(신설 G10 후보)** 로 계측 — selftest-registry-runtime 이 이미 빌더를 실 JSON 으로 구동하므로 분모(컨트랙트 축)·분자(바인딩된 축)를 셀 자리가 있다.

## 4. 해법 방향 (Ideation)

1. **스키마 v3** — exporter 가 `{component}_variant.dart` 의 enum 멤버 전수, size 목록, 상태 축, docs 설명(catalog+md frontmatter)을 components.json 에 추가. 결정성·골든 테스트 유지.
2. **페이지 재구성** — 섹션 순서 페이지 + 컴포넌트당 페이지(`{Section} / {Component}` 명명 규약). mint-by-name 조회를 문서 전체 스코프로 일반화, 이동은 구조 마이그레이션(renames.ts 계열)로 1회 처리.
3. **빌더 일반화** — variant×size 조합은 JSON 의 축 데이터에서 파생(하드코딩 금지 = G7 방향과 일치), boolean/state 는 Figma component property 로.
4. **문서 표면** — 컴포넌트 `description`(한국어 md frontmatter 우선) + `documentationLinks`(docs_site URL). 페이지 안에 ① 컴포넌트 셋 ② 프로퍼티 표 ③ 코드 예시(기본 생성자 / withStyle / 토큰 getter 체인 — docs 의 `*_chain_example.dart` 재사용) 프레임.
5. **커버리지 경계** — G2 uncovered 44개(Infra·Icon·Text 계열 다수)는 이번 범위에서 제외/포함을 명시적으로 정한다 (카탈로그 Infra 그룹은 docs 미등록 관례와 대칭으로 미노출이 자연스러움).

### 기술 타당성 요약
| 항목 | 판정 | 근거 |
|---|---|---|
| 페이지당 1 컴포넌트 + identity 보존 | ✅ 가능 | mint-by-name 은 이름 기반, 페이지 이동은 id/key 유지. 조회 스코프만 일반화 |
| 컨트랙트 프로퍼티 반영 | ✅ 가능 (스키마 확장 필요) | AST 리더가 이미 제네릭 전수 순회 — variant enum 파일 판독 추가 |
| 슈거 체인 예시 | ✅ 가능 | docs `*_chain_example.dart` 소스 존재, 코드 텍스트 블록 + 스타일 패치 적용 렌더 프레임 |
| docs 설명 반영 | ✅ 가능 | 구조화된 2소스 + `ComponentNode.description` API + exporter 선례 |
| 위험 | ⚠️ | variant 폭발(72조합)·5분 예산, 무료 플랜 3페이지 제한, 다중 페이지 마이그레이션 1회성 안전장치 |

## 5. Specification 단계로 넘기는 것

1. **A1 해소** — "페이지 하나당 1 컴포넌트"의 정확한 의미 (컴포넌트당 페이지 vs 섹션당 페이지).
2. **4섹션 매핑표 확정** — Navigation(9)·Overlay(12)·Menu(5)·Infra(14)·Icon/Text 의 소속. 특히: Button/Fab/Filter/Command → Control 이동 여부, Alert(현행 Display)·Toast(현행 Overlay) 정합.
3. **프로퍼티 반영의 "필수" 범위** — variant·size 축만인지, boolean/state component property 까지인지, 조합 폭발 상한.
4. **슈거 체인 예시 형식** — 코드 텍스트 블록만 vs 스타일 적용 렌더 프레임 동반.
5. **설명 언어·출처 우선순위** — 한국어 md frontmatter vs 영어 catalog.
6. **선행 Epic D/E 승계 방식** — 기존 이슈 재사용 vs 신규 Epic 으로 supersede.
