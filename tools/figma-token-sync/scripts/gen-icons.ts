// Generates `src/data/icons.json` — the Lucide path data the builders draw
// with, extracted from the vendored Iconify set at build time.
//
// Why generate instead of importing the whole set: the vendored JSON is
// 1817 icons / ~560 KB, and a Figma plugin's `code.js` is a single bundled
// file the sandbox parses on every run. Only the icons some builder actually
// names are emitted (currently a few dozen), so the bundle grows by the size
// of what's used rather than the size of the catalog.
//
// Why the name list lives here and not next to each builder: the generator
// has to know the full set before it can emit, and a list assembled by
// scanning builder source would silently drop an icon the moment a call was
// written in a shape the scanner didn't match — an icon that resolves to
// `undefined` at runtime draws nothing, which reads as "that component has no
// icon" rather than as a build error. `ICON_NAMES` is checked against every
// `makeIcon(...)` literal by `check_figma_icon_names.sh`, so a name used but
// not listed fails before it can reach the canvas.
//
// Usage: npm run gen:icons   (writes src/data/icons.json)

// Minimal local ambients instead of `@types/node` — the same shape the three
// `selftest-*.ts` scripts already use. `typeRoots` is pinned to
// `@figma/plugin-typings` so the plugin's own code can't accidentally reach
// Node APIs, and adding a global Node types package would remove that.
declare const process: { cwd(): string; exit(code: number): never };
declare function require(id: string): unknown;

const { existsSync, readFileSync, writeFileSync } = require('node:fs') as {
  existsSync(p: string): boolean;
  readFileSync(p: string, enc: string): string;
  writeFileSync(p: string, data: string, enc: string): void;
};
const { resolve } = require('node:path') as {
  resolve(...parts: string[]): string;
};

// Resolved from the npm working directory (`tools/figma-token-sync`), not
// `__dirname` — esbuild bundles this to the package root, so `__dirname`
// points one level shallower than the source file's own location and a
// source-relative path silently escapes the repo.
const VENDOR = resolve(
  process.cwd(),
  '../../tool/parity/vendor/iconify/lucide-1.2.121.json',
);
const OUT = resolve(process.cwd(), 'src/data/icons.json');

if (!existsSync(VENDOR)) {
  console.error(
    `gen-icons: vendored icon set not found at ${VENDOR}\n` +
      '           run this via `npm run gen:icons` from tools/figma-token-sync.',
  );
  process.exit(1);
}

