// The same half-texel shift as `probe_half_texel.frag`, but interpolated by
// hand from four nearest fetches — the workaround for an engine that binds
// the backdrop as nearest. If this one yields the intermediate colour and
// the plain sample does not, the workaround is what restores sub-pixel
// sampling.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

vec4 sampleBilinear(vec2 px) {
  vec2 p = px - 0.5;
  vec2 f = fract(p);
  vec2 p0 = floor(p);
  vec2 maxPx = max(vec2(0.0), uSize - 1.0);
  vec2 a = clamp(p0, vec2(0.0), maxPx);
  vec2 b = clamp(p0 + vec2(1.0, 0.0), vec2(0.0), maxPx);
  vec2 c = clamp(p0 + vec2(0.0, 1.0), vec2(0.0), maxPx);
  vec2 d = clamp(p0 + vec2(1.0, 1.0), vec2(0.0), maxPx);
  vec4 top = mix(texture(uTexture, (a + 0.5) / uSize),
                 texture(uTexture, (b + 0.5) / uSize), f.x);
  vec4 bottom = mix(texture(uTexture, (c + 0.5) / uSize),
                    texture(uTexture, (d + 0.5) / uSize), f.x);
  return mix(top, bottom, f.y);
}

void main() {
  fragColor = sampleBilinear(FlutterFragCoord().xy + vec2(0.5, 0.0));
}
