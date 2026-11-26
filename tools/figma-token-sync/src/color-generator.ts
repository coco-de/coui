/// <reference types="@figma/plugin-typings" />

// Pure color-space math + primitive-palette generator. This is a hand-port of
// `packages/coui_core/lib/src/color/color_conversion.dart`
// (`CoreColorConversion.fromHSL`) and
// `packages/coui_core/lib/src/color/primitive_colors.dart`
// (`NeutralScale.fromHue` / `ChromaticScale.fromHSL`) — same constants, same
// branch order, so a palette generated here matches what
// `PrimitiveColors.generate` would produce for the same input in Dart (single
// source of truth; ported by hand because this plugin has no way to execute
// Dart at build time).
//
// Variable names emitted here are the generated palette's 64 scale names
// (`color/neutral/grey-lightest`, `color/primary/base`) — the vocabulary
// `PrimitiveColors` has. CoUI's own palette is fixed hex with numbered steps
// (`neutral/50` … `base/black`) and is not produced by this generator.
//
// No `figma` API usage in this file on purpose — keeps the math testable
// (via `npm run typecheck`) independent of the plugin sandbox.

export interface Rgb255 {
  r: number; // 0-255
  g: number; // 0-255
  b: number; // 0-255
  a: number; // 0-255
}

const HUE_MAX = 360;

// Dart's `%` always returns a non-negative result for a positive divisor;
// JS's does not for a negative dividend. Normalize so hue wrap-around is
// numerically identical to the Dart source.
function mod(n: number, m: number): number {
  return ((n % m) + m) % m;
}

function hex2(n: number): string {
  const s = Math.round(n).toString(16);
  return s.length < 2 ? `0${s}` : s;
}

export function rgb255ToHex(c: Rgb255): string {
  return `#${hex2(c.r)}${hex2(c.g)}${hex2(c.b)}`.toUpperCase();
}

// CoreColorConversion.fromHSL
function fromHSL(h: number, s: number, l: number, a = 1): Rgb255 {
  const hNorm = mod(h, HUE_MAX) / HUE_MAX;
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((hNorm * 6) % 2) - 1));
  const m = l - c / 2;

  let r: number;
  let g: number;
  let b: number;
  if (hNorm < 1 / 6) {
    r = c;
    g = x;
    b = 0;
  } else if (hNorm < 2 / 6) {
    r = x;
    g = c;
    b = 0;
  } else if (hNorm < 3 / 6) {
    r = 0;
    g = c;
    b = x;
  } else if (hNorm < 4 / 6) {
    r = 0;
    g = x;
    b = c;
  } else if (hNorm < 5 / 6) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return {
    a: Math.round(a * 255),
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255),
  };
}

// ─── Neutral scale — NeutralScale.fromHue ───────────────────────────────────
// Weber-Fechner lightness (narrow at the extremes, wide in the middle) with an
// inverted-bell saturation (minimal at mid-lightness). Hue comes from the
// input; `pure-white` / `pure-black` are hue-independent constants.

interface NeutralStep {
  slug: string;
  s: number;
  l: number;
}

const NEUTRAL_STEPS: NeutralStep[] = [
  { slug: 'white', s: 0.06, l: 0.99 },
  { slug: 'white-dark', s: 0.05, l: 0.95 },
  { slug: 'white-darker', s: 0.04, l: 0.9 },
  { slug: 'grey-lightest', s: 0.03, l: 0.84 },
  { slug: 'grey-lighter', s: 0.03, l: 0.77 },
  { slug: 'grey-light', s: 0.02, l: 0.69 },
  { slug: 'grey', s: 0.02, l: 0.6 },
  { slug: 'grey-dark', s: 0.02, l: 0.5 },
  { slug: 'grey-darker', s: 0.02, l: 0.4 },
  { slug: 'grey-darkest', s: 0.03, l: 0.31 },
  { slug: 'black-lighter', s: 0.04, l: 0.23 },
  { slug: 'black-light', s: 0.05, l: 0.16 },
  { slug: 'black', s: 0.06, l: 0.1 },
];

