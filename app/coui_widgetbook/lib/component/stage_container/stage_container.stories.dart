import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'stage_container.stories.g.dart';

/// Height of the demo content block.
const _kContentHeight = 100.0;

/// Alpha applied to the demo content background.
const _kBackgroundAlpha = 0.2;

/// Spacing between the padding label and the content block.
const _kColumnSpacing = 16.0;

/// Demo host for [StageContainer] stories.
///
/// Shows the resolved horizontal padding and a content block that
/// adapts to the available stage width.
class StageContainerDemo extends StatelessWidget {
  /// Creates a [StageContainerDemo].
  const StageContainerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.primary.toValue();

    return StageContainer(
      builder: (context, padding) {
        return Padding(
          padding: .fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: .start,
            spacing: _kColumnSpacing,
            children: [
              Text('Padding: ${padding.left + padding.right}'),
              ColoredBox(
                color: base.withValues(alpha: _kBackgroundAlpha),
                child: const SizedBox(
                  height: _kContentHeight,
                  child: Center(
                    child: Text('Content adapts to screen width'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Navigation metadata for the StageContainer component.
const kComponentMeta = ComponentMeta(name: 'StageContainer', path: 'layout');

/// Story metadata for [StageContainerDemo].
const kMeta = Meta(StageContainerDemo.new);

/// Stage container with width-adaptive padding.
final $Default = _Story();
