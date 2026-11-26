# Architecture: style-chain-showcase (v2)

- 일자: 2026-08-07 · v2 = Architect 리뷰 Blocking 1~5 + UX 리뷰 Blocking 2 반영 (리뷰 전문·해소 매핑: `docs/design-review-style-chain-showcase.md`)
- 입력: LOCKED seed spec + tech-spec TR-1~9 + BDD + flow-permutation
- AC-10 PoC 하드 게이트 유지 — 본 설계의 채널 전제(§3 PoC 관찰 항목)를 실증해야 Part B 착수.

## 0. 설계 결정 요약 (TR-9 → DD)

| # | 질문 | 결정 (v2) | 핵심 근거 |
|---|---|---|---|
| DD-1 | transport 채널 | **공유 Dart 스토어 직결 단일 채널** — 아일랜드(버튼·Web 팬)와 Flutter 임베드가 **같은 Dart 힙**에서 같은 `ChainShuffleStore` 를 구독. DOM attribute·폴링 확장 **불사용** | 전 아일랜드가 단일 클라이언트 번들(`main.client.options.dart` 단일 `ClientOptions.clients` 맵, deferred = 같은 dart2js 프로그램의 code-split). 임베드 위젯 `PreviewApp` 은 아일랜드 build 에서 **직접 생성**(`flutter_preview.dart:52`) — spike-3592 §5 "같은 JS 힙" 실측과 일치. attribute 안(v1)은 임베드 로딩 시 fallback→flutter 컴포넌트 교체로 DOM 재생성되어 attribute 유실(Architect B-3) — 구조적으로 열세 |
| DD-2 | Flutter 팬 수신자 | `PreviewApp` 이 chain variant 일 때 스토어 **직접 구독**(initState 리스너 → setState) + `_AutoSizePreview` build 분기 → chain 순열 렌더러. 기존 theme/surface 200ms 폴링은 **무변경** | 같은 힙이라 Dart 리스너 직결 가능 — 지연 ~0(다음 프레임). 재마운트 0, 기존 builder 경로 무접촉. 로딩 중 클릭은 initState 첫 read 로 수렴 (B-3 구조 해소) |
| DD-3 | 순열 렌더러 저작 | **생성기** — `tool/generate_chain_artifacts.dart` 가 실측표 + **server-safe T1 name-set** + 렌더러(T1×2플랫폼)를 생성·체크인 | 30분기×~39×2 기계 저작 (`generate_style_tables.dart` 선례). name-set 분리는 B-5 (서버 빌드 dart:ui 유입 차단) |
| DD-4 | 랜덤 버튼 UI 위상 | `ChainShuffleControl` `@client` 아일랜드 — chain 갤러리 item 라벨 행 (T1 판정 = server-safe name-set) | UX 스펙 §1-2. 배치 실현성은 UX 리뷰로 검증 (CSS 명세는 UX 스펙 소유) |

## 1. 시스템 배선도 (v2 — 스토어 직결)

```text
                [SSG 시점 — live_preview.dart]
  _VariantGallery (chain item, panelId = 파일-top-level 카운터로 인스턴스 유일)
    ├─ variant-gallery-label(chain 한정 flex) ─ 'chain' + 순열칩 + ⟨ChainShuffleControl panelId⟩
    └─ _LivePreviewPanel
        ├─ ⟨WebPreview … panelId⟩            ← chain 시 스토어 구독 (docs_core 내부 의존)
        ├─ ⟨FlutterPreview … panelId⟩ → PreviewApp(… panelId) ← chain 시 스토어 구독
        └─ preview-code — code#code-web-{panelId} · code#code-flutter-{panelId} · copy[data-code]

                [클라이언트 런타임 — 클릭 1회]
  ChainShuffleControl.onClick
    → chainShuffleStore.advance(panelId)              // docs_core/shared — 순수 Dart
        ├─① WebPreview 리스너 → setState → web 순열 렌더러
        ├─② PreviewApp 리스너 → setState → flutter 순열 렌더러   (같은 힙 직결 — 폴링 0)
        └─③ 버튼 아일랜드: substitute() 결과로
             code 두 요소 textContent 교체 + copy data-code 는 **활성 탭 코드** 로 교체
```