// Every icon a builder draws, with the component that grounds the choice.
// "Grounded" means the widget source for that component actually renders that
// `LucideIcons.<name>` — not that the shape looked close to the old text
// glyph. Ungrounded picks are marked, because they are the ones that can be
// wrong without anything failing.
const ICON_NAMES = [
  'lock', // MockupBrowser address
  'rotate-cw', // MockupBrowser reload
  'share', // MockupBrowser actions
  // ── grounded in widget source ──
  'x', //              toast · sortable · filter · chip · alert · banner
  'check', //          checkbox · select · item-picker · steps · validation-badge
  'chevron-down', //   accordion · collapsible · select · phone-input
  'chevron-right', //  breadcrumb · tree · pagination
  'chevron-left', //   pagination
  'arrow-left', //     calendar · command (fullscreen back)
  'arrow-right', //    calendar
  'grip-vertical', //  sortable handle
  'search', //         command · navigation-bar
  'house', //          navigation-bar
  'heart', //          navigation-bar
  'upload', //         file-input
  'file', //           file-input · tree (leaf node)
  'credit-card', //    description-card (title leading default glyph)
  'folder', //         tree (parent node) — tree.dart:170, web tree.dart:184
  'folder-open', //    tree-item (expanded parent) — `isExpanded ? folderOpen
  //                   : folderClosed` in both tree.dart files
  'folder-closed', //  tree-item (collapsed parent) — same branch
  'copy', //           code-snippet copy button at rest — `_copied ? check : copy`
  'calendar', //       date-picker
  'clock', //          time-picker
  'inbox', //          empty-state
  'info', //           alert · banner · validator-hint
  'triangle-alert', // alert · banner · validator-hint
  'circle-check', //   alert · banner · step-item (done)
  'circle-x', //       alert · banner · step-item (failed)
  'circle', //         step-item (todo)
  'circle-dot', //     step-item (current)
  'circle-alert', //   validator-hint
  'circle-check-big', // validator-hint
  'circle-dashed', //  validator-hint (neutral — the not-yet of a checklist,
  //                   drawn as the unfilled twin of `circle-check-big`)
  'bell', //           banner
  'dot', //            validation-badge
  'star', //           star-rating
  'mail', //           label
  'arrow-down', //     refresh-trigger · command footer
  'arrow-up', //       command footer
  'corner-down-left', // command footer (Enter)
  'tag', //            chip leading (demo slot the widget leaves to the caller)
  'pipette', //        color-picker eyedropper — the ONLY `Icon(` in that widget
  // ── not grounded: the component renders no icon in code, so these are the
  //    plugin's own choice for a slot that exists visually. Wrong-but-silent
  //    is the risk here; a code-side `Icon(...)` would settle each one.
  'plus', //           fab trigger — fab.dart's own doc example
  'minus', //          number input — the decrease step button
  'bold', //           rich editor toolbar — LucideIcons.bold
  'italic', //         rich editor toolbar — LucideIcons.italic
  'strikethrough', //  rich editor toolbar — LucideIcons.strikethrough
  'code', //           rich editor toolbar — LucideIcons.code
  'link', //           rich editor toolbar — LucideIcons.link
  'link-2', //         Link leading slot sample — LucideIcons.link2
  'list', //           rich editor toolbar — LucideIcons.list
  'list-ordered', //   rich editor toolbar — LucideIcons.listOrdered
  'list-todo', //      rich editor toolbar — LucideIcons.listTodo
  'quote', //          rich editor toolbar — LucideIcons.quote
  'menu', //           navigation-bar "More"
  'ellipsis', //       basic-card overflow affordance
  'smile', //          command palette demo row — the widget's doc example
  'calculator', //     command palette demo row — the widget's doc example
  'user', //           command palette demo row — the widget's doc example
  'image', //          hover-gallery placeholder · fab example row
  // ── stated by the redesign spec: the Fab speed-dial's example rows. The
  //    widget takes any `FabAction.icon`, so none of these is grounded in code.
  'calendar-plus', //  fab example row · add an event
  'paperclip', //      fab example row · attach a file
  'pencil', //         fab example row · write
  // Sidebar sample — the destinations of the designer's scaffold (#5738). The
  //    rows take any `SidebarItem.leading`, so none of these is grounded in code.
  'layout-dashboard', // sidebar sample · dashboard
  'kanban', //           sidebar sample · board
  'chart-column', //     sidebar rail sample · reports
  'users', //            sidebar sample · members
  'settings', //         sidebar sample · settings group
  'life-buoy', //        sidebar sample · help
  'external-link', //    sidebar sample · help opens elsewhere
  'terminal', //         sidebar sample · workspace mark
  'chevrons-up-down', // sidebar sample · workspace / user switcher
];

interface IconifySet {
  icons: Record<string, { body: string; width?: number; height?: number }>;
  aliases?: Record<string, { parent: string }>;
  width?: number;
  height?: number;
}

const set = JSON.parse(readFileSync(VENDOR, 'utf8')) as IconifySet;
const boxW = set.width ?? 24;
const boxH = set.height ?? 24;

const out: Record<string, { body: string; w: number; h: number }> = {};
const missing: string[] = [];
for (const name of [...ICON_NAMES].sort()) {
  // An alias resolves to its parent's body — Lucide renames icons across
  // releases and keeps the old name as an alias, so a name that only exists
  // as an alias is still a legitimate request.
  const direct = set.icons[name];
  const alias = set.aliases?.[name];
  const icon = direct ?? (alias ? set.icons[alias.parent] : undefined);
  if (!icon) {
    missing.push(name);
    continue;
  }
  out[name] = {
    body: icon.body,
    w: icon.width ?? boxW,
    h: icon.height ?? boxH,
  };
}

if (missing.length) {
  console.error(
    `gen-icons: ${missing.length} name(s) not in the vendored set: ` +
      missing.join(', '),
  );
  process.exit(1);
}

writeFileSync(OUT, `${JSON.stringify(out, null, 2)}\n`, 'utf8');
console.log(
  `gen-icons: ${Object.keys(out).length} icon(s) → src/data/icons.json ` +
    `(${(JSON.stringify(out).length / 1024).toFixed(1)} KB inlined)`,
);
