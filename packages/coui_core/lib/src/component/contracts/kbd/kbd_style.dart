/// Per-instance style for `Kbd`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Kbd` should render.
///
/// `CoreKbdStyle` carries chrome / dimensional flat fields plus
/// nested text style slots. Behavioural fields (`keys`) stay flat on
/// the widget / contract (Epic #1302 원칙 6/7 — semantic input).
///
/// ```text
/// design system default (CoreKbdStyle.defaultX static const)
///   → CoreKbdTheme.style                             // 프로젝트 공통
///   → parent component slot override
///   → widget.kbdStyle                                // 인스턴스별
/// ```
@immutable
class CoreKbdStyle implements CoreStyle<CoreKbdStyle> {
  /// Creates a [CoreKbdStyle].
  const CoreKbdStyle({
    this.keyMinSize,
    this.keyPadding,
    this.keySeparatorSpacing,
    this.keyRadius,
    this.keyBackgroundColor,
    this.keyBorderColor,
    this.keyBorderWidth,
    this.keyShadow,
    this.keyTextStyle,
  });

  // ─── Design-system defaults (Phase 6f option D, Epic #1696 Phase 4) ─
  // Single source of truth shared by Flutter and Web — both platforms
  // resolve `CoreColor` via their own extension (`.toValue()` /
  // `scheme.resolve(...)`) and the typography token-backed reference
  // via the matching adapter (`tailwindTypographyRole` /
  // `resolveTypographyRole`).

