/// <reference types="@figma/plugin-typings" />

// Self-test for src/unbound-props.ts — the cleanup that keeps Figma's publish
// dialog from silently dropping a set (#5323).
//
// 이 정리가 틀리는 방식은 두 방향이고 둘 다 조용하다:
//
//   · **덜 지운다** — 잔재가 남아 세트가 계속 게시에서 빠진다. 신호가 없다.
//   · **더 지운다** — 레이어가 쓰는 속성을 지워 패널에서 손잡이가 사라진다. 이쪽이 더 나쁘다.
//
// 그래서 여기서는 두 방향을 같은 무게로 고정한다:
//
//   1. 잔재(어떤 레이어도 참조 안 함)는 지워지고 한 줄씩 로그에 남는다 — 양성.
//   2. 레이어가 참조하는 속성은 안 지워진다 — 음성. 양성만 보면 전부 지워도 통과한다.
//   3. 한 변형만 참조해도 연결된 것이다 — 세트 안 모든 변형을 합쳐서 본다.
//   4. 숨은 레이어 · 중첩 인스턴스 안쪽의 참조도 참조다.
//   5. VARIANT 속성은 절대 안 지워진다.
//   6. 디자이너 사본은 안 지워진다.
//   7. 같은 노드의 같은 필드를 다른 속성으로 다시 결선하면 먼저 속성이 잔재가 된다.
//   8. 결선 기록이 놓친 참조는 지우지 않고 ⚠ 로 말한다 — 더 지우는 쪽으로 틀리지 않는다.
//   9. 제거가 거부돼도 던지지 않고 남은 것으로 보고한다.
//  10. 정의를 못 읽는 세트는 "없음" 이 아니라 "판정 못 함" 이다.
//  11. 꼬리 줄 — 남은 세트가 있으면 ⚠, 없으면 ✅.
//
// Figma 런타임 없음 — 노드는 `{type, name, children, componentPropertyReferences,
// componentPropertyDefinitions}` 모양의 순수 객체다.

import { bindSwapProp, bindTextProp, bindVisibleProp, resetUnboundTracking } from '../src/component-props';
import {
  addToUnboundTally,
  emptyUnboundTally,
  formatUnboundSettle,
  formatUnboundTally,
  settleUnboundProps,
} from '../src/unbound-props';
import { kRedesignSnapshotMarker } from '../src/designer-parity';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
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
function read(...parts: string[]): string {
  return readFileSync(join(process.cwd(), ...parts), 'utf8');
}

// ── 더블 ────────────────────────────────────────────────────────────────────

interface Def {
  type: string;
  defaultValue?: unknown;
}
interface FakeNode {
  type: string;
  name: string;
  parent?: FakeNode;
  children: FakeNode[];
  componentPropertyReferences?: Record<string, string>;
  componentPropertyDefinitions?: Record<string, Def>;
  deleted?: string[];
  attempted?: string[];
  deleteComponentProperty?: (key: string) => void;
}

function layer(name: string, children: FakeNode[] = []): FakeNode {
  const n: FakeNode = { type: 'FRAME', name: name, children: children };
  for (const c of children) c.parent = n;
  return n;
}

/** 한 세트: 변형 둘, 각 변형에 레이어 하나씩. 속성은 defs 로 선언한다. */
function makeSet(
  name: string,
  defs: Record<string, Def>,
  opts: { refuseDelete?: boolean; unreadable?: boolean } = {},
): { set: FakeNode; a: FakeNode; b: FakeNode } {
  const a: FakeNode = { type: 'COMPONENT', name: 'Size=a', children: [] };
  const b: FakeNode = { type: 'COMPONENT', name: 'Size=b', children: [] };
  const set: FakeNode = {
    type: 'COMPONENT_SET',
    name: name,
    children: [a, b],
    deleted: [],
    attempted: [],
  };
  a.parent = set;
  b.parent = set;
  if (opts.unreadable) {
    Object.defineProperty(set, 'componentPropertyDefinitions', {
      get() {
        throw new Error('in get_componentPropertyDefinitions: Component set has existing errors');
      },
    });
  } else {
    set.componentPropertyDefinitions = defs;
  }
  set.deleteComponentProperty = (key: string) => {
    set.attempted!.push(key);
    if (opts.refuseDelete) throw new Error('Cannot delete: refused');
    const d = set.componentPropertyDefinitions!;
    if (d[key]?.type === 'VARIANT') throw new Error('Cannot delete a variant property');
    delete d[key];
    set.deleted!.push(key);
  };
  return { set: set, a: a, b: b };
}

