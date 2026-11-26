# CoUI 디자인 시스템 전역 재검토 (cc-designer 감사)

- 일자: 2026-07-25
- 범위: 디자인 시스템 전역 (토큰 · 테마 · 모션 · 아이콘 · 네이밍 · 로컬라이제이션 · 거버넌스)
- 렌즈: `dsys-*` 시스템 감사 + `critique-*` 시각 비평 + `ix-*` 인터랙션 + `dsys-accessibility-audit`
- 대상: `coui_core` / `coui_flutter` / `coui_web` — 카탈로그 139 컴포넌트
- 판정 방식: 코드 실측(grep/count). 추정·인상 판단 없음.

## 요약

CoUI 는 **1:1:1:1:1:1 레이어 매핑 · resolver 단일 진입점 · render-only** 라는 구조 규율이 이미 CI 가드로 강제되고 있어, *컴포넌트 개별 구현 품질*은 높다. 이번 감사에서 나온 갭은 거의 전부 **시스템 레이어(전역 축)** 에 있다 — 개별 컴포넌트가 아니라 "그 축이 시스템에 아예 없다" 는 종류다.

핵심 3줄:
1. **접근성 전역 축이 비어 있다** — reduced-motion 0건, 고대비 모드 0건, 최소 터치 타겟 규정 0건, WCAG 대비 검증 가드 0건.
2. **한 축이 두 플랫폼에서 비대칭** — Semantics(Flutter) 21% vs aria(Web) 49%. CoUI 자신의 cross-platform 대칭 룰 위반.
3. **토큰 tier 가 색상에만 완성돼 있다** — 모션은 alias tier 없이 raw ms 이름(`ms150`)만, 아이콘은 사이즈 토큰 없이 카탈로그 3종 혼용.

---

## A. 접근성 (dsys-accessibility-audit · critique-color)

### A-1. reduced-motion 전역 미지원 — **Critical**

- **관측**: `reduced-motion` / `prefersReducedMotion` / `disableAnimations` 를 `coui_core`·`coui_flutter`·`coui_web` 전체에서 검색해 **0건**.
- **문제**: WCAG 2.2 `2.3.3 Animation from Interactions` 미충족. 전정기관 장애·편두통 사용자가 애니메이션을 끌 수 없다. `dsys-motion-system` 은 이 처리를 **컴포넌트별이 아니라 시스템 레벨**에서 하도록 요구하는데, 지금은 어느 레벨에도 없다.
- **수정**: `CoreDuration` 에 reduced 오버라이드 경로를 만들고 resolver 가 그 지점을 단일 통과하게 한다. Flutter 는 `MediaQuery.disableAnimations`, Web 은 `@media (prefers-reduced-motion: reduce)` 에서 duration 토큰을 0/1ms 로 치환. 로딩 스피너·진행률처럼 **상태를 전달하는 모션은 보존**.

### A-2. Semantics(Flutter) ↔ aria(Web) 커버리지 비대칭 — **Major**

- **관측**: `Semantics(` 사용 파일 **40 / 189** (21%) · `aria-*` 사용 파일 **87 / 179** (49%) · `role` **61 / 179**.
- **문제**: 같은 컴포넌트가 Web 에선 스크린리더에 읽히고 Flutter 에선 안 읽힌다. CoUI 자체 룰(`cross-platform/api.md` — capability 는 양쪽 대칭)의 직접 위반이며, "메커니즘 비대칭은 OK, capability 비대칭은 금지" 기준에서 **capability 비대칭**에 해당한다.
- **수정**: Web 이 `role`/`aria-*` 를 가진 컴포넌트를 기준선으로 잡고 Flutter 쌍둥이에 `Semantics` 를 채운다(역방향도 동일). 커버리지 차이를 CI 가드로 고정해 재발 차단.

### A-3. 최소 터치 타겟 44×44 규정 없음 — **Major**

- **관측**: `44` / `minTouchTarget` / `tapTarget` 관련 토큰·가드가 라이브러리 코드에 **없음** (`coui_mcp` 의 문서 출력 문자열 1건 제외).
- **문제**: WCAG 2.2 `2.5.8 Target Size (Minimum)` — 24×24 CSS px 최소, 모바일 권장 44×44. `xs`/`sm` 사이즈 컨트롤(Checkbox `size12`, DotIndicator, 아이콘 affordance 버튼)이 이 기준 아래로 내려갈 수 있는데 이를 막는 규정이 없다.
- **수정**: `CoreSize` 에 최소 타겟 상수를 두고, 인터랙티브 컴포넌트 resolver 가 시각 크기와 별개로 **히트 영역 하한**을 보장하게 한다(Flutter 히트 확장 / Web `::after` 확장). 컴포넌트 스펙 문서에 명시.