  /// Default padding inside each key box — 6 across, 2 down. The label line
  /// is 15.4 (`labelXs` 11px × 1.4), so the cap is 2 + 15.4 + 2 = 19.4 tall
  /// once the border is out of the layout (see [defaultKeyBorderWidth]).
  static const CoreEdgeInsets defaultKeyPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space6,
    vertical: CoreSpace.space2,
  );

  /// Default minimum key-box square extent (18px) — a dimension, so it comes
  /// off the size scale rather than the spacing one. Narrow glyphs
  /// (`↑` / `↵`) would otherwise shrink the box to their intrinsic
  /// width, so the chips read as differently-sized squares across
  /// keys — and across platforms, whose fonts give the same glyph
  /// different advances. The cap is taller than 18 (19.4), so the floor
  /// only binds on width: a narrow glyph, and an icon key.
  static const double defaultKeyMinSize = CoreSize.size18;

  /// Default spacing (logical px) between adjacent key boxes. Used as
  /// `Row.spacing` (Flutter) / flex container `gap` (Web) — N-sibling 균등
  /// 분포 (Key, Key, Key) 패턴이라 raw double 슬롯. No glyph sits between the
  /// keys, so the gap alone keeps neighbouring key boxes — and any shadow
  /// stated on them — from touching.
  static const double defaultKeySeparatorSpacing = CoreSpace.space4;

  /// Default border radius of key boxes.
  static const CoreBorderRadius defaultKeyRadius = CoreBorderRadius.all(
    CoreRadius.radius4,
  );

  /// Default key background colour token.
  ///
  /// `surface`: the cap is the page's own face, told apart from it by the
  /// hairline edge ([defaultKeyBorderColor]) rather than by a darker fill —
  /// a fill-only cap needed the highest container step to stay visible, and
  /// read as a grey smudge in running text. The label colour
  /// (`onSurfaceVariant`) is audited against this tone with the other
  /// surface tones.
  static const CoreColor defaultKeyBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default key border colour — the subtle outline (`outlineSubtle`).
  ///
  /// The edge is what separates a `surface` cap from the surface it sits on,
  /// drawn at the hairline width below. It adds that width to the box on both
  /// platforms (a 30 × 19 cap becomes 31 × 20). The cap does not opt in to the
  /// cast a surface style contributes — a key cap is flat by design. Under a
  /// forced-colours mode the edge is a border, so it survives in the system
  /// colour along with the glyph.
  static const CoreColor defaultKeyBorderColor = CoreColor.token(
    CoreColors.outlineSubtle,
  );

  /// Default key border stroke width (hairline) — routed through the active
  /// surface style's geometry seat (`theme.geometry.stroke(...)` /
  /// the `--coui-stroke-width-0_5` variable on Web) so a preset's
  /// `strokeFloor` (e.g. neo-brutalism) reaches the key box.
  ///
  /// The width is drawn only while the border colour is visible: a fully
  /// transparent [keyBorderColor] collapses the width to 0 on both platforms,
  /// so a border that is not there does not take layout (a border adds its
  /// width to the box, even in a colour nobody can see). An app that wants the
  /// edge back states a visible colour — the width is already here.
  static const double defaultKeyBorderWidth = CoreStrokeWidth.stroke0_5;

  /// Default key shadow — none. A key cap states no shadow of its own, and a
  /// surface style does not contribute one either; a style or an app that
  /// wants one states the stack on [keyShadow] (it is drawn per key cap, never
  /// on the row that holds the keys, so a `Ctrl + C` sequence shows one shadow
  /// per key, and a surface style bends a stack stated there — blur / offset —
  /// instead of contributing its injected cast).
  static const List<CoreShadowLayer> defaultKeyShadow = CoreShadow.none;

  /// Default text style applied to each key label — token-backed
  /// reference to the `labelXs` role (11 / 500 / 1.4) in the sans family,
  /// with `onSurfaceVariant` colour. The role's own `medium` weight is the
  /// weight a key cap wants, so nothing is overlaid.
  ///
  /// Sans, not mono. The sans face covers the symbol keys — Pretendard's
  /// cmap carries ↑ ↵ ⏎ ⌘ ⌥ ⌃ ⇧ ⌫ ⎋ ⇥ — while the bundled Geist Mono has
  /// no ⌘ ⌥ ⌃ ⎋, so a mono cap would draw those from whatever face the
  /// platform falls back to, and the two platforms fall back to different
  /// faces. `Kbd.icon` is the way to pin a symbol's look on both platforms.
  static const CoreTextStyle defaultKeyTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelXs,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  // ── Chrome (flat) ────────────────────────────

  /// Padding inside each key box.
  final CoreEdgeInsets? keyPadding;

  /// Spacing (logical px) between adjacent key boxes — rendered as
  /// `Row.spacing` (Flutter) / flex container `gap` (Web). N-sibling 균등
  /// 분포 (Key, Key, Key) 패턴. See [defaultKeySeparatorSpacing].
  final double? keySeparatorSpacing;

  /// Minimum key-box square extent — see [defaultKeyMinSize].
  final double? keyMinSize;

  /// Border radius of key boxes.
  final CoreBorderRadius? keyRadius;

  /// Background colour of each key box.
  final CoreColor? keyBackgroundColor;

  /// Border colour of each key box.
  final CoreColor? keyBorderColor;

  /// Border stroke width of each key box — see [defaultKeyBorderWidth]. Drawn
  /// only while [keyBorderColor] is visible.
  final double? keyBorderWidth;

  /// Shadow of each key box — see [defaultKeyShadow]. An empty list draws
  /// no shadow.
  final List<CoreShadowLayer>? keyShadow;

  // ── Slot Styles (nested) ─────────────────────

  /// Text style applied to the key label characters.
  final CoreTextStyle? keyTextStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles are
  /// merged recursively.
  @override
  CoreKbdStyle merge(CoreKbdStyle? other) {
    if (other == null) return this;
    return CoreKbdStyle(
      keyMinSize: other.keyMinSize ?? keyMinSize,
      keyPadding: other.keyPadding ?? keyPadding,
      keySeparatorSpacing: other.keySeparatorSpacing ?? keySeparatorSpacing,
      keyRadius: other.keyRadius ?? keyRadius,
      keyBackgroundColor: other.keyBackgroundColor ?? keyBackgroundColor,
      keyBorderColor: other.keyBorderColor ?? keyBorderColor,
      keyBorderWidth: other.keyBorderWidth ?? keyBorderWidth,
      keyShadow: other.keyShadow ?? keyShadow,
      keyTextStyle: _mergeText(keyTextStyle, other.keyTextStyle),
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreKbdStyle copyWith({
    double? keyMinSize,
    CoreEdgeInsets? keyPadding,
    double? keySeparatorSpacing,
    CoreBorderRadius? keyRadius,
    CoreColor? keyBackgroundColor,
    CoreColor? keyBorderColor,
    double? keyBorderWidth,
    List<CoreShadowLayer>? keyShadow,
    CoreTextStyle? keyTextStyle,
  }) {
    return CoreKbdStyle(
      keyMinSize: keyMinSize ?? this.keyMinSize,
      keyPadding: keyPadding ?? this.keyPadding,
      keySeparatorSpacing: keySeparatorSpacing ?? this.keySeparatorSpacing,
      keyRadius: keyRadius ?? this.keyRadius,
      keyBackgroundColor: keyBackgroundColor ?? this.keyBackgroundColor,
      keyBorderColor: keyBorderColor ?? this.keyBorderColor,
      keyBorderWidth: keyBorderWidth ?? this.keyBorderWidth,
      keyShadow: keyShadow ?? this.keyShadow,
      keyTextStyle: keyTextStyle ?? this.keyTextStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreKbdStyle &&
          runtimeType == other.runtimeType &&
          keyMinSize == other.keyMinSize &&
          keyPadding == other.keyPadding &&
          keySeparatorSpacing == other.keySeparatorSpacing &&
          keyRadius == other.keyRadius &&
          keyBackgroundColor == other.keyBackgroundColor &&
          keyBorderColor == other.keyBorderColor &&
          keyBorderWidth == other.keyBorderWidth &&
          _listEq(keyShadow, other.keyShadow) &&
          keyTextStyle == other.keyTextStyle;

  @override
  int get hashCode => Object.hash(
    keyMinSize,
    keyPadding,
    keySeparatorSpacing,
    keyRadius,
    keyBackgroundColor,
    keyBorderColor,
    keyBorderWidth,
    keyShadow == null ? null : Object.hashAll(keyShadow!),
    keyTextStyle,
  );

  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
