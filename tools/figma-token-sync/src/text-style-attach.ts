/// <reference types="@figma/plugin-typings" />

// A label's text style, attached while the member holding it is still off its
// set — and before that set's fingerprint is taken.
//
// It used to be one pass at the end of the run. Three things moved it into the
// entry that drew the label:
//
// 1. Cost. A call on a node inside a large component set is paid for by the
//    set: on the 972-member Button the end-of-run pass took 750.8s, 0.77s a
//    label, flat from the first label to the last, while the same run drew each
//    member — dozens of writes — in about a tenth of a second off the set. The
//    builders that yield (`buildButton`, `buildChip`) take their members out of
//    the set for the loop, so a style attached before `finish()` is a write on
//    a loose node.
// 2. The fingerprint. Hand-edit preservation stamps a set right after drawing
//    it and compares on the next run. A style rewrites fields the stamp reads
//    (`fontName`, `lineHeight`, `letterSpacing`) whenever style and label differ
//    as strings — the family is one such string: the label takes it from a
//    variable, the style from a literal — so a style attached after the stamp
//    can make the next run read its own output as a designer's edit.
// 3. Failure. Inside the entry's try/catch a failed attach fails that entry and
//    it rebuilds next run. At the end of the run every entry had already been
//    stamped by the time the pass could throw.
//
// Where the drains sit: never right after `makeLabel`, because a later write in
// the same combo — a decoration, say — would land on top of the style. A
// yielding builder drains at the yield that opens the NEXT combo, the first
// point every write to the previous one is done, and once more before
// `finish()` for the last combo. `generate.ts`
// drains again after `build()` returns; that is the only drain a builder that
// never yields gets, and its members are back in their set by then — the small
// sets are the ones that do not yield.
//
// The node bindings are cleared once the style is on: a node binding and a
// style both claiming `fontSize` have no defined winner in the plugin typings,
// and this repo has already paid once for a binding that quietly overwrote
// what the builder wrote. The style binds the same semantic variables on its
// own layer, so the connection moves rather than disappears.
//
// Binds are not skipped up front. `makeLabel` still binds `fontSize` /
// `letterSpacing` / `fontFamily` and the attach unbinds them, so no path leaves
// a label with neither: a style the document lacks, a face that did not load,
// an entry that threw before its drain — each leaves the label as `makeLabel`
// drew it.
//
// A style resets every range of the node to its own family, so the Hangul a
// monospace label's text face painted (`paintHangulRunsSans`) is monospace
// again the moment the style lands. It is painted once more here, after the
// unbind (which would clear the ranges' family binding too) and before the
// fingerprint, which reads `fontName` — still inside the entry. Whether a range
// write leaves the rest of the node on its style is not measured on the canvas;
// the run counts every range it wrote so the cost is in the log.

import { GrowthSampler } from './growth';
import { paintHangulRunsSans, type SansTarget } from './text-nodes';
import { textStyleNameOf } from './text-styles';

/** A label whose typography role survived `roleDeparture` in `makeLabel`, waiting for its style. */
export interface PendingTextStyle {
  node: TextNode;
  role: string;
}

/** What the run's attaches add up to — read once, for the `✎` line. */
export interface TextStyleAttachStats {
  /** Labels handed to `attach`, the skipped ones included. */
  queued: number;
  attached: number;
  /** Milliseconds inside `attach`, one sample per label. */
  ms: number;
  growth: GrowthSampler;
  /** Style names a role asked for that this document does not have. */
  namesNotFound: Set<string>;
  /** Labels whose style exists but whose face did not load. */
  faceMissing: number;
  /** Labels that carried a decoration when their style was applied… */
  decoratedBefore: number;
  /** …and how many needed it written back after the style cleared it (see
   *  `attach`'s own note — a style always clears it, this always restores). */
  decorationRestored: number;
  /** Hangul ranges of monospace labels painted back in the text face. */
  hangulRuns: number;
  /** Labels whose Hangul repaint threw. The label keeps its style; only its
   *  Hangul is left in the monospace family. */
  hangulFailed: number;
  /** The first of those throws, for the run log — null when none threw. */
  hangulFirstError: string | null;
}

/** How the attach repaints a monospace label's Hangul after its style lands. */
export interface HangulRepaint {
  sans: SansTarget;
  /** True for a role whose style draws in the monospace family. Asked before
   *  anything is read off the node, so every other label costs nothing. */
  isMonoRole(role: string): boolean;
}