const PURE_WHITE: Rgb255 = { r: 255, g: 255, b: 255, a: 255 };
const PURE_BLACK: Rgb255 = { r: 0, g: 0, b: 0, a: 255 };

// ─── Chromatic scale — ChromaticScale.fromHSL ───────────────────────────────
// Bidirectional lerp from the authored base lightness toward fixed targets:
// light side → 0.95 (background-safe), dark side → 0.15 (text-safe).
// Saturation is preserved across all 7 steps.

const LIGHT_TARGET = 0.95;
const DARK_TARGET = 0.15;

interface ChromaticStep {
  slug: string;
  t: number;
  /** `true` lerps toward LIGHT_TARGET, `false` toward DARK_TARGET. */
  lighter: boolean;
}

const CHROMATIC_STEPS: ChromaticStep[] = [
  { slug: 'lightest', t: 0.95, lighter: true },
  { slug: 'lighter', t: 0.85, lighter: true },
  { slug: 'light', t: 0.55, lighter: true },
  { slug: 'base', t: 0, lighter: true },
  { slug: 'dark', t: 0.55, lighter: false },
  { slug: 'darker', t: 0.85, lighter: false },
  { slug: 'darkest', t: 0.95, lighter: false },
];

/** The closed set of chromatic roles `PrimitiveColors.generate` accepts. */
export const CHROMATIC_ROLES = [
  'primary',
  'secondary',
  'tertiary',
  'success',
  'info',
  'warning',
  'error',
] as const;

export type ChromaticRole = (typeof CHROMATIC_ROLES)[number];

/** One authored chromatic role. `s` / `l` are 0-1 (Dart convention). */
export interface HslInput {
  h: number;
  s: number;
  l: number;
}

/** The 8 inputs of `PrimitiveColors.generate`. */
export type PaletteInput = {
  neutralHue: number;
} & { [K in ChromaticRole]: HslInput };

export interface PaletteSwatch {
  /** Figma variable name, e.g. `color/primary/base`. */
  name: string;
  /** Group this swatch belongs to, e.g. `neutral` / `primary`. */
  group: string;
  /** Step within the group, e.g. `grey-lightest` / `base`. */
  step: string;
  color: Rgb255;
  hex: string;
}

function swatch(group: string, step: string, color: Rgb255): PaletteSwatch {
  return {
    name: `color/${group}/${step}`,
    group,
    step,
    color,
    hex: rgb255ToHex(color),
  };
}

function chromaticLightness(baseL: number, step: ChromaticStep): number {
  if (step.t === 0) return baseL;
  return step.lighter
    ? baseL + (LIGHT_TARGET - baseL) * step.t
    : baseL - (baseL - DARK_TARGET) * step.t;
}

/**
 * Expands the 8 authored inputs into the full 64-color primitive palette —
 * 15 neutral + 7 roles x 7 steps — keyed by the same variable names the token
 * exporter emits.
 */
export function generatePrimitivePalette(input: PaletteInput): PaletteSwatch[] {
  const out: PaletteSwatch[] = [swatch('neutral', 'pure-white', PURE_WHITE)];

  for (const step of NEUTRAL_STEPS) {
    out.push(
      swatch('neutral', step.slug, fromHSL(input.neutralHue, step.s, step.l)),
    );
  }
  out.push(swatch('neutral', 'pure-black', PURE_BLACK));

  for (const role of CHROMATIC_ROLES) {
    const hsl = input[role];
    for (const step of CHROMATIC_STEPS) {
      out.push(
        swatch(
          role,
          step.slug,
          fromHSL(hsl.h, hsl.s, chromaticLightness(hsl.l, step)),
        ),
      );
    }
  }

  return out;
}
