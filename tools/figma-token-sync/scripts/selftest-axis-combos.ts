// #4033 (C1) — drives src/axis-combos.ts against the REAL components.json
// (same no-fixture reasoning as the other selftests: the interesting claims
// are about this repo's actual axes). BDD anchors:
//   "Button 108 조합" — 9 canvas variants × 6 sizes × enabled 2, variant
//   slowest. The enum has 12; `text` and `fixed` are `hidden`, not members.
//   "Checkbox — disabled×checked 소실 금지" — State and Enabled are separate
//   axes, so `State=checked, Enabled=false` exists (the flattening the old
//   hand-written builder did is unrepresentable through this enumerator).
import {
  enumerateAxisAssignments,
  axisSpecsOf,
  axisValueOf,
  composeVariantName,
  enumerateAxisCombos,
  isAxisAtRest,
  kAxisOrder,
  restingValueOf,
  ComponentAxesJson,
  distinctSizeCells,
  sizeRowFor,
} from '../src/axis-combos';
import componentsJson from '../src/data/components.json';

// Runs under plain Node — no `@types/node`, so `process` is declared
// locally (same pattern as the other selftests).
declare const process: { exit(code: number): never };

let failures = 0;
function check(label: string, cond: boolean, detail?: string): void {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    failures++;
    console.error(`  ✗ ${label}${detail ? ` — ${detail}` : ''}`);
  }
}

const components = componentsJson.components as Record<
  string,
  { axes: ComponentAxesJson }
>;

const kV3Axes = ['Variant', 'Size', 'State', 'Enabled'];

console.log('axis order (T-16)');
// The invariant is that the four schema-v3 axes come in that order, ahead of
// every pose axis — not that they are the only ones. Pinning the whole array to
// a four-name string made this assertion fail the moment pose axes were added,
// and because `npm run selftest` is an `&&` chain with this script third, that
// failure took the registry-runtime and fidelity harnesses down with it: the two
// heaviest checks in the project stopped running in CI while the stale assertion
// was the only thing wrong.
//
// `Color` is the one axis allowed to lead them. It is a design axis, not a pose
// (the colour a Chip takes on when selected), and a Chip member has always been
// spelled colour-first. The exception is as narrow as the claim: exactly one
// axis, named, at index 0 — a second axis ahead of the four still fails.
check(
  'the four v3 axes come in declaration order, behind the one design axis that may lead them',
  kAxisOrder.slice(0, 5).join(',') === 'Color,Variant,Size,State,Enabled',
  kAxisOrder.slice(0, 5).join(','),
);
check(
  'pose axes come after the four (a pose qualifies a variant, not the reverse)',
  kAxisOrder.length > 5 && !kAxisOrder.slice(5).some((a) => kV3Axes.includes(a)),
  `${kAxisOrder.length - 5} axis/axes after index 4`,
);
let threw = false;
try {
  composeVariantName([
    ['Size', 'md'],
    ['Variant', 'primary'],
  ]);
} catch {
  threw = true;
}
check('out-of-order assignment throws (no silent re-sort)', threw);

console.log('Button — the seed spec arithmetic');
const buttonCombos = enumerateAxisCombos(axisSpecsOf(components.button.axes));
// 9, not the enum's 10: `fixed` (@behaviourOnly) is read off the canvas at the
// exporter and lands in `hidden` instead.
check('9 × 6 × 2 = 108 combos', buttonCombos.length === 108, `got ${buttonCombos.length}`);
check(
  'variant varies slowest (first 12 are Variant=primary)',
  buttonCombos.slice(0, 12).every((c) => c.indexOf('Variant=primary, ') === 0),
);
check(
  'first combo spelling is canonical',
  buttonCombos[0] === 'Variant=primary, Size=xs, Enabled=true',
  buttonCombos[0],
);

console.log('Checkbox — the schema states two axes, the builder three; disabled×checked must exist');
// The checkbox's value is a tristate `bool?`, not an enum the reader could
// promote, so `axes` carries only Size and Enabled — the builder declares
// State (five rungs) and Checked (three) for itself, the way Chip does. The
// flattening the old hand-written builder did — no disabled checked pose —
// is what the third axis keeps unrepresentable.
const checkboxSchemaCombos = enumerateAxisCombos(axisSpecsOf(components.checkbox.axes));
check('schema: 6 × 2 = 12 (State is not an axis the reader promotes)', checkboxSchemaCombos.length === 12, `got ${checkboxSchemaCombos.length}`);
check(
  'schema: no `State=` — the builder declares that axis, not the reader',
  checkboxSchemaCombos.every((c) => c.indexOf('State=') < 0),
);
const checkboxCombos = enumerateAxisCombos([
  { axis: 'Size', values: Object.keys(componentsJson.components.checkbox.sizes.defaultsBySize) },
  { axis: 'State', values: ['enabled', 'hover', 'focus', 'pressed', 'disabled'] },
  { axis: 'Checked', values: ['false', 'true', 'indeterminate'] },
]);
check('builder: 6 × 5 × 3 = 90 combos', checkboxCombos.length === 90, `got ${checkboxCombos.length}`);
check(
  'State=disabled, Checked=true combo exists (no flattening)',
  checkboxCombos.some((c) => c.indexOf('State=disabled') >= 0 && c.indexOf('Checked=true') >= 0),
);
check(
  'Checked sits after State in the canonical order',
  checkboxCombos[0] === 'Size=xs, State=enabled, Checked=false',
  checkboxCombos[0],
);

