/// Icon data representation and Iconify JSON parsing.
library;

import 'package:meta/meta.dart';

/// Existing default for a standalone [IconSvgData] value.
const _kDefaultIconSize = 24;

/// Default viewBox dimensions in the Iconify JSON protocol.
const _kIconifyDefaultSize = 16;

/// Maximum alias chain depth to prevent infinite loops.
const _kMaxAliasDepth = 10;

/// Represents the SVG data for a single icon.
@immutable
class IconSvgData {
  /// Creates an [IconSvgData].
  const IconSvgData({
    required this.body,
    this.width = _kDefaultIconSize,
    this.height = _kDefaultIconSize,
  });

  /// Creates an [IconSvgData] from a JSON map.
  factory IconSvgData.fromJson(Map<String, dynamic> json) {
    return IconSvgData(
      body: json['body'] as String,
      width: json['width'] as int? ?? _kDefaultIconSize,
      height: json['height'] as int? ?? _kDefaultIconSize,
    );
  }

  /// The SVG body content (inner elements of the `<svg>` tag).
  final String body;

  /// The icon's native width.
  final int width;

  /// The icon's native height.
  final int height;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'body': body,
    'width': width,
    'height': height,
  };
}

/// Parsed representation of an Iconify API JSON response.
class IconifyJson {
  const IconifyJson._({
    required Map<String, _IconEntry> icons,
    required Map<String, _AliasEntry> aliases,
    required this.defaultWidth,
    required this.defaultHeight,
    required _IconProperties defaults,
  }) : _icons = icons,
       _aliases = aliases,
       _defaults = defaults;

  /// Parses an Iconify API JSON response.
  factory IconifyJson.fromJson(Map<String, dynamic> json) {
    final defaults = _IconProperties.fromJson(json);

    final iconsJson = json['icons'] as Map<String, dynamic>? ?? {};
    final aliasesJson = json['aliases'] as Map<String, dynamic>? ?? {};

    final icons = <String, _IconEntry>{};
    for (final entry in iconsJson.entries) {
      final data = entry.value as Map<String, dynamic>;
      icons[entry.key] = _IconEntry(
        body: data['body'] as String,
        properties: _IconProperties.fromJson(data),
      );
    }

    final aliases = <String, _AliasEntry>{};
    for (final entry in aliasesJson.entries) {
      final data = entry.value as Map<String, dynamic>;
      aliases[entry.key] = _AliasEntry(
        parent: data['parent'] as String,
        properties: _IconProperties.fromJson(data),
      );
    }

    return IconifyJson._(
      icons: icons,
      aliases: aliases,
      defaultWidth: defaults.width ?? _kIconifyDefaultSize,
      defaultHeight: defaults.height ?? _kIconifyDefaultSize,
      defaults: defaults,
    );
  }

  /// Default icon width for this set.
  final int defaultWidth;

  /// Default icon height for this set.
  final int defaultHeight;

  final Map<String, _IconEntry> _icons;

  final Map<String, _AliasEntry> _aliases;

  final _IconProperties _defaults;

  /// Resolves an icon by [name] within this set.
  IconSvgData? resolve(String name) {
    var current = name;
    var properties = const _IconProperties();

    for (var depth = 0; depth <= _kMaxAliasDepth; depth++) {
      final icon = _icons[current];
      if (icon != null) {
        return _defaults
            .merge(icon.properties.merge(properties))
            .toSvgData(icon.body);
      }
      if (depth == _kMaxAliasDepth) return null;
      final alias = _aliases[current];
      if (alias == null) return null;
      properties = alias.properties.merge(properties);
      current = alias.parent;
    }

    return null;
  }

  /// All icon names in this set (including aliases).
  Iterable<String> get names => _icons.keys.followedBy(_aliases.keys);
}

class _IconEntry {
  const _IconEntry({required this.body, required this.properties});

  final String body;
  final _IconProperties properties;
}

class _AliasEntry {
  const _AliasEntry({required this.parent, required this.properties});

  final String parent;
  final _IconProperties properties;
}

/// Metadata inherited by an icon or alias in the Iconify JSON protocol.
class _IconProperties {
  const _IconProperties({
    this.left,
    this.top,
    this.width,
    this.height,
    this.hFlip = false,
    this.vFlip = false,
    this.rotate = 0,
  });

  factory _IconProperties.fromJson(Map<String, dynamic> json) =>
      _IconProperties(
        left: json['left'] as num?,
        top: json['top'] as num?,
        width: json['width'] as int?,
        height: json['height'] as int?,
        hFlip: json['hFlip'] == true,
        vFlip: json['vFlip'] == true,
        rotate: json['rotate'] as int? ?? 0,
      );

  final num? left;
  final num? top;
  final int? width;
  final int? height;
  final bool hFlip;
  final bool vFlip;
  final int rotate;

  // Dimensions/origins inherit; transformations compose rather than override.
  _IconProperties merge(_IconProperties child) => _IconProperties(
    left: child.left ?? left,
    top: child.top ?? top,
    width: child.width ?? width,
    height: child.height ?? height,
    hFlip: hFlip != child.hFlip,
    vFlip: vFlip != child.vFlip,
    rotate: (rotate + child.rotate) % 4,
  );

  // IconSvgData already carries SVG, so materialize the protocol's transforms
  // in that body while preserving its existing body/width/height API. Both
  // renderers consume a zero-origin viewBox. Flips precede clockwise rotation.
  IconSvgData toSvgData(String body) {
    final w = width ?? _kIconifyDefaultSize;
    final h = height ?? _kIconifyDefaultSize;
    final sx = hFlip ? -1 : 1;
    final sy = vFlip ? -1 : 1;
    final tx = (hFlip ? w : 0) - sx * (left ?? 0);
    final ty = (vFlip ? h : 0) - sy * (top ?? 0);
    final rotation = rotate % 4;
    final (num, num, num, num, num, num) matrix = switch (rotation) {
      1 => (0, sx, -sy, 0, h - ty, tx),
      2 => (-sx, 0, 0, -sy, w - tx, h - ty),
      3 => (0, -sx, sy, 0, ty, w - tx),
      _ => (sx, 0, 0, sy, tx, ty),
    };
    final (a, b, c, d, e, f) = matrix;
    final identity = a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0;
    return IconSvgData(
      body: identity
          ? body
          : '<g transform="matrix($a $b $c $d $e $f)">$body</g>',
      width: rotation.isOdd ? h : w,
      height: rotation.isOdd ? w : h,
    );
  }
}
