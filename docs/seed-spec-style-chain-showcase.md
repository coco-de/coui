# Seed Spec: style-chain-showcase (v2)

- 상태: **LOCKED** (2026-08-07 — 3단 평가 게이트 PASS: 모호성 0.13 · 미해결 Critical 0 · 합의 3/3, 비차단 개선 3건 반영. 상세: `docs/spec-evaluation-style-chain-showcase.md`)
- 일자: 2026-08-07 · 레벨: 2 · 결정 근거: `docs/decision-log-style-chain-showcase.md` (D1~D12)
- 입력: `docs/discovery-style-chain-showcase.md`, `docs/socratic-discovery-style-chain-showcase.md`, contrarian/simplifier 리뷰 (`docs/spec-evaluation-style-chain-showcase.md` 에 수록)

## 1. 한 줄 목표

Style 슬롯 보유 전 컴포넌트에서 스타일 슈거 체인(`withStyle` + 토큰-정확 getter)의 실재 표면을 **티어별 충실도**로 예시·프리뷰에 노출하고, 양축 getter 보유 컴포넌트에는 랜덤 순열 토글 버튼을 얹어 코드와 비주얼(Web·Flutter 양 팬)을 동시에 갱신 — 조합 탐색과 파리티 비주얼 테스트를 겸하게 한다.

## 2. 용어와 티어 (contrarian C-1 반영 — "전역 uniform 축" 폐기)

| 용어 | 정의 |
|---|---|
| **슈거 체인** | `withStyle(CoreXxxStyle(...))` full-control 확장 + `.radius16`/`.primary` 류 토큰-정확 primitive getter (정본: `.claude/rules/cross-platform/api.md`) |
| **chain variant** | LivePreview 공유 변형 — `docs_core/lib/shared/preview_variants.dart` 단일 출처 |
| **축(axis)** | radius getter 계열(존재 시 19종) / 색 getter 계열(존재 시 11종). **getter 이름은 존재하는 곳에서 전 컴포넌트 동일**(이름=값 규약)하나, **보유 여부는 컴포넌트별로 다르다** (실측: 양축 ~39 · 단축 ~17 · getter 0 ~60 — 2026-08-07 grep 추정, 확정은 AC-2 실측표) |
| **순열(permutation)** | 그 컴포넌트가 보유한 축의 데카르트 곱 원소 1개 — 양축 보유 시 19×11=209 |
| **순열 식별자** | `(radiusIndex, colorIndex)` 두 독립 축 인덱스 — 임의 값이 아니라 토큰 이름 좌표 |

**티어 판정은 기계적** — `*StyleChain` extension 의 실제 getter 표면 grep 으로 자동 분류 (주관적 큐레이션 금지, simplifier S-2):

| 티어 | 판정 기준 | 예시 확충 (Part A) | 랜덤 토글 (Part B) |
|---|---|---|---|
| **T1 양축** | radius·색 getter 둘 다 보유 | 4요소 (a)(b)(c)(d) 전부 | **대상** |
| **T2 단축** | 한 축만 보유 (slider=radius만, dock=색만 류) | 보유 축의 (a) 또는 (b) + (c 는 보유 축 내 조합) + (d) | v1 비대상 (후속) |
| **T3 무축** | getter 0, `withStyle` 만 (checkbox·menu·dialog 류) | (d) 만 | v1 비대상 |
| 대상 외 | Style 슬롯/`merge` 없음 (layout primitive) | 제외 — 제외 목록 산출 | 제외 |

## 3. 범위 (Scope In)

### Part A — chain 예시 확충 + 노출

- **REQ-A1**: Style 슬롯 보유 전 컴포넌트의 `*_chain_example.dart`(Flutter·Web 쌍)를 **자기 티어의 요소**로 확충한다:
  - (a) radius 계열 getter 대표 ≥1 — **보유 시에만**
  - (b) 색 계열 getter 대표 ≥1 — **보유 시에만**
  - (c) getter 조합 체인 ≥1 (T1: `.radius9999.success` 형 / T2: 보유 축 내) — **getter ≥2 보유 시에만**
  - (d) `withStyle(CoreXxxStyle(...))` full-control — 그 컴포넌트 고유 Style 필드 **≥ min(nullable 필드 수, 3)** 사용 (simplifier S-2 — `CoreGapStyle` 3필드 류 대응), 보일러플레이트 금지
  - 예제 클래스는 **문서용으로 얇게 유지** — 순열 dispatch 배관을 넣지 않는다 (D10, C-2 해소). Flutter·Web 동일 문자열·동일 토큰 (시각 파리티).