### A-4. disabled 를 opacity 로 표현 — **Major**

- **관측**: contracts 안 disabled+opacity 조합 **58건** vs disabled 전용 색 토큰 **8건**.
- **문제**: CoUI **자체 룰**(`core/design-tokens.md`: "disabled 는 전용 disabled 색상 토큰으로 표현, `Opacity`/`opacity-50` 은 전용 토큰이 없을 때만")과 반대 비율이다. opacity 곱은 배경에 따라 실제 대비가 예측 불가하게 떨어져 `1.4.3 Contrast (Minimum)` 을 통과하는지 보장할 수 없다.
- **수정**: disabled 전용 시맨틱 색 토큰(전경/배경/보더 3종)을 `CoreColors` 에 추가하고, 58건을 그 토큰 참조로 치환.

### A-5. focus-visible 커버리지 부분적 — **Major**

- **관측**: Web `focus-visible` **20 / 179** · Flutter focus ring **28 / 189**.
- **문제**: `2.4.7 Focus Visible` — 키보드 사용자가 현재 위치를 잃는 인터랙티브 컴포넌트가 다수 남아 있다. 커버리지가 낮은 데다 양 플랫폼 수치도 어긋난다.
- **수정**: 인터랙티브 컴포넌트 목록을 확정하고 각각 `focusOutlineStyle` 슬롯 배선 여부를 점검. 이미 `focusRingScopedRule` / `FocusOutline` 인프라가 있으므로 **배선 누락 해소**가 대부분이다.

### A-6. WCAG 대비 검증 가드 없음 — **Major**

- **관측**: `contrastRatio` / WCAG 비율 검증 로직 **없음**. `getContrastColor` 는 명도 기반 대비색 *생성* 유틸이지 **감사**가 아니다.
- **문제**: 팔레트나 시맨틱 매핑이 바뀔 때 4.5:1 / 3:1 위반이 조용히 들어온다. 토큰 가드(Phase 1~7)는 *하드코딩*은 막지만 *대비*는 안 본다.
- **수정**: 색 스킴의 (전경, 배경) 시맨틱 쌍을 열거해 대비율을 계산하는 CI 가드를 추가. light/dark 양쪽 검사.

---

## B. 테마 시스템 (dsys-theming-system · ui-dark-mode)

### B-1. 고대비 / forced-colors 모드 없음 — **Major**

- **관측**: `highContrast` / `forced-colors` **0건**.
- **문제**: `dsys-theming-system` 의 컬러 모드 4종(light · dark · high contrast · dimmed) 중 2종만 존재. Windows 고대비 모드에서 컴포넌트가 어떻게 무너지는지 정의도 테스트도 없다.
- **수정**: 시맨틱 토큰 tier 는 이미 있으므로 **오버라이드 세트 추가**로 해결된다(레이어 2에서만 치환). Flutter `MediaQuery.highContrast`, Web `@media (forced-colors: active)`.

### B-2. 밀도(density) 모드 없음 — **Enhancement**

- **관측**: 전역 density 축 없음. `EmptyState` 의 컴포넌트-로컬 density variant 만 존재.
- **문제**: 데이터 밀집 화면(Table · Listing · Menu)에서 comfortable/compact 전환 수요가 생기면 컴포넌트마다 개별 대응하게 되어 갈라진다.
- **수정**: 즉시 필요하진 않다. 다만 `CoreSpace` 스케일에 density 배율을 끼울 자리를 지금 정해두면 나중이 싸다.

---

## C. 모션 시스템 (dsys-motion-system · ix-animation-principles)

### C-1. 모션 토큰에 alias tier 부재 — **Major**

