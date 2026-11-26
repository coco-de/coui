/// <reference types="@figma/plugin-typings" />

// Self-test for the retired-PROPERTY half of src/renames.ts.
//
// 빌더가 프로퍼티 선언을 멈춰도 재활용된 세트에는 그 정의가 남는다 — `defineProp`
// 은 더하거나 재사용할 뿐 지우지 않는다. 그래서 명시적 retire 액션이 지워야 하고,
// 이 셀프테스트는 그 액션이 틀리는 세 방향을 Node 더블로 고정한다:
//
//   1. **있는 것을 찾는가** — dry-run 이 ● 로 보고하고 execute 가 정확히 그 키를 지운다.
//   2. **이름만 같고 타입이 다른 것은 건드리지 않는가** — 같은 표시 이름의 TEXT 는 남는다.
//   3. **없는 것은 no-op 인가** — 다른 세트·빈 페이지에서 조용히 "not found" 줄만 낸다.
//
// 그리고 배선 — `retire-dry-run` / `retire-execute` 두 핸들러가 이 목록을 실제로
// 읽는지. 빠져도 타입체크는 통과하고 아무도 모른다.

import {
  RETIRED_PROPERTIES,
  dryRunRetiredProperties,
  removeRetiredProperties,
  retiredPropertyKey,
  type RetiredProperty,
  type RetiredPropertyOwner,
} from '../src/renames';

declare const process: { exit(code: number): never; cwd(): string };
declare function require(m: string): unknown;
const { readFileSync } = require('fs') as {
  readFileSync(p: string, enc: string): string;
};
const { join } = require('path') as { join(...parts: string[]): string };

let failures = 0;
function check(cond: boolean, label: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    console.error(`  ✗ ${label}`);
    failures++;
  }
}

interface FakeOwner extends RetiredPropertyOwner {
  componentPropertyDefinitions: Record<string, { type: string }>;
  deleted: string[];
}

function owner(type: string, name: string, defs: Record<string, { type: string }>): FakeOwner {
  const node: FakeOwner = {
    type,
    name,
    componentPropertyDefinitions: { ...defs },
    deleted: [],
    deleteComponentProperty(propertyId: string) {
      if (!(propertyId in node.componentPropertyDefinitions)) {
        throw new Error(`deleteComponentProperty: no ${propertyId}`);
      }
      delete node.componentPropertyDefinitions[propertyId];
      node.deleted.push(propertyId);
    },
  };
  return node;
}

console.log('retired properties — list');
check(RETIRED_PROPERTIES.length > 0, 'RETIRED_PROPERTIES is not empty');
check(
  RETIRED_PROPERTIES.every((r) => r.reason.trim().length > 0),
  'every row states a reason',
);
check(
  RETIRED_PROPERTIES.some((r) => r.component === 'Scaffold' && r.name === 'Show header action 1'),
  'Scaffold `Show header action 1` is listed (#4574)',
);

console.log('retired properties — found and removed');
const scaffold = owner('COMPONENT_SET', 'Scaffold', {
  'Show header action 1#12:3': { type: 'BOOLEAN' },
  'Show header action 2#12:4': { type: 'BOOLEAN' },
  'Show sidebar#12:5': { type: 'BOOLEAN' },
});
const pages = [{ children: [scaffold] }];
const dry = dryRunRetiredProperties(pages, RETIRED_PROPERTIES);
const scaffoldRows = dry.filter((c) => c.component === 'Scaffold');
check(scaffoldRows.length === 2 && scaffoldRows.every((c) => c.found), 'dry-run reports both as found');
check(scaffold.deleted.length === 0, 'dry-run deletes nothing');
const log = removeRetiredProperties(pages, RETIRED_PROPERTIES);
check(
  scaffold.deleted.join(',') === 'Show header action 1#12:3,Show header action 2#12:4',
  `execute deletes exactly the two keys (got ${scaffold.deleted.join(',')})`,
);
check('Show sidebar#12:5' in scaffold.componentPropertyDefinitions, 'an unlisted property survives');
check(log.filter((l) => l.includes('removed property')).length === 2, 'the log names both removals');

console.log('retired properties — same name, different type');
const textTwin: RetiredProperty = {
  component: 'Twin',
  name: 'label',
  type: 'BOOLEAN',
  reason: 'selftest',
};
const twin = owner('COMPONENT', 'Twin', { 'label#1:1': { type: 'TEXT' } });
check(retiredPropertyKey(twin, textTwin) === null, 'a TEXT property is not matched by a BOOLEAN row');
removeRetiredProperties([{ children: [twin] }], [textTwin]);
check(twin.deleted.length === 0, 'and execute leaves it alone');

console.log('retired properties — absent is a no-op');
const other = owner('COMPONENT_SET', 'AppBar', { 'Show header action 1#9:9': { type: 'BOOLEAN' } });
const absent = dryRunRetiredProperties([{ children: [other] }, { children: [] }], RETIRED_PROPERTIES);
check(
  absent.filter((c) => c.component === 'Scaffold').every((c) => !c.found),
  'a same-named key on ANOTHER set is not reported',
);
const absentLog = removeRetiredProperties([{ children: [other] }], RETIRED_PROPERTIES);
check(other.deleted.length === 0, 'and is not deleted');
check(absentLog.every((l) => l.includes('not found')), 'every line says not found');

console.log('retired properties — wiring');
const code = readFileSync(join(process.cwd(), 'code.ts'), 'utf8');
check(/dryRunRetiredProperties\(pages, RETIRED_PROPERTIES\)/.test(code), 'retire-dry-run reads the list');
check(/removeRetiredProperties\(pages, RETIRED_PROPERTIES\)/.test(code), 'retire-execute reads the list');

if (failures > 0) {
  console.error(`\n${failures} retired-property check(s) failed.`);
  process.exit(1);
}
console.log('\nAll retired-property self-tests passed.');