- **REQ-A2**: 각 `_code.dart` 의 `'chain'` 스니펫 ≡ 대응 `_chain_example.dart` 클래스 전문 (`process/docs-site.md` 동기화 의무 — **저작 스니펫에만 적용**, 런타임 파생 표시는 REQ-B3).
- **REQ-A4**: `kDocsChainPreviewMode` `hidden` → `appended` 전환 + 모드 회귀 테스트 갱신. (139개 md 전부에 `<LivePreview>` 태그가 이미 존재 — md 무편집으로 chain 갤러리 자동 노출, simplifier R-1 실측.)
- **REQ-A5**: "Style 슬롯 보유(withStyle 131) vs chain 예제 존재(119)" 갭 전수 조사 → 신규 작성. 산출물: **컴포넌트별 축 실측표**(티어·getter 표면·서브컴포넌트·플랫폼별 — star_rating 의 Flutter `ControlledStarRating` 대 Web 표면 차 같은 케이스 포함) + 제외 목록.
- ~~REQ-A3 (md 120개 산문 교체)~~ — **삭제** (D9/R-1): appended 갤러리가 코드+비주얼을 md 페이지 안에서 제공, md 산문 손저작은 어떤 룰도 감시하지 않는 제3의 사본. 현행 보일러플레이트는 거짓이 아님(검증됨 — getter 없는 컴포넌트 md 는 withStyle 만 정직하게 시연). 후속 후보: `tool/generate_style_tables.dart` 선례의 생성기 기반 md 주입.

### Part B — 랜덤 순열 토글 (T1 한정)

- **REQ-B1**: chain 프리뷰 패널(appended 시 variant 갤러리의 chain item — 버튼은 그 item 내부, 채널은 panel 스코프)에 랜덤 버튼 추가. 클릭 1회 = 다음 순열 — **Web 팬 · Flutter 팬 · 코드 패널(양 탭) 세 표면이 같은 순열을 동시에** 반영.
- **REQ-B2**: 순열 시퀀스는 보유 축 곱에서 **결정적 seed 셔플**. 임의 런타임 값 생성 금지 — 나르는 것은 `(radiusIndex, colorIndex)` 토큰 좌표뿐 (spike-3592 봉쇄 비해당: 값 타입이 기존 채널의 enum 문자열과 동급 — contrarian 반증-실패 항목 1).
- **REQ-B3**: 코드 패널의 순열 반영은 **동기화된 base 스니펫 위 getter-토큰 치환**으로 파생한다 — base 에 리터럴로 존재하는 기본 순열 getter 이름(치환 어휘 = 실재 getter 30종)을 현재 순열 이름으로 교체. 순열별 스니펫 저작 금지, 209-entry 테이블 금지. **치환 앵커**: T1 의 base 스니펫은 양축 getter 리터럴을 각 1개 이상 포함해야 하며(REQ-A1(a)(b)가 보장), 그 리터럴이 곧 기본 순열이다.
- **REQ-B4**: 순열 축 정의·seed 셔플·코드 치환 로직은 **순수 Dart 단일 출처**(`docs_core/lib/shared/`) — jaspr/Flutter 무의존, docs_app 공유 가능 (`preview_variants.dart` 선례).
- **REQ-B5**: SSG 제약 준수 — 인터랙션은 `@client` 아일랜드 안에서만 (`surface_style_switcher.dart` 선례).
- **REQ-B6**: 랜덤 버튼 접근성 — `aria-label`, 키보드(Enter/Space), 포커스 표시.
- **REQ-B7**: **파리티 하드 요구** — 같은 순열이 두 팬에서 같은 토큰으로 렌더. 한쪽만 갱신되는 상태 수용 불가.
- **REQ-B8** (D10 — 역할 분리): 순열 적용은 문서용 chain 예제 클래스가 아니라 **per-component 순열 렌더러**(T1 한정, 랜덤 토글 전용, 코드 패널 비노출)가 담당한다. 렌더러의 dispatch 는 **축 분해 필수** — radius 19-way + 색 11-way 독립 매핑 후 체이닝 (합 30분기, 209-way 단일 switch 금지 — simplifier S-1). 렌더러 저작을 생성기로 할지는 Design 결정.
- **REQ-B9** (M-1 — transport): 세 표면(Web 팬·Flutter 팬·코드 패널) **모두** 런타임 손잡이가 현재 없다 — 신규 배선이다. 1순위 후보는 surface-style 패턴을 따르는 **per-panel attribute + observer/폴링 채널** (variant 문자열 재마운트 인코딩은 contrarian M-1 로 반증 — embed id·제약 조회·registry 매칭 연쇄 파손). **transport PoC 스토리는 하드 게이트** — 실패 시 Part B 중단·재설계, Part A 는 독립 진행.

## 4. 비범위 (Scope Out — 명시적)

| 항목 | 이유 | 처리 |
|---|---|---|
| 임의 값 실시간 편집 (슬라이더/컬러피커) | spike-3592 착수 보류 판정 유지 | 봉쇄 유지 |
| T2/T3 컴포넌트 랜덤 토글 | 축 부재/부분 — getter 표면 균일화는 라이브러리 API 확장(양 플랫폼)이지 docs 작업이 아님 (C-1) | 후속: "getter 표면 균일화" 별도 Epic 후보 |
| full-control 필드 랜덤 축 | 컴포넌트별 필드 상이·순열 폭발 | 후속 이슈 후보 |
| md 산문 컴포넌트별 손저작 (구 REQ-A3) | R-1 — 제3의 사본, 갤러리가 대체 | 후속: 생성기 기반 주입 후보 |
| docs_app(네이티브) 랜덤 버튼 UI | 스코프 봉쇄 — 로직은 공유 위치(REQ-B4) | 후속 이슈 후보 |
| URL/localStorage 순열 영속화, 순열 스크린샷 CI 회귀 | v1 불필요 / 별도 인프라 크기 | 후속 이슈 후보 |
| Style 슬롯 없는 layout primitive | withStyle 비대상 (룰 정본) | 제외 목록 산출 (REQ-A5) |

