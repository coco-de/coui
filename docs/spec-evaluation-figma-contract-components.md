# Spec Evaluation: figma-contract-components

## Summary
- Target: `docs/seed-spec-figma-contract-components.md` (LOCKED, 2026-08-06 검토 반영본)
- Evaluation Date: 2026-08-07
- 평가 입력: `docs/socratic-discovery-figma-contract-components.md` · `docs/discovery-figma-contract-components.md` · `docs/decision-log-figma-contract-components.md` · `.pipeline/figma-contract-components.yaml` · 실코드 4종(`tools/figma-token-sync/src/{helpers,renames,generate}.ts`, `tools/figma-token-sync/scripts/selftest-registry-runtime.ts`)
- **Final Verdict: PASS**

### 게이트 판정 표

| 게이트 | 기준 | 실측 | 판정 |
|---|---|---|---|
| Ambiguity | ≤ 0.2 | **0.07** (5차원 평균, 최고 차원 0.10) | ✅ |
| Convergence | ≥ 0.95 | **1.00** (39/39 — 요구원문 5 + 소크라틱 Q 10 + discovery 이월 6 + 검토항목 18 전부 해소/명시처분) | ✅ |
| Contrarian unresolved Critical | 0 | **0** (Critical = CH-007 단 1건, D-13 으로 스펙 본문 반영 확인) | ✅ |
| Consensus | 3/3 | **3/3 APPROVE (single-model panel)** | ✅ |

---

## Stage 1: Mechanical Verification — **PASS (10/10)**

| ID | 항목 | 결과 | 증거 |
|---|---|---|---|
| M-01 | 용어 정의 닫힘 | ✅ | §1 표 6항목 전부 기계 판별 가능한 닫힌 정의 — 섹션은 "디렉터리 단위 fold 만, 컴포넌트별 재분류 없음", variant 축은 `Core{Component}Variant` 명명 규약, 대상은 "N=101 (2026-08 실측)" + 이탈 시 처분 규칙(RETIRED)까지 명시 |
| M-02 | Must / Won't 분리 | ✅ | §2 FR-1~FR-6 (Must) ↔ §4 Won't 6항목. 경계 케이스에 처분 명시 — `axes.other` 승격은 "명시적 Won't + 별도 카운트 추적"(§4-2), BOOLEAN/TEXT/INSTANCE_SWAP 은 "사용자 확정으로 후속 분리"(§4-3) |
| M-03 | 완료판정 측정가능성 | ✅ | §5 게이트 6항목 전부 기계/절차 판정 가능: G10 uncovered 0(종료 코드), 가드 green, 페이지 수 = N+1, key 불변 로그, 2회차 all-skip(판정+시간), 표본 10 존재 검사 |
| M-04 | 대상 수 명기 | ✅ | §1 "REGISTRY 등재 **N=101** (2026-08 실측 — fold 상 infra 소속 빌더 0)". §4-4 미등재 42종과 산수 정합(143−101=42) |
| M-05 | NFR 존재 | ✅ | §3 NFR-A~F 6항목 — 각각 위반 판정 기준 동봉(예: NFR-A "한 컴포넌트의 docs 수정이 101개 재빌드를 유발하면 위반") |
| M-06 | 미해결 항목 명시 | ✅ | §6 3항목(Epic D/E 승계 형식 · NFR-E 재계측 협상 · A-5 non-blocking) — 전부 Planning 단계 소관으로 이관 근거 명시 |
| M-07 | 산출물 경로 | ✅ | 헤더에 파이프라인·입력·결정로그 경로, FR-1 에 `packages/coui_core/bin/`, FR-6 에 `selftest-registry-runtime.ts`. ⚠️ 참고: selftest 파일의 전체 경로는 `tools/figma-token-sync/scripts/` — 스펙은 파일명만 적었으나 레포 내 유일 파일이라 모호성 없음 |
| M-08 | 결정 근거 추적성 | ✅ | decision log D-1~D-22 + CH-003/S-001대안 기각 2건. 각 결정에 출처 태그([사용자]/[룰]/[코드]/[검토]) + 기각된 대안 열 존재. 스펙 각 조항이 D-ID 로 역추적됨(하단 Stage 2b 표) |
| M-09 | 자기모순 0 | ✅ | 지정 3점 검산: ① §1 산수 — Button 12×6×2=**144** ✓(state enum 부재로 3축 곱), Checkbox 1×6×3×2=**36** ✓ ② FR-2 페이지 수 — N+1=102, §5 게이트·§4-5(구분 페이지 폐기)와 정합 ✓ ③ FR-6 G10 분모(v3 `axes` 4축) = FR-3 파생원(v3 `axes`), 모집단 동일(REGISTRY N=101 — selftest 는 REGISTRY 를 구동하므로 구조적으로 일치) ✓. FR-1(예시 저장 2종) ↔ FR-4(표시 3종, 게이트 2종) 도 "기본 생성자 = 저장 없이 파생"으로 무모순 |
| M-10 | 검증 명령·게이트 실재성 | ✅ | 실코드 대조 — G2 "현재 미배선" 주장 = discovery 실사와 일치. G10 의 전제 "현행 하네스는 호출 tally 만 기록" = `selftest-registry-runtime.ts:82-88`(`callTally` 기록만, 축 판독 없음)로 사실 확인. NFR-A 의 "JSON 전체 hash 로 접지 않음" 요구 = `generate.ts:129`(`fnv1a(JSON.stringify(componentsJsonRaw))` 전체 hash를 매 엔트리에 폴드)가 실제 현행 결함이라 요구가 실코드를 정확히 겨냥함 |

