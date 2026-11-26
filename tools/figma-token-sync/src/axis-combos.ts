// #4033 (C1 / T-14 / T-16) — THE combination enumerator.
//
// Every consumer of "which variant combinations does this component have" —
// the variant-set builders (C3/C4) and the G10 axis-coverage check (E2) —
// calls the functions here, never a hand-rolled loop. That sharing is the
// point: when numerator and denominator are the same function, they cannot
// disagree by arithmetic drift (the seed spec's CH-001/CH-002 class of
// bug — 72 vs 144 — becomes unrepresentable).
//
// T-16 — axis order is FIXED: Variant → Size → State → Enabled (a set that
// draws a `Color` axis puts it first — see `kAxisOrder`). Rename
// entries, adoption (C2), parseVariantKey consumers and G10 all assume one
// canonical spelling per combination (`Variant=primary, Size=md,
// Enabled=true`), so composition lives in exactly one function below.
//
// Axis values are the enum members' raw source spellings (v3 `axes` keeps
// declaration order); `Enabled` is the boolean axis spelled `true`/`false`.
//
// Deliberately figma-API-free (same reasoning as variant-safety.ts) so
// `npm run selftest` can drive it — and break it on purpose — under Node.

export const kAxisOrder = [
  // A design axis, not a pose — the colour a component takes on when it is
  // selected, for the one component whose colour enum (`CoreChipColor`) sits
  // beside a `variant` of its own (`CoreChipVariant`, the unselected shape).
  // `axes.other` records a colour enum without promoting it, so it is a
  // builder-declared axis like the ones below the schema-v3 line; it sits ABOVE
  // `Variant` because the canvas has always spelled a Chip member colour-first
  // (`Color=neutral, …`), and a member's name is its identity.
  //
  // Every other set that draws a colour enum names the axis `Variant` (Status,
  // Dock, Fab, …) because it has no variant of its own to give that name to.
  // Chip is the one that does. An enum that says what a colour MEANS
  // (`CoreBadgeTone`, `CoreProgressTone`) is the `Tone` axis below instead.
  'Color',
  // The four schema-v3 axes, in the order `axes` declares them.
  'Variant',
  'Size',
  'State',
  'Enabled',
  // A design axis, not a pose — `CoreNavigationBarMode`, the bar's shape
  // (bar | rail | sidebar). It is a contract parameter the way `variant` is,
  // and the widget branches on it eight times over (axis direction, label
  // mode, label position, item growth, alignment, hairline side, divider
  // orientation, scroll axis) — so the canvas has to draw it as a member,
  // not as a property. It sits with the four rather than below because a
  // member's name is its identity and this is the axis that tells the three
  // shapes apart; the poses below qualify a shape that already has a mode.
  // The designer's set spelled it `Variant`; the code's `variant` is a
  // different thing (one member, `standard`), so the canvas name moves.
  'Mode',
  // Design axes, not poses — `CoreSidebarType` (standard | twoPane | collapsed)
  // and `CoreSidebarItemLevel` (top | nested): contract enums the widgets branch
  // on the way `variant` is, declared by the Sidebar builders rather than by
  // `axes`, so they sit behind the four like `Mode` does.
  'Type',
  'Level',
  // POSE axes — a resting state a component holds until something changes it,
  // declared by a builder rather than by `axes`. They come after the four
  // because they are narrower: a component has a variant and a size whatever
  // else is true of it, while a pose qualifies that variant.
  //
  // Listed here for one reason — `composeVariantName` throws on any axis it does
  // not know (an unknown name gets `indexOf === -1`, which fails the ordering
  // check on the first entry). So an axis absent from this list is an axis a
  // builder cannot compose a name with, and the failure is loud rather than a
  // silently mis-sorted member name.
  //
  // Order among themselves is fixed and arbitrary-but-stable: it only has to be
  // the SAME order every builder uses, because a member's name is its identity
  // and two builders sorting two axes differently would mint two names for one
  // pose.
  // `Tabs` — `CoreTabsContract.expand`, a widget bool (`this.expand =
  // false`) the bar's builder promotes as `Width=fill|scroll`, the designer's
  // own spelling. After Size because `tabs.axes.size` is now declared
  // (#4577), so `composeVariantName` spells `Variant=pill, Size=md, Width=fill`.
  // Not a pose: a layout choice the caller makes, like `Style` and `Position`
  // below.
  'Width',
  'Placement',
  // A design axis, not a pose — the component states it as an enum in its
  // contract (`CoreBannerEmphasis`) the way it states `variant`. It sits here
  // rather than beside `Variant` because the four above are the ones
  // `axisSpecsOf` derives from schema-v3 `axes`; anything a builder declares
  // for itself lives below that line, whatever its nature.
  //
  // Named `Style` because that is what the canvas already calls it, and a
  // member's name is its identity — spelling it `Emphasis` here would orphan
  // every instance of the ten Banner members a designer already placed.
  'Style',
  // Where the bubble sits relative to its trigger. A design axis like
  // `Style` — the component states it as an enum (`CoreTooltipPosition`),
  // and all four members draw a different tail on a different edge.
  'Position',
  // Which screen edge a drawer docks to — `CoreDrawerSide`, the contract's
  // `side`. A design axis like `Position`: the four members put the panel, its
  // flattened corners and its grab handle on four different edges, so a
  // member's identity carries it.
  'Side',
  // Which bottom corner a chat bubble's tail leaves from — `none` (no tail, the
  // contract's `defaultTail` is false), `start` or `end`. A design axis like
  // `Position`: the widget states it as `tail` + the row's alignment, and the
  // three poses draw different silhouettes, so a member's identity carries it.
  'Tail',
  // `TreeItem`'s row shape — `leaf` | `collapsed` | `expanded`, the node's
  // `hasKids` and its disclosure state read together, the way the widget reads
  // them (chevron or its placeholder, folder or file glyph). Before `Selected`
  // because what a row IS comes before whether it is the current one.
  'Kind',
  'Selection',
  'Selected',
  // `ColorPicker`'s presentation — `CoreColorPickerPromptMode` (popover |
  // inline): a field trigger that opens a popover, or the panel drawn in
  // place. A design axis the builder declares, after `Selected` because the
  // designer's set spells its members `Enabled=…, Selected=…,
  // Presentation=…` and a member's name is its identity.
  'Presentation',
  // `TreeItem`'s nesting level — the row's start inset (`nodePadding.l` plus
  // one `indent` per level). After `Selected`: a row's depth is where it sits,
  // the last thing that moves its pixels.
  'Depth',
  // The checkbox's VALUE axis — Flutter's tristate `bool?` spelled out as
  // `true` / `false` / `indeterminate`. A pose axis like `Selected` and
  // `On`, and it sits with them: the canvas orders a member's identity
  // Size → State → Checked, and the widget's `checked` is the last thing
  // that changes what the box paints.
  'Checked',
  // A design axis like `Style` — `CoreChipEmphasis` in the contract, and the
  // canvas already spells it `Emphasis` (the axis is a value rename away from
  // its members' identity, so the spelling is the canvas's, not a choice).
  // After `Selected` because that is the order the chip set declares them in,
  // and a member's name is its identity.
  'Emphasis',
  'Expanded',
  'Open',
  // `Fab`'s pill pose — `label != null` turns the circle into an Extended FAB.
  // Immediately after `Open` because that is where the designer's members
  // already spell it (`Size=…, State=…, Open=…, Extended=…`), and a member's
  // name is its identity: any other seat composes a different string and
  // orphans the fifteen she placed.
  'Extended',
  // `Link`'s `underline` flag — whether the underline is permanent. A design
  // axis rather than a pose: it is a constructor argument and a link in running
  // text states it, the way `Variant` states its tone. Before `Focus`, because
  // the members are spelled `Variant=…, Underline=…, Focus=…` and a member's name
  // is its identity: any other seat composes a different string.
  'Underline',
  'Hover',
  'Focus',
  'Error',
  'Empty',
  'Dismissible',
  'Disabled',
  'Orientation',
  'Label',
  'Tone',
  // `Progress`'s `segments` — `null` is the continuous bar, a count is a row
  // of cells — spelled `false|true` the way `Ring` spells a flag, so the
  // continuous bar is the member at rest. A design axis rather than a pose:
  // the two members draw different structures (one track, or cells), so a
  // member's identity has to carry it. After `Tone` because a stepped bar
  // still has a tone, and the members are spelled `Size=…, Tone=…,
  // Segmented=…`.
  'Segmented',
  'Shape',
  'Ring',
  'Icon',
  'Direction',
  'Effect',
  // `Dialog`'s design axis — `CoreDialogActionsLayout`, how the dialog spreads
  // its actions along the panel's last row (`CoreDialogStyle.actionsLayout`).
  // Beside `Layout` because it is the same kind of choice: one value per way of
  // arranging a row, each drawing a different row.
  'Actions',
  'Layout',
  // `Footer`'s pose axis — whether the business-info disclosure is open.
  // Immediately after `Layout` because the designer's members are spelled
  // `Layout=…, Info=…` and a member's name is its identity: any other seat
  // composes a different string and orphans every instance she placed.
  //
  // A pose, not a design axis: nothing in `CoreFooterContract` is named
  // `Info`. The two values are the two states of the composed `Collapsible`
  // (`businessInfoExpanded`), the way `State=hover` is a pose of a button.
  'Info',
  'Stage',
  'Status',
  'ChangeType',
  'Matches',
  'Minimized',
  'DragOver',
  'Vertical',
  'On',
  'Axis',
  // AppBar 의 pose 축 — `leading` 은 caller 가 채우는 `List<W>` 슬롯이라, 흔한
  // 네 affordance(none|back|close|menu)를 프리뷰하는 자세다.
  'Leading',
  // AppBar 의 pose 축 — `centerTitle` 의 두 값(start|center). 타이틀 정렬만 바꾼다.
  'Align',
  // `SwipeActions`' pose axis — where a swiped row is left: `closed`,
  // `openLeading`, `openTrailing`. `CoreSwipeOutcome` states them (its execute
  // pair is `@behaviourOnly`: what a release does, not a place the row stays).
  // Last, with the other poses a builder declares for itself: the set has no
  // variant or size for it to follow.
  'Pose',
  // `OptionList`'s design axis — how many rows the preview list carries (3 to 6).
  // The list takes its rows as children, so the count is the example's, not a
  // field; the set offers four of them, spelled `Count=3` … `Count=6`.
  'Count',
  // `Popup`'s inset preset — `content` (`CorePopupStyle.defaultContentPadding`,
  // the field's own default) or `list` (`defaultListPadding`, what a panel that
  // holds rows states). Core keeps it ONE field (`padding`) with two named
  // presets, not an enum; the canvas draws the two presets as members so a
  // composing parent can pick the one its code states instead of overriding the
  // inset on an instance. A design axis rather than a pose: the two members
  // draw the same box at different insets, and a parent's code chooses one.
  'Padding',
] as const;
export type AxisName = (typeof kAxisOrder)[number];

