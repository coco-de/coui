// Self-test for src/variant-safety.ts (#3741 completion criterion: "검증
// 코드는 실패시켜 보기 전까지 검증이 아니다"). Pure logic, no Figma runtime —
// runs under plain Node via `npm run selftest`. Exits non-zero on any
// assertion failure so it's wireable into CI without a Figma sandbox.

import {
  VariantIdentityError,
  auditVariantRenames,
  describeDuplicateVariants,
  diffVariantNames,
  findDuplicateVariantNames,
  parseVariantKey,
  verifyAppendedVariant,
  verifyLooseVariantName,
} from '../src/variant-safety';

// This script runs under plain Node (see package.json `selftest`), not the
// Figma plugin sandbox — `@types/node` isn't a dependency here, so `process`
// is declared locally rather than pulling in the whole Node type root.
declare const process: { exit(code: number): never };

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

function expectThrows(label: string, fn: () => void, errType: new (...a: never[]) => Error): void {
  check(label, () => {
    try {
      fn();
    } catch (e) {
      if (e instanceof errType) return;
      throw new Error(`threw ${e instanceof Error ? e.constructor.name : typeof e}, expected ${errType.name}`);
    }
    throw new Error('did not throw');
  });
}

console.log('parseVariantKey');
check('parses a single axis', () => {
  const got = parseVariantKey('Variant=primary');
  if (got.Variant !== 'primary') throw new Error(`got ${JSON.stringify(got)}`);
});
check('parses multiple axes', () => {
  const got = parseVariantKey('Variant=primary, Size=md');
  if (got.Variant !== 'primary' || got.Size !== 'md') throw new Error(`got ${JSON.stringify(got)}`);
});
expectThrows(
  'rejects a segment with no "="',
  () => parseVariantKey('Variant primary'),
  VariantIdentityError,
);

console.log('verifyAppendedVariant — S-b (appendChild reread)');
check('passes when variantProperties matches', () => {
  verifyAppendedVariant({ Variant: 'primary' }, 'Variant=primary', 'test');
});
expectThrows(
  'aborts on null (the exact failure mode S-b guards against)',
  () => verifyAppendedVariant(null, 'Variant=primary', 'test'),
  VariantIdentityError,
);
expectThrows(
  'aborts on a mismatched read-back',
  () => verifyAppendedVariant({ Variant: 'secondary' }, 'Variant=primary', 'test'),
  VariantIdentityError,
);

console.log('verifyLooseVariantName — the half of S-b that runs before the append');
{
  const expected = new Set(['Variant=primary', 'Variant=secondary']);
  check('a declared name passes', () => {
    verifyLooseVariantName('Variant=primary', expected, 'test');
  });
  expectThrows(
    'a flattened name (what a detach leaves) is refused before it enters the set',
    () => verifyLooseVariantName('Button/primary', expected, 'test'),
    VariantIdentityError,
  );
  expectThrows(
    'a well-formed name the builder never declared is refused too',
    () => verifyLooseVariantName('Variant=tertiary', expected, 'test'),
    VariantIdentityError,
  );
}

