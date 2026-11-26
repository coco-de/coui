# Epic #2861 cc-designer 재검토 — 세션 핸드오프 (2026-07-26)

> 다른 세션이 이어받기 위한 노트. 이슈 트래커 상태를 다시 파헤치지 않고 바로 이어가는 것이 목적이다.
> 룰이 아니라 **작업 스냅샷**이므로 `.claude/rules/` 가 아니라 `docs/` 에 둔다 (tracker 번호 참조가 본문 대부분이라
> `principles/writing-rules.md` 의 self-contained 요건 대상이 아니다).

## 무엇을 했나

Epic [#2861](https://github.com/coco-de/coui/issues/2861)(Surface 스타일 프리셋 시스템)을 `cc-designer` 플러그인 렌즈
(`dsys-theming-system` · `dsys-design-token` · `dsys-accessibility-audit` · `dsys-governance` · `dsys-motion-system` ·
`critique-affordance` · `critique-color` · `ui-dark-mode` · `ui-aesthetic-usability`)로 재검토하고, 발견을 이슈로 반영했다.
모든 판정은 코드 실측(grep/count) 기반이다.

**코드 변경 없음** — 이 브랜치의 산출물은 이 문서 하나이고, 실제 작업은 전부 GitHub/ZenHub 이슈에 있다.

## 생성한 이슈 3건

| # | 제목 | 부모 | pt | 우선 | 파이프라인 |
|---|---|---|---|---|---|
| [#3322](https://github.com/coco-de/coui/issues/3322) | S0 — 프리셋 a11y 계약 (포커스 링 프리셋 축 + 수용 게이트 + reduce-transparency 판정) | #2861 | 5 | p0 | Sprint Backlog |
| [#3323](https://github.com/coco-de/coui/issues/3323) | S0b — Liquid Glass 모델 통합 판정 (glassX ↔ CoreGlassMaterial ↔ sheen 경계) | #2861 | 3 | p1 | Product Backlog |
| [#3326](https://github.com/coco-de/coui/issues/3326) | 테마 축 조합 규칙 확정 — brightness × surface × 고대비 × 밀도 | **#3298** (Epic D) | 3 | p0 | Sprint Backlog |

## 수정한 이슈 4건

- **#2861** — `재검토 갱신 (2026-07-26)` 섹션 추가, 트래커에 S0/S0b 편입, 33pt → **41pt**, 의존성 라인 갱신.
- **#2862 (S1)** — 발견 ③④ 흡수. 작업 4~6(팔레트 우선순위 · 최소 커버리지 매트릭스 · 레시피→번들 파생 판정) + AC 4건. 의존성 `없음` → `#3326`.
- **#2866 (S5)** — Web pressed 색 emit 경로를 #3265 `emitPseudoColor` / scoped `<style>` 로 명시 + AC 1건.
- **#2867 (S6)** — 목표 직후 ⚠️ 선행 블록(#3323), sheen 결론에 재검증 단서, AC 3건, 의존성에 #3323·#3322 추가.

## 발견 (코드 근거 포함)

| # | 발견 | 근거 | 반영처 |
|---|---|---|---|
| ① | Liquid Glass 시맨틱 색 토큰 4종이 **이미 존재**하고 production 소비자 0 | `color_scheme.dart:579-589`(glassTint/Highlight/Shadow/Illumination), CSS 변수 배선 `:310-313`, `surface_token.dart:111-118`(`CoreGlassMaterial` 3층) | #3323 |
| ② | Epic+10 Story 전체 **a11y 게이트 0건** | 키워드 스캔: contrast/WCAG/접근성/포커스/reduced-motion/투명도 = 0. `대비` 1건은 비교급, `스크린` 은 전부 "스크린샷" | #3322 |
| ②-1 | 포커스 링이 프리셋과 충돌 | `effect/focus_ring.dart` — `ringWidth = 2`, `ringOffsetColor = CoreColors.surface`(**불투명 surface 가정**) → 글래스(8~15% 반투명)에서 불투명 후광, 브루탈리즘(stroke4 보더 옆 2px)에서 식별 실패 | #3322 |
| ②-2 | reduce-transparency 파리티 비대칭 | Web `prefers-reduced-transparency` 가능 / Flutter `MediaQueryData` 대응 플래그 없음. coui_web 전체 `prefers-reduced-*`·`forced-colors` **0건** | #3322 |
| ②-3 | 대비/명도 유틸 부재 | 레포 전체 contrast-ratio 계산 0건. `coui_flutter/util.dart:917` 의 HSL `withLuminance` 는 플랫폼 전용 → S8 의 "bg 에서 ±루미넌스 파생" 레시피가 전제 미충족 | #3322 · #3308 |
| ③ | "brightness 와 직교" 전제 불성립 | 프리셋이 colorScheme 을 조정(브루탈리즘 원색 / 클레이 파스텔 / 뉴모피즘 `bg == 페이지 bg` **제약**). 앱 브랜드 팔레트와의 우선순위 미정의 | #2862 |
| ④ | 프리셋이 토큰 Layer 3 에 삶 | `core_component_theme.dart` 슬롯 **142** / 카탈로그 컴포넌트 **140** vs 프리셋이 채운다는 슬롯 각 **4~6** → 혼종 화면 | #2862 |
| ⑤ | 상태 매트릭스가 `pressed` 하나만 | 실제 표면 = 4프리셋 × 6상태. 뉴모피즘 disabled(recolor 가 배경에 먹힘) · 브루탈리즘 selected(전부 4px 보더) 미정의 | #3322 게이트 |
| ⑥ | 시각 위계 | 브루탈리즘 균일 적용 시 primary CTA 소실 → 프리셋 레시피에 "강조 사다리" 필요 | #2861 본문 |

**기준선 갱신 (7/20 재검토 이후 랜딩)**: #3265(`emitPseudoColor`/`focusRingScopedRule`) · #3282(`ResolvedColorScheme` authored/resolved 분리) ·
#3249(`ringOpacity` 실배선) · #3279(border-width px 고정) · #3288(disabled resolver-time recolor).
**갭 ⑤는 여전히 유효** — `CoreThemeData.defaultSurface` production 소비자 0 (테스트만).

## 작업 순서

**선행 0 · 지금 병렬 착수 가능**

| # | 작업 | pt | 푸는 대상 |
|---|---|---|---|
| #3326 | 테마 축 조합 규칙 | 3 | #2862 스파인 전체, #3314 설계 전제 |
| #2864 | S3 OutlinedContainer `boxShadow` 슬롯 | 3 | #2865 · #2866 · #2868 · #3183 |
| #3323 | S0b 글래스 모델 판정 | 3 | #2867 → #3183 · #2870 |
| #3309 | duration·easing alias (Epic B) | 5 | #3302 → #3322 |
| #3305 | focus-visible 배선 (Epic A) | 8 | #3322 |
| #3308 | WCAG 대비 가드 (Epic A) | 5 | #3322 |

**이후**

```
L1  #2862 S1 (3) ←#3326       #3302 reduced-motion (5) ←#3309    #3314 고대비 (8) ←#3326
L2  #2863 S2 (5) ←#2862       #2866 S5 (5) ←#2864                #2868 S7 (3) ←#2864
    #3322 S0 (5) ←#3305,#3308,#3302,#3314
L3  #2865 S4 (3) ←#2863,#2864,[S0]        #2867 S6 (3) ←#2863,#3323,[S0]
L4  #3183 S6b (3) ←#2864,#2867   #2869 S8 (3) ←#2866,#2868,[S0]   #2870 S9 (2) ←#2867,#2868,[S0]
```

임계 경로: `#3326 → #3314 → #3322 → #2867 → #3183` = **22pt**.

## 미결 — 이어받는 세션이 결정할 것

1. **#3322 분할 여부 (사용자 확인 대기 중)** — 현재 구조에서 #2865(S4, "파이프라인 첫 E2E 검증")가 Epic A/D **31pt** 뒤에 있고 그중 3건이 p1 이다.
   제안: **S0(정의)** = 포커스 링 프리셋 축 + 수용 게이트 체크리스트 + reduce-transparency 판정 (선행 없음, S4 게이트) /
   **S0c(가드 배선)** = 대비 가드 프리셋 확장 + forced-colors 폴백 + reduced-motion 전환 (#3308·#3314·#3302 선행, S6/S8/S9 게이트).
   분할 시 임계 경로 22pt → **14pt**. 진행하면 #3322 본문을 정의 파트로 좁히고 #2865/#2867/#2869/#2870 의 게이트 참조를 갈라야 한다.
2. **보드 순서** — Sprint Backlog 에서 #3326 이 #2862 보다 아래에 있다(뒤집어야 함). #2864 는 선행 0 이라 최상단 가능.
3. **Sprint 총량** — #3294 계획 p0 34pt + #2861 p0 14pt + #3322 5 + #3326 3 = **56pt**. #3303(13) · #3304(8)은 본 Epic 선행이 아니라 분리 가능.
4. **#3305 · #3308 · #3314 (p1) 승격 여부** — 글래스·뉴모피즘을 이번 분기에 낼 계획이면 p0 승격 검토. 브루탈리즘까지면 p1 유지로 충분.

## 주의 — 중복 생성 함정

**2026-07-25 에 별도 디자인 감사가 이미 돌아 [#3294](https://github.com/coco-de/coui/issues/3294)(Project) 아래 Epic A~G(#3295~#3301) +
작업 항목 #3302~#3321 **19건**이 생성돼 있다** (#3307 은 API 오류로 생긴 중복이고 #3308 이 정본). 이 세션의 초기 제안(a11y 전반 스토리)은
그것과 정면 중복이었고, 착수 직전에 발견해 **프리셋 델타만** 남기도록 재설계했다.
**a11y · 모션 · 토큰 tier · 거버넌스 관련 이슈를 새로 만들기 전에 반드시 #3294 트리를 먼저 확인할 것.**

## 감사 축 산출물 위치 — `development` 브랜치

감사 근거와 그 후속 산출물은 **`development` 브랜치**(커밋 `b541d7766`)에 있다. `main` 에는 없다.

| 경로 | 내용 |
|---|---|
| `docs/design-audit-coui-2026-07-25.md` | cc-designer 전역 감사 원본 (지적 19건, 4단계 심각도) |
| `.claude/docs/design-system-hardening/design-decisions.md` | **DDR — append-only 디자인 판단 기록** |
| `.claude/docs/design-system-hardening/zenhub/priority.md` | 우선순위(p0/p1/p2) 축 |
| `.pipeline/design-system-hardening.yaml` | 파이프라인 정의 |

DDR 은 "같은 질문을 두 번 결정하지 않기 위한" append-only 기록이다 — 아래 **미결 4건**을 결정할 때
그 형식(질문 / 결정 / 근거 / 기각한 대안 / 가역성 / 신뢰도)에 맞춰 DDR 로 남기는 것이 이 트랙의 관례다.

## 트래커 규약 (이 Epic 한정)

- #2861 은 umbrella 트래커 — **`gh issue develop` 금지** (Development 링크는 closing keyword 와 무관하게 머지 시 부모를 닫는다).
- sub-PR 제목은 scope 필수 (`feat(core): #N — …`), 본문은 `Part of #2861`. 각 Story PR 만 `Closes #<story>`.
