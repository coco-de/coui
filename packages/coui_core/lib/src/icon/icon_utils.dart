/// SVG utility functions for icon rendering.
library;

int _counter = 0;

/// Replaces internal SVG IDs with unique ones to prevent collisions
/// when multiple instances of the same icon are rendered.
String replaceIDs(String svgBody) {
  final prefix = 'coui-icon-${_counter++}';
  final idMap = <String, String>{};

  final idDefPattern = RegExp('id="([^"]+)"');
  final matches = idDefPattern.allMatches(svgBody);
  for (final match in matches) {
    final originalId = match.group(1)!;
    idMap[originalId] = '$prefix-$originalId';
  }

  if (idMap.isEmpty) return svgBody;

  var result = svgBody;
  for (final entry in idMap.entries) {
    final original = entry.key;
    final replacement = entry.value;
    result = result
        .replaceAll('id="$original"', 'id="$replacement"')
        .replaceAll('url(#$original)', 'url(#$replacement)')
        .replaceAll('href="#$original"', 'href="#$replacement"')
        .replaceAll(
          'xlink:href="#$original"',
          'xlink:href="#$replacement"',
        );
  }

  return result;
}

/// Builds a complete SVG string from icon body data.
///
/// Used by both Flutter (for flutter_svg) and Web (for inline `<svg>`).
String buildSvgString({
  required String body,
  required int width,
  required int height,
  double? size,
  String? className,
  String? style,
  String? id,
  Map<String, String>? attributes,
}) {
  final w = size ?? width.toDouble();
  final h = size ?? height.toDouble();

  final buffer = StringBuffer('<svg')
    ..write(' xmlns="http://www.w3.org/2000/svg"')
    ..write(' viewBox="0 0 $width $height"')
    ..write(' width="$w"')
    ..write(' height="$h"')
    ..write(' aria-hidden="true"')
    ..write(' role="img"');

  if (id != null) {
    buffer.write(' id="$id"');
  }
  if (className != null) {
    buffer.write(' class="$className"');
  }
  if (style != null) {
    buffer.write(' style="$style"');
  }

  if (attributes != null) {
    for (final entry in attributes.entries) {
      buffer.write(' ${entry.key}="${entry.value}"');
    }
  }

  buffer
    ..write('>')
    ..write(replaceIDs(body))
    ..write('</svg>');

  return buffer.toString();
}
