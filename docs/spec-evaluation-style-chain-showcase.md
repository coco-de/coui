# Spec Evaluation: style-chain-showcase

- 일자: 2026-08-07
- 대상: `docs/seed-spec-style-chain-showcase.md` (v2)
- 구성: §1 Contrarian 리뷰(v1 대상) → §2 Simplifier 리뷰(v1 대상) → §3 v2 반영 매핑 → §4 3단 평가 결과(작성 중)

## 1. Contrarian 리뷰 (seed-spec v1 대상, 요지)

### Critical
- **[C-1] "getter 표면 uniform (radius 19 × 색 11 = 209, 전 컴포넌트)" 는 실측으로 거짓.** Flutter `*StyleChain` extension ~137개 중 getter 보유 파일 59개뿐. getter 0 (withStyle 만): checkbox(`checkbox.dart:156-162`)·menu·popover·dialog·drawer·toast·calendar·select 등 ≈60. radius 만: slider(`slider.dart:455-461`)·focus_outline·clickable·range 등 12파일. 색 만: dock(`dock.dart:191-256`)·hero_section·footer·navigation_bar·tabs 5파일. 양축 완전 보유 ~39 (chain 예제 119개의 약 1/3). getter 부재는 구조적인 경우 존재 — checkbox 의 radius 필드는 `boxBorderRadius` 라 "radius getter → `borderRadius` 필드" 규약 대상 필드 자체가 없음. getter 채우기는 docs 가 아니라 양 플랫폼 라이브러리 API 확장.
- **[C-2] REQ-A2(스니펫 ≡ 예제 전문) × REQ-B8(순열-인지 예제) × REQ-A1(d)(보일러플레이트 금지) 3자 모순.** getter 는 문자열 호출 불가(공통 supertype 없음) → 예제 내 dispatch 필요 → 그 배관이 동기화 룰에 의해 문서 코드 패널에 노출 → 보일러플레이트 금지와 충돌. 해소 방식 명문화 없이는 동시 만족 불가.

### Major
- **[M-1] "variant 문자열 채널 인코딩"(D6 v1) 반증.** 그 채널은 hydration-시점 고정(`flutter_preview.dart:48-53`, `web_preview.dart:12-24`, 코드 패널은 SSG `<pre>` 고정). 폴링 대상은 전역 `data-theme`+surface-style attribute 뿐(`preview_app.dart:40-54`) — variant 는 런타임 채널이 아님. 재마운트 인코딩 시 embed id·`component/variant` 제약 조회·`docsComponentHasChainPreview`·registry `case 'chain':` 매칭 연쇄 파손. 세 표면 모두 런타임 손잡이 부재 — per-panel attribute 채널 신규 배선 + PoC 하드 게이트 요구.
- **[M-2] 물량 Level 2 초과 소지** — Part B 를 양축 ~39 로 한정, REQ-A3 축소/분리 권고.
- **[M-3] AC-2/AC-7 전역 grep 은 오검출** (Text 동명 getter, avatar 서브컴포넌트 혼합 표면) — per-component 실측표 기반으로 재설계 요구.

### Minor
- [m-1] 제거 테스트: REQ-A3 만 "제거해도 원 요청 생존" — 나머지 REQ 는 하중 보유.
- [m-2] star_rating Flutter getter 22(ControlledStarRating 포함) vs Web 11 — 플랫폼·서브컴포넌트 단위 실측 필요.
- [m-3] 랜덤 버튼의 `_VariantGallery` 내 배치·panel-스코프 채널을 Design 입력으로 명시.

### 반증 실패 (스펙이 옳았던 것)
1. REQ-B2 값-타입 논거(순열 식별자는 enum 급 → spike-3592 봉쇄 비해당) — 성립.
2. D2 appended / A5 한 줄 전환 — `preview_variants.dart:21-40` 실재로 참.
3. chain 예제 119개 — glob 정확.
4. per-component 플랫폼 getter 대칭 — button 30↔30, dock 11↔11, slider 19↔19, avatar 41↔41 (총계 Flutter 1,518 ↔ Web 1,506, 차이는 m-2 + Text 잡음).
5. D8 (A/B 동일 Epic) — 성립.
6. "md 보일러플레이트가 거짓 예시" 공격 — 실패: 현행 md 는 컴파일 불가능 코드를 싣지 않음(`checkbox.md:107-138`).

## 2. Simplifier 리뷰 (seed-spec v1 대상, 요지)

- **[R-1] REQ-A3 삭제**: 139개 md 전부에 `<LivePreview>` 태그 기존재(grep 150 hits/139 files) — appended 전환만으로 chain 갤러리(Web 비주얼+Flutter 비주얼+코드 패널)가 md 무편집 자동 노출. md 산문은 어떤 룰도 동기화를 감시하지 않는 제3의 사본 (`tool/generate_style_tables.dart:10-15` 의 "hand-maintained copy is a second place to forget" 선례). AC-4 동반 폐기. 차선: 생성기 기반 주입.
- **[S-1] 축 분해 의무**: getter 이름이 (존재하는 곳에서) 전 컴포넌트 동일 → 순열은 `(radiusIndex, colorIndex)` 독립 2축 — 19-way + 11-way 합 30분기로 209 조합 전부 재현. 209-entry 테이블/switch 금지 명문화. 기존 `String Function(String? variant)` 시그니처와 호환.
- **[S-2] 구조적 게이트 티어링**: "Style 슬롯 보유" 자격만으로 4요소 균일 요구 불가 — Icon(`CoreIconStyle` 2필드, getter 0)·Breakpoint(0필드 "no visual chrome")·Hidden/Mask(2필드)·Gap(3필드) 실측. (a)(b)는 getter 보유 시에만, (d)는 `min(nullable 필드 수, 3)`, Part B 는 양축 보유만. 티어 판정은 grep 기계화(주관 큐레이션 금지).
- **유지 판정 [K-1~K-8]**: REQ-B7 파리티(핵심 가치)·B2 결정성·B4 단일 출처·B5 SSG·B6 a11y·A5 갭 조사·AC-8 전역 게이트·B1 3-표면 동시성 — 전부 현 수준 적정.

