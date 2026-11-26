# Tech Spec: style-chain-showcase

- 일자: 2026-08-07 · 입력: LOCKED seed spec + D1~D12
- 경계: 본 문서는 **기술 요구·인터페이스 계약·검증 전략**까지만 — 채널 설계 확정·파일 배선도는 Design 단계(architecture doc) 몫. 여기의 API 스케치는 계약 수준 예시이지 최종 시그니처가 아니다.

## 1. 시스템 컨텍스트

```text
packages/coui_{flutter,web}   ← 슈거 체인 API 실체 (본 건에서 무변경이 원칙)
docs_core/
  lib/shared/                 ← 순수 Dart 단일 출처 (preview_variants.dart 기존 + 순열 모듈 신규)
  lib/previews/examples/…     ← *_chain_example.dart (확충 대상) + *_code.dart (동기)
  lib/previews/*registry.dart ← (component, variant) → widget/snippet
docs_site/
  lib/components/live_preview.dart · flutter_preview.dart   ← 프리뷰 표면 (랜덤 버튼 자리)
  lib/widgets/preview_app.dart                              ← Flutter 임베드 (channel 소비자)
```

원칙: `packages/` 는 손대지 않는다. getter 표면 부족(T2/T3)은 라이브러리 API 확장 = 별도 Epic (D3-rev) — 본 건은 docs 계층에서만 움직인다.

## 2. 기술 요구 (TR)

### TR-1. 순열 모듈 (REQ-B2/B3/B4, D11) — `docs_core/lib/shared/`

- 순수 Dart(jaspr/Flutter import 0 — AC-11 grep 게이트). 계약 스케치:
  - 축 정의: radius getter 19종·색 getter 11종의 **이름 목록 상수** (치환 어휘 = 이 30 이름이 유일한 출처).
  - `(int step, {required int seed}) → ({int radiusIndex, int colorIndex})` — 결정적 셔플. 같은 (seed, step) → 같은 좌표 (AC-6).
  - `substitute(String baseSnippet, permutation)` — base 스니펫의 양축 getter 리터럴(기본 순열, REQ-B3 앵커)을 현재 순열 이름으로 치환. 존재하지 않는 getter 이름 생성 불가 구조 (AC-7 — 어휘 상수 밖 문자열 조립 금지).
- 209-entry 자료구조 금지 — 두 축 독립 (19+11).

### TR-2. 티어 실측표 (REQ-A5, AC-2) — 생성 도구

- `*StyleChain` extension 의 getter 표면을 grep/파싱해 컴포넌트별 표를 생성: 티어(T1/T2/T3)·보유 getter·플랫폼별(Flutter↔Web)·서브컴포넌트별(ControlledStarRating 류)·chain 예제 존재 여부·제외 목록.
- 손 목록 금지 — 표는 소스에서 파생 (`tool/generate_style_tables.dart` 선례). Text 체인 동명 getter 오검출 제외 규칙 포함.
- 이 표가 티어 멤버십의 단일 출처 — 예제 확충 batch 분할과 AC-2/AC-7 테스트의 입력.

### TR-3. chain 예제 규약 (REQ-A1/A2/B8, D10)

- 문서용 `*_chain_example.dart`: 티어별 필수 요소(seed spec §2 표) + **얇은 클래스**(순열 dispatch 배관 0). T1 base 는 양축 getter 리터럴 각 ≥1 포함(치환 앵커). `_code.dart` 전문 동기 (verify 7-3).
- T1 순열 렌더러(별도 파일, 코드 패널 비노출): `(radiusIndex, colorIndex)` → 19-way + 11-way 독립 switch → getter 체이닝. 파일당 30분기 고정 — 기계적 저작이므로 **생성기 저작 여부는 Design 결정** (손저작 시에도 상한 유계).
- 예제 콘텐츠는 docs 룰 준수: Text 체인, 토큰 보간, 하드코딩 0 (`process/docs-site.md` self-grep).

### TR-4. transport 채널 (REQ-B9, D6-rev) — 요구만, 설계는 Design

채널이 만족해야 할 요구 (후보 비교 기준):