- **관측**: duration 토큰 **16개**가 전부 raw ms 이름(`ms0`·`ms50`·`ms100`…`ms5000`). easing **30+개**(`easeInSine`·`easeOutQuart`·`easeInOutQuint` …).
- **문제**: `dsys-design-token` 의 3-tier(global → alias → component) 중 **모션은 alias tier 가 없다**. 색은 `CoreColors.primary` 같은 시맨틱 이름이 있는데 모션은 `ms150` 이라 "이게 왜 150 인가"가 이름에 없다. `dsys-motion-system` 은 "4~6개면 충분, 구분되는 use case 보다 토큰을 많이 만들지 말 것"을 명시하는데 easing 30+ 는 그 반대다.
- **수정**: raw 스케일(`ms*`)은 global tier 로 유지하고, 그 위에 **시맨틱 alias**(`instant`/`fast`/`normal`/`moderate`/`slow`)와 **의미 기반 easing**(`standard`/`decelerate`/`accelerate`/`spring`/`linear`)을 얹는다. 컴포넌트 default 는 alias 를 참조.

### C-2. choreography(stagger) 규칙 없음 — **Minor**

- **관측**: 여러 요소 동시 등장 시 stagger 간격·순서 규칙이 문서·코드 어디에도 없음.
- **문제**: 리스트/메뉴/토스트가 각자 타이밍을 정하면 제품 전체 모션 언어가 갈라진다.
- **수정**: stagger 30–50ms, 시퀀스 총합 500ms 상한을 모션 문서에 명문화.

---

## D. 로컬라이제이션 (dsys-localization)

### D-1. RTL 미지원 — **Major**

- **관측**: Web 논리 방향 클래스(`ps-`/`pe-`/`ms-`/`me-`) **0건**, 물리 방향(`pl-`/`ml-`/`left-`/`border-l-`)만 사용. `dir` 속성 설정 **5곳**(text_field · stacks · text · selectable_text)에 국한. RTL 로케일 **0개**.
- **문제**: 아랍어/히브리어에서 레이아웃이 미러링되지 않는다. Flutter 쪽은 `Directionality`/`EdgeInsetsDirectional` 사용처가 있어 **플랫폼 간에도 비대칭**이다.
- **수정**: Web 은 Tailwind 논리 유틸리티로 전환하고 루트에 `dir` 을 전파. `dsys-localization` 권고대로 컴포넌트가 시스템에 들어오기 전 **RTL 로케일 1종 + 텍스트 확장 로케일 1종**으로 테스트하는 것을 기준에 넣는다.

### D-2. Flutter 컴포넌트에 하드코딩 chrome 문자열 잔존 — **Major**

- **관측**: `item_picker.dart` `'Search...'` · `'No items found.'`, `select.dart` `'Search'` · `'No results'` 등.
- **문제**: CoUI **자체 룰**(`cross-platform/localization.md`) 위반 — 표시값은 nullable 필드 + 렌더 시점 `explicit ?? localizations.xxx` 로 해석해야 하는데 리터럴로 박혀 로케일 전환에 반응하지 않는다. 겉보기엔 정상 렌더라 회귀가 늦게 드러나는 종류다.
- **수정**: 해당 문자열을 `CoUILocalizations` 멤버로 올리고 렌더 시점 폴백으로 전환. Web 대응 멤버도 동시 확인.

### D-3. 로케일 2종 · 텍스트 확장 미검증 — **Minor**

- **관측**: `Default*` + `Ko*` 2종. 독일어/핀란드어 같은 확장 최악값 프록시 없음.
- **수정**: pseudo-localization 문자열로 +35% 확장을 프리뷰에서 검증.

---

## E. 아이콘 시스템 (dsys-icon-system)

### E-1. 아이콘 카탈로그 3종 혼용 — **Major**

- **관측**: `LucideIcons` **170** · `RadixIcons` **14** · `HeroIcons` **3** 참조.
- **문제**: 세 라이브러리는 그리드(24 vs 15)·스트로크 폭·코너 반경이 다르다. 같은 화면에 섞이면 아이콘 획 굵기가 시각적으로 어긋난다 — `critique-brand-consistency` 의 전형적 실패 패턴.
- **수정**: Lucide 를 기본 카탈로그로 확정하고 Radix 14 · Hero 3 참조를 Lucide 등가로 매핑. 예외가 필요하면 그 근거를 아이콘 시스템 문서에 남긴다.

### E-2. 아이콘 사이즈 토큰 없음 — **Minor**

