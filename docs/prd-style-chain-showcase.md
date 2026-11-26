# PRD: style-chain-showcase

- 일자: 2026-08-07 · 레벨: 2 · 내부 DX 기능 (docs_site)
- **요구사항 단일 출처는 LOCKED seed spec** (`docs/seed-spec-style-chain-showcase.md`) — 본 PRD 는 REQ/AC 를 복제하지 않고 참조하며, PRD 고유 내용(스토리·우선순위·릴리스 단계)만 담는다.
- 결정 근거: `docs/decision-log-style-chain-showcase.md` (D1~D12)

## 1. 배경 (원 요청)

> "문서에 컴포넌트별 스타일 슈거 체인 예시가 너무 부족해서 스타일 옵션을 모두 사용한 슈거 체인을 반영해주고, 추가로 랜덤 버튼을 통해 옵션별 토큰 변경을 랜덤 토글 반영해서 다양한 적용 예시를 사용자들이 적절하게 코드와 비주얼을 동시에 확인할 수 있음 좋겠어. 비주얼 테스트도 되니 매우 좋을 것 같아."

실측(discovery): API 는 완비(withStyle 131 파일 + getter 표면), 문서는 얕음(md 120개 보일러플레이트 1문단), chain 프리뷰 인프라는 존재하나 `hidden` 으로 꺼져 있고 예제 내용은 최소.

## 2. 목표 / 비목표

- 목표·범위: seed spec §1(한 줄 목표) · §3(REQ-A1~A5, REQ-B1~B9) · §4(비범위 7항) 참조.
- 성공 지표: seed spec §7 — 티어 충족률 100% + T1 랜덤 토글 동작률 100% (파리티 위반 0).

## 3. 사용자 스토리

| # | 페르소나 | 스토리 | 대응 REQ |
|---|---|---|---|
| US-1 | CoUI 소비 개발자 | 컴포넌트 문서를 열면 chain 갤러리에서 슈거 체인의 실재 표면(getter 계열 + withStyle full-control)을 코드·비주얼로 즉시 본다 | A1, A4 |
| US-2 | CoUI 소비 개발자 | chain 코드 패널의 코드를 복사하면 그대로 컴파일되는 실제 API 다 | A2 |
| US-3 | 디자이너/리뷰어 | 랜덤 버튼을 눌러 토큰 조합을 탐색하고, Web·Flutter 가 같은 조합을 나란히 렌더하는 것을 확인한다 | B1, B7 |
| US-4 | CoUI 메인테이너 | 랜덤 순열로 스타일 필드가 실제 렌더에 반영되는지(양 플랫폼 파리티 포함) 시각 검증한다 — 재현 가능한 시퀀스로 | B2, B7 |
| US-5 | AI 에이전트 | 레지스트리의 chain 예제·스니펫이 풍부해져 체인 API 를 올바르게 생성한다 (md 주입은 후속 — D9) | A1, A2 |
| US-6 | 접근성 사용자 | 랜덤 버튼을 키보드만으로 조작한다 | B6 |

## 4. 우선순위 (MoSCoW)

| 순위 | 항목 |
|---|---|
| **Must** | REQ-A1(티어별 예제 확충) · A2(동기화) · A4(appended 전환) · A5(실측표+갭 보충) · B9/AC-10(transport PoC 게이트) |
| **Must (PoC 통과 조건부)** | B1~B3, B7, B8 (T1 랜덤 토글 본체) |
| **Should** | B4(공유 위치) · B5(SSG) · B6(a11y) — 구현 시 필수 준수이나 별도 작업 단위로는 소형 |
| **Won't (v1)** | seed spec §4 비범위 전부 — 임의 값 편집·T2/T3 토글·full-control 랜덤·md 산문 생성기·docs_app UI·영속화·CI 스크린샷 |

## 5. 릴리스 단계 (의존 구조가 곧 단계)

```text
Phase 0  실측표 + 티어 확정 (AC-2 기반 산출물)          ← 모든 후속의 입력
Phase 1  Part A: 예제 확충(티어 batch) + appended 전환   ← transport 와 독립, 단독 출하 가능
Phase G  transport PoC (AC-10 하드 게이트)               ← 실패 시 Part B 중단, Phase 1 은 그대로 출하
Phase 2  Part B: 순열 모듈 + 랜덤 버튼 + 세 표면 배선 (T1)
```

- 최악 케이스 바닥: "Phase 1 단독 출하" (PM 합의 판정 — spec-evaluation §4).
- Phase 1 내부 batch 는 카테고리 단위 병렬 (breakdown 단계에서 분할).

## 6. 의존·제약

- 기존 chain 인프라(`preview_variants.dart`)·LivePreview·레지스트리 4분리 구조를 그대로 사용 — 신규 아키텍처 없음.
- SSG(`jaspr mode: static`) + `@client` 아일랜드 제약 (seed spec REQ-B5).
- spike-3592 봉쇄 유지 — 임의 값 transport 는 만들지 않는다.
- 레포 룰: docs-site 동기화 의무 · verify 7-x 게이트 · DCM 0 · 커밋 전 사용자 확인.
