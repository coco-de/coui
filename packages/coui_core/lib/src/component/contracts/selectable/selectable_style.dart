/// Per-instance style for `SelectableText`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/focus_ring.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `SelectableText` should render.
///
/// `CoreSelectableTextStyle` carries the text-style slot plus caret
/// chrome (width / height / radius / colour). Behavioural fields
/// (`maxLines`, `textAlign`, `autofocus`, …) stay flat on the widget.
///
/// Variant-independent design-system defaults live as `static const`
/// on this class (Epic #1415 Phase 6f + #1696 Phase 6) — Flutter and
/// Web reference the same `CoreSelectableTextStyle.defaultX` so the
/// two platforms cannot silently diverge. The selectable text has no
/// size or variant axis, so there is no `defaultsBySize` /
/// `defaultsByVariant` map.
///
/// ```text
/// design system default (CoreSelectableTextStyle.defaultX)
///   → CoreSelectableTextTheme.style                  // 프로젝트 공통
///   → widget.selectableTextStyle                     // 인스턴스별
/// ```
///
/// Flutter paints the caret; Web emits its colour as `caret-color` and
/// exposes its geometry as custom properties for the browser-native caret.
@immutable
class CoreSelectableTextStyle implements CoreStyle<CoreSelectableTextStyle> {
  /// Creates a [CoreSelectableTextStyle].
  const CoreSelectableTextStyle({
    this.textStyle,
    this.cursorColor,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.selectionColor,
  });

  // ── Design-system defaults (Epic #1415 Phase 6f + #1696 Phase 6) ──
  //
  // Variant-independent defaults — single source of truth shared by
  // both selectable-text resolvers. Web emits the caret colour and exposes
  // geometry as custom properties for the browser-native caret.

  /// Default text-caret width (logical px). Matches the focus-ring
  /// width so the caret stays visually consistent with other
  /// interactive surfaces.
  /// Default typography of the selectable text — the platform ambient
  /// (`bodyMedium` + `onSurface`). Web inherits the same pair from the
  /// application root; Flutter has no automatic ambient text style, so
  /// without this single source it fell back to the framework default
  /// (14px) and rendered smaller than the Web twin (16px).
  static const CoreTextStyle defaultTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodyMedium,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default caret stroke width.
  static const double defaultCursorWidth = CoreFocusRing.ringWidth;

  /// Default caret colour — the same primary token as an input cursor.
  /// Both resolvers use it when neither the theme nor the caller overrides it.
  static const CoreColor defaultCursorColor = CoreColor.token(
    CoreColors.primary,
  );

  /// Default text-selection tint base colour (`primaryContainer`) — the
  /// soft container tone, so the band sits behind the text without a
  /// strong chroma and the `onSurface` text stays the colour it already is.
  /// Both resolvers paint it as stated, with no alpha of their own — the
  /// highlight sits behind the text, so an opaque container tone reads
  /// without one. Flutter hands it to `DefaultSelectionStyle`, Web emits it
  /// as a `selection:bg-*` Tailwind pseudo-element class (`::selection`).
  /// Without it, `m.SelectableText` falls back to the ambient
  /// `DefaultSelectionStyle` — i.e. the Material theme's selection
  /// colour — which clashes with the CoUI scheme.
  static const CoreColor defaultSelectionColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  // ── Slot Styles (nested) ─────────────────────

  /// Text style applied to the selectable text content.
  final CoreTextStyle? textStyle;

  // ── Caret chrome ────────────────────────────

  /// Caret colour override. `null` → [defaultCursorColor].
  final CoreColor? cursorColor;

  /// Caret width in logical pixels. `null` → token default.
  final double? cursorWidth;

  /// Caret height in logical pixels. `null` → auto (line height).
  ///
  /// **No `defaultCursorHeight`, deliberately.** "Auto" is not a number:
  /// the Flutter resolver keeps null so the framework sizes the caret to
  /// the line height, and Web emits the `--coui-caret-height` custom
  /// property only inside `if (cursorHeight != null)`. A constant would
  /// freeze the caret at a fixed px on both platforms — it would stop
  /// growing with the font size, which is the one thing a caret must do.
  final double? cursorHeight;

  /// Caret corner radius.
  ///
  /// **No `defaultCursorRadius`, deliberately.** A square caret is the
  /// design: Flutter converts to a `Radius` only when the merged value
  /// is non-null and otherwise passes null, and Web emits the
  /// `--coui-caret-radius` custom property only inside
  /// `if (cursorRadius != null)`. A constant rounds every caret in the
  /// kit.
  final CoreBorderRadius? cursorRadius;

  /// Text-selection tint colour override — Flutter paints it via
  /// `EditableText.selectionColor`, Web via a `selection:bg-*` Tailwind
  /// pseudo-element class (`::selection`). `null` → [defaultSelectionColor].
  final CoreColor? selectionColor;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The nested [textStyle] slot
  /// is merged recursively.
  @override
  CoreSelectableTextStyle merge(CoreSelectableTextStyle? other) {
    if (other == null) return this;
    return CoreSelectableTextStyle(
      textStyle: _mergeText(textStyle, other.textStyle),
      cursorColor: other.cursorColor ?? cursorColor,
      cursorWidth: other.cursorWidth ?? cursorWidth,
      cursorHeight: other.cursorHeight ?? cursorHeight,
      cursorRadius: other.cursorRadius ?? cursorRadius,
      selectionColor: other.selectionColor ?? selectionColor,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreSelectableTextStyle copyWith({
    CoreTextStyle? textStyle,
    CoreColor? cursorColor,
    double? cursorWidth,
    double? cursorHeight,
    CoreBorderRadius? cursorRadius,
    CoreColor? selectionColor,
  }) {
    return CoreSelectableTextStyle(
      textStyle: textStyle ?? this.textStyle,
      cursorColor: cursorColor ?? this.cursorColor,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      selectionColor: selectionColor ?? this.selectionColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSelectableTextStyle &&
          runtimeType == other.runtimeType &&
          textStyle == other.textStyle &&
          cursorColor == other.cursorColor &&
          cursorWidth == other.cursorWidth &&
          cursorHeight == other.cursorHeight &&
          cursorRadius == other.cursorRadius &&
          selectionColor == other.selectionColor;

  @override
  int get hashCode => Object.hash(
    textStyle,
    cursorColor,
    cursorWidth,
    cursorHeight,
    cursorRadius,
    selectionColor,
  );

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
