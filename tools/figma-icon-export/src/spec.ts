/// <reference types="@figma/plugin-typings" />

// Single source of truth for the icon/splash variant matrix. Numbers here are
// carried over from a manual, screenshot-verified build against real shipped
// assets (see kobic repo `.claude/rules/app-icon-splash-guidelines.md`):
//   - Android Adaptive Icon safe zone: 66dp/108dp ≈ 61.1% → guide diameter 626/1024
//   - Android 12+ splash safe zone: 768/1152 ≈ 66.7% → guide diameter 683/1024,
//     logo scaled 0.84x (content ratio lands at ~57-60%, matches shipped asset)
//   - Android adaptive foreground/monochrome logo scale 0.8x (content ~54-57%,
//     safely under 61.1%; shipped assets are more conservative at ~43-53%, this
//     is a deliberately roomier default template)
//   - iOS squircle guide corner radius ≈ 22.4% of canvas (229/1024)
//   - Desktop (macOS/Windows/Linux) squircle guide corner radius ≈ 18% (184/1024)
//   - Android legacy square guide corner radius ≈ 15% (154/1024)
// Do not "round" these to prettier numbers without re-verifying against a real
// exported PNG's ink bounding box — the guide corridor is intentionally tight.

export const CANVAS = 1024;

export type GuideShape =
  | { kind: 'none' }
  | { kind: 'ellipse'; size: number }
  | { kind: 'roundedRect'; size: number; cornerRadius: number; cornerSmoothing: number };

export interface PlatformSpec {
  key: string; // Figma variant name segment, also used to derive default filenames
  /** true = opaque background fill (icon/background var); false = transparent */
  opaqueBg: boolean;
  /** Fixed background override (hex). If unset and opaqueBg, uses the plugin's
   *  bg-light/bg-dark input. iOS variants each need their own fixed treatment
   *  because they do NOT use the generic brand-color background. */
  fixedBg?: { light: string; dark?: string };
  /** 0 = no logo instance at all (e.g. a pure background layer) */
  logoScale: number;
  /** true = override every fill inside the logo instance to a single gray tone
   *  (iOS 18+ tinted app icon requirement) */
  grayscaleLogo?: boolean;
  guide: GuideShape;
  /** Real shipped filename this variant maps to (production; dev/stg append
   *  `_dev`/`_stg` before the extension). Multiple platforms may share a file
   *  (e.g. Desktop and Android-LegacyRadius both ship as ic_logo_radius.png). */
  filenameBase: string | null; // null = no direct 1:1 code asset (documentation-only)
  /** true = this filename is NOT flavor-specific; dev/stg export the exact same
   *  file as production (still exported 3x for completeness, but flagged in UI log) */
  flavorAgnostic?: boolean;
}

export const APP_ICON_PLATFORMS: PlatformSpec[] = [
  {
    key: 'iOS-Light',
    opaqueBg: true,
    fixedBg: { light: '#FFFFFF' },
    logoScale: 1.0,
    guide: { kind: 'roundedRect', size: CANVAS, cornerRadius: 229, cornerSmoothing: 0.6 },
    filenameBase: 'ic_logo_rectangle_light',
  },
  {
    key: 'iOS-Dark',
    opaqueBg: true,
    fixedBg: { light: '#1C1C1E' }, // real asset has a subtle gradient; flat color approximation
    logoScale: 1.0,
    guide: { kind: 'roundedRect', size: CANVAS, cornerRadius: 229, cornerSmoothing: 0.6 },
    filenameBase: 'ic_logo_rectangle_dark',
  },
  {
    key: 'iOS-Tinted',
    opaqueBg: true,
    fixedBg: { light: '#000000' },
    logoScale: 1.0,
    grayscaleLogo: true,
    guide: { kind: 'roundedRect', size: CANVAS, cornerRadius: 229, cornerSmoothing: 0.6 },
    filenameBase: 'ic_logo_rectangle_tinted',
  },
  {
    key: 'Desktop (macOS-Windows-Linux)',
    opaqueBg: true,
    logoScale: 1.0,
    guide: { kind: 'roundedRect', size: CANVAS, cornerRadius: 184, cornerSmoothing: 0.6 },
    filenameBase: 'ic_logo_radius',
  },
  {
    key: 'Android-Background',
    opaqueBg: true,
    logoScale: 0,
    guide: { kind: 'ellipse', size: 626 },
    filenameBase: 'ic_background',
    flavorAgnostic: true,
  },
  {
    key: 'Android-Foreground',
    opaqueBg: false,
    logoScale: 0.8,
    guide: { kind: 'ellipse', size: 626 },
    filenameBase: 'ic_foreground',
  },
  {
    key: 'Android-Monochrome',
    opaqueBg: false,
    logoScale: 0.8,
    guide: { kind: 'ellipse', size: 626 },
    filenameBase: 'ic_black_white',
  },
  {
    key: 'Android-LegacyRadius',
    opaqueBg: true,
    logoScale: 1.0,
    guide: { kind: 'roundedRect', size: CANVAS, cornerRadius: 154, cornerSmoothing: 0 },
    filenameBase: 'ic_logo_radius',
  },
  {
    key: 'Android-LegacyRound',
    opaqueBg: true,
    logoScale: 1.0,
    guide: { kind: 'ellipse', size: CANVAS },
    filenameBase: 'ic_logo_round',
  },
];

export const SPLASH_PLATFORMS: PlatformSpec[] = [
  {
    key: 'Normal (iOS-Android-Web)',
    opaqueBg: true,
    logoScale: 1.0,
    guide: { kind: 'ellipse', size: CANVAS },
    filenameBase: 'splash_logo',
    flavorAgnostic: true,
  },
  {
    key: 'Android 12+',
    opaqueBg: true,
    logoScale: 0.84,
    guide: { kind: 'ellipse', size: 683 },
    filenameBase: 'splash_logo_android12',
    flavorAgnostic: true,
  },
];

export interface FlavorSpec {
  key: 'Production' | 'Development' | 'Staging';
  suffix: '' | '_dev' | '_stg';
  badge: { label: string; color: RGB } | null;
}

export const FLAVORS: FlavorSpec[] = [
  { key: 'Production', suffix: '', badge: null },
  { key: 'Development', suffix: '_dev', badge: { label: 'DEV', color: { r: 0.133, g: 0.835, b: 0.667 } } },
  { key: 'Staging', suffix: '_stg', badge: { label: 'STG', color: { r: 0.078, g: 0.537, b: 0.992 } } },
];

export const GUIDE_COLOR: RGB = { r: 0.988, g: 0.31, b: 0.306 };
export const TINT_GRAY: RGB = { r: 0.2, g: 0.2, b: 0.212 };

export function variantName(platform: string, flavor: FlavorSpec['key']): string {
  return `Platform=${platform}, Flavor=${flavor}`;
}

export function exportFilename(platform: PlatformSpec, flavor: FlavorSpec): string | null {
  if (!platform.filenameBase) return null;
  const suffix = platform.flavorAgnostic ? '' : flavor.suffix;
  return `${platform.filenameBase}${suffix}.png`;
}
