/// <reference types="@figma/plugin-typings" />

// Self-test for src/swap-default-repair.ts — an INSTANCE_SWAP default that
// points at a REMOTE copy of a local component goes back to the local one
// (#5323: MenuItem's Leading · Trailing held a published copy of `Icon`).
//
// 고쳐 쓰는 쪽이 틀리는 방식도 두 방향이다:
//
//   · **안 고친다** — 사본이 기본값으로 남아 로컬을 고쳐도 슬롯이 따라오지 않는다.
//   · **디자이너의 선택을 덮는다** — 다른 라이브러리의 컴포넌트를 일부러 가리킨 기본값을
//     "사본" 으로 오인해 되돌린다. 이쪽이 더 나쁘다: `defineProp` 이 id 를 보존하는 이유가
//     바로 그 선택이다.
//
// 그래서 양성(사본 → 로컬)과 음성 넷(key 가 다른 원격 · 로컬에 짝 없는 원격 · 이미 로컬 ·
// 원격이 아닌 노드)을 같은 무게로 둔다. 음성만 단언하면 `return []` 로 바꿔도 통과한다.

import {
  formatSwapDefaultRepairs,
  localCounterpartByKey,
  repairRemoteSwapDefaults,
  type SwapOwnerLike,
  type SwapTargetLike,
} from '../src/swap-default-repair';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as { readFileSync(p: string, enc: string): string };
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;
function check(label: string, fn: () => void | Promise<void>): Promise<void> {
  return Promise.resolve()
    .then(fn)
    .then(
      () => console.log(`  ok  ${label}`),
      (e) => {
        failures++;
        console.error(`FAIL  ${label}\n      ${String(e)}`);
      },
    );
}
function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}
function assertEq<T>(actual: T, expected: T, what: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) throw new Error(`${what}: expected ${b}, got ${a}`);
}

// ── 더블 ────────────────────────────────────────────────────────────────────

const kLocalIconKey = 'a1b2c3-local-icon-24';

/** 문서의 노드들 — id 로 열린다. */
const nodes: Record<string, SwapTargetLike> = {
  // 로컬 Icon 변형 (key 는 게시본과 같다)
  'L:24': { id: 'L:24', name: 'Size=24', key: kLocalIconKey, remote: false, parent: { type: 'COMPONENT_SET', name: 'Icon' } },
  // 발행본에서 되가져온 사본 — 같은 key, remote
  'R:24': { id: 'R:24', name: 'Size=24', key: kLocalIconKey, remote: true, parent: { type: 'COMPONENT_SET', name: 'Icon' } },
  // key 는 같지만 remote 가 아닌 노드 — 사본이 아니다
  'L:99': { id: 'L:99', name: 'Size=24', key: kLocalIconKey, remote: false, parent: { type: 'COMPONENT_SET', name: 'Icon' } },
  // 다른 라이브러리의 컴포넌트 — remote, 다른 key (디자이너의 선택)
  'X:1': { id: 'X:1', name: 'Size=24', key: 'other-library-key', remote: true, parent: { type: 'COMPONENT_SET', name: 'Icon' } },
  // 로컬에 같은 이름의 세트가 없는 원격
  'Y:1': { id: 'Y:1', name: 'Size=16', key: 'no-local-twin', remote: true, parent: { type: 'COMPONENT_SET', name: 'Avatar Badge' } },
};

const localSets: Record<string, { id: string; type: string; key?: string; children?: { id: string; key?: string }[] }> = {
  Icon: { id: 'LS:1', type: 'COMPONENT_SET', children: [{ id: 'L:24', key: kLocalIconKey }, { id: 'L:16', key: 'k16' }] },
};

const resolve = async (id: string): Promise<SwapTargetLike | null> => nodes[id] ?? null;
const counterpart = (t: SwapTargetLike): string | null =>
  localCounterpartByKey(t, (name) => localSets[name] ?? null);

interface OwnerDouble extends SwapOwnerLike {
  edits: { key: string; to: string }[];
  componentPropertyDefinitions: Record<string, { type: string; defaultValue?: unknown }>;
}
function owner(
  name: string,
  defs: Record<string, { type: string; defaultValue?: unknown }>,
  opts: { refuse?: boolean } = {},
): OwnerDouble {
  const o: OwnerDouble = {
    name: name,
    edits: [],
    componentPropertyDefinitions: defs,
    editComponentProperty(key: string, change: { defaultValue: string }) {
      if (opts.refuse) throw new Error('refused');
      o.edits.push({ key: key, to: change.defaultValue });
      o.componentPropertyDefinitions[key].defaultValue = change.defaultValue;
      return key;
    },
  };
  return o;
}

