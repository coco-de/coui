# CoUI Button — 코드 인계 문서

> 2026-08-21 기준. Figma 파일 `9FgsLhiWz0aLsVqcoI6nYJ`의 `❖ Button` 최종 상태를 실측해서 작성했다. 기억이 아니라 파일에서 읽은 값이다.
>
> 이 문서는 **Button 한정**이다. 포커스 링 규약은 Button 밖의 12개 컴포넌트에도 이미 적용했으므로 §6은 Button 외 컴포넌트에도 그대로 적용된다.

---

## 0. 한 장 요약

| 항목 | 이전 | 이후 |
|---|---|---|
| 배리언트 수 | 576 | **210** |
| Variant 축 | 12개 | **7개** (`primary · secondary · outline · ghost · link · plain · destructive`) |
| Size 축 | 6개 | 6개 (`xs · sm · md · lg · xl · xl2`) — 유지 |
| 상태 표현 | `Enabled(bool)` + `Hover(bool)` | **`State` enum 5개** (`enabled · hover · focus · pressed · disabled`) |
| `Selected` 축 | 있음 | **삭제** |
| 상태 레이어 색 | 전역 `on-surface` | **컨테이너 자신의 `on-` 색** |
| 상태 레이어 알파 | 하드코딩 | **`opacity/3 · 8 · 12`** 원시 토큰 |
| 포커스 표시 | 컴포넌트마다 제각각 | **간격 2 · 굵기 2 · 75% 단일 규약** |
| 높이 | 일부 하드코딩(xs 20, outline md 35) | **전부 `control-size/*` 바인딩** |

**공개 API 삭제가 포함된다.** §2를 먼저 읽을 것.

---

## 1. 축 구조

```
CoreButton = Variant(7) × Size(6) × State(5) = 210
```

### 1.1 Variant

| 값 | 역할 |
|---|---|
| `primary` | 주 액션 |
| `secondary` | 보조 액션 |
| `outline` | 테두리로 영역을 구분하는 저강조 |
| `ghost` | 배경 없음, 호버 시 배경 노출. 영역을 보여줄 필요가 있는 저강조 |
| `plain` | 배경/패딩 없음. 콘텐츠 정렬을 침범하지 않는 유틸리티 액션 |
| `link` | `plain` + 밑줄 |
| `destructive` | 파괴적 액션 |

`ghost` / `plain` / `link`는 역할이 서로 다르므로 셋 다 유지한다. 기준은 다음과 같다.

- 버튼의 **영역 자체를 보여줘야 한다** → `ghost`
- 영역 없이 **콘텐츠와 정렬돼야 한다** → `plain`
- 이동/외부 링크 의미가 있다 → `link`

### 1.2 Size

`xs · sm · md · lg · xl · xl2` — control-size 계약을 그대로 따른다.

| Size | 높이 |
|---:|---:|
| xs | 24 |
| sm | 32 |
| md | 40 |
| lg | 48 |
| xl | 56 |
| xl2 | 64 |

**`height-*`는 최소 높이(min-height)다.** 고정 높이가 아니다. NavigationBar에서 세운 규약을 Chip에 이어 Button에도 적용했다. 코드에서 `height: 40px`가 아니라 `min-height: 40px`로 내보내야 한다.

### 1.3 State

```
enabled | hover | focus | pressed | disabled
```

이전의 `Enabled(bool) × Hover(bool)` 조합은 `focus`와 `pressed`를 표현할 수 없었고, `Enabled=false, Hover=true` 같은 무의미한 칸을 만들었다. enum 하나로 바꿨다.

코드 쪽에서는 이 축이 컴포넌트 prop이 아니라 **CSS 의사클래스로 매핑**되는 것이 정상이다. Figma의 State는 디자인 표기용이다.

```
enabled  → 기본
hover    → :hover
focus    → :focus-visible
pressed  → :active
disabled → :disabled / [aria-disabled="true"]
```

---

## 2. 삭제된 공개 API — 디프리케이션 필요

아래는 **이미 릴리스된 API**다. Figma에서는 지웠지만 코드에서 바로 지우면 파괴적 변경이다. 마이너 릴리스 2회에 걸쳐 처리할 것을 권한다.

### 2.1 삭제된 Variant

