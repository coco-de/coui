// 섹션 스코프의 `needs` 폐포와 **합집합 동등성** 셀프테스트 (#4038 / C5).
// `npm run selftest` 아래 plain Node 로 돈다.
//
// ## 무엇을 지키나
//
// C5 의 AC 는 두 문장이고, 둘째가 오래 증명되지 않은 채였다 —
// "섹션별 실행의 **합집합이 전체 실행과 같은 결과**를 낸다".
//
// 캔버스가 없으면 "같은 결과" 의 픽셀은 잴 수 없다. 하지만 그 주장이
// 성립하기 위한 **집합론적 조건**은 여기서 전부 판정된다:
//
//   1. 모든 엔트리가 적어도 한 섹션 실행에 들어간다 (합집합 ⊇ 전체)
//   2. 각 섹션 실행이 자기 `needs` 를 범위 안에 갖는다 (폐포)
//   3. 그 범위 안의 빌드 순서가 `needs` 를 만족한다
//
// 셋이 깨지면 픽셀을 보기 전에 이미 "같은 결과" 가 거짓이다. 실제로 둘 다
// 깨져 있었다 — 섹션 필터가 REGISTRY 의 선언 fallback 을 안 읽어 12개가
// 어떤 섹션에도 안 들어갔고, `needs` 가 섹션을 건너는 간선이 182개인데
// 폐포가 없었다.

import { REGISTRY, closeOverNeeds, topoSortRegistry } from '../src/registry';
import { kPageSectionOrder, resolveScopedNames, sectionOfEntry } from '../src/generate';
import type { RegistryEntry } from '../src/helpers';
import { applyScopedMigrations } from '../src/renames';

declare const process: { exit(code: number): never };

let failures = 0;

async function check(label: string, fn: () => void | Promise<void>): Promise<void> {
  try {
    await fn();
    console.log(`  ok  ${label}`);
  } catch (e) {
    failures++;
    console.error(`FAIL  ${label}\n      ${String(e)}`);
  }
}

function assert(cond: boolean, msg: string): void {
  if (!cond) throw new Error(msg);
}

const entry = (name: string, needs?: string[]): RegistryEntry =>
  ({ name, section: 'Control', needs, build: () => undefined }) as unknown as RegistryEntry;

