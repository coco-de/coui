/// <reference types="@figma/plugin-typings" />

import { composeVariantName, type AxisName } from './axis-combos';

// Controlled, intentional identity-preserving renames (#3741 scaffold,
// populated by #3742). Renames are never auto-detected — a mismatch that
// isn't listed here is a signal to STOP (see src/variant-safety.ts), not to
// guess. Applying a listed rename is idempotent: once the live node carries
// the new name, `find` on the old name finds nothing and the entry is a
// silent no-op on every later run.

export interface SetRename {
  /** Current on-page name (what a leftover run may still show). */
  from: string;
  /** REGISTRY name this run's builder now produces. */
  to: string;
  reason: string;
}

// Component/component-set level renames — set once, apply in place before
// mint-by-name looks anything up by name.
export const SET_RENAMES: SetRename[] = [
  {
    from: 'Input',
    to: 'TextField',
    reason: '#3742 — code class is CoreTextFieldStyle/TextField; exporter’s `input` JSON key already read it.',
  },
  {
    from: 'Radio',
    to: 'RadioGroup',
    reason: '#3742 — no standalone `Radio` class exists in coui_core; the real class is `RadioGroup`.',
  },
  {
    from: 'InputOTP',
    to: 'InputOtp',
    reason: "#3745 (G2 parity guard) — the coui_flutter class is `InputOtp` (Dart's Effective Dart style treats acronyms as regular words), not `InputOTP`.",
  },
  {
    from: 'MockupPhone',
    to: 'MockupDevice',
    reason:
      'the code class is `MockupDevice` (`CoreMockupDeviceStyle`, since 0.141/0.143) — the phone became one value of a `Device` axis ' +
      'beside `tablet`, so the loose `MockupPhone` COMPONENT is renamed in place and then adopted as the `Device=phone` member by ' +
      '`buildMockupDevice`\'s `adoptLooseAs`, keeping its key and every consuming instance.',
  },
  {
    from: 'HeroSection',
    to: 'Hero',
    reason:
      'the public block is `Hero` (`CoreHeroStyle`, since 0.146) — `HeroSection` was the component name. ' +
      'Renamed in place before the COMPONENT → COMPONENT_SET migration so the centred node is the one ' +
      '`STRUCTURAL_MIGRATIONS` removes and `buildHero` rebuilds as `Layout=center`.',
  },
  {
    from: 'Tab',
    to: 'TabItem',
    reason:
      'the code class is `CoreTabItem` (Flutter-first naming, the way `NavigationBarItem` is named after `CoreNavigationBarItem`); ' +
      'renamed in place so the designer’s sixteen member keys survive. The six instances inside every `Tabs` member are builder-owned ' +
      'content — `buildTabs` resets each member and mints them again against these keys, so nothing in another file detaches.',
  },
];

export interface VariantRename {
  /** The set's CURRENT name (post SET_RENAMES, if any) — not the old one. */
  component: string;
  from: string;
  to: string;
  reason: string;
}

// The Chip canvas → builder rows, generated rather than typed out.
//
// `applyPendingVariantRenames` matches `child.name === r.from` verbatim, so every
// row has to be a concrete name — and a live set carries 192 of them, in one of
// three older spellings: the two below, and the pre-`Shape` generation that
// `chipShapeRows` renames. Each lands on the member the builder mints NOW, one
// hop (a table does not chain; see `auditVariantRenames`):
//
//   designer  `Color=<c>, Size=<s>, Selected=<no|yes>, Emphasis=<e>, State=<st>`
//             — the canvas the designer drew, before the builder owned the set.
//   builder   `Variant=<c>, Size=<s>, State=<st>, Selected=<true|false>,
//             Emphasis=<e>` — the previous builder: the colour enum drawn as
//             `Variant`, every other axis in `kAxisOrder`.
//   now       `Color=<c>, Variant=outlined, Size=<s>, State=<st>,
//             Selected=<true|false>, Emphasis=<e>, Shape=rounded` — the colour
//             is `Color`, `Variant` is the contract's own `CoreChipVariant`,
//             and `Shape` its `CoreChipShape` (see `chipShapeRows`).
//
// Which colours survive: `CoreChipColor` keeps `neutral` and `primary`. The
// 96 members of `secondary` and `tertiary` have no destination — the enum value
// is gone, so there is no `Color=secondary` for them to become — and are listed
// in `RETIRED_VARIANTS` (`chipRetiredColourRows`) instead. A table row is a
// rename that keeps a key; the two colours' keys are the ones being given up,
// on purpose and by name.
//
// Where the old members land on `Variant`: all of them on `outlined`. Every
// pose the old set drew — resting, selected, disabled — was the outlined look;
// `filled` did not exist, so it is a member to ADD, not one to rename onto.
// And on `Shape`: all of them on `rounded`, the size row's corner every old
// member drew; `pill` did not exist either.
//
// Enumerated in the old canvas's own axis order so a reader can check the
// product against the file, and a bijection within each generation — distinct
// `from`s, distinct `to`s, every `to` a member the builder now produces. Across
// generations a `to` repeats (a designer row, a builder row and a pre-`Shape`
// row can name the same member); a canvas carries one generation at a time, so
// no two rows ever claim one member on the same set. Composed through
// `composeVariantName` so a `to` cannot drift from the name
// `enumerateAxisAssignments` mints for the same pose.
const kChipColours = ['neutral', 'primary', 'secondary', 'tertiary'] as const;
// `CoreChipColor` values that no longer exist. Anything not listed here is a
// colour the builder still draws.
const kChipRetiredColours: readonly string[] = ['secondary', 'tertiary'];
// The look every pre-`Variant` member drew (see above).
const kChipLegacyVariant = 'outlined';
// The outline every pre-`Shape` member drew — `CoreChipShape.defaultShape`, the
// size row's corner (see `chipShapeRows`).
const kChipLegacyShape = 'rounded';

interface ChipCanvasPose {
  readonly colour: (typeof kChipColours)[number];
  /** The older spelling the designer's canvas used. */
  readonly designer: string;
  /** The spelling the previous builder minted. */
  readonly builder: string;
  /** The spelling the builder mints now — only meaningful for a kept colour. */
  readonly now: string;
}

/** 캔버스가 실제로 들고 있던 192 이름과 각자의 목적지 pose. */
function chipCanvasPoses(): ChipCanvasPose[] {
  const sizes = ['sm', 'md', 'lg'] as const;
  const selected = ['no', 'yes'] as const;
  const emphases = ['low', 'high'] as const;
  const states = ['enabled', 'hover', 'pressed', 'disabled'] as const;
  const poses: ChipCanvasPose[] = [];
  for (const c of kChipColours) {
    for (const s of sizes) {
      for (const sel of selected) {
        for (const e of emphases) {
          for (const st of states) {
            const selectedValue = sel === 'yes' ? 'true' : 'false';
            poses.push({
              colour: c,
              designer: `Color=${c}, Size=${s}, Selected=${sel}, Emphasis=${e}, State=${st}`,
              builder: composeVariantName([
                ['Variant', c],
                ['Size', s],
                ['State', st],
                ['Selected', selectedValue],
                ['Emphasis', e],
              ]),
              now: composeVariantName([
                ['Color', c],
                ['Variant', kChipLegacyVariant],
                ['Size', s],
                ['State', st],
                ['Selected', selectedValue],
                ['Emphasis', e],
                ['Shape', kChipLegacyShape],
              ]),
            });
          }
        }
      }
    }
  }
  return poses;
}

function chipCanvasRows(): VariantRename[] {
  // 192 중 살아남는 색(neutral · primary)의 96 × 두 세대 = 192 행. 옛 이름 하나가
  // 새 이름 하나로 간다.
  const rows: VariantRename[] = [];
  for (const p of chipCanvasPoses()) {
    if (kChipRetiredColours.includes(p.colour)) continue;
    rows.push(
      {
        component: 'Chip',
        from: p.designer,
        to: p.now,
        reason:
          '축 이행 — 캔버스의 Color 축은 그대로 Color 로 남고, Selected 의 yes/no 는 '
          + 'true/false 로 철자가 바뀌며, State 가 빌더 순서로 들어가고, 계약의 '
          + '`variant`(CoreChipVariant)가 새 `Variant` 축으로, `shape`(CoreChipShape)가 '
          + '새 `Shape` 축으로 들어온다 — 옛 멤버는 전부 outlined · rounded 를 그렸으므로 '
          + '거기로 간다',
      },
      {
        component: 'Chip',
        from: p.builder,
        to: p.now,
        reason:
          '축 이행(#5415 · #5423 · #5630) — 색 축의 이름이 `Variant` 에서 `Color` 로 바뀌고 '
          + '`Variant` 는 계약의 `CoreChipVariant`(outlined · filled)가, `Shape` 는 '
          + '`CoreChipShape`(rounded · pill)가 된다. 옛 멤버는 전부 outlined · rounded 를 '
          + '그렸으므로 거기로 간다',
      },
    );
  }
  return rows;
}

// The Chip rows for the `Shape` axis (#5630) — the generation the builder
// minted just before it: `Color=<c>, Variant=<v>, Size=<s>, State=<st>,
// Selected=<true|false>, Emphasis=<e>`. Every one of those members drew the
// size row's corner, so each keeps its key as the `Shape=rounded` member of the
// same pose; the `pill` members are new and have nothing to rename from. Same
// shape as `avatarShapeRows`, composed through `composeVariantName` so a `to`
// cannot drift from the name `enumerateAxisAssignments` mints.
//
// The axis values are written out rather than read off the builder: this table
// names what WAS on the canvas, so it has to keep that generation's values on
// the day the builder's values change.
const kChipShapeEraColours = ['neutral', 'primary'] as const;
const kChipShapeEraVariants = ['outlined', 'filled'] as const;

function chipShapeRows(): VariantRename[] {
  const reason =
    'Chip 모양 축(#5630) — `CoreChipShape`(rounded | pill)가 생겨 `Shape` 축이 `Emphasis` 뒤에 '
    + '들어간다. 지금까지의 멤버는 모두 크기 행의 모서리(6 · 8 · 10)를 그렸으므로 같은 '
    + '포즈의 `Shape=rounded` 멤버로 개명되어 key 가 유지된다. `pill` 멤버는 새로 만든다.';
  const rows: VariantRename[] = [];
  for (const c of kChipShapeEraColours) {
    for (const v of kChipShapeEraVariants) {
      for (const s of ['sm', 'md', 'lg']) {
        for (const st of ['enabled', 'hover', 'pressed', 'disabled']) {
          for (const sel of ['false', 'true']) {
            for (const e of ['low', 'high']) {
              const pose: [AxisName, string][] = [
                ['Color', c],
                ['Variant', v],
                ['Size', s],
                ['State', st],
                ['Selected', sel],
                ['Emphasis', e],
              ];
              rows.push({
                component: 'Chip',
                from: composeVariantName(pose),
                to: composeVariantName([...pose, ['Shape', kChipLegacyShape]]),
                reason,
              });
            }
          }
        }
      }
    }
  }
  return rows;
}

/**
 * Chip 의 secondary · tertiary 멤버 — `CoreChipColor` 에서 두 값이 빠지면서(#5415)
 * 목적지를 잃는다. 두 세대의 이름을 모두 싣는다: 어느 쪽이 캔버스에 남아 있든
 * `finish()` 가 설명할 수 없는 멤버를 만나 거부할 때 "Retire phantoms" 로 가는
 * 길이 문서화돼 있어야 한다. 이 목록은 은퇴를 **실행하지 않는다** — 열쇠를 버리는
 * 일은 드라이런을 본 사람이 명시적으로 누른다.
 */
function chipRetiredColourRows(): RetiredVariant[] {
  const reason =
    '#5415 — `CoreChipColor` 에서 이 값이 빠졌다(secondary · tertiary). 기본 테마에서 '
    + 'primary / neutral 과 같은 그림이어서 축이 거짓 신호를 보냈고, 사용처가 0 이었다. '
    + '`Color=` 에 이 값이 없으므로 이 멤버는 목적지가 없다. 이 이름을 쓰는 인스턴스는 '
    + 'neutral 또는 primary 로 먼저 옮겨야 한다 — 은퇴는 key 를 버린다';
  const rows: RetiredVariant[] = [];
  for (const p of chipCanvasPoses()) {
    if (!kChipRetiredColours.includes(p.colour)) continue;
    rows.push(
      { component: 'Chip', name: p.designer, reason },
      { component: 'Chip', name: p.builder, reason },
    );
  }
  return rows;
}


// Breadcrumb — the `Disabled` pose became the contract's `Enabled` axis.
//
// `CoreBreadcrumbContract` states `bool? get enabled` (a disabled trail draws
// every label and the separators in `disabledColor` and is not interactive),
// and `axes.enabled` is what schema v3 promotes — so the builder's own
// `Disabled=<bool>` pose is replaced by the `Enabled=<bool>` axis every other
// contract with an `enabled` uses, and the spelling and the value flip
// together (`Disabled=true` is `Enabled=false`). The canvas the designer drew,
// and the set the previous builder minted, both carry the eight
// `Hover × Disabled × Focus` members; each lands on the member that draws the
// same pose, so its key and every instance of it survive.
//
// The prefix is `Variant=standard`, then `Enabled` (the four-axis part, in
// `kAxisOrder`), then the poses that remain (`Hover`, `Focus`) — composed
// through `composeVariantName` so a `to` cannot drift from the name
// `enumerateAxisAssignments` mints for the same pose.
function breadcrumbCanvasRows(): VariantRename[] {
  const why =
    '`CoreBreadcrumbContract.enabled` 가 생겨 스키마가 `Enabled` 축을 승격한다 — 빌더가 그리던 ' +
    '`Disabled` 포즈는 그 축으로 철자와 값이 뒤집힌다(`Disabled=true` 는 `Enabled=false`). ' +
    '같은 포즈, 같은 key.';
  const rows: VariantRename[] = [];
  for (const hover of ['false', 'true'] as const) {
    for (const disabled of ['false', 'true'] as const) {
      for (const focus of ['false', 'true'] as const) {
        rows.push({
          component: 'Breadcrumb',
          from: `Variant=standard, Hover=${hover}, Disabled=${disabled}, Focus=${focus}`,
          to:
            composeVariantName([
              ['Variant', 'standard'],
              ['Enabled', disabled === 'false' ? 'true' : 'false'],
            ]) + `, Hover=${hover}, Focus=${focus}`,
          reason: why,
        });
      }
    }
  }
  return rows;
}

// Pagination — the `Disabled` pose became the contract's `Enabled` axis.
//
// The same move as Breadcrumb's (`breadcrumbCanvasRows`): `CorePaginationContract`
// states `bool? get enabled`, schema v3 promotes `Enabled`, and the builder's
// own `Disabled=<bool>` pose becomes that axis with the value flipped. The
// designer's canvas and the previous builder both carry the eight
// `Hover × Disabled × Focus` members; each lands on the member that draws the
// same pose, so its key and every instance of it survive.
function paginationCanvasRows(): VariantRename[] {
  const why =
    '`CorePaginationContract.enabled` 가 생겨 스키마가 `Enabled` 축을 승격한다 — 빌더가 그리던 ' +
    '`Disabled` 포즈는 그 축으로 철자와 값이 뒤집힌다(`Disabled=true` 는 `Enabled=false`). ' +
    '같은 포즈, 같은 key.';
  const rows: VariantRename[] = [];
  for (const hover of ['false', 'true'] as const) {
    for (const disabled of ['false', 'true'] as const) {
      for (const focus of ['false', 'true'] as const) {
        rows.push({
          component: 'Pagination',
          from: `Variant=standard, Hover=${hover}, Disabled=${disabled}, Focus=${focus}`,
          to:
            composeVariantName([
              ['Variant', 'standard'],
              ['Enabled', disabled === 'false' ? 'true' : 'false'],
            ]) + `, Hover=${hover}, Focus=${focus}`,
          reason: why,
        });
      }
    }
  }
  return rows;
}


// ThemeController — the three generations of names one set has carried, each
// row pointing DIRECTLY at the member the builder mints now (a table does not
// chain; see `auditVariantRenames`).
//
//   1. `Variant=standard`                       one static member (pre-axis)
//   2. `Variant=standard, Disabled=false|true`  the builder's own `Disabled` gen
//   3. `Size=<sm|md|lg>, Disabled=false|true`   the designer's redesign — Size
//                                               ladder, `Disabled` spelled the
//                                               way the previous generation
//                                               spelled it
//
// All land on `Size=…, Enabled=…`. `Enabled` because that is the axis schema v3
// promotes for this contract (`axes.enabled`) and the spelling every builder
// with a promoted `enabled` uses — G10 reads coverage through that name, and a
// `Disabled=` member projects to nothing there. Generations 1 and 2 drew the
// `md` row: `CoreThemeControllerStyle.default*` are the md values, and
// `defaultSize` is `md`.
const kThemeControllerSizes = ['sm', 'md', 'lg'] as const;

function themeControllerCanvasRows(): VariantRename[] {
  const why =
    '`Variant` 축이 죽고(`CoreThemeControllerVariant` 삭제) `Size` 사다리' +
    '(sm/md/lg)가 들어왔다. 옛 멤버는 `default*` 값 — 지금의 md 행 — 을 ' +
    '그렸으므로 md 로 직행한다. `Disabled` 는 스키마가 승격하는 `Enabled` 로 ' +
    '철자와 값이 뒤집힌다: 계약이 진술하는 것은 `bool get enabled` 이고 G10 이 ' +
    '그 이름으로 커버리지를 읽는다(계약에 `enabled` 를 둔 서른 몇 컴포넌트가 ' +
    '같은 철자를 쓴다). 같은 포즈, 같은 key.';
  const rows: VariantRename[] = [
    {
      component: 'ThemeController',
      from: 'Variant=standard',
      to: composeVariantName([
        ['Size', 'md'],
        ['Enabled', 'true'],
      ]),
      reason: why,
    },
  ];
  // 두 세대가 같은 목적지로 간다 — `Variant` 만 있던 것, 그리고 디자이너가
  // 캔버스에 세운 `Size × Disabled` 여섯.
  for (const disabled of ['false', 'true'] as const) {
    const enabled = disabled === 'false' ? 'true' : 'false';
    rows.push({
      component: 'ThemeController',
      from: `Variant=standard, Disabled=${disabled}`,
      to: composeVariantName([
        ['Size', 'md'],
        ['Enabled', enabled],
      ]),
      reason: why,
    });
  }
  for (const size of kThemeControllerSizes) {
    for (const disabled of ['false', 'true'] as const) {
      const enabled = disabled === 'false' ? 'true' : 'false';
      rows.push({
        component: 'ThemeController',
        from: `Size=${size}, Disabled=${disabled}`,
        to: composeVariantName([
          ['Size', size],
          ['Enabled', enabled],
        ]),
        reason: why,
      });
    }
  }

  return rows;
}

// ThemeSwatch — the 24 members the designer's set carries, in the canvas's own
// axis order (`Size=…, Selected=…, State=…`), each pointing at the name
// `enumerateAxisAssignments` mints for the same pose (`Size → State →
// Selected`, the T-16 order `composeVariantName` enforces). Same shape as
// `chipCanvasRows`: a bijection by construction, and composed rather than typed
// so a `to` cannot drift from the builder's spelling.
function themeSwatchCanvasRows(): VariantRename[] {
  const states = ['enabled', 'hover', 'pressed', 'disabled'] as const;
  const rows: VariantRename[] = [];
  for (const size of kThemeControllerSizes) {
    for (const selected of ['false', 'true'] as const) {
      for (const state of states) {
        rows.push({
          component: 'ThemeSwatch',
          from: `Size=${size}, Selected=${selected}, State=${state}`,
          to: composeVariantName([
            ['Size', size],
            ['State', state],
            ['Selected', selected],
          ]),
          reason:
            '축 이행 — 캔버스는 `Selected` 를 `State` 앞에 적었고 빌더는 T-16 순서' +
            '(`Size → State → Selected`)로 조립한다. 같은 포즈, 같은 key.',
        });
      }
    }
  }
  return rows;
}

// RadioGroup — the 24 members the 4-axis generation minted
// (`Variant=defaultVariant, Size=…, Enabled=…, Selected=…`), each pointing at
// the name `enumerateAxisAssignments` mints for the same pose on the builder's
// `Variant → Size → State → Selected` axes. `Enabled=true` is the `enabled` rung
// and `Enabled=false` the `disabled` one, and every old member was the plain
// row. Same shape as `chipCanvasRows`: a bijection by construction, composed
// rather than typed so a `to` cannot drift from the builder's spelling.
const kRadioGroupSizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const;
// The plain row's `Variant` member, spelled as `CoreRadioGroupVariant` is.
const kRadioGroupDefaultVariant = 'defaultVariant';

function radioGroupCanvasRows(): VariantRename[] {
  const rows: VariantRename[] = [];
  for (const size of kRadioGroupSizes) {
    for (const enabled of ['true', 'false'] as const) {
      for (const selected of ['false', 'true'] as const) {
        rows.push({
          component: 'RadioGroup',
          from: `Variant=defaultVariant, Size=${size}, Enabled=${enabled}, Selected=${selected}`,
          to: radioGroupMember(size, enabled === 'true' ? 'enabled' : 'disabled', selected),
          reason:
            '리디자인 — `Enabled` 불린이 `State` 사다리(enabled/hover/focus/' +
            'pressed/disabled)로. 같은 포즈, 같은 key.',
        });
      }
    }
  }
  return rows;
}

// RadioGroup — the 60 members the `Size → State → Selected` generation minted,
// each onto the plain row of the `Variant` axis `card` brought back: every one
// of them drew the plain row, and the tile is a member to ADD, not one to
// rename onto.
const kRadioGroupStateRungs = ['enabled', 'hover', 'focus', 'pressed', 'disabled'] as const;

function radioGroupVariantAxisRows(): VariantRename[] {
  const rows: VariantRename[] = [];
  for (const size of kRadioGroupSizes) {
    for (const state of kRadioGroupStateRungs) {
      for (const selected of ['false', 'true'] as const) {
        rows.push({
          component: 'RadioGroup',
          from: composeVariantName([
            ['Size', size],
            ['State', state],
            ['Selected', selected],
          ]),
          to: radioGroupMember(size, state, selected),
          reason:
            '`card` 변형 추가 — `Variant` 축이 다시 둘이 되어 기존 멤버는 전부 ' +
            '`Variant=defaultVariant` 로. 같은 포즈, 같은 key.',
        });
      }
    }
  }
  return rows;
}

// The member the builder mints for a plain-row pose — the one place a
// RadioGroup `to` is spelled, so the three generations cannot point at three
// spellings of it.
function radioGroupMember(size: string, state: string, selected: string): string {
  return composeVariantName([
    ['Variant', kRadioGroupDefaultVariant],
    ['Size', size],
    ['State', state],
    ['Selected', selected],
  ]);
}

// Variant axis/value renames — the sanctioned way a builder gains an axis
// without orphaning what it already produced.
//
// `mountSet.finish()` refuses to delete a variant it no longer produces unless a
// rename explains where it went (S-a), and adding an axis renames every existing
// member: `Disabled=false` becomes `Disabled=false, Layout=horizontal`. Without
// these two entries the Stepper entry throws `VariantIdentityError`, and the
// throw is not rolled back: the entry is reported as failed and a half-drawn
// Stepper stays on the canvas until the next run blanks it.
// The Checkbox v3 canvas → redesign rows, generated rather than typed out.
//
// The live set carried 36 members
// (`Variant=defaultVariant, Size=<6>, State=<checked|indeterminate|unchecked>,
// Enabled=<true|false>`), every one of which changes: the single-member
// `Variant` axis is gone, the tri-state VALUE moves from `State` to `Checked`
// (spelled `true` / `false` / `indeterminate` so `restingValueOf` can read it),
// and `Enabled` folds into the new five-rung `State` the way Button's and
// Chip's did (`Enabled=true` → `State=enabled`, `false` → `disabled`). The
// three new poses (hover / focus / pressed) are additions with no old name.
// A bijection by construction — distinct `from`s, distinct `to`s, every `to`
// a member `buildCheckbox` now produces. Composed through `composeVariantName`
// so a `to` cannot drift from the name `enumerateAxisAssignments` mints.
function checkboxV3CanvasRows(): VariantRename[] {
  const sizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const;
  const states = ['checked', 'indeterminate', 'unchecked'] as const;
  const enabled = ['true', 'false'] as const;
  const checkedOf = { checked: 'true', indeterminate: 'indeterminate', unchecked: 'false' } as const;
  const rows: VariantRename[] = [];
  for (const size of sizes) {
    for (const state of states) {
      for (const en of enabled) {
        rows.push({
          component: 'Checkbox',
          from: `Variant=defaultVariant, Size=${size}, State=${state}, Enabled=${en}`,
          to: composeVariantName([
            ['Size', size],
            ['State', en === 'true' ? 'enabled' : 'disabled'],
            ['Checked', checkedOf[state]],
          ]),
          reason:
            '리디자인(2026-09) — 단일값 Variant 축 삭제, 값 축은 `Checked`(tristate), `Enabled` 는 5단 `State` 로 접힌다',
        });
      }
    }
  }
  return rows;
}