function bindVisible(node: FakeNode, key: string): void {
  bindVisibleProp(node as unknown as SceneNode, key);
}

function settle(set: FakeNode) {
  return settleUnboundProps(set as unknown as ComponentSetNode);
}

// ── 판정 ────────────────────────────────────────────────────────────────────

console.log('unbound props — removal');

check('an unreferenced property is removed and logged on one line each', () => {
  resetUnboundTracking();
  const { set, a } = makeSet('Probe', {
    'Show label#1:0': { type: 'BOOLEAN', defaultValue: true },
    'Dead text#1:1': { type: 'TEXT', defaultValue: 'Hello' },
    'Dead swap#1:2': { type: 'INSTANCE_SWAP', defaultValue: '12:34' },
    Size: { type: 'VARIANT', defaultValue: 'a' },
  });
  const shown = layer('shown');
  a.children.push(shown);
  shown.parent = a;
  bindVisible(shown, 'Show label#1:0');
  const out = settle(set);
  assertEq(set.deleted, ['Dead text#1:1', 'Dead swap#1:2'], 'deleted keys');
  assertEq(out.removed.map((p) => p.name), ['Dead text', 'Dead swap'], 'removed names');
  assertEq(out.remaining, [], 'nothing remaining');
  const lines = formatUnboundSettle(out);
  assertEq(lines.length, 2, 'one log line per removal');
  assert(lines[0].includes('Probe') && lines[0].includes('"Dead text"'), `line names set + property: ${lines[0]}`);
  assert(lines[0].includes('TEXT') && lines[0].includes('"Hello"'), `line carries type + default: ${lines[0]}`);
  assert(lines[1].includes('INSTANCE_SWAP') && lines[1].includes('12:34'), `swap default is the node id: ${lines[1]}`);
});

check('a property a layer references survives (the negative half)', () => {
  resetUnboundTracking();
  const { set, a } = makeSet('Probe', {
    'Show label#1:0': { type: 'BOOLEAN', defaultValue: true },
    'Label#1:1': { type: 'TEXT', defaultValue: 'x' },
  });
  const l1 = layer('l1');
  const l2 = layer('l2');
  a.children.push(l1, l2);
  l1.parent = a;
  l2.parent = a;
  bindVisible(l1, 'Show label#1:0');
  bindTextProp(l2 as unknown as TextNode, 'Label#1:1');
  const out = settle(set);
  assertEq(set.deleted, [], 'nothing deleted');
  assertEq(out.removed, [], 'nothing removed');
  assertEq(formatUnboundSettle(out), [], 'and silent');
});

check('one variant referencing it is enough — the variants are read together', () => {
  resetUnboundTracking();
  const { set, b } = makeSet('Probe', { 'Show x#1:0': { type: 'BOOLEAN', defaultValue: false } });
  const only = layer('only-in-b');
  b.children.push(only);
  only.parent = b;
  bindVisible(only, 'Show x#1:0');
  settle(set);
  assertEq(set.deleted, [], 'not deleted');
});

