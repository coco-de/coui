// Minimal displacement shader for the Tier 2 refraction feasibility probe
// (R — 굴절 타당성 측정). Not a component asset: nothing in the kit renders
// this, and it exists so `ImageFilter.shader` has something valid to accept.
//
// The two uniform declarations are load-bearing. `ImageFilter.shader` rejects
// a program whose declared floats number fewer than two, or that declares no
// sampler at all — it reads what the *program* declares, so satisfying it by
// calling `setFloat` twice is not possible.
#include <flutter/runtime_effect.glsl>

// First uniform, a vec2: the engine writes the bound texture's size here.
uniform vec2 uSize;

// At least one sampler2D: the engine binds the filter input to the first.
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // Mirror across x. Displacing on x alone sidesteps the GLES y-flip the SDK
  // doc warns about, and mirroring needs no clamp reasoning — every sampled
  // coordinate stays in range. The measurement only asks whether the backdrop
  // moves at all, so the cheapest unambiguous displacement is the right one.
  fragColor = texture(uTexture, vec2(1.0 - uv.x, uv.y));
}