async function main(): Promise<void> {
  console.log('swap default repair — decisions');

  await check('a REMOTE copy sharing a local component\'s key goes back to the local one', async () => {
    const menuItem = owner('MenuItem', {
      'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'R:24' },
      'Trailing#1:1': { type: 'INSTANCE_SWAP', defaultValue: 'R:24' },
    });
    const out = await repairRemoteSwapDefaults(menuItem, resolve, counterpart);
    assertEq(out.map((r) => [r.prop, r.from, r.to, r.ok]), [
      ['Leading', 'R:24', 'L:24', true],
      ['Trailing', 'R:24', 'L:24', true],
    ], 'repairs');
    assertEq(menuItem.componentPropertyDefinitions['Leading#1:0'].defaultValue, 'L:24', 'the definition now holds the local id');
    const lines = formatSwapDefaultRepairs(out);
    assert(lines.length === 2 && lines.every((l) => l.startsWith('↻ MenuItem') && l.includes('R:24 → L:24')), lines.join(' | '));
  });

  await check('a remote node with a DIFFERENT key is the designer\'s choice — left alone', async () => {
    const o = owner('Probe', { 'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'X:1' } });
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'no repair');
    assertEq(o.edits, [], 'no write');
  });

  await check('a remote node with no local twin has nowhere to go — left alone', async () => {
    const o = owner('Probe', { 'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'Y:1' } });
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'no repair');
    assertEq(o.edits, [], 'no write');
  });

  await check('a default that already points at the local component is not rewritten', async () => {
    const o = owner('Probe', { 'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'L:24' } });
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'no repair');
    assertEq(o.edits, [], 'no write');
  });

  await check('a node that shares the key but is NOT remote is not a copy — left alone', async () => {
    const o = owner('Probe', { 'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'L:99' } });
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'no repair');
    assertEq(o.edits, [], 'no write');
  });

  await check('only INSTANCE_SWAP is read — a TEXT default that looks like an id is not', async () => {
    const o = owner('Probe', {
      'Label#1:0': { type: 'TEXT', defaultValue: 'R:24' },
      'Show#1:1': { type: 'BOOLEAN', defaultValue: true },
      Size: { type: 'VARIANT', defaultValue: 'R:24' },
    });
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'no repair');
    assertEq(o.edits, [], 'no write');
  });

  await check('a default that resolves to nothing, or an unresolvable id that throws, does not stop the others', async () => {
    const o = owner('Probe', {
      'A#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'gone:1' },
      'B#1:1': { type: 'INSTANCE_SWAP', defaultValue: 'boom' },
      'C#1:2': { type: 'INSTANCE_SWAP', defaultValue: 'R:24' },
    });
    const throwing = async (id: string): Promise<SwapTargetLike | null> => {
      if (id === 'boom') throw new Error('node is gone');
      return resolve(id);
    };
    const out = await repairRemoteSwapDefaults(o, throwing, counterpart);
    assertEq(out.map((r) => r.prop), ['C'], 'the third still repaired');
  });

  await check('a refused write is reported, never thrown', async () => {
    const o = owner('Probe', { 'Leading#1:0': { type: 'INSTANCE_SWAP', defaultValue: 'R:24' } }, { refuse: true });
    const out = await repairRemoteSwapDefaults(o, resolve, counterpart);
    assertEq(out.length, 1, 'one report');
    assert(!out[0].ok, 'not ok');
    const line = formatSwapDefaultRepairs(out)[0];
    assert(line.startsWith('⚠') && line.includes('되돌리지 못했다'), line);
  });

  await check('unreadable definitions yield nothing and do not throw', async () => {
    const o = {
      name: 'Probe',
      get componentPropertyDefinitions(): never {
        throw new Error('existing errors');
      },
    } as unknown as SwapOwnerLike;
    assertEq(await repairRemoteSwapDefaults(o, resolve, counterpart), [], 'nothing');
  });

  console.log('swap default repair — counterpart lookup');

  await check('a standalone local COMPONENT matches on its own key', async () => {
    const t: SwapTargetLike = { id: 'R:9', name: 'Divider', key: 'dk', remote: true, parent: null };
    const got = localCounterpartByKey(t, (name) => (name === 'Divider' ? { id: 'L:9', type: 'COMPONENT', key: 'dk' } : null));
    assertEq(got, 'L:9', 'matched');
    const miss = localCounterpartByKey(t, (name) => (name === 'Divider' ? { id: 'L:9', type: 'COMPONENT', key: 'other' } : null));
    assertEq(miss, null, 'a local with another key is not a twin');
  });

  console.log('swap default repair — wiring');

  await check('generate.ts repairs BEFORE the builder reads the default, and after the hand-edit verdict', async () => {
    const src = readFileSync(join(process.cwd(), 'src', 'generate.ts'), 'utf8');
    const repairAt = src.indexOf('repairRemoteSwapDefaults(');
    const handEditAt = src.indexOf("existing.setPluginData(kCanvasFingerprintKey, '')");
    const buildAt = src.indexOf('markStep(`${e.name}:build`)');
    assert(repairAt > 0 && handEditAt > 0 && buildAt > 0, 'all three anchors exist');
    assert(repairAt > handEditAt, 'after the fingerprint is judged and cleared');
    assert(repairAt < buildAt, 'before the builder runs');
  });

  if (failures > 0) {
    console.error(`\n${failures} swap-default-repair check(s) failed.`);
    process.exit(1);
  }
  console.log('\nAll swap-default-repair self-tests passed.');
}

main();