check('a reference on a HIDDEN layer inside a NESTED instance counts', () => {
  // 결선 기록이 놓친 경로를 흉내 낸다 — 기록에는 없고 트리에는 있다.
  resetUnboundTracking();
  const { set, a } = makeSet('Probe', { 'Hidden#1:0': { type: 'BOOLEAN', defaultValue: true } });
  const deep = layer('deep');
  deep.componentPropertyReferences = { visible: 'Hidden#1:0' };
  const inst = layer('inst', [layer('mid', [deep])]);
  a.children.push(inst);
  inst.parent = a;
  const out = settle(set);
  assertEq(set.deleted, [], 'the tree walk saved it');
  assertEq(out.trackerMissed.map((p) => p.name), ['Hidden'], 'and it says the record missed it');
  const lines = formatUnboundSettle(out);
  assert(lines.length === 1 && lines[0].startsWith('⚠'), `reported with ⚠: ${lines.join(' | ')}`);
});

check('VARIANT and SLOT properties are never removed', () => {
  resetUnboundTracking();
  const { set } = makeSet('Probe', {
    Size: { type: 'VARIANT', defaultValue: 'a' },
    State: { type: 'VARIANT', defaultValue: 'x' },
    'Body#2:0': { type: 'SLOT' },
  });
  const out = settle(set);
  assertEq(set.attempted, [], 'no delete call was even attempted');
  assertEq(out.removed, [], 'none removed');
  assertEq(out.remaining, [], 'and none left over as a failed removal');
  assertEq(Object.keys(set.componentPropertyDefinitions!), ['Size', 'State', 'Body#2:0'], 'definitions intact');
});

check('a designer copy is left alone', () => {
  resetUnboundTracking();
  const { set } = makeSet(`Probe ${kRedesignSnapshotMarker} 10-08`, {
    'Dead#1:0': { type: 'BOOLEAN', defaultValue: true },
  });
  const out = settle(set);
  assertEq(set.deleted, [], 'not deleted');
  assertEq(out.removed, [], 'not removed');
  assertEq(out.remaining.length, 1, 'reported as remaining so it is not mistaken for clean');
  assert(out.remaining[0].why.includes('사본'), `says why: ${out.remaining[0].why}`);
});

check('rebinding the SAME field to another property un-binds the first', () => {
  resetUnboundTracking();
  const { set, a } = makeSet('Probe', {
    'Show x#1:0': { type: 'BOOLEAN', defaultValue: true },
    'Show y#1:1': { type: 'BOOLEAN', defaultValue: true },
  });
  const n = layer('n');
  a.children.push(n);
  n.parent = a;
  bindVisible(n, 'Show x#1:0');
  // 실제 Figma 와 같다: 두 번째 쓰기가 같은 필드를 덮는다.
  n.componentPropertyReferences = { visible: 'Show y#1:1' };
  bindVisible(n, 'Show y#1:1');
  const out = settle(set);
  assertEq(out.removed.map((p) => p.name), ['Show x'], 'the replaced property is the dead one');
  assertEq(set.deleted, ['Show x#1:0'], 'and only it is deleted');
});

check('a refused delete does not throw — it is reported as remaining', () => {
  resetUnboundTracking();
  const { set } = makeSet('Probe', { 'Dead#1:0': { type: 'BOOLEAN', defaultValue: true } }, { refuseDelete: true });
  const out = settle(set);
  assertEq(out.removed, [], 'nothing removed');
  assertEq(out.remaining.length, 1, 'remaining');
  const line = formatUnboundSettle(out)[0];
  assert(line.startsWith('⚠') && line.includes('#5323'), `names the consequence: ${line}`);
});

check('unreadable definitions are "could not tell", not "none"', () => {
  resetUnboundTracking();
  const { set } = makeSet('Probe', {}, { unreadable: true });
  const out = settle(set);
  assert(out.unreadable, 'flagged');
  const tally = emptyUnboundTally();
  addToUnboundTally(tally, out);
  assertEq(tally.stillUnbound, ['Probe'], 'counted as still unbound');
});