**Stage 1 마이너 노트 (비차단)**: FR-2 마이그레이션이 노드 이동(appendChild)까지만 규정하고 **비워진 기존 `🧩 Components` 페이지 자체의 처분**(삭제/개명)을 명시하지 않음. 단 §5 게이트 "페이지 수 = N+1" 이 이를 구현 의무로 강제하므로 모순이 아닌 미세 미기술 — breakdown 에서 PAGE_MIGRATIONS 규약에 소스 페이지 처분 1줄 추가 권고.

---

## Stage 2: Semantic Verification — **PASS**

### 2a. Ambiguity Score: **0.07** → PASS (≤ 0.2)

| 차원 | 점수 | 근거 (스펙 인용) |
|---|---|---|
| 용어 | 0.10 | 대부분 기계 판별 규칙으로 닫힘 — variant 축: "`Core{Component}Variant` 명명 규약의 enum (그 enum 하나로 한정 — 한 파일에 enum 이 여럿이어도 이 규약으로 기계 판별)". 잔여 모호: state 축의 "`Core{Component}State` **류**" — variant 축과 달리 '류' 표현이 판별 규칙을 한 단계 느슨하게 함(exporter 구현 시 판별 술어 1개 확정 필요) |
| 범위 | 0.05 | "대상 컴포넌트 = REGISTRY 등재 N=101" + 경계 이탈 처분("이후 infra 로 fold 되는 엔트리가 생기면 그 노드는 RETIRED 등재로 처분") + Won't 6항목에 각각 후속 추적 장치 명기 |
| 수치 | 0.05 | 전 수치 명시·검산 가능: 144/36 예시 산수, 페이지 수 N+1, 예시 게이트 "최소 = 2종", 예산 "≤ 5분", 표본 "10", G7 "587 증가 금지" |
| 의존성 | 0.10 | 의존이 숨지 않고 전부 명시: "G2 CI 배선 — registry 를 흔들기 전 **선행**"(FR-6), "스코프의 문서 전체 일반화 + 이동 + 승격은 **동일 릴리스에 원자적으로**"(FR-2), Epic D/E 승계는 §6 으로 명시 이월. 잔여: 승계·supersede 의 구체 형식이 Planning 이월(의도적 — 감점 최소) |
| 검증가능성 | 0.05 | 성공 판정이 사람 검수가 아닌 기계 게이트: "uncovered 0 을 종료 코드에 반영"(FR-6), "2회차 실행 all-skip (엔트리 판정 + 실행 시간 모두)"(§5). 멱등 위반 판정문까지 스펙에 내장(NFR-A) |