| 요구 | 기준 |
|---|---|
| per-panel 스코프 | 한 페이지 복수 패널 독립 (전역 attribute 금지 — 기존 theme/surface 채널과 구분) |
| 나르는 값 | `(radiusIndex, colorIndex)` 좌표 문자열뿐 — 임의 값 불가 구조 |
| 세 표면 도달 | Web 팬(아일랜드 state 재렌더)·Flutter 팬(embed 내 수신)·코드 패널(치환 표시) |
| 재마운트 금지 | embed id·제약 조회·스켈레톤 재로딩 비유발 (M-1 반증 사유 회피) |
| 선례 정합 | `surface_style_switcher.dart` attribute+observer 패턴 · `preview_app.dart` 폴링 확장 중 택일/조합 |

- **AC-10 PoC 가 이 채널의 존재 증명** — Epic 최선두, 실패 시 Part B 중단 (Part A 무영향).

### TR-5. 랜덤 버튼 + 코드 패널 갱신 (REQ-B1/B3/B5/B6)

- 버튼은 chain 갤러리 item 내부, `@client` 아일랜드 소속. dart2js 함정 회피 — 이벤트는 `EventHandlers` helper 경유 (`ui_events.dart`, dynamic dispatch 금지).
- 코드 패널: SSG 초기 상태 = 동기화된 base 스니펫 그대로. 클릭 시 클라이언트에서 치환 결과로 텍스트 교체 (양 탭). 순열별 pre-render 금지 (209개 DOM 낭비).
- a11y: `aria-label`(로컬라이즈 대상 아님 — docs 사이트 표면), 키보드 Enter/Space, 포커스 표시.

### TR-6. 노출 전환 (REQ-A4)

- `kDocsChainPreviewMode = hidden → appended` 한 줄 + `preview_variants` 테스트 갱신. 롤백 = 같은 한 줄 — 위험 최소.
- 전환 전제: Phase 1 예제 확충 완료 (빈약한 예제를 122곳에 노출하는 순서 역전 금지).

### TR-7. 성능·비기능

- SSG 빌드: chain 갤러리 추가로 페이지당 패널 +1 (Web pane SSG + Flutter embed lazy) — 기존 variant 갤러리와 동일 비용 구조, 신규 메커니즘 없음.
- 클릭 반응: 치환·재렌더는 클라이언트 로컬 연산 — 네트워크 0, 목표 즉시(<수십 ms). Flutter 팬 반영은 채널 지연(폴링 주기) 허용 — 기존 테마 토글과 동일 UX 급.
- 번들: 순열 모듈은 이름 상수 30개 + 셔플 함수 수준 — 무시 가능.

### TR-8. 테스트 전략 (AC 매핑)

| 층 | 내용 | AC |
|---|---|---|
| 순수 Dart unit | 셔플 결정성·치환 어휘 1:1·티어 판정 | AC-6, AC-7 |
| docs 테스트 | `resolveDocsPreviewVariants` appended 모드·registry 대응 | AC-1 |
| 동기화 검사 | `_code.dart` ≡ example (chain) | AC-3 |
| SSR curl | 대표 페이지 chain 갤러리 마크업 | AC-1 |
| CDP (release 빌드) | 세 표면 동시 갱신·computed style·키보드/aria | AC-5, AC-9 |
| 가드 grep | 순열 모듈 import 0·`@client` 경계 | AC-11 |
| 전역 게이트 | analyze/dcm 0·기존 스위트 회귀 0 | AC-8 |

### TR-9. 열린 질문 → Design 입력

1. 채널 방식 확정: per-panel attribute+MutationObserver vs 기존 200ms 폴링 확장 vs 혼합 (TR-4 기준표로 비교).
2. Flutter 팬 내 수신자: `PreviewApp` 확장 vs chain 전용 wrapper 위젯 — 순열 렌더러 호출 지점.
3. T1 순열 렌더러 저작: 손저작(39×2 파일) vs 생성기 (TR-2 도구 확장).
4. 랜덤 버튼 UI 위상: 갤러리 item 라벨 행 vs 패널 헤더 — UX 스펙에서 확정.
