/// Geometric constants shared by Flutter (`CustomClipper`) and Web (SVG
/// `mask-image`) implementations of `CoreMaskShape`.
///
/// Having a single source of truth guarantees visual parity across platforms.
library;

/// Squircle corner radius as a fraction of the shorter side.
const kMaskSquircleRadiusFactor = 0.3;

/// Standard 5-point star inner/outer radius ratio.
const kMaskStarInnerRadiusFactor = 0.4;

/// Bolder star (star2) inner/outer ratio.
const kMaskStar2InnerRadiusFactor = 0.55;

/// Top dip vertical position as a fraction of the heart height.
const kMaskHeartTopFactor = 0.35;

/// Left heart lobe control-point x fraction.
const kMaskHeartLeftControlX = 0.15;

/// Right heart lobe control-point x fraction.
const kMaskHeartRightControlX = 0.85;

/// Heart side curve control-point y fraction.
const kMaskHeartCurveY = 0.4;

/// Hexagon side count.
const kMaskHexagonSides = 6;

/// Pentagon side count.
const kMaskPentagonSides = 5;

/// Decagon side count.
const kMaskDecagonSides = 10;

/// Normalized SVG viewBox edge (used by Web; Flutter scales to actual size).
const kMaskSvgViewBox = 100.0;
