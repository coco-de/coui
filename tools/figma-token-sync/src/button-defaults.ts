/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.
import { COMPONENTS } from './data';
import type { Dim } from './compat/v1';
// The colour a glyph inside a composed `Button` inherits — that button
// variant's own resting foreground.
//
// Read off `Button`'s exported defaults rather than named here, because that
// is where the widget reads it too: the glyph's own `iconStyle` carries only a
// size, and the colour arrives through the button's ambient `IconTheme`. The
// same reason `avatarBadgeSlot` reads `badgeSize` off the composed child.
export const kPlainButtonForeground = COMPONENTS.button.variants.defaultsByVariant.plain.foregroundColor;

// The glyph an icon-only (`square` / `circle`) Button draws at `size`, unless
// the caller's slot states one — `CoreButtonStyle.iconSizeFor` on both
// platforms. A panel's close affordance that states no `leadingIconStyle`
// (Banner, Toast) takes the row's `iconShapeIconStyle` through the button's
// ambient icon theme, so the canvas reads the same row (#6214).
type ButtonSizeRow = { iconShapeIconStyle?: { size: unknown } };
export function iconShapeGlyphSize(size: string, slot?: object | null): number | Dim {
  const stated = (slot as { leadingIconStyle?: { size?: unknown } | null } | null | undefined)?.leadingIconStyle?.size;
  if (stated != null) return stated as number | Dim;
  const rows = (COMPONENTS.button.sizes as unknown as { defaultsBySize: Record<string, ButtonSizeRow> }).defaultsBySize;
  const row = rows[size] ?? (() => { throw new Error(`Button has no size row "${size}"`); })();
  const v = row.iconShapeIconStyle?.size;
  if (v == null) throw new Error(`Button "${size}" row states no iconShapeIconStyle size`);
  return v as number | Dim;
}
