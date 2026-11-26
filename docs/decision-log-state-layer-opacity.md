# State Layer 적용 가이드 (Hover / Focus / Pressed)

CoUI Design System — 2026.08 결정 사항 정리

## 1. 배경

기존에는 컴포넌트 상태(hover/focus/pressed) 변경 시 컴포넌트 자체의 알파값을 조정하는 방식을 썼다. 이 방식은 상태가 바뀔 때마다 컴포넌트 고유 색상(브랜드 컬러 등)이 함께 흐려진다는 문제가 있어, 원래 색상은 유지하고 그 위에 반투명 레이어를 얹는 **상태 레이어(state layer) 방식**으로 전환하기로 했다.

전환 과정에서 현재 적용된 hover 3% / focus 8% / pressed 12% 값이 primary처럼 어둡고 채도가 높은 fill 컴포넌트(예: 블랙 버튼)에서는 거의 보이지 않는 문제가 발견됐다. 이를 계기로 전체를 문서 원안인 5/10/15로 일괄 상향하는 안도 검토했으나, 다음 이유로 채택하지 않았다.

- 문제는 "값이 작아서"가 아니라 **어두운 배경 위에서는 같은 알파값이라도 지각되는 명도 변화폭이 작기 때문**에 발생한다 (저휘도 영역에서의 지각 대비 특성).
- 전체를 5/10/15로 올리면 이미 문제없이 동작하던 text field 등 밝은 표면 컴포넌트에서 특히 pressed 15%가 과해질 위험이 있다.

## 2. 결정 원칙

1. **메커니즘은 하나로 유지한다.** 컴포넌트 자체 색상의 알파를 낮추는 방식은 쓰지 않고, 모든 상태 변경은 상태 레이어(오버레이) 방식으로 통일한다.
2. **오버레이 강도(퍼센트)는 표면 유형에 따라 두 티어로 분기한다.** "알파 vs 상태레이어"로 메커니즘을 나누지 않고, 같은 상태레이어 메커니즘 안에서 배경의 명도/채도에 따라 토큰 값만 다르게 가져간다.
3. **Focus 상태의 접근성 요구사항은 상태 레이어와 별도로 보장한다.** 상태 레이어는 시각적 보조 장치이며, WCAG 비텍스트 대비 3:1(SC 1.4.11) 충족은 별도의 focus ring/outline이 담당한다.

## 3. Tier 정의

### Tier A — Light / Neutral Surface

**대상**: 배경이 밝은 뉴트럴 계열인 컴포넌트. 예) Text Field, Card, List Item, Surface, Outlined/Ghost 버튼 등 배경이 흰색·연한 회색인 경우.

**오버레이 컬러**: Black (on-surface 다크 컬러)

| 상태 | 값 | 비고 |
|---|---|---|
| Hover | 3% | 기존 값 유지 |
| Focus | 8% | 기존 값 유지 |
| Pressed | 12% | 기존 값 유지 |

이 티어는 현재 문제가 보고되지 않았으므로 값을 바꾸지 않는다.

### Tier B — Dark / Saturated Fill

**대상**: 채도가 높거나 명도가 낮은 fill 컴포넌트. 예) Primary(블랙) 버튼, Danger 등 진한 semantic color 버튼.

**오버레이 컬러**: White (on-fill 라이트 컬러)

| 상태 | 값 | 비고 |
|---|---|---|
| Hover | 8% | 기존 3% 대비 상향 |
| Focus | 12% | 기존 8% 대비 상향 |
| Pressed | 16% | 기존 12% 대비 상향 |

Material Design 3의 state layer 기준값(hover 8% / focus·pressed 10~12% / dragged 16%)을 참고해 설정했다. 실제 팔레트에 대입한 뒤 육안 QA로 최종 확정한다.

### 예외 — semantic 전환은 토큰 교체 (2026.08 추가)

원칙 2-1("모든 상태 변경은 상태 레이어로 통일")의 **유일한 예외**: rest 와 hover 가
같은 색의 세기 차이가 아니라 **다른 의미**인 variant 는 오버레이가 아니라 토큰을
교체한다.