// Link — `Variant` stops carrying the underline, and `Disabled` goes (#5389).
//
// The old set drew `Variant=default|underline|muted × Disabled × Focus`: the
// colour (`default`, `muted`) and the underline (`underline`) were folded into one
// axis, which is why "muted with an underline" could not be drawn. The new set is
// `Variant=standard|muted × Underline=false|true × Focus`. Each old `Disabled=false`
// member keeps drawing the picture it drew, so it is renamed into the member that
// now draws that picture — same key, so a Footer's eighteen links and a HoverCard's
// one survive. The `Disabled=true` members have no destination (see
// `linkDisabledRetirements`).
function linkAxisRows(): VariantRename[] {
  const reason =
    '리디자인(#5389) — Variant 가 색과 밑줄을 함께 들고 있던 것을 `Variant`(standard · muted) 와 ' +
    '`Underline` 두 축으로 가른다. 옛 `default` 는 `standard`, 옛 `underline` 은 ' +
    '`standard + Underline=true`, 옛 `muted` 는 `muted + Underline=false` 다 — 개명이라 key 가 ' +
    '유지되어 그 멤버를 쓰던 인스턴스(푸터의 muted, 호버카드의 underline)가 살아남는다. ' +
    '`Disabled=true` 멤버는 목적지가 없어 RETIRED_VARIANTS 로 은퇴한다.';
  const rows: VariantRename[] = [];
  const map: ReadonlyArray<readonly [string, string, string]> = [
    ['default', 'standard', 'false'],
    ['underline', 'standard', 'true'],
    ['muted', 'muted', 'false'],
  ];
  for (const [oldKind, kind, underline] of map) {
    for (const focus of ['false', 'true']) {
      rows.push({
        component: 'Link',
        from: `Variant=${oldKind}, Disabled=false, Focus=${focus}`,
        to: `Variant=${kind}, Underline=${underline}, Focus=${focus}`,
        reason,
      });
    }
  }
  return rows;
}

// Badge — `Variant` stops carrying the colour (CoUI v2).
//
// The old set drew `Variant=primary|secondary|outline|destructive` — one value
// that was a colour and a strength at once, which is why "a quiet red label"
// could not be drawn. The new set draws three design axes, `Variant`
// (`CoreBadgeVariant`: filled · tonal · outlined), `Style` (`CoreBadgeForm`:
// label · count · dot) and `Tone` (`CoreBadgeTone`), and each old value is
// renamed into the member that takes its place — same key, so an instance a
// designer placed keeps its link:
//
//   primary     → Tone=primary,     Variant=filled
//   secondary   → Tone=neutral,     Variant=filled
//   outline     → Tone=neutral,     Variant=outlined
//   destructive → Tone=destructive, Variant=filled
//
// Three of them keep their colours. `secondary` had no meaning of its own —
// there is no secondary tone — so it lands on the neutral fill, the strength it
// had with the colour that says nothing.
//
// `Style=count` lands on `Style=label`. The old `count` was the set's only
// content form, so every badge on the canvas that carries a word stands on it,
// and a word now has a form of its own (a rounded rectangle rather than the
// pill); `dot` stays `dot`.
//
// Three generations of names can still be on a canvas, and every row points
// DIRECTLY at the member the builder mints now (a table does not chain; see
// `auditVariantRenames`):
//
//   1. `Variant, Size, Style`                 the designer's set, before poses
//   2. `Variant, Size, Style, Hover`          a canvas that picked up Hover only
//   3. `Variant, Size, Style, Hover, Focused` the previous builder
//
// Hover and focus are no longer members — the set shows them through two
// BOOLEAN properties — so only the resting member of each pose group is
// renamed. A member with `Hover=true` or `Focused=true` has no destination (its
// resting sibling takes the one name there is) and retires instead
// (`badgePoseRetirements`).
//
// Generated rather than written out: 336 names that differ in four values are
// where one goes quietly wrong by hand. Six sizes, though the old canvas drew
// five — a row whose `from` is not on the page is a no-op.
const kBadgeOldVariants: ReadonlyArray<readonly [string, string, string]> = [
  // [old Variant, Tone, Variant]
  ['primary', 'primary', 'filled'],
  ['secondary', 'neutral', 'filled'],
  ['outline', 'neutral', 'outlined'],
  ['destructive', 'destructive', 'filled'],
];
const kBadgeOldForms: ReadonlyArray<readonly [string, string]> = [
  // [old Style, Style]
  ['count', 'label'],
  ['dot', 'dot'],
];
const kBadgeSizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const;

/** One old Badge pose and the member the builder now draws for its picture. */
interface BadgeOldPose {
  /** `Variant=…, Size=…, Style=…` — the design axes every generation spells. */
  readonly design: string;
  readonly now: string;
}

function badgeOldPoses(): BadgeOldPose[] {
  const poses: BadgeOldPose[] = [];
  for (const [oldVariant, tone, variant] of kBadgeOldVariants) {
    for (const size of kBadgeSizes) {
      for (const [oldStyle, style] of kBadgeOldForms) {
        poses.push({
          design: `Variant=${oldVariant}, Size=${size}, Style=${oldStyle}`,
          now: composeVariantName([
            ['Variant', variant],
            ['Size', size],
            ['Style', style],
            ['Tone', tone],
          ]),
        });
      }
    }
  }
  return poses;
}

function badgeAxisRows(): VariantRename[] {
  const reason =
    'Badge 축 재설계(v2) — 색과 세기를 한 값에 담던 `Variant` 를 `Tone` · `Variant`(세기) · ' +
    '`Style`(꼴) 세 축으로 가른다. 옛 값은 같은 그림을 그리는 멤버로 개명되어 key 가 ' +
    '유지된다. 옛 `Style=count` 는 낱말을 담던 유일한 꼴이라 `Style=label` 로 간다. ' +
    'Hover · Focused 는 이제 BOOLEAN 이라 쉬는 멤버만 옮긴다.';
  const rows: VariantRename[] = [];
  for (const pose of badgeOldPoses()) {
    for (const from of [
      pose.design,
      `${pose.design}, Hover=false`,
      `${pose.design}, Hover=false, Focused=false`,
    ]) {
      rows.push({ component: 'Badge', from, to: pose.now, reason });
    }
  }
  return rows;
}

/**
 * The Badge members a pose made — `Hover=true` or `Focused=true` in the two
 * generations that spelled poses as axes. Hover and focus are BOOLEAN properties
 * of the set now, and the resting sibling of each group takes the one name its
 * picture has (`badgeAxisRows`), so these have no destination.
 */
function badgePoseRetirements(): RetiredVariant[] {
  const reason =
    'Badge 축 재설계(v2) — Hover · Focused 가 변형 축에서 BOOLEAN 속성으로 옮겨 갔다. ' +
    '같은 묶음의 쉬는 멤버가 새 이름으로 개명되므로 이 멤버는 목적지가 없다.';
  const rows: RetiredVariant[] = [];
  for (const pose of badgeOldPoses()) {
    const names = [
      `${pose.design}, Hover=true`,
      `${pose.design}, Hover=true, Focused=false`,
      `${pose.design}, Hover=false, Focused=true`,
      `${pose.design}, Hover=true, Focused=true`,
    ];
    for (const name of names) rows.push({ component: 'Badge', name, reason });
  }
  return rows;
}

// The Avatar rows for the `Shape` axis (v2, P5-c) — every member the set had
// (`Size=<s>, Ring=<r>`) is a disc, because a disc was the only outline the
// widget drew, so each keeps its key as the `Shape=circle` member of the same
// size and ring. The `rounded` members are new and have nothing to rename from.
// Composed through `composeVariantName` so a `to` cannot drift from the name
// `enumerateAxisAssignments` mints for the same pose.
const kAvatarSizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const;

function avatarShapeRows(): VariantRename[] {
  const reason =
    'Avatar 모양 축(v2, P5-c) — `CoreAvatarShape`(circle | rounded)가 생겨 `Shape` 축이 ' +
    '`Size` 와 `Ring` 사이에 들어간다. 지금까지의 멤버는 모두 원이었으므로 같은 크기 · ' +
    '링의 `Shape=circle` 멤버로 개명되어 key 가 유지된다. `rounded` 멤버는 새로 만든다.';
  const rows: VariantRename[] = [];
  for (const size of kAvatarSizes) {
    for (const ring of ['false', 'true']) {
      rows.push({
        component: 'Avatar',
        from: composeVariantName([
          ['Size', size],
          ['Ring', ring],
        ]),
        to: composeVariantName([
          ['Size', size],
          ['Shape', 'circle'],
          ['Ring', ring],
        ]),
        reason,
      });
    }
  }
  return rows;
}

// Alert — gains a `Layout` axis (`CoreAlertLayout`: stacked · inline, CoUI v2).
//
// Gaining an axis renames every existing member: `Variant=info` becomes
// `Variant=info, Layout=stacked`, the picture it always drew (stacked is the
// contract's default and today's look). `inline` members are additions with no
// old name.
//
// Three generations of the tone spelling can still be on a canvas, and every row
// points DIRECTLY at the member the builder mints now (a table does not chain;
// see `auditVariantRenames`): `Variant=default` (v3, before the reserved-word
// fold), `Variant=defaultVariant` (#4035), and `Variant=neutral` (the redesign) —
// all three are the one tone-less row. Composed through `composeVariantName` so a
// `to` cannot drift from the name `enumerateAxisAssignments` mints.
const kAlertTones = ['neutral', 'info', 'success', 'warning', 'destructive'] as const;

function alertLayoutAxisRows(): VariantRename[] {
  const stacked = (tone: string): string =>
    composeVariantName([
      ['Variant', tone],
      ['Layout', 'stacked'],
    ]);
  const reason =
    'CoUI v2 — `CoreAlertLayout`(stacked · inline) 축을 얻는다. 기존 멤버는 모두 지금 그림인 ' +
    '`Layout=stacked` 로 개명되어 key 가 유지된다(stacked 가 계약의 기본값). inline 은 새 멤버다.';
  const rows: VariantRename[] = [];
  for (const tone of kAlertTones) {
    rows.push({ component: 'Alert', from: `Variant=${tone}`, to: stacked(tone), reason });
  }
  // 톤 없음 행의 옛 철자 둘 — 어느 쪽이든 같은 도착지로 바로 간다.
  rows.push({
    component: 'Alert',
    from: 'Variant=default',
    to: stacked('neutral'),
    reason:
      '재설계 — CoreAlertVariant 의 그 멤버는 기본값이 아니라 톤 없음(`neutral`)이고, v2 에서 ' +
      '`Layout=stacked` 축을 얻었다',
  });
  rows.push({
    component: 'Alert',
    from: 'Variant=defaultVariant',
    to: stacked('neutral'),
    reason: '재설계 — #4035 에서 옮겨간 캔버스를 같은 도착지(`neutral` · stacked)로 이어붙인다',
  });
  return rows;
}

// Progress — gains a `Segmented` axis (`segments`: the continuous bar or a row
// of cells, #5557).
//
// Gaining an axis renames every existing member: `Size=sm, Tone=primary`
// becomes `Size=sm, Tone=primary, Segmented=false`, the picture it always drew
// (a continuous bar — `segments` is `null` unless a caller names a count). The
// `Segmented=true` members are additions with no old name. Composed through
// `composeVariantName` so a `to` cannot drift from the name
// `enumerateAxisAssignments` mints.
const kProgressSizes = ['xs2', 'xs', 'sm', 'md', 'lg', 'xl'] as const;
const kProgressTones = ['primary', 'success', 'warning', 'destructive'] as const;

function progressSegmentedAxisRows(): VariantRename[] {
  const reason =
    'Progress `Segmented` 축(#5557) — `segments` 가 생겨 연속 막대와 칸으로 나뉜 막대가 ' +
    '다른 구조를 그린다. 기존 멤버는 모두 지금 그림인 `Segmented=false`(연속 막대, ' +
    '`segments` 의 기본값 null)로 개명되어 key 가 유지된다. `Segmented=true` 는 새 멤버다.';
  const rows: VariantRename[] = [];
  for (const size of kProgressSizes) {
    for (const tone of kProgressTones) {
      rows.push({
        component: 'Progress',
        from: composeVariantName([
          ['Size', size],
          ['Tone', tone],
        ]),
        to: composeVariantName([
          ['Size', size],
          ['Tone', tone],
          ['Segmented', 'false'],
        ]),
        reason,
      });
    }
  }
  return rows;
}

// Loading — gains a `Tone` axis (`primary · neutral · inverse`, #5879).
//
// Gaining an axis renames every existing member: `Variant=dots, Size=md`
// becomes `Variant=dots, Size=md, Tone=primary`, the picture it always drew
// (the accent colour — `primary` is `CoreLoadingTone.defaultTone`). The
// `neutral` and `inverse` members are additions with no old name. Composed
// through `composeVariantName` so a `to` cannot drift from the name
// `enumerateAxisCombos` mints.
const kLoadingVariants = ['spinner', 'dots', 'bar', 'pulse'] as const;
const kLoadingSizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const;

function loadingToneAxisRows(): VariantRename[] {
  const reason =
    'Loading `Tone` 축(#5879) — 지시자 색이 강조 · 중립 · 반전 셋으로 갈린다. 기존 멤버는 ' +
    '모두 지금 그림인 `Tone=primary`(강조색, `CoreLoadingTone.defaultTone`)로 개명되어 ' +
    'key 가 유지된다. 나머지 둘은 새 멤버다.';
  const rows: VariantRename[] = [];
  for (const variant of kLoadingVariants) {
    for (const size of kLoadingSizes) {
      rows.push({
        component: 'Loading',
        from: composeVariantName([
          ['Variant', variant],
          ['Size', size],
        ]),
        to: composeVariantName([
          ['Variant', variant],
          ['Size', size],
          ['Tone', 'primary'],
        ]),
        reason,
      });
    }
  }
  return rows;
}

// ChatBubble — a `Tail` axis (CoUI v2).
//
// The old set drew one member per `Variant`, and every one of them drew the
// tail on the bottom-left corner — the tail was not a choice, it was the shape.
// The new set makes it one: `Tail=none|start|end`, with `none` the resting pose
// because `CoreChatBubbleContract.defaultTail` is false. Each old member is
// renamed into `Tail=start`, the pose that draws the same picture (tail on the
// bottom-left, that corner square), so the instances a designer placed keep
// their link AND their look. The alternative — landing them on `Tail=none`, the
// new default — would apply the new default to existing pictures; whether to do
// that is the designer's call, and a one-word change to the `to` below.
//
// `plain` and the `Tail=none` / `Tail=end` members are new. `plain` still gets
// one row, to `Tail=none` — the only member it has: the rename audit
// (`auditVariantRenames`) reconstructs the old set by projecting the current
// names back onto the old axes, and cannot tell a variant the old set never drew
// from a row somebody forgot. The row is inert on a canvas with no
// `Variant=plain` (a row whose `from` is not on the page is a no-op), and if a
// designer drew one by hand it lands where the new set would put it anyway.
const kChatBubbleOldVariants = [
  'neutral',
  'primary',
  'secondary',
  'accent',
  'info',
  'success',
  'warning',
  'error',
] as const;

function chatBubbleTailRows(): VariantRename[] {
  const reason =
    'ChatBubble `Tail` 축(v2) — 옛 세트는 모든 변형이 왼쪽 아래 꼬리를 그렸다. 새 세트는 ' +
    '`Tail=none|start|end` 로 꼬리를 축에 올리고 기본(`defaultTail`)은 `none` 이다. 옛 멤버는 ' +
    '같은 그림인 `Tail=start` 로 개명되어 key 와 모양이 유지된다.';
  const rows: VariantRename[] = kChatBubbleOldVariants.map((variant) => ({
    component: 'ChatBubble',
    from: `Variant=${variant}`,
    to: composeVariantName([
      ['Variant', variant],
      ['Tail', 'start'],
    ]),
    reason,
  }));
  rows.push({
    component: 'ChatBubble',
    from: 'Variant=plain',
    to: composeVariantName([
      ['Variant', 'plain'],
      ['Tail', 'none'],
    ]),
    reason:
      'ChatBubble `plain`(v2) — 새 변형이라 옛 캔버스에 멤버가 없다. 이 행은 감사 ' +
      '(`auditVariantRenames`)가 옛 축 투영에서 `plain` 을 설명할 수 있게 하는 자리이며, ' +
      '`plain` 은 채움이 없어 꼬리가 없으므로 유일한 멤버 `Tail=none` 으로 간다.',
  });
  return rows;
}