| 값 | 삭제 이유 | 대체 |
|---|---|---|
| `menu` | Button이 아니라 Menu 컴포넌트의 항목이었다 | `Menu` / `MenuItem` |
| `menubar` | 위와 동일 | `Menubar` |
| `card` | 컨테이너였다. 게다가 `outline`(테두리 토큰)을 채움으로 써서 라벨 대비가 Light 1.43 · Dark 1.26이었다 — 글자가 안 보였다 | `Card` + 내부 `ghost` Button |
| `fixed` | 크기 축과 중복 | `Size` 축 |
| `text` | `plain`과 역할이 겹쳤다. 패딩 유무로 구분하려 했으나 `plain`이 이미 패딩 0이다 | `plain` |

### 2.2 삭제된 축

- **`Selected`** — Button은 선택 상태를 갖지 않는다. 토글되는 버튼은 `ToggleButton` 또는 `Chip`이다. 확인 결과 파일 내 다른 버튼류 컴포넌트도 `Selected`를 쓰지 않았다.

### 2.3 권장 처리 순서

1. **N+1 릴리스**: 위 값들을 런타임에서 계속 동작시키되 `console.warn` + 타입 `@deprecated` 표시. 대체 경로를 메시지에 명시.
2. **N+2 릴리스**: 제거.

`card`만은 예외로 취급해도 된다. 현재 구현이 대비 1.43/1.26이라 **접근성 결함**이므로, 디프리케이션 기간 중에도 배경을 표면 사다리(`surface-container` → `-high` → `-highest`)로 즉시 교체하는 것이 맞다.

---

## 3. 색 매트릭스

Light · Dark · HCLight · HCDark **4모드 전부**에서 검증했다. 대비 실패 0건.

### 3.1 Variant × 슬롯

| Variant | 컨테이너 | 라벨/아이콘 | 테두리 | 상태 레이어 색 |
|---|---|---|---|---|
| `primary` | `primary` | `on-primary` | — | `on-primary` |
| `secondary` | `secondary` | `on-secondary` | — | `on-secondary` |
| `outline` | `surface` | `on-surface` | `outline` | `on-surface` |
| `ghost` | transparent | `on-surface` | — | `on-surface` |
| `destructive` | `error` | `on-error` | — | **`on-surface`** (예외, §3.3) |
| `plain` | transparent | §3.4 | — | **없음** |
| `link` | transparent | §3.4 | — | **없음** |

### 3.2 disabled

| Variant | 컨테이너 | 라벨 | 테두리 |
|---|---|---|---|
| `primary` `secondary` `destructive` | `disabled-container` | `on-surface-variant` | — |
| `outline` | `surface` | `disabled-content` | `disabled-outline` |
| `ghost` | transparent | `disabled-content` | — |
| `plain` `link` | transparent | `disabled-content` | — |

**주의**: disabled 라벨 색은 enabled 라벨 색을 그대로 쓰면 안 된다. 작업 중 `primary`의 흰 라벨을 `disabled-container` 위에 그대로 복사해 대비 1.0(글자 실종)이 났다. **disabled 배경 기준으로 라벨을 다시 고른다.**

파일 전체 disabled 규약: 전용 토큰(`disabled-container` / `disabled-content` / `disabled-outline`)이 있으면 그것을 쓰고, 없으면 `on-surface` → `on-surface-variant` 한 단계 하향. 무처리는 허용하지 않는다.

**미해결**: `disabled-content`가 Light/Dark 모두 `#7d7f82`다. 모드 분리가 안 돼 있다. 코드 쪽에서 값을 하드코딩하지 말고 토큰만 참조해두면, 토큰이 분리될 때 자동으로 따라온다.

### 3.3 destructive의 상태 레이어 예외

`destructive`의 상태 레이어만 `on-error`가 아니라 **`on-surface`**를 쓴다.

`on-error`(흰색)를 12% 얹으면 `error` 배경이 밝아지면서 그 위 흰 라벨의 대비가 **4.16**으로 떨어진다(기준 4.5). `on-surface`(검정 계열)를 얹으면 배경이 어두워져 라벨 대비가 오히려 올라간다.

이건 "레이어 색 = 컨테이너의 `on-` 색" 규칙의 의도적 예외다. 규칙의 목적은 *레이어가 실제로 배경을 바꾸게 하는 것*이고, `destructive`에서는 반대 방향이 그 목적을 더 잘 달성한다. 코드에도 이 예외를 명시적으로 남길 것.

**미해결**: HC 모드에서 `destructive/hover`의 변화량이 **1.01**이다. 노드 하나의 opacity를 모드별로 다르게 줄 수 없어서 Figma에서는 못 고쳤다. 코드에서는 가능하다 — HC 모드에서만 hover를 테두리 변화로 바꾸거나 알파를 올리는 분기를 넣을 것.

### 3.4 plain / link 라벨 색

배경이 없으므로 상태를 **전경색만으로** 표현한다.