종합 = (0.10+0.05+0.05+0.10+0.05)/5 = **0.07**.

### 2b. Contrarian 처분 검증 — Unresolved Critical **0** / Unresolved Major **0**

decision log 의 처분을 스펙 **본문**과 1:1 대조 (Evidence = 스펙 조항 실재 확인):

| CH | 심각도 | 처분(D-ID) | 스펙 본문 증거 | 해소 |
|---|---|---|---|---|
| CH-007 | **Critical** | D-13 수용 | FR-2 "`PAGE_MIGRATIONS` 규약 신설로 새 페이지에 `appendChild` 이동(id/key 보존). 기존 `STRUCTURAL_MIGRATIONS`(삭제 기반)는 이 용도로 사용 금지" + FR-3 "입양: rename 후 `combineAsVariants` 포함 — remove+rebuild 금지" + NFR-F "검증 단위는 자식 ComponentNode key" + FR-2 원자성 조항 | ✅ |
| CH-001·002 | Major | D-14 수용 | §1 4축 "State 와 Enabled 는 **별도 축** — 곱집합 보존(disabled×checked 소실 금지). 예: Button = 12×6×2 = 144" | ✅ |
| CH-011 | Major | D-15 수용 | §1 variant 축 명명 규약 판별 + `axes.other` 전수 기록 + §4-2 승격 명시적 Won't(별도 카운트) | ✅ |
| CH-004 | Major | D-20 수용 | FR-2 "프레임 ②③도 per-entry content-hash skip 대상 — 엔트리 hash 입력에 그 콘텐츠(v3 서브트리) 포함… 2회차 all-skip 이 시간에도 성립" | ✅ |
| CH-008 | Major | D-18 수용 | FR-1 "추출된 식(expression) 스니펫만… 기본 생성자 스니펫은 저장하지 않고 빌더가 파생 (verbatim 클래스 소스 금지)" + NFR-A per-entry 서브트리 hash | ✅ |
| CH-009 | Major | D-19 수용 | FR-6 "신규 스크립트가 아니라 `selftest-registry-runtime.ts` **확장** — 빌드 결과 트리 축 판독기 추가…가 명시적 Must" | ✅ |
| CH-003 | — | 기각 유지 (Contrarian 스스로 기각) | 조합 규모 144 는 Figma 실무 범위 내 — 축소 없음. 기각 근거가 로그에 기록됨 | ✅ (기각 정당) |
| CH-005 | (사용자 게이트) | D-17 확정 | FR-2 "구분 페이지 없음 — 이름 접두 + 물리 정렬… 적용 범위는 파일 내 페이지 목록 한정(Assets 패널 범위 외)" | ✅ |
| CH-006·012·013 | Minor | D-21 수용 | NFR-E(loadAsync·TextNode 계상) / FR-4(게이트 최소 2종) / §1(N=101 실측 + RETIRED 처분) | ✅ |
| CH-010 | (사용자 게이트) | D-16 확정 | §4-3 BOOLEAN/TEXT/INSTANCE_SWAP 후속 분리 + "프로퍼티 반영 필수 = 4축 variant + Properties 표 전수 문서화로 충족" | ✅ |

13건 전부 Evidence 비어있지 않음(전 항목 스펙 조항 실재 확인) — fail-closed 기준으로도 Unresolved 0.

### 2c. Simplifier 수용분 반영 확인 — 미결 **0**