check('bindSwapProp / bindTextProp / bindVisibleProp all count', () => {
  resetUnboundTracking();
  const { set, a } = makeSet('Probe', {
    'Show s#1:0': { type: 'BOOLEAN', defaultValue: true },
    'S#1:1': { type: 'INSTANCE_SWAP', defaultValue: '1:1' },
    'T#1:2': { type: 'TEXT', defaultValue: 't' },
  });
  const v = layer('v');
  const s = layer('s');
  const t = layer('t');
  for (const n of [v, s, t]) {
    a.children.push(n);
    n.parent = a;
  }
  bindVisible(v, 'Show s#1:0');
  bindSwapProp(s as unknown as InstanceNode, 'S#1:1');
  bindTextProp(t as unknown as TextNode, 'T#1:2');
  settle(set);
  assertEq(set.deleted, [], 'none deleted');
});

check('the tracking is reset by the drain — one entry cannot bind for the next', () => {
  resetUnboundTracking();
  const first = makeSet('First', { 'K#9:0': { type: 'BOOLEAN', defaultValue: true } });
  const n = layer('n');
  first.a.children.push(n);
  n.parent = first.a;
  bindVisible(n, 'K#9:0');
  settle(first.set);
  // 같은 키를 다음 세트가 선언하지만 결선하지 않았다 — 앞 엔트리의 기록이 남았다면 지워지지 않는다.
  const second = makeSet('Second', { 'K#9:0': { type: 'BOOLEAN', defaultValue: true } });
  settle(second.set);
  assertEq(second.set.deleted, ['K#9:0'], 'the stale count did not protect it');
});

console.log('unbound props — tail line');

check('no set left unbound → ✅ and says it is 0; one left → ⚠ and names it', () => {
  const clean = emptyUnboundTally();
  clean.pruned = 3;
  clean.prunedSets = ['TextField', 'TextArea'];
  const cleanLine = formatUnboundTally(clean, 150)[0];
  assert(cleanLine.includes('남은 세트 0') && cleanLine.includes('✅'), cleanLine);
  assert(cleanLine.includes('2 세트에서 3 개 제거'), cleanLine);
  const dirty = emptyUnboundTally();
  dirty.stillUnbound = ['Alert'];
  const dirtyLine = formatUnboundTally(dirty, 150)[0];
  assert(dirtyLine.startsWith('⚠') && dirtyLine.includes('Alert') && dirtyLine.includes('기대 0'), dirtyLine);
});

console.log('unbound props — wiring');

check('generate.ts settles every entry it draws and prints the tail line', () => {
  const src = read('src', 'generate.ts');
  assert(/settleUnboundProps\(node\)/.test(src), 'settleUnboundProps(node) is called');
  assert(/formatUnboundSettle\(settled\)/.test(src), 'its lines are logged');
  assert(/formatUnboundTally\(unboundTally, setsSettled\)/.test(src), 'the tail line is logged');
  assert(/resetUnboundTracking\(\);/.test(src), 'tracking is reset before each build');
  const settleAt = src.indexOf('settleUnboundProps(node)');
  const reassembleAt = src.indexOf('reassembly = completePendingMounts()');
  const stampAt = src.indexOf('node.setPluginData(kHashDataKey, hashStampFor(hash,');
  assert(reassembleAt > 0 && settleAt > reassembleAt, 'settle runs AFTER the set is reassembled');
  assert(stampAt > settleAt, 'and BEFORE the entry is stamped current');
});

check('addPropRef is the only writer of componentPropertyReferences', () => {
  // 결선 기록은 addPropRef 안에서만 쌓인다 — 다른 곳이 쓰면 기록이 놓친다.
  const src = read('src', 'component-props.ts');
  assert(/noteBinding\(node, field, propId\);\s*\n\s*if \(recordPropRef/.test(src), 'noteBinding precedes the write');
});

if (failures > 0) {
  console.error(`\n${failures} unbound-props check(s) failed.`);
  process.exit(1);
}
console.log('\nAll unbound-props self-tests passed.');