| State | 라벨/아이콘 |
|---|---|
| `enabled` | `on-surface-variant` |
| `hover` | `on-surface` |
| `focus` | `on-surface-variant` (링으로 표시) |
| `pressed` | `on-surface` |
| `disabled` | `disabled-content` |

`link`는 위와 동일 + **밑줄**.

---

## 4. 상태 레이어

### 4.1 알파

새 원시 토큰 3개를 만들었다.

```
opacity/3   → hover
opacity/8   → focus
opacity/12  → pressed
```

`enabled`는 0(레이어 노드는 존재하되 투명).

**`pressed 12%`가 상한이다.** 더 올리면 라벨 대비가 깨진다. NavigationBarItem의 Dark pressed가 이미 **4.54**로 기준 4.5에 0.04 여유밖에 없다. 코드에서 알파를 조정할 일이 생기면 반드시 4모드 대비를 다시 재야 한다.

**Figma 트랩**: Figma는 opacity 변수를 0–100으로 해석한다. 익스포터가 Figma용으로 내보낼 때 ×100 해야 한다. 코드 쪽 값은 0.03 / 0.08 / 0.12다.

### 4.2 레이어 색 규칙

> 상태 레이어 색은 전역 상수가 아니라 **자신이 올라앉은 표면의 콘텐츠 색(`on-` 색)** 이어야 한다.

이전에는 전역 `on-surface`를 썼다. 모노크롬 시스템(CoUI의 유채색 계열은 `tertiary` 하나뿐)에서는 채움과 전경이 같은 중성 램프에서 나오므로, 레이어 색이 배경 색과 **우연히 같아질 확률이 구조적으로 높다.** Chip이 실제로 그랬다 — hover/pressed 변화량이 정확히 **1.00**, 즉 아무 일도 일어나지 않았다.

수정 후 Button 전 배리언트: hover 1.04~1.10, pressed 1.20~1.45. 변화량 0인 칸 없음.

가드에 검사로 넣을 것: `contrast(배경, 배경에 레이어 합성) < 1.02`면 실패.

---

## 5. 지오메트리

### 5.1 패딩 있는 배리언트 (`primary` `secondary` `outline` `ghost` `destructive`)

높이는 `control-size/*`에 바인딩된다. 좌우 패딩은 사이즈별 사다리.

이전에 하드코딩으로 어긋나 있던 값 2건을 고쳤다.

- `xs` 높이 **20 → 24**
- `outline/md` 높이 **35 → 40** (테두리 1px을 높이에서 뺀 상태였다. `box-sizing: border-box`면 뺄 필요가 없다.)

### 5.2 plain / link

`plainbuttonspec.md`를 따른다.

```
padding-inline: 0
padding-block: 0
background: transparent
border: none
box-shadow: none
```

**인터랙션 높이는 한 단계 낮춘다.**

| Size | 일반 배리언트 | plain / link |
|---|---:|---:|
| xs | 24 | 24 |
| sm | 32 | **24** |
| md | 40 | **32** |
| lg | 48 | **40** |
| xl | 56 | **48** |
| xl2 | 64 | **56** |

이유: 시각적 패딩이 0이라 같은 높이를 쓰면 라벨 위아래로 과도한 빈 영역이 생기고, 인접 요소와의 정렬이 깨진다. 스펙 §6의 "기존 Button Size Token 재사용" 원칙은 지키되(별도 높이 체계를 만들지 않았다), 한 단계 아래 토큰을 참조한다.

**Figma 트랩**: `layoutSizingVertical='FIXED'`는 `minHeight` 바인딩을 조용히 무시한다. `HUG`로 강제해야 최소 높이가 먹는다. 코드에는 영향 없다.

### 5.3 모바일 터치 타깃 — 코드에서 닫아야 하는 구멍

> **2026-10-07 결정(D17, `휴대폰-배율-조사.md` §6-1):** 터치 환경에서 누르는 영역을 48 로 넓히지 않는다. 하한은 24(`a11y/pointer-target-min`)를 유지하고, 터치 화면의 큰 컨트롤은 크기 단계(lg 이상)로 고른다. 근거는 #5306 측정 — 넓히려면 Button 을 포함한 65곳을 새로 감싸야 하고, Flutter 는 넓힌 영역이 조상 상자를 넘지 못해 구조를 고쳐야 하며, 촘촘한 배치에서 영역끼리 겹친다. 아래 문단은 결정 전의 요구로 남긴다. §5.2 의 plain 높이 표와 코드가 다른 점은 #5330 에서 다룬다.