export interface AxisSpec {
  axis: AxisName;
  values: readonly string[];
}

// ─── What an axis reads when nothing has happened to the component yet ───────
//
// A parent that composes a child wants the child AT REST — a nav arrow is not
// pre-hovered, a field's clear affordance is not pre-pressed. Two helpers used
// to answer that, one per file, and both answered it by knowing which boolean
// value means "off".
//
// That works only while every state axis IS a boolean. It stopped being true
// when `Button` moved its five poses onto one `State=` enum: "off" is not
// `false` there, it is `enabled`, and a counter that reads "away from rest" as
// `value === 'true'` scores `State=hover` and `State=enabled` identically —
// so a composed child could come back pre-hovered from a sort that had no
// opinion either way. Silent, and only in the direction of looking wrong.
//
// Keyed by axis NAME because the name is what the enumeration writes, and
// there is nothing on a variant to read polarity off of. `Enabled` is here for
// the reason it always was: the schema spells the axis `Enabled=true|false`
// where the old canvas said `Disabled=`, so its rest is the value that reads
// as "on".
const kRestingAxisValue: Readonly<Record<string, string>> = {
  Enabled: 'true',
  State: 'enabled',
  // `CoreChipEmphasis.defaultEmphasis` — a chip nobody asked to be quiet is
  // `high`. Without this entry the default rest `'false'` matches neither
  // value, and every chip member scores as away from rest.
  Emphasis: 'high',
  // `button.dart`'s own `this.shape = CoreButtonShape.rectangle` — a button
  // nobody asked to be square is a rectangle. Without this entry the default
  // rest `'false'` matches none of the three, and every parent that composes a
  // `Button` without naming a shape throws instead of picking one; that is how
  // the Carousel / TimePicker / Command entries failed the moment the axis
  // arrived.
  //
  // One spelling caveat, recorded because the table is keyed by axis NAME and
  // therefore global: `Clickable` also has a `Shape` axis and spells its
  // rectangle `rect`. Harmless today because nothing composes a `Clickable` —
  // it only builds its own set, so this table never meets that spelling. If a
  // builder ever does compose one, the two vocabularies have to be reconciled
  // rather than a second value added here. `Chip` (`rounded` | `pill`) has a
  // `Shape` axis of its own too, and is harmless for a different reason: every
  // parent that composes a chip names `Shape` outright (ChipGroup · ChipInput ·
  // Command ask for `rounded`), so this table never meets that spelling either.
  Shape: 'rectangle',
  // Which drawn segment is current, on the set whose `Selected` is an INDEX
  // rather than a flag — `Filter`. One-based because a designer reads the axis
  // in the Figma panel, and the first segment is the one nothing has happened
  // to yet. Without this entry the default rest `'false'` matches none of
  // `1..4`, and a parent composing a `Filter` without naming a segment would
  // throw the way the `Shape` note above records.
  //
  // The same spelling caveat as `Shape`, because this table is keyed by axis
  // NAME: `Chip`, `ColorPicker` and `TabItem` spell their `Selected` as
  // `true`/`false` — a flag, "is THIS one current", where Filter's is "which
  // one" (`Calendar`'s day cells pose on `Selection`, a different axis, so they
  // never meet this entry). Harmless today because every parent that composes
  // one of those names the axis outright (`ChipInput` asks for `Selected:
  // 'true'`; `Tabs` spells every `TabItem` axis through `composeVariantName`),
  // so this table never meets that spelling unasked. If a builder ever
  // composes one at rest without naming it, the two vocabularies have to be
  // reconciled rather than a second value added here.
  Selected: '1',
  // `tabs.dart`'s own `this.expand = false` — a bar nobody asked to stretch
  // hugs its tabs, which the canvas spells `scroll`. Nothing composes `Tabs`
  // today; the entry is so a parent that ever does gets the contract's default
  // rather than the default rest `'false'`, which matches neither value and
  // would throw the way the `Shape` note records.
  Width: 'scroll',
  Placement: 'overlay',
  // `CoreFooterContract.defaultBusinessInfoExpanded` is `false` — a footer
  // nobody has clicked keeps its registration details folded away, which the
  // canvas spells `collapsed`. Without this entry the default rest `'false'`
  // matches neither value, and the loose-component adoption below (and any
  // parent that ever composes a `Footer`) would ask for a member that does
  // not exist.
  Info: 'collapsed',
  // `CoreNavigationBarMode.defaultMode` — the bar. A parent composing a
  // navigation bar at rest gets the docked horizontal one.
  Mode: 'bar',
  // `CoreDrawerSide.defaultSide` — a drawer nobody docked anywhere slides in
  // from the left, which is also the one edge the single component this set
  // grew out of drew. A parent composing a `Drawer` at rest gets that member.
  Side: 'left',
  // `CoreChatBubbleContract.defaultTail` is `false` — a bubble nobody asked to
  // have a tail has none, which the canvas spells `none`. Without this entry the
  // default rest `'false'` matches none of `none|start|end`, and a parent
  // composing a `ChatBubble` without naming a tail would ask for a member that
  // does not exist.
  Tail: 'none',
  // `SwipeActions` at rest is a row nobody has swiped — `closed`, the member
  // `CoreSwipeOutcome` lists first and the one a row starts in. Without this
  // entry the default rest `'false'` matches none of the three poses.
  Pose: 'closed',
  // `CorePopupStyle.defaultPadding` is the content preset — a popup nobody
  // asked to hold a list does not know it holds one. Without this entry the
  // default rest `'false'` matches neither `content` nor `list`.
  Padding: 'content',
};

