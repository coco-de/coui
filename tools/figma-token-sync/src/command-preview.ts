/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { COMPONENTS } from './data';
export const COMMAND = COMPONENTS.command;

// ─── Command (palette) ───────────────────────────────────────────────────────
//
// `command.axes` promotes nothing — `Variant` has one member and it is
// `@behaviourOnly`, `Size` is the component's own `CoreCommandSize` (three
// rungs, so it lands in `other`), and `Presentation` is `other` too. The
// canvas set is what the design states: `Presentation(3) × Size(3) × Empty(2)`
// = 18, named in that order because that is the order the designer's set
// carries and `mountSet` matches members by name.
//
// ── What each axis is ────────────────────────────────────────────────────────
//
// `Presentation` is the SHAPE — chrome and bounds only. `inline` sits in a
// page (radius 12, outline, min width `layout/240`, list capped at
// `layout/320`); `dialog` is the panel a `Dialog` hosts (radius 20, `shadow/lg`,
// max width `layout/640`, list capped at `layout/400`); `fullscreen` fills a
// phone (radius 0, no border, no caps). Scrim and routing belong to the host,
// so nothing here draws them. Every value comes from
// `command.variants.defaultsByPresentation`.
//
// `Size` is density: search-row height, icons, row inset and typography move
// together out of `command.sizes.defaultsBySize`. `Empty` is which branch
// `_buildResults` returned — the rows, or the composed `EmptyState`.
//
// ── Composed children ────────────────────────────────────────────────────────
//
// The rows are `CommandItem` INSTANCES (the set below), the search field is a
// `TextField` `Variant=plain` instance (exposed, so its `Placeholder` surfaces
// on a placed palette), the scope row is `Chip` instances, the empty branch is
// an `EmptyState` instance (exposed, for its `Title` / `Description`), and the
// footer caps are `Kbd` instances through `kbdKey`. What Command draws itself
// is exactly what `command.dart` draws itself: the panel, the search row's
// glyph + gap, the group heading, and the footer strip.
//
// ── Rows ─────────────────────────────────────────────────────────────────────
//
// A row's states are `CommandItem`'s own axes — `Active` (the keyboard cursor)
// and `State` (hover / pressed / disabled) — because they vary per row, and an
// axis on the palette could only say "the third row is active" by minting a
// member per row. The palette's populated members place four rows: the first
// active, one two-line (`Lines=2`, overline above a title), one with a
// shortcut. Copy is the widget's own doc example.
//
// ── Footer ───────────────────────────────────────────────────────────────────
//
// `showFooter` defaults by presentation (`CoreCommandContract
// .defaultShowFooterFor`): only `dialog` shows it, so only the six dialog
// members carry the strip. Its labels are the Korean
// `CoUILocalizations` strings (`coui_i10n/chrome/i18n/ko.i18n.json`).

export const COMMAND_ITEM_NAME = 'CommandItem';
export const kCommandSizes = ['sm', 'md', 'lg'] as const;
export type CommandSize = (typeof kCommandSizes)[number];
