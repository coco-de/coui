# Seed Spec: figma-contract-components

> 상태: **LOCKED** (2026-08-06 · Contrarian 13건/Simplifier 5건 반영 · 사용자 게이트 확정 4건 반영)
> 파이프라인 `.pipeline/figma-contract-components.yaml` · 입력: `docs/discovery-figma-contract-components.md`, `docs/socratic-discovery-figma-contract-components.md` · 검토 반영 내역: `docs/decision-log-figma-contract-components.md`

## 0. 한 문장

figma-token-sync 플러그인이 coui_core 컨트랙트의 투영이 되도록 — **컴포넌트당 페이지 1개(4섹션 접두 정렬) · 컨트랙트 축 4종 완전 조합 · 전 프로퍼티 문서화 · 코드 예시(슈거 체인) · docs 설명**을 SSOT(components.json schema v3)에서 파생해 그린다.

## 1. 용어 (닫힌 정의)

| 용어 | 정의 |
|---|---|
| **섹션** | Display·Control·Form·Layout 4개. 출처 = coui_flutter 카테고리 디렉터리 + 고정 fold 맵(Control←control+navigation+menu / Display←display+overlay+text+icon / Form←form / Layout←layout / infra 제외). 디렉터리 단위 fold 만 — 컴포넌트별 재분류 없음 |
| **variant 축** | `Core{Component}Variant` 명명 규약의 enum (그 enum 하나로 한정 — 한 파일에 enum 이 여럿이어도 이 규약으로 기계 판별) |
| **4축** | variant 축 × `CoreComponentSize` × 상호배타 state enum(`Core{Component}State` 류) × `enabled`(bool). **State 와 Enabled 는 별도 축** — 곱집합 보존(disabled×checked 소실 금지). 예: Button = 12×6×2 = **144**, Checkbox = 1×6×3×2 = 36 |
| **기타 축(`axes.other`)** | 4축 밖의 상호배타 시각 enum(mode/orientation/labelPosition 류). schema v3 에 **전수 기록** + Properties 표에 **전수 문서화**. Figma variant 축 승격은 이번 범위 외(§4-2) |
| **schema v3** | components.json 확장판(v2 상위 집합): + `section`·`axes`(4축 + other 전수)·`docs`(설명·URL·slug 대조)·`examples`(식 스니펫) |
| **대상 컴포넌트** | REGISTRY 등재 **N=101** (2026-08 실측 — fold 상 infra 소속 빌더 0. 이후 infra 로 fold 되는 엔트리가 생기면 그 노드는 RETIRED 등재로 처분) |

## 2. 기능 요구 (Must)

### FR-1. schema v3 — exporter 확장 (`packages/coui_core/bin/`)
- v3 는 v2 의 상위 집합(기존 키 불변 — G1·G3·G4·selftest 하위호환).
- 컴포넌트별 추가:
  - `section` + `sourceCategory` (fold 맵은 exporter 내 단일 상수)
  - `axes.variant`(variant 축 enum 멤버 전수 + `defaultVariant`) · `axes.size` · `axes.state` · `axes.enabled`(존재 여부) · `axes.other[]`(기타 축 enum 별 멤버 전수)
  - `docs.description`(한국어 md frontmatter 우선, 카탈로그 영어 fallback) · `docs.url` · `docs.slugs{kebab,snake,pascal}`
  - `examples`: **추출된 식(expression) 스니펫만** — `withStyle` 1종 + 토큰 getter 체인 1종 (docs `*_chain_example.dart` 에서 식 추출 우선, 없으면 컨트랙트 파생 canonical). **기본 생성자 스니펫은 저장하지 않고** 빌더가 `axes`+필수 필드에서 파생 (verbatim 클래스 소스 금지 — JSON 비대·소재 부적합)
- 결정성 유지(2회 byte-identical), 골든 테스트 확장.

### FR-2. 페이지 재구성 — 컴포넌트당 1페이지
- 페이지 이름 `{Section} / {Component}`. **구분 페이지 없음** — 섹션 경계는 이름 접두 + 물리 정렬(섹션순 Display→Control→Form→Layout, 섹션 내 알파벳순)로 표현. 이 순서 주장의 적용 범위는 **파일 내 페이지 목록 한정** (라이브러리 Assets 패널은 자체 정렬 — 범위 외).
- 페이지 수 = N + 1(`🎨 Palette Generator` 불변).
- 페이지 내부 **3프레임**: ① 컴포넌트/ComponentSet ② Properties 표(4축 + `axes.other` + 나머지 컨트랙트 프로퍼티 **전수** — 이름·타입·기본값·설명; 캡션에 컨트랙트 파일 경로) ③ Code Examples(FR-4).
- **프레임 ②③도 per-entry content-hash skip 대상** — 엔트리 hash 입력에 그 콘텐츠(v3 서브트리) 포함. 매회 재생성 장식 금지(2회차 all-skip 이 시간에도 성립해야 함).
- **마이그레이션(신설 필수)**: 기존 `🧩 Components` 페이지의 노드는 **`PAGE_MIGRATIONS` 규약 신설**로 새 페이지에 `appendChild` **이동**(id/key 보존). 기존 `STRUCTURAL_MIGRATIONS`(삭제 기반)는 이 용도로 사용 금지. mint/mountSet 조회 스코프의 문서 전체 일반화 + 이동 + 승격(FR-3)은 **동일 릴리스에 원자적으로** 들어간다.

