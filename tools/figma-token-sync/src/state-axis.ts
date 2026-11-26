/// <reference types="@figma/plugin-typings" />
// `State` 축의 공용 계약 — 값 목록(R1)과 `Show focus ring`(R3)을 만드는 곳이 여기 하나다.
//
// ## 왜 있는가
//
// 상호작용 상태를 `State` 한 축으로 둔다는 규칙은 이미 열여섯 세트가 따랐지만, 값 목록은
// 세트마다 빌더 안에 따로 적혀 있었고 `Show focus ring` 정의는 여덟 곳에 복사돼 있었다. 같은
// 규칙이 복사본으로 살면 한 곳만 어기는 날 아무도 모른다: 순서가 다른 세트가 생겨도 멤버 이름은
// 그대로 그럴듯하고, `State=focus` 만 있고 불린이 없는 세트는 오류 없이 그려진다 — 링을 겹쳐
// 켜야 하는 pressed + 포커스, disabled + 포커스를 그릴 방법이 없을 뿐이다.
//
// 이 파일은 규칙을 **빌더가 만들 수 없는 형태**로 옮긴다:
//
//   · `stateAxis(...)` — 값 목록은 R1 순서의 부분열이어야 한다. 아니면 던진다.
//   · `defineShowFocusRing` / `bindShowFocusRing` — 불린의 이름 · 타입 · 기본값 · 결선 규칙이 한 곳.
//
// ## 던지는 이유 (정렬하지 않는 이유)
//
// 순서가 어긋난 입력을 조용히 R1 순서로 고치면 **그 세트의 멤버 순서가 바뀐다** — 캔버스의
// 변형 이름은 정체성이고 `mountSet` 은 이름으로 기존 컴포넌트를 찾는다. 순서를 고치는 것은
// 헬퍼의 일이 아니라 그 세트를 옮기는 작업(변형 개명표와 함께)이다. 헬퍼는 어긋남을 드러내기만
// 한다. 정적으로 같은 질문을 하는 CI 가드(`check_figma_state_axis.py`)가 소스 모양에서 먼저 잡는다.
//
// ## 이 파일이 하지 않는 것
//
// 값 상태(선택 · 체크 · 켜짐 · 열림 · 펼침 · 오류 · 가상 포커스)는 `State` 에 들어오지 않는다(R2) —
// `InteractionState` 에 없는 이름은 거부된다. `Button` 의 `selected` 처럼 아직 `State` 안에 있는
// 값은 그 세트를 옮기는 작업 때까지 이 헬퍼를 거치지 않고 가드의 baseline 에 있다.

import type { AxisSpec } from './axis-combos';
import { bindFocusRing, defineProp, type FocusRingNodes } from './helpers';

/**
 * R1 — 상호작용 상태의 이름과 순서. 컴포넌트에 없는 값은 빼되 순서는 지킨다
 * (입력 필드는 `enabled · hover · focus · disabled`). `default` 는 쓰지 않는다.
 */
export const kStateOrder = ['enabled', 'hover', 'focus', 'pressed', 'disabled'] as const;

export type InteractionState = (typeof kStateOrder)[number];

/**
 * 이 세트가 가진 상호작용 상태의 `State` 축 값 목록. R1 이름이고 R1 순서의 부분열이어야 한다 —
 * 이름이 R1 에 없거나 · 중복이거나 · 순서가 어긋나면 던진다. 입력을 그대로 돌려주므로 리터럴
 * 타입(`(typeof kXStates)[number]`)이 보존된다.
 */
export function stateAxis<const T extends readonly InteractionState[]>(offered: T): T {
  let at = -1;
  const seen = new Set<string>();
  for (const value of offered) {
    const index = (kStateOrder as readonly string[]).indexOf(value);
    if (index < 0) {
      throw new Error(
        `stateAxis: '${String(value)}' is not an interaction state. R1 names are ` +
          `[${kStateOrder.join(', ')}]; a value state (selected, checked, on, open, …) ` +
          'belongs on its own axis (R2), and `default` is not used.',
      );
    }
    if (seen.has(value)) {
      throw new Error(`stateAxis: '${value}' is listed twice in [${offered.join(', ')}].`);
    }
    seen.add(value);
    if (index < at) {
      throw new Error(
        `stateAxis: [${offered.join(', ')}] is out of R1 order — expected a subsequence of ` +
          `[${kStateOrder.join(', ')}]. A member's name is its identity, so the order is not ` +
          'fixed here: moving a set to R1 order is a change to that set with its variant renames.',
      );
    }
    at = index;
  }
  return offered;
}

/** `{ axis: 'State', values }` — the spec `enumerateAxisCombos` takes, built through `stateAxis`. */
export function stateAxisSpec(offered: readonly InteractionState[]): AxisSpec {
  return { axis: 'State', values: [...stateAxis(offered)] };
}

/** R3 — 이 값 목록에 `focus` 가 있으면 세트는 `Show focus ring` 을 가져야 한다. */
export function offersFocus(offered: readonly string[]): boolean {
  return offered.indexOf('focus') >= 0;
}

/**
 * R3 — 링과 밴드를 켜는 BOOLEAN 의 이름. 한 곳에서만 적는다: 소비 파일의 override 는 이 이름과
 * 타입으로 키가 잡히므로(`defineProp` 은 이름+타입으로 재사용한다) 철자가 한 곳이라도 달라지면
 * 같은 세트에 속성이 둘 생긴다.
 */
export const kShowFocusRing = 'Show focus ring';

/**
 * `Show focus ring` 을 정의한다 — 기본 `false`: 쉬는 그림에는 링이 없다. `State=focus` 에서는
 * 링이 항상 보이고(상태가 그렇게 말한다), 그 밖의 값에서는 이 불린이 링과 밴드를 함께 켠다.
 * pressed + 포커스, disabled + 포커스(메뉴 항목)처럼 `State` 하나로 그릴 수 없는 겹침을 위한
 * Figma 전용 장치이고 코드 prop 이 아니다(R7).
 *
 * 세트가 만들어진 **뒤**, 다른 속성들과 같은 자리에서 부른다 — 속성 패널의 순서가 호출 순서다.
 */
export function defineShowFocusRing(set: ComponentSetNode | ComponentNode): string | null {
  return defineProp(set, kShowFocusRing, 'BOOLEAN', false);
}

/**
 * 링과 밴드를 `Show focus ring` 에 묶는다. **이미 보이는 링은 묶지 않는다** — `State=focus` 멤버의
 * 링이다. 결선된 `visible` 은 출처가 속성 하나라 묶으면 그 멤버가 기본값 `false` 를 받아, 링을 보이려고
 * 존재하는 상태에서 링이 사라진다.
 */
export function bindShowFocusRing(ring: FocusRingNodes, propId: string | null): void {
  if (!ring.ring.visible) bindFocusRing(ring, propId);
}