export const VARIANT_RENAMES: VariantRename[
  // ── 4-axis migration rows (#4035), from the other side of this merge ────────
  //
  // Concatenated, not chosen. The two tables target disjoint components — 86 rows
  // below and 35 here — and exactly ONE pair collided (`Toast Variant=default`,
  // composed into the row below that carries both changes, so main's row is not
  // repeated here).
  //
  // Rows are never deleted to tidy up: a row whose `from` no longer exists is a
  // no-op, while a MISSING row costs a component its identity — `finish()` refuses
  // to delete a member it can no longer explain, the throw is not rolled back, and
  // the entry is reported as failed with a half-drawn component left on the page.
] = [
  // Resizable — the single `Hover` axis became `Orientation` × `State`. The
  // old members drew the horizontal split (panes side by side), at rest and
  // under the pointer, so they become those two poses and keep their keys.
  {
    component: 'Resizable',
    from: 'Hover=false',
    to: 'State=enabled, Orientation=horizontal',
    reason: '축 이행 — 구 Hover 축은 가로 분할의 평상시였다',
  },
  {
    component: 'Resizable',
    from: 'Hover=true',
    to: 'State=hover, Orientation=horizontal',
    reason: '축 이행 — 구 Hover 축은 가로 분할의 hover 였다',
  },
  // #4035 (C3) — 4-axis migration. 구 단일축(Variant=) 자식을 그 자식이
  // 실제로 렌더하던 조합명(결여 축 = 기본값: Size=md, Enabled=true)으로
  // 이행한다 — rename 이므로 자식 key/인스턴스 링크가 생존한다. 자동
  // 감지가 아니라 이 명시 목록이 정본(S-a).
  {
    component: 'Button',
    from: 'Variant=primary',
    to: 'Variant=primary, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=secondary',
    to: 'Variant=secondary, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=tonal',
    to: 'Variant=tonal, Size=md, State=enabled, Shape=rectangle',
    reason:
      '`tonal` 은 축 이행 뒤에 들어온 새 변형이라 옛 단일축 캔버스에 멤버가 없다. ' +
      'ChatBubble `plain` 행처럼 감사(`auditVariantRenames`)가 옛 축 투영을 설명하게 ' +
      '두는 자리이며, 캔버스에서는 아무것도 바꾸지 않는다.',
  },
  {
    component: 'Button',
    from: 'Variant=outline',
    to: 'Variant=outline, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=ghost',
    to: 'Variant=ghost, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=plain',
    to: 'Variant=plain, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=destructive',
    to: 'Variant=destructive, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=menu',
    to: 'Variant=menu, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },
  {
    component: 'Button',
    from: 'Variant=menubar',
    to: 'Variant=menubar, Size=md, State=enabled, Shape=rectangle',
    reason: '축 이행 — 구 단일축 자식은 md·enabled 렌더였다',
  },

  // TextField — v3 `CoreTextFieldVariant` 는 실재하는 축(defaultVariant/error)
  // 이라 구 `Variant=Default|Error` 는 대소문자 정정 + 결여 축(Size/Enabled)
  // 기본값 접미로 그대로 이행된다.
  {
    component: 'TextField',
    from: 'Variant=Default',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason: '4축 이행(#4035) — 구 자식은 md·enabled 렌더였고, v3 멤버 철자는 `defaultVariant`',
  },
  {
    component: 'TextField',
    from: 'Variant=Error',
    to: 'Variant=error, Size=md, Enabled=true, Focus=false',
    reason: '4축 이행(#4035) — `error` 는 v3 CoreTextFieldVariant 의 실재 멤버(철자만 소문자로 정정)',
  },

  // Checkbox — 세 세대. 첫 세대 `State=Checked|Unchecked|Indeterminate|
  // Disabled` 는 곧장 최종 이름을 가리킨다(Toast·Toggle 과 같은 재조준 —
  // 중간 세대 `Variant=defaultVariant, Size=md, State=…, Enabled=…` 이름은 이제
  // 아무 빌더도 만들지 않아 거기 두면 감사가 dangling 으로 읽는다). 구 Disabled
  // 자식은 glyph 없이 disabledBackground/disabledBorderColor 를 그렸으므로 목적지는
  // `State=disabled, Checked=false` 다.
  {
    component: 'Checkbox',
    from: 'State=Unchecked',
    to: 'Size=md, State=enabled, Checked=false',
    reason: '리디자인(2026-09) — 구 자식은 md·enabled 렌더였고, 값 축은 `Checked` 불린(tristate)',
  },
  {
    component: 'Checkbox',
    from: 'State=Checked',
    to: 'Size=md, State=enabled, Checked=true',
    reason: '리디자인(2026-09) — 구 자식은 md·enabled 렌더였고, 값 축은 `Checked` 불린(tristate)',
  },
  {
    component: 'Checkbox',
    from: 'State=Indeterminate',
    to: 'Size=md, State=enabled, Checked=indeterminate',
    reason: '리디자인(2026-09) — 구 자식은 md·enabled 렌더였고, 값 축은 `Checked` 불린(tristate)',
  },
  {
    component: 'Checkbox',
    from: 'State=Disabled',
    to: 'Size=md, State=disabled, Checked=false',
    reason:
      '리디자인(2026-09) — 구 Disabled 자식은 glyph 없이 disabledBackground/disabledBorderColor 를 그렸다(= 미체크 모양). `Enabled=false` 는 `State=disabled` 로 접힌다',
  },
  ...checkboxV3CanvasRows(),

  // Toggle — 첫 세대 `State=Off|On|Disabled` 는 곧장 최종 이름을 가리킨다
  // (Toast 와 같은 재조준). 중간 이름 `…Enabled=true|false` 는 이제 아무
  // 빌더도 만들지 않아 거기 두면 감사가 dangling 으로 읽는다. `State=On` 은
  // 캔버스에 On 축이 생겨 목적지를 얻었으므로 은퇴 목록이 아니라 여기 산다.
  {
    component: 'Toggle',
    from: 'State=Off',
    to: 'Size=md, State=enabled, On=false',
    reason: '4축 이행(#4035) — 구 Off 자식이 md·enabled 의 rest(off) 위치를 그렸다',
  },
  {
    component: 'Toggle',
    from: 'State=On',
    to: 'Size=md, State=enabled, On=true',
    reason: '구 On 자식은 md·enabled 의 on 위치(activeTrack/activeThumb)를 그렸고, On 축이 그 자리를 다시 연다',
  },
  {
    component: 'Toggle',
    from: 'State=Disabled',
    to: 'Size=md, State=disabled, On=false',
    reason: '4축 이행(#4035) — 구 Disabled 자식은 disabledTrack/disabledThumb 의 off 위치 = md × State=disabled',
  },
  // Toggle — State 축 획득 세대. 캔버스의 30 멤버는 `Size=<s>, On=<b>, State=<t>` 로
  // 살았고(속성 순서 Size→On→State), 목적지는 축 순서를 kAxisOrder 로 맞춘 현재
  // 이름이다. 한때 `Variant=defaultVariant, …` 를 앞세웠지만 2026-09 리디자인이
  // 단일값 Variant 축을 지웠으므로 목적지도 그 철자다. `Size=xs` 8 행은 목적지가
  // 없다(ladder 에서 제거) — RETIRED_VARIANTS 로 은퇴. `State=focus` 10 행은 어느
  // 캔버스에도 없던 이름이라 실행 시 no-op 이지만 투영 완전성을 위해 둔다.
  {
    component: 'Toggle',
    from: 'Size=sm, On=false, State=enabled',
    to: 'Size=sm, State=enabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=false, State=hover',
    to: 'Size=sm, State=hover, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=false, State=focus',
    to: 'Size=sm, State=focus, On=false',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=false, State=disabled',
    to: 'Size=sm, State=disabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=true, State=enabled',
    to: 'Size=sm, State=enabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=true, State=hover',
    to: 'Size=sm, State=hover, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=true, State=focus',
    to: 'Size=sm, State=focus, On=true',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=sm, On=true, State=disabled',
    to: 'Size=sm, State=disabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=false, State=enabled',
    to: 'Size=md, State=enabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=false, State=hover',
    to: 'Size=md, State=hover, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=false, State=focus',
    to: 'Size=md, State=focus, On=false',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=false, State=disabled',
    to: 'Size=md, State=disabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=true, State=enabled',
    to: 'Size=md, State=enabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=true, State=hover',
    to: 'Size=md, State=hover, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=true, State=focus',
    to: 'Size=md, State=focus, On=true',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=md, On=true, State=disabled',
    to: 'Size=md, State=disabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=false, State=enabled',
    to: 'Size=lg, State=enabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=false, State=hover',
    to: 'Size=lg, State=hover, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=false, State=focus',
    to: 'Size=lg, State=focus, On=false',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=false, State=disabled',
    to: 'Size=lg, State=disabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=true, State=enabled',
    to: 'Size=lg, State=enabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=true, State=hover',
    to: 'Size=lg, State=hover, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=true, State=focus',
    to: 'Size=lg, State=focus, On=true',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=lg, On=true, State=disabled',
    to: 'Size=lg, State=disabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=false, State=enabled',
    to: 'Size=xl, State=enabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=false, State=hover',
    to: 'Size=xl, State=hover, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=false, State=focus',
    to: 'Size=xl, State=focus, On=false',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=false, State=disabled',
    to: 'Size=xl, State=disabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=true, State=enabled',
    to: 'Size=xl, State=enabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=true, State=hover',
    to: 'Size=xl, State=hover, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=true, State=focus',
    to: 'Size=xl, State=focus, On=true',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl, On=true, State=disabled',
    to: 'Size=xl, State=disabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=false, State=enabled',
    to: 'Size=xl2, State=enabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=false, State=hover',
    to: 'Size=xl2, State=hover, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=false, State=focus',
    to: 'Size=xl2, State=focus, On=false',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=false, State=disabled',
    to: 'Size=xl2, State=disabled, On=false',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=true, State=enabled',
    to: 'Size=xl2, State=enabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=true, State=hover',
    to: 'Size=xl2, State=hover, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=true, State=focus',
    to: 'Size=xl2, State=focus, On=true',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  {
    component: 'Toggle',
    from: 'Size=xl2, On=true, State=disabled',
    to: 'Size=xl2, State=disabled, On=true',
    reason: 'State 축 획득 — 캔버스 철자(Size→On→State)를 kAxisOrder 순으로 맞춘다',
  },
  // Toggle — Variant 축 소실 세대(2026-09 리디자인). 빌더가 한 세대 동안 민트한
  // `Variant=defaultVariant, Size=…, State=…, On=…` 48 이름 가운데 `Size=xs` 8 은
  // 은퇴하고 나머지 40 은 Variant= 만 떼어낸 현재 이름으로 간다. 축을 잃는 세대라
  // 감사는 투영을 거부(unprojectable)하지만, 각 행의 목적지는 빌더가 지금 만드는
  // 멤버라 dangling 이 아니다. 캔버스는 이미 그 철자를 들고 있어 실행 시 no-op.
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=enabled, On=false',
    to: 'Size=sm, State=enabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=enabled, On=true',
    to: 'Size=sm, State=enabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=hover, On=false',
    to: 'Size=sm, State=hover, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=hover, On=true',
    to: 'Size=sm, State=hover, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=focus, On=false',
    to: 'Size=sm, State=focus, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=focus, On=true',
    to: 'Size=sm, State=focus, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=disabled, On=false',
    to: 'Size=sm, State=disabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=sm, State=disabled, On=true',
    to: 'Size=sm, State=disabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=enabled, On=false',
    to: 'Size=md, State=enabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=enabled, On=true',
    to: 'Size=md, State=enabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=hover, On=false',
    to: 'Size=md, State=hover, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=hover, On=true',
    to: 'Size=md, State=hover, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=focus, On=false',
    to: 'Size=md, State=focus, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=focus, On=true',
    to: 'Size=md, State=focus, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=disabled, On=false',
    to: 'Size=md, State=disabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=md, State=disabled, On=true',
    to: 'Size=md, State=disabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=enabled, On=false',
    to: 'Size=lg, State=enabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=enabled, On=true',
    to: 'Size=lg, State=enabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=hover, On=false',
    to: 'Size=lg, State=hover, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=hover, On=true',
    to: 'Size=lg, State=hover, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=focus, On=false',
    to: 'Size=lg, State=focus, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=focus, On=true',
    to: 'Size=lg, State=focus, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=disabled, On=false',
    to: 'Size=lg, State=disabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=lg, State=disabled, On=true',
    to: 'Size=lg, State=disabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=enabled, On=false',
    to: 'Size=xl, State=enabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=enabled, On=true',
    to: 'Size=xl, State=enabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=hover, On=false',
    to: 'Size=xl, State=hover, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=hover, On=true',
    to: 'Size=xl, State=hover, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=focus, On=false',
    to: 'Size=xl, State=focus, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=focus, On=true',
    to: 'Size=xl, State=focus, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=disabled, On=false',
    to: 'Size=xl, State=disabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl, State=disabled, On=true',
    to: 'Size=xl, State=disabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=enabled, On=false',
    to: 'Size=xl2, State=enabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=enabled, On=true',
    to: 'Size=xl2, State=enabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=hover, On=false',
    to: 'Size=xl2, State=hover, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=hover, On=true',
    to: 'Size=xl2, State=hover, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=focus, On=false',
    to: 'Size=xl2, State=focus, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=focus, On=true',
    to: 'Size=xl2, State=focus, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=disabled, On=false',
    to: 'Size=xl2, State=disabled, On=false',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },
  {
    component: 'Toggle',
    from: 'Variant=defaultVariant, Size=xl2, State=disabled, On=true',
    to: 'Size=xl2, State=disabled, On=true',
    reason: 'Variant 축 소실 — 단일값 축을 지운 이름으로 재조준',
  },

  // RadioGroup — 네 세대의 이름이 한 세트를 거쳤고, 각 행은 빌더가 지금 찍는
  // 멤버를 곧장 가리킨다(표는 연쇄하지 않는다 — `auditVariantRenames`).
  //
  //   1. `State=Unselected|Disabled`                        단일 축(pre-axis)
  //   2. `Variant=defaultVariant, Size=…, Enabled=…, Selected=…`  4축 이행 + pose
  //   3. `Size=…, State=…, Selected=…`                      단일값 `Variant` 축을
  //      그리지 않고, `Enabled` 불린이 `State` 사다리(enabled/hover/focus/
  //      pressed/disabled)로. Chip·Toggle 이 `Enabled` 를 접은 것과 같은 모양.
  //   4. `Variant=defaultVariant, Size=…, State=…, Selected=…` — 지금 이름.
  //      `card` 가 `Variant` 를 다시 둘로 만들었다.
  //
  // 1·2 세대는 전부 enabled/disabled 두 rung 으로 간다 — 옛 멤버가 그리던 것은
  // rest 와 disabled 뿐이고 hover/focus/pressed 는 캔버스에 없던 이름이라 목적지
  // 가 아니다. 모든 옛 멤버는 평범한 행이었으므로 `Variant=defaultVariant` 로
  // 간다. 같은 포즈, 같은 key.
  {
    component: 'RadioGroup',
    from: 'State=Unselected',
    to: radioGroupMember('md', 'enabled', 'false'),
    reason: '구 Unselected 자식이 md·enabled 의 미선택 인디케이터를 그렸다 — State 축 위의 같은 좌표',
  },
  {
    component: 'RadioGroup',
    from: 'State=Disabled',
    to: radioGroupMember('md', 'disabled', 'false'),
    reason: '구 Disabled 자식은 dot 없이 disabled 토큰을 그렸다 = 미선택 × State=disabled',
  },
  ...radioGroupCanvasRows(),
  ...radioGroupVariantAxisRows(),

  // TextArea — v3 `axes.variant` 자체가 null(CoreTextAreaStyle 에 variant enum
  // 없음). Default 만 Size/Enabled 조합으로 이행되고 Error 는 목적지가 없다.
  {
    component: 'TextArea',
    from: 'Variant=Default',
    to: 'Variant=defaultVariant, Size=md, State=enabled',
    reason: '4축 이행(#4035) — 구 Default 자식이 md·enabled 렌더였다(text_area 에는 variant 축이 없다)',
  },

  // Alert / Banner / Toast — 축 구성은 그대로(Variant 하나)이고 멤버 철자만
  // 다르다. Alert·Banner 는 그 철자가 두 번 움직였다: `default` 를 피한
  // `defaultVariant`/`default_` 를 거쳐, 재설계에서 **`neutral`** 로.
  //
  // 이름이 바뀐 이유는 예약어 회피가 아니라 **뜻**이다 — 그 행은 "기본값"이
  // 아니라 "톤이 없는 것"이고, info·success·warning·destructive 와 같은
  // 축 위의 다섯 번째 톤이다. `default` 는 그걸 기본값처럼 읽히게 했다.
  //
  // 두 단계를 각각 적는다. 캔버스가 아직 `default` 면 첫 줄이, 이미
  // `defaultVariant`/`default_` 로 옮겨졌으면 둘째 줄이 받는다 — 어느
  // 쪽이든 `neutral` 에 도착하고, 해당 없는 줄은 no-op 이다(위 헤더).
  // Alert 는 v2 에서 `Layout` 축까지 얻어 그 도착지가 `…, Layout=stacked` 다 —
  // 행은 `alertLayoutAxisRows` 가 만든다.
  ...alertLayoutAxisRows(),
  // Banner 는 두 축이라 이름이 `Variant=…, Style=…` 이고, rename 은 **전체
  // 이름**으로 매칭된다 — 축 하나만 적은 항목은 어느 멤버와도 안 맞는다.
  // 그래서 한 철자당 emphasis 수만큼 줄이 필요하다.
  {
    component: 'Banner',
    from: 'Variant=default, Style=weak',
    to: 'Variant=neutral, Style=weak',
    reason: '재설계 — CoreBannerVariant 의 그 멤버는 기본값이 아니라 톤 없음(`neutral`)이다',
  },
  {
    component: 'Banner',
    from: 'Variant=default, Style=solid',
    to: 'Variant=neutral, Style=solid',
    reason: '재설계 — 위와 같은 이름, 반대쪽 emphasis',
  },
  {
    component: 'Banner',
    from: 'Variant=default_, Style=weak',
    to: 'Variant=neutral, Style=weak',
    reason: '재설계 — #4035 에서 옮겨간 캔버스를 같은 도착지로 이어붙인다',
  },
  {
    component: 'Banner',
    from: 'Variant=default_, Style=solid',
    to: 'Variant=neutral, Style=solid',
    reason: '재설계 — 위와 같은 이름, 반대쪽 emphasis',
  },
  // 축이 생기기 전의 한-축 이름도 남겨둔다. 위 헤더가 적은 대로 해당 없는
  // 줄은 no-op 이고, 빠진 줄은 그 멤버의 정체성을 잃게 한다.
  {
    component: 'Banner',
    from: 'Variant=default_',
    to: 'Variant=neutral, Style=weak',
    reason: 'Style 축이 생기기 전 한-축 멤버 — 기본 emphasis 로 착지',
  },

  // Skeleton — `Enabled` 축이 사라지고 `Variant` 한 축만 남는다(#5234).
  //
  // #4035 가 `Variant=x` → `Variant=x, Enabled=true` 로 옮기던 세 줄의 자리다.
  // 그 줄은 이번 방향과 정확히 반대라 함께 두면 실행마다 이름이 오간다 — 이
  // 표는 체인을 만들지 않으므로(`auditVariantRenames`) 각 줄은 지금의 최종
  // 이름을 가리켜야 하고, #4035 이전의 `Variant=x` 는 이미 그 최종 이름이다.
  {
    component: 'Skeleton',
    from: 'Variant=rectangular, Enabled=true',
    to: 'Variant=rectangular',
    reason:
      'Enabled 축 소멸(#5234) — 계약에서 `enabled` 가 제거되어 세트는 `Variant` 한 축이다. ' +
      '`Enabled=true` 멤버가 그 변형의 그림을 그대로 이어받는다 — 같은 포즈, 같은 key. ' +
      '`Enabled=false` 멤버는 목적지가 없어 RETIRED_VARIANTS 로 은퇴한다.',
  },
  {
    component: 'Skeleton',
    from: 'Variant=circular, Enabled=true',
    to: 'Variant=circular',
    reason:
      'Enabled 축 소멸(#5234) — 계약에서 `enabled` 가 제거되어 세트는 `Variant` 한 축이다. ' +
      '`Enabled=true` 멤버가 그 변형의 그림을 그대로 이어받는다 — 같은 포즈, 같은 key. ' +
      '`Enabled=false` 멤버는 목적지가 없어 RETIRED_VARIANTS 로 은퇴한다.',
  },
  {
    component: 'Skeleton',
    from: 'Variant=text, Enabled=true',
    to: 'Variant=text',
    reason:
      'Enabled 축 소멸(#5234) — 계약에서 `enabled` 가 제거되어 세트는 `Variant` 한 축이다. ' +
      '`Enabled=true` 멤버가 그 변형의 그림을 그대로 이어받는다 — 같은 포즈, 같은 key. ' +
      '`Enabled=false` 멤버는 목적지가 없어 RETIRED_VARIANTS 로 은퇴한다.',
  },
  ...linkAxisRows(),
  // Swiper — Variant 철자는 그대로, Enabled 축만 추가된다.
  {
    component: 'Swiper',
    from: 'Variant=drawer',
    to: 'Variant=drawer, Enabled=true',
    reason: '4축 이행(#4035) — 구 자식은 enabled 렌더였다(Enabled 축 신설)',
  },
  {
    component: 'Swiper',
    from: 'Variant=sheet',
    to: 'Variant=sheet, Enabled=true',
    reason: '4축 이행(#4035) — 구 자식은 enabled 렌더였다(Enabled 축 신설)',
  },

  // StarRating — `Size` 가 생기기 전 세대(`Enabled` 한 축). 그 시절 별은 24 였다 —
  // 기본 `lg` 행(`defaultStarSize`)이 같은 크기이므로 그 자리로 이어받는다.
  {
    component: 'StarRating',
    from: 'Enabled=true',
    to: 'Size=lg, Enabled=true',
    reason: '`Size` 축 신설 — 옛 멤버는 24px 별(= 기본 lg 행)을 그렸다',
  },
  {
    component: 'StarRating',
    from: 'Enabled=false',
    to: 'Size=lg, Enabled=false',
    reason: '`Size` 축 신설 — 옛 멤버는 24px 별(= 기본 lg 행)을 그렸다',
  },

  // Chip — 이 일곱 줄은 `Size` · `Enabled` 가 생기기 전의 세대다. 그 시절 v3
  // `axes.variant` 는 null 이었고 열거기는 `CoreChipColor`(axes.other)를
  // 승격하지 않으므로(seed spec §4-2) 세트는 neutral 한 색만 그렸다 — 그 색을
  // 그리던 `Variant=neutral` 이 key 를 이어받는다. 아래에서 두 걸음 더 간다.
  {
    component: 'Chip',
    from: 'Variant=neutral',
    to: 'Variant=neutral, Size=md, Enabled=true',
    reason:
      'The single-colour member, from before Size/Enabled existed. `neutral` is '
      + 'still the colour it carried, and the `md` row / enabled pose are what it '
      + 'drew, so it lands on that combination.',
  },
  {
    component: 'Chip',
    from: 'Size=sm, Enabled=true',
    to: 'Variant=neutral, Size=sm, Enabled=true',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  {
    component: 'Chip',
    from: 'Size=sm, Enabled=false',
    to: 'Variant=neutral, Size=sm, Enabled=false',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  {
    component: 'Chip',
    from: 'Size=md, Enabled=true',
    to: 'Variant=neutral, Size=md, Enabled=true',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  {
    component: 'Chip',
    from: 'Size=md, Enabled=false',
    to: 'Variant=neutral, Size=md, Enabled=false',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  {
    component: 'Chip',
    from: 'Size=lg, Enabled=true',
    to: 'Variant=neutral, Size=lg, Enabled=true',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  {
    component: 'Chip',
    from: 'Size=lg, Enabled=false',
    to: 'Variant=neutral, Size=lg, Enabled=false',
    reason: 'See the `Size=xs, Enabled=true` entry above.',
  },
  // Chip — the 192 rows for the two spellings the canvas carries or has carried,
  // 96 each (see `chipCanvasRows`); the other 192 members' names are in
  // `RETIRED_VARIANTS` (`chipRetiredColourRows`).
  ...chipCanvasRows(),
  // Chip — the 192 rows for the generation just before `Shape` (#5630): every
  // member it minted becomes the `Shape=rounded` member of the same pose
  // (`chipShapeRows`).
  ...chipShapeRows(),
  // Chip — the thirteen rows above land on `…, Enabled=true|false` names that
  // the builder no longer produces, so each of those names is a `from` here and
  // lands one hop further on. What that shape drew was `neutral` in the
  // selected pose at the default emphasis (`chipTableColors(…, true, …)`), so
  // that is the member it becomes — `outlined` · `rounded`, the only look that
  // shape had. No-ops on the live canvas, which never carried the intermediate
  // shape; present so the table stays landable.
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=sm, Enabled=true',
    to: 'Color=neutral, Variant=outlined, Size=sm, State=enabled, Selected=true, Emphasis=high, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=true 는 선택된 포즈의 enabled 렌더였다',
  },
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=sm, Enabled=false',
    to: 'Color=neutral, Variant=outlined, Size=sm, State=disabled, Selected=false, Emphasis=low, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=false 는 disabled 렌더였다 — disabled 는 선택·강조를 지우므로 크기당 하나 남은 disabled 멤버로 간다',
  },
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=md, Enabled=true',
    to: 'Color=neutral, Variant=outlined, Size=md, State=enabled, Selected=true, Emphasis=high, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=true 는 선택된 포즈의 enabled 렌더였다',
  },
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=md, Enabled=false',
    to: 'Color=neutral, Variant=outlined, Size=md, State=disabled, Selected=false, Emphasis=low, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=false 는 disabled 렌더였다 — disabled 는 선택·강조를 지우므로 크기당 하나 남은 disabled 멤버로 간다',
  },
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=lg, Enabled=true',
    to: 'Color=neutral, Variant=outlined, Size=lg, State=enabled, Selected=true, Emphasis=high, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=true 는 선택된 포즈의 enabled 렌더였다',
  },
  {
    component: 'Chip',
    from: 'Variant=neutral, Size=lg, Enabled=false',
    to: 'Color=neutral, Variant=outlined, Size=lg, State=disabled, Selected=false, Emphasis=low, Shape=rounded',
    reason: 'State 축 이행 — 구 Enabled=false 는 disabled 렌더였다 — disabled 는 선택·강조를 지우므로 크기당 하나 남은 disabled 멤버로 간다',
  },

  // Select / SwitchField / MultiAnswerCard — v3 가 승격하는 축이 `enabled`
  // 하나뿐이다. 구 Default/Off/Unselected 가 Enabled=true 로 접히고,
  // Open/On/Selected 는 목적지가 없어 RETIRED_VARIANTS 로 명시 은퇴한다.
  // Select — 트리거가 Button 에서 TextField 계약으로 옮겨가며 축이
  // `Enabled` 하나에서 `Variant × Size × State` 로 늘었다(Select 코드 인계
  // 통합본 2026-09-08 §2). 구 멤버 둘은 각각 md 의 enabled·disabled 를
  // 그리고 있었으므로 그 자리로 간다.
  {
    component: 'Select',
    from: 'Variant=Default',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'enabled'],
    ]),
    reason:
      '축 이행 — 구 Default 자식이 닫힌·enabled 트리거를 그렸고, 그 포즈는 ' +
      '이제 md 의 enabled 멤버다(트리거가 TextField 계약을 상속하며 ' +
      'Variant × Size × State 로 늘었다)',
  },
  {
    component: 'Select',
    from: 'Enabled=true',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'enabled'],
    ]),
    reason:
      '축 이행 — 구 단일 `Enabled` 축의 enabled 멤버. 크기·변형이 없던 시절의 ' +
      '그 하나가 그리던 것은 기본 변형 md 의 enabled 포즈다',
  },
  {
    component: 'Select',
    from: 'Enabled=false',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'disabled'],
    ]),
    reason:
      '축 이행 — 구 `Enabled=false` 는 disabled 렌더였다. disabled 는 크기·변형을 ' +
      '지우지 않으므로 기본 변형 md 의 disabled 멤버로 간다',
  },
  {
    component: 'SwitchField',
    from: 'State=Off',
    to: 'Enabled=true, On=false',
    reason: '4축 이행(#4035) — 구 Off 자식이 enabled 의 rest(off) 위치를 그렸다(switch_field 는 enabled 축만 승격)',
  },
  {
    component: 'MultiAnswerCard',
    from: 'State=Unselected',
    to: 'Enabled=true, Selected=false, Hover=false',
    reason: '4축 이행(#4035) — 구 Unselected 자식이 enabled 의 미선택 카드를 그렸다(multi_answer_card 는 enabled 축만 승격)',
  },
  // ── this side's rows (86) ───────────────────────────────────────────────────
  // ThemeController — three name generations onto `Size=…, Enabled=…` (see
  // `themeControllerCanvasRows`), and the swatch set the redesign split out of
  // it, in the canvas's axis order (see `themeSwatchCanvasRows`).
  ...themeControllerCanvasRows(),
  ...themeSwatchCanvasRows(),
  // Breadcrumb — the `Disabled` pose onto the contract's `Enabled` axis (see
  // `breadcrumbCanvasRows`).
  ...breadcrumbCanvasRows(),
  // Pagination — the `Disabled` pose onto the contract's `Enabled` axis (see
  // `paginationCanvasRows`).
  ...paginationCanvasRows(),
  // The intermediate spelling, for a canvas already carrying it. Both
  // `Dismissible` halves, because renames match on the FULL member name.
  {
    component: 'Toast',
    from: 'Variant=default_, Dismissible=true',
    to: 'Variant=success, Dismissible=true',
    reason:
      '재설계 — 그 멤버는 초록 성공 체크를 그린다. `default_` 는 enum 안 자리를 ' +
      '말했을 뿐이고, 진짜 기본값은 글리프 없는 `neutral` 이다.',
  },
  {
    component: 'Toast',
    from: 'Variant=default_, Dismissible=false',
    to: 'Variant=success, Dismissible=false',
    reason: '위와 같은 이름, 반대쪽 Dismissible.',
  },
  {
    component: 'Toast',
    from: 'Variant=default',
    // THREE changes in one target, because a `from` can only appear once —
    // two rows with the same `from` leave the second a silent no-op and the
    // canvas holding a name neither side produces.
    //
    // (1) main renamed the member `default` → `default_` (Dart reserved
    // word), (2) this side added the `Dismissible` axis, (3) the redesign
    // renamed it again to `success`, because that is what it draws: the old
    // name said where the member sat in the enum, not what it was.
    to: 'Variant=success, Dismissible=true',
    reason:
      'Gained a `Dismissible` axis. `onDismiss` is optional and it is the only ' +
      'switch between the two padding fields the component states — ' +
      '`panelPaddingWithDismiss` when a caller passed it, `panelPadding` when not. ' +
      'Only the with-dismiss inset was drawn, so the widget DEFAULT reached no node ' +
      'and every toast on the canvas carried a ✕. The existing members are the ' +
      'dismissible ones.',
  },
  {
    component: 'Toast',
    from: 'Variant=destructive',
    to: 'Variant=destructive, Dismissible=true',
    reason:
      'Gained a `Dismissible` axis. `onDismiss` is optional and it is the only ' +
      'switch between the two padding fields the component states — ' +
      '`panelPaddingWithDismiss` when a caller passed it, `panelPadding` when not. ' +
      'Only the with-dismiss inset was drawn, so the widget DEFAULT reached no node ' +
      'and every toast on the canvas carried a ✕. The existing members are the ' +
      'dismissible ones.',
  },
  // The two members the rows above forgot. `default_` is the reserved-word
  // spelling the canvas gave the default toast (`default` cannot be a variant
  // value), so it is the same member the bare `Variant=default` row already
  // sends to success; `neutral` is the exact twin of the `destructive` row.
  // With one member already in the two-axis shape and these two still bare,
  // the set sits in Figma's "existing errors" state — property reads throw —
  // until every member spells both axes.
  {
    component: 'Toast',
    from: 'Variant=default_',
    to: 'Variant=success, Dismissible=true',
    reason: '위 `Variant=default` 행과 같은 멤버 — 캔버스가 예약어를 피해 `default_` 로 적었을 뿐이다.',
  },
  {
    component: 'Toast',
    from: 'Variant=neutral',
    to: 'Variant=neutral, Dismissible=true',
    reason: '위 `Variant=destructive` 행과 같은 이유 — ✕ 를 단 채 그려지던 멤버다.',
  },
  {
    component: 'Collapsible',
    from: 'Disabled=false, Focus=false',
    to: 'Expanded=false, Disabled=false, Focus=false',
    reason:
      'Gained an `Expanded` axis. `expanded = false` is the widget default and every ' +
      'member showed the content anyway, with a chevron pointing the COLLAPSED way — ' +
      'a disclosure caught between its two poses, with the default one absent. Both ' +
      'poses are resting states (each persists until a click), so this is an axis and ' +
      'not motion. The existing members are the collapsed ones, which is why they keep ' +
      'their chevron and lose their body.',
  },
  {
    component: 'Collapsible',
    from: 'Disabled=false, Focus=true',
    to: 'Expanded=false, Disabled=false, Focus=true',
    reason: 'Same axis. The existing members are the collapsed ones.',
  },
  {
    component: 'Collapsible',
    from: 'Disabled=true, Focus=false',
    to: 'Expanded=false, Disabled=true, Focus=false',
    reason: 'Same axis. The existing members are the collapsed ones.',
  },
  {
    component: 'Collapsible',
    from: 'Disabled=true, Focus=true',
    to: 'Expanded=false, Disabled=true, Focus=true',
    reason: 'Same axis. The existing members are the collapsed ones.',
  },
  {
    component: 'MultiAnswerCard',
    from: 'Selected=false, Disabled=false',
    to: 'Enabled=true, Selected=false, Hover=false',
    reason:
      'Gained a `Hover` axis. `hoverColor` is the middle arm of the widget\'s own ' +
      'three-way (`if (selected) … else if (_hovering && enabled) … else …`) and it ' +
      'changes the fill only — the border, its width and the inset stay the resting ' +
      'ones — so a card under the pointer was drawn with its resting background and ' +
      'the field reached no node. The existing members are the un-hovered ones.',
  },
  {
    component: 'MultiAnswerCard',
    from: 'Selected=false, Disabled=true',
    to: 'Enabled=true, Selected=false, Hover=false',
    reason:
      'Same axis. Hover is gated on `enabled`, so this row keeps the resting fill in ' +
      'both members and exists to keep the axis square.',
  },
  {
    component: 'MultiAnswerCard',
    from: 'Selected=true, Disabled=false',
    to: 'Enabled=true, Selected=true, Hover=false',
    reason:
      'Same axis. Selected wins over hover in the widget\'s order, so this row keeps ' +
      'the selected fill in both members.',
  },
  {
    component: 'MultiAnswerCard',
    from: 'Selected=true, Disabled=true',
    to: 'Enabled=true, Selected=true, Hover=false',
    reason: 'Same axis, and both reasons above apply at once.',
  },
  {
    component: 'Card',
    from: 'Variant=outlined, Disabled=false, Focused=false',
    to: 'Variant=outlined, Disabled=false, Focused=false, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=outlined, Disabled=false, Focused=true',
    to: 'Variant=outlined, Disabled=false, Focused=true, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=outlined, Disabled=true, Focused=false',
    to: 'Variant=outlined, Disabled=true, Focused=false, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=outlined, Disabled=true, Focused=true',
    to: 'Variant=outlined, Disabled=true, Focused=true, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=filled, Disabled=false, Focused=false',
    to: 'Variant=filled, Disabled=false, Focused=false, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=filled, Disabled=false, Focused=true',
    to: 'Variant=filled, Disabled=false, Focused=true, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=filled, Disabled=true, Focused=false',
    to: 'Variant=filled, Disabled=true, Focused=false, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'Card',
    from: 'Variant=filled, Disabled=true, Focused=true',
    to: 'Variant=filled, Disabled=true, Focused=true, Hovered=false',
    reason:
      'Gained a `Hovered` axis. `card.dart` paints `boxShadow: _hovered ? ' +
      'hoverShadows : null` and a pointer RESTS on a card, so it earns a pose — ' +
      'the axis was declined only while the stack that `hoverElevation` names was ' +
      'exported nowhere. The existing members are the un-hovered ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xs',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=sm',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=md',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=lg',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl2',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xs',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=sm',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=md',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=lg',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl2',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason:
      'Gained a `Disabled` axis. The Web resolver reads `enabled` and gives the ' +
      'label `labelDisabledColor` when it is false, so that colour was stated ' +
      'by Core and had no node on the canvas. The existing members are the ' +
      'enabled ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=filled, Disabled=false',
    to: 'Variant=filled, Size=md, Disabled=false',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=filled, Disabled=true',
    to: 'Variant=filled, Size=md, Disabled=true',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=outlined, Disabled=false',
    to: 'Variant=outlined, Size=md, Disabled=false',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=outlined, Disabled=true',
    to: 'Variant=outlined, Size=md, Disabled=true',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=ghost, Disabled=false',
    to: 'Variant=ghost, Size=md, Disabled=false',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'DescriptionCard',
    from: 'Variant=ghost, Disabled=true',
    to: 'Variant=ghost, Size=md, Disabled=true',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries five rows and only `md` ' +
      'was drawn, so four rows existed in the data and nowhere on the page — ' +
      'and they differ in more than padding (three typography roles and four ' +
      'gap slots move with the size). The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=outlined, ChangeType=positive',
    to: 'Variant=outlined, Size=md, ChangeType=positive',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=outlined, ChangeType=negative',
    to: 'Variant=outlined, Size=md, ChangeType=negative',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=outlined, ChangeType=neutral',
    to: 'Variant=outlined, Size=md, ChangeType=neutral',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=filled, ChangeType=positive',
    to: 'Variant=filled, Size=md, ChangeType=positive',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=filled, ChangeType=negative',
    to: 'Variant=filled, Size=md, ChangeType=negative',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stat',
    from: 'Variant=filled, ChangeType=neutral',
    to: 'Variant=filled, Size=md, ChangeType=neutral',
    reason:
      'Gained a `Size` axis. `defaultsBySize` carries `md` and the compact ' +
      '`sm` (14 / 16 inset, a 4 row gap, every text role one step down), and ' +
      'only `md` was drawn. The existing members are the md ones.',
  },
  {
    component: 'Stepper',
    from: 'Disabled=false',
    to: 'Layout=horizontal, Disabled=false',
    reason:
      "#3996 — gained a `Layout` axis. The widget picks its label role by " +
      'orientation (`labelVerticalStyle` is titleSmall, `labelHorizontalStyle` ' +
      'labelSmall) and only the horizontal layout was drawn, so the vertical ' +
      'role was stated by Core and appeared nowhere on the canvas. The existing ' +
      'members are the horizontal ones.',
  },
  {
    component: 'Stepper',
    from: 'Disabled=true',
    to: 'Layout=horizontal, Disabled=true',
    reason: '#3996 — see the `Disabled=false` entry above.',
  },
  // The boolean axis moves from the builder's `Disabled` to the schema's
  // `Enabled` (`CoreStepperContract.enabled`), values flipped, and takes the
  // canonical slot before `Layout` — four rows, one per pose, applied after the
  // two above so a canvas still on the first generation reaches the same names.
  ...(['horizontal', 'vertical'] as const).flatMap((layout): VariantRename[] =>
    ([false, true] as const).map((disabled) => ({
      component: 'Stepper',
      from: `Layout=${layout}, Disabled=${disabled}`,
      to: composeVariantName([
        ['Enabled', disabled ? 'false' : 'true'],
        ['Layout', layout],
      ]),
      reason:
        '`CoreStepperContract` gained `bool? get enabled`, so the schema promotes ' +
        'an `Enabled` axis and G10 reads coverage through that name — a ' +
        '`Disabled=` member projects to nothing there. Same pose, same key; the ' +
        'value flips (`Disabled=true` is `Enabled=false`) and the axis sorts ' +
        'before `Layout`.',
    })),
  ),
  {
    component: 'FileInput',
    from: 'Disabled=false',
    to: 'Enabled=true, DragOver=false',
    reason:
      'Gained a `DragOver` axis. `file_input.dart` repaints the dashed border ' +
      '(`dragOverBorderColor`) and the container fill ' +
      '(`dragActiveBackgroundColor`) while a file is over the zone, and neither ' +
      'colour had a node on the canvas — the box was only ever drawn in its ' +
      'resting colours. The existing members are the not-dragging ones.',
  },
  {
    component: 'FileInput',
    from: 'Disabled=true',
    to: 'Enabled=true, DragOver=false',
    reason: 'See the `Disabled=false` entry above.',
  },
  {
    component: 'Calendar',
    from: 'Selected=false',
    to: 'Selection=None',
    reason:
      'A boolean could not hold a range, and three fields — `rangeSelectionColor` ' +
      '/ `rangeSelectionTextStyle` / `endpointPillBorderRadius` — are spent only ' +
      'on the three range cell branches, so Core stated them and the canvas drew ' +
      'nothing. `CoreCalendarValue` has exactly three states (null / `.single` / ' +
      '`.range`) and the axis now has the same three. A fourth boolean ' +
      'combination would have offered "selected, and also ranged", which the ' +
      'value type cannot be in. This member is the no-selection one.',
  },
  {
    component: 'Calendar',
    from: 'Selected=true',
    to: 'Selection=Single',
    reason: 'See the `Selected=false` entry above — this member is the single-date one.',
  },
  // ─── Axis gains whose old members are two hops behind ──────────────────────
  //
  // ORDER IS LOAD-BEARING for `TextField`. `applyPendingVariantRenames` walks
  // this array once, in order, so a page still carrying the pre-`Disabled`
  // shape (`Variant=Default, Size=xs`) is migrated in two hops in one pass:
  // the entry above renames it to `…, Disabled=false`, and the entry below
  // then renames that same node to `…, Disabled=false, Focus=false`. Reversed,
  // the second hop runs before the node has the name it matches on, and the
  // node is left at the intermediate name — where nothing catches it:
  // `diffVariantNames` suppresses it from `unexplained` precisely BECAUSE it is
  // some entry's `from`, and `mountSet` deletes nothing. The result is a silent
  // 49th member, which is the failure this whole file exists to prevent. New
  // axis gains therefore append HERE, after every earlier gain on the same set.
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xs, Disabled=false',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason:
      'Gained a `Focus` axis. Two things the focused pose is made of were stated ' +
      'by Core and had no node on the canvas: the ring `FocusOutline` draws ' +
      '(geometry from `fields.focusOutlineStyle`, colour from the variant row’s ' +
      '`focusRingColor`) and the caret standing in the value (`cursorColor` / ' +
      '`cursorWidth` / `cursorRadius`). The existing members are the unfocused ones.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xs, Disabled=true',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=sm, Disabled=false',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=sm, Disabled=true',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=md, Disabled=false',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=md, Disabled=true',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=lg, Disabled=false',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=lg, Disabled=true',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl, Disabled=false',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl, Disabled=true',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl2, Disabled=false',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Default, Size=xl2, Disabled=true',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xs, Disabled=false',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xs, Disabled=true',
    to: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=sm, Disabled=false',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=sm, Disabled=true',
    to: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=md, Disabled=false',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=md, Disabled=true',
    to: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=lg, Disabled=false',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=lg, Disabled=true',
    to: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl, Disabled=false',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl, Disabled=true',
    to: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl2, Disabled=false',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  {
    component: 'TextField',
    from: 'Variant=Error, Size=xl2, Disabled=true',
    to: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    reason: 'See the `Variant=Default, Size=xs, Disabled=false` entry above.',
  },
  // ─── `Enabled × Focus` → `State` (TextField) ──────────────────────────────
  //
  // Third hop on the same set, appended after the two above for the reason the
  // ORDER note gives. The first twenty rows are the live canvas (State-shaped,
  // `Variant=default` spelling); the thirty-six after them chain the builder's
  // previous `Enabled × Focus` names so a page that went through that builder
  // — or the legacy chain that lands on `…Enabled=true, Focus=false` — reaches
  // `State=` in the same pass.
  {
    component: 'TextField',
    from: 'Variant=default, Size=sm, State=enabled',
    to: 'Variant=defaultVariant, Size=sm, State=enabled',
    reason:
      '`State` 축을 받았다. 라이브 캔버스는 이미 State 를 들고 있지만 variant 를 ' +
      '`default` 로 적었다 — v3 `CoreTextFieldVariant` 멤버는 `defaultVariant` ' +
      '(Dart 예약어 회피, Alert·Banner 와 같은 접기). `error` 멤버는 이미 목표 ' +
      '철자라 키를 그대로 둔다.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=sm, State=hover',
    to: 'Variant=defaultVariant, Size=sm, State=hover',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=sm, State=focus',
    to: 'Variant=defaultVariant, Size=sm, State=focus',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=sm, State=disabled',
    to: 'Variant=defaultVariant, Size=sm, State=disabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=md, State=enabled',
    to: 'Variant=defaultVariant, Size=md, State=enabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=md, State=hover',
    to: 'Variant=defaultVariant, Size=md, State=hover',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=md, State=focus',
    to: 'Variant=defaultVariant, Size=md, State=focus',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=md, State=disabled',
    to: 'Variant=defaultVariant, Size=md, State=disabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=lg, State=enabled',
    to: 'Variant=defaultVariant, Size=lg, State=enabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=lg, State=hover',
    to: 'Variant=defaultVariant, Size=lg, State=hover',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=lg, State=focus',
    to: 'Variant=defaultVariant, Size=lg, State=focus',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=lg, State=disabled',
    to: 'Variant=defaultVariant, Size=lg, State=disabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl, State=enabled',
    to: 'Variant=defaultVariant, Size=xl, State=enabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl, State=hover',
    to: 'Variant=defaultVariant, Size=xl, State=hover',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl, State=focus',
    to: 'Variant=defaultVariant, Size=xl, State=focus',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl, State=disabled',
    to: 'Variant=defaultVariant, Size=xl, State=disabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl2, State=enabled',
    to: 'Variant=defaultVariant, Size=xl2, State=enabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl2, State=hover',
    to: 'Variant=defaultVariant, Size=xl2, State=hover',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl2, State=focus',
    to: 'Variant=defaultVariant, Size=xl2, State=focus',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=default, Size=xl2, State=disabled',
    to: 'Variant=defaultVariant, Size=xl2, State=disabled',
    reason: '위 `Variant=default, Size=sm, State=enabled` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=xs, State=enabled',
    reason:
      '빌더의 `Enabled × Focus` 두 불리언이 `State` 한 enum 으로 접힌다 — ' +
      'true/false 는 `enabled`, true/true 는 `focus`, false/false 는 `disabled`. ' +
      '위 `Disabled` 행에 이어져 옛 캔버스는 한 번에 세 홉으로 이행한다. ' +
      '`Enabled=false, Focus=true` 는 행이 없다: `text_field_style.dart` 에서 ' +
      'disabled 가 focus 보다 위라 그 포즈는 `disabled` 로 렌더되고, 그 키는 ' +
      '이미 주인이 있어 두 번째 행은 다대일 붕괴가 된다.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xs, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=xs, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xs, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=xs, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=sm, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=sm, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=sm, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=sm, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=sm, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=md, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=md, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=md, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=md, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=md, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=lg, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=lg, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=lg, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=lg, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=lg, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=xl, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=xl, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=xl, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=false',
    to: 'Variant=defaultVariant, Size=xl2, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl2, Enabled=true, Focus=true',
    to: 'Variant=defaultVariant, Size=xl2, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=defaultVariant, Size=xl2, Enabled=false, Focus=false',
    to: 'Variant=defaultVariant, Size=xl2, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xs, Enabled=true, Focus=false',
    to: 'Variant=error, Size=xs, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xs, Enabled=true, Focus=true',
    to: 'Variant=error, Size=xs, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xs, Enabled=false, Focus=false',
    to: 'Variant=error, Size=xs, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=sm, Enabled=true, Focus=false',
    to: 'Variant=error, Size=sm, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=sm, Enabled=true, Focus=true',
    to: 'Variant=error, Size=sm, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=sm, Enabled=false, Focus=false',
    to: 'Variant=error, Size=sm, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=md, Enabled=true, Focus=false',
    to: 'Variant=error, Size=md, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=md, Enabled=true, Focus=true',
    to: 'Variant=error, Size=md, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=md, Enabled=false, Focus=false',
    to: 'Variant=error, Size=md, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=lg, Enabled=true, Focus=false',
    to: 'Variant=error, Size=lg, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=lg, Enabled=true, Focus=true',
    to: 'Variant=error, Size=lg, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=lg, Enabled=false, Focus=false',
    to: 'Variant=error, Size=lg, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl, Enabled=true, Focus=false',
    to: 'Variant=error, Size=xl, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl, Enabled=true, Focus=true',
    to: 'Variant=error, Size=xl, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl, Enabled=false, Focus=false',
    to: 'Variant=error, Size=xl, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl2, Enabled=true, Focus=false',
    to: 'Variant=error, Size=xl2, State=enabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl2, Enabled=true, Focus=true',
    to: 'Variant=error, Size=xl2, State=focus',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextField',
    from: 'Variant=error, Size=xl2, Enabled=false, Focus=false',
    to: 'Variant=error, Size=xl2, State=disabled',
    reason: '위 `Variant=defaultVariant, Size=xs, Enabled=true, Focus=false` 항목 참조.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Default, Size=xs',
    to: 'Variant=defaultVariant, Size=xs, State=enabled',
    reason:
      'Gained a `Focus` axis — the same pose, the same two things, the same fields ' +
      'as `TextField`. The ring and the caret were stated by Core and had nowhere on ' +
      'this component to land. The existing members are the unfocused ones.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Default, Size=sm',
    to: 'Variant=defaultVariant, Size=sm, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Default, Size=md',
    to: 'Variant=defaultVariant, Size=md, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Default, Size=lg',
    to: 'Variant=defaultVariant, Size=lg, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Default, Size=xl',
    to: 'Variant=defaultVariant, Size=xl, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Error, Size=xs',
    to: 'Variant=error, Size=xs, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Error, Size=sm',
    to: 'Variant=error, Size=sm, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Error, Size=md',
    to: 'Variant=error, Size=md, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Error, Size=lg',
    to: 'Variant=error, Size=lg, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'TextArea',
    from: 'Variant=Error, Size=xl',
    to: 'Variant=error, Size=xl, State=enabled',
    reason: 'See the `Variant=Default, Size=xs` entry above.',
  },
  {
    component: 'Avatar',
    from: 'Size=xs',
    to: 'Size=xs, Shape=circle, Ring=false',
    reason:
      'Gained a `Ring` axis. `ring` is a widget parameter that changes chrome and ' +
      'lingers (`avatar.dart`: `this.ring = false`), and all three fields the band is ' +
      'made of — `ringColor` / `ringWidth` / `ringOffset` — were stated by Core and ' +
      'reached no pixel, because nothing on the canvas drew a ring at all. The ' +
      'existing members are the ring-less ones. Points straight at the disc member ' +
      'the `Shape` axis now spells (see `avatarShapeRows`): a row names the final ' +
      'member, not the one it pointed at before the next axis came.',
  },
  {
    component: 'Avatar',
    from: 'Size=sm',
    to: 'Size=sm, Shape=circle, Ring=false',
    reason: 'See the `Size=xs` entry above.',
  },
  {
    component: 'Avatar',
    from: 'Size=md',
    to: 'Size=md, Shape=circle, Ring=false',
    reason: 'See the `Size=xs` entry above.',
  },
  {
    component: 'Avatar',
    from: 'Size=lg',
    to: 'Size=lg, Shape=circle, Ring=false',
    reason: 'See the `Size=xs` entry above.',
  },
  {
    component: 'Avatar',
    from: 'Size=xl',
    to: 'Size=xl, Shape=circle, Ring=false',
    reason: 'See the `Size=xs` entry above.',
  },
  {
    component: 'Avatar',
    from: 'Size=xl2',
    to: 'Size=xl2, Shape=circle, Ring=false',
    reason:
      'See the `Size=xs` entry above. This sixth row was the one real gap the rename ' +
      'audit found: the size ladder runs xs…xl2 and only five rows were written, so an ' +
      '`xl2` avatar on an existing page would have come back unexplained and taken the ' +
      'whole component down with it. Costs nothing if no page ever had one — a row whose ' +
      '`from` matches nothing is a silent no-op on every run.',
  },
  {
    component: 'FormLabel',
    from: 'Size=md, State=default',
    to: 'Size=md, Enabled=true',
    reason:
      'The designer\'s hand-made set (4 members: Size=[md|lg] × State=[default|disabled]) ' +
      'predates the builder\'s rewrite to a full Size(6) × Enabled(2) = 12-combo set — the ' +
      'plugin\'s own axis-naming convention for sets with no interactive state (no hover/' +
      'focus, same as Slider/FileInput/PhoneInput/ChipInput) is `Enabled`, not `State`. ' +
      '`default`/`disabled` map onto `Enabled=true`/`Enabled=false` 1:1 — nothing about ' +
      'the member\'s own content changes, only the axis vocabulary that names it.',
  },
  {
    component: 'FormLabel',
    from: 'Size=lg, State=default',
    to: 'Size=lg, Enabled=true',
    reason: 'See the `Size=md, State=default` entry above — same rename, `lg` rung.',
  },
  {
    component: 'FormLabel',
    from: 'Size=md, State=disabled',
    to: 'Size=md, Enabled=false',
    reason: 'See the `Size=md, State=default` entry above — the disabled member.',
  },
  {
    component: 'FormLabel',
    from: 'Size=lg, State=disabled',
    to: 'Size=lg, Enabled=false',
    reason: 'See the `Size=md, State=default` entry above — `lg`, disabled.',
  },
  // Fieldset: the set grows a `Variant` axis (`filled` · `outlined` · `plain`,
  // issue #6667). Every member the canvas carries drew the OUTLINED look — a
  // transparent fill inside an edge — so each lands on `Variant=outlined`;
  // `filled` (the new default) and `plain` did not exist, so they are members to
  // ADD, not to rename onto (the same reading as the Chip `Variant` rows above).
  // A table does not chain, so the older `State=default|disabled` spellings land
  // on the member the builder mints NOW, not on the `Size=…, Enabled=…` hop.
  {
    component: 'Fieldset',
    from: 'Size=md, State=default',
    to: 'Variant=outlined, Size=md, Enabled=true',
    reason:
      'The designer\'s hand-made set spells its non-interactive pose as ' +
      '`State=default|disabled`; the plugin\'s axis vocabulary for a set with no ' +
      'hover/focus is `Enabled`, and the set now also draws a `Variant` axis whose ' +
      'older look is `outlined` — the member itself is unchanged, only the axes ' +
      'that name it.',
  },
  {
    component: 'Fieldset',
    from: 'Size=lg, State=default',
    to: 'Variant=outlined, Size=lg, Enabled=true',
    reason: 'See the `Size=md, State=default` entry above — `lg` rung.',
  },
  {
    component: 'Fieldset',
    from: 'Size=md, State=disabled',
    to: 'Variant=outlined, Size=md, Enabled=false',
    reason: 'See the `Size=md, State=default` entry above — the disabled member.',
  },
  {
    component: 'Fieldset',
    from: 'Size=lg, State=disabled',
    to: 'Variant=outlined, Size=lg, Enabled=false',
    reason: 'See the `Size=md, State=default` entry above — `lg`, disabled.',
  },
  {
    component: 'Fieldset',
    from: 'Size=md, Enabled=true',
    to: 'Variant=outlined, Size=md, Enabled=true',
    reason:
      'The `Variant` axis arrives (issue #6667). The set drew one look, the outlined ' +
      'one, so the member keeps its key by landing on `Variant=outlined`.',
  },
  {
    component: 'Fieldset',
    from: 'Size=lg, Enabled=true',
    to: 'Variant=outlined, Size=lg, Enabled=true',
    reason: 'See the `Size=md, Enabled=true` entry above — `lg` rung.',
  },
  {
    component: 'Fieldset',
    from: 'Size=md, Enabled=false',
    to: 'Variant=outlined, Size=md, Enabled=false',
    reason: 'See the `Size=md, Enabled=true` entry above — the disabled member.',
  },
  {
    component: 'Fieldset',
    from: 'Size=lg, Enabled=false',
    to: 'Variant=outlined, Size=lg, Enabled=false',
    reason: 'See the `Size=md, Enabled=true` entry above — `lg`, disabled.',
  },
  {
    component: 'FormField',
    from: 'Variant=Default',
    to: 'Disabled=false, Error=false',
    reason:
      'Replaced a two-valued `Variant` enum with the two independent booleans the ' +
      'widget actually has. `resolveFormField(context, enabled:, formFieldStyle:)` ' +
      'takes `enabled` as its only state input while the error is a render-time ' +
      'branch in the widget body, so a field can be disabled and invalid at once — ' +
      'the Web twin writes `aria-disabled` and `aria-invalid` as two separate `if`s ' +
      'on one `role="group"`, which a single three-valued enum cannot hold. The gain ' +
      'also gives `disabledFormLabelStyle.labelStyle` a node: the disabled overlay ' +
      'mutes the label to `on-surface-subtle` against `FormLabel`’s own enabled ' +
      '`on-surface-variant`, a colour Core states and the canvas had nowhere to ' +
      'put. The existing members are the enabled ones.',
  },
  {
    component: 'FormField',
    from: 'Variant=Error',
    to: 'Disabled=false, Error=true',
    reason: 'See the `Variant=Default` entry above — this member is the invalid one.',
  },
  {
    component: 'FormField',
    from: 'Size=md, State=default',
    to: 'Disabled=false, Error=false',
    reason:
      'The designer\'s hand-made set carries a `Size` axis (md · lg) and a ' +
      'three-valued `State`; Core FormField has no size — it forwards none to the ' +
      'FormLabel and TextField it composes — so only the `md` members have a ' +
      'destination, on the two booleans the widget actually has. The `lg` three ' +
      'are retired below; a size axis for FormField is a Core decision, not a ' +
      'spelling.',
  },
  {
    component: 'FormField',
    from: 'Size=md, State=error',
    to: 'Disabled=false, Error=true',
    reason: 'See the `Size=md, State=default` entry above — the invalid member.',
  },
  {
    component: 'FormField',
    from: 'Size=md, State=disabled',
    to: 'Disabled=true, Error=false',
    reason: 'See the `Size=md, State=default` entry above — the disabled member.',
  },
  {
    component: 'Clickable',
    from: 'State=default, Shape=rect',
    to: 'State=default, Shape=rect, Enabled=true',
    reason:
      'Gained the `Enabled` axis the v3 `axes` block promotes (the contract\'s '
      + '`bool enabled`). `disabled` had been spelled as a fourth `State` value, '
      + 'which put the same fact on two axes while leaving the promoted one absent — '
      + 'so the disabled member moves to `State=default, Enabled=false`, and the '
      + 'other three states gain `Enabled=true`. Sparse on purpose: '
      + '`clickable.dart` returns early out of the focus handler when disabled and '
      + 'never scales an unpressable child, so focused/pressed-while-disabled are '
      + 'not states the app reaches.',
  },
  {
    component: 'Clickable',
    from: 'State=default, Shape=circle',
    to: 'State=default, Shape=circle, Enabled=true',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=focused, Shape=rect',
    to: 'State=focused, Shape=rect, Enabled=true',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=focused, Shape=circle',
    to: 'State=focused, Shape=circle, Enabled=true',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=pressed, Shape=rect',
    to: 'State=pressed, Shape=rect, Enabled=true',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=pressed, Shape=circle',
    to: 'State=pressed, Shape=circle, Enabled=true',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=disabled, Shape=rect',
    to: 'State=default, Shape=rect, Enabled=false',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  {
    component: 'Clickable',
    from: 'State=disabled, Shape=circle',
    to: 'State=default, Shape=circle, Enabled=false',
    reason: 'See the `State=default, Shape=rect` entry above.',
  },
  // Command — the 2026-09 redesign. `Presentation(3) × Size(3) × Empty(2)`
  // replaces `Variant=standard × Disabled × Empty`. The populated, enabled
  // pose and the empty pose keep their nodes (and keys) as the inline `md`
  // members — inline is what the old 360px preview was, and `md` is the
  // default density. The two `Disabled=true` members have no destination:
  // the axis is gone (a palette that cannot be used is not opened; the one
  // real case — an inline field that cannot take input — is the composed
  // `TextField`'s own disabled state) — see RETIRED_VARIANTS.
  {
    component: 'Command',
    from: 'Variant=standard',
    to: 'Presentation=inline, Size=md, Empty=false',
    reason:
      'The single member a `Variant`-only build minted — the populated, enabled ' +
      'pose, which the redesign draws as the inline `md` palette.',
  },
  {
    component: 'Command',
    from: 'Disabled=false',
    to: 'Presentation=inline, Size=md, Empty=false',
    reason: 'Pre-`Empty` populated pose → the inline `md` populated member.',
  },
  {
    component: 'Command',
    from: 'Variant=standard, Disabled=false, Empty=false',
    to: 'Presentation=inline, Size=md, Empty=false',
    reason:
      '`Variant` is `@behaviourOnly` now (one member separates nothing) and ' +
      '`Disabled` is gone; the populated, enabled pose is the inline `md` member.',
  },
  {
    component: 'Command',
    from: 'Variant=standard, Disabled=false, Empty=true',
    to: 'Presentation=inline, Size=md, Empty=true',
    reason: 'Same fold as the populated member — the empty branch, inline `md`.',
  },
  // InputOtp
  //
  // Two generations, each pointed straight at today's name (the table does not
  // chain): the `Variant=default` members of the build before the `State` axis
  // folded `Enabled`, and the `Variant × State` members of the build before the
  // `Size` axis. Every one of them was drawn at 40 cells, which is the `md` rung.
  {
    component: 'InputOtp',
    from: 'Variant=default, State=enabled',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'enabled'],
    ]),
    reason:
      'Button 패턴대로 builder 가 `State` 축을 선언하며 `Enabled` 를 접었고, v3 멤버 ' +
      '철자는 `defaultVariant` 다. 캔버스의 네 `Variant=default` 멤버는 각자 같은 ' +
      'pose 를 1:1 로 유지한다 — 이 멤버는 포커스된 셀이 없는 resting pose. 그 뒤 ' +
      '`Size` 축이 생겨 40 셀이던 이 멤버는 `md` 행으로 간다.',
  },
  {
    component: 'InputOtp',
    from: 'Variant=default, State=hover',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'hover'],
    ]),
    reason:
      'See the `State=enabled` entry above — resolver 에 hover rung 이 없어 rest 와 ' +
      '같은 그림이지만 캔버스 키가 있어 멤버로 남긴다. `md` 행.',
  },
  {
    component: 'InputOtp',
    from: 'Variant=default, State=focus',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'focus'],
    ]),
    reason:
      'See the `State=enabled` entry above — 첫 빈 셀에 ring 이 켜진 focused pose. ' +
      '`md` 행.',
  },
  {
    component: 'InputOtp',
    from: 'Variant=default, State=disabled',
    to: composeVariantName([
      ['Variant', 'defaultVariant'],
      ['Size', 'md'],
      ['State', 'disabled'],
    ]),
    reason:
      'See the `State=enabled` entry above — 셀 행이 `opacity50` 으로 눕는 disabled ' +
      'pose. `md` 행.',
  },
  ...(['defaultVariant', 'error'] as const).flatMap((variant) =>
    (['enabled', 'hover', 'focus', 'disabled'] as const).map((state) => ({
      component: 'InputOtp',
      from: `Variant=${variant}, State=${state}`,
      to: composeVariantName([
        ['Variant', variant],
        ['Size', 'md'],
        ['State', state],
      ]),
      reason:
        'Gained a `Size` axis — `CoreInputOtpContract.size` (`CoreInputOtpSize` ' +
        'md · lg). Existing members were the md row.',
    })),
  ),
  // Fab
  {
    component: 'Fab',
    from: 'Size=mini, Open=false, State=enabled',
    to: 'Size=mini, State=enabled, Open=false, Extended=false',
    reason:
      '빌더가 `State` 축을 T-16 순서로 선언했고, 그 뒤 디자이너가 `Extended` 를 ' +
      '더했다 — `label` 을 받은 알약. 옛 이름은 축이 둘 다 없던 세대의 것이라 ' +
      '원형 포즈(`Extended=false`)로 직행한다. 같은 포즈, 같은 key.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=false, State=hover',
    to: 'Size=mini, State=hover, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=false, State=focus',
    to: 'Size=mini, State=focus, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=false, State=pressed',
    to: 'Size=mini, State=pressed, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=false, State=disabled',
    to: 'Size=mini, State=disabled, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=true, State=enabled',
    to: 'Size=mini, State=enabled, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=true, State=hover',
    to: 'Size=mini, State=hover, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=true, State=focus',
    to: 'Size=mini, State=focus, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=mini, Open=true, State=pressed',
    to: 'Size=mini, State=pressed, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=false, State=enabled',
    to: 'Size=regular, State=enabled, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=false, State=hover',
    to: 'Size=regular, State=hover, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=false, State=focus',
    to: 'Size=regular, State=focus, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=false, State=pressed',
    to: 'Size=regular, State=pressed, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=false, State=disabled',
    to: 'Size=regular, State=disabled, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=true, State=enabled',
    to: 'Size=regular, State=enabled, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=true, State=hover',
    to: 'Size=regular, State=hover, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=true, State=focus',
    to: 'Size=regular, State=focus, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=regular, Open=true, State=pressed',
    to: 'Size=regular, State=pressed, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=false, State=enabled',
    to: 'Size=large, State=enabled, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=false, State=hover',
    to: 'Size=large, State=hover, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=false, State=focus',
    to: 'Size=large, State=focus, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=false, State=pressed',
    to: 'Size=large, State=pressed, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=false, State=disabled',
    to: 'Size=large, State=disabled, Open=false, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=true, State=enabled',
    to: 'Size=large, State=enabled, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=true, State=hover',
    to: 'Size=large, State=hover, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=true, State=focus',
    to: 'Size=large, State=focus, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  {
    component: 'Fab',
    from: 'Size=large, Open=true, State=pressed',
    to: 'Size=large, State=pressed, Open=true, Extended=false',
    reason:
      '위 `Size=mini, Open=false, State=enabled` 행과 같은 이유.',
  },
  // FormattedInput · PhoneInput — the canvas grew a `Size` axis the code never
  // had. Both widgets compose one md TextField and state no size of their own
  // (`formatted_input.sizes` and `phone_input.sizes` are `{}`; neither
  // contract reads `CoreComponentSize`), so the five sizes on the canvas were
  // a designer's promise the app cannot keep. The user chose to let the canvas
  // step back: the md members are the ones that always rendered, so they keep
  // their keys under the size-less name; the other four sizes retire (see
  // RETIRED_VARIANTS). Retire first, then Generate — renaming while the other
  // sizes are still in the set leaves it holding two name shapes at once.
  // FormattedInput now exposes its previously missing hover pose. Both the
  // size-bearing generation and the last size-less generation land directly
  // on the same unhovered member; the migration table must not rely on a chain.
  ...sizeAxisDroppedRows('FormattedInput', ['Enabled', 'Focus']).map((row) => ({
    ...row,
    to: row.to.replace(', Focus=', ', Hover=false, Focus='),
  })),
  ...(['true', 'false'] as const).flatMap((enabled) =>
    (['true', 'false'] as const).map((focus) => ({
      component: 'FormattedInput',
      from: `Enabled=${enabled}, Focus=${focus}`,
      to: `Enabled=${enabled}, Hover=false, Focus=${focus}`,
      reason: 'hover 축 추가: 기존 멤버를 같은 비호버 상태로 옮겨 키를 보존한다.',
    })),
  ),
  ...sizeAxisDroppedRows('PhoneInput', ['Enabled', 'Hover', 'Focus']),

  // AppBar — 디자이너 초판(3064:502)의 소문자 pose 축(leading/align)을 canonical
  // 축 표기로. 값과 조합은 동일하고 24 멤버 키 전부 보존된다 — 이 블록이 없으면
  // `finish()` 가 설명할 수 없는 멤버를 지우기를 거부해(S-a) AppBar 엔트리 전체가
  // 실패한다.
  ...(['standard', 'compact', 'medium'] as const).flatMap((v) =>
    (['none', 'back', 'close', 'menu'] as const).flatMap((l) =>
      (['start', 'center'] as const).map((a) => ({
        component: 'AppBar',
        from: `Variant=${v}, leading=${l}, align=${a}`,
        to: composeVariantName([['Variant', v], ['Leading', l], ['Align', a]]),
        reason: '디자이너 초판의 소문자 pose 축(leading/align)을 canonical 축 표기로 — 값과 조합은 동일, 24 멤버 키 전부 보존',
      })))),
  // Badge — every generation of the old axes, onto the v2 members
  // (`badgeAxisRows`).
  ...badgeAxisRows(),
  // Avatar — the disc members onto the `Shape=circle` spelling
  // (`avatarShapeRows`).
  ...avatarShapeRows(),
  // ChatBubble — the tail becomes an axis; each old member keeps its picture
  // as `Tail=start` (`chatBubbleTailRows`).
  ...chatBubbleTailRows(),
  // Adding the error pose preserves the existing main component identities.
  ...(['true', 'false'] as const).flatMap((enabled) =>
    (['false', 'true'] as const).map((focus) => ({
      component: 'TimePicker',
      from: composeVariantName([['Enabled', enabled], ['Focus', focus]]),
      to: composeVariantName([['Enabled', enabled], ['Focus', focus], ['Error', 'false']]),
      reason: 'The existing trigger is Error=false; errorText now has an Error=true projection.',
    })),
  ),
  // TextArea — the generation that follows `CoreTextAreaVariant`.
  //
  // Two things moved at once and both are spelling, not shape. The set
  // gained a Variant axis (the error row finally has somewhere to be
  // drawn — see `CoreTextAreaVariant`'s own note for why it had not),
  // and the canvas's `Variant=default` is the enum member the exporter
  // names `defaultVariant`, so every live member's name shifts even
  // where nothing about it changed.
  //
  // Generated: thirty-six rows differing in three values is where one
  // goes quietly wrong by hand.
  ...(['default', 'error'] as const).flatMap((v) =>
    (['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const).flatMap((sz) =>
      (['true', 'false'] as const).flatMap((enabled) =>
        (['false', 'true'] as const)
          .filter((focus) => !(v === 'error' && enabled === 'false') && !(focus === 'true' && enabled === 'false' && v === 'error'))
          .map((focus) => ({
            component: 'TextArea' as const,
            from: `Variant=${v}, Size=${sz}, Enabled=${enabled}, Focus=${focus}, Hover=false`,
            to: `Variant=${v === 'default' ? 'defaultVariant' : v}, Size=${sz}, State=${
              enabled === 'false' ? 'disabled' : focus === 'true' ? 'focus' : 'enabled'
            }`,
            reason:
              'TextArea gained a Variant axis when `CoreTextAreaVariant` ' +
              'replaced the bare-bool key on `defaultsByVariant`, and the ' +
              "canvas's `default` is that enum's `defaultVariant`. Enabled × " +
              'Focus is now the single `State` pose TextField spells — these ' +
              'rows all carried `Hover=false`, so none of them is the hover member.',
          })),
      ),
    ),
  ),
  // NavigationBarItem — the generation that splits the canvas's
  // `orientation` axis and lifts `selected` out of `state`.
  //
  // Three renamings at once, all of them the builder catching up to a set
  // the designer authored:
  //
  //   orientation=vertical    → Label=bottom   (label under the icon)
  //   orientation=horizontal  → Label=end      (label beside it)
  //   orientation=icon        → Label=none     (icon-only — not a
  //                                             direction, an absence)
  //   selected=yes|no         → Selected=true|false, its own axis
  //
  // `icon` was never an orientation. The contract already says what it is
  // — `CoreNavigationLabelMode.none`, "No item shows a label (icon-only)"
  // — and one axis answering both "where is the label" and "is there
  // one" is why the two could not be enumerated separately.
  //
  // Selection leaves `state` for the reason it never belonged there: an
  // item is selected WHILE hovered and WHILE disabled, so a `state`
  // member could not name those.
  ...(
    [
      ['vertical', 'bottom'],
      ['horizontal', 'end'],
      ['icon', 'none'],
    ] as const
  ).flatMap(([orientation, label]) =>
    (['Default', 'hover', 'disabled'] as const).flatMap((st) =>
      (['no', 'yes'] as const).map((sel) => ({
        component: 'NavigationBarItem' as const,
        from: `orientation=${orientation}, state=${st}, selected=${sel}`,
        // `Default` lands on `enabled` directly — the R1 rename below (#4552)
        // patches this `to` rather than chaining through it, because a `from`
        // is looked up once.
        to: `Label=${label}, State=${st === 'Default' ? 'enabled' : st}, Selected=${sel === 'yes'}, Indicator=fill`,
        reason:
          'Canvas `orientation` split into Label placement and presence ' +
          '(icon-only is `CoreNavigationLabelMode.none`, not a direction), ' +
          'and `selected` became its own axis — an item is selected while ' +
          'hovered and while disabled, which a `state` member cannot name.',
      })),
    ),
  ),
  // NavigationBarItem — the rest rung takes its R1 name (#4552). The
  // designer's `Default` was the one `State` value on this set outside R1
  // (`state-axis.ts`), and the set now offers `focus` beside it through
  // `stateAxis`, which refuses `Default`. Renamed in place so every member
  // keeps its key and every placed instance its main; `NavigationBar` asks
  // for `State=enabled` in the same change.
  ...(['bottom', 'end', 'none'] as const).flatMap((label) =>
    (['false', 'true'] as const).map((sel) => ({
      component: 'NavigationBarItem' as const,
      from: `Label=${label}, State=Default, Selected=${sel}`,
      to: `Label=${label}, State=enabled, Selected=${sel}, Indicator=fill`,
      reason:
        '#4552 — `State` 쉬는 칸을 R1 이름 `enabled` 로. 같은 세트가 `focus` 를 더하면서 ' +
        '`stateAxis` 를 거치게 됐고, `Default` 는 R1 밖이라 받지 않는다. 이름만 바뀌고 ' +
        '멤버 키는 그대로다.',
    })),
  ),
  // NavigationBarItem — the `Indicator` axis (#5740). How the selected
  // destination is marked became `CoreNavigationSelectionIndicator`: every
  // member the set already had draws the tile, so each gains
  // `, Indicator=fill` and keeps its key. The new `Indicator=color` members
  // (the bar's colour-alone selection) are new nodes.
  ...(['bottom', 'end', 'none'] as const).flatMap((label) =>
    (['enabled', 'hover', 'focus', 'disabled'] as const).flatMap((st) =>
      (['false', 'true'] as const).map((sel) => ({
        component: 'NavigationBarItem' as const,
        from: `Label=${label}, State=${st}, Selected=${sel}`,
        to: `Label=${label}, State=${st}, Selected=${sel}, Indicator=fill`,
        reason:
          '#5740 — 선택 표시가 `Indicator` 축(fill / color)이 됐다. 있던 멤버는 모두 ' +
          '타일(fill)을 그리므로 이름에 `Indicator=fill` 만 붙고 멤버 키는 그대로다.',
      })),
    ),
  ),
  // Button — the generation that absorbs the separate `IconButton` set.
  //
  // `CoreButtonShape` becomes a canvas axis, so every member the set already
  // has gains `, Shape=rectangle` — the shape it was already drawing, under
  // the enum's own default. Nothing about those 360 pictures changes; only
  // their names do, and the names are their identity, so without these rows
  // `finish()` would refuse to explain 360 members and fail the entry whole.
  //
  // The ten legacy single-axis rows above (`Variant=primary` → …) had their
  // `to` patched in the same change rather than chained through here: a `from`
  // is looked up once, so a row pointing at a name this generation renames
  // would be left dangling.
  //
  // Generated, not written out: 324 rows differing in three values is where
  // one goes quietly wrong by hand, and the arithmetic is the same product the
  // builder enumerates. `card` and `link` are not in the list: their members
  // have no destination under the current enumeration (`card` hidden since
  // 0.138, Button · Menu 개편 §7; `link` gone from the enum) and are listed in
  // `buttonHiddenVariantRetirements` instead — a rename whose `to` nothing
  // produces is a dangling row, not a path.
  //
  // `tonal` is in the list although no pre-`Shape` canvas ever had it: it
  // joined after the axis did (designer hand-edit 2026-10-23, drawn straight
  // as `…, Shape=…`). Its rows are no-ops on any canvas — no `from` exists —
  // and are here for the same reason ChatBubble's `plain` row is: so the
  // audit (`auditVariantRenames`), which reconstructs the old generation by
  // projecting today's members onto it, can explain the projection.
  ...(
    [
      'primary',
      'secondary',
      'tonal',
      'outline',
      'ghost',
      'plain',
      'destructive',
      'menu',
      'menubar',
    ] as const
  ).flatMap((v) =>
    (['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const).flatMap((sz) =>
      (['enabled', 'hover', 'focus', 'pressed', 'selected', 'disabled'] as const).map(
        (st) => ({
          component: 'Button' as const,
          from: `Variant=${v}, Size=${sz}, State=${st}`,
          to: composeVariantName([
            ['Variant', v],
            ['Size', sz],
            ['State', st],
            ['Shape', 'rectangle'],
          ]),
          reason:
            'Button gained the `Shape` axis that absorbs the separate ' +
            'IconButton set — a square button is `Button(shape: .square)` and ' +
            'always was, so the drawn members are the `rectangle` rung.',
        }),
      ),
    ),
  ),
  // Filter — the generation that absorbs the designer's segment properties.
  //
  // `Selected` becomes a canvas axis (which of the four drawn segments is
  // current, 1-indexed — one-based because a designer reads it in the Figma
  // panel), so both members the set
  // already has gain `, Selected=1` — the segment they were already drawing as
  // selected. Composed through `composeVariantName` for the same reason the
  // Chip rows are: a `to` spelled by hand could drift from the name
  // `enumerateAxisCombos` mints for the same pose, and `kAxisOrder` puts
  // `Enabled` before `Selected`.
  //
  // The contract then states `enabled` (the filter takes the composed group's
  // flat disabled look), so `Disabled` — a builder pose until then — becomes the
  // schema's own `Enabled` axis, inverted. Every earlier spelling folds
  // straight to the current one: a row that stopped at the intermediate name
  // would point at a member nothing produces.
  //
  // The contract then gains `size` (#6016 — the composed group's size, handed
  // over as is), so every member gains `Size=md`: the members drawn before had
  // no size and were the `md` bar. Rows are one hop, so every earlier spelling
  // goes straight to the `Size=md` name.
  ...(['false', 'true'] as const).flatMap((disabled) => [
    {
      component: 'Filter' as const,
      from: `Variant=segmented, Disabled=${disabled}`,
      to: composeVariantName([
        ['Variant', 'segmented'],
        ['Size', 'md'],
        ['Enabled', disabled === 'true' ? 'false' : 'true'],
        ['Selected', '1'],
      ]),
      reason:
        'Filter gained the `Selected` axis that carries which segment is ' +
        'current — the drawn members had the first segment selected, so they ' +
        'are the `Selected=1` rung — and its `Disabled` pose became the ' +
        "contract's `Enabled` axis (inverted).",
    },
    ...(['1', '2', '3', '4'] as const).map((selected) => ({
      component: 'Filter' as const,
      from: `Variant=segmented, Selected=${selected}, Disabled=${disabled}`,
      to: composeVariantName([
        ['Variant', 'segmented'],
        ['Size', 'md'],
        ['Enabled', disabled === 'true' ? 'false' : 'true'],
        ['Selected', selected],
      ]),
      reason:
        "Filter's `Disabled` pose became the contract's `Enabled` axis " +
        '(inverted): the filter states `enabled` now and takes the composed ' +
        "group's flat disabled look.",
    })),
    ...(['1', '2', '3', '4'] as const).map((selected) => {
      const enabled = disabled === 'true' ? 'false' : 'true';
      return {
        component: 'Filter' as const,
        from: composeVariantName([
          ['Variant', 'segmented'],
          ['Enabled', enabled],
          ['Selected', selected],
        ]),
        to: composeVariantName([
          ['Variant', 'segmented'],
          ['Size', 'md'],
          ['Enabled', enabled],
          ['Selected', selected],
        ]),
        reason:
          'Size 축 신설(#6016 — Filter 가 합성한 ToggleGroup 의 size 를 그대로 받는다) — ' +
          '옛 멤버는 크기를 말하지 않았고 늘 md 막대를 그렸다. 개명이라 key 가 유지되어 ' +
          '그 멤버를 쓰던 인스턴스가 살아남는다. `Size=sm` 은 새 멤버라 이 표에 없다.',
      };
    }),
  ]),
  // Carousel used to fold here — the designer's `Variant=slide|banner ×
  // Size=sm|md` was rewritten to a single Placement axis, and the md
  // members retired. Both are gone: the contract states those two axes now
  // (`CoreCarouselVariant` / `CoreCarouselSize`) and the builder enumerates
  // them, so the canvas keeps the set she drew and there is nothing to
  // rename. A fold row left here would re-collapse it on the next Generate,
  // which is the exact loop that lost her work twice.
  // NavigationBar — the designer's set spelled the bar's shape as `Variant`
  // (bar | rail | sidebar) and carried a `slot` axis for the destination
  // count. The code calls the shape `mode` (`CoreNavigationBarMode`; its
  // `variant` is a different, one-member axis), so the axis moves to `Mode`
  // and gains the builder's three poses. `slot` does not survive as an axis:
  // a count is a `List<W>` length, which Figma cannot bind, and an axis of
  // counts multiplies every other axis by three — it became `Show item N`
  // booleans instead (five drawn, four on), so one member per mode carries
  // the whole range. Which count survives is decided by consumers, not by
  // the drawing: a key that a consuming file instances must be the one that
  // lives, because a rename keeps the key and a retirement kills it — and
  // every instance of it in every file. The published `Variant=bar, slot=3`
  // is instanced 25 times in Unibook; rail and sidebar have no consumers
  // anywhere, so there `slot=4` (the four the default shows) keeps the seat.
  // The other counts retire below.
  ...(
    [
      ['bar', '3'],
      ['rail', '4'],
    ] as const
  ).map(([mode, slot]) => ({
    component: 'NavigationBar' as const,
    from: `Variant=${mode}, slot=${slot}`,
    to: `Variant=standard, Mode=${mode}, Hover=false, Disabled=false, Focus=false`,
    reason:
      '캔버스의 `Variant` 는 코드의 `mode` 다 — 코드의 `variant` 는 `standard` ' +
      '하나뿐인 다른 축. 이름이 `Mode` 로 옮겨가고 빌더의 세 포즈가 붙는다. ' +
      '`slot` 은 개수라 축이 아니라 `Show item N` 불린이 됐고, 살아남는 개수는 ' +
      '소비처가 정한다 — bar 는 유니북이 `slot=3` 키를 25번 쓰므로 그 키가, ' +
      'rail·sidebar 는 소비처가 없어 기본으로 켜지는 넷을 그리던 `slot=4` 가 ' +
      '그 자리를 지킨다.',
  })),
  // #4577 — `CoreTabsContract.size` now reaches axis_reader, so both sets
  // enumerate Size. Existing members were the md row.
  //
  // `Focus=true, Disabled=true` is skipped, and the skip is not an omission:
  // the `State` generation below retires that corner rather than carrying it
  // (no widget draws a focus ring on a disabled tab — `Clickable` renders its
  // outline with `focused: enabled && _focused`). A row pointing at a name
  // nothing produces and nothing picks up is exactly what
  // `auditVariantRenames` calls dangling, so the pose-only spelling is retired
  // directly instead — see `tabItemFocusDisabledRetirements`.
  ...(['pill', 'underline'] as const).flatMap((variant) =>
    (['true', 'false'] as const).flatMap((selected) =>
      (['true', 'false'] as const).flatMap((focus) =>
        (['true', 'false'] as const)
          .filter((disabled) => !(focus === 'true' && disabled === 'true'))
          .map((disabled) => ({
            component: 'TabItem' as const,
            from: `Variant=${variant}, Selected=${selected}, Focus=${focus}, Disabled=${disabled}`,
            to: composeVariantName([
              ['Variant', variant],
              ['Size', 'md'],
              ['Selected', selected],
              ['Focus', focus],
              ['Disabled', disabled],
            ]),
            reason:
              'Gained a `Size` axis — `CoreTabsContract.size` now reaches ' +
              'axis_reader (#4577). Existing members were the md row.',
          })),
      ),
    ),
  ),
  ...(['pill', 'underline'] as const).flatMap((variant) =>
    (['fill', 'scroll'] as const).map((width) => ({
      component: 'Tabs' as const,
      from: `Variant=${variant}, Width=${width}`,
      to: composeVariantName([
        ['Variant', variant],
        ['Size', 'md'],
        ['Width', width],
      ]),
      reason:
        'Gained a `Size` axis — `CoreTabsContract.size` now reaches ' +
        'axis_reader (#4577). Existing members were the md row.',
    })),
  ),
  {
    component: 'Mockup',
    from: 'Variant=window',
    to: 'Variant=app',
    reason:
      'MockupBrowser absorbed MockupWindow: the desktop app window is ' +
      '`MockupBrowser(addressBar: null)`, so this member now instances ' +
      'MockupBrowser with `Show address bar` off. Renamed, not retired, so ' +
      'instances of the window member keep their key.',
  },
  // EmptyState — Variant 철자는 그대로, Tone 축만 추가된다.
  //
  // 빌더는 세트 **밖** 낱개 노드를 위해 이미 `adoptLooseAs: 'Variant=normal,
  // Tone=neutral'` 을 들고 있고, 그 주석이 근거를 적어 뒀다 — 옛 노드는 톤
  // 구분이 없는 렌더였고 그것이 neutral 이다. 세트 **안** 멤버는 그 경로를
  // 타지 않아 S-a 로 떨어지므로 같은 근거를 여기 적는다. 개명이라 key 가
  // 유지돼 그 멤버를 쓰던 인스턴스가 살아남는다 — 손으로 지우면 전부 떨어진다.
  {
    component: 'EmptyState',
    from: 'Variant=normal',
    to: 'Variant=normal, Tone=neutral',
    reason:
      'Tone 축 신설 — 옛 멤버는 톤 구분이 없던 렌더이고 그것이 neutral 이다 ' +
      '(빌더의 `adoptLooseAs` 가 낱개 노드에 대해 내린 것과 같은 판단).',
  },
  {
    component: 'EmptyState',
    from: 'Variant=compact',
    to: 'Variant=compact, Tone=neutral',
    reason: 'Tone 축 신설 — 위 `Variant=normal` 항목과 같은 근거.',
  },
  {
    component: 'EmptyState',
    from: 'Variant=large',
    to: 'Variant=large, Tone=neutral',
    reason: '감사 전용 — 캔버스에 없던 이름이라 실행 시 no-op, 투영 완전성을 위해 둔다',
  },
  // TabItem — `Focus` × `Disabled` 두 불린 축이 `State` 5-rung 으로 접힌다.
  //
  // **순서가 load-bearing 이다**: `from` 은 위 #4577 블록이 이미 `Size=md` 로
  // 옮겨 놓은 이름이라, 이 줄들은 그 블록 **뒤에** 와야 같은 실행에서 연쇄로
  // 적용된다. 앞에 두면 `from` 이 아직 캔버스에 없어 통째로 no-op 이 되고,
  // 다음 `finish()` 가 설명할 수 없는 멤버 48개를 만난다.
  //
  // 세 rung 만 목적지가 있다 — 옛 축은 focus 와 disabled 를 곱했고 새 축은
  // 고른다. `Focus=true, Disabled=true` 는 목적지가 없어 `RETIRED_VARIANTS`
  // 쪽으로 가고(위젯이 도달할 수 없는 자세다), `hover` 와 `pressed` 는 조상이
  // 없는 신규 멤버라 여기 적을 것이 없다.
  ...(['pill', 'underline'] as const).flatMap((variant) =>
    (['sm', 'md', 'lg'] as const).flatMap((size) =>
      (['true', 'false'] as const).flatMap((selected) =>
        (
          [
            ['false', 'false', 'enabled'],
            ['true', 'false', 'focus'],
            ['false', 'true', 'disabled'],
          ] as const
        ).map(([focus, disabled, state]) => ({
          component: 'TabItem' as const,
          from: `Variant=${variant}, Size=${size}, Selected=${selected}, Focus=${focus}, Disabled=${disabled}`,
          to: composeVariantName([
            ['Variant', variant],
            ['Size', size],
            ['State', state],
            ['Selected', selected],
          ]),
          reason:
            '`Focus` · `Disabled` 두 불린 축이 디자이너의 `State` 5-rung 으로 ' +
            '접혔다 — Fab · Checkbox · Toggle 이 쓰는 것과 글자 그대로 같은 ' +
            '집합이고, 리디자인이 `CoreTabsStyle` 에 hover · pressed 워시를 ' +
            '더해 두 rung 이 그릴 것을 갖게 됐다. 개명이라 key 가 유지돼 그 ' +
            '멤버를 쓰던 인스턴스가 살아남는다.',
        })),
      ),
    ),
  ),
  {
    component: 'MockupDevice',
    from: 'Device=phone',
    to: 'Device=phone, Orientation=portrait, Finish=realistic',
    reason:
      'Orientation · Finish 축 신설 — 옛 멤버는 돌리지 않은 기기를 사진처럼 ' +
      '그렸고 그것이 portrait · realistic 이다. 개명이라 key 가 유지되어 그 ' +
      '멤버를 쓰던 인스턴스가 살아남는다. 표는 연쇄하지 않으므로 `to` 는 ' +
      '지금 빌더가 만드는 이름(Finish 까지)이다.',
  },
  {
    component: 'MockupDevice',
    from: 'Device=tablet',
    to: 'Device=tablet, Orientation=portrait, Finish=realistic',
    reason: 'Orientation · Finish 축 신설 — 위 `Device=phone` 항목과 같은 근거.',
  },
  // Progress — Size 철자는 그대로, Tone 축만 추가된다.
  //
  // 옛 멤버는 톤 구분이 없던 막대이고 그 채움은 `primary` 였다 — 그것이
  // `CoreProgressTone.defaultTone` 이다. 빌더의 `adoptLooseAs` 가 세트 밖 낱개
  // 노드에 대해 내린 판단(`Size=md, Tone=primary`)과 같은 근거를 세트 안
  // 멤버에 적는다. 개명이라 key 가 유지돼 그 멤버를 쓰던 인스턴스가 살아남는다.
  // 표는 연쇄하지 않으므로 `to` 는 지금 빌더가 만드는 이름(`Segmented=false`
  // 까지)이다 — 아래 `progressSegmentedAxisRows` 참조.
  ...(['xs2', 'xs', 'sm', 'md', 'lg', 'xl'] as const).map((size) => ({
    component: 'Progress' as const,
    from: `Size=${size}`,
    to: composeVariantName([
      ['Size', size],
      ['Tone', 'primary'],
      ['Segmented', 'false'],
    ]),
    reason:
      'Tone 축 신설 — 옛 멤버는 톤 구분이 없던 막대이고 그 채움이 primary ' +
      '(`CoreProgressTone.defaultTone`) 다. 개명이라 key 가 유지돼 그 멤버를 ' +
      '쓰던 인스턴스가 살아남는다. 그 뒤 Segmented 축이 생겨 연속 막대인 ' +
      '`Segmented=false` 로 바로 간다.',
  })),
  // Progress — `Segmented` 축(단계형 막대, `segments`). 행은
  // `progressSegmentedAxisRows` 가 만든다.
  ...progressSegmentedAxisRows(),
  ...loadingToneAxisRows(),
  // Steps — `Variant` axis (`CoreStepsVariant`: numbered | list). The two
  // members the set drew were the numbered layout in its two orientations, and
  // `numbered` is the variant the widget has always had, so they take it as a
  // prefix: same picture, same key, and the instances a designer placed keep
  // their link. The list is a new member (`Variant=list, Vertical=true`) with
  // no ancestor, so there is nothing to write for it.
  ...(['false', 'true'] as const).map((vertical) => ({
    component: 'Steps' as const,
    from: `Vertical=${vertical}`,
    to: composeVariantName([
      ['Variant', 'numbered'],
      ['Vertical', vertical],
    ]),
    reason:
      '`Variant` 축 신설(`CoreStepsVariant`) — 옛 두 멤버는 numbered 배치의 두 방향이고 ' +
      'numbered 가 위젯이 늘 그려 온 variant 다. 개명이라 key 가 유지되어 그 멤버를 쓰던 ' +
      '인스턴스가 살아남는다.',
  })),
  // ToggleGroup — `Orientation` 축 신설(`direction`)과 `Hover` 축 신설(칸 hover
  // 상태 레이어). 옛 멤버는 늘 가로 한 줄을 그렸고 그것이 Horizontal 이며, 쉬는
  // 그림이 곧 `Hover=false` 다. 이름은 한 홉이다 — 표는 이어 붙지 않으므로 어느
  // 세대의 이름이 캔버스에 남아 있든(Orientation 이전, Orientation 세대) 지금
  // 빌더가 내는 이름 하나로 간다. Vertical · Hover=true 는 새 멤버라 표에 없다.
  // 개명이라 key 가 유지되어 그 멤버를 쓰던 인스턴스(Filter · TimePicker ·
  // ColorPicker)가 살아남는다.
  ...toggleGroupAxisRows(),
  // Finish 축 신설 — Orientation 세대의 네 멤버. 이름 끝에 `, Finish=realistic`
  // 이 붙는다: 옛 멤버는 마감을 말하지 않았고 늘 기기 사진(realistic)을 그렸다.
  // flat 은 새 멤버라 표에 없다.
  ...(['phone', 'tablet'] as const).flatMap((device) =>
    (['portrait', 'landscape'] as const).map((orientation) => ({
      component: 'MockupDevice',
      from: `Device=${device}, Orientation=${orientation}`,
      to: `Device=${device}, Orientation=${orientation}, Finish=realistic`,
      reason:
        'Finish 축 신설 — 옛 멤버는 마감을 말하지 않았고 늘 기기 사진을 ' +
        '그렸으며 그것이 realistic 이다. 개명이라 key 가 유지되어 그 멤버를 ' +
        '쓰던 인스턴스가 살아남는다. flat 은 새 멤버라 이 표에 없다.',
    })),
  ),
  // ColorPicker — `Presentation` 축 신설(`CoreColorPickerPromptMode` 의
  // popover | inline). 옛 네 멤버는 트리거가 여는 팝오버형이었고 그것이 지금도
  // 기본값(`defaultPromptMode`)이다. inline 은 새 멤버라 이 표에 없다.
  ...(['true', 'false'] as const).flatMap((enabled) =>
    (['false', 'true'] as const).map((selected) => ({
      component: 'ColorPicker',
      from: composeVariantName([
        ['Enabled', enabled],
        ['Selected', selected],
      ]),
      to: composeVariantName([
        ['Enabled', enabled],
        ['Selected', selected],
        ['Presentation', 'popover'],
      ]),
      reason:
        'Presentation 축 신설 — 옛 멤버는 트리거가 여는 팝오버형이었고 그것이 ' +
        '기본값(`CoreColorPickerContract.defaultPromptMode`)이다. 개명이라 key 가 ' +
        '유지되어 그 멤버를 쓰던 인스턴스가 팝오버형으로 그려진다. inline 은 새 ' +
        '멤버라 이 표에 없다.',
    })),
  ),
];

// ToggleGroup — 두 세대의 옛 이름을 지금 이름으로. 지금 이름은 `Size · Enabled ·
// Width · Selected · Hover · Orientation` 순서(kAxisOrder)다. 가로 24 멤버는 두
// 세대에서 오고(`Orientation` 이전 · 이후), 세로는 `Size=sm` · `Width=Hug` 여섯
// 멤버만 Orientation 세대에서 온다 — 나머지 세로는 RETIRED_VARIANTS
// (`toggleGroupVerticalRetirements`).
function toggleGroupAxisRows(): VariantRename[] {
  const rows: VariantRename[] = [];
  const reason =
    'Hover 축 신설(칸 hover 상태 레이어) — 옛 멤버는 hover 를 그리지 않았고 그 쉬는 ' +
    '그림이 `Hover=false` 다. 개명이라 key 가 유지되어 그 멤버를 쓰던 인스턴스가 ' +
    '살아남는다. `Hover=true` 는 새 멤버라 이 표에 없다.';
  for (const size of ['md', 'sm'] as const) {
    for (const enabled of ['true', 'false'] as const) {
      for (const width of ['Hug', 'Fill'] as const) {
        for (const selected of ['1', '2', '3'] as const) {
          const pose: [AxisName, string][] = [
            ['Size', size],
            ['Enabled', enabled],
            ['Width', width],
            ['Selected', selected],
          ];
          const to = composeVariantName([
            ...pose,
            ['Hover', 'false'],
            ['Orientation', 'Horizontal'],
          ]);
          // Orientation 이전 세대.
          rows.push({
            component: 'ToggleGroup',
            from: composeVariantName(pose),
            to,
            reason:
              'Orientation · Hover 축 신설 — 옛 멤버는 늘 가로 한 줄을 그렸고 ' +
              '(Horizontal) hover 를 그리지 않았다(Hover=false). 개명이라 key 가 ' +
              '유지되어 그 멤버를 쓰던 인스턴스가 살아남는다.',
          });
          // Orientation 세대.
          rows.push({
            component: 'ToggleGroup',
            from: composeVariantName([...pose, ['Orientation', 'Horizontal']]),
            to,
            reason,
          });
        }
      }
    }
  }
  // 살아남는 세로: `Size=sm` · `Width=Hug`.
  for (const enabled of ['true', 'false'] as const) {
    for (const selected of ['1', '2', '3'] as const) {
      const pose: [AxisName, string][] = [
        ['Size', 'sm'],
        ['Enabled', enabled],
        ['Width', 'Hug'],
        ['Selected', selected],
      ];
      rows.push({
        component: 'ToggleGroup',
        from: composeVariantName([...pose, ['Orientation', 'Vertical']]),
        to: composeVariantName([...pose, ['Hover', 'false'], ['Orientation', 'Vertical']]),
        reason,
      });
    }
  }
  return rows;
}

// ToggleGroup 세로의 은퇴 — 캔버스는 세로를 `Size=sm` · `Width=Hug` 만 그린다
// (유일한 소비처인 TimePicker AM/PM 이 쓰는 모양). `md` 세로 12 · `Width=Fill`
// 세로 6 은 소비처가 없어 목적지 없이 은퇴한다. 코드의 `direction` 은 그대로이고
// 캔버스의 표현만 좁아진다. 이름은 은퇴 직전 세대(Orientation 세대)의 것이다 —
// 그려진 적이 없으면 no-op 이다.
function toggleGroupVerticalRetirements(): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  for (const size of ['md', 'sm'] as const) {
    for (const width of ['Hug', 'Fill'] as const) {
      if (size === 'sm' && width === 'Hug') continue;
      for (const enabled of ['true', 'false'] as const) {
        for (const selected of ['1', '2', '3'] as const) {
          rows.push({
            component: 'ToggleGroup',
            name: composeVariantName([
              ['Size', size],
              ['Enabled', enabled],
              ['Width', width],
              ['Selected', selected],
              ['Orientation', 'Vertical'],
            ]),
            reason:
              '세로 ToggleGroup 은 `Size=sm` · `Width=Hug` 하나만 그린다 — 유일한 소비처' +
              '(TimePicker AM/PM)가 쓰는 모양이다. `Width=Fill` 은 가로 폭을 채우는 ' +
              '옵션이라 세로 배치와 함께 쓸 곳이 아직 없고, `md` 세로는 소비처가 없다. ' +
              '코드의 `direction` 은 그대로이며 캔버스의 표현만 좁아진다. 이 멤버를 ' +
              '쓰는 인스턴스는 없다(소비처는 모두 Orientation=Horizontal).',
          });
        }
      }
    }
  }
  return rows;
}

