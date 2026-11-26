# Discovery: 스타일 슈거 체인 전수 예시 + 랜덤 토큰 토글 프리뷰 (style-chain-showcase)

- 일자: 2026-08-07
- 파이프라인: `.pipeline/style-chain-showcase.yaml` (Level 2)
- 성격: 내부 DX 기능 — "사용자"는 CoUI 소비 개발자·디자이너·AI 에이전트, "시장"은 경쟁 디자인 시스템 문서(기존 벤치마크 `docs/docs-benchmark-2026-08-01.md` 재사용). 본 문서는 실측(코드 라인 근거) 기반.

## 0. 요청 원문 분해

> "문서에 컴포넌트별 스타일 슈거 체인 예시가 너무 부족해서 스타일 옵션을 모두 사용한 슈거 체인을 반영해주고, 추가로 랜덤 버튼을 통해 옵션별 토큰 변경을 랜덤 토글 반영해서 다양한 적용 예시를 사용자들이 적절하게 코드와 비주얼을 동시에 확인할 수 있으면 좋겠어. 비주얼 테스트도 되니 매우 좋을 것 같아."

- **(A) 문서 확충**: 컴포넌트별 `withStyle` + 토큰-정확 primitive getter 체인 예시를 "스타일 옵션을 모두 사용한" 수준으로.
- **(B) 랜덤 토글 프리뷰**: LivePreview 에 랜덤 버튼 — 스타일 옵션별 토큰을 랜덤으로 갈아끼우고 **코드와 비주얼이 동시에** 갱신. 부수 가치로 **비주얼 테스트**(스타일 필드 전수 커버리지의 시각 확인).

## 1. 현재 상태 실측 (User Research 의 "문제 확인")

### 1-1. API 표면은 이미 풍부하다 — 문서만 얕다

| 축 | 실측 | 근거 |
|---|---|---|
| Flutter `withStyle` 보유 컴포넌트 파일 | **131개** | `grep -rln withStyle packages/coui_flutter/lib/src/components` |
| Web `withStyle` | 동일하게 광범위 (형태 대칭) | 동일 grep, coui_web |
| 컴포넌트당 primitive getter | **~30개** (radius 계열 19 + 색 계열 11) | `button.dart:595-788` (`radius0`~`radius9999`, `primary`~`transparent`) |
| `CoreButtonStyle` 필드 수 | **39개** (withStyle full-control 이 커버하는 표면) | `packages/coui_core/.../button/button_style.dart` |

### 1-2. 문서의 얕음 — 사용자 지적이 정량으로 확인됨

- 컴포넌트 md **139개 중 120개**가 `withStyle` 을 언급하지만, **각 문서당 정확히 1회** — 동일한 보일러플레이트 문단 + 최소 예시 1개(`.radius4` 또는 `.radius16` 단일 getter)뿐 (`button.md:310`, `badge.md:192`, `card.md:118` 동일 문형 확인).
- 미언급 19개는 대부분 Style 슬롯이 없는 layout primitive/인프라(aspect-ratio-box, breakpoint, group, stack-layout, text 등) — **부재가 정당한 케이스**로 보이나, Specification 단계에서 컴포넌트별 Style 슬롯 보유 여부로 판정 필요.

### 1-3. 핵심 발견 — `chain` 공유 variant 인프라가 이미 존재하며, 꺼져 있다

`docs_core/lib/shared/preview_variants.dart` (순수 Dart 단일 출처):

- `DocsChainPreviewMode { hidden, appended, only }` — chain 변형의 노출 방식 3종이 이미 설계·구현됨.
- **현재 `kDocsChainPreviewMode = hidden`** — 즉 chain 프리뷰가 전 컴포넌트에서 **비노출** 상태.
- chain 예제 파일: **Flutter 119개 + Web 대응** (`*_chain_example.dart`) 이미 존재, 레지스트리 배선 완료 (`docsComponentHasChainPreview` 가 스니펫 레지스트리에서 파생 판정).
- 단, 기존 chain 예제의 **내용이 최소** — `button_chain_example.dart` 는 `.radius16` 하나만 시연 (23줄). "모든 스타일 옵션" 요청과 큰 격차.

