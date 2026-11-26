import {
  createCollectionOverrides,
  extensionNameFor,
  isMismatchedVariableType,
  listOverrideCollections,
  mismatchedCopiesHint,
  planResync,
  resyncOverridesByName,
  type ResyncLocal,
} from '../src/collection-overrides';

function assert(ok: unknown, message: string): asserts ok {
  if (!ok) throw new Error(message);
}

const alias = (id: string) => ({ type: 'VARIABLE_ALIAS', id });

// 「같은 이름의 로컬 토큰으로 다시 맞추기」의 세계 — 브랜드마다 로컬 컬렉션을 둔 소비
// 파일(Blue · Orange 둘 다 `color/primary` 를 갖는다)과 Blue 의 확장 컬렉션 하나. 확장
// 컬렉션의 모드는 CoUI 의 넷이다. `color/error-container` 는 같은 키의 사본이 둘이라
// 덮어쓰기가 `Mismatched variable type` 으로 거부된다(2026-11-01 실측 — 두 사본 모두).
function resyncWorld(opts: { dropWritesTo?: string } = {}) {
  const ext = {
    id: 'C:ext',
    name: 'Blue · Overrides',
    isExtension: true,
    rootVariableCollectionId: 'C:sem',
    modes: [
      { modeId: 'e1', name: 'Light', parentModeId: 'm1' },
      { modeId: 'e2', name: 'Dark', parentModeId: 'm2' },
      { modeId: 'e3', name: 'HCLight', parentModeId: 'm3' },
      { modeId: 'e4', name: 'HCDark', parentModeId: 'm4' },
    ],
    variableIds: ['R1', 'R2a', 'R2b', 'R3', 'R4', 'R5', 'R6'],
    variableOverrides: { R4: { e1: alias('LB4') } } as Record<string, Record<string, unknown>>,
  };
  const collections = [
    { id: 'C:blue', name: 'Blue', isExtension: false },
    { id: 'C:orange', name: 'Orange', isExtension: false },
    ext,
  ];
  const local = (id: string, name: string, type: string, collection: string) => ({
    id,
    name,
    resolvedType: type,
    remote: false,
    variableCollectionId: collection,
  });
  const locals = [
    local('LB1', 'color/primary', 'COLOR', 'C:blue'),
    local('LO1', 'color/primary', 'COLOR', 'C:orange'),
    local('LB2', 'color/error-container', 'COLOR', 'C:blue'),
    local('LB3', 'space/4', 'FLOAT', 'C:blue'),
    local('LB4', 'color/on-primary', 'COLOR', 'C:blue'),
    local('LB5', 'color/secondary', 'FLOAT', 'C:blue'),
  ];
  const remote = (id: string, name: string, type: string, mismatched = false) => ({
    id,
    name,
    resolvedType: type,
    remote: true,
    variableCollectionId: 'C:sem',
    setValueForMode(modeId: string, value: unknown) {
      if (mismatched) throw new Error('in setValueForMode: Mismatched variable type');
      if (opts.dropWritesTo === id) return;
      ext.variableOverrides[id] = { ...(ext.variableOverrides[id] ?? {}), [modeId]: value };
    },
  });
  const remotes = [
    remote('R1', 'color/primary', 'COLOR'),
    remote('R2a', 'color/error-container', 'COLOR', true),
    remote('R2b', 'color/error-container', 'COLOR', true),
    remote('R3', 'color/surface-raised', 'COLOR'),
    remote('R4', 'color/on-primary', 'COLOR'),
    remote('R5', 'space/4', 'FLOAT'),
    remote('R6', 'color/secondary', 'COLOR'),
  ];
  const byId = new Map<string, unknown>([...locals, ...remotes].map((v) => [v.id, v]));
  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => collections,
      getLocalVariablesAsync: async () => locals,
      getVariableByIdAsync: async (id: string) => byId.get(id) ?? null,
      getVariableCollectionByIdAsync: async (id: string) => collections.find((c) => c.id === id) ?? null,
      createVariableAlias: (v: { id: string }) => alias(v.id),
    },
  };
  return ext;
}

