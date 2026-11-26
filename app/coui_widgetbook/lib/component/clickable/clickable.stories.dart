import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'clickable.stories.g.dart';

/// Interactive demo host for [Clickable] stories.
///
/// Wraps a simple [Card] box and shows the built-in hover/press
/// feedback (cursor, press-scale animation, focus ring) alongside
/// live status text tracking the hover state and press count.
class ClickableDemo extends StatefulWidget {
  /// Creates a [ClickableDemo].
  const ClickableDemo({
    super.key,
    this.enabled = true,
    this.label = 'Click or hover me',
  });

  /// Whether the demoed [Clickable] reacts to hover/press.
  final bool enabled;

  /// Text shown inside the clickable card.
  final String label;

  @override
  State<ClickableDemo> createState() => _ClickableDemoState();
}

class _ClickableDemoState extends State<ClickableDemo> {
  bool _hovered = false;
  int _pressCount = 0;

  void handleHover(bool hovered) {
    setState(() {
      _hovered = hovered;
    });
  }

  void handlePressed() {
    setState(() {
      _pressCount += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space8,
      children: [
        Clickable(
          onPressed: handlePressed,
          onHover: handleHover,
          enabled: widget.enabled,
          child: Card(child: Text(widget.label).bodyMedium),
        ),
        Text(
          _hovered
              ? 'Hovered - pressed $_pressCount time(s)'
              : 'Pressed $_pressCount time(s)',
        ).bodySmall,
      ],
    );
  }
}

/// Navigation metadata for the Clickable component.
const kComponentMeta = ComponentMeta(name: 'Clickable', path: 'infra');

/// Story metadata for [ClickableDemo].
const kMeta = Meta(ClickableDemo.new);

/// Interactive clickable card with hover/press status text.
final $Default = _Story();

/// Disabled clickable — forbidden cursor and dimmed child instead of
/// hover/press feedback.
final $Disabled = _Story(
  args: _Args(enabled: BoolArg(false)),
);