// One `Size=md` member per pose keeps its identity under the pose-only name;
// the pose axes are booleans, so the rows are the boolean product. Generated
// because 4 + 8 rows that differ only in true/false is where one gets missed.
function sizeAxisDroppedRows(component: string, poses: readonly string[]): VariantRename[] {
  const rows: VariantRename[] = [];
  const combos = poses.reduce<string[][]>(
    (acc, axis) => acc.flatMap((prefix) => ['true', 'false'].map((v) => [...prefix, `${axis}=${v}`])),
    [[]],
  );
  for (const parts of combos) {
    rows.push({
      component,
      from: `${parts.join(', ')}, Size=md`,
      to: parts.join(', '),
      reason:
        '캔버스의 `Size` 축을 접는다 — 코드에 size 축이 없고(`sizes: {}`), md 가 항상 그리던 ' +
        '크기라 그 멤버가 키를 지킨다. 나머지 네 크기는 RETIRED_VARIANTS.',
    });
  }
  return rows;
}

// Node-type migrations: a name whose SHAPE changed (COMPONENT ↔
// COMPONENT_SET) between runs. Figma has no API to convert one node type
// into the other in place, so the old-shaped node cannot be recycled — it is
// explicitly, loudly retired here exactly once. This is NOT the same
// mechanism as #3744's opt-in phantom removal: the name still exists in
// REGISTRY (unlike a true phantom), it just cannot keep its old identity
// across a shape change. Left undocumented, the old node would otherwise
// stay as a silent duplicate now that generate.ts no longer bulk-deletes.
export interface StructuralMigration {
  name: string;
  oldType: 'COMPONENT' | 'COMPONENT_SET';
  reason: string;
}