/** The value [axis] carries on a member nothing has happened to yet. */
export function restingValueOf(axis: string): string {
  return kRestingAxisValue[axis] ?? 'false';
}

/** Whether `axis=value` is that axis at rest. */
export function isAxisAtRest(axis: string, value: string): boolean {
  return value === restingValueOf(axis);
}

/** The axes named here rest at something other than `"false"`, for messages. */
export function restingAxisSummary(): string {
  return Object.entries(kRestingAxisValue)
    .map(([axis, value]) => `${axis}="${value}"`)
    .join(', ');
}

// What a member carries for [axis] — reading a `State=` fold when the member
// does not name the axis directly.
//
// `Enabled` and `State` are not independent: a state axis names `disabled` as
// one of its rungs, so a set that carries `State=` has ALREADY said everything
// `Enabled=` would say. A builder that folds the boolean into the enum is not
// dropping coverage, it is spelling it once instead of twice.
//
// This matters to anything that asks "is combination X reachable" while holding
// the schema's own axis list, because the schema keeps promoting `enabled` — it
// describes the component, not the canvas's spelling of it. Without the fold
// such a check reads a fully-covered set as covering nothing at all.
//
// A `Disabled` pose axis (a set that predates its contract's `enabled`) says
// the same thing as its inverse, so `Disabled=true` reads as `Enabled=false`.
//
// One direction only, deliberately. `State=hover` folds to `Enabled=true`
// because a hovered button is an enabled one; nothing folds the other way,
// since `Enabled=true` says nothing about which rung.
export function axisValueOf(
  variantProperties: Readonly<Record<string, string>>,
  axis: string,
): string | undefined {
  const direct = variantProperties[axis];
  if (direct !== undefined) return direct;
  if (axis === 'Enabled') {
    const state = variantProperties['State'];
    if (state !== undefined) return state === 'disabled' ? 'false' : 'true';
    // A `Disabled` pose axis is the same state spelled as its inverse.
    const disabled = variantProperties['Disabled'];
    if (disabled !== undefined) return disabled === 'true' ? 'false' : 'true';
  }
  return undefined;
}