async function resyncChecks(): Promise<void> {
  const L = (id: string, name: string, collectionId: string, resolvedType = 'COLOR'): ResyncLocal => ({
    id,
    name,
    resolvedType,
    collectionId,
    collectionName: collectionId,
  });
  const target = (id: string, name: string, overridden = false, resolvedType = 'COLOR') => ({
    id,
    name,
    resolvedType,
    overridden,
  });
  const locals = [L('b', 'color/primary', 'Blue'), L('o', 'color/primary', 'Orange'), L('e', 'color/error', 'Blue')];

  // 짝이 하나면 그것, 둘이면 기존 덮어쓰기가 가리키는 컬렉션의 것, 그래도 둘이면 고르지 않는다.
  const unique = planResync([target('t1', 'color/error')], locals, []);
  assert(unique.set.length === 1 && unique.set[0].localId === 'e', 'a unique counterpart is chosen');
  const paired = planResync([target('t1', 'color/primary')], locals, ['b', 'b', 'o']);
  assert(paired.set.length === 1 && paired.set[0].localId === 'b', 'the collection most overrides point to wins');
  const tie = planResync([target('t1', 'color/primary')], locals, ['b', 'o']);
  assert(tie.set.length === 0 && tie.ambiguous[0]?.collections.join(',') === 'Blue,Orange', 'a tie is not guessed');
  const none = planResync([target('t1', 'color/primary')], locals, []);
  assert(none.ambiguous.length === 1, 'two candidates without overrides are not guessed');
  const typed = planResync([target('t1', 'color/error', false, 'FLOAT')], locals, []);
  assert(typed.noCounterpart[0] === 'color/error', 'a same-named local of another type is no counterpart');
  const kept = planResync([target('t1', 'color/error', true)], locals, []);
  assert(kept.overridden === 1 && kept.set.length === 0, 'an overridden variable is left alone');

  assert(isMismatchedVariableType('in setValueForMode: Mismatched variable type'), 'mismatch detected');
  assert(!isMismatchedVariableType('in setValueForMode: Cannot modify'), 'other errors are not');
  const hint = mismatchedCopiesHint(['color/error-container']);
  assert(hint.includes('color/error-container'), 'hint names the variable');
  assert(hint.includes('두 번 가져와 사본이 둘'), 'hint names the cause');
  assert(hint.includes('「가져온 사본 중복」') && hint.includes('「옛 사본 다시 연결」'), 'hint points to the audit and the rebind');

  const ext = resyncWorld();
  const log = await resyncOverridesByName();
  const all = (id: string, local: string): boolean =>
    ext.modes.every((m) => (ext.variableOverrides[id]?.[m.modeId] as { id?: string } | undefined)?.id === local);
  assert(all('R1', 'LB1'), 'color/primary → the Blue local in every mode');
  assert(all('R5', 'LB3'), 'space/4 → its FLOAT local');
  assert(Object.keys(ext.variableOverrides.R4).join() === 'e1', 'the existing override is left as it was');
  assert(ext.variableOverrides.R3 == null && ext.variableOverrides.R6 == null, 'no counterpart → nothing written');
  assert(
    log[0] === '✓ Blue · Overrides: 덮어쓰기 넣음 2개 (다시 읽어 확인 2) · 이미 덮어씀 1 · 짝 없음 2',
    `summary line: ${log[0]}`,
  );
  assert(log[1] === '  짝 없음 — color/surface-raised, color/secondary', `no-counterpart line: ${log[1]}`);
  assert(log.includes(`⚠ ${mismatchedCopiesHint(['color/error-container'])}`), 'mismatch is explained once');

  // 던지지 않았는데 들어가지 않은 덮어쓰기는 다시 읽어 드러난다.
  resyncWorld({ dropWritesTo: 'R5' });
  const dropped = await resyncOverridesByName();
  assert(dropped[0].startsWith('⚠ Blue · Overrides: 덮어쓰기 넣음 2개 (다시 읽어 확인 1)'), `read-back: ${dropped[0]}`);

  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => [{ id: 'C:blue', name: 'Blue', isExtension: false }],
    },
  };
  const empty = await resyncOverridesByName();
  assert(empty.length === 1 && empty[0].startsWith('이 파일에 확장 컬렉션이 없다'), 'no extended collection');
  console.log('collection override resync selftest: ok');
}

async function main(): Promise<void> {
  const extended: string[] = [];
  const root = { id: 'remote:color', key: 'color', name: 'Semantic Color', isExtension: false };
  const localExtension = {
    id: 'local:space',
    key: 'local-space',
    name: 'Spacing · Overrides',
    isExtension: true,
    rootVariableCollectionId: 'remote:space',
  };
  const roots = new Map([
    ['remote:space', { id: 'remote:space', key: 'space', name: 'Spacing', isExtension: false }],
  ]);
  (globalThis as any).figma = {
    teamLibrary: {
      getAvailableLibraryVariableCollectionsAsync: async () => [
        { key: 'space', name: 'Spacing', libraryName: 'CoUI' },
        { key: 'color', name: 'Semantic Color', libraryName: 'CoUI' },
      ],
    },
    variables: {
      getLocalVariableCollectionsAsync: async () => [localExtension],
      getVariableCollectionByIdAsync: async (id: string) => roots.get(id) ?? root,
      extendLibraryCollectionByKeyAsync: async (key: string, name: string) => {
        extended.push(`${key}:${name}`);
        return {};
      },
    },
  };

  const listed = await listOverrideCollections();
  assert(listed.map((x) => x.key).join(',') === 'color,space', 'stable library/name sort');
  assert(listed[0].extended === false, 'unextended collection');
  assert(listed[1].extended === true, 'existing extension detected by root key');

  const log = await createCollectionOverrides(['color', 'space', 'color']);
  assert(extended.length === 1, 'create only missing extension once');
  assert(extended[0] === `color:${extensionNameFor('Semantic Color')}`, 'extension name');
  assert(log.some((line) => line.startsWith('= 이미 생성됨')), 'idempotent log');

  let rejected = false;
  try {
    await createCollectionOverrides(['missing']);
  } catch (error) {
    rejected = String(error).includes('활성화된 라이브러리');
  }
  assert(rejected, 'reject stale/unknown keys');
  console.log('collection override selftest: ok');
  await resyncChecks();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
