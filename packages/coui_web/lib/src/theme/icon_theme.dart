import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Data for a Web [IconTheme] — mirrors Flutter SDK `IconThemeData`.
///
/// Currently exposes the subset of fields that CoUI's `<iconify-icon>`
/// rendering actually consumes (size + color). Flutter `IconThemeData`
/// has additional fields (fill / weight / grade / opticalSize / shadows /
/// opacity / applyTextScaling) that target Material font icons; those
/// don't apply to the iconify SVG pipeline so they're omitted here.
@immutable
class IconThemeData {
  /// Creates an [IconThemeData].
  const IconThemeData({this.size, this.color});

  /// The ambient data a composing component hands its slot content from a
  /// resolved [CoreIconStyle] — size and colour as-is, so a slot colour
  /// and an `Icon`'s own `iconStyle` colour reach the glyph through the
  /// same emit. A `null` colour leaves the glyph on `currentColor`.
  factory IconThemeData.fromCoreIconStyle(CoreIconStyle style) =>
      IconThemeData(size: style.size, color: style.color);

  /// Default icon size (logical pixels) for descendant icons.
  final double? size;

  /// Default icon color for descendant icons.
  ///
  /// A [CoreColor], the CoUI counterpart of the `Color` Flutter SDK's
  /// `IconThemeData.color` holds. Keeping the value (rather than a token
  /// string) is what lets a raw colour reach the glyph: `Icon` decides
  /// class vs inline when it emits, and a string has already lost the
  /// raw value by then.
  final CoreColor? color;

  @override
  bool operator ==(Object other) =>
      other is IconThemeData && other.size == size && other.color == color;

  @override
  int get hashCode => Object.hash(size, color);
}

/// Inherited icon theme — descendant `Icon` instances pick up the
/// nearest [IconTheme]'s [data] when their own `size` / `color` is null.
///
/// Mirrors Flutter SDK's `IconTheme` exactly in usage:
///
/// ```dart
/// IconTheme(
///   data: IconThemeData(
///     size: 16,
///     color: CoreColor.token(CoreColors.onSurface),
///   ),
///   child: icon,
/// )
/// ```
///
/// Icon resolution priority (Web):
/// widget param > [CoreComponentTheme] > nearest [IconTheme] > default.
///
/// Pure metadata — emits no DOM of its own.
class IconTheme extends InheritedComponent {
  /// Creates an [IconTheme] provider.
  const IconTheme({required this.data, required super.child, super.key});

  /// The icon theme data.
  final IconThemeData data;

  /// Returns the nearest [IconTheme] data in the ancestor chain, or `null`.
  static IconThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<IconTheme>()?.data;

  @override
  bool updateShouldNotify(covariant IconTheme oldComponent) =>
      data != oldComponent.data;
}
