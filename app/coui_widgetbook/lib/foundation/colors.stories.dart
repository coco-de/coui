import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'colors.stories.g.dart';

const _kBorderAlpha = 0.3;
const _kSwatchSize = 24.0;
const _kUnnamedColor = '';

/// Showcase page listing every semantic color of the active color scheme.
class ColorSchemeDemo extends StatelessWidget {
  /// Creates a [ColorSchemeDemo].
  const ColorSchemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _ColorList(colorScheme: colorScheme);
  }
}

/// Navigation metadata for the Colors foundation page.
const kComponentMeta = ComponentMeta(name: 'Colors', path: 'foundation');

/// Story metadata for [ColorSchemeDemo].
const kMeta = Meta(ColorSchemeDemo.new);

/// Full color scheme listing.
final $Default = _Story();

class _ColorList extends StatelessWidget {
  const _ColorList({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ColorScheme(
      :error,
      :info,
      :onError,
      :onInfo,
      :onPrimary,
      :onSecondary,
      :onSuccess,
      :onSurface,
      :onTertiary,
      :onWarning,
      :outline,
      :primary,
      :secondary,
      :success,
      :surface,
      surfaceContainer: lowEmphasisSurface,
      surfaceContainerHigh: raisedSurface,
      :tertiary,
      :warning,
    ) = colorScheme;

    // Sorted alphabetically (uppercase before lowercase in ASCII).
    final couiColors = {
      'Base Colors': null,
      'Brand Colors': null,
      'Semantic Status Colors': null,
      'error': error,
      'info': info,
      'onError': onError,
      'onInfo': onInfo,
      'onPrimary': onPrimary,
      'onSecondary': onSecondary,
      'onSuccess': onSuccess,
      'onSurface': onSurface,
      'onTertiary': onTertiary,
      'onWarning': onWarning,
      'outline': outline,
      'primary': primary,
      'secondary': secondary,
      'success': success,
      'surface': surface,
      'surfaceContainer': lowEmphasisSurface,
      'surfaceContainerHigh': raisedSurface,
      'tertiary': tertiary,
      'warning': warning,
    };

    final Map<String, CoreColor?>(:keys, :length, :values) = couiColors;

    return ListView.builder(
      itemBuilder: (context, index) {
        final name = keys.elementAtOrNull(index) ?? _kUnnamedColor;
        final color = values.elementAtOrNull(index);

        return color == null
            ? Padding(
                padding: const .only(left: 16, top: 16, bottom: 8),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: .bold,
                  ),
                ),
              )
            : material.ListTile(
                leading: SizedBox.square(
                  dimension: _kSwatchSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color.toValue(),
                      border: Border.all(
                        color: material.Colors.grey.withValues(
                          alpha: _kBorderAlpha,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: Text(color.toString()),
              );
      },
      itemCount: length,
    );
  }
}
