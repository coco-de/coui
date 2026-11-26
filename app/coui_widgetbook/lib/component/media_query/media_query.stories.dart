import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'media_query.stories.g.dart';

// MediaQueryVisibility widgetbook constants.
const _kDefaultMaxWidth = 800.0;
const _kAlpha = 0.2;

/// Interactive demo host for [MediaQueryVisibility] stories.
class MediaQueryVisibilityDemo extends StatelessWidget {
  /// Creates a [MediaQueryVisibilityDemo].
  const MediaQueryVisibilityDemo({
    super.key,
    this.minWidth = 0,
    this.maxWidth = _kDefaultMaxWidth,
  });

  /// Minimum viewport width in pixels (0 disables the lower bound).
  final double minWidth;

  /// Maximum viewport width in pixels.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: CoreSpace.space16,
        children: [
          Text('Min: ${minWidth.toInt()}px, Max: ${maxWidth.toInt()}px'),
          MediaQueryVisibility(
            alternateChild: Container(
              padding: const .all(CoreSpace.space16),
              color: material.Colors.orange.withValues(alpha: _kAlpha),
              child: const Text('Hidden (outside width range)'),
            ),
            minWidth: minWidth > 0 ? minWidth : null,
            maxWidth: maxWidth,
            child: Container(
              padding: const .all(CoreSpace.space16),
              color: material.Colors.green.withValues(alpha: _kAlpha),
              child: const Text('Visible (within width range)'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the MediaQueryVisibility component.
const kComponentMeta = ComponentMeta(
  name: 'MediaQueryVisibility',
  path: 'layout',
);

/// Story metadata for [MediaQueryVisibilityDemo].
const kMeta = Meta(MediaQueryVisibilityDemo.new);

/// Visibility toggling by viewport width with editable knobs.
final $Default = _Story();