console.log('Tabs — variant axis via the naming-exception entry');
const tabsCombos = enumerateAxisCombos(axisSpecsOf(components.tabs.axes));
check(
  'pill and underline both enumerate (the gap this project exists to close)',
  tabsCombos.some((c) => c.indexOf('Variant=pill') >= 0) &&
    tabsCombos.some((c) => c.indexOf('Variant=underline') >= 0),
);

console.log('axis-free component');
const gapCombos = enumerateAxisCombos(axisSpecsOf(components.gap.axes));
check('gap enumerates to zero combos (stays a single COMPONENT)', gapCombos.length === 0);


console.log('enumerateAxisAssignments — one enumeration, both halves');
{
  const specs = [
    { axis: 'Variant' as const, values: ['outlined', 'filled'] },
    { axis: 'Disabled' as const, values: ['false', 'true'] },
  ];
  const names = enumerateAxisCombos(specs);
  const assigns = enumerateAxisAssignments(specs);
  check(
    'names match enumerateAxisCombos exactly (switching a builder moves no member)',
    assigns.map((a) => a.name).join('|') === names.join('|'),
    assigns.map((a) => a.name).join('|'),
  );
  check(
    'values round-trip to the name they produced',
    assigns.every((a) => a.name === `Variant=${a.values.Variant}, Disabled=${a.values.Disabled}`),
  );
  check('empty specs enumerate to nothing', enumerateAxisAssignments([]).length === 0);
}

// ─── Rest, and the `State=` fold ─────────────────────────────────────────────
//
// Both of these used to be spelled per-file as "which boolean means off". They
// were moved here when a state axis stopped being a boolean, and these cases
// are what that move has to keep true. The pair that matters most is the last
// two: read raw, a `State=`-only member answers NOTHING for `Enabled`, and the
// coverage check that holds the schema's axis list scores a fully-covered set
// at zero.
console.log('rest, and the State fold');
{
  check('a pose axis rests at false', restingValueOf('Hover') === 'false');
  check(
    'Enabled rests at true (the axis spelled the other way round)',
    restingValueOf('Enabled') === 'true',
  );
  check('State rests at enabled', restingValueOf('State') === 'enabled');
  check('an axis nobody named still rests at false', restingValueOf('Whatever') === 'false');

  check('State=enabled is at rest', isAxisAtRest('State', 'enabled'));
  // The bug the table replaced: a counter reading "away = value === 'true'"
  // scored `State=hover` and `State=enabled` the same, so a sort that broke
  // ties on axis-distance could hand a parent a PRE-HOVERED child.
  check('State=hover is NOT at rest', !isAxisAtRest('State', 'hover'));
  check('State=disabled is NOT at rest', !isAxisAtRest('State', 'disabled'));
  check('Enabled=false is NOT at rest', !isAxisAtRest('Enabled', 'false'));

  check(
    'a named axis reads straight off the member',
    axisValueOf({ Variant: 'primary', State: 'hover' }, 'Variant') === 'primary',
  );
  check(
    'State=disabled folds to Enabled=false',
    axisValueOf({ State: 'disabled' }, 'Enabled') === 'false',
  );
  check(
    'every other rung folds to Enabled=true (a hovered button is an enabled one)',
    ['enabled', 'hover', 'focus', 'pressed', 'selected'].every(
      (state) => axisValueOf({ State: state }, 'Enabled') === 'true',
    ),
  );
  check(
    'the fold is one-way — Enabled says nothing about which rung',
    axisValueOf({ Enabled: 'true' }, 'State') === undefined,
  );
  check(
    'a member naming both is read directly, not folded',
    axisValueOf({ Enabled: 'false', State: 'hover' }, 'Enabled') === 'false',
  );
  check(
    'an axis the member does not carry is undefined, not guessed',
    axisValueOf({ Variant: 'primary' }, 'Size') === undefined,
  );
}