- **panelId** (UX B-2 해소): `chain-{component}-{n}` — SSG 파일-top-level 카운터로 인스턴스 유일 (Web overlay unique-id 선례). 같은 컴포넌트 `<LivePreview>` 태그가 복수인 페이지(date-picker ×4 등 실측)에서도 embed id·code id·스토어 키 충돌 0. 각 chain 패널은 독립 상태 (공유하면 다른 패널의 코드 표면만 미갱신되어 REQ-B7 위반).
- **큐레이션 opt-out**: 복수 태그 페이지의 chain 중복 노출은 태그 속성 `chain="off"` 로 저자가 끌 수 있다 (`LivePreview.create` 가 읽어 resolve 에 전달). D9 "md 무편집" 원칙의 예외적 큐레이션 — 대상 4~5개 md, 콘텐츠 저작이 아니라 노출 플래그 (D13). **불변식: 페이지당 chain ≥1** — 전 태그 off 는 AC-1 위반이므로 테스트로 강제 (재검증 권고 4).
- 좌표·테마 직교: 스토어는 좌표만 보유 — 다크모드/surface 전환 rebuild 에서 그대로 재해석.

## 2. 모듈 배치 (신규/변경)

| 파일 | 신규/변경 | 책임 |
|---|---|---|
| `docs_core/lib/shared/chain_permutations.dart` | 신규 | 축 이름 상수 30개 · `ChainPermutation` · seed 셔플 · `substituteChainTokens`(§4 계약). **순수 Dart** (AC-11) |
| `docs_core/lib/shared/chain_shuffle_store.dart` | 신규 | panelId→step + 리스너 (framework-free 자체 Listenable). **서버 경로 read-only** — 쓰기 API 는 클라이언트 전용 호출 계약 + **리스너 등록도 서버 경로 no-op 가드**(jaspr 는 SSG 중에도 initState 를 실행 — 빌드 중 리스너 누적 위생, 재검증 권고 6). AC-11 grep 이 클라이언트 전용 계약을 게이트화 |
| `docs_core/lib/shared/chain_tier1.dart` | 신규(생성물) | `kChainTier1Components: Set<String>` — **server-safe T1 판정 단일 출처** (B-5: widget-bearing registry 를 SSG 판정에 쓰면 서버 빌드에 dart:ui 유입) |
| `tool/generate_chain_artifacts.dart` | 신규 | 실측표(티어·getter·플랫폼·서브컴포넌트, Text 동명 제외) + tier1 set + T1 순열 렌더러 생성 `--write` |
| `docs_core/lib/previews/examples/{flutter,web}/{X}/{X}_chain_permutations.dart` | 신규(생성물, T1) | `(ChainPermutation) => Widget/Component` — 19+11 독립 switch. base 예제와 **동일 구조**(§4 저작 규약)라 첫 클릭 콘텐츠 점프 없음 |
| `docs_core/lib/previews/{flutter,web}_chain_registry.dart` | 신규 | T1 renderer 배선 — 각각 flutter/web **클라이언트 경로 전용** import (서버는 tier1 set 만) |
| `examples/**/*_chain_example.dart` + `*_code.dart` | 변경(전 티어) | REQ-A1 티어 요소 + §4 저작 규약 (T1: 축당 getter 정확 1회) + 동기화 |
| `docs_site/lib/components/chain_shuffle_control.dart` | 신규 | `@client` 버튼 — advance + ③ 코드/copy 갱신 (textContent/DOM API 만 — innerHTML·신규 eval 0). `EventHandlers` 경유 |
| `docs_core/lib/components/web_preview.dart` | 변경 | chain+T1 시 스토어 구독 (docs_core→docs_core 내부 의존 — **B-1 해소**: 스토어가 docs_core 소속이라 의존 역전 없음) |
| `docs_site/lib/components/flutter_preview.dart` · `docs_site/lib/widgets/preview_app.dart` | 변경 | `panelId` 전달(optional) + chain 시 스토어 구독·렌더러 분기. embed id 는 panelId 파생 — **id 파생식은 공유 helper 1곳** (NB-1: 현행 3곳 산재 해소) |
| `docs_site/lib/components/live_preview.dart` | 변경 | chain item: panelId 부여·라벨 행 확장·code 요소 id·버튼 렌더 조건 = `kChainTier1Components` |
| `docs_core/lib/shared/preview_variants.dart` | 변경 | `appended` 전환 (Phase 1 후) + `chain="off"` opt-out 파라미터 |

