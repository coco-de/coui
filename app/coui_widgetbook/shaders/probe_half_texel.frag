// Samples the backdrop half a texel to the right, through the sampler the
// engine bound. Over a hard vertical edge, a bilinear sampler returns a
// 50% mix on the column that straddles the edge; a nearest sampler snaps
// to one side and returns no intermediate colour at all. Which one the
// engine bound is the measurement.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy + vec2(0.5, 0.0)) / uSize;
  fragColor = texture(uTexture, uv);
}
