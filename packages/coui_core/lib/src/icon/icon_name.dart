import 'package:meta/meta.dart';

/// Platform-independent icon name reference.
///
/// Represents an icon from the Iconify ecosystem with a prefix and name.
/// Used by both Flutter and Web Icon widgets to reference the same icon.
///
/// Four catalogues ship (`LucideIcons` / `RadixIcons` / `BootstrapIcons` /
/// `HeroIcons`) and a consuming app is free to pick any of them. CoUI's
/// own shipped components draw from `LucideIcons` only — each catalogue
/// is drawn on its own grid with its own stroke weight, so glyphs from
/// two sets at the same size arrive at different optical weights. Mix
/// catalogues in app code only across unrelated UI, never within the
/// same row of controls.
///
/// Example:
/// ```dart
/// Icon(LucideIcons.home)
/// Icon(
///   LucideIcons.chevronLeft,
///   iconStyle: CoreIconStyle(size: CoreIconSize.size16),
/// )
/// ```
@immutable
class IconName {
  /// Creates an [IconName] with the given [prefix] and [name].
  const IconName(this.prefix, this.name);

  /// The icon set prefix (e.g., 'lucide', 'radix-icons', 'heroicons').
  final String prefix;

  /// The icon name within the set (e.g., 'home', 'chevron-left').
  final String name;

  /// The full Iconify icon ID (e.g., 'lucide:home').
  String get id => '$prefix:$name';

  /// Returns a copy with a different prefix (for style variants).
  IconName withPrefix(String prefix) => .new(prefix, name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconName && other.prefix == prefix && other.name == name;

  @override
  int get hashCode => Object.hash(prefix, name);

  @override
  String toString() => id;
}

/// An icon that supports multiple styles (e.g., HeroIcons outline/solid/mini/micro).
@immutable
class StyledIconName extends IconName {
  /// Creates a [StyledIconName].
  const StyledIconName(super.prefix, super.name, {this.styles = const {}});

  /// Available style variants with their prefixes.
  final Map<String, String> styles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StyledIconName && other.prefix == prefix && other.name == name;

  @override
  int get hashCode => Object.hash(prefix, name);

  /// Outline style (default for HeroIcons).
  IconName get outline => this;

  /// Solid style.
  IconName get solid {
    final p = styles['solid'];
    return p != null ? IconName(p, name) : this;
  }

  /// Mini style (20px optimized).
  IconName get mini {
    final p = styles['mini'];
    return p != null ? IconName(p, name) : this;
  }

  /// Micro style (16px optimized).
  IconName get micro {
    final p = styles['micro'];
    return p != null ? IconName(p, name) : this;
  }
}
