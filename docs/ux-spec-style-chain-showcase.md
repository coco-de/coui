# UX Spec: style-chain-showcase (v2)

- 일자: 2026-08-07 · v2 = UX 리뷰 Blocking 1~4 + NB 1~5 반영 (리뷰 전문·해소 매핑: `docs/design-review-style-chain-showcase.md`)
- 도구: ASCII/Markdown. 이 표면은 site CSS 기반 chrome — `SurfaceStyleSwitcher` 선례와 동일 계열 (CoUI 컴포넌트 표면 아님, 선례 주석의 SSG 근거 동일).

## 1. 화면 구조 (chain 갤러리 item)

```text
┌─ variant-gallery-item (chain) ──────────────────────────────────┐
│ chain      ⟨.radius16.primary⟩                  [⤨ Shuffle]     │ ← 라벨 행 (chain 한정 flex)
│ ┌─ preview-container ─────────────────────────────────────────┐ │
│ │  ● Web [순열 렌더]            ● Flutter [순열 렌더]          │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ ┌─ preview-code ──────────────────────────────────────────────┐ │
│ │ [Web][Flutter]                                      [Copy]  │ │
│ │  …combo 체인(순열 반영 구간) + withStyle full-control…       │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

- **라벨 행 CSS (신규 명세 — 리뷰 B-1)**: `.variant-gallery-label` 은 현재 일반 블록 + `text-transform: capitalize` (`site_head.dart:613-621`). chain item 에 한해 모디파이어 클래스(예: `.variant-gallery-label--chain`)로 `display:flex; align-items:center; gap;` + 버튼 우측 정렬(`margin-left:auto`). **순열 칩은 `text-transform: none` + monospace 필수** — 미명세 시 `.Radius16.Primary` 로 렌더되어 "칩 = 재현 좌표" 가 표시 레벨에서 깨진다.
- **좁은 폭 wrap (NB-4)**: 라벨 행은 `flex-wrap: wrap` — 긴 칩(`.radius9999.surfaceContainer` 류)이 버튼을 밀어내면 버튼이 다음 줄로. 갤러리 스택 모드(`variant-gallery--stacked`)에서도 동일 규칙 (media query 부재가 사이트 실측 — 클래스 기반 스택뿐).
- **페이지당 chain item 수 (리뷰 B-2)**: 1개가 아니라 **태그당 1개** — 같은 컴포넌트 태그가 복수인 페이지(date-picker ×4 등)에선 여러 개가 뜬다. 각 item 은 **고유 panelId** 로 완전 독립(프리뷰·코드·상태 — 아키텍처 §1). 중복 노출이 과한 페이지는 저자가 태그에 `chain="off"` 를 달아 큐레이션 (대상 4~5개 md).
- T2/T3 chain item: 라벨 행에 'chain' 텍스트만 (칩·버튼 없음 — 티어 계약).

## 2. `ChainShuffleControl` 상세

### 구성

| 요소 | 내용 |
|---|---|
| 버튼 | ⤨ 아이콘 + visible text `Shuffle` + **aria-label="Shuffle" (visible text 와 동일 문자열)** — LOCKED spec REQ-B6/AC-9 의 aria-label 요건을 준수하되, aria-label 은 accessible name 을 **대체**하므로 visible text 와 동일 문자열로 두어 부작용 0 (재검증 스펙 정합성 §1 해소안 (b) 채택 — spec 무개정) |
| 순열 칩 | 현재 순열 체인 표기 `.radius16.primary` — monospace + `text-transform:none`, 클릭 전 = base 앵커. 시각 갱신은 즉시 |
| SR 통보 리전 | **visually-hidden 형제 `aria-live="polite"`** — 칩과 분리 (NB-2). ~300ms debounce 로 연타 시 큐 밀림 방지. 사이트 chrome 첫 aria-live 도입 (기존 0건 실측) |

### 스타일 (NB-1)

- `SurfaceStyleSwitcher` 클래스 차용 금지 (후손 셀렉터라 헤더 정체성 클래스가 갤러리로 유출) — **갤러리-로컬 어휘 재사용**: `.preview-copy-btn`/`.preview-code-tab` 계열 레시피(`site_head.dart:511-570`)를 시맨틱 클래스 `.chain-shuffle-btn` 으로.
- focus: **outline 억제 금지** — 사이트 관행은 커스텀 focus CSS 0건 = UA 기본 focus-visible 링 유지 (NB-5).

### 인터랙션

1. 클릭/Enter/Space → 다음 순열. **채널이 공유 스토어 직결이라 세 표면 모두 사실상 즉시**(같은 힙 리스너 — 아키텍처 v2 DD-1). 로딩 스피너 없음.
2. **파리티 판정은 settled 기준** (리뷰 B-4): 클릭 직후 프레임 경계의 순간 불일치는 판정 대상이 아니다 — AC-5 CDP 는 반영 완료 대기 후 샘플 (flow I-1 명시).
3. 연타: 마지막 클릭이 이긴다 (좌표 결정적). SR 통보는 debounce 로 최종 좌표만.
4. Flutter 임베드 lazy 로딩 중 클릭: 스토어가 상태 보유 — 로드 완료 시 수렴. 스켈레톤이 로딩을 이미 말하므로 별도 안내 없음 (스켈레톤 중엔 "옛 순열" 표면 자체가 없어 모순 노출 없음 — 리뷰 5c 판정).
5. 리셋 없음 (v1) — 시퀀스가 209 순회 후 base 복귀. 영속화 없음.

## 3. 접근성 (AC-9)

- 버튼: `<button type="button">` + visible text + UA focus-visible 링 + Enter/Space.
- SR: visually-hidden polite 리전이 debounce 후 현재 좌표 통보 (assertive 금지 — 상태 변경이지 실패가 아님, `widget/failure-surfaces.md` 톤 원칙). 코드 패널·프리뷰 팬에는 live region 없음 (전체 재낭독 소음 방지).

## 4. 콘텐츠·코드·Copy

- 칩·코드의 getter 표기는 실재 getter 이름 그대로 (치환 어휘 30종 밖 표기 금지 — AC-7 동일 출처).
- **Copy 는 활성 탭 추종** (리뷰 B-3): 기존 탭 전환 스크립트가 `data-code` 를 활성 패널 텍스트로 재설정하므로(`main.server.dart:233-240`), 셔플의 갱신도 "**현재 활성 탭**의 새 순열 코드" 로 기록 — Web 탭이든 Flutter 탭이든 Copy = 지금 보이는 코드.
- chain 예제 콘텐츠는 docs 룰 그대로 (Text 체인·토큰 보간·하드코딩 0·양 플랫폼 동일 문자열).

## 5. UX 결정 근거 요약

| 결정 | 근거 |
|---|---|
| 버튼을 라벨 행에 | 세 표면을 관장하는 패널-스코프 컨트롤 — 특정 팬 소속으로 보이면 오해 |
| 순열 칩 병기 + 정확 표기 | 칩 텍스트 = 재현 좌표 (US-4) — capitalize 왜곡 금지가 그래서 Blocking |
| 스피너 없음 | 스토어 직결로 전 표면 즉시 — 지연 축 자체가 소멸 (구 폴링 안의 200ms 논의는 폐기) |
| 시각 칩 / SR 리전 분리 | 시각은 즉시·SR 은 debounce — 연타 시 폴라이트 큐 밀림 방지 |
| 갤러리-로컬 버튼 어휘 | 헤더 컨트롤 chrome 유출 방지, 물리적 인접 어휘 재사용 |