// Structural shape of one component's schema-v3 `axes` value — matches what
// `data.ts`'s literal-typed JSON widens to. `variant.default` is carried
// for the basic-constructor derivation (S-001), not for enumeration.
export interface ComponentAxesJson {
  variant: {
    enum: string;
    members: readonly string[];
    default: string | null;
    /** Enum members the reader kept OFF the canvas — `@Deprecated` and
     *  `@behaviourOnly` — named so their canvas members can be retired
     *  deliberately rather than turning up unexplained. Not enumerated. */
    hidden?: readonly string[];
  } | null;
  size: { enum: string; members: readonly string[] } | null;
  state: { enum: string; members: readonly string[]; hidden?: readonly string[] } | null;
  enabled: boolean;
  other: readonly { enum: string; members: readonly string[] }[];
}

// The four Figma-representable axes of a component, in T-16 order, empty
// axes omitted. `other` is deliberately NOT here — recording without
// promotion is the seed spec's §4-2 boundary.
export function axisSpecsOf(axes: ComponentAxesJson): AxisSpec[] {
  const specs: AxisSpec[] = [];
  if (axes.variant && axes.variant.members.length > 0) {
    specs.push({ axis: 'Variant', values: axes.variant.members });
  }
  if (axes.size && axes.size.members.length > 0) {
    specs.push({ axis: 'Size', values: axes.size.members });
  }
  if (axes.state && axes.state.members.length > 0) {
    specs.push({ axis: 'State', values: axes.state.members });
  }
  if (axes.enabled) {
    specs.push({ axis: 'Enabled', values: ['true', 'false'] });
  }
  return specs;
}