console.log('diffVariantNames — S-a (rename/removal detection)');
check('no diff when sets match exactly', () => {
  const d = diffVariantNames(['Variant=a', 'Variant=b'], ['Variant=a', 'Variant=b'], []);
  if (d.missing.length || d.unexplained.length) throw new Error(JSON.stringify(d));
});
check('a genuinely new variant is "missing", not "unexplained"', () => {
  const d = diffVariantNames(['Variant=a'], ['Variant=a', 'Variant=b'], []);
  if (d.missing.length !== 1 || d.missing[0] !== 'Variant=b') throw new Error(JSON.stringify(d));
  if (d.unexplained.length !== 0) throw new Error(JSON.stringify(d));
});
check('an unrecognized leftover is reported as "unexplained" (would abort mountSet)', () => {
  const d = diffVariantNames(['Variant=a', 'Variant=renamed-by-designer'], ['Variant=a'], []);
  if (d.unexplained.length !== 1 || d.unexplained[0] !== 'Variant=renamed-by-designer') {
    throw new Error(JSON.stringify(d));
  }
});
check('a documented rename source is not re-flagged as unexplained', () => {
  // In real use applyPendingVariantRenames() already renamed the node in
  // place before mountSet runs, so "Variant=old-name" would not still be in
  // existingNames. This exercises diffVariantNames() in isolation for the
  // defensive case where it somehow is (e.g. the rename pass was skipped) —
  // the known-rename list must still suppress the false alarm on its own.
  const d = diffVariantNames(
    ['Variant=a', 'Variant=old-name'],
    ['Variant=a', 'Variant=new-name'],
    [{ from: 'Variant=old-name', to: 'Variant=new-name' }],
  );
  if (d.unexplained.length !== 0) throw new Error(JSON.stringify(d));
});

// Gaining an axis — the shape VARIANT_RENAMES was reserved for and, until
// Stepper, never used. Every existing member is renamed (not removed) and new
// combinations appear alongside them, so both halves of the diff have to come
// out right: the old names must be explained by the renames, and the genuinely
// new members must be reported as missing so `mountSet` creates them.
//
// Worth its own case because the mechanism is invisible in the ordinary test
// loop: the flow deletes the page before each run, so no existing set is ever
// there to rename, and this path only runs when someone updates a file in place.
check('gaining an axis renames every existing member and adds the rest', () => {
  const renames = [
    { from: 'Disabled=false', to: 'Layout=horizontal, Disabled=false' },
    { from: 'Disabled=true', to: 'Layout=horizontal, Disabled=true' },
  ];
  const wanted = [
    'Layout=horizontal, Disabled=false',
    'Layout=horizontal, Disabled=true',
    'Layout=vertical, Disabled=false',
    'Layout=vertical, Disabled=true',
  ];
  const d = diffVariantNames(['Disabled=false', 'Disabled=true'], wanted, renames);
  if (d.unexplained.length !== 0) {
    throw new Error(`old members unexplained: ${JSON.stringify(d.unexplained)}`);
  }
  // All four are "missing" pre-rename; what matters is that the two NEW ones are
  // in there, since those are what mountSet has to create.
  for (const n of ['Layout=vertical, Disabled=false', 'Layout=vertical, Disabled=true']) {
    if (!d.missing.includes(n)) throw new Error(`new member not requested: ${n}`);
  }
});

// The same diff with the renames dropped must FAIL — otherwise the case above
// passes for a reason unrelated to the rename table, and the entries could be
// deleted without any test noticing.
check('without the rename entries the same axis gain is refused', () => {
  const d = diffVariantNames(
    ['Disabled=false', 'Disabled=true'],
    ['Layout=horizontal, Disabled=false', 'Layout=horizontal, Disabled=true'],
    [],
  );
  if (d.unexplained.length !== 2) {
    throw new Error(`expected both old members unexplained, got ${JSON.stringify(d)}`);
  }
});

// auditVariantRenames — is the TABLE complete for the members a builder makes?
//
// The case above proves the diff behaves once the entries exist. Nothing proved
// they all exist, and that is the half a person writes by hand: an axis gain on
// `Variant × Size × Disabled` owes 24 entries, and 23 of them look exactly like
// 24 to every other signal in this repo. The generation walk is exercised here;
// the real tables are audited against real member lists in
// scripts/selftest-registry-runtime.ts, which is the only place that has both.
console.log('auditVariantRenames — table completeness');

