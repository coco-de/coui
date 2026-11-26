/// Per-instance style for `AspectRatioBox`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `AspectRatioBox` behaves.
///
/// `AspectRatioBox` is a pure layout primitive — it owns no chrome
/// (background / border / padding). The only knob that flows through
/// the style is the fallback [defaultRatio] applied when the widget
/// itself receives a non-positive ratio.
///
/// ```text
/// design system default (defaultDefaultRatio)
///   → CoreAspectRatioBoxTheme.style                  // 프로젝트 공통
///   → widget.ratio                                    // 인스턴스별
/// ```
@immutable
class CoreAspectRatioBoxStyle implements CoreStyle<CoreAspectRatioBoxStyle> {
  /// Creates a [CoreAspectRatioBoxStyle].
  const CoreAspectRatioBoxStyle({this.defaultRatio});

  /// Design-system fallback ratio (`width / height`) applied when
  /// neither the widget nor a higher-priority style supplies a strictly
  /// positive value. `1.0` renders a square box.
  ///
  /// The doubled word is the `default<Field>` pairing spelled out for a
  /// field that is itself named [defaultRatio] — `core/layer-mapping.md`
  /// makes a chrome field greppable from its default by that name alone.
  ///
  /// Single source of truth shared by the Flutter and Web resolvers so
  /// the fallback cannot silently diverge between platforms.
  static const double defaultDefaultRatio = 1;

  /// Project-level fallback ratio (`width / height`) when the widget
  /// caller supplies a value that is not strictly positive. `null`
  /// defers to [defaultDefaultRatio] (square).
  final double? defaultRatio;

  @override
  CoreAspectRatioBoxStyle merge(CoreAspectRatioBoxStyle? other) {
    if (other == null) return this;
    return CoreAspectRatioBoxStyle(
      defaultRatio: other.defaultRatio ?? defaultRatio,
    );
  }

  /// Returns a copy of this style with the supplied non-null field
  /// overridden.
  CoreAspectRatioBoxStyle copyWith({double? defaultRatio}) =>
      .new(defaultRatio: defaultRatio ?? this.defaultRatio);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAspectRatioBoxStyle &&
          runtimeType == other.runtimeType &&
          defaultRatio == other.defaultRatio;

  @override
  int get hashCode => defaultRatio.hashCode;
}