**함의**: (A) 는 제로베이스가 아니라 "이미 배선된 chain 인프라의 **내용 확충 + 노출 모드 전환**" 문제다. md 손편집 없이 `kDocsChainPreviewMode` 한 줄로 122개 컴포넌트 노출이 바뀌는 구조가 이미 준비돼 있다.

### 1-4. LivePreview 구조 — 랜덤 버튼이 앉을 자리

`docs_site/lib/components/live_preview.dart` (230줄):

- SSG 정적 렌더 + `@client` 아일랜드 2개(`WebPreview`, `FlutterPreview`) — variant 는 **SSG 시점 prop**.
- 코드 스니펫은 SSG 시점 문자열 (`kCodeSnippetRegistry[component](variant)` → `<pre>` 고정).
- 인터랙션은 코드 탭 전환 + 복사뿐 (스파이크 #3592 §2 실측과 일치).
- 인터랙티브 아일랜드 선례 2종: `SurfaceStyleSwitcher`(prepaint 스크립트 + delegated listener) / `FlutterPreview` 폴링 채널(`preview_app.dart`, 200ms — bool/enum 급 신호만 나름).

## 2. 선행 자료와의 관계 (Market/Prior-art)

| 자료 | 관계 |
|---|---|
| `docs/spike-3592-dual-preview-token-editor.md` | **구분 필수.** 스파이크는 "테마 축(62슬롯 CoreColorScheme) 실시간 편집기"를 Flutter transport 부재로 **착수 보류** 판정. 본 건 (B)는 테마 축이 아니라 **컴포넌트 인스턴스 스타일 순열** — "사전 등록된 순열 세트 중 인덱스 선택" 설계면 임의-값 transport 가 필요 없어 봉쇄를 우회한다(인덱스/enum 은 기존 폴링 채널이 이미 나르는 대역폭). 이 구분이 본 프로젝트의 실현 가능성 논거의 핵심. |
| `docs/docs-benchmark-2026-08-01.md` | P1: "`LivePreview` 는 고정 variant 쇼케이스일 뿐 편집 가능한 플레이그라운드가 아님" — (B) 가 이 갭의 1단계 응답. 장기 비전 "실시간 토큰 편집 도구"의 전 단계로 위치. |
| `.pipeline/coui-live-docs.yaml` | LivePreview/레지스트리 인프라의 원조 파이프라인 — 예제·코드·레지스트리 4분리 구조와 자산 목록의 출처. |
| `.claude/rules/process/docs-site.md` | `_code.dart` ≡ `_example.dart` 전체 동기화 의무 — 순열 예시가 늘수록 이 의무도 배가. 자동 생성 옵션 검토 근거(벤치마크의 "defaultsByVariant 에서 자동 생성" 방향과 일치). |
| `.claude/rules/cross-platform/api.md` "Style 슬롯 체인" | withStyle/primitive getter 의 규범 정본 — 커스텀 nickname getter 금지, 토큰-정확 이름만. 예시 확충 시 이 규칙이 콘텐츠 가드레일. |

경쟁 관점(벤치마크 재사용): daisyUI Theme Generator·Astryx `defineTheme` 은 단일 렌더 엔진이라 "랜덤 스타일 순열을 두 플랫폼이 동시에 렌더" 하는 형태 자체가 없다 — 듀얼 프리뷰 + 랜덤 순열은 CoUI 만 보여줄 수 있는 차별점(파리티 증명 도구를 겸함).

## 3. 페르소나와 니즈

| 페르소나 | 니즈 | 현재 pain |
|---|---|---|
| CoUI 소비 개발자 (Flutter/Web) | "이 컴포넌트에서 뭘 어디까지 스타일링할 수 있나"를 문서에서 즉시 파악 | withStyle 문단이 전 문서 동일 보일러플레이트 + getter 1개 예시 — full-control 경로(39필드)를 문서로 알 수 없음 |
| 디자이너/리뷰어 | 토큰 조합의 시각 결과를 빠르게 탐색 | 고정 쇼케이스뿐, 조합 탐색 수단 없음 |
| AI 에이전트 (llms.txt 스파이크 §참조) | md 예시가 곧 코드 생성 소스 | 예시 부족 = 에이전트가 chain API 를 못 쓰거나 잘못 씀 |
| CoUI 메인테이너 | 스타일 필드가 실제 렌더에 반영되는지(orphan 필드) 시각 검증 | 랜덤 순열 프리뷰 = 필드 커버리지 비주얼 테스트 (사용자 명시 가치) |

## 4. 가정과 검증 (Specification 단계 입력)

| # | 가정 | 위험도 | 검증 방법 |
|---|---|---|---|
| A1 | "모든 스타일 옵션" = **전 getter 계열 대표 시연 + withStyle full-control 예시**로 해석 (39필드를 문자 그대로 한 예시에 전부 = 비가독) | **높음 — 사용자 확인 필요** | Specification 게이트에서 범위 확정 |
| A2 | (B) 랜덤 = **사전 등록 순열 세트 중 결정적(seed) 랜덤 선택** — 임의 런타임 값 생성 아님 | 중간 | spike-3592 §6 판정 재적용: 인덱스 신호는 양 플랫폼 손잡이 존재 |
| A3 | 코드-비주얼 동기화는 순열별 코드를 SSG pre-render 후 토글 표시 전환 (SSG 제약 호환) | 중간 | `surface_style_switcher.dart` 선례 + Design 단계 PoC |
| A4 | FlutterPreview 가 순열 인덱스를 **런타임에** 받으려면 기존 폴링 채널 확장 또는 아일랜드 re-mount 필요 — 어느 쪽이든 신규 배선 | **중간-높음 (기술 리스크 1순위)** | Design 단계에서 두 경로 비교, 필요시 PoC 스토리 분리 |
| A5 | (A) 노출은 `kDocsChainPreviewMode` hidden→appended 전환으로 충분 | 낮음 | 한 줄 변경 + 시각 확인 |
| A6 | Style 슬롯 없는 19개 문서는 (A) 대상 제외가 정당 | 낮음 | 컴포넌트별 `CoreXxxStyle` 슬롯 보유 grep |

## 5. 솔루션 방향 (Ideation)

1. **(A) chain 예제 내용 확충** — 컴포넌트별 `*_chain_example.dart` 를 "radius 계열 + 색 계열 getter + `withStyle(CoreXxxStyle(...))` full-control" 시연으로 승격, `_code.dart` 동기화, md 산문도 컴포넌트 고유 예시로 교체(보일러플레이트 탈피). 노출 모드 `appended` 전환.
2. **(B) 랜덤 순열 토글** — 순열 정의를 **순수 Dart 단일 출처**(preview_variants 패턴 준용)에 두고, 프리뷰 패널에 랜덤(셔플) 버튼 추가: 클릭 → 다음 순열 인덱스 → Web 아일랜드 리렌더 + Flutter 채널로 인덱스 전달 + 해당 순열의 pre-render 코드 표시. 순열은 컴포넌트의 Style 필드에서 **파생 생성**(손 목록 rot 방지) 검토.
3. **비주얼 테스트 연계** — 순열 세트가 곧 스타일 필드 커버리지 매트릭스: 스크린샷 파리티 검증(verify 7-5)과 접목 가능성은 후속으로 분리.

## 6. 비전 · North Star

- **비전 한 줄**: "문서를 연 사용자가 어떤 컴포넌트든 스타일 커스터마이징의 전 표면을 코드와 비주얼로 동시에 — 두 플랫폼 나란히 — 확인한다."
- **North Star Metric**: chain 프리뷰 노출 + 랜덤 순열 동작 컴포넌트 비율 (현재 0% — hidden — → 목표: Style 슬롯 보유 전 컴포넌트).
- 보조 지표: 순열 세트의 Style 필드 커버리지 %, md 보일러플레이트 문단 잔존 수 (120 → 0).

## 7. Planning 단계로 넘길 것

1. A1 범위 확정 (아래 게이트 질문) → Specification.
2. (B) 기술 경로 결정은 Design 단계로: 폴링 채널 확장 vs 아일랜드 re-mount vs 공유 JS 힙 notifier (spike §5).
3. 스토리 후보 골격: ① chain 예제 확충(카테고리별 batch) ② 노출 모드 전환+회귀 테스트 ③ 순열 단일 출처 + 랜덤 버튼 UI ④ Flutter 인덱스 transport ⑤ 코드 pre-render 토글 ⑥ 문서 md 스윕.
4. 명시적으로 미룸: 임의 값 실시간 편집(스파이크 봉쇄 유지), 순열 스크린샷 자동 회귀(CI), URL 영속화.