## 5. 수용 기준 (테스트 가능 — M-3 반영: 전역 grep 아닌 실측표 기반)

| # | 기준 | 검증 방법 |
|---|---|---|
| AC-1 | Style 슬롯 보유 전 컴포넌트 문서에서 chain 프리뷰 노출 (appended — 선언 variant 뒤) | `resolveDocsPreviewVariants` 단위 테스트 + 대표 페이지 SSR curl |
| AC-2 | **컴포넌트별 축 실측표** 산출 + 각 chain 예제가 자기 티어 요소 100% 충족 | 실측표 기반 per-component 검사 (Text 체인 등 동명 getter 오검출 제외 규칙 포함) |
| AC-3 | `_code.dart` chain 스니펫 ≡ example 클래스 전문 (저작 스니펫) | verify 7-3 동기화 검사 |
| AC-5 | T1 컴포넌트에서 랜덤 클릭 시 Web 팬·Flutter 팬·코드 패널이 같은 순열 반영 | CDP computed style + 코드 패널 텍스트 대조 (release 빌드, dart2js 함정 노출) |
| AC-6 | 같은 seed·같은 클릭 횟수 → 같은 순열 시퀀스 | 순수 Dart 단위 테스트 |
| AC-7 | 치환 어휘·축 매핑이 실측표의 실제 getter 이름과 1:1 (존재하지 않는 getter 생성 0) — 플랫폼·서브컴포넌트 단위 | 실측표 대조 단위 테스트 (30 이름 목록) |
| AC-8 | `dart analyze` + `dcm analyze` 0 (변경 라인), 기존 프리뷰·테스트 회귀 0 | verify 7-1/7-2 + docs 테스트 스위트 |
| AC-9 | 랜덤 버튼 키보드 조작 + aria-label | CDP/DOM 검사 |
| AC-10 | transport PoC: per-panel 채널로 T1 대표 1개 컴포넌트의 세 표면 동시 갱신 시연. **대표 선정 기준**: T1 중 variant 갤러리와 chain 이 공존하는 컴포넌트(button 급 표면) — 갤러리 배치·panel 스코프 채널까지 일반화 가능해야 함 | Epic 최선두 스토리 — 실패 시 Part B 게이트 중단 |
| AC-11 | REQ-B4/B5 직접 게이트: `docs_core/lib/shared/` 순열 모듈의 import 그래프에 jaspr/Flutter 0 + 랜덤 토글 인터랙션 코드가 `@client` 아일랜드 밖 0 | import grep + 파일 위치 검사 |

(구 AC-4 "md 보일러플레이트 잔존 0" 은 REQ-A3 삭제와 함께 폐기.)

## 6. 리스크

| # | 리스크 | 영향 | 완화 |
|---|---|---|---|
| R1 | **세 표면 모두** 런타임 순열 전달 배선 부재 (M-1 실측 — Flutter 팬 hydration 고정, Web 팬 Stateless 1회, 코드 패널 SSG 고정) | Part B 전체 | AC-10 PoC 하드 게이트 최선두 + per-panel attribute 채널 후보. Part A 는 transport 와 독립 |
| R2 | 예제 확충 물량 (실측표 기준 ~131 컴포넌트 × 2 플랫폼 + code 동기) | 일정 | 티어별 요구 차등(T3 는 (d)만) + 카테고리 batch 병렬 Agent + 실측표 기계 검증 |
| R3 | 색 getter 대상 필드가 일부 컴포넌트에서 어색한 시각 | 낮음 | 대상 필드는 `.claude/rules/cross-platform/api.md` 의 "주 칠 필드" 원칙 하나로 정한다 — 대부분 `backgroundColor`, 채움이 트랙 위에 얹히는 부품은 채움 필드, `transparent` 는 어디서나 바탕. 그 원칙 아래에서도 남는 어색함은 필드 반영 여부를 드러내는 비주얼 테스트 신호로 허용 |
| R4 | 축 표면 비표준이 **다수** (C-1 실측 확정: T2 ~17 + T3 ~60) + 플랫폼 간 서브컴포넌트 차 (star_rating) | 티어 오분류·파생 오류 | 실측표가 티어의 단일 출처 (AC-2) — 손 목록 금지, grep 파생 |

## 7. 성공 지표

- **North Star**: (i) Style 슬롯 보유 전 컴포넌트의 chain 예시 티어 충족률 100% + (ii) T1 컴포넌트 랜덤 토글 동작률 100% (파리티 위반 0).
- 보조: chain 프리뷰 노출률(hidden→appended 로 0%→100%), AC-5 세-표면 동시성 위반 0, 실측표 커버리지(withStyle 보유 131 전수).
