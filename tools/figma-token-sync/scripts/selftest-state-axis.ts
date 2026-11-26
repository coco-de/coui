/// <reference types="@figma/plugin-typings" />

// Self-test for src/state-axis.ts — the one place a `State` axis' value list (R1)
// and `Show focus ring` (R3) are made.
//
// 헬퍼가 틀리는 방식은 두 방향이다:
//
//   · **받아선 안 될 것을 받는다** — 값 상태(`selected`) · `default` · 순서가 어긋난 목록. 받으면
//     그 세트의 멤버 이름이 조용히 규칙 밖이 된다.
//   · **고쳐 버린다** — 어긋난 입력을 R1 순서로 정렬해 돌려주면 그 세트의 멤버 순서가 바뀐다.
//     변형 이름은 정체성이라 그건 헬퍼의 일이 아니라 그 세트를 옮기는 작업이다. 그래서 헬퍼는
//     던지기만 하고, 맞는 입력은 **같은 목록을 그대로** 돌려준다.
//
// 그리고 불린: 이름 · 타입 · 기본값은 한 곳, 결선은 "이미 보이는 링은 묶지 않는다" 한 곳.
//
// Figma 런타임 없음 — 세트는 `{componentPropertyDefinitions, addComponentProperty}`, 링은
// `{ring, band}` 모양의 순수 객체다.

import { bindShowFocusRing, defineShowFocusRing, kShowFocusRing, kStateOrder, offersFocus, stateAxis, stateAxisSpec } from '../src/state-axis';
import { resetUnboundTracking } from '../src/component-props';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync, readdirSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
  readdirSync(p: string): string[];
};
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;
function check(label: string, fn: () => void): void {
  try {
    fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}
function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}
function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}
function throws(fn: () => unknown, needle: string): void {
  try {
    fn();
  } catch (e) {
    const m = String(e);
    if (!m.includes(needle)) throw new Error(`threw, but not about "${needle}": ${m}`);
    return;
  }
  throw new Error(`expected a throw mentioning "${needle}"`);
}

console.log('state axis — R1 value list');

check('R1 is exactly enabled · hover · focus · pressed · disabled', () => {
  assertEq([...kStateOrder], ['enabled', 'hover', 'focus', 'pressed', 'disabled'], 'kStateOrder');
});

check('every subsequence of R1 is accepted and returned UNCHANGED (same order, same members)', () => {
  const n = kStateOrder.length;
  let count = 0;
  for (let mask = 1; mask < 1 << n; mask++) {
    const list = kStateOrder.filter((_, i) => (mask & (1 << i)) !== 0);
    assertEq([...stateAxis(list)], list, `mask ${mask}`);
    count += 1;
  }
  assertEq(count, 31, 'all 31 non-empty subsequences');
});

check('the shapes the builders use (input field · chip · full ladder) are valid', () => {
  stateAxis(['enabled', 'hover', 'focus', 'disabled']);
  stateAxis(['enabled', 'hover', 'pressed', 'disabled']);
  stateAxis(['enabled', 'hover', 'focus', 'pressed', 'disabled']);
});

check('a value state is refused (R2) — selected, checked, on, open, active', () => {
  for (const v of ['selected', 'checked', 'on', 'open', 'active']) {
    throws(() => stateAxis(['enabled', v as never]), `'${v}' is not an interaction state`);
  }
});

check('`default` and the capitalised / past-tense spellings are refused', () => {
  for (const v of ['default', 'Default', 'focused', 'hovered', 'Enabled']) {
    throws(() => stateAxis([v as never]), 'is not an interaction state');
  }
});

check('an out-of-order list throws — it is NOT sorted for the caller', () => {
  throws(() => stateAxis(['enabled', 'pressed', 'focus']), 'out of R1 order');
  throws(() => stateAxis(['disabled', 'enabled']), 'out of R1 order');
  throws(() => stateAxis(['enabled', 'focus', 'hover', 'pressed', 'disabled']), 'out of R1 order');
});

check('a duplicate throws', () => {
  throws(() => stateAxis(['enabled', 'hover', 'hover']), 'listed twice');
});

check('the throw says what to do about order (a rename is a change to that set)', () => {
  throws(() => stateAxis(['hover', 'enabled']), 'variant renames');
});

check('stateAxisSpec builds the spec enumerateAxisCombos takes', () => {
  assertEq(stateAxisSpec(['enabled', 'disabled']), { axis: 'State', values: ['enabled', 'disabled'] }, 'spec');
});

check('offersFocus reads the list', () => {
  assert(offersFocus(['enabled', 'focus']), 'focus present');
  assert(!offersFocus(['enabled', 'hover', 'pressed', 'disabled']), 'focus absent');
});