// ─── 크기 단계 결정 (2026-10-01) — a Size cell draws the row the app renders ──
//
// `sizeRowFor` is the canvas's copy of `resolveSizeRow`; these pin it to the
// Dart behaviour on the real tables, and pin the two-cell FormLabel/Fieldset
// shape to the rows rather than to a typed list.
{
  console.log('\nsizeRowFor / distinctSizeCells');
  const data = componentsJson.components as unknown as Record<
    string,
    {
      axes: ComponentAxesJson;
      sizes: { defaultsBySize?: Record<string, unknown> };
      constants: { size?: { choice: string } };
    }
  >;
  const rowsOf = (slug: string) =>
    new Map(Object.entries(data[slug].sizes.defaultsBySize ?? {}));
  const ladderOf = (slug: string) => data[slug].axes.size?.members ?? [];

  // A stated size is its own row — for every tier of a full ladder.
  const button = rowsOf('button');
  check(
    'Button — every stated tier comes back as its own row',
    ladderOf('button').every((size) => sizeRowFor(button, size, ladderOf('button')) === button.get(size)),
  );

  // Badge states its own xl2 row.
  const badge = rowsOf('badge');
  check(
    'Badge xl2 is its own row',
    sizeRowFor(badge, 'xl2', ladderOf('badge')) === badge.get('xl2'),
  );

  // A ladder without its top row draws the nearest row BELOW, not md.
  const badgeWithoutXl2 = new Map([...badge].filter(([size]) => size !== 'xl2'));
  check(
    'a ladder without xl2 — xl2 draws the xl row (nearest below), not md',
    sizeRowFor(badgeWithoutXl2, 'xl2', ladderOf('badge')) === badgeWithoutXl2.get('xl'),
  );

  // Avatar's diameters (and initials roles) are the code's table, xl2 included.
  const avatar = rowsOf('avatar') as Map<string, { diameter: { v: number } }>;
  check(
    'Avatar xl2 is a stated 96',
    sizeRowFor(avatar, 'xl2', ladderOf('avatar')).diameter.v === 96,
    `got ${JSON.stringify(sizeRowFor(avatar, 'xl2', ladderOf('avatar')))}`,
  );

  // The cohort-E end state: a field ladder without xs draws sm at xs.
  for (const slug of ['text_field', 'text_area']) {
    const withoutXs = new Map([...rowsOf(slug)].filter(([size]) => size !== 'xs'));
    check(
      `${slug} without its xs row — xs draws the sm row (smallest), not md`,
      sizeRowFor(withoutXs, 'xs', ladderOf(slug)) === withoutXs.get('sm'),
    );
  }

  // Middle gap reaches DOWN.
  const gappy = new Map([['sm', 'sm'], ['md', 'md'], ['xl', 'xl']]);
  const ladder = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'];
  check('an unstated middle size reaches down (lg → md)', sizeRowFor(gappy, 'lg', ladder) === 'md');
  check('a size above the ladder takes its top (xl2 → xl)', sizeRowFor(gappy, 'xl2', ladder) === 'xl');
  check('a size below the ladder takes its smallest (xs → sm)', sizeRowFor(gappy, 'xs', ladder) === 'sm');
  let threw = false;
  try {
    sizeRowFor(new Map<string, string>(), 'md', ladder);
  } catch {
    threw = true;
  }
  check('an empty table throws (it failed to export)', threw);

  // FormLabel / Fieldset: two pictures → two cells, named md · lg.
  for (const slug of ['form_label', 'fieldset']) {
    const cells = distinctSizeCells(
      rowsOf(slug),
      ladderOf(slug),
      data[slug].constants.size?.choice ?? '',
    );
    check(
      `${slug} draws md · lg`,
      cells.cells.join(',') === 'md,lg',
      `got ${cells.cells.join(',')}`,
    );
    check(
      `${slug} — xs/sm/md find md, lg/xl/xl2 find lg`,
      ['xs', 'sm', 'md'].every((size) => cells.cellFor(size) === 'md') &&
        ['lg', 'xl', 'xl2'].every((size) => cells.cellFor(size) === 'lg'),
    );
    check(
      `${slug} — each cell shows the row the app renders for every size it stands for`,
      ladderOf(slug).every(
        (size) =>
          JSON.stringify(sizeRowFor(rowsOf(slug), cells.cellFor(size), ladderOf(slug))) ===
          JSON.stringify(sizeRowFor(rowsOf(slug), size, ladderOf(slug))),
      ),
    );
  }

  // A ladder whose rows are all distinct keeps every cell.
  const buttonCells = distinctSizeCells(button, ladderOf('button'), 'md');
  check(
    'distinct rows keep all six cells',
    buttonCells.cells.length === ladderOf('button').length,
    `got ${buttonCells.cells.join(',')}`,
  );

  // Ties go down: a group {sm, lg} around md is named sm.
  const tie = distinctSizeCells(
    new Map([['sm', 'a'], ['md', 'b'], ['lg', 'a']]),
    ['sm', 'md', 'lg'],
    'md',
  );
  check('a tie in distance keeps the lower step', tie.cellFor('lg') === 'sm', `got ${tie.cellFor('lg')}`);
}

if (failures > 0) {
  console.error(`\n${failures} axis-combos self-test(s) failed.`);
  process.exit(1);
}
console.log('\nAll axis-combos self-tests passed.');