### FR-3. 축 반영 — 4축 완전 조합 (완전 호환 A)
- 대상 N개 각각: v3 `axes` 에서 Figma variant 축을 **파생**(빌더 하드코딩 금지): `Variant=` / `Size=` / `State=` / `Enabled=` — 존재하는 축의 완전 조합(최대 Button 144).
- **static → variant set 승격은 입양(adoption)**: 기존 ComponentNode 를 `{Axis}=<현행값>` 으로 rename 후 `combineAsVariants` 에 **포함** — remove+rebuild 금지(key 파괴 경로). `mountSet` 에 loose COMPONENT 입양 경로 추가.
- `axes.other` 는 이번에 Figma 축으로 승격하지 않는다(§4-2) — Properties 표 문서화가 반영 수단.
- 색·치수는 Figma variable 바인딩(G7 리터럴 ratchet 감소 방향).

### FR-4. 코드 예시 프레임
- 전 페이지 코드 텍스트 블록: ① 기본 생성자(빌더 파생) ② `withStyle` ③ 토큰 getter 체인. **게이트 최소 = 2종**(기본 + 슈거 체인 1종 — 사용자 확정 범위) — ②③ 분해는 soft(예산 압박 시 병합 가능).
- 역할 분리 준수: composition slot 은 Text 체인 표기, chrome 은 withStyle 계열.

### FR-5. docs 설명 반영
- `ComponentSetNode/ComponentNode.description` = v3 `docs.description`(한국어). `documentationLinks` = v3 `docs.url`. (페이지 내 별도 설명 프레임 없음 — Properties 표 캡션과 네이티브 메타데이터로 충족.)

### FR-6. 가드
- **G10 축 반영률(성공 판정)**: **신규 스크립트가 아니라 `selftest-registry-runtime.ts` 확장** — (a) 하네스에 **빌드 결과 트리 축 판독기** 추가(반환 트리의 variant 자식 `variantProperties` 집합 수집 — 현행 하네스는 호출 tally 만 기록하므로 이 확장이 명시적 Must), (b) v3 `axes` 4축과 diff, uncovered 0 을 종료 코드에 반영, 로그 섹션 라벨 "G10". `axes.other` 는 게이트가 아닌 별도 카운트로 보고(후속 추적).
- **G2 CI 배선**(현재 미배선) — registry 를 흔들기 전 선행.
- 기존 G1·G3·G4·G6·G7 green 유지, G7(587) 증가 금지. G1 유의: docs 설명/예시 편집도 exporter 재실행 대상이 된다 — per-entry hash 입도(FR-2)로 재빌드 파장은 해당 엔트리로 한정.

## 3. 비기능 요구

| ID | 내용 |
|---|---|
| NFR-A | 멱등: 변경 없는 2회차 = 전 엔트리 skip — **skip 판정 입도는 per-entry v3 서브트리**(JSON 전체 hash 로 접지 않음 — 한 컴포넌트의 docs 수정이 101개 재빌드를 유발하면 위반) |
| NFR-B | 결정성: exporter 2회 byte-identical |
| NFR-C | 단방향 code→Figma, `networkAccess: none` 유지 |
| NFR-D | 부분 실패 격리: per-entry 트랜잭션 유지 |
| NFR-E | 생성 예산 ≤ 5분 — 재계측 항목에 **144-variant set·페이지별 프레임 TextNode·전 페이지 `loadAsync`(dynamic-page)** 명시 포함. 초과 시 예산 재협상(기능 축소 아님) |
| NFR-F | 마이그레이션 안전: 1회성 명시 목록, 실행 전후 **ComponentNode key 불변** 검증 로그(승격으로 새로 생기는 ComponentSet 노드 자체는 신규임을 명시 — 검증 단위는 자식 ComponentNode key) |

## 4. 범위 외 (Won't — 이번 파이프라인)

1. 상호작용 상태(hover/press/focus) variant — 생성자 표면 아님.
2. **`axes.other`(mode/orientation 류)의 Figma variant 축 승격** — v3 기록 + Properties 표 문서화까지가 이번 범위. 승격은 후속(별도 카운트로 추적). *(예: NavigationBar 의 bar/rail/sidebar 는 표에는 있으나 Figma 축으로는 미노출 — 명시적 한정)*
3. **BOOLEAN/TEXT/INSTANCE_SWAP component property** — 사용자 확정으로 후속 분리(신규 AST 휴리스틱·Figma API·하네스 double 필요).
4. registry 미등재 42종 신규 빌더 / infra 14종 노출.
5. 스타일 패치 적용 렌더 프레임(코드 블록만) / 섹션 구분 페이지(폐기 확정).
6. 표면 재질 토큰 · Palette Generator 변경 · docs_site 변경(읽기 전용) · Figma→code 역방향 · 무료 플랜 지원(README 명시).

## 5. 완료 판정 (게이트)

- [ ] G10: 대상 N 에서 4축 uncovered **0** (selftest 확장 경로) — **성공 판정**
- [ ] G1·G2(신규 배선)·G3·G4·G6·G7 green, G7 비증가
- [ ] 페이지 수 = N + 1 · 명명 규약 100% · 구분 페이지 0
- [ ] 마이그레이션 전후 ComponentNode key 불변 로그 확인
- [ ] 2회차 실행 all-skip (엔트리 판정 + 실행 시간 모두)
- [ ] 무작위 표본 10: description(한국어)·documentationLinks·예시 ≥2종·Properties 표(4축+other 전수) 존재

## 6. Planning 으로 넘기는 미해결

- Epic D(#3724)/E(#3725) 승계·supersede 형식 (breakdown 집행)
- NFR-E 재계측 결과에 따른 예산 협상
- 선행 미결 A-5(organization plugin)는 착수를 막지 않음