console.log('state axis — Show focus ring');

interface SetDouble {
  componentPropertyDefinitions: Record<string, { type: string; defaultValue: unknown }>;
  added: Array<[string, string, unknown]>;
  addComponentProperty(name: string, type: string, value: unknown): string;
  getPluginData?(key: string): string;
  setPluginData?(key: string, value: string): void;
}
function setDouble(): SetDouble {
  let n = 0;
  const set: SetDouble = {
    componentPropertyDefinitions: {},
    added: [],
    addComponentProperty(name, type, value) {
      n += 1;
      const key = `${name}#${n}:0`;
      set.componentPropertyDefinitions[key] = { type: type, defaultValue: value };
      set.added.push([name, type, value]);
      return key;
    },
  };
  return set;
}

check('the BOOLEAN is named `Show focus ring`, defaults off, and is defined once per set', () => {
  assertEq(kShowFocusRing, 'Show focus ring', 'name');
  const set = setDouble();
  const first = defineShowFocusRing(set as unknown as ComponentSetNode);
  const second = defineShowFocusRing(set as unknown as ComponentSetNode);
  assertEq(set.added, [['Show focus ring', 'BOOLEAN', false]], 'one definition, default false');
  assertEq(first, second, 'a second call reuses the same key (overrides stay bound)');
});

interface RingDouble {
  ring: { visible: boolean; componentPropertyReferences?: Record<string, string> };
  band: { visible: boolean; componentPropertyReferences?: Record<string, string> };
}
function ringDouble(visible: boolean): RingDouble {
  return { ring: { visible: visible }, band: { visible: visible } };
}

check('a hidden ring and its band are both bound to the property', () => {
  resetUnboundTracking();
  const ring = ringDouble(false);
  bindShowFocusRing(ring as never, 'Show focus ring#1:0');
  assertEq(ring.ring.componentPropertyReferences, { visible: 'Show focus ring#1:0' }, 'ring');
  assertEq(ring.band.componentPropertyReferences, { visible: 'Show focus ring#1:0' }, 'band');
});

check('a ring that is already visible (the State=focus member) is NOT bound', () => {
  resetUnboundTracking();
  const ring = ringDouble(true);
  bindShowFocusRing(ring as never, 'Show focus ring#1:0');
  assertEq(ring.ring.componentPropertyReferences, undefined, 'ring left alone');
  assertEq(ring.band.componentPropertyReferences, undefined, 'band left alone');
});

console.log('state axis — wiring');

const kComponentsDir = join(process.cwd(), 'src', 'components');
function builders(): Array<{ file: string; code: string }> {
  return readdirSync(kComponentsDir)
    .filter((f) => f.endsWith('.ts'))
    .map((f) => ({
      file: f,
      // 주석 줄을 뺀다 — 설명에 이름을 인용하는 것은 사용이 아니다.
      code: readFileSync(join(kComponentsDir, f), 'utf8')
        .split('\n')
        .filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l))
        .join('\n'),
    }));
}

check('no builder spells the property name or defines it with defineProp — the name lives in one file', () => {
  const offenders: string[] = [];
  for (const b of builders()) {
    if (/defineProp\([^)]*'Show focus ring'/.test(b.code)) offenders.push(b.file);
  }
  assertEq(offenders, [], 'files that still define `Show focus ring` by hand');
});

check('no builder calls bindFocusRing directly — the "already visible" rule is in one place', () => {
  const offenders = builders()
    .filter((b) => /\bbindFocusRing\(/.test(b.code))
    .map((b) => b.file);
  assertEq(offenders, [], 'files that bind a focus ring by hand');
});

check('state-axis.ts is the only file that owns R1 in the plugin source', () => {
  const src = readFileSync(join(process.cwd(), 'src', 'state-axis.ts'), 'utf8');
  assert(/export const kStateOrder = \['enabled', 'hover', 'focus', 'pressed', 'disabled'\] as const;/.test(src), 'kStateOrder literal');
  // The guard keeps its own copy (a Python file cannot import it) — the two must agree.
  const guard = readFileSync(join(process.cwd(), '..', '..', 'scripts', 'guards', 'structure', 'check_figma_state_axis.py'), 'utf8');
  assert(/R1_ORDER = \["enabled", "hover", "focus", "pressed", "disabled"\]/.test(guard), 'the guard\'s R1_ORDER matches');
});

if (failures > 0) {
  console.error(`\n${failures} state-axis check(s) failed.`);
  process.exit(1);
}
console.log('\nAll state-axis self-tests passed.');