export interface TextStyleAttacher {
  attach(items: readonly PendingTextStyle[]): Promise<void>;
  readonly stats: TextStyleAttachStats;
}

/** One key per face — the unit `loadFontAsync` works in. */
export function faceKeyOf(font: FontName): string {
  return JSON.stringify([font.family, font.style]);
}

export interface FacePreload {
  loaded: Set<string>;
  /** `family style` → what `loadFontAsync` threw. */
  failed: Map<string, string>;
  ms: number;
}

/**
 * Every face the document's text styles draw in, loaded once before the first
 * entry. Not left to `loadFonts`: that loads the family the `font-family/sans`
 * variable names, a style carries the family the exporter wrote as a literal,
 * and nothing makes the two strings equal.
 */
export async function preloadTextStyleFaces(styles: Iterable<TextStyle>): Promise<FacePreload> {
  const startedAt = Date.now();
  const loaded = new Set<string>();
  const failed = new Map<string, string>();
  const seen = new Set<string>();
  for (const style of styles) {
    const key = faceKeyOf(style.fontName);
    if (seen.has(key)) continue;
    seen.add(key);
    try {
      await figma.loadFontAsync(style.fontName);
      loaded.add(key);
    } catch (err) {
      failed.set(`${style.fontName.family} ${style.fontName.style}`, String(err));
    }
  }
  return { loaded, failed, ms: Date.now() - startedAt };
}

/**
 * `bill` gets each label's start time as its sample closes. `generate.ts`
 * passes `recordDetailSpan('attach', …)`, so the time lands on the entry that
 * drew the label.
 */
export function createTextStyleAttacher(
  styleIndex: ReadonlyMap<string, TextStyle>,
  loadedFaces: ReadonlySet<string>,
  bill: (startedAt: number) => void,
  hangul: HangulRepaint | null = null,
): TextStyleAttacher {
  const stats: TextStyleAttachStats = {
    queued: 0,
    attached: 0,
    ms: 0,
    growth: new GrowthSampler(),
    namesNotFound: new Set<string>(),
    faceMissing: 0,
    decoratedBefore: 0,
    decorationRestored: 0,
    hangulRuns: 0,
    hangulFailed: 0,
    hangulFirstError: null,
  };
  return {
    stats,
    async attach(items: readonly PendingTextStyle[]): Promise<void> {
      for (const item of items) {
        const startedAt = Date.now();
        stats.queued += 1;
        try {
          const node = item.node;
          if (node.removed) continue;
          const name = textStyleNameOf(item.role);
          const style = name == null ? undefined : styleIndex.get(name);
          if (style == null) {
            if (name != null) stats.namesNotFound.add(name);
            continue;
          }
          if (!loadedFaces.has(faceKeyOf(style.fontName))) {
            stats.faceMissing += 1;
            continue;
          }
          // A style carries `textDecoration: NONE` as part of its bundle, and
          // applying one clears whatever the builder wrote — measured on a
          // real Button run, back when a variant row underlined its hover and
          // pressed labels: 36/36 of them came back `NONE` the moment their
          // style landed. That is the canvas's answer to the question this
          // used to leave open — restored, not left blind, because a
          // builder's decoration is a per-LABEL fact a shared style has no way
          // to carry (one style, many labels, only some of them underlined)
          // and the label is the more specific source. No builder draws a
          // decorated label today; `selftest:registry-runtime` holds this
          // path with a label it decorates itself, so the first builder that
          // does is not the one that finds out it is broken.
          const before = node.textDecoration;
          await node.setTextStyleIdAsync(style.id);
          node.setBoundVariable('fontSize', null);
          node.setBoundVariable('letterSpacing', null);
          node.setBoundVariable('fontFamily', null);
          stats.attached += 1;
          if (before !== 'NONE') {
            stats.decoratedBefore += 1;
            if (node.textDecoration !== before) {
              node.textDecoration = before;
              stats.decorationRestored += 1;
            }
          }
          if (hangul != null && hangul.isMonoRole(item.role)) {
            // Caught here rather than failing the entry: the style is on and
            // correct, and an unmeasured range write should cost the Hangul's
            // face, not the whole set's rebuild every run.
            try {
              stats.hangulRuns += paintHangulRunsSans(node, hangul.sans, { face: style.fontName.style });
            } catch (err) {
              stats.hangulFailed += 1;
              stats.hangulFirstError ??= String(err);
            }
          }
        } finally {
          const ms = Date.now() - startedAt;
          stats.ms += ms;
          stats.growth.add(ms);
          bill(startedAt);
        }
      }
    },
  };
}