- `packages/coui_*` 무변경 원칙 유지.
- **서버/클라이언트 경계 규칙**: SSG(live_preview)가 읽는 chain 관련 심볼은 `chain_tier1.dart`·`chain_permutations.dart`(문자열/좌표)뿐 — widget-bearing chain registry 는 서버 경로 import 금지 (barrel 4분리 근거와 동일, AC-11 grep 에 이 방향도 포함).

## 3. DD-1 상세 — 대안 비교 (v2) 와 PoC

| 후보 | 판정 | 근거 |
|---|---|---|
| **공유 스토어 직결 (채택)** | ✅ | 단일 클라이언트 번들 실측(`main.client.options.dart` 단일 clients 맵) + 임베드 위젯 직접 생성(`flutter_preview.dart:52`) = 같은 Dart 힙. 지연 ~0, DOM 경유 0, 로딩-스왑 유실 문제 원천 부재 |
| variant 문자열 재마운트 | ❌ | embed id·제약 조회·registry 매칭 연쇄 파손 (contrarian M-1, D6-rev) |
| 임베드 컨테이너 attribute + 폴링 확장 (v1 안) | ❌ → **폴백 후보로 강등** | fallback→flutter 컴포넌트 교체 시 DOM 재생성으로 attribute 유실 (jaspr_flutter_embed `flutter_embed_view_web.dart` 실측 — Architect B-3). 폴백 시엔 기록 대상을 **SSG-stable 조상 요소**로 |
| 전역 document attribute | ❌ | per-panel 스코프 위반 |
| postMessage/iframe | ❌ | 임베드는 iframe 이 아님 (spike §5) |

**PoC(AC-10)가 실증할 것** (button 급 T1 1개, release 빌드):
1. 스토어 리스너가 아일랜드↔임베드 간 실제 발화 (dart2js deferred 경계 포함 — 설계의 단일 힙 전제 실증).
2. 재마운트/스켈레톤/제약 부작용 0 + only-grow 높이: 축이 paint-only(radius·색)이고 렌더러가 base 와 동일 구조라 **높이 변동 기대 ≈0** — 이 근거로 관찰하고, 어긋나면 `'{component}/chain'` per-variant 제약 키(기존 조회 경로 실재)로 고정 (NB-2).
3. 임베드 로딩 중 클릭 → 로드 후 수렴 (스토어 잔존 + initState read).
4. **복수 chain 패널 동시(per-panel 격리)** — PoC 페이지에 chain 패널 2개를 임시로 띄워 panelId 키 격리(한쪽 셔플이 다른 쪽 3표면에 무영향)를 실증 (재검증 권고 1).
5. **실패 시 폴백**: SSG-stable 조상 attribute + 폴링 확장으로 회귀 (그마저 실패 시 Part B 중단·재설계 — Feature E).

## 4. 데이터 계약 (v2 — Architect B-4 반영)

```dart
// docs_core/lib/shared/chain_permutations.dart
const kChainRadiusGetters = <String>[/* radius0 … radius9999 — 19, 정본 */];
const kChainColorGetters  = <String>[/* primary … transparent — 11, 정본 */];

class ChainPermutation { final int radiusIndex; final int colorIndex; }
ChainPermutation chainPermutationAt(int step, {int seed = kChainShuffleSeed}); // 결정적, 209 전 조합 순회
String substituteChainTokens(String baseSnippet, ChainPermutation p);
```

**T1 base 저작 규약 (치환 앵커의 유일성 확보)**:
- T1 base 예제는 **combo 체인 인스턴스 1개**(`.radius16.primary` 형 — REQ-A1 (a)(b)(c)를 한 체인이 동시 충족) + **withStyle full-control 인스턴스 1개**((d), getter 0 — 필드명이라 어휘 충돌 없음)로 구성한다.
- **combo 인스턴스의 콘텐츠(슬롯·문자열)는 그 컴포넌트 default 예제를 유지한 채 체인만 얹는다** — "chain 예제가 축소판이 되면 안 된다"는 기존 관례(과거 chain 예제 축소판 회귀를 재작성으로 바로잡은 이력이 레포에 있음)를 계승. 확충이 다시 축소판을 만들면 같은 회귀의 반복이다.
- 결과: **축당 getter 리터럴이 base 전체에서 정확히 1회** — 치환이 결정적. (seed spec REQ-B3 앵커 "각 ≥1" 의 설계-강화 — 스펙 호환.)
- **withStyle 인스턴스는 combo 앵커와 같은 이름의 토큰 상수 사용 금지** (재검증 권고 2) — 값-위치 상수(`CoreRadius.radius16` 류)는 getter 와 동명이라 `.{name}` 매칭에 걸릴 수 있다. 같은 토큰을 쓰면 출현=2 로 fail-safe 가 잡지만, 저작 규약으로 사전 차단한다.
- 순열 렌더러는 base 와 **같은 2-인스턴스 구조**에서 combo 인스턴스만 순열 적용 — 코드 치환 결과와 시각이 1:1, 첫 클릭 구조 점프 없음.