// `[['Variant','primary'], ['Size','md']]` → `"Variant=primary, Size=md"`.
// Input order is trusted to be T-16 order (axisSpecsOf/enumerate produce
// it); an out-of-order assignment is a programming error worth throwing on,
// not silently re-sorting — a re-sort would hide the drifted call site.
export function composeVariantName(
  assignment: ReadonlyArray<readonly [AxisName, string]>,
): string {
  let lastIndex = -1;
  for (const [axis] of assignment) {
    const orderIndex = kAxisOrder.indexOf(axis);
    if (orderIndex <= lastIndex) {
      throw new Error(
        `axis assignment out of canonical order (T-16 ${kAxisOrder.join('→')}): ` +
          assignment.map(([a, v]) => `${a}=${v}`).join(', '),
      );
    }
    lastIndex = orderIndex;
  }
  return assignment.map(([axis, value]) => `${axis}=${value}`).join(', ');
}

// Full cross product in deterministic order: the FIRST axis varies slowest
// (its members in declaration order), later axes faster — so `Button`'s
// 144 come out grouped by variant, then size, then enabled.
/** One member of a set: its name and the axis values that produced it. */
export interface AxisAssignment {
  readonly name: string;
  readonly values: Readonly<Record<string, string>>;
}

/**
 * The cross product with the VALUES kept, not just the composed names.
 *
 * `enumerateAxisCombos` returns names, so a builder that needs the values back —
 * and every builder does, to pick the data row for each member — enumerates a
 * second time in its draw loop. Two enumerations of the same axes with nothing
 * connecting them is a divergence waiting for someone to add a pose value to one
 * of them; `mountSet` now refuses that at runtime, and this is how a builder avoids
 * being refused: enumerate once, hand `.name` to `mountSet`, read `.values` in the
 * loop.
 *
 * Order is identical to `enumerateAxisCombos` — first axis slowest — so switching a
 * builder over does not move a single member.
 */