| S | 처분 | 스펙 반영 확인 |
|---|---|---|
| S-001 | 수용 (대안 '별도 examples 파일'은 기각 — SSOT 2개화 근거 기록) | FR-1 examples 식 스니펫 인라인 ✅ |
| S-002 | 수용 (사용자 확정) | FR-2 구분 페이지 폐기 · §4-5 재확인 ✅ |
| S-003 | 수용 | FR-6 G10 = selftest 확장 (신규 스크립트 아님) ✅ |
| S-004 | 게이트 확정 — 후속 분리 | §4-3 (수용분 목록 외이나 처분 명시 — 미결 아님) ✅ |
| S-005 | 수용 | FR-2 "3프레임" + FR-5 "페이지 내 별도 설명 프레임 없음 — Properties 표 캡션과 네이티브 메타데이터로 충족" ✅ |

5건 전부 accept/reject 처분 존재. (별도 복잡도 점수 산출물은 없음 — 팀 리드 지시에 따라 2c 는 수용분 반영 확인으로 평가. Simplifier 5건 전량 처분 완료로 미결 0.)

---

## Stage 3: Consensus Verification (single-model panel) — **PASS · 3/3 APPROVE**

> 세 페르소나는 단일 워크플로 에이전트의 prompt-only 역할이며 별개 모델이 아니다. 아래 만장일치는 상관된 단일 모델 의견으로 읽어야 한다.

| Role | Verdict | Key Comments |
|---|---|---|
| Analyst | APPROVE | 요구 원문 5항목 전부 충족, 2항목은 초과 충족. REQUEST_CHANGES 후보 1건 제시(비차단) |
| PM | APPROVE | Won't 경계마다 추적 장치 결합 — 집행 가능. 승계 리스크는 §6 명시 이월. 후보 1건 제시(비차단) |
| Architect | APPROVE | 실코드 대조 결과 FR-2/FR-6 전부 기술 실현 가능 + 스펙이 현행 코드 결함을 정확히 겨냥. 후보 1건 제시(비차단) |

### Analyst — 요구 원문 대비 판정

| 요구 원문 (`requirements_verbatim`) | 판정 | 근거 |
|---|---|---|
| "coui_core 컨트랙트를 잘 따라 컴포넌트를 구현" | **충족+초과** | 충실도를 감상이 아닌 게이트로 환원 — schema v3 SSOT(FR-1) + 빌더 하드코딩 금지 파생(FR-3) + **G10 uncovered 0 이 성공 판정**(FR-6/§5). "잘 따른다"의 조작적 정의가 생겼다 |
| "섹션별 페이지 하나당 1 컴포넌트" | **충족** | FR-2 = 컴포넌트당 1페이지 + `{Section} / {Component}`. 구분 페이지 폐기는 사용자 게이트 A4 확정으로 원문 해석 변경이 아닌 정제 |
| "컴포넌트별 프로퍼티 반영은 필수" | **충족 (사용자 확정 기준)** | 4축 완전 조합(A) + Properties 표 **전수** 문서화. BOOLEAN/TEXT/INSTANCE_SWAP 후속 분리는 사용자 게이트 확정(D-16)으로 "필수"의 범위가 재정의됨 — 원문 축소가 아니라 확정된 범위. Button `loading` 같은 비-축 boolean 도 표 전수 문서화 경로로 커버 |
| "가능하다면 슈거 체인 예시" | **초과** | soft 요구("가능하다면")를 hard 게이트(최소 2종, §5)로 승격. 역할 분리(composition=Text 체인 / chrome=withStyle) 룰 정합까지 명시(FR-4) |
| "docs 설명도 같이 반영" | **충족** | FR-5 description(한국어 우선)+documentationLinks. 표면 축소(별도 프레임 폐지)는 S-005 검토 수용 — 네이티브 메타데이터로 동일 정보 도달 |