스펙 §6은 모바일 최소 인터랙션 높이를 **44px 이상**으로 잡는다. 그런데 `plain/md`의 인터랙션 높이는 **32**다.

Figma에서는 해결할 수 없다(포인터 환경을 모른다). **코드에서 처리해야 한다.**

```
포인터 환경     → 위 표 그대로
터치 환경       → min-height/min-width를 a11y/touch-target(48)로 승격
                  단, 시각적 크기는 유지 (::before 확장 또는 음수 마진)
```

`@media (pointer: coarse)` 또는 런타임 감지 중 팀 컨벤션에 맞는 쪽. 시각 크기를 같이 키우면 §5.2의 정렬 이점이 사라지므로, **히트 영역만** 키울 것.

### 5.4 아이콘–라벨 간격 — 스펙에서 의도적으로 벗어난 부분

스펙 §7은 `4 / 6 / 8` 3단계를 권한다. 현재 파일은 사이즈 6단계에 각각 다른 gap을 쓴다.

의도적이다. Button만 3단계로 줄이면 같은 사이즈의 Chip · Field · NavigationBar와 아이콘 간격이 어긋난다. gap은 Button 고유 값이 아니라 control-size 계약의 일부다.

**다만 이건 재검토 대상으로 남긴다.** 6단계 중 실제로 시각적 차이가 나는 건 3~4단계일 가능성이 크다. 사다리 단순화는 Button 단독이 아니라 control-size 전체를 대상으로 별도 진행할 것.

---

## 6. 포커스 링

**Button뿐 아니라 파일 전체 규약이다.** 12개 이상 컴포넌트, 331개 노드에 적용했다.

### 6.1 사양

```
간격(offset)  2px   — 컨트롤 바깥 경계와 링 사이의 빈 공간
굵기(width)   2px
색            on-surface-variant @ 75%
              단, 에러 맥락(destructive, 에러 상태 Field 등)은 error @ 75%
모서리        컨트롤 radius + 4  (= 간격 + 굵기)
위치          컨트롤 바깥 (outside)
```

CSS로는 이렇게 나온다.

```css
:focus-visible {
  outline: 2px solid color-mix(in srgb, var(--color-on-surface-variant) 75%, transparent);
  outline-offset: 2px;
}
```

### 6.2 왜 바깥인가 — inset을 버린 이유

처음에는 컨트롤 **안쪽**에 그리는 방향으로 갔다가 되돌렸다.

문제는 테두리가 있는 컴포넌트다. 안쪽 링의 바깥 1px이 기존 `outline` 테두리와 겹친다. 그 픽셀에서 일어나는 변화는 **1.33~2.40**뿐이다. 즉 링 면적의 절반만 3:1을 만족한다.

WCAG 2.4.13 Focus Appearance(AAA)는 두 가지를 요구한다.

1. 지시자 면적이 **최소 2 CSS px 두께의 둘레 이상**
2. 포커스 전/후 **같은 픽셀에서 3:1 이상의 대비 변화**

안쪽 링은 1번을 만족하지 못했다. 바깥에 그리면 링이 놓이는 픽셀이 전부 페이지 표면이므로 두 조건 다 만족한다.

(2.4.7 Focus Visible(AA)에는 수치 요구가 없다. AA만 목표라면 안쪽도 통과한다. 우리는 AAA를 기준으로 잡았다.)

### 6.3 링 색이 `on-` 색이 아닌 이유

안쪽 링일 때는 컨테이너의 `on-` 색이 맞았다. 바깥으로 옮기면 링이 놓이는 곳은 컨테이너가 아니라 **페이지 표면**이다.

`primary` 버튼에 `on-primary`(흰색) 링을 바깥에 그리면 흰 페이지 위 흰 링 — 대비 **1.0**. 그래서 배리언트 계열 색이 아니라 표면 기준 색인 `on-surface-variant`로 통일했다.

에러 맥락만 `error`를 쓰는 것은 의미 전달 때문이다.

### 6.4 Figma stroke 정렬 산술 — 반드시 기록

Figma 작업 중 같은 실수를 세 번 했다. 코드에는 직접 영향이 없지만 **Figma를 다시 만질 사람은 반드시 읽을 것.**

`strokeAlign='INSIDE'`일 때, 링 사각형의 위치·크기와 실제 보이는 간격의 관계는 이렇다.

```
GAP = 2, W = 2, OFF = GAP + W = 4

ring.x = -OFF                          // -4
ring.y = -OFF
ring.resize(w + OFF*2, h + OFF*2)      // 각 변 4px씩 확장
ring.cornerRadius = 컨트롤 radius + OFF
ring.strokeAlign = 'INSIDE'
ring.strokeWeight = W                  // 획이 -4 ~ -2 구간을 차지 → 실제 간격 2px
```

