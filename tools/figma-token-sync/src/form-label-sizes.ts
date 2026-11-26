/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { COMPONENTS } from './data';
import { distinctSizeCells } from './axis-combos';
export const FORM_LABEL = COMPONENTS.form_label;

// ─── FormLabel (label + required asterisk) ───────────────────────────────────

// Data-driven from coui_core FORM_LABEL: `sizes.defaultsBySize[size].labelStyle`
// drives the "Password" text's role — `xs`/`sm`/`md` read `labelMedium` (13px),
// `lg`/`xl`/`xl2` read `labelLarge` (14px), in `onSurfaceVariant`, Figma
// "❖ FormLabel" `Size` axis — a two-value ladder on the shared six-tier scale
// (`CoreFormLabelStyle.defaultsBySize`). The "*"
// indicator reuses that role at `requiredColor` (error) while `Enabled=true`;
// while `Enabled=false` BOTH the label and the indicator switch to the SAME
// `disabledColor` (`form_label_style.dart`'s `resolveFormLabel` — the tone
// dims the `*` along with the label it marks, rather than leaving it in its
// enabled colour). `requiredIndicatorGapStyle` drives the gap between them
// and is not size-keyed — one flat value at every rung.
//
// The `Size=` cells FormLabel draws — one per distinct row of its ladder.
// Exported because the sets that compose a FormLabel (`TextField`,
// `TextArea`) pick the label cell for their own size through `cellFor`, and
// must agree with the cells this builder made.
export function formLabelSizeCells() {
  return distinctSizeCells(
    new Map(Object.entries(FORM_LABEL.sizes.defaultsBySize)),
    FORM_LABEL.axes.size.members,
    FORM_LABEL.constants.size.choice,
  );
}
