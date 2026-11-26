/// The ruler the refraction probes read pixels with.
///
/// Shared rather than copied because the runtime probe's floors are inherited
/// from the feasibility measurement's — the claim "the shipped runtime moves
/// as many pixels as the feasibility page did" is only a claim if both are
/// measured the same way. Two private copies could drift in the luminance
/// weights or the bucket width and the two numbers would stop being
/// comparable, silently and while both suites stayed green.
library;

import 'package:image/image.dart' as img;

/// Ratios. A displaced backdrop moves a large share of the panel; a control
/// that should do nothing is allowed only encoder-level noise.
const double kMovedRatioFloor = 0.02;

/// The most a capture pair that should be identical may differ by.
const double kUnchangedRatioCeiling = 0.005;

/// Distinct luminance buckets. A sharp-striped backdrop has very few; the same
/// backdrop under a 16px blur has many, which is how "the glass is drawn" is
/// decided without hardcoding a colour.
const int kBlurBucketFloor = 12;

/// How much luminance is collapsed before bucketing.
const int kLuminanceBucketShift = 3;

/// Rec. 709 luma coefficients, the weights a display gives each channel.
const double _kRedLuma = 0.213;
const double _kGreenLuma = 0.715;
const double _kBlueLuma = 0.072;

/// A one-step channel difference is below the capture path's noise floor,
/// so it is not counted as a difference.
///
/// 8비트 채널에서 1 LSB 차이는 렌더가 아니라 반올림 경계다. 굴절 프로브가
/// 재는 잔차는 서브픽셀(0.098px)이라, 어느 픽셀이 그 경계를 넘느냐가 화면이
/// 아니라 **래스터/캡처 경로**에 따라 갈린다 — 같은 커밋·같은 Chrome 에서
/// 브라우저가 여럿 경합하면 같은 장면이 1095 · 3455 · 5035 픽셀로 세어졌고,
/// 세 상태 모두 채널당 최대 차이가 정확히 1 이었다. 이것이 #4672 플레이크의
/// 정체다.
///
/// 임계 2 는 신호를 잃지 않는다 — 같은 장면에서 주입한 진짜 회귀(중성 맵에
/// 128 대신 0)는 임계 0 에서 0.9392, 임계 2 에서 0.9342 로 거의 그대로인
/// 반면 노이즈 세 상태는 전부 0.0000 으로 떨어졌다. 분리가 무한대라, 이
/// 상수를 올린 덕에 소비하는 쪽 천장을 **낮출 수** 있다.
const int kChannelNoiseFloor = 2;

/// Fraction of panel pixels whose colour differs between two captures.
double diffRatio(img.Image a, img.Image b) {
  if (a.width != b.width || a.height != b.height) return 1;

  var differing = 0;
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      if ((pa.r - pb.r).abs() >= kChannelNoiseFloor ||
          (pa.g - pb.g).abs() >= kChannelNoiseFloor ||
          (pa.b - pb.b).abs() >= kChannelNoiseFloor) {
        differing++;
      }
    }
  }

  return differing / (a.width * a.height);
}

/// How many coarse luminance buckets the region occupies.
///
/// A sharp black/white stripe pattern lands in two; the same pattern seen
/// through a blur lands in many. That difference is what "the glass is drawn"
/// is read from, without pinning a colour that a palette change would break.
int luminanceBuckets(img.Image image) {
  final seen = <int>{
    for (var y = 0; y < image.height; y++)
      for (var x = 0; x < image.width; x++) _bucketAt(image, x, y),
  };

  return seen.length;
}

int _bucketAt(img.Image image, int x, int y) {
  final pixel = image.getPixel(x, y);
  final luminance =
      (pixel.r * _kRedLuma + pixel.g * _kGreenLuma + pixel.b * _kBlueLuma)
          .round();

  return luminance >> kLuminanceBucketShift;
}