- **관측**: `CoreIconStyle.size` 는 `CoreSize` 범용 스케일을 재사용. XS/S/M/L/XL 아이콘 전용 단계 정의 없음.
- **수정**: `dsys-icon-system` 기준 단계(12–16 / 20 / 24 / 32 / 48)를 아이콘 전용 토큰으로 명명.

---

## F. 인터랙션 상태 (ix-loading-states · ix-error-handling)

### F-1. 로딩/스켈레톤 상태 커버리지 — **Major**

- **관측**: 로딩/스켈레톤 관련 참조 **2 / 189** 컴포넌트.
- **문제**: 비동기 콘텐츠를 담는 컴포넌트(Table · Listing · Card · Avatar · Chat)가 로딩 상태를 표현할 방법이 없어 소비 앱이 각자 만든다 → 시스템 밖에서 갈라진다. `dsys-component-spec` 이 요구하는 상태 집합(default/hover/focus/active/disabled/**loading**/error) 중 loading 이 사실상 비어 있다.
- **수정**: `Skeleton` 인프라는 이미 있으므로, 비동기 표현이 필요한 컴포넌트에 `loading` 상태 슬롯을 표준으로 뚫는다.

### F-2. 에러 상태 커버리지 — **Minor**

- **관측**: `hasError`/`errorText`/`CoreFormFieldError` **11 / 189** — 폼 계열에 국한.
- **문제**: 폼 밖(데이터 로드 실패 등)의 에러 표현 표준이 없다.
- **수정**: 폼 에러 표준은 유지하고, 비폼 에러는 `EmptyState` 계열로 흡수할지 결정.

---

## G. 거버넌스 · 문서 (dsys-governance · dsys-documentation-template)

### G-1. deprecation 정책 문서 없음 — **Minor**

- **관측**: `@Deprecated` **0건**(현재 deprecated 항목 없음), 정책 문서 없음. `release.yml` 로 semver 자동 릴리스는 도입됨.
- **문제**: 릴리스 자동화는 있는데 "무엇을 언제 어떻게 없애는가"(예고 시점 · 유지 기간 · 마이그레이션 가이드)가 없다. 다음 breaking change 때 즉흥 결정이 된다.
- **수정**: `CONTRIBUTING.md` 에 deprecation 타임라인(도입 릴리스에 예고 → 최소 1 마이너 유지 → 메이저에서 제거)과 breaking change 정책을 명문화.

### G-2. 문서 a11y 섹션 누락 50건 — **Minor**

- **관측**: md 문서 **139 / 139**(커버리지 완전) 중 접근성 섹션 보유 **89**.
- **수정**: `dsys-component-spec` 의 8 섹션 구조 기준으로 누락 50건에 접근성 섹션 추가.

---

## 감사에서 "이상 없음"으로 확인된 축

과다 지적을 피하기 위해 명시한다.

| 축 | 근거 |
|---|---|
| 토큰 하드코딩 방지 | 디자인 토큰 가드 Phase 1~7 이 CI 에서 강제 |
| 레이어 매핑 규율 | 1:1:1:1:1:1 + resolver 단일 진입점 + render-only 가 룰·가드로 고정 |
| 색상 시맨틱 tier | M3 슬롯 기반 3-tier 완성, `ResolvedColorScheme` 로 non-null 확정 |
| 타이포 스케일 | display/headline/title/body/label × L/M/S 15단계 M3 정합 |
| 네이밍 일관성 | bare 컴포넌트명 + `Core*`/`CoUI*` 접두 경계, 충돌 CI 가드 존재 |
| 문서 커버리지 | 139/139, 카탈로그 단일 출처 + 정합성 테스트 |
| 린트 | dart + DCM 전수 0 (ignore 없이) |

---

## 참고

- 이 감사는 **정적 코드 실측** 기반이다. `critique-*` 렌즈 중 렌더 화면이 있어야 판정 가능한 항목(실제 대비율 측정, eye-flow, 밀도 체감)은 시스템 레이어 갭으로 환원해 기록했다 — 개별 화면 비평은 `docs_site` 기동 후 `/cc-designer:critique-screen` 으로 별도 수행할 수 있다.
- 지적 19건 중 **자체 룰 위반**이 3건(A-2 대칭 · A-4 disabled 토큰 · D-2 하드코딩 문자열)이다. 이들은 새 정책이 아니라 **이미 합의된 규칙의 미이행**이라 우선순위가 높다.
