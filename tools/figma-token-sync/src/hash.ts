// Deterministic string hashing for content-hash skip (#3739). Pure — no
// Figma API, no Node crypto (the plugin sandbox has neither). FNV-1a 32-bit,
// good enough for change-detection (not security).

export function fnv1a(input: string): string {
  let hash = 0x811c9dc5;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  // Unsigned, fixed-width hex so two hashes are always string-comparable.
  return (hash >>> 0).toString(16).padStart(8, '0');
}
