/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { ShadowData } from './helpers';
import { optField } from './compat/v1';
import { COMPONENTS } from './data';
export const OUTLINED_CONTAINER = COMPONENTS.outlined_container;

// ─── OutlinedContainer ───────────────────────────────────────────────────────

// Whether a `CoreClipBehavior` confines children to the node's own path.
//
// Three of the four members clip and differ only in HOW the edge is
// antialiased, which is a rasteriser setting with no Figma counterpart — Figma
// antialiases unconditionally. `clipsContent` is the one bit that survives the
// mapping, and it is the bit that decides whether a child paints over the
// rounded corner.
//
// Enumerated rather than `!== 'none'` so a member added to the enum arrives
// here as a throw instead of being silently folded into "clips". The throw is
// the safe arm for the reason `alignmentOf` (display.ts) gives: every builder
// runs against the committed `components.json` in `selftest-registry-runtime`,
// so an unknown name fails on the machine that added it and never reaches a
// canvas — while a wrong default is invisible, because a box that clips and a
// box that does not look identical until a child reaches a corner.
const kClipsContent: Readonly<Record<string, boolean>> = {
  none: false,
  hardEdge: true,
  antiAlias: true,
  antiAliasWithSaveLayer: true,
};

// Exported because `Stacks` and `Frame` state a `clipBehavior` too, and both were
// asserting `clipsContent = true` as a literal — right for `hardEdge` (what both
// state today) and wrong the moment either moves to `.none`, which is the one
// member that does not clip. Two components asserting a boolean the data already
// decides is two places to forget.
export function clipsFor(leaf: { readonly choice: string }, field: string): boolean {
  const clips = kClipsContent[leaf.choice];
  if (clips === undefined) {
    throw new Error(
      `${field}: unknown CoreClipBehavior "${leaf.choice}". Add it to ` +
        '`kClipsContent` in primitives-chrome.ts with whether that member ' +
        'confines children to the node path (see ' +
        'coui_core/lib/src/component/contracts/stacks/core_clip_behavior.dart). ' +
        `Known: ${Object.keys(kClipsContent).join(', ')}.`,
    );
  }
  return clips;
}

// The shadow stack an `elevation` choice contributes, following the resolver's
// own precedence: `outlined_container_style.dart` does
// `coreShadow = merged.boxShadow ?? elevation.layers`, so the elevation is the
// source whenever no explicit stack overrides it — and an explicit stack "wins
// outright rather than layering on top of the elevation preset".
//
// Only `none` can be honoured, and not because Figma lacks the means: a drop
// shadow is `setShadow`'s whole job. The gap is upstream — `elevation` is
// exported as a bare `{"choice": …}` while the geometry each choice names
// (`CoreOutlinedContainerStyle.defaultSoftShadow` / `defaultMediumShadow` /
// `defaultStrongShadow`, aliases of `CoreShadow.sm/md/lg`) is not exported at
// all. Drawing `soft` would mean picking offsets and blurs here, or borrowing
// another component's stack: either is this builder deciding a design value,
// which is what `kSlotGlyph` above refuses to do with `controlIconStyle.size`.
//
// So the choice is READ, and the stack it names is read too — from
// `OutlinedContainer`'s own `constants`, which is where the enum resolves:
// `CoreCardElevation.medium.toOutlinedContainerElevation()` →
// `CoreOutlinedContainerStyle.defaultMediumShadow`.
//
// It used to throw here with the missing export named, and the throw was right at
// the time: those `default*Shadow` consts have no matching instance field (the
// primitive's elevation is a choice, not a stack a caller passes), and the reader
// dropped every such const. Reading Popup's stack instead would have "worked" —
// it is `CoreShadow.md` too, by its own independent decision — and that is why the
// throw was better than the workaround: the day Popup moved to `lg`, Card's hover
// shadow would have followed it with nothing red anywhere.
//
// An unknown choice still throws. A new elevation step with no exported stack is
// the same situation as before, and painting flat is the failure a shadow has
// every time.
export function elevationLayers(
  leaf: { readonly choice: string },
  explicit: ShadowData,
  field: string,
): ShadowData {
  if (leaf.choice === 'none' || explicit.layers.length > 0) return explicit;
  const stack = optField<ShadowData>(
    OUTLINED_CONTAINER.constants,
    `${leaf.choice}Shadow`,
  );
  if (stack != null) return stack;
  throw new Error(
    `${field}: elevation "${leaf.choice}" names a shadow stack the export does ` +
      'not carry. `CoreOutlinedContainerStyle.default*Shadow` (soft → sm, ' +
      'medium → md, strong → lg) reaches components.json through the ' +
      '`constants` bucket; a step named here with no const there has to be ' +
      'exported before this builder can paint it — inventing offsets would put ' +
      'a design decision in the plugin.',
  );
}