현재 해당하는 것은 `destructive` 버튼 하나다. rest 는 흰 배경 + 빨간 테두리 +
빨간 라벨(= "이 버튼은 파괴적이다"), hover 는 빨간 통짜 채움 + 흰 라벨(= "지금
누르면 실행된다"). 이건 강조의 세기 조절이 아니라 **상태의 전환**이고, 어떤
불투명도의 흰/검정 오버레이로도 흰 배경을 빨강으로 만들 수 없다.

판정 기준: **오버레이로 표현 가능한가.** 오버레이는 배경을 밝히거나 어둡게만
할 수 있으므로, hover 가 rest 와 **다른 색상(hue)** 을 요구하면 그 variant 는
이 예외에 속한다. 밝기만 달라지면 예외가 아니다 — Tier B 가 그 경우다.

이 예외는 **variant 단위로 문서에 등재**해야 하며, 코드에서만 다르게 구현하는
것은 위반으로 본다. 등재되지 않은 variant 가 토큰을 교체하고 있으면 그것은
결정이 아니라 표류다.

## 4. Tier 판정 기준

새로운 브랜드 컬러나 컴포넌트가 추가될 때 어느 티어에 속하는지는 배경색의 relative luminance로 판단한다.

```
relative luminance (WCAG 공식)
L = 0.2126 * R + 0.7152 * G + 0.0722 * B
(R, G, B는 sRGB를 감마 보정한 linear 값, 0~1 범위)
```

- L 값이 낮은(어두운) 컬러 → Tier B
- L 값이 높은(밝은) 컬러 → Tier A

임계값은 지금 결정된 팔레트를 기준으로 QA하며 확정한다. 팔레트에 따라 딱 두 그룹으로 갈리지 않는 애매한 색(중간 톤 브랜드 컬러 등)이 나오면 그때 개별 검토한다.

## 5. 구현 가이드

컴포넌트 색상 자체가 아니라, 별도의 오버레이 레이어(의사 요소 또는 별도 엘리먼트)로 얹는 방식을 권장한다. `pointer-events: none`으로 처리해 인터랙션에 영향을 주지 않게 한다.

```css
:root {
  --state-layer-color-on-light: #000000;
  --state-layer-color-on-dark: #ffffff;

  /* Tier A: Light / Neutral Surface */
  --state-opacity-hover-a: 0.03;
  --state-opacity-focus-a: 0.08;
  --state-opacity-pressed-a: 0.12;

  /* Tier B: Dark / Saturated Fill */
  --state-opacity-hover-b: 0.08;
  --state-opacity-focus-b: 0.12;
  --state-opacity-pressed-b: 0.16;
}

.state-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.1s ease;
}

/* Tier A 예시: Text Field */
.text-field .state-layer {
  background: var(--state-layer-color-on-light);
}
.text-field:hover .state-layer { opacity: var(--state-opacity-hover-a); }
.text-field:focus-within .state-layer { opacity: var(--state-opacity-focus-a); }
.text-field:active .state-layer { opacity: var(--state-opacity-pressed-a); }

/* Tier B 예시: Primary Button */
.btn-primary .state-layer {
  background: var(--state-layer-color-on-dark);
}
.btn-primary:hover .state-layer { opacity: var(--state-opacity-hover-b); }
.btn-primary:focus-visible .state-layer { opacity: var(--state-opacity-focus-b); }
.btn-primary:active .state-layer { opacity: var(--state-opacity-pressed-b); }
```

Focus 상태는 위 `.state-layer` opacity와 별개로 `outline` 또는 `box-shadow` 기반 focus ring을 항상 함께 적용하고, 이 focus ring이 인접 배경과 3:1 이상의 대비를 갖도록 별도 검증한다.

## 6. 컴포넌트 매핑 (초안 — 실제 컬러 확정 후 팀 검토 필요)

| 컴포넌트 | Tier | 비고 |
|---|---|---|
| Primary Button (Black fill) | B | 이번 이슈의 발단 |
| `destructive` 버튼 | **예외** | 토큰 교체 — 위 "예외" 절 참조 |
| 그 밖의 semantic fill 버튼 | B | 배경색 luminance 낮은 경우만 |
| Secondary/Outlined 버튼 | A 또는 B | 배경이 흰색이면 A, fill이 진하면 B — 개별 확인 |
| Text Field | A | |
| Card / List Item | A | |
| Checkbox / Radio (선택된 상태의 fill) | B | fill 색상이 진한 경우 |

실제 팔레트에 있는 모든 컬러 토큰을 4번 기준으로 재분류해 이 표를 채워야 한다.

## 7. 변경 전/후 요약

| 상태 | 변경 전 (일괄) | 변경 후 — Tier A | 변경 후 — Tier B |
|---|---|---|---|
| Hover | 3% | 3% (유지) | 8% |
| Focus | 8% | 8% (유지) | 12% |
| Pressed | 12% | 12% (유지) | 16% |

문서 원안(5/10/15) 일괄 적용안은 채택하지 않음.

`destructive` 는 이 표의 대상이 아니다 — 위 "예외" 절.

## 8. QA 체크리스트

- [ ] 실제 팔레트의 각 fill 컬러에 대해 Tier A/B 분류가 4번 기준(luminance)과 일치하는지 확인
- [ ] Tier B 적용 컴포넌트(블랙 버튼 등)에서 hover/pressed 상태 변화가 육안으로 명확히 인지되는지 확인
- [ ] Tier A 적용 컴포넌트(text field 등)에서 pressed 12%가 기존과 동일하게 자연스러운지 회귀 확인
- [ ] Focus 상태의 outline/focus ring이 인접 배경과 3:1 이상 대비를 갖는지 별도 측정
- [ ] 중간 톤이라 Tier 분류가 애매한 컬러가 있는지 전수 확인 후 개별 값 협의
- [ ] **모드에 따라 티어가 뒤집히는 컴포넌트** 확인 — 실측 결과 `surface` 계열
      채움(outline·ghost·card·menu)은 light 에서 L=0.974(A), dark 에서
      L=0.010(B) 이다. 티어는 variant 의 고정 속성이 아니라 **해석된 채움의
      속성**이므로, 불투명도도 색과 같이 모드에 따라 달라져야 한다
- [ ] **채움이 투명한 variant**(link·text·plain·fixed·ghost)의 처리 — 뒤에
      무엇이 오는지 컴포넌트가 알 수 없어 luminance 로 티어를 정할 수 없다.
      오버레이 색을 리터럴 흑/백이 아니라 그 variant 의 전경 토큰(`on*`)으로
      두면 자동으로 해소된다 (전경은 정의상 배경과 대비된다)
