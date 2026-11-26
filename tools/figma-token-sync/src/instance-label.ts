/// <reference types="@figma/plugin-typings" />

// Shared drawing operations: dependencies point here, never through a registry builder.

// Rewrites a child instance's label. `setProperties` when the child set exposes
// a TEXT property — that property is the child builder's to declare, so this
// reads what is there instead of assuming a name — else the first TEXT
// descendant's `characters`, which is the same override a designer's
// double-click produces.
export function setInstanceLabel(inst: InstanceNode, text: string): void {
  const props = inst.componentProperties;
  if (props) {
    for (const key of Object.keys(props)) {
      if (props[key].type !== 'TEXT') continue;
      const patch: Record<string, string> = {};
      patch[key] = text;
      inst.setProperties(patch);
      return;
    }
  }
  for (const node of inst.findAll((n) => n.type === 'TEXT')) {
    if (node.type !== 'TEXT') continue;
    node.characters = text;
    return;
  }
}
