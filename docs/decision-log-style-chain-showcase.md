# Decision Log: style-chain-showcase

- 일자: 2026-08-07 (Specification 단계)
- D1 만 사용자 명시 결정, 나머지는 근거 기반 기본값 — 게이트에서 검토·번복 가능.

| # | 결정 | 근거 | 대안과 기각 이유 |
|---|---|---|---|
| D1 | **예시 범위 = 계열 대표 + full-control** (radius·색 getter 계열 대표 + `withStyle(CoreXxxStyle(...))` 주요 필드 조합) | 사용자 선택 (2026-08-07 게이트). 가독성 유지 + 전 표면의 존재 시연. 나머지 조합은 랜덤 토글이 담당 | getter 30개 전수 나열(문서 비대·동기화 부담), 39필드 전수(비가독) — 기각 |
| D2 | **chain 노출 모드 = `appended`** | `preview_variants.dart` 설계 의도 그대로 — 선언 variant 갤러리 보존 + 끝에 chain 덧붙임. 한 줄 변경으로 122개 컴포넌트 일괄 | `only`: md 선언 갤러리 치환 → 기존 variant 문서 가치 파괴. md 별 `variants="…,chain"` 손편집: 118개 파일 재편집 — 기각 |
| D3 | **랜덤 순열 v1 축 = uniform getter 표면 (radius 19 × 색 11)** | 전 컴포넌트 × 양 플랫폼에서 이름·의미 동일(토큰-정확 getter 규약) → per-component 저작 0, 파리티 구조 보장. 사용자 원문 "옵션별 토큰 변경"과 정합 | full-control 필드 축: 컴포넌트마다 필드 상이·순열 폭발·per-component 저작 필요 → 후속 분리. 임의 값: spike-3592 봉쇄 — 기각 |
| D4 | **랜덤 = 결정적 seed 셔플** (클릭 시퀀스 재현 가능) | "비주얼 테스트" 가치는 재현성 전제. 체감 랜덤 + 재현 가능 양립 | 진짜 난수: 버그 재현 불가 — 기각 |
| D5 | **v1 표면 = docs_site 만, 순열 로직은 순수 Dart 공유 위치** | Level 2 스코프 봉쇄. `preview_variants.dart` 선례 — 로직을 docs_core/shared 에 두면 docs_app 후속이 UI 만 얹으면 됨 | docs_app 동시: 네이티브 UI 작업 추가로 스코프 초과 — 후속 이슈로 분리 |
| D6 | **순열 식별자는 기존 variant 문자열 채널 인코딩이 1순위 후보** (Design 단계 확정) | `(component, variant)` 시그니처가 레지스트리·제약 조회·아일랜드 전 배선에 이미 관통 — 시그니처 무변경 경로. 나르는 것이 enum급 문자열이라 spike-3592 봉쇄 비해당 | 신규 채널(공유 notifier/postMessage 류): 선례 없는 인프라 — Design 에서 비교 후 필요시에만 |
| D7 | **비범위 유지: 임의 값 실시간 편집·URL 영속화·스크린샷 CI 회귀·docs_app UI·full-control 랜덤 축** | 스코프 봉쇄 + spike-3592 판정 존중. 각각 후속 이슈 후보로 breakdown 단계에서 등록 | — |
| D8 | **chain 예제 확충(A)과 랜덤 토글(B)은 한 Epic** — 순열 적용 주체가 컴포넌트-타입 코드(D10 렌더러)라 같은 영역을 만짐 | socratic Q3b/H5 — getter 는 컴포넌트 타입에 붙음. contrarian 반증-실패 항목 5 로 재확인 | 분리 Epic: 같은 파일 2회 스윕 + 충돌 — 기각 |

## v2 개정 (contrarian + simplifier 반영, 2026-08-07)

