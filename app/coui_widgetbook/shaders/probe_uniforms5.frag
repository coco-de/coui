// Same declaration shape as the shipped refraction shader — a vec2, five
// floats, a sampler — reporting three of the five as colour so the slot
// mapping is checked at the exact layout the shipped program uses.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uA;
uniform float uB;
uniform float uC;
uniform float uD;
uniform float uE;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  fragColor = vec4(uB, uC, uD, 1.0);
}
