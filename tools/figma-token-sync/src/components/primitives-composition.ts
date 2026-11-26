/// <reference types="@figma/plugin-typings" />

import { RegistryEntry } from '../helpers';

import { kHalf } from '../chrome-preview';
import {
  VarLookup,
  applyPanelCompChrome,
  bindTextProp,
  defineProp,
  instanceOf,
  makeLabel,
  mountSet,
  textLabelOpts,
  setInstanceBoolNamed,
} from '../helpers';
import { textStyleData } from '../compat/v1';
import { COMPONENTS } from '../data';

// ─── Mockup ──────────────────────────────────────────────────────────────────

// `CoreMockupStyle` is not a widget — it is the cross-variant style slot
// folded into each mockup variant's resolve chain as its lowest-priority
// layer, so one project theme can recolour every mockup frame at once.
//
// All four of its fields (`backgroundColor` / `borderColor` / `frameColor` /
// `borderRadius`) default to `null` on purpose: each variant supplies its own
// fallback when the shared slot leaves a field unset. That is why
// `mockup.fields` is `{}` — there is no value here to draw, and painting a
// fill or a radius would assert a default this type deliberately does not
// have.
//
// So the node is structural only: one variant per mockup the slot feeds. The
// drawable sibling contracts in `mockup_contract.dart` are `MockupBrowser` /
// `MockupCode` / `MockupDevice`, and `MockupBrowser` feeds two compositions — a
// web page, and with `addressBar: null` a desktop app window — so the app
// window is its own variant, an instance of the same component with its
// `Show address bar` property off. The variant names are the whole information
// content of the type — what this slot spans — and they come from the
// contracts, not from a guess.
//
// Each variant holds an INSTANCE of that mockup, which is the whole of what
// "spans these four" can look like. It used to hold an unpainted, unstroked
// `slotBox` instead, and the result was a component that rendered NOTHING: a
// transparent 160×48 frame inside a fill-less variant, four times over. The
// argument for the empty box was that `mockup.fields` is `{}` so there is no
// value here to paint — true, and it does not follow that there is nothing to
// SHOW. Every value on screen belongs to the mockup that owns it, which is
// exactly what an instance says and what a hand-painted stand-in could not:
// a copy keeps whatever those four looked like the day it was written, and the
// content-hash skip never re-enters this builder to notice they changed.
//
// `instanceOf` resolves in the runtime harness as well: its
// `figma.createComponent` parents every `mint()`ed component under the page
// precisely so a single-component target (`MockupCode`, `MockupBrowser`) is
// found the way a set is.
interface MockupVariant {
  /// The `Variant=` axis value. Frozen — `mountSet` refuses to drop a variant
  /// a previous run created, so renaming one needs a `VARIANT_RENAMES` entry.
  readonly axis: string;
  /// The REGISTRY component that draws it. Also the `needs` edge below, read
  /// from here so the two cannot disagree.
  readonly component: string;
  /// BOOLEAN properties set on the instance, for a variant that is one
  /// composition of its component rather than its resting pose.
  readonly booleans?: Readonly<Record<string, boolean>>;
  /// The member to instantiate when that component is a set. Named rather
  /// than left to `instanceOf`'s first child, which is an ordering accident.
  readonly member?: string;
}

const kMockupVariants: readonly MockupVariant[] = [
  { axis: 'browser', component: 'MockupBrowser' },
  { axis: 'code', component: 'MockupCode' },
  // The axis keeps the designer's `phone` while the component became the
  // device set — the instance placed here is that set's upright phone.
  {
    axis: 'phone',
    component: 'MockupDevice',
    member: 'Device=phone, Orientation=portrait, Finish=realistic',
  },
  // `MockupBrowser(addressBar: null)` — the desktop app window. Renamed from
  // `Variant=window` (VARIANT_RENAMES), so instances of that member keep their
  // key and now point at the component that draws the composition.
  { axis: 'app', component: 'MockupBrowser', booleans: { 'Show address bar': false } },
];

function buildMockup(page: PageNode, lk: VarLookup): ComponentSetNode {
  const mount = mountSet(page, 'Mockup', kMockupVariants.map((v) => `Variant=${v.axis}`));
  for (const v of kMockupVariants) {
    const c = mount.getOrCreate(`Variant=${v.axis}`);
    applyPanelCompChrome(c, 'VERTICAL', lk, {});
    const surface = instanceOf(page, v.component, v.member);
    surface.name = v.component;
    for (const [name, value] of Object.entries(v.booleans ?? {})) {
      setInstanceBoolNamed(surface, name, value);
    }
    c.appendChild(surface);
  }
  return mount.finish();
}

export const PRIMITIVES_COMPOSITION: RegistryEntry[] = [
  // One instance per variant — the compositions this shared style slot feeds.
  // Read off `kMockupVariants` so the axis list and the build-order edges are
  // the same list; a name that is not in REGISTRY fails `topoSortRegistry`
  // loudly instead of leaving `instanceOf` to throw at run time. Deduplicated
  // because one component can draw more than one variant.
  {
    section: 'Display',
    name: 'Mockup',
    build: buildMockup,
    needs: [...new Set(kMockupVariants.map((v) => v.component))],
  },
];