## 3. v2 반영 매핑

| 리뷰 항목 | v2 반영 |
|---|---|
| C-1 / S-2 | §2 티어 체계(T1/T2/T3 + 기계 판정) + REQ-A1 티어별 요소 + Part B = T1 한정 + R4 격상 + North Star 재기술 |
| C-2 | D10 역할 분리 — REQ-A1 예제 얇게 유지 / REQ-B8 별도 순열 렌더러 / REQ-B3 토큰 치환 파생 |
| M-1 | REQ-B9 신설 — 세 표면 배선 부재 명시, per-panel attribute 채널 1순위, AC-10 PoC 하드 게이트. D6-rev |
| M-2 / R-1 | REQ-A3·AC-4 삭제 (D9), Part B 대상 축소 |
| M-3 / m-2 | AC-2/AC-7 실측표 기반 재설계, 실측표에 플랫폼·서브컴포넌트 축 포함 (REQ-A5) |
| m-3 | REQ-B1 에 갤러리 item 내 배치·panel 스코프 명시 |
| S-1 | REQ-B8/B3 에 축 분해 의무 + 209-way 금지 (D11) |
| (d) ≥3 경직성 | D12 — `min(nullable 필드 수, 3)` |

## 4. 3단 평가 결과 (2026-08-07, v2 대상)

### Stage 1 — 기계적 검증: **10/10 PASS**

한 줄 목표·용어 완결·REQ 검증가능성·Scope Out·REQ↔AC 추적성·리스크 완화·결정↔로그 1:1·수치 실측 근거(withStyle 131 / chain 예제 119 / `<LivePreview>` 150 hits÷139 md — 전부 재검증 일치)·spike-3592 관계·후속 처리 — 전 항목 통과. (B4/B5 의 간접 추적은 Stage 2 감점 + 개선 권고 1로 처리.)

### Stage 2 — 의미 검증: **모호성 0.13 / 미해결 Critical 0**

| 차원 | 점수 | 잔여 근거 |
|---|---|---|
| 용어 | 0.10 | (d) "보일러플레이트 금지" 정성적 — min(nullable,3)+dispatch-0 으로 실질 경계 존재 |
| 범위 경계 | 0.10 | 티어 멤버십 확정이 AC-2 실측표로 이연 (라벨링된 의도적 이연) |
| 검증 기준 | 0.20 | B4/B5 전용 AC 부재·AC-10 대표 선정 기준 미기재 (→ 개선 권고 1·2) |
| 책임 소재 | 0.10 | D10 3-역할 분리·게이트 위치 명문 |
| 의존 관계 | 0.15 | REQ-B3 치환 앵커 암묵 (→ 개선 권고 3) |

- Contrarian 해소: **C-1 Resolved** (티어 체계 + Part B=T1 + 코드 스팟체크로 재확인) · **C-2 Resolved** (역할 분리 — 모순 구조 소멸) · **M-1/M-2/M-3 Resolved**.
- Simplifier 반영: R-1·S-1·S-2 전부 Reflected (R-1 전제 사실 재검증 일치).

### Stage 3 — 합의 검증: **3/3 APPROVE** (single-model panel — 상관된 단일 모델 의견임을 명시)

- **Analyst**: 원 요청 3요소 전부 하중 보유 REQ 존재. REQ-A3 삭제 독립 판단 — "문서에 반영"의 가시 결과(md 페이지에서 chain 예시를 코드+비주얼로)는 appended 갤러리가 md **안에서** 달성, 산문보다 rot 없는 동기화 갤러리가 더 충실. APPROVE.
- **PM**: transport 최대 리스크가 최선두 PoC 하드 게이트로 전진 배치, 최악 케이스 바닥 = "Part A 단독 출하". T1 한정 + 티어 차등 + batch 병렬로 물량 유계. 렌더러 생성기 여부의 Design 이연은 정당한 단계 배치 — 워치 아이템. APPROVE.
- **Architect**: D10 은 docs-site 동기화 룰 약화 없는 해소(룰 대상=저작물 유지, 파생은 경계 밖 명문화), D11 은 토큰-정확 getter 규약이 축 독립성을 보증, REQ-B9/AC-10 은 theme-axis-composition "같은 손잡이" 원칙의 정확한 구현. 순열 렌더러 divergence 우려는 public getter 합성뿐이라 기각. APPROVE.

### Gate 판정: **PASS**

| 기준 | 요구 | 실측 |
|---|---|---|
| 모호성 점수 | ≤ 0.2 | **0.13** |
| 미해결 Critical | 0 | **0** |
| 합의 | 3/3 | **3/3** |

### 비차단 개선 권고 3건 — **전부 반영 완료 후 LOCKED 승격**

1. AC-11 신설 (B4/B5 직접 게이트 — import grep + `@client` 경계) ✅
2. AC-10 대표 컴포넌트 선정 기준 명시 (T1 중 variant 갤러리+chain 공존, button 급) ✅
3. REQ-B3 치환 앵커 명시 (base 스니펫 양축 리터럴 각 ≥1 = 기본 순열) ✅
