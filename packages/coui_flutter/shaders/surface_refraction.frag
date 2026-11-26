// Edge refraction for a glass surface: bends what shows through, near the
// rim, and leaves the interior optically flat.
//
// ## This file is a mirror, not a design
//
// Every line of the optics below is `CoreSurfaceRefraction.displacementAt`
// written out in GLSL, because this runs on the GPU and cannot call Dart.
// That duplication is the risk this whole file is organised around — the two
// platforms once owned separate copies and disagreed on the direction, the
// falloff *and* the magnitude at the same time, with nothing in either suite
// able to notice. `surface_refraction_parity_test.dart` evaluates the two
// against the same inputs; change anything here and change it there.
//
// The two leading uniform declarations are load-bearing. `ImageFilter.shader`
// rejects a program whose declared floats number fewer than two, or that
// declares no sampler — it reads what the *program declares*, so satisfying
// it by calling `setFloat` twice is not possible.
//
// ## The texture is the backdrop, not the surface
//
// `uSize` and `FlutterFragCoord()` describe the *backdrop snapshot* — the
// whole render target the filter reads, which on screen is the window —
// not the surface the filter is attached to. Measured on Impeller with a
// program that reported them as colour: a 200×100 panel inside a 240×140
// capture at 2× saw `uSize ≈ 482` and fragment coordinates in the capture's
// pixels — composed with the blur or bare, clipped or not, under an
// `Opacity` or not (`refraction_sampling_probe_test.dart` and its
// siblings). The first version of this file took them for the surface's
// rectangle and bent the *window's* edges: a glass panel anywhere but at the
// screen's rim stayed optically flat, and the bend people did see on
// edge-hugging panels was the window's band showing through them. The
// surface's own rectangle therefore arrives as two more uniforms, in the
// same pixels.
#include <flutter/runtime_effect.glsl>

// First uniform, a vec2: the engine writes the bound texture's size here.
uniform vec2 uSize;

// How much of the shorter side the bending occupies.
uniform float uBezel;

// Corner radius in the texture's pixels, so the band follows the shape's
// actual corners rather than its bounding box. Without it the two platforms
// disagree at exactly the place a rounded pane is most obviously round.
//
// Texture pixels are the device's — `uSize` and `FlutterFragCoord()` arrive
// physical (measured, P1) — so the caller scales its logical radius by the
// device pixel ratio, as it does the rectangle below. The Web map's raster
// is the CSS pixel and never had this seam.
uniform float uRadius;

// The dial, 0..1 — how much of the described bend is applied.
uniform float uStrength;

// Index of refraction. Sets the angle; the dial above sets the distance.
uniform float uRefractiveIndex;

// Channel separation as a fraction of the shared bend. Zero draws one sample.
uniform float uDispersion;

// The surface's rectangle inside the texture, in texture pixels: where it
// starts and how big it is. Everything geometric below — the band, the
// corner, the inset — is measured against this rectangle, never against
// `uSize`. The caller derives it from the surface's transform to the root
// each time the scene is built, so it follows a scroll without a repaint.
uniform vec2 uOrigin;
uniform vec2 uExtent;

// `CoreSurfaceRefraction.lens`: how much the whole face magnifies what
// shows through it. Declared after the rectangle so its indices did not move
// when it arrived.
uniform float uLens;

// `CoreSurfaceRefraction.model`, as the index of the `CoreRefractionModel`:
// 0 is `snell` (the law the band has always been drawn with), 1 is
// `paraxial`. Declared last so every index above it stayed where it was.
uniform float uRefractionModel;

// `CoreSurfaceBodyShade.strength` for the palette the surface draws in: how
// much of itself a white pixel loses, 0..1. Zero draws nothing, and a program
// mounted only for the shade (a surface that bends nothing) is handed zero for
// every uniform above this one. Declared last so every index above it stayed
// where it was.
uniform float uBodyShade;

// At least one sampler2D: the engine binds the filter input to the first.
uniform sampler2D uTexture;

out vec4 fragColor;

// `CoreSurfaceRefraction.travelPerBand`.
const float kTravelPerBand = 5.0;

// `CoreSurfaceRefraction.dispersionUnit`: how far apart the outer channels
// sit at full dispersion. The Web filter scales its passes by the same
// number; before it was shared the shader fringed twice as far.
const float kDispersionUnit = 0.5;