export function enumerateAxisAssignments(
  specs: readonly AxisSpec[],
): AxisAssignment[] {
  if (specs.length === 0) return [];
  let assignments: (readonly [AxisName, string])[][] = [[]];
  for (const spec of specs) {
    const next: (readonly [AxisName, string])[][] = [];
    for (const partial of assignments) {
      for (const value of spec.values) {
        next.push([...partial, [spec.axis, value] as const]);
      }
    }
    assignments = next;
  }
  return assignments.map((a) => {
    const values: Record<string, string> = {};
    for (const [axis, value] of a) values[axis] = value;
    return { name: composeVariantName(a), values: values };
  });
}

export function enumerateAxisCombos(specs: readonly AxisSpec[]): string[] {
  if (specs.length === 0) return [];
  let assignments: (readonly [AxisName, string])[][] = [[]];
  for (const spec of specs) {
    const next: (readonly [AxisName, string])[][] = [];
    for (const partial of assignments) {
      for (const value of spec.values) {
        next.push([...partial, [spec.axis, value] as const]);
      }
    }
    assignments = next;
  }
  return assignments.map((a) => composeVariantName(a));
}


// Which size row a `Size=` member draws — the same answer
// `resolveSizeRow` (`coui_core/lib/src/size/component_size.dart`) gives the
// app, so a cell the code table does not state draws what the widget
// renders rather than whatever the builder happened to reach for.
//
// The rule, in the code's order: the stated row if there is one; otherwise
// the nearest stated row BELOW the request; otherwise (the request is
// smaller than everything stated) the smallest stated row. Downward because
// a table that stops at `xl` stops because the larger step was not
// designed — `xl` is what its author last decided.
//
// `ladder` is the axis's own member order (`axes.size.members`), which is
// the enum's declaration order — the same order the Dart walk uses.
//
// The code also asserts in debug when it falls back. The canvas has no
// debug run to say it in, so the fallback is silent here, exactly as it is
// in a release build.
export function sizeRowFor<T>(
  rows: ReadonlyMap<string, T>,
  size: string,
  ladder: readonly string[],
): T {
  const exact = rows.get(size);
  if (exact !== undefined) return exact;
  if (rows.size === 0) {
    throw new Error(
      `sizeRowFor: empty size table for "${size}" — the table failed to ` +
        'export; this is not a missing size.',
    );
  }
  const at = ladder.indexOf(size);
  if (at < 0) {
    throw new Error(
      `sizeRowFor: "${size}" is not on the ladder [${ladder.join(', ')}] — ` +
        'the cell names a size the enum does not have.',
    );
  }
  for (let i = at - 1; i >= 0; i--) {
    const smaller = rows.get(ladder[i]);
    if (smaller !== undefined) return smaller;
  }
  for (const candidate of ladder) {
    const smallest = rows.get(candidate);
    if (smallest !== undefined) return smallest;
  }
  throw new Error(
    `sizeRowFor: no row of [${[...rows.keys()].join(', ')}] is on the ` +
      `ladder [${ladder.join(', ')}].`,
  );
}