// One gain, fully explained: Size × Ring, five old `Size=` members.
const ringMembers = ['xs', 'sm', 'md'].flatMap((z) => [
  `Size=${z}, Ring=false`,
  `Size=${z}, Ring=true`,
]);
const ringRenames = ['xs', 'sm', 'md'].map((z) => ({
  from: `Size=${z}`,
  to: `Size=${z}, Ring=false`,
}));
check('a complete generation reports nothing', () => {
  const a = auditVariantRenames(ringMembers, ringRenames);
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});
check('a missing entry is named, not merely counted', () => {
  const a = auditVariantRenames(ringMembers, ringRenames.slice(0, 2));
  if (a.unexplained.length !== 1 || a.unexplained[0] !== 'Size=md') {
    throw new Error(JSON.stringify(a));
  }
});
check('an entry pointing at a name the builder does not produce is dangling', () => {
  const a = auditVariantRenames(ringMembers, [{ from: 'Size=md', to: 'Size=md, Ring=nope' }]);
  if (a.dangling.length !== 1) throw new Error(JSON.stringify(a));
});

// Two gains on one set, which is TextField's shape: an older generation whose
// `to` is not a member at all but the `from` of the newer one. A walk that
// compared every entry against the member list would call all of gen-1 dangling.
check('a two-hop chain is read as a chain, not as six dangling entries', () => {
  const members = ['a', 'b'].flatMap((v) =>
    ['false', 'true'].flatMap((d) => [
      `V=${v}, D=${d}, F=false`,
      `V=${v}, D=${d}, F=true`,
    ]),
  );
  const gen1 = ['a', 'b'].map((v) => ({ from: `V=${v}`, to: `V=${v}, D=false` }));
  const gen2 = ['a', 'b'].flatMap((v) =>
    ['false', 'true'].map((d) => ({ from: `V=${v}, D=${d}`, to: `V=${v}, D=${d}, F=false` })),
  );
  const a = auditVariantRenames(members, gen1.concat(gen2));
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});

// A third gain on the same set — TextField's shape again once its two booleans
// fold onto one `S=` enum. Neither gen-1 nor gen-2 `to` is a member any more;
// only gen-3 lands, and one gen-2 name (`D=true, F=true`) has no gen-3 row at
// all because the ladder never renders it. A walk that only tolerated one
// intermediate name would call gen-1 dangling here.
check('a three-hop chain is read as a chain, not as dangling', () => {
  const members = ['a', 'b'].flatMap((v) =>
    ['enabled', 'focus', 'disabled'].map((s) => `V=${v}, S=${s}`),
  );
  const gen1 = ['a', 'b'].map((v) => ({ from: `V=${v}`, to: `V=${v}, D=false` }));
  const gen2 = ['a', 'b'].flatMap((v) =>
    ['false', 'true'].map((d) => ({ from: `V=${v}, D=${d}`, to: `V=${v}, D=${d}, F=false` })),
  );
  const gen3 = ['a', 'b'].flatMap((v) => [
    { from: `V=${v}, D=false, F=false`, to: `V=${v}, S=enabled` },
    { from: `V=${v}, D=false, F=true`, to: `V=${v}, S=focus` },
    { from: `V=${v}, D=true, F=false`, to: `V=${v}, S=disabled` },
  ]);
  const a = auditVariantRenames(members, gen1.concat(gen2, gen3));
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});

// Axis order is the SET's, not alphabetical. Projecting sorted made every
// `Variant=…, Disabled=…` entry read as missing and named the six that were
// already there — a false alarm is as useless as a missed one, and this shape
// (a later axis sorting before an earlier one) is the one that produced it.
check('projection follows the entry’s axis order, not alphabetical order', () => {
  const members = ['filled', 'ghost'].flatMap((v) =>
    ['sm', 'md'].flatMap((z) =>
      ['false', 'true'].map((d) => `Variant=${v}, Size=${z}, Disabled=${d}`),
    ),
  );
  const renames = ['filled', 'ghost'].flatMap((v) =>
    ['false', 'true'].map((d) => ({
      from: `Variant=${v}, Disabled=${d}`,
      to: `Variant=${v}, Size=md, Disabled=${d}`,
    })),
  );
  const a = auditVariantRenames(members, renames);
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});