**치환 알고리즘 계약**:
- **identifier-boundary 매칭 필수** — `.{name}` 뒤에 식별자 문자가 이어지지 않는 위치만 (`radius4` 가 `radius40` 안에서 매칭되면 안 됨; `surface`/`surfaceContainer` 동일). 단순 부분문자열 치환 금지.
- 축당 출현 1회 전제 검사 — 출현 ≠ 1 이면 원문 반환(fail-safe) — 저작 규약 위반은 AC 테스트가 잡는다.
- **AC-7 테스트에 충돌쌍 의무 케이스**: (radius4↔radius40, radius2↔{20,24,28}, radius6↔64, surface↔surfaceContainer) — 어휘 상수 밖 문자열 생성 불가 구조.

## 5. 실패 모드와 폴백 (v2)

| 상황 | 동작 |
|---|---|
| 임베드 로딩 중 클릭 | 스토어가 상태 보유 — PreviewApp initState 첫 read 로 수렴 (DOM attribute 미사용이라 유실 없음) |
| 좌표 범위 밖/스토어 미초기화 | base(step 0 = 기본 순열) — throw 0 |
| base 저작 규약 위반 (축당 출현 ≠1) | substitute 원문 반환 + AC 테스트 실패로 저작 단계에서 차단 |
| chain registry 미등재(T2/T3) / tier1 set 밖 | 버튼·칩 SSG 미렌더 — 계약 그대로 |
| 코드 요소 id 미발견 | 코드 갱신 skip + debug 로그 — CDP 검증은 id 존재 선행 assert (flow R-3) |
| PoC 실패 | §3 폴백 → 그마저 실패 시 Part B 중단, Part A 무영향 |

## 6. 보안·성능·게이트 (v2)

- 신규 입력/네트워크 표면 0. **신규 eval 0** (v1 의 폴링 read 확장도 제거됨 — 코드 갱신은 textContent/DOM API). 스토어 쓰기는 클라이언트 아일랜드 한정.
- 성능: 클릭 → 세 표면 전부 같은 힙 내 리스너/DOM 쓰기 — 네트워크 0, Flutter 포함 다음 프레임 급. **파리티 판정은 settled 기준** (UX B-4 — CDP 는 반영 완료 후 샘플).
- 게이트 훅: AC-11(순수 Dart grep + `@client` 경계 + **서버 경로의 widget-bearing chain import 0**), AC-6/7(충돌쌍 포함) unit, AC-5/9 CDP release, AC-3 동기화, AC-8 전역, **tier1 set ≡ chain registry 키 동일성 unit** (생성물 간 drift 가드 — 재검증 권고 3), 페이지당 chain ≥1 불변식 테스트.

## 7. 구현 순서 (breakdown 입력, v2)

1. **S0** 생성기 골격 — 실측표 + `chain_tier1.dart` name-set → 티어 확정
2. **S1 (PoC, 하드 게이트)** button 급 1개 — 스토어 직결 채널(§3 관찰 1~3) 실증, 실패 시 폴백 검증까지
3. S2 순열 모듈 + 스토어 + unit (AC-6/7/11, 충돌쌍)
4. S3 chain 예제 확충 batch (티어별, §4 저작 규약) + `_code.dart` 동기 — S1 과 독립
5. S4 T1 순열 렌더러 생성 + chain registry 2종 배선
6. S5 `ChainShuffleControl` + WebPreview/PreviewApp 구독 + panelId/id helper + 코드·copy 갱신(활성 탭 추종) + a11y
7. S6 `appended` 전환 + `chain="off"` 큐레이션(4~5 md) + 회귀·SSR·CDP 검증 (verify 7-x)
