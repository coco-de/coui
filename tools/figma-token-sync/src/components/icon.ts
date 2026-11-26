/// <reference types="@figma/plugin-typings" />

// The `Icon` component — VALIDATED here, not built.
//
// `Icon` is authored by the designer on `❖ Icon` and the plugin is a consumer
// of it. It is a COMPONENT_SET with a `Size=N` variant axis and ONE
// INSTANCE_SWAP property that chooses the glyph; the glyphs live in four
// separate library files (Lucide / Bootstrap / Radix / HeroIcons) rather than
// in the DS file, which is what let the catalogue grow past the handful the
// plugin used to draw.
//
// Why the plugin stopped owning it: the glyph vocabulary is now ~5,000 across
// four catalogues and the whole plugin bundle is one file the Figma sandbox
// parses per run. Shipping that as path data is not possible, and it does not
// need to be — a swap property reaches every glyph in an enabled library for
// free.
//
// ─── What this entry MUST NOT do ─────────────────────────────────────────────
//
// Three calls would each destroy designer-owned work, and all three are the
// normal shape of a builder in this file:
//
//   · `mountSet(...)` — its `finish()` diffs the existing variant names
//     against the ones this builder declares. `Size=16…48` are not names a
//     glyph-axis builder produces, so they read as `unexplained`, and it
//     throws `VariantIdentityError` (identity.ts). It refuses to delete them
//     (S-a), which is the only reason the restructure survived the first run.
//   · `resetNode(...)` — blanks the component, taking the designer's glyph
//     instance with it.
//   · `defaultSetLayout(...)` — relayouts the set, moving variants the
//     designer arranged.
//
// So this entry locates the set, asserts the shape `makeIcon` depends on, and
// returns it untouched. It must stay in the REGISTRY even though it builds
// nothing: `topoSortRegistry` throws on a `needs` name that is not a REGISTRY
// name, and every icon-bearing entry declares a `needs` edge on `Icon`. (No
// count here on purpose — one would drift the first time a component gains or
// loses an icon, and nothing checks it.)
//
// ─── What it asserts, and why each one is invisible otherwise ────────────────
//
//   · a `Size=N` axis exists — without it `makeIcon` has nothing to instance.
//   · exactly one INSTANCE_SWAP — two, and the glyph chooser is ambiguous.
//   · every `Size=N` pins mode `N` in each variable collection it pins. If
//     `Size=20` ever pins mode `16`, every 20px icon draws the 16-grid stroke
//     and NOTHING else in the pipeline notices — the same class of silent
//     failure as the 2/3-size defect, and this is the only check that can
//     catch it.
//
// The cost, stated plainly: per-use colour is an instance override on a main
// the CoUI team does not own. The library binds glyph strokes to one token
// (`color/on-surface`); every other semantic colour is an override written
// onto a REMOTE main's vectors. A republish that restructures glyphs can reset
// those overrides, and there is no plugin-side defence.

import { RegistryEntry, VarLookup, sizeStepsOf } from '../helpers';
import { findComponentByName } from '../identity';

/**
 * Locates the designer's `Icon` set and checks the shape `makeIcon` needs.
 *
 * Builds nothing. See this file's header for the three calls that would each
 * destroy designer work if this were written as a normal builder.
 */
function validateIcon(page: PageNode, _lk: VarLookup): ComponentSetNode {
  const found = findComponentByName(page, 'Icon');
  if (!found || found.type !== 'COMPONENT_SET') {
    throw new Error(
      'Icon: the `Icon` COMPONENT_SET is missing from the document. It is ' +
        'designer-owned and lives on `❖ Icon`. The plugin no longer builds it, ' +
        'so it cannot be recreated by re-running — restore it from Figma ' +
        'version history.',
    );
  }

  const steps = sizeStepsOf(found);
  if (steps.length === 0) {
    throw new Error(
      'Icon: the set has no `Size=N` variants. `makeIcon` instances a step of ' +
        'that axis, so every icon-bearing component would fail.',
    );
  }

  const swaps = Object.keys(found.componentPropertyDefinitions).filter(
    (k) => found.componentPropertyDefinitions[k].type === 'INSTANCE_SWAP',
  );
  if (swaps.length !== 1) {
    throw new Error(
      `Icon: expected exactly one INSTANCE_SWAP property (the glyph chooser), ` +
        `found ${swaps.length}. \`makeIcon\` cannot tell which one to set.`,
    );
  }

  // The mode-pin check is NOT here. It has to resolve each pinned collection to
  // read the mode's name, and the synchronous variable API is off under this
  // plugin's `documentAccess: "dynamic-page"` manifest — `getVariableById`
  // throws under it, and a builder cannot await the async twin. It runs in
  // `generate.ts`'s async prelude instead, next to the glyph import, which is
  // the only place in a run that can await.

  return found;
}

export const ICON_BUILDERS: RegistryEntry[] = [
  { section: 'Display', name: 'Icon', validateOnly: true, build: validateIcon },
];
