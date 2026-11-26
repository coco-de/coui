/// Minimal surface used by the Figma builder and by its regression test.
export interface TransparentBorderNode {
  strokes: readonly Paint[] | PluginAPI['mixed'];
  strokeWeight: number | PluginAPI['mixed'];
  strokeAlign: 'INSIDE' | 'OUTSIDE' | 'CENTER';
  strokesIncludedInLayout: boolean;
}

interface BorderColor {
  color?: string | null;
  argb?: number | null;
  opacity?: number | null;
}

/// Reserve the same transparent stroke inset that the two renderers use.
/// Return the effective inset so nested content uses the same corner geometry.
export function reserveTransparentBorder(
  node: TransparentBorderNode,
  color: BorderColor | null,
  width: number,
  preserve: boolean,
  borderStyle: string = 'solid',
): number {
  const transparent = color != null && (
    color.opacity === 0 ||
    (color.color == null && color.argb != null && (color.argb >>> 24) === 0)
  );
  // Explicitly reset on regeneration: a previously preserved instance may
  // have been switched back to the default collapse behaviour.
  node.strokesIncludedInLayout = false;
  if (borderStyle === 'none') {
    node.strokes = [];
    return 0;
  }
  if (!transparent) {
    if (preserve && width > 0) {
      node.strokeAlign = 'INSIDE';
      node.strokesIncludedInLayout = true;
    }
    return width;
  }
  if (!preserve || width === 0) {
    node.strokes = [];
    return 0;
  }
  // Figma normally removes transparent paints. An invisible stroke with
  // layout inclusion reserves the inset without drawing a visible line.
  node.strokes = [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 }, opacity: 0 }];
  node.strokeAlign = 'INSIDE';
  node.strokeWeight = width;
  node.strokesIncludedInLayout = true;
  return width;
}