// `CoreSurfaceBodyShade.shade`, line for line: every pixel multiplied by
// `1 - strength * luma^2`, with the luminance weights of
// `CoreSurfaceBodyShade.lumaRed` / `lumaGreen` / `lumaBlue`.
//
// A point operation: it reads nothing but the pixel it is shading, so it needs
// no geometry, commutes with the bend (applied to each sample, below), and is
// right in whatever pass the engine hands this program. The Web filter does
// the same with a luminance matrix, a gamma transfer and a multiply.
//
// The texture is premultiplied, and the luminance is the straight colour's —
// an opaque backdrop (the only kind a page has behind a surface) makes the two
// the same, and a translucent one is shaded by what it looks like rather than
// by how little of it there is.
vec4 bodyShaded(vec4 colour) {
  if (uBodyShade <= 0.0 || colour.a <= 0.0) return colour;

  vec3 straight = colour.rgb / colour.a;
  float luma = dot(straight, vec3(0.213, 0.715, 0.072));

  return vec4(colour.rgb * (1.0 - uBodyShade * luma * luma), colour.a);
}

// Signed distance to the rounded rectangle: negative inside, zero on the
// edge. The same rounded-rect field the Web map bakes.
float roundedRectDistance(vec2 p, vec2 half_, float radius) {
  vec2 q = abs(p) - half_ + radius;

  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

// The outward unit normal, as the gradient of that field.
vec2 roundedRectNormal(vec2 p, vec2 half_, float radius) {
  vec2 e = vec2(1.0, 0.0);
  vec2 g = vec2(
    roundedRectDistance(p + e.xy, half_, radius)
        - roundedRectDistance(p - e.xy, half_, radius),
    roundedRectDistance(p + e.yx, half_, radius)
        - roundedRectDistance(p - e.yx, half_, radius));
  float len = length(g);

  return len == 0.0 ? vec2(0.0) : g / len;
}

// `CoreSurfaceRefraction.displacementAt`, line for line.
//
// The surface faces the viewer in the flat interior and tilts over as it
// nears the rim, so the 2D normal is lifted into 3D with the band as its
// ramp — a quarter circle rather than a straight one, because a real bevel
// is round. A ray coming straight at the screen is bent against that normal
// by Snell's law, and the sample moves by the screen-space part of where it
// went. `zone` fades the travel out at the band's inner boundary so the
// interior stays optically flat instead of uniformly shifted.
float displacementAt(float insetPx, float bandPx) {
  if (bandPx <= 0.0) return 0.0;

  float h = clamp(insetPx / bandPx, 0.0, 1.0);
  float bulge = sqrt(max(0.0, 1.0 - h * h));
  float normalLength = sqrt(bulge * bulge + h * h);
  if (normalLength == 0.0) return 0.0;

  float nx = bulge / normalLength;
  float nz = h / normalLength;

  float eta = 1.0 / max(uRefractiveIndex, 1.0);
  float k = 1.0 - eta * eta * (1.0 - nz * nz);
  if (k < 0.0) return 0.0;

  float tangential = -eta * nx;
  float zone = 1.0 - clamp(insetPx / bandPx, 0.0, 1.0);

  return tangential * bandPx * uStrength * kTravelPerBand * zone;
}

// `CoreSurfaceRefraction._paraxialDisplacementAt`, line for line: the
// thin-prism law. The same bevel as above — its lateral normal share at a
// point `h` of the way in is sqrt(1 - h*h) — but the deviation is
// (index - 1) times the slope, and the slope is that share squared, so the
// travel is a parabola in the inset that reaches zero at the band's inner
// boundary on its own. No fade, no total-internal-reflection guard: the law
// has neither. An index of 1 bends nothing.
float paraxialDisplacementAt(float insetPx, float bandPx) {
  if (bandPx <= 0.0) return 0.0;

  float h = clamp(insetPx / bandPx, 0.0, 1.0);
  float slope = 1.0 - h * h;
  float deviation = max(uRefractiveIndex, 1.0) - 1.0;

  return -deviation * slope * bandPx * uStrength * kTravelPerBand;
}

// The rim's travel under the law the request states. `displacementAt` is
// the snell law and is left exactly as it was, so a request that states no
// law is bent by the same lines it always was.
float rimDisplacement(float insetPx, float bandPx) {
  return uRefractionModel > 0.5
      ? paraxialDisplacementAt(insetPx, bandPx)
      : displacementAt(insetPx, bandPx);
}

// `CoreSurfaceRefraction.lensDisplacement`, per axis: the face is a
// shallow dome, so a sample moves toward the centre by a fixed fraction of
// its distance from it — a uniform magnification of what shows through,
// with no seam, because it never asks which edge is nearest.
vec2 lensTravel(vec2 centred) {
  return -uLens * centred;
}

// Where a fragment finally reads from: the rim's bend first, then the lens
// evaluated at the bent position. That order is the Web filter's — its lens
// stage runs on the source and the rim passes read from the lensed result,
// so a rim-shifted sample lands in the lensed image at its shifted place.
vec2 readAt(vec2 shifted, vec2 half_) {
  vec2 lensed = shifted + lensTravel(shifted - uOrigin - half_);

  return clamp(lensed / uSize, 0.0, 1.0);
}

// Backdrop reads go straight through the bound sampler — a parity
// decision, not an oversight.
//
// The engine binds this program's input as nearest-neighbour (Flutter
// #188365; the `filterQuality` argument that closed it is newer than the
// SDK this kit pins and defaults to nearest even where it exists), so a
// displaced read snaps to whole texels. A four-fetch interpolation was
// tried here and measured on Impeller: it lifted the blue channel's
// in-between share inside the band from 0.000 to 0.273
// (`refraction_sampling_probe_test.dart`, P3). Then the Web renderer was
// measured the same way — `feDisplacementMap` inside `backdrop-filter`
// snaps too, and offers no primitive that does not
// (`tool/parity/test/web/backdrop_sampling_probe_test.dart`). Smoothing
// one platform would have made the two bends disagree at the pixel level
// where they agreed before, so the plain read stays. The two move together
// or not at all.
void main() {
  vec2 fragPx = FlutterFragCoord().xy;
  vec2 half_ = uExtent * 0.5;
  vec2 centred = fragPx - uOrigin - half_;

  float shorter = min(uExtent.x, uExtent.y);
  float band = uBezel * shorter;
  float radius = clamp(uRadius, 0.0, min(half_.x, half_.y));

  // Outside the shape counts as the edge itself. A negative inset would run
  // the ramp backwards in the slivers a rounded corner leaves in the box.
  float inset = max(0.0, -roundedRectDistance(centred, half_, radius));
  vec2 normal = roundedRectNormal(centred, half_, radius);
  vec2 travel = normal * rimDisplacement(inset, band);

  vec2 uv = readAt(fragPx + travel, half_);

  // One exit. This program samples a texture, and the shader compiler of
  // Flutter 3.50 warns about such a program having more than one `return` in
  // `main()`; a package that made the same change reports HLSL compile
  // failures for that shape on Windows Direct3D and Chrome ANGLE (not
  // reproduced here; flutter/flutter#190809 is a crash in that compiler whose
  // shader was never identified). So the middle sample is
  // read unconditionally — it is the whole answer when nothing disperses — the
  // dispersion below only replaces the two outer channels, and `fragColor` is
  // written once, at the end. `check_shader_single_exit.sh` pins the shape.
  //
  // Each sample is shaded before the channel is taken from it. The Web
  // filter shades the backdrop and only then displaces it, so the channels
  // it takes are already shaded by the luminance of the pixel they came from;
  // shading the finished composite would use the luminance of a colour no
  // pixel had, and the two would part wherever the rim fringes.
  vec4 middle = bodyShaded(texture(uTexture, uv));
  vec4 colour = middle;

  if (uDispersion > 0.0) {
    // Short wavelengths bend further, so blue travels most and red least —
    // the same three scales the Web filter runs its three passes at. Only the
    // rim's travel spreads; the lens is one image on both platforms.
    float spread = kDispersionUnit * uDispersion;
    vec2 red = readAt(fragPx + travel * (1.0 + spread), half_);
    vec2 blue = readAt(fragPx + travel * (1.0 - spread), half_);

    // Alpha from the middle sample alone. Averaging three would soften the
    // surface's own edge, which is the band's job to state, not this one's.
    colour = vec4(
      bodyShaded(texture(uTexture, red)).r,
      middle.g,
      bodyShaded(texture(uTexture, blue)).b,
      middle.a);
  }

  fragColor = colour;
}
