# Design Review: style-chain-showcase

- 일자: 2026-08-07 · 대상: architecture/ux-spec/flow-permutation v1 → **v2 개정의 근거 기록**
- 구성: §1 Architect 리뷰 요지 → §2 UX Designer 리뷰 요지 → §3 v2 해소 매핑 → §4 재검증 및 Solutioning Gate

## 1. Architect 리뷰 (v1 대상, 요지)

### Blocking
- **[A-B1] 의존 역전**: `WebPreview` 는 docs_core 소속(`docs_core/lib/components/web_preview.dart`)인데 v1 모듈표는 docs_site 의 스토어를 구독하게 배선 — docs_core→docs_site import 는 컴파일 불가 방향 (docs_core pubspec 에 docs_site 없음).
- **[A-B2] 기각 근거 거짓**: v1 대안표의 "공유 스토어 단독 ❌ — 임베드와 Dart 힙 공유 불보장" 은 실측과 모순 — 전 아일랜드가 단일 클라이언트 번들(`main.client.options.dart` 단일 clients 맵, deferred = 같은 dart2js 프로그램)이고 임베드 위젯 `PreviewApp` 은 아일랜드 build 에서 직접 생성(`flutter_preview.dart:52`). spike-3592 §5 자기 인용과도 모순.
- **[A-B3] attribute 유실**: 임베드 컨테이너는 로딩 시 fallback→flutter 컴포넌트 교체로 DOM 재생성(jaspr_flutter_embed `flutter_embed_view_web.dart` 실측) — 명령형 attribute 는 유실. v1 실패 모드 표("attribute 는 남아 있음") 불성립.
- **[A-B4] substitute 계약 모순**: "정확히 1개 리터럴" 전제가 REQ-A1 (a)(b)(c)의 축당 ≥2 출현과 충돌 + 어휘 접두 충돌 실측(radius4/40·radius2/20/24/28·radius6/64·surface/surfaceContainer)으로 부분문자열 치환 오염.
- **[A-B5] 서버 빌드 함정**: T1 판정을 widget-bearing Flutter chain registry 로 하면 SSG 서버 빌드에 dart:ui 유입 (barrel 4분리 근거와 동일 함정 — 현행 `docsComponentHasChainPreview` 가 string-only 레지스트리로 판정하는 이유).

### 판정된 성립 항목
- 컨테이너 id = 실제 DOM id (jaspr_flutter_embed 소스 확인), 폴링 확장 = 최소 변경, only-grow 는 paint-only 축이라 위험 낮음(관찰 항목 보강), 레지스트리 관례·eval 범위·packages 무변경 ✅.
- NB: id 파생식 3곳 → helper 추출 / 높이 근거 명문화 + `component/chain` 제약 키 옵션 / 스토어 SSR read-only 조항 / 코드 갱신 textContent 한정 / web chain registry typedef 명시.
- v1 Gate: clean_architecture FAIL · di_structure FAIL · api_design FAIL · security PASS.

## 2. UX Designer 리뷰 (v1 대상, 요지)

### Blocking
- **[U-B1] 라벨 행 CSS 미명세**: `.variant-gallery-label` 은 일반 블록 + `text-transform: capitalize`(`site_head.dart:613-621`) — flex 모디파이어와 칩 `text-transform:none`+monospace 미명세 시 칩이 `.Radius16.Primary` 로 왜곡.
- **[U-B2] "페이지당 chain 1개" 거짓**: 병합은 태그 단위 — 같은 컴포넌트 태그 복수 페이지 실재(date-picker ×4·time-picker ×4·tabs ×3·resizable ×3) → chain item 중복 + `flutter-{component}-chain`/code id 충돌로 채널 파손.
- **[U-B3] Copy 활성 탭**: 탭 전환 스크립트가 data-code 를 활성 패널 텍스트로 재설정(`main.server.dart:233-240`) — 셔플 갱신이 무조건 web 코드면 Flutter 탭 활성 시 G-1 재발.
- **[U-B4] 과도 창 파리티**: 클릭~반영 사이 표면 불일치가 REQ-B7/BDD 문면과 충돌 — settled 기준 판정 시점 미정의 시 CDP 오검출.

### 판정된 성립 항목
- 라벨 행 삽입 자체 가능, 'Shuffle' 영문 관행 일관, polite 선택·키보드·포커스(UA 기본) 정합, 스켈레톤 중 혼란은 방어 가능. coui_compliance PASS · accessibility PASS · layout FAIL · interaction FAIL.
- NB: 버튼 스타일은 갤러리-로컬 어휘(`preview-copy-btn` 계열) / SR 리전 분리+debounce / aria-label 은 대체임(visible text 로 충분) / wrap 정책 / focus = 억제 금지 구체화.