// An axis REPLACEMENT drops the old axis, so there is nothing left to project
// onto and no way to enumerate what the table owes. It must say so rather than
// pass quietly — a check that declines is not a check that agreed.
check('an axis replacement is reported as undecidable, not as complete', () => {
  const a = auditVariantRenames(
    ['Disabled=false, Error=false', 'Disabled=false, Error=true'],
    [{ from: 'Variant=Default', to: 'Disabled=false, Error=false' }],
  );
  if (a.unprojectable.length !== 1) throw new Error(JSON.stringify(a));
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});

// A PARTIAL replacement — one axis of the generation survives and one does not.
// The earlier test asked whether ANY axis survived, so this passed it and then
// demanded rows for `Selected=false` / `Selected=true`: half-names, which no
// generation ever had. Half a projection is not a projection.
check('a partial axis replacement declines rather than demanding half-names', () => {
  const a = auditVariantRenames(
    ['Enabled=true, Selected=false, Hover=false', 'Enabled=true, Selected=true, Hover=false'],
    [
      { from: 'Selected=false, Disabled=false', to: 'Enabled=true, Selected=false, Hover=false' },
      { from: 'Selected=true, Disabled=false', to: 'Enabled=true, Selected=true, Hover=false' },
    ],
  );
  if (a.unprojectable.length !== 1) throw new Error(JSON.stringify(a));
  if (a.unexplained.length) throw new Error(JSON.stringify(a));
});

// A VALUE rename on a surviving axis. Projection puts the NEW value in the OLD
// frame and asks for a name that never existed — `State=checked` where the page
// had `State=Checked`. Nothing to enumerate, so it declines.
check('a value rename declines rather than demanding the new spelling', () => {
  const a = auditVariantRenames(
    ['Size=md, State=checked, Enabled=true', 'Size=md, State=unchecked, Enabled=true'],
    [
      { from: 'State=Checked', to: 'Size=md, State=checked, Enabled=true' },
      { from: 'State=Unchecked', to: 'Size=md, State=unchecked, Enabled=true' },
    ],
  );
  if (a.unprojectable.length !== 1) throw new Error(JSON.stringify(a));
  if (a.unexplained.length) throw new Error(JSON.stringify(a));
});

// An axis REORDER — same axes, different order — gains nothing, so every current
// member projects to a well-formed old-frame name, the ones this run minted
// included. Demanding rows for those asks the table to explain members the page
// never had; the old set was sparse, not the table half-written. It declines,
// and leaves the half-written case to S-a on the page, which still sees an old
// name that no row moved.
check('a same-axis reorder declines rather than demanding rows for minted members', () => {
  const a = auditVariantRenames(
    ['Size=md, State=enabled, Open=false', 'Size=md, State=hover, Open=false'],
    [{ from: 'Size=md, Open=false, State=enabled', to: 'Size=md, State=enabled, Open=false' }],
  );
  if (a.unprojectable.length !== 1) throw new Error(JSON.stringify(a));
  if (a.unexplained.length || a.dangling.length) throw new Error(JSON.stringify(a));
});

// A pure axis GAIN with values left alone is the one shape projection CAN
// reconstruct, so it must still enumerate — this is the half-written table the
// audit exists for, and the row it named on its first real run (`Avatar`'s sixth
// size) was genuinely missing.
check('a pure axis gain still enumerates the row a table is missing', () => {
  const a = auditVariantRenames(
    ['Size=sm, Ring=false', 'Size=md, Ring=false', 'Size=lg, Ring=false'],
    [
      { from: 'Size=sm', to: 'Size=sm, Ring=false' },
      { from: 'Size=md', to: 'Size=md, Ring=false' },
    ],
  );
  if (a.unprojectable.length) throw new Error(JSON.stringify(a));
  if (a.unexplained.join() !== 'Size=lg') throw new Error(JSON.stringify(a));
});

