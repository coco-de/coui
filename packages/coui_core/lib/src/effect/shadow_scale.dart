/// Pure-Dart shadow layer record.
///
/// Layer 하나를 표현하는 데이터 구조입니다. Flutter `BoxShadow` 의존을 피하기
/// 위해 record 로 정의되며, `coui_flutter` 의 어댑터 extension 이 색상과 함께
/// `BoxShadow` 로 변환합니다.
typedef CoreShadowLayer = ({
  double offsetX,
  double offsetY,
  double blurRadius,
  double spreadRadius,
  double opacity,
  bool inset,
});

/// Shadow semantic tokens.
///
/// Spec: 9개 토큰 (`none`/`xs`/`sm`/`md`/`lg`/`xl`/`xl2`/`xl3`/`inset`).
/// `xs`/`sm` 는 2-layer(Sharp + Diffuse) — 표면에 붙어 있는 작은 들림이라
/// 가까운 가장자리와 먼 번짐을 둘 다 그린다. `md` 부터는 떠 있는 판(토스트 ·
/// 메뉴 · 대화상자)의 그림자라 한 겹이다: 판은 화면 위로 멀리 떠서 날카로운
/// 가장자리 그림자가 보이지 않는다. `inset` 만 안쪽 그림자.
///
/// 층의 `opacity` 는 Light 의 세기다. 같은 검정이 어두운
/// 면에서는 거의 보이지 않으므로, 테마가 Dark 면 알파에 [darkStrength] 를
/// 곱한다(최대 1) — 기하는 Light 와 같다. 그 곱셈은 토큰이 아니라 테마
/// 기하의 seat(`CoreSurfaceGeometryConstraint`) 가 한다.
///
/// Dart 식별자 제약으로 `2xl`→`xl2`, `3xl`→`xl3` 로 매핑됩니다 (spec 4.4 표기).
abstract final class CoreShadow {
  const CoreShadow._();

  /// No shadow.
  static const List<CoreShadowLayer> none = [];

  /// Subtlest lift — Input field, small button.
  static const List<CoreShadowLayer> xs = [
    (
      offsetX: 0,
      offsetY: 1,
      blurRadius: 2,
      spreadRadius: 0,
      opacity: 0.04,
      inset: false,
    ),
    (
      offsetX: 0,
      offsetY: 1,
      blurRadius: 1,
      spreadRadius: 0,
      opacity: 0.03,
      inset: false,
    ),
  ];

  /// Small shadow — Card default state.
  static const List<CoreShadowLayer> sm = [
    (
      offsetX: 0,
      offsetY: 2,
      blurRadius: 4,
      spreadRadius: -1,
      opacity: 0.05,
      inset: false,
    ),
    (
      offsetX: 0,
      offsetY: 1,
      blurRadius: 2,
      spreadRadius: 0,
      opacity: 0.03,
      inset: false,
    ),
  ];

  /// Medium shadow — Toast, Card hover.
  static const List<CoreShadowLayer> md = [
    (
      offsetX: 0,
      offsetY: 8,
      blurRadius: 24,
      spreadRadius: 0,
      opacity: 0.1,
      inset: false,
    ),
  ];

  /// Large shadow — Popup panel (menu · popover · select), Drawer, Command.
  static const List<CoreShadowLayer> lg = [
    (
      offsetX: 0,
      offsetY: 16,
      blurRadius: 40,
      spreadRadius: 0,
      opacity: 0.125,
      inset: false,
    ),
  ];

  /// Extra-large shadow — Modal, Dialog.
  static const List<CoreShadowLayer> xl = [
    (
      offsetX: 0,
      offsetY: 24,
      blurRadius: 64,
      spreadRadius: 0,
      opacity: 0.125,
      inset: false,
    ),
  ];

  /// 2X-large shadow (`shadow-2xl`) — full-screen overlay.
  static const List<CoreShadowLayer> xl2 = [
    (
      offsetX: 0,
      offsetY: 32,
      blurRadius: 80,
      spreadRadius: 0,
      opacity: 0.14,
      inset: false,
    ),
  ];

  /// 3X-large shadow (`shadow-3xl`) — dramatic depth.
  static const List<CoreShadowLayer> xl3 = [
    (
      offsetX: 0,
      offsetY: 40,
      blurRadius: 96,
      spreadRadius: 0,
      opacity: 0.15,
      inset: false,
    ),
  ];

  /// Inset shadow — pressed buttons, recessed inputs.
  static const List<CoreShadowLayer> inset = [
    (
      offsetX: 0,
      offsetY: 2,
      blurRadius: 4,
      spreadRadius: 0,
      opacity: 0.06,
      inset: true,
    ),
  ];

  /// How much stronger every shadow layer is on a dark theme: the layer's
  /// opacity times this, capped at 1.
  ///
  /// A shadow is darker than the face it falls on, and a dark face leaves a
  /// black shadow almost nothing to darken — the same alpha that reads as a
  /// lift on white disappears on a near-black panel. The geometry stays the
  /// Light geometry; only the alpha moves, so a component authors one stack
  /// and both brightnesses draw it.
  static const double darkStrength = 4;

  // === Scale Names (String for Web) ===

  /// CSS variable key record for compile-safe interpolation.
  ///
  /// Usage: `var(--shadow-${CoreShadow.scale.md})` → `var(--shadow-md)`.
  /// `xl2`/`xl3` 는 CSS 측에서는 `2xl`/`3xl` 로 매핑됩니다.
  static const ({
    String inset,
    String lg,
    String md,
    String none,
    String sm,
    String xl,
    String xl2,
    String xl3,
    String xs,
  })
  scale = (
    none: 'none',
    xs: 'xs',
    sm: 'sm',
    md: 'md',
    lg: 'lg',
    xl: 'xl',
    xl2: '2xl',
    xl3: '3xl',
    inset: 'inset',
  );
}
