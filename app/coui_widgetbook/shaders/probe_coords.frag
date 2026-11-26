// Reports the coordinate space an `ImageFilter.shader` program runs in:
// R = uSize.x / 2048, G = FlutterFragCoord().x / 2048, B = FlutterFragCoord().y / 2048.
// Read at a known pixel, that says whether the fragment coordinate is the
// filter input's pixel (origin at the filtered region) or something wider.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

const float kScale = 2048.0;

void main() {
  vec2 f = FlutterFragCoord().xy;
  fragColor = vec4(uSize.x / kScale, f.x / kScale, f.y / kScale, 1.0);
}