// A `to` may point straight at a member from ANY generation's frame. The table
// does not chain — every row names a final member — and comparing against the
// previous generation's sources instead accused 38 rows of renaming to names the
// builder produces.
check('a flat table’s older generation is not reported as dangling', () => {
  const members = ['Size=md, Enabled=true', 'Size=md, Enabled=false'];
  const a = auditVariantRenames(members, [
    { from: 'Variant=Default, Size=md', to: 'Size=md, Enabled=true' },
    { from: 'Variant=Default', to: 'Size=md, Enabled=true' },
  ]);
  if (a.dangling.length) throw new Error(JSON.stringify(a));
});

// …and a `to` nobody produces and nobody picks up is STILL dangling, which is
// what a typo'd `to` looks like.
check('a to nobody produces is still dangling', () => {
  const a = auditVariantRenames(['Size=md, Enabled=true'], [
    { from: 'Size=md', to: 'Size=md, Enabled=ture' },
  ]);
  if (a.dangling.length !== 1) throw new Error(JSON.stringify(a));
});

console.log('findDuplicateVariantNames — the state that makes a set unreadable');
check('a set where every name is claimed once reports nothing', () => {
  const got = findDuplicateVariantNames([
    'Variant=primary, Size=md',
    'Variant=primary, Size=lg',
    'Variant=secondary, Size=md',
  ]);
  if (got.length !== 0) throw new Error(JSON.stringify(got));
});

check('a name claimed twice is reported with its count', () => {
  const got = findDuplicateVariantNames([
    'Variant=primary, Size=md',
    'Variant=primary, Size=lg',
    'Variant=primary, Size=md',
  ]);
  if (got.length !== 1) throw new Error(JSON.stringify(got));
  if (got[0].name !== 'Variant=primary, Size=md') throw new Error(JSON.stringify(got));
  if (got[0].count !== 2) throw new Error(JSON.stringify(got));
});

// Three copies is one duplicated NAME and two surplus members — the two
// numbers differ, and the message reports the second because that is how many
// nodes someone has to look at.
check('three copies of one name is one entry with count 3', () => {
  const got = findDuplicateVariantNames(['A=1', 'A=1', 'A=1']);
  if (got.length !== 1 || got[0].count !== 3) throw new Error(JSON.stringify(got));
});

// The shape this guard was written for: a full second generation of a set,
// which is what Badge carried — 96 names, each claimed twice.
check('a whole duplicated generation reports every name once', () => {
  const names: string[] = [];
  for (const v of ['primary', 'secondary']) {
    for (const size of ['xs', 'sm', 'md']) names.push(`Variant=${v}, Size=${size}`);
  }
  const got = findDuplicateVariantNames([...names, ...names]);
  if (got.length !== 6) throw new Error(String(got.length));
  if (got.some((d) => d.count !== 2)) throw new Error(JSON.stringify(got));
});

console.log('describeDuplicateVariants');
check('the message names the set, the surplus count and an example', () => {
  const msg = describeDuplicateVariants('Badge', [
    { name: 'Variant=primary, Size=md', count: 2 },
    { name: 'Variant=primary, Size=lg', count: 2 },
  ]);
  if (!msg.includes('Badge')) throw new Error(msg);
  if (!msg.includes('2 surplus member(s)')) throw new Error(msg);
  if (!msg.includes('Variant=primary, Size=md')) throw new Error(msg);
});

// Deliberately not actionable-by-deletion: the two copies are rarely
// interchangeable (instances pin one of them), so a message that told the
// reader which to remove would be guessing on their behalf — the exact thing
// the rest of this module refuses to do.
check('the message does not pick a copy to delete', () => {
  const msg = describeDuplicateVariants('Badge', [{ name: 'A=1', count: 2 }]);
  if (/delete the (newer|older|second|first|last)/i.test(msg)) throw new Error(msg);
  if (!msg.includes('by hand')) throw new Error(msg);
});

if (failures > 0) {
  console.error(`\n${failures} failure(s).`);
  process.exit(1);
}
console.log('\nAll variant-safety self-tests passed.');