// One `Size=` cell per DISTINCT row, for a ladder whose rows repeat.
//
// FormLabel and Fieldset take the whole shared six-tier enum but state only
// two pictures — `xs`/`sm`/`md` read one row, `lg`/`xl`/`xl2` the other. Six
// cells over two pictures are four cells that show nothing a designer can
// choose between, so the canvas draws each picture once (크기 단계 결정,
// 2026-10-01: those sets are drawn as two steps, `md · lg`).
//
// Which member names a picture is derived, not typed: the one closest to the
// component's default size (`constants.size.choice`) — the step the canvas
// has always confirmed — ties going DOWN, the same direction `sizeRowFor`
// falls. For a `md` default over the two groups above that gives `md · lg`.
//
// "Same row" is structural equality of the exported row, so the cells follow
// the code: give `xl` its own row in Dart and it gets its own cell here
// without an edit. `cellFor` is the other half — a set that composes this one
// (`TextField`'s label is a `FormLabel` at the field's size) asks it which
// cell shows a size's picture, instead of naming a cell the set no longer has.
export interface SizeCells {
  /** The `Size=` values drawn, in ladder order. A drawn cell is a stated
   *  size, so `sizeRowFor` hands back its own row. */
  readonly cells: readonly string[];
  /** The drawn cell whose picture is the one the app renders for `size`. */
  cellFor(size: string): string;
}

export function distinctSizeCells<T>(
  rows: ReadonlyMap<string, T>,
  ladder: readonly string[],
  defaultSize: string,
): SizeCells {
  const pivot = ladder.indexOf(defaultSize);
  if (pivot < 0) {
    throw new Error(
      `distinctSizeCells: default size "${defaultSize}" is not on the ladder ` +
        `[${ladder.join(', ')}].`,
    );
  }
  // Group every ladder member by the row the app renders for it — including
  // members the table does not state, which render their fallback row.
  const groups = new Map<string, string[]>();
  for (const size of ladder) {
    const key = JSON.stringify(sizeRowFor(rows, size, ladder));
    const group = groups.get(key);
    if (group) group.push(size);
    else groups.set(key, [size]);
  }
  const cellOf = new Map<string, string>();
  for (const members of groups.values()) {
    let best = members[0];
    for (const size of members) {
      const d = Math.abs(ladder.indexOf(size) - pivot);
      const bestD = Math.abs(ladder.indexOf(best) - pivot);
      // `members` is in ladder order, so a later member wins only on a
      // strictly smaller distance — a tie keeps the lower step.
      if (d < bestD) best = size;
    }
    for (const size of members) cellOf.set(size, best);
  }
  const cells = ladder.filter((size) => cellOf.get(size) === size);
  return {
    cells,
    cellFor: (size) => {
      const cell = cellOf.get(size);
      if (cell === undefined) {
        throw new Error(
          `distinctSizeCells: "${size}" is not on the ladder [${ladder.join(', ')}].`,
        );
      }
      return cell;
    },
  };
}