- 테스트 작성 가능성: §5 전 게이트가 명령/종료코드/카운트로 환원됨 — **이 스펙에서 인수 테스트를 직접 쓸 수 있다**.
- **REQUEST_CHANGES 후보 (비차단)**: §5 표본 게이트의 "description(**한국어**)" 표기 — FR-1 은 "한국어 우선, 영어 fallback" 이므로 fallback 만 존재하는 컴포넌트가 표본에 뽑히면 게이트 문구와 충돌 소지. registry 101 ⊆ md 139 이 확인되지 않은 상태라, 게이트 문구를 "description 존재(FR-1 우선순위 규칙 적용)"로 완화하거나 breakdown 에서 101↔139 대응을 grep 확정할 것.

### PM — 범위 경계·게이트 집행 가능성·승계 리스크

- **Won't 집행 가능성**: 6항목 각각이 "안 한다"로 끝나지 않고 추적 장치와 짝지어짐 — axes.other 승격은 "별도 카운트로 보고(후속 추적)"(FR-6), 미등재 42종은 G2 uncovered ratchet, BOOLEAN류는 사용자 확정 후속. 범위 침식이 조용히 일어날 통로가 없다.
- **게이트 집행 가능성**: G10 이 종료 코드에 실려 CI 가 판정 주체가 됨 — "가드 green ≠ Figma 정합"이라는 선행 파이프라인 교훈이 성공 판정 설계에 반영됨(D-11). G2 미배선을 **선행 조건**으로 끌어올린 것(FR-6)은 registry 를 흔드는 작업의 리스크 관리로 적절.
- **승계 리스크(Epic D #3724 / E #3725)**: 이번 스펙이 D 의 연장(schema v3)·E 의 상위 집합임을 discovery 가 이미 판정했고, 스펙은 형식 결정만 §6 으로 이월 — "중복 이슈 금지" 원칙이 decision log D-12 에 고정돼 있어 breakdown 에서 집행 가능. 미이월 시나리오(무관 Epic 병립)는 기각 대안으로 기록됨.
- **REQUEST_CHANGES 후보 (비차단)**: NFR-E "초과 시 예산 재협상(기능 축소 아님)" — 기능은 지키고 시간만 늘리는 단방향 협상 조항이라, 재계측 결과가 크게 초과할 경우 릴리스 일정 리스크가 스펙 안에서 상한 없이 열려 있음. Planning 에서 재협상의 상한(예: 예산 2배 초과 시 분할 릴리스)을 정할 것을 권고.

### Architect — FR-2·FR-6 기술 실현성 (실코드 판독 기반)

**FR-2 PAGE_MIGRATIONS / 조회 일반화 / 원자성 — 실현 가능 ✅**
- 현행 `helpers.ts` 의 `mint()`/`mountSet()` 은 `page.children` 단일 페이지 스코프(191·223행), `generate.ts` 는 `🧩 Components` 단일 페이지 고정(77행) — 스펙의 "조회 스코프 문서 전체 일반화" 요구가 실제 코드 형상과 정확히 일치한다.
- `renames.ts` 는 이미 "명시 목록 + 멱등 + 조회 전 선적용" 패턴(`applyPendingRenames`, 86-95행)을 갖고 있어 PAGE_MIGRATIONS 는 동형 확장이다. Figma `PageNode.appendChild` 는 reparent 이동이라 id/key 보존 — 스펙 주장과 부합.
- 스펙이 "STRUCTURAL_MIGRATIONS(삭제 기반) 사용 금지"라 한 것은 실코드로 검증됨 — `applyStructuralMigrations` 는 `node.remove()`(127행) 기반이 맞고, 그 존재 이유(COMPONENT↔SET in-place 변환 API 부재, renames.ts 51-53행 주석)까지 스펙의 입양 설계가 정확히 우회한다.
- dynamic-page 모드의 `page.loadAsync()` 의무(generate.ts 83-85행)가 다중 페이지에서 N+1회로 늘어나는 비용을 NFR-E 재계측 항목에 **명시** — 함정을 스펙이 선반영.

**FR-3 입양 승격 — 실현 가능 ✅**
- `combineAsVariants` 는 기존 ComponentNode 를 새 Set 으로 감싸며 자식 key 를 보존 — NFR-F 가 "새로 생기는 ComponentSet 노드 자체는 신규, 검증 단위는 자식 ComponentNode key"로 정확히 그 경계를 긋는다. `mountSet` 의 현행 조회가 `COMPONENT_SET` 타입만 찾으므로(224-225행) "loose COMPONENT 입양 경로 추가"가 필요하다는 스펙 지목도 정확. rename 후 결합 시 `verifyAppendedVariant`(281행)가 variantProperties 를 즉시 검증하는 기존 안전망에 그대로 얹힌다.

**FR-6 G10 selftest 확장 — 실현 가능 ✅**
- 스펙의 전제 "현행 하네스는 호출 tally 만 기록" = 사실(`callTally`, 82-88행). 판독기 실현성: FakeNode 트리가 자식·`variantProperties` 를 **이미 보존**한다 — `appendChild` 가 `COMPONENT_SET` 자식에 `parseVariantKey(child.name)` 를 세팅(263-265행)하므로, 반환 트리를 걷어 축 집합을 수집하는 판독기는 double 확장 없이 붙는다. v3 `axes` 와의 diff 는 하네스가 이미 실 JSON 을 구동하므로 분모 접근도 확보. 종료 코드 배선(`process.exit(1)`, 404행)도 기존 경로 재사용.
- NFR-A 의 hash 입도 요구가 실코드 결함을 정확히 겨냥함을 확인: 현행 `generate.ts:129` 는 **JSON 전체** hash 를 모든 엔트리 hash 에 폴드 — 한 컴포넌트의 docs 수정이 오늘은 101개 전체를 invalidate 한다. per-entry v3 서브트리 hash 로의 전환은 국소 변경(hash 입력 치환)으로 실현 가능.

- **REQUEST_CHANGES 후보 (비차단, Stage 1 노트와 동일 건)**: PAGE_MIGRATIONS 가 노드 이동 후 **비워진 `🧩 Components` 페이지의 처분**을 규정하지 않음 — §5 "페이지 수 = N+1" 게이트가 결과를 강제하긴 하나, 마이그레이션 규약 자체에 소스 페이지 처분(빈 페이지 remove 또는 명시 보존 사유)을 1줄 명기하면 집행 모호성이 0 이 된다. 부수: 페이지 이동은 per-entry 트랜잭션(commitUndo/triggerUndo) 바깥의 선행 단계이므로 마이그레이션 자체의 실패 시 복구 semantics 를 breakdown 에서 확인할 것(NFR-F 의 1회성 목록 + key 검증 로그가 최소 안전망은 제공).

---

## 최종 판정

**PASS** — Stage 1 10/10 · Stage 2 (ambiguity 0.07 ≤ 0.2, unresolved Critical 0, Simplifier 미결 0) · Stage 3 3/3 APPROVE (single-model panel).

### 후속 권고 (비차단 — Planning/breakdown 에서 처리)

1. **[Architect/Stage1]** PAGE_MIGRATIONS 규약에 비워진 `🧩 Components` 소스 페이지 처분 1줄 명기 + 마이그레이션 단계 실패 복구 semantics 확인.
2. **[Analyst]** §5 표본 게이트의 "description(한국어)" 문구를 FR-1 우선순위 규칙(한국어 우선·영어 fallback)과 정합하게 조정, 또는 registry 101 ↔ content md 139 대응을 grep 으로 확정.
3. **[PM]** NFR-E "예산 재협상" 의 상한/분할 기준을 Planning 에서 결정 (§6 항목에 이미 포함 — 구체화만 필요).
4. **[Exporter 구현 시]** state 축 판별 술어("`Core{Component}State` 류")를 variant 축과 동급의 기계 규칙 1개로 확정.
