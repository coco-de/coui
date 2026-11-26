import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'stacks.stories.g.dart';

/// Labels of the stacked deck layers.
const List<String> _kLayerLabels = ['Layer 1', 'Layer 2', 'Layer 3'];

/// Top offset of the corner badge (overhangs the box).
const double _kBadgeCornerTopOffset = -CoreSpace.space8;

/// Right offset of the corner badge (overhangs the box).
const double _kBadgeCornerRightOffset = -CoreSpace.space8;

/// Layout variants for [StacksDemo].
enum StacksDemoLayout {
  /// Non-positioned child alignment plus a corner badge.
  alignment,

  /// Card-deck effect with three offset layers.
  deck,
}

/// Non-positioned child alignment options for the [StacksDemo] knob.
enum StacksAlignmentOption {
  /// Bottom-end alignment.
  bottomEnd,

  /// Center alignment.
  center,

  /// Top-start alignment.
  topStart,
}

/// Interactive demo host for [Stacks] stories.
class StacksDemo extends StatelessWidget {
  /// Creates a [StacksDemo].
  const StacksDemo({
    super.key,
    this.layout = StacksDemoLayout.deck,
    this.alignment = StacksAlignmentOption.center,
  });

  /// Which demo layout to render.
  final StacksDemoLayout layout;

  /// Non-positioned child alignment (alignment layout only).
  final StacksAlignmentOption alignment;

  @override
  Widget build(BuildContext context) => switch (layout) {
    .deck => const _DeckLayout(),
    .alignment => _AlignmentLayout(alignment: alignment),
  };
}

/// Maps a widgetbook [StacksAlignmentOption] knob value to a
/// [CoreAlignment].
CoreAlignment _toCoreAlignment(StacksAlignmentOption alignment) =>
    switch (alignment) {
      .topStart => .topStart,
      .center => .center,
      .bottomEnd => .bottomEnd,
    };

class _DeckLayout extends StatelessWidget {
  const _DeckLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight =
        CoreSpace.space160 / 2 + (_kLayerLabels.length - 1) * CoreSpace.space8;

    return SizedBox(
      width: CoreSpace.space160,
      height: totalHeight,
      child: Stacks(
        children: [
          for (final (i, label) in _kLayerLabels.indexed)
            Position(
              top: i * CoreSpace.space8,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer.toValue(),
                  border: Border.all(
                    color: theme.colorScheme.outline.toValue(),
                  ),
                  borderRadius: const .all(
                    .circular(CoreRadius.radius16),
                  ),
                ),
                width: CoreSpace.space160,
                height: CoreSpace.space160 / 2,
                child: Text(label).bodyMedium.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

class _AlignmentLayout extends StatelessWidget {
  const _AlignmentLayout({required this.alignment});

  final StacksAlignmentOption alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.square(
      dimension: CoreSpace.space160,
      child: Stacks(
        alignment: _toCoreAlignment(alignment),
        children: [
          Position.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.toValue(),
                border: Border.all(
                  color: theme.colorScheme.outline.toValue(),
                ),
                borderRadius: const .all(
                  .circular(CoreRadius.radius16),
                ),
              ),
            ),
          ),
          const Text('Centered label').bodyMedium.onSurface,
          Position(
            top: _kBadgeCornerTopOffset,
            right: _kBadgeCornerRightOffset,
            child: SizedBox.square(
              dimension: CoreSpace.space32,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.toValue(),
                  borderRadius: const .all(
                    .circular(CoreRadius.radius9999),
                  ),
                ),
                child: Icon(
                  LucideIcons.star,
                  iconStyle: CoreIconStyle(
                    size: CoreSpace.space16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the Stacks component.
const kComponentMeta = ComponentMeta(name: 'Stacks', path: 'layout');

/// Story metadata for [StacksDemo].
const kMeta = Meta(StacksDemo.new);

/// Card-deck effect with three layered boxes offset via [Position].
final $Default = _Story();

/// Alignment demo with a [Position]-anchored corner badge.
final $WithAlignment = _Story(
  name: 'With Alignment',
  args: _Args(
    layout: EnumArg(
      StacksDemoLayout.alignment,
      values: StacksDemoLayout.values,
    ),
  ),
);
