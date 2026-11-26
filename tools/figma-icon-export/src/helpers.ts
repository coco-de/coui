/// <reference types="@figma/plugin-typings" />

export function hexToRgb(hex: string): RGB {
  const clean = hex.trim().replace(/^#/, '');
  const full =
    clean.length === 3
      ? clean
          .split('')
          .map((c) => c + c)
          .join('')
      : clean;
  const n = parseInt(full, 16);
  if (full.length !== 6 || isNaN(n)) {
    throw new Error(`Invalid hex color: "${hex}" (expected e.g. #0A56DB)`);
  }
  return {
    r: ((n >> 16) & 255) / 255,
    g: ((n >> 8) & 255) / 255,
    b: (n & 255) / 255,
  };
}

export async function loadFonts(): Promise<void> {
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
}

/** Finds the single selected COMPONENT to use as the logo master. Throws a
 *  user-facing message (shown in the plugin log) if the selection is invalid —
 *  this plugin never guesses which node is "the logo". */
export function requireSelectedLogoComponent(): ComponentNode {
  const sel = figma.currentPage.selection;
  if (sel.length !== 1) {
    throw new Error(
      `Select exactly one component to use as the logo (found ${sel.length}). ` +
        'Select the master component itself (not an instance).',
    );
  }
  const node = sel[0];
  if (node.type !== 'COMPONENT') {
    throw new Error(
      `Selected node "${node.name}" is a ${node.type}, not a COMPONENT. ` +
        'Right-click your logo group → "Create component", select that, then retry.',
    );
  }
  return node;
}
