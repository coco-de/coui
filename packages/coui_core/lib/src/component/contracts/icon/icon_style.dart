/// Per-instance / per-theme style for `Icon`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Icon` should render.
///
/// Every field is nullable — `null` means "inherit from the next level
/// in the resolve chain":
///
/// 1. design system default
/// 2. `theme.icon.defaultStyle` (app-level CoreIconTheme)
/// 3. parent component slot override (e.g. `CoreButtonStyle.leadingIconStyle`)
/// 4. widget per-instance `style:` parameter
///
/// Use [merge] to compose two styles, with the *other* style winning on
/// each non-null field.
///
/// ### Colour type (Epic #1415)
///
/// `color` is a [CoreColor] — a platform-neutral descriptor that can
/// carry an ARGB value or a semantic token reference. Resolution to
/// Flutter `Color` / CSS string happens through the per-platform
/// `.toValue()` extension at render time.
@immutable
class CoreIconStyle implements CoreStyle<CoreIconStyle> {
  /// Creates a [CoreIconStyle].
  const CoreIconStyle({
    this.size,
    this.color,
  });

  // ── Design-system defaults (Epic #1603 Phase 27) ──────────────────

  /// Default icon size in logical pixels (Flutter) / CSS pixels (Web).
  /// Used when no [CoreIconStyle] in the resolve chain supplies a [size]
  /// and the ambient `IconTheme` does not either.
  static const double defaultSize = CoreIconSize.defaultSize;

  /// The size the application root states through its ambient `IconTheme`
  /// — what an `Icon` with no size in its resolve chain draws at inside a
  /// CoUI app.
  ///
  /// The resolver reads `merged.size ?? ambient IconTheme size ??`
  /// [defaultSize], and both app roots fill the middle step from here:
  /// Flutter `CoUIApp` mounts `theme.iconTheme.medium`, whose default is
  /// this value (before the theme's text scaling), and Web `CoUIWeb`
  /// mounts an `IconTheme` of this size. So a slot that renders a caller's
  /// `Icon` as handed, with no `IconTheme` of its own around it, draws that
  /// icon at this size — not at [defaultSize], which an app only reaches
  /// where something removes the ambient size.
  ///
  /// No instance field pairs with it: a subtree changes the ambient size
  /// with its own `IconTheme`, not through a [CoreIconStyle].
  static const double defaultAmbientSize = CoreIconSize.size20;

  /// Default icon colour — the `onSurface` semantic token. Used by the
  /// Flutter resolver as the final colour fallback when neither the merge
  /// chain nor the ambient `IconTheme` supplies a colour, so the
  /// design-system colour decision lives here as a single source (no
  /// `scheme.onSurface` direct read in the platform resolver).
  ///
  /// The Web resolver intentionally does **not** force this token: with
  /// no override and no ambient colour it leaves the icon to inherit
  /// `currentColor` from the CSS cascade — the platform-native colour
  /// inheritance mechanism (mirrors Flutter's ambient `IconTheme` and
  /// converges on `onSurface` at the document root). Hard-coding the
  /// token class would break colour inheritance for icons composed inside
  /// coloured parents (button / chip / label / …).
  static const CoreColor defaultColor = CoreColor.token(CoreColors.onSurface);

  /// Icon size in logical pixels (Flutter) / CSS pixels (Web). `null`
  /// inherits it — from the surrounding `IconTheme`, else [defaultSize].
  final double? size;

  /// Icon colour. `null` → inherit.
  final CoreColor? color;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. `null` in [other] keeps the
  /// existing value.
  ///
  /// Resolve chain usage:
  /// ```dart
  /// final effective = designSystemDefault
  ///   .merge(theme.icon.defaultStyle)
  ///   .merge(parent.iconStyle)
  ///   .merge(widget.style);
  /// ```
  @override
  CoreIconStyle merge(CoreIconStyle? other) {
    if (other == null) return this;
    return CoreIconStyle(
      size: other.size ?? size,
      color: other.color ?? color,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden. Convenient for one-off tweaks where building a fresh
  /// `CoreIconStyle` feels heavy.
  /// This style's size with no colour — a glyph drawn from it takes the
  /// ambient icon tone of whatever it sits in. A control that is disabled
  /// hands its glyph back to the field's own disabled foreground this way
  /// instead of restating a colour that would win over it.
  CoreIconStyle get withoutColor => CoreIconStyle(size: size);

  CoreIconStyle copyWith({
    double? size,
    CoreColor? color,
  }) {
    return CoreIconStyle(
      size: size ?? this.size,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIconStyle && size == other.size && color == other.color;

  @override
  int get hashCode => Object.hash(size, color);
}