export const STRUCTURAL_MIGRATIONS: StructuralMigration[] = [
  {
    name: 'Divider',
    oldType: 'COMPONENT',
    reason: '#3743 — Divider grew a label/orientation variant matrix (single ComponentNode → ComponentSetNode).',
  },
  {
    name: 'Hero',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Layout` axis (center | split) and a `media` instance-swap slot ' +
      '(single ComponentNode → ComponentSetNode). The published component was the ' +
      'centered child-only pose, so ADE/Assets could not select a copy|media split. ' +
      'Figma cannot convert COMPONENT → COMPONENT_SET in place.',
  },
  // `Mockup` 은 여기 없다 — 있었고, 그게 결함이었다.
  //
  // #3742 는 낡은 `Mockup` 세트를 넷으로 쪼갰지만 그 뒤 같은 이름이 **우산
  // 세트**로 되살아났다(`buildMockup`, Variant=browser·code·phone·app, 각 멤버가
  // 진짜 컴포넌트를 인스턴스한다). 그래서 이 표의 (name, oldType) 이 빌더가
  // 지금 만드는 모양과 정확히 일치하게 됐고, `applyStructuralMigrations` 의
  // `if (!node) continue // already migrated` 전제가 깨졌다 — 빌더가 매번 다시
  // 만들어 두므로 매 실행 remove → rebuild 가 돌았다. 세트를 지우면 key 가
  // 죽으므로 **매 Generate 마다 소비 파일의 인스턴스가 떨어져 나갔고**, 갓
  // 만든 노드에는 지문이 없어 손 편집 보존도 원리적으로 동작하지 못했다.
  // 아래 selftest 가 같은 형태의 항목을 다시 못 들어오게 막는다.
  {
    name: 'Diff',
    oldType: 'COMPONENT',
    reason:
      'Gained a `State` axis (single ComponentNode → ComponentSetNode). The ' +
      'redesigned split carries a round handle whose cast and size change with ' +
      'the pointer (`handleHoverShadow`, `handlePressedShadow`, ' +
      '`handlePressedScale`), a keyboard focus ring on it, and no handle at all ' +
      'when `interactive` is false — and only the resting pose was drawn, so ' +
      'those fields were stated by Core and had no node on the canvas to live on. ' +
      'Figma cannot turn a COMPONENT into a COMPONENT_SET in place, so without ' +
      'this entry the old single component lingers on the page as a silent ' +
      'duplicate under the same name.',
  },
  {
    name: 'Subfocus',
    oldType: 'COMPONENT',
    reason:
      'Gained an `Enabled` axis (single ComponentNode → ComponentSetNode). The ring '
      + 'is the whole drawing this component owns and it is conditional: '
      + '`subfocus.dart` computes `_isFocused => _focused && widget.enabled`, so a '
      + 'disabled item inside a focused scope draws no ring at all. Only the ringed '
      + 'pose was on the canvas, under a comment that read the widget\'s own '
      + '`enabled` as absence rather than as a member.',
  },
  {
    name: 'Steps',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Vertical` axis (single ComponentNode → ComponentSetNode). ' +
      '`Steps(vertical: bool)` branches into `_buildVertical` / ' +
      '`_buildHorizontal`, and only the horizontal branch was drawn — so ' +
      '`stepPadding` (the vertical layout\'s per-step inset) and ' +
      '`indicatorContentGapStyle` (which appears in `_buildVertical` only) ' +
      'were stated by Core and had no node on the canvas to live on.',
  },
  {
    name: 'Window',
    oldType: 'COMPONENT',
    reason:
      'Gained `Focused` and `Minimized` axes (single ComponentNode → ' +
      'ComponentSetNode). `window.dart` reads both as runtime state — ' +
      '`focused` swaps the panel bundle\'s `titleStyle` for ' +
      '`unfocusedTitleStyle`, and `_viewport.minify` scales the whole window ' +
      'by `minimizedScale` — and only the focused, full-size pose was drawn, ' +
      'so those two fields were stated by Core and had no node on the canvas ' +
      'to live on.',
  },
  {
    name: 'Stat',
    oldType: 'COMPONENT',
    reason:
      'Gained a `ChangeType` axis (single ComponentNode → ComponentSetNode). ' +
      '`stat.dart` switches on `CoreStatChangeType` twice — once for the trend ' +
      'glyph and once for the change colour — and only the positive pose was ' +
      'drawn, so `negativeColor` and `neutralColor` were stated by Core and ' +
      'had no node on the canvas to live on.',
  },
  {
    name: 'Slider',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Disabled` axis (single ComponentNode → ComponentSetNode). Both ' +
      'resolvers key three colours on `enabled` — `disabledTrackColor` for the ' +
      'rail, `disabledActiveColor` for the filled bar AND for the thumb’s border ' +
      '— and only the enabled pose was drawn, so those two fields were stated by ' +
      'Core and had no node on the canvas to live on. The thumb’s own fill is ' +
      'resolved outside that branch and is unchanged in both poses.',
  },
  {
    name: 'Command',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Disabled` axis and then an `Empty` axis (single ComponentNode → ' +
      'ComponentSetNode). `_buildResults` returns an empty-state branch instead ' +
      'of the list, and disabled rows carry their own foreground — only the ' +
      'enabled, populated pose was drawn, so the fields stating those poses were ' +
      'stated by Core and had no node on the canvas to live on. Figma cannot ' +
      'turn a COMPONENT into a COMPONENT_SET in place, so without this entry ' +
      'the old single component lingers on the page as a silent duplicate ' +
      'under the same name.',
  },
  {
    name: 'NavigationMenu',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Hover` axis (single ComponentNode → ComponentSetNode). ' +
      '`triggerHoverColor` is a flat `CoreNavigationMenuStyle` field — not part ' +
      'of the nested `triggerButtonStyle` — and the Web resolver emits it as the ' +
      'trigger’s own `background-color` when that trigger is `highlighted` ' +
      '(`_openIndex == i || _hoveredTrigger == i`), so the colour was stated by ' +
      'Core and had no node on the canvas to live on. The builder previously read ' +
      'the hover half as the composed `Button`’s state, which is true of ' +
      '`Menubar` (no state colour of its own) and not of this component.',
  },
  {
    name: 'FocusOutline',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Shape` axis (single ComponentNode → ComponentSetNode) that ' +
      '`CoreFocusOutlineShape` states and the designer had already drawn as a ' +
      'set of the same name. The two nodes shared one name on one page, and ' +
      'the document index keeps whichever sorts first — so consumers named ' +
      '`FocusOutline` were handed a different main from run to run. Removing ' +
      'the single node is safe because every instance of it is builder-minted: ' +
      'InputOtp, Range, ChipInput and DotIndicator re-create theirs on each ' +
      'Generate against the set, and the designer\'s own instances already ' +
      'point at the set\'s members.',
  },
  {
    name: 'DotIndicator',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Size` axis (`CoreDotIndicatorSize`, the contract\'s own) and a ' +
      '`Selected` pose axis (single ComponentNode → ComponentSetNode) that the ' +
      'designer had already drawn as a set of the same name. On the live file ' +
      'the lone builder COMPONENT is already gone — the designer combined it into ' +
      'the set — so this is a no-op there; a document that still has the old ' +
      'shape must not keep two same-named nodes, because the document index ' +
      'keeps whichever sorts first and consumers (`Carousel`) are handed a ' +
      'different main from run to run (the `FocusOutline` lesson above). Every ' +
      'instance of the single node is builder-minted (Carousel re-creates its ' +
      '`dots` on each Generate against the set), so removing it is safe.',
  },
  {
    name: 'Footer',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Layout` axis (`CoreFooterLayout`: horizontal | vertical | ' +
      'center) and an `Info` pose axis (single ComponentNode → ' +
      'ComponentSetNode) that the designer had already drawn as a set of the ' +
      'same name. The builder used to read `layout` once from the field and ' +
      'mint one member, so her set and its component sat under one name on one ' +
      'page — and the document index keeps whichever sorts first, which hands ' +
      'consumers a different main from run to run (the `FocusOutline` lesson ' +
      'above). On the live file both nodes are present, so this removes the ' +
      'builder\'s COMPONENT and `mountSet` then finds her SET by name and ' +
      'reuses its members — her component keys survive. This pass runs before ' +
      'the builders, so on a document that holds ONLY the old single node the ' +
      'removal wins over `buildFooter`\'s `adoptLooseAs` and the set is minted ' +
      'fresh; that is the intended trade, because two nodes under one name is ' +
      'the failure with no recovery.',
  },
  {
    name: 'Carousel',
    oldType: 'COMPONENT',
    reason:
      'Gained axes (single ComponentNode → ComponentSetNode) that the contract ' +
      'states — `CoreCarouselVariant` × `CoreCarouselSize`, which is the set the ' +
      'designer drew. On the live file she already combined the builder\'s ' +
      'component into that set, so this is a no-op there; a document that still ' +
      'holds the old shape must not keep two nodes under one name (the ' +
      'FocusOutline lesson — `mint` and the index disagree).',
  },
  {
    name: 'TabPane',
    oldType: 'COMPONENT',
    reason:
      'Gained a `Variant` axis (`CoreTabPaneVariant`: boxed | editorStrip) ' +
      '(single ComponentNode → ComponentSetNode). The published component was ' +
      'the boxed card only, so a consumer could not select `Variant=editorStrip`. ' +
      '`editorStrip` is the strip-only pose from `CoreTabPaneStyle.editorStrip` / ' +
      '`defaultsByVariant` — no content panel, no T-junction overlap, strip band ' +
      'fill, inter-tab hairline, flush corners. Figma cannot turn a COMPONENT ' +
      'into a COMPONENT_SET in place, so without this entry the old single ' +
      'component stays on the page as a same-named duplicate. There is no chrome ' +
      'or theme axis on TabPane; dark appearance comes from CoUI mode variables ' +
      'on the product canvas. ' +
      'v2: the editorStrip selected tab carries an inside top bar ' +
      '(`indicatorColor` × `indicatorWidth`, no layout) and a tab with ' +
      '`onClose` draws the close box (`closeButtonStyle`) around the 12 px glyph ' +
      '(`closeIconStyle`) behind a `Show close` BOOLEAN. ' +
      'P6-c: the tab is its own `TabPaneTab` set (`Variant` × `Selected`, ' +
      '`Label` · `Show leading`/`Leading` · `Show trailing`/`Trailing` · ' +
      '`Show count` · `Show close`) and the strip places exposed instances of ' +
      'it. That is a property move, not a shape change, so it needs no row ' +
      'here: the strip\'s own `Tab N label` · `Show leading` · `Leading` · ' +
      '`Show trailing` · `Trailing` · `Show count` · `Show close` bind no ' +
      'layer any more and Generate\'s unbound-property cleanup removes them ' +
      '(an instance\'s value for one of them is dropped; the same value now ' +
      'lives on the nested tab). `Content` and `Show disabled tab` stay.',
  },
];

function isComponentLike(
  node: SceneNode,
): node is ComponentNode | ComponentSetNode {
  return node.type === 'COMPONENT' || node.type === 'COMPONENT_SET';
}

// The three `apply*` functions below read `page.children` synchronously and
// stay synchronous on purpose: their only caller is `generateComponents`, which
// has already `await page.loadAsync()`-ed the page it hands them (a PageNode's
// `.children` throws until then under manifest documentAccess:
// "dynamic-page"). Making them async would push that `await` onto a caller that
// already did the work. The retire pair at the bottom of this file is async for
// the opposite reason — its caller hands it pages nothing has loaded.

// Renames the on-page node matching `from` to `to`, in place — never
// removes, never creates. Idempotent: a second run finds nothing under
// `from` (it's already `to`) and does nothing.
export function applyPendingRenames(page: PageNode, renames: readonly SetRename[]): string[] {
  const log: string[] = [];
  for (const r of renames) {
    const node = page.children.find((n) => isComponentLike(n) && n.name === r.from);
    if (!node) continue; // already renamed, or nothing to rename on a fresh page
    node.name = r.to;
    log.push(`renamed "${r.from}" → "${r.to}" (${r.reason})`);
  }
  return log;
}

export function applyPendingVariantRenames(
  page: PageNode,
  renames: readonly VariantRename[],
): string[] {
  const log: string[] = [];
  for (const r of renames) {
    const set = page.children.find(
      (n): n is ComponentSetNode => n.type === 'COMPONENT_SET' && n.name === r.component,
    );
    if (!set) continue;
    const child = set.children.find((c) => c.name === r.from);
    if (!child) continue; // already renamed, or nothing to rename
    child.name = r.to;
    log.push(`${r.component}: renamed variant "${r.from}" → "${r.to}" (${r.reason})`);
  }
  return log;
}

// Removes the old-shaped node for each STRUCTURAL_MIGRATIONS entry, exactly
// once. This is the one explicitly-documented exception to "never remove a
// persistent node" — the alternative is a silent, permanent duplicate.
export function applyStructuralMigrations(
  page: PageNode,
  migrations: readonly StructuralMigration[],
): string[] {
  const log: string[] = [];
  for (const m of migrations) {
    const node = page.children.find((n) => n.type === m.oldType && n.name === m.name);
    if (!node) continue; // already migrated (removed) on a previous run
    node.remove();
    log.push(`removed superseded ${m.oldType} "${m.name}" (${m.reason}) — rebuilding as the new shape`);
  }
  return log;
}

/** Apply identity migrations only to entries the current Generate run builds.
 * A scoped run may still load the whole file (for example when forced), but
 * loading a page must never authorize migrations on unrelated components. */
export function applyScopedMigrations(
  page: PageNode,
  scopedNames: ReadonlySet<string> | null,
  tables: {
    sets: readonly SetRename[];
    variants: readonly VariantRename[];
    structural: readonly StructuralMigration[];
  },
): string[] {
  const includes = (name: string): boolean => scopedNames === null || scopedNames.has(name);
  const log = [
    ...applyPendingRenames(page, tables.sets.filter((r) => includes(r.to))),
    ...applyPendingVariantRenames(page, tables.variants.filter((r) => includes(r.component))),
    ...applyStructuralMigrations(page, tables.structural.filter((r) => includes(r.name))),
  ];
  // A partial run cannot know which legacy heading belongs to an entry it
  // does not build. Retain all of them; a full run can clean up as before.
  if (scopedNames === null) {
    for (const node of page.children.slice()) {
      if (node.type === 'TEXT' && node.name.startsWith('Section / ')) node.remove();
    }
  }
  return log;
}

// ─── Phantom removal (#3744) — explicit opt-in, never automatic ─────────────
//
// A component removed from REGISTRY stops appearing in `names` (the
// idempotency set generate.ts used to bulk-delete by), so it simply becomes
// invisible to every automatic path — mint-by-name (#3737) never touches a
// name it isn't asked to build, on purpose. Without a list naming it
// explicitly, a retired entry's old node sits on the page forever with no
// path back to a designer's attention. This list is that path — dry-run
// first, delete only via a separate explicit action, never from Generate
// Components itself.
export interface RetiredVariant {
  /** The set's CURRENT name (post SET_RENAMES, if any). */
  component: string;
  /** Variant child name with no destination under the 4-axis enumeration. */
  name: string;
  reason: string;
}

// Button members with no place on the canvas — every pose of the variants
// listed in `hidden` below.
//
// `text` and `fixed` stay in the enum and the style table; the exporter keeps
// them off the canvas (`axes.variant.hidden`). `text` is `@Deprecated` with a
// message that has said "Dropped from the Figma Button variant set" since it
// was written; nothing on this side ever kept that promise, so Generate
// re-drew its 36 members on every run. `fixed` is `@behaviourOnly`: CardImage's
// invisible button, a mechanism that sat on the canvas beside `primary` as if
// a designer could pick it. `card` and `link` are not in the enum any more, so
// their members have no `Variant=` to become.
//
// Generated, not hand-written: a variant × 6 sizes × 6 states is 72 rows that
// differ in nothing but the coordinates, and a hand-written table that long is
// where one gets missed. The bare single-axis names are the pre-Size-axis
// children a very old canvas could still hold; their rename rows used to point
// at the md·enabled member, which no longer exists to point at, so they retire
// directly.
function buttonHiddenVariantRetirements(): RetiredVariant[] {
  const hidden: ReadonlyArray<[string, string]> = [
    ['text', '@Deprecated (since 0.130) — 디자인 시스템이 변형 수를 줄였고 메시지가 "Figma 세트에서 뺀다" 고 말한다'],
    ['fixed', '@behaviourOnly — CardImage 가 누르는 카드를 감싸는 보이지 않는 버튼, 디자이너의 선택지가 아니다'],
    // Button · Menu 개편 §7 — a pressable box is `outline` with the box
    // radius, not a Button variant. 108 members (6 sizes × 6 states × 3
    // shapes) plus the two older shapes of the name.
    ['card', '@Deprecated (since 0.138) — outline + borderRadius radius16 이 같은 모양이다 (Button · Menu 개편 §7)'],
    // The enum value is gone, so the 108 members have no `Variant=link` to
    // become. It drew the same picture as `plain`; a destination is a `Link`,
    // a sentence's link is `Link.inlineSpan`, an action is `plain`.
    ['link', 'CoreButtonVariant.link 이 없어졌다 — plain 과 같은 그림이고, 이동은 Link · 문장 속 링크는 Link.inlineSpan · 동작은 plain 이다'],
  ];
  const sizes = ['xs', 'sm', 'md', 'lg', 'xl', 'xl2'];
  const states = ['enabled', 'hover', 'focus', 'pressed', 'selected', 'disabled'];
  // The canvas has carried a `Shape` axis since the icon-only forms landed,
  // so a member's current name has four parts; the three-part name is what
  // an older canvas still holds. Both are listed — a retirement is a path
  // back to a designer's attention, and a name that is not listed has none.
  const shapes = ['rectangle', 'square', 'circle'];
  const rows: RetiredVariant[] = [];
  for (const [variant, why] of hidden) {
    rows.push({ component: 'Button', name: `Variant=${variant}`, reason: `${why} (구 단일축 자식)` });
    for (const size of sizes) {
      for (const state of states) {
        rows.push({
          component: 'Button',
          name: `Variant=${variant}, Size=${size}, State=${state}`,
          reason: why,
        });
        for (const shape of shapes) {
          rows.push({
            component: 'Button',
            name: `Variant=${variant}, Size=${size}, State=${state}, Shape=${shape}`,
            reason: why,
          });
        }
      }
    }
  }
  return rows;
}

// The four sizes a composed-TextField input never had. The canvas drew
// FormattedInput and PhoneInput at sm/lg/xl/xl2 as well as md; the code sizes
// neither (`sizes: {}`), so those members promised a rendering the app does
// not produce. md survives through the rename rows above; these go.
function sizeAxisDroppedRetirements(
  component: string,
  poses: readonly string[],
  why: string,
): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  const combos = poses.reduce<string[][]>(
    (acc, axis) => acc.flatMap((prefix) => ['true', 'false'].map((v) => [...prefix, `${axis}=${v}`])),
    [[]],
  );
  for (const parts of combos) {
    for (const size of ['sm', 'lg', 'xl', 'xl2']) {
      rows.push({ component, name: `${parts.join(', ')}, Size=${size}`, reason: why });
    }
  }
  return rows;
}

/**
 * `Enabled` 세대(3축·4축)의 이름 중 사다리 밖 tier 를 가리키던 것들. 이관
 * 목적지(`…Size=xs|xl|xl2…`)가 사라졌으므로 한 hop 더 가는 대신 여기서 끝난다.
 */
function chipEnabledEraRetirements(): RetiredVariant[] {
  return [
    {
      component: 'Chip',
      name: 'Size=xs, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Size=xs, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Size=xl, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Size=xl, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Size=xl2, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Size=xl2, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xs, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xs, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xl, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xl, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xl2, Enabled=true',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
    {
      component: 'Chip',
      name: 'Variant=neutral, Size=xl2, Enabled=false',
      reason: 'Enabled 세대의 이름 — 사다리 밖 tier(xs·xl·xl2)라 이관 목적지가 죽었다',
    },
  ];
}

/**
 * 318-세대 이름 중 빌더가 더는 만들지 않는 것들 — `xs` / `xl` / `xl2` 사이즈와
 * `State=focus`. 세 사이즈는 8월에 "24 는 Badge, 48·56 은 Button 의 자리" 로
 * 내려진 결정이 세트에 늦게 도달한 것이고, `focus` 는 `Show focus ring`
 * 프로퍼티와 같은 그림을 두 번째 이름으로 그리던 rung 이다. 목적지가 없으니
 * 이관이 아니라 은퇴다.
 *
 * 값 목록을 하드코딩하는 것은 의도적이다 — 은퇴 목록은 **캔버스에 있던
 * 이름**을 가리키므로 그 시절의 축 값이어야 하고, 빌더의 현재 축을 따라가면
 * 축이 바뀌는 날 지워야 할 이름을 못 찾는다.
 */
function chipDroppedTierRetirements(): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  for (const Variant of ['neutral', 'primary', 'secondary', 'tertiary']) {
    for (const Size of ['xs', 'sm', 'md', 'lg', 'xl', 'xl2']) {
      for (const State of ['enabled', 'hover', 'focus', 'pressed', 'disabled']) {
        for (const Selected of ['false', 'true']) {
          for (const Emphasis of ['low', 'high']) {
            const droppedSize = Size === 'xs' || Size === 'xl' || Size === 'xl2';
            const droppedState = State === 'focus';
            if (!droppedSize && !droppedState) continue;
            rows.push({
              component: 'Chip',
              name:
                `Variant=${Variant}, Size=${Size}, State=${State}, ` +
                `Selected=${Selected}, Emphasis=${Emphasis}`,
              reason: droppedSize
                ? '사다리는 sm·md·lg 셋 — 24 는 Badge, 48·56 은 Button 의 자리라 이 tier 는 Chip 이 갖지 않는다'
                : 'focus 는 상태가 아니라 `Show focus ring` 의 표현 — 같은 그림을 두 번째 이름으로 그리던 rung',
            });
          }
        }
      }
    }
  }
  return rows;
}
/**
 * `TabItem` 의 `Focus=true, Disabled=true` — 옛 축의 곱이 만든 12개.
 *
 * 옛 축은 `Focus` 와 `Disabled` 를 **곱했고** 새 `State` 축은 **고른다**.
 * 나머지 세 조합은 `VARIANT_RENAMES` 가 `enabled` · `focus` · `disabled` 로
 * 옮기지만 이 하나는 목적지가 없다 — 그리고 없는 것이 옳다: 비활성 탭은
 * 포커스를 받지 못하므로(`Clickable` 이 `enabled: false` 일 때 포커스를
 * 요청하지 않는다) 두 위젯 중 어느 것도 이 그림을 그리지 않는다. 캔버스는
 * 도달할 수 없는 자세를 멤버로 갖고 있었던 셈이다.
 *
 * 이름은 옛 세대의 철자 그대로다 — 은퇴 목록은 **캔버스에 있던 이름**을
 * 가리키므로 그 시절의 축과 순서여야 한다(`chipDroppedTierRetirements` 의
 * 같은 주석).
 */
/**
 * `FormLabel` · `Fieldset` 의 반복 칸 — 크기 단계 결정(2026-10-01)으로 두 세트는
 * `Size` 를 그림 하나당 한 칸(`md · lg`)으로 그린다.
 *
 * 두 사다리는 공용 6단을 받지만 그림은 둘이다 — `xs`/`sm`/`md` 가 한 행,
 * `lg`/`xl`/`xl2` 가 다른 행. 남은 네 칸은 옆 칸과 같은 그림을 다른 이름으로
 * 그리던 멤버라 목적지가 없다(두 칸을 한 이름으로 옮길 수 없다). `md` · `lg`
 * 멤버는 그대로 남아 키를 지킨다. 이름은 캔버스에 있던 철자 그대로다.
 */
function repeatedSizeCellRetirements(component: 'FormLabel' | 'Fieldset'): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  for (const size of ['xs', 'sm', 'xl', 'xl2']) {
    for (const enabled of ['true', 'false']) {
      rows.push({
        component,
        name: `Size=${size}, Enabled=${enabled}`,
        reason:
          '크기 단계 결정(2026-10-01) — 이 세트는 사다리의 그림 하나당 한 칸(`md · lg`)으로 ' +
          '그린다. 이 칸은 옆 칸과 같은 행을 그리던 반복이라 목적지가 없다.',
      });
    }
  }
  return rows;
}

function tabItemFocusDisabledRetirements(): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  const reason =
    '`Focus` × `Disabled` 곱이 `State` 5-rung 으로 접히면서 목적지를 잃은 ' +
    '모서리 — 비활성 탭은 포커스를 받지 못해(`Clickable` 은 링을 ' +
    '`focused: enabled && _focused` 로 그린다) 어느 위젯도 이 그림을 그리지 ' +
    '않는다. 나머지 세 조합은 개명으로 살아남는다.';
  for (const Variant of ['pill', 'underline']) {
    // `Size` 세대와 그 이전 세대 둘 다 — 문서마다 마지막으로 Generate 를 돌린
    // 시점이 달라 캔버스에 어느 철자가 있는지는 문서가 정한다. 두 이름 모두
    // 도달할 곳이 없으므로 둘 다 은퇴시킨다.
    for (const Size of ['sm', 'md', 'lg']) {
      for (const Selected of ['true', 'false']) {
        rows.push({
          component: 'TabItem',
          name:
            `Variant=${Variant}, Size=${Size}, Selected=${Selected}, ` +
            `Focus=true, Disabled=true`,
          reason,
        });
      }
    }
    for (const Selected of ['true', 'false']) {
      rows.push({
        component: 'TabItem',
        name: `Variant=${Variant}, Selected=${Selected}, Focus=true, Disabled=true`,
        reason,
      });
    }
  }
  return rows;
}

/**
 * Skeleton 의 `Enabled=false` 세 멤버 — `Enabled` 축이 사라지면서(#5234) 목적지를
 * 잃는다. 계약이 `enabled` 를 들고 있던 동안에도 이 멤버는 `Enabled=true` 와
 * 같은 그림이었다(`defaultsByVariant` 에 disabled 크롬이 없다) — 그래서 옮길
 * 곳이 아니라 반복이고, `Enabled=true` 멤버가 개명으로 key 를 지킨다.
 */
function skeletonDisabledRetirements(): RetiredVariant[] {
  return (['rectangular', 'circular', 'text'] as const).map((variant) => ({
    component: 'Skeleton',
    name: `Variant=${variant}, Enabled=false`,
    reason:
      'Enabled 축 소멸(#5234) — 그릴지는 호출하는 쪽 조건이 정하므로 계약에 켜짐 ' +
      '스위치가 없다. 이 멤버는 같은 변형의 `Enabled=true` 와 같은 그림을 그리던 ' +
      '반복이라 목적지가 없다.',
  }));
}

/**
 * Link 의 `Disabled=true` 여섯 멤버 — `Disabled` 축이 사라지면서(#5389) 목적지를
 * 잃는다. 코드의 `Link` 에는 비활성 상태가 없다(`enabled` 도 없고 `Clickable` 에
 * 넘기지도 않는다) — 이 멤버들은 빌더가 `CoreClickableStyle.defaultDisabledOpacity`
 * 를 루트에 칠해 코드에 없는 상태를 그린 것이다. 파일 안 비활성 인스턴스는 0 이다.
 */
function linkDisabledRetirements(): RetiredVariant[] {
  const rows: RetiredVariant[] = [];
  for (const kind of ['default', 'underline', 'muted']) {
    for (const focus of ['false', 'true']) {
      rows.push({
        component: 'Link',
        name: `Variant=${kind}, Disabled=true, Focus=${focus}`,
        reason:
          'Disabled 축 소멸(#5389) — 코드의 `Link` 에는 비활성 상태가 없다. 이 멤버는 ' +
          '빌더가 코드에 없는 상태를 그린 것이라 목적지가 없다.',
      });
    }
  }
  return rows;
}

export const RETIRED_VARIANTS: RetiredVariant[] = [
  ...chipRetiredColourRows(),
  ...tabItemFocusDisabledRetirements(),
  ...linkDisabledRetirements(),
  ...repeatedSizeCellRetirements('FormLabel'),
  ...repeatedSizeCellRetirements('Fieldset'),
  ...skeletonDisabledRetirements(),
  ...badgePoseRetirements(),
  ...toggleGroupVerticalRetirements(),

  // #4726 — Tabs / TabItem 의 좁혀진 크기 사다리.
  //
  // `axes.size` 가 `CoreComponentSize` 이던 동안 두 세트는 여섯 rung 을 전부
  // 그렸다(#4577). 리디자인이 그것을 sm/md/lg 로 좁혔으므로 나머지 셋은 목적지가
  // 없다 — VARIANT_RENAMES 가 옛 무-Size 이름을 `Size=md` 로 옮기는 것과 짝이 되는
  // 반대쪽이다. 살아있는 캔버스에 그 멤버가 없으면 이 줄들은 no-op 이다.
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xs, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xs, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xs, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xs, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xs, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xs, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xl, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xl, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xl, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xl, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=pill, Size=xl2, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=true, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=true, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=true, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=true, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=false, Focus=true, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=false, Focus=true, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=false, Focus=false, Disabled=true',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'TabItem',
    name: 'Variant=underline, Size=xl2, Selected=false, Focus=false, Disabled=false',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xl2, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=pill, Size=xl2, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xl2, Width=fill',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Tabs',
    name: 'Variant=underline, Size=xl2, Width=scroll',
    reason:
      '#4726 — Tabs 의 크기 사다리가 공용 6단(`CoreComponentSize`)에서 ' +
      'Tabs 전용 3단(`CoreTabsSize` sm/md/lg)으로 좁혀졌다. 이 rung 은 ' +
      '목적지가 없어 명시 은퇴한다 — 캔버스에 그려진 적이 없으면 no-op 이고, ' +
      '그려졌다면 이 줄이 없을 때 `finish()` 가 설명할 수 없는 멤버를 만난다.',
  },
  {
    component: 'Command',
    name: 'Variant=standard, Disabled=true, Empty=false',
    reason:
      'The `Disabled` axis is gone with the 2026-09 redesign: an overlay that ' +
      'cannot be used is not opened, and the inline case is the composed ' +
      '`TextField`\'s own disabled state, not a palette pose.',
  },
  {
    component: 'Command',
    name: 'Variant=standard, Disabled=true, Empty=true',
    reason: 'See `Disabled=true, Empty=false` — no destination on the new axes.',
  },
  {
    component: 'Command',
    name: 'Disabled=true',
    reason: 'Pre-`Empty` spelling of the retired disabled pose.',
  },
  {
    component: 'FormField',
    name: 'Size=lg, State=default',
    reason:
      'Core FormField has no `Size` axis — the widget composes FormLabel and ' +
      'TextField at their own defaults and forwards no size. The designer\'s `md` ' +
      'members map onto `Disabled` × `Error` (see VARIANT_RENAMES); `lg` has no ' +
      'member to become until Core grows a size, which is a design decision ' +
      'rather than a rename.',
  },
  {
    component: 'FormField',
    name: 'Size=lg, State=error',
    reason: 'See `Size=lg, State=default` — same axis, no destination.',
  },
  {
    component: 'FormField',
    name: 'Size=lg, State=disabled',
    reason: 'See `Size=lg, State=default` — same axis, no destination.',
  },
  ...buttonHiddenVariantRetirements(),
  ...chipEnabledEraRetirements(),
  ...chipDroppedTierRetirements(),
  ...sizeAxisDroppedRetirements(
    'FormattedInput',
    ['Enabled', 'Focus'],
    '코드에 size 축이 없다 — 위젯은 md TextField 하나를 합성하고 `formatted_input.sizes` 는 `{}`. 캔버스가 물러난다',
  ),
  ...sizeAxisDroppedRetirements(
    'PhoneInput',
    ['Enabled', 'Hover', 'Focus'],
    '코드에 size 축이 없다 — 위젯은 md TextField 하나를 합성하고 `phone_input.sizes` 는 `{}`. 캔버스가 물러난다',
  ),
  {
    component: 'RadioGroup',
    name: 'State=Selected',
    reason:
      '#4035 (a) — 어느 옵션이 선택됐는지는 그룹의 VALUE 이고 v3 `radio_group.axes.state` 는 null 이다. 4축에 목적지가 없다',
  },
  {
    component: 'SwitchField',
    name: 'State=On',
    reason:
      '#4035 (a) — 스위치의 on/off 는 VALUE 이고 v3 `switch_field.axes` 는 `enabled` 하나만 승격한다. 목적지가 없다',
  },
  {
    component: 'MultiAnswerCard',
    name: 'State=Selected',
    reason:
      '#4035 (a) — 카드의 선택 여부는 VALUE 이고 v3 `multi_answer_card.axes` 는 `enabled` 하나만 승격한다. 목적지가 없다',
  },
  {
    component: 'TextArea',
    name: 'Variant=Error',
    reason:
      '#4035 (b) — hasError 표현은 4축 범위 외(seed spec §4): v3 `text_area.axes.variant` 는 null 이고 `axes.other` 에도 없다. 후속에서 재도입 판단',
  },
  {
    component: 'Select',
    name: 'Variant=Open',
    reason:
      '#4035 (b) — 팝오버 open/closed 는 4축 범위 외(seed spec §4): v3 `select.axes` 는 `enabled` 만 승격하고 `axes.other` 는 비어 있다. 후속에서 재도입 판단',
  },
  // TextArea — Hover 포즈 은퇴. 캔버스에 열두 멤버가 있는데 위젯이 hover 를
  // 그리지 않는다: Flutter 위젯 · Flutter resolver · Core style 모두 hover
  // 참조 0 건이다(Web 의 1 건은 pseudo-state 일반을 말하는 doc 주석).
  // 대조로 TextField 의 Core style 은 4 건이고, 그래서 그쪽에는 State=hover
  // 가 있다. 캔버스가 위젯이 그리지 않는 모습을 단언하면 안 된다.
  ...(['default', 'error'] as const).flatMap((v) =>
    (['xs', 'sm', 'md', 'lg', 'xl', 'xl2'] as const).map((sz) => ({
      component: 'TextArea' as const,
      name: `Variant=${v}, Size=${sz}, Enabled=true, Focus=false, Hover=true`,
      reason:
        'TextArea 는 hover 를 그리지 않는다 — 위젯 · resolver · Core style ' +
        '모두 참조 0 건. 캔버스만 이 포즈를 갖고 있었다.',
    })),
  ),
  // NavigationBarItem — pressed 포즈 은퇴. 캔버스에 여섯 멤버가 있는데
  // 그 chrome 이 진술된 적이 없다: Core style 은 hover 와 selected 의 색을
  // 이름 짓고 press 가 칠할 것은 이름 짓지 않는다. 디자이너가 확인했다 —
  // 쓰지 않는다. 캔버스 멤버는 위젯이 무엇을 그리는가에 대한 주장이므로,
  // 아무도 그리지 않는 주장은 물러난다.
  ...(['vertical', 'horizontal', 'icon'] as const).flatMap((orientation) =>
    (['no', 'yes'] as const).map((sel) => ({
      component: 'NavigationBarItem' as const,
      name: `orientation=${orientation}, state=pressed, selected=${sel}`,
      reason:
        'press 상태의 chrome 이 Core 에 진술된 적이 없고, 쓰지 않는 것으로 ' +
        '확인됐다. 캔버스만 이 포즈를 갖고 있었다.',
    })),
  ),
  // NavigationBar — the `slot` count axis. One count per mode is renamed
  // above and keeps its node; the other two have no destination — a count is
  // not an axis, and the range they spanned is the `Show item N` booleans on
  // the surviving member. "No instances in the file" was checked in this file
  // AND in the consuming Unibook file: the six below are referenced by neither.
  // (`Variant=bar, slot=3` is not here because Unibook references it — see
  // the rename above.)
  ...(
    [
      ['bar', '4'],
      ['bar', '5'],
      ['rail', '3'],
      ['rail', '5'],
      ['sidebar', '3'],
      ['sidebar', '4'],
      ['sidebar', '5'],
    ] as const
  ).map(([mode, slot]) => ({
    component: 'NavigationBar' as const,
    name: `Variant=${mode}, slot=${slot}`,
    reason:
      '`slot` 은 목적지 개수다. 개수는 축이 아니라 `Show item N` 불린이 됐고 ' +
      '(다섯 그리고 넷 켬), 같은 모드의 살아남은 멤버가 그 범위를 다 담는다. ' +
      '이 멤버를 가리키는 인스턴스는 이 파일에도 유니북에도 없다.',
  })),
  // NavigationBar — `CoreNavigationBarMode.sidebar` is `@Deprecated` now that
  // `Sidebar` is its own component (#5738), and the exporter keeps a
  // deprecated member off the canvas. Every pose of the sidebar mode retires;
  // a pose this canvas never drew makes its row a no-op. The old
  // `Variant=sidebar, slot=4` key that used to be renamed onto this member
  // retires above with its siblings — rail and sidebar never had consumers.
  ...(['false', 'true'] as const).flatMap((hover) =>
    (['false', 'true'] as const).flatMap((disabled) =>
      (['false', 'true'] as const).map((focus) => ({
        component: 'NavigationBar' as const,
        name: `Variant=standard, Mode=sidebar, Hover=${hover}, Disabled=${disabled}, Focus=${focus}`,
        reason:
          '`CoreNavigationBarMode.sidebar` 는 `Sidebar` 가 대신한다(@Deprecated since 0.164, ' +
          '#5738) — 예고된 모드는 캔버스에서 빠진다. 소비처가 없던 모드다.',
      })),
    ),
  ),
  // Toggle — `Size=xs` 는 2026-09 리디자인에서 사다리에서 제거됐다: 24×12 트랙에
  // 8px thumb 은 이동 거리 8px 라 피드백이 성립하지 않는다. 코드는
  // `CoreToggleStyle.sizeDefaults` 가 xs 를 sm 으로 올려 그린다. 두 세대의 철자
  // 모두 목적지가 없다.
  {
    component: 'Toggle',
    name: 'Size=xs, On=false, State=enabled',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=false, State=hover',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=false, State=focus',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=false, State=disabled',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=true, State=enabled',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=true, State=hover',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=true, State=focus',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Size=xs, On=true, State=disabled',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=enabled, On=false',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=enabled, On=true',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=hover, On=false',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=hover, On=true',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=focus, On=false',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=focus, On=true',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=disabled, On=false',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
  {
    component: 'Toggle',
    name: 'Variant=defaultVariant, Size=xs, State=disabled, On=true',
    reason: '`xs` 는 사다리에서 제거 — 코드가 sm 으로 clamp 한다(CoreToggleStyle.sizeDefaults).',
  },
];

// Names that left REGISTRY: a node a past run minted for a component that turned
// out not to exist in the code, or that split into several. The opposite of the
// migrations above — those keep a name and change its shape, these give the name
// up — so a `replacement` is named where a designer has somewhere to go.
//
// Listed rather than deleted on sight, because generate.ts no longer bulk-deletes
// what it does not recognise: an unrecognised node is now assumed to be a
// designer's, and only what is written here is removed.
export interface RetiredEntry {
  name: string;
  type: 'COMPONENT' | 'COMPONENT_SET';
  reason: string;
  /** REGISTRY name a designer should switch to, if any. */
  replacement?: string;
}

export const RETIRED: RetiredEntry[] = [
  {
    name: 'Separator',
    type: 'COMPONENT_SET',
    reason: '#3744 — no `Separator` class in coui_core (`find … -name separator` → 0, `class Separator` grep → 0); only `display/divider` exists.',
    replacement: 'Divider',
  },
  {
    name: 'Datalist',
    type: 'COMPONENT',
    reason: '#3744 — no `Datalist` class anywhere in coui_core (`find … -iname *datalist*` → 0).',
  },
  {
    name: 'Rating',
    type: 'COMPONENT',
    reason: '#3742 — byte-for-byte duplicate of `StarRating`; no standalone `Rating` class in coui_core.',
    replacement: 'StarRating',
  },
  {
    name: 'MockupWindow',
    type: 'COMPONENT',
    reason:
      '`CoreMockupWindowStyle` has been removed — the exporter never shipped it and no ' +
      'builder draws it. The app-window composition is `MockupBrowser` with ' +
      '`Show address bar` off; its metrics differ (bar 40→44, padding 12→16, ' +
      'spacing 8→12, control 12→8), so a swapped instance moves.',
    replacement: 'MockupBrowser',
  },
  {
    name: 'NavigationHeader',
    type: 'COMPONENT_SET',
    reason: 'Product retire 2026-09-23 — no NavigationHeader in coui_core; orphan Figma SET (Variant=rail|sidebar) with zero consumers; not a rename of NavigationBar.',
  },
  {
    name: 'InputOtpCell',
    type: 'COMPONENT_SET',
    reason:
      '#4511 — no `InputOtpCell` in coui_core (`git grep InputOtpCell -- packages` → 0) and ' +
      'no builder draws it, so its `Variant × State × Content` members can only drift. ' +
      '`InputOtp` draws its own cells; a separate cell component would have no reader.',
    replacement: 'InputOtp',
  },
  {
    name: 'InputOtpCell/Default',
    type: 'COMPONENT',
    reason: '#4511 — the lone page-level member beside the `InputOtpCell` set; same reason.',
    replacement: 'InputOtp',
  },
  {
    name: 'TripleDots',
    type: 'COMPONENT',
    reason:
      '#5384 — `TripleDots` and `CoreTripleDotsStyle` are removed from coui_core and no builder ' +
      'draws it, so the canvas component can only drift. The "more" glyph is an `Icon` ' +
      '(`lucide/ellipsis`, `lucide/ellipsis-vertical` for the vertical run); the file held no instances.',
    replacement: 'Icon',
  },
  {
    name: 'KeyboardShortcut',
    type: 'COMPONENT',
    reason:
      '#5433 — `KeyboardShortcut` and `CoreKeyboardShortcutStyle` are removed from coui_core and no ' +
      'builder draws it, so the canvas component can only drift. `Kbd` draws a key combination ' +
      '(`Show key 2` … `Show key 4`); the file held no instances. The designer copy ' +
      '`KeyboardShortcut (리디자인)` is not listed here — it is the designer\'s to delete.',
    replacement: 'Kbd',
  },
];

export interface RetiredCheck {
  name: string;
  type: 'COMPONENT' | 'COMPONENT_SET';
  found: boolean;
  reason: string;
  replacement?: string;
}

// Loads every page whose `.children` the two functions below are about to read.
//
// Required, and required HERE: the manifest sets documentAccess:
// "dynamic-page", under which `PageNode.children` throws until that page has
// been `loadAsync`-ed, and only the page the user happens to have open is
// loaded for free. A page list built from `figma.root.children` loads nothing —
// `DocumentNode.children` carries no such requirement — and neither retire
// handler switches the current page
// the way `generateComponents` does. So the read throws in any session whose
// open page is not the one being scanned, on the one code path in this plugin
// that deletes a persistent node.
//
// It lives next to the readers rather than at the call site so a future caller
// of either function cannot forget it.
async function loadPages(pages: readonly PageNode[]): Promise<void> {
  for (const p of pages) await p.loadAsync();
}

// Dry-run — reports what WOULD be removed, touches nothing.
//
// Scans every plugin-owned page, not one. Components live on per-section pages
// after a run distributes them, and a single-page scan would report a retired
// component as "not found (no-op)" while it is sitting on `🧩 Display`. A false
// negative in the dry run of a destructive action is the worst direction to be
// wrong in: it tells the operator there is nothing to lose — which is also
// exactly what an unloaded page would have produced, had the read not thrown.
export async function dryRunRetired(
  pages: readonly PageNode[],
  retired: readonly RetiredEntry[],
): Promise<RetiredCheck[]> {
  await loadPages(pages);
  return retired.map((r) => ({
    name: r.name,
    type: r.type,
    found: pages.some((p) =>
      p.children.some((n) => n.type === r.type && n.name === r.name),
    ),
    reason: r.reason,
    replacement: r.replacement,
  }));
}

// Executes the removal — the one place in this plugin that deletes a
// persistent node outside a documented structural migration. Only reachable
// from an explicit UI action (see code.ts `retire-execute`), never from
// Generate Components.
export async function removeRetired(
  pages: readonly PageNode[],
  retired: readonly RetiredEntry[],
): Promise<string[]> {
  await loadPages(pages);
  const log: string[] = [];
  for (const r of retired) {
    let node: SceneNode | undefined;
    for (const p of pages) {
      node = p.children.find((n) => n.type === r.type && n.name === r.name);
      if (node) break;
    }
    if (!node) {
      log.push(`"${r.name}" not found — already removed, or never existed.`);
      continue;
    }
    node.remove();
    log.push(
      `removed ${r.type} "${r.name}" (${r.reason})` +
        (r.replacement ? ` — migrate designs to "${r.replacement}".` : ''),
    );
  }
  return log;
}

export interface RetiredVariantCheck {
  component: string;
  name: string;
  found: boolean;
  reason: string;
}

// Dry-run — reports what WOULD be removed, touches nothing.
export function dryRunRetiredVariants(
  pages: readonly PageNode[],
  retired: readonly RetiredVariant[],
): RetiredVariantCheck[] {
  return retired.map((r) => ({
    component: r.component,
    name: r.name,
    found: findRetiredVariantChild(pages, r) !== null,
    reason: r.reason,
  }));
}

// Executes the removal. Reachable only from an explicit UI action (code.ts
// `retire-execute`), never from Generate Components — a variant child's `key`
// dies with it, detaching every instance in every consuming file.
export function removeRetiredVariants(
  pages: readonly PageNode[],
  retired: readonly RetiredVariant[],
): string[] {
  const log: string[] = [];
  for (const r of retired) {
    const child = findRetiredVariantChild(pages, r);
    if (!child) {
      log.push(
        `${r.component}: variant "${r.name}" not found — already removed, or never existed in this document.`,
      );
      continue;
    }
    child.remove();
    log.push(`${r.component}: removed variant "${r.name}" (${r.reason})`);
  }
  return log;
}

function findRetiredVariantChild(
  pages: readonly PageNode[],
  r: RetiredVariant,
): SceneNode | null {
  for (const page of pages) {
    const set = page.children.find(
      (n): n is ComponentSetNode => n.type === 'COMPONENT_SET' && n.name === r.component,
    );
    if (!set) continue;
    const child = set.children.find((c) => c.name === r.name);
    if (child) return child;
  }
  return null;
}

// ─── Retired component PROPERTIES ─────────────────────────────────────────
//
// `defineProp` only adds or reuses, and a recycled set keeps every definition it
// ever had. Once the nodes that referenced a property are re-minted without the
// binding it is an orphan — a handle in the Properties panel that toggles
// nothing (`orphan-props.ts` reports exactly that shape), and a set that
// declares one is silently left out of Figma's publish dialog (#5323).
//
// Generate removes such a property itself, right after it draws the set
// (`unbound-props.ts`): every property no layer of the set references goes, and
// each removal is a log line. This list is for the case that cannot be decided
// from the layers — a property still referenced by a layer that is itself being
// retired — and for removing one WITHOUT redrawing its set: the explicit retire
// action below, dry-run first, never from Generate. Unlike a retired variant
// this detaches nothing — an instance keeps its main component and only loses a
// value for a property that no longer does anything.
export interface RetiredProperty {
  /** The owning set's (or loose component's) CURRENT name. */
  component: string;
  /** Property display name — the key's prefix before `#`. */
  name: string;
  type: 'BOOLEAN' | 'TEXT' | 'INSTANCE_SWAP';
  reason: string;
}

export const RETIRED_PROPERTIES: RetiredProperty[] = [1, 2].map((i) => ({
  component: 'Scaffold',
  name: `Show header action ${i}`,
  type: 'BOOLEAN' as const,
  reason:
    "#4574 — the header row is a composed ❖ AppBar instance; its actions are AppBar's " +
    'own `action 1` / `action 2`, exposed through the instance.',
}));

export interface RetiredPropertyCheck {
  component: string;
  name: string;
  found: boolean;
  reason: string;
}

/** A node a retired-property row may name. Structural so the selftest can drive it. */
export interface RetiredPropertyOwner {
  readonly type: string;
  readonly name: string;
  readonly componentPropertyDefinitions?: Readonly<Record<string, { readonly type: string }>>;
  deleteComponentProperty?(propertyId: string): void;
}

interface RetiredPropertyPage {
  readonly children: readonly RetiredPropertyOwner[];
}

/** The full key (`name#id`) of `r` on `owner`, or null when it is not defined. */
export function retiredPropertyKey(
  owner: RetiredPropertyOwner,
  r: RetiredProperty,
): string | null {
  const defs = owner.componentPropertyDefinitions;
  if (!defs) return null;
  for (const [key, def] of Object.entries(defs)) {
    if (key.split('#')[0] === r.name && def.type === r.type) return key;
  }
  return null;
}

function findRetiredPropertyOwner(
  pages: readonly RetiredPropertyPage[],
  r: RetiredProperty,
): RetiredPropertyOwner | null {
  for (const page of pages) {
    const owner = page.children.find(
      (n) => (n.type === 'COMPONENT_SET' || n.type === 'COMPONENT') && n.name === r.component,
    );
    if (owner) return owner;
  }
  return null;
}

// Dry-run — reports what WOULD be removed, touches nothing.
export function dryRunRetiredProperties(
  pages: readonly RetiredPropertyPage[],
  retired: readonly RetiredProperty[],
): RetiredPropertyCheck[] {
  return retired.map((r) => {
    const owner = findRetiredPropertyOwner(pages, r);
    return {
      component: r.component,
      name: r.name,
      found: owner !== null && retiredPropertyKey(owner, r) !== null,
      reason: r.reason,
    };
  });
}

// Executes the removal. Reachable only from the explicit retire action
// (code.ts `retire-execute`), never from Generate.
export function removeRetiredProperties(
  pages: readonly RetiredPropertyPage[],
  retired: readonly RetiredProperty[],
): string[] {
  const log: string[] = [];
  for (const r of retired) {
    const owner = findRetiredPropertyOwner(pages, r);
    const key = owner ? retiredPropertyKey(owner, r) : null;
    if (!owner || !key || typeof owner.deleteComponentProperty !== 'function') {
      log.push(
        `${r.component}: property "${r.name}" not found — already removed, or never existed in this document.`,
      );
      continue;
    }
    owner.deleteComponentProperty(key);
    log.push(`${r.component}: removed property "${r.name}" (${r.reason})`);
  }
  return log;
}
