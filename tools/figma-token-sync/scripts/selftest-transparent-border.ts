import { reserveTransparentBorder, type TransparentBorderNode } from '../src/transparent-border-reservation';

function equal(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const node: TransparentBorderNode = {
  strokes: [],
  strokeWeight: 0,
  strokeAlign: 'CENTER',
  strokesIncludedInLayout: false,
};
const clear = { color: null, argb: 0x00123456, opacity: 1 };
const opaque = { color: null, argb: 0xff123456, opacity: 1 };

equal(reserveTransparentBorder(node, clear, 1, false), 0);
equal(node.strokes, []);
equal(node.strokesIncludedInLayout, false);
equal(reserveTransparentBorder(node, clear, 1, true), 1);
equal(node.strokeWeight, 1);
equal(node.strokeAlign, 'INSIDE');
equal(node.strokesIncludedInLayout, true);
equal((node.strokes as readonly SolidPaint[])[0].opacity, 0);
equal(reserveTransparentBorder(node, clear, 1, false), 0);
equal(node.strokes, []);
equal(node.strokesIncludedInLayout, false);
equal(reserveTransparentBorder(node, opaque, 2, true), 2);
equal(node.strokesIncludedInLayout, true);
equal(reserveTransparentBorder(node, { color: 'outline', opacity: 0 }, 2, true), 2);
equal(node.strokesIncludedInLayout, true);
equal(reserveTransparentBorder(node, clear, 1, true, 'none'), 0);
equal(node.strokesIncludedInLayout, false);
for (const style of ['solid', 'dashed', 'dotted']) {
  equal(reserveTransparentBorder(node, clear, 2, false, style), 0);
  equal(node.strokesIncludedInLayout, false);
  equal(reserveTransparentBorder(node, clear, 2, true, style), 2);
  equal(node.strokesIncludedInLayout, true);
  equal(reserveTransparentBorder(node, opaque, 2, true, style), 2);
  equal(node.strokesIncludedInLayout, true);
}
equal(reserveTransparentBorder(node, opaque, 2, true, 'none'), 0);
equal(node.strokesIncludedInLayout, false);
equal(reserveTransparentBorder(node, clear, 0, true), 0);
equal(node.strokesIncludedInLayout, false);
console.log('transparent border: default, opt-in, reset, opaque, token alpha, zero width passed');