핵심: **INSIDE 정렬에서 획은 사각형 경계의 안쪽으로 자란다.** 그래서 사각형을 `-4`에 두면 획은 `-4~-2`를 채우고, `-2~0`이 빈 간격 2px로 남는다.

- `offset -4`를 "4px 간격"으로 읽는 것 → 틀렸다. 이미 2px 간격이다.
- "간격 2px이니 `-2`로 옮기자" → 간격이 **0**이 된다. 붙어버린다.

### 6.5 `FocusOutline` 인프라 컴포넌트

토큰 바인딩된 링을 가진 `FocusOutline` 컴포넌트를 만들었다. `Focused(BOOLEAN)` × `Shape` 축을 가진다.

**하지만 현재 소비 컴포넌트들은 이걸 인스턴스로 쓰지 않고 각자 링을 그린다.** 제너레이터가 합성을 평면화하기 때문이다. 즉 **일관성 강제는 Figma가 아니라 코드와 가드에서 해야 한다.**

코드 쪽 권장: 포커스 링을 컴포넌트마다 선언하지 말고 **단일 유틸리티/믹스인 하나**로 만들고 전 컴포넌트가 그것만 참조하게 할 것. 가드에는 "포커스 스타일이 공용 유틸을 거치지 않고 선언되면 실패" 규칙을 넣는다.

---

## 7. 컴포넌트 프로퍼티

Figma 최종 상태.

| 이름 | 타입 | 기본값 |
|---|---|---|
| `Child` | TEXT | `Button` |
| `Show leading` | BOOLEAN | `false` |
| `Leading` | INSTANCE_SWAP | — |
| `Show trailing` | BOOLEAN | `false` |
| `Trailing` | INSTANCE_SWAP | — |
| `Show focus ring` | BOOLEAN | `false` |

노드 순서:

```
state layer (절대 위치)
leading
Button (TEXT)
trailing
focus ring (절대 위치)
```

코드 매핑 제안:

```ts
type ButtonProps = {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost'
          | 'link' | 'plain' | 'destructive';   // 기본 'primary'
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xl2';  // 기본 'md'
  leading?: ReactNode;
  trailing?: ReactNode;
  disabled?: boolean;
  children: ReactNode;
};
```

`State`와 `Show focus ring`은 prop이 아니다. 각각 의사클래스와 `:focus-visible`로 매핑된다.

---

## 8. Figma에 아직 없는 것

- **`CoreButtonShape` 축** — 사용자 요청으로 이번 라운드에서는 보류. 코드에 이미 있다면 그대로 두고, Figma에는 다음 라운드에 넣는다.

---

## 9. 코드 팀 작업 목록 (우선순위)

1. **대비 가드 도입** — 별도 문서 `CoUI 대비 가드 — 사양과 참조 구현`에 사양 + 실행 가능한 참조 구현 + 회귀 픽스처 4건이 있다. 기존 게이트는 "정의된 시맨틱 짝"만 봐서 이번에 잡은 결함 4건을 전부 통과시켰다. 이게 1순위다.
2. **삭제 API 디프리케이션** (§2) — N+1에서 경고, N+2에서 제거. `card`의 대비 결함만은 즉시 수정.
3. **`State` 축 → 의사클래스 매핑** (§1.3) — Figma의 State를 prop으로 노출하지 말 것.
4. **상태 레이어 색 규칙** (§4.2) + `destructive` 예외 (§3.3) + HC hover 분기.
5. **`opacity/3 · 8 · 12`** 토큰 도입, 하드코딩 알파 제거. Figma 익스포트 시 ×100.
6. **포커스 링 공용 유틸 단일화** (§6.5).
7. **모바일 터치 타깃** (§5.3) — plain/link의 히트 영역만 48로 승격.
8. **높이를 min-height로** (§1.2) — `height` 고정으로 내보내고 있다면 수정.

---

## 10. 열린 질문

- **`❖ Link`(Text 그룹)와 Button `link` 배리언트의 역할 중복** — 미확인. 텍스트 안 인라인 링크와 독립 액션 버튼은 다른 것이어야 하는데, 현재 둘 다 존재한다. 코드 쪽 실제 사용처를 봐야 판단할 수 있다.
- **아이콘–라벨 gap 6단계 vs 스펙 3단계** (§5.4) — control-size 전체 차원에서 재검토.
- **`disabled-content` 모드 미분리** (§3.2).