## 3. v2 해소 매핑

| 리뷰 | v2 반영 |
|---|---|
| A-B1 | 스토어를 `docs_core/lib/shared/chain_shuffle_store.dart` 로 — docs_core 내부 의존 (아키텍처 §2) |
| A-B2 + A-B3 | **채널 재설계**: 공유 스토어 직결 단일 채널 (DD-1 v2) — attribute·폴링 확장 폐기(폴백 후보로 강등, 폴백 시 SSG-stable 조상 요소). 지연 ~0, 로딩-스왑 유실 원천 소멸. PoC 관찰 1(힙 직결 실증) 유지 |
| A-B4 | §4 재작성 — T1 base 저작 규약(combo 체인 1개가 (a)(b)(c) 동시 충족 → 축당 출현 정확 1회) + identifier-boundary 매칭 + 출현≠1 fail-safe + AC-7 충돌쌍 의무 |
| A-B5 | 생성물 `chain_tier1.dart` name-set 이 server-safe T1 판정 단일 출처 — widget-bearing registry 는 클라이언트 경로 전용 + AC-11 에 서버 경로 import 금지 grep 추가 |
| A-NB1~5 | id helper 1곳·높이 근거+제약 키 옵션·스토어 SSR read-only·textContent 한정·(typedef 는 구현 시 §4 계약에) 반영 |
| U-B1 | UX §1 — `--chain` flex 모디파이어 + 칩 `text-transform:none`+monospace 명세 |
| U-B2 | panelId(파일-top-level 카운터) 인스턴스 유일 + `chain="off"` 큐레이션 — 아키텍처 §1·UX §1·flow E-6 |
| U-B3 | Copy 활성 탭 추종 — UX §4·flow I-4b |
| U-B4 | settled 기준 파리티 판정 — UX §2·flow I-1 (스토어 직결로 창 자체도 프레임 급으로 축소) |
| U-NB1~5 | 갤러리-로컬 버튼 어휘·SR 리전 분리+debounce·aria-label 제거(visible text)·wrap 정책·focus 억제 금지 반영 |

## 4. 재검증 및 Solutioning Gate (2026-08-07)

**재검증 결과: Blocking 9/9 Resolved** — 각 항목 v2 문면 인용 + 신규 모순 교차 검사 통과. 스펙 정합성 4건 판정:

1. aria-label 문면 충돌 (유일한 개정-필요 후보) → **해소안 (b) 채택** (D15): visible text 와 동일 문자열 aria-label — spec 무개정, UX v2 반영 완료.
2. REQ-B9 후보 서열 → supersession 기록 (D14) — LOCKED 개정 불요 (구속 4요소 보존).
3. BDD 파리티 절대 문면 → settled 한정자 반영 완료 (Feature B).
4. D9 vs `chain="off"` → 충돌 아님, 예외 선언 기록 (D13).

잔여 권고 8건 전부 반영: PoC 복수-패널 관찰(아키텍처 §3-4) · withStyle 토큰 상수 규약(§4) · tier1≡registry 가드(§6) · 페이지당 ≥1 불변식(§1) · D13/D14 기록 · 스토어 서버 리스너 no-op(§2) · flow v1 잔재 정리(I-7/F-1/F-3) · BDD settled 한정자.

### Solutioning Gate: **PASS (8/8)**

| Architect | 판정 | UX Designer | 판정 |
|---|---|---|---|
| clean_architecture | **pass** — 스토어 docs_core 이전으로 의존 방향 합법 + 서버/클라 경계 규칙 + tier1 name-set | coui_compliance | **pass** — site CSS chrome 선언 + 갤러리-로컬 어휘 (헤더 chrome 유출 0) |
| di_structure | **pass** — 단일 스토어 직결 수렴, 구독·폴백·SSR read-only 계약 명시 | layout | **pass** — `--chain` flex + 칩 `text-transform:none`/monospace + wrap 정책 |
| api_design | **pass** — substitute 계약 재작성 (정확 1회 + boundary + fail-safe + 충돌쌍), REQ-A1/B3 양립 확인 | interaction | **pass** — panelId/opt-out + Copy 활성 탭 추종 + settled 판정 |
| security | **pass** — 신규 입력/네트워크/eval 표면 0, 쓰기 클라이언트 한정 + AC-11 | accessibility | **pass** — polite 분리 리전 + debounce + UA focus 링, aria-label 충돌은 D15 로 해소 완료 |
