// Deliberately invalid input for the Tier 2 refraction feasibility probe.
//
// This declares the leading vec2 and no sampler, so `ImageFilter.shader` must
// reject it with a StateError. It ships rather than being injected and
// reverted by hand because a one-time inject-fail-revert proves the check was
// live once; a shipped counter-example proves it on every run.
//
// Without it, "no throw" from the sibling probe would be ambiguous between
// "the platform accepted a real shader" and "the SDK validated nothing".
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;

out vec4 fragColor;

void main() {
  // Reads uSize so the uniform survives any dead-code elimination that would
  // otherwise leave the program declaring fewer than two floats — which would
  // trip the *other* half of the same check and make the StateError stop
  // meaning "missing sampler".
  fragColor = vec4(uSize.x, uSize.y, 0.0, 1.0);
}