async function main(): Promise<void> {
  console.log('selftest: scope union (#4038)');

  // ─── closeOverNeeds — 순수 단위 ───────────────────────────────────────────

  await check('needs 없는 선택은 그대로다', () => {
    const r = closeOverNeeds(new Set(['A']), [entry('A'), entry('B')]);
    assert(r.closed.size === 1 && r.closed.has('A'), [...r.closed].join(','));
    assert(r.added.length === 0, `added ${r.added.join(',')}`);
  });

  await check('직접 needs 를 끌어온다', () => {
    const r = closeOverNeeds(new Set(['A']), [entry('A', ['B']), entry('B')]);
    assert(r.closed.has('B'), '자식이 범위에 들어와야 한다');
    assert(r.added.join(',') === 'B', `added ${r.added.join(',')}`);
  });

  await check('전이적으로 닫는다 — A→B→C', () => {
    const r = closeOverNeeds(new Set(['A']), [entry('A', ['B']), entry('B', ['C']), entry('C')]);
    assert(r.closed.has('C'), '손자까지 닫아야 한다');
    assert(r.added.join(',') === 'B,C', `added ${r.added.join(',')}`);
  });

  await check('이미 고른 것은 added 에 넣지 않는다', () => {
    const r = closeOverNeeds(new Set(['A', 'B']), [entry('A', ['B']), entry('B')]);
    assert(r.added.length === 0, `added ${r.added.join(',')}`);
    assert(r.closed.size === 2, `closed ${r.closed.size}`);
  });

  await check('멱등 — 폐포를 다시 닫아도 늘지 않는다', () => {
    const reg = [entry('A', ['B']), entry('B', ['C']), entry('C')];
    const once = closeOverNeeds(new Set(['A']), reg);
    const twice = closeOverNeeds(once.closed, reg);
    assert(twice.added.length === 0, `added ${twice.added.join(',')}`);
    assert(twice.closed.size === once.closed.size, 'size drift');
  });

  await check('needs 순환이 있어도 멈춘다', () => {
    // `topoSortRegistry` 가 순환을 하드 에러로 막지만, 폐포가 먼저 도는
    // 자리라 여기서 무한 루프가 나면 그 에러를 볼 기회조차 없다.
    const r = closeOverNeeds(new Set(['A']), [entry('A', ['B']), entry('B', ['A'])]);
    assert(r.closed.size === 2, `closed ${r.closed.size}`);
  });

  await check('added 는 정렬된다 — 로그가 실행마다 흔들리지 않게', () => {
    const r = closeOverNeeds(new Set(['A']), [entry('A', ['Z', 'M']), entry('M'), entry('Z')]);
    assert(r.added.join(',') === 'M,Z', `added ${r.added.join(',')}`);
  });

  // ─── 실제 REGISTRY 에 대한 합집합 동등성 ──────────────────────────────────

  const sectionsOf = new Map(REGISTRY.map((e) => [e.name, sectionOfEntry(e)]));
  const allNames = new Set(REGISTRY.map((e) => e.name));

  await check('모든 엔트리가 어떤 섹션엔가 속한다 — 아니면 그 엔트리는 합집합 밖이다', () => {
    const orphan = REGISTRY.filter((e) => sectionsOf.get(e.name) === null).map((e) => e.name);
    assert(orphan.length === 0, `섹션 없는 엔트리 ${orphan.length}개: ${orphan.join(', ')}`);
  });

  await check('선언된 섹션이 전부 kPageSectionOrder 안에 있다', () => {
    const unknown = [...new Set([...sectionsOf.values()])]
      .filter((s): s is string => s !== null)
      .filter((s) => !kPageSectionOrder.includes(s));
    assert(unknown.length === 0, `목록 밖 섹션: ${unknown.join(', ')}`);
  });

  // ⚠️ 아래 셋은 전부 `resolveScopedNames` — 실행이 쓰는 **그 함수** — 를 몬다.
  // 테스트가 자기 파티션을 계산하면 개념만 검사하게 되고, 출하되는 필터가
  // 그것과 갈려도 초록이다. 실제로 갈려 있었다(섹션 fallback 미적용 12건).
  const scopeOfSection = (section: string) => resolveScopedNames({ sections: [section] }).names;

  await check('섹션별 실행의 합집합 == 전체 REGISTRY (C5 AC 둘째 문장)', () => {
    const union = new Set<string>();
    for (const section of kPageSectionOrder) {
      for (const name of scopeOfSection(section) ?? []) union.add(name);
    }
    const missing = [...allNames].filter((n) => !union.has(n));
    assert(
      missing.length === 0,
      `${missing.length}개가 어떤 섹션 실행에도 안 들어간다: ${missing.slice(0, 12).join(', ')}`,
    );
    assert(union.size === allNames.size, `union ${union.size} vs registry ${allNames.size}`);
  });

  await check('각 섹션 실행이 자기 needs 를 범위 안에 갖는다 (폐포 후)', () => {
    const broken: string[] = [];
    for (const section of kPageSectionOrder) {
      const closed = scopeOfSection(section);
      if (closed === null || closed.size === 0) continue;
      for (const e of REGISTRY) {
        if (!closed.has(e.name)) continue;
        for (const need of e.needs ?? []) {
          if (!closed.has(need)) broken.push(`${section}: ${e.name} needs ${need}`);
        }
      }
    }
    assert(broken.length === 0, `${broken.length}건: ${broken.slice(0, 8).join(' · ')}`);
  });

  await check('각 섹션 실행의 빌드 순서가 needs 를 만족한다', () => {
    const broken: string[] = [];
    for (const section of kPageSectionOrder) {
      const closed = scopeOfSection(section);
      if (closed === null || closed.size === 0) continue;
      // 실행과 같은 순서 — 정렬 먼저, 스코프 필터 나중.
      const ordered = topoSortRegistry(REGISTRY).filter((e) => closed.has(e.name));
      const at = new Map(ordered.map((e, i) => [e.name, i]));
      for (const e of ordered) {
        for (const need of e.needs ?? []) {
          const c = at.get(need);
          const p = at.get(e.name);
          if (c === undefined || p === undefined || c > p) {
            broken.push(`${section}: ${e.name} needs ${need}`);
          }
        }
      }
    }
    assert(broken.length === 0, `${broken.length}건: ${broken.slice(0, 8).join(' · ')}`);
  });

  await check('범위 없는 실행은 전량이다 — 폐포가 전체를 바꾸지 않는다', () => {
    assert(resolveScopedNames(undefined).names === null, '범위 없음은 null 이어야 한다');
    assert(resolveScopedNames({}).names === null, '빈 옵션도 null');
    const r = closeOverNeeds(allNames, REGISTRY);
    assert(r.added.length === 0, `added ${r.added.join(',')}`);
  });

  await check('entryNames 가 sections 를 이긴다 — 그리고 needs 를 끌어온다', () => {
    const r = resolveScopedNames({ entryNames: ['Button'], sections: ['Form'] });
    assert(r.names !== null && r.names.has('Button'), 'Button 이 범위에 있어야 한다');
    // Button(Control) → Icon(Icon) — 섹션을 건너는 실측 간선.
    assert(r.names!.has('Icon'), `needs 자식이 끌려와야 한다: ${[...r.names!].join(',')}`);
    assert(r.added.includes('Icon'), `added ${r.added.join(',')}`);
    const formOnly = REGISTRY.filter((e) => sectionsOf.get(e.name) === 'Form').map((e) => e.name);
    assert(!formOnly.every((n) => r.names!.has(n)), 'sections 가 무시돼야 한다');
  });

  await check('scoped migration only changes selected entries and their actual dependencies', () => {
    type Node = { name: string; type: string; children?: Node[]; remove: () => void };
    const children: Node[] = [];
    const node = (name: string, type: string, kids?: Node[]): Node => {
      const n: Node = { name, type, children: kids, remove: () => {
        const i = children.indexOf(n); if (i >= 0) children.splice(i, 1);
      } };
      return n;
    };
    const input = node('Input', 'COMPONENT');
    const selectedOld = node('old', 'COMPONENT');
    const dependency = node('Button', 'COMPONENT_SET', [selectedOld]);
    const skeletonOld = node('old', 'COMPONENT');
    const skeleton = node('Skeleton', 'COMPONENT_SET', [skeletonOld]);
    const mockup = node('Mockup', 'COMPONENT_SET');
    const heading = node('Section / Display', 'TEXT');
    children.push(input, dependency, skeleton, mockup, heading);
    const page = { children } as unknown as PageNode;
    const tables = {
      sets: [{ from: 'Input', to: 'TextField', reason: 'fixture' }],
      variants: [
        { component: 'Button', from: 'old', to: 'new', reason: 'fixture' },
        { component: 'Skeleton', from: 'old', to: 'new', reason: 'fixture' },
      ],
      structural: [{ name: 'Mockup', oldType: 'COMPONENT_SET' as const, reason: 'fixture' }],
    };
    const scope = resolveScopedNames({ entryNames: ['TextField'] }).names;
    assert(scope !== null && scope.has('Button') && !scope.has('Skeleton') && !scope.has('Mockup'),
      `unexpected dependency closure: ${[...(scope ?? [])].join(', ')}`);
    applyScopedMigrations(page, scope, tables);
    assert(input.name === 'TextField' && selectedOld.name === 'new', 'selected and dependency migrations must run');
    assert(skeletonOld.name === 'old' && children.includes(mockup) && children.includes(heading),
      'unselected variants, structural nodes and headings must remain untouched');
    assert(applyScopedMigrations(page, scope, tables).length === 0, 'scoped migrations must be idempotent');
    applyScopedMigrations(page, null, tables);
    assert(skeletonOld.name === 'new' && !children.includes(mockup) && !children.includes(heading),
      'a full run must still apply the previously deferred migrations and cleanup');
  });

  if (failures > 0) {
    console.error(`\n${failures} check(s) failed`);
    process.exit(1);
  }
  console.log('✅ scope-union selftest passed');
}

void main();
