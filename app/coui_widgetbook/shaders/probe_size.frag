// Reports the size the engine hands an `ImageFilter.shader` program — the
// unit question. `FlutterFragCoord()` and `uSize` are in the same space, but
// nothing says whether that space is logical or physical pixels, and the
// shipped refraction shader receives its corner radius in logical pixels.
// If the texture is physical, the corner it bends around is the true one
// divided by the device pixel ratio. Measured, not assumed — see
// `refraction_sampling_probe_test.dart`.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform sampler2D uTexture;

out vec4 fragColor;

// 8-bit channels, so the size lands in steps of `kSizeScale / 255` pixels.
// Coarse, but the question is a factor of two or three, not a pixel.
const float kSizeScale = 2048.0;

void main() {
  fragColor = vec4(uSize.x / kSizeScale, uSize.y / kSizeScale, 0.0, 1.0);
}
