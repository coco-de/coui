/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { instanceOf, setInstanceBoolNamed } from './helpers';
import { COMPONENTS } from './data';
import { composeVariantName } from './axis-combos';
// Popup's composition contract: variant selection and instance overrides are
// shared with its renderer and consumers without importing the registry module.

export const POPUP = COMPONENTS.popup;

// ─── Popup ───────────────────────────────────────────────────────────────────

// ─── The `Padding` axis ──────────────────────────────────────────────────────
//
// `CorePopupStyle` keeps the inset as ONE field (`padding`) with two named
// presets — `defaultContentPadding` (16, free-form content: a form, a card, a
// calendar) and `defaultListPadding` (6, a panel that holds rows, so the rows
// sit concentrically in the panel radius). A popup cannot know which it holds,
// so `defaultPadding` is the content preset and the component that holds a list
// states the list one. The canvas draws the two presets as the two members of a
// `Padding` axis so a parent composes the one its code states, rather than
// overriding the inset on an instance of the other.
//
// Both values come from the export: `content` from the field the resolver reads
// (`fields.padding`), `list` from the named constant (`constants.listPadding`).
// `popupPaddingData` refuses a `contentPadding` constant that has drifted from
// the field — the axis would otherwise name two different `content`s.
export const kPopupPaddings = ['content', 'list'] as const;
export type PopupPadding = (typeof kPopupPaddings)[number];
/** The member nothing asked to be a list: `defaultPadding` is the content preset. */
export const kPopupDefaultPadding: PopupPadding = 'content';

/** The member name a composing parent asks for (`Padding=list`). */
export function popupVariantName(padding: PopupPadding): string {
  return composeVariantName([['Padding', padding]]);
}

export function popupPaddingData(padding: PopupPadding): typeof POPUP.fields.padding {
  const stated = POPUP.constants;
  const same = (a: typeof POPUP.fields.padding, b: typeof POPUP.fields.padding): boolean =>
    a.l.v === b.l.v && a.t.v === b.t.v && a.r.v === b.r.v && a.b.v === b.b.v;
  if (!same(POPUP.fields.padding, stated.contentPadding)) {
    throw new Error(
      'Popup: `fields.padding` and `constants.contentPadding` disagree — the `content` ' +
        'member would be two different insets. `CorePopupStyle.defaultPadding` is the ' +
        'content preset; if that changed, the axis needs a decision, not a guess.',
    );
  }
  return padding === 'list' ? stated.listPadding : POPUP.fields.padding;
}

/** An inset a parent's `Style` states, as the export spells it. */
export interface StatedPopupPadding {
  readonly l: { readonly v: number };
  readonly t: { readonly v: number };
  readonly r: { readonly v: number };
  readonly b: { readonly v: number };
}

/**
 * The preset a stated inset IS, or null when it is neither.
 *
 * Matched by value on all four sides: the parent's code states `padding` as a
 * number, and the preset it names (`CorePopupStyle.defaultListPadding`) is that
 * number — the export carries no name for it.
 */
export function popupPaddingFor(stated: StatedPopupPadding): PopupPadding | null {
  for (const padding of kPopupPaddings) {
    const want = popupPaddingData(padding);
    if (
      stated.l.v === want.l.v &&
      stated.t.v === want.t.v &&
      stated.r.v === want.r.v &&
      stated.b.v === want.b.v
    ) {
      return padding;
    }
  }
  return null;
}

/**
 * An instance of the `Popup` member a parent's code asks for.
 *
 * A parent that states a preset inset (`panelStyle.padding` = 6, the list
 * preset) gets that member; one that states a one-off inset, or none, gets the
 * default `content` member — a popup that holds arbitrary content does not know
 * it holds a list. Named `Popup` rather than the member's `Padding=…`, because
 * the composed surface is the popup, and the layers around it find it by that name.
 */
export function popupInstance(page: PageNode, stated?: StatedPopupPadding | null): InstanceNode {
  const padding = (stated != null ? popupPaddingFor(stated) : null) ?? kPopupDefaultPadding;
  const instance = instanceOf(page, 'Popup', popupVariantName(padding));
  instance.name = 'Popup';
  return instance;
}

/**
 * The inset still to write onto an instance made by [popupInstance]: null when
 * the member already draws it, so the instance carries no override that merely
 * repeats its main component.
 */
export function popupPaddingOverride<T extends StatedPopupPadding>(stated: T): T | null {
  return popupPaddingFor(stated) == null ? stated : null;
}

// The slot `children` is drawn as. One `.Slot` stand-in rather than sample
// copy: `children` is `List<W>`, any widgets, and the copy that stood here
// ("Popup content" / "Second row") was a picture of one particular content.
// Composing parents need the opposite of a picture — `Menu`, `Fab` and the
// ContextMenu preview lay their own rows over the surface and turn the slot off
// (`hidePopupContent`), `Popover` / `NavigationMenu` leave it showing and a
// designer swaps it through `Content`. Fixed copy offered neither: shown it
// could only be edited, never replaced, and a parent that hid it under its own
// rows showed it again the day a scoped Popup redraw replaced those nodes and
// the parent was not redrawn with it.
//
// That is why the off switch is a property (`Show content`) and not a hidden
// layer: a hidden layer is an override on a node id, and a redraw that
// replaces the node drops it; a property value lives on the instance, keyed by
// the property, and is applied to whichever node is bound to it now.
//
// `contentColor` has no reader here any more: it is the ambient text colour
// the widget installs over the caller's children, and the stand-in carries no
// text. It reaches the canvas the day a parent puts copy in the slot.
//
// The stand-in keeps its own box (the `.Slot` member's 160 × 40) — the slot
// box the designer's `Popup(리디자인)` draws — and the popup hugs it.
export const kPopupContentSlotName = 'content';
/** The BOOLEAN a parent turns off when it lays its own rows over the surface. */
export const kPopupShowContentProp = 'Show content';

/**
 * Empties a composed `Popup`'s `children` slot, for a parent whose own rows
 * ARE those children and ride over the surface (`Menu`, `Fab`, the ContextMenu
 * preview). Through the property, never `visible` on the node inside the
 * instance — see the note above `kPopupContentSlotName`.
 */
export function hidePopupContent(instance: InstanceNode): void {
  setInstanceBoolNamed(instance, kPopupShowContentProp, false);
}
