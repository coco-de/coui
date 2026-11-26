# Flow Permutation: style-chain-showcase

- 일자: 2026-08-07 · 방식: 사용자 도달 경로 × 패널 상태 × 실패 축 전수 나열 → 갭 판정 → BDD 보강 권고
- 대상: chain 갤러리 + 랜덤 토글 (Part B 는 T1 한정)

## 1. 도달 경로 (Entry)

| # | 경로 | 상태 | 판정 |
|---|---|---|---|
| E-1 | md 페이지 직접 로드 (SSG) → 갤러리에 chain item | base 순열 표시 (앵커 리터럴 = 코드·칩·팬 일치) | 커버 (AC-1, Feature C 앵커) |
| E-2 | 페이지 내 앵커 스크롤로 chain 도달 (Flutter embed lazy) | Web 팬·코드 즉시, Flutter 스켈레톤 → 로드 후 base | 커버 (기존 lazy 동작) |
| E-3 | 다크모드 상태로 진입 | base 순열 + dark 토큰 해석 | 커버 (좌표-테마 직교) |
| E-4 | T2/T3 컴포넌트 페이지 | chain item 에 버튼·칩 없음 | 커버 (BDD "T1 에만 노출") |
| E-5 | chain 스니펫 없는 컴포넌트 (`docsComponentHasChainPreview == false`) | chain item 자체 미노출 (기존 `resolveDocsPreviewVariants` 동작) | 커버 (기존 테스트) |
| E-6 | **같은 컴포넌트 태그 복수 페이지** (date-picker ×4·time-picker ×4·tabs ×3·resizable ×3 실측) | 태그당 chain item — 각각 고유 panelId 로 완전 독립 (id·상태·코드 충돌 0). 과한 페이지는 `chain="off"` 큐레이션 | **v2 반영** (UX 리뷰 B-2 — 아키텍처 §1 panelId + opt-out) |

## 2. 인터랙션 경로 (Happy + Edge)

| # | 경로 | 기대 | 판정 |
|---|---|---|---|
| I-1 | Shuffle 1회 클릭 | 세 표면 모두 즉시(스토어 직결) — 같은 좌표. **파리티 판정은 settled 기준** — AC-5 CDP 는 반영 완료 대기 후 샘플 (프레임 경계 순간 샘플 금지) | 커버 (AC-5, v2 — UX 리뷰 B-4) |
| I-2 | 연타 N회 | 마지막 좌표로 수렴, 중간 상태 잔상 없음, 재마운트 0 | 커버 (BDD 연속 5회) |
| I-3 | 클릭 → 코드 탭 전환 (Web↔Flutter) | 양 탭 모두 현재 순열 반영 상태 | 커버 (AC-5 "양 탭") |
| I-4 | 클릭 → Copy | **현재 순열 코드**가 복사됨 | **갭이었음 → G-1 로 해소** (data-code 동시 갱신을 아키텍처 ③ 에 편입) |
| I-4b | **Flutter 탭 활성 상태에서 셔플 → Copy** | 탭 전환 스크립트가 data-code 를 활성 패널 텍스트로 재설정(`main.server.dart:233-240`)하므로, 셔플 갱신은 **활성 탭 코드** 기록 — Copy = 보이는 코드 | **v2 반영** (UX 리뷰 B-3) |
| I-4c | Copy 'Copied!' 1.5s 상태 중 셔플 | 버튼 텍스트만 관여 — 무해 | 커버 (UX 리뷰 신규-2) |
| I-5 | 클릭 → 다크모드 토글 → 재확인 | 좌표 유지 + dark 재해석 (양 팬) | 커버 (Feature B 직교) |
| I-6 | 클릭 → surface 스타일 전환 | 좌표 유지 + 표면 스타일 재해석 | **BDD 보강 권고 R-1** (다크모드와 동형이나 명시 시나리오 없음) |
| I-7 | Flutter lazy 로딩 완료 전 클릭 | 스토어가 상태 보유 → 임베드 초기화 시 initState read 로 수렴 | 커버 (아키텍처 v2 §5, UX §2) |
| I-8 | 키보드만: Tab → Enter/Space | 포커스 링 + 전환 + 칩 polite 통보 | 커버 (AC-9) |
| I-9 | 시퀀스 209회 전진 (전 조합 순회) | 좌표 중복 없이 순회 후 반복 — base 복귀 | **BDD 보강 권고 R-2** (순회 완전성 unit 시나리오 명시) |
| I-10 | 같은 페이지 다른 variant 패널과 병행 조작 | chain 패널만 갱신 (per-panel 스코프) | 커버 (BDD per-panel 시나리오) |

## 3. 실패·경계 경로

| # | 경로 | 기대 | 판정 |
|---|---|---|---|
| F-1 | 좌표 범위 밖/스토어 미초기화 | base(step 0) 유지, throw 0 | 커버 (아키텍처 v2 §5) |
| F-2 | 코드 요소 id 미발견 (마크업 회귀) | 코드 갱신 skip, 프리뷰 정상 + debug 로그 | 커버 (아키텍처 §5) — **R-3**: 이 상태를 CDP 검증이 "파리티 위반"으로 오검출하지 않게 검증 스크립트에서 id 존재를 선행 assert |
| F-3 | 순열 렌더러 미등록인데 버튼 렌더 (실측표-registry 불일치) | 발생 불가 — 버튼 렌더 조건 = `kChainTier1Components`(생성기 단일 출처, server-safe) + **tier1 ≡ registry 키 unit 가드**가 생성물 간 drift 차단 | 커버 (아키텍처 v2 §2·§6 — 재검증 권고 3 반영) |
| F-4 | release(dart2js) 빌드에서 이벤트 dead | 발생 방지 — `EventHandlers` 경유 의무 + AC-5 를 release 빌드로 검증 | 커버 (TR-5, verify 7-24 관행) |
| F-5 | JS 비활성/클라이언트 번들 실패 | SSG base 상태 그대로 (버튼 무반응) — 문서 가치는 유지 (Part A 콘텐츠는 정적으로 완전) | 커버 (SSG-우선 설계의 자연 폴백) |
| F-6 | PoC 실패 | Part B 중단·재설계, Part A 출하 | 커버 (Feature E) |

## 4. 갭 처리 결과

| # | 내용 | 처리 |
|---|---|---|
| G-1 | Copy 가 base 코드를 복사 (I-4) | **설계 반영 완료** — data-code 동시 갱신(활성 탭 추종, I-4b), UX §4, BDD Feature B 시나리오 반영 |
| R-1 | surface 스타일 직교 시나리오 부재 (I-6) | **BDD Feature B 반영 완료** |
| R-2 | 209 순회 완전성 unit 명시 (I-9) | **BDD Feature C 반영 완료** |
| R-3 | F-2 상태의 CDP 오검출 방지 | 검증 스크립트 설계 노트 — breakdown 의 검증 스토리에 포함 (settled 판정 I-1 과 한 쌍) |
| (v2) | UX 리뷰 신규 경로 E-6·I-4b·I-4c + Architect B-3(로딩-스왑 attribute 유실) | E-6/I-4b/I-4c 본문 반영, B-3 는 채널을 스토어 직결로 바꿔 원천 소멸 (아키텍처 v2 §5) |