| # | 결정 | 근거 | 대안과 기각 이유 |
|---|---|---|---|
| D3-rev | **"전역 uniform 축(209)" 폐기 → per-component 축 + 기계 티어링** (T1 양축 ~39 / T2 단축 ~17 / T3 무축 ~60, 확정은 실측표). Part B v1 = T1 만 | contrarian C-1 실측 — getter 표면은 이름은 동일하나 보유는 비균일 (checkbox=0, slider=radius만, dock=색만). 티어 판정은 `*StyleChain` getter grep 으로 기계화 (simplifier S-2) | 전 컴포넌트에 getter 채워넣기: docs 작업이 아니라 양 플랫폼 라이브러리 API 확장 — 별도 Epic 후보로 분리. 주관적 "핵심 N개" 큐레이션: rot — 기각 |
| D6-rev | **variant 문자열 인코딩 후보 기각 → per-panel attribute + observer/폴링 채널** (surface-style 패턴)이 1순위. transport PoC = 하드 게이트 (AC-10, 실패 시 Part B 중단) | contrarian M-1 — variant 채널은 hydration 고정이며 재마운트 인코딩은 embed id·제약 조회·registry 매칭 연쇄 파손. 세 표면(Web 팬·Flutter 팬·코드 패널) 모두 런타임 손잡이 부재 실측 | variant 재마운트: 스켈레톤 재로딩 + `component/variant` 제약 미스 + `docsComponentHasChainPreview` fall-through — 기각 |
| D9 | **REQ-A3 (md 120개 산문 손저작 교체) 삭제** — md 무편집. 후속 후보: 생성기 기반 주입 (`tool/generate_style_tables.dart` 선례) | simplifier R-1 — 139개 md 전부에 `<LivePreview>` 태그 기존재, appended 전환만으로 chain 갤러리(코드+비주얼) 자동 노출. md 산문은 어떤 룰도 동기화를 감시하지 않는 제3의 사본. 현행 보일러플레이트는 거짓 아님(검증) | 120개 손저작: 창작 비용 + 사본 drift. contrarian m-1 제거 테스트에서도 "제거해도 원 요청 생존" 판정 |
| D10 | **C-2 모순 해소 = 역할 분리 + 토큰 치환**: ① 문서용 chain 예제 = 얇은 리터럴 체인 (dispatch 배관 0, `_code.dart` 전문 동기 유지) ② 순열 적용 = 별도 per-component 렌더러 (T1 한정, 코드 패널 비노출) ③ 코드 패널 순열 표시 = base 스니펫의 getter-토큰 치환 파생 (저작 아님) | contrarian C-2 — 동기화 룰 × 순열-인지 × 보일러플레이트 금지 3자 모순은 한 파일이 세 역할을 겸할 때만 발생. 역할을 쪼개면 각 룰이 자기 대상에만 적용됨 | (a) 동기화 룰 예외 개정: 룰 약화 — 차선. 예제 안 dispatch: 문서 코드 오염 — 기각 |
| D11 | **축 분해 dispatch 의무** — 순열 적용·코드 치환 모두 radius 19-way + 색 11-way 독립 매핑 후 합성 (합 30분기). 209-way 단일 테이블/switch 금지 | simplifier S-1 — getter 이름이 (존재하는 곳에서) 전역 동일하므로 두 축은 독립. 컴포넌트당 분기 209→30 | 209-entry 저작: 7배 비용 + AC-7 대조 불가능 수준 — 기각 |
| D12 | **(d) full-control 필드 요구 = `min(nullable 필드 수, 3)`** | simplifier S-2 — `CoreGapStyle` 3필드 류에서 "≥3 고정" 은 여유 0 또는 불가능 | ≥3 고정: T3 소형 Style 에서 구조적 실패 — 기각 |

## Design 단계 개정 (Architect·UX 리뷰 + 재검증 반영, 2026-08-07)

| # | 결정 | 근거 | 대안과 기각 이유 |
|---|---|---|---|
| D13 | **D9 예외 — `chain="off"` 태그 속성** (노출 플래그, 대상 4~5개 복수-태그 md, 페이지당 chain ≥1 불변식) | UX 리뷰 B-2 — 태그 단위 병합이라 date-picker ×4 류 페이지에서 chain 중복. D9 가 금지한 건 산문 손저작(제3의 사본)이지 노출 플래그가 아님 | 페이지-스코프 자동 dedup: SSG 렌더 컨텍스트에 페이지 상태 없음 — 전역 mutable 위험. 방치: 4개 chain item 노이즈 — 기각 |
| D14 | **REQ-B9 후보 서열 supersession** — "per-panel attribute+폴링 1순위" 는 Architect B-2/B-3 실측(임베드 동일 힙 + 로딩-스왑 attribute 유실)으로 역전. **채택 = 공유 스토어 직결**, attribute+폴링 = 폴백. REQ-B9 의 구속 4요소(신규 배선 인정·per-panel·재마운트 금지·PoC 하드 게이트)는 전부 보존 — LOCKED 개정 불요 (재검증 판정) | `flutter_preview.dart:52` PreviewApp 직접 생성 + `main.client.options.dart` 단일 clients 맵 + jaspr_flutter_embed 로딩 스왑 DOM 재생성 실측 | attribute 채널 고수: 유실 버그 + 200ms 지연 + 신규 eval — 열세 확정 |
| D15 | **aria-label 충돌 해소 = UX 순응(해소안 b)** — 버튼에 visible text 와 **동일 문자열** aria-label 부여. LOCKED spec REQ-B6/AC-9/BDD 문면 무개정 | 재검증 스펙 정합성 §1 — 동일 문자열이면 accessible name 대체 부작용 0, 재-lock 사이클 회피 | (a) spec 개정("명시적 accessible name"으로 일반화): a11y 순수주의로는 우월하나 LOCKED 재평가 비용 > 이득 — 기각 |
