/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { revealValueOverPlaceholder } from './helpers';
export const kFieldValueTextProp = 'Value text';
export const kFieldValueShownProp = 'Value';

// Puts a VALUE into a composed `TextField` — every property that decides
// whether it reads as one, in a single patch.
//
// Every `TextField` these pickers compose is a field with text in it: the hex
// input takes `initialValue: _hexBuffer`, each mode-input cell takes
// `initialValue: '$value'`, and each clock segment takes a `controller` already
// holding its two digits. None of the three passes `placeholder:` or
// `hintText:`, so in the widget `placeholderContent` resolves to null and no
// placeholder is built at all.
//
// `TextField` splits that state across two properties because it models the
// widget's `Stacks(placeholder?, editable)` as two nodes — the placeholder is
// the in-flow child (which is what keeps an empty field and a filled one one
// line box high) and the value rides above it at the same origin, revealed by a
// `Value` BOOLEAN. Writing only `Value text` leaves the copy on a hidden node;
// flipping only `Value` reveals the literal word `Value`. Both, or the field
// says something this picker did not.
//
// The value node is also where the right colour is: `valueStyle` carries none,
// so it resolves to the shared on-surface fallback — which is exactly
// `segmentContentColor` / `contentColor`, the colour these widgets state for a
// value. The placeholder node paints the muted `affixColor` instead.
//
// The placeholder NODE is hidden, which is the state these three call sites
// actually have: none of them passes `placeholder:` or `hintText:`, so
// `placeholderContent` resolves to null and the widget builds no placeholder at
// all. Its copy is left alone — the component's own default hint belongs to the
// component, and overwriting it with this instance's value would only lie to
// whoever re-shows it.
//
// What used to be here instead was both nodes visible carrying the same copy, on
// the theory that identical strings at one origin register exactly and the value
// is what reads. They do not register, and the clock segment is where that
// became visible: its value is restyled to a 44px `displaySmall` while the
// placeholder is 14px, and the two drew as digits with a second offset copy
// behind them. Even at equal size the premise was wrong — the placeholder is the
// in-flow child and the value is absolute, so nothing keeps them aligned; equal
// copy only made the disagreement small enough to miss.
//
// Hiding it was ruled out before, for a reason that was true when written: the
// input stack's only in-flow child is the placeholder, so hiding it collapsed
// the frame and took the ABSOLUTE value holder down with it. That is why the
// value comes into flow first, here, in the same patch — then the stack hugs the
// value, the placeholder's space is not needed, and the field is one string.
//
// Throws rather than no-ops when any of the three is missing, the way
// `setSlotIcon` throws on an empty patch: a field silently showing
// `Placeholder` where its value belongs is green in every other signal, and the
// run log names the loud version as one failing entry.
export function setFieldValue(inst: InstanceNode, text: string): void {
  const props: ComponentProperties | undefined = inst.componentProperties;
  if (!props || typeof inst.setProperties !== 'function') return;
  const patch: { [key: string]: string | boolean } = {};
  for (const key of Object.keys(props)) {
    const label = key.split('#')[0];
    if (label === kFieldValueTextProp && props[key].type === 'TEXT') patch[key] = text;
    if (label === kFieldValueShownProp && props[key].type === 'BOOLEAN') patch[key] = true;
  }
  const wanted = 2;
  if (Object.keys(patch).length !== wanted) {
    throw new Error(
      `setFieldValue: ${inst.name} does not declare both '${kFieldValueTextProp}' ` +
        `(TEXT) and '${kFieldValueShownProp}' (BOOLEAN), so this value has ` +
        `nowhere to land that renders. Its properties are ` +
        `[${Object.keys(props).map((k) => k.split('#')[0]).join(', ')}] — ` +
        'TextField renamed them, or this is not a TextField.',
    );
  }
  inst.setProperties(patch);
  revealValueOverPlaceholder(inst);
}
