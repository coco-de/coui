import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'typography.stories.g.dart';

/// Showcase page listing typography roles and font families.
class TypographyDemo extends StatelessWidget {
  /// Creates a [TypographyDemo].
  const TypographyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        _buildRoleSection(theme),
        _buildSansMonoSection(),
      ],
    );
  }
}

/// Navigation metadata for the Typography foundation page.
const kComponentMeta = ComponentMeta(name: 'Typography', path: 'foundation');

/// Story metadata for [TypographyDemo].
const kMeta = Meta(TypographyDemo.new);

/// Typography roles and font families listing.
final $Default = _Story();

Widget _buildRoleSection(ThemeData theme) {
  final typography = theme.typography;
  // Every role in `CoreTextStyles` order — a role added to the scale shows
  // up here without this list being edited.
  final styles = {
    for (final token in CoreTextStyles.values)
      _roleLabel(token.name, token.read(typography)): token
          .read(typography)
          .toValue(theme: theme),
  };

  return _buildSection('CoUI Typography', styles);
}

/// `label-xl2` → `labelXl2 · 16px / 1.4 / 500 / -0.01em` — the chain name
/// and the theme's metrics, the line box in px where the role fixes one.
String _roleLabel(String kebab, CoreTextStyle style) {
  final parts = kebab.split('-');
  final name = [
    parts.first,
    for (final part in parts.skip(1))
      '${part[0].toUpperCase()}${part.substring(1)}',
  ].join();
  final line = switch (style.lineHeightPx) {
    final box? => '${_number(box)}px',
    null => _number(style.lineHeight),
  };
  return '$name · ${_number(style.fontSize)}px / $line / '
      '${style.fontWeight ?? '—'} / ${_number(style.letterSpacing)}em';
}

/// `52.0` → `52`, `1.4` → `1.4`, `null` → `—`.
String _number(double? value) {
  if (value == null) return '—';
  return value == value.roundToDouble() ? '${value.round()}' : '$value';
}

Widget _buildSansMonoSection() {
  final styles = {
    'mono': kCoreMonoTextStyle,
    'sans': kCoreSansTextStyle,
  };

  return _buildSection('Font Families', styles);
}

Widget _buildSection(String title, Map<String, TextStyle> styles) {
  return Column(
    crossAxisAlignment: .start,
    children: [
      Padding(
        padding: const .all(16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: .bold,
          ),
        ),
      ),
      ...styles.entries.map(
        (entry) => material.ListTile(
          title: Text(entry.key, style: entry.value),
          subtitle: Text(
            'The quick brown fox jumps over the lazy dog',
            style: entry.value,
          ),
        ),
      ),
      const material.Divider(),
    ],
  );
}
